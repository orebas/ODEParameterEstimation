#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-12_04-42-59
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
p_true = OrderedDict(muN => 0.7057453184576699, muEE => 0.19053248261567496, muLE => 0.7609695187547062, muLL => 0.23031058069828456, muM => 0.38236563088998143, muP => 0.728842508016433, muPE => 0.23156563020079377, muPL => 0.12964016960401034, deltaNE => 0.441970645339395, deltaEL => 0.5696175378589462, deltaLM => 0.39153604635058914, rhoE => 0.42904164692716074, rhoP => 0.3346242401352895)
ic = OrderedDict(n => 0.8627957435732373, e => 0.6636022030926013, s => 0.8740260645758143, m => 0.3961905102229685, p => 0.24815588488661078)

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
