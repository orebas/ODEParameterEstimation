"""
Generate a bilby 1e-4 broad-mixed sweep comparing:
- best-fit baseline
- family consensus (v0)
- synthesized finalizer (v0)
- branch consensus v1

Optional environment variables:
- ODEPE_SWEEP_CASE_LIMIT
- ODEPE_SWEEP_CASE_IDS (comma-separated)
"""

using Dates
using Logging
using ODEParameterEstimation
using OrderedCollections

const ODEPE = ODEParameterEstimation

const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sweeps", "bilby_2026_03_09_1em4_branch_v1")

case_limit = let raw = get(ENV, "ODEPE_SWEEP_CASE_LIMIT", "")
    isempty(strip(raw)) ? nothing : parse(Int, strip(raw))
end

requested_case_ids = let raw = get(ENV, "ODEPE_SWEEP_CASE_IDS", "")
    isempty(strip(raw)) ? String[] : [String(strip(part)) for part in split(raw, ',') if !isempty(strip(part))]
end

function branch_hypothesis_rows(report::ODEPE.BranchConsensusReport)
    rows = NamedTuple[]
    limit = min(length(report.branch_hypotheses), 5)
    for branch in report.branch_hypotheses[1:limit]
        push!(rows, (
            rank = branch.branch_index,
            member_count = length(branch.member_indices),
            branch_score = branch.branch_score,
            representative_index = branch.representative_candidate_index,
            best_fit_index = branch.best_fit_candidate_index,
            best_equation_index = branch.best_equation_candidate_index,
            source_types = isempty(branch.distinct_source_types) ? "none" : join(string.(branch.distinct_source_types), ", "),
            interpolators = isempty(branch.distinct_interpolators) ? "none" : join(string.(branch.distinct_interpolators), ", "),
            shooting_support = isempty(branch.distinct_shooting_support) ? "none" : join(string.(branch.distinct_shooting_support), ", "),
            combo_support = isempty(branch.distinct_combo_support) ? "none" : join(string.(branch.distinct_combo_support), ", "),
            confidence_tier = branch.confidence_tier,
            refined = !isnothing(branch.refined_candidate),
        ))
    end
    return rows
end

function branch_strategy_summary(
    pep::ODEPE.ParameterEstimationProblem,
    report::ODEPE.BranchConsensusReport,
    selection_seconds::Float64,
    shared_seconds::Float64,
    t_vector::Vector{Float64},
)
    best_branch = isnothing(report.best_branch_index) ? nothing : report.branch_hypotheses[report.best_branch_index]
    raw_candidate = isnothing(best_branch) ? nothing : best_branch.representative_candidate
    final_candidate = report.best_result
    raw_truth = ODEPE._candidate_truth_metrics(pep, raw_candidate)
    final_truth = ODEPE._candidate_truth_metrics(pep, final_candidate)
    evidence = isnothing(best_branch) || isnothing(best_branch.representative_candidate_index) ? nothing :
        ODEPE._candidate_evidence_dict(report.candidate_evidence[best_branch.representative_candidate_index])

    return Dict{Symbol, Any}(
        :strategy => :branch_consensus_v1,
        :status => :ok,
        :selection_seconds => selection_seconds,
        :effective_total_seconds => shared_seconds + selection_seconds,
        :candidate_count => length(report.raw_candidates),
        :family_count => length(report.branch_hypotheses),
        :winner_mode => isnothing(best_branch) ? :missing : (isnothing(best_branch.refined_candidate) ? :raw : :refined),
        :raw_winner_lineage => isnothing(raw_candidate) ? "none" : lineage_summary(raw_candidate),
        :final_winner_lineage => isnothing(final_candidate) ? "none" : lineage_summary(final_candidate),
        :raw_winner_fit_error => isnothing(raw_candidate) ? Inf : ODEPE._result_err_key(raw_candidate),
        :final_winner_fit_error => isnothing(final_candidate) ? Inf : ODEPE._result_err_key(final_candidate),
        :raw_winner_score => isnothing(best_branch) ? Inf : best_branch.branch_score,
        :final_winner_score => isnothing(best_branch) ? Inf : best_branch.branch_score,
        :support_points => copy(report.support_points),
        :support_point_times => ODEPE._consensus_support_times(t_vector, report.support_points),
        :support_combos => deepcopy(report.support_combos),
        :support_combo_times => ODEPE._consensus_support_combo_times(t_vector, report.support_combos),
        :parameter_rows => final_truth[:parameter_rows],
        :state_rows => final_truth[:state_rows],
        :truth_metrics => final_truth,
        :raw_truth_metrics => raw_truth,
        :winner_evidence => evidence,
        :raw_winner_evidence => evidence,
        :top_families => branch_hypothesis_rows(report),
        :best_branch_index => report.best_branch_index,
        :adaptive_k => report.adaptive_k,
        :guard_applied => get(report.scoring_summary, :guard_applied, false),
        :version_label => report.version_label,
    )
