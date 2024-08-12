#module SharedUtils

using ModelingToolkit
#using DifferentialEquations
using OrderedCollections
using ODEParameterEstimation


struct ParameterEstimationProblem
	name::String
	model::ODESystem
	measured_quantities::Vector{Equation}
	data_sample::Union{Nothing, OrderedDict}
	solver::Any
	p_true::Vector{Float64}
	ic::Vector{Float64}
	unident_count::Int
end

function create_ode_system(name, states, parameters, equations, measured_quantities)
	@named model = ODESystem(equations, t, states, parameters)
	return model, measured_quantities
end

function sample_problem_data(problem::ParameterEstimationProblem; datasize = 21, time_interval = [-0.5, 0.5], solver = Vern9())
	return ParameterEstimationProblem(
		problem.name,
		complete(problem.model),
		problem.measured_quantities,
		ODEParameterEstimation.sample_data(problem.model, problem.measured_quantities, time_interval, problem.p_true, problem.ic, datasize, solver = solver),
		solver,
		problem.p_true,
		problem.ic,
		problem.unident_count,
	)
end

function analyze_estimation_result(problem::ParameterEstimationProblem, result)
	all_params = vcat(problem.ic, problem.p_true)
	besterror = Inf

	for each in result
		estimates = vcat(collect(values(each.states)), collect(values(each.parameters)))
		errorvec = abs.((estimates .- all_params) ./ all_params)

		if problem.unident_count > 0
			sort!(errorvec)
			for i in 1:problem.unident_count
				pop!(errorvec)
			end
		end

		besterror = min(besterror, maximum(errorvec))
	end

	println("For model $(problem.name): The max abs rel. err: $besterror")
	return besterror
end

