#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_22-13-14
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
p_true = OrderedDict(muN => 0.7672228931981809, muEE => 0.2550476731561585, muLE => 0.5786015822546733, muLL => 0.24138183423879767, muM => 0.7246616152485172, muP => 0.6144985249172221, muPE => 0.8019325566523204, muPL => 0.7820283430126064, deltaNE => 0.4900074055808873, deltaEL => 0.2934598406641641, deltaLM => 0.26545791825487075, rhoE => 0.4250262554197074, rhoP => 0.7950226622038582)
ic = OrderedDict(n => 0.3100326999420372, e => 0.6103182806747917, s => 0.5221543577826243, m => 0.7093120726931095, p => 0.797284037908902)

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
