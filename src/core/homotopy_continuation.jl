
"""
	handle_simple_substitutions(eqns, varlist)

Look for equations like a-5.5 and replace a with 5.5.

# Arguments
- `eqns`: Equations to process
- `varlist`: List of variables

# Returns
- Tuple containing filtered equations, reduced variable list, trivial variables, and trivial dictionary
"""
function handle_simple_substitutions(eqns, varlist)
	trivial_dict = Dict()
	filtered_eqns = typeof(eqns)()
	trivial_vars = []
	for i in eqns
		g = Symbolics.get_variables(i)
		if (length(g) == 1 && Symbolics.degree(i) == 1)
			thisvar = g[1]
			td = (polynomial_coeffs(i, (thisvar,)))[1]
			if (1 in Set(keys(td)))
				thisvarvalue = (-td[1] / td[thisvar])
				trivial_dict[thisvar] = thisvarvalue
				push!(trivial_vars, thisvar)
			else
				thisvarvalue = 0
				trivial_dict[thisvar] = thisvarvalue
				push!(trivial_vars, thisvar)
			end
		else
			push!(filtered_eqns, i)
		end
	end
	reduced_varlist = filter(x -> !(x in Set(trivial_vars)), varlist)
	filtered_eqns = Symbolics.substitute.(filtered_eqns, Ref(trivial_dict))
	return filtered_eqns, reduced_varlist, trivial_vars, trivial_dict
end





########Below code is largely untested and hard to test.
"""
	add_random_linear_equation(F::System)

Returns a new system which is F plus a random linear equation in F's variables.
This tries to lower the dimension by 1, hopefully making the solution set finite.

# Arguments
- `F`: The HomotopyContinuation.System to augment

# Returns
- A new System with an additional random linear equation
"""
function add_random_linear_equation(F::HomotopyContinuation.System)
	vars = HomotopyContinuation.variables(F)
	coeffs = randn(length(vars))
	c = randn()
	eq = sum(coeffs[i] * vars[i] for i in 1:length(vars)) + c
	return HomotopyContinuation.System(
		vcat(expressions(F), eq),
		vars,
		parameters = HomotopyContinuation.parameters(F),
	)
end


"""
	squarify_by_trashing(poly_system, varlist, rtol = 1e-12)

Make a polynomial system square by removing equations.

# Arguments
- `poly_system`: Polynomial system to squarify
- `varlist`: List of variables
- `rtol`: Relative tolerance (default: 1e-12)

# Returns
- Tuple containing the new system, variable list, and trashed equations
"""
function squarify_by_trashing(poly_system, varlist, rtol = 1e-12)
	mat = ModelingToolkit.jacobian(poly_system, varlist)
	vsubst = Dict([p => rand(Float64) for p in varlist])
	numerical_mat = Matrix{Float64}(Symbolics.value.((substitute.(mat, Ref(vsubst)))))
	target_rank = rank(numerical_mat, rtol = rtol)
	currentlist = 1:length(poly_system)
	trashlist = []
	keep_looking = true
	while (keep_looking)
		improvement_found = false
		for j in currentlist
			newlist = filter(x -> x != j, currentlist)
			jac_view = view(numerical_mat, newlist, :)
			rank2 = rank(jac_view, rtol = rtol)
			if (rank2 == target_rank)
				improvement_found = true
				currentlist = newlist
				push!(trashlist, j)
				break
			end
		end
		keep_looking = improvement_found
	end
	new_system = [poly_system[i] for i in currentlist]
	trash_system = [poly_system[i] for i in trashlist]

	#println("we trash these: (line 708)")
	#display(trash_system)

	return new_system, varlist, trash_system
end







