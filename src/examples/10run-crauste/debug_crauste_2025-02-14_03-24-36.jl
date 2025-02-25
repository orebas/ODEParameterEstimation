#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-14_03-24-36
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
p_true = OrderedDict(muN => 0.3923669612506715, muEE => 0.4670439878105509, muLE => 0.11168930682728534, muLL => 0.5917354583720312, muM => 0.2374633756274748, muP => 0.8063775521912032, muPE => 0.7190043591588651, muPL => 0.8238759241739024, deltaNE => 0.3928107137784912, deltaEL => 0.7214605892412889, deltaLM => 0.289378474538765, rhoE => 0.11473626720158236, rhoP => 0.16729084461456836)
ic = OrderedDict(n => 0.14730247761035697, e => 0.6391064992603368, s => 0.22998279818636957, m => 0.12039487534823241, p => 0.662559483115277)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 1.0e-6)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
