#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: vanderpol
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 0.0
# Generated on: 2025-02-09_14-11-49
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables a x1(t) b x2(t)

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("vanderpol"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(a => 0.638676916511597, b => 0.23271554783450724)
ic = OrderedDict(x1 => 0.5907825800006753, x2 => 0.6346722623661822)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-1.0, 1.0][1], [-1.0, 1.0][2]], noise_level = 0.0)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
