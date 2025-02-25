#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-12_01-10-26
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
p_true = OrderedDict(muN => 0.5348764030506271, muEE => 0.5178943018291536, muLE => 0.4125196895847829, muLL => 0.3724668580823087, muM => 0.23270053309421287, muP => 0.7644756080290351, muPE => 0.3621745263541053, muPL => 0.17766721415562117, deltaNE => 0.7124761585168293, deltaEL => 0.7405030877162979, deltaLM => 0.3580888591307082, rhoE => 0.3183865002718669, rhoP => 0.13391105967355293)
ic = OrderedDict(n => 0.550913271628144, e => 0.7447478627024924, s => 0.6553947034904815, m => 0.32130414546479946, p => 0.7093286363181082)

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
