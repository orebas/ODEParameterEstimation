"""
Validation run for the sensitivity-seed pipeline (Layer 1 σ_d + Layer 2 wiring).

Compares the existing baseline (use_sensitivity_seeds = false) against the new
sensitivity-aware path (use_sensitivity_seeds = true) on the two cases where
the existing `synthesized_finalizer` had documented wins:

- `fitzhugh_nagumo_2_1em4`: baseline 322.22% → synthesized 1.48%
- `daisy_mamil3_7_1em4`:    baseline 5.46%   → synthesized 0.01%

Output: a markdown summary at
`artifacts/diagnostics/sensitivity_seeds_validation/summary.md`.

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("test/generate_sensitivity_seeds_validation.jl")'
"""

using CSV
using Logging
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Statistics

const ODEPE = ODEParameterEstimation

# ─── Bilby case loaders ────────────────────────────────────────────────────

function _load_bilby_data(case_dir::AbstractString, mq)
    datafile = joinpath(case_dir, "data.csv")
    isfile(datafile) || error("Benchmark dataset not found at $datafile")
    csv_data = CSV.read(datafile, Tuple, header = false)
    data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
    data_sample["t"] = collect(Float64, csv_data[1])
    for (i, eq) in enumerate(mq)
        data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
    end
    return data_sample
end

# ─── Case definitions ──────────────────────────────────────────────────────

