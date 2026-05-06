function _branch_base_consensus_opts(branch_opts::BranchConsensusOptions)
    return ConsensusOptions(
        strategy = :family_consensus,
        support_point_count = branch_opts.support_point_count,
        support_combo_count = branch_opts.support_combo_count,
        refine_top_families = 1,
        do_equation_refit = false,
    )
end

function _branch_origin_key(candidate::ParameterEstimationResult)
    prov = candidate.provenance
    return (
        source_type = prov.source_type,
        interpolator = isnothing(prov.interpolator_source) ? :unknown : prov.interpolator_source,
        shooting = prov.source_shooting_index,
        combo = prov.multipoint_combo_index,
        mp_times = isnothing(prov.multipoint_time_indices) ? () : Tuple(Int[prov.multipoint_time_indices...]),
    )
end

function _branch_origin_label(origin_key)::String
    parts = String["source=$(origin_key.source_type)", "interp=$(origin_key.interpolator)"]
    !isnothing(origin_key.shooting) && push!(parts, "shoot=$(origin_key.shooting)")
    !isnothing(origin_key.combo) && push!(parts, "combo=$(origin_key.combo)")
    !isempty(origin_key.mp_times) && push!(parts, "mp=$(origin_key.mp_times)")
    return join(parts, ", ")
end

function _branch_count_prior(candidates::Vector{ParameterEstimationResult})
    counts = Int[]

    by_shoot = Dict{Int, Int}()
    by_combo = Dict{Tuple{Int, Vararg{Int}}, Int}()
    for candidate in candidates
        prov = candidate.provenance
        if !isnothing(prov.source_shooting_index)
            by_shoot[prov.source_shooting_index] = get(by_shoot, prov.source_shooting_index, 0) + 1
        end
        if !isnothing(prov.multipoint_combo_index) && !isnothing(prov.multipoint_time_indices)
            key = (prov.multipoint_combo_index, prov.multipoint_time_indices...)
            by_combo[key] = get(by_combo, key, 0) + 1
        end
    end

    append!(counts, values(by_shoot))
    append!(counts, values(by_combo))
    isempty(counts) && return 1
    return max(1, round(Int, median(Float64[counts...])))
end

function _branch_distance_matrix(candidates::Vector{ParameterEstimationResult})
    n = length(candidates)
    dist = fill(Inf, n, n)
    for i in 1:n
        dist[i, i] = 0.0
    end
    for i in 1:n
        for j in (i + 1):n
            dij = try
                solution_distance(candidates[i], candidates[j])
            catch
                Inf
            end
            dist[i, j] = dij
            dist[j, i] = dij
        end
    end
    return dist
end

function _branch_components_from_threshold(
    origin_keys,
    dist_matrix::AbstractMatrix{<:Real},
    threshold::Float64,
)
    n = length(origin_keys)
    adjacency = [Int[] for _ in 1:n]
    for i in 1:n
        for j in (i + 1):n
            origin_keys[i] == origin_keys[j] && continue
            dij = Float64(dist_matrix[i, j])
            if isfinite(dij) && dij <= threshold
                push!(adjacency[i], j)
                push!(adjacency[j], i)
            end
        end
    end

    visited = falses(n)
    components = Vector{Vector{Int}}()
    for start in 1:n
        visited[start] && continue
        stack = [start]
        visited[start] = true
        component = Int[]
        while !isempty(stack)
            idx = pop!(stack)
            push!(component, idx)
            for nbr in adjacency[idx]
                visited[nbr] && continue
                visited[nbr] = true
                push!(stack, nbr)
            end
        end
        sort!(component)
        push!(components, component)
    end
    return components
end

function _select_branch_threshold(
    candidates::Vector{ParameterEstimationResult},
    origin_keys,
    dist_matrix::AbstractMatrix{<:Real},
    branch_opts::BranchConsensusOptions,
)
    target_count = _branch_count_prior(candidates)
    finite_distances = Float64[]
    for i in 1:length(candidates)
        for j in (i + 1):length(candidates)
            origin_keys[i] == origin_keys[j] && continue
            dij = Float64(dist_matrix[i, j])
            isfinite(dij) || continue
            branch_opts.branch_distance_floor <= dij <= branch_opts.branch_distance_ceiling || continue
            push!(finite_distances, dij)
        end
    end

    if isempty(finite_distances)
        return branch_opts.branch_distance_floor, target_count
    end

    thresholds = sort!(unique(vcat(
        [branch_opts.branch_distance_floor, branch_opts.branch_distance_ceiling],
        finite_distances,
    )))

    best_threshold = branch_opts.branch_distance_floor
    best_cost = (typemax(Int), Inf)
    for threshold in thresholds
        components = _branch_components_from_threshold(origin_keys, dist_matrix, threshold)
        branch_count = length(components)
        cost = (abs(branch_count - target_count), threshold)
        if cost < best_cost
            best_cost = cost
            best_threshold = threshold
        end
    end

    return best_threshold, target_count
end

