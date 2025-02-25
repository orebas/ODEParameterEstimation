#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_20-31-06
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
p_true = OrderedDict(muN => 0.4051088643517994, muEE => 0.4826714108498108, muLE => 0.6007892355700886, muLL => 0.6731234429582637, muM => 0.4089583516761669, muP => 0.624962762433859, muPE => 0.3919155325678958, muPL => 0.3035934547117186, deltaNE => 0.3561702205925248, deltaEL => 0.6280452900787504, deltaLM => 0.5545964282610951, rhoE => 0.35228111340599944, rhoP => 0.8909411601926064)
ic = OrderedDict(n => 0.563667177270721, e => 0.7378938140361029, s => 0.7454304223747518, m => 0.32879010810116727, p => 0.1977193878070402)

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
