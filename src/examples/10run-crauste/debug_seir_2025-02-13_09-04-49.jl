#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: seir
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-13_09-04-49
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
p_true = OrderedDict(a => 0.2618659738511673, b => 0.4432639256579429, nu => 0.7210470152655927)
ic = OrderedDict(S => 0.12294236411026285, E => 0.4357426223397075, In => 0.5495495446838664, N => 0.7263609095409406)

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