function _branch_member_compactness(members::Vector{Int}, dist_matrix::AbstractMatrix{<:Real})
    length(members) <= 1 && return 0.0
    distances = Float64[]
    for i in 1:length(members)
        for j in (i + 1):length(members)
            dij = Float64(dist_matrix[members[i], members[j]])
            isfinite(dij) && push!(distances, dij)
        end
    end
    isempty(distances) && return 0.0
    return median(distances)
end

function _branch_distinct_shooting_support(members, candidates)
    support = Int[]
    for idx in members
        prov = candidates[idx].provenance
        !isnothing(prov.source_shooting_index) && push!(support, prov.source_shooting_index)
        if !isnothing(prov.multipoint_time_indices)
            append!(support, prov.multipoint_time_indices)
        end
    end
    sort!(support)
    unique!(support)
    return support
end

function _branch_distinct_combo_support(members, candidates)
    combos = Int[]
    for idx in members
        prov = candidates[idx].provenance
        !isnothing(prov.multipoint_combo_index) && push!(combos, prov.multipoint_combo_index)
    end
    sort!(combos)
    unique!(combos)
    return combos
end

function _branch_distinct_source_types(members, candidates)
    return sort!(collect(Set(Symbol[candidates[idx].provenance.source_type for idx in members])))
end

function _branch_distinct_interpolators(members, candidates)
    interpolators = Symbol[]
    for idx in members
        src = candidates[idx].provenance.interpolator_source
        isnothing(src) || push!(interpolators, src)
    end
    return sort!(collect(Set(interpolators)))
end

function _branch_quality_score(member_indices::Vector{Int}, evidence::Vector{CandidateEvidence})
    best_member = _argmin_by(member_indices, i -> evidence[i].composite_score)
    best_score = evidence[best_member].composite_score
    trust_score = 1.0 - evidence[best_member].score_breakdown.trust
    return best_member, clamp(1.0 - best_score, 0.0, 1.0), clamp(trust_score, 0.0, 1.0)
end

function _branch_equation_best_member(member_indices::Vector{Int}, evidence::Vector{CandidateEvidence})
    return _argmin_by(member_indices, i -> _candidate_equation_proxy(evidence[i]))
end

function _branch_confidence_tier(score::Float64)
    score >= 0.80 && return :high
    score >= 0.60 && return :medium
    score >= 0.40 && return :low
    return :fragile
end

function _branch_variable_registry(polish_ctx::PolishContext)
    registry = NamedTuple[]
    for (idx, sym) in enumerate(polish_ctx.unknown_syms)
        push!(registry, (
            index = idx,
            display_name = replace(string(sym), "(t)" => "(0)"),
            base_name = _symbol_base_name(sym),
            kind = :state_ic,
        ))
    end
    for (offset, sym) in enumerate(polish_ctx.param_syms)
        push!(registry, (
            index = polish_ctx.n_ic + offset,
            display_name = string(sym),
            base_name = _symbol_base_name(sym),
            kind = :parameter,
        ))
    end
    return registry
end

function _safe_abs_correlation(values_a::Vector{Float64}, values_b::Vector{Float64})
    length(values_a) <= 2 && return 0.0
    std(values_a) <= 1e-12 && return 0.0
    std(values_b) <= 1e-12 && return 0.0
    corr = try
        cor(values_a, values_b)
    catch
        NaN
    end
    return isfinite(corr) ? abs(Float64(corr)) : 0.0
end

function _branch_empirical_coupling(vectors::Vector{Vector{Float64}})
    isempty(vectors) && return zeros(0, 0)
    n = length(first(vectors))
    coupling = zeros(Float64, n, n)
    for i in 1:n
        coupling[i, i] = 1.0
    end
    length(vectors) <= 2 && return coupling

    for i in 1:n
        vals_i = Float64[vec[i] for vec in vectors]
        for j in (i + 1):n
            vals_j = Float64[vec[j] for vec in vectors]
            weight = _safe_abs_correlation(vals_i, vals_j)
            coupling[i, j] = weight
            coupling[j, i] = weight
        end
    end
    return coupling
end

function _branch_equation_sets(context, registry)
    base_to_indices = Dict{String, Vector{Int}}()
    for item in registry
        push!(get!(base_to_indices, item.base_name, Int[]), item.index)
    end

    eq_sets = Vector{Vector{Int}}()
    all_collections = Any[]
    push!(all_collections, hasproperty(context.si_template, :all_equations) ? context.si_template.all_equations : context.si_template.equations)
    if !isnothing(context.mpt)
        push!(all_collections, context.mpt.all_equations)
    end

    for collection in all_collections
        for eq in collection
            idxs = Int[]
            for var in Symbolics.get_variables(eq)
                base_name = _var_base_name(string(var))
                haskey(base_to_indices, base_name) || continue
                append!(idxs, base_to_indices[base_name])
            end
            sort!(idxs)
            unique!(idxs)
            isempty(idxs) || push!(eq_sets, idxs)
        end
    end
    return eq_sets
end

