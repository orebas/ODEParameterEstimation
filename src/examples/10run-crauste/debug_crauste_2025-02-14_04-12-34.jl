#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_04-12-34
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
p_true = OrderedDict(muN => 0.36184322767447763, muEE => 0.7252868149443191, muLE => 0.7109444547615605, muLL => 0.3813757097009445, muM => 0.8481014957164542, muP => 0.28376630745936193, muPE => 0.2766949577531227, muPL => 0.8626511141944776, deltaNE => 0.4427237108497051, deltaEL => 0.6194899853989523, deltaLM => 0.30032830136321165, rhoE => 0.3957334379583406, rhoP => 0.8446073335657593)
ic = OrderedDict(n => 0.42289027572036963, e => 0.5212561163099203, s => 0.1929049511629657, m => 0.6319659784504833, p => 0.7259310944771875)

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
