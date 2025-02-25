#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-14_04-45-23
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
p_true = OrderedDict(muN => 0.44755894208392266, muEE => 0.2468938971245768, muLE => 0.5110686695480557, muLL => 0.8399141870354146, muM => 0.16046683370366424, muP => 0.3845074251557766, muPE => 0.8184232978933997, muPL => 0.686705592220633, deltaNE => 0.3669950568435746, deltaEL => 0.18731430564987372, deltaLM => 0.5648376500040634, rhoE => 0.8217892266608908, rhoP => 0.35347189700661263)
ic = OrderedDict(n => 0.701716976911842, e => 0.8427227994505365, s => 0.7705621163423897, m => 0.8600167743398869, p => 0.7435012698141932)

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
