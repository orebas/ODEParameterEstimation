# ── Per-run estimation context ────────────────────────────────────────────────
# Replaces the module-global run-state Refs (_TIMING_CAPTURE_ENABLED,
# _LAST_ESTIMATION_TIMING, _LAST_ESTIMATION_AUTO_M, and the two timing-sink
# Refs) with a dynamically-scoped, task-inherited context (Base.ScopedValues —
# child tasks spawned inside a run inherit the binding). This removes the
# cross-run contamination class flagged in the 2026-07 review: two analyses in
# one process can no longer read each other's auto-M or timing, and the sink
# save/install/restore dance disappears entirely.
#
# Deliberately NOT migrated:
#   - `_LAST_ESTIMATION_REUSE` (optimized_multishot_estimation.jl): a CROSS-run
#     hand-off consumed after the run completes (consensus/benchmark flows via
#     `_last_estimation_reuse()`). Global by design.
#   - the `_*_TIMING_CONTEXT_STACK` label stacks (si_template_integration.jl):
#     module-global; worst case under concurrent runs is mislabeled timing
#     rows. Follow-up candidate.

using Base.ScopedValues: ScopedValue

abstract type AbstractEstimatorArtifact end

# Research-only selection contracts used by audited conditional-coverage
# campaigns. They are intentionally scoped to one RunContext instead of added
# to EstimationOptions: ordinary package callers must retain adaptive point and
# pair selection byte-for-byte.
abstract type AbstractCampaignSelectionRecipe end

struct FixedSinglePointRecipe <: AbstractCampaignSelectionRecipe
	row::Int
	interpolator_source::Union{Nothing, Symbol}
	function FixedSinglePointRecipe(
		row::Integer;
		interpolator_source::Union{Nothing, Symbol} = nothing,
	)
		row > 0 || throw(ArgumentError("fixed single-point row must be positive"))
		new(Int(row), interpolator_source)
	end
end

struct FixedMultipointRecipe <: AbstractCampaignSelectionRecipe
	rows::Vector{Int}
	interpolator_source::Union{Nothing, Symbol}
	function FixedMultipointRecipe(
		rows::AbstractVector{<:Integer};
		interpolator_source::Union{Nothing, Symbol} = nothing,
	)
		resolved = Int.(rows)
		isempty(resolved) && throw(ArgumentError("fixed multipoint rows must be non-empty"))
		all(row -> row > 0, resolved) ||
			throw(ArgumentError("fixed multipoint rows must be positive"))
		length(unique(resolved)) == length(resolved) ||
			throw(ArgumentError("fixed multipoint rows must be unique"))
		new(resolved, interpolator_source)
	end
end

"""Exact production recipe retained for one square single-point algebraic root."""
struct SinglePointUQArtifact{E<:AbstractVector, V<:AbstractVector, D<:AbstractVector,
        R<:AbstractVector, I<:AbstractDict} <: AbstractEstimatorArtifact
	equations::E
	solve_vars::V
	data_vars::D
	data_values::Vector{Float64}
	root::R
	interpolants::I
	time_index::Int
	time_value::Float64
end

"""Exact production recipe retained for one square multipoint algebraic root."""
struct MultipointUQArtifact{R<:AbstractVector, I<:AbstractDict} <: AbstractEstimatorArtifact
	evaluation::MultiPointEvaluation
	root::R
	interpolants::I
	interpolator_source::Symbol
end

"""Local full-trajectory optimizer recipe retained for score-equation UQ."""
struct PolishUQArtifact{C, R<:AbstractVector, O} <: AbstractEstimatorArtifact
	context::C
	internal_optimum::R
	optimizer_result::O
	parent_candidate_id::Int
	objective_kind::Symbol
end

"""Local branch-completion recipe; concrete payload is owned by branch completion."""
struct BranchCompletionUQArtifact{P} <: AbstractEstimatorArtifact
	parent_candidate_id::Int
	payload::P
end

"""Physical-estimator influence with respect to the retained raw observations."""
struct UQInfluenceArtifact
	influence::Matrix{Float64}
	observation_covariance::Matrix{Float64}
	observation_labels::Vector{String}
	coordinate_labels::Vector{String}
end

mutable struct RunContext
	capture_timing::Bool
	timing::Union{Nothing, TimingBreakdown}
	auto_m::Union{Nothing, Int}
	resolve_timing_sink::Union{Nothing, Vector{NamedTuple}}
	detailed_timing_sink::Union{Nothing, Vector{NamedTuple}}
	# Per-analysis HC solver config (from EstimationOptions; nothing = fall back
	# to the module Refs HC_SOLVE_THREADING / HC_COMPILE_MODE).
	hc_threading::Union{Nothing, Bool}
	hc_compile_mode::Union{Nothing, Symbol}
	# Timing context-label stacks (formerly module-global in
	# si_template_integration.jl; per-run here so concurrent runs cannot
	# mislabel each other's timing rows).
	resolve_timing_labels::Vector{Symbol}
	detailed_timing_labels::Vector{Symbol}
	# Estimator-aware UQ state. Identities are lightweight and always retained;
	# heavy artifacts are installed only when capture_uq is true.
	capture_uq::Bool
	next_candidate_id::Int
	estimator_artifacts::Dict{Int, AbstractEstimatorArtifact}
	estimator_identities::Dict{Int, EstimatorIdentity}
	uq_noise_interpolants::Dict{Symbol, AbstractDict}
	uq_influences::Dict{Int, UQInfluenceArtifact}
	estimator_lock::ReentrantLock
	selection_recipe::Union{Nothing, AbstractCampaignSelectionRecipe}
