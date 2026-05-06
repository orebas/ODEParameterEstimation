"""
Generate a bilby 1e-4 broad support-budget sweep comparing:
- best_fit_baseline
- polish_top_3_raw_by_fit
- block_v2_no_polish at configurable support budgets
- polish the best no-polish block budget per case

Optional environment variables:
- ODEPE_SWEEP_CASE_LIMIT
- ODEPE_SWEEP_CASE_IDS (comma-separated)
- ODEPE_SUPPORT_BUDGETS (comma-separated P/C pairs, default "4/4,8/8,12/12")
"""

using Dates
using Logging
using ODEParameterEstimation
using OrderedCollections
using Statistics

const ODEPE = ODEParameterEstimation

const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sweeps", "bilby_2026_03_09_1em4_support_budgets")
const DEFAULT_CASE_LIMIT = 15
const STATIC_STRATEGY_ORDER = (
    :best_fit_baseline,
    :polish_top_3_raw_by_fit,
)

case_limit = let raw = get(ENV, "ODEPE_SWEEP_CASE_LIMIT", string(DEFAULT_CASE_LIMIT))
    isempty(strip(raw)) ? nothing : parse(Int, strip(raw))
end

requested_case_ids = let raw = get(ENV, "ODEPE_SWEEP_CASE_IDS", "")
    isempty(strip(raw)) ? String[] : [String(strip(part)) for part in split(raw, ',') if !isempty(strip(part))]
end

function parse_support_budgets(raw::AbstractString)
    stripped = strip(raw)
    isempty(stripped) && return [(4, 4), (8, 8), (12, 12)]
    budgets = Tuple{Int, Int}[]
    seen = Set{Tuple{Int, Int}}()
    for part in split(stripped, ',')
        piece = strip(part)
        isempty(piece) && continue
        fields = split(piece, '/')
        length(fields) == 2 || error("Invalid support budget '$piece'; expected P/C")
        budget = (parse(Int, strip(fields[1])), parse(Int, strip(fields[2])))
        budget in seen && continue
        push!(budgets, budget)
        push!(seen, budget)
    end
    isempty(budgets) && error("No valid support budgets provided")
    return budgets
end

const SUPPORT_BUDGETS = parse_support_budgets(get(ENV, "ODEPE_SUPPORT_BUDGETS", "4/4,8/8,12/12"))

function budget_label(points::Int, combos::Int)
    return "$(points)x$(combos)"
end

function block_strategy_key(points::Int, combos::Int)
    return Symbol("block_v2_no_polish_$(points)x$(combos)")
end

function budget_for_key(key::Symbol)
    name = String(key)
    startswith(name, "block_v2_no_polish_") || return nothing
    suffix = name[length("block_v2_no_polish_") + 1:end]
    fields = split(suffix, 'x')
    length(fields) == 2 || return nothing
    return (parse(Int, fields[1]), parse(Int, fields[2]))
end

function support_budget_text(summary::AbstractDict{Symbol, <:Any})
    requested = get(summary, :support_budget, nothing)
    requested isa Tuple{Int, Int} && return budget_label(requested...)
    return "$(length(get(summary, :support_points, Int[])))x$(length(get(summary, :support_combos, Vector{Vector{Int}}())))"
end

function relabel_timing(timing::ODEPE.TimingBreakdown, label::Symbol)
    return ODEPE.TimingBreakdown(
        label = label,
        total_seconds = timing.total_seconds,
        phases = timing.phases,
        details = copy(timing.details),
    )
end

function relabel_strategy_summary(summary::Dict{Symbol, Any}, strategy::Symbol)
    relabeled = copy(summary)
    relabeled[:strategy] = strategy
    relabeled[:timing] = relabel_timing(get(summary, :timing, ODEPE.TimingBreakdown()), strategy)
    return relabeled
end

function worst_error_text(summary)
    row = ODEPE._summary_worst_row(summary)
    return isnothing(row) ? "none" : "$(row.label) ($(ODEPE._fmt_percent(row.rel_error)))"
end

function reference_gain_per_second(reference_summary, summary)
    delta = ODEPE._summary_combined_rmse(reference_summary) - ODEPE._summary_combined_rmse(summary)
    seconds = get(summary, :incremental_seconds, NaN)
    (!isfinite(delta) || !isfinite(seconds) || seconds <= 0) && return -Inf
    return delta / seconds
