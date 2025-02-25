#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_03-30-10
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
p_true = OrderedDict(muN => 0.6135716787212895, muEE => 0.5607548699978047, muLE => 0.6600580841627413, muLL => 0.3616245812455672, muM => 0.6322028444413288, muP => 0.11583320332572661, muPE => 0.6697787713218206, muPL => 0.7873636111195237, deltaNE => 0.5747040282623757, deltaEL => 0.6596181519939897, deltaLM => 0.275148203732863, rhoE => 0.5418964686819213, rhoP => 0.3680081044859964)
ic = OrderedDict(n => 0.6506182645329402, e => 0.2300528721561519, s => 0.41105089678892737, m => 0.8338535330748299, p => 0.3261354092569333)

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
