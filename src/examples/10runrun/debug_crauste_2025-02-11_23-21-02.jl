#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_23-21-02
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
p_true = OrderedDict(muN => 0.15975927653653335, muEE => 0.5237804139624876, muLE => 0.4784279215364625, muLL => 0.33232663930358786, muM => 0.5766775293885752, muP => 0.13000606693583405, muPE => 0.8071469662472317, muPL => 0.14922001471661306, deltaNE => 0.7386301083111536, deltaEL => 0.1668959213033155, deltaLM => 0.5075678846904793, rhoE => 0.5520375003634312, rhoP => 0.35549481733054944)
ic = OrderedDict(n => 0.8007323734288406, e => 0.7074077811763927, s => 0.7290645351797658, m => 0.8931390306609712, p => 0.81773513579712)

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