end

function practical_winner_key(case_artifact::Dict{Symbol, Any})
    reference = case_artifact[:strategies][:polish_top_3_raw_by_fit]
    best_key = :polish_top_3_raw_by_fit
    best_score = 0.0
    for key in case_artifact[:strategy_order]
        key == :polish_top_3_raw_by_fit && continue
        score = reference_gain_per_second(reference, case_artifact[:strategies][key])
        if score > best_score
            best_score = score
            best_key = key
        end
    end
    return best_key
end

function best_quality_key(case_artifact::Dict{Symbol, Any})
    best_key = first(case_artifact[:strategy_order])
    best_rmse = Inf
    for key in case_artifact[:strategy_order]
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

function select_support_budget_cases(
    benchmark_root::AbstractString;
    comparison_csv_path::AbstractString = joinpath(benchmark_root, "analysis_results", "comparison_amigo2_run_vs_odepe_multipoint_full.csv"),
    data_variant::AbstractString = "odepe_nopolish",
    noise::Float64 = 1e-4,
    case_limit::Union{Nothing, Int} = nothing,
    requested_case_ids::Vector{String} = String[],
)
    selected = ODEPE._select_bilby_sweep_cases(
        benchmark_root;
        comparison_csv_path = comparison_csv_path,
        data_variant = data_variant,
        noise = noise,
        case_limit = isempty(requested_case_ids) ? nothing : case_limit,
        requested_case_ids = requested_case_ids,
    )
    !isempty(requested_case_ids) && return selected
    isnothing(case_limit) && return selected
    length(selected) >= case_limit && return selected[1:case_limit]

    rows = ODEPE._read_bilby_comparison_rows(comparison_csv_path)
    noise_rows = filter(row -> isapprox(row.noise, noise; atol = 1e-12, rtol = 0.0), rows)
    seen = Set(item.case_id for item in selected)

    for spec in ODEPE._sweep_bucket_specs()
        fallback_rows = sort(
            filter(spec.filter, noise_rows);
            by = row -> ODEPE._bucket_sort_key(row, spec.sort_mode),
        )
        for row in fallback_rows
            row.id in seen && continue
            case_dir = ODEPE._bilby_case_dir(benchmark_root, row.id; data_variant = data_variant)
            isdir(case_dir) || continue
            push!(selected, (
                bucket = spec.bucket,
                bucket_label = spec.label,
                selected_via = :extended_fallback,
                case_id = row.id,
                case_dir = case_dir,
                row = row,
            ))
            push!(seen, row.id)
            length(selected) >= case_limit && return selected
        end
    end

    return selected
end

function best_block_key_by_fit(block_summaries::OrderedDict{Symbol, Dict{Symbol, Any}}, strategy_order::Vector{Symbol})
    best_key = nothing
    best_fit = Inf
    for key in strategy_order
        summary = block_summaries[key]
        fit = ODEPE._summary_fit_error(summary)
        if fit < best_fit
            best_fit = fit
            best_key = key
        end
    end
    return best_key
end

