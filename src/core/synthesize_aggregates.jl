# synthesize_aggregates.jl
#
# Inject extra "test" candidates into the polish pool by per-component aggregating
# the existing SP and MP candidates' parameters and ICs. Designed as a research
# probe with full provenance, NOT a sloppy-case fix.
#
# All aggregations are per-component (each parameter / state IC aggregated
# independently across the pool), not vector medoid (which would be in the input
# set by construction → redundant).
#
# Categories:
#   A — Global parameter-only aggregates × 3 groupings × 3 strategies = 9 candidates
#       (each requires resolve_states_with_fixed_params; cached) — Phase 2
#   B — Per-SP per-component aggregates of (params + states) × 2 strategies × n_sps
#       (no resolve needed — reuses post-backsolve t=0 ICs)
#   C — Per-SP-with-MP-anchored aggregates × 2 strategies × n_sps
#       (no resolve needed)
#   D — Cheap extras: per-interpolator median, interior-only median,
#       cross-source-spread weighted median (Phase 3, requires resolve)
#
# Cache for the resolve calls (Category A + most of D) lives below as
# `_SYNTH_RESOLVE_CACHE`; degenerate-value fallback bypasses it (Phase 4).
#
# Sidecar: artifacts/diagnostics/<model>/synthesis_log.csv records all
# synthesized candidates' lineage for post-hoc inspection.

# ─── Per-component aggregation primitives ──────────────────────────────────────

"""
    _aggregate_scalar(values::AbstractVector{<:Real}, strategy::Symbol) -> Float64

Apply `strategy` (`:median`, `:mean`, `:trim25_mean`) to a vector of scalar values.
Returns NaN if input is empty or all-NaN. `:trim25_mean` drops the top 12.5% and
bottom 12.5% by value, then averages the middle 75%.
"""
function _aggregate_scalar(values::AbstractVector{<:Real}, strategy::Symbol)
	finite_values = Float64[v for v in values if isfinite(v)]
	isempty(finite_values) && return NaN
	if strategy == :median
		return Statistics.median(finite_values)
	elseif strategy == :mean
		return Statistics.mean(finite_values)
	elseif strategy == :trim25_mean
		n = length(finite_values)
		if n < 4
			# Too few to trim — fall back to mean
			return Statistics.mean(finite_values)
		end
		sorted = sort(finite_values)
		drop_each_side = max(1, floor(Int, n / 8))  # 12.5% per tail
		keep = sorted[(drop_each_side + 1):(n - drop_each_side)]
		return isempty(keep) ? Statistics.median(finite_values) : Statistics.mean(keep)
	else
		error("unknown aggregation strategy: $strategy")
	end
end

"""
    _per_component_aggregate(dicts::AbstractVector, strategy::Symbol) -> OrderedDict

Given a vector of OrderedDicts {Num => Float64} all sharing the same key set,
return a new OrderedDict with `_aggregate_scalar(values, strategy)` applied
per key. The resulting dict is a frankenstein vector — each component aggregated
independently across the inputs. Skips keys where all values are non-finite.
"""
function _per_component_aggregate(dicts::AbstractVector, strategy::Symbol)
	out = OrderedDict{Num, Float64}()
	isempty(dicts) && return out
	# Use the first dict's keys as the canonical ordering
	for k in keys(first(dicts))
		vals = Float64[]
		for d in dicts
			haskey(d, k) || continue
			v = d[k]
			isfinite(v) && push!(vals, Float64(v))
		end
		isempty(vals) && continue
		out[k] = _aggregate_scalar(vals, strategy)
	end
	return out
end

# ─── Candidate-grouping helpers ────────────────────────────────────────────────

"""
    _is_sp_candidate(c) -> Bool

A "single-point" candidate has provenance.source_type ∈ (:single_point,) and
came from an algebraic SP solve (not a synthesized aggregate, not imported).
"""
function _is_sp_candidate(c)
	isnothing(c.provenance) && return false
	c.provenance.source_type == :single_point || return false
	return true
end

"""
    _is_mp_candidate(c) -> Bool
"""
function _is_mp_candidate(c)
	isnothing(c.provenance) && return false
	return c.provenance.source_type == :multipoint
end

