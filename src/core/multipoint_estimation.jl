"""
	multipoint_parameter_estimation(PEP::ParameterEstimationProblem; options...)

Perform Multi-point Parameter Estimation using a three-phase approach:
1. Setup: Determine optimal points and analyze identifiability
2. Solve: Construct and solve the system of equations
3. Process: Convert raw solutions to parameter estimates

# Arguments
- `PEP::ParameterEstimationProblem`: The parameter estimation problem
- `system_solver`: System solver function (default: solve_with_rs)
- `max_num_points`: Maximum number of points to use (default: 1)
- `interpolator`: Function for interpolating data (required)
- `nooutput`: Whether to suppress output (default: false)
- `diagnostics`: Whether to output diagnostic information (default: false)
- `diagnostic_data`: Additional diagnostic data (default: nothing)
- `polish_solutions`: Whether to polish solutions (default: false)
- `polish_maxiters`: Maximum iterations for polishing (default: 20)
- `polish_method`: Optimization method for polishing (default: NewtonTrustRegion)
- `point_hint`: Hint for where to sample in the time series (default: 0.5)

# Returns
- Tuple containing (solutions, unidentifiable_dict, trivial_dict, all_unidentifiable)
"""
function multipoint_parameter_estimation(
	PEP::ParameterEstimationProblem;
	system_solver = solve_with_rs,
	max_num_points = 1,
	interpolator = interpolator,
	nooutput = false,
	diagnostics = false,
	diagnostic_data = nothing,
	polish_solutions = false,
	polish_maxiters = 20,
	polish_method = NewtonTrustRegion,
	point_hint = 0.5,
	save_system = true,
	debug_solver = false,
	debug_cas_diagnostics = false,
	debug_dimensional_analysis = false,
)
	# Check input validity
	if isnothing(PEP.data_sample)
		error("No data sample provided in the ParameterEstimationProblem")
	end

	found_any_solutions = false
	attempt_count = 0

	while (!found_any_solutions && attempt_count < 1)
		attempt_count += 1

		# Phase 1: Setup - Determine optimal points and analyze identifiability
		setup_data = setup_parameter_estimation(
			PEP,
			max_num_points = max_num_points,
			point_hint = point_hint,
			nooutput = nooutput,
			interpolator = interpolator,
		)

		# Phase 2: Solve - Construct and solve the system of equations
		solution_data = solve_parameter_estimation(
			PEP,
			setup_data,
			system_solver = system_solver,
			interpolator = interpolator,
			diagnostics = diagnostics,
			diagnostic_data = diagnostic_data,
			save_system = save_system,
			debug_solver = debug_solver,
			debug_cas_diagnostics = debug_cas_diagnostics,
			debug_dimensional_analysis = debug_dimensional_analysis,
		)

		# Check if we found any solutions
		if !isempty(solution_data.solns)
			found_any_solutions = true

			# Phase 3: Process - Convert raw solutions to parameter estimates
			solved_res = process_estimation_results(
				PEP,
				solution_data,
				setup_data,
				nooutput = nooutput,
				polish_solutions = polish_solutions,
				polish_maxiters = polish_maxiters,
				polish_method = polish_method,
			)

			return (solved_res, setup_data.good_udict, solution_data.trivial_dict, setup_data.good_DD.all_unidentifiable)
		end
	end

	# No solutions found after maximum attempts
	@warn "No solutions found after $attempt_count attempts"
	return ([], Dict(), Dict(), Set())
end

# Add the multishot parameter estimation function
"""
	multishot_parameter_estimation(PEP::ParameterEstimationProblem; system_solver=solve_with_rs, ...)

Perform parameter estimation at multiple point hints (shooting points).
This function calls multipoint_parameter_estimation at each point hint
and combines the results.

# Arguments
- Same as multipoint_parameter_estimation, plus:
- `shooting_points`: Number of different point hints to use (default: 10)

# Returns
- Tuple containing (all_solutions, all_udict, all_trivial_dict, all_unidentifiable)
"""
function multishot_parameter_estimation(
	PEP::ParameterEstimationProblem;
	system_solver = solve_with_rs,
	max_num_points = 1,
	interpolator = interpolator,
	nooutput = false,
	diagnostics = false,
	diagnostic_data = nothing,
	polish_solutions = false,
	polish_maxiters = 20,
	polish_method = NewtonTrustRegion,
	shooting_points = 10,
)
	# Initialize empty arrays to store all solutions and metadata
	all_solutions = []
	all_udict = nothing
	all_trivial_dict = nothing
	all_unidentifiable = nothing

	# Run parameter estimation at each point hint
	for i in 1:(shooting_points+1)
		# Special case: when shooting_points = 0, use slightly offset midpoint to avoid potential issues
		if shooting_points == 0
			point_hint = 0.499  # Use slightly offset midpoint (matching PE's behavior)
		else
			point_hint = i / (shooting_points + 1)
		end
		println("\n[DEBUG-ODEPE] Shooting point $i/$(shooting_points+1), point_hint=$point_hint")

		# Call multipoint_parameter_estimation
		solutions, udict, trivial_dict, unidentifiable = multipoint_parameter_estimation(
			PEP;
			system_solver = system_solver,
			max_num_points = max_num_points,
			interpolator = interpolator,
			nooutput = nooutput,
			diagnostics = diagnostics,
			diagnostic_data = diagnostic_data,
			polish_solutions = polish_solutions,
			polish_maxiters = polish_maxiters,
			polish_method = polish_method,
			point_hint = point_hint,
		)

		# Store metadata from first run
		if isnothing(all_udict)
			all_udict = udict
			all_trivial_dict = trivial_dict
			all_unidentifiable = unidentifiable
		end

		# Add solutions from this run
		append!(all_solutions, solutions)
	end

	return all_solutions, all_udict, all_trivial_dict, all_unidentifiable
end

# Export the functions
export multipoint_parameter_estimation, multishot_parameter_estimation
