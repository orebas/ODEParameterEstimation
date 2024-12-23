#module SharedUtils

using ModelingToolkit
#using DifferentialEquations
using OrderedCollections
using ODEParameterEstimation

struct OrderedODESystem
	system::ODESystem
	original_parameters::Vector
	original_states::Vector
end

struct ParameterEstimationProblem
	name::String
	model::OrderedODESystem
	measured_quantities::Vector{Equation}
	data_sample::Union{Nothing, OrderedDict}
	solver::Any
	p_true::Any
	ic::Any
	unident_count::Int
end

function create_ode_system(name, states, parameters, equations, measured_quantities)
	@named model = ODESystem(equations, t, states, parameters)
	model = complete(model)
	ordered_system = OrderedODESystem(model, parameters, states)
	return ordered_system, measured_quantities
end

function sample_problem_data(problem::ParameterEstimationProblem; datasize = 21, time_interval = [-0.5, 0.5], solver = Vern9())
	# Create new OrderedODESystem with completed system
	ordered_system = OrderedODESystem(
		complete(problem.model.system),  # Complete the inner system
		problem.model.original_parameters,
		problem.model.original_states,
	)

	return ParameterEstimationProblem(
		problem.name,
		ordered_system,
		problem.measured_quantities,
		ODEParameterEstimation.sample_data(ordered_system.system, problem.measured_quantities,
			time_interval, problem.p_true, problem.ic, datasize, solver = solver),
		solver,
		problem.p_true,
		problem.ic,
		problem.unident_count,
	)
end

#=function analyze_estimation_result(problem::ParameterEstimationProblem, result)
	all_params = merge(problem.ic, problem.p_true)
	println("\nTrue values ordering:")
	println("Initial conditions: ", problem.ic)
	println("Parameters: ", problem.p_true)
	println("Combined true values: ", all_params)

	besterror = Inf

	for each in result
		println("\nAnalyzing result:")
		println("States from result: ", collect(keys(each.states)), " => ", collect(values(each.states)))
		println("Parameters from result: ", collect(keys(each.parameters)), " => ", collect(values(each.parameters)))

		estimates = vcat(collect(values(each.states)), collect(values(each.parameters)))
		println("Combined estimates: ", estimates)

		errorvec = abs.((estimates .- all_params) ./ all_params)
		println("Error vector before filtering: ", errorvec)

		if problem.unident_count > 0
			sort!(errorvec)
			for i in 1:problem.unident_count
				pop!(errorvec)
			end
			println("Error vector after removing unidentifiable: ", errorvec)
		end

		besterror = min(besterror, maximum(errorvec))
	end

	println("\nFor model $(problem.name): The max abs rel. err: $besterror")
	return besterror
end=#


function analyze_estimation_result(problem::ParameterEstimationProblem, result)
	# Merge dictionaries into a single OrderedDict
	all_params = merge(OrderedDict(), problem.ic, problem.p_true)

	# println("\nTrue values ordering:")
	# println("Initial conditions: ", problem.ic)
	# println("Parameters: ", problem.p_true)
	# println("Combined true values: ", all_params)

	besterror = Inf
	for each in result
		# println("\nAnalyzing result:")
		# println("States from result: ", keys(each.states), " => ", values(each.states))
		# println("Parameters from result: ", keys(each.parameters), " => ", values(each.parameters))

		# Convert dictionary values to a vector for comparison
		estimates = Vector{Float64}()
		append!(estimates, values(each.states))
		append!(estimates, values(each.parameters))

		# Convert all_params to vector maintaining order
		true_values = collect(values(all_params))

		# println("Combined estimates: ", estimates)
		errorvec = abs.((estimates .- true_values) ./ true_values)
		# println("Error vector before filtering: ", errorvec)

		if problem.unident_count > 0
			sort!(errorvec)
			for i in 1:problem.unident_count
				pop!(errorvec)
			end
			# println("Error vector after removing unidentifiable: ", errorvec)
		end
		besterror = min(besterror, maximum(errorvec))
	end

	println("\nFor model $(problem.name): The max abs rel. err: $besterror")
	return besterror
end