"""
    _mp_anchor_sp(c) -> Union{Nothing, Int}

Returns the leftmost time-index of an MP candidate's combo, or nothing if not MP.
Per existing convention, MP candidates' ICs are anchored at this index.
"""
function _mp_anchor_sp(c)
	_is_mp_candidate(c) || return nothing
	idxs = c.provenance.multipoint_time_indices
	(isnothing(idxs) || isempty(idxs)) && return nothing
	return minimum(idxs)
end

# ─── Build a synthetic candidate from aggregated (params, states) ──────────────

"""
    _build_synth_candidate(params::OrderedDict, states::OrderedDict, t0::Real,
        n_total::Int, source_indices::Vector{Int}, strategy::Symbol,
        category_notes::Vector{Symbol}) -> ParameterEstimationResult

Construct a synthetic candidate with provenance fully tagged. Uses
`source_type = :synthesized_aggregate` and the supplied strategy + source indices.
The candidate is NOT polished here; downstream polish runs on it like any other.
"""
function _build_synth_candidate(
	params::OrderedDict{Num, Float64},
	states::OrderedDict{Num, Float64},
	t0::Real,
	n_total::Int,
	source_indices::Vector{Int},
	strategy::Symbol,
	category_notes::Vector{Symbol},
)
	result = ParameterEstimationResult(
		params,
		states,
		Float64(t0),
		nothing,                          # err — filled in downstream
		nothing,                          # return_code
		n_total,
		Float64(t0),
		OrderedDict{Num, Float64}(),     # known/auxiliary states
		Set{Num}(),                       # all_unidentifiable
		nothing,                          # ode_solution
	)
	# Note: interpolator_source is intentionally `nothing` for synthesized candidates.
	# Downstream consumers (consensus_estimation, synthesized_finalizer) use
	# `_consensus_source_symbol` which falls back to `default_source` when this is nil
	# — synthesized candidates aren't tied to any single interpolator's interpolant
	# cache. The :synthesized_aggregate marker lives on `source_type` instead.
	result.provenance = ResultProvenance(
		primary_method = :algebraic,
		interpolator_source = nothing,
		source_type = :synthesized_aggregate,
		aggregation_strategy = strategy,
		aggregation_source_indices = source_indices,
		notes = vcat([:synthesized_aggregate], category_notes),
		polish_applied = false,
	)
	sync_result_contract!(result)
	return result
end

# ─── Category B/C: per-SP full aggregate (params + states, no resolve) ─────────

"""
    _synthesize_per_sp_full_aggregate(PEP, candidates_for_sp::Vector,
        sp_idx::Int, strategy::Symbol, source_indices::Vector{Int};
        with_mp::Bool) -> Union{Nothing, ParameterEstimationResult}

Aggregate (params, t=0 state ICs) per-component across `candidates_for_sp` using
`strategy`. Build a synthetic candidate. Returns nothing when fewer than 2
inputs (median/trim of 1 == that 1, redundant).
"""
function _synthesize_per_sp_full_aggregate(
	PEP, candidates_for_sp::Vector, sp_idx::Int, strategy::Symbol,
	source_indices::Vector{Int}; with_mp::Bool,
)
	length(candidates_for_sp) < 2 && return nothing
	param_dicts = OrderedDict{Num, Float64}[c.parameters for c in candidates_for_sp]
	state_dicts = OrderedDict{Num, Float64}[c.states for c in candidates_for_sp]
	agg_params = _per_component_aggregate(param_dicts, strategy)
	agg_states = _per_component_aggregate(state_dicts, strategy)
	(isempty(agg_params) || isempty(agg_states)) && return nothing
	t_vec = PEP.data_sample["t"]
	cat_notes = with_mp ?
		Symbol[:per_sp_full_with_mp, Symbol("sp_$sp_idx")] :
		Symbol[:per_sp_full, Symbol("sp_$sp_idx")]
	return _build_synth_candidate(
		agg_params, agg_states,
		Float64(t_vec[1]),
		length(t_vec),
		source_indices,
		strategy,
		cat_notes,
	)
end

# ─── Sidecar CSV writer ────────────────────────────────────────────────────────

"""
    _synthesis_sidecar_path(PEP) -> String

Per-run sidecar location. Returns "" if no model name available.
"""
function _synthesis_sidecar_path(PEP)
	name = string(PEP.name)
	isempty(name) && return ""
	return joinpath("artifacts", "diagnostics", name, "synthesis_log.csv")
