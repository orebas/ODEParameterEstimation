function _block_base_consensus_opts(block_opts::BlockConsensusOptions)
    return ConsensusOptions(
        strategy = :family_consensus,
        support_point_count = block_opts.support_point_count,
        support_combo_count = block_opts.support_combo_count,
        refine_top_families = 1,
        do_equation_refit = false,
    )
end

function _block_confidence_tier(score::Float64)
    score >= 0.80 && return :high
    score >= 0.60 && return :medium
    score >= 0.40 && return :low
    return :fragile
end

function _block_candidate_weights(evidence::Vector{CandidateEvidence})
    isempty(evidence) && return Float64[]
    scores = Float64[
        isfinite(item.composite_score) ? item.composite_score : 1.0
        for item in evidence
    ]
    finite_scores = filter(isfinite, scores)
    isempty(finite_scores) && return fill(1.0 / length(scores), length(scores))
    min_score = minimum(finite_scores)
    shifted = [isfinite(score) ? score - min_score : 1.0 for score in scores]
    weights = exp.(-3.0 .* shifted)
    total = sum(weights)
    total > 0 || return fill(1.0 / length(scores), length(scores))
    return weights ./ total
end

function _weighted_mean(values::Vector{Float64}, weights::Vector{Float64})
    total_weight = sum(weights)
    total_weight > 0 || return NaN
    return sum(values .* weights) / total_weight
end

function _weighted_std(values::Vector{Float64}, weights::Vector{Float64})
    total_weight = sum(weights)
    total_weight > 0 || return NaN
    mean_value = _weighted_mean(values, weights)
    return sqrt(max(sum(weights .* ((values .- mean_value) .^ 2)) / total_weight, 0.0))
end

function _weighted_abs_correlation(values_a::Vector{Float64}, values_b::Vector{Float64}, weights::Vector{Float64})
    length(values_a) <= 1 && return 0.0
    total_weight = sum(weights)
    total_weight > 0 || return 0.0
    mean_a = _weighted_mean(values_a, weights)
    mean_b = _weighted_mean(values_b, weights)
    std_a = _weighted_std(values_a, weights)
    std_b = _weighted_std(values_b, weights)
    std_a > 1e-12 || return 0.0
    std_b > 1e-12 || return 0.0
    cov = sum(weights .* ((values_a .- mean_a) .* (values_b .- mean_b))) / total_weight
    corr = cov / max(std_a * std_b, 1e-12)
    return isfinite(corr) ? abs(clamp(corr, -1.0, 1.0)) : 0.0
end

function _block_correlation_matrix(vectors::Vector{Vector{Float64}}, weights::Vector{Float64})
    isempty(vectors) && return zeros(Float64, 0, 0)
    n = length(first(vectors))
    matrix = Matrix{Float64}(I, n, n)
    for i in 1:n
        values_i = Float64[vec[i] for vec in vectors]
        for j in (i + 1):n
            values_j = Float64[vec[j] for vec in vectors]
            corr = _weighted_abs_correlation(values_i, values_j, weights)
            matrix[i, j] = corr
            matrix[j, i] = corr
        end
    end
    return matrix
end

function _block_components_from_threshold(correlation_matrix::AbstractMatrix{<:Real}, threshold::Float64)
    n = size(correlation_matrix, 1)
    adjacency = [Int[] for _ in 1:n]
    for i in 1:n
        for j in (i + 1):n
            Float64(correlation_matrix[i, j]) >= threshold || continue
            push!(adjacency[i], j)
            push!(adjacency[j], i)
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

function _block_normalize_columns(matrix::Matrix{Float64})
    isempty(matrix) && return matrix
    normalized = copy(matrix)
    for col in axes(normalized, 2)
        col_values = view(normalized, :, col)
        min_val = minimum(col_values)
        max_val = maximum(col_values)
        scale = max(max_val - min_val, 1e-12)
        col_values .= (col_values .- min_val) ./ scale
    end
    return normalized
end

function _block_pairwise_distances(matrix::Matrix{Float64})
    n = size(matrix, 1)
    distances = zeros(Float64, n, n)
    for i in 1:n
        for j in (i + 1):n
            dist = norm(view(matrix, i, :) .- view(matrix, j, :))
            distances[i, j] = dist
            distances[j, i] = dist
        end
    end
    return distances
end

function _weighted_kmedoid_init(distances::AbstractMatrix{<:Real}, weights::Vector{Float64}, k::Int)
    n = length(weights)
    k = max(1, min(k, n))
    medoids = Int[argmax(weights)]
    while length(medoids) < k
        best_idx = nothing
        best_score = -Inf
        for idx in 1:n
            idx in medoids && continue
            min_distance = minimum(Float64(distances[idx, medoid]) for medoid in medoids)
            score = weights[idx] * min_distance
            if score > best_score
                best_score = score
                best_idx = idx
            end
        end
        isnothing(best_idx) && break
        push!(medoids, best_idx)
    end
    return medoids
end

function _weighted_assign_medoids(distances::AbstractMatrix{<:Real}, medoids::Vector{Int})
    assignments = fill(1, size(distances, 1))
    for idx in eachindex(assignments)
        best_cluster = 1
        best_distance = Float64(distances[idx, medoids[1]])
        for cluster_idx in 2:length(medoids)
            distance = Float64(distances[idx, medoids[cluster_idx]])
            if distance < best_distance - 1e-12
                best_distance = distance
                best_cluster = cluster_idx
            end
        end
        assignments[idx] = best_cluster
    end
    return assignments
end

function _weighted_recompute_medoids(distances::AbstractMatrix{<:Real}, weights::Vector{Float64}, assignments::Vector{Int}, k::Int)
    medoids = Int[]
    for cluster_idx in 1:k
        members = findall(==(cluster_idx), assignments)
        isempty(members) && continue
        best_member = members[1]
        best_cost = Inf
        for candidate in members
            cost = sum(weights[member] * Float64(distances[candidate, member]) for member in members)
            if cost < best_cost
                best_cost = cost
                best_member = candidate
            end
        end
        push!(medoids, best_member)
    end

    while length(medoids) < k
        remainder = setdiff(collect(eachindex(weights)), medoids)
        isempty(remainder) && break
        push!(medoids, remainder[argmax(weights[remainder])])
    end
    return medoids
