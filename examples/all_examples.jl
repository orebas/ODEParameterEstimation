using ODEParameterEstimation
using ModelingToolkit
using DifferentialEquations
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
#using SharedUtils

#=
This file contains a collection of ODE models from various scientific domains, many of which exhibit
interesting dynamical behaviors and numerical challenges. Several models are likely to require
stiff solvers due to multiple time scales or sharp transitions:

Definitely stiff:
- HIV model (multiple timescales: fast viral dynamics vs slow immune response)
- Repressilator (sharp switching in gene expression)
- Two-compartment PK (fast equilibration between compartments vs slow elimination)
- Brusselator (can be stiff near bifurcation points)

Potentially stiff depending on parameters:
- SEIR and Treatment models (during outbreak peaks)
- Crauste model (cell population interactions)
- FitzHugh-Nagumo (during action potential firing)
- Van der Pol (for large parameter values)

The remaining models are generally non-stiff and should work well with standard solvers.
=#

function biohydrogenation()
	parameters = @parameters k5 k6 k7 k8 k9 k10
	states = @variables x4(t) x5(t) x6(t) x7(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.5,    # k5: max rate of first reaction
		2.0,    # k6: Michaelis constant for first reaction
		0.3,    # k7: max rate of second reaction
		1.0,    # k8: Michaelis constant for second reaction
		0.2,    # k9: max rate of third reaction
		5.0]    # k10: carrying capacity
	ic_true = [4.0,   # x4: initial substrate
		0.0,   # x5: initial intermediate 1
		0.0,   # x6: initial intermediate 2
		0.0]   # x7: initial product

	equations = [
		D(x4) ~ -k5 * x4 / (k6 + x4),
		D(x5) ~ k5 * x4 / (k6 + x4) - k7 * x5 / (k8 + x5 + x6),
		D(x6) ~ k7 * x5 / (k8 + x5 + x6) - k9 * x6 * (k10 - x6) / k10,
		D(x7) ~ k9 * x6 * (k10 - x6) / k10,
	]
	measured_quantities = [y1 ~ x4, y2 ~ x5]

	model, mq = create_ordered_ode_system("BioHydrogenation", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"BioHydrogenation",
		model,
		mq,
		nothing, nothing,
		[0.0, 36.0],  # recommended timescale: 36 hours for complete reaction chain
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		1,
	)
end

