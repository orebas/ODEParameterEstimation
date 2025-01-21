using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

function lotka_volterra()
	parameters = @parameters k1 k2 k3
	states = @variables r(t) w(t)
	observables = @variables y1(t)
	p_true = [1.0, 0.5, 0.3]  # prey growth, predation rate, predator death
	ic_true = [2.0, 1.0]      # initial prey and predator populations

	equations = [
		D(r) ~ k1 * r - k2 * r * w,
		D(w) ~ k2 * r * w - k3 * w,
	]
	measured_quantities = [y1 ~ r]

	model, mq = create_ordered_ode_system("Lotka_Volterra", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"Lotka_Volterra",
		model,
		mq,
		nothing,
		[0.0, 20.0],  # recommended timescale: 20 time units to see multiple oscillations
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function vanderpol()
	parameters = @parameters a b
	states = @variables x1(t) x2(t)
	observables = @variables y1(t) y2(t)
	p_true = [1.0, 1.0]      # standard van der pol parameters
	ic_true = [2.0, 0.0]     # typical initial displacement and velocity

	equations = [
		D(x1) ~ a * x2,
		D(x2) ~ -(x1) - b * (x1^2 - 1) * (x2),
	]
	measured_quantities = [y1 ~ x1, y2 ~ x2]

	model, mq = create_ordered_ode_system("vanderpol", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"vanderpol",
		model,
		mq,
		nothing, nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function brusselator()
	parameters = @parameters a b
	states = @variables X(t) Y(t)
	observables = @variables y1(t) y2(t)
	p_true = [1.0, 3.0]     # standard parameters for oscillatory behavior
	ic_true = [1.0, 1.0]    # initial concentrations

	equations = [
		D(X) ~ 1.0 - (b + 1) * X + a * X^2 * Y,
		D(Y) ~ b * X - a * X^2 * Y,
	]
	measured_quantities = [y1 ~ X, y2 ~ Y]

	model, mq = create_ordered_ode_system("brusselator", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"brusselator",
		model,
		mq,
		nothing,
		[0.0, 20.0],  # recommended timescale: 20 time units to see oscillations
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end