"""
	find_start_solutions(system, tracking_system, param_final; max_attempts=500, min_attempts=10)

Finds starting solutions for monodromy solving by attempting to find and track solution pairs.

# Arguments
- `system`: The system to find start pairs for
- `tracking_system`: The system to solve with
- `param_final`: Final parameter values
- `max_attempts`: Maximum number of attempts to find start pairs
- `min_attempts`: Minimum number of attempts before giving up

# Returns
- `start_pairs`: Array of starting solutions
"""
function find_start_solutions(system, tracking_system, param_final; max_attempts = 50, min_attempts = 10)
	attempt_count = 0
	start_pairs = []

	#display(system)

	while (attempt_count < max_attempts && (attempt_count < min_attempts || isempty(start_pairs)))
		test_point, test_params = HomotopyContinuation.find_start_pair(tracking_system)
		#println("\n=== Start Pair Information ===")
		#println("Test point: ", test_point)
		#println("Test parameters: ", test_params)

		# Verify that test_point, test_params form a valid start pair
		#try
		#	residual = HomotopyContinuation.evaluate(tracking_system, test_point, test_params)
		#	println("Residual norm at start pair: ", norm(residual))

		# Add Jacobian condition number check
		#	J = HomotopyContinuation.jacobian(tracking_system, test_point, test_params)
		#	cond_num = try
		#		LinearAlgebra.cond(J)
		#	catch
		#		Inf
		#	end
		#	println("Jacobian condition number at start: ", cond_num)

		#	if norm(residual) > 1e-8
		#		@warn "Found start pair may not be valid - residual norm: $(norm(residual))"
		#	elseif cond_num > 1e8
		#		@warn "System may be ill-conditioned at start point - condition number: $(cond_num)"
		#	else
		#		println("✓ Valid start pair found (residual norm < 1e-8, condition number: $(cond_num))")
		#	end

		# Check for zero/infinite components
		if any(isnan.(test_point)) || any(isinf.(test_point))
			@warn "Start point contains NaN or Inf values"
		end
		if any(abs.(test_point) .< 1e-8) || any(abs.(test_point) .> 1e8)
			@warn "Start point contains very small or very large values"
		end
		#catch e
		#	@warn "Error evaluating start pair:" exception = e
		#end



		try
			tracked_solutions = HomotopyContinuation.solve(system, test_point,
				start_parameters = test_params,
				target_parameters = param_final,
				show_progress = true,
				tracker_options = HomotopyContinuation.TrackerOptions(
					automatic_differentiation = 3,
					max_steps = 10000,
					min_step_size = 1e-14,
					max_step_size = 0.1,
					extended_precision = true,
					max_initial_step_size = 0.01,
				))

			#	println("\n=== System Analysis ===")
			#			println("System dimensions: ", HomotopyContinuation.nequations(system), " equations, ",
			#				length(HomotopyContinuation.variables(system)), " variables")

			# Analyze coefficient magnitudes
			#	coeffs = filter(x -> x ≠ 0, HomotopyContinuation.coefficients(system))
			#	println("Coefficient magnitude range: [", minimum(abs.(coeffs)), ", ", maximum(abs.(coeffs)), "]")
			#	println("Coefficient magnitude histogram:")
			#	mags = floor.(Int, log10.(abs.(coeffs)))
			#	for mag in minimum(mags):maximum(mags)
			#		count = count(x -> x == mag, mags)
			#		if count > 0
			#			println("  1e", mag, ": ", count, " coefficients")
			#		end
			#	end

			# Analyze variable scaling
			#	println("\nVariable magnitudes in start point:")
			#	for (i, v) in enumerate(test_point)
			#		if abs(v) < 1e-6 || abs(v) > 1e6
			#			println("  Variable ", i, ": ", abs(v))
			#		end
			#	end

			#	println("\n=== Tracking Details ===")
			#println("System size: ", HomotopyContinuation.nequations(system), " equations, ", length(HomotopyContinuation.variables(system)), " variables")
			#	println("Parameter count: ", length(HomotopyContinuation.parameters(system)))
			#	println("Coefficient range: [", minimum(abs.(filter(x -> x ≠ 0, test_point))), ", ", maximum(abs.(test_point)), "]")
			#	println("Parameter range: [", minimum(abs.(filter(x -> x ≠ 0, test_params))), ", ", maximum(abs.(test_params)), "]")
			#	println("Target parameter range: [", minimum(abs.(filter(x -> x ≠ 0, param_final))), ", ", maximum(abs.(param_final)), "]")

			#	println("tracked_solutions: ", tracked_solutions)
			if !isempty(solutions(tracked_solutions))
				push!(start_pairs, solutions(tracked_solutions))
			else
				#		println("\n=== Debug Information for Empty Solution Set ===")
				#		println("Number of results: ", nresults(tracked_solutions))
				#		println("Number of solutions: ", nsolutions(tracked_solutions))
				#		println("Number of real solutions: ", nreal(tracked_solutions))
				#		println("Number of nonsingular solutions: ", nnonsingular(tracked_solutions))
				#		println("Number of singular solutions: ", nsingular(tracked_solutions))
				#		println("Number of solutions at infinity: ", nat_infinity(tracked_solutions))
				#		println("Number of failed paths: ", nfailed(tracked_solutions))
				#		println("Number of excess solutions: ", nexcess_solutions(tracked_solutions))

				#		println("\n=== Detailed Path Results ===")
				#		for (i, result) in enumerate(path_results(tracked_solutions))
				#			println("\nPath $i:")
				#			println("  Return code: ", result.return_code)
				#			println("  Residual: ", result.residual)
				#			println("  Accuracy: ", result.accuracy)
				#			println("  Condition number: ", result.condition_jacobian)
				#			println("  Is singular: ", result.singular)
				#			println("  Winding number: ", result.winding_number)
				#			println("  Steps taken: ", steps(result))
				#			println("    Accepted: ", accepted_steps(result))
				#			println("    Rejected: ", rejected_steps(result))
				#			println("  Extended precision used: ", result.extended_precision_used)
				#		end
				#		println("\n=== End Debug Information ===\n")
				#		println("Found $(length(solutions(tracked_solutions))) solutions")
				#		println("Singular solutions: ", singular(tracked_solutions))

			end
		catch e
			if e isa FiniteException
				@warn "Caught FiniteException. The solution set is positive-dimensional."
				@warn "Attempting to reduce dimension by adding a random linear equation."
				system = add_random_linear_equation(system)
			else
				rethrow(e)
			end
		end
		#println("attempt_count: ", attempt_count)
		attempt_count += 1
	end



	return start_pairs
