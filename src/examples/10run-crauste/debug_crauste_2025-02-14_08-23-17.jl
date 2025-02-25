#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-14_08-23-17
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
p_true = OrderedDict(muN => 0.6626340494987959, muEE => 0.6186309079623384, muLE => 0.5554729854618787, muLL => 0.6274518285545228, muM => 0.41791351577597835, muP => 0.17094211951552268, muPE => 0.17024565094465674, muPL => 0.8615634761912795, deltaNE => 0.6840126786534707, deltaEL => 0.7679838913719852, deltaLM => 0.1090436025857585, rhoE => 0.5078857426274138, rhoP => 0.5759608141073017)
ic = OrderedDict(n => 0.6704196463542403, e => 0.4906281394320694, s => 0.5701605220826317, m => 0.14481030948772045, p => 0.5357620930675366)

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
