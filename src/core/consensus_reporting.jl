function _consensus_options_with_strategy(base::ConsensusOptions, strategy::Symbol)
    return ConsensusOptions(
        strategy = strategy,
        support_point_count = base.support_point_count,
        support_combo_count = base.support_combo_count,
        refine_top_families = base.refine_top_families,
        family_distance_threshold = base.family_distance_threshold,
        family_min_distinct_sources = base.family_min_distinct_sources,
        do_equation_refit = base.do_equation_refit,
        score_weights = base.score_weights,
        nonlinearity_penalty_threshold = base.nonlinearity_penalty_threshold,
    )
end

_consensus_truth_rel_error(estimate::Real, truth::Real) = abs(Float64(estimate) - Float64(truth)) / max(abs(Float64(truth)), 1e-12)
_consensus_truth_rel_error(::Any, truth::Real) = Inf

function _consensus_lookup_estimate(values::OrderedDict, sym)
    by_name = Dict(string(k) => Float64(v) for (k, v) in values)
    return get(by_name, string(sym), NaN)
end

function _consensus_truth_rows(
    truth_values::OrderedDict{Num, Float64},
    estimates::OrderedDict{Num, Float64};
    kind::Symbol,
)
    rows = NamedTuple[]
    for (sym, truth) in truth_values
        estimate = _consensus_lookup_estimate(estimates, sym)
        label = kind == :state_ic ? replace(string(sym), "(t)" => "(0)") : string(sym)
        abs_error = isfinite(estimate) ? abs(estimate - truth) : Inf
        rel_error = isfinite(estimate) ? _consensus_truth_rel_error(estimate, truth) : Inf
        push!(rows, (
            kind = kind,
            label = label,
            estimate = estimate,
            truth = truth,
            abs_error = abs_error,
            rel_error = rel_error,
        ))
    end
    return rows
end

function _consensus_rel_rmse(rows)
    rel_errors = [row.rel_error for row in rows if isfinite(row.rel_error)]
    isempty(rel_errors) && return Inf
    return sqrt(mean(abs2, rel_errors))
end

function _candidate_truth_metrics(
    pep::ParameterEstimationProblem,
    candidate::Union{Nothing, ParameterEstimationResult},
)
    if isnothing(candidate)
        return Dict{Symbol, Any}(
            :parameter_rows => NamedTuple[],
            :state_rows => NamedTuple[],
            :all_rows => NamedTuple[],
            :parameter_rel_rmse => Inf,
            :state_rel_rmse => Inf,
            :combined_rel_rmse => Inf,
            :worst_row => nothing,
        )
    end

    parameter_rows = _consensus_truth_rows(pep.p_true, candidate.parameters; kind = :parameter)
    state_rows = _consensus_truth_rows(pep.ic, candidate.states; kind = :state_ic)
    all_rows = vcat(parameter_rows, state_rows)
    worst_row = isempty(all_rows) ? nothing : all_rows[argmax([row.rel_error for row in all_rows])]
    return Dict{Symbol, Any}(
        :parameter_rows => parameter_rows,
        :state_rows => state_rows,
        :all_rows => all_rows,
        :parameter_rel_rmse => _consensus_rel_rmse(parameter_rows),
        :state_rel_rmse => _consensus_rel_rmse(state_rows),
        :combined_rel_rmse => _consensus_rel_rmse(all_rows),
        :worst_row => worst_row,
    )
end

function _candidate_evidence_dict(evidence::Union{Nothing, CandidateEvidence})
    isnothing(evidence) && return nothing
    return Dict{Symbol, Any}(
        :base_fit_error => evidence.base_fit_error,
        :sp_equation_residual_kept => evidence.sp_equation_residual_kept,
        :sp_equation_residual_dropped => evidence.sp_equation_residual_dropped,
        :mp_equation_residual_kept => evidence.mp_equation_residual_kept,
        :mp_equation_residual_dropped => evidence.mp_equation_residual_dropped,
        :conditioning_score => evidence.conditioning_score,
        :uq_volume_proxy => evidence.uq_volume_proxy,
        :source_diversity_tags => copy(evidence.source_diversity_tags),
        :composite_score => evidence.composite_score,
        :score_breakdown => evidence.score_breakdown,
    )
end

function _consensus_support_times(t_vector::Vector{Float64}, indices::Vector{Int})
    return [t_vector[idx] for idx in indices if 1 <= idx <= length(t_vector)]
end

function _consensus_support_combo_times(t_vector::Vector{Float64}, combos::Vector{Vector{Int}})
    return [Float64[t_vector[idx] for idx in combo if 1 <= idx <= length(t_vector)] for combo in combos]
end

function _consensus_family_rows(report::ConsensusEstimationReport)
    rows = NamedTuple[]
    limit = min(length(report.families), 5)
    for (rank, family) in enumerate(report.families[1:limit])
        push!(rows, (
            rank = rank,
            member_count = length(family.member_indices),
            family_score = family.family_score,
            medoid_index = family.family_medoid_index,
            best_member_index = family.best_member_index,
            interpolators = join(string.(family.distinct_interpolators), ", "),
            source_types = join(string.(family.distinct_source_types), ", "),
            shooting_support = isempty(family.distinct_shooting_support) ? "none" : join(string.(family.distinct_shooting_support), ", "),
        ))
    end
    return rows
