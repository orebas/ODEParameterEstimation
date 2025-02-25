#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: hiv
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-09_14-47-21
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables a y(t) v(t) d u h lm w(t) x(t) q k b beta z(t) c

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("hiv"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(lm => 0.8343999567428327, d => 0.37619676705114624, beta => 0.2074542344498892, a => 0.7662413765450579, k => 0.8666213286819936, u => 0.3106728971907916, c => 0.15506944858927466, q => 0.3761373371859218, b => 0.12181211118959744, h => 0.7496595439799066)
ic = OrderedDict(x => 0.6873958032725723, y => 0.6614275349821052, v => 0.7780052571639687, w => 0.3799131672622694, z => 0.8468587979134473)

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
