#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-12_01-45-49
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
p_true = OrderedDict(muN => 0.5915576017532537, muEE => 0.6214920523175476, muLE => 0.6632864290991776, muLL => 0.156657088178768, muM => 0.1919986365335733, muP => 0.6904647169674996, muPE => 0.39173651863271797, muPL => 0.5783327996273838, deltaNE => 0.41175656591801024, deltaEL => 0.1775384867885019, deltaLM => 0.20291380262090836, rhoE => 0.7524941851282182, rhoP => 0.21392576860812432)
ic = OrderedDict(n => 0.2220473222093573, e => 0.13046909038060328, s => 0.23546813617584839, m => 0.12253278245850785, p => 0.6011908059078992)

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