end

function _consensus_winner_mode(summary::AbstractDict{Symbol, <:Any})::Symbol
    return Symbol(get(summary, :winner_mode, :missing))
end

function _consensus_winner_label(summary::AbstractDict{Symbol, <:Any})::String
    mode = _consensus_winner_mode(summary)
    strategy = Symbol(get(summary, :strategy, :unknown))
    if mode == :refined
        return "refined winner"
    elseif mode == :raw && strategy == :family_consensus_refit
        return "refit kept raw winner"
    elseif mode == :raw
        return "raw winner"
    end
    return "no winner"
end

function _consensus_strategy_summary(
    pep::ParameterEstimationProblem,
    report::ConsensusEstimationReport,
    selection_seconds::Float64,
    shared_seconds::Float64,
    t_vector::Vector{Float64},
    timing::Union{Nothing, TimingBreakdown} = nothing,
)
    final_winner = isnothing(report.winner_refined) ? report.winner_candidate : report.winner_refined
    raw_truth = _candidate_truth_metrics(pep, report.winner_candidate)
    final_truth = _candidate_truth_metrics(pep, final_winner)
    raw_evidence = _candidate_evidence_dict(get(report.scoring_summary, :raw_winner_evidence, nothing))
    final_evidence = _candidate_evidence_dict(get(report.scoring_summary, :final_winner_evidence, get(report.scoring_summary, :raw_winner_evidence, nothing)))

    return Dict{Symbol, Any}(
        :strategy => report.strategy,
        :selection_seconds => selection_seconds,
        :effective_total_seconds => shared_seconds + selection_seconds,
        :incremental_seconds => selection_seconds,
        :candidate_count => length(report.raw_candidates),
        :family_count => length(report.families),
        :winner_mode => Symbol(get(report.scoring_summary, :final_winner_kind, :missing)),
        :raw_winner_lineage => isnothing(report.winner_candidate) ? "none" : lineage_summary(report.winner_candidate),
        :final_winner_lineage => isnothing(final_winner) ? "none" : lineage_summary(final_winner),
        :raw_winner_fit_error => isnothing(report.winner_candidate) ? Inf : _result_err_key(report.winner_candidate),
        :final_winner_fit_error => get(report.scoring_summary, :final_winner_fit_error, isnothing(final_winner) ? Inf : _result_err_key(final_winner)),
        :raw_winner_score => get(report.scoring_summary, :winner_score, NaN),
        :final_winner_score => get(report.scoring_summary, :final_winner_score, get(report.scoring_summary, :winner_score, NaN)),
        :support_points => copy(report.support_points),
        :support_point_times => _consensus_support_times(t_vector, report.support_points),
        :support_combos => deepcopy(report.support_combos),
        :support_combo_times => _consensus_support_combo_times(t_vector, report.support_combos),
        :parameter_rows => final_truth[:parameter_rows],
        :state_rows => final_truth[:state_rows],
        :truth_metrics => final_truth,
        :raw_truth_metrics => raw_truth,
        :winner_evidence => final_evidence,
        :raw_winner_evidence => raw_evidence,
        :top_families => _consensus_family_rows(report),
        :timing => isnothing(timing) ? TimingBreakdown(label = report.strategy, total_seconds = selection_seconds) : timing,
    )
end

function _consensus_raw_pool_summary(
    pep::ParameterEstimationProblem,
    raw_candidates::Vector{ParameterEstimationResult},
)
    isempty(raw_candidates) && return Dict{Symbol, Any}(
        :best_fit_index => nothing,
        :best_truth_index => nothing,
        :best_fit_lineage => "none",
        :best_truth_lineage => "none",
        :best_fit_fit_error => Inf,
        :best_truth_fit_error => Inf,
        :best_fit_truth_metrics => Dict{Symbol, Any}(),
        :best_truth_truth_metrics => Dict{Symbol, Any}(),
    )

    truth_metrics = [_candidate_truth_metrics(pep, candidate) for candidate in raw_candidates]
    best_fit_index = _argmin_by(eachindex(raw_candidates), i -> begin
        err = _result_err_key(raw_candidates[i])
        isfinite(err) ? err : Inf
    end)
    best_truth_index = _argmin_by(eachindex(raw_candidates), i -> begin
        rmse = truth_metrics[i][:combined_rel_rmse]
        isfinite(rmse) ? rmse : Inf
    end)
    best_fit_index = isnothing(best_fit_index) ? 1 : best_fit_index
    best_truth_index = isnothing(best_truth_index) ? 1 : best_truth_index
    return Dict{Symbol, Any}(
        :best_fit_index => best_fit_index,
        :best_truth_index => best_truth_index,
        :best_fit_lineage => lineage_summary(raw_candidates[best_fit_index]),
        :best_truth_lineage => lineage_summary(raw_candidates[best_truth_index]),
        :best_fit_fit_error => _result_err_key(raw_candidates[best_fit_index]),
        :best_truth_fit_error => _result_err_key(raw_candidates[best_truth_index]),
        :best_fit_truth_metrics => truth_metrics[best_fit_index],
        :best_truth_truth_metrics => truth_metrics[best_truth_index],
    )
