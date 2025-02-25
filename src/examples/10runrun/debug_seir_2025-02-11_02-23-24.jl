#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: seir
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.01
# Generated on: 2025-02-11_02-23-24
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables a nu N(t) S(t) b In(t) E(t)

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("seir"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(a => 0.5854195211130916, b => 0.5499223026654717, nu => 0.1645635676254683)
ic = OrderedDict(S => 0.7307803193013934, E => 0.6271998958384809, In => 0.5889736574300186, N => 0.1315372479516846)

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
