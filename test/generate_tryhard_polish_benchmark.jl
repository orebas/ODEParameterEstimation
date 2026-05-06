"""
Generate a quality-first tryhard polishing benchmark against benchmark `odepe_polish`.

Policy:
- import benchmark `odepe_nopolish` raw pool from result.csv
- import benchmark `odepe_polish` reference pool from result.csv
- build `block_v2` no-polish hypotheses at 4/4 on the imported raw pool
- select top 5 distinct raw candidates by fit
- select top 5 distinct block hypotheses by block score
- merge and deduplicate the combined pool using the standard polish distance rule
- polish all merged seeds with the benchmark polish options
- compare the best local tryhard result against benchmark `odepe_polish`

Optional environment variables:
- ODEPE_SWEEP_CASE_LIMIT
- ODEPE_SWEEP_CASE_IDS
"""

using Dates
using Logging
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Statistics

const ODEPE = ODEParameterEstimation

const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "sweeps", "bilby_2026_03_09_1em4_tryhard_polish")
const RAW_TOP_K = 10
const BLOCK_TOP_K = 10
const BLOCK_SUPPORT_POINTS = 4
const BLOCK_SUPPORT_COMBOS = 4
const TIE_ATOL = 1e-4

const HARD_FAMILIES = [
    "seir",
    "daisy_mamil3",
    "fitzhugh_nagumo",
    "sirt_treatment",
    "forced_lotka_volterra",
    "boost_converter",
    "dc_motor",
]

const GUARD_FAMILIES = [
    "daisy_mamil4",
    "brusselator",
    "aircraft_pitch",
    "slow_fast",
]

case_limit = let raw = get(ENV, "ODEPE_SWEEP_CASE_LIMIT", "")
    isempty(strip(raw)) ? nothing : parse(Int, strip(raw))
end

requested_case_ids = let raw = get(ENV, "ODEPE_SWEEP_CASE_IDS", "")
    isempty(strip(raw)) ? String[] : [String(strip(part)) for part in split(raw, ',') if !isempty(strip(part))]
end

function case_dir_for_variant(case_id::AbstractString, variant::AbstractString)
    return joinpath(BENCHMARK_ROOT, "filetree", variant, case_id)
end

function case_result_exists(case_id::AbstractString)
    nopolish_dir = case_dir_for_variant(case_id, "odepe_nopolish")
    polish_dir = case_dir_for_variant(case_id, "odepe_polish")
    return isdir(nopolish_dir) &&
        isdir(polish_dir) &&
        isfile(joinpath(nopolish_dir, "result.csv")) &&
        isfile(joinpath(polish_dir, "result.csv"))
end

function hard_family_sort_key(row)
    classification_rank =
        row.classification == "a_only" ? 0 :
        row.classification == "both_success" ? 1 :
        row.classification == "b_only" ? 2 : 3
    err = isfinite(row.mean_rel_error_b) ? row.mean_rel_error_b : -Inf
    runtime = isfinite(row.time_b) ? row.time_b : Inf
    return (-err, classification_rank, runtime, row.id)
end

function guard_family_sort_key(row)
    classification_rank =
        row.classification == "both_success" ? 0 :
        row.classification == "b_only" ? 1 :
        row.classification == "a_only" ? 2 : 3
    err = isfinite(row.mean_rel_error_b) ? row.mean_rel_error_b : Inf
    runtime = isfinite(row.time_b) ? row.time_b : Inf
    return (err, classification_rank, runtime, row.id)
end

function make_case_spec(row, role::Symbol, role_label::AbstractString, selected_via::Symbol)
    return (
        case_id = row.id,
        model_name = row.name,
        role = role,
        role_label = role_label,
        selected_via = selected_via,
        nopolish_case_dir = case_dir_for_variant(row.id, "odepe_nopolish"),
        polish_case_dir = case_dir_for_variant(row.id, "odepe_polish"),
        row = row,
    )
end

function select_tryhard_cases(;
    comparison_csv_path::AbstractString = joinpath(BENCHMARK_ROOT, "analysis_results", "comparison_amigo2_run_vs_odepe_multipoint_full.csv"),
    noise::Float64 = 1e-4,
    case_limit::Union{Nothing, Int} = nothing,
    requested_case_ids::Vector{String} = String[],
)
    rows = ODEPE._read_bilby_comparison_rows(comparison_csv_path)
    noise_rows = filter(row -> isapprox(row.noise, noise; atol = 1e-12, rtol = 0.0), rows)
    row_by_id = Dict(row.id => row for row in noise_rows)

    if !isempty(requested_case_ids)
        selected = NamedTuple[]
        for case_id in requested_case_ids
            haskey(row_by_id, case_id) || continue
            row = row_by_id[case_id]
            case_result_exists(case_id) || continue
            role = row.name in HARD_FAMILIES ? :hard_target : (row.name in GUARD_FAMILIES ? :guard : :ad_hoc)
            role_label =
                role == :hard_target ? "hard target" :
                role == :guard ? "guard" : "ad hoc"
            push!(selected, make_case_spec(row, role, role_label, :requested))
        end
        return isnothing(case_limit) ? selected : selected[1:min(case_limit, length(selected))]
    end

    selected = NamedTuple[]
    seen = Set{String}()

    function push_family!(family::AbstractString, role::Symbol, role_label::AbstractString, sort_key)
        family_rows = sort(
            filter(row -> row.name == family && case_result_exists(row.id), noise_rows);
            by = sort_key,
        )
        isempty(family_rows) && return
        candidate = first(family_rows)
        candidate.id in seen && return
        push!(selected, make_case_spec(candidate, role, role_label, :family_priority))
        push!(seen, candidate.id)
    end

    for family in HARD_FAMILIES
        push_family!(family, :hard_target, "hard target", hard_family_sort_key)
    end
    for family in GUARD_FAMILIES
        push_family!(family, :guard, "guard", guard_family_sort_key)
    end

    return isnothing(case_limit) ? selected : selected[1:min(case_limit, length(selected))]
end

function zero_timing(label::Symbol)
    return ODEPE.TimingBreakdown(label = label, total_seconds = 0.0)
end

function candidate_reference_summary(
    pep::ODEPE.ParameterEstimationProblem,
    strategy::Symbol,
    candidates::Vector{ODEPE.ParameterEstimationResult},
)
    idx, best = ODEPE._best_fit_raw_candidate(candidates)
    summary = ODEPE._simple_candidate_strategy_summary(
        pep,
        strategy,
        best,
        best,
        0.0,
        0.0,
        zero_timing(strategy);
        raw_candidate_count = length(candidates),
        winner_mode = isnothing(best) ? :missing : :reference,
        t_vector = isnothing(pep.data_sample) || !haskey(pep.data_sample, "t") ? Float64[] : Float64[pep.data_sample["t"]...],
        extra = Dict{Symbol, Any}(
            :selected_index => idx,
            :reference_candidate_count => length(candidates),
        ),
    )
    summary[:status] = :ok
    return summary
end

function finalist_report_summary(
    pep::ODEPE.ParameterEstimationProblem,
    strategy::Symbol,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    block_report::Union{Nothing, ODEPE.BlockConsensusReport},
    report::ODEPE.TryhardFinalistReport,
    t_vector::Vector{Float64},
)
    timing = get(report.selection_summary, :timing, zero_timing(strategy))
    best_seed = isempty(report.merged_seed_rows) ? nothing : report.merged_seed_rows[1][:candidate]
    summary = ODEPE._simple_candidate_strategy_summary(
        pep,
        strategy,
        best_seed,
        report.best_result,
        get(report.selection_summary, :selection_seconds, 0.0),
        0.0,
        timing;
        raw_candidate_count = length(raw_candidates),
        family_count = isnothing(block_report) ? 0 : length(block_report.block_decomposition.blocks),
        winner_mode = isnothing(report.best_result) ? :missing : :refined,
        support_points = isnothing(block_report) ? Int[] : block_report.support_points,
        support_combos = isnothing(block_report) ? Vector{Vector{Int}}() : block_report.support_combos,
        t_vector = t_vector,
        extra = Dict{Symbol, Any}(
            :finalist_count => length(report.finalists),
            :winner_sources => get(report.selection_summary, :winner_sources, "none"),
            :policy_label => get(report.selection_summary, :policy_label, strategy),
            :seed_summary => report.seed_summary,
            :source_mix_counts => get(report.selection_summary, :source_mix_counts, Dict{Symbol, Int}()),
        ),
    )
    summary[:status] = get(report.selection_summary, :status, :ok)
    return summary
