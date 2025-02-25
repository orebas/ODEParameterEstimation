#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-11_09-37-28
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
p_true = OrderedDict(muN => 0.48612587536663143, muEE => 0.8656317473281218, muLE => 0.7718748873444565, muLL => 0.1845457814804493, muM => 0.8079605876284867, muP => 0.4270545448815769, muPE => 0.6232975110157716, muPL => 0.21193884763209525, deltaNE => 0.6687659444088714, deltaEL => 0.86796792606341, deltaLM => 0.631871044830554, rhoE => 0.18098295629958416, rhoP => 0.29561780739600885)
ic = OrderedDict(n => 0.7083166282507645, e => 0.7869628133652314, s => 0.14521670471513543, m => 0.7211764796933734, p => 0.16591773832451262)

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
