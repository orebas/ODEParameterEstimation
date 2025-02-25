#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-13_23-41-58
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables muPE p(t) muLL s(t) rhoP e(t) n(t) muP m(t) rhoE muM muEE deltaNE deltaEL muN muLE muPL deltaLM

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("crauste"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(muN => 0.6034760985140871, muEE => 0.46027115247695494, muLE => 0.48192571474625423, muLL => 0.6625038792025612, muM => 0.638676916511597, muP => 0.23271554783450724, muPE => 0.5907825800006753, muPL => 0.6346722623661822, deltaNE => 0.4656248726413633, deltaEL => 0.3394922363150089, deltaLM => 0.6289146980954964, rhoE => 0.6115450896338794, rhoP => 0.3741183383210783)
ic = OrderedDict(n => 0.3142963507191361, e => 0.5126971266796015, s => 0.17201841283471753, m => 0.3181259566354351, p => 0.25324976207755046)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 1.0e-6)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
