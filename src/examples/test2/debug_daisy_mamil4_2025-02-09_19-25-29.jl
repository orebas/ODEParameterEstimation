#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: daisy_mamil4
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 0.0
# Generated on: 2025-02-09_19-25-29
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
p_true = OrderedDict(k01 => 0.39787730346435024, k12 => 0.12414844003136648, k13 => 0.16346711155787264, k14 => 0.6310063964303895, k21 => 0.493646537378729, k31 => 0.6705810461027489, k41 => 0.232368677803505)
ic = OrderedDict(x1 => 0.5217965511213006, x2 => 0.47016799661614017, x3 => 0.7831207656944205, x4 => 0.2390102259513702)

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
