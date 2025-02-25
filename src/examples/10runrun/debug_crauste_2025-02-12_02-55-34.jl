#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-12_02-55-34
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
p_true = OrderedDict(muN => 0.7541532777151633, muEE => 0.4877613112437881, muLE => 0.5245445518615609, muLL => 0.222051196246131, muM => 0.6214876437403662, muP => 0.3846895502208372, muPE => 0.3738310325796257, muPL => 0.7875017931715725, deltaNE => 0.673032717753781, deltaEL => 0.1711097308644825, deltaLM => 0.8257369159447001, rhoE => 0.8760518384962959, rhoP => 0.14718764177554267)
ic = OrderedDict(n => 0.32048428491894115, e => 0.2084164096672149, s => 0.25990331462031036, m => 0.39789698483748104, p => 0.634482446981053)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 0.0001)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
