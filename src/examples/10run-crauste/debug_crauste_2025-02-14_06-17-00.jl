#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_06-17-00
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
p_true = OrderedDict(muN => 0.10449726539816623, muEE => 0.3510735988309541, muLE => 0.15171646249969264, muLL => 0.5011318714622894, muM => 0.8368441317665648, muP => 0.34431869564755735, muPE => 0.3832193743964749, muPL => 0.8350388508149608, deltaNE => 0.6680246690934943, deltaEL => 0.6927243632889795, deltaLM => 0.8418486158969954, rhoE => 0.5410324581727181, rhoP => 0.7628636672545775)
ic = OrderedDict(n => 0.5270081908969156, e => 0.7879799124946101, s => 0.2917114681217686, m => 0.44249755759329434, p => 0.2683033001252797)

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