end

"""
    _write_synthesis_sidecar(PEP, synth_candidates, source_pool)

Write a CSV log of every synthesized candidate's lineage. One row per candidate.
Columns: synth_idx, category, strategy, source_indices, params (per-name),
states (per-name), err_pre_polish (pre-pool-eval; usually nothing).
"""
function _write_synthesis_sidecar(PEP, synth_candidates, source_pool)
	path = _synthesis_sidecar_path(PEP)
	isempty(path) && return nothing
	mkpath(dirname(path))
	# Get param + state names from the first synth candidate
	isempty(synth_candidates) && return nothing
	pnames = collect(keys(first(synth_candidates).parameters))
	snames = collect(keys(first(synth_candidates).states))
	open(path, "w") do io
		# Header
		header_parts = String["synth_idx", "category", "strategy", "source_indices"]
		append!(header_parts, ["param_" * string(p) for p in pnames])
		append!(header_parts, ["state_" * string(s) for s in snames])
		push!(header_parts, "err")
		println(io, join(header_parts, ","))
		for (k, c) in enumerate(synth_candidates)
			cat_notes = filter(n -> n != :synthesized_aggregate, c.provenance.notes)
			cat_str = isempty(cat_notes) ? "?" : string(first(cat_notes))
			src_str = "[" * join(c.provenance.aggregation_source_indices, ";") * "]"
			row_parts = String[
				string(k),
				cat_str,
				string(c.provenance.aggregation_strategy),
				src_str,
			]
			for p in pnames
				v = get(c.parameters, p, NaN)
				push!(row_parts, isfinite(v) ? string(v) : "NaN")
			end
			for s in snames
				v = get(c.states, s, NaN)
				push!(row_parts, isfinite(v) ? string(v) : "NaN")
			end
			err_str = isnothing(c.err) ? "" : (isfinite(c.err) ? string(c.err) : "Inf")
			push!(row_parts, err_str)
			println(io, join(row_parts, ","))
		end
	end
	return path
end

# ─── Loss evaluation (matches sensitivity_seeds.jl pattern) ────────────────────

"""
    _evaluate_candidate_loss!(candidate, polish_ctx)

Compute and set `candidate.err` via the polish-context loss closure.
Mirrors the per-candidate evaluation in `sensitivity_seeds.jl` so that
downstream consumers (cluster, branch consensus, etc.) see a finite Float64
err on every synthesized candidate. Leaves `err` as nothing if evaluation
fails or returns non-finite.
"""
function _evaluate_candidate_loss!(candidate, polish_ctx)
	try
		p_external = _candidate_to_external_vector(candidate, polish_ctx)
		any(!isfinite, p_external) && return
		if !isnothing(polish_ctx.lb) && !isnothing(polish_ctx.ub)
			p_external = clamp.(p_external, polish_ctx.lb, polish_ctx.ub)
		end
		p_internal = _polish_external_to_internal(
			p_external, polish_ctx.coordinate_transforms, polish_ctx.coordinate_shifts,
		)
		loss = Float64(polish_ctx.optf.f(p_internal, nothing))
		if isfinite(loss)
			candidate.err = loss
			if !isnothing(candidate.provenance)
				candidate.provenance.pre_polish_error = loss
				candidate.provenance.post_polish_error = loss
			end
		end
	catch
		# Leave err as nothing; downstream cluster tolerates this.
	end
	return
end

# ─── Main entry point ──────────────────────────────────────────────────────────

