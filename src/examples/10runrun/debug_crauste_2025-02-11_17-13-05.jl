#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-11_17-13-05
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
p_true = OrderedDict(muN => 0.7165692006387409, muEE => 0.1251317122388593, muLE => 0.6021082469379097, muLL => 0.6236838285688794, muM => 0.49403383309258186, muP => 0.6230066707302868, muPE => 0.11093029241644325, muPL => 0.4456970614461271, deltaNE => 0.6249115354801685, deltaEL => 0.7902943056803358, deltaLM => 0.14214396973894267, rhoE => 0.3915058734104798, rhoP => 0.7936774284884386)
ic = OrderedDict(n => 0.2135607470482424, e => 0.36909362349949293, s => 0.4849952010753873, m => 0.6612239733266446, p => 0.23858498623972058)

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