function build_case_artifact(case_spec;
    est_opts::ODEPE.EstimationOptions = ODEPE._default_sweep_estimation_options(),
    consensus_opts::ODEPE.ConsensusOptions = ODEPE._default_sweep_consensus_options(),
    support_budgets::Vector{Tuple{Int, Int}} = SUPPORT_BUDGETS,
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

    strategy_order = Symbol[STATIC_STRATEGY_ORDER...]
    for (points, combos) in support_budgets
        push!(strategy_order, block_strategy_key(points, combos))
    end
    push!(strategy_order, :polish_best_block_budget)

    strategies = OrderedDict{Symbol, Dict{Symbol, Any}}()
    block_reports = OrderedDict{Symbol, Any}()
    block_summaries = OrderedDict{Symbol, Dict{Symbol, Any}}()
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

    for (points, combos) in support_budgets
        key = block_strategy_key(points, combos)
        try
            block_opts = ODEPE.BlockConsensusOptions(
                support_point_count = points,
                support_combo_count = combos,
                enable_polish = false,
            )
            report, summary = ODEPE._block_no_polish_strategy(
                shared.pep_with_data,
                shared.run_opts,
                shared.raw_candidates,
                shared.context,
                shared.shared_seconds,
                shared.t_vector;
                baseline_report = baseline_report,
                force_reuse_baseline = (
                    points == consensus_opts.support_point_count &&
                    combos == consensus_opts.support_combo_count
                ),
                block_opts = block_opts,
            )
            summary = relabel_strategy_summary(summary, key)
            summary[:status] = get(summary, :status, :ok)
            summary[:support_budget] = (points, combos)
            strategies[key] = summary
            block_reports[key] = report
            block_summaries[key] = summary
        catch err
            summary = ODEPE._method_failure_summary(key, err, shared.shared_seconds, length(shared.raw_candidates), 0)
            summary[:status] = :error
            summary[:support_budget] = (points, combos)
            strategies[key] = summary
        end
    end

    best_block_key = best_block_key_by_fit(block_summaries, collect(keys(block_summaries)))
    polish_block = try
        if isnothing(best_block_key)
            Dict{Symbol, Any}(ODEPE._method_failure_summary(
                :polish_best_block_budget,
                ArgumentError("no valid no-polish block report"),
                shared.shared_seconds,
                length(shared.raw_candidates),
                0,
            ))
        else
            polished = ODEPE._polish_block_best_strategy(
                shared.pep_with_data,
                shared.run_opts,
                block_reports[best_block_key],
                block_summaries[best_block_key],
                shared.shared_seconds,
                shared.t_vector,
            )
            polished = relabel_strategy_summary(polished, :polish_best_block_budget)
            polished[:source_block_strategy] = best_block_key
            polished[:source_support_budget] = get(block_summaries[best_block_key], :support_budget, nothing)
            polished
        end
    catch err
        ODEPE._method_failure_summary(:polish_best_block_budget, err, shared.shared_seconds, length(shared.raw_candidates), 0)
    end
    polish_block[:status] = get(polish_block, :status, :ok)
    strategies[:polish_best_block_budget] = polish_block

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
        :strategy_order => strategy_order,
        :support_budgets => support_budgets,
        :best_block_strategy => best_block_key,
        :best_quality_strategy => best_quality_key(Dict{Symbol, Any}(:strategies => strategies, :strategy_order => strategy_order)),
    )
end

function build_case_artifact_safe(case_spec;
    est_opts::ODEPE.EstimationOptions = ODEPE._default_sweep_estimation_options(),
    consensus_opts::ODEPE.ConsensusOptions = ODEPE._default_sweep_consensus_options(),
    support_budgets::Vector{Tuple{Int, Int}} = SUPPORT_BUDGETS,
)
    strategy_order = Symbol[STATIC_STRATEGY_ORDER...]
    for (points, combos) in support_budgets
        push!(strategy_order, block_strategy_key(points, combos))
    end
    push!(strategy_order, :polish_best_block_budget)
    try
        return build_case_artifact(case_spec; est_opts = est_opts, consensus_opts = consensus_opts, support_budgets = support_budgets)
    catch err
        strategies = OrderedDict{Symbol, Dict{Symbol, Any}}()
        for key in strategy_order
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
            :strategy_order => strategy_order,
            :support_budgets => support_budgets,
            :best_block_strategy => nothing,
            :best_quality_strategy => :best_fit_baseline,
            :error_message => sprint(showerror, err),
        )
    end
end

function budget_reuse_text(summary::AbstractDict{Symbol, <:Any})
    timing = get(summary, :timing, ODEPE.TimingBreakdown())
    details = timing.details
    reused = get(details, :reused_baseline_report, nothing)
    return isnothing(reused) ? "n/a" : string(reused)
end

