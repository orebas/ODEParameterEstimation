#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_21-38-31
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
p_true = OrderedDict(muN => 0.2992760678814774, muEE => 0.18308779570745806, muLE => 0.12445311510679931, muLL => 0.6035053587466039, muM => 0.7639372542188697, muP => 0.40453361672381305, muPE => 0.596025283172782, muPL => 0.7967238031450765, deltaNE => 0.8409245327052798, deltaEL => 0.8775500821424367, deltaLM => 0.41878601591216713, rhoE => 0.8425745395708769, rhoP => 0.8815854183604749)
ic = OrderedDict(n => 0.7261098871433981, e => 0.6496689695770972, s => 0.4560358301784301, m => 0.1916383712663989, p => 0.5315232425639687)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 1.0e-6)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
