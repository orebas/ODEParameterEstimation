function _symbol_base_name(sym)::String
    return replace(string(sym), "(t)" => "")
end

function _seed_vector_distance(v1::AbstractVector{<:Real}, v2::AbstractVector{<:Real})
    dist = 0.0
    for i in eachindex(v1, v2)
        a = Float64(v1[i])
        b = Float64(v2[i])
        scale = max(abs(a) + abs(b), 1.0)
        dist = max(dist, abs(a - b) / scale)
    end
    return dist
end

function _clamp_seed_vector(seed_vector::AbstractVector{<:Real}, ctx::PolishContext)
    vec = Float64[seed_vector...]
    if !isnothing(ctx.lb) && !isnothing(ctx.ub)
        return clamp.(vec, ctx.lb, ctx.ub)
    end
    return vec
end

function _seed_loss(ctx::PolishContext, seed_vector::AbstractVector{<:Real})
    try
        return Float64(ctx.optf.f(_clamp_seed_vector(seed_vector, ctx), nothing))
    catch
        return Inf
    end
end

function _finite_mean_or_inf(values)
    finite_values = filter(isfinite, values)
    return isempty(finite_values) ? Inf : mean(finite_values)
end

function _common_value(values)
    isempty(values) && return nothing
    first_val = first(values)
    all(==(first_val), values) ? first_val : nothing
end

function _candidate_equation_proxy(evidence::CandidateEvidence)
    components = Float64[]
    for val in (evidence.sp_equation_residual_kept, evidence.mp_equation_residual_kept)
        isfinite(val) && push!(components, val)
    end
    for val in (evidence.sp_equation_residual_dropped, evidence.mp_equation_residual_dropped)
        isfinite(val) && push!(components, 0.5 * val)
    end
    return isempty(components) ? Inf : mean(components)
end

function _build_seed_candidate(
    seed_vector::AbstractVector{<:Real},
    pep::ParameterEstimationProblem,
    ctx::PolishContext,
    fit_error::Float64,
    seed_kind::Symbol,
    source_candidate_indices::Vector{Int},
    source_family_indices::Vector{Int},
    source_candidates::Vector{ParameterEstimationResult},
)
    vec = _clamp_seed_vector(seed_vector, ctx)
    states_out = OrderedDict(
        s => Float64(vec[ctx.state_index[s]])
        for s in ctx.state_syms_out if haskey(ctx.state_index, s)
    )
    params_out = OrderedDict(
        p => Float64(vec[ctx.n_ic + ctx.param_index[p]])
        for p in ctx.param_syms_out if haskey(ctx.param_index, p)
    )

    all_unidentifiable = Set{Num}()
    for candidate in source_candidates
        union!(all_unidentifiable, candidate.all_unidentifiable)
    end

    result = ParameterEstimationResult(
        params_out,
        states_out,
        ctx.t_vector[1],
        fit_error,
        nothing,
        length(ctx.t_vector),
        ctx.t_vector[1],
        OrderedDict{Num, Float64}(),
        all_unidentifiable,
        nothing,
    )

    common_interp = _common_value([
        candidate.provenance.interpolator_source for candidate in source_candidates
        if !isnothing(candidate.provenance.interpolator_source)
    ])
    common_shoot = _common_value([
        candidate.provenance.source_shooting_index for candidate in source_candidates
        if !isnothing(candidate.provenance.source_shooting_index)
    ])
    common_mp = _common_value([
        candidate.provenance.multipoint_time_indices for candidate in source_candidates
        if !isnothing(candidate.provenance.multipoint_time_indices)
    ])

    notes = Symbol[:synthesized_seed, seed_kind]
    length(source_family_indices) > 1 && push!(notes, :cross_family_synthesis)
    seed_kind == :parameter_stitch && push!(notes, :parameter_stitch)

    result.provenance = ResultProvenance(
        primary_method = :direct_opt,
        interpolator_source = common_interp,
        source_shooting_index = common_shoot,
        source_candidate_index = length(source_candidate_indices) == 1 ? only(source_candidate_indices) : nothing,
        pre_polish_error = fit_error,
        polish_applied = false,
        notes = notes,
        source_type = :synthesized,
        multipoint_time_indices = isnothing(common_mp) ? nothing : copy(common_mp),
    )
    sync_result_contract!(result)
    return result
