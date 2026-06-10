# ============================================================================
# Research-only result & option types
# ============================================================================
# Relocated from src/types/core_types.jl on 2026-06-10 to keep the foundational
# types file production-only. These back the benchmark/consensus tooling under
# src/research/ (consensus, synthesized-finalizer, branch-consensus-v1,
# block-consensus-v2, tryhard finalists) — NONE is used by the estimation
# pipeline. Production `TimingPhaseEntry`/`TimingBreakdown`, which were textually
# interleaved with this cluster, stayed in core_types.jl.
#
# Included by src/ODEParameterEstimation.jl AFTER types/core_types.jl (which
# defines ParameterEstimationResult, used in field types here) and BEFORE the
# research/*.jl that construct these. Still exported from the module.
# ============================================================================

Base.@kwdef struct ConsensusOptions
    strategy::Symbol = :family_consensus_refit
    support_point_count::Int = 8
    support_combo_count::Int = 8
    refine_top_families::Int = 3
    family_distance_threshold::Float64 = CLUSTERING_THRESHOLD
    family_min_distinct_sources::Int = 2
    do_equation_refit::Bool = true
    score_weights::NamedTuple{(:fit, :equation, :support, :trust), Tuple{Float64, Float64, Float64, Float64}} =
        (fit = 0.45, equation = 0.35, support = 0.10, trust = 0.10)
    nonlinearity_penalty_threshold::Float64 = 1.0
end

struct CandidateEvidence
    candidate_index::Int
    base_fit_error::Float64
    sp_equation_residual_kept::Float64
    sp_equation_residual_dropped::Float64
    mp_equation_residual_kept::Float64
    mp_equation_residual_dropped::Float64
    conditioning_score::Float64
    uq_volume_proxy::Float64
    source_diversity_tags::Vector{Symbol}
    composite_score::Float64
    score_breakdown::NamedTuple{(:fit, :equation, :support, :trust), Tuple{Float64, Float64, Float64, Float64}}
end

struct CandidateFamily
    member_indices::Vector{Int}
    family_medoid_index::Int
    best_member_index::Int
    distinct_interpolators::Vector{Symbol}
    distinct_source_types::Vector{Symbol}
    distinct_shooting_support::Vector{Int}
    family_score::Float64
end

struct ConsensusEstimationReport
    model_name::String
    strategy::Symbol
    raw_candidates::Vector{ParameterEstimationResult}
    candidate_evidence::Vector{CandidateEvidence}
    families::Vector{CandidateFamily}
    winner_family_index::Union{Nothing, Int}
    winner_candidate_index::Union{Nothing, Int}
    winner_candidate::Union{Nothing, ParameterEstimationResult}
    winner_refined::Union{Nothing, ParameterEstimationResult}
    support_points::Vector{Int}
    support_combos::Vector{Vector{Int}}
    scoring_summary::Dict{Symbol, Any}
end

Base.@kwdef struct SynthesizedFinalizerOptions
    base_consensus_opts::ConsensusOptions = ConsensusOptions(
        strategy = :family_consensus,
        refine_top_families = 1,
        do_equation_refit = false,
    )
    max_family_seeds::Int = 6
    max_cross_family_seeds::Int = 4
    allow_cross_family_synthesis::Bool = true
    allow_parameter_stitching::Bool = true
    cross_family_distance_limit::Float64 = 0.5
    seed_consistency_threshold::Float64 = 100.0
    max_refine_candidates::Int = 6
    refine_with_full_trajectory::Bool = true
    refine_objective_mode::Symbol = :trajectory_only
end

struct SynthesizedSeed
    seed_vector::Vector{Float64}
    seed_kind::Symbol
    source_candidate_indices::Vector{Int}
    source_family_indices::Vector{Int}
    seed_lineage_summary::String
    pre_refine_checks::Dict{Symbol, Any}
end

struct SynthesizedFinalizerReport
    raw_consensus_report::ConsensusEstimationReport
    synthesized_seeds::Vector{SynthesizedSeed}
    refined_seed_results::Vector{ParameterEstimationResult}
    winning_result::Union{Nothing, ParameterEstimationResult}
    winning_origin::Symbol
    selection_summary::Dict{Symbol, Any}
    benchmark_evaluation::Dict{Symbol, Any}
