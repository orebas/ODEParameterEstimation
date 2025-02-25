#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.01
# Generated on: 2025-02-14_07-40-23
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
p_true = OrderedDict(muN => 0.7791902942953983, muEE => 0.4469139044028708, muLE => 0.8655004538755375, muLL => 0.4347187439202854, muM => 0.4686140979261889, muP => 0.8857517121669386, muPE => 0.29778106259325937, muPL => 0.895037440764078, deltaNE => 0.14449286339498812, deltaEL => 0.536123086699855, deltaLM => 0.27556172007804014, rhoE => 0.7657093592618084, rhoP => 0.24091251552279236)
ic = OrderedDict(n => 0.18480391012805822, e => 0.4724298703105885, s => 0.47241020914849086, m => 0.34003454409312434, p => 0.76418127548451)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 0.01)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
