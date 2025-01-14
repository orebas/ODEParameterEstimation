function fillPEP(pe::ParameterEstimationProblem; datasize = 21, time_interval = [-0.5, 0.5], solver = package_wide_default_ode_solver, add_noise = false)  #TODO add noise handling 

	return ParameterEstimationProblem(
		pe.Name,
		complete(pe.model),
		pe.measured_quantities,
		sample_data(pe.model, pe.measured_quantities, time_interval, pe.p_true, pe.ic, datasize, solver = solver),
		solver,
		pe.p_true,
		pe.ic,
		pe.unident_count)
end

function analyze_parameter_estimation_problem(PEP::ParameterEstimationProblem; test_mode = false, showplot = true, run_ode_pe = true)
	if run_ode_pe
		println("Starting model: ", PEP.name)
		#display(PEP.model)
		#display(PEP.measured_quantities)
		#display(PEP.data_sample)

		res = ODEPEtestwrapper(
			PEP.model,  # This is now an OrderedODESystem
			PEP.measured_quantities,
			PEP.data_sample,
			PEP.solver,
		)
		besterror = analyze_estimation_result(PEP, res)

		if test_mode
			# @test besterror < 1e-1
		end
	end
end


"""
	ODEPEtestwrapper(model::OrderedODESystem, measured_quantities, data_sample, ode_solver; system_solver = solveJSwithHC, abstol = 1e-12, reltol = 1e-12, max_num_points = 4)

Wrapper function for testing ODE Parameter Estimation.

# Arguments
- `model::OrderedODESystem`: The ODE system
- `measured_quantities`: Measured quantities
- `data_sample`: Sample data
- `ode_solver`: ODE solver to use
- `system_solver`: System solver function (optional, default: solveJSwithHC)
- `abstol`: Absolute tolerance (optional, default: 1e-12)
- `reltol`: Relative tolerance (optional, default: 1e-12)
- `max_num_points`: Maximum number of points to use (optional, default: 4)

# Returns
- Vector of ParameterEstimationResult objects
"""
function ODEPEtestwrapper(model::OrderedODESystem, measured_quantities, data_sample, ode_solver; system_solver = solveJSwithHC, abstol = 1e-12, reltol = 1e-12, max_num_points = 2)
	# println("\nStarting ODEPEtestwrapper")

	# Get original ordering from OrderedODESystem
	original_states = model.original_states
	original_parameters = model.original_parameters

	# Get current ordering from ModelingToolkit
	current_states = ModelingToolkit.unknowns(model.system)
	current_params = ModelingToolkit.parameters(model.system)

	# println("Original states ordering: ", original_states)
	# println("Original parameters ordering: ", original_parameters)
	# println("Current states ordering: ", current_states)
	# println("Current parameters ordering: ", current_params)

	tspan = (data_sample["t"][begin], data_sample["t"][end])

	# Create ordered dictionaries to preserve parameter order
	param_dict = OrderedDict(current_params .=> ones(length(current_params)))
	states_dict = OrderedDict(current_states .=> ones(length(current_states)))

	# Get unidentifiable parameters information
	(deriv_level, unident_dict, varlist, DD) = multipoint_local_identifiability_analysis(model.system, measured_quantities, max_num_points)

	solved_res = []
	newres = ParameterEstimationResult(param_dict, states_dict, tspan[1], nothing, nothing, length(data_sample["t"]), tspan[1], unident_dict, DD.all_unidentifiable)

	results_vec = MPHCPE(model.system, measured_quantities, data_sample, ode_solver, system_solver = system_solver, max_num_points = max_num_points)

	for raw_sol in results_vec
		# println("\nProcessing solution:")
		# println("Raw solution vector: ", raw_sol)

		push!(solved_res, deepcopy(newres))

		# Create ordered collections for states and parameters
		ordered_states = OrderedDict()
		ordered_params = OrderedDict()

		# Reorder states according to original ordering
		for (i, state) in enumerate(original_states)
			idx = findfirst(s -> isequal(s, state), current_states)
			if isnothing(idx)
				@warn "State $state not found in current states, using original index $i"
				idx = i
			end
			ordered_states[state] = raw_sol[idx]
		end

		# Reorder parameters according to original ordering
		for (i, param) in enumerate(original_parameters)
			idx = findfirst(p -> isequal(p, param), current_params)
			if isnothing(idx)
				@warn "Parameter $param not found in current parameters, using original index $i"
				idx = i
			end
			ordered_params[param] = raw_sol[length(current_states)+idx]
		end

		# Update result with ordered collections
		solved_res[end].states = ordered_states
		solved_res[end].parameters = ordered_params

		ic = collect(values(ordered_states))
		ps = collect(values(ordered_params))


		prob = ODEProblem(complete(model.system), ic, tspan, ps)
		ode_solution = ModelingToolkit.solve(prob, ode_solver, saveat = data_sample["t"], abstol = abstol, reltol = reltol)
		#if @isdefined(Infiltrator)
		#	@infiltrate
		#end# Debug prints
		#println("\nDEBUG: ODE Solution Info:")
		#println("Available keys in solution: ", typeof(ode_solution(data_sample["t"])))
		#println("\nDEBUG: Data Sample Info:")
		#println("Keys in data_sample: ", keys(data_sample))

		err = 0
		if ode_solution.retcode == ReturnCode.Success
			err = 0
			for (key, sample) in data_sample
				if isequal(key, "t")
					continue
				end
				#		println("\nDEBUG: Processing key: ", key)
				#		println("Type of key: ", typeof(key))
				#				println("Available solution components: ", keys(ode_solution(data_sample["t"])))
				err += norm((ode_solution(data_sample["t"])[key]) .- sample) / length(data_sample["t"])
			end
			err /= length(data_sample)
		else
			err = 1e+15
		end
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