end
RunContext(;
	capture_timing::Bool = false,
	selection_recipe::Union{Nothing, AbstractCampaignSelectionRecipe} = nothing,
) =
	RunContext(capture_timing, nothing, nothing, nothing, nothing,
		nothing, nothing, Symbol[], Symbol[], false, 1,
			Dict{Int, AbstractEstimatorArtifact}(), Dict{Int, EstimatorIdentity}(),
			Dict{Symbol, AbstractDict}(), Dict{Int, UQInfluenceArtifact}(), ReentrantLock(),
			selection_recipe)

const RUN_CONTEXT = ScopedValue{Union{Nothing, RunContext}}(nothing)

_run_ctx() = RUN_CONTEXT[]
_run_ctx_capture_timing() = (c = RUN_CONTEXT[]; c !== nothing && c.capture_timing)
_run_ctx_set_timing!(tb) = (c = RUN_CONTEXT[]; c === nothing || (c.timing = tb); nothing)
_run_ctx_set_auto_m!(m) = (c = RUN_CONTEXT[]; c === nothing || (c.auto_m = m); nothing)

"""
	_run_ctx_take_auto_m!() -> Union{Nothing, Int}

Consume-once read of the run's auto-detected algebraic multiplicity: returns
the value and clears it, so it can never leak into a later analysis sharing an
outer scope. Returns `nothing` when no context is bound.
"""
function _run_ctx_take_auto_m!()
	c = RUN_CONTEXT[]
	c === nothing && return nothing
	m = c.auto_m
	c.auto_m = nothing
	return m
end

function _run_ctx_install_sinks!(resolve_records::Vector{NamedTuple}, detailed_records::Vector{NamedTuple})
	c = RUN_CONTEXT[]
	c === nothing && return nothing
	c.resolve_timing_sink = resolve_records
	c.detailed_timing_sink = detailed_records
	return nothing
end
_run_ctx_resolve_sink() = (c = RUN_CONTEXT[]; c === nothing ? nothing : c.resolve_timing_sink)
_run_ctx_detailed_sink() = (c = RUN_CONTEXT[]; c === nothing ? nothing : c.detailed_timing_sink)

function _run_ctx_set_hc_opts!(threading::Bool, compile_mode::Symbol)
	c = RUN_CONTEXT[]
	c === nothing && return nothing
	c.hc_threading = threading
	c.hc_compile_mode = compile_mode
	return nothing
end
_run_ctx_hc_threading() = (c = RUN_CONTEXT[]; c === nothing ? nothing : c.hc_threading)
_run_ctx_hc_compile_mode() = (c = RUN_CONTEXT[]; c === nothing ? nothing : c.hc_compile_mode)
_run_ctx_selection_recipe() = (c = RUN_CONTEXT[]; c === nothing ? nothing : c.selection_recipe)

_run_ctx_set_capture_uq!(enabled::Bool) = (c = RUN_CONTEXT[]; c === nothing || (c.capture_uq = enabled); nothing)
_run_ctx_capture_uq() = (c = RUN_CONTEXT[]; c !== nothing && c.capture_uq)

"""
	_run_ctx_begin_uq!(enabled)

Start one logical estimator run inside the currently bound context. Timing
wrappers may intentionally reuse a `RunContext` across multiple analyses, so
all candidate-scoped UQ state must be reset here to prevent an earlier run's
noise provider or candidate ID from being matched to a later winner.
"""
function _run_ctx_begin_uq!(enabled::Bool)
	c = RUN_CONTEXT[]
	c === nothing && return nothing
	lock(c.estimator_lock) do
		c.capture_uq = enabled
		c.next_candidate_id = 1
		empty!(c.estimator_artifacts)
		empty!(c.estimator_identities)
		empty!(c.uq_noise_interpolants)
		empty!(c.uq_influences)
	end
	return nothing
end

"""
	_run_ctx_try_uq_capture(f, description)

Build optional UQ-only state without allowing capture failures to change the
estimator pool. Interrupts still propagate. A later selected candidate whose
capture failed receives a typed `UQUnavailable(:missing_artifact)` outcome.
"""
function _run_ctx_try_uq_capture(f::F, description::AbstractString) where {F}
	_run_ctx_capture_uq() || return nothing
	try
		return f()
	catch err
		_rethrow_if_interrupt(err)
		@warn "Estimator-aware UQ capture failed; retaining the estimator candidate without an artifact" description exception = (err, catch_backtrace())
		return nothing
	end
