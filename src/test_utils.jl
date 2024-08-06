
struct ParameterEstimationProblem
	Name::Any
	model::Any
	measured_quantities::Any
	data_sample::Any
	solver::Any
	p_true::Any
	ic::Any
	unident_count::Any
end

function fillPEP(pe::ParameterEstimationProblem; datasize = 21, time_interval = [-0.5, 0.5], solver = Vern9(), add_noise = false)  #TODO add noise handling 

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

	#interpolators = Dict(
	#	"AAA" => ParameterEstimation.aaad,
	#"FHD3" => ParameterEstimation.fhdn(3),
	#"FHD6" => ParameterEstimation.fhdn(6),
	#"FHD8" => ParameterEstimation.fhdn(8),
	#"Fourier" => ParameterEstimation.FourierInterp,
	#)
	datasize = 21 #TODO(Orebas) magic number

	#stepsize = max(1, datasize ÷ 8)
	#for i in range(1, (datasize - 2), step = stepsize)
	#	interpolators["RatOld($i)"] = ParameterEstimation.SimpleRationalInterpOld(i)
	#end

	#@time res = ParameterEstimation.estimate(PEP.model, PEP.measured_quantities,
	#	PEP.data_sample,
	#	solver = PEP.solver, disable_output = false, interpolators = interpolators)
	#all_params = vcat(PEP.ic, PEP.p_true)
	#println("TYPERES: ", typeof(res))
	#println(res)

	#println(res)
	besterror = 1e30
	all_params = vcat(PEP.ic, PEP.p_true)

	if (run_ode_pe)
		println("Starting model: ", PEP.Name)
		@time PEP.Name res3 = ODEPEtestwrapper(PEP.model, PEP.measured_quantities,
			PEP.data_sample,
			PEP.solver,
		)
		besterror = 1e30
		res3 = sort(res3, by = x -> x.err)
		display("How close are we?")
		println("Actual values:")
		display(all_params)

		for each in res3

			estimates = vcat(collect(values(each.states)), collect(values(each.parameters)))
			if (each.err < 1)  #TODO: magic number

				display(estimates)
				println("Error: ", each.err)
			end

			errorvec = abs.((estimates .- all_params) ./ (all_params))
			if (PEP.unident_count > 0)
				sort!(errorvec)
				for i in 1:PEP.unident_count
					pop!(errorvec)
				end
			end
			besterror = min(besterror, maximum(errorvec))
		end

		if (test_mode)
			#@test besterror < 1e-1
		end
		println("For model ", PEP.Name, ": The ODEPE  max abs rel. err: ", besterror)
	end
end


"""
	ODEPEtestwrapper(model::ODESystem, measured_quantities, data_sample, ode_solver; system_solver = solveJSwithHC, abstol = 1e-12, reltol = 1e-12, max_num_points = 4)

Wrapper function for testing ODE Parameter Estimation.

# Arguments
- `model::ODESystem`: The ODE system
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
function ODEPEtestwrapper(model::ODESystem, measured_quantities, data_sample, ode_solver; system_solver = solveJSwithHC, abstol = 1e-12, reltol = 1e-12, max_num_points = 4)

	model_states = ModelingToolkit.unknowns(model)
	model_ps = ModelingToolkit.parameters(model)
	tspan = (data_sample["t"][begin], data_sample["t"][end])

	param_dict  = Dict(model_ps .=> ones(length(model_ps)))
	states_dict = Dict(model_states .=> ones(length(model_states)))

	solved_res = []
	newres = ParameterEstimationResult(param_dict,
		states_dict, tspan[1], nothing, nothing, length(data_sample["t"]), tspan[1])
	results_vec = MPHCPE(model, measured_quantities, data_sample, ode_solver, system_solver = system_solver, max_num_points = max_num_points)

	for each in results_vec
		push!(solved_res, deepcopy(newres))


		for (key, value) in solved_res[end].parameters
			solved_res[end].parameters[key] = 1e30
		end
		for (key, value) in solved_res[end].states
			solved_res[end].states[key] = 1e30
		end
		#println(newres)
		i = 1
		for (key, value) in solved_res[end].states
			solved_res[end].states[key] = each[i]
			i += 1
		end


		for (key, value) in solved_res[end].parameters
			solved_res[end].parameters[key] = each[i]
			i += 1
		end
		ic = deepcopy(solved_res[end].states)
		ps = deepcopy(solved_res[end].parameters)
		prob = ODEProblem(complete(model), ic, tspan, ps)

		ode_solution = ModelingToolkit.solve(prob, ode_solver, saveat = data_sample["t"], abstol = abstol, reltol = reltol)
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
		solved_res[end].err = err


	end
	return solved_res
end
