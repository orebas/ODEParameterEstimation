#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-14_06-09-40
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
p_true = OrderedDict(muN => 0.5753838121339919, muEE => 0.8323293291235142, muLE => 0.5104268341174234, muLL => 0.6328577783459379, muM => 0.10657804462173281, muP => 0.20983031712718622, muPE => 0.7400137553355366, muPL => 0.6813500624308262, deltaNE => 0.6565445339883752, deltaEL => 0.8327966364125633, deltaLM => 0.2386801902074258, rhoE => 0.40595021116481955, rhoP => 0.6621943739456431)
ic = OrderedDict(n => 0.5706534028754784, e => 0.461914814108507, s => 0.4313419319258093, m => 0.19750711797675413, p => 0.8571807827421755)

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
