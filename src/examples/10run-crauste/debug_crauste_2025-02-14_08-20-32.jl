#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_08-20-32
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
p_true = OrderedDict(muN => 0.1911000165208334, muEE => 0.695528597641234, muLE => 0.6539787543115504, muLL => 0.8566123090112997, muM => 0.5030698529101466, muP => 0.7626810554722775, muPE => 0.27602147584660985, muPL => 0.8727873501492729, deltaNE => 0.8066679266077913, deltaEL => 0.1698848522814429, deltaLM => 0.5943493632507021, rhoE => 0.34634900699717674, rhoP => 0.490501372421725)
ic = OrderedDict(n => 0.48052841074966424, e => 0.137139187670995, s => 0.2299771702170971, m => 0.43849412175774893, p => 0.17745523024600818)

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
