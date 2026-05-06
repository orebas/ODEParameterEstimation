"""
Generate a bilby 1e-4 broad-mixed sweep comparing practical finishers:
- best_fit_baseline
- polish_best_fit_raw
- polish_top_3_raw_by_fit
- block_v2_no_polish
- polish_block_v2_best

Optional environment variables:
- ODEPE_SWEEP_CASE_LIMIT
- ODEPE_SWEEP_CASE_IDS (comma-separated)
"""

using Dates
using Logging
using ODEParameterEstimation
using OrderedCollections
using Statistics

const ODEPE = ODEParameterEstimation

const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sweeps", "bilby_2026_03_09_1em4_finishers")
const STRATEGY_ORDER = (
    :best_fit_baseline,
    :polish_best_fit_raw,
    :polish_top_3_raw_by_fit,
    :block_v2_no_polish,
    :polish_block_v2_best,
)

case_limit = let raw = get(ENV, "ODEPE_SWEEP_CASE_LIMIT", "")
    isempty(strip(raw)) ? nothing : parse(Int, strip(raw))
end

requested_case_ids = let raw = get(ENV, "ODEPE_SWEEP_CASE_IDS", "")
    isempty(strip(raw)) ? String[] : [String(strip(part)) for part in split(raw, ',') if !isempty(strip(part))]
end

function worst_error_text(summary)
    row = ODEPE._summary_worst_row(summary)
    return isnothing(row) ? "none" : "$(row.label) ($(ODEPE._fmt_percent(row.rel_error)))"
end

function gain_per_second(baseline_summary, summary)
    delta = ODEPE._summary_combined_rmse(baseline_summary) - ODEPE._summary_combined_rmse(summary)
    seconds = get(summary, :incremental_seconds, NaN)
    (!isfinite(delta) || !isfinite(seconds) || seconds <= 0) && return -Inf
    return delta / seconds
end

function practical_winner_key(case_artifact::Dict{Symbol, Any})
    baseline = case_artifact[:strategies][:best_fit_baseline]
    best_key = :best_fit_baseline
    best_score = 0.0
    for key in STRATEGY_ORDER[2:end]
        summary = case_artifact[:strategies][key]
        score = gain_per_second(baseline, summary)
        if score > best_score
            best_score = score
            best_key = key
        end
    end
    return best_key
end

function best_quality_key(case_artifact::Dict{Symbol, Any})
    best_key = first(STRATEGY_ORDER)
    best_rmse = Inf
    for key in STRATEGY_ORDER
        rmse = ODEPE._summary_combined_rmse(case_artifact[:strategies][key])
        if rmse < best_rmse
            best_rmse = rmse
            best_key = key
        end
    end
    return best_key
end

function format_source_timing(dict_like)
    isempty(dict_like) && return "none"
    parts = ["`$(key)`=$(ODEPE._fmt_float(val; digits = 3))s" for (key, val) in dict_like]
    return join(parts, ", ")
end

function render_phase_table(io, timing::ODEPE.TimingBreakdown)
    println(io, "| Phase | Seconds | GC s | Bytes |")
    println(io, "|-------|---------|------|-------|")
    if isempty(timing.phases)
        println(io, "| `none` | 0.000 | 0.000 | 0 B |")
        return
    end
    for phase in timing.phases
        println(io, "| `$(phase.name)` | $(ODEPE._fmt_float(phase.seconds; digits = 3)) | $(ODEPE._fmt_float(phase.gctime; digits = 3)) | $(phase.bytes) |")
    end
end