function render_case_markdown(case_artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "# Support-Budget Sweep Case: $(case_artifact[:case_id])\n")
    println(io, "- Model: `$(case_artifact[:model_name])`")
    println(io, "- Bucket: `$(case_artifact[:bucket_label])`")
    println(io, "- Selected via: `$(case_artifact[:selected_via])`")
    println(io, "- Generated: `$(case_artifact[:generated_at])`")
    println(io, "- Status: `$(case_artifact[:status])`")
    println(io, "- Datasize: $(case_artifact[:datasize])")
    println(io, "- Case dir: `$(case_artifact[:case_dir])`")
    println(io, "- Support budgets: `$(join([budget_label(p, c) for (p, c) in case_artifact[:support_budgets]], ", "))`\n")

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

    practical_baseline = case_artifact[:strategies][:polish_top_3_raw_by_fit]
    println(io, "## Strategy Comparison\n")
    println(io, "| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |")
    println(io, "|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|")
    for key in case_artifact[:strategy_order]
        summary = case_artifact[:strategies][key]
        delta = ODEPE._summary_combined_rmse(practical_baseline) - ODEPE._summary_combined_rmse(summary)
        gps = reference_gain_per_second(practical_baseline, summary)
        gain_text = isfinite(delta) ? ODEPE._fmt_percent(delta) : "Inf"
        gps_text = isfinite(gps) && gps > 0 ? "$(ODEPE._fmt_percent(gps))/s" : "n/a"
        println(io, "| `$(key)` | `$(support_budget_text(summary))` | `$(summary[:status])` | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(summary))) | $(worst_error_text(summary)) | $(ODEPE._fmt_float(get(summary, :incremental_seconds, NaN); digits = 3)) | $(gain_text) | $(gps_text) | `$(budget_reuse_text(summary))` |")
    end
    println(io)

    println(io, "## Recommendations\n")
    println(io, "- Best quality strategy: `$(best_quality_key(case_artifact))`")
    println(io, "- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `$(practical_winner_key(case_artifact))`")
    println(io, "- Best no-polish block budget by fit: `$(get(case_artifact, :best_block_strategy, nothing))`\n")

    println(io, "## Per-Strategy Timing Detail\n")
    for key in case_artifact[:strategy_order]
        summary = case_artifact[:strategies][key]
        println(io, "### `$(key)`\n")
        println(io, "- Budget: `$(support_budget_text(summary))`")
        println(io, "- Final lineage: $(summary[:final_winner_lineage])")
        println(io, "- Incremental seconds: $(ODEPE._fmt_float(get(summary, :incremental_seconds, NaN); digits = 3))")
        if key == :polish_best_block_budget
            println(io, "- Source no-polish block strategy: `$(get(summary, :source_block_strategy, nothing))`")
        end
        render_phase_table(io, get(summary, :timing, ODEPE.TimingBreakdown()))
        details = get(summary, :timing, ODEPE.TimingBreakdown()).details
        if !isempty(details)
            println(io)
            println(io, "| Detail | Value |")
            println(io, "|--------|-------|")
            for (name, value) in details
                println(io, "| `$(name)` | `$(value)` |")
            end
        end
        println(io)
    end

    return String(take!(io))
end

function render_summary_csv(case_artifacts, support_budgets::Vector{Tuple{Int, Int}})
    io = IOBuffer()
    block_headers = String[]
    for (points, combos) in support_budgets
        label = lowercase(budget_label(points, combos))
        push!(block_headers, "block_$(label)_combined_rmse")
        push!(block_headers, "block_$(label)_seconds")
        push!(block_headers, "block_$(label)_reused_baseline")
    end
    headers = vcat(
        [
            "case_id",
            "model_name",
            "bucket",
            "classification",
            "raw_candidate_count",
            "best_fit_vs_truth_gap",
            "best_fit_baseline_combined_rmse",
            "polish_top3_combined_rmse",
        ],
        block_headers,
        [
            "polish_best_block_budget_combined_rmse",
            "polish_best_block_budget_seconds",
            "best_no_polish_block_strategy",
            "practical_winner",
            "best_quality_strategy",
        ],
    )
    println(io, join(headers, ","))
    for case_artifact in case_artifacts
        ref = case_artifact[:benchmark_reference]
        row = String[
            case_artifact[:case_id],
            case_artifact[:model_name],
            String(case_artifact[:bucket_label]),
            ref.classification,
            string(case_artifact[:raw_candidate_count]),
            string(get(case_artifact[:raw_pool], :best_fit_vs_truth_gap, Inf)),
            string(ODEPE._summary_combined_rmse(case_artifact[:strategies][:best_fit_baseline])),
            string(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_top_3_raw_by_fit])),
        ]
        for (points, combos) in support_budgets
            key = block_strategy_key(points, combos)
            summary = case_artifact[:strategies][key]
            push!(row, string(ODEPE._summary_combined_rmse(summary)))
            push!(row, string(get(summary, :incremental_seconds, Inf)))
            push!(row, budget_reuse_text(summary))
        end
        push!(row, string(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_best_block_budget])))
        push!(row, string(get(case_artifact[:strategies][:polish_best_block_budget], :incremental_seconds, Inf)))
        push!(row, string(get(case_artifact, :best_block_strategy, nothing)))
        push!(row, string(practical_winner_key(case_artifact)))
        push!(row, string(best_quality_key(case_artifact)))
        println(io, join(row, ","))
    end
    return String(take!(io))