end

function method_failure_summary(strategy::Symbol, err, shared_seconds::Float64, raw_candidate_count::Int, family_count::Int)
    return Dict{Symbol, Any}(
        :strategy => strategy,
        :status => :error,
        :error_message => sprint(showerror, err),
        :selection_seconds => NaN,
        :effective_total_seconds => shared_seconds,
        :candidate_count => raw_candidate_count,
        :family_count => family_count,
        :winner_mode => :missing,
        :raw_winner_lineage => "none",
        :final_winner_lineage => "none",
        :raw_winner_fit_error => Inf,
        :final_winner_fit_error => Inf,
        :raw_winner_score => Inf,
        :final_winner_score => Inf,
        :support_points => Int[],
        :support_point_times => Float64[],
        :support_combos => Vector{Vector{Int}}(),
        :support_combo_times => Vector{Vector{Float64}}(),
        :parameter_rows => NamedTuple[],
        :state_rows => NamedTuple[],
        :truth_metrics => Dict{Symbol, Any}(
            :parameter_rel_rmse => Inf,
            :state_rel_rmse => Inf,
            :combined_rel_rmse => Inf,
            :all_rows => NamedTuple[],
        ),
        :raw_truth_metrics => Dict{Symbol, Any}(),
        :winner_evidence => nothing,
        :raw_winner_evidence => nothing,
        :top_families => NamedTuple[],
    )
end

function strategy_shift_rows(case_artifact::Dict{Symbol, Any})
    baseline = case_artifact[:strategies][:best_fit_baseline]
    rows = NamedTuple[]
    for strategy_key in (:family_consensus, :synthesized_finalizer, :branch_consensus_v1)
        summary = case_artifact[:strategies][strategy_key]
        push!(rows, (
            strategy = strategy_key,
            fit_delta = ODEPE._summary_fit_error(baseline) - ODEPE._summary_fit_error(summary),
            parameter_rmse_delta = ODEPE._summary_parameter_rmse(baseline) - ODEPE._summary_parameter_rmse(summary),
            combined_rmse_delta = ODEPE._summary_combined_rmse(baseline) - ODEPE._summary_combined_rmse(summary),
            best_gain = ODEPE._summary_biggest_shift(baseline, summary; direction = :improvement),
            worst_regression = ODEPE._summary_biggest_shift(baseline, summary; direction = :worsening),
        ))
    end
    return rows
end

function best_strategy_key(case_artifact::Dict{Symbol, Any})
    strategies = case_artifact[:strategies]
    keys = (:best_fit_baseline, :family_consensus, :synthesized_finalizer, :branch_consensus_v1)
    best_key = first(keys)
    best_rmse = Inf
    for key in keys
        rmse = ODEPE._summary_combined_rmse(strategies[key])
        if rmse < best_rmse
            best_rmse = rmse
            best_key = key
        end
    end
    return best_key
end