function build_case_artifact(case_spec;
    est_opts::ODEPE.EstimationOptions = ODEPE._default_sweep_estimation_options(),
    consensus_opts::ODEPE.ConsensusOptions = ODEPE._default_sweep_consensus_options(),
)
    generated_at = string(Dates.now())
    case_data = ODEPE._load_bilby_case(case_spec.case_dir)
    pep = case_data.pep
    run_est_opts = ODEPE.merge_options(est_opts; datasize = length(pep.data_sample["t"]))
    shared = ODEPE._shared_case_inputs(pep, run_est_opts)
    raw_pool = ODEPE._consensus_raw_pool_summary(shared.pep_with_data, shared.raw_candidates)
    raw_pool = merge(raw_pool, Dict{Symbol, Any}(
        :raw_candidate_count => length(shared.raw_candidates),
        :best_fit_vs_truth_gap => ODEPE._raw_fit_truth_gap(raw_pool),
    ))

    strategies = OrderedDict{Symbol, Dict{Symbol, Any}}()
    baseline_report = nothing

    baseline = try
        built = @timed ODEPE._assemble_consensus_report(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            ODEPE._consensus_options_with_strategy(consensus_opts, :best_fit_baseline);
            context = shared.context,
        )
        baseline_report = built.value
        timing = ODEPE._single_phase_timing(
            :best_fit_baseline,
            "best_fit_baseline",
            built.time,
            built.bytes,
            built.gctime,
        )
        summary = ODEPE._consensus_strategy_summary(shared.pep_with_data, built.value, built.time, shared.shared_seconds, shared.t_vector, timing)
        summary[:status] = :ok
        summary
    catch err
        ODEPE._method_failure_summary(:best_fit_baseline, err, shared.shared_seconds, length(shared.raw_candidates), 0)
    end
    strategies[:best_fit_baseline] = baseline

    polish_best_fit = try
        ODEPE._polish_raw_candidate_strategy(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            shared.shared_seconds,
            shared.t_vector;
            top_k = 1,
        )
    catch err
        ODEPE._method_failure_summary(:polish_best_fit_raw, err, shared.shared_seconds, length(shared.raw_candidates), 0)
    end
    polish_best_fit[:status] = get(polish_best_fit, :status, :ok)
    strategies[:polish_best_fit_raw] = polish_best_fit

    polish_top3 = try
        ODEPE._polish_raw_candidate_strategy(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            shared.shared_seconds,
            shared.t_vector;
            top_k = 3,
        )
    catch err
        ODEPE._method_failure_summary(:polish_top_3_raw_by_fit, err, shared.shared_seconds, length(shared.raw_candidates), 0)
    end
    polish_top3[:status] = get(polish_top3, :status, :ok)
    strategies[:polish_top_3_raw_by_fit] = polish_top3

    block_report = nothing
    block_no_polish = try
        block_report, summary = ODEPE._block_no_polish_strategy(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            shared.context,
            shared.shared_seconds,
            shared.t_vector,
            baseline_report = baseline_report,
        )
        summary
    catch err
        ODEPE._method_failure_summary(:block_v2_no_polish, err, shared.shared_seconds, length(shared.raw_candidates), 0)
    end
    block_no_polish[:status] = get(block_no_polish, :status, :ok)
    strategies[:block_v2_no_polish] = block_no_polish

    polish_block = try
        if isnothing(block_report)
            Dict{Symbol, Any}(ODEPE._method_failure_summary(:polish_block_v2_best, ArgumentError("block_v2_no_polish did not produce a report"), shared.shared_seconds, length(shared.raw_candidates), 0))
        else
            ODEPE._polish_block_best_strategy(
                shared.pep_with_data,
                shared.run_opts,
                block_report,
                block_no_polish,
                shared.shared_seconds,
                shared.t_vector,
            )
        end
    catch err
        ODEPE._method_failure_summary(:polish_block_v2_best, err, shared.shared_seconds, length(shared.raw_candidates), 0)
    end
    polish_block[:status] = get(polish_block, :status, :ok)
    strategies[:polish_block_v2_best] = polish_block

    return Dict{Symbol, Any}(
        :case_id => case_spec.case_id,
        :model_name => case_spec.row.name,
        :bucket => case_spec.bucket,
        :bucket_label => case_spec.bucket_label,
        :selected_via => case_spec.selected_via,
        :generated_at => generated_at,
        :case_dir => case_spec.case_dir,
        :benchmark_reference => case_spec.row,
        :status => :ok,
        :datasize => length(shared.pep_with_data.data_sample["t"]),
        :shared_candidate_generation_seconds => shared.prep_seconds,
        :shared_context_seconds => shared.context_seconds,
        :shared_total_seconds => shared.shared_seconds,
        :shared_timing => shared.shared_timing,
        :raw_timing => shared.raw_timing,
        :context_timing => shared.context_timing,
        :raw_candidate_count => length(shared.raw_candidates),
        :raw_pool => raw_pool,
        :strategies => strategies,
        :best_quality_strategy => best_quality_key(Dict{Symbol, Any}(:strategies => strategies)),
    )
