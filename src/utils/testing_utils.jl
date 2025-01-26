

function analyze_parameter_estimation_problem(PEP::ParameterEstimationProblem; test_mode = false, interpolator, nooutput = false, system_solver = solve_with_hc)
	if !nooutput
		println("Starting model: ", PEP.name)
	end

	res = ODEPEtestwrapper(
		PEP.model,  # This is now an OrderedODESystem
		PEP.measured_quantities,
		PEP.data_sample,
		PEP.solver,
		interpolator = interpolator, nooutput = nooutput, system_solver = system_solver)
	besterror = analyze_estimation_result(PEP, res, nooutput = nooutput)

	if test_mode
		# @test besterror < 1e-1
	end
	return res
end

function print_debug_info(prefix::String, unident_dict, all_unidentifiable, varlist)
	#println("\nDEBUG [$prefix]: Getting unidentifiable parameters...")
	#println("DEBUG [$prefix]: Initial unidentifiable parameters dict: ", unident_dict)
	#println("DEBUG [$prefix]: Initial all unidentifiable parameters: ", all_unidentifiable)
	#println("DEBUG [$prefix]: Initial varlist: ", varlist)
end

"""
	ODEPEtestwrapper(model::OrderedODESystem, measured_quantities, data_sample, ode_solver; system_solver = solve_with_hc, abstol = 1e-12, reltol = 1e-12, max_num_points = 1)

Wrapper function for testing ODE Parameter Estimation.

# Arguments
- `model::OrderedODESystem`: The ODE system
- `measured_quantities`: Measured quantities
- `data_sample`: Sample data
- `ode_solver`: ODE solver to use
- `system_solver`: System solver function (optional, default: solve_with_hc)
- `abstol`: Absolute tolerance (optional, default: 1e-12)
- `reltol`: Relative tolerance (optional, default: 1e-12)
- `max_num_points`: Maximum number of points to use (optional, default: 4)

# Returns
- Vector of ParameterEstimationResult objects
"""
function ODEPEtestwrapper(model::OrderedODESystem, measured_quantities, data_sample, ode_solver; system_solver = solve_with_hc, abstol = 1e-12, reltol = 1e-12, max_num_points = 1, interpolator, nooutput = false)
	# Get current ordering from ModelingToolkit
	current_states = ModelingToolkit.unknowns(model.system)
	current_params = ModelingToolkit.parameters(model.system)

	# Create ordered dictionaries to preserve parameter order
	param_dict = OrderedDict(current_params .=> ones(length(current_params)))
	states_dict = OrderedDict(current_states .=> ones(length(current_states)))

	solved_res = []
	tspan = (data_sample["t"][begin], data_sample["t"][end])

	# Create initial result object without unidentifiability info - MPHCPE will handle that
	newres = ParameterEstimationResult(param_dict, states_dict, tspan[1], nothing, nothing, length(data_sample["t"]), tspan[1], Dict(), Set(), nothing)

	#	println("\nDEBUG [ODEPEtestwrapper]: Calling MPHCPE...")
	results_tuple = multipoint_parameter_estimation(model.system, measured_quantities, data_sample, ode_solver, system_solver = system_solver, max_num_points = max_num_points, interpolator = interpolator, nooutput = nooutput)
	results_vec, unident_dict, trivial_dict, all_unidentifiable = results_tuple
	#	println("DEBUG [ODEPEtestwrapper]: Got ", length(results_vec), " results from MPHCPE")

	#	println("DEBUG [ODEPEtestwrapper]: Results vector: ", results_vec)
	# Print unidentifiability information
	if !nooutput
		println("\nUnidentifiability Analysis from MPHCPE:")
		println("All unidentifiable variables: ", all_unidentifiable)
		println("Unidentifiable variables substitution dictionary: ", unident_dict)
		println("Trivially solvable variables: ", trivial_dict)
	end

	# Create initial result object with unidentifiability info
	newres = ParameterEstimationResult(param_dict, states_dict, tspan[1], nothing, nothing, length(data_sample["t"]), tspan[1], unident_dict, all_unidentifiable, nothing)

	# Process raw solutions
	for (i, raw_sol) in enumerate(results_vec)
		if !nooutput
			println("\nDEBUG [ODEPEtestwrapper]: Processing solution ", i)
		end
		push!(solved_res, deepcopy(newres))

		ordered_states, ordered_params, ode_solution, err = process_raw_solution(raw_sol, model, data_sample, ode_solver, abstol = abstol, reltol = reltol)

		# Update result with processed data
		solved_res[end].states = ordered_states
		solved_res[end].parameters = ordered_params
		solved_res[end].solution = ode_solution
		solved_res[end].err = err
	end
	return solved_res
