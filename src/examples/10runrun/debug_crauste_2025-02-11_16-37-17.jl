#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_16-37-17
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
p_true = OrderedDict(muN => 0.7572612824120276, muEE => 0.3142399451511489, muLE => 0.4909019424100005, muLL => 0.8904606122402441, muM => 0.6393043637926902, muP => 0.6946003053087528, muPE => 0.2593268286144086, muPL => 0.7340529155589284, deltaNE => 0.18375833210072914, deltaEL => 0.3346317140625057, deltaLM => 0.21743230430591742, rhoE => 0.5814283052420446, rhoP => 0.1152763832733606)
ic = OrderedDict(n => 0.4118280701499032, e => 0.40269886652041664, s => 0.41467228439368087, m => 0.45430354084551705, p => 0.8580816759587683)

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
