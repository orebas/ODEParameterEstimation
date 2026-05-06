"""
Sloppy-seed mechanism dive — diagnostic script for `temp_plans/`.

For each test case × arm, walks the post-polish candidate pool returned by
`analyze_parameter_estimation_problem` and prints provenance breakdowns:

- How many candidates by `source_type` (`:single_point`, `:multipoint`, `:sensitivity_seed`)?
- How many polished vs. unpolished?
- Which candidate is oracle-best (closest to truth)?
- Which candidate is fit-best (lowest err)?
- Are oracle-best and fit-best the same candidate? Polished?

The cases:
- `fitzhugh_nagumo_2_1em4`, polish=OFF — sensitivity-seed WIN (7.06 → 2.54). What kind of seed produced it?
- `daisy_mamil3_7_1em4`, polish=OFF — non-winner (0.13 → 0.13). Why didn't seeds help on this sloppy case?
- `seir_2_1em4`, polish=ON — alleged "catastrophic" fit (8290 vs baseline 18.19). Is the oracle-best polished?

Re-uses the case builders from `test/generate_sensitivity_seeds_validation.jl`.

Output: a markdown report at
`artifacts/diagnostics/sloppy_seed_mechanism_dive.md`.

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/sloppy_seed_mechanism_dive.jl")'
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

const ODEPE = ODEParameterEstimation

# Inline case builders (copied from test/generate_sensitivity_seeds_validation.jl
# so we don't trigger the full v6 sweep at the bottom of that file).

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

# ─── Helpers ───────────────────────────────────────────────────────────────

"""
Extract truth as a single OrderedDict (params + ICs).
"""
function _truth_dict(pep)
    truth = OrderedDict{Any, Any}()
    for (k, v) in pep.p_true; truth[k] = v; end
    for (k, v) in pep.ic; truth[k] = v; end
    return truth
end

"""
Per-candidate max-rel-err vs. truth (parameters + states only).
"""
function _candidate_max_rel_err(candidate, truth)
    estimated = OrderedDict{Any, Any}()
    for (k, v) in candidate.parameters; estimated[k] = v; end
    for (k, v) in candidate.states; estimated[k] = v; end
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

function _candidate_summary_row(idx, c, truth)
    src = isnothing(c.provenance) ? :unknown : c.provenance.source_type
    polished = isnothing(c.provenance) ? false : c.provenance.polish_applied
    err = isnothing(c.err) ? NaN : Float64(c.err)
    rel = _candidate_max_rel_err(c, truth)
    return (idx = idx, source = src, polished = polished, err = err, rel = rel)
end

function _provenance_breakdown(rows)
    by_src = Dict{Symbol, Tuple{Int, Int}}()  # source => (total, polished)
    for r in rows
        tot, pol = get(by_src, r.source, (0, 0))
        by_src[r.source] = (tot + 1, pol + (r.polished ? 1 : 0))
    end
    return by_src
end

# ─── Per-arm dive ──────────────────────────────────────────────────────────

function _format_param_dict(d::AbstractDict; sigdigits = 4)
    parts = String[]
    for (k, v) in d
        push!(parts, "$(k)=$(round(Float64(v); sigdigits=sigdigits))")
    end
    return join(parts, ", ")
end

function _dive_one_arm(io::IO, pep, arm_label::AbstractString, opts)
    println("\n=== $(pep.name): $arm_label ===")

    elapsed = @elapsed begin
        # Run with logger ON so the [Sensitivity seeds] reports surface.
        results = ODEPE.analyze_parameter_estimation_problem(pep, opts)
    end

    # results is (results_tuple, sorted_cluster_tuple, uq_result) where
    # results_tuple = (solved_res, unident_dict, trivial_dict, all_unidentifiable).
    # We want the raw post-polish candidate pool: results[1][1].
    pool = results[1][1]
    truth = _truth_dict(pep)
    rows = [_candidate_summary_row(i, c, truth) for (i, c) in enumerate(pool)]

    # Identify oracle-best (lowest rel) and fit-best (lowest err) over the WHOLE pool.
    finite_rel = filter(r -> isfinite(r.rel), rows)
    finite_err = filter(r -> isfinite(r.err), rows)
    oracle_best_row = isempty(finite_rel) ? nothing : argmin(r -> r.rel, finite_rel)
    fit_best_row = isempty(finite_err) ? nothing : argmin(r -> r.err, finite_err)

    by_src = _provenance_breakdown(rows)

    println(io, "## $(pep.name): $(arm_label)")
    println(io)
    println(io, "Pool size: $(length(pool)) candidates  (elapsed $(round(elapsed; digits=1))s)")
    println(io)
    println(io, "### Provenance breakdown")
    println(io)
    println(io, "| source_type | total | polished |")
    println(io, "|---|---:|---:|")
    for (src, (tot, pol)) in sort(collect(by_src); by = first)
        println(io, "| `$(src)` | $(tot) | $(pol) |")
    end
    println(io)

    if !isnothing(oracle_best_row)
        c = pool[oracle_best_row.idx]
        println(io, "### Oracle-best (closest to truth)")
        println(io)
        println(io, "- pool index: $(oracle_best_row.idx)")
        println(io, "- source_type: `$(oracle_best_row.source)`")
        println(io, "- polish_applied: $(oracle_best_row.polished)")
        println(io, "- err: $(round(oracle_best_row.err; sigdigits=4))")
        println(io, "- max-rel-err: $(round(oracle_best_row.rel; sigdigits=4))")
        println(io, "- parameters: `$(_format_param_dict(c.parameters))`")
        println(io, "- states:     `$(_format_param_dict(c.states))`")
        println(io)
    else
        println(io, "### Oracle-best: NONE (no finite max-rel-err)")
        println(io)
    end

    if !isnothing(fit_best_row)
        c = pool[fit_best_row.idx]
        println(io, "### Fit-best (lowest trajectory residual)")
        println(io)
        println(io, "- pool index: $(fit_best_row.idx)")
        println(io, "- source_type: `$(fit_best_row.source)`")
        println(io, "- polish_applied: $(fit_best_row.polished)")
        println(io, "- err: $(round(fit_best_row.err; sigdigits=4))")
        println(io, "- max-rel-err: $(round(fit_best_row.rel; sigdigits=4))")
        println(io, "- parameters: `$(_format_param_dict(c.parameters))`")
        println(io, "- states:     `$(_format_param_dict(c.states))`")
        println(io)
    else
        println(io, "### Fit-best: NONE (no finite err)")
        println(io)
    end

    if !isnothing(oracle_best_row) && !isnothing(fit_best_row)
        same = oracle_best_row.idx == fit_best_row.idx
        println(io, "**Oracle-best == Fit-best?** $(same ? "YES" : "NO")")
        println(io)
        if !same
            # Tell us how far off fit-best is from truth.
            println(io, "If we had picked fit-best instead of oracle-best, max-rel-err would be **$(round(fit_best_row.rel; sigdigits=4))** (vs oracle-best's $(round(oracle_best_row.rel; sigdigits=4))).")
            println(io)
        end
    end

    # Print top 8 by source/polish/rel so we can eyeball the geometry.
    println(io, "### Top candidates by max-rel-err (best 8)")
    println(io)
    println(io, "| idx | source | polished | err | max-rel-err |")
    println(io, "|---:|---|---|---:|---:|")
    sorted = sort(rows; by = r -> isfinite(r.rel) ? r.rel : Inf)
    for r in first(sorted, min(8, length(sorted)))
        println(io, "| $(r.idx) | `$(r.source)` | $(r.polished) | $(round(r.err; sigdigits=4)) | $(round(r.rel; sigdigits=4)) |")
    end
    println(io)
    println(io, "### Top candidates by err (lowest 8)")
    println(io)
    println(io, "| idx | source | polished | err | max-rel-err |")
    println(io, "|---:|---|---|---:|---:|")
    sorted_by_err = sort(rows; by = r -> isfinite(r.err) ? r.err : Inf)
    for r in first(sorted_by_err, min(8, length(sorted_by_err)))
        println(io, "| $(r.idx) | `$(r.source)` | $(r.polished) | $(round(r.err; sigdigits=4)) | $(round(r.rel; sigdigits=4)) |")
    end
    println(io)

    return (
        case = pep.name, arm = arm_label,
        oracle = oracle_best_row, fit = fit_best_row,
        breakdown = by_src,
    )
end

# ─── Driver ────────────────────────────────────────────────────────────────

function _build_arm_opts(; polish::Bool, seeds::Bool)
    base = EstimationOptions(
        interpolator = InterpolatorAAADGPR,
        interpolators = InterpolatorMethod[],
        shooting_points = 3,
        nooutput = false,
        diagnostics = false,
        save_system = false,
        polish_solutions = polish,
        polish_solver_solutions = false,
        polish_maxiters = 50,
        polish_maxtime = 30.0,
        use_parameter_homotopy = true,
        use_multipoint = true,
        multipoint_n_points = 2,
        multipoint_max_pairs = 4,
        max_solutions = 30,
        noise_level = 1e-4,  # bilby cases are 1e-4 noise; without this, σ_d falls through to 0
    )
    return ODEPE.merge_options(base;
        use_sensitivity_seeds = seeds,
        sensitivity_seed_probe_scale = 1.0,
        sensitivity_seed_eigenvalue_threshold = 0.01,
    )
end

println("Loading PEPs for mechanism dive (3 cases, 1-2 arms each)...")
peps = Dict(
    "fitzhugh" => build_fitzhugh_nagumo_pep(),
    "daisy"    => build_daisy_mamil3_pep(),
    "seir"     => build_seir_pep(),
)

io = IOBuffer()
println(io, "# Sloppy-Seed Mechanism Dive")
println(io)
println(io, "Walks the post-polish candidate pool of cases where the v6 sweep showed surprising results.")
println(io, "Each candidate carries a `provenance.source_type` (`:single_point` / `:multipoint` /")
println(io, "`:sensitivity_seed`) and `provenance.polish_applied`. Tagging the oracle-best and fit-best")
println(io, "tells us mechanically what kind of candidate is winning, and whether it's polished.")
println(io)
println(io, "## Cases")
println(io)
println(io, "- **fitzhugh_nagumo_2_1em4 polish=OFF**: v6 said 7.06 → 2.54 (oracle-best). What seed produced it?")
println(io, "- **daisy_mamil3_7_1em4 polish=OFF**: v6 said 0.13 → 0.13 (no movement). Why didn't seeds help?")
println(io, "- **seir_2_1em4 polish=ON**: v6 said oracle-best fit went 18.19 → 8290 — \"catastrophic\". Is the oracle-best a polished result or an unpolished seed?")
println(io)

results_log = []

# Arm 1: fitzhugh polish=OFF (the winner — what seed produced it?)
push!(results_log, _dive_one_arm(io, peps["fitzhugh"], "polish=OFF, seeds=ON",
    _build_arm_opts(polish = false, seeds = true)))

# Arm 2: daisy polish=OFF (non-winner — why no movement?)
push!(results_log, _dive_one_arm(io, peps["daisy"], "polish=OFF, seeds=ON",
    _build_arm_opts(polish = false, seeds = true)))

# Arm 3: seir polish=ON (catastrophic-fit question)
push!(results_log, _dive_one_arm(io, peps["seir"], "polish=ON, seeds=ON",
    _build_arm_opts(polish = true, seeds = true)))

# ─── Write report ──────────────────────────────────────────────────────────

println(io, "---")
println(io)
println(io, "## Quick takeaways")
println(io)
for r in results_log
    if isnothing(r.oracle) || isnothing(r.fit)
        println(io, "- **$(r.case) / $(r.arm)**: no finite oracle-best or fit-best found.")
        continue
    end
    is_seed_oracle = r.oracle.source == :sensitivity_seed
    is_polished_oracle = r.oracle.polished
    is_seed_fit = r.fit.source == :sensitivity_seed
    is_polished_fit = r.fit.polished
    line = "- **$(r.case) / $(r.arm)**: oracle-best is $(is_seed_oracle ? "a seed" : "an algebraic candidate") ($(is_polished_oracle ? "polished" : "unpolished"), err=$(round(r.oracle.err; sigdigits=3)), rel=$(round(r.oracle.rel; sigdigits=3))). " *
        "Fit-best is $(is_seed_fit ? "a seed" : "an algebraic candidate") ($(is_polished_fit ? "polished" : "unpolished"), err=$(round(r.fit.err; sigdigits=3)), rel=$(round(r.fit.rel; sigdigits=3)))."
    println(io, line)
end

report_path = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sloppy_seed_mechanism_dive.md")
mkpath(dirname(report_path))
write(report_path, String(take!(io)))

println("\n=== DONE ===")
println("Report at: $report_path")
println("MECHANISM_DIVE_DONE")
