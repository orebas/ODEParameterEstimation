#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: lotka_volterra
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-13_07-34-41
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables k2 w(t) r(t) k1 k3

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("lotka_volterra"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(k1 => 0.2841587451564046, k2 => 0.2936957821401611, k3 => 0.7361658005804507)
ic = OrderedDict(r => 0.6750914360892971, w => 0.4457780611085157)

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