end

function best_finalist_truth(pep::ODEPE.ParameterEstimationProblem, report::Union{Nothing, ODEPE.TryhardFinalistReport})
    if isnothing(report) || isempty(report.finalists)
        return nothing, Dict{Symbol, Any}(), Inf
    end
    best_idx = nothing
    best_metrics = Dict{Symbol, Any}()
    best_rmse = Inf
    for (idx, finalist) in enumerate(report.finalists)
        metrics = ODEPE._candidate_truth_metrics(pep, finalist.representative_candidate)
        rmse = get(metrics, :combined_rel_rmse, Inf)
        if rmse < best_rmse
            best_idx = idx
            best_metrics = metrics
            best_rmse = rmse
        end
    end
    return best_idx, best_metrics, best_rmse
end

function _format_symbol_count_dict(dict::AbstractDict)
    isempty(dict) && return "none"
    parts = String[]
    for key in sort!(collect(keys(dict)); by = x -> string(x))
        push!(parts, "$(key)=$(dict[key])")
    end
    return join(parts, ", ")
end

function _format_reason_family_counts(dict::AbstractDict)
    isempty(dict) && return "none"
    parts = String[]
    ordered = sort!(
        collect(keys(dict));
        by = key -> (string(key[1]), string(key[2])),
    )
    for key in ordered
        push!(parts, "$(key[1])/$(key[2])=$(dict[key])")
    end
    return join(parts, ", ")
end

function finalist_set_outcome(
    polish_summary::AbstractDict{Symbol, <:Any},
    report::Union{Nothing, ODEPE.TryhardFinalistReport},
    pep::ODEPE.ParameterEstimationProblem,
)
    polish_rmse = ODEPE._summary_combined_rmse(polish_summary)
    _, _, finalist_rmse = best_finalist_truth(pep, report)
    if !isfinite(polish_rmse) || !isfinite(finalist_rmse)
        return :error
    end
    delta = polish_rmse - finalist_rmse
    if abs(delta) <= TIE_ATOL
        return :tie
    end
    return delta > 0 ? :finalist_set_better : :benchmark_polish_better
end

function finalist_set_mode(
    polish_summary::AbstractDict{Symbol, <:Any},
    raw_report::Union{Nothing, ODEPE.TryhardFinalistReport},
    block_report::Union{Nothing, ODEPE.TryhardFinalistReport},
    merged_report::Union{Nothing, ODEPE.TryhardFinalistReport},
    pep::ODEPE.ParameterEstimationProblem,
)
    merged_outcome = finalist_set_outcome(polish_summary, merged_report, pep)
    merged_outcome == :finalist_set_better || return :no_improvement
    raw_win = finalist_set_outcome(polish_summary, raw_report, pep) == :finalist_set_better
    block_win = finalist_set_outcome(polish_summary, block_report, pep) == :finalist_set_better
    raw_win && block_win && return :both_seed_families_win
    raw_win && return :baseline_seed_family_win
    block_win && return :additive_seed_family_win
    return :merged_only_win
end

function block_summary_from_report(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    report::ODEPE.BlockConsensusReport,
    selection_seconds::Float64,
    t_vector::Vector{Float64},
)
    report_timing = get(report.scoring_summary, :timing, zero_timing(:block_v2_no_polish_4x4))
    timing = ODEPE.TimingBreakdown(
        label = :block_v2_no_polish_4x4,
        total_seconds = selection_seconds,
        phases = report_timing.phases,
        details = OrderedDict{Symbol, Any}(
            pairs(report_timing.details)...,
            :block_count => length(report.block_decomposition.blocks),
            :hypothesis_count => length(report.assembled_hypotheses),
        ),
    )
    summary = ODEPE._simple_candidate_strategy_summary(
        pep,
        :block_v2_no_polish_4x4,
        report.best_result,
        report.best_result,
        selection_seconds,
        0.0,
        timing;
        raw_candidate_count = length(raw_candidates),
        family_count = length(report.block_decomposition.blocks),
        winner_mode = isnothing(report.best_result) ? :missing : :raw,
        support_points = report.support_points,
        support_combos = report.support_combos,
        t_vector = t_vector,
        extra = Dict{Symbol, Any}(
            :block_count => length(report.block_decomposition.blocks),
            :hypothesis_count => length(report.assembled_hypotheses),
            :version_label => report.version_label,
        ),
    )
    summary[:status] = :ok
    return summary
end

function build_seed_row(
    candidate::ODEPE.ParameterEstimationResult,
    origin::Symbol,
    origin_rank::Int,
    source_id::Int;
    block_score::Real = NaN,
)
    return Dict{Symbol, Any}(
        :candidate => candidate,
        :origin_tags => Set([origin]),
        :origin_label => origin == :raw ? "raw" : "block",
        :origin_rank => origin_rank,
        :source_id => source_id,
        :block_score => Float64(block_score),
        :fit_error => ODEPE._result_err_key(candidate),
        :lineage => ODEPE.lineage_summary(candidate),
    )
end

function select_top_raw_seed_rows(
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    polish_ctx::ODEPE.PolishContext;
    top_k::Int = RAW_TOP_K,
)
    indices = ODEPE._top_distinct_raw_fit_indices(raw_candidates, polish_ctx; top_k = top_k)
    rows = Dict{Symbol, Any}[]
    for (rank, idx) in enumerate(indices)
        push!(rows, build_seed_row(raw_candidates[idx], :raw, rank, idx))
    end
    return rows
end

function select_top_block_seed_rows(
    report::ODEPE.BlockConsensusReport,
    polish_ctx::ODEPE.PolishContext;
    top_k::Int = BLOCK_TOP_K,
)
    hypotheses = report.assembled_hypotheses
    isempty(hypotheses) && return Dict{Symbol, Any}[]
    candidates = ODEPE.ParameterEstimationResult[
        hypothesis.final_candidate for hypothesis in hypotheses
        if !isnothing(hypothesis.final_candidate)
    ]
    candidate_hypothesis_indices = Int[
        idx for (idx, hypothesis) in enumerate(hypotheses)
        if !isnothing(hypothesis.final_candidate)
    ]
    isempty(candidates) && return Dict{Symbol, Any}[]

    ranked = sort(
        collect(eachindex(candidates));
        by = i -> (
            hypotheses[candidate_hypothesis_indices[i]].final_combined_score,
            ODEPE._result_err_key(candidates[i]),
            candidate_hypothesis_indices[i],
        ),
    )
    selected_local = ODEPE._select_distinct_candidate_indices_by_order(
        candidates,
        polish_ctx,
        ranked;
        top_k = top_k,
    )
    rows = Dict{Symbol, Any}[]
    for (rank, local_idx) in enumerate(selected_local)
        hypothesis_idx = candidate_hypothesis_indices[local_idx]
        hypothesis = hypotheses[hypothesis_idx]
        push!(rows, build_seed_row(
            hypothesis.final_candidate,
            :block,
            rank,
            hypothesis_idx;
            block_score = hypothesis.final_combined_score,
        ))
    end
    return rows
end

function merge_distinct_seed_rows(
    seed_rows::Vector{Dict{Symbol, Any}},
    polish_ctx::ODEPE.PolishContext;
    threshold::Float64 = 0.001,
)
    isempty(seed_rows) && return Dict{Symbol, Any}[]
    merged = Dict{Symbol, Any}[]
    cached_vectors = IdDict{Any, Vector{Float64}}()

    for row in seed_rows
        candidate = row[:candidate]
        vector = get!(cached_vectors, candidate) do
            ODEPE._polish_seed_vector(candidate, polish_ctx)
        end
        matched = false
        for existing in merged
            existing_candidate = existing[:candidate]
            existing_vector = get!(cached_vectors, existing_candidate) do
                ODEPE._polish_seed_vector(existing_candidate, polish_ctx)
            end
            if ODEPE._polish_seed_relative_distance(vector, existing_vector) <= threshold
                union!(existing[:origin_tags], row[:origin_tags])
                existing[:members] = get(existing, :members, String[])  # ensure present
                push!(existing[:members], "$(row[:origin_label])#$(row[:source_id])")
                if row[:fit_error] < existing[:fit_error]
                    existing[:candidate] = candidate
                    existing[:fit_error] = row[:fit_error]
                    existing[:lineage] = row[:lineage]
                    existing[:block_score] = row[:block_score]
                    existing[:representative_origin_label] = row[:origin_label]
                    existing[:representative_source_id] = row[:source_id]
                end
                matched = true
                break
            end
        end
        matched && continue
        push!(merged, Dict{Symbol, Any}(
            :candidate => candidate,
            :origin_tags => Set(row[:origin_tags]),
            :members => String["$(row[:origin_label])#$(row[:source_id])"],
            :fit_error => row[:fit_error],
            :lineage => row[:lineage],
            :block_score => row[:block_score],
            :representative_origin_label => row[:origin_label],
            :representative_source_id => row[:source_id],
        ))
    end
    return merged
