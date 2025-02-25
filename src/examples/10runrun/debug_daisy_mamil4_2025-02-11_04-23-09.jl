#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: daisy_mamil4
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.01
# Generated on: 2025-02-11_04-23-09
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
p_true = OrderedDict(k01 => 0.7968897445146942, k12 => 0.4371338397961434, k13 => 0.5469521270696597, k14 => 0.40235548646701136, k21 => 0.48383687380565277, k31 => 0.8434587517180953, k41 => 0.24386923255163176)
ic = OrderedDict(x1 => 0.5878848924848196, x2 => 0.7368265087637984, x3 => 0.3636213053243338, x4 => 0.13961596546179528)

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
