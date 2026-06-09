#
# Point selection is intentionally simple: the package uses the pick_points path
# below (point-hint + equidistant shooting indices). The older derivative-scoring
# machinery was archived 2026-06-09 to deprecated/pointpicker_scoring.jl
# (not part of the build) to cut core complexity.
#

function pick_points(vec, n, interpolants, point_hint = 0.5)
	if n == 1
		return min(max(1, round(Int, point_hint * length(vec))), length(vec))
	else
		if n == 2
			return [min(max(1, round(Int, point_hint * length(vec))), length(vec)), min(max(1, round(Int, (point_hint + 1 / 3) * length(vec))), length(vec))]
		else
			# For n>2 points, use equidistant shooting indices (warp=false to preserve legacy behavior)
			return compute_shooting_indices(n, length(vec); warp = false)
		end
	end
end
