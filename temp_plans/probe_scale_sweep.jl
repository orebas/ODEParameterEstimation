"""
Probe-scale sweep on fitzhugh polish=OFF.

After fixing the parser bug (sigma_d.jl `parse_sensitivity_label` now handles Symbolics
labels), σ_d-aware probes finally fire — but with `probe_scale=1.0` they're tiny (b moves
by ~0.1 from x_c=7.15). Truth is at b=0.887, so the probes don't reach.

This sweep tests whether bumping `sensitivity_seed_probe_scale` lets the L2-projection
reach truth-close points. The L2-projection clamps `t* = clamp(−x_c·u_k, ±probe_scale·σ_k)`,
so a larger scale = larger reach.

Output: a markdown table at
`artifacts/diagnostics/sloppy_seed_probe_scale_sweep.md`.

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/probe_scale_sweep.jl")'
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

function _candidate_max_rel_err(candidate, truth)
    estimated = OrderedDict{Any, Any}()
    for (k, v) in candidate.parameters; estimated[k] = v; end
    for (k, v) in candidate.states; estimated[k] = v; end
    rels = Float64[]
    for (sym, true_val) in truth
        haskey(estimated, sym) || continue
        est_val = Float64(estimated[sym])
        tv = Float64(true_val)
        push!(rels, abs(tv) > 1e-12 ? abs(est_val - tv) / abs(tv) : abs(est_val - tv))
    end
    return isempty(rels) ? NaN : maximum(rels)
end

function _truth_dict(pep)
    truth = OrderedDict{Any, Any}()
    for (k, v) in pep.p_true; truth[k] = v; end
    for (k, v) in pep.ic; truth[k] = v; end
    return truth
end

function _run_one_scale(pep, scale::Float64)
    opts = EstimationOptions(
        interpolator = InterpolatorAAADGPR,
        interpolators = InterpolatorMethod[],
        shooting_points = 3,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = false,  # design intent: no-polish wins
        polish_solver_solutions = false,
        polish_maxiters = 50,
        polish_maxtime = 30.0,
        use_parameter_homotopy = true,
        use_multipoint = true,
        multipoint_n_points = 2,
        multipoint_max_pairs = 4,
        max_solutions = 30,
        noise_level = 1e-4,
        use_sensitivity_seeds = true,
        sensitivity_seed_probe_scale = scale,
        sensitivity_seed_eigenvalue_threshold = 0.01,
    )
    elapsed = @elapsed begin
        results = with_logger(NullLogger()) do
            ODEPE.analyze_parameter_estimation_problem(pep, opts)
        end
    end
    pool = results[1][1]
    truth = _truth_dict(pep)
    finite_rel_rows = [(i, _candidate_max_rel_err(c, truth), c) for (i, c) in enumerate(pool)]
    finite_rel_rows = filter(t -> isfinite(t[2]), finite_rel_rows)
    isempty(finite_rel_rows) && return (scale = scale, oracle_rel = NaN, oracle_idx = -1, oracle_b = NaN, pool_size = length(pool), elapsed = elapsed)
    best = argmin(t -> t[2], finite_rel_rows)
    cand = best[3]
    b_val = haskey(cand.parameters, only(p for (p, _) in pep.p_true if string(p) == "b")) ?
        Float64(cand.parameters[only(p for (p, _) in pep.p_true if string(p) == "b")]) : NaN
    return (
        scale = scale,
        oracle_rel = best[2],
        oracle_idx = best[1],
        oracle_b = b_val,
        pool_size = length(pool),
        elapsed = elapsed,
    )
end

println("Building fitzhugh PEP...")
pep = build_fitzhugh_nagumo_pep()

scales = [1.0, 5.0, 10.0, 50.0, 100.0]
println("Running probe-scale sweep on fitzhugh polish=OFF (truth: g=0.779, a=0.849, b=0.887)...")

rows = []
for s in scales
    println("\n--- probe_scale = $s ---")
    row = _run_one_scale(pep, s)
    println("  pool_size=$(row.pool_size), oracle_rel=$(round(row.oracle_rel; sigdigits=4)), oracle_idx=$(row.oracle_idx), oracle_b=$(round(row.oracle_b; sigdigits=4)), elapsed=$(round(row.elapsed; digits=1))s")
    push!(rows, row)
end

# Write summary
io = IOBuffer()
println(io, "# Probe-Scale Sweep — fitzhugh polish=OFF")
println(io)
println(io, "Tests whether bumping `sensitivity_seed_probe_scale` lets the L2-projection probe")
println(io, "reach truth-near regions on fitzhugh polish=OFF. Truth: `g=0.779, a=0.849, b=0.887`.")
println(io, "Fit-best algebraic candidate has `b=7.15` (very wrong); single-σ_d probe reaches")
println(io, "only `b=7.05` (clipped to ±0.1 ball). Larger scales let the L2-projection clip-toward-zero")
println(io, "logic move further along the sloppy `b` direction.")
println(io)
println(io, "## Results")
println(io)
println(io, "| probe_scale | pool size | oracle-best max-rel-err | oracle-best b | elapsed (s) |")
println(io, "|---:|---:|---:|---:|---:|")
for r in rows
    println(io, "| $(r.scale) | $(r.pool_size) | $(round(r.oracle_rel; sigdigits=4)) | $(round(r.oracle_b; sigdigits=4)) | $(round(r.elapsed; digits=1)) |")
end
println(io)
println(io, "## Reference points")
println(io)
println(io, "- v6 (buggy parser, all-pairs blending): oracle-best rel = **2.54** (b=−1.37)")
println(io, "- post-parser-fix, scale=1.0: oracle-best rel = 6.93 (b=7.04)")
println(io, "- truth: b=0.887")
println(io, "- L2-projection at probe_scale=∞ would land at b=0 (rel ≈ 1.0, the b error rel = 1.0)")

report_path = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sloppy_seed_probe_scale_sweep.md")
mkpath(dirname(report_path))
write(report_path, String(take!(io)))

println("\n=== DONE ===")
println("Report at: $report_path")
println("PROBE_SCALE_SWEEP_DONE")
