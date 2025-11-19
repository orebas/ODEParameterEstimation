# RS and RationalUnivariateRepresentation dependent functions from homotopy_continuation.jl

using SymbolicUtils

# Import zdim_parameterization without fully qualifying since we already have using RationalUnivariateRepresentation
const zdim_parameterization = RationalUnivariateRepresentation.zdim_parameterization

"""
	exprs_to_AA_polys(exprs, vars, digits; debug_aa = false)

Convert symbolic expressions to AbstractAlgebra polynomials.
"""
function exprs_to_AA_polys(exprs, vars, digits; debug_aa = false)
	# Create a polynomial ring over QQ, using the variable names

	M = Module()
	Base.eval(M, :(using AbstractAlgebra))
	#Base.eval(M, :(using Nemo))
	Base.eval(M, :(using RationalUnivariateRepresentation))
	Base.eval(M, :(using RS))

	var_names = string.(vars)
	# Create the polynomial ring with polynomial_ring function
	ring_command = "R, poly_vars = polynomial_ring(QQ, $var_names)"
	#approximation_command = "R(expr::Float64) = R(Nemo.rational_approx(expr, 1e-4))"
	result = Base.eval(M, Meta.parse(ring_command))
	ring_object = result[1]  # The ring is the first element
	poly_vars = result[2]  # The polynomial variables

	# Build substitution dictionary
	substitution_dict = Base.eval(M, :(Dict()))
	for (i, var) in enumerate(vars)
		substitution_dict[var] = poly_vars[i]
	end

	# Convert each expression to AA polynomial
	aa_polys = []
	for (i, expr) in enumerate(exprs)
		# Apply substitutions
		substituted_expr = substitute(expr, substitution_dict)
		# Convert to AA polynomial
		aa_poly = Symbolics.value(substituted_expr)
		if debug_aa
			println("[DEBUG-AA] Expression $i: $(Symbolics.value(expr))")
			println("[DEBUG-AA] After substitution: $aa_poly")
		end
		push!(aa_polys, aa_poly)
	end

	return ring_object, aa_polys
end

"""
	poly_evaluate(poly, x)

Evaluate a polynomial at a given point x.
"""
function poly_evaluate(poly, x)
	if poly isa AbstractVector
		value = 0.0 + 0.0im
		for (i, coeff) in enumerate(poly)
			value += Float64(coeff) * x^(i - 1)
		end
		return value
	else
		return evaluate(poly, x)
	end
end

"""
	evaluate_rur_subs(rur, v_val, vars)

Evaluate RUR substitutions to reconstruct full solution from univariate root.
"""
function evaluate_rur_subs(rur, v_val, vars)
	#println("\nDEBUG [evaluate_rur_subs]: Processing RUR substitutions")
	#println("Input root value: $v_val")

	# Get the first polynomial (f₁) and compute its derivative coefficients
	f1 = rur[1]
	if f1 isa AbstractVector
		f1_derivative_coeffs = [(i - 1) * f1[i] for i in 2:length(f1)]
	else
		error("Unsupported polynomial type for derivative")
	end

	# Evaluate derivative at root
	normalization = poly_evaluate(f1_derivative_coeffs, v_val)
	#println("Normalization factor (f₁'(x₀)): $normalization")

	# Create solution dictionary
	sol_dict = Dict{Symbol, Any}()

	# Instead of splitting vars into parameters and states by name, preserve the original order
	ordered_vars = vars  # FIX: Use the original ordering rather than reordering by filtering

	#println("\nDEBUG [evaluate_rur_subs]: Variable ordering:")
	#for (i, v) in enumerate(ordered_vars)
	#	println("$i: $v")
	#end

	# Process RUR substitutions (skip first polynomial which was used to find roots)
	for (i, u_poly) in enumerate(rur[2:end])
		if i <= length(ordered_vars)
			var = ordered_vars[i]
			u_val = poly_evaluate(u_poly, v_val)
			computed_val = u_val / normalization
			sol_dict[var] = computed_val
		end
	end

	#println("\nDEBUG [evaluate_rur_subs]: Solution verification:")
	#for (var, val) in sol_dict
	#	println("$var => $val")
	#end

	return sol_dict
