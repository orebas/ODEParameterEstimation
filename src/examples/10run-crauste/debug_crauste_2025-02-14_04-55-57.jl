#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-14_04-55-57
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
p_true = OrderedDict(muN => 0.814743052704843, muEE => 0.18217086926113835, muLE => 0.6412906281720867, muLL => 0.7714344068830727, muM => 0.5264297429049205, muP => 0.20311234216456173, muPE => 0.3322590992357254, muPL => 0.7715799590650864, deltaNE => 0.43448704524271, deltaEL => 0.5935385647583329, deltaLM => 0.8783912504029979, rhoE => 0.7940533856375572, rhoP => 0.41079261472969586)
ic = OrderedDict(n => 0.7208525439732077, e => 0.6837349161816432, s => 0.30487909374479205, m => 0.3581245089564432, p => 0.3018486367019628)

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
