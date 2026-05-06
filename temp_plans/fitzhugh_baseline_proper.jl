"""
E1 — Re-establish the proper baseline for fitzhugh polish=OFF using the bilby config.

Mimics `benchmark_bilby_2026_03_09/.../fitzhugh_nagumo_2_1em4/script.jl` exactly.
Captures the raw pool (with provenance) and the sorted cluster reps.

Verification target: 186 cluster reps, best max-rel-err ≈ 0.1155 (matching bilby's
result.csv numbers).

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/fitzhugh_baseline_proper.jl")'
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
const OUTDIR = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "fitzhugh_deep_dive")
mkpath(OUTDIR)

# ─── Case loader (matches bilby) ──────────────────────────────────────────────────

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

# ─── Bilby exact config ────────────────────────────────────────────────────────────

function bilby_opts(pep)
    return EstimationOptions(
        datasize = length(pep.data_sample["t"]),
        noise_level = 0.000,
        system_solver = SolverHC,
        flow = FlowStandard,
        use_si_template = true,
        interpolators = InterpolatorMethod[
            InterpolatorAAAD,
            InterpolatorAAADGPR,
            InterpolatorS2AAAMLE,
            InterpolatorAGPRobust,
            InterpolatorAGPRobustRQ,
            InterpolatorAGPRobustSEpRQ,
            InterpolatorAGPRobustSExRQ,
            InterpolatorS3SE,
            InterpolatorS3RQ,
            InterpolatorS3SEpRQ,
            InterpolatorS3SExRQ,
            InterpolatorFHD,
        ],
        shooting_points = 12,
        shooting_warp = true,
        shooting_warp_beta = 3.0,
        use_parameter_homotopy = true,
        polish_solver_solutions = true,
        polish_solutions = false,
        polish_maxiters = 5000,
        polish_method = PolishBFGS,
        abstol = 1e-13,
        reltol = 1e-13,
        polish_maxtime = 1200.0,
        polish_divergence_factor = 10.0,
        polish_stagnation_window = 50,
        polish_ode_maxiters = 20000,
        diagnostics = false,  # bilby has true; we don't need the report for E1
        nooutput = true,
        save_system = false,
        use_sensitivity_seeds = false,
    )
end

# ─── Helpers ───────────────────────────────────────────────────────────────────────

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

# ─── Run ──────────────────────────────────────────────────────────────────────────

println("="^72)
println("E1: fitzhugh polish=OFF at the actual bilby config")
println("="^72)

pep = build_fitzhugh()
opts = bilby_opts(pep)

println("Config: shooting_points=$(opts.shooting_points), warp=$(opts.shooting_warp), beta=$(opts.shooting_warp_beta)")
println("Interpolators: $(length(opts.interpolators))")
println("polish_solver_solutions=$(opts.polish_solver_solutions), polish_solutions=$(opts.polish_solutions)")

println("\nRunning pipeline (this will take ~10-20 min on a multi-core box)...")
flush(stdout)
elapsed = @elapsed begin
    results = with_logger(NullLogger()) do
        ODEPE.analyze_parameter_estimation_problem(pep, opts)
    end
end

println("Done in $(round(elapsed; digits=1))s.")

# Unpack: (results_tuple, results_tuple_to_return, uq_result)
results_tuple = results[1]
results_tuple_to_return = results[2]

raw_pool = results_tuple[1]                         # vector of every candidate post-everything
cluster_reps = results_tuple_to_return[1]           # cluster representatives, sorted by oracle_sort_key
besterror = results_tuple_to_return[2]
best_max_error = results_tuple_to_return[6]

println("\n--- E1 sanity check ---")
println("Total raw candidates in pool:  $(length(raw_pool))")
println("Cluster representatives:       $(length(cluster_reps))")
@printf("Best approximation error:      %.6g\n", besterror)
@printf("Best max-rel-err (overall):    %.6g\n", best_max_error)

# Truth dict for per-candidate rel-err
truth = OrderedDict{Any, Any}()
for (k, v) in pep.p_true; truth[k] = v; end
for (k, v) in pep.ic; truth[k] = v; end

raw_rels = [_max_rel_err(c, truth) for c in raw_pool]
finite_rels = filter(isfinite, raw_rels)
if !isempty(finite_rels)
    @printf("Raw pool best max-rel-err:      %.6g\n", minimum(finite_rels))
    @printf("Raw pool median max-rel-err:    %.6g\n", median(finite_rels))
    println("Raw pool size with finite rel:  $(length(finite_rels))")

    # Distribution
    println("\nRaw pool max-rel-err distribution:")
    for thresh in [0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0]
        n = count(r -> r < thresh, finite_rels)
        @printf("  rel < %-6.4g : %d / %d  (%.1f%%)\n", thresh, n, length(finite_rels), 100*n/length(finite_rels))
    end
end

cluster_rels = [_max_rel_err(c, truth) for c in cluster_reps]
finite_cluster_rels = filter(isfinite, cluster_rels)
if !isempty(finite_cluster_rels)
    @printf("\nCluster reps best max-rel-err:  %.6g\n", minimum(finite_cluster_rels))
    @printf("Cluster reps median max-rel-err: %.6g\n", median(finite_cluster_rels))
end

# Compare to bilby ground truth
println("\n--- Verification vs bilby's result.csv ---")
println("Bilby cluster count:    186")
println("Bilby best max-rel-err: 0.115505")
@printf("Mine cluster count:     %d  (%s)\n",
    length(cluster_reps),
    abs(length(cluster_reps) - 186) <= 5 ? "✓ within ±5" : "✗ MISMATCH")
@printf("Mine best max-rel-err:  %.6g  (%s)\n",
    minimum(finite_cluster_rels),
    abs(minimum(finite_cluster_rels) - 0.1155) < 0.05 ? "✓ within 0.05" : "✗ MISMATCH")


# ─── E2: Where does the best candidate come from? ─────────────────────────────────

println("\n", "="^72)
println("E2: Provenance of best candidates")
println("="^72)

function _row(i, c, truth)
    src = isnothing(c.provenance) ? :unknown : c.provenance.source_type
    sp = isnothing(c.provenance) ? nothing : c.provenance.source_shooting_index
    interp = isnothing(c.provenance) ? nothing : c.provenance.interpolator_source
    mp_idx = isnothing(c.provenance) ? nothing : c.provenance.multipoint_combo_index
    mp_times = isnothing(c.provenance) ? nothing : c.provenance.multipoint_time_indices
    polished = isnothing(c.provenance) ? false : c.provenance.polish_applied
    g_v = NaN; a_v = NaN; b_v = NaN
    for (k, v) in c.parameters
        s = string(k)
        if s == "g"; g_v = Float64(v)
        elseif s == "a"; a_v = Float64(v)
        elseif s == "b"; b_v = Float64(v)
        end
    end
    Vm_v = NaN; R_v = NaN
    for (k, v) in c.states
        s = string(k)
        if s == "Vm(t)"; Vm_v = Float64(v)
        elseif s == "R(t)"; R_v = Float64(v)
        end
    end
    return (
        idx = i,
        src = src, sp = sp, interp = interp, mp_idx = mp_idx, mp_times = mp_times, polished = polished,
        g = g_v, a = a_v, b = b_v, Vm = Vm_v, R = R_v,
        rel = _max_rel_err(c, truth),
        err = isnothing(c.err) ? NaN : Float64(c.err),
    )
end

rows = [_row(i, c, truth) for (i, c) in enumerate(raw_pool)]
finite_rows = filter(r -> isfinite(r.rel), rows)

# ── Top 20 by rel-err ─────────────────────────────
println("\nTop 20 candidates by max-rel-err (best first):")
sorted = sort(finite_rows; by = r -> r.rel)
@printf("%-4s %-15s %-25s %-4s %-3s %-15s %-3s %-9s %-9s %-9s %-9s %-9s %-9s %-9s\n",
    "idx", "src", "interp", "pol", "sp", "mp_times", "mp", "g", "a", "b", "Vm", "R", "rel", "err")
for r in first(sorted, 20)
    @printf("%-4d %-15s %-25s %-4s %-3s %-15s %-3s %-9.4g %-9.4g %-9.4g %-9.4g %-9.4g %-9.4g %-9.4g\n",
        r.idx, string(r.src), string(r.interp),
        r.polished ? "yes" : "no",
        isnothing(r.sp) ? "-" : string(r.sp),
        isnothing(r.mp_times) ? "-" : string(r.mp_times),
        isnothing(r.mp_idx) ? "-" : string(r.mp_idx),
        r.g, r.a, r.b, r.Vm, r.R, r.rel, r.err)
end

# ── Per-interpolator breakdown ────────────────────
println("\nPer-interpolator breakdown:")
@printf("%-30s %-8s %-8s %-12s %-12s\n", "interpolator", "count", "polished", "best_rel", "median_rel")
interp_groups = Dict{Symbol, Vector}()
for r in finite_rows
    ip = isnothing(r.interp) ? :unknown : r.interp
    push!(get!(interp_groups, ip, Vector{Any}()), r)
end
interp_order = sort(collect(keys(interp_groups)); by = k -> begin
    g = interp_groups[k]
    minimum(r.rel for r in g)
end)
for ip in interp_order
    g = interp_groups[ip]
    n = length(g)
    n_pol = count(r -> r.polished, g)
    rels = [r.rel for r in g]
    @printf("%-30s %-8d %-8d %-12.4g %-12.4g\n",
        string(ip), n, n_pol, minimum(rels), median(rels))
end

# ── Per-source-type breakdown ─────────────────────
println("\nPer-source-type breakdown:")
@printf("%-20s %-8s %-12s %-12s\n", "source_type", "count", "best_rel", "median_rel")
src_groups = Dict{Symbol, Vector}()
for r in finite_rows
    push!(get!(src_groups, r.src, Vector{Any}()), r)
end
for st in sort(collect(keys(src_groups)))
    g = src_groups[st]
    rels = [r.rel for r in g]
    @printf("%-20s %-8d %-12.4g %-12.4g\n",
        string(st), length(g), minimum(rels), median(rels))
end

# ── Per-shooting-point breakdown (single-point only) ─
println("\nPer-shooting-point breakdown (single_point candidates only):")
@printf("%-8s %-8s %-12s %-12s\n", "sp_idx", "count", "best_rel", "median_rel")
sp_groups = Dict{Int, Vector}()
for r in finite_rows
    if r.src == :single_point && !isnothing(r.sp)
        push!(get!(sp_groups, r.sp, Vector{Any}()), r)
    end
end
for sp in sort(collect(keys(sp_groups)))
    g = sp_groups[sp]
    rels = [r.rel for r in g]
    @printf("%-8d %-8d %-12.4g %-12.4g\n", sp, length(g), minimum(rels), median(rels))
end

# ── Per-MP-combo breakdown ────────────────────────
println("\nPer-MP-combo breakdown (multipoint candidates only):")
@printf("%-15s %-8s %-12s %-12s\n", "mp_times", "count", "best_rel", "median_rel")
mp_groups = Dict{String, Vector}()
for r in finite_rows
    if r.src == :multipoint && !isnothing(r.mp_times)
        key = string(r.mp_times)
        push!(get!(mp_groups, key, Vector{Any}()), r)
    end
end
for k in sort(collect(keys(mp_groups)); by = s -> minimum(r.rel for r in mp_groups[s]))
    g = mp_groups[k]
    rels = [r.rel for r in g]
    @printf("%-15s %-8d %-12.4g %-12.4g\n", k, length(g), minimum(rels), median(rels))
end

# ── Save the full per-candidate table to CSV for E3+ ──
csv_path = joinpath(OUTDIR, "proper_pool_candidates.csv")
open(csv_path, "w") do io
    println(io, "idx,src,interp,polished,sp,mp_times,mp_idx,g,a,b,Vm,R,rel,err")
    for r in rows
        println(io, "$(r.idx),$(r.src),$(r.interp),$(r.polished),",
            "$(isnothing(r.sp) ? "" : r.sp),",
            "$(isnothing(r.mp_times) ? "" : replace(string(r.mp_times), ","=>"|")),",
            "$(isnothing(r.mp_idx) ? "" : r.mp_idx),",
            "$(r.g),$(r.a),$(r.b),$(r.Vm),$(r.R),$(r.rel),$(r.err)")
    end
end
println("\nSaved per-candidate CSV to: $csv_path")

println("\nE1_DONE")
