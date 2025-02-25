#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: daisy_mamil3
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-13_14-56-03
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
p_true = OrderedDict(a12 => 0.3154261820436822, a13 => 0.5933866147712069, a21 => 0.2906967593791653, a31 => 0.3531167500340163, a01 => 0.36112637234522704)
ic = OrderedDict(x1 => 0.1807809912802627, x2 => 0.273841033346066, x3 => 0.8582892494124222)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 1.0e-6)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
