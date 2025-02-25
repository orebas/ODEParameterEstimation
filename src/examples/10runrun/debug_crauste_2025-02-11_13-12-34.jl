#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_13-12-34
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
p_true = OrderedDict(muN => 0.15710896537428376, muEE => 0.6255501400187762, muLE => 0.2617545714840306, muLL => 0.5719817964085685, muM => 0.6540233242489797, muP => 0.3306857082350535, muPE => 0.6743994328079739, muPL => 0.7088282055414544, deltaNE => 0.5416855842001774, deltaEL => 0.15817901093702275, deltaLM => 0.5450390131198913, rhoE => 0.5585710965312904, rhoP => 0.5919907185713521)
ic = OrderedDict(n => 0.40704053054550937, e => 0.2880286414287335, s => 0.11362849294903327, m => 0.7701499534418387, p => 0.2622848158429586)

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
