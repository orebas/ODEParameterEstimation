using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections


const t = ModelingToolkit.t_nounits
const D = ModelingToolkit.D_nounits

function quadratic_test()
	parameters = @parameters a b c
	states = @variables x1(t) x2(t) x3(t)
	observables = @variables y1(t) y2(t) y3(t)
	p_true = [0.1, 0.9, -1.5]
	ic_true = [2.0, 3.0, 4.0]

	equations = [
		D(x1) ~ -a * x1,
		D(x2) ~ b * b * (x2),
		D(x3) ~ (c + 1) * (c + 0.5) * (x3),
	]
	measured_quantities = [y1 ~ x1, y2 ~ x2, y3 ~ x3]

	model, mq = create_ordered_ode_system("quadratic_test", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"quadratic_test",  #name
		model,
		mq,
		nothing,
		[0.0, 2.0],  #time scale.  they must be floats
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function run_first_example()
	estimation_problem = quadratic_test()
	datasize = 101

	time_interval = isnothing(estimation_problem.recommended_time_interval) ? [0.0, 5.0] : estimation_problem.recommended_time_interval


	estimation_problem_with_data = sample_problem_data(estimation_problem, datasize = 101, time_interval = time_interval, noise_level = 0.0)
	res = analyze_parameter_estimation_problem(estimation_problem_with_data, nooutput = true, interpolator = aaad)


	#display(sol.solution)  #this contains the entire ODE solution, you probably don't want to display this

	#display(analysis_result[1])
end

temp = run_first_example()
0