end

function origin_tag_text(tags::Set{Symbol})
    isempty(tags) && return "none"
    ordered = sort!(collect(String(tag) for tag in tags))
    return join(ordered, "+")
end

function polish_merged_seed_rows(
    pep::ODEPE.ParameterEstimationProblem,
    run_opts::ODEPE.EstimationOptions,
    polish_ctx::ODEPE.PolishContext,
    merged_seed_rows::Vector{Dict{Symbol, Any}},
)
    polished_rows = Dict{Symbol, Any}[]
    polish_seconds = 0.0

    for (rank, row) in enumerate(merged_seed_rows)
        polished = nothing
        err_text = nothing
        elapsed = @elapsed begin
            try
                polished = ODEPE._polish_research_seed(pep, row[:candidate], polish_ctx, run_opts)
            catch err
                err_text = sprint(showerror, err)
            end
        end
        polish_seconds += elapsed
        polished_truth = isnothing(polished) ? Dict{Symbol, Any}() : ODEPE._candidate_truth_metrics(pep, polished)
        push!(polished_rows, Dict{Symbol, Any}(
            :rank => rank,
            :sources => origin_tag_text(row[:origin_tags]),
            :members => join(row[:members], ", "),
            :seed_fit_error => row[:fit_error],
            :seed_lineage => row[:lineage],
            :seed_candidate => row[:candidate],
            :polished_candidate => polished,
            :polished_truth_metrics => polished_truth,
            :polish_seconds => elapsed,
            :error_message => err_text,
        ))
    end

    best_idx = nothing
    best_err = Inf
    for (idx, row) in enumerate(polished_rows)
        polished = row[:polished_candidate]
        isnothing(polished) && continue
        err = ODEPE._result_err_key(polished)
        if err < best_err
            best_err = err
            best_idx = idx
        end
    end
    return polished_rows, best_idx, polish_seconds
end

function tryhard_summary(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    block_report::Union{Nothing, ODEPE.BlockConsensusReport},
    merged_seed_rows::Vector{Dict{Symbol, Any}},
    polished_rows::Vector{Dict{Symbol, Any}},
    best_polished_idx::Union{Nothing, Int},
    selection_seconds::Float64,
    t_vector::Vector{Float64};
    context_seconds::Float64,
    baseline_report_seconds::Float64,
    block_seconds::Float64,
    polish_context_seconds::Float64,
    polish_seconds::Float64,
    raw_seed_count::Int,
    block_seed_count::Int,
    degraded_without_block::Bool,
)
    best_seed = isempty(merged_seed_rows) ? nothing : merged_seed_rows[1][:candidate]
    winner_row = isnothing(best_polished_idx) ? nothing : polished_rows[best_polished_idx]
    final_candidate = isnothing(winner_row) ? nothing : winner_row[:polished_candidate]
    winner_sources = isnothing(winner_row) ? "none" : winner_row[:sources]
    timing = ODEPE.TimingBreakdown(
        label = :tryhard_pooled_polish,
        total_seconds = selection_seconds,
        phases = ODEPE.TimingPhaseEntry[
            ODEPE.TimingPhaseEntry("build_consensus_context", context_seconds, 0, 0.0),
            ODEPE.TimingPhaseEntry("build_baseline_report", baseline_report_seconds, 0, 0.0),
            ODEPE.TimingPhaseEntry("build_block_report", block_seconds, 0, 0.0),
            ODEPE.TimingPhaseEntry("build_polish_context", polish_context_seconds, 0, 0.0),
            ODEPE.TimingPhaseEntry("polish_seed_pool", polish_seconds, 0, 0.0),
        ],
        details = OrderedDict{Symbol, Any}(
            :raw_seed_count => raw_seed_count,
            :block_seed_count => block_seed_count,
            :merged_seed_count => length(merged_seed_rows),
            :polished_seed_count => count(row -> !isnothing(row[:polished_candidate]), polished_rows),
            :winner_sources => winner_sources,
            :degraded_without_block => degraded_without_block,
        ),
    )
    summary = ODEPE._simple_candidate_strategy_summary(
        pep,
        :tryhard_pooled_polish,
        best_seed,
        final_candidate,
        selection_seconds,
        0.0,
        timing;
        raw_candidate_count = length(raw_candidates),
        family_count = isnothing(block_report) ? 0 : length(block_report.block_decomposition.blocks),
        winner_mode = isnothing(final_candidate) ? :missing : :refined,
        support_points = isnothing(block_report) ? Int[] : block_report.support_points,
        support_combos = isnothing(block_report) ? Vector{Vector{Int}}() : block_report.support_combos,
        t_vector = t_vector,
        extra = Dict{Symbol, Any}(
            :raw_seed_count => raw_seed_count,
            :block_seed_count => block_seed_count,
            :merged_seed_count => length(merged_seed_rows),
            :polished_seed_count => count(row -> !isnothing(row[:polished_candidate]), polished_rows),
            :winner_sources => winner_sources,
            :degraded_without_block => degraded_without_block,
            :local_total_seconds => selection_seconds,
            :local_polish_seconds => polish_seconds,
            :local_context_seconds => context_seconds,
            :local_baseline_report_seconds => baseline_report_seconds,
            :local_block_seconds => block_seconds,
        ),
    )
    summary[:status] = isnothing(final_candidate) ? :error : :ok
    return summary
end

function compare_tryhard_to_polish(case_artifact::AbstractDict{Symbol, <:Any})
    tryhard_rmse = ODEPE._summary_combined_rmse(case_artifact[:tryhard_summary])
    polish_rmse = ODEPE._summary_combined_rmse(case_artifact[:benchmark_polish_summary])
    if !isfinite(tryhard_rmse) || !isfinite(polish_rmse)
        return :error
    end
    delta = polish_rmse - tryhard_rmse
    if abs(delta) <= TIE_ATOL
        return :tie
    end
    return delta > 0 ? :tryhard_better : :benchmark_polish_better
end

function improvement_mode(case_artifact::AbstractDict{Symbol, <:Any})
    outcome = compare_tryhard_to_polish(case_artifact)
    outcome == :tryhard_better || return :no_improvement
    tags = get(case_artifact[:tryhard_summary], :winner_sources, "none")
    tags == "baseline" && return :baseline_seed_family_win
    tags == "additive" && return :additive_seed_family_win
    return :both_seed_families_win
end

