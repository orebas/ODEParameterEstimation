#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: hiv
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 0.0
# Generated on: 2025-02-09_14-19-58
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
p_true = OrderedDict(lm => 0.6618684313791385, d => 0.5466487640881654, beta => 0.339486852087868, a => 0.525945760321096, k => 0.768453805267735, u => 0.47045840649564485, c => 0.19324104141848625, q => 0.45840647390690614, b => 0.10353363572086778, h => 0.73468228340938)
ic = OrderedDict(x => 0.8595889791414535, y => 0.3155935492337688, v => 0.30415189468423276, w => 0.8029412037528267, z => 0.35503238281549054)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-1.0, 1.0][1], [-1.0, 1.0][2]], noise_level = 0.0)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