end

function build_case_artifact_safe(case_spec;
    est_opts::ODEPE.EstimationOptions = ODEPE._default_sweep_estimation_options(),
    consensus_opts::ODEPE.ConsensusOptions = ODEPE._default_sweep_consensus_options(),
)
    try
        return build_case_artifact(case_spec; est_opts = est_opts, consensus_opts = consensus_opts)
    catch err
        strategies = OrderedDict{Symbol, Dict{Symbol, Any}}()
        for key in STRATEGY_ORDER
            strategies[key] = ODEPE._method_failure_summary(key, err, 0.0, 0, 0)
            strategies[key][:status] = :error
        end
        return Dict{Symbol, Any}(
            :case_id => case_spec.case_id,
            :model_name => case_spec.row.name,
            :bucket => case_spec.bucket,
            :bucket_label => case_spec.bucket_label,
            :selected_via => case_spec.selected_via,
            :generated_at => string(Dates.now()),
            :case_dir => case_spec.case_dir,
            :benchmark_reference => case_spec.row,
            :status => :error,
            :datasize => 0,
            :shared_candidate_generation_seconds => 0.0,
            :shared_context_seconds => 0.0,
            :shared_total_seconds => 0.0,
            :shared_timing => ODEPE.TimingBreakdown(label = :shared_case_setup),
            :raw_timing => ODEPE.TimingBreakdown(label = :optimized_multishot),
            :context_timing => ODEPE.TimingBreakdown(label = :consensus_context),
            :raw_candidate_count => 0,
            :raw_pool => Dict{Symbol, Any}(
                :best_fit_index => nothing,
                :best_truth_index => nothing,
                :best_fit_vs_truth_gap => Inf,
            ),
            :strategies => strategies,
            :best_quality_strategy => :best_fit_baseline,
            :error_message => sprint(showerror, err),
        )
    end
end

