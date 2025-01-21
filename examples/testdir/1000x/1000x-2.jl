using ModelingToolkit, DifferentialEquations
using ODEParameterEstimation
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

function create_1000x_problem(p_true)
	parameters = @parameters K1 g1 K2 g2 pi
	states = @variables S0(t) S1(t) S2(t)
	observables = @variables y0(t) y1(t) y2(t)
	ic_true = [5.0, 0.0, 0.0]

	equations = [
		D(S0) ~ -K1 * S0 / (g1 * S0 + g2 * S1 + 1),
		D(S1) ~ (-K2 * S1 + (1 - pi) * K1 * S0) / (g1 * S0 + g2 * S1 + 1),
		D(S2) ~ (pi * K1 * S0 + K2 * S1) / (g1 * S0 + g2 * S1 + 1),
	]
	measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]

	model, mq = create_ordered_ode_system("1000x", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"1000x",
		model,
		mq,
		nothing,
		Vern9(),
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function analyze_1000x_problem(PEP::ParameterEstimationProblem, p_true)
	println("Testing with parameters: ", p_true)
	res = ODEPEtestwrapper(PEP.model, PEP.measured_quantities, PEP.data_sample, Vern9(), max_num_points = 11)

	println("The results are:")
	display(res)
	for each in res
		estimates = collect(values(each.parameters))
		println("Relative mean square error for parameters: ",
			sqrt(sum([p^2 for p in (p_true - estimates) ./ p_true]) / length(p_true)) * 100, "%")
	end
end

# Main execution
time_interval = [0.0, 20.0]
datasize = 8
grid_num = 4
time_points = [0, 0.5, 2, 3.25, 3.75, 5, 10, 20]

for i1 in 1:grid_num
	for i2 in 1:grid_num
		for i3 in 1:grid_num
			for i4 in 1:grid_num
				for i5 in 1:grid_num
					# Create parameter set for this iteration
					p_true = [0.01 + (i1 - 1) / grid_num,
						0.01 + (i2 - 1) / grid_num,
						0.01 + (i3 - 1) / grid_num,
						0.01 + (i4 - 1) / grid_num,
						0.01 + (i5 - 1) / grid_num]

					# Create the problem instance with the current parameters
					PEP = create_1000x_problem(p_true)

					# Sample data
					PEP = sample_problem_data(PEP,
						datasize = datasize,
						time_interval = time_interval,
						solver = Vern9(),
						uneven_sampling = true,
						uneven_sampling_times = time_points)

					# Analyze the problem
					println("$i1, $i2, $i3, $i4, $i5")
					analyze_1000x_problem(PEP, p_true)
				end
			end
		end
	end
end
