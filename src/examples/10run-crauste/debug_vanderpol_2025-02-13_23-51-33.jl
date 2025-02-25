#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: vanderpol
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-13_23-51-33
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables a x1(t) b x2(t)

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("vanderpol"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(a => 0.48271374950253365, b => 0.17846480539937845)
ic = OrderedDict(x1 => 0.21529934054294114, x2 => 0.5637028610210107)

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
