#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: fitzhugh_nagumo
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-13_05-21-40
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables a R(t) g b V(t)

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("fitzhugh_nagumo"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(g => 0.8007486063683277, a => 0.6024398111494524, b => 0.41886533930182934)
ic = OrderedDict(V => 0.6975896822391443, R => 0.40493872736714287)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 0.0)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