function render_case_markdown(case_artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "# Finisher Sweep Case: $(case_artifact[:case_id])\n")
    println(io, "- Model: `$(case_artifact[:model_name])`")
    println(io, "- Bucket: `$(case_artifact[:bucket_label])`")
    println(io, "- Generated: `$(case_artifact[:generated_at])`")
    println(io, "- Status: `$(case_artifact[:status])`")
    println(io, "- Datasize: $(case_artifact[:datasize])")
    println(io, "- Case dir: `$(case_artifact[:case_dir])`\n")

    if case_artifact[:status] != :ok
        println(io, "## Failure\n")
        println(io, "- Error: `$(get(case_artifact, :error_message, "unknown"))`")
        return String(take!(io))
    end

    ref = case_artifact[:benchmark_reference]
    println(io, "## Benchmark Reference\n")
    println(io, "- Classification: `$(ref.classification)`")
    println(io, "- Benchmark ODEPE mean/max relative error: $(ODEPE._fmt_percent(ref.mean_rel_error_b)) / $(ODEPE._fmt_percent(ref.max_rel_error_b))")
    println(io, "- Benchmark ODEPE runtime: $(ODEPE._fmt_float(ref.time_b; digits = 3)) s\n")

    raw_pool = case_artifact[:raw_pool]
    println(io, "## Shared Raw Pool\n")
    println(io, "- Raw candidates: $(case_artifact[:raw_candidate_count])")
    println(io, "- Best raw fit index: $(get(raw_pool, :best_fit_index, nothing))")
    println(io, "- Best raw oracle index: $(get(raw_pool, :best_truth_index, nothing))")
    println(io, "- Best-fit vs best-truth combined-RMSE gap: $(ODEPE._fmt_percent(get(raw_pool, :best_fit_vs_truth_gap, Inf)))\n")

    println(io, "## Shared Timing\n")
    println(io, "- Shared total: $(ODEPE._fmt_float(case_artifact[:shared_total_seconds]; digits = 3)) s")
    println(io, "- Raw candidate generation: $(ODEPE._fmt_float(case_artifact[:shared_candidate_generation_seconds]; digits = 3)) s")
    println(io, "- Consensus/block context build: $(ODEPE._fmt_float(case_artifact[:shared_context_seconds]; digits = 3)) s\n")

    println(io, "### Raw Estimation Phases\n")
    render_phase_table(io, case_artifact[:raw_timing])
    println(io)
    raw_details = case_artifact[:raw_timing].details
    println(io, "### Raw Estimation Subphase Totals\n")
    println(io, "- Interpolant creation: $(format_source_timing(get(raw_details, :interpolant_creation_seconds_by_source, OrderedDict{Symbol, Float64}())))")
    println(io, "- Single-point data eval: $(format_source_timing(get(raw_details, :single_point_data_eval_seconds_by_source, OrderedDict{Symbol, Float64}())))")
    println(io, "- Single-point HC: $(format_source_timing(get(raw_details, :single_point_hc_seconds_by_source, OrderedDict{Symbol, Float64}())))")
    println(io, "- Single-point system solve: $(format_source_timing(get(raw_details, :single_point_system_seconds_by_source, OrderedDict{Symbol, Float64}())))")
    println(io, "- Multipoint template: $(format_source_timing(get(raw_details, :multipoint_template_seconds_by_source, OrderedDict{Symbol, Float64}())))")
    println(io, "- Multipoint evaluation: $(format_source_timing(get(raw_details, :multipoint_eval_seconds_by_source, OrderedDict{Symbol, Float64}())))")
    println(io, "- Multipoint solve: $(format_source_timing(get(raw_details, :multipoint_solve_seconds_by_source, OrderedDict{Symbol, Float64}())))\n")

    baseline = case_artifact[:strategies][:best_fit_baseline]
    println(io, "## Strategy Comparison\n")
    println(io, "| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |")
    println(io, "|----------|--------|---------------|-------------|---------|------------------|----------|")
    for key in STRATEGY_ORDER
        summary = case_artifact[:strategies][key]
        delta = ODEPE._summary_combined_rmse(baseline) - ODEPE._summary_combined_rmse(summary)
        gps = gain_per_second(baseline, summary)
        gain_text = isfinite(delta) ? ODEPE._fmt_percent(delta) : "Inf"
        gps_text = isfinite(gps) && gps > 0 ? ODEPE._fmt_percent(gps) * "/s" : "n/a"
        println(io, "| `$(key)` | `$(summary[:status])` | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(summary))) | $(worst_error_text(summary)) | $(ODEPE._fmt_float(get(summary, :incremental_seconds, NaN); digits = 3)) | $(gain_text) | $(gps_text) |")
    end
    println(io)

    println(io, "## Practical Recommendation\n")
    println(io, "- Best quality strategy: `$(best_quality_key(case_artifact))`")
    println(io, "- Best gain-per-added-second strategy: `$(practical_winner_key(case_artifact))`\n")

    println(io, "## Per-Strategy Timing Detail\n")
    for key in STRATEGY_ORDER
        summary = case_artifact[:strategies][key]
        println(io, "### `$(key)`\n")
        println(io, "- Final lineage: $(summary[:final_winner_lineage])")
        println(io, "- Incremental seconds: $(ODEPE._fmt_float(get(summary, :incremental_seconds, NaN); digits = 3))")
        render_phase_table(io, get(summary, :timing, ODEPE.TimingBreakdown()))
        println(io)
    end

    return String(take!(io))
end

function render_summary_csv(case_artifacts)
    io = IOBuffer()
    println(io, "case_id,model_name,bucket,classification,raw_candidate_count,best_fit_vs_truth_gap,baseline_combined_rmse,polish_best_fit_combined_rmse,polish_top3_combined_rmse,block_no_polish_combined_rmse,polish_block_combined_rmse,practical_winner,best_quality_strategy")
    for case_artifact in case_artifacts
        ref = case_artifact[:benchmark_reference]
        println(io, join([
            case_artifact[:case_id],
            case_artifact[:model_name],
            String(case_artifact[:bucket_label]),
            ref.classification,
            string(case_artifact[:raw_candidate_count]),
            string(get(case_artifact[:raw_pool], :best_fit_vs_truth_gap, Inf)),
            string(ODEPE._summary_combined_rmse(case_artifact[:strategies][:best_fit_baseline])),
            string(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_best_fit_raw])),
            string(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_top_3_raw_by_fit])),
            string(ODEPE._summary_combined_rmse(case_artifact[:strategies][:block_v2_no_polish])),
            string(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_block_v2_best])),
            string(practical_winner_key(case_artifact)),
            string(best_quality_key(case_artifact)),
        ], ","))
    end
    return String(take!(io))
