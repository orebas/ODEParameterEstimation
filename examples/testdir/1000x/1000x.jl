#using ParameterEstimation
using ModelingToolkit, DifferentialEquations
using ODEParameterEstimation
solver = Vern9()
@parameters K1 g1 K2 g2 pi
@variables t S0(t) S1(t) S2(t) y0(t) y1(t) y2(t)
D = Differential(t)
states = [S0, S1, S2]
parameters = [K1, g1, K2, g2, pi]
@named model = ODESystem([
		D(S0) ~ -K1 * S0 / (g1 * S0 + g2 * S1 + 1),
		D(S1) ~ (-K2 * S1 + (1 - pi) * K1 * S0) / (g1 * S0 + g2 * S1 + 1),
		D(S2) ~ (pi * K1 * S0 + K2 * S1) / (g1 * S0 + g2 * S1 + 1),
	], t, states, parameters)
measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]
ic = [5.0, 0.0, 0.0]
time_interval = [0.0, 20.0]
datasize = 8
time_points = [0, 0.5, 2, 3.25, 3.75, 5, 10, 20]
grid_num = 4
for i1 in 1:grid_num
	for i2 in 1:grid_num
		for i3 in 1:grid_num
			for i4 in 1:grid_num
				for i5 in 1:grid_num
					p_true = [0.01 + (i1 - 1) / grid_num, 0.01 + (i2 - 1) / grid_num, 0.01 + (i3 - 1) / grid_num, 0.01 + (i4 - 1) / grid_num, 0.01 + (i5 - 1) / grid_num]
					data_sample = sample_data(
						model, measured_quantities, time_interval, p_true,
						ic, datasize; solver = solver, uneven_sampling = true,
						uneven_sampling_times = time_points)

					res = ODEPEtestwrapper(model, measured_quantities,
						data_sample, solver, max_num_points = 11) #at_time = 0.01, 


					println("$i1, $i2, $i3, $i4, $i5")
					println("the results are:")
					display(res)
					for each in res
						estimates = collect(values(each.parameters))
						println("Relative mean square error for parameters: ",
							sqrt(sum([p^2 for p in (p_true - estimates) ./ p_true]) / length(p_true)) * 100, "%")
					end
				end
			end
		end
	end
end
