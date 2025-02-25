#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-14_04-15-38
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
p_true = OrderedDict(muN => 0.57301141601858, muEE => 0.44336404536507157, muLE => 0.5897661213818818, muLL => 0.26796714219140194, muM => 0.23190204745332554, muP => 0.6062654868447727, muPE => 0.1392163299707705, muPL => 0.6009972415314921, deltaNE => 0.8876226489116728, deltaEL => 0.5890475653058532, deltaLM => 0.771185266212666, rhoE => 0.5158959887341116, rhoP => 0.2967797146357885)
ic = OrderedDict(n => 0.28916255606403474, e => 0.16205528701755734, s => 0.3896748700915693, m => 0.7025262912362038, p => 0.7577732681351028)

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