function build_case_artifact(case_spec)
    generated_at = string(Dates.now())
    polish_case = ODEPE._load_bilby_case(case_spec.polish_case_dir)
    pep_original = polish_case.pep
    datasize = isnothing(pep_original.data_sample) || !haskey(pep_original.data_sample, "t") ? 0 : length(pep_original.data_sample["t"])
    polish_run_opts = ODEPE.merge_options(
        isnothing(polish_case.benchmark_opts) ? ODEPE.EstimationOptions() : polish_case.benchmark_opts;
        datasize = datasize,
        nooutput = true,
        diagnostics = false,
        save_system = false,
    )
    block_run_opts = ODEPE.merge_options(
        ODEPE._default_sweep_estimation_options();
        datasize = datasize,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = false,
        polish_solver_solutions = false,
    )
    pep_block = pep_original
    if block_run_opts.auto_handle_transcendentals
        t_var = ModelingToolkit.get_iv(pep_block.model.system)
        pep_block, _ = ODEPE.transform_pep_for_estimation(pep_block, t_var)
    end
    t_vector = isnothing(pep_original.data_sample) || !haskey(pep_original.data_sample, "t") ? Float64[] : Float64[pep_original.data_sample["t"]...]

    nopolish_candidates = ODEPE.ParameterEstimationResult[]
    polish_candidates = ODEPE.ParameterEstimationResult[]
    reference_load_seconds = @elapsed begin
        nopolish_candidates = ODEPE._load_benchmark_result_candidates(pep_original, polish_run_opts, case_spec.nopolish_case_dir)
        polish_candidates = ODEPE._load_benchmark_result_candidates(pep_original, polish_run_opts, case_spec.polish_case_dir)
    end

    benchmark_nopolish_summary = candidate_reference_summary(pep_original, :benchmark_odepe_nopolish, nopolish_candidates)
    benchmark_polish_summary = candidate_reference_summary(pep_original, :benchmark_odepe_polish, polish_candidates)
    raw_pool = ODEPE._consensus_raw_pool_summary(pep_original, nopolish_candidates)
    raw_pool = merge(raw_pool, Dict{Symbol, Any}(
        :raw_candidate_count => length(nopolish_candidates),
        :best_fit_vs_truth_gap => ODEPE._raw_fit_truth_gap(raw_pool),
    ))

    context = nothing
    context_seconds = @elapsed context = ODEPE._build_consensus_context(pep_block, block_run_opts)

    baseline_consensus_opts = ODEPE.ConsensusOptions(
        strategy = :best_fit_baseline,
        support_point_count = BLOCK_SUPPORT_POINTS,
        support_combo_count = BLOCK_SUPPORT_COMBOS,
    )
    baseline_report = nothing
    baseline_report_seconds = 0.0
    baseline_report_error = nothing
    try
        baseline_report_seconds = @elapsed baseline_report = ODEPE._assemble_consensus_report(
            pep_block,
            block_run_opts,
            nopolish_candidates,
            baseline_consensus_opts;
            context = context,
        )
    catch err
        baseline_report_error = sprint(showerror, err)
    end

    block_report = nothing
    block_summary = nothing
    block_seconds = 0.0
    block_error = nothing
    branch_report = nothing
    branch_seconds = 0.0
    branch_error = nothing
    synth_report = nothing
    synth_seconds = 0.0
    synth_error = nothing
    try
        block_opts = ODEPE.BlockConsensusOptions(
            support_point_count = BLOCK_SUPPORT_POINTS,
            support_combo_count = BLOCK_SUPPORT_COMBOS,
            enable_polish = false,
        )
        block_report, _ = ODEPE._block_no_polish_strategy(
            pep_block,
            block_run_opts,
            nopolish_candidates,
            context,
            0.0,
            t_vector;
            baseline_report = baseline_report,
            force_reuse_baseline = !isnothing(baseline_report),
            block_opts = block_opts,
        )
        block_timing = get(block_report.scoring_summary, :timing, zero_timing(:block_v2_no_polish_4x4))
        block_seconds = block_timing.total_seconds
        block_summary = block_summary_from_report(pep_original, nopolish_candidates, block_report, block_seconds, t_vector)
        block_summary[:status] = get(block_summary, :status, :ok)
    catch err
        block_error = sprint(showerror, err)
        block_summary = ODEPE._method_failure_summary(:block_v2_no_polish_4x4, err, 0.0, length(nopolish_candidates), 0)
        block_summary[:status] = :error
    end

    try
        branch_opts = ODEPE.BranchConsensusOptions(
            support_point_count = BLOCK_SUPPORT_POINTS,
            support_combo_count = BLOCK_SUPPORT_COMBOS,
        )
        branch_seconds = @elapsed branch_report = ODEPE._assemble_branch_consensus_report(
            pep_block,
            block_run_opts,
            nopolish_candidates,
            branch_opts;
            context = context,
        )
    catch err
        branch_error = sprint(showerror, err)
    end

    try
        synth_defaults = ODEPE._default_sweep_synthesized_options()
        synth_opts = ODEPE.SynthesizedFinalizerOptions(
            base_consensus_opts = ODEPE.ConsensusOptions(
                strategy = :family_consensus,
                support_point_count = BLOCK_SUPPORT_POINTS,
                support_combo_count = BLOCK_SUPPORT_COMBOS,
                refine_top_families = 1,
                do_equation_refit = false,
            ),
            max_family_seeds = synth_defaults.max_family_seeds,
            max_cross_family_seeds = synth_defaults.max_cross_family_seeds,
            allow_cross_family_synthesis = synth_defaults.allow_cross_family_synthesis,
            allow_parameter_stitching = synth_defaults.allow_parameter_stitching,
            cross_family_distance_limit = synth_defaults.cross_family_distance_limit,
            seed_consistency_threshold = synth_defaults.seed_consistency_threshold,
            max_refine_candidates = synth_defaults.max_refine_candidates,
            refine_with_full_trajectory = synth_defaults.refine_with_full_trajectory,
            refine_objective_mode = synth_defaults.refine_objective_mode,
        )
        synth_seconds = @elapsed synth_report = ODEPE._research_synthesized_finalizer_from_shared(
            pep_block,
            block_run_opts,
            nopolish_candidates,
            context,
            synth_opts,
        )
    catch err
        synth_error = sprint(showerror, err)
    end

    polish_ctx = nothing
    polish_context_seconds = @elapsed polish_ctx = ODEPE._build_polish_context(pep_original; opts = polish_run_opts)
    tryhard_opts = ODEPE.TryhardFinalistOptions(
        block_support_point_count = BLOCK_SUPPORT_POINTS,
        block_support_combo_count = BLOCK_SUPPORT_COMBOS,
    )
    baseline_seed_rows = ODEPE._select_tryhard_baseline_seed_rows(
        nopolish_candidates,
        polish_ctx;
        opts = polish_run_opts,
    )
    block_seed_rows = isnothing(block_report) ? Dict{Symbol, Any}[] : ODEPE._collect_tryhard_block_seed_rows(
        block_report,
        polish_ctx;
        threshold = tryhard_opts.distinctness_threshold,
    )
    branch_seed_rows = isnothing(branch_report) ? Dict{Symbol, Any}[] : ODEPE._collect_tryhard_branch_seed_rows(
        branch_report,
        polish_ctx;
        threshold = tryhard_opts.distinctness_threshold,
    )
    synthesized_seed_rows = isnothing(synth_report) ? Dict{Symbol, Any}[] : ODEPE._collect_tryhard_synthesized_seed_rows(
        synth_report,
        polish_ctx;
        threshold = tryhard_opts.distinctness_threshold,
    )
    additive_seed_rows = ODEPE._merge_tryhard_seed_rows(
        vcat(block_seed_rows, branch_seed_rows, synthesized_seed_rows),
        polish_ctx;
        threshold = tryhard_opts.distinctness_threshold,
    )
    frontier_seed_rows, rejected_additive_seed_rows, frontier_metadata = ODEPE._build_reasonable_tryhard_frontier(
        baseline_seed_rows,
        additive_seed_rows,
        polish_ctx,
        tryhard_opts;
        threshold = tryhard_opts.distinctness_threshold,
    )

    raw_finalist_report = ODEPE._assemble_tryhard_finalist_report(
        pep_original,
        polish_run_opts,
        nopolish_candidates,
        polish_ctx,
        baseline_seed_rows,
        baseline_seed_rows;
        block_report = block_report,
        branch_report = branch_report,
        synth_report = synth_report,
        block_seed_rows = block_seed_rows,
        branch_seed_rows = branch_seed_rows,
        synthesized_seed_rows = synthesized_seed_rows,
        additive_seed_rows = Dict{Symbol, Any}[],
        rejected_additive_seed_rows = Dict{Symbol, Any}[],
        frontier_metadata = Dict{Symbol, Any}(
            :frontier_limit => length(baseline_seed_rows),
            :fit_limit => ODEPE._tryhard_reasonable_fit_limit(baseline_seed_rows),
            :rejection_counts => Dict{Symbol, Int}(),
        ),
        policy_label = :baseline_polish_finalists,
        finalists_opts = tryhard_opts,
    )
    block_finalist_report = ODEPE._assemble_tryhard_finalist_report(
        pep_original,
        polish_run_opts,
        nopolish_candidates,
        polish_ctx,
        Dict{Symbol, Any}[],
        additive_seed_rows;
        block_report = block_report,
        branch_report = branch_report,
        synth_report = synth_report,
        block_seed_rows = block_seed_rows,
        branch_seed_rows = branch_seed_rows,
        synthesized_seed_rows = synthesized_seed_rows,
        additive_seed_rows = additive_seed_rows,
        rejected_additive_seed_rows = Dict{Symbol, Any}[],
        frontier_metadata = Dict{Symbol, Any}(
            :frontier_limit => length(additive_seed_rows),
            :fit_limit => ODEPE._tryhard_reasonable_fit_limit(baseline_seed_rows),
            :rejection_counts => Dict{Symbol, Int}(),
        ),
        policy_label = :additive_generator_finalists,
        finalists_opts = tryhard_opts,
    )
    merged_finalist_report = ODEPE._assemble_tryhard_finalist_report(
        pep_original,
        polish_run_opts,
        nopolish_candidates,
        polish_ctx,
        baseline_seed_rows,
        frontier_seed_rows;
        block_report = block_report,
        branch_report = branch_report,
        synth_report = synth_report,
        block_seed_rows = block_seed_rows,
        branch_seed_rows = branch_seed_rows,
        synthesized_seed_rows = synthesized_seed_rows,
        additive_seed_rows = additive_seed_rows,
        rejected_additive_seed_rows = rejected_additive_seed_rows,
        frontier_metadata = frontier_metadata,
        policy_label = :reasonable_frontier_finalists,
        finalists_opts = tryhard_opts,
    )
    for row in merged_finalist_report.polished_seed_rows
        polished = row[:polished_candidate]
        row[:polished_truth_metrics] = isnothing(polished) ? Dict{Symbol, Any}() : ODEPE._candidate_truth_metrics(pep_original, polished)
    end
    merged_finalist_truth_rows = [
        ODEPE._candidate_truth_metrics(pep_original, finalist.representative_candidate)
        for finalist in merged_finalist_report.finalists
    ]

    raw_finalist_summary = finalist_report_summary(
        pep_original,
        :baseline_polish_finalists,
        nopolish_candidates,
        block_report,
        raw_finalist_report,
        t_vector,
    )
    block_finalist_summary = finalist_report_summary(
        pep_original,
        :additive_generator_finalists,
        nopolish_candidates,
        block_report,
        block_finalist_report,
        t_vector,
    )
    merged_finalist_summary = finalist_report_summary(
        pep_original,
        :reasonable_frontier_finalists,
        nopolish_candidates,
        block_report,
        merged_finalist_report,
        t_vector,
    )

    raw_best_finalist_idx, raw_best_finalist_metrics, raw_best_finalist_rmse = best_finalist_truth(pep_original, raw_finalist_report)
    block_best_finalist_idx, block_best_finalist_metrics, block_best_finalist_rmse = best_finalist_truth(pep_original, block_finalist_report)
    merged_best_finalist_idx, merged_best_finalist_metrics, merged_best_finalist_rmse = best_finalist_truth(pep_original, merged_finalist_report)

    tryhard_polish_seconds =
        get(raw_finalist_report.selection_summary, :selection_seconds, 0.0) +
        get(block_finalist_report.selection_summary, :selection_seconds, 0.0) +
        get(merged_finalist_report.selection_summary, :selection_seconds, 0.0)
    total_local_seconds =
        context_seconds +
        baseline_report_seconds +
        block_seconds +
        branch_seconds +
        synth_seconds +
        polish_context_seconds +
        tryhard_polish_seconds

    return Dict{Symbol, Any}(
        :case_id => case_spec.case_id,
        :model_name => case_spec.model_name,
        :role => case_spec.role,
        :role_label => case_spec.role_label,
        :selected_via => case_spec.selected_via,
        :generated_at => generated_at,
        :nopolish_case_dir => case_spec.nopolish_case_dir,
        :polish_case_dir => case_spec.polish_case_dir,
        :benchmark_reference => case_spec.row,
        :status => :ok,
        :datasize => datasize,
        :reference_load_seconds => reference_load_seconds,
        :context_seconds => context_seconds,
        :baseline_report_seconds => baseline_report_seconds,
        :block_seconds => block_seconds,
        :branch_seconds => branch_seconds,
        :synth_seconds => synth_seconds,
        :polish_context_seconds => polish_context_seconds,
        :polish_seconds => tryhard_polish_seconds,
        :local_total_seconds => total_local_seconds,
        :raw_candidate_count => length(nopolish_candidates),
        :polish_reference_candidate_count => length(polish_candidates),
        :raw_pool => raw_pool,
        :benchmark_nopolish_summary => benchmark_nopolish_summary,
        :benchmark_polish_summary => benchmark_polish_summary,
        :block_no_polish_summary => block_summary,
        :branch_error => branch_error,
        :synth_error => synth_error,
        :raw_finalist_report => raw_finalist_report,
        :block_finalist_report => block_finalist_report,
        :merged_finalist_report => merged_finalist_report,
        :raw_finalist_summary => raw_finalist_summary,
        :block_finalist_summary => block_finalist_summary,
        :tryhard_summary => merged_finalist_summary,
        :raw_seed_rows => baseline_seed_rows,
        :block_seed_rows => additive_seed_rows,
        :branch_seed_rows => branch_seed_rows,
        :synthesized_seed_rows => synthesized_seed_rows,
        :merged_seed_rows => merged_finalist_report.merged_seed_rows,
        :rejected_additive_seed_rows => rejected_additive_seed_rows,
        :polished_seed_rows => merged_finalist_report.polished_seed_rows,
        :raw_best_finalist_index => raw_best_finalist_idx,
        :raw_best_finalist_metrics => raw_best_finalist_metrics,
        :raw_best_finalist_rmse => raw_best_finalist_rmse,
        :block_best_finalist_index => block_best_finalist_idx,
        :block_best_finalist_metrics => block_best_finalist_metrics,
        :block_best_finalist_rmse => block_best_finalist_rmse,
        :merged_best_finalist_index => merged_best_finalist_idx,
        :merged_best_finalist_metrics => merged_best_finalist_metrics,
        :merged_best_finalist_rmse => merged_best_finalist_rmse,
        :merged_finalist_truth_rows => merged_finalist_truth_rows,
        :baseline_report_error => baseline_report_error,
        :block_error => block_error,
        :comparison_outcome => finalist_set_outcome(benchmark_polish_summary, merged_finalist_report, pep_original),
        :improvement_mode => finalist_set_mode(
            benchmark_polish_summary,
            raw_finalist_report,
            block_finalist_report,
            merged_finalist_report,
            pep_original,
        ),
    )
