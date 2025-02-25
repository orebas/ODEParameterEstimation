#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: daisy_mamil4
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-13_21-11-48
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables k21 k01 k14 k13 x2(t) x4(t) k12 x1(t) x3(t) k41 k31

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("daisy_mamil4"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(k01 => 0.676230816867267, k12 => 0.48725831768674055, k13 => 0.4590338067662908, k14 => 0.6841286166439848, k21 => 0.3861063637799208, k31 => 0.2896621619553519, k41 => 0.760328512599744)
ic = OrderedDict(x1 => 0.5536604158915538, x2 => 0.22735956863273943, x3 => 0.5927458548643539, x4 => 0.5213849050703283)

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
