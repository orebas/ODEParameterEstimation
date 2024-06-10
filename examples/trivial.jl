using ModelingToolkit, DifferentialEquations
using ODEParameterEstimation

#using ParameterEstimation





function simple()
	@parameters a b
	@variables t x1(t) y1(t)
	D = Differential(t)
	states = [x1]
	parameters = [a]

	@named model = ODESystem([
			D(x1) ~ a * x1,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1]

	ic = [0.333]
	p_true = [0.4]

	model = complete(model)
	data_sample = sample_data(model, measured_quantities, [-1.0, 1.0], p_true, ic, 19, solver = Vern9())

	ret = ODEPEtestwrapper(model, measured_quantities, data_sample, Vern9())

	display(ret)
	return ret
end

simple()