#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-14_03-29-26
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
p_true = OrderedDict(muN => 0.3661921589859308, muEE => 0.5781115582238215, muLE => 0.3951015705618771, muLL => 0.2994415856281896, muM => 0.4672696351418405, muP => 0.4548546191567605, muPE => 0.8383374023767546, muPL => 0.2812978661961367, deltaNE => 0.8644956506708102, deltaEL => 0.11948509687855663, deltaLM => 0.8183427325969167, rhoE => 0.6284496418573546, rhoP => 0.3651943361607063)
ic = OrderedDict(n => 0.22386755330517288, e => 0.5938924828487956, s => 0.5099240561959466, m => 0.11349402697018683, p => 0.18437104592128994)

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