function render_case_markdown(case_artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "# Branch v1 Sweep Case: $(case_artifact[:case_id])\n")
    println(io, "- Model: `$(case_artifact[:model_name])`")
    println(io, "- Bucket: `$(case_artifact[:bucket_label])`")
    println(io, "- Selected via: `$(case_artifact[:selected_via])`")
    println(io, "- Generated: `$(case_artifact[:generated_at])`")
    println(io, "- Status: `$(case_artifact[:status])`")
    println(io, "- Case dir: `$(case_artifact[:case_dir])`\n")

    ref = case_artifact[:benchmark_reference]
    println(io, "## Benchmark Reference\n")
    println(io, "| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |")
    println(io, "|------------|--------------|-------------|-----------|---------|")
    println(io, "| `amigo2_run` | $(ODEPE._fmt_percent(ref.mean_rel_error_a)) | $(ODEPE._fmt_percent(ref.max_rel_error_a)) | $(ODEPE._fmt_float(ref.time_a; digits = 3)) | $(ref.is_successful_a) |")
    println(io, "| `odepe_multipoint` | $(ODEPE._fmt_percent(ref.mean_rel_error_b)) | $(ODEPE._fmt_percent(ref.max_rel_error_b)) | $(ODEPE._fmt_float(ref.time_b; digits = 3)) | $(ref.is_successful_b) |")
    println(io, "- Benchmark classification: `$(ref.classification)`\n")

    raw_pool = case_artifact[:raw_pool]
    println(io, "## Shared Raw Pool\n")
    println(io, "- Raw candidates: $(case_artifact[:raw_candidate_count])")
    println(io, "- Baseline-family count: $(case_artifact[:family_count])")
    println(io, "- Best raw fit index: $(get(raw_pool, :best_fit_index, nothing))")
    println(io, "- Best raw oracle index: $(get(raw_pool, :best_truth_index, nothing))")
    println(io, "- Best-fit vs best-truth RMSE gap: $(ODEPE._fmt_percent(get(raw_pool, :best_fit_vs_truth_gap, Inf)))\n")

    println(io, "## Strategy Comparison\n")
    println(io, "| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Effective Total s |")
    println(io, "|----------|--------|--------|-----------|------------|---------------|-------------------|")
    for strategy_key in (:best_fit_baseline, :family_consensus, :synthesized_finalizer, :branch_consensus_v1)
        summary = case_artifact[:strategies][strategy_key]
        winner_label = strategy_key == :synthesized_finalizer ? string(get(summary, :winning_origin, get(summary, :winner_mode, :missing))) : string(get(summary, :winner_mode, :missing))
        println(io, "| `$(strategy_key)` | `$(summary[:status])` | $(winner_label) | $(ODEPE._fmt_sci(ODEPE._summary_fit_error(summary))) | $(ODEPE._fmt_percent(ODEPE._summary_parameter_rmse(summary))) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(summary))) | $(ODEPE._fmt_float(summary[:effective_total_seconds]; digits = 3)) |")
    end
    println(io)

    println(io, "## Baseline Deltas\n")
    println(io, "| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |")
    println(io, "|----------|-----------|------------------|---------------------|--------------|--------------------|")
    for row in strategy_shift_rows(case_artifact)
        gain = isnothing(row.best_gain) ? "none" : "$(row.best_gain.label) ($(ODEPE._fmt_percent(row.best_gain.before)) → $(ODEPE._fmt_percent(row.best_gain.after)))"
        regression = isnothing(row.worst_regression) ? "none" : "$(row.worst_regression.label) ($(ODEPE._fmt_percent(row.worst_regression.before)) → $(ODEPE._fmt_percent(row.worst_regression.after)))"
        println(io, "| `$(row.strategy)` | $(ODEPE._fmt_sci(row.fit_delta)) | $(ODEPE._fmt_percent(row.parameter_rmse_delta)) | $(ODEPE._fmt_percent(row.combined_rmse_delta)) | $(gain) | $(regression) |")
    end
    println(io)

    branch = case_artifact[:strategies][:branch_consensus_v1]
    println(io, "## Branch v1 Top Hypotheses\n")
    println(io, "- Best branch index: $(get(branch, :best_branch_index, nothing))")
    println(io, "- Adaptive K: $(get(branch, :adaptive_k, 0))")
    println(io, "- Guard applied: $(get(branch, :guard_applied, false))")
    println(io, "- Winner lineage: $(branch[:final_winner_lineage])\n")
    println(io, "| Rank | Size | Branch Score | Representative | Best Fit | Best Eq | Confidence | Refined | Sources | Shooting Support | Combo Support |")
    println(io, "|------|------|--------------|----------------|----------|---------|------------|---------|---------|------------------|---------------|")
    if isempty(branch[:top_families])
        println(io, "| 1 | 0 | Inf | - | - | - | none | false | none | none | none |")
    else
        for row in branch[:top_families]
            println(io, "| $(row.rank) | $(row.member_count) | $(ODEPE._fmt_float(row.branch_score; digits = 4)) | $(row.representative_index) | $(row.best_fit_index) | $(row.best_equation_index) | `$(row.confidence_tier)` | $(row.refined) | $(row.source_types) | $(row.shooting_support) | $(row.combo_support) |")
        end
    end
    println(io)

    println(io, "## Best Strategy\n")
    println(io, "- Best combined-RMSE strategy on this case: `$(best_strategy_key(case_artifact))`")
    println(io)

    return String(take!(io))