end

function _weighted_silhouette(distances::AbstractMatrix{<:Real}, assignments::Vector{Int}, weights::Vector{Float64})
    n = length(assignments)
    clusters = sort!(unique(assignments))
    length(clusters) <= 1 && return 0.0

    total = 0.0
    total_weight = 0.0
    for idx in 1:n
        cluster = assignments[idx]
        same_members = [j for j in 1:n if assignments[j] == cluster && j != idx]
        a = if isempty(same_members)
            0.0
        else
            member_weights = weights[same_members]
            sum(member_weights .* Float64[distances[idx, j] for j in same_members]) / max(sum(member_weights), 1e-12)
        end

        b = Inf
        for other_cluster in clusters
            other_cluster == cluster && continue
            other_members = [j for j in 1:n if assignments[j] == other_cluster]
            isempty(other_members) && continue
            member_weights = weights[other_members]
            candidate = sum(member_weights .* Float64[distances[idx, j] for j in other_members]) / max(sum(member_weights), 1e-12)
            b = min(b, candidate)
        end

        if !isfinite(b)
            continue
        end
        score = max(a, b) <= 1e-12 ? 0.0 : (b - a) / max(a, b)
        total += weights[idx] * score
        total_weight += weights[idx]
    end
    return total_weight > 0 ? total / total_weight : 0.0
end

function _weighted_kmedoids(distances::AbstractMatrix{<:Real}, weights::Vector{Float64}, k::Int; maxiters::Int = 25)
    medoids = _weighted_kmedoid_init(distances, weights, k)
    isempty(medoids) && return (Int[], Int[], 0.0)
    assignments = _weighted_assign_medoids(distances, medoids)

    for _ in 1:maxiters
        new_medoids = _weighted_recompute_medoids(distances, weights, assignments, length(medoids))
        new_assignments = _weighted_assign_medoids(distances, new_medoids)
        if new_medoids == medoids && new_assignments == assignments
            break
        end
        medoids = new_medoids
        assignments = new_assignments
    end

    silhouette = _weighted_silhouette(distances, assignments, weights)
    return medoids, assignments, silhouette
end

function _cluster_block_candidates(
    block_index::Int,
    block_indices::Vector{Int},
    block_names::Vector{String},
    vectors::Vector{Vector{Float64}},
    weights::Vector{Float64},
    block_opts::BlockConsensusOptions,
)
    isempty(vectors) && return BlockCluster[]
    matrix = reduce(vcat, permutedims.(getindex.(vectors, Ref(block_indices))))
    normalized = _block_normalize_columns(matrix)
    distances = _block_pairwise_distances(normalized)

    n = size(matrix, 1)
    max_k = min(block_opts.max_clusters_per_block, n)
    best = (
        medoids = Int[1],
        assignments = fill(1, n),
        silhouette = 0.0,
        objective = -Inf,
    )

    for k in 1:max_k
        medoids, assignments, silhouette = _weighted_kmedoids(distances, weights, k)
        objective = silhouette - 0.05 * (k - 1)
        if objective > best.objective + 1e-12
            best = (
                medoids = medoids,
                assignments = assignments,
                silhouette = silhouette,
                objective = objective,
            )
        end
    end

    rows = BlockCluster[]
    for cluster_idx in 1:length(best.medoids)
        members = findall(==(cluster_idx), best.assignments)
        isempty(members) && continue
        medoid_local_index = best.medoids[cluster_idx]
        member_weights = weights[members]
        total_weight = sum(member_weights)
        spread = if isempty(members)
            0.0
        else
            sum(member_weights .* Float64[distances[medoid_local_index, member] for member in members]) / max(total_weight, 1e-12)
        end
        cluster_silhouette = _weighted_silhouette(
            distances,
            [assignment == cluster_idx ? 1 : 2 for assignment in best.assignments],
            weights,
        )
        push!(rows, BlockCluster(
            block_index,
            cluster_idx,
            copy(block_names),
            Int[members...],
            medoid_local_index,
            Float64[matrix[medoid_local_index, col] for col in 1:size(matrix, 2)],
            total_weight,
            spread,
            cluster_silhouette,
        ))
    end

    sort!(rows; by = row -> (-row.total_weight, row.spread, row.medoid_candidate_index))
    for (idx, row) in enumerate(rows)
        rows[idx] = BlockCluster(
            row.block_index,
            idx,
            row.variable_names,
            row.member_indices,
            row.medoid_candidate_index,
            row.medoid_values,
            row.total_weight,
            row.spread,
            row.silhouette,
        )
    end
    return rows
end

function _build_block_decomposition(
    raw_candidates::Vector{ParameterEstimationResult},
    evidence::Vector{CandidateEvidence},
    polish_ctx::PolishContext,
    block_opts::BlockConsensusOptions,
)
    registry = _branch_variable_registry(polish_ctx)
    vectors = [_candidate_to_vector(candidate, polish_ctx) for candidate in raw_candidates]
    weights = _block_candidate_weights(evidence)
    correlation_matrix = _block_correlation_matrix(vectors, weights)
    blocks = _block_components_from_threshold(correlation_matrix, block_opts.correlation_threshold)
    block_names = [[registry[idx].display_name for idx in block] for block in blocks]

    clusters = Vector{Vector{BlockCluster}}()
    for (block_index, block) in enumerate(blocks)
        push!(clusters, _cluster_block_candidates(
            block_index,
            block,
            block_names[block_index],
            vectors,
            weights,
            block_opts,
        ))
    end

    return BlockDecomposition(
        [item.display_name for item in registry],
        [item.kind for item in registry],
        weights,
        correlation_matrix,
        blocks,
        block_names,
        clusters,
    )
