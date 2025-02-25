#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-12_02-21-06
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
p_true = OrderedDict(muN => 0.20362050584617855, muEE => 0.2505356951456366, muLE => 0.3804183643187894, muLL => 0.14571967902291788, muM => 0.8400850731742519, muP => 0.26319168660326253, muPE => 0.6874060767691795, muPL => 0.36503951531666357, deltaNE => 0.502029046788521, deltaEL => 0.25051198932694574, deltaLM => 0.8436307781297205, rhoE => 0.28100359290117705, rhoP => 0.884844982703762)
ic = OrderedDict(n => 0.7409227432132303, e => 0.2341261054225477, s => 0.7524131560294066, m => 0.5176296623121789, p => 0.35377248546411744)

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
