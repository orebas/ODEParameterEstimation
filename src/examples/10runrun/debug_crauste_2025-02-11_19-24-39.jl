#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_19-24-39
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
p_true = OrderedDict(muN => 0.7801997339181406, muEE => 0.3134179226430528, muLE => 0.8737741205786475, muLL => 0.5233964978808585, muM => 0.5499930677371901, muP => 0.15096659293083103, muPE => 0.75651333893744, muPL => 0.2605920873773469, deltaNE => 0.5595961994129394, deltaEL => 0.4352001606075222, deltaLM => 0.4148852742401904, rhoE => 0.8290880383464149, rhoP => 0.2990006003233724)
ic = OrderedDict(n => 0.15790788555616297, e => 0.6651166698925335, s => 0.7040341129457904, m => 0.663839094985002, p => 0.47319146052865013)

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