end

Base.@kwdef struct BranchConsensusOptions
    version_label::Symbol = :branch_consensus_v1
    support_point_count::Int = 8
    support_combo_count::Int = 8
    branch_distance_floor::Float64 = 1e-3
    branch_distance_ceiling::Float64 = 0.25
    max_returned_branches::Int = 5
    adaptive_k_score_ratio::Float64 = 0.60
    adaptive_k_support_fraction::Float64 = 0.90
    block_edge_threshold::Float64 = 0.40
    low_confidence_threshold::Float64 = 0.45
    enable_branch_local_synthesis::Bool = true
    top_branch_neighbor_count::Int = 3
    max_refined_seeds::Int = 4
    small_pool_candidate_guard::Int = 5
    small_pool_branch_guard::Int = 3
    override_score_margin::Float64 = 0.15
    override_fit_factor::Float64 = 1.5
    branch_score_weights::NamedTuple{(:quality, :persistence, :compactness, :trust), Tuple{Float64, Float64, Float64, Float64}} =
        (quality = 0.45, persistence = 0.35, compactness = 0.10, trust = 0.10)
end

struct BranchVariableSupport
    branch_index::Int
    variable_name::String
    variable_kind::Symbol
    representative_value::Float64
    within_branch_dispersion::Float64
    cross_branch_margin::Float64
    equation_sensitivity::Float64
    fit_sensitivity::Float64
    scalar_support_score::Float64
    confidence_tier::Symbol
end

struct BranchBlockSupport
    branch_index::Int
    block_index::Int
    variable_names::Vector{String}
    block_bases::Vector{String}
    within_branch_dispersion::Float64
    cross_branch_margin::Float64
    equation_sensitivity::Float64
    fit_sensitivity::Float64
    block_support_score::Float64
    low_confidence::Bool
    donor_branch_indices::Vector{Int}
end

struct BranchHypothesis
    branch_index::Int
    member_indices::Vector{Int}
    representative_candidate_index::Union{Nothing, Int}
    representative_candidate::Union{Nothing, ParameterEstimationResult}
    best_fit_candidate_index::Union{Nothing, Int}
    best_equation_candidate_index::Union{Nothing, Int}
    branch_score::Float64
    persistence_score::Float64
    quality_score::Float64
    compactness_score::Float64
    trust_score::Float64
    distinct_origin_count::Int
    distinct_shooting_support::Vector{Int}
    distinct_combo_support::Vector{Int}
    distinct_source_types::Vector{Symbol}
    distinct_interpolators::Vector{Symbol}
    variable_support::Vector{BranchVariableSupport}
    block_support::Vector{BranchBlockSupport}
    confidence_tier::Symbol
    refined_candidate::Union{Nothing, ParameterEstimationResult}
end

struct BranchConsensusReport
    model_name::String
    version_label::Symbol
    raw_candidates::Vector{ParameterEstimationResult}
    candidate_evidence::Vector{CandidateEvidence}
    branch_hypotheses::Vector{BranchHypothesis}
    best_branch_index::Union{Nothing, Int}
    best_result::Union{Nothing, ParameterEstimationResult}
    top_branches::Vector{BranchHypothesis}
    adaptive_k::Int
    support_points::Vector{Int}
    support_combos::Vector{Vector{Int}}
    scoring_summary::Dict{Symbol, Any}
end

Base.@kwdef struct BlockConsensusOptions
    version_label::Symbol = :block_consensus_v2
    support_point_count::Int = 8
    support_combo_count::Int = 8
    correlation_threshold::Float64 = 0.75
    max_clusters_per_block::Int = 5
    max_recombined_clusters_per_block::Int = 3
    max_hypotheses::Int = 20
    enable_polish::Bool = true
    polish_top_hypotheses::Int = 3
    score_weights::NamedTuple{(:fit, :equation), Tuple{Float64, Float64}} =
        (fit = 0.70, equation = 0.30)
end

struct BlockCluster
    block_index::Int
    cluster_index::Int
    variable_names::Vector{String}
    member_indices::Vector{Int}
    medoid_candidate_index::Int
    medoid_values::Vector{Float64}
    total_weight::Float64
    spread::Float64
    silhouette::Float64
end

