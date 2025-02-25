#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_09-28-51
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
p_true = OrderedDict(muN => 0.6164703423805907, muEE => 0.3897847938377056, muLE => 0.5869310277335336, muLL => 0.753877549022598, muM => 0.5578563523356284, muP => 0.8463508243054697, muPE => 0.22572348106944978, muPL => 0.5363450610059501, deltaNE => 0.3703210899689652, deltaEL => 0.22125798589485024, deltaLM => 0.6467154651709438, rhoE => 0.5594805937536057, rhoP => 0.4933541080789148)
ic = OrderedDict(n => 0.7543945237333383, e => 0.6833040125283717, s => 0.5419692715996768, m => 0.8057660661926507, p => 0.15479804274378672)

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
