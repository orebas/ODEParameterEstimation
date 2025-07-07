"""
	solve_with_nlopt(poly_system, varlist; 
					start_point=nothing,
					optimizer=BFGS(),
					polish_only=false,
					options=Dict())

Solves a polynomial system using traditional nonlinear optimization methods.
Can be used either as a standalone solver or to polish solutions from other methods.

# Arguments
- `poly_system`: System of polynomial equations to solve
- `varlist`: List of variables in the system
- `start_point`: Optional starting point. If not provided, random initialization is used
- `optimizer`: The optimization algorithm to use (default: BFGS)
- `polish_only`: If true, assumes start_point is close to solution and uses more local methods
- `options`: Dictionary of additional options for the optimizer

# Returns
- `solutions`: Array of solutions found
- `hc_variables`: Variables in HomotopyContinuation format
"""
function solve_with_nlopt(poly_system, varlist;
	start_point = nothing,
	optimizer = NonlinearSolve.LevenbergMarquardt(),
	polish_only = false,
	options = Dict())

	# Prepare system for optimization
	prepared_system, mangled_varlist = (poly_system, varlist)

	# Define residual function for NonlinearLeastSquares
	function residual!(res, u, p)
		for (i, eq) in enumerate(prepared_system)
			res[i] = real(Symbolics.value(substitute(eq, Dict(zip(mangled_varlist, u)))))
		end
	end

	# Set up optimization problem
	n = length(varlist)
	m = length(prepared_system)  # Number of equations
	x0 = if isnothing(start_point)
		randn(n)  # Random initialization if no start point provided
	else
		start_point
	end

	# Calculate initial residual
	initial_residual = zeros(m)
	residual!(initial_residual, x0, nothing)
	initial_norm = norm(initial_residual)

	# Create NonlinearLeastSquaresProblem
	prob = NonlinearLeastSquaresProblem(
		NonlinearFunction(residual!, resid_prototype = zeros(m)),
		x0,
		nothing;  # no parameters needed
	)

	# Set solver options based on polish_only
	solver_opts = if polish_only
		(abstol = 1e-12, reltol = 1e-12, maxiters = 1000)
	else
		(abstol = 1e-8, reltol = 1e-8, maxiters = 10000)
	end

	# Merge with user options
	solver_opts = merge(solver_opts, options)

	# Solve the problem with exception handling
	sol = try
		NonlinearSolve.solve(prob, optimizer; solver_opts...)
	catch e
		@warn "Error during optimization: $(e)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end

	# Check if solution is valid
	if SciMLBase.successful_retcode(sol)
		# Calculate final residual
		final_residual = zeros(m)
		residual!(final_residual, sol.u, nothing)
		final_norm = norm(final_residual)

		improvement = initial_norm - final_norm
		if improvement > 0
			println("Optimization improved residual by $(improvement) (from $(initial_norm) to $(final_norm))")
		else
			println("Optimization did not improve residual (initial: $(initial_norm), final: $(final_norm))")
		end

		# Return all four expected values: solutions, variables, trivial_dict, trimmed_varlist
		return [sol.u], mangled_varlist, Dict(), mangled_varlist
	else
		@warn "Optimization did not converge. RetCode: $(sol.retcode)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end
end











"""
	exprs_to_AA_polys(exprs, vars)

Convert each symbolic expression in `exprs` into a polynomial in an
AbstractAlgebra polynomial ring in the variables `vars`. This returns
both the ring `R` and the vector of polynomials in `R`.
"""
function exprs_to_AA_polys(exprs, vars)
	# Create a polynomial ring over QQ, using the variable names

	M = Module()
	Base.eval(M, :(using AbstractAlgebra))
	#Base.eval(M, :(using Nemo))
	#	Base.eval(M, :(using RationalUnivariateRepresentation))
	#	Base.eval(M, :(using RS))

	var_names = string.(vars)
	ring_command = "R = @polynomial_ring(QQ, $var_names)"
	#approximation_command = "R(expr::Float64) = R(Nemo.rational_approx(expr, 1e-4))"
	ring_object = Base.eval(M, Meta.parse(ring_command))
	#println(temp)
	#Base.eval(M, Meta.parse(approximation_command))


	a = string.(exprs)
	AA_polys = []
	for expr in exprs
		push!(AA_polys, Base.eval(M, Meta.parse(string(expr))))
	end
	return ring_object, AA_polys

end





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

function evaluate_rur_subs(rur, v_val, vars)
	println("\nDEBUG [evaluate_rur_subs]: Processing RUR substitutions")
	println("Input root value: $v_val")

	# Get the first polynomial (f₁) and compute its derivative coefficients
	f1 = rur[1]
	if f1 isa AbstractVector
		f1_derivative_coeffs = [(i - 1) * f1[i] for i in 2:length(f1)]
	else
		error("Unsupported polynomial type for derivative")
	end

	# Evaluate derivative at root
	normalization = poly_evaluate(f1_derivative_coeffs, v_val)
	println("Normalization factor (f₁'(x₀)): $normalization")

	# Create solution dictionary
	sol_dict = Dict{Symbol, Any}()

	# Instead of splitting vars into parameters and states by name, preserve the original order
	ordered_vars = vars  # FIX: Use the original ordering rather than reordering by filtering

	println("\nDEBUG [evaluate_rur_subs]: Variable ordering:")
	for (i, v) in enumerate(ordered_vars)
		println("$i: $v")
	end

	# Process RUR substitutions (skip first polynomial which was used to find roots)
	for (i, u_poly) in enumerate(rur[2:end])
		if i <= length(ordered_vars)
			var = ordered_vars[i]
			u_val = poly_evaluate(u_poly, v_val)
			computed_val = u_val / normalization
			sol_dict[var] = computed_val
		end
	end

	println("\nDEBUG [evaluate_rur_subs]: Solution verification:")
	for (var, val) in sol_dict
		println("$var => $val")
	end

	return sol_dict
