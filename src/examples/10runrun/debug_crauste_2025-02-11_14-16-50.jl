#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_14-16-50
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
p_true = OrderedDict(muN => 0.8381851254288728, muEE => 0.8674174523159627, muLE => 0.5231392055025252, muLL => 0.22567013973003913, muM => 0.2603729804441177, muP => 0.707668057101614, muPE => 0.5051871054969712, muPL => 0.8815338144584995, deltaNE => 0.5972768113475775, deltaEL => 0.19240707843129093, deltaLM => 0.710525508061866, rhoE => 0.22641113831190163, rhoP => 0.6993822460601097)
ic = OrderedDict(n => 0.1682493823548752, e => 0.8662444898263525, s => 0.548620835421664, m => 0.14990401097086173, p => 0.24199495292209755)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 1.0e-8)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