end

function _block_combo_indices(cluster_sets::Vector{Vector{Int}})
    isempty(cluster_sets) && return Vector{Vector{Int}}()
    combos = Vector{Vector{Int}}()
    current = Int[]
    function recurse(idx::Int)
        if idx > length(cluster_sets)
            push!(combos, copy(current))
            return
        end
        for entry in cluster_sets[idx]
            push!(current, entry)
            recurse(idx + 1)
            pop!(current)
        end
    end
    recurse(1)
    return combos
end

function _build_block_seed_candidate(
    seed_vector::AbstractVector{<:Real},
    pep::ParameterEstimationProblem,
    ctx::PolishContext,
    fit_error::Float64,
    source_candidate_indices::Vector{Int},
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
    result.provenance = ResultProvenance(
        primary_method = :direct_opt,
        source_candidate_index = length(source_candidate_indices) == 1 ? only(source_candidate_indices) : nothing,
        pre_polish_error = fit_error,
        polish_applied = false,
        source_type = :assembled,
        notes = Symbol[:block_assembled],
    )
    sync_result_contract!(result)
    return result
end

function _minmax_normalize(values::Vector{Float64})
    isempty(values) && return Float64[]
    finite_values = filter(isfinite, values)
    isempty(finite_values) && return fill(1.0, length(values))
    min_val = minimum(finite_values)
    max_val = maximum(finite_values)
    scale = max(max_val - min_val, 1e-12)
    return Float64[
        isfinite(value) ? (value - min_val) / scale : 1.0
        for value in values
    ]
end

function _block_hypothesis_metric(
    hypothesis_index::Int,
    candidate::ParameterEstimationResult,
    context,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
    coeff_cache::Dict,
    system_cache::Dict,
    order_cache::Dict,
)
    raw_metric = _score_candidate_raw(
        hypothesis_index,
        candidate,
        context,
        support_points,
        support_combos,
        coeff_cache,
        system_cache,
        order_cache,
    )
    return (
        fit_error = raw_metric.base_fit_error,
        equation_penalty = raw_metric.equation_penalty,
    )
end

function _block_direct_score(fit_error::Float64, equation_penalty::Float64, block_opts::BlockConsensusOptions)
    fit_component = isfinite(fit_error) ? log1p(max(fit_error, 0.0)) : Inf
    equation_component = isfinite(equation_penalty) ? log1p(max(equation_penalty, 0.0)) : Inf
    return block_opts.score_weights.fit * fit_component + block_opts.score_weights.equation * equation_component
end

function _assemble_block_hypotheses(
    pep::ParameterEstimationProblem,
    raw_candidates::Vector{ParameterEstimationResult},
    block_decomposition::BlockDecomposition,
    polish_ctx::PolishContext,
    context,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
    block_opts::BlockConsensusOptions,
    coeff_cache::Dict,
    system_cache::Dict,
    order_cache::Dict,
)
    isempty(block_decomposition.blocks) && return AssembledHypothesis[]

    cluster_sets = [
        collect(1:min(block_opts.max_recombined_clusters_per_block, length(clusters)))
        for clusters in block_decomposition.block_clusters
    ]
    combos = _block_combo_indices(cluster_sets)
    sort!(combos; by = combo -> begin
        -sum(block_decomposition.block_clusters[block_idx][cluster_idx].total_weight for (block_idx, cluster_idx) in enumerate(combo))
    end)
    combos = combos[1:min(block_opts.max_hypotheses, length(combos))]

    rows = NamedTuple[]
    seen_vectors = Vector{Vector{Float64}}()

    for (hypothesis_index, combo) in enumerate(combos)
        seed_vector = zeros(Float64, length(block_decomposition.variable_names))
        source_candidate_indices = Int[]
        block_confidence = Float64[]

        for (block_idx, cluster_idx) in enumerate(combo)
            cluster = block_decomposition.block_clusters[block_idx][cluster_idx]
            block_indices = block_decomposition.blocks[block_idx]
            seed_vector[block_indices] .= cluster.medoid_values
            push!(source_candidate_indices, cluster.medoid_candidate_index)
            total_cluster_weight = sum(item.total_weight for item in block_decomposition.block_clusters[block_idx])
            dominance = total_cluster_weight > 0 ? cluster.total_weight / total_cluster_weight : 0.0
            push!(block_confidence, dominance)
        end
        unique!(source_candidate_indices)

        if any(existing -> _seed_vector_distance(existing, seed_vector) <= 1e-8, seen_vectors)
            continue
        end
        push!(seen_vectors, copy(seed_vector))

        fit_error = _seed_loss(polish_ctx, seed_vector)
        candidate = _build_block_seed_candidate(
            seed_vector,
            pep,
            polish_ctx,
            fit_error,
            source_candidate_indices,
            raw_candidates[source_candidate_indices],
        )
        raw_metric = _block_hypothesis_metric(
            length(raw_candidates) + length(rows) + 1,
            candidate,
            context,
            support_points,
            support_combos,
            coeff_cache,
            system_cache,
            order_cache,
        )
        push!(rows, (
            source_block_cluster_indices = combo,
            source_candidate_indices = source_candidate_indices,
            block_confidence = block_confidence,
            candidate = candidate,
            raw_fit_error = raw_metric.fit_error,
            raw_equation_penalty = raw_metric.equation_penalty,
        ))
    end

    isempty(rows) && return AssembledHypothesis[]
    fit_norm = _minmax_normalize(Float64[log1p(max(row.raw_fit_error, 0.0)) for row in rows])
    eq_norm = _minmax_normalize(Float64[log1p(max(row.raw_equation_penalty, 0.0)) for row in rows])

    hypotheses = AssembledHypothesis[]
    for (idx, row) in enumerate(rows)
        score = block_opts.score_weights.fit * fit_norm[idx] + block_opts.score_weights.equation * eq_norm[idx]
        push!(hypotheses, AssembledHypothesis(
            idx,
            copy(row.source_block_cluster_indices),
            copy(row.source_candidate_indices),
            row.candidate,
            nothing,
            row.candidate,
            row.raw_fit_error,
            row.raw_equation_penalty,
            score,
            row.raw_fit_error,
            row.raw_equation_penalty,
            score,
            false,
            copy(row.block_confidence),
        ))
    end
    sort!(hypotheses; by = item -> (item.final_combined_score, item.final_fit_error, item.final_equation_penalty))
    return hypotheses
end

function _renormalize_hypothesis_scores!(
    hypotheses::Vector{AssembledHypothesis},
    block_opts::BlockConsensusOptions,
)
    isempty(hypotheses) && return hypotheses
    fit_values = Float64[log1p(max(hypothesis.final_fit_error, 0.0)) for hypothesis in hypotheses]
    eq_values = Float64[log1p(max(hypothesis.final_equation_penalty, 0.0)) for hypothesis in hypotheses]
    fit_norm = _minmax_normalize(fit_values)
    eq_norm = _minmax_normalize(eq_values)
    for idx in eachindex(hypotheses)
        score = block_opts.score_weights.fit * fit_norm[idx] + block_opts.score_weights.equation * eq_norm[idx]
        hypothesis = hypotheses[idx]
        hypotheses[idx] = AssembledHypothesis(
            hypothesis.hypothesis_index,
            hypothesis.source_block_cluster_indices,
            hypothesis.source_candidate_indices,
            hypothesis.candidate,
            hypothesis.polished_candidate,
            hypothesis.final_candidate,
            hypothesis.raw_fit_error,
            hypothesis.raw_equation_penalty,
            hypothesis.raw_combined_score,
            hypothesis.final_fit_error,
            hypothesis.final_equation_penalty,
            score,
            hypothesis.improved_by_polish,
            hypothesis.block_confidence,
        )
    end
    sort!(hypotheses; by = item -> (item.final_combined_score, item.final_fit_error, item.final_equation_penalty))
    return hypotheses
end

function _refine_block_hypotheses!(
    hypotheses::Vector{AssembledHypothesis},
    pep::ParameterEstimationProblem,
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
    context,
    support_points::Vector{Int},
    support_combos::Vector{Vector{Int}},
    run_opts::EstimationOptions,
    block_opts::BlockConsensusOptions,
    coeff_cache::Dict,
    system_cache::Dict,
    order_cache::Dict,
)
    block_opts.enable_polish || return hypotheses
    isempty(hypotheses) && return hypotheses

    limit = min(block_opts.polish_top_hypotheses, length(hypotheses))
    improved_indices = Int[]
    for idx in 1:limit
        hypothesis = hypotheses[idx]
        polished = try
            _polish_research_seed(pep, hypothesis.candidate, polish_ctx, run_opts)
        catch
            nothing
        end
        isnothing(polished) && continue
        polished_metrics = _block_hypothesis_metric(
            length(raw_candidates) + 20_000 + idx,
            polished,
            context,
            support_points,
            support_combos,
            coeff_cache,
            system_cache,
            order_cache,
        )
        polished_score = _block_direct_score(polished_metrics.fit_error, polished_metrics.equation_penalty, block_opts)
        raw_score = _block_direct_score(hypothesis.raw_fit_error, hypothesis.raw_equation_penalty, block_opts)
        polished_score < raw_score - 1e-12 || continue
        hypotheses[idx] = AssembledHypothesis(
            hypothesis.hypothesis_index,
            hypothesis.source_block_cluster_indices,
            hypothesis.source_candidate_indices,
            hypothesis.candidate,
            polished,
            polished,
            hypothesis.raw_fit_error,
            hypothesis.raw_equation_penalty,
            hypothesis.raw_combined_score,
            polished_metrics.fit_error,
            polished_metrics.equation_penalty,
            polished_score,
            true,
            hypothesis.block_confidence,
        )
        push!(improved_indices, idx)
    end
    isempty(improved_indices) || _renormalize_hypothesis_scores!(hypotheses, block_opts)
    return hypotheses
end

function _block_variable_confidence(
    report_hypotheses::Vector{AssembledHypothesis},
    block_decomposition::BlockDecomposition,
    polish_ctx::PolishContext,
)
    isempty(report_hypotheses) && return BlockVariableConfidence[]
    best_vector = _candidate_to_vector(first(report_hypotheses).final_candidate, polish_ctx)
    top_vectors = [_candidate_to_vector(item.final_candidate, polish_ctx) for item in report_hypotheses[1:min(3, length(report_hypotheses))]]

    rows = BlockVariableConfidence[]
    for (block_index, block_indices) in enumerate(block_decomposition.blocks)
        best_hypothesis_cluster = first(report_hypotheses).source_block_cluster_indices[block_index]
        total_cluster_weight = sum(cluster.total_weight for cluster in block_decomposition.block_clusters[block_index])
        cluster = block_decomposition.block_clusters[block_index][best_hypothesis_cluster]
        dominance = total_cluster_weight > 0 ? cluster.total_weight / total_cluster_weight : 0.0

        for idx in block_indices
            values = Float64[vec[idx] for vec in top_vectors]
            spread = _relative_spread(values)
            spread_score = 1.0 / (1.0 + 5.0 * spread)
            confidence = clamp(mean((dominance, spread_score)), 0.0, 1.0)
            push!(rows, BlockVariableConfidence(
                block_decomposition.variable_names[idx],
                block_index,
                best_vector[idx],
                spread,
                dominance,
                confidence,
                _block_confidence_tier(confidence),
            ))
        end
    end
    sort!(rows; by = row -> (row.block_index, row.variable_name))
    return rows
end

function _empty_block_consensus_report(model_name::String, block_opts::BlockConsensusOptions)
    empty_decomposition = BlockDecomposition(String[], Symbol[], Float64[], zeros(Float64, 0, 0), Vector{Vector{Int}}(), Vector{Vector{String}}(), Vector{Vector{BlockCluster}}())
    return BlockConsensusReport(
        model_name,
        block_opts.version_label,
        ParameterEstimationResult[],
        CandidateEvidence[],
        empty_decomposition,
        AssembledHypothesis[],
        nothing,
        AssembledHypothesis[],
        BlockVariableConfidence[],
        Int[],
        Vector{Vector{Int}}(),
        Dict{Symbol, Any}(
            :version_label => block_opts.version_label,
            :n_raw_candidates => 0,
            :n_blocks => 0,
            :n_hypotheses => 0,
        ),
    )
end

function _assemble_block_consensus_report(
    pep_with_data::ParameterEstimationProblem,
    run_opts::EstimationOptions,
    raw_candidates::Vector{ParameterEstimationResult},
    block_opts::BlockConsensusOptions;
    context = nothing,
    support_points = nothing,
    support_combos = nothing,
    evidence = nothing,
)
    isempty(raw_candidates) && return _empty_block_consensus_report(pep_with_data.name, block_opts)

    context = isnothing(context) ? _build_consensus_context(pep_with_data, run_opts) : context
    polish_ctx = _build_polish_context(pep_with_data; opts = run_opts)
    consensus_opts = _block_base_consensus_opts(block_opts)
    coeff_cache = Dict{Any, Any}()
    system_cache = Dict{Any, Any}()
    order_cache = Dict{Any, Any}()
    timing_phases = TimingPhaseEntry[]
    timing_details = OrderedDict{Symbol, Any}()
    reused_support_points = !isnothing(support_points)
    reused_support_combos = !isnothing(support_combos)
    reused_candidate_evidence = !isnothing(evidence)

    support_stage = @timed begin
        local_support_points = if reused_support_points
            copy(support_points)
        else
            _select_consensus_support_points(
                pep_with_data,
                raw_candidates,
                context.point_indices,
                context.support_labels,
                context.interpolant_cache,
                consensus_opts,
                context.t_vector,
            )
        end
        local_support_combos = if reused_support_combos
            deepcopy(support_combos)
        else
            _select_consensus_support_combos(raw_candidates, local_support_points, run_opts.multipoint_n_points, consensus_opts)
        end
        local_evidence = if reused_candidate_evidence
            evidence
        else
            _build_candidate_evidence(
                raw_candidates,
                context,
                local_support_points,
                local_support_combos,
                consensus_opts;
                coeff_cache = coeff_cache,
                system_cache = system_cache,
                order_cache = order_cache,
            )
        end
        (
            support_points = local_support_points,
            support_combos = local_support_combos,
            evidence = local_evidence,
        )
    end
    support_points = support_stage.value.support_points
    support_combos = support_stage.value.support_combos
    evidence = support_stage.value.evidence
    push!(timing_phases, TimingPhaseEntry("reuse_or_build_evidence", support_stage.time, Int64(support_stage.bytes), support_stage.gctime))
    timing_details[:reused_support_points] = reused_support_points
    timing_details[:reused_support_combos] = reused_support_combos
    timing_details[:reused_candidate_evidence] = reused_candidate_evidence
    timing_details[:support_point_count] = length(support_points)
    timing_details[:support_combo_count] = length(support_combos)

    block_stage = @timed _build_block_decomposition(raw_candidates, evidence, polish_ctx, block_opts)
    block_decomposition = block_stage.value
    push!(timing_phases, TimingPhaseEntry("block_decomposition", block_stage.time, Int64(block_stage.bytes), block_stage.gctime))
    timing_details[:block_count] = length(block_decomposition.blocks)

    assemble_stage = @timed _assemble_block_hypotheses(
        pep_with_data,
        raw_candidates,
        block_decomposition,
        polish_ctx,
        context,
        support_points,
        support_combos,
        block_opts,
        coeff_cache,
        system_cache,
        order_cache,
    )
    hypotheses = assemble_stage.value
    push!(timing_phases, TimingPhaseEntry("assemble_hypotheses", assemble_stage.time, Int64(assemble_stage.bytes), assemble_stage.gctime))
    timing_details[:hypothesis_count] = length(hypotheses)

    hypothesis_rescore_seconds = 0.0
    push!(timing_phases, TimingPhaseEntry("hypothesis_rescore", hypothesis_rescore_seconds, 0, 0.0))

    polish_stage = @timed _refine_block_hypotheses!(
        hypotheses,
        pep_with_data,
        raw_candidates,
        polish_ctx,
        context,
        support_points,
        support_combos,
        run_opts,
        block_opts,
        coeff_cache,
        system_cache,
        order_cache,
    )
    hypotheses = polish_stage.value
    push!(timing_phases, TimingPhaseEntry("polish_hypotheses", polish_stage.time, Int64(polish_stage.bytes), polish_stage.gctime))

    confidence_stage = @timed _block_variable_confidence(hypotheses[1:min(3, length(hypotheses))], block_decomposition, polish_ctx)
    variable_confidence = confidence_stage.value
    push!(timing_phases, TimingPhaseEntry("variable_confidence", confidence_stage.time, Int64(confidence_stage.bytes), confidence_stage.gctime))

    top_hypotheses = hypotheses[1:min(3, length(hypotheses))]
    best_result = isempty(top_hypotheses) ? nothing : first(top_hypotheses).final_candidate
    timing = TimingBreakdown(
        label = block_opts.version_label,
        total_seconds = sum(phase.seconds for phase in timing_phases),
        phases = timing_phases,
        details = timing_details,
    )

    return BlockConsensusReport(
        pep_with_data.name,
        block_opts.version_label,
        raw_candidates,
        evidence,
        block_decomposition,
        hypotheses,
        best_result,
        top_hypotheses,
        variable_confidence,
        support_points,
        support_combos,
        Dict{Symbol, Any}(
            :version_label => block_opts.version_label,
            :n_raw_candidates => length(raw_candidates),
            :n_blocks => length(block_decomposition.blocks),
            :n_hypotheses => length(hypotheses),
            :support_point_count => length(support_points),
            :support_combo_count => length(support_combos),
            :correlation_threshold => block_opts.correlation_threshold,
            :best_fit_error => isnothing(best_result) ? Inf : _result_err_key(best_result),
            :best_score => isempty(top_hypotheses) ? Inf : first(top_hypotheses).final_combined_score,
            :timing => timing,
        ),
    )
end

function research_block_consensus_v2(
    pep::ParameterEstimationProblem;
    est_opts::EstimationOptions = EstimationOptions(),
    block_opts::BlockConsensusOptions = BlockConsensusOptions(),
)
    pep_with_data, run_opts, raw_candidates = _prepare_consensus_inputs(pep, est_opts)
    context = isempty(raw_candidates) ? nothing : _build_consensus_context(pep_with_data, run_opts)
    return _assemble_block_consensus_report(
        pep_with_data,
        run_opts,
        raw_candidates,
        block_opts;
        context = context,
    )
end

function _read_simple_csv(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && return (String[], Vector{Vector{String}}())
    header = split(strip(first(lines)), ',')
    rows = Vector{Vector{String}}()
    for line in lines[2:end]
        stripped = strip(line)
        isempty(stripped) && continue
        push!(rows, split(stripped, ','))
    end
    return header, rows
end

function _load_benchmark_result_candidates(
    pep::ParameterEstimationProblem,
    opts::Union{Nothing, EstimationOptions},
    case_dir::AbstractString,
)
    result_path = joinpath(case_dir, "result.csv")
    isfile(result_path) || throw(ArgumentError("Benchmark result.csv not found at $result_path"))

    header, rows = _read_simple_csv(result_path)
    header_lookup = Dict(name => idx for (idx, name) in enumerate(header))
    run_opts = isnothing(opts) ? EstimationOptions() : opts
    polish_ctx = _build_polish_context(pep; opts = run_opts)
    t_vector = pep.data_sample["t"]
    results = ParameterEstimationResult[]

    for (row_index, row) in enumerate(rows)
        length(row) == length(header) || continue
        state_values = OrderedDict{Num, Float64}()
        param_values = OrderedDict{Num, Float64}()
        row_ok = true

        for state in keys(pep.ic)
            key = string(state)
            haskey(header_lookup, key) || begin
                row_ok = false
                break
            end
            value = try
                parse(Float64, row[header_lookup[key]])
            catch
                NaN
            end
            isfinite(value) || begin
                row_ok = false
                break
            end
            state_values[state] = value
        end
        row_ok || continue

        for param in keys(pep.p_true)
            key = string(param)
            haskey(header_lookup, key) || begin
                row_ok = false
                break
            end
            value = try
                parse(Float64, row[header_lookup[key]])
            catch
                NaN
            end
            isfinite(value) || begin
                row_ok = false
                break
            end
            param_values[param] = value
        end
        row_ok || continue

        candidate = ParameterEstimationResult(
            param_values,
            state_values,
            first(t_vector),
            NaN,
            nothing,
            length(t_vector),
            first(t_vector),
            OrderedDict{Num, Float64}(),
            Set{Num}(),
            nothing,
        )
        candidate.provenance = ResultProvenance(
            primary_method = :algebraic,
            source_candidate_index = row_index,
            source_type = :imported,
            notes = Symbol[:benchmark_result_csv],
        )
        sync_result_contract!(candidate)
        candidate.err = _seed_loss(polish_ctx, _candidate_to_vector(candidate, polish_ctx))
        push!(results, candidate)
    end

    return results
end

function _block_strategy_summary(
    pep::ParameterEstimationProblem,
    strategy::Symbol,
    candidate::Union{Nothing, ParameterEstimationResult},
    selection_seconds::Float64,
    shared_seconds::Float64;
    report = nothing,
)
    truth_metrics = _candidate_truth_metrics(pep, candidate)
    return Dict{Symbol, Any}(
        :strategy => strategy,
        :selection_seconds => selection_seconds,
        :effective_total_seconds => shared_seconds + selection_seconds,
        :final_winner_lineage => isnothing(candidate) ? "none" : lineage_summary(candidate),
        :final_winner_fit_error => isnothing(candidate) ? Inf : _result_err_key(candidate),
        :truth_metrics => truth_metrics,
        :version_label => isnothing(report) ? strategy : report.version_label,
        :timing => isnothing(report) ? TimingBreakdown(label = strategy, total_seconds = selection_seconds) : get(report.scoring_summary, :timing, TimingBreakdown(label = report.version_label, total_seconds = selection_seconds)),
    )
end

function _block_high_correlation_rows(report::BlockConsensusReport)
    matrix = report.block_decomposition.correlation_matrix
    names = report.block_decomposition.variable_names
    rows = NamedTuple[]
    for i in 1:size(matrix, 1)
        for j in (i + 1):size(matrix, 2)
            value = Float64(matrix[i, j])
            value >= 0.70 || continue
            push!(rows, (
                lhs = names[i],
                rhs = names[j],
                corr = value,
            ))
        end
    end
    sort!(rows; by = row -> -row.corr)
    return rows[1:min(10, length(rows))]
end

function _block_cluster_rows(report::BlockConsensusReport)
    rows = NamedTuple[]
    for (block_index, clusters) in enumerate(report.block_decomposition.block_clusters)
        total_weight = sum(cluster.total_weight for cluster in clusters)
        for cluster in clusters[1:min(3, length(clusters))]
            dominance = total_weight > 0 ? cluster.total_weight / total_weight : 0.0
            push!(rows, (
                block_index = block_index,
                variable_names = join(cluster.variable_names, ", "),
                cluster_index = cluster.cluster_index,
                medoid_candidate_index = cluster.medoid_candidate_index,
                total_weight = cluster.total_weight,
                dominance = dominance,
                spread = cluster.spread,
                silhouette = cluster.silhouette,
            ))
        end
    end
    return rows
end

function _assembled_hypothesis_rows(report::BlockConsensusReport)
    rows = NamedTuple[]
    for hypothesis in report.top_hypotheses
        push!(rows, (
            rank = hypothesis.hypothesis_index,
            source_clusters = join(string.(hypothesis.source_block_cluster_indices), ", "),
            source_candidates = join(string.(hypothesis.source_candidate_indices), ", "),
            fit_error = hypothesis.final_fit_error,
            equation_penalty = hypothesis.final_equation_penalty,
            combined_score = hypothesis.final_combined_score,
            polished = hypothesis.improved_by_polish,
            lineage = lineage_summary(hypothesis.final_candidate),
        ))
    end
    return rows
end

function _build_exact_block_study_artifact(
    case_dir::AbstractString;
    est_opts::Union{Nothing, EstimationOptions} = nothing,
    block_opts::BlockConsensusOptions = BlockConsensusOptions(
        support_point_count = 4,
        support_combo_count = 4,
        max_hypotheses = 12,
        polish_top_hypotheses = 2,
    ),
    branch_opts::BranchConsensusOptions = BranchConsensusOptions(
        support_point_count = 4,
        support_combo_count = 4,
        top_branch_neighbor_count = 3,
        max_refined_seeds = 2,
    ),
    candidate_source::Symbol = :benchmark_result_csv,
)
    loaded = _load_bilby_case(case_dir)
    pep_with_data = loaded.pep
    base_opts = isnothing(est_opts) ? loaded.benchmark_opts : est_opts
    run_opts = isnothing(base_opts) ? EstimationOptions() : merge_options(base_opts; nooutput = true, diagnostics = false, save_system = false)

    prep = if candidate_source == :benchmark_result_csv
        @timed _load_benchmark_result_candidates(pep_with_data, run_opts, case_dir)
    else
        @timed begin
            _, _, raw_candidates = _prepare_consensus_inputs(pep_with_data, run_opts)
            raw_candidates
        end
    end
    raw_candidates = prep.value
    context_timed = isempty(raw_candidates) ? nothing : (@timed _build_consensus_context(pep_with_data, run_opts))
    context = isnothing(context_timed) ? nothing : context_timed.value
    context_seconds = isnothing(context_timed) ? 0.0 : context_timed.time
    shared_seconds = prep.time + context_seconds

    raw_pool = _consensus_raw_pool_summary(pep_with_data, raw_candidates)
    baseline_idx = get(raw_pool, :best_fit_index, nothing)
    baseline_candidate = isnothing(baseline_idx) ? nothing : raw_candidates[baseline_idx]

    branch_timed = isempty(raw_candidates) ? nothing : (@timed _assemble_branch_consensus_report(
        pep_with_data,
        run_opts,
        raw_candidates,
        branch_opts;
        context = context,
    ))
    block_timed = isempty(raw_candidates) ? nothing : (@timed _assemble_block_consensus_report(
        pep_with_data,
        run_opts,
        raw_candidates,
        block_opts;
        context = context,
    ))

    branch_report = isnothing(branch_timed) ? nothing : branch_timed.value
    block_report = isnothing(block_timed) ? nothing : block_timed.value

    return Dict{Symbol, Any}(
        :case_dir => case_dir,
        :case_id => basename(case_dir),
        :model_name => pep_with_data.name,
        :generated_at => string(Dates.now()),
        :candidate_source => candidate_source,
        :shared_candidate_seconds => prep.time,
        :shared_context_seconds => context_seconds,
        :shared_total_seconds => shared_seconds,
        :raw_candidate_count => length(raw_candidates),
        :raw_pool => raw_pool,
        :baseline => _block_strategy_summary(pep_with_data, :best_fit_baseline, baseline_candidate, 0.0, shared_seconds),
        :branch_v1 => isnothing(branch_report) ? nothing : _block_strategy_summary(pep_with_data, :branch_consensus_v1, branch_report.best_result, branch_timed.time, shared_seconds; report = branch_report),
        :block_v2 => isnothing(block_report) ? nothing : _block_strategy_summary(pep_with_data, :block_consensus_v2, block_report.best_result, block_timed.time, shared_seconds; report = block_report),
        :branch_report => branch_report,
        :block_report => block_report,
        :high_correlations => isnothing(block_report) ? NamedTuple[] : _block_high_correlation_rows(block_report),
        :block_clusters => isnothing(block_report) ? NamedTuple[] : _block_cluster_rows(block_report),
        :top_hypotheses => isnothing(block_report) ? NamedTuple[] : _assembled_hypothesis_rows(block_report),
        :system_summary => Dict{Symbol, Any}(
            :states => [string(sym) for sym in keys(pep_with_data.ic)],
            :parameters => [string(sym) for sym in keys(pep_with_data.p_true)],
            :observables => [replace(string(mq.lhs), "(t)" => "") for mq in pep_with_data.measured_quantities],
            :datasize => length(pep_with_data.data_sample["t"]),
            :time_interval => collect(Float64, pep_with_data.recommended_time_interval),
        ),
    )
end

function _render_block_consensus_study_markdown(artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "# Exact Block Consensus Study: $(artifact[:case_id])\n")
    println(io, "- Model: `$(artifact[:model_name])`")
    println(io, "- Case dir: `$(artifact[:case_dir])`")
    println(io, "- Generated: `$(artifact[:generated_at])`")
    println(io, "- Candidate source: `$(artifact[:candidate_source])`")
    println(io, "- Shared candidate load/generation: $(_fmt_float(artifact[:shared_candidate_seconds]; digits = 3)) s")
    println(io, "- Shared context build: $(_fmt_float(artifact[:shared_context_seconds]; digits = 3)) s")
    println(io, "- Shared total pre-selection time: $(_fmt_float(artifact[:shared_total_seconds]; digits = 3)) s")
    println(io, "- Raw candidate count: $(artifact[:raw_candidate_count])\n")

    system_summary = artifact[:system_summary]
    println(io, "## System Summary\n")
    println(io, "- States: `$(join(system_summary[:states], "`, `"))`")
    println(io, "- Parameters: `$(join(system_summary[:parameters], "`, `"))`")
    println(io, "- Observables: `$(join(system_summary[:observables], "`, `"))`")
    println(io, "- Datasize: $(system_summary[:datasize])")
    println(io, "- Time interval: [$(_fmt_float(system_summary[:time_interval][1]; digits = 3)), $(_fmt_float(system_summary[:time_interval][2]; digits = 3))]\n")

    raw_pool = artifact[:raw_pool]
    println(io, "## Raw Pool Reference\n")
    println(io, "- Best raw fit index: $(get(raw_pool, :best_fit_index, nothing))")
    println(io, "- Best raw oracle index: $(get(raw_pool, :best_truth_index, nothing))")
    println(io, "- Best-fit raw combined RMSE: $(_fmt_percent(get(get(raw_pool, :best_fit_truth_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)))")
    println(io, "- Best-truth raw combined RMSE: $(_fmt_percent(get(get(raw_pool, :best_truth_truth_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)))\n")

    println(io, "## Strategy Comparison\n")
    println(io, "| Strategy | Selection s | Effective Total s | Fit Error | Param RMSE | Combined RMSE | Lineage |")
    println(io, "|----------|-------------|-------------------|-----------|------------|---------------|---------|")
    for key in (:baseline, :branch_v1, :block_v2)
        summary = artifact[key]
        isnothing(summary) && continue
        println(io,
            "| `$(summary[:strategy])` | $(_fmt_float(summary[:selection_seconds]; digits = 3)) | " *
            "$(_fmt_float(summary[:effective_total_seconds]; digits = 3)) | $(_fmt_sci(summary[:final_winner_fit_error])) | " *
            "$(_fmt_percent(get(summary[:truth_metrics], :parameter_rel_rmse, Inf))) | $(_fmt_percent(get(summary[:truth_metrics], :combined_rel_rmse, Inf))) | " *
            "$(summary[:final_winner_lineage]) |")
    end
    println(io)

    block_summary = artifact[:block_v2]
    block_timing = isnothing(block_summary) ? TimingBreakdown() : get(block_summary, :timing, TimingBreakdown())
    println(io, "## Block v2 Timing\n")
    println(io, "| Phase | Seconds |")
    println(io, "|-------|---------|")
    if isempty(block_timing.phases)
        println(io, "| `none` | 0.000 |")
    else
        for phase in block_timing.phases
            println(io, "| `$(phase.name)` | $(_fmt_float(phase.seconds; digits = 3)) |")
        end
    end
    println(io)

    println(io, "## High Correlations\n")
    println(io, "| Variable A | Variable B | |corr| |")
    println(io, "|------------|------------|--------|")
    if isempty(artifact[:high_correlations])
        println(io, "| none | none | 0.0000 |")
    else
        for row in artifact[:high_correlations]
            println(io, "| `$(row.lhs)` | `$(row.rhs)` | $(_fmt_float(row.corr; digits = 4)) |")
        end
    end
    println(io)

    println(io, "## Inferred Blocks\n")
    println(io, "| Block | Variables | Cluster | Medoid Candidate | Cluster Weight | Dominance | Spread | Silhouette |")
    println(io, "|-------|-----------|---------|------------------|----------------|-----------|--------|------------|")
    if isempty(artifact[:block_clusters])
        println(io, "| 1 | none | 1 | - | 0.0000 | 0.0000 | 0.0000 | 0.0000 |")
    else
        for row in artifact[:block_clusters]
            println(io, "| $(row.block_index) | `$(row.variable_names)` | $(row.cluster_index) | $(row.medoid_candidate_index) | " *
                "$(_fmt_float(row.total_weight; digits = 4)) | $(_fmt_float(row.dominance; digits = 4)) | " *
                "$(_fmt_float(row.spread; digits = 4)) | $(_fmt_float(row.silhouette; digits = 4)) |")
        end
    end
    println(io)

    println(io, "## Top Assembled Hypotheses\n")
    println(io, "| Rank | Source Clusters | Source Candidates | Fit Error | Equation Penalty | Combined Score | Polished | Lineage |")
    println(io, "|------|-----------------|-------------------|-----------|------------------|----------------|----------|---------|")
    if isempty(artifact[:top_hypotheses])
        println(io, "| 1 | none | none | Inf | Inf | Inf | false | none |")
    else
        for (rank, row) in enumerate(artifact[:top_hypotheses])
            println(io, "| $(rank) | `$(row.source_clusters)` | `$(row.source_candidates)` | $(_fmt_sci(row.fit_error)) | " *
                "$(_fmt_sci(row.equation_penalty)) | $(_fmt_float(row.combined_score; digits = 4)) | $(row.polished) | $(row.lineage) |")
        end
    end
    println(io)

    block_report = artifact[:block_report]
    if !isnothing(block_report)
        println(io, "## Variable Confidence\n")
        println(io, "| Variable | Block | Representative | Cross-Hypothesis Spread | Block Dominance | Confidence | Tier |")
        println(io, "|----------|-------|----------------|-------------------------|-----------------|------------|------|")
        for row in block_report.variable_confidence
            println(io, "| `$(row.variable_name)` | $(row.block_index) | $(_fmt_float(row.representative_value; digits = 6)) | " *
                "$(_fmt_float(row.cross_hypothesis_spread; digits = 4)) | $(_fmt_float(row.block_dominance; digits = 4)) | " *
                "$(_fmt_float(row.confidence_score; digits = 4)) | `$(row.confidence_tier)` |")
        end
        println(io)
    end

    return String(take!(io))
end
