#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-14_07-07-36
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
p_true = OrderedDict(muN => 0.43764532201490025, muEE => 0.7085707573704122, muLE => 0.6399153977837397, muLL => 0.6261062895450871, muM => 0.5264585710677337, muP => 0.8011161978772909, muPE => 0.5129683164197312, muPL => 0.8673665473479056, deltaNE => 0.46613052124722976, deltaEL => 0.2930367993954164, deltaLM => 0.19887438173838, rhoE => 0.7424208057294159, rhoP => 0.23540589054799232)
ic = OrderedDict(n => 0.7629312033870036, e => 0.1448605568115359, s => 0.5767029379496939, m => 0.5670169748133057, p => 0.3923669612506715)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 0.0)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
