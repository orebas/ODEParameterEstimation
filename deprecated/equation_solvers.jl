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
function find_start_solutions(system, tracking_system, param_final; max_attempts = 500, min_attempts = 10)
	attempt_count = 0
	start_pairs = []

	while (attempt_count < max_attempts && (attempt_count < min_attempts || isempty(start_pairs)))
		test_point, test_params = HomotopyContinuation.find_start_pair(system)

		try
			tracked_solutions = HomotopyContinuation.solve(tracking_system, test_point,
				start_parameters = test_params,
				target_parameters = param_final,
				tracker_options = TrackerOptions(automatic_differentiation = 3))

			if !isempty(solutions(tracked_solutions))
				push!(start_pairs, solutions(tracked_solutions))
			end
		catch e
			if e isa FiniteException
				@warn "Caught FiniteException. The solution set is positive-dimensional."
				@warn "Attempting to reduce dimension by adding a random linear equation."
				tracking_system = add_random_linear_equation(tracking_system)
			else
				rethrow(e)
			end
		end

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
	append!(parameters, monodromy_multipliers)
	append!(parameters, monodromy_constants)

	# Create parameterized system: m_i * eq_i - c_i = 0
	parameterized = copy(parsed_system)
	for i in eachindex(parameterized)
		parameterized[i] = monodromy_multipliers[i] * parameterized[i] - monodromy_constants[i]
	end

	HomotopyContinuation.set_default_compile(:all)
	system = HomotopyContinuation.System(parameterized, variables = hc_variables, parameters = parameters)
	tracking_system = HomotopyContinuation.System(parameterized, variables = hc_variables, parameters = parameters)

	# Final parameters: all multipliers = 1, all constants = 0
	param_final = vcat(repeat([1.0], outer = num_equations), repeat([0.0], outer = num_equations))

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
			system_with_rand = add_random_linear_equation(system)
			result = HomotopyContinuation.solve(system_with_rand, show_progress = show_progress)
			return HomotopyContinuation.solutions(result, real_tol = 1e-4)
		else
			rethrow(e)
		end
	end
end

"""
	solve_with_hc(input_poly_system, input_varlist, use_monodromy=true, display_system=false)

Main entry point for solving polynomial systems using HomotopyContinuation.jl.
Automatically chooses between standard solving methods and monodromy-based methods
based on system complexity.

# Arguments
- `input_poly_system`: System of polynomial equations to solve
- `input_varlist`: List of variables in the system
- `use_monodromy`: Whether to allow using monodromy method for high-degree systems
- `display_system`: Whether to display debug information about the system

# Returns
- `solutions`: Array of solutions found
- `hc_variables`: Variables in HomotopyContinuation format
- `trivial_dict`: Dictionary of trivial substitutions found
- `symbolic_variables`: Original variable list in Julia Symbolics format
"""
function solve_with_hc(input_poly_system, input_varlist, use_monodromy = true, display_system = false)
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

	if total_degree > 50 && use_monodromy
		solutions, hc_variables = solve_with_monodromy(poly_system, varlist)
		return solutions, hc_variables, trivial_dict, symbolic_variables
	end

	# Standard solving method
	mangled_varlist, variable_mapping = mangle_variables(varlist)

	# Apply substitutions
	for i in eachindex(poly_system)
		poly_system[i] = Symbolics.substitute(Symbolics.unwrap(poly_system[i]), variable_mapping)
	end

	# Convert to HomotopyContinuation format
	hc_system, hc_variables = convert_to_hc_format(poly_system, mangled_varlist)

	# Solve the system
	solutions = solve_with_fallback(hc_system)

	if isempty(solutions)
		@warn "No solutions found."
		return ([], [], [], [])
	end

	return solutions, hc_variables, trivial_dict, symbolic_variables
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
	# Reuse existing helper functions
	mangled_varlist, variable_mapping = mangle_variables(varlist)

	# Apply substitutions
	for i in eachindex(poly_system)
		poly_system[i] = Symbolics.substitute(Symbolics.unwrap(poly_system[i]), variable_mapping)
	end

	# Convert to HC format with parameterization
	system, tracking_system, param_final, hc_variables = convert_to_hc_format(poly_system, mangled_varlist, parameterize = true)

	# Find start solutions
	start_pairs = find_start_solutions(system, tracking_system, param_final)

	if isempty(start_pairs)
		@warn "No start solutions found."
		return [], hc_variables
	end

	# Solve using monodromy
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
			result = HomotopyContinuation.monodromy_solve(system, flattened_start_pairs, param_final,
				show_progress = false,
				target_solutions_count = 10000,
				timeout = 300.0,
				max_loops_no_progress = 100,
				unique_points_rtol = 1e-6,
				unique_points_atol = 1e-6,
				trace_test = true,
				trace_test_tol = 1e-10,
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