end

function _build_consensus_benchmark_artifact(
    pep::ParameterEstimationProblem;
    est_opts::EstimationOptions = EstimationOptions(),
    dataset_label::String = pep.name,
    base_consensus_opts::ConsensusOptions = ConsensusOptions(),
    strategies::Vector{Symbol} = Symbol[:best_fit_baseline, :family_consensus, :family_consensus_refit],
)
    prep = @timed _prepare_consensus_inputs(pep, est_opts)
    pep_with_data, run_opts, raw_candidates = prep.value
    context_timed = isempty(raw_candidates) ? nothing : (@timed _build_consensus_context(pep_with_data, run_opts))
    context = isnothing(context_timed) ? nothing : context_timed.value
    context_seconds = isnothing(context_timed) ? 0.0 : context_timed.time
    t_vector = isnothing(context) ? (
        isnothing(pep_with_data.data_sample) || !haskey(pep_with_data.data_sample, "t") ? Float64[] : Float64[pep_with_data.data_sample["t"]...]
    ) : context.t_vector

    raw_pool = _consensus_raw_pool_summary(pep_with_data, raw_candidates)
    shared_seconds = prep.time + context_seconds
    strategy_summaries = Dict{Symbol, Any}[]
    for strategy in strategies
        consensus_opts = _consensus_options_with_strategy(base_consensus_opts, strategy)
        built = @timed _assemble_consensus_report(pep_with_data, run_opts, raw_candidates, consensus_opts; context = context)
        push!(strategy_summaries, _consensus_strategy_summary(pep_with_data, built.value, built.time, shared_seconds, t_vector))
    end

    return Dict{Symbol, Any}(
        :model_name => pep_with_data.name,
        :dataset_label => dataset_label,
        :generated_at => string(Dates.now()),
        :shared_candidate_generation_seconds => prep.time,
        :shared_context_seconds => context_seconds,
        :shared_total_seconds => shared_seconds,
        :raw_candidate_count => length(raw_candidates),
        :raw_pool => raw_pool,
        :strategies => strategy_summaries,
        :oracle_note => "Truth-based metrics in this artifact are benchmark-only evaluation metrics and were not used by the consensus selector.",
        :run_config => Dict{Symbol, Any}(
            :interpolator => string(est_opts.interpolator),
            :interpolator_count => length(resolve_interpolator_list(run_opts)),
            :shooting_points => run_opts.shooting_points,
            :multipoint_n_points => run_opts.multipoint_n_points,
            :multipoint_max_pairs => run_opts.multipoint_max_pairs,
            :use_parameter_homotopy => run_opts.use_parameter_homotopy,
            :use_multipoint => run_opts.use_multipoint,
            :polish_solutions => run_opts.polish_solutions,
            :polish_solver_solutions => run_opts.polish_solver_solutions,
            :polish_maxiters => run_opts.polish_maxiters,
            :polish_maxtime => run_opts.polish_maxtime,
        ),
        :consensus_config => Dict{Symbol, Any}(
            :support_point_count => base_consensus_opts.support_point_count,
            :support_combo_count => base_consensus_opts.support_combo_count,
            :refine_top_families => base_consensus_opts.refine_top_families,
            :do_equation_refit => base_consensus_opts.do_equation_refit,
        ),
    )
end

_fmt_float(x; digits::Int = 4) = isfinite(x) ? @sprintf("%.*f", digits, x) : "Inf"
_fmt_sci(x) = isfinite(x) ? @sprintf("%.4e", x) : "Inf"
_fmt_percent(x) = isfinite(x) ? @sprintf("%.2f%%", 100 * x) : "Inf"

function _consensus_rel_error_for_label(summary::Dict{Symbol, Any}, label::String)
    rows = get(get(summary, :truth_metrics, Dict{Symbol, Any}()), :all_rows, NamedTuple[])
    for row in rows
        row.label == label && return row.rel_error
    end
    return NaN
end

function _consensus_biggest_shift(before::Dict{Symbol, Any}, after::Dict{Symbol, Any}; direction::Symbol)
    before_rows = Dict(row.label => row.rel_error for row in get(get(before, :truth_metrics, Dict{Symbol, Any}()), :all_rows, NamedTuple[]))
    after_rows = Dict(row.label => row.rel_error for row in get(get(after, :truth_metrics, Dict{Symbol, Any}()), :all_rows, NamedTuple[]))
    labels = intersect(keys(before_rows), keys(after_rows))
    isempty(labels) && return nothing

    best_label = nothing
    best_delta = direction == :improvement ? -Inf : -Inf
    for label in labels
        delta = before_rows[label] - after_rows[label]
        score = direction == :improvement ? delta : -delta
        if score > best_delta
            best_delta = score
            best_label = label
        end
    end
    isnothing(best_label) && return nothing
    return (
        label = best_label,
        before = before_rows[best_label],
        after = after_rows[best_label],
        delta = before_rows[best_label] - after_rows[best_label],
    )
