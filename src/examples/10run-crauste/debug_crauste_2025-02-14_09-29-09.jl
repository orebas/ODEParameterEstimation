#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-14_09-29-09
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
p_true = OrderedDict(muN => 0.5216295680702, muEE => 0.22328234697894597, muLE => 0.5136405996441746, muLL => 0.47019606776742917, muM => 0.41363520589355995, muP => 0.5860097823688727, muPE => 0.34605579119145, muPL => 0.7765698146791279, deltaNE => 0.862661381057732, deltaEL => 0.45658157833263036, deltaLM => 0.16587967746646343, rhoE => 0.576264789453527, rhoP => 0.49247499743499834)
ic = OrderedDict(n => 0.20315549792813137, e => 0.819514000898644, s => 0.31622087938189924, m => 0.3059154642352411, p => 0.6611034907359039)

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
