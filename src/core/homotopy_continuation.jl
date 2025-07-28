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



function solve_with_nlopt_quick(poly_system, varlist;
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
	solver_opts = (abstol = 1e-3, reltol = 1e-3, maxiters = 50)

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




function solve_with_nlopt_testing(poly_system, varlist;
	start_point = nothing,
	optimizer   = nothing,  # default set below to FastShortcutNLLSPolyalg()
	polish_only = false,
	options     = Dict())

	# Minimal deps locally; assumes these packages are in your environment.
	#	using NonlinearSolve
	#	using Symbolics
	#	using ADTypes  # provides AutoForwardDiff()

	# Prepare
	prepared_system, mangled_varlist = (poly_system, varlist)
	m = length(prepared_system)
	n = length(mangled_varlist)

	# --- Fast compiled residual (prefer) with safe fallback -------------------
	compiled_residual! = nothing
	begin
		try
			# For a vector of expressions, build_function returns (oop, iip) functions.
			# We use the in-place version f!(res, x1, x2, ...).
			f_oop, f_ip = Symbolics.build_function(prepared_system, mangled_varlist;
				expression = Val(false))
			compiled_residual! = (res, u, p) -> (f_ip(res, u...); nothing)
		catch err
			@warn "Symbolics.build_function failed; falling back to substitute/value" err
			compiled_residual! = nothing
		end
	end

	function residual!(res, u, p)
		if compiled_residual! !== nothing
			compiled_residual!(res, u, p)
		else
			# Slow but robust fallback; keeps your original semantics.
			d = Dict(zip(mangled_varlist, u))
			@inbounds for i in 1:m
				# Avoid `real(...)` so autodiff can work; assume expressions are real-valued.
				res[i] = Symbolics.value(substitute(prepared_system[i], d))
			end
			nothing
		end
	end

	# Initial guess
	x0 = isnothing(start_point) ? randn(n) : copy(start_point)

	# Initial residual norm (for reporting)
	initial_residual = zeros(m)
	residual!(initial_residual, x0, nothing)
	initial_norm = norm(initial_residual)

	# Problem definition
	nf = NonlinearFunction(residual!; resid_prototype = zeros(m))  # size hint only. :contentReference[oaicite:2]{index=2}
	prob = NonlinearLeastSquaresProblem(nf, x0, nothing)

	# Tolerances
	solver_opts = polish_only ?
				  (abstol = 1e-12, reltol = 1e-12, maxiters = 1_000) :
				  (abstol = 1e-8, reltol = 1e-8, maxiters = 10_000)

	# Merge user options (convert Dict -> NamedTuple for keyword splatting)
	# Strip any keys we handle explicitly.
	user_pairs = collect(pairs(options))
	# nothing to strip currently
	user_named = (; user_pairs...)
	solver_opts = merge(solver_opts, user_named)

	# Algorithm: recommended polyalgorithm unless user supplied one.
	# FastShortcutNLLSPolyalg(): tries Gauss-Newton, falls back to LM/TrustRegion. :contentReference[oaicite:3]{index=3}
	alg = isnothing(optimizer) ? NonlinearSolve.FastShortcutNLLSPolyalg() : optimizer

	# Dense forward-mode AD is the safest default for problems of this size. :contentReference[oaicite:4]{index=4}
	ad_backend = AutoForwardDiff()

	# Solve
	sol = try
		NonlinearSolve.solve(prob, alg; autodiff = ad_backend, solver_opts...)
	catch e
		@warn "Error during optimization: $(e)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end

	# Post-process
	if SciMLBase.successful_retcode(sol)
		final_residual = zeros(m)
		residual!(final_residual, sol.u, nothing)
		final_norm = norm(final_residual)
		improvement = initial_norm - final_norm
		if improvement > 0
			println("Optimization improved residual by $(improvement) (from $(initial_norm) to $(final_norm))")
		else
			println("Optimization did not improve residual (initial: $(initial_norm), final: $(final_norm))")
		end
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
function round_floats(expr, digits)
	r = SymbolicUtils.Rewriters.Prewalk(x -> x isa Float64 ? round(x; digits = digits) : x)
	return r(expr)
end


function exprs_to_AA_polys(exprs, vars, digits)
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

	exprs = round_floats.(exprs, digits)
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
	# Get the number of variables
	n = length(varlist)

	# Generate random coefficients for the linear equation
	coeffs = rand(Float64, n)

	# Create the linear equation
	linear_equation = sum(coeffs[i] * varlist[i] for i in 1:n) - rand(Float64)

	# Add the new equation to the system
	new_poly_system = [poly_system; linear_equation]

	return new_poly_system
end

function solve_with_rs(poly_system, varlist;
	start_point = nothing,  # Not used but kept for interface consistency
	options = Dict(),
	_recursion_depth = 0, digits = 10)

	if _recursion_depth > 5
		@warn "solve_with_rs: Maximum recursion depth exceeded. System may have no solutions."
		return [], varlist, Dict(), varlist
	end

	try
		# Convert symbolic expressions to AA polynomials using existing infrastructure
		R, aa_system = exprs_to_AA_polys(poly_system, varlist, digits)

		#println("aa_system")
		#println(aa_system)
		#println("R")
		#println(R)
		# Compute RUR and get separating element
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
		return solutions, varlist, Dict(), varlist
	catch e
		if isa(e, DomainError) && occursin("zerodimensional ideal", string(e))
			@warn "System is not zero-dimensional, adding a random linear equation."
			modified_poly_system = add_random_linear_equation_direct(poly_system, varlist)
			return solve_with_rs(modified_poly_system, varlist, start_point = start_point, options = options, _recursion_depth = _recursion_depth+1)
		else
			@warn "solve_with_rs failed: $e"
			return [], varlist, Dict(), varlist
		end
	end
end


"""
	save_poly_system(filepath, poly_system, varlist;
					 param_map=nothing, pep=nothing, metadata=nothing)

Saves a polynomial system and its variables to a file as Julia code.

# Arguments
- `filepath`: Path to save the file.
- `poly_system`: The polynomial system (an array of symbolic expressions).
- `varlist`: The list of symbolic variables.
- `param_map` (optional): A dictionary mapping parameter names to their estimated values.
- `pep` (optional): The `ParameterEstimationProblem` object.
- `metadata` (optional): A dictionary for any other metadata to save.
"""
function save_poly_system(filepath, poly_system, varlist;
	param_map = nothing, pep = nothing, metadata = nothing)
	open(filepath, "w") do f
		# Write header
		write(f, "# Polynomial system saved on $(now())\n")
		if !isnothing(pep)
			write(f, "# Original problem: $(pep.name)\n")
		end
		write(f, "using Symbolics\n")
		write(f, "using StaticArrays\n\n")

		# Write metadata
		if !isnothing(metadata)
			write(f, "# Metadata\n")
			for (key, value) in metadata
				write(f, "# $key: $value\n")
			end
			write(f, "\n")
		end

		# Write varlist
		write(f, "# Variables\n")
		write(f, "varlist_str = \"\"\"\n$(join(varlist, "\n"))\n\"\"\"\n")
		write(f, "@variables ")
		for (i, var) in enumerate(varlist)
			write(f, string(var))
			if i < length(varlist)
				write(f, " ")
			end
		end
		write(f, "\n")
		write(f, "varlist = [$([Symbol(v) for v in varlist]...)]\n\n")


		# Write polynomial system
		write(f, "# Polynomial System\n")
		write(f, "poly_system = [\n")
		for (i, poly) in enumerate(poly_system)
			# Use repr to get a string representation that can be parsed back
			poly_str = repr(poly)
			write(f, "    $poly_str")
			if i < length(poly_system)
				write(f, ",\n")
			end
		end
		write(f, "\n]\n\n")

		# Write param_map if available
		if !isnothing(param_map)
			write(f, "# Parameter Map\n")
			write(f, "param_map = Dict(\n")
			for (param, val) in param_map
				write(f, "    Symbol(\"$param\") => $val,\n")
			end
			write(f, ")\n\n")
		end

		# Write PEP if available
		if !isnothing(pep)
			# This is a bit tricky, we might just save the name and key fields
			write(f, "# Original Problem Info\n")
			write(f, "problem_name = \"$(pep.name)\"\n")
			# You might need to reconstruct the PEP object manually if needed
		end
	end
end

"""
	load_poly_system(filepath)

Loads a polynomial system from a Julia source file.

# Arguments
- `filepath`: Path to the file to load.

# Returns
A tuple containing:
- `poly_system`: The loaded polynomial system.
- `varlist`: The list of variables.
"""
function load_poly_system(filepath)
	# The file is expected to define `poly_system` and `varlist`
	loaded_module = @eval Module() begin
		include($filepath)
		(poly_system, varlist)
	end
	return loaded_module
end



#=
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
	R, aa_system = exprs_to_AA_polys(poly_system, varlist)

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
=#
