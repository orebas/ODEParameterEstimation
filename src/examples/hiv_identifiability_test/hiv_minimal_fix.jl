# HIV model with MINIMAL fix for practical identifiability
# Only change: y(0) = 1 instead of y(0) = 0
# Keeps original v(0) = 1e-3 and time window [0, 25]

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

"""
HIV model with minimal IC fix - only y(0) changed from 0 to 1.
This is the smallest modification needed to make c and q practically identifiable.
"""
function hiv_minimal_fix()
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

	# MINIMAL FIX: Only change y(0) from 0.0 to 1.0
	ic_true = [1000.0,  # x: initial uninfected CD4+ T cells (per uL)
		1.0,     # y: initial infected cells (CHANGED from 0.0)
		1e-3,    # v: initial virus (UNCHANGED)
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

	model, mq = create_ordered_ode_system("hiv_minimal_fix", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"hiv_minimal_fix",
		model,
		mq,
		nothing,
		[0.0, 25.0],  # UNCHANGED - original time window
		nothing,  # solver
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end