function _branch_equation_coupling(context, registry)
    n = length(registry)
    coupling = zeros(Float64, n, n)
    for i in 1:n
        coupling[i, i] = 1.0
    end
    eq_sets = _branch_equation_sets(context, registry)
    counts = zeros(Float64, n, n)
    for idxs in eq_sets
        for i in idxs
            for j in idxs
                i == j && continue
                counts[i, j] += 1.0
            end
        end
    end
    max_count = maximum(counts)
    max_count > 0 || return coupling
    for i in 1:n
        for j in (i + 1):n
            weight = counts[i, j] / max_count
            coupling[i, j] = weight
            coupling[j, i] = weight
        end
    end
    return coupling
end

function _branch_variable_blocks(
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
    context,
    branch_opts::BranchConsensusOptions,
)
    registry = _branch_variable_registry(polish_ctx)
    vectors = [_candidate_to_vector(candidate, polish_ctx) for candidate in raw_candidates]
    equation_coupling = _branch_equation_coupling(context, registry)
    empirical_coupling = _branch_empirical_coupling(vectors)
    combined = 0.6 .* equation_coupling .+ 0.4 .* empirical_coupling

    n = length(registry)
    adjacency = [Int[] for _ in 1:n]
    for i in 1:n
        for j in (i + 1):n
            combined[i, j] >= branch_opts.block_edge_threshold || continue
            push!(adjacency[i], j)
            push!(adjacency[j], i)
        end
    end

    visited = falses(n)
    blocks = NamedTuple[]
    block_index = 0
    for start in 1:n
        visited[start] && continue
        stack = [start]
        visited[start] = true
        indices = Int[]
        while !isempty(stack)
            idx = pop!(stack)
            push!(indices, idx)
            for nbr in adjacency[idx]
                visited[nbr] && continue
                visited[nbr] = true
                push!(stack, nbr)
            end
        end
        sort!(indices)
        block_index += 1
        push!(blocks, (
            block_index = block_index,
            indices = indices,
            variable_names = [registry[idx].display_name for idx in indices],
            block_bases = [registry[idx].base_name for idx in indices],
        ))
    end

    return registry, blocks, combined
end

function _relative_spread(values::Vector{Float64})
    length(values) <= 1 && return 0.0
    med = median(values)
    scale = max(abs(med), 1.0)
    return maximum(abs.(values .- med)) / scale
end

function _relative_margin(a::Float64, b::Float64)
    scale = max(abs(a) + abs(b), 1.0)
    return abs(a - b) / scale
end

function _branch_representative_vector(branch_members::Vector{Int}, raw_candidates, polish_ctx, evidence)
    rep_idx = _argmin_by(branch_members, i -> evidence[i].composite_score)
    return rep_idx, _candidate_to_vector(raw_candidates[rep_idx], polish_ctx)
end

function _branch_fit_sensitivity(
    base_vector::Vector{Float64},
    indices::Vector{Int},
    polish_ctx::PolishContext,
)
    base_loss = _seed_loss(polish_ctx, base_vector)
    isfinite(base_loss) || return 0.0

    perturbed = copy(base_vector)
    total_step = 0.0
    for idx in indices
        step = 1e-3 * max(abs(base_vector[idx]), 1.0)
        perturbed[idx] += step
        total_step += step
    end
    total_step > 0 || return 0.0

    perturbed_loss = _seed_loss(polish_ctx, perturbed)
    isfinite(perturbed_loss) || return 0.0
    return abs(perturbed_loss - base_loss) / total_step
end

function _branch_equation_sensitivity(
    candidate_index::Int,
    candidate::ParameterEstimationResult,
    base_vector::Vector{Float64},
    indices::Vector{Int},
    group_bases::Set{String},
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
    context,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
)
    coeff_cache = Dict{Any, Any}()
    system_cache = Dict{Any, Any}()
    base_penalty = _group_penalty_for_candidate(
        candidate_index,
        candidate,
        context,
        support_points,
        support_combos,
        group_bases,
        coeff_cache,
        system_cache,
    )
    isfinite(base_penalty) || return 0.0

    perturbed = copy(base_vector)
    total_step = 0.0
    for idx in indices
        step = 1e-3 * max(abs(base_vector[idx]), 1.0)
        perturbed[idx] += step
        total_step += step
    end
    total_step > 0 || return 0.0

    perturbed_candidate = _build_seed_candidate(
        perturbed,
        context.pep,
        polish_ctx,
        candidate.err,
        :branch_probe,
        [candidate_index],
        Int[],
        [candidate],
    )
    perturbed_penalty = _group_penalty_for_candidate(
        length(raw_candidates) + candidate_index,
        perturbed_candidate,
        context,
        support_points,
        support_combos,
        group_bases,
        coeff_cache,
        system_cache,
    )
    isfinite(perturbed_penalty) || return 0.0
    return abs(perturbed_penalty - base_penalty) / total_step
end

