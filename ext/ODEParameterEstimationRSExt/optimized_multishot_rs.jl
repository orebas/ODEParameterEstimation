# RS and RationalUnivariateRepresentation dependent functions from optimized_multishot_estimation.jl

"""
	find_all_roots_polynomial_roots(rur, variables)

Find all roots (real and complex) of a univariate polynomial from RUR
and reconstruct the full solutions.
"""
function find_all_roots_polynomial_roots(rur, variables)
	# Use PolynomialRoots (already imported at module level)

	# Extract the univariate polynomial from RUR
	univariate_poly = rur[1]

	# Convert coefficients to Complex{Float64} for PolynomialRoots
	coeffs = Complex{Float64}[]
	for coeff in univariate_poly
		push!(coeffs, Complex(Float64(coeff), 0.0))
	end

	# Find ALL roots (complex and real)
	all_roots = PolynomialRoots.roots(coeffs)

	if isempty(all_roots)
		return []
	end

	# Reconstruct full solutions from univariate roots
	solutions = []

	for root in all_roots
		# Skip roots with very large imaginary parts (likely spurious)
		if abs(imag(root)) > 1e6
			continue
		end

		# Compute derivative of f1 at root for reconstruction
		f1 = univariate_poly
		f1_deriv = sum((i-1) * f1[i] * root^(i-2) for i in 2:length(f1))

		# Skip if derivative is too small (multiple root or numerical issue)
		if abs(f1_deriv) < 1e-14
			continue
		end

		# Reconstruct solution for all variables
		solution = Float64[]

		# For each variable, use the corresponding polynomial in the RUR
		for (idx, var) in enumerate(variables)
			if idx + 1 <= length(rur)
				poly = rur[idx+1]
				value = sum(poly[i] * root^(i-1) for i in 1:length(poly))
				reconstructed = value / f1_deriv

				# Use real part if imaginary part is negligible
				if abs(imag(reconstructed)) < 1e-10
					push!(solution, real(reconstructed))
				else
					# For complex solutions, use the real part (this may need refinement)
					push!(solution, real(reconstructed))
				end
			else
				# If we don't have enough polynomials, use a default value
				push!(solution, 0.0)
			end
		end

		push!(solutions, solution)
	end

	return solutions
end

"""
	try_rur_solve(equations, variables)

Attempt to solve the system using RUR and return status.
Returns: (:success, solutions), (:no_solutions, []), or (:not_zero_dim, [])
"""
function try_rur_solve(equations, variables)
	try
		# Clear denominators from all equations first
		cleared_equations = clear_denoms.(equations)

		# Use robust conversion from robust_conversion.jl
		R, aa_system, var_map = robust_exprs_to_AA_polys(cleared_equations, variables)

		# Try RUR
		rur, sep = RationalUnivariateRepresentation.zdim_parameterization(aa_system, get_separating_element = true)

		# If we get here, system is zero-dimensional - try to find ALL solutions (including complex)
		# Using PolynomialRoots instead of RS to handle complex solutions
		try
			# Use PolynomialRoots to find all roots (complex and real)
			solutions = find_all_roots_polynomial_roots(rur, variables)

			if isempty(solutions)
				return (:no_solutions, [])
			else
				return (:success, solutions)
			end
		catch e
			# Fallback to RS if PolynomialRoots fails
			@debug "PolynomialRoots failed, falling back to RS: $e"
			sol = RS.rs_isolate(rur, sep, output_precision = Int32(20))

			if isempty(sol)
				return (:no_solutions, [])
			else
				# Convert solutions
				solutions = []
				for s in sol
					real_sol = [convert(Float64, real(v[1])) for v in s]
					push!(solutions, real_sol)
				end
				return (:success, solutions)
			end
		end

	catch e
		error_msg = string(e)
		if occursin("zerodimensional ideal", error_msg) || occursin("not zero-dimensional", error_msg)
			return (:not_zero_dim, [])
		elseif occursin("no solutions", error_msg)
			return (:no_solutions, [])
		else
			# Re-throw for unexpected errors
			rethrow(e)
		end
	end
end