"""
    _maybe_synthesize_aggregate_candidates(PEP, solved_res, setup_data, opts;
        interpolant_cache=nothing) -> Vector{ParameterEstimationResult}

Inject per-component aggregate "test" candidates into the pool. Returns a
vector containing the original `solved_res` entries plus all synthesized
candidates. Synthesized candidates carry `source_type = :synthesized_aggregate`
plus strategy + source-indices fields.

Each synthesized candidate's `err` is evaluated via the polish-context loss
closure (so downstream cluster/branch-consensus paths see a finite Float64
err and don't trip on `nothing`).

Categories implemented:
  B — Per-SP aggregate of (params + states), 2 strategies × n_sps
  C — Same as B but including MP-anchored-here candidates per SP
  (Categories A and D added in Phases 2-3.)
"""
function _maybe_synthesize_aggregate_candidates(
	PEP, solved_res::Vector, setup_data, opts::EstimationOptions;
	interpolant_cache = nothing,
)
	!opts.synthesize_aggregate_candidates && return solved_res
	isempty(solved_res) && return solved_res

	new_candidates = ParameterEstimationResult[]

	# ── Category B & C: per-SP aggregates (no resolve) ───────────────────────
	# Group SP candidates by source_shooting_index
	sp_groups = Dict{Int, Vector{Tuple{Int, Any}}}()  # sp_idx => [(pool_idx, candidate), ...]
	for (i, c) in enumerate(solved_res)
		_is_sp_candidate(c) || continue
		sp_idx = c.provenance.source_shooting_index
		isnothing(sp_idx) && continue
		push!(get!(sp_groups, sp_idx, Tuple{Int, Any}[]), (i, c))
	end
	# Group MP candidates by their leftmost time index (anchor SP)
	mp_groups = Dict{Int, Vector{Tuple{Int, Any}}}()
	for (i, c) in enumerate(solved_res)
		anchor = _mp_anchor_sp(c)
		isnothing(anchor) && continue
		push!(get!(mp_groups, anchor, Tuple{Int, Any}[]), (i, c))
	end

	# Category B: per-SP, SP-only
	for (sp_idx, entries) in sp_groups
		length(entries) < 2 && continue
		candidates_for_sp = [e[2] for e in entries]
		source_indices = [e[1] for e in entries]
		for strategy in (:median, :trim25_mean)
			cand = try
				_synthesize_per_sp_full_aggregate(
					PEP, candidates_for_sp, sp_idx, strategy, source_indices;
					with_mp = false,
				)
			catch err
				@warn "[SYNTH-B] sp=$sp_idx strategy=$strategy failed" exception = err
				nothing
			end
			!isnothing(cand) && push!(new_candidates, cand)
		end
	end

	# Category C: per-SP, SP + MP-anchored-here
	all_anchor_sps = union(keys(sp_groups), keys(mp_groups))
	for sp_idx in all_anchor_sps
		sp_entries = get(sp_groups, sp_idx, Tuple{Int, Any}[])
		mp_entries = get(mp_groups, sp_idx, Tuple{Int, Any}[])
		# Skip when there's no MP contribution at this anchor — would duplicate Category B
		isempty(mp_entries) && continue
		combined = vcat(sp_entries, mp_entries)
		length(combined) < 2 && continue
		candidates_for_sp = [e[2] for e in combined]
		source_indices = [e[1] for e in combined]
		for strategy in (:median, :trim25_mean)
			cand = try
				_synthesize_per_sp_full_aggregate(
					PEP, candidates_for_sp, sp_idx, strategy, source_indices;
					with_mp = true,
				)
			catch err
				@warn "[SYNTH-C] sp=$sp_idx strategy=$strategy failed" exception = err
				nothing
			end
			!isnothing(cand) && push!(new_candidates, cand)
		end
	end

	# Evaluate each new candidate's err via polish-context loss closure.
	# This mirrors sensitivity_seeds.jl and ensures downstream consumers
	# (branch consensus, tryhard finalists) see a finite Float64 err rather
	# than the candidate's initial `nothing`.
	if !isempty(new_candidates)
		try
			polish_ctx = _build_polish_context(PEP; opts = opts)
			for c in new_candidates
				_evaluate_candidate_loss!(c, polish_ctx)
			end
		catch err
			@warn "[SYNTH] loss evaluation failed; candidates retain err=nothing (non-fatal)" exception = err
		end
	end

	# Sidecar log
	if !isempty(new_candidates)
		try
			_write_synthesis_sidecar(PEP, new_candidates, solved_res)
		catch err
			@warn "[SYNTH] sidecar write failed (non-fatal)" exception = err
		end
	end

	if !opts.nooutput && !isempty(new_candidates)
		println("[Synthesize aggregates] $(length(solved_res)) → $(length(solved_res) + length(new_candidates)) candidates " *
			"(B/C: $(length(new_candidates)))")
	end

	return vcat(solved_res, new_candidates)
end