end

function render_summary_csv(case_artifacts)
    io = IOBuffer()
    println(io, "case_id,model_name,bucket,classification,selected_via,raw_candidate_count,family_count,baseline_combined_rmse,consensus_combined_rmse,synth_combined_rmse,branch_combined_rmse,consensus_delta_combined_rmse,synth_delta_combined_rmse,branch_delta_combined_rmse,best_fit_vs_truth_gap,best_strategy")
    for case_artifact in case_artifacts
        baseline = case_artifact[:strategies][:best_fit_baseline]
        consensus = case_artifact[:strategies][:family_consensus]
        synth = case_artifact[:strategies][:synthesized_finalizer]
        branch = case_artifact[:strategies][:branch_consensus_v1]
        ref = case_artifact[:benchmark_reference]
        println(io, join([
            case_artifact[:case_id],
            case_artifact[:model_name],
            String(case_artifact[:bucket_label]),
            ref.classification,
            String(case_artifact[:selected_via]),
            string(case_artifact[:raw_candidate_count]),
            string(case_artifact[:family_count]),
            string(ODEPE._summary_combined_rmse(baseline)),
            string(ODEPE._summary_combined_rmse(consensus)),
            string(ODEPE._summary_combined_rmse(synth)),
            string(ODEPE._summary_combined_rmse(branch)),
            string(ODEPE._summary_combined_rmse(baseline) - ODEPE._summary_combined_rmse(consensus)),
            string(ODEPE._summary_combined_rmse(baseline) - ODEPE._summary_combined_rmse(synth)),
            string(ODEPE._summary_combined_rmse(baseline) - ODEPE._summary_combined_rmse(branch)),
            string(get(case_artifact[:raw_pool], :best_fit_vs_truth_gap, Inf)),
            string(best_strategy_key(case_artifact)),
        ], ","))
    end
    return String(take!(io))
end