end

function budget_change_count(case_artifacts, smaller::Tuple{Int, Int}, larger::Tuple{Int, Int})
    key_small = block_strategy_key(smaller...)
    key_large = block_strategy_key(larger...)
    count = 0
    for case_artifact in case_artifacts
        a = case_artifact[:strategies][key_small]
        b = case_artifact[:strategies][key_large]
        if get(a, :final_winner_lineage, "none") != get(b, :final_winner_lineage, "none")
            count += 1
        end
    end
    return count
end

function best_budget_delta_case(case_artifacts, larger::Tuple{Int, Int}, smaller::Tuple{Int, Int}; direction::Symbol)
    key_large = block_strategy_key(larger...)
    key_small = block_strategy_key(smaller...)
    best_case = nothing
    best_delta = direction == :improvement ? -Inf : -Inf
    for case_artifact in case_artifacts
        delta = ODEPE._summary_combined_rmse(case_artifact[:strategies][key_small]) -
            ODEPE._summary_combined_rmse(case_artifact[:strategies][key_large])
        metric = direction == :improvement ? delta : -delta
        if metric > best_delta
            best_delta = metric
            best_case = (case_id = case_artifact[:case_id], delta = delta)
        end
    end
    return best_case
end

function render_summary_markdown(case_artifacts, support_budgets::Vector{Tuple{Int, Int}})
    io = IOBuffer()
    println(io, "# Bilby Sweep Summary: support budgets\n")
    println(io, "- Generated: `$(Dates.now())`")
    println(io, "- Benchmark root: `$(BENCHMARK_ROOT)`")
    println(io, "- Noise slice: `1e-4`")
    println(io, "- Total cases: $(length(case_artifacts))")
    println(io, "- Support budgets: `$(join([budget_label(p, c) for (p, c) in support_budgets], ", "))`")
    println(io, "- Oracle note: truth metrics here are benchmark-only evaluation and were not used by any finisher.\n")

    strategy_order = vcat(
        collect(STATIC_STRATEGY_ORDER),
        [block_strategy_key(points, combos) for (points, combos) in support_budgets],
        [:polish_best_block_budget],
    )

    println(io, "## Best-Quality Counts\n")
    for key in strategy_order
        count_key = count(case_artifact -> best_quality_key(case_artifact) == key, case_artifacts)
        println(io, "- `$(key)`: $(count_key)")
    end
    println(io)

    println(io, "## Delta vs `polish_top_3_raw_by_fit`\n")
    println(io, "| Strategy | Mean Combined-RMSE Delta | Median Combined-RMSE Delta | Median Added s | Mean Gain / s |")
    println(io, "|----------|---------------------------|-----------------------------|----------------|---------------|")
    reference_key = :polish_top_3_raw_by_fit
    for key in filter(!=(reference_key), strategy_order)
        deltas = Float64[]
        added = Float64[]
        gps_values = Float64[]
        for case_artifact in case_artifacts
            reference = case_artifact[:strategies][reference_key]
            summary = case_artifact[:strategies][key]
            push!(deltas, ODEPE._summary_combined_rmse(reference) - ODEPE._summary_combined_rmse(summary))
            push!(added, get(summary, :incremental_seconds, Inf))
            gps = reference_gain_per_second(reference, summary)
            isfinite(gps) && gps > 0 && push!(gps_values, gps)
        end
        finite_deltas = filter(isfinite, deltas)
        finite_added = filter(isfinite, added)
        mean_delta = isempty(finite_deltas) ? Inf : mean(finite_deltas)
        median_delta = isempty(finite_deltas) ? Inf : median(finite_deltas)
        median_added = isempty(finite_added) ? Inf : median(finite_added)
        mean_gps = isempty(gps_values) ? 0.0 : mean(gps_values)
        println(io, "| `$(key)` | $(ODEPE._fmt_percent(mean_delta)) | $(ODEPE._fmt_percent(median_delta)) | $(ODEPE._fmt_float(median_added; digits = 3)) | $(ODEPE._fmt_percent(mean_gps))/s |")
    end
    println(io)

    println(io, "## Winner Changes Across Budgets\n")
    for idx in 2:length(support_budgets)
        smaller = support_budgets[idx - 1]
        larger = support_budgets[idx]
        println(io, "- `$(budget_label(larger...))` vs `$(budget_label(smaller...))`: winner changed on $(budget_change_count(case_artifacts, smaller, larger)) case(s)")
    end
    println(io)

    println(io, "## Budget Follow-Ups\n")
    if length(support_budgets) >= 2
        first_gain = best_budget_delta_case(case_artifacts, support_budgets[2], support_budgets[1]; direction = :improvement)
        println(io, "- Biggest `$(budget_label(support_budgets[2]...))` gain over `$(budget_label(support_budgets[1]...))`: `$(first_gain.case_id)` ($(ODEPE._fmt_percent(first_gain.delta)))")
    end
    if length(support_budgets) >= 3
        second_gain = best_budget_delta_case(case_artifacts, support_budgets[3], support_budgets[2]; direction = :improvement)
        println(io, "- Biggest `$(budget_label(support_budgets[3]...))` gain over `$(budget_label(support_budgets[2]...))`: `$(second_gain.case_id)` ($(ODEPE._fmt_percent(second_gain.delta)))")
    end
    if length(support_budgets) >= 2
        regression = best_budget_delta_case(case_artifacts, support_budgets[end], support_budgets[1]; direction = :regression)
        println(io, "- Biggest regression from larger budgets: `$(regression.case_id)` ($(ODEPE._fmt_percent(regression.delta)))")
    end
    println(io)

    println(io, "## Per-Case Outcomes\n")
    header = ["Case", "Bucket", "Top-3 Polish"]
    append!(header, [budget_label(points, combos) for (points, combos) in support_budgets])
    append!(header, ["Polish Best Block", "Practical Winner"])
    println(io, "| " * join(header, " | ") * " |")
    println(io, "|------|--------|--------------|" * join(fill("--------------", length(header) - 3), "|") * "|")
    for case_artifact in case_artifacts
        cells = String[
            "`$(case_artifact[:case_id])`",
            String(case_artifact[:bucket_label]),
            ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_top_3_raw_by_fit])),
        ]
        for (points, combos) in support_budgets
            push!(cells, ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:strategies][block_strategy_key(points, combos)])))
        end
        push!(cells, ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:strategies][:polish_best_block_budget])))
        push!(cells, "`$(practical_winner_key(case_artifact))`")
        println(io, "| " * join(cells, " | ") * " |")
    end
    println(io)

    return String(take!(io))