function _branch_variable_support(
    branch_index::Int,
    branch_members::Vector{Int},
    representative_index::Int,
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
    registry,
    all_branch_reps::Vector{Int},
    context,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
)
    member_vectors = [_candidate_to_vector(raw_candidates[idx], polish_ctx) for idx in branch_members]
    rep_vector = _candidate_to_vector(raw_candidates[representative_index], polish_ctx)

    raw_dispersion = Float64[]
    raw_margin = Float64[]
    raw_equation = Float64[]
    raw_fit = Float64[]
    base_names = [item.base_name for item in registry]

    for item in registry
        values = Float64[vec[item.index] for vec in member_vectors]
        push!(raw_dispersion, _relative_spread(values))

        rep_value = rep_vector[item.index]
        margins = Float64[]
        for other_idx in all_branch_reps
            other_idx == representative_index && continue
            other_vector = _candidate_to_vector(raw_candidates[other_idx], polish_ctx)
            push!(margins, _relative_margin(rep_value, other_vector[item.index]))
        end
        push!(raw_margin, isempty(margins) ? 0.0 : minimum(margins))

        group_base = Set([item.base_name])
        push!(raw_equation, _branch_equation_sensitivity(
            representative_index,
            raw_candidates[representative_index],
            rep_vector,
            [item.index],
            group_base,
            raw_candidates,
            polish_ctx,
            context,
            support_points,
            support_combos,
        ))
        push!(raw_fit, _branch_fit_sensitivity(rep_vector, [item.index], polish_ctx))
    end

    dispersion_score = 1 .- _rank_penalties(raw_dispersion)
    margin_score = 1 .- _rank_penalties(raw_margin; higher_is_better = true)
    equation_score = 1 .- _rank_penalties(raw_equation; higher_is_better = true)
    fit_score = 1 .- _rank_penalties(raw_fit; higher_is_better = true)

    rows = BranchVariableSupport[]
    for (offset, item) in enumerate(registry)
        score = mean((dispersion_score[offset], margin_score[offset], equation_score[offset], fit_score[offset]))
        push!(rows, BranchVariableSupport(
            branch_index,
            item.display_name,
            item.kind,
            rep_vector[item.index],
            raw_dispersion[offset],
            raw_margin[offset],
            raw_equation[offset],
            raw_fit[offset],
            score,
            _branch_confidence_tier(score),
        ))
    end
    return rows
end

function _branch_block_support(
    branch_index::Int,
    blocks,
    variable_support::Vector{BranchVariableSupport},
    representative_index::Int,
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
    context,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
    branch_opts::BranchConsensusOptions,
)
    rep_vector = _candidate_to_vector(raw_candidates[representative_index], polish_ctx)
    support_by_name = Dict(row.variable_name => row for row in variable_support)
    rows = BranchBlockSupport[]
    for block in blocks
        block_rows = BranchVariableSupport[support_by_name[name] for name in block.variable_names if haskey(support_by_name, name)]
        isempty(block_rows) && continue

        block_dispersion = mean(row.within_branch_dispersion for row in block_rows)
        block_margin = minimum(row.cross_branch_margin for row in block_rows)
        block_equation = _branch_equation_sensitivity(
            representative_index,
            raw_candidates[representative_index],
            rep_vector,
            block.indices,
            Set(block.block_bases),
            raw_candidates,
            polish_ctx,
            context,
            support_points,
            support_combos,
        )
        block_fit = _branch_fit_sensitivity(rep_vector, block.indices, polish_ctx)

        scalar_support = mean(row.scalar_support_score for row in block_rows)
        score = mean((
            scalar_support,
            1.0 - first(_rank_penalties([block_dispersion, 0.0])),
            clamp(block_margin / max(block_margin + 0.25, 1e-12), 0.0, 1.0),
            1.0 - first(_rank_penalties([block_equation, 0.0]; higher_is_better = true)),
            1.0 - first(_rank_penalties([block_fit, 0.0]; higher_is_better = true)),
        ))
        push!(rows, BranchBlockSupport(
            branch_index,
            block.block_index,
            copy(block.variable_names),
            copy(block.block_bases),
            block_dispersion,
            block_margin,
            block_equation,
            block_fit,
            score,
            score < branch_opts.low_confidence_threshold,
            Int[],
        ))
    end
    return rows
end

function _branch_local_seed_specs(
    branch::NamedTuple,
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
)
    seeds = NamedTuple[]
    representative_vector = _candidate_to_vector(raw_candidates[branch.representative_candidate_index], polish_ctx)
    push!(seeds, (
        branch_index = branch.branch_index,
        seed_kind = :branch_representative_seed,
        seed_vector = _clamp_seed_vector(representative_vector, polish_ctx),
        source_candidate_indices = [branch.representative_candidate_index],
    ))
    length(branch.member_indices) <= 1 && return seeds

    vectors = [_candidate_to_vector(raw_candidates[idx], polish_ctx) for idx in branch.member_indices]
    push!(seeds, (
        branch_index = branch.branch_index,
        seed_kind = :branch_component_median,
        seed_vector = _clamp_seed_vector(_componentwise_median(vectors), polish_ctx),
        source_candidate_indices = copy(branch.member_indices),
    ))
    weights = _inverse_fit_weights(raw_candidates, branch.member_indices)
    push!(seeds, (
        branch_index = branch.branch_index,
        seed_kind = :branch_weighted_center,
        seed_vector = _clamp_seed_vector(_weighted_average(vectors, weights), polish_ctx),
        source_candidate_indices = copy(branch.member_indices),
    ))
    return seeds