end

function _family_seed_vectors(
    raw_candidates::Vector{ParameterEstimationResult},
    family::CandidateFamily,
    ctx::PolishContext,
)
    return [_candidate_to_vector(raw_candidates[idx], ctx) for idx in family.member_indices]
end

function _componentwise_median(vectors::Vector{Vector{Float64}})
    isempty(vectors) && return Float64[]
    n = length(first(vectors))
    return Float64[median([vec[i] for vec in vectors]) for i in 1:n]
end

function _inverse_fit_weights(candidates::Vector{ParameterEstimationResult}, indices::Vector{Int})
    weights = Float64[]
    for idx in indices
        err = _result_err_key(candidates[idx])
        push!(weights, isfinite(err) ? 1 / max(err, 1e-12) : 0.0)
    end
    total = sum(weights)
    total > 0 || return fill(1 / max(length(indices), 1), length(indices))
    return weights ./ total
end

function _weighted_average(vectors::Vector{Vector{Float64}}, weights::Vector{Float64})
    isempty(vectors) && return Float64[]
    total = zero(first(vectors))
    for (vec, w) in zip(vectors, weights)
        total .+= w .* vec
    end
    return Float64[total...]
end

function _candidate_groups(ctx::PolishContext)
    names = [_symbol_base_name(sym) for sym in vcat(ctx.unknown_syms, ctx.param_syms)]
    assigned = falses(length(names))
    groups = NamedTuple[]

    function add_group(name::Symbol, base_names::Vector{String})
        idxs = findall(i -> names[i] in base_names, eachindex(names))
        isempty(idxs) && return
        assigned[idxs] .= true
        push!(groups, (name = name, base_names = Set(base_names), indices = Int[idxs...]))
    end

    add_group(:latent_branch, ["x3", "a13", "a31", "a01"])
    add_group(:observed_branch, ["a12", "a21"])
    add_group(:direct_ic, ["x1", "x2"])

    for (idx, name) in enumerate(names)
        assigned[idx] && continue
        push!(groups, (
            name = Symbol("group_" * replace(name, r"[^A-Za-z0-9]+" => "_")),
            base_names = Set([name]),
            indices = [idx],
        ))
    end
    return groups
end

function _var_base_name(var_name::AbstractString)
    clean_name, _ = _parse_multipoint_var_name(var_name)
    parsed = parse_derivative_variable_name(clean_name)
    if !isnothing(parsed)
        base_name, _ = parsed
        return String(base_name)
    end
    return clean_name
end

function _filter_equations_for_group(equations, group_bases::Set{String})
    selected = Num[]
    vars = OrderedSet{Any}()
    for eq in equations
        eq_vars = Symbolics.get_variables(eq)
        if any(v -> _var_base_name(string(v)) in group_bases, eq_vars)
            push!(selected, eq)
            union!(vars, eq_vars)
        end
    end
    return selected, collect(vars)
end

