# Per-(interpolator, t, derivative-order) error grid for forced_lv y1, y2 at noise=1e-2.
# Same idea as fitzhugh_derivative_grid.jl but for the high-noise case.

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

function _load_bilby_data(case_dir, mq)
    csv_data = CSV.read(joinpath(case_dir, "data.csv"), Tuple, header = false)
    data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
    data_sample["t"] = collect(Float64, csv_data[1])
    for (i, eq) in enumerate(mq)
        data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
    end
    return data_sample
end

parameters = @parameters alpha beta delta gamma
states = @variables x(t) yv(t)
observables = @variables y1(t) y2(t)
eqs = [
    D(x) ~ (-0.3*sin(2.0*t) + 6.0*alpha*x - 8.0*beta*x*yv) / 2.0,
    D(yv) ~ (-12.0*gamma*yv + 4.0*delta*x*yv) / 2.0,
]
mq_orig = [y1 ~ 2.0*x, y2 ~ 2.0*yv]
ic = [0.806, 0.676]
p_true = [0.103, 0.243, 0.59, 0.165]
model, mq = ODEPE.create_ordered_ode_system("forced_lv", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/forced_lotka_volterra_0_1em2"
pep = ParameterEstimationProblem("forced_lv", model, mq, _load_bilby_data(case_dir, mq), [0.0, 5.0], nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)

t_data = pep.data_sample["t"]
println("Data: $(length(t_data)) points over [$(t_data[1]), $(t_data[end])], dt=$(t_data[2]-t_data[1])")

# Get y1 and y2 from the data_sample
y_data_keys = [k for (k, v) in pep.data_sample if !(k isa String)]
y1_data = pep.data_sample[y_data_keys[1]]
y2_data = pep.data_sample[y_data_keys[2]]
@printf("y1 data range: [%.4g, %.4g]\n", minimum(y1_data), maximum(y1_data))
@printf("y2 data range: [%.4g, %.4g]\n", minimum(y2_data), maximum(y2_data))

# Test points: across the full range
test_ts = [0.05, 0.5, 1.5, 2.5, 4.5, 4.95]
max_order = 4

# Oracle derivatives
println("\nComputing oracles...")
oracle_y1 = Dict{Float64, Vector{Float64}}()
oracle_y2 = Dict{Float64, Vector{Float64}}()
for tval in test_ts
    state_taylor = ODEPE.compute_oracle_taylor_coefficients(pep, tval, max_order + 2)
    obs_taylor = ODEPE.compute_observable_taylor_coefficients(pep, state_taylor, tval, max_order + 2)
    obs_keys = collect(keys(obs_taylor))
    # Order y1, y2 in the same order as data
    for (idx, k) in enumerate(obs_keys)
        coeffs = obs_taylor[k]
        derivs = Float64[factorial(n) * coeffs[n + 1] for n in 0:max_order]
        if idx == 1; oracle_y1[tval] = derivs; end
        if idx == 2; oracle_y2[tval] = derivs; end
    end
    @printf("t=%.4g: oracle y1 ord 0..4 = %s\n", tval, string(round.(oracle_y1[tval]; sigdigits=4)))
    @printf("       oracle y2 ord 0..4 = %s\n", string(round.(oracle_y2[tval]; sigdigits=4)))
end

# Pick a few representative interpolators
interp_methods = [
    InterpolatorAAAD,
    InterpolatorAAADGPR,
    InterpolatorAGPRobust,
    InterpolatorAGPRobustSExRQ,
    InterpolatorChebyshevBIC,
    InterpolatorS2AAAMLE,
]

# Fit and evaluate per interpolator
grid_y1 = Dict{Symbol, Dict{Float64, Vector{Float64}}}()
grid_y2 = Dict{Symbol, Dict{Float64, Vector{Float64}}}()

for method in interp_methods
    name = ODEPE.interpolator_method_to_symbol(method)
    print("$(name) ... ")
    flush(stdout)
    f1 = nothing; f2 = nothing
    try
        interp_func = ODEPE.get_interpolator_function(method)
        f1 = interp_func(t_data, y1_data)
        f2 = interp_func(t_data, y2_data)
    catch e
        println("FIT FAIL: $e")
        continue
    end
    grid_y1[name] = Dict(); grid_y2[name] = Dict()
    for tval in test_ts
        derivs1 = Float64[]
        derivs2 = Float64[]
        for k in 0:max_order
            d1 = try; ODEPE.nth_deriv(x -> f1(x), k, tval); catch; NaN; end
            d2 = try; ODEPE.nth_deriv(x -> f2(x), k, tval); catch; NaN; end
            push!(derivs1, d1); push!(derivs2, d2)
        end
        grid_y1[name][tval] = derivs1
        grid_y2[name][tval] = derivs2
    end
    println("done")
end

# Print rel-err grid for y1
println("\n", "="^80)
println("y1 derivative rel-err grid (|interp − truth| / |truth|)")
println("="^80)
for tval in test_ts
    println("\n=== t=$tval ===")
    @printf("%-30s %-12s %-12s %-12s %-12s %-12s\n", "interp", "ord 0", "ord 1", "ord 2", "ord 3", "ord 4")
    for method in interp_methods
        name = ODEPE.interpolator_method_to_symbol(method)
        haskey(grid_y1, name) || continue
        derivs = grid_y1[name][tval]
        rels = Float64[]
        for k in 0:max_order
            ot = oracle_y1[tval][k+1]; it = derivs[k+1]
            r = abs(ot) > 1e-12 ? abs(it - ot) / abs(ot) : abs(it - ot)
            push!(rels, r)
        end
        @printf("%-30s %-12.3g %-12.3g %-12.3g %-12.3g %-12.3g\n",
            string(name), rels[1], rels[2], rels[3], rels[4], rels[5])
    end
end

# y2 grid
println("\n", "="^80)
println("y2 derivative rel-err grid")
println("="^80)
for tval in test_ts
    println("\n=== t=$tval ===")
    @printf("%-30s %-12s %-12s %-12s %-12s %-12s\n", "interp", "ord 0", "ord 1", "ord 2", "ord 3", "ord 4")
    for method in interp_methods
        name = ODEPE.interpolator_method_to_symbol(method)
        haskey(grid_y2, name) || continue
        derivs = grid_y2[name][tval]
        rels = Float64[]
        for k in 0:max_order
            ot = oracle_y2[tval][k+1]; it = derivs[k+1]
            r = abs(ot) > 1e-12 ? abs(it - ot) / abs(ot) : abs(it - ot)
            push!(rels, r)
        end
        @printf("%-30s %-12.3g %-12.3g %-12.3g %-12.3g %-12.3g\n",
            string(name), rels[1], rels[2], rels[3], rels[4], rels[5])
    end
end

println("\nFORCED_LV_GRID_DONE")