end

# Add this helper function in the same file
function reorder_solution(raw_sol::AbstractVector, model_states::AbstractVector, model_ps::AbstractVector)
	num_states = length(model_states)
	num_params = length(model_ps)
	total_vars = num_states + num_params

	# Ensure raw_sol has the right length
	if length(raw_sol) != total_vars
		error("Solution vector length ($(length(raw_sol))) doesn't match total variables ($total_vars)")
	end

	# The solver appears to be returning parameters first, then states
	# So we need to reorder from [params..., states...] to [states..., params...]
	ordered_sol = Vector{eltype(raw_sol)}(undef, total_vars)

	# Copy states (they come after parameters in raw_sol)
	for i in 1:num_states
		ordered_sol[i] = raw_sol[num_params+i]
	end

	# Copy parameters (they come first in raw_sol)
	for i in 1:num_params
		ordered_sol[num_states+i] = raw_sol[i]
	end

	return ordered_sol
end

function process_raw_solution(raw_sol, model::OrderedODESystem, data_sample, ode_solver; abstol = 1e-12, reltol = 1e-12)
	# Create ordered collections for states and parameters
	ordered_states = OrderedDict()
	ordered_params = OrderedDict()

	# Get current ordering from ModelingToolkit
	current_states = ModelingToolkit.unknowns(model.system)
	current_params = ModelingToolkit.parameters(model.system)

	#	println("DEBUG [process_raw_solution]: Original parameter order: ", model.original_parameters)
	#	println("DEBUG [process_raw_solution]: Current parameter order: ", current_params)
	#	println("DEBUG [process_raw_solution]: Raw solution: ", raw_sol)

	# Reorder states according to original ordering
	for (i, state) in enumerate(model.original_states)
		idx = findfirst(s -> isequal(s, state), current_states)
		if isnothing(idx)
			@warn "State $state not found in current states, using original index $i"
			idx = i
		end
		ordered_states[state] = raw_sol[idx]
	end

	# Reorder parameters according to original ordering
	param_offset = length(current_states)
	#	println("DEBUG [process_raw_solution]: Parameter offset: ", param_offset)
	for (i, param) in enumerate(model.original_parameters)
		#		println("DEBUG [process_raw_solution]: Processing parameter $i: $param")
		#		println("DEBUG [process_raw_solution]: Using index: ", param_offset + i)
		ordered_params[param] = raw_sol[param_offset+i]
		#		println("DEBUG [process_raw_solution]: Assigned value: ", ordered_params[param])
	end







	ic = collect(values(ordered_states))
	ps = collect(values(ordered_params))

	#	println("DEBUG [process_raw_solution]: Final ordered parameters: ", ordered_params)

	# Solve ODE problem
	tspan = (data_sample["t"][begin], data_sample["t"][end])

	#	println("DEBUG [process_raw_solution]: Solving ODE with initial conditions: ", ic)
	#	println("DEBUG [process_raw_solution]: Solving ODE with parameters: ", ps)
	prob = ODEProblem(complete(model.system), ic, tspan, ps)
	ode_solution = ModelingToolkit.solve(prob, ode_solver, saveat = data_sample["t"], abstol = abstol, reltol = reltol)

	# Calculate error
	err = 0
	if ode_solution.retcode == ReturnCode.Success
		err = 0
		for (key, sample) in data_sample
			if isequal(key, "t")
				continue
			end
			err += norm((ode_solution(data_sample["t"])[key]) .- sample) / length(data_sample["t"])
		end
		err /= length(data_sample)
	else
		err = 1e+15
	end


	# Reorder parameters according to original ordering
	param_offset = length(current_states)
	#	println("DEBUG [process_raw_solution]: Parameter offset: ", param_offset)
	for (i, param) in enumerate(model.original_parameters)
		#		println("DEBUG [process_raw_solution]: Processing parameter $i: $param")
		# Find the index of this parameter in the current parameters
		idx = findfirst(p -> isequal(p, param), current_params)
		if isnothing(idx)
			@warn "Parameter $param not found in current parameters, using original index $i"
			idx = i
		end
		#		println("DEBUG [process_raw_solution]: Found at index: ", idx)
		ordered_params[param] = raw_sol[param_offset+idx]
		#		println("DEBUG [process_raw_solution]: Assigned value: ", ordered_params[param])
	end


	return ordered_states, ordered_params, ode_solution, err
end