function _group_penalty_for_candidate(
    candidate_index::Int,
    candidate::ParameterEstimationResult,
    context,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
    group_bases::Set{String},
    coeff_cache::Dict,
    system_cache::Dict,
)
    pep = context.pep
    opts = context.opts
    source = _consensus_source_symbol(candidate, context.default_source)
    interpolants = get(context.interpolant_cache, source, context.interpolant_cache[context.default_source])

    penalties = Float64[]

    all_sp_eqs = hasproperty(context.si_template, :all_equations) ? context.si_template.all_equations : context.si_template.equations
    dropped_sp_indices = hasproperty(context.si_template, :rank_trimming_metadata) ? context.si_template.rank_trimming_metadata.dropped_equation_indices : Int[]
    dropped_sp_eqs = isempty(dropped_sp_indices) ? Num[] : all_sp_eqs[filter(i -> 1 <= i <= length(all_sp_eqs), dropped_sp_indices)]

    for point_idx in support_points
        t_eval = pep.data_sample["t"][point_idx]
        kept_key = (:sp_kept, source, point_idx)
        eqs, _ = get!(system_cache, kept_key) do
            construct_equation_system_from_si_template(
                pep.model.system,
                pep.measured_quantities,
                pep.data_sample,
                context.ident_data.good_deriv_level,
                context.ident_data.good_udict,
                context.ident_data.good_varlist,
                context.ident_data.good_DD;
                interpolator = context.interpolator_function_cache[source],
                time_index_set = [point_idx],
                precomputed_interpolants = interpolants,
                diagnostics = false,
                si_template = context.si_template,
            )
        end
        selected_eqs, selected_vars = _filter_equations_for_group(eqs, group_bases)
        if !isempty(selected_eqs)
            max_order = maximum(_multipoint_var_order(string(v)) for v in selected_vars)
            coeff_data = _consensus_coefficients!(coeff_cache, candidate_index, candidate, pep, [point_idx], max_order, opts)
            vals = _candidate_value_vector(selected_vars, coeff_data)
            push!(penalties, _equation_residual_norm(selected_eqs, selected_vars, vals))
        end

        if !isempty(dropped_sp_eqs)
            dropped_key = (:sp_dropped, source, point_idx)
            inst_dropped_eqs, _ = get!(system_cache, dropped_key) do
                _instantiate_template_equations_at_point(dropped_sp_eqs, pep, interpolants, t_eval)
            end
            selected_eqs, selected_vars = _filter_equations_for_group(inst_dropped_eqs, group_bases)
            if !isempty(selected_eqs)
                max_order = maximum(_multipoint_var_order(string(v)) for v in selected_vars)
                coeff_data = _consensus_coefficients!(coeff_cache, candidate_index, candidate, pep, [point_idx], max_order, opts)
                vals = _candidate_value_vector(selected_vars, coeff_data)
                push!(penalties, 0.5 * _equation_residual_norm(selected_eqs, selected_vars, vals))
            end
        end
    end

    if !isnothing(context.mpt) && !isempty(support_combos)
        for combo in support_combos
            combo_tuple = Tuple(combo)
            try
                evaluation = get!(system_cache, (:mp_eval, source, combo_tuple)) do
                    evaluate_multipoint_template(context.mpt, Int[combo...], interpolants, pep.data_sample)
                end

                kept_eqs, _ = get!(system_cache, (:mp_kept, source, combo_tuple)) do
                    _instantiate_multipoint_equations(context.mpt, context.mpt.stripped_equations, evaluation)
                end
                selected_eqs, selected_vars = _filter_equations_for_group(kept_eqs, group_bases)
                if !isempty(selected_eqs)
                    max_order = maximum(_multipoint_var_order(string(v)) for v in selected_vars)
                    coeff_data = _consensus_coefficients!(coeff_cache, candidate_index, candidate, pep, combo, max_order, opts)
                    vals = _candidate_value_vector(selected_vars, coeff_data)
                    push!(penalties, _equation_residual_norm(selected_eqs, selected_vars, vals))
                end

                if !isempty(context.mpt.dropped_equation_indices)
                    dropped_eqs, _ = get!(system_cache, (:mp_dropped, source, combo_tuple)) do
                        all_dropped = context.mpt.all_equations[context.mpt.dropped_equation_indices]
                        _instantiate_multipoint_equations(context.mpt, all_dropped, evaluation)
                    end
                    selected_eqs, selected_vars = _filter_equations_for_group(dropped_eqs, group_bases)
                    if !isempty(selected_eqs)
                        max_order = maximum(_multipoint_var_order(string(v)) for v in selected_vars)
                        coeff_data = _consensus_coefficients!(coeff_cache, candidate_index, candidate, pep, combo, max_order, opts)
                        vals = _candidate_value_vector(selected_vars, coeff_data)
                        push!(penalties, 0.5 * _equation_residual_norm(selected_eqs, selected_vars, vals))
                    end
                end
            catch
            end
        end
    end

    return _finite_mean_or_inf(penalties)
