
"""
	compute_derivative_score(interpolant, t, max_deriv=3)

Compute a score based on the magnitudes of derivatives at a point.
Higher derivatives with significant values indicate more dynamic behavior.
"""
function compute_derivative_score(interpolant, t, max_deriv = 3)
	score = 0.0
	for i in 1:max_deriv
		deriv = abs(nth_deriv_at(interpolant, i, t))
		# Weight higher derivatives less
		score += deriv / (2^i)
	end
	return score
end

"""
	find_local_extrema_score(interpolant, t, Δt=1e-3)

Compute a score indicating proximity to local extrema.
Returns higher scores for points closer to extrema.
"""
function find_local_extrema_score(interpolant, t, Δt = 1e-3)
	first_deriv = nth_deriv_at(interpolant, 1, t)
	if abs(first_deriv) < 1e-10  # Potential extremum
		second_deriv = nth_deriv_at(interpolant, 2, t)
		if abs(second_deriv) > 1e-10  # Confirm it's an extremum
			return 1.0
		end
	end
	return 0.0
end

"""
	compute_inflection_score(interpolant, t, Δt=1e-3)

Compute a score indicating proximity to inflection points.
Returns higher scores for points closer to inflection points.
"""
function compute_inflection_score(interpolant, t, Δt = 1e-3)
	second_deriv = nth_deriv_at(interpolant, 2, t)
	if abs(second_deriv) < 1e-10  # Potential inflection point
		third_deriv = nth_deriv_at(interpolant, 3, t)
		if abs(third_deriv) > 1e-10  # Confirm it's an inflection point
			return 1.0
		end
	end
	return 0.0
end

"""
	compute_variability_score(interpolant, t, window=0.1)

Compute a score based on the local variability around a point.
Higher scores indicate more variable regions.
"""
function compute_variability_score(interpolant, t, window = 0.1)
	try
		derivatives = [nth_deriv_at(interpolant, 1, t + δ) for δ in -window:window/10:window]
		return std(derivatives)
	catch
		return 0.0
	end
end

"""
	compute_point_interestingness(interpolants, t)

Compute an overall interestingness score for a point based on multiple criteria
across all interpolants.
"""
function compute_point_interestingness(interpolants, t)
	total_score = 0.0

	for interpolant in values(interpolants)
		# Combine different scoring components
		deriv_score = compute_derivative_score(interpolant, t)
		extrema_score = find_local_extrema_score(interpolant, t)
		inflection_score = compute_inflection_score(interpolant, t)
		variability_score = compute_variability_score(interpolant, t)

		# Weight and combine the scores
		point_score = deriv_score +
					  2.0 * extrema_score +
					  1.5 * inflection_score +
					  variability_score

		total_score += point_score
	end

	return total_score
end


function pick_points(vec, n, interpolants)
	if n == 1
		return fld(length(vec), 3)
	else
		if n == 2
			return [fld(length(vec), 3), fld(length(vec), 2) + 1]
		else
			# For n>2 points, return n equispaced points (excluding start and end)
			step = fld(length(vec) - 2, n + 1)  # Calculate spacing between points
			return [i for i in (step+1):step:(step*(n))]
		end
	end
end

"""
	pick_points(vec, n, interpolants)

Select n points from a vector, trying to pick the most interesting points based on
multiple criteria including extrema, inflection points, and areas of high variability.

# Arguments
- `vec`: Vector of time points
- `n`: Number of points to pick
- `interpolants`: Dictionary of interpolant functions for different variables

# Returns
- Vector of selected indices
"""
function pick_points_old(vec, n, interpolants)
	println("\nDEBUG [pick_points]: Starting point selection...")
	println("DEBUG [pick_points]: Number of points to pick: $n")
	println("DEBUG [pick_points]: Total points available: $(length(vec))")
	println("DEBUG [pick_points]: Number of interpolants: $(length(interpolants))")

	if n >= length(vec) - 2
		# Handle edge cases as before
		if (n == length(vec))
			println("DEBUG [pick_points]: Edge case - returning all points")
			return 1:n
		elseif (n == length(vec) - 1)
			println("DEBUG [pick_points]: Edge case - returning all but last point")
			return 1:(n-1)
		elseif (n == length(vec) - 2)
			println("DEBUG [pick_points]: Edge case - returning middle points")
			return 2:(n-1)
		end
	end

	# Compute interestingness scores for all points (except endpoints)
	scores = Float64[]
	println("\nDEBUG [pick_points]: Computing interestingness scores...")
	for i in 2:(length(vec)-1)
		score = compute_point_interestingness(interpolants, vec[i])
		push!(scores, score)
		if i % 100 == 0
			println("DEBUG [pick_points]: Processed $i points")
		end
	end

	println("\nDEBUG [pick_points]: Score statistics:")
	println("DEBUG [pick_points]: Min score: $(minimum(scores))")
	println("DEBUG [pick_points]: Max score: $(maximum(scores))")
	println("DEBUG [pick_points]: Mean score: $(mean(scores))")

	# Normalize scores
	max_score = maximum(scores)
	if max_score > 0
		scores ./= max_score
		println("DEBUG [pick_points]: Normalized scores")
	else
		println("DEBUG [pick_points]: Warning: All scores are zero")
	end

	# Find indices of n highest scoring points
	sorted_indices = sortperm(scores, rev = true)
	selected_indices = sorted_indices[1:min(n, length(sorted_indices))]

	# Add 1 to account for skipping first point in scoring
	final_indices = sort!(selected_indices .+ 1)
	println("\nDEBUG [pick_points]: Selected $(length(final_indices)) points")
	println("DEBUG [pick_points]: Selected time points: $(vec[final_indices])")

	return final_indices
end
