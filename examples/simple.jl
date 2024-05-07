using ModelingToolkit, DifferentialEquations
using ODEParameterEstimation

#using ParameterEstimation





function simple()
	@parameters a b
	@variables t x1(t) x2(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2]
	parameters = [a, b]

	@named model = ODESystem([
			D(x1) ~ -a * x2,
			D(x2) ~ b * x1,  #edited from 1/b
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1,
		y2 ~ x2]

	ic = [0.333, 0.667]
	p_true = [0.4, 0.8]

	model = complete(model)
	data_sample = sample_data(model,measured_quantities, [-1.0,1.0] ,p_true,ic,19, solver = Vern9())

	ret = ODEPEtestwrapper(model, measured_quantities, data_sample,  Vern9())

	display(ret)
	return ret
end

simple()