end

function solve_rur_complex(poly)
	coeffs = isa(poly, AbstractVector) ? poly : coefficients(poly)
	# Make polynomial square-free first
	# This is a simplified version - ideally we'd use gcd with derivative like in your colleague's code
	complex_coeffs = Complex{Float64}[Float64(c) for c in coeffs]
	roots_found = PolynomialRoots.roots(complex_coeffs)
	return roots_found
end

"""
	add_random_linear_equation_direct(poly_system, varlist)

Returns a modified polynomial system with an additional random linear equation.
This tries to lower the dimension by 1, hopefully making the solution set finite.

# Arguments
- `poly_system`: The system of polynomial equations
- `varlist`: List of variables in the system

# Returns
- A new polynomial system with an additional random linear equation
"""
function add_random_linear_equation_direct(poly_system, varlist)
	# Generate random coefficients for each variable
	coeffs = randn(length(varlist))
	c = randn()

	# Create a linear equation: sum(coeffs[i] * varlist[i]) + c
	eq = sum(coeffs[i] * varlist[i] for i in 1:length(varlist)) + c

	# Return the original system with the new equation appended
	return vcat(poly_system, [eq])
end

function solve_with_rs(poly_system, varlist;
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
	R, aa_system = exprs_to_AA_polys(poly_system, varlist)

	if debug
		println("DEBUG [solve_with_rs]: Abstract Algebra system:")
		for eq in aa_system
			println("\t", eq)
		end
	end

	# Round coefficients to improve numerical stability
	sys_toround = deepcopy(aa_system)
	sys_rounded = map(f -> map_coefficients(c -> rationalize(BigInt, round(BigFloat(c), digits = 8)), f), sys_toround)

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
				println("DEBUG [solve_with_rs]: Zero-dimensional ideal error, adding random linear equation")
			end

			# Add a random linear equation directly to make the system zero-dimensional
			modified_poly_system = add_random_linear_equation_direct(poly_system, varlist)

			if debug
				println("DEBUG [solve_with_rs]: Added random linear equation, new system size: ", length(modified_poly_system))
			end

			# Recursive call with the modified system
			return solve_with_rs(modified_poly_system, varlist,
				start_point = start_point,
				polish_solutions = polish_solutions,
				debug = debug,
				verify_solutions = verify_solutions,
				is_augmented_system = true)  # Mark that this is an augmented system
		else
			if debug
				println("DEBUG [solve_with_rs]: Unhandled exception: ", e)
				println("DEBUG [solve_with_rs]: Solution method failed, no fallback available")
			end
			# Return empty solutions since the method failed
			return [], varlist, Dict(), varlist
		end
	end

	# Verify all found solutions against the original system
	if verify_solutions && !isempty(solutions)
		verified_solutions = []
		for sol in solutions
			all_valid = true

			# Determine which equations to verify against
			verification_system = if is_augmented_system
				# If we know this is an augmented system, only verify against original equations
				# The last equation is the random one we added
				poly_system[1:end-1]
			else
				poly_system
			end

			for eq in verification_system
				subst_dict = Dict([v => sol[i] for (i, v) in enumerate(varlist)])
				residual = abs(Symbolics.value(substitute(eq, subst_dict)))

				if debug
					println("DEBUG [solve_with_rs]: For solution ", sol)
					println("\tEquation: ", eq)
					println("\tResidual: ", residual)
				end

				if residual > 1e-8
					all_valid = false
					break
				end
			end

			if all_valid
				push!(verified_solutions, sol)
			else
				if debug
					println("DEBUG [solve_with_rs]: Solution failed verification: ", sol)
				end
			end
		end

		solutions = verified_solutions
	end

	# Polish solutions if requested
	if polish_solutions && !isempty(solutions)
		polished_solutions = []
		for sol in solutions
			# Extract real part as starting point for polishing
			start_pt = real.(sol)

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
		println("DEBUG [solve_with_rs]: Final solutions: ", solutions)
	end

	return solutions, varlist, Dict(), varlist
end



function solve_with_rs_old(poly_system, varlist;
	start_point = nothing,  # Not used but kept for interface consistency
	polish_solutions = true)

	#try
	# Convert symbolic expressions to AA polynomials using existing infrastructure
	R, aa_system = exprs_to_AA_polys(poly_system, varlist)

	println("aa_system")
	println(aa_system)
	println("R")
	println(R)
	# Compute RUR and get separating element
	rur, sep = zdim_parameterization(aa_system, get_separating_element = true)

	# Find solutions
	output_precision = Int32(20)
	sol = # RS.rs_isolate(rur, sep, output_precision = output_precision)

	# Convert solutions back to our format
	solutions = []
	println(sol)
	for s in sol
		# Extract real solutions
		#println(s)
		real_sol = [convert(Float64, real(v[1])) for v in s]
		push!(solutions, real_sol)
	end




	# Polish solutions if requested
	if polish_solutions && !isempty(solutions)
		polished_solutions = []
		for sol in solutions
			# Extract real part as starting point for polishing
			start_point = real.(sol)
			# Polish the solution
			polished_sol, _, _, _ = solve_with_nlopt(poly_system, varlist,
				start_point = start_point,
				polish_only = true,
				options = Dict(:abstol => 1e-12, :reltol => 1e-12))
			# If polishing succeeded, use polished solution, otherwise keep original
			if !isempty(polished_sol)
				push!(polished_solutions, polished_sol[1])
			else
				push!(polished_solutions, sol)
			end
		end
		solutions = polished_solutions
	end


	#return solutions, varlist, Dict(), varlist
	return solutions, varlist, Dict(), varlist
end