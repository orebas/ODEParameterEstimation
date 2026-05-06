"""
Multi-interpolator run on fitzhugh polish=OFF.

Hypothesis: the previous deep-dive used ONE interpolator (InterpolatorAAADGPR). Production
default uses 9. Pure GP and pure AAA may produce different (better?) candidates because
they have different derivative-error structures, especially at boundaries.

Output: pool composition + best-rel-err per interpolator.

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/fitzhugh_multi_interp.jl")'
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

function _max_rel_err(c, truth)
    estimated = OrderedDict{Any, Any}()
    for (k, v) in c.parameters; estimated[k] = v; end
    for (k, v) in c.states; estimated[k] = v; end
    rels = Float64[]
    for (sym, true_val) in truth
        haskey(estimated, sym) || continue
        est_val = Float64(estimated[sym])
        tv = Float64(true_val)
        push!(rels, abs(tv) > 1e-12 ? abs(est_val - tv) / abs(tv) : abs(est_val - tv))
    end
    return isempty(rels) ? NaN : maximum(rels)
end

# ─── Run with various interpolator configurations ─────────────────────────────────

pep = build_fitzhugh()
truth = OrderedDict{Any, Any}()
for (k, v) in pep.p_true; truth[k] = v; end
for (k, v) in pep.ic; truth[k] = v; end

base_opts = (
    shooting_points = 3,
    nooutput = true,
    diagnostics = false,
    save_system = false,
    polish_solutions = false,
    polish_solver_solutions = false,
    polish_maxiters = 50,
    polish_maxtime = 30.0,
    use_parameter_homotopy = true,
    use_multipoint = true,
    multipoint_n_points = 2,
    multipoint_max_pairs = 4,
    max_solutions = 30,
    use_sensitivity_seeds = false,
)

# Configurations to compare
configs = [
    (label = "Single AAADGPR (was production default)",
     opts_overrides = (interpolator = InterpolatorAAADGPR, interpolators = InterpolatorMethod[])),
    (label = "Single AAAD (pure rational)",
     opts_overrides = (interpolator = InterpolatorAAAD, interpolators = InterpolatorMethod[])),
    (label = "Single AGPRobust (pure GP/SE)",
     opts_overrides = (interpolator = InterpolatorAGPRobust, interpolators = InterpolatorMethod[])),
    (label = "Single AGPRobustMatern52",
     opts_overrides = (interpolator = InterpolatorAGPRobustMatern52, interpolators = InterpolatorMethod[])),
    (label = "Single AGPRobustSExRQ",
     opts_overrides = (interpolator = InterpolatorAGPRobustSExRQ, interpolators = InterpolatorMethod[])),
    (label = "Multi (AAAD + AGPRobust + AAADGPR)",
     opts_overrides = (interpolator = InterpolatorAAADGPR,
                       interpolators = InterpolatorMethod[InterpolatorAAAD, InterpolatorAGPRobust, InterpolatorAAADGPR])),
    (label = "Multi (full default 9-interpolator set)",
     opts_overrides = (interpolator = InterpolatorAAADGPR,
                       interpolators = InterpolatorMethod[
                           InterpolatorAGPRobust, InterpolatorAGPRobustSExRQ,
                           InterpolatorS3AdaptSE, InterpolatorS3AdaptSExRQ,
                           InterpolatorChebyshevBIC, InterpolatorChebyshevAICc,
                           InterpolatorAAADGPR, InterpolatorAAAD, InterpolatorS2AAAMLE,
                       ])),
]

results_log = []
for cfg in configs
    println("\n", "="^72)
    println("Config: $(cfg.label)")
    println("="^72)
    opts = EstimationOptions(; base_opts..., cfg.opts_overrides...)
    elapsed = @elapsed begin
        results = with_logger(NullLogger()) do
            ODEPE.analyze_parameter_estimation_problem(pep, opts)
        end
    end
    pool = results[1][1]
    rels = [_max_rel_err(c, truth) for c in pool]
    finite_rels = filter(isfinite, rels)
    best_rel = isempty(finite_rels) ? NaN : minimum(finite_rels)
    median_rel = isempty(finite_rels) ? NaN : median(finite_rels)

    # Per-interpolator breakdown of the pool
    interp_counts = Dict{Symbol, Int}()
    interp_best = Dict{Symbol, Float64}()
    for (i, c) in enumerate(pool)
        ip = isnothing(c.provenance) ? :unknown : something(c.provenance.interpolator_source, :unknown)
        interp_counts[ip] = get(interp_counts, ip, 0) + 1
        cur_rel = rels[i]
        if isfinite(cur_rel)
            interp_best[ip] = min(get(interp_best, ip, Inf), cur_rel)
        end
    end

    @printf("Elapsed: %.1fs, pool size: %d\n", elapsed, length(pool))
    @printf("Best rel-err:   %.4g\n", best_rel)
    @printf("Median rel-err: %.4g\n", median_rel)
    println("Per-interpolator breakdown:")
    for ip in sort(collect(keys(interp_counts)))
        bb = get(interp_best, ip, NaN)
        @printf("  %-30s : %d candidates, best rel = %.4g\n", string(ip), interp_counts[ip], bb)
    end

    push!(results_log, (
        label = cfg.label,
        elapsed = elapsed,
        pool_size = length(pool),
        best_rel = best_rel,
        median_rel = median_rel,
        interp_counts = interp_counts,
        interp_best = interp_best,
    ))
end

# Summary table
println("\n", "="^72)
println("SUMMARY")
println("="^72)
@printf("%-50s %-10s %-15s %-15s %-15s\n", "Config", "elapsed", "pool size", "best rel", "median rel")
for r in results_log
    @printf("%-50s %-10.1f %-15d %-15.4g %-15.4g\n",
        r.label, r.elapsed, r.pool_size, r.best_rel, r.median_rel)
end

println("\nMULTI_INTERP_DONE")
