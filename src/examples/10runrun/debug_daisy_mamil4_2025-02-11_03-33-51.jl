#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: daisy_mamil4
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_03-33-51
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
p_true = OrderedDict(k01 => 0.4651546378020158, k12 => 0.30078206637561405, k13 => 0.2371774937749941, k14 => 0.7725280544747598, k21 => 0.48974309039522723, k31 => 0.5640428067317161, k41 => 0.6115204694297147)
ic = OrderedDict(x1 => 0.24946846154287777, x2 => 0.11063204923559465, x3 => 0.8008675560464747, x4 => 0.831796646328192)

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