end

function _dedup_synthesized_seeds(seeds::Vector{SynthesizedSeed}; threshold::Float64 = 1e-3)
    deduped = SynthesizedSeed[]
    for seed in seeds
        if any(existing -> _seed_vector_distance(seed.seed_vector, existing.seed_vector) <= threshold, deduped)
            continue
        end
        push!(deduped, seed)
    end
    return deduped
end

function _build_family_synthesized_seeds(
    raw_candidates::Vector{ParameterEstimationResult},
    raw_report::ConsensusEstimationReport,
    polish_ctx::PolishContext,
    synth_opts::SynthesizedFinalizerOptions,
)
    seeds = SynthesizedSeed[]
    for (family_rank, family) in enumerate(raw_report.families)
        family_rank > synth_opts.max_family_seeds && break
        length(family.member_indices) <= 1 && continue

        vectors = _family_seed_vectors(raw_candidates, family, polish_ctx)
        median_vec = _clamp_seed_vector(_componentwise_median(vectors), polish_ctx)
        push!(seeds, SynthesizedSeed(
            median_vec,
            :family_barycenter,
            copy(family.member_indices),
            [family_rank],
            "family=$(family_rank), members=$(family.member_indices), kind=componentwise_median",
            Dict{Symbol, Any}(),
        ))

        weights = _inverse_fit_weights(raw_candidates, family.member_indices)
        weighted_vec = _clamp_seed_vector(_weighted_average(vectors, weights), polish_ctx)
        push!(seeds, SynthesizedSeed(
            weighted_vec,
            :family_weighted_barycenter,
            copy(family.member_indices),
            [family_rank],
            "family=$(family_rank), members=$(family.member_indices), kind=fit_weighted_average",
            Dict{Symbol, Any}(),
        ))
    end
    return _dedup_synthesized_seeds(seeds)
end

function _cross_family_pairs(
    raw_candidates::Vector{ParameterEstimationResult},
    raw_report::ConsensusEstimationReport,
    synth_opts::SynthesizedFinalizerOptions,
)
    isempty(raw_report.families) && return NamedTuple[]
    family_limit = min(length(raw_report.families), max(2, synth_opts.max_cross_family_seeds + 1))
    pairs = NamedTuple[]
    for i in 1:family_limit
        for j in (i + 1):family_limit
            family_i = raw_report.families[i]
            family_j = raw_report.families[j]
            dist = solution_distance(
                raw_candidates[family_i.family_medoid_index],
                raw_candidates[family_j.family_medoid_index],
            )
            dist <= synth_opts.cross_family_distance_limit || continue
            push!(pairs, (
                family_i = i,
                family_j = j,
                distance = dist,
                priority = raw_report.families[i].family_score + raw_report.families[j].family_score,
            ))
        end
    end
    sort!(pairs; by = pair -> (pair.priority, pair.distance))
    return pairs
end

