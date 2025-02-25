#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_15-24-36
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
p_true = OrderedDict(muN => 0.5616673505690385, muEE => 0.15258632924086932, muLE => 0.19753620378847103, muLL => 0.7014887853223677, muM => 0.5109253379788568, muP => 0.45173792795007184, muPE => 0.8423190705615445, muPL => 0.42136881981528285, deltaNE => 0.236172583491019, deltaEL => 0.7735681392172776, deltaLM => 0.8840503045023127, rhoE => 0.6647838902572702, rhoP => 0.8322596277177075)
ic = OrderedDict(n => 0.19533818447110304, e => 0.46718893951703533, s => 0.42796881950279964, m => 0.36709914836263613, p => 0.5738730865767079)

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
