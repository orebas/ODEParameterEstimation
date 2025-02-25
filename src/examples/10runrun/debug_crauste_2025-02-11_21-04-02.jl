#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_21-04-02
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
p_true = OrderedDict(muN => 0.377041330882946, muEE => 0.24656415795073477, muLE => 0.7665890513705257, muLL => 0.5865921944624114, muM => 0.4587589832422082, muP => 0.4723704523902694, muPE => 0.15335155387521526, muPL => 0.21664421115759458, deltaNE => 0.8635623663870684, deltaEL => 0.5132046935623833, deltaLM => 0.2686190351927018, rhoE => 0.8533245205773596, rhoP => 0.7228663970259682)
ic = OrderedDict(n => 0.21985521019138413, e => 0.5670632620912672, s => 0.21731071642625344, m => 0.21829118639318681, p => 0.6721220275016867)

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
