#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_14-51-15
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
p_true = OrderedDict(muN => 0.5841380586421564, muEE => 0.789313671230056, muLE => 0.18020937749815805, muLL => 0.436596683233096, muM => 0.6563002985012314, muP => 0.5087823078960416, muPE => 0.7321114442207097, muPL => 0.21622455145614936, deltaNE => 0.42124130452721464, deltaEL => 0.39260408232487565, deltaLM => 0.3118059475052335, rhoE => 0.48313452742106144, rhoP => 0.5735268083230328)
ic = OrderedDict(n => 0.3010148281455741, e => 0.4248143016748881, s => 0.5543672725173191, m => 0.19346823937594754, p => 0.6331025908065755)

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
