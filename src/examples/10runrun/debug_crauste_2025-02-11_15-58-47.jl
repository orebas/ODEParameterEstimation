#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_15-58-47
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
p_true = OrderedDict(muN => 0.42027878740658275, muEE => 0.7291200115025862, muLE => 0.38030452471129983, muLL => 0.38639683514239276, muM => 0.5394169539184889, muP => 0.6702510354118583, muPE => 0.2595142228950802, muPL => 0.23336284194136248, deltaNE => 0.10557516187500458, deltaEL => 0.4461856298154403, deltaLM => 0.7699284873791051, rhoE => 0.5065296022431903, rhoP => 0.6183413625651173)
ic = OrderedDict(n => 0.44859755337511587, e => 0.7444956639927506, s => 0.6197578896187151, m => 0.5003736945110944, p => 0.18331436849531926)

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
