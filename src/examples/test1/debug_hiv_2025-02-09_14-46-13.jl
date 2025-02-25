#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: hiv
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-09_14-46-13
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
p_true = OrderedDict(lm => 0.3761761410189308, d => 0.5208784176355722, beta => 0.19842490789903985, a => 0.8722439748988187, k => 0.13661800274126393, u => 0.6214499773187494, c => 0.6267806389606896, q => 0.6079087398647943, b => 0.5753838121339919, h => 0.8323293291235142)
ic = OrderedDict(x => 0.5104268341174234, y => 0.6328577783459379, v => 0.10657804462173281, w => 0.20983031712718622, z => 0.7400137553355366)

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