end



"""
	mangle_variables(varlist)

Convert variable names to a format compatible with HomotopyContinuation.jl.
Adds prefixes and suffixes to avoid naming conflicts.

# Arguments
- `varlist`: List of variables to mangle

# Returns
- `mangled_varlist`: List of mangled variables
- `variable_mapping`: Dictionary mapping original variables to mangled ones
"""
function mangle_variables(varlist)
	mangled_varlist = deepcopy(varlist)
	variable_mapping = OrderedDict()

	for i in eachindex(varlist)
		# Convert variable name to HC-compatible format
		# _z_ prefix avoids conflicts, _d suffix indicates it's a "derived" variable
		mangled_name = Symbol("_z_" * replace(string(varlist[i]), "(t)" => "_t") * "_d")
		mangled_var = (@variables $mangled_name)[1]
		mangled_varlist[i] = mangled_var
		variable_mapping[Symbolics.unwrap(varlist[i])] = mangled_var
	end

	return mangled_varlist, variable_mapping
end

"""
	convert_to_hc_format(poly_system, varlist; parameterize=false)

Convert a polynomial system to HomotopyContinuation.jl format.
Can optionally create a parameterized system for monodromy solving.

# Arguments
- `poly_system`: System of polynomial equations
- `varlist`: List of variables
- `parameterize`: Whether to create a parameterized system for monodromy

# Returns
If parameterize=false:
- `hc_system`: System in HomotopyContinuation format
- `hc_variables`: Variables in HomotopyContinuation format

If parameterize=true:
- `system`: The parameterized system
- `tracking_system`: Copy of system for tracking
- `param_final`: Final parameter values
- `hc_variables`: Variables in HomotopyContinuation format
"""
function convert_to_hc_format(poly_system, varlist; parameterize = false)
	# Convert polynomials to strings for HC parsing
	string_target = string.(poly_system)
	variable_string_mapping = Dict()  # Maps variable strings to HC format
	var_name_mapping = Dict()         # Maps variables to their string names
	var_dict = Dict()                 # Maps variables to HC variables
	hc_variables = Vector{HomotopyContinuation.ModelKit.Variable}()

	for var in varlist
		var_name = string(var)
		hc_var_string = "hmcs(\"" * var_name * "\")"  # HC's string format for variables
		var_name_mapping[var] = var_name
		hc_var = HomotopyContinuation.ModelKit.Variable(Symbol(var_name))
		var_dict[var] = hc_var
		variable_string_mapping[string(var)] = hc_var_string
		push!(hc_variables, hc_var)
	end

	# Replace variable strings with HC format
	for i in eachindex(string_target)
		string_target[i] = replace(string_target[i], variable_string_mapping...)
	end

	# Parse the system
	parsed = eval.(Meta.parse.(string_target))
	HomotopyContinuation.set_default_compile(:all)

	if !parameterize
		hc_system = HomotopyContinuation.System(parsed, variables = hc_variables)
		return hc_system, hc_variables
	else
		num_equations = length(poly_system)
		system, tracking_system, param_final = create_parameterized_system(parsed, hc_variables, num_equations)
		return system, tracking_system, param_final, hc_variables
	end