end

function _consensus_strategy_lookup(artifact::Dict{Symbol, Any}, strategy::Symbol)
    for summary in artifact[:strategies]
        Symbol(summary[:strategy]) == strategy && return summary
    end
    return nothing
end

function _consensus_impact_lines(artifact::Dict{Symbol, Any})
    comparisons = [
        (:best_fit_baseline, :family_consensus),
        (:family_consensus, :family_consensus_refit),
    ]

    lines = String[]
    for (before_key, after_key) in comparisons
        before = _consensus_strategy_lookup(artifact, before_key)
        after = _consensus_strategy_lookup(artifact, after_key)
        if isnothing(before) || isnothing(after)
            push!(lines, "- `$(before_key)` → `$(after_key)`: comparison unavailable.")
            continue
        end

        before_rmse = get(get(before, :truth_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)
        after_rmse = get(get(after, :truth_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)
        before_fit = get(before, :final_winner_fit_error, Inf)
        after_fit = get(after, :final_winner_fit_error, Inf)
        improvement = _consensus_biggest_shift(before, after; direction = :improvement)
        worsening = _consensus_biggest_shift(before, after; direction = :worsening)

        line = "- `$(before_key)` → `$(after_key)`: combined oracle RMSE $(_fmt_percent(before_rmse)) → $(_fmt_percent(after_rmse)); fit error $(_fmt_sci(before_fit)) → $(_fmt_sci(after_fit))"
        if !isnothing(improvement) && improvement.delta > 0
            line *= "; biggest gain `$(improvement.label)` $(_fmt_percent(improvement.before)) → $(_fmt_percent(improvement.after))"
        end
        if !isnothing(worsening) && worsening.delta < 0
            line *= "; biggest regression `$(worsening.label)` $(_fmt_percent(worsening.before)) → $(_fmt_percent(worsening.after))"
        end
        push!(lines, line * ".")
    end
    return lines
end

function _render_consensus_benchmark_markdown(artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "# Consensus Benchmark: $(artifact[:model_name])\n")
    println(io, "- Dataset: `$(artifact[:dataset_label])`")
    println(io, "- Generated: `$(artifact[:generated_at])`")
    println(io, "- Shared raw candidate generation: $(_fmt_float(artifact[:shared_candidate_generation_seconds]; digits = 3)) s")
    println(io, "- Shared consensus context build: $(_fmt_float(artifact[:shared_context_seconds]; digits = 3)) s")
    println(io, "- Shared total pre-selection time: $(_fmt_float(artifact[:shared_total_seconds]; digits = 3)) s")
    println(io, "- Raw candidate count: $(artifact[:raw_candidate_count])")
    println(io, "- Oracle note: $(artifact[:oracle_note])\n")

    println(io, "## What's New\n")
    println(io, "- The selector now compares one shared SP/MP raw candidate pool under three strategies: `best_fit_baseline`, `family_consensus`, and `family_consensus_refit`.")
    println(io, "- `family_consensus` scores candidates with oracle-free evidence from fit, SP/MP kept and dropped equations, provenance support, and conditioning.")
    println(io, "- `family_consensus_refit` can locally polish top families after consensus selection and keep the refined winner only when it rescored better.\n")

    config = artifact[:run_config]
    println(io, "## Run Configuration\n")
    println(io, "- Interpolator: `$(config[:interpolator])` (resolved interpolator count: $(config[:interpolator_count]))")
    println(io, "- Shooting points: $(config[:shooting_points])")
    println(io, "- Multipoint: enabled=$(config[:use_multipoint]), points=$(config[:multipoint_n_points]), max pairs=$(config[:multipoint_max_pairs])")
    println(io, "- Parameter homotopy: $(config[:use_parameter_homotopy])")
    println(io, "- Built-in polishing during raw generation: solver=$(config[:polish_solver_solutions]), final=$(config[:polish_solutions]), maxiters=$(config[:polish_maxiters]), maxtime=$(_fmt_float(config[:polish_maxtime]; digits = 1)) s")
    consensus_config = artifact[:consensus_config]
    println(io, "- Consensus scoring support: points=$(consensus_config[:support_point_count]), combos=$(consensus_config[:support_combo_count]), refine top families=$(consensus_config[:refine_top_families]), equation refit=$(consensus_config[:do_equation_refit])\n")

    raw_pool = artifact[:raw_pool]
    println(io, "## Raw Pool Reference\n")
    println(io, "| Selector | Candidate | Fit Error | Combined Oracle RMSE | Lineage |")
    println(io, "|----------|-----------|-----------|----------------------|---------|")
    println(io, "| Best raw fit | $(raw_pool[:best_fit_index]) | $(_fmt_sci(raw_pool[:best_fit_fit_error])) | $(_fmt_percent(get(raw_pool[:best_fit_truth_metrics], :combined_rel_rmse, Inf))) | $(raw_pool[:best_fit_lineage]) |")
    println(io, "| Best raw oracle | $(raw_pool[:best_truth_index]) | $(_fmt_sci(raw_pool[:best_truth_fit_error])) | $(_fmt_percent(get(raw_pool[:best_truth_truth_metrics], :combined_rel_rmse, Inf))) | $(raw_pool[:best_truth_lineage]) |\n")

    println(io, "## Strategy Comparison\n")
    println(io, "| Strategy | Winner | Selection s | Effective Total s | Fit Error | Param RMSE | Combined RMSE | a31 Rel Err | Families |")
    println(io, "|----------|--------|-------------|-------------------|-----------|------------|---------------|-------------|----------|")
    for summary in artifact[:strategies]
        a31_rel_err = _fmt_percent(_consensus_rel_error_for_label(summary, "a31"))
        println(
            io,
            "| `$(summary[:strategy])` | $(_consensus_winner_label(summary)) | $(_fmt_float(summary[:selection_seconds]; digits = 3)) | " *
            "$(_fmt_float(summary[:effective_total_seconds]; digits = 3)) | $(_fmt_sci(summary[:final_winner_fit_error])) | " *
            "$(_fmt_percent(get(summary[:truth_metrics], :parameter_rel_rmse, Inf))) | $(_fmt_percent(get(summary[:truth_metrics], :combined_rel_rmse, Inf))) | " *
            "$(a31_rel_err) | $(summary[:family_count]) |"
        )
    end
    println(io)

    println(io, "## Impact Summary\n")
    for line in _consensus_impact_lines(artifact)
        println(io, line)
    end
    println(io)

    for summary in artifact[:strategies]
        println(io, "## Strategy: `$(summary[:strategy])`\n")
        println(io, "- Winner mode: $(_consensus_winner_label(summary))")
        println(io, "- Final lineage: $(summary[:final_winner_lineage])")
        println(io, "- Final fit error: $(_fmt_sci(summary[:final_winner_fit_error]))")
        println(io, "- Final composite score: $(_fmt_float(summary[:final_winner_score]; digits = 4))")
        support_point_string = if isempty(summary[:support_points])
            "none"
        else
            join(["$(idx)@$(_fmt_float(t; digits = 3))" for (idx, t) in zip(summary[:support_points], summary[:support_point_times])], ", ")
        end
        println(io, "- Support points: $(support_point_string)")
        combo_strings = isempty(summary[:support_combos]) ? ["none"] : [
            "[" * join(["$(idx)@$(_fmt_float(t; digits = 3))" for (idx, t) in zip(combo, times)], ", ") * "]"
            for (combo, times) in zip(summary[:support_combos], summary[:support_combo_times])
        ]
        println(io, "- Support combos: $(join(combo_strings, "; "))\n")

        println(io, "### Final Winner Truth Table\n")
        println(io, "| Variable | Estimate | Truth | Abs Error | Rel Error |")
        println(io, "|----------|----------|-------|-----------|-----------|")
        for row in vcat(summary[:parameter_rows], summary[:state_rows])
            println(io, "| `$(row.label)` | $(_fmt_float(row.estimate; digits = 6)) | $(_fmt_float(row.truth; digits = 6)) | $(_fmt_sci(row.abs_error)) | $(_fmt_percent(row.rel_error)) |")
        end
        println(io)

        evidence = summary[:winner_evidence]
        println(io, "### Winner Evidence\n")
        println(io, "| Metric | Value |")
        println(io, "|--------|-------|")
        if isnothing(evidence)
            println(io, "| Evidence | none |")
        else
            diversity_string = isempty(evidence[:source_diversity_tags]) ? "none" : join(string.(evidence[:source_diversity_tags]), ", ")
            println(io, "| Base fit error | $(_fmt_sci(evidence[:base_fit_error])) |")
            println(io, "| SP kept residual | $(_fmt_sci(evidence[:sp_equation_residual_kept])) |")
            println(io, "| SP dropped residual | $(_fmt_sci(evidence[:sp_equation_residual_dropped])) |")
            println(io, "| MP kept residual | $(_fmt_sci(evidence[:mp_equation_residual_kept])) |")
            println(io, "| MP dropped residual | $(_fmt_sci(evidence[:mp_equation_residual_dropped])) |")
            println(io, "| Conditioning score | $(_fmt_sci(evidence[:conditioning_score])) |")
            println(io, "| Composite score | $(_fmt_float(evidence[:composite_score]; digits = 4)) |")
            println(io, "| Score breakdown | fit=$(_fmt_float(evidence[:score_breakdown].fit; digits = 3)), equation=$(_fmt_float(evidence[:score_breakdown].equation; digits = 3)), support=$(_fmt_float(evidence[:score_breakdown].support; digits = 3)), trust=$(_fmt_float(evidence[:score_breakdown].trust; digits = 3)) |")
            println(io, "| Diversity tags | $(diversity_string) |")
        end
        println(io)

        println(io, "### Top Families\n")
        println(io, "| Rank | Size | Family Score | Medoid | Best Member | Interpolators | Sources | Shooting Support |")
        println(io, "|------|------|--------------|--------|-------------|---------------|---------|------------------|")
        if isempty(summary[:top_families])
            println(io, "| 1 | 0 | Inf | - | - | none | none | none |")
        else
            for row in summary[:top_families]
                interpolator_string = isempty(row.interpolators) ? "none" : row.interpolators
                source_type_string = isempty(row.source_types) ? "none" : row.source_types
                println(io, "| $(row.rank) | $(row.member_count) | $(_fmt_float(row.family_score; digits = 4)) | $(row.medoid_index) | $(row.best_member_index) | $(interpolator_string) | $(source_type_string) | $(row.shooting_support) |")
            end
        end
        println(io)
    end

    return String(take!(io))
end

function _synthesized_candidate_summary(
    pep::ParameterEstimationProblem,
    candidate::Union{Nothing, ParameterEstimationResult},
    label::String,
)
    truth_metrics = _candidate_truth_metrics(pep, candidate)
    return Dict{Symbol, Any}(
        :label => label,
        :lineage => isnothing(candidate) ? "none" : lineage_summary(candidate),
        :fit_error => isnothing(candidate) ? Inf : _result_err_key(candidate),
        :truth_metrics => truth_metrics,
    )
end

function _synthesized_seed_rows(report::SynthesizedFinalizerReport)
    rows = NamedTuple[]
    ordered = sort(
        collect(enumerate(report.synthesized_seeds));
        by = item -> get(item[2].pre_refine_checks, :pre_refine_score, Inf),
    )
    limit = min(length(ordered), 8)
    for idx in 1:limit
        seed_index, seed = ordered[idx]
        push!(rows, (
            rank = idx,
            seed_index = seed_index,
            kind = seed.seed_kind,
            families = isempty(seed.source_family_indices) ? "none" : join(string.(seed.source_family_indices), ", "),
            source_candidates = isempty(seed.source_candidate_indices) ? "none" : join(string.(seed.source_candidate_indices), ", "),
            accepted = get(seed.pre_refine_checks, :accepted, false),
            pre_refine_score = get(seed.pre_refine_checks, :pre_refine_score, Inf),
            fit_loss = get(seed.pre_refine_checks, :fit_loss, Inf),
            equation_penalty = get(seed.pre_refine_checks, :equation_penalty, Inf),
            nearest_raw_distance = get(seed.pre_refine_checks, :nearest_raw_distance, Inf),
        ))
    end
    return rows
end

function _synthesized_refined_rows(
    pep::ParameterEstimationProblem,
    refined_results::Vector{ParameterEstimationResult},
)
    rows = NamedTuple[]
    ordered = sort(refined_results; by = result -> _result_err_key(result))
    limit = min(length(ordered), 5)
    for (rank, result) in enumerate(ordered[1:limit])
        truth_metrics = _candidate_truth_metrics(pep, result)
        push!(rows, (
            rank = rank,
            lineage = lineage_summary(result),
            fit_error = _result_err_key(result),
            parameter_rel_rmse = truth_metrics[:parameter_rel_rmse],
            combined_rel_rmse = truth_metrics[:combined_rel_rmse],
        ))
    end
    return rows
end

function _build_synthesized_benchmark_artifact(
    pep::ParameterEstimationProblem;
    est_opts::EstimationOptions = EstimationOptions(),
    synth_opts::SynthesizedFinalizerOptions = SynthesizedFinalizerOptions(),
    dataset_label::String = pep.name,
)
    built = @timed research_synthesized_finalizer(pep; est_opts = est_opts, synth_opts = synth_opts)
    report = built.value
    raw_report = report.raw_consensus_report
    raw_summary = _synthesized_candidate_summary(pep, raw_report.winner_candidate, "raw consensus winner")
    best_refined = isempty(report.refined_seed_results) ? nothing : report.refined_seed_results[_argmin_by(eachindex(report.refined_seed_results), i -> _result_err_key(report.refined_seed_results[i]))]
    best_refined_summary = _synthesized_candidate_summary(pep, best_refined, "best synthesized refined result")
    final_summary = _synthesized_candidate_summary(pep, report.winning_result, "final selected winner")

    return Dict{Symbol, Any}(
        :model_name => pep.name,
        :dataset_label => dataset_label,
        :generated_at => string(Dates.now()),
        :total_seconds => built.time,
        :raw_candidate_count => length(raw_report.raw_candidates),
        :family_count => length(raw_report.families),
        :synthesized_seed_count => length(report.synthesized_seeds),
        :accepted_synthesized_seed_count => count(seed -> get(seed.pre_refine_checks, :accepted, false), report.synthesized_seeds),
        :refined_seed_result_count => length(report.refined_seed_results),
        :winning_origin => report.winning_origin,
        :selection_summary => report.selection_summary,
        :raw_summary => raw_summary,
        :best_refined_summary => best_refined_summary,
        :final_summary => final_summary,
        :seed_rows => _synthesized_seed_rows(report),
        :refined_rows => _synthesized_refined_rows(pep, report.refined_seed_results),
        :top_families => _consensus_family_rows(raw_report),
        :oracle_note => "Truth-based metrics in this artifact are benchmark-only evaluation metrics and were not used by the synthesized selector.",
        :run_config => Dict{Symbol, Any}(
            :interpolator => string(est_opts.interpolator),
            :interpolator_count => length(resolve_interpolator_list(est_opts)),
            :shooting_points => est_opts.shooting_points,
            :multipoint_n_points => est_opts.multipoint_n_points,
            :multipoint_max_pairs => est_opts.multipoint_max_pairs,
            :use_parameter_homotopy => est_opts.use_parameter_homotopy,
            :use_multipoint => est_opts.use_multipoint,
            :polish_solutions => est_opts.polish_solutions,
            :polish_solver_solutions => est_opts.polish_solver_solutions,
            :polish_maxiters => est_opts.polish_maxiters,
            :polish_maxtime => est_opts.polish_maxtime,
        ),
        :consensus_config => Dict{Symbol, Any}(
            :strategy => synth_opts.base_consensus_opts.strategy,
            :support_point_count => synth_opts.base_consensus_opts.support_point_count,
            :support_combo_count => synth_opts.base_consensus_opts.support_combo_count,
            :refine_top_families => synth_opts.base_consensus_opts.refine_top_families,
            :do_equation_refit => synth_opts.base_consensus_opts.do_equation_refit,
        ),
        :synth_config => Dict{Symbol, Any}(
            :max_family_seeds => synth_opts.max_family_seeds,
            :max_cross_family_seeds => synth_opts.max_cross_family_seeds,
            :allow_cross_family_synthesis => synth_opts.allow_cross_family_synthesis,
            :allow_parameter_stitching => synth_opts.allow_parameter_stitching,
            :cross_family_distance_limit => synth_opts.cross_family_distance_limit,
            :seed_consistency_threshold => synth_opts.seed_consistency_threshold,
            :max_refine_candidates => synth_opts.max_refine_candidates,
            :refine_with_full_trajectory => synth_opts.refine_with_full_trajectory,
            :refine_objective_mode => synth_opts.refine_objective_mode,
        ),
    )
end

function _render_synthesized_benchmark_markdown(artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "# Synthesized Finalizer Benchmark: $(artifact[:model_name])\n")
    println(io, "- Dataset: `$(artifact[:dataset_label])`")
    println(io, "- Generated: `$(artifact[:generated_at])`")
    println(io, "- Total runtime: $(_fmt_float(artifact[:total_seconds]; digits = 3)) s")
    println(io, "- Raw candidate count: $(artifact[:raw_candidate_count])")
    println(io, "- Family count: $(artifact[:family_count])")
    println(io, "- Synthesized seeds: $(artifact[:synthesized_seed_count]) ($(artifact[:accepted_synthesized_seed_count]) accepted for refinement)")
    println(io, "- Refined synthesized results: $(artifact[:refined_seed_result_count])")
    println(io, "- Winning origin: `$(artifact[:winning_origin])`")
    println(io, "- Oracle note: $(artifact[:oracle_note])\n")

    println(io, "## What's New\n")
    println(io, "- The finalizer now generates new seeds from the raw SP/MP candidate pool instead of only selecting an existing candidate.")
    println(io, "- Seed generation includes within-family barycenters and guarded cross-family synthesis, including grouped parameter stitching.")
    println(io, "- Every synthesized seed is screened with oracle-free fit and equation checks before optional full-trajectory refinement.")
    println(io, "- The final choice still stays oracle-free; truth metrics here are benchmark-only evaluation.\n")

    config = artifact[:run_config]
    consensus_config = artifact[:consensus_config]
    synth_config = artifact[:synth_config]
    println(io, "## Run Configuration\n")
    println(io, "- Interpolator: `$(config[:interpolator])` (resolved interpolator count: $(config[:interpolator_count]))")
    println(io, "- Shooting points: $(config[:shooting_points])")
    println(io, "- Multipoint: enabled=$(config[:use_multipoint]), points=$(config[:multipoint_n_points]), max pairs=$(config[:multipoint_max_pairs])")
    println(io, "- Parameter homotopy: $(config[:use_parameter_homotopy])")
    println(io, "- Raw-generation polishing: solver=$(config[:polish_solver_solutions]), final=$(config[:polish_solutions]), maxiters=$(config[:polish_maxiters]), maxtime=$(_fmt_float(config[:polish_maxtime]; digits = 1)) s")
    println(io, "- Base consensus: strategy=`$(consensus_config[:strategy])`, support points=$(consensus_config[:support_point_count]), support combos=$(consensus_config[:support_combo_count]), refine top families=$(consensus_config[:refine_top_families]), equation refit=$(consensus_config[:do_equation_refit])")
    println(io, "- Synthesizer: family seeds=$(synth_config[:max_family_seeds]), cross-family seeds=$(synth_config[:max_cross_family_seeds]), cross-family enabled=$(synth_config[:allow_cross_family_synthesis]), stitching=$(synth_config[:allow_parameter_stitching]), distance limit=$(_fmt_float(synth_config[:cross_family_distance_limit]; digits = 3)), max refined seeds=$(synth_config[:max_refine_candidates]), objective=`$(synth_config[:refine_objective_mode])`\n")

    raw_summary = artifact[:raw_summary]
    best_refined_summary = artifact[:best_refined_summary]
    final_summary = artifact[:final_summary]
    println(io, "## Outcome Comparison\n")
    println(io, "| Candidate | Fit Error | Param RMSE | Combined RMSE | Lineage |")
    println(io, "|-----------|-----------|------------|---------------|---------|")
    for summary in (raw_summary, best_refined_summary, final_summary)
        println(
            io,
            "| $(summary[:label]) | $(_fmt_sci(summary[:fit_error])) | " *
            "$(_fmt_percent(get(summary[:truth_metrics], :parameter_rel_rmse, Inf))) | " *
            "$(_fmt_percent(get(summary[:truth_metrics], :combined_rel_rmse, Inf))) | $(summary[:lineage]) |"
        )
    end
    println(io)

    improvement = _consensus_biggest_shift(raw_summary, final_summary; direction = :improvement)
    worsening = _consensus_biggest_shift(raw_summary, final_summary; direction = :worsening)
    println(io, "## Impact Summary\n")
    raw_rmse = get(raw_summary[:truth_metrics], :combined_rel_rmse, Inf)
    final_rmse = get(final_summary[:truth_metrics], :combined_rel_rmse, Inf)
    println(io, "- Combined oracle RMSE: $(_fmt_percent(raw_rmse)) → $(_fmt_percent(final_rmse))")
    println(io, "- Final winner came from: `$(artifact[:winning_origin])`")
    if !isnothing(improvement) && improvement.delta > 0
        println(io, "- Biggest improvement: `$(improvement.label)` $(_fmt_percent(improvement.before)) → $(_fmt_percent(improvement.after))")
    end
    if !isnothing(worsening) && worsening.delta < 0
        println(io, "- Biggest regression: `$(worsening.label)` $(_fmt_percent(worsening.before)) → $(_fmt_percent(worsening.after))")
    end
    println(io)

    println(io, "## Parameter and IC Table\n")
    println(io, "| Variable | Raw Rel Error | Final Rel Error | Delta |")
    println(io, "|----------|---------------|-----------------|-------|")
    raw_rows = Dict(row.label => row.rel_error for row in get(raw_summary[:truth_metrics], :all_rows, NamedTuple[]))
    final_rows = Dict(row.label => row.rel_error for row in get(final_summary[:truth_metrics], :all_rows, NamedTuple[]))
    labels = sort!(collect(union(keys(raw_rows), keys(final_rows))))
    for label in labels
        raw_rel = get(raw_rows, label, Inf)
        final_rel = get(final_rows, label, Inf)
        delta = raw_rel - final_rel
        delta_string = isfinite(delta) ? @sprintf("%+.2f%%", 100 * delta) : "n/a"
        println(io, "| `$(label)` | $(_fmt_percent(raw_rel)) | $(_fmt_percent(final_rel)) | $(delta_string) |")
    end
    println(io)

    println(io, "## Synthesized Seeds\n")
    println(io, "| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |")
    println(io, "|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|")
    if isempty(artifact[:seed_rows])
        println(io, "| 1 | - | none | none | none | false | Inf | Inf | Inf | Inf |")
    else
        for row in artifact[:seed_rows]
            println(io, "| $(row.rank) | $(row.seed_index) | `$(row.kind)` | $(row.families) | $(row.source_candidates) | $(row.accepted) | $(_fmt_float(row.pre_refine_score; digits = 4)) | $(_fmt_sci(row.fit_loss)) | $(_fmt_sci(row.equation_penalty)) | $(_fmt_float(row.nearest_raw_distance; digits = 4)) |")
        end
    end
    println(io)

    println(io, "## Refined Synthesized Results\n")
    println(io, "| Rank | Fit Error | Param RMSE | Combined RMSE | Lineage |")
    println(io, "|------|-----------|------------|---------------|---------|")
    if isempty(artifact[:refined_rows])
        println(io, "| 1 | Inf | Inf | Inf | none |")
    else
        for row in artifact[:refined_rows]
            println(io, "| $(row.rank) | $(_fmt_sci(row.fit_error)) | $(_fmt_percent(row.parameter_rel_rmse)) | $(_fmt_percent(row.combined_rel_rmse)) | $(row.lineage) |")
        end
    end
    println(io)

    println(io, "## Raw Families\n")
    println(io, "| Rank | Size | Family Score | Medoid | Best Member | Interpolators | Sources | Shooting Support |")
    println(io, "|------|------|--------------|--------|-------------|---------------|---------|------------------|")
    if isempty(artifact[:top_families])
        println(io, "| 1 | 0 | Inf | - | - | none | none | none |")
    else
        for row in artifact[:top_families]
            interpolator_string = isempty(row.interpolators) ? "none" : row.interpolators
            source_type_string = isempty(row.source_types) ? "none" : row.source_types
            println(io, "| $(row.rank) | $(row.member_count) | $(_fmt_float(row.family_score; digits = 4)) | $(row.medoid_index) | $(row.best_member_index) | $(interpolator_string) | $(source_type_string) | $(row.shooting_support) |")
        end
    end
    println(io)

    return String(take!(io))
end