function crauste()
	parameters = @parameters mu_N mu_EE mu_LE mu_LL mu_M mu_P mu_PE mu_PL delta_NE delta_EL delta_LM rho_E rho_P
	states = @variables N(t) E(t) S(t) M(t) P(t)
	observables = @variables y1(t) y2(t) y3(t) y4(t)
	p_true = [0.05,    # mu_N: death rate of naive cells
		0.02,    # mu_EE: death rate due to cell-cell interaction
		0.1,     # mu_LE: death rate of late cells by early cells
		0.02,    # mu_LL: death rate due to late cell interaction
		0.1,     # mu_M: death rate of memory cells
		0.15,    # mu_P: death rate of proliferating cells
		0.1,     # mu_PE: death rate by early cells
		0.05,    # mu_PL: death rate by late cells
		0.2,     # delta_NE: differentiation rate N->E
		0.2,     # delta_EL: differentiation rate E->L
		0.1,     # delta_LM: differentiation rate L->M
		0.2,     # rho_E: proliferation rate of early cells
		0.3]     # rho_P: self-renewal rate
	ic_true = [1000.0,  # N: initial naive cells
		0.0,     # E: initial early cells
		0.0,     # S: initial late cells
		0.0,     # M: initial memory cells
		100.0]   # P: initial proliferating cells

	equations = [
		D(N) ~ -N * mu_N - N * P * delta_NE,
		D(E) ~ N * P * delta_NE - E^2 * mu_EE - E * delta_EL + E * P * rho_E,
		D(S) ~ S * delta_EL - S * delta_LM - S^2 * mu_LL - E * S * mu_LE,
		D(M) ~ S * delta_LM - mu_M * M,
		D(P) ~ P^2 * rho_P - P * mu_P - E * P * mu_PE - S * P * mu_PL,
	]
	measured_quantities = [y1 ~ N, y2 ~ E, y3 ~ S + M, y4 ~ P]

	model, mq = create_ordered_ode_system("Crauste", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"Crauste",
		model,
		mq,
		nothing,
		[0.0, 100.0],  # recommended timescale: 100 days for cell population dynamics
		nothing,  # solver
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

	model, mq = create_ordered_ode_system("DAISY_ex3", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"DAISY_ex3",
		model,
		mq,
		nothing,
		nothing,  # no specific timescale needed for test model
		nothing,  # solver
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

	model, mq = create_ordered_ode_system("DAISY_mamil3", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"DAISY_mamil3",
		model,
		mq,
		nothing,
		nothing,  # no specific timescale needed for test model
		nothing,  # solver
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

	model, mq = create_ordered_ode_system("DAISY_mamil4", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"DAISY_mamil4",
		model,
		mq,
		nothing,
		nothing,  # no specific timescale needed for test model
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function fitzhugh_nagumo()
	#=
	Simplified model of neuron dynamics, reduction of the Hodgkin-Huxley model.
	Shows excitable behavior with:
	- Fast activation (V) variable
	- Slow recovery (R) variable
	- Can be stiff during action potential firing
	- Exhibits both slow and fast phases
	=#
	parameters = @parameters g a b
	states = @variables V(t) R(t)
	observables = @variables y1(t) y2(t)
	p_true = [3.0, 0.2, 0.2]  # time scale, threshold, recovery
	ic_true = [-1.0, 0.0]     # initial voltage and recovery

	equations = [
		D(V) ~ g * (V - V^3 / 3 + R),
		D(R) ~ 1 / g * (V - a + b * R),
	]
	measured_quantities = [y1 ~ V]

	model, mq = create_ordered_ode_system("fitzhugh-nagumo", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"fitzhugh-nagumo",
		model,
		mq,
		nothing,
		[0.0, 0.03],  # recommended timescale: 30ms for action potential
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function hiv()
	#=
	HIV infection model with immune response.
	Based on models from Perelson et al.
	Combines viral dynamics with immune system response.
	Numerical characteristics:
	- Highly stiff due to multiple timescales
	- Fast: viral replication and clearance (hours)
	- Medium: infected cell death (days)
	- Slow: immune response development (weeks)
	- Benefits greatly from stiff solvers
	=#
	parameters = @parameters lm d beta a k u c q b h
	states = @variables x(t) y(t) v(t) w(t) z(t)
	observables = @variables y1(t) y2(t) y3(t) y4(t)
	p_true = [1.0,     # lm: production of immune cells (per day)
		0.01,    # d: natural death rate of immune cells (per day)
		2e-5,    # beta: infection rate (per virion per day)
		0.5,     # a: death rate of infected cells (per day)
		50.0,    # k: virus production by infected cells (per day)
		3.0,     # u: viral clearance rate (per day)
		0.05,    # c: immune response rate (per day)
		0.1,     # q: probability of immune cell activation
		0.002,   # b: death rate of immune cells (per day)
		0.1]     # h: death rate of activated cells (per day)
	ic_true = [1000.0,  # x: initial uninfected CD4+ T cells (per μL)
		0.0,     # y: initial infected cells
		1e-3,    # v: initial virus (per mL)
		1.0,     # w: initial immune response
		0.0]     # z: initial activated immune cells

	equations = [
		D(x) ~ lm - d * x - beta * x * v,
		D(y) ~ beta * x * v - a * y,
		D(v) ~ k * y - u * v,
		D(w) ~ c * x * y * w - c * q * y * w - b * w,
		D(z) ~ c * q * y * w - h * z,
	]
	measured_quantities = [y1 ~ w, y2 ~ z, y3 ~ x, y4 ~ y + v]

	model, mq = create_ordered_ode_system("hiv", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"hiv",
		model,
		mq,
		nothing,
		[0.0, 180.0],  # recommended timescale: half year to see full immune response
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

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

function lv_periodic()
	parameters = @parameters a b c d
	states = @variables x1(t) x2(t)
	observables = @variables y1(t) y2(t)
	p_true = [1.5, 0.9, 3.0, 0.8]
	ic_true = [2.0, 0.5]

	equations = [
		D(x1) ~ a * x1 - b * x1 * x2,
		D(x2) ~ -c * x2 + d * x1 * x2,
	]
	measured_quantities = [y1 ~ x1, y2 ~ x2]

	model, mq = create_ordered_ode_system("lv_periodic", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"lv_periodic",
		model,
		mq,
		nothing,
		[0.0, 15.0],  # recommended timescale: 15 time units to see periodic behavior
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function seir()
	parameters = @parameters a b nu
	states = @variables S(t) E(t) In(t) N(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.2, 0.4, 0.15]  # recovery rate, infection rate, exposed->infected rate
	ic_true = [990.0, 10.0, 0.0, 1000.0]  # S0=990, E0=10, I0=0, N0=1000

	equations = [
		D(S) ~ -b * S * In / N,
		D(E) ~ b * S * In / N - nu * E,
		D(In) ~ nu * E - a * In,
		D(N) ~ 0,
	]
	measured_quantities = [y1 ~ In, y2 ~ N]

	model, mq = create_ordered_ode_system("SEIR", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"SEIR",
		model,
		mq,
		nothing,
		[0.0, 60.0],  # recommended timescale: 2 months to see disease progression
		nothing,  # solver
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

	model, mq = create_ordered_ode_system("simple", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"simple",
		model,
		mq,
		nothing,
		nothing,  # no specific timescale needed
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function simple_linear_combination()
	parameters = @parameters a b
	states = @variables x1(t) x2(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.4, 0.8]
	ic_true = [1.0, 2.0]

	equations = [
		D(x1) ~ -a * x2,
		D(x2) ~ b * x1,
	]
	measured_quantities = [y1 ~ 2.0 * x1 + 0.5 * x2, y2 ~ 3.0 * x1 - 0.25 * x2]

	model, mq = create_ordered_ode_system("simple_linear_combination", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"simple_linear_combination",
		model,
		mq,
		nothing, nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function threesp_cubed()
	parameters = @parameters a b c
	states = @variables x1(t) x2(t) x3(t)
	observables = @variables y1(t) y2(t) y3(t)
	p_true = [0.1, 0.2, 0.3]
	ic_true = [2.0, 3.0, 4.0]

	equations = [
		D(x1) ~ -a * x2,
		D(x2) ~ -b * x1,
		D(x3) ~ -c * x1,
	]
	measured_quantities = [y1 ~ x1 * x1 * x1, y2 ~ x2 * x2 * x2, y3 ~ x3 * x3 * x3]

	model, mq = create_ordered_ode_system("threesp_cubed", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"threesp_cubed",
		model,
		mq,
		nothing, nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function onesp_cubed()
	parameters = @parameters a
	states = @variables x1(t)
	observables = @variables y1(t)
	p_true = [0.1]
	ic_true = [2.0]

	equations = [
		D(x1) ~ -a * x1,
	]
	measured_quantities = [y1 ~ x1 * x1 * x1]

	model, mq = create_ordered_ode_system("onesp_cubed", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"onesp_cubed",
		model,
		mq,
		nothing, nothing,
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

	model, mq = create_ordered_ode_system("sirsforced", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"sirsforced",
		model,
		mq,
		nothing, nothing,
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

	model, mq = create_ordered_ode_system("slowfast", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"slowfast",
		model,
		mq,
		nothing,
		[0.0, 10.0],  # recommended timescale: 10 time units to see separation of scales
		nothing,  # solver
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

	model, mq = create_ordered_ode_system("substr_test", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"substr_test",
		model,
		mq,
		nothing,
		nothing,  # no specific timescale needed for test model
		nothing,  # solver
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

	model, mq = create_ordered_ode_system("global_unident_test", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"global_unident_test",
		model,
		mq,
		nothing, nothing,
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

	model, mq = create_ordered_ode_system("sum_test", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"sum_test",
		model,
		mq,
		nothing,
		nothing,  # no specific timescale needed for test model
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		3,
	)
end

function trivial_unident()
	parameters = @parameters a b
	states = @variables x1(t)
	observables = @variables y1(t)
	p_true = [0.4 0.6]
	ic_true = [2.0]

	equations = [
		D(x1) ~ (a + b) * x1,
	]
	measured_quantities = [y1 ~ x1]

	model, mq = create_ordered_ode_system("trivial_unident", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"trivial_unident",
		model,
		mq,
		nothing,
		nothing,  # no specific timescale needed for test model
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		4,
	)
end

function treatment()
	parameters = @parameters a b d g nu
	states = @variables In(t) N(t) S(t) Tr(t)
	observables = @variables y1(t) y2(t)
	p_true = [0.2,    # a: recovery rate without treatment
		0.3,    # b: infection rate
		1.5,    # d: treatment effectiveness multiplier
		0.1,    # g: rate of starting treatment
		0.15]   # nu: treatment clearance rate
	ic_true = [10.0,    # In: initial infected
		1000.0,  # N: total population
		990.0,   # S: initial susceptible
		0.0]     # Tr: initial under treatment

	equations = [
		D(In) ~ b * S * In / N + d * b * S * Tr / N - (a + g) * In,
		D(N) ~ 0,
		D(S) ~ -b * S * In / N - d * b * S * Tr / N,
		D(Tr) ~ g * In - nu * Tr,
	]
	measured_quantities = [y1 ~ Tr, y2 ~ N]

	model, mq = create_ordered_ode_system("treatment", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"treatment",
		model,
		mq,
		nothing, nothing,
		[0.0, 40.0],  # recommended timescale: 40 days to see treatment effects
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		6,
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
	#=
	The Brusselator: a classical chemical oscillator model showing limit cycles.
	Named after Brussels, where it was first studied. Shows:
	- Autocatalytic behavior
	- Hopf bifurcation when b > 1 + a^2
	- Can be stiff near the bifurcation points
	=#
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

function repressilator()
	#=
	A synthetic genetic oscillator consisting of three genes repressing each other in a cycle.
	One of the first synthetic biology circuits to demonstrate engineered oscillations.
	Characteristics:
	- Highly nonlinear due to Hill function repression
	- Can be very stiff due to separation between mRNA and protein timescales
	- Shows delayed negative feedback leading to oscillations
	=#
	parameters = @parameters beta n alpha
	states = @variables m1(t) m2(t) m3(t) p1(t) p2(t) p3(t)
	observables = @variables y1(t) y2(t) y3(t)
	p_true = [2.0,    # beta: promoter strength
		2.0,    # n: Hill coefficient
		1.0]    # alpha: protein degradation rate
	ic_true = [0.0, 0.0, 0.0,      # initial mRNA levels
		2.0, 1.0, 3.0]      # initial protein levels

	equations = [
		D(m1) ~ -m1 + beta / (1 + p3^n),
		D(m2) ~ -m2 + beta / (1 + p1^n),
		D(m3) ~ -m3 + beta / (1 + p2^n),
		D(p1) ~ -alpha * (p1 - m1),
		D(p2) ~ -alpha * (p2 - m2),
		D(p3) ~ -alpha * (p3 - m3),
	]
	measured_quantities = [y1 ~ p1, y2 ~ p2, y3 ~ p3]

	model, mq = create_ordered_ode_system("repressilator", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"repressilator",
		model,
		mq,
		nothing, nothing,
		[0.0, 24.0],  # recommended timescale: 24 hours to see multiple gene expression cycles
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function allee_competition()
	#=
	Population dynamics model combining competition with Allee effects.
	Shows rich dynamical behavior:
	- Multiple stable states possible
	- Population collapse below Allee threshold
	- Competitive exclusion or coexistence
	- Generally not stiff unless near extinction points
	=#
	parameters = @parameters r1 r2 K1 K2 A1 A2 b12 b21
	states = @variables N1(t) N2(t)
	observables = @variables y1(t) y2(t)
	p_true = [1.0,     # r1: growth rate species 1
		0.8,     # r2: growth rate species 2
		10.0,    # K1: carrying capacity 1
		8.0,     # K2: carrying capacity 2
		0.2,     # A1: Allee threshold 1
		0.1,     # A2: Allee threshold 2
		0.3,     # b12: competition effect of 2 on 1
		0.4]     # b21: competition effect of 1 on 2
	ic_true = [2.0,    # N1: initial population 1
		1.5]    # N2: initial population 2

	equations = [
		D(N1) ~ r1 * N1 * (1 - N1 / K1) * (N1 - A1) / K1 - b12 * N1 * N2,
		D(N2) ~ r2 * N2 * (1 - N2 / K2) * (N2 - A2) / K2 - b21 * N1 * N2,
	]
	measured_quantities = [y1 ~ N1, y2 ~ N2]

	model, mq = create_ordered_ode_system("allee_competition", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"allee_competition",
		model,
		mq,
		nothing, nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function two_compartment_pk()
	#=
	Two-compartment pharmacokinetic model for drug distribution.
	Central compartment represents blood and well-perfused organs,
	peripheral represents less-perfused tissues.
	Properties:
	- Usually stiff due to fast distribution vs slow elimination
	- Shows bi-exponential decay in concentration
	- Common in drug development and PKPD modeling
	=#
	parameters = @parameters k12 k21 ke V1 V2
	states = @variables C1(t) C2(t)
	observables = @variables y1(t)
	p_true = [0.5,     # k12: transfer rate central to peripheral
		0.25,    # k21: transfer rate peripheral to central
		0.15,    # ke: elimination rate
		1.0,     # V1: volume of central compartment
		2.0]     # V2: volume of peripheral compartment
	ic_true = [10.0,   # C1: initial concentration in central compartment
		0.0]    # C2: initial concentration in peripheral compartment

	equations = [
		D(C1) ~ -k12 * C1 + k21 * C2 * V2 / V1 - ke * C1,
		D(C2) ~ k12 * C1 * V1 / V2 - k21 * C2,
	]
	measured_quantities = [y1 ~ C1]  # typically only central compartment is measured

	model, mq = create_ordered_ode_system("two_compartment_pk", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"two_compartment_pk",
		model,
		mq,
		nothing, nothing,
		[0.0, 48.0],  # recommended timescale: 48 hours for drug distribution and elimination
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

function varied_estimation_main()
	datasize = 101

	models = [
		# Simple test models
		simple(),
		simple_linear_combination(),
		onesp_cubed(),
		threesp_cubed(),
		substr_test(),
		sum_test(),

		# Identifiability test models
		global_unident_test(),
		trivial_unident(),

		# Classical dynamical systems
		lotka_volterra(),
		lv_periodic(),
		vanderpol(),
		brusselator(),

		# Neuroscience
		fitzhugh_nagumo(),

		# Population dynamics
		allee_competition(),

		# Pharmacology
		two_compartment_pk(),

		# Other test models
		daisy_ex3(),
		daisy_mamil3(),
		daisy_mamil4(),
		slowfast(),



		# Biological systems
		hiv(),
		seir(),
		treatment(),
		biohydrogenation(),
		crauste(),
		sirsforced(),
		repressilator()]

	for PEP in models
		# Use the model's recommended timescale if available, otherwise default to [0.0, 5.0]
		time_interval = isnothing(PEP.recommended_time_interval) ? [0.0, 5.0] : PEP.recommended_time_interval
		analyze_parameter_estimation_problem(
			sample_problem_data(PEP, datasize = datasize, time_interval = time_interval),
			test_mode = false,
			showplot = true)
	end
end

#varied_estimation_main()
