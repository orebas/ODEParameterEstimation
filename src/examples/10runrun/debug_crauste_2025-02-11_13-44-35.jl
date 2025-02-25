#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_13-44-35
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
p_true = OrderedDict(muN => 0.37114613934927687, muEE => 0.18093635791066331, muLE => 0.7476009438164815, muLL => 0.4456073299194623, muM => 0.5539043804853471, muP => 0.12674587240115393, muPE => 0.46742200118479516, muPL => 0.8050899207396051, deltaNE => 0.6201980316298736, deltaEL => 0.28416373746377166, deltaLM => 0.45677295061114087, rhoE => 0.4374869698525602, rhoP => 0.2795139346503066)
ic = OrderedDict(n => 0.6657144987076788, e => 0.25516703714415123, s => 0.7283558527736134, m => 0.6761092955340986, p => 0.5045214678333113)

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
