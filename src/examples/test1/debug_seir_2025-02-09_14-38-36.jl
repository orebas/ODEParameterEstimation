#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: seir
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-09_14-38-36
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
p_true = OrderedDict(a => 0.4588429568243777, b => 0.796460756205163, nu => 0.7287985828486236)
ic = OrderedDict(S => 0.4212296427370692, E => 0.3687513797587225, In => 0.4641114348779892, N => 0.24289852763303754)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-1.0, 1.0][1], [-1.0, 1.0][2]], noise_level = 1.0e-6)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