function build_daisy_mamil3_pep()
    parameters = @parameters a12 a13 a21 a31 a01
    states = @variables x1(t) x2(t) x3(t)
    observables = @variables y1(t) y2(t)
    state_equations = [
        D(x1) ~ (0.5 * (-1.666 * a01 - a21 - 1.334 * a31) * x1 + 0.334 * a12 * x2 + 0.999 * a13 * x3) / 0.5,
        D(x2) ~ -0.334 * a12 * x2 + 0.5 * a21 * x1,
        D(x3) ~ (-0.999 * a13 * x3 + 0.667 * a31 * x1) / 1.5,
    ]
    measured_quantities = [y1 ~ 0.5 * x1, y2 ~ x2]
    ic = [0.139, 0.303, 0.457]
    p_true = [0.52, 0.7, 0.367, 0.839, 0.79]
    model, mq = ODEPE.create_ordered_ode_system("daisy_mamil3", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "daisy_mamil3_7_1em4",
        model, mq, data_sample, [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

function build_fitzhugh_nagumo_pep()
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

function build_seir_pep()
    parameters = @parameters a b nu
    states = @variables S(t) E(t) In(t) Npop(t)
    observables = @variables y1(t) y2(t)
    state_equations = [
        D(S) ~ (-15840.0 * b * In * S) / (3960000.0 * Npop),
        D(E) ~ ((15840.0 * b * In * S) / (2000.0 * Npop) - 6.0 * nu * E) / 20.0,
        D(In) ~ (-4.0 * a * In + 6.0 * nu * E) / 10.0,
        D(Npop) ~ 0,
    ]
    measured_quantities = [y1 ~ 10.0 * In, y2 ~ 2000.0 * Npop]
    ic = [0.647, 0.182, 0.418, 0.321]
    p_true = [0.187, 0.414, 0.277]
    model, mq = ODEPE.create_ordered_ode_system("seir", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/seir_2_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "seir_2_1em4",
        model, mq, data_sample, [0.0, 60.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

function build_daisy_mamil3_4_pep()
    parameters = @parameters a12 a13 a21 a31 a01
    states = @variables x1(t) x2(t) x3(t)
    observables = @variables y1(t) y2(t)
    state_equations = [
        D(x1) ~ (0.5 * (-1.666 * a01 - a21 - 1.334 * a31) * x1 + 0.334 * a12 * x2 + 0.999 * a13 * x3) / 0.5,
        D(x2) ~ -0.334 * a12 * x2 + 0.5 * a21 * x1,
        D(x3) ~ (-0.999 * a13 * x3 + 0.667 * a31 * x1) / 1.5,
    ]
    measured_quantities = [y1 ~ 0.5 * x1, y2 ~ x2]
    ic = [0.434, 0.205, 0.583]
    p_true = [0.896, 0.461, 0.157, 0.334, 0.222]
    model, mq = ODEPE.create_ordered_ode_system("daisy_mamil3", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_4_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "daisy_mamil3_4_1em4",
        model, mq, data_sample, [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

function build_sirt_treatment_pep()
    parameters = @parameters a b d g nu
    states = @variables In(t) Npop(t) S(t) Tr(t)
    observables = @variables y1(t) y2(t) y3(t)
    state_equations = [
        D(In) ~ 1.52 * b * S * In / Npop + 0.608 * d * b * S * Tr / Npop - (0.2 * a + 0.6 * g) * In,
        D(Npop) ~ 0,
        D(S) ~ -0.08 * b * S * In / Npop - 0.032 * d * b * S * Tr / Npop,
        D(Tr) ~ 6.0 * g * In - 0.2 * nu * Tr,
    ]
    measured_quantities = [y1 ~ 10.0 * Tr, y2 ~ 2000.0 * Npop, y3 ~ 10.0 * In]
    ic = [0.758, 0.66, 0.806, 0.873]
    p_true = [0.715, 0.669, 0.143, 0.417, 0.234]
    model, mq = ODEPE.create_ordered_ode_system("sirt_treatment", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "sirt_treatment_7_1em4",
        model, mq, data_sample, [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

function build_brusselator_pep()
    parameters = @parameters a b
    states = @variables X(t) Yc(t)
    observables = @variables y1(t) y2(t)
    state_equations = [
        D(X) ~ 0.5 - 0.5 * X - 3.0 * b * X + 16.0 * a * Yc * (X^2),
        D(Yc) ~ 6.0 * b * X - 16.0 * a * Yc * (X^2),
    ]
    measured_quantities = [y1 ~ 2.0 * X, y2 ~ 2.0 * Yc]
    ic = [0.858, 0.685]
    p_true = [0.65, 0.272]
    model, mq = ODEPE.create_ordered_ode_system("brusselator", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/brusselator_1_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "brusselator_1_1em4",
        model, mq, data_sample, [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

# ─── Comparison harness ────────────────────────────────────────────────────

function _max_rel_err(estimated::AbstractDict, truth::AbstractDict)
    rels = Float64[]
    for (sym, true_val) in truth
        haskey(estimated, sym) || continue
        est_val = Float64(estimated[sym])
        tv = Float64(true_val)
        if abs(tv) > 1e-12
            push!(rels, abs(est_val - tv) / abs(tv))
        else
            push!(rels, abs(est_val - tv))
        end
    end
    return isempty(rels) ? NaN : maximum(rels)
end

function _candidate_max_rel_err(candidate, truth)
    estimated = OrderedDict{Any, Any}()
    for (k, v) in candidate.parameters; estimated[k] = v; end
    for (k, v) in candidate.states; estimated[k] = v; end
    return _max_rel_err(estimated, truth)
end

function _summarize_run(label::AbstractString, pep, results, elapsed)
    cluster_reps = results[2][1]
    if isempty(cluster_reps)
        return (
            label = label, n_clusters = 0,
            oracle_rel_err = NaN, oracle_fit = NaN,
            fit_rel_err = NaN, fit_best = NaN,
            elapsed = elapsed,
        )
    end
    p_true = pep.p_true
    ic_true = pep.ic
    truth = OrderedDict{Any, Any}()
    for (k, v) in p_true; truth[k] = v; end
    for (k, v) in ic_true; truth[k] = v; end

    # Oracle-best: results[2][1] is sorted by oracle_sort_key (truth-aware) at
    # analysis_utils.jl:421. cluster_reps[1] is the closest-to-truth representative.
    oracle_best = cluster_reps[1]
    oracle_rel = _candidate_max_rel_err(oracle_best, truth)
    oracle_fit = isnothing(oracle_best.err) ? NaN : Float64(oracle_best.err)

    # Fit-best: re-rank the same cluster representatives by err. This is what
    # production code (where p_true is unknown) effectively returns.
    by_err = sort(cluster_reps; by = c -> isnothing(c.err) ? Inf : Float64(c.err))
    fit_best_cand = by_err[1]
    fit_rel = _candidate_max_rel_err(fit_best_cand, truth)
    fit_best = isnothing(fit_best_cand.err) ? NaN : Float64(fit_best_cand.err)

    return (
        label = label,
        n_clusters = length(cluster_reps),
        oracle_rel_err = oracle_rel,
        oracle_fit = oracle_fit,
        fit_rel_err = fit_rel,
        fit_best = fit_best,
        elapsed = elapsed,
    )
end

function _run_arm(pep, arm_label::AbstractString, opts)
    println("\n=== $(pep.name): $arm_label ===")
    elapsed = @elapsed begin
        results = with_logger(NullLogger()) do
            ODEPE.analyze_parameter_estimation_problem(pep, opts)
        end
    end
    summary = _summarize_run(arm_label, pep, results, elapsed)
    println("  clusters=$(summary.n_clusters), oracle_rel_err=$(round(summary.oracle_rel_err; sigdigits=4)), oracle_fit=$(round(summary.oracle_fit; sigdigits=4)), fit_rel_err=$(round(summary.fit_rel_err; sigdigits=4)), fit_best=$(round(summary.fit_best; sigdigits=4)), elapsed=$(round(summary.elapsed; digits=1))s")
    return summary
end

function _run_case(pep, case_label::AbstractString)
    polish_opts = EstimationOptions(
        interpolator = InterpolatorAAADGPR,
        interpolators = InterpolatorMethod[],
        shooting_points = 3,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = true,
        polish_solver_solutions = false,
        polish_maxiters = 50,
        polish_maxtime = 30.0,
        use_parameter_homotopy = true,
        use_multipoint = true,
        multipoint_n_points = 2,
        multipoint_max_pairs = 4,
    )
    no_polish_opts = ODEPE.merge_options(polish_opts; polish_solutions = false)

    polish_baseline = _run_arm(pep, "polish=ON, seeds=OFF", polish_opts)
    polish_seeded = _run_arm(
        pep, "polish=ON, seeds=ON",
        ODEPE.merge_options(polish_opts;
            use_sensitivity_seeds = true,
            sensitivity_seed_probe_scale = 1.0,
            sensitivity_seed_eigenvalue_threshold = 0.01,
        ),
    )
    nopol_baseline = _run_arm(pep, "polish=OFF, seeds=OFF", no_polish_opts)
    nopol_seeded = _run_arm(
        pep, "polish=OFF, seeds=ON",
        ODEPE.merge_options(no_polish_opts;
            use_sensitivity_seeds = true,
            sensitivity_seed_probe_scale = 1.0,
            sensitivity_seed_eigenvalue_threshold = 0.01,
        ),
    )

    return (
        case = case_label,
        polish_baseline = polish_baseline,
        polish_seeded = polish_seeded,
        nopol_baseline = nopol_baseline,
        nopol_seeded = nopol_seeded,
    )
end

function _render_summary(rows)
    io = IOBuffer()
    println(io, "# Sensitivity-Seed Validation Summary")
    println(io)
    println(io, "Compares baseline (`use_sensitivity_seeds = false`) against seeded")
    println(io, "(`use_sensitivity_seeds = true`) on bilby cases. Reports BOTH oracle-best max-rel-err")
    println(io, "(closest to truth — what the test framework returns at `analysis_utils.jl:421`) AND")
    println(io, "fit-best max-rel-err (lowest err — what production code returns when `p_true` is unknown).")
    println(io, "These can diverge sharply on practical-non-identifiable systems.")
    println(io)
    println(io, "## Polish=ON — oracle-best vs fit-best")
    println(io)
    println(io, "| Case | Oracle baseline | Oracle seeded | Δ oracle | Fit baseline | Fit seeded | Δ fit | t base (s) | t seed (s) |")
    println(io, "|------|---:|---:|---:|---:|---:|---:|---:|---:|")
    for r in rows
        b, s = r.polish_baseline, r.polish_seeded
        Δo = b.oracle_rel_err - s.oracle_rel_err
        Δf = b.fit_rel_err - s.fit_rel_err
        println(io, "| $(r.case) | $(round(b.oracle_rel_err; sigdigits=4)) | $(round(s.oracle_rel_err; sigdigits=4)) | $(round(Δo; sigdigits=4)) | $(round(b.fit_rel_err; sigdigits=4)) | $(round(s.fit_rel_err; sigdigits=4)) | $(round(Δf; sigdigits=4)) | $(round(b.elapsed; digits=1)) | $(round(s.elapsed; digits=1)) |")
    end
    println(io)
    println(io, "## Polish=OFF — oracle-best vs fit-best (raw algebraic, the design-intent test)")
    println(io)
    println(io, "| Case | Oracle baseline | Oracle seeded | Δ oracle | Fit baseline | Fit seeded | Δ fit | t base (s) | t seed (s) |")
    println(io, "|------|---:|---:|---:|---:|---:|---:|---:|---:|")
    for r in rows
        b, s = r.nopol_baseline, r.nopol_seeded
        Δo = b.oracle_rel_err - s.oracle_rel_err
        Δf = b.fit_rel_err - s.fit_rel_err
        println(io, "| $(r.case) | $(round(b.oracle_rel_err; sigdigits=4)) | $(round(s.oracle_rel_err; sigdigits=4)) | $(round(Δo; sigdigits=4)) | $(round(b.fit_rel_err; sigdigits=4)) | $(round(s.fit_rel_err; sigdigits=4)) | $(round(Δf; sigdigits=4)) | $(round(b.elapsed; digits=1)) | $(round(s.elapsed; digits=1)) |")
    end
    println(io)
    println(io, "## Cluster counts")
    println(io)
    println(io, "| Case | polish=ON baseline | polish=ON seeded | polish=OFF baseline | polish=OFF seeded |")
    println(io, "|------|---:|---:|---:|---:|")
    for r in rows
        println(io, "| $(r.case) | $(r.polish_baseline.n_clusters) | $(r.polish_seeded.n_clusters) | $(r.nopol_baseline.n_clusters) | $(r.nopol_seeded.n_clusters) |")
    end
    println(io)
    println(io, "## Reference (synthesized_finalizer baseline from `bilby_2026_03_09_1em4_broad_mixed`)")
    println(io)
    println(io, "- `fitzhugh_nagumo_2_1em4`: 322.22% → 1.48% (synthesized_finalizer, against OLD scalar polish)")
    println(io, "- `daisy_mamil3_7_1em4`:    5.46%   → 0.01% (synthesized_finalizer, against OLD scalar polish)")
    return String(take!(io))
end

# ─── Run ───────────────────────────────────────────────────────────────────

println("Loading cases...")
peps = [
    build_fitzhugh_nagumo_pep(),
    build_daisy_mamil3_pep(),
    build_seir_pep(),
    build_daisy_mamil3_4_pep(),
    build_sirt_treatment_pep(),
    build_brusselator_pep(),
]

println("Running validation across $(length(peps)) cases × 4 arms = $(length(peps) * 4) runs...")
rows = NamedTuple[]
for pep in peps
    try
        push!(rows, _run_case(pep, pep.name))
    catch err
        @warn "[Validation] Case $(pep.name) failed: $err"
    end
end

report = _render_summary(rows)
report_path = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sensitivity_seeds_validation", "summary.md")
mkpath(dirname(report_path))
write(report_path, report)

println("\n=== SUMMARY ===")
println(report)
println("\nReport at: $report_path")
println("VALIDATION_DONE")