end

function build_case_artifact_safe(case_spec)
    try
        return build_case_artifact(case_spec)
    catch err
        return Dict{Symbol, Any}(
            :case_id => case_spec.case_id,
            :model_name => case_spec.model_name,
            :role => case_spec.role,
            :role_label => case_spec.role_label,
            :selected_via => case_spec.selected_via,
            :generated_at => string(Dates.now()),
            :nopolish_case_dir => case_spec.nopolish_case_dir,
            :polish_case_dir => case_spec.polish_case_dir,
            :benchmark_reference => case_spec.row,
            :status => :error,
            :error_message => sprint(showerror, err),
        )
    end
end

function worst_error_text(summary)
    row = ODEPE._summary_worst_row(summary)
    return isnothing(row) ? "none" : "$(row.label) ($(ODEPE._fmt_percent(row.rel_error)))"
end

function render_case_markdown(case_artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "# Tryhard Finalist Benchmark Case: $(case_artifact[:case_id])\n")
    println(io, "- Model: `$(case_artifact[:model_name])`")
    println(io, "- Role: `$(case_artifact[:role_label])`")
    println(io, "- Selected via: `$(case_artifact[:selected_via])`")
    println(io, "- Generated: `$(case_artifact[:generated_at])`")
    println(io, "- Status: `$(case_artifact[:status])`")
    println(io, "- Nopolish case dir: `$(case_artifact[:nopolish_case_dir])`")
    println(io, "- Polish case dir: `$(case_artifact[:polish_case_dir])`\n")

    if case_artifact[:status] != :ok
        println(io, "## Failure\n")
        println(io, "- Error: `$(get(case_artifact, :error_message, "unknown"))`")
        return String(take!(io))
    end

    ref = case_artifact[:benchmark_reference]
    println(io, "## Comparison-Table Reference\n")
    println(io, "- Classification: `$(ref.classification)`")
    println(io, "- Comparison CSV ODEPE mean/max relative error: $(ODEPE._fmt_percent(ref.mean_rel_error_b)) / $(ODEPE._fmt_percent(ref.max_rel_error_b))")
    println(io, "- Comparison CSV ODEPE runtime: $(ODEPE._fmt_float(ref.time_b; digits = 3)) s\n")

    println(io, "## Benchmark References\n")
    println(io, "| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |")
    println(io, "|----------|-----------------|---------------|-------------|-----------|")
    for (label, summary, count) in [
        ("odepe_nopolish", case_artifact[:benchmark_nopolish_summary], case_artifact[:raw_candidate_count]),
        ("odepe_polish", case_artifact[:benchmark_polish_summary], case_artifact[:polish_reference_candidate_count]),
    ]
        println(io, "| `$(label)` | $(count) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(summary))) | $(worst_error_text(summary)) | $(ODEPE._fmt_sci(ODEPE._summary_fit_error(summary))) |")
    end
    println(io)

    raw_pool = case_artifact[:raw_pool]
    println(io, "## Imported Raw Pool\n")
    println(io, "- Raw imported candidates: $(case_artifact[:raw_candidate_count])")
    println(io, "- Best raw fit index: $(get(raw_pool, :best_fit_index, nothing))")
    println(io, "- Best raw oracle index: $(get(raw_pool, :best_truth_index, nothing))")
    println(io, "- Best-fit vs best-truth combined-RMSE gap: $(ODEPE._fmt_percent(get(raw_pool, :best_fit_vs_truth_gap, Inf)))\n")

    println(io, "## Local Tryhard Runtime\n")
    println(io, "- Reference CSV load/scoring: $(ODEPE._fmt_float(case_artifact[:reference_load_seconds]; digits = 3)) s")
    println(io, "- Consensus/block context: $(ODEPE._fmt_float(case_artifact[:context_seconds]; digits = 3)) s")
    println(io, "- 4x4 baseline evidence report: $(ODEPE._fmt_float(case_artifact[:baseline_report_seconds]; digits = 3)) s")
    println(io, "- 4x4 block no-polish report: $(ODEPE._fmt_float(case_artifact[:block_seconds]; digits = 3)) s")
    println(io, "- Polish context build: $(ODEPE._fmt_float(case_artifact[:polish_context_seconds]; digits = 3)) s")
    println(io, "- Baseline-only finalists: $(ODEPE._fmt_float(get(case_artifact[:raw_finalist_report].selection_summary, :selection_seconds, 0.0); digits = 3)) s")
    println(io, "- Additive-only finalists: $(ODEPE._fmt_float(get(case_artifact[:block_finalist_report].selection_summary, :selection_seconds, 0.0); digits = 3)) s")
    println(io, "- Reasonable frontier finalists: $(ODEPE._fmt_float(get(case_artifact[:merged_finalist_report].selection_summary, :selection_seconds, 0.0); digits = 3)) s")
    println(io, "- Local total (excluding reference load): $(ODEPE._fmt_float(case_artifact[:local_total_seconds]; digits = 3)) s\n")

    println(io, "## Local Policy Comparison\n")
    println(io, "| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |")
    println(io, "|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|")
    local_rows = [
        (
            "best imported raw",
            case_artifact[:benchmark_nopolish_summary],
            ODEPE._summary_combined_rmse(case_artifact[:benchmark_nopolish_summary]),
            length(case_artifact[:raw_seed_rows]),
            "raw",
            "benchmark nopolish best-fit reference",
        ),
        (
            "benchmark odepe_polish",
            case_artifact[:benchmark_polish_summary],
            ODEPE._summary_combined_rmse(case_artifact[:benchmark_polish_summary]),
            case_artifact[:polish_reference_candidate_count],
            "benchmark",
            "saved benchmark polished reference",
        ),
        (
            "block_v2_no_polish_4x4",
            case_artifact[:block_no_polish_summary],
            ODEPE._summary_combined_rmse(case_artifact[:block_no_polish_summary]),
            length(case_artifact[:block_seed_rows]),
            "block",
            "best block seed before polish",
        ),
        (
            "baseline_polish_finalists",
            case_artifact[:raw_finalist_summary],
            case_artifact[:raw_best_finalist_rmse],
            length(case_artifact[:raw_finalist_report].finalists),
            get(case_artifact[:raw_finalist_report].selection_summary, :winner_sources, "none"),
            "baseline standard-polish declustered seeds only",
        ),
        (
            "additive_generator_finalists",
            case_artifact[:block_finalist_summary],
            case_artifact[:block_best_finalist_rmse],
            length(case_artifact[:block_finalist_report].finalists),
            get(case_artifact[:block_finalist_report].selection_summary, :winner_sources, "none"),
            "all additive generator seeds only",
        ),
        (
            "reasonable_frontier_finalists",
            case_artifact[:tryhard_summary],
            case_artifact[:merged_best_finalist_rmse],
            length(case_artifact[:merged_finalist_report].finalists),
            get(case_artifact[:merged_finalist_report].selection_summary, :winner_sources, "none"),
            "baseline seeds plus filtered additive frontier, then polished",
        ),
    ]
    for (label, summary, best_in_set_rmse, finalist_count, winner_sources, notes) in local_rows
        println(io, "| `$(label)` | `$(get(summary, :status, :ok))` | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(summary))) | $(ODEPE._fmt_percent(best_in_set_rmse)) | $(finalist_count) | `$(winner_sources)` | $(ODEPE._fmt_sci(ODEPE._summary_fit_error(summary))) | $(notes) |")
    end
    println(io)

    println(io, "## Finalist-Set Outcome\n")
    println(io, "- Benchmark `odepe_polish` vs merged finalist set: `$(case_artifact[:comparison_outcome])`")
    println(io, "- Improvement mode: `$(case_artifact[:improvement_mode])`")
    println(io, "- Baseline best finalist index / RMSE: $(case_artifact[:raw_best_finalist_index]) / $(ODEPE._fmt_percent(case_artifact[:raw_best_finalist_rmse]))")
    println(io, "- Additive best finalist index / RMSE: $(case_artifact[:block_best_finalist_index]) / $(ODEPE._fmt_percent(case_artifact[:block_best_finalist_rmse]))")
    println(io, "- Frontier best finalist index / RMSE: $(case_artifact[:merged_best_finalist_index]) / $(ODEPE._fmt_percent(case_artifact[:merged_best_finalist_rmse]))")
    println(io, "- Baseline preserved seeds: $(length(case_artifact[:raw_seed_rows]))")
    println(io, "- Additive candidate seeds: $(length(case_artifact[:block_seed_rows]))")
    println(io, "- Frontier admitted seeds: $(length(case_artifact[:merged_seed_rows]))")
    println(io, "- Rejected additive seeds: $(length(case_artifact[:rejected_additive_seed_rows]))")
    println(io, "- Successful merged polished seeds: $(count(row -> !isnothing(row[:polished_candidate]), case_artifact[:polished_seed_rows]))")
    println(io, "- Post-polish basin metric: `$(get(case_artifact[:merged_finalist_report].selection_summary, :post_polish_metric, :unknown))`")
    println(io, "- Pre-polish distinctness threshold: $(ODEPE._fmt_float(get(case_artifact[:merged_finalist_report].selection_summary, :pre_polish_distinctness_threshold, Inf); digits = 4))")
    println(io, "- Post-polish trajectory threshold: $(ODEPE._fmt_float(get(case_artifact[:merged_finalist_report].selection_summary, :post_polish_traj_threshold, Inf); digits = 4))")
    println(io, "- Post-polish secondary threshold: $(ODEPE._fmt_float(get(case_artifact[:merged_finalist_report].selection_summary, :post_polish_secondary_threshold, Inf); digits = 4))")
    println(io, "- Post-polish basin threshold: $(ODEPE._fmt_float(get(case_artifact[:merged_finalist_report].selection_summary, :post_polish_basin_threshold, Inf); digits = 4))")
    println(io, "- Admitted additive by family: $(_format_symbol_count_dict(get(case_artifact[:merged_finalist_report].selection_summary, :admitted_additive_family_counts, Dict{Symbol, Int}())))")
    println(io, "- Rejected additive by reason/family: $(_format_reason_family_counts(get(case_artifact[:merged_finalist_report].selection_summary, :rejected_additive_reason_family_counts, Dict{Tuple{Symbol, Symbol}, Int}())))")
    basin_histogram = get(case_artifact[:merged_finalist_report].selection_summary, :basin_histogram, Dict{Symbol, Int}())
    clustering_summary = get(case_artifact[:merged_finalist_report].selection_summary, :clustering_summary, Dict{Symbol, Any}())
    println(io, "- Merge mode counts: $(_format_symbol_count_dict(get(clustering_summary, :merge_mode_counts, Dict{Symbol, Int}())))")
    println(io, "- Representative update counts: $(_format_symbol_count_dict(get(clustering_summary, :representative_update_counts, Dict{Symbol, Int}())))")
    println(io, "- Basin histogram: singletons=$(get(basin_histogram, :singleton, 0)), multi=$(get(basin_histogram, :multi_member, 0)), largest=$(get(basin_histogram, :largest, 0))")
    println(io, "- Returned merged finalists: $(length(case_artifact[:merged_finalist_report].finalists))\n")

    println(io, "## Baseline Seed Pool\n")
    println(io, "| Rank | Source | Candidate Index | Fit Error | Lineage |")
    println(io, "|------|--------|-----------------|-----------|---------|")
    for row in case_artifact[:raw_seed_rows]
        println(io, "| $(row[:origin_rank]) | `baseline` | $(row[:source_id]) | $(ODEPE._fmt_sci(row[:fit_error])) | $(row[:lineage]) |")
    end
    isempty(case_artifact[:raw_seed_rows]) && println(io, "| 1 | `none` | - | Inf | none |")
    println(io)

    println(io, "## Additive Seed Pool\n")
    println(io, "| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |")
    println(io, "|------|---------|-----------|-----------------|-----------|---------|")
    for row in case_artifact[:block_seed_rows]
        score = haskey(row, :generator_score) ? row[:generator_score] : row[:block_score]
        println(io, "| $(row[:best_origin_rank]) | `$(ODEPE._tryhard_origin_tag_text(row[:origin_tags]))` | $(row[:representative_source_id]) | $(ODEPE._fmt_float(score; digits = 4)) | $(ODEPE._fmt_sci(row[:fit_error])) | $(row[:lineage]) |")
    end
    isempty(case_artifact[:block_seed_rows]) && println(io, "| 1 | `none` | - | Inf | Inf | none |")
    println(io)

    println(io, "## Rejected Additive Seeds\n")
    println(io, "| Rank | Sources | Reason | Dist | New Families | Fit Error | Lineage |")
    println(io, "|------|---------|--------|------|--------------|-----------|---------|")
    for (rank, row) in enumerate(case_artifact[:rejected_additive_seed_rows])
        new_families = haskey(row, :new_family_tags) && !isempty(row[:new_family_tags]) ? join(row[:new_family_tags], ",") : "-"
        println(io, "| $(rank) | `$(ODEPE._tryhard_origin_tag_text(row[:origin_tags]))` | `$(row[:decision_reason])` | $(ODEPE._fmt_float(get(row, :nearest_admitted_distance, Inf); digits = 4)) | `$(new_families)` | $(ODEPE._fmt_sci(row[:fit_error])) | $(row[:lineage]) |")
    end
    isempty(case_artifact[:rejected_additive_seed_rows]) && println(io, "| 1 | `none` | `none` | Inf | `-` | Inf | none |")
    println(io)

    println(io, "## Reasonable Frontier Seed Pool\n")
    println(io, "| Rank | Sources | Members | Seed Fit Error | Representative Lineage |")
    println(io, "|------|---------|---------|----------------|------------------------|")
    for (rank, row) in enumerate(case_artifact[:merged_seed_rows])
        println(io, "| $(rank) | `$(ODEPE._tryhard_origin_tag_text(row[:origin_tags]))` | `$(join(row[:members], ", "))` | $(ODEPE._fmt_sci(row[:fit_error])) | $(row[:lineage]) |")
    end
    isempty(case_artifact[:merged_seed_rows]) && println(io, "| 1 | `none` | none | Inf | none |")
    println(io)

    println(io, "## Frontier Finalists\n")
    println(io, "| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Obs Loss | Traj Max | Secondary Max | Near-Bound Count | Margin | Lineage |")
    println(io, "|----------|------------|---------|-----------|---------------|----------|----------|---------------|------------------|--------|---------|")
    for (idx, finalist) in enumerate(case_artifact[:merged_finalist_report].finalists)
        metrics = idx <= length(case_artifact[:merged_finalist_truth_rows]) ? case_artifact[:merged_finalist_truth_rows][idx] : Dict{Symbol, Any}()
        basin_row = idx <= length(case_artifact[:merged_finalist_report].basin_summary) ? case_artifact[:merged_finalist_report].basin_summary[idx] : Dict{Symbol, Any}()
        println(io, "| $(finalist.finalist_index) | `$(finalist.source_mix)` | $(finalist.member_count) | $(ODEPE._fmt_sci(finalist.best_fit_error)) | $(ODEPE._fmt_percent(get(metrics, :combined_rel_rmse, Inf))) | $(ODEPE._fmt_sci(get(basin_row, :representative_observable_loss, Inf))) | $(ODEPE._fmt_float(get(basin_row, :trajectory_distance_max, 0.0); digits = 4)) | $(ODEPE._fmt_float(get(basin_row, :secondary_distance_max, 0.0); digits = 4)) | $(finalist.near_bound_count) | $(ODEPE._fmt_float(finalist.nearest_bound_margin; digits = 4)) | $(finalist.representative_lineage) |")
    end
    isempty(case_artifact[:merged_finalist_report].finalists) && println(io, "| 1 | `none` | 0 | Inf | Inf | Inf | 0.0000 | 0.0000 | 0 | Inf | none |")
    println(io)

    println(io, "## Frontier Polished Seed Results\n")
    println(io, "| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |")
    println(io, "|------|---------|----------------|--------------------|------------------------|----------|-------|")
    for row in case_artifact[:polished_seed_rows]
        polished = row[:polished_candidate]
        polished_rmse = isnothing(polished) ? Inf : get(row[:polished_truth_metrics], :combined_rel_rmse, Inf)
        println(io, "| $(row[:rank]) | `$(row[:sources])` | $(ODEPE._fmt_sci(row[:seed_fit_error])) | $(ODEPE._fmt_sci(isnothing(polished) ? Inf : ODEPE._result_err_key(polished))) | $(ODEPE._fmt_percent(polished_rmse)) | $(ODEPE._fmt_float(row[:polish_seconds]; digits = 3)) | `$(isnothing(row[:error_message]) ? "" : row[:error_message])` |")
    end
    isempty(case_artifact[:polished_seed_rows]) && println(io, "| 1 | `none` | Inf | Inf | Inf | 0.000 | `no seeds` |")
    println(io)

    if !isnothing(case_artifact[:baseline_report_error]) || !isnothing(case_artifact[:block_error])
        println(io, "## Internal Errors\n")
        !isnothing(case_artifact[:baseline_report_error]) && println(io, "- Baseline report: `$(case_artifact[:baseline_report_error])`")
        !isnothing(case_artifact[:block_error]) && println(io, "- Block report: `$(case_artifact[:block_error])`")
        println(io)
    end

    return String(take!(io))