struct BlockDecomposition
    variable_names::Vector{String}
    variable_kinds::Vector{Symbol}
    candidate_weights::Vector{Float64}
    correlation_matrix::Matrix{Float64}
    blocks::Vector{Vector{Int}}
    block_names::Vector{Vector{String}}
    block_clusters::Vector{Vector{BlockCluster}}
end

struct BlockVariableConfidence
    variable_name::String
    block_index::Int
    representative_value::Float64
    cross_hypothesis_spread::Float64
    block_dominance::Float64
    confidence_score::Float64
    confidence_tier::Symbol
end

struct AssembledHypothesis
    hypothesis_index::Int
    source_block_cluster_indices::Vector{Int}
    source_candidate_indices::Vector{Int}
    candidate::ParameterEstimationResult
    polished_candidate::Union{Nothing, ParameterEstimationResult}
    final_candidate::ParameterEstimationResult
    raw_fit_error::Float64
    raw_equation_penalty::Float64
    raw_combined_score::Float64
    final_fit_error::Float64
    final_equation_penalty::Float64
    final_combined_score::Float64
    improved_by_polish::Bool
    block_confidence::Vector{Float64}
end

struct BlockConsensusReport
    model_name::String
    version_label::Symbol
    raw_candidates::Vector{ParameterEstimationResult}
    candidate_evidence::Vector{CandidateEvidence}
    block_decomposition::BlockDecomposition
    assembled_hypotheses::Vector{AssembledHypothesis}
    best_result::Union{Nothing, ParameterEstimationResult}
    top_hypotheses::Vector{AssembledHypothesis}
    variable_confidence::Vector{BlockVariableConfidence}
    support_points::Vector{Int}
    support_combos::Vector{Vector{Int}}
    scoring_summary::Dict{Symbol, Any}
end

Base.@kwdef struct TryhardFinalistOptions
    version_label::Symbol = :reasonable_frontier_v1
    frontier_growth_factor::Float64 = 1.5
    max_admitted_merged_seeds::Int = 64
    max_raw_seeds::Int = 10
    max_block_seeds::Int = 10
    block_support_point_count::Int = 4
    block_support_combo_count::Int = 4
    distinctness_threshold::Float64 = 0.001
    post_polish_metric::Symbol = :trajectory_hybrid
    post_polish_traj_threshold::Float64 = 0.02
    post_polish_secondary_threshold::Float64 = 1.0
    post_polish_basin_threshold::Float64 = 0.003
    near_bound_threshold::Float64 = 0.01
    include_block_seeds::Bool = true
    include_branch_seeds::Bool = true
    include_synthesized_seeds::Bool = true
end

struct TryhardFinalist
    finalist_index::Int
    representative_candidate::ParameterEstimationResult
    member_indices::Vector{Int}
    member_count::Int
    source_tags::Vector{Symbol}
    source_mix::Symbol
    best_fit_error::Float64
    representative_lineage::String
    nearest_bound_margin::Float64
    near_bound_count::Int
    bound_pinned::Bool
end

struct TryhardFinalistReport
    version_label::Symbol
    raw_candidates::Vector{ParameterEstimationResult}
    block_report::Union{Nothing, BlockConsensusReport}
    branch_report::Union{Nothing, BranchConsensusReport}
    synth_report::Union{Nothing, SynthesizedFinalizerReport}
    raw_seed_rows::Vector{Dict{Symbol, Any}}
    block_seed_rows::Vector{Dict{Symbol, Any}}
    branch_seed_rows::Vector{Dict{Symbol, Any}}
    synthesized_seed_rows::Vector{Dict{Symbol, Any}}
    additive_seed_rows::Vector{Dict{Symbol, Any}}
    merged_seed_rows::Vector{Dict{Symbol, Any}}
    rejected_additive_seed_rows::Vector{Dict{Symbol, Any}}
    polished_seed_rows::Vector{Dict{Symbol, Any}}
    all_polished_candidates::Vector{ParameterEstimationResult}
    finalists::Vector{TryhardFinalist}
    best_result::Union{Nothing, ParameterEstimationResult}
    seed_summary::Dict{Symbol, Any}
    basin_summary::Vector{Dict{Symbol, Any}}
    selection_summary::Dict{Symbol, Any}
end
