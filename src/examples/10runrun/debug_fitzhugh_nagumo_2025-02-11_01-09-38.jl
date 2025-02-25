#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: fitzhugh_nagumo
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_01-09-38
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
p_true = OrderedDict(g => 0.43437042301514095, a => 0.494903977340272, b => 0.5853228467221777)
ic = OrderedDict(V => 0.7583136843321475, R => 0.38954926087416986)

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
