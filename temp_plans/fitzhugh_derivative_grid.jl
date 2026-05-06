"""
Fast per-(interpolator, t_eval, order) derivative-error grid for fitzhugh polish=OFF.

Bypasses the full pipeline. Just:
1. Load fitzhugh y1(t) data.
2. Compute oracle Taylor coefficients at each t_eval via solving the ODE high-precision.
3. For each interpolator: fit to data, evaluate derivatives at each (t, order),
   compare to oracle.

Targets the question: at the production shooting points (t≈0, 0.183, 1.0), how does each
interpolator do per derivative order? Are boundaries the killer? Does any single interp
have a clean signal at the interior?

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/fitzhugh_derivative_grid.jl")'
"""

using CSV
using Logging
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Statistics
using Printf

const ODEPE = ODEParameterEstimation

function _load_bilby_data(case_dir::AbstractString, mq)
    datafile = joinpath(case_dir, "data.csv")
    csv_data = CSV.read(datafile, Tuple, header = false)
    data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
    data_sample["t"] = collect(Float64, csv_data[1])
    for (i, eq) in enumerate(mq)
        data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
    end
    return data_sample
end

function build_fitzhugh()
    parameters = @parameters g a b
    states = @variables Vm(t) R(t)
    observables = @variables y1(t)
    state_equations = [
        D(Vm) ~ (-3.0) * g * (0.5 * R - 2.0 * Vm + (2.6666666666666665) * (Vm^3)),
        D(R) ~ (-0.4 * a - 2.0 * Vm + 0.2 * b * R) / (3.0 * g),
    ]
    measured_quantities = [y1 ~ -2.0 * Vm]
    ic = [0.42, 0.404]
    p_true = [0.779, 0.849, 0.887]
    model, mq = ODEPE.create_ordered_ode_system("fitzhugh_nagumo", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_2_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "fitzhugh_nagumo_2_1em4",
        model, mq, data_sample, [0.0, 1.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

# ─── Build oracle and load data ────────────────────────────────────────────────────

println("Loading fitzhugh + computing oracles...")
pep = build_fitzhugh()

t_data = pep.data_sample["t"]
y1_data = let
    found = nothing
    for (k, v) in pep.data_sample
        if !(k isa String)
            found = v
            break
        end
    end
    found
end
isnothing(y1_data) && error("Couldn't find y1 data column")
println("Data: $(length(t_data)) points over [$(t_data[1]), $(t_data[end])], dt=$(round(t_data[2]-t_data[1]; sigdigits=3))")

# Test points: boundary (0), early-spike (0.05), production-best (0.183), middle (0.5),
# right-boundary (0.95), absolute-end (0.999)
test_ts = [0.001, 0.05, 0.183, 0.5, 0.95, 0.999]
max_order = 4

# Oracle: for each t in test_ts, compute true derivatives via the ODE
println("\nComputing oracle derivatives (high-precision ODE solve)...")
oracle = Dict{Float64, Vector{Float64}}()
for tval in test_ts
    state_taylor = ODEPE.compute_oracle_taylor_coefficients(pep, tval, max_order + 2)
    obs_taylor = ODEPE.compute_observable_taylor_coefficients(pep, state_taylor, tval, max_order + 2)
    # obs_taylor is Dict{Num, Vector{Float64}} keyed by the observable LHS
    obs_key = first(keys(obs_taylor))
    coeffs = obs_taylor[obs_key]   # [c_0/0!, c_1/1!, ..., c_k/k!]
    # nth derivative = c_n = n! · coeff[n+1]
    derivs = Float64[factorial(n) * coeffs[n + 1] for n in 0:max_order]
    oracle[tval] = derivs
    @printf("t=%.4g: oracle[d^k y1/dt^k] for k=0..%d = %s\n",
        tval, max_order, string(round.(derivs; sigdigits=4)))
end

# ─── Interpolators to test ─────────────────────────────────────────────────────────

interp_methods = [
    InterpolatorAAAD,
    InterpolatorAAADGPR,
    InterpolatorAGPRobust,        # SE
    InterpolatorAGPRobustSExRQ,
    InterpolatorAGPRobustMatern52,
    InterpolatorChebyshevBIC,
    InterpolatorS2AAAMLE,
]

# ─── Per-(method, t, order) derivative grid ─────────────────────────────────────────

println("\nFitting each interpolator and evaluating derivatives at test points...")
grid = Dict{Symbol, Dict{Float64, Vector{Float64}}}()

for method in interp_methods
    name = ODEPE.interpolator_method_to_symbol(method)
    print("  $(name) ... ")
    fit_elapsed = @elapsed begin
        f = try
            interp_func = ODEPE.get_interpolator_function(method)
            interp_func(t_data, y1_data)
        catch e
            println("FIT FAILED: $e")
            nothing
        end
    end
    if isnothing(f)
        println("(skipped)")
        continue
    end
    grid[name] = Dict{Float64, Vector{Float64}}()
    for tval in test_ts
        derivs = Float64[]
        for k in 0:max_order
            d = try
                ODEPE.nth_deriv(x -> f(x), k, tval)
            catch
                NaN
            end
            push!(derivs, d)
        end
        grid[name][tval] = derivs
    end
    println("done in $(round(fit_elapsed; digits=1))s")
end

# ─── Print the grid: per-t table of relative errors ────────────────────────────────

println("\n", "="^72)
println("DERIVATIVE GRID — relative errors |interp − truth| / max(|truth|, 1e-12)")
println("="^72)

for tval in test_ts
    println("\n=== t = $tval ===")
    @printf("%-30s %-12s %-12s %-12s %-12s %-12s\n",
        "interpolator", "ord 0", "ord 1", "ord 2", "ord 3", "ord 4")
    for method in interp_methods
        name = ODEPE.interpolator_method_to_symbol(method)
        haskey(grid, name) || continue
        derivs = grid[name][tval]
        rels = Float64[]
        for k in 0:max_order
            ot = oracle[tval][k + 1]
            it = derivs[k + 1]
            r = abs(ot) > 1e-12 ? abs(it - ot) / abs(ot) : abs(it - ot)
            push!(rels, r)
        end
        @printf("%-30s %-12.3g %-12.3g %-12.3g %-12.3g %-12.3g\n",
            string(name), rels[1], rels[2], rels[3], rels[4], rels[5])
    end
end

# Also: show absolute predictions at one bad point and one good point for spot-check
println("\n", "="^72)
println("ABSOLUTE VALUES at t=0.001 (left boundary) — sanity")
println("="^72)
println("Oracle: ", oracle[0.001])
for method in interp_methods
    name = ODEPE.interpolator_method_to_symbol(method)
    haskey(grid, name) || continue
    println("  $(name): ", round.(grid[name][0.001]; sigdigits=4))
end

println("\nABSOLUTE VALUES at t=0.5 (interior)")
println("Oracle: ", oracle[0.5])
for method in interp_methods
    name = ODEPE.interpolator_method_to_symbol(method)
    haskey(grid, name) || continue
    println("  $(name): ", round.(grid[name][0.5]; sigdigits=4))
end

println("\nDERIV_GRID_DONE")
