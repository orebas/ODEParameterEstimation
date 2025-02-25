#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-12_00-32-10
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
p_true = OrderedDict(muN => 0.3812847722791516, muEE => 0.32671927345343327, muLE => 0.2563397047963871, muLL => 0.1464502981431064, muM => 0.6887411090700422, muP => 0.5823554529060189, muPE => 0.8508217720104382, muPL => 0.7868724169574239, deltaNE => 0.7358816874720557, deltaEL => 0.528369429873802, deltaLM => 0.8935924314180171, rhoE => 0.8909645816282316, rhoP => 0.3955404903225964)
ic = OrderedDict(n => 0.2760647884844135, e => 0.10932537591515717, s => 0.355774427608447, m => 0.4838372627892876, p => 0.22823847593524277)

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
