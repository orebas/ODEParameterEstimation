using ODEParameterEstimation
using ModelingToolkit
using DifferentialEquations
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
#using SharedUtils

function biohydrogenation()
	parameters = @parameters k5 k6 k7 k8 k9 k10
	states = @variables x4(t) x5(t) x6(t) x7(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.143, 0.286, 0.429, 0.571, 0.714, 0.857]
	ic_true = [0.2, 0.4, 0.6, 0.8]

	equations = [
		D(x4) ~ -k5 * x4 / (k6 + x4),
		D(x5) ~ k5 * x4 / (k6 + x4) - k7 * x5 / (k8 + x5 + x6),
		D(x6) ~ k7 * x5 / (k8 + x5 + x6) - k9 * x6 * (k10 - x6) / k10,
		D(x7) ~ k9 * x6 * (k10 - x6) / k10,
	]
	measured_quantities = [y1 ~ x4, y2 ~ x5]

	model, mq = create_ode_system("BioHydrogenation", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"BioHydrogenation",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		1,
	)
end

function crauste()
	parameters = @parameters mu_N mu_EE mu_LE mu_LL mu_M mu_P mu_PE mu_PL delta_NE delta_EL delta_LM rho_E rho_P
	states = @variables N(t) E(t) S(t) M(t) P(t)
	observables = @variables y1(t) y2(t) y3(t) y4(t)
	p_true = [0.071, 0.143, 0.214, 0.286, 0.357, 0.429, 0.5, 0.571, 0.643, 0.714, 0.786, 0.857, 0.929]
	ic_true = [0.167, 0.333, 0.5, 0.667, 0.833]

	equations = [
		D(N) ~ -N * mu_N - N * P * delta_NE,
		D(E) ~ N * P * delta_NE - E^2 * mu_EE - E * delta_EL + E * P * rho_E,
		D(S) ~ S * delta_EL - S * delta_LM - S^2 * mu_LL - E * S * mu_LE,
		D(M) ~ S * delta_LM - mu_M * M,
		D(P) ~ P^2 * rho_P - P * mu_P - E * P * mu_PE - S * P * mu_PL,
	]
	measured_quantities = [y1 ~ N, y2 ~ E, y3 ~ S + M, y4 ~ P]

	model, mq = create_ode_system("Crauste", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"Crauste",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function daisy_ex3()
	parameters = @parameters p1 p3 p4 p6 p7
	states = @variables x1(t) x2(t) x3(t) u0(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.167, 0.333, 0.5, 0.667, 0.833]
	ic_true = [0.2, 0.4, 0.6, 0.8]

	equations = [
		D(x1) ~ -1.0 * p1 * x1 + x2 + u0,
		D(x2) ~ p3 * x1 - p4 * x2 + x3,
		D(x3) ~ p6 * x1 - p7 * x3,
		D(u0) ~ 1.0,
	]
	measured_quantities = [y1 ~ x1, y2 ~ u0]

	model, mq = create_ode_system("DAISY_ex3", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"DAISY_ex3",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function daisy_mamil3()
	parameters = @parameters a12 a13 a21 a31 a01
	states = @variables x1(t) x2(t) x3(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.167, 0.333, 0.5, 0.667, 0.833]
	ic_true = [0.25, 0.5, 0.75]

	equations = [
		D(x1) ~ -(a21 + a31 + a01) * x1 + a12 * x2 + a13 * x3,
		D(x2) ~ a21 * x1 - a12 * x2,
		D(x3) ~ a31 * x1 - a13 * x3,
	]
	measured_quantities = [y1 ~ x1, y2 ~ x2]

	model, mq = create_ode_system("DAISY_mamil3", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"DAISY_mamil3",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function daisy_mamil4()
	parameters = @parameters k01 k12 k13 k14 k21 k31 k41
	states = @variables x1(t) x2(t) x3(t) x4(t)
	observables = @variables y1(t) y2(t) y3(t)
	p_true = [0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875]
	ic_true = [0.2, 0.4, 0.6, 0.8]

	equations = [
		D(x1) ~ -k01 * x1 + k12 * x2 + k13 * x3 + k14 * x4 - k21 * x1 - k31 * x1 - k41 * x1,
		D(x2) ~ -k12 * x2 + k21 * x1,
		D(x3) ~ -k13 * x3 + k31 * x1,
		D(x4) ~ -k14 * x4 + k41 * x1,
	]
	measured_quantities = [y1 ~ x1, y2 ~ x2, y3 ~ x3 + x4]

	model, mq = create_ode_system("DAISY_mamil4", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"DAISY_mamil4",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function fitzhugh_nagumo()
	parameters = @parameters g a b
	states = @variables V(t) R(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.25, 0.5, 0.75]
	ic_true = [0.333, 0.67]

	#states = [V, R]
	#parameters = [g, a, b]
	equations = [
		D(V) ~ g * (V - V^3 / 3 + R),
		D(R) ~ 1 / g * (V - a + b * R),
	]
	measured_quantities = [y1 ~ V]

	model, mq = create_ode_system("fitzhugh-nagumo", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"fitzhugh-nagumo",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function hiv()
	parameters = @parameters lm d beta a k u c q b h
	states = @variables x(t) y(t) v(t) w(t) z(t)
	observables = @variables y1(t) y2(t) y3(t) y4(t)
	p_true = [0.091, 0.181, 0.273, 0.364, 0.455, 0.545, 0.636, 0.727, 0.818, 0.909]
	ic_true = [0.167, 0.333, 0.5, 0.667, 0.833]

	equations = [
		D(x) ~ lm - d * x - beta * x * v,
		D(y) ~ beta * x * v - a * y,
		D(v) ~ k * y - u * v,
		D(w) ~ c * x * y * w - c * q * y * w - b * w,
		D(z) ~ c * q * y * w - h * z,
	]
	measured_quantities = [y1 ~ w, y2 ~ z, y3 ~ x, y4 ~ y + v]

	model, mq = create_ode_system("hiv", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"hiv",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function lotka_volterra()
	parameters = @parameters k1 k2 k3
	states = @variables r(t) w(t)
	observables = @variables y1(t)
	p_true = [0.25, 0.5, 0.75]
	ic_true = [0.333, 0.667]

	equations = [
		D(r) ~ k1 * r - k2 * r * w,
		D(w) ~ k2 * r * w - k3 * w,
	]
	measured_quantities = [y1 ~ r]

	model, mq = create_ode_system("Lotka_Volterra", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"Lotka_Volterra",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function seir()
	parameters = @parameters a b nu
	states = @variables S(t) E(t) In(t) N(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.25, 0.5, 0.75]
	ic_true = [0.2, 0.4, 0.6, 0.8]

	equations = [
		D(S) ~ -b * S * In / N,
		D(E) ~ b * S * In / N - nu * E,
		D(In) ~ nu * E - a * In,
		D(N) ~ 0,
	]
	measured_quantities = [y1 ~ In, y2 ~ N]

	model, mq = create_ode_system("SEIR", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"SEIR",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function simple()
	parameters = @parameters a b
	states = @variables x1(t) x2(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.4, 0.8]
	ic_true = [0.333, 0.667]

	equations = [
		D(x1) ~ -a * x2,
		D(x2) ~ b * x1,
	]
	measured_quantities = [y1 ~ x1, y2 ~ x2]

	model, mq = create_ode_system("simple", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"simple",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end


function sirsforced()
	parameters = @parameters b0 b1 g M mu nu
	states = @variables i(t) r(t) s(t) x1(t) x2(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.143, 0.286, 0.429, 0.571, 0.714, 0.857]
	ic_true = [0.167, 0.333, 0.5, 0.667, 0.833]

	equations = [
		D(i) ~ b0 * (1.0 + b1 * x1) * i * s - (nu + mu) * i,
		D(r) ~ nu * i - (mu + g) * r,
		D(s) ~ mu - mu * s - b0 * (1.0 + b1 * x1) * i * s + g * r,
		D(x1) ~ -M * x2,
		D(x2) ~ M * x1,
	]
	measured_quantities = [y1 ~ i, y2 ~ r]

	model, mq = create_ode_system("sirsforced", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"sirsforced",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		3,
	)
end

function slowfast()
	parameters = @parameters k1 k2 eB
	states = @variables xA(t) xB(t) xC(t) eA(t) eC(t)
	observables = @variables y1(t) y2(t) y3(t) y4(t)
	p_true = [0.25, 0.5, 0.75]
	ic_true = [0.166, 0.333, 0.5, 0.666, 0.833]

	equations = [
		D(xA) ~ -k1 * xA,
		D(xB) ~ k1 * xA - k2 * xB,
		D(xC) ~ k2 * xB,
		D(eA) ~ 0,
		D(eC) ~ 0,
	]
	measured_quantities = [y1 ~ xC, y2 ~ eA * xA + eB * xB + eC * xC, y3 ~ eA, y4 ~ eC]

	model, mq = create_ode_system("slowfast", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"slowfast",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function substr_test()
	parameters = @parameters a b beta
	states = @variables x1(t) x2(t) x3(t)
	observables = @variables y1(t) y2(t) y3(t)
	p_true = [0.1, 0.2, 0.3]
	ic_true = [2.0, 3.0, 4.0]

	equations = [
		D(x1) ~ -a * x2,
		D(x2) ~ b * (x1),
		D(x3) ~ a * b * beta * b * a * x3,
	]
	measured_quantities = [y1 ~ x1, y2 ~ x2, y3 ~ x3]

	model, mq = create_ode_system("substr_test", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"substr_test",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function global_unident_test()
	parameters = @parameters a b c d
	states = @variables x1(t) x2(t) x3(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.1, 0.2, 0.3, 0.4]
	ic_true = [2.0, 3.0, 4.0]

	equations = [
		D(x1) ~ -a * x1,
		D(x2) ~ (b + c) * (x1),
		D(x3) ~ d * x1,
	]
	measured_quantities = [y1 ~ x1, y2 ~ x2]

	model, mq = create_ode_system("global_unident_test", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"global_unident_test",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		4,
	)
end

function sum_test()
	parameters = @parameters a b c
	states = @variables x1(t) x2(t) x3(t)
	observables = @variables y1(t)
	p_true = [0.1, 0.2, 0.3]
	ic_true = [2.0, 3.0, 4.0]

	equations = [
		D(x1) ~ -a * x1,
		D(x2) ~ b * (x2),
		D(x3) ~ c * (x1 + x2),
	]
	measured_quantities = [y1 ~ x3]

	model, mq = create_ode_system("sum_test", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"sum_test",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		3,
	)
end

function treatment()
	parameters = @parameters a b d g nu
	states = @variables In(t) N(t) S(t) Tr(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.167, 0.333, 0.5, 0.667, 0.833]
	ic_true = [0.2, 0.4, 0.6, 0.8]

	equations = [
		D(In) ~ b * S * In / N + d * b * S * Tr / N - (a + g) * In,
		D(N) ~ 0,
		D(S) ~ -b * S * In / N - d * b * S * Tr / N,
		D(Tr) ~ g * In - nu * Tr,
	]
	measured_quantities = [y1 ~ Tr, y2 ~ N]

	model, mq = create_ode_system("treatment", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"treatment",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		6,
	)
end

function vanderpol()
	parameters = @parameters a b
	states = @variables x1(t) x2(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.4, 0.8]
	ic_true = [0.333, 0.667]

	equations = [
		D(x1) ~ a * x2,
		D(x2) ~ -(x1) - b * (x1^2 - 1) * (x2),
	]
	measured_quantities = [y1 ~ x1, y2 ~ x2]

	model, mq = create_ode_system("vanderpol", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"vanderpol",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function analyze_parameter_estimation_problem(PEP::ParameterEstimationProblem; test_mode = false, showplot = true, run_ode_pe = true)
	if run_ode_pe
		println("Starting model: ", PEP.name)
		res = ODEPEtestwrapper(PEP.model, PEP.measured_quantities, PEP.data_sample, PEP.solver)
		besterror = analyze_estimation_result(PEP, res)

		if test_mode
			# @test besterror < 1e-1
		end
	end
end

function varied_estimation_main()
	println("testing")
	time_interval = [-0.5, 0.5]
	datasize = 21




	models = [
		treatment(),
		simple(),
		substr_test(),
		vanderpol(),
		daisy_mamil3(),
		fitzhugh_nagumo(),
		slowfast(),
		daisy_ex3(),
		sum_test(),
		daisy_mamil4(),
		lotka_volterra(),
		global_unident_test(),
		hiv(),
		seir(),
		biohydrogenation(),
		crauste(),
		sirsforced(),
	]

	#models = [
	#	fitzhugh_nagumo(),
	#]


	for PEP in models
		analyze_parameter_estimation_problem(sample_problem_data(PEP, datasize = datasize, time_interval = time_interval), test_mode = false, showplot = true)
	end
end

varied_estimation_main()
