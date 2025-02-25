#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_18-50-24
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
p_true = OrderedDict(muN => 0.4264727219296962, muEE => 0.24549604685552345, muLE => 0.26612569211690973, muLL => 0.5491146405234307, muM => 0.37793465825969796, muP => 0.6399017242453295, muPE => 0.6306934066195704, muPL => 0.43472112024186993, deltaNE => 0.8219226656472375, deltaEL => 0.5548656542501288, deltaLM => 0.6296797970424076, rhoE => 0.4841899990314381, rhoP => 0.5227612567435416)
ic = OrderedDict(n => 0.5722106039198815, e => 0.6748578109672706, s => 0.1748834020742877, m => 0.6247290825369014, p => 0.7804711428498433)

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