function _build_cross_family_synthesized_seeds(
    raw_candidates::Vector{ParameterEstimationResult},
    raw_report::ConsensusEstimationReport,
    context,
    polish_ctx::PolishContext,
    synth_opts::SynthesizedFinalizerOptions,
)
    synth_opts.allow_cross_family_synthesis || return SynthesizedSeed[]

    seeds = SynthesizedSeed[]
    pairs = _cross_family_pairs(raw_candidates, raw_report, synth_opts)
    coeff_cache = Dict{Any, Any}()
    system_cache = Dict{Any, Any}()
    groups = _candidate_groups(polish_ctx)

    for pair in pairs
        length(seeds) >= synth_opts.max_cross_family_seeds && break
        family_i = raw_report.families[pair.family_i]
        family_j = raw_report.families[pair.family_j]
        cand_i = raw_candidates[family_i.family_medoid_index]
        cand_j = raw_candidates[family_j.family_medoid_index]
        vec_i = _candidate_to_vector(cand_i, polish_ctx)
        vec_j = _candidate_to_vector(cand_j, polish_ctx)

        blend_vec = _clamp_seed_vector((vec_i .+ vec_j) ./ 2, polish_ctx)
        push!(seeds, SynthesizedSeed(
            blend_vec,
            :family_medoid_blend,
            [family_i.family_medoid_index, family_j.family_medoid_index],
            [pair.family_i, pair.family_j],
            "families=($(pair.family_i), $(pair.family_j)), kind=medoid_blend, distance=$(round(pair.distance; digits = 4))",
            Dict{Symbol, Any}(:family_distance => pair.distance),
        ))
        length(seeds) >= synth_opts.max_cross_family_seeds && break

        synth_opts.allow_parameter_stitching || continue
        group_sources = Dict{Symbol, Int}()
        stitched_vec = copy(vec_i)
        for group in groups
            penalty_i = _group_penalty_for_candidate(
                family_i.family_medoid_index,
                cand_i,
                context,
                raw_report.support_points,
                raw_report.support_combos,
                group.base_names,
                coeff_cache,
                system_cache,
            )
            penalty_j = _group_penalty_for_candidate(
                family_j.family_medoid_index,
                cand_j,
                context,
                raw_report.support_points,
                raw_report.support_combos,
                group.base_names,
                coeff_cache,
                system_cache,
            )
            if penalty_j + 1e-12 < penalty_i
                stitched_vec[group.indices] .= vec_j[group.indices]
                group_sources[group.name] = family_j.family_medoid_index
            else
                group_sources[group.name] = family_i.family_medoid_index
            end
        end

        if length(unique(values(group_sources))) > 1
            push!(seeds, SynthesizedSeed(
                _clamp_seed_vector(stitched_vec, polish_ctx),
                :parameter_stitch,
                [family_i.family_medoid_index, family_j.family_medoid_index],
                [pair.family_i, pair.family_j],
                "families=($(pair.family_i), $(pair.family_j)), kind=parameter_stitch, distance=$(round(pair.distance; digits = 4))",
                Dict{Symbol, Any}(
                    :family_distance => pair.distance,
                    :group_sources => group_sources,
                ),
            ))
        end
    end
    return _dedup_synthesized_seeds(seeds)
end

function _seed_baselines(raw_report::ConsensusEstimationReport)
    best_fit = minimum(_result_err_key(candidate) for candidate in raw_report.raw_candidates)
    best_eq = minimum(_candidate_equation_proxy(evidence) for evidence in raw_report.candidate_evidence)
    return (
        best_fit = isfinite(best_fit) ? best_fit : 1.0,
        best_equation = isfinite(best_eq) ? best_eq : 1.0,
    )
end

