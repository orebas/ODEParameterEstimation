#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.01
# Generated on: 2025-02-14_02-19-55
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
p_true = OrderedDict(muN => 0.1847978547469091, muEE => 0.8909343132153646, muLE => 0.4023562722124049, muLL => 0.734800590439528, muM => 0.20186465685423124, muP => 0.1075628685058657, muPE => 0.8686653422271207, muPL => 0.3110092596944799, deltaNE => 0.3248220279708659, deltaEL => 0.4389395419712232, deltaLM => 0.6606873911572384, rhoE => 0.84892967612617, rhoP => 0.38102073242959145)
ic = OrderedDict(n => 0.3258304606819813, e => 0.401068690965391, s => 0.3140454568283116, m => 0.8856681679893438, p => 0.2879886906274167)

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