function render_summary_markdown(case_artifacts)
    io = IOBuffer()
    println(io, "# Bilby Sweep Summary: branch_consensus_v1\n")
    println(io, "- Generated: `$(Dates.now())`")
    println(io, "- Benchmark root: `$(BENCHMARK_ROOT)`")
    println(io, "- Noise slice: `1e-4`")
    println(io, "- Total cases: $(length(case_artifacts))")
    println(io, "- Oracle note: truth metrics here are benchmark-only evaluation and were not used by any selector.\n")

    println(io, "## Aggregate Counts\n")
    consensus_beats = count(case_artifact -> begin
        baseline = case_artifact[:strategies][:best_fit_baseline]
        consensus = case_artifact[:strategies][:family_consensus]
        ODEPE._summary_combined_rmse(consensus) + 1e-9 < ODEPE._summary_combined_rmse(baseline)
    end, case_artifacts)
    synth_beats = count(case_artifact -> begin
        baseline = case_artifact[:strategies][:best_fit_baseline]
        synth = case_artifact[:strategies][:synthesized_finalizer]
        ODEPE._summary_combined_rmse(synth) + 1e-9 < ODEPE._summary_combined_rmse(baseline)
    end, case_artifacts)
    branch_beats = count(case_artifact -> begin
        baseline = case_artifact[:strategies][:best_fit_baseline]
        branch = case_artifact[:strategies][:branch_consensus_v1]
        ODEPE._summary_combined_rmse(branch) + 1e-9 < ODEPE._summary_combined_rmse(baseline)
    end, case_artifacts)
    branch_beats_consensus = count(case_artifact -> begin
        consensus = case_artifact[:strategies][:family_consensus]
        branch = case_artifact[:strategies][:branch_consensus_v1]
        ODEPE._summary_combined_rmse(branch) + 1e-9 < ODEPE._summary_combined_rmse(consensus)
    end, case_artifacts)
    branch_best = count(case_artifact -> best_strategy_key(case_artifact) == :branch_consensus_v1, case_artifacts)
    println(io, "- Consensus v0 beat baseline: $(consensus_beats)")
    println(io, "- Synth v0 beat baseline: $(synth_beats)")
    println(io, "- Branch v1 beat baseline: $(branch_beats)")
    println(io, "- Branch v1 beat consensus v0: $(branch_beats_consensus)")
    println(io, "- Branch v1 was overall best: $(branch_best)\n")

    println(io, "## Per-Case Outcomes\n")
    println(io, "| Case | Bucket | Baseline | Consensus v0 | Synth v0 | Branch v1 | Best Strategy |")
    println(io, "|------|--------|----------|--------------|----------|-----------|---------------|")
    for case_artifact in case_artifacts
        baseline = case_artifact[:strategies][:best_fit_baseline]
        consensus = case_artifact[:strategies][:family_consensus]
        synth = case_artifact[:strategies][:synthesized_finalizer]
        branch = case_artifact[:strategies][:branch_consensus_v1]
        println(io, "| `$(case_artifact[:case_id])` | $(case_artifact[:bucket_label]) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(baseline))) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(consensus))) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(synth))) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(branch))) | `$(best_strategy_key(case_artifact))` |")
    end
    println(io)
    return String(take!(io))
end