end

function render_summary_markdown(case_artifacts)
    io = IOBuffer()
    println(io, "# Bilby Sweep Summary: cheap finishers\n")
    println(io, "- Generated: `$(Dates.now())`")
    println(io, "- Benchmark root: `$(BENCHMARK_ROOT)`")
    println(io, "- Noise slice: `1e-4`")
    println(io, "- Total cases: $(length(case_artifacts))")
    println(io, "- Oracle note: truth metrics here are benchmark-only evaluation and were not used by any finisher.\n")

    baseline_beats = count(case_artifact -> best_quality_key(case_artifact) == :best_fit_baseline, case_artifacts)
    println(io, "## Best-Quality Counts\n")
    for key in STRATEGY_ORDER
        count_key = count(case_artifact -> best_quality_key(case_artifact) == key, case_artifacts)
        println(io, "- `$(key)`: $(count_key)")
    end
    println(io, "- Baseline remained best: $(baseline_beats)\n")

    println(io, "## Average Added Time and Gain\n")
    println(io, "| Strategy | Mean Combined-RMSE Gain | Median Added s | Mean Gain / s |")
    println(io, "|----------|-------------------------|----------------|---------------|")
    baseline = :best_fit_baseline
    for key in STRATEGY_ORDER[2:end]
        deltas = Float64[]
        added = Float64[]
        gps_values = Float64[]
        for case_artifact in case_artifacts
            base = case_artifact[:strategies][baseline]
            summary = case_artifact[:strategies][key]
            push!(deltas, ODEPE._summary_combined_rmse(base) - ODEPE._summary_combined_rmse(summary))
            push!(added, get(summary, :incremental_seconds, Inf))
            gps = gain_per_second(base, summary)
            isfinite(gps) && gps > 0 && push!(gps_values, gps)
        end
        finite_deltas = filter(isfinite, deltas)
        finite_added = filter(isfinite, added)
        mean_delta = isempty(finite_deltas) ? Inf : mean(finite_deltas)
        median_added = isempty(finite_added) ? Inf : median(finite_added)
        mean_gps = isempty(gps_values) ? 0.0 : mean(gps_values)
        println(io, "| `$(key)` | $(ODEPE._fmt_percent(mean_delta)) | $(ODEPE._fmt_float(median_added; digits = 3)) | $(ODEPE._fmt_percent(mean_gps))/s |")
    end
    println(io)

    println(io, "## Per-Case Outcomes\n")
    println(io, "| Case | Bucket | Baseline | Polish Best Fit | Polish Top 3 | Block No Polish | Polish Block Best | Practical Winner |")
    println(io, "|------|--------|----------|-----------------|--------------|-----------------|-------------------|------------------|")
    for case_artifact in case_artifacts
        println(io, "| `$(case_artifact[:case_id])` | $(case_artifact[:bucket_label]) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:strategies][:best_fit_baseline]))) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_best_fit_raw]))) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_top_3_raw_by_fit]))) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:strategies][:block_v2_no_polish]))) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_block_v2_best]))) | `$(practical_winner_key(case_artifact))` |")
    end
    println(io)
    return String(take!(io))
end

est_opts = ODEPE._default_sweep_estimation_options()
consensus_opts = ODEPE._default_sweep_consensus_options()
selected_cases = ODEPE._select_bilby_sweep_cases(
    BENCHMARK_ROOT;
    noise = 1e-4,
    case_limit = case_limit,
    requested_case_ids = requested_case_ids,
)

println("Running cheap-finisher sweep on $(length(selected_cases)) case(s)...")
case_artifacts = with_logger(NullLogger()) do
    Dict{Symbol, Any}[build_case_artifact_safe(case_spec; est_opts = est_opts, consensus_opts = consensus_opts) for case_spec in selected_cases]
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