end

"""
	create_parameterized_system(parsed_system, hc_variables, num_equations)

Creates a parameterized system for monodromy solving.
The system is parameterized as: m_i * eq_i - c_i = 0
where m_i and c_i are parameters for each equation i.

# Arguments
- `parsed_system`: The parsed polynomial system
- `hc_variables`: List of variables in HC format
- `num_equations`: Number of equations in the system

# Returns
- `system`: The parameterized system
- `tracking_system`: Copy of system for tracking
- `param_final`: Final parameter values
"""
function create_parameterized_system(parsed_system, hc_variables, num_equations)
	# Create parameters for each equation:
	# monodromy_multipliers: coefficients that multiply each equation
	# monodromy_constants: constants subtracted from each equation
	@var monodromy_multipliers[1:num_equations] monodromy_constants[1:num_equations]

	parameters = Vector{HomotopyContinuation.ModelKit.Variable}()
	#append!(parameters, monodromy_multipliers)
	append!(parameters, monodromy_constants)

	# Create parameterized system: m_i * eq_i - c_i = 0
	parameterized = deepcopy(parsed_system)
	for i in eachindex(parameterized)
		parameterized[i] = parameterized[i] - monodromy_constants[i]
		#    parameterized[i] = monodromy_multipliers[i] * parameterized[i] - monodromy_constants[i]
	end

	HomotopyContinuation.set_default_compile(:all)
	system = HomotopyContinuation.System(parameterized, variables = hc_variables, parameters = parameters)
	tracking_system = HomotopyContinuation.System(parameterized, variables = hc_variables, parameters = parameters)

	# Final parameters: all multipliers = 1, all constants = 0
	#param_final = vcat(repeat([1.0], outer = num_equations), repeat([0.0], outer = num_equations))
	param_final = vcat(repeat([0.0], outer = num_equations))

	return system, tracking_system, param_final
end

