#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_17-46-49
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
p_true = OrderedDict(muN => 0.8502982693432947, muEE => 0.1652410355786511, muLE => 0.8843217644880003, muLL => 0.8175898463647431, muM => 0.14084875482732892, muP => 0.16398499305824926, muPE => 0.2200973500060063, muPL => 0.23472821421434784, deltaNE => 0.25328698442708886, deltaEL => 0.8541008911508878, deltaLM => 0.16145501043801902, rhoE => 0.15499266349571822, rhoP => 0.3919682590538661)
ic = OrderedDict(n => 0.7159592658270779, e => 0.7185488615469727, s => 0.854768247736901, m => 0.41320676930591516, p => 0.17584900665162762)

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