end

function _branch_swap_seed_specs(
    ranked_branches,
    blocks,
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
    branch_opts::BranchConsensusOptions,
)
    branch_opts.enable_branch_local_synthesis || return NamedTuple[]
    limit = min(branch_opts.top_branch_neighbor_count, length(ranked_branches))
    seeds = NamedTuple[]

    for source_rank in 1:limit
        source_branch = ranked_branches[source_rank]
        isnothing(source_branch.representative_candidate_index) && continue
        source_vector = _candidate_to_vector(raw_candidates[source_branch.representative_candidate_index], polish_ctx)

        for block in source_branch.block_support
            block.low_confidence || continue
            donor_rankings = sort(
                [branch for branch in ranked_branches[1:limit] if branch.branch_index != source_branch.branch_index];
                by = branch -> begin
                    donor_block = findfirst(row -> row.block_index == block.block_index, branch.block_support)
                    isnothing(donor_block) ? -Inf : branch.block_support[donor_block].block_support_score
                end,
                rev = true,
            )
            isempty(donor_rankings) && continue
            donor_branch = first(donor_rankings)
            donor_block_idx = findfirst(row -> row.block_index == block.block_index, donor_branch.block_support)
            isnothing(donor_block_idx) && continue
            donor_block = donor_branch.block_support[donor_block_idx]
            donor_block.block_support_score > block.block_support_score + 1e-6 || continue
            isnothing(donor_branch.representative_candidate_index) && continue
            donor_vector = _candidate_to_vector(raw_candidates[donor_branch.representative_candidate_index], polish_ctx)
            block_def_idx = findfirst(item -> item.block_index == block.block_index, blocks)
            isnothing(block_def_idx) && continue
            block_def = blocks[block_def_idx]

            swapped = copy(source_vector)
            swapped[block_def.indices] .= donor_vector[block_def.indices]
            push!(seeds, (
                branch_index = source_branch.branch_index,
                seed_kind = :branch_block_swap,
                seed_vector = _clamp_seed_vector(swapped, polish_ctx),
                source_candidate_indices = [source_branch.representative_candidate_index, donor_branch.representative_candidate_index],
            ))
        end
    end

    deduped = NamedTuple[]
    for seed in seeds
        if any(existing -> _seed_vector_distance(seed.seed_vector, existing.seed_vector) <= 1e-6, deduped)
            continue
        end
        push!(deduped, seed)
    end
    return deduped
end

