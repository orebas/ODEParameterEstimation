#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_07-42-22
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
p_true = OrderedDict(muN => 0.6037277691349507, muEE => 0.6215534537588704, muLE => 0.3848011164976549, muLL => 0.6774161067554343, muM => 0.38728390550317304, muP => 0.826750722775412, muPE => 0.875316992568372, muPL => 0.20961534061446932, deltaNE => 0.3630614094198379, deltaEL => 0.45989882817638206, deltaLM => 0.5974467697911142, rhoE => 0.7096535484554141, rhoP => 0.16659119009646287)
ic = OrderedDict(n => 0.837541154058885, e => 0.42652161386821985, s => 0.5562691878094549, m => 0.7232575946369596, p => 0.8012007950297215)

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