function _evaluate_synthesized_seeds(
    seeds::Vector{SynthesizedSeed},
    raw_candidates::Vector{ParameterEstimationResult},
    pep::ParameterEstimationProblem,
    context,
    polish_ctx::PolishContext,
    raw_report::ConsensusEstimationReport,
    synth_opts::SynthesizedFinalizerOptions,
)
    baselines = _seed_baselines(raw_report)
    coeff_cache = Dict{Any, Any}()
    system_cache = Dict{Any, Any}()
    order_cache = Dict{Any, Any}()
    evaluated = NamedTuple[]

    for (offset, seed) in enumerate(seeds)
        fit_loss = _seed_loss(polish_ctx, seed.seed_vector)
        source_candidates = raw_candidates[seed.source_candidate_indices]
        candidate = _build_seed_candidate(
            seed.seed_vector,
            pep,
            polish_ctx,
            fit_loss,
            seed.seed_kind,
            seed.source_candidate_indices,
            seed.source_family_indices,
            source_candidates,
        )

        raw_metric = _score_candidate_raw(
            length(raw_candidates) + offset,
            candidate,
            context,
            raw_report.support_points,
            raw_report.support_combos,
            coeff_cache,
            system_cache,
            order_cache,
        )
        nearest_raw_distance = minimum(solution_distance(candidate, raw) for raw in raw_candidates)
        equation_proxy = (
            isfinite(raw_metric.equation_penalty) ? raw_metric.equation_penalty :
            _finite_mean_or_inf([
                raw_metric.sp_equation_residual_kept,
                raw_metric.mp_equation_residual_kept,
                0.5 * raw_metric.sp_equation_residual_dropped,
                0.5 * raw_metric.mp_equation_residual_dropped,
            ])
        )

        accepted = isfinite(fit_loss) &&
                   isfinite(equation_proxy) &&
                   nearest_raw_distance <= synth_opts.cross_family_distance_limit * 2 &&
                   (
                       fit_loss <= baselines.best_fit * synth_opts.seed_consistency_threshold ||
                       equation_proxy <= baselines.best_equation * synth_opts.seed_consistency_threshold ||
                       nearest_raw_distance <= synth_opts.cross_family_distance_limit
                   )

        pre_score = (
            (isfinite(fit_loss) ? fit_loss / max(baselines.best_fit, 1e-12) : Inf) +
            (isfinite(equation_proxy) ? equation_proxy / max(baselines.best_equation, 1e-12) : Inf) +
            nearest_raw_distance / max(synth_opts.cross_family_distance_limit, 1e-12)
        )

        checks = copy(seed.pre_refine_checks)
        checks[:fit_loss] = fit_loss
        checks[:equation_penalty] = equation_proxy
        checks[:nearest_raw_distance] = nearest_raw_distance
        checks[:accepted] = accepted
        checks[:pre_refine_score] = pre_score
        checks[:sp_equation_residual_kept] = raw_metric.sp_equation_residual_kept
        checks[:sp_equation_residual_dropped] = raw_metric.sp_equation_residual_dropped
        checks[:mp_equation_residual_kept] = raw_metric.mp_equation_residual_kept
        checks[:mp_equation_residual_dropped] = raw_metric.mp_equation_residual_dropped

        evaluated_seed = SynthesizedSeed(
            seed.seed_vector,
            seed.seed_kind,
            seed.source_candidate_indices,
            seed.source_family_indices,
            seed.seed_lineage_summary,
            checks,
        )
        push!(evaluated, (
            seed = evaluated_seed,
            candidate = candidate,
            accepted = accepted,
            pre_score = pre_score,
        ))
    end
    return evaluated
end

function _refine_synthesized_seed_candidates(
    evaluated_seeds,
    pep::ParameterEstimationProblem,
    polish_ctx::PolishContext,
    context,
    synth_opts::SynthesizedFinalizerOptions,
)
    accepted = filter(item -> item.accepted, evaluated_seeds)
    isempty(accepted) && return ParameterEstimationResult[]
    ordered = sort(accepted; by = item -> item.pre_score)
    selected = ordered[1:min(synth_opts.max_refine_candidates, length(ordered))]

    if !synth_opts.refine_with_full_trajectory
        return ParameterEstimationResult[item.candidate for item in selected]
    end

    refined = ParameterEstimationResult[]
    for item in selected
        try
            push!(refined, _polish_research_seed(pep, item.candidate, polish_ctx, context.opts))
        catch
        end
    end
    return refined
end

