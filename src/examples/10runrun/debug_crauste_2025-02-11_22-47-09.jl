#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_22-47-09
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
p_true = OrderedDict(muN => 0.5461064423369274, muEE => 0.47859710996531235, muLE => 0.6478134317647317, muLL => 0.8182972386110676, muM => 0.2963129096860133, muP => 0.7982729663626179, muPE => 0.558377487144762, muPL => 0.47035491422122344, deltaNE => 0.5124722096288415, deltaEL => 0.8595680927740359, deltaLM => 0.20808555958512961, rhoE => 0.2290504621973229, rhoP => 0.6255175347713534)
ic = OrderedDict(n => 0.6070332892467121, e => 0.7632055897586253, s => 0.8345501438083008, m => 0.34461491619144935, p => 0.5582880118673292)

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