function build_case_artifact(case_spec;
    est_opts::ODEPE.EstimationOptions = ODEPE._default_sweep_estimation_options(),
    consensus_opts::ODEPE.ConsensusOptions = ODEPE._default_sweep_consensus_options(),
    synth_opts::ODEPE.SynthesizedFinalizerOptions = ODEPE._default_sweep_synthesized_options(),
    branch_opts::ODEPE.BranchConsensusOptions = ODEPE.BranchConsensusOptions(
        support_point_count = 4,
        support_combo_count = 4,
        top_branch_neighbor_count = 3,
        max_refined_seeds = 4,
    ),
)
    generated_at = string(Dates.now())
    case_id = case_spec.case_id
    case_dir = case_spec.case_dir
    benchmark_row = case_spec.row

    case_data = ODEPE._load_bilby_case(case_dir)
    pep = case_data.pep
    run_est_opts = ODEPE.merge_options(est_opts; datasize = length(pep.data_sample["t"]))
    shared = ODEPE._shared_case_inputs(pep, run_est_opts)
    raw_pool = ODEPE._consensus_raw_pool_summary(shared.pep_with_data, shared.raw_candidates)
    raw_pool = merge(raw_pool, Dict{Symbol, Any}(
        :raw_candidate_count => length(shared.raw_candidates),
        :best_fit_vs_truth_gap => ODEPE._raw_fit_truth_gap(raw_pool),
    ))

    strategies = OrderedDict{Symbol, Dict{Symbol, Any}}()
    families = ODEPE.CandidateFamily[]

    baseline = try
        built = @timed ODEPE._assemble_consensus_report(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            ODEPE._consensus_options_with_strategy(consensus_opts, :best_fit_baseline);
            context = shared.context,
        )
        families = built.value.families
        summary = ODEPE._consensus_strategy_summary(shared.pep_with_data, built.value, built.time, shared.shared_seconds, shared.t_vector)
        summary[:status] = :ok
        summary
    catch err
        method_failure_summary(:best_fit_baseline, err, shared.shared_seconds, length(shared.raw_candidates), length(families))
    end
    strategies[:best_fit_baseline] = baseline

    consensus = try
        built = @timed ODEPE._assemble_consensus_report(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            ODEPE._consensus_options_with_strategy(consensus_opts, :family_consensus);
            context = shared.context,
        )
        families = built.value.families
        summary = ODEPE._consensus_strategy_summary(shared.pep_with_data, built.value, built.time, shared.shared_seconds, shared.t_vector)
        summary[:status] = :ok
        summary
    catch err
        method_failure_summary(:family_consensus, err, shared.shared_seconds, length(shared.raw_candidates), length(families))
    end
    strategies[:family_consensus] = consensus

    synth = try
        built = @timed ODEPE._research_synthesized_finalizer_from_shared(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            shared.context,
            synth_opts,
        )
        ODEPE._synthesized_strategy_summary(shared.pep_with_data, built.value, built.time, shared.shared_seconds)
    catch err
        method_failure_summary(:synthesized_finalizer, err, shared.shared_seconds, length(shared.raw_candidates), length(families))
    end
    synth[:status] = get(synth, :status, :ok)
    strategies[:synthesized_finalizer] = synth

    branch = try
        built = @timed ODEPE._assemble_branch_consensus_report(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            branch_opts;
            context = shared.context,
        )
        branch_strategy_summary(shared.pep_with_data, built.value, built.time, shared.shared_seconds, shared.t_vector)
    catch err
        method_failure_summary(:branch_consensus_v1, err, shared.shared_seconds, length(shared.raw_candidates), length(families))
    end
    branch[:status] = get(branch, :status, :ok)
    strategies[:branch_consensus_v1] = branch

    return Dict{Symbol, Any}(
        :case_id => case_id,
        :model_name => benchmark_row.name,
        :bucket => case_spec.bucket,
        :bucket_label => case_spec.bucket_label,
        :selected_via => case_spec.selected_via,
        :generated_at => generated_at,
        :case_dir => case_dir,
        :benchmark_reference => benchmark_row,
        :status => :ok,
        :raw_candidate_count => length(shared.raw_candidates),
        :family_count => length(families),
        :raw_pool => raw_pool,
        :strategies => strategies,
    )
end

est_opts = ODEPE._default_sweep_estimation_options()
consensus_opts = ODEPE._default_sweep_consensus_options()
synth_opts = ODEPE._default_sweep_synthesized_options()
branch_opts = ODEPE.BranchConsensusOptions(
    support_point_count = 4,
    support_combo_count = 4,
    top_branch_neighbor_count = 3,
    max_refined_seeds = 4,
)

selected_cases = ODEPE._select_bilby_sweep_cases(
    BENCHMARK_ROOT;
    noise = 1e-4,
    case_limit = case_limit,
    requested_case_ids = requested_case_ids,
)

println("Running branch v1 sweep on $(length(selected_cases)) case(s)...")
case_artifacts = with_logger(NullLogger()) do
    Dict{Symbol, Any}[build_case_artifact(case_spec; est_opts = est_opts, consensus_opts = consensus_opts, synth_opts = synth_opts, branch_opts = branch_opts) for case_spec in selected_cases]
end

mkpath(OUTPUT_ROOT)
write(joinpath(OUTPUT_ROOT, "summary.md"), render_summary_markdown(case_artifacts))
write(joinpath(OUTPUT_ROOT, "summary.csv"), render_summary_csv(case_artifacts))

for case_artifact in case_artifacts
    case_dir = joinpath(OUTPUT_ROOT, "cases", case_artifact[:case_id])
    mkpath(case_dir)
    write(joinpath(case_dir, "study.md"), render_case_markdown(case_artifact))
end

println("Done! Sweep artifact root: $OUTPUT_ROOT")
