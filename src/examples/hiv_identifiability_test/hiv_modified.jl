# HIV model variants for identifiability testing
# Testing whether c and q become practically identifiable with:
# 1. Modified initial conditions (infection present at t=0)
# 2. Short time window (where immune dynamics are excited)

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

"""
HIV model with modified initial conditions to test practical identifiability.
Uses y(0)=1, v(0)=10 instead of y(0)=0, v(0)=1e-3 to establish infection from start.
"""
function hiv_modified_ic()
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

	# MODIFIED: Start with actual infection present
	ic_true = [1000.0,  # x: initial uninfected CD4+ T cells (per uL)
		1.0,     # y: initial infected cells (MODIFIED from 0.0)
		10.0,    # v: initial virus (MODIFIED from 1e-3)
		1.0,     # w: initial immune response
		0.0]     # z: initial activated immune cells

	equations = [
		D(x) ~ lm - d * x - beta * x * v,
		D(y) ~ beta * x * v - a * y,
		D(v) ~ k * y - u * v,
		D(w) ~ c * z * y * w - c * q * y * w - b * w,
		D(z) ~ c * q * y * w - h * z,
	]
	measured_quantities = [y1 ~ w, y2 ~ z, y3 ~ x, y4 ~ y + v]

	model, mq = create_ordered_ode_system("hiv_modified_ic", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"hiv_modified_ic",
		model,
		mq,
		nothing,
		[0.0, 10.0],  # SHORT time window where c*q*y*w terms dominate
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

"""
HIV model with original ICs but short time window for comparison.
"""
function hiv_short_window()
	parameters = @parameters lm d beta a k u c q b h
	states = @variables x(t) y(t) v(t) w(t) z(t)
	observables = @variables y1(t) y2(t) y3(t) y4(t)
	p_true = [1.0, 0.01, 2e-5, 0.5, 50.0, 3.0, 0.05, 0.1, 0.002, 0.1]

	# Original ICs - no infection at start
	ic_true = [1000.0, 0.0, 1e-3, 1.0, 0.0]

	equations = [
		D(x) ~ lm - d * x - beta * x * v,
		D(y) ~ beta * x * v - a * y,
		D(v) ~ k * y - u * v,
		D(w) ~ c * z * y * w - c * q * y * w - b * w,
		D(z) ~ c * q * y * w - h * z,
	]
	measured_quantities = [y1 ~ w, y2 ~ z, y3 ~ x, y4 ~ y + v]

	model, mq = create_ordered_ode_system("hiv_short_window", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"hiv_short_window",
		model,
		mq,
		nothing,
		[0.0, 10.0],  # Short window
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end
