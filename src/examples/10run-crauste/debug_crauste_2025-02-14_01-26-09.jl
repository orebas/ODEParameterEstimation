#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-14_01-26-09
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
p_true = OrderedDict(muN => 0.5985958231622586, muEE => 0.7159671251084558, muLE => 0.27329072654344855, muLL => 0.6613557124430514, muM => 0.1561678105799693, muP => 0.17512258410214188, muPE => 0.34649410590000906, muPL => 0.773779918350304, deltaNE => 0.10963073315063597, deltaEL => 0.373408253453583, deltaLM => 0.5409279318712585, rhoE => 0.4310315526264338, rhoP => 0.19042702539874157)
ic = OrderedDict(n => 0.7625074717960029, e => 0.3131642048750892, s => 0.8278418913257999, m => 0.5801605509502804, p => 0.10706976307801447)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 0.0001)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