function _branch_ranked_data(
    raw_candidates::Vector{ParameterEstimationResult},
    evidence::Vector{CandidateEvidence},
    origin_keys,
    dist_matrix::AbstractMatrix{<:Real},
    polish_ctx::PolishContext,
    context,
    branch_opts::BranchConsensusOptions,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
)
    threshold, target_count = _select_branch_threshold(raw_candidates, origin_keys, dist_matrix, branch_opts)
    components = _branch_components_from_threshold(origin_keys, dist_matrix, threshold)

    provisional = NamedTuple[]
    for members in components
        rep_idx, quality_score, trust_score = _branch_quality_score(members, evidence)
        best_fit_idx = _argmin_by(members, i -> _result_err_key(raw_candidates[i]))
        best_equation_idx = _branch_equation_best_member(members, evidence)
        compactness = _branch_member_compactness(members, dist_matrix)
        distinct_origins = length(Set(origin_keys[idx] for idx in members))
        distinct_shooting_support = _branch_distinct_shooting_support(members, raw_candidates)
        distinct_combo_support = _branch_distinct_combo_support(members, raw_candidates)
        distinct_source_types = _branch_distinct_source_types(members, raw_candidates)
        distinct_interpolators = _branch_distinct_interpolators(members, raw_candidates)

        push!(provisional, (
            member_indices = members,
            representative_candidate_index = rep_idx,
            best_fit_candidate_index = best_fit_idx,
            best_equation_candidate_index = best_equation_idx,
            quality_score = quality_score,
            trust_score = trust_score,
            compactness = compactness,
            distinct_origin_count = distinct_origins,
            distinct_shooting_support = distinct_shooting_support,
            distinct_combo_support = distinct_combo_support,
            distinct_source_types = distinct_source_types,
            distinct_interpolators = distinct_interpolators,
        ))
    end

    max_origin_count = max(maximum(item.distinct_origin_count for item in provisional), 1)
    max_shoot_support = max(maximum(length(item.distinct_shooting_support) for item in provisional), 1)
    max_combo_support = max(maximum(length(item.distinct_combo_support) for item in provisional), 1)
    max_interp_support = max(maximum(length(item.distinct_interpolators) for item in provisional), 1)

    scored = NamedTuple[]
    for item in provisional
        persistence_score = mean((
            item.distinct_origin_count / max_origin_count,
            length(item.distinct_shooting_support) / max_shoot_support,
            length(item.distinct_combo_support) / max_combo_support,
            length(item.distinct_source_types) / 2.0,
            length(item.distinct_interpolators) / max_interp_support,
        ))
        compactness_score = 1.0 / (1.0 + item.compactness / max(threshold, 1e-12))
        branch_score = (
            branch_opts.branch_score_weights.quality * item.quality_score +
            branch_opts.branch_score_weights.persistence * persistence_score +
            branch_opts.branch_score_weights.compactness * compactness_score +
            branch_opts.branch_score_weights.trust * item.trust_score
        )
        push!(scored, merge(item, (
            persistence_score = persistence_score,
            compactness_score = compactness_score,
            branch_score = branch_score,
        )))
    end

    sort!(scored; by = item -> (-item.branch_score, evidence[item.representative_candidate_index].composite_score, _result_err_key(raw_candidates[item.representative_candidate_index])))
    registry, blocks, combined_coupling = _branch_variable_blocks(raw_candidates, polish_ctx, context, branch_opts)
    representative_indices = [item.representative_candidate_index for item in scored]

    enriched = NamedTuple[]
    for (branch_rank, item) in enumerate(scored)
        variable_support = _branch_variable_support(
            branch_rank,
            item.member_indices,
            item.representative_candidate_index,
            raw_candidates,
            polish_ctx,
            registry,
            representative_indices,
            context,
            support_points,
            support_combos,
        )
        block_support = _branch_block_support(
            branch_rank,
            blocks,
            variable_support,
            item.representative_candidate_index,
            raw_candidates,
            polish_ctx,
            context,
            support_points,
            support_combos,
            branch_opts,
        )
        push!(enriched, merge(item, (
            branch_index = branch_rank,
            representative_candidate = raw_candidates[item.representative_candidate_index],
            variable_support = variable_support,
            block_support = block_support,
            confidence_tier = _branch_confidence_tier(item.branch_score),
        )))
    end

    with_donors = NamedTuple[]
    for item in enriched
        donor_rows = BranchBlockSupport[]
        for row in item.block_support
            donors = Int[]
            for other in enriched
                other.branch_index == item.branch_index && continue
                other_row_idx = findfirst(candidate_row -> candidate_row.block_index == row.block_index, other.block_support)
                isnothing(other_row_idx) && continue
                other.block_support[other_row_idx].block_support_score > row.block_support_score + 1e-6 || continue
                push!(donors, other.branch_index)
            end
            push!(donor_rows, BranchBlockSupport(
                row.branch_index,
                row.block_index,
                row.variable_names,
                row.block_bases,
                row.within_branch_dispersion,
                row.cross_branch_margin,
                row.equation_sensitivity,
                row.fit_sensitivity,
                row.block_support_score,
                row.low_confidence,
                sort!(unique(donors)),
            ))
        end
        push!(with_donors, merge(item, (block_support = donor_rows,)))
    end

    return with_donors, registry, blocks, combined_coupling, threshold, target_count
end

function _branch_seed_candidate_score(
    candidate::ParameterEstimationResult,
    context,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
    branch_opts::BranchConsensusOptions,
)
    coeff_cache = Dict{Any, Any}()
    system_cache = Dict{Any, Any}()
    order_cache = Dict{Any, Any}()
    metrics = try
        _score_candidate_raw(1, candidate, context, support_points, support_combos, coeff_cache, system_cache, order_cache)
    catch
        (
            base_fit_error = _result_err_key(candidate),
            equation_penalty = Inf,
            support_strength = 1.0,
            trust_strength = 0.0,
        )
    end

    fit_component = isfinite(metrics.base_fit_error) ? log1p(max(metrics.base_fit_error, 0.0)) : Inf
    equation_component = isfinite(metrics.equation_penalty) ? log1p(max(metrics.equation_penalty, 0.0)) : Inf
    support_component = 1.0 / max(Float64(metrics.support_strength), 1.0)
    trust_component = 1.0 / (1.0 + max(Float64(metrics.trust_strength), 0.0))
    score = (
        branch_opts.branch_score_weights.quality * fit_component +
        branch_opts.branch_score_weights.persistence * equation_component +
        branch_opts.branch_score_weights.compactness * support_component +
        branch_opts.branch_score_weights.trust * trust_component
    )
    return score, metrics.base_fit_error
end