end

"""
	solve_rur_complex(poly)

Solve a univariate polynomial for complex roots.
"""
function solve_rur_complex(poly)
	coeffs = isa(poly, AbstractVector) ? poly : coefficients(poly)
	# Make polynomial square-free first
	# This is a simplified version - ideally we'd use gcd with derivative like in your colleague's code
	complex_coeffs = Complex{Float64}[Float64(c) for c in coeffs]
	roots_found = PolynomialRoots.roots(complex_coeffs)
	return roots_found
end

"""
	solve_with_rs(poly_system, varlist; kwargs...)

Solve a polynomial system using Rational Univariate Representation.
"""
function solve_with_rs(poly_system, varlist;
	start_point = nothing,  # Not used but kept for interface consistency
	options = Dict(),
	_recursion_depth = 0, digits = 10)

	# Extract debug options with defaults
	debug_solver = get(options, :debug_solver, false)
	debug_cas_diagnostics = get(options, :debug_cas_diagnostics, false)
	debug_dimensional_analysis = get(options, :debug_dimensional_analysis, false)

	@debug "solve_with_rs: Starting with system:" equations=length(poly_system) variables=length(varlist) recursion_depth=_recursion_depth digits=digits start_point=start_point options=options
	if debug_solver || get(ENV, "ODEPE_DEEP_DEBUG", "false") == "true"
		println("solve_with_rs: System equations:")
		for eq in poly_system
			println("\t", eq)
		end
		println("Variables: ", varlist)
	end

	if _recursion_depth > 5
		@warn "solve_with_rs: Maximum recursion depth exceeded. System may have no solutions."
		return [], varlist, Dict(), varlist
	end

	# First rationalize the system and clear denominators
	rationalized_system = []
	for eq in poly_system
		rationalized = rationalize_expr(eq, 10, force_float_to_rational = true)
		cleared = clear_denoms(rationalized)
		push!(rationalized_system, cleared)
	end

	if debug_solver
		println("[DEBUG-SOLVER] Rationalized system:")
		for (i, eq) in enumerate(rationalized_system)
			println("  Eq$i: $eq")
		end
	end

	# Convert symbolic expressions to AA polynomials
	R, aa_system = exprs_to_AA_polys(rationalized_system, varlist, digits, debug_aa = false)

	# Round coefficients for numerical stability
	sys_toround = deepcopy(aa_system)
	sys_rounded = map(f -> map_coefficients(c -> rationalize(BigInt, round(BigFloat(c), digits = 5)), f), sys_toround)

	# Sanitize variable names for CAS systems (remove special characters like (t) or subscript notation)
	sanitized = [replace(string(v), r"[^\w]" => "_") for v in varlist]

	# Dimension diagnostics if requested
	if debug_dimensional_analysis || debug_solver
		println("\n[DEBUG-SOLVER] === Polynomial System Dimension Analysis ===")
		println("[DEBUG-SOLVER] System: $(length(aa_system)) equations in $(length(varlist)) variables")
		if length(aa_system) < length(varlist)
			println("[DEBUG-SOLVER] ⚠ Underdetermined: Fewer equations than variables")
			println("[DEBUG-SOLVER]   Expected dimension: >= $(length(varlist) - length(aa_system))")
		elseif length(aa_system) > length(varlist)
			println("[DEBUG-SOLVER] ⚠ Overdetermined: More equations than variables")
			println("[DEBUG-SOLVER]   System may be inconsistent")
		else
			println("[DEBUG-SOLVER] ✓ Square system: Equal equations and variables")
		end
	end

	# CAS-specific diagnostics (Oscar, Singular, Groebner.jl - code abbreviated for space)
	# [Previous CAS diagnostic code sections would go here if needed]

	# Compute RUR and get separating element
	if debug_solver
		println("\n[DEBUG-SOLVER] Computing RUR (Rational Univariate Representation)...")
	end
	try
		rur, sep = zdim_parameterization(aa_system, get_separating_element = true)

		# Find solutions
		output_precision = get(options, :output_precision, Int32(20))
		sol = RS.rs_isolate(rur, sep, output_precision = output_precision)

		# Convert solutions back to our format
		solutions = []
		for s in sol
			# Extract real solutions
			#display(s)
			real_sol = [convert(Float64, real(v[1])) for v in s]
			push!(solutions, real_sol)
		end
		@debug "RAW SOLVER SOLUTIONS from solve_with_rs" num_solutions=length(solutions) varlist=varlist solutions=solutions

		return solutions, varlist, Dict(), varlist
	catch e
		if isa(e, DomainError) && occursin("zerodimensional ideal", string(e))
			@warn "System is not zero-dimensional, needs reconstruction with higher derivative levels."

			# Try to extract dimension information from error message
			error_msg = string(e)
			dim_match = match(r"(\d+)-dimensional", error_msg)
			if dim_match !== nothing
				dim = parse(Int, dim_match[1])
				@warn "[DEBUG-ODEPE] System has dimension $dim (expected 0)"

				# Analyze which variables might be unconstrained
				if length(poly_system) == length(varlist)
					@warn "[DEBUG-ODEPE] Square system ($(length(poly_system))x$(length(varlist))) but $dim-dimensional"
					@warn "[DEBUG-ODEPE] This suggests $dim variables are algebraically unconstrained"

					# Try to identify which variables are likely free
					if dim <= 5  # Only for small dimensions
						@warn "[DEBUG-ODEPE] Analyzing variable constraints to identify free parameters..."

						# Count how many equations each variable appears in
						var_counts = Dict()
						for v in varlist
							count = 0
							for eq in poly_system
								if occursin(string(v), string(eq))
									count += 1
								end
							end
							var_counts[v] = count
						end

						# Variables that appear in few equations might be free
						sorted_vars = sort(collect(var_counts), by = x -> x[2])
						@warn "[DEBUG-ODEPE] Variables by equation count:"
						for (v, c) in sorted_vars[1:min(dim+1, end)]
							@warn "[DEBUG-ODEPE]   $v appears in $c equations"
						end
					end
				end
			end

			# Return special status indicating reconstruction is needed
			# Format: (status_symbol, empty_solutions, empty_dict, varlist)
			return :needs_reconstruction, varlist, Dict(), varlist
		else
			@warn "solve_with_rs failed: $e"
			return [], varlist, Dict(), varlist
		end
	end
