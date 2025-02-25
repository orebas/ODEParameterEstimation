#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_05-37-59
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
p_true = OrderedDict(muN => 0.8397476912422128, muEE => 0.21228562283892272, muLE => 0.49226016345812906, muLL => 0.550846633452853, muM => 0.2656260143079344, muP => 0.6695796265243036, muPE => 0.8681479701962818, muPL => 0.510607334784694, deltaNE => 0.18928731288218748, deltaEL => 0.6087078128620342, deltaLM => 0.17075253477685398, rhoE => 0.5296023388461153, rhoP => 0.2158364029301823)
ic = OrderedDict(n => 0.6141216137914867, e => 0.2868945074746354, s => 0.8574722565913688, m => 0.5333707824274461, p => 0.5379472742757155)

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