function _select_synthesized_winner(
    raw_report::ConsensusEstimationReport,
    refined_results::Vector{ParameterEstimationResult},
    context,
    synth_opts::SynthesizedFinalizerOptions,
)
    raw_candidates = raw_report.raw_candidates
    raw_winner_idx = isnothing(raw_report.winner_candidate_index) ? _argmin_by(eachindex(raw_report.candidate_evidence), i -> raw_report.candidate_evidence[i].composite_score) : raw_report.winner_candidate_index
    raw_winner = isnothing(raw_winner_idx) ? nothing : raw_candidates[raw_winner_idx]
    raw_score = isnothing(raw_winner_idx) ? Inf : raw_report.candidate_evidence[raw_winner_idx].composite_score
    raw_fit = isnothing(raw_winner) ? Inf : _result_err_key(raw_winner)

    isempty(refined_results) && return (
        winning_result = raw_winner,
        winning_origin = :raw,
        selection_summary = Dict{Symbol, Any}(
            :raw_winner_index => raw_winner_idx,
            :raw_winner_score => raw_score,
            :raw_winner_fit_error => raw_fit,
            :synthesized_best_index => nothing,
            :synthesized_best_score => Inf,
            :synthesized_best_fit_error => Inf,
            :winning_origin => :raw,
            :winner_seed_kind => nothing,
            :combined_candidate_count => length(raw_candidates),
        ),
    )

    combined = vcat(raw_candidates, refined_results)
    combined_evidence = _build_candidate_evidence(
        combined,
        context,
        raw_report.support_points,
        raw_report.support_combos,
        synth_opts.base_consensus_opts,
    )
    combined_order = sortperm(1:length(combined_evidence); by = idx -> (
        combined_evidence[idx].composite_score,
        combined_evidence[idx].base_fit_error,
    ))
    best_idx = first(combined_order)
    best_result = combined[best_idx]
    best_evidence = combined_evidence[best_idx]

    raw_combined_evidence = isnothing(raw_winner_idx) ? nothing : combined_evidence[raw_winner_idx]
    raw_combined_score = isnothing(raw_combined_evidence) ? raw_score : raw_combined_evidence.composite_score
    raw_combined_fit = isnothing(raw_combined_evidence) ? raw_fit : raw_combined_evidence.base_fit_error

    winning_result = raw_winner
    winning_origin = :raw
    winner_seed_kind = nothing
    if best_idx > length(raw_candidates)
        synth_better = best_evidence.composite_score + 1e-6 < raw_combined_score ||
                       (abs(best_evidence.composite_score - raw_combined_score) <= 1e-6 &&
                        best_evidence.base_fit_error < raw_combined_fit * 0.99)
        if synth_better
            winning_result = best_result
            winning_origin = :synthesized
            winner_seed_kind = let
                seed_notes = filter(
                    note -> note in (:family_barycenter, :family_weighted_barycenter, :family_medoid_blend, :parameter_stitch),
                    best_result.provenance.notes,
                )
                isempty(seed_notes) ? nothing : first(seed_notes)
            end
        end
    end

    return (
        winning_result = winning_result,
        winning_origin = winning_origin,
        selection_summary = Dict{Symbol, Any}(
            :raw_winner_index => raw_winner_idx,
            :raw_winner_score => raw_combined_score,
            :raw_winner_fit_error => raw_combined_fit,
            :synthesized_best_index => best_idx > length(raw_candidates) ? best_idx - length(raw_candidates) : nothing,
            :synthesized_best_score => best_idx > length(raw_candidates) ? best_evidence.composite_score : Inf,
            :synthesized_best_fit_error => best_idx > length(raw_candidates) ? best_evidence.base_fit_error : Inf,
            :winning_origin => winning_origin,
            :winner_seed_kind => winner_seed_kind,
            :combined_candidate_count => length(combined),
        ),
    )
end

function _synthesized_benchmark_evaluation(
    raw_report::ConsensusEstimationReport,
    refined_results::Vector{ParameterEstimationResult},
    winning_result::Union{Nothing, ParameterEstimationResult},
    pep::ParameterEstimationProblem,
)
    raw_truth = _candidate_truth_metrics(pep, raw_report.winner_candidate)
    win_truth = _candidate_truth_metrics(pep, winning_result)
    best_synth = if isempty(refined_results)
        nothing
    else
        refined_results[_argmin_by(eachindex(refined_results), i -> _result_err_key(refined_results[i]))]
    end
    synth_truth = _candidate_truth_metrics(pep, best_synth)
    return Dict{Symbol, Any}(
        :raw_winner_truth_metrics => raw_truth,
        :winning_truth_metrics => win_truth,
        :best_synthesized_truth_metrics => synth_truth,
        :combined_rmse_improvement => get(raw_truth, :combined_rel_rmse, Inf) - get(win_truth, :combined_rel_rmse, Inf),
    )
