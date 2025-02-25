#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: daisy_mamil3
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-11_02-48-05
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables a13 a31 x1(t) x3(t) a21 a12 a01 x2(t)

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("daisy_mamil3"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(a12 => 0.287197672771719, a13 => 0.23953802990865336, a21 => 0.2655260811262211, a31 => 0.7499361876274164, a01 => 0.10597072102771446)
ic = OrderedDict(x1 => 0.6684355456998844, x2 => 0.14156338086208084, x3 => 0.47689784701392635)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 0.0001)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