end

est_opts = ODEPE._default_sweep_estimation_options()
consensus_opts = ODEPE._default_sweep_consensus_options()
selected_cases = select_support_budget_cases(
    BENCHMARK_ROOT;
    noise = 1e-4,
    case_limit = case_limit,
    requested_case_ids = requested_case_ids,
)

println("Running support-budget sweep on $(length(selected_cases)) case(s) with budgets $(join([budget_label(p, c) for (p, c) in SUPPORT_BUDGETS], ", "))...")
case_artifacts = with_logger(NullLogger()) do
    Dict{Symbol, Any}[build_case_artifact_safe(case_spec; est_opts = est_opts, consensus_opts = consensus_opts, support_budgets = SUPPORT_BUDGETS) for case_spec in selected_cases]
end

mkpath(OUTPUT_ROOT)
write(joinpath(OUTPUT_ROOT, "summary.md"), render_summary_markdown(case_artifacts, SUPPORT_BUDGETS))
write(joinpath(OUTPUT_ROOT, "summary.csv"), render_summary_csv(case_artifacts, SUPPORT_BUDGETS))

for case_artifact in case_artifacts
    case_dir = joinpath(OUTPUT_ROOT, "cases", case_artifact[:case_id])
    mkpath(case_dir)
    write(joinpath(case_dir, "study.md"), render_case_markdown(case_artifact))
end

println("Done! Sweep artifact root: $OUTPUT_ROOT")
