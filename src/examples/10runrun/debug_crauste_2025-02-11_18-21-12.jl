#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_18-21-12
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
p_true = OrderedDict(muN => 0.47704380993631657, muEE => 0.7669697415520655, muLE => 0.4513635372030189, muLL => 0.25489566561048094, muM => 0.5918954385981592, muP => 0.2473333974354504, muPE => 0.5350491603295225, muPL => 0.4629875538850585, deltaNE => 0.43206449529075686, deltaEL => 0.20529678770051626, deltaLM => 0.2869824063459593, rhoE => 0.7982786812144681, rhoP => 0.16853197578974272)
ic = OrderedDict(n => 0.23135088932047765, e => 0.16779649311071304, s => 0.5797329627848283, m => 0.8613652290058752, p => 0.5192894818028151)

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