"""
	solve_with_fallback(system; show_progress=false)

Solve a system with fallback for finite-dimensional cases.
First tries to find real solutions, then falls back to complex solutions if none found.

# Arguments
- `system`: HomotopyContinuation.System to solve
- `show_progress`: Whether to show progress during solving

# Returns
- `solutions`: Array of solutions found
"""
function solve_with_fallback(system; show_progress = false)
	tryagain = true
	while (tryagain)
		try
			result = HomotopyContinuation.solve(system, show_progress = show_progress)

			# Try real solutions first with reasonable tolerance
			solutions = HomotopyContinuation.solutions(result, only_real = true, real_tol = 1e-4)

			# If no real solutions found, try complex ones
			if isempty(solutions)
				solutions = HomotopyContinuation.solutions(result, real_tol = 1e-4)
			end

			return solutions
		catch e
			if e isa FiniteException
				@warn "Caught FiniteException. The solution set is positive-dimensional."
				@warn "Attempting to reduce dimension by adding a random linear equation."
				system = add_random_linear_equation(system)

			else
				rethrow(e)
			end
		end
	end
end

"""
	prepare_system_for_hc(poly_system, varlist)

Prepares a polynomial system for HomotopyContinuation by mangling variables and applying substitutions.

# Arguments
- `poly_system`: System of polynomial equations to prepare
- `varlist`: List of variables in the system

# Returns
- `prepared_system`: System after mangling and substitution
- `mangled_varlist`: List of mangled variables
"""
function prepare_system_for_hc(poly_system, varlist)
	mangled_varlist, variable_mapping = mangle_variables(varlist)

	# Apply substitutions
	prepared_system = deepcopy(poly_system)
	for i in eachindex(prepared_system)
		prepared_system[i] = Symbolics.substitute(Symbolics.unwrap(prepared_system[i]), variable_mapping)
	end

	return prepared_system, mangled_varlist
end

"""
	solve_with_hc(input_poly_system, input_varlist, use_monodromy = true, display_system = false, polish_solutions = true)

Main entry point for solving polynomial systems using HomotopyContinuation.jl.
Automatically chooses between standard solving methods and monodromy-based methods
based on system complexity.

# Arguments
- `input_poly_system`: System of polynomial equations to solve
- `input_varlist`: List of variables in the system
- `use_monodromy`: Whether to allow using monodromy method for high-degree systems
- `display_system`: Whether to display debug information about the system
- `polish_solutions`: Whether to polish solutions using solve_with_nlopt

# Returns
- `solutions`: Array of solutions found
- `hc_variables`: Variables in HomotopyContinuation format
- `trivial_dict`: Dictionary of trivial substitutions found
- `symbolic_variables`: Original variable list in Julia Symbolics format
"""
function solve_with_hc(input_poly_system, input_varlist, use_monodromy = true, display_system = true, polish_solutions = true)
	if display_system
		println("Starting solve_with_hc with system:")
		display(input_poly_system)
		println("Variables:")
		display(input_varlist)
	end

	# Store original ordering for consistency
	original_order = Dict(v => i for (i, v) in enumerate(input_varlist))

	# Handle substitutions and squarification
	(poly_system, varlist, trivial_vars, trivial_dict) = handle_simple_substitutions(input_poly_system, input_varlist)
	poly_system, varlist, trash = squarify_by_trashing(poly_system, varlist)
	println("DEBUG [solve_with_hc]: Poly system:")
	for term in poly_system
		println("\t$term")
	end
	println("DEBUG [solve_with_hc]: Varlist: $varlist")
	println("DEBUG [solve_with_hc]: Trivial vars: $trivial_vars")
	println("DEBUG [solve_with_hc]: Trivial dict: $trivial_dict")

	# Preserve original ordering after squarifying
	varlist = sort(varlist, by = v -> get(original_order, v, length(input_varlist) + 1))
	symbolic_variables = deepcopy(varlist)

	# Calculate total degree to decide on solution method
	total_degree = 1
	for poly in poly_system
		total_degree *= Symbolics.degree(poly)
	end

	if display_system
		println("Total degree: ", total_degree)
	end

	symbolic_solutions = []
	hc_variables = []
	if total_degree > 50 && use_monodromy
		symbolic_solutions, hc_variables = solve_with_monodromy(poly_system, varlist)
		#return solutions, hc_variables, trivial_dict, symbolic_variables
	end
	if (isempty(symbolic_solutions))

		# Standard solving method
		prepared_system, mangled_varlist = prepare_system_for_hc(poly_system, varlist)

		# Convert to HomotopyContinuation format
		hc_system, hc_variables = convert_to_hc_format(prepared_system, mangled_varlist)

		# Solve the system
		solutions = solve_with_fallback(hc_system)

		if isempty(solutions)
			@warn "No solutions found."
			return ([], [], [], [])
		end

		# Convert HC solutions back to JuliaSymbolics format
		symbolic_solutions = []
		for sol in solutions
			symbolic_sol = [convert(ComplexF64, s) for s in sol]  # Convert to standard Julia complex numbers
			push!(symbolic_solutions, symbolic_sol)
		end
	end

	# Polish solutions if requested
	if polish_solutions && !isempty(symbolic_solutions)
		polished_solutions = []
		for sol in symbolic_solutions
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
		symbolic_solutions = polished_solutions
	end

	return symbolic_solutions, hc_variables, trivial_dict, symbolic_variables