end

function render_summary_csv(case_artifacts)
    io = IOBuffer()
    println(io, "case_id,model_name,role,benchmark_nopolish_combined_rmse,benchmark_polish_combined_rmse,block_no_polish_combined_rmse,raw_best_finalist_rmse,block_best_finalist_rmse,merged_best_finalist_rmse,merged_ranked_best_rmse,delta_vs_benchmark_polish,raw_seed_count,block_seed_count,merged_seed_count,merged_polished_seed_count,merged_finalist_count,winner_sources,comparison_outcome,improvement_mode,local_total_seconds,local_polish_seconds")
    for case_artifact in case_artifacts
        if case_artifact[:status] != :ok
            println(io, join([
                case_artifact[:case_id],
                case_artifact[:model_name],
                String(case_artifact[:role_label]),
                "Inf",
                "Inf",
                "Inf",
                "Inf",
                "Inf",
                "Inf",
                "Inf",
                "-Inf",
                "0",
                "0",
                "0",
                "0",
                "0",
                "none",
                "error",
                "no_improvement",
                "Inf",
                "Inf",
            ], ","))
            continue
        end
        delta = ODEPE._summary_combined_rmse(case_artifact[:benchmark_polish_summary]) - case_artifact[:merged_best_finalist_rmse]
        println(io, join([
            case_artifact[:case_id],
            case_artifact[:model_name],
            String(case_artifact[:role_label]),
            string(ODEPE._summary_combined_rmse(case_artifact[:benchmark_nopolish_summary])),
            string(ODEPE._summary_combined_rmse(case_artifact[:benchmark_polish_summary])),
            string(ODEPE._summary_combined_rmse(case_artifact[:block_no_polish_summary])),
            string(case_artifact[:raw_best_finalist_rmse]),
            string(case_artifact[:block_best_finalist_rmse]),
            string(case_artifact[:merged_best_finalist_rmse]),
            string(ODEPE._summary_combined_rmse(case_artifact[:tryhard_summary])),
            string(delta),
            string(length(case_artifact[:raw_seed_rows])),
            string(length(case_artifact[:block_seed_rows])),
            string(length(case_artifact[:merged_seed_rows])),
            string(count(row -> !isnothing(row[:polished_candidate]), case_artifact[:polished_seed_rows])),
            string(length(case_artifact[:merged_finalist_report].finalists)),
            get(case_artifact[:tryhard_summary], :winner_sources, "none"),
            String(case_artifact[:comparison_outcome]),
            String(case_artifact[:improvement_mode]),
            string(case_artifact[:local_total_seconds]),
            string(case_artifact[:polish_seconds]),
        ], ","))
    end
    return String(take!(io))
