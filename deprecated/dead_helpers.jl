# Archived 2026-06-09 from src/core/parameter_estimation_helpers.jl — NOT part of the build.
# Two unreferenced helpers: get_next_deriv_increment (iterative derivative-level
# increment selection, never wired up) and record_representative_assignment!
# (a ResultProvenance variant of the live apply_representative_assignment!).
# Reference only; reference package types ResultProvenance etc.
# ============================================================================

"""
	get_next_deriv_increment(current_deriv_level, attempted_increments; max_deriv_level=10)

Determine which observable's derivative level to increment next.

# Arguments
- `current_deriv_level`: Dict mapping observable indices to current derivative levels
- `attempted_increments`: Set of previously attempted (observable_index, new_level) pairs
- `max_deriv_level`: Maximum allowed derivative level (default: 10)

# Returns
- Tuple (observable_index, new_level) or nothing if no valid increment exists
"""
function get_next_deriv_increment(current_deriv_level, attempted_increments; max_deriv_level = 10)
	# TODO: max_deriv_level is a magic number - should be moved to config options

	# Generate all possible valid next increments
	candidates = []
	for (obs_idx, level) in current_deriv_level
		new_level = level + 1
		if new_level <= max_deriv_level && !((obs_idx, new_level) in attempted_increments)
			push!(candidates, (obs_idx, new_level))
		end
	end

	if isempty(candidates)
		return nothing
	end

	# Sort candidates to ensure deterministic selection.
	# Sort by new level first (prefer lowest), then by observable index.
	sort!(candidates, by = x -> (x[2], x[1]))

	return first(candidates)
end

function record_representative_assignment!(
	provenance::ResultProvenance,
	var,
	kind::Symbol,
	all_unidentifiable,
)
	if !is_structurally_unidentifiable(var, all_unidentifiable)
		return nothing
	end

	value = representative_completion_value(kind)
	provenance.representative_assignments[var] = value
	note_provenance!(provenance, :representative_completion)
	return value
end