end

function _research_synthesized_finalizer_from_shared(
    pep_with_data::ParameterEstimationProblem,
    run_opts::EstimationOptions,
    raw_candidates::Vector{ParameterEstimationResult},
    context,
    synth_opts::SynthesizedFinalizerOptions,
)
    raw_report = _assemble_consensus_report(
        pep_with_data,
        run_opts,
        raw_candidates,
        synth_opts.base_consensus_opts;
        context = context,
    )

    if isempty(raw_report.raw_candidates)
        return SynthesizedFinalizerReport(
            raw_report,
            SynthesizedSeed[],
            ParameterEstimationResult[],
            nothing,
            :raw,
            Dict{Symbol, Any}(
                :note => "no raw candidates were produced",
                :winning_origin => :raw,
            ),
            Dict{Symbol, Any}(),
        )
    end

    polish_ctx = _build_polish_context(pep_with_data; opts = run_opts)

    family_seeds = _build_family_synthesized_seeds(raw_report.raw_candidates, raw_report, polish_ctx, synth_opts)
    cross_family_seeds = _build_cross_family_synthesized_seeds(raw_report.raw_candidates, raw_report, context, polish_ctx, synth_opts)
    synthesized_seeds = _dedup_synthesized_seeds(vcat(family_seeds, cross_family_seeds))

    evaluated_seeds = _evaluate_synthesized_seeds(
        synthesized_seeds,
        raw_report.raw_candidates,
        pep_with_data,
        context,
        polish_ctx,
        raw_report,
        synth_opts,
    )
    evaluated_seed_reports = SynthesizedSeed[item.seed for item in evaluated_seeds]

    refined_results = _refine_synthesized_seed_candidates(
        evaluated_seeds,
        pep_with_data,
        polish_ctx,
        context,
        synth_opts,
    )

    selection = _select_synthesized_winner(raw_report, refined_results, context, synth_opts)
    benchmark_evaluation = _synthesized_benchmark_evaluation(raw_report, refined_results, selection.winning_result, pep_with_data)

    selection_summary = copy(selection.selection_summary)
    selection_summary[:n_raw_candidates] = length(raw_report.raw_candidates)
    selection_summary[:n_families] = length(raw_report.families)
    selection_summary[:n_synthesized_seeds] = length(evaluated_seed_reports)
    selection_summary[:n_accepted_synthesized_seeds] = count(seed -> get(seed.pre_refine_checks, :accepted, false), evaluated_seed_reports)
    selection_summary[:n_refined_seed_results] = length(refined_results)
    selection_summary[:refine_objective_mode] = synth_opts.refine_objective_mode
    selection_summary[:allow_cross_family_synthesis] = synth_opts.allow_cross_family_synthesis
    selection_summary[:allow_parameter_stitching] = synth_opts.allow_parameter_stitching
    selection_summary[:version_label] = :synth_v0

    return SynthesizedFinalizerReport(
        raw_report,
        evaluated_seed_reports,
        refined_results,
        selection.winning_result,
        selection.winning_origin,
        selection_summary,
        benchmark_evaluation,
    )
end

function research_synthesized_finalizer(
    pep::ParameterEstimationProblem;
    est_opts::EstimationOptions = EstimationOptions(),
    synth_opts::SynthesizedFinalizerOptions = SynthesizedFinalizerOptions(),
)
    pep_with_data, run_opts, raw_candidates = _prepare_consensus_inputs(pep, est_opts)
    context = isempty(raw_candidates) ? nothing : _build_consensus_context(pep_with_data, run_opts)
    return _research_synthesized_finalizer_from_shared(
        pep_with_data,
        run_opts,
        raw_candidates,
        context,
        synth_opts,
    )
end
