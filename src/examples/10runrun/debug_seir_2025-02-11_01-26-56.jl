#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: seir
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-11_01-26-56
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
p_true = OrderedDict(a => 0.29027509144981745, b => 0.4818633244923052, nu => 0.4186299200358826)
ic = OrderedDict(S => 0.6730842504731509, E => 0.6835533080164409, In => 0.7178151569390553, N => 0.4679651130006456)

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
