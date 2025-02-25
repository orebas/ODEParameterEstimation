#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: hiv
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-11_07-13-19
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
p_true = OrderedDict(lm => 0.6710201898760358, d => 0.6981264728556351, beta => 0.22008998848119346, a => 0.8138117025319342, k => 0.6996730311353179, u => 0.2220083507748635, c => 0.5252307903019194, q => 0.14858983428584321, b => 0.29211795285740944, h => 0.48775943992081083)
ic = OrderedDict(x => 0.3033345865016355, y => 0.6907989657896928, v => 0.2962709477654336, w => 0.18315020362087583, z => 0.8115491118873525)

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
