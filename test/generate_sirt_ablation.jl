"""
Run exact-case ablations for the benchmark-backed `sirt_treatment_7_1em4` case.

This separates:
- direct polish of imported raw candidates,
- branch consensus without refinement,
- block consensus without polish,
- the existing polished branch/block results for comparison.
"""

using Logging
using ODEParameterEstimation

const ODEPE = ODEParameterEstimation

case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4"
isdir(case_dir) || throw(ArgumentError("Benchmark case not found at $case_dir"))

function _fmt_pct(x)
    return isfinite(x) ? string(round(100 * x; digits = 2), "%") : "Inf"
end

function _fmt_sci(x)
    return isfinite(x) ? string(round(x; sigdigits = 6)) : "Inf"
end

function _candidate_summary(pep, label, candidate)
    truth = ODEPE._candidate_truth_metrics(pep, candidate)
    return (
        label = label,
        fit_error = isnothing(candidate) ? Inf : ODEPE._result_err_key(candidate),
        param_rmse = truth[:parameter_rel_rmse],
        combined_rmse = truth[:combined_rel_rmse],
        lineage = isnothing(candidate) ? "none" : ODEPE.lineage_summary(candidate),
        worst_row = truth[:worst_row],
    )
end

function _summary_row(io, row)
    println(
        io,
        "| `", row.label, "` | ",
        _fmt_sci(row.fit_error), " | ",
        _fmt_pct(row.param_rmse), " | ",
        _fmt_pct(row.combined_rmse), " | ",
        row.lineage, " |",
    )
end

println("Running sirt_treatment exact ablations...")

artifact = with_logger(NullLogger()) do
    loaded = ODEPE._load_bilby_case(case_dir)
    pep = loaded.pep
    base_opts = isnothing(loaded.benchmark_opts) ? ODEPE.EstimationOptions() : loaded.benchmark_opts
    run_opts = ODEPE.merge_options(
        base_opts;
        nooutput = true,
        diagnostics = false,
        save_system = false,
    )

    raw_timed = @timed ODEPE._load_benchmark_result_candidates(pep, run_opts, case_dir)
    raw_candidates = raw_timed.value
    context_timed = @timed ODEPE._build_consensus_context(pep, run_opts)
    context = context_timed.value
    polish_ctx = ODEPE._build_polish_context(pep; opts = run_opts)

    raw71 = raw_candidates[71]
    raw77 = raw_candidates[77]
    polished71_timed = @timed ODEPE._polish_research_seed(pep, raw71, polish_ctx, run_opts)
    polished77_timed = @timed ODEPE._polish_research_seed(pep, raw77, polish_ctx, run_opts)

    branch_no_refine_timed = @timed ODEPE._assemble_branch_consensus_report(
        pep,
        run_opts,
        raw_candidates,
        ODEPE.BranchConsensusOptions(
            support_point_count = 4,
            support_combo_count = 4,
            top_branch_neighbor_count = 3,
            max_refined_seeds = 0,
        );
        context = context,
    )

    block_no_polish_timed = @timed ODEPE._assemble_block_consensus_report(
        pep,
        run_opts,
        raw_candidates,
        ODEPE.BlockConsensusOptions(
            support_point_count = 4,
            support_combo_count = 4,
            max_hypotheses = 12,
            enable_polish = false,
            polish_top_hypotheses = 0,
        );
        context = context,
    )

    rows = [
        _candidate_summary(pep, :raw_71, raw71),
        _candidate_summary(pep, :polished_raw_71, polished71_timed.value),
        _candidate_summary(pep, :raw_77_best_fit, raw77),
        _candidate_summary(pep, :polished_raw_77, polished77_timed.value),
        _candidate_summary(pep, :branch_v1_no_refine, branch_no_refine_timed.value.best_result),
        _candidate_summary(pep, :block_v2_no_polish, block_no_polish_timed.value.best_result),
    ]

    timing = Dict(
        :raw_import_seconds => raw_timed.time,
        :context_seconds => context_timed.time,
        :polish_raw_71_seconds => polished71_timed.time,
        :polish_raw_77_seconds => polished77_timed.time,
        :branch_no_refine_seconds => branch_no_refine_timed.time,
        :block_no_polish_seconds => block_no_polish_timed.time,
    )

    (
        pep = pep,
        rows = rows,
        timing = timing,
    )
end

io = IOBuffer()
println(io, "# SIRT Exact Ablation\n")
println(io, "- Case dir: `", case_dir, "`")
println(io, "- Raw import seconds: ", _fmt_sci(artifact.timing[:raw_import_seconds]))
println(io, "- Context build seconds: ", _fmt_sci(artifact.timing[:context_seconds]), "\n")
println(io, "## Results\n")
println(io, "| Case | Fit Error | Param RMSE | Combined RMSE | Lineage |")
println(io, "|------|-----------|------------|---------------|---------|")
for row in artifact.rows
    _summary_row(io, row)
end
println(io, "\n## Stage Timings\n")
for key in (
    :polish_raw_71_seconds,
    :polish_raw_77_seconds,
    :branch_no_refine_seconds,
    :block_no_polish_seconds,
)
    println(io, "- `", key, "` = ", _fmt_sci(artifact.timing[key]), " s")
end

report = String(take!(io))
report_path = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sirt_treatment_7_1em4", "ablation.md")
mkpath(dirname(report_path))
write(report_path, report)

println(report)
println("Wrote: ", report_path)
