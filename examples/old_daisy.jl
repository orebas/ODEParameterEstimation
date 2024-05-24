using ParameterEstimation
using ModelingToolkit, DifferentialEquations
solver = Vern9()

@parameters p1 p3 p4 p6 p7 pd
@variables t x1(t) x2(t) x3(t) u0(t) y1(t) y2(t)
D = Differential(t)

ic = [1.0, 2.0, 1.0, 1.0]
time_interval = [0.0, 10.0]
datasize = 20
sampling_times = range(time_interval[1], time_interval[2], length = datasize)
p_true = [0.2, 0.3, 0.5, 0.6, -0.2,1.0] # True Parameters

states = [x1, x2, x3, u0]
parameters = [p1, p3, p4, p6, p7,pd]
@named model = ODESystem([
                             D(x1) ~ x2 + u0 -  p1 * x1,
                             D(x2) ~ p3 * x1 - p4 * x2 + x3,
                             D(x3) ~ p6 * x1 - p7 * x3,
                             D(u0) ~ pd],
                         t, states, parameters)
#measured_quantities = [y1 ~ x1 + x3, y2 ~ x2]
measured_quantities = [
    y1 ~ x1 , 
    y2 ~ u0]

interpolators = Dict(
		"AAA" => ParameterEstimation.aaad,
		#"FHD3" => ParameterEstimation.fhdn(3),
		#"FHD6" => ParameterEstimation.fhdn(6),
		#"FHD8" => ParameterEstimation.fhdn(8),
		#"Fourier" => ParameterEstimation.FourierInterp,
		)


data_sample = ParameterEstimation.sample_data(model, measured_quantities, time_interval,
                                              p_true, ic, datasize; solver = solver)
res = ParameterEstimation.estimate(model, measured_quantities, data_sample;
                                   solver = solver, interpolators = interpolators)