end

function _run_ctx_new_identity!(;
	estimator_kind::Symbol,
	data_scope::Symbol,
	time_indices::AbstractVector{<:Integer} = Int[],
	time_values::AbstractVector{<:Real} = Float64[],
	interpolator_source::Union{Nothing, Symbol} = nothing,
	parent_candidate_ids::AbstractVector{<:Integer} = Int[],
)
	c = RUN_CONTEXT[]
	if c === nothing
		return EstimatorIdentity(
			estimator_kind = estimator_kind, data_scope = data_scope,
			time_indices = time_indices, time_values = time_values,
			interpolator_source = interpolator_source,
			parent_candidate_ids = parent_candidate_ids,
		)
	end
	lock(c.estimator_lock) do
		candidate_id = c.next_candidate_id
		c.next_candidate_id += 1
		identity = EstimatorIdentity(
			candidate_id = candidate_id, estimator_kind = estimator_kind,
			data_scope = data_scope, time_indices = time_indices,
			time_values = time_values, interpolator_source = interpolator_source,
			parent_candidate_ids = parent_candidate_ids,
		)
		c.estimator_identities[candidate_id] = identity
		return copy_estimator_identity(identity)
	end
end

function _run_ctx_register_artifact!(candidate_id::Integer, artifact::AbstractEstimatorArtifact)
	c = RUN_CONTEXT[]
	(c === nothing || !c.capture_uq || candidate_id <= 0) && return nothing
	lock(c.estimator_lock) do
		c.estimator_artifacts[Int(candidate_id)] = artifact
	end
	return nothing
end

function _run_ctx_artifact(candidate_id::Integer)
	c = RUN_CONTEXT[]
	(c === nothing || candidate_id <= 0) && return nothing
	return lock(c.estimator_lock) do
		get(c.estimator_artifacts, Int(candidate_id), nothing)
	end
end

function _run_ctx_identity(candidate_id::Integer)
	c = RUN_CONTEXT[]
	(c === nothing || candidate_id <= 0) && return nothing
	return lock(c.estimator_lock) do
		identity = get(c.estimator_identities, Int(candidate_id), nothing)
		isnothing(identity) ? nothing : copy_estimator_identity(identity)
	end
end

function _run_ctx_register_noise_interpolants!(source::Symbol, interpolants::AbstractDict)
	c = RUN_CONTEXT[]
	(c === nothing || !c.capture_uq) && return nothing
	lock(c.estimator_lock) do
		c.uq_noise_interpolants[source] = interpolants
	end
	return nothing
end

function _run_ctx_noise_interpolants(source::Symbol = :agp_uq)
	c = RUN_CONTEXT[]
	c === nothing && return nothing
	return lock(c.estimator_lock) do
		get(c.uq_noise_interpolants, source, nothing)
	end
end

function _run_ctx_register_uq_influence!(candidate_id::Integer, artifact::UQInfluenceArtifact)
	c = RUN_CONTEXT[]
	(c === nothing || candidate_id <= 0) && return nothing
	lock(c.estimator_lock) do
		c.uq_influences[Int(candidate_id)] = artifact
	end
	return nothing
end

function _run_ctx_uq_influence(candidate_id::Integer)
	c = RUN_CONTEXT[]
	(c === nothing || candidate_id <= 0) && return nothing
	return lock(c.estimator_lock) do
		get(c.uq_influences, Int(candidate_id), nothing)
	end
end

function _run_ctx_lineage(identity::EstimatorIdentity)
	c = RUN_CONTEXT[]
	lineage = EstimatorIdentity[copy_estimator_identity(identity)]
	c === nothing && return lineage
	seen = Set{Int}([identity.candidate_id])
	queue = copy(identity.parent_candidate_ids)
	while !isempty(queue)
		candidate_id = popfirst!(queue)
		candidate_id in seen && continue
		push!(seen, candidate_id)
		parent = lock(c.estimator_lock) do
			get(c.estimator_identities, candidate_id, nothing)
		end
		isnothing(parent) && continue
		push!(lineage, copy_estimator_identity(parent))
		append!(queue, parent.parent_candidate_ids)
	end
	return lineage
end

"""
	_with_run_context(f; capture_timing=false, selection_recipe=nothing) -> (value, ctx)

Bind a fresh `RunContext` for the duration of `f()`; return `(f(), ctx)`. The
ctx object stays readable after the scope exits (it is an ordinary mutable
struct), which is how `with_estimation_timing` retrieves the timing breakdown.
"""
function _with_run_context(
	f::Function;
	capture_timing::Bool = false,
	selection_recipe::Union{Nothing, AbstractCampaignSelectionRecipe} = nothing,
)
	ctx = RunContext(; capture_timing, selection_recipe)
	value = Base.ScopedValues.with(f, RUN_CONTEXT => ctx)
	return value, ctx
end
