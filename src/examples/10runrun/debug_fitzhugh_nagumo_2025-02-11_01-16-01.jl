#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: fitzhugh_nagumo
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.01
# Generated on: 2025-02-11_01-16-01
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
p_true = OrderedDict(g => 0.26848159378712, a => 0.576162851756648, b => 0.2866086075115367)
ic = OrderedDict(V => 0.3826932862216873, R => 0.7859349069647894)

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