function _branch_refined_candidate(
    branch,
    ranked_branches,
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
    context,
    blocks,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
    branch_opts::BranchConsensusOptions,
)
    local_seeds = _branch_local_seed_specs(branch, raw_candidates, polish_ctx)
    swap_seeds = _branch_swap_seed_specs(ranked_branches, blocks, raw_candidates, polish_ctx, branch_opts)
    seed_specs = [seed for seed in vcat(local_seeds, swap_seeds) if seed.branch_index == branch.branch_index]
    isempty(seed_specs) && return nothing

    base_candidate = branch.representative_candidate
    base_score, base_fit = _branch_seed_candidate_score(base_candidate, context, support_points, support_combos, branch_opts)
    best_candidate = nothing
    best_score = base_score

    for seed in seed_specs[1:min(length(seed_specs), branch_opts.max_refined_seeds)]
        fit_loss = _seed_loss(polish_ctx, seed.seed_vector)
        isfinite(fit_loss) || continue

        seed_candidate = _build_seed_candidate(
            seed.seed_vector,
            context.pep,
            polish_ctx,
            fit_loss,
            seed.seed_kind,
            seed.source_candidate_indices,
            [branch.branch_index],
            raw_candidates[seed.source_candidate_indices],
        )

        refined = try
            _polish_research_seed(context.pep, seed_candidate, polish_ctx, context.opts)
        catch
            nothing
        end
        isnothing(refined) && continue

        candidate_score, candidate_fit = _branch_seed_candidate_score(refined, context, support_points, support_combos, branch_opts)
        candidate_score + 1e-6 < best_score || continue
        candidate_fit <= base_fit * branch_opts.override_fit_factor || continue
        best_candidate = refined
        best_score = candidate_score
    end

    return best_candidate
end

function _branch_selected_candidate(branch)
    return isnothing(branch.refined_candidate) ? branch.representative_candidate : branch.refined_candidate
end

function _branch_candidate_index_map(branches)
    mapping = Dict{Int, Int}()
    for branch in branches
        for idx in branch.member_indices
            mapping[idx] = branch.branch_index
        end
    end
    return mapping
end

function _adaptive_branch_indices(branches, branch_opts::BranchConsensusOptions)
    isempty(branches) && return Int[]
    limit = min(branch_opts.max_returned_branches, length(branches))
    scores = Float64[branch.branch_score for branch in branches[1:limit]]
    total = sum(scores)
    selected = Int[1]
    cumulative = scores[1]
    for idx in 2:limit
        scores[idx] + 1e-12 >= scores[1] * branch_opts.adaptive_k_score_ratio || break
        if total > 0 && cumulative / total >= branch_opts.adaptive_k_support_fraction
            break
        end
        push!(selected, idx)
        cumulative += scores[idx]
    end
    return selected
end

function _select_best_branch_index(
    branches,
    raw_candidates::Vector{ParameterEstimationResult},
    branch_opts::BranchConsensusOptions,
)
    isempty(branches) && return nothing, false
    best_branch_index = firstindex(branches)
    guard_applied = false

    if length(raw_candidates) <= branch_opts.small_pool_candidate_guard || length(branches) <= branch_opts.small_pool_branch_guard
        raw_best_fit_idx = _argmin_by(eachindex(raw_candidates), i -> _result_err_key(raw_candidates[i]))
        candidate_to_branch = _branch_candidate_index_map(branches)
        raw_best_branch_index = get(candidate_to_branch, raw_best_fit_idx, best_branch_index)
        if raw_best_branch_index != best_branch_index
            top_branch = branches[best_branch_index]
            raw_branch = branches[raw_best_branch_index]
            top_candidate = _branch_selected_candidate(top_branch)
            raw_candidate = raw_candidates[raw_best_fit_idx]
            top_branch.branch_score >= raw_branch.branch_score * (1.0 + branch_opts.override_score_margin) &&
            _result_err_key(top_candidate) <= _result_err_key(raw_candidate) * branch_opts.override_fit_factor || begin
                best_branch_index = raw_best_branch_index
                guard_applied = true
            end
        end
    end

    return best_branch_index, guard_applied
end

function _finalize_branch_hypotheses(
    branch_data,
    refined_candidates::Dict{Int, Union{Nothing, ParameterEstimationResult}},
)
    hypotheses = BranchHypothesis[]
    for branch in branch_data
        push!(hypotheses, BranchHypothesis(
            branch.branch_index,
            copy(branch.member_indices),
            branch.representative_candidate_index,
            branch.representative_candidate,
            branch.best_fit_candidate_index,
            branch.best_equation_candidate_index,
            branch.branch_score,
            branch.persistence_score,
            branch.quality_score,
            branch.compactness_score,
            branch.trust_score,
            branch.distinct_origin_count,
            copy(branch.distinct_shooting_support),
            copy(branch.distinct_combo_support),
            copy(branch.distinct_source_types),
            copy(branch.distinct_interpolators),
            copy(branch.variable_support),
            copy(branch.block_support),
            branch.confidence_tier,
            get(refined_candidates, branch.branch_index, nothing),
        ))
    end
    return hypotheses
end

