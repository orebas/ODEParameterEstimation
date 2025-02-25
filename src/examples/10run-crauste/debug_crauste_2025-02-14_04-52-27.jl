#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_04-52-27
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
p_true = OrderedDict(muN => 0.24741848394022992, muEE => 0.29599978460975085, muLE => 0.4162421854118048, muLL => 0.37681880281925617, muM => 0.7871907655625545, muP => 0.7668928483269049, muPE => 0.6098669299935516, muPL => 0.7436396605634186, deltaNE => 0.485087799143781, deltaEL => 0.7186166930811964, deltaLM => 0.22086204480702173, rhoE => 0.21032673758241327, rhoP => 0.1860162436332966)
ic = OrderedDict(n => 0.2943594361018443, e => 0.275206093282775, s => 0.5812403486317627, m => 0.7215079801071238, p => 0.11480168884816351)

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