end

"""
	solve_with_monodromy(poly_system, varlist)

Solves a polynomial system using monodromy-based methods from HomotopyContinuation.jl.
This method is more efficient for systems with high total degree.

# Arguments
- `poly_system`: System of polynomial equations to solve
- `varlist`: List of variables in the system

# Returns
- `solutions`: Array of solutions found
- `hc_variables`: Variables in HomotopyContinuation format
"""
function solve_with_monodromy(poly_system, varlist)
	# Prepare system for HC
	prepared_system, mangled_varlist = prepare_system_for_hc(poly_system, varlist)

	# Convert to HC format with parameterization
	system, tracking_system, param_final, hc_variables = convert_to_hc_format(prepared_system, mangled_varlist, parameterize = true)

	# Find start solutions
	start_pairs = find_start_solutions(system, tracking_system, param_final)

	if isempty(start_pairs)
		@warn "No start solutions found."
		return [], hc_variables
	else
		println("DEBUG [solve_with_monodromy]: Start pairs: $start_pairs")
	end

	# Solve using monodromy
	println("DEBUG [solve_with_monodromy]: Solving with monodromy tracking.")
	solutions = solve_with_monodromy_tracking(system, start_pairs, param_final)

	if isempty(solutions)
		@warn "No solutions found."
		return [], hc_variables
	end

	return solutions, hc_variables
end

# Rename the original solve_with_monodromy to solve_with_monodromy_tracking to avoid naming conflict
"""
	solve_with_monodromy_tracking(system, start_pairs, param_final)

Solves a system using monodromy tracking.

# Arguments
- `system`: The system to solve
- `start_pairs`: Starting solutions
- `param_final`: Final parameter values

# Returns
- `solutions`: Array of solutions found
"""
function solve_with_monodromy_tracking(system, start_pairs, param_final)
	flattened_start_pairs = length(start_pairs) > 0 ? vcat(start_pairs...) : Vector{eltype(start_pairs)}()
	tryagain = true
	result = nothing

	while (tryagain)
		try
			println("DEBUG [solve_with_monodromy_tracking]: starting monodromy solve.")
			result = HomotopyContinuation.monodromy_solve(system, flattened_start_pairs, param_final,
				show_progress = true,
				target_solutions_count = 10000,
				#timeout = 300.0,
				#max_loops_no_progress = 100,
				unique_points_rtol = 1e-4,
				unique_points_atol = 1e-4,
				trace_test = true,
				trace_test_tol = 1e-6,
				min_solutions = 100000,
				tracker_options = TrackerOptions(automatic_differentiation = 3))
			tryagain = false
		catch e
			if e isa FiniteException
				@warn "Caught FiniteException. The solution set is positive-dimensional."
				@warn "Attempting to reduce dimension by adding a random linear equation."
				system = add_random_linear_equation(system)
			else
				rethrow(e)
			end
		end
	end

	return HomotopyContinuation.solutions(result)
end

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