end

"""
	solve_with_rs_old(poly_system, varlist; kwargs...)

Old version of solve_with_rs for compatibility.
"""
function solve_with_rs_old(poly_system, varlist;
						start_point = nothing,
						polish_solutions = true,
						debug = false,
						verify_solutions = true,
						is_augmented_system = false)  # New parameter to track if system was augmented

	if debug
		println("DEBUG [solve_with_rs]: Starting with system:")
		for eq in poly_system
			println("\t", eq)
		end
		println("Variables: ", varlist)
	end

	# Convert symbolic expressions to AA polynomials using existing infrastructure
	R, aa_system = exprs_to_AA_polys(poly_system, varlist, 10)  # Use default digits=10

	if debug
		println("DEBUG [solve_with_rs]: Abstract Algebra system:")
		for eq in aa_system
			println("\t", eq)
		end
	end

	# Round coefficients to improve numerical stability
	sys_toround = deepcopy(aa_system)
	sys_rounded = map(f -> map_coefficients(c -> rationalize(BigInt, round(BigFloat(c), digits = 5)), f), sys_toround)

	solutions = []

	# Try to compute RUR with fallback to adding a random linear equation
	try
		# Compute RUR and get separating element
		if debug
			println("DEBUG [solve_with_rs]: Computing RUR...")
		end

		rur, sep = zdim_parameterization(sys_rounded, get_separating_element = true)

		if debug
			println("DEBUG [solve_with_rs]: Got RUR, separating element: ", sep)
		end

		# Find solutions using PolynomialRoots instead of RS
		tosolve = rur[1]
		roots_found = solve_rur_complex(tosolve)

		if debug
			println("DEBUG [solve_with_rs]: Found roots: ", roots_found)
		end

		# Convert variables to symbols for RUR substitution
		var_symbols = [Symbol(v) for v in varlist]

		# Process solutions with more careful handling of the root
		for v_val in roots_found
			if debug
				println("DEBUG [solve_with_rs]: Processing root v_val = ", v_val)
			end

			sol_dict = evaluate_rur_subs(rur, v_val, var_symbols)

			# Extract solution values in original variable order
			sol_vector = []
			for v in varlist
				val = get(sol_dict, Symbol(v), nothing)
				if isnothing(val)
					# If this variable isn't in the RUR substitutions, check if it's the root variable
					if Symbol(v) == Symbol(sep) # Compare against the separating element found during RUR computation
						val = v_val
					else
						# For any other missing variables, use 0.0 as fallback
						val = 0.0
					end
				end
				push!(sol_vector, real(val)) # Store real part only
			end

			if debug
				println("DEBUG [solve_with_rs]: Solution vector: ", sol_vector)
			end

			push!(solutions, sol_vector)
		end
	catch e
		if debug
			println("DEBUG [solve_with_rs]: Caught exception: ", e)
		end

		if isa(e, DomainError) && occursin("zerodimensional ideal", string(e))
			if debug
				println("DEBUG [solve_with_rs_old]: System is not zero-dimensional, needs reconstruction")
			end

			# Return special status indicating reconstruction is needed
			# Random hyperplane addition has been disabled in favor of systematic derivative level increases
			return :needs_reconstruction, varlist, Dict(), varlist
		else
			if debug
				println("DEBUG [solve_with_rs_old]: RUR failed with error: ", e)
			end

			# If we're in an augmented system already, don't recurse further
			if is_augmented_system
				if debug
					println("DEBUG [solve_with_rs]: Already augmented, cannot recover")
				end
				return solutions, varlist, Dict(), varlist
			end

			# Add a random linear equation to make system zero-dimensional
			# This is a fallback strategy when the original system has free variables
			if debug
				println("DEBUG [solve_with_rs]: Adding random linear equation to reduce dimension")
			end

			# Generate random coefficients
			n = length(varlist)
			coeffs = rand(Float64, n)
			constant = rand(Float64)

			# Create the linear equation
			linear_eq = sum(coeffs[i] * varlist[i] for i in 1:n) - constant

			if debug
				println("DEBUG [solve_with_rs]: Added linear equation: ", linear_eq)
			end

			# Augment the system and solve again
			augmented_system = [poly_system; linear_eq]
			return solve_with_rs_old(augmented_system, varlist,
									  start_point = start_point,
									  polish_solutions = polish_solutions,
									  debug = debug,
									  verify_solutions = verify_solutions,
									  is_augmented_system = true)
		end
	end

	# Polish solutions using NLopt if requested
	if polish_solutions && !isempty(solutions) && @isdefined(solve_with_nlopt)
		if debug
			println("DEBUG [solve_with_rs]: Polishing solutions with NLopt...")
		end

		polished_solutions = []
		for sol in solutions
			# Use the solution as starting point
			start_pt = Float64.(sol)  # Ensure Float64

			if debug
				println("DEBUG [solve_with_rs]: Polishing solution: ", start_pt)
			end

			# Polish the solution
			polished_sol, _, _, _ = solve_with_nlopt(poly_system, varlist,
													start_point = start_pt,
													polish_only = true,
													options = Dict(:abstol => 1e-12, :reltol => 1e-12))

			# If polishing succeeded, add polished solution to list
			if !isempty(polished_sol)
				push!(polished_solutions, polished_sol[1])

				if debug
					println("DEBUG [solve_with_rs]: Polished solution: ", polished_sol[1])
				end
			else
				push!(polished_solutions, sol)

				if debug
					println("DEBUG [solve_with_rs]: Polishing failed, keeping original solution")
				end
			end
		end

		solutions = polished_solutions
	end

	if debug
		println("DEBUG [solve_with_rs]: Returning solutions: ", solutions)
	end

	return solutions, varlist, Dict(), varlist
end