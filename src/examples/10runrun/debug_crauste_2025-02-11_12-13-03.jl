#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-11_12-13-03
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables muPE p(t) muLL s(t) rhoP e(t) n(t) muP m(t) rhoE muM muEE deltaNE deltaEL muN muLE muPL deltaLM

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("crauste"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(muN => 0.5473121123728611, muEE => 0.8708124736722762, muLE => 0.1825039706304745, muLL => 0.46580621981436, muM => 0.5325638511689947, muP => 0.4627814810803276, muPE => 0.53330201147704, muPL => 0.8296527847546437, deltaNE => 0.76810217068822, deltaEL => 0.875156543541597, deltaLM => 0.7042758671454297, rhoE => 0.6645426460093246, rhoP => 0.8576385238485803)
ic = OrderedDict(n => 0.7513612731018673, e => 0.16141363665374453, s => 0.28419136633696934, m => 0.20929832572304452, p => 0.3746245915242553)

pep = ParameterEstimationProblem(
	original_pep.name,
	original_pep.model,
	original_pep.measured_quantities,
	original_pep.data_sample,
	original_pep.recommended_time_interval,
	original_pep.solver,
	p_true,
	ic,
	original_pep.unident_count
)

# Use the specified time interval and sample size.
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 0.0)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