function _branch_scoring_summary(
    raw_candidates::Vector{ParameterEstimationResult},
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
    threshold::Float64,
    target_count::Int,
    best_branch_index,
    adaptive_indices::Vector{Int},
    guard_applied::Bool,
    branch_opts::BranchConsensusOptions,
    branches,
)
    origin_counts = Dict{String, Int}()
    for candidate in raw_candidates
        label = _branch_origin_label(_branch_origin_key(candidate))
        origin_counts[label] = get(origin_counts, label, 0) + 1
    end

    return Dict{Symbol, Any}(
        :version_label => branch_opts.version_label,
        :support_point_count => length(support_points),
        :support_combo_count => length(support_combos),
        :selected_branch_threshold => threshold,
        :expected_branch_count_prior => target_count,
        :n_raw_candidates => length(raw_candidates),
        :n_branches => length(branches),
        :adaptive_k => length(adaptive_indices),
        :top_branch_indices => copy(adaptive_indices),
        :best_branch_index => best_branch_index,
        :guard_applied => guard_applied,
        :enable_branch_local_synthesis => branch_opts.enable_branch_local_synthesis,
        :origin_solution_counts => origin_counts,
    )
end

function _empty_branch_consensus_report(model_name::String, branch_opts::BranchConsensusOptions; note::String = "no raw candidates were produced")
    return BranchConsensusReport(
        model_name,
        branch_opts.version_label,
        ParameterEstimationResult[],
        CandidateEvidence[],
        BranchHypothesis[],
        nothing,
        nothing,
        BranchHypothesis[],
        0,
        Int[],
        Vector{Vector{Int}}(),
        Dict{Symbol, Any}(
            :version_label => branch_opts.version_label,
            :note => note,
            :best_branch_index => nothing,
            :adaptive_k => 0,
        ),
    )
end

function _assemble_branch_consensus_report(
    pep_with_data::ParameterEstimationProblem,
    run_opts::EstimationOptions,
    raw_candidates::Vector{ParameterEstimationResult},
    branch_opts::BranchConsensusOptions;
    context = nothing,
)
    isempty(raw_candidates) && return _empty_branch_consensus_report(pep_with_data.name, branch_opts)

    context = isnothing(context) ? _build_consensus_context(pep_with_data, run_opts) : context
    polish_ctx = _build_polish_context(pep_with_data; opts = run_opts)
    consensus_opts = _branch_base_consensus_opts(branch_opts)
    support_points = _select_consensus_support_points(
        pep_with_data,
        raw_candidates,
        context.point_indices,
        context.support_labels,
        context.interpolant_cache,
        consensus_opts,
        context.t_vector,
    )
    support_combos = _select_consensus_support_combos(raw_candidates, support_points, run_opts.multipoint_n_points, consensus_opts)
    evidence = _build_candidate_evidence(raw_candidates, context, support_points, support_combos, consensus_opts)

    origin_keys = [_branch_origin_key(candidate) for candidate in raw_candidates]
    dist_matrix = _branch_distance_matrix(raw_candidates)
    branch_data, _, blocks, _, threshold, target_count = _branch_ranked_data(
        raw_candidates,
        evidence,
        origin_keys,
        dist_matrix,
        polish_ctx,
        context,
        branch_opts,
        support_points,
        support_combos,
    )

    refined_candidates = Dict{Int, Union{Nothing, ParameterEstimationResult}}()
    for branch in branch_data[1:min(length(branch_data), branch_opts.top_branch_neighbor_count)]
        refined_candidates[branch.branch_index] = _branch_refined_candidate(
            branch,
            branch_data,
            raw_candidates,
            polish_ctx,
            context,
            blocks,
            support_points,
            support_combos,
            branch_opts,
        )
    end

    hypotheses = _finalize_branch_hypotheses(branch_data, refined_candidates)
    adaptive_indices = _adaptive_branch_indices(hypotheses, branch_opts)
    best_branch_index, guard_applied = _select_best_branch_index(hypotheses, raw_candidates, branch_opts)
    if !isnothing(best_branch_index) && best_branch_index ∉ adaptive_indices
        push!(adaptive_indices, best_branch_index)
        sort!(adaptive_indices)
    end
    best_result = isnothing(best_branch_index) ? nothing : _branch_selected_candidate(hypotheses[best_branch_index])
    top_branches = isempty(adaptive_indices) ? BranchHypothesis[] : hypotheses[adaptive_indices]

    return BranchConsensusReport(
        pep_with_data.name,
        branch_opts.version_label,
        raw_candidates,
        evidence,
        hypotheses,
        best_branch_index,
        best_result,
        top_branches,
        length(adaptive_indices),
        support_points,
        support_combos,
        _branch_scoring_summary(
            raw_candidates,
            support_points,
            support_combos,
            threshold,
            target_count,
            best_branch_index,
            adaptive_indices,
            guard_applied,
            branch_opts,
            hypotheses,
        ),
    )
end

function research_branch_consensus_v1(
    pep::ParameterEstimationProblem;
    est_opts::EstimationOptions = EstimationOptions(),
    branch_opts::BranchConsensusOptions = BranchConsensusOptions(),
)
    pep_with_data, run_opts, raw_candidates = _prepare_consensus_inputs(pep, est_opts)
    context = isempty(raw_candidates) ? nothing : _build_consensus_context(pep_with_data, run_opts)
    return _assemble_branch_consensus_report(
        pep_with_data,
        run_opts,
        raw_candidates,
        branch_opts;
        context = context,
    )
end
