#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: daisy_mamil3
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-09_14-39-24
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables a13 a31 x1(t) x3(t) a21 a12 a01 x2(t)

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("daisy_mamil3"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(a12 => 0.4696972617434104, a13 => 0.35728620634163355, a21 => 0.7243427028332833, a31 => 0.5400618540668193, a01 => 0.4134508104846333)
ic = OrderedDict(x1 => 0.40967343169686676, x2 => 0.6924717521396302, x3 => 0.6693385719464968)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-1.0, 1.0][1], [-1.0, 1.0][2]], noise_level = 1.0e-6)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