end

function render_summary_markdown(case_artifacts)
    io = IOBuffer()
    println(io, "# Tryhard Finalist Benchmark Summary\n")
    println(io, "- Generated: `$(Dates.now())`")
    println(io, "- Benchmark root: `$(BENCHMARK_ROOT)`")
    println(io, "- Noise slice: `1e-4`")
    println(io, "- Policy: `preserve baseline standard-polish seeds, add all current generator families under conservative filtering, apply a soft 1.5x frontier cap, cluster polished basins, return finalists`")
    println(io, "- Block support budget: `4x4`")
    println(io, "- Total cases: $(length(case_artifacts))")
    println(io, "- Oracle note: truth metrics here are benchmark-only evaluation and were not used to rank local tryhard seeds, polished basins, or finalists.\n")

    ok_cases = filter(case_artifact -> case_artifact[:status] == :ok, case_artifacts)
    merged_better = count(case_artifact -> case_artifact[:comparison_outcome] == :finalist_set_better, ok_cases)
    ties = count(case_artifact -> case_artifact[:comparison_outcome] == :tie, ok_cases)
    polish_better = count(case_artifact -> case_artifact[:comparison_outcome] == :benchmark_polish_better, ok_cases)

    println(io, "## Headline\n")
    println(io, "- Reasonable frontier finalist set beats benchmark `odepe_polish`: $(merged_better)")
    println(io, "- Ties within tolerance: $(ties)")
    println(io, "- Benchmark `odepe_polish` remains better: $(polish_better)\n")

    deltas = [
        ODEPE._summary_combined_rmse(case_artifact[:benchmark_polish_summary]) - case_artifact[:merged_best_finalist_rmse]
        for case_artifact in ok_cases
        if isfinite(ODEPE._summary_combined_rmse(case_artifact[:benchmark_polish_summary])) &&
           isfinite(case_artifact[:merged_best_finalist_rmse])
    ]
    runtime_totals = [case_artifact[:local_total_seconds] for case_artifact in ok_cases if isfinite(case_artifact[:local_total_seconds])]
    runtime_polish = [case_artifact[:polish_seconds] for case_artifact in ok_cases if isfinite(case_artifact[:polish_seconds])]
    finalist_counts = [length(case_artifact[:merged_finalist_report].finalists) for case_artifact in ok_cases]
    println(io, "## Aggregate Delta vs Benchmark `odepe_polish`\n")
    println(io, "- Mean best-in-set combined-RMSE improvement: $(ODEPE._fmt_percent(isempty(deltas) ? Inf : mean(deltas)))")
    println(io, "- Median best-in-set combined-RMSE improvement: $(ODEPE._fmt_percent(isempty(deltas) ? Inf : median(deltas)))")
    println(io, "- Mean local total runtime: $(ODEPE._fmt_float(isempty(runtime_totals) ? Inf : mean(runtime_totals); digits = 3)) s")
    println(io, "- Median local total runtime: $(ODEPE._fmt_float(isempty(runtime_totals) ? Inf : median(runtime_totals); digits = 3)) s")
    println(io, "- Mean local polish-only runtime: $(ODEPE._fmt_float(isempty(runtime_polish) ? Inf : mean(runtime_polish); digits = 3)) s")
    println(io, "- Median local polish-only runtime: $(ODEPE._fmt_float(isempty(runtime_polish) ? Inf : median(runtime_polish); digits = 3)) s")
    println(io, "- Mean merged finalist count: $(ODEPE._fmt_float(isempty(finalist_counts) ? Inf : mean(finalist_counts); digits = 2))")
    println(io, "- Median merged finalist count: $(ODEPE._fmt_float(isempty(finalist_counts) ? Inf : median(finalist_counts); digits = 2))\n")

    println(io, "## Coverage Modes\n")
    for mode in (:baseline_seed_family_win, :additive_seed_family_win, :both_seed_families_win, :merged_only_win, :no_improvement)
        println(io, "- `$(mode)`: $(count(case_artifact -> case_artifact[:improvement_mode] == mode, ok_cases))")
    end
    println(io)

    raw_better = count(
        case_artifact -> isfinite(case_artifact[:raw_best_finalist_rmse]) &&
            case_artifact[:raw_best_finalist_rmse] + TIE_ATOL < ODEPE._summary_combined_rmse(case_artifact[:benchmark_polish_summary]),
        ok_cases,
    )
    block_better = count(
        case_artifact -> isfinite(case_artifact[:block_best_finalist_rmse]) &&
            case_artifact[:block_best_finalist_rmse] + TIE_ATOL < ODEPE._summary_combined_rmse(case_artifact[:benchmark_polish_summary]),
        ok_cases,
    )
    println(io, "## Family Coverage vs Benchmark `odepe_polish`\n")
    println(io, "- Baseline-only finalist set better: $(raw_better)")
    println(io, "- Additive-only finalist set better: $(block_better)")
    println(io, "- Reasonable frontier finalist set better: $(merged_better)\n")

    println(io, "## Wins by Family\n")
    for family in vcat(HARD_FAMILIES, GUARD_FAMILIES)
        family_cases = filter(case_artifact -> case_artifact[:status] == :ok && case_artifact[:model_name] == family, case_artifacts)
        isempty(family_cases) && continue
        better = count(case_artifact -> case_artifact[:comparison_outcome] == :finalist_set_better, family_cases)
        ties_family = count(case_artifact -> case_artifact[:comparison_outcome] == :tie, family_cases)
        polish_family = count(case_artifact -> case_artifact[:comparison_outcome] == :benchmark_polish_better, family_cases)
        println(io, "- `$(family)`: merged finalist set better $(better), ties $(ties_family), benchmark polish better $(polish_family)")
    end
    println(io)

    println(io, "## Per-Case Outcomes\n")
    println(io, "| Case | Role | Benchmark Polish | Baseline Best-In-Set | Additive Best-In-Set | Frontier Best-In-Set | Frontier Ranked Best | Finalists | Outcome |")
    println(io, "|------|------|------------------|-----------------|-------------------|--------------------|--------------------|-----------|---------|")
    for case_artifact in case_artifacts
        if case_artifact[:status] != :ok
            println(io, "| `$(case_artifact[:case_id])` | `$(case_artifact[:role_label])` | Inf | Inf | Inf | Inf | Inf | 0 | `error` |")
            continue
        end
        println(io, "| `$(case_artifact[:case_id])` | `$(case_artifact[:role_label])` | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:benchmark_polish_summary]))) | $(ODEPE._fmt_percent(case_artifact[:raw_best_finalist_rmse])) | $(ODEPE._fmt_percent(case_artifact[:block_best_finalist_rmse])) | $(ODEPE._fmt_percent(case_artifact[:merged_best_finalist_rmse])) | $(ODEPE._fmt_percent(ODEPE._summary_combined_rmse(case_artifact[:tryhard_summary]))) | $(length(case_artifact[:merged_finalist_report].finalists)) | `$(case_artifact[:comparison_outcome])` |")
    end
    println(io)

    return String(take!(io))
end

function main()
    selected_cases = select_tryhard_cases(; case_limit = case_limit, requested_case_ids = requested_case_ids)
    println("Running tryhard polishing benchmark on $(length(selected_cases)) case(s)...")
    case_artifacts = with_logger(NullLogger()) do
        Dict{Symbol, Any}[build_case_artifact_safe(case_spec) for case_spec in selected_cases]
    end

    mkpath(OUTPUT_ROOT)
    write(joinpath(OUTPUT_ROOT, "summary.md"), render_summary_markdown(case_artifacts))
    write(joinpath(OUTPUT_ROOT, "summary.csv"), render_summary_csv(case_artifacts))

    for case_artifact in case_artifacts
        case_dir = joinpath(OUTPUT_ROOT, "cases", case_artifact[:case_id])
        mkpath(case_dir)
        write(joinpath(case_dir, "study.md"), render_case_markdown(case_artifact))
    end

    println("Done! Tryhard benchmark artifact root: $OUTPUT_ROOT")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
