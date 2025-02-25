#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: daisy_mamil4
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.01
# Generated on: 2025-02-11_04-19-22
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
p_true = OrderedDict(k01 => 0.27259365419046616, k12 => 0.308000353721094, k13 => 0.6554444720128638, k14 => 0.39032876929358074, k21 => 0.17230580064364115, k31 => 0.709822469765872, k41 => 0.385167376628759)
ic = OrderedDict(x1 => 0.8016536713257987, x2 => 0.5789390228160153, x3 => 0.7908005859313723, x4 => 0.3591666969099274)

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
