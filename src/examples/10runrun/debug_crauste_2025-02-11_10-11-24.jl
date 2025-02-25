#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0
# Generated on: 2025-02-11_10-11-24
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
p_true = OrderedDict(muN => 0.35628290847884025, muEE => 0.7544258373131429, muLE => 0.455168105549699, muLL => 0.17887753330910822, muM => 0.3372442383434361, muP => 0.6326374078627108, muPE => 0.44375615400358737, muPL => 0.5859185940160087, deltaNE => 0.4793331032713791, deltaEL => 0.33967505580982105, deltaLM => 0.48271374950253365, rhoE => 0.17846480539937845, rhoP => 0.21529934054294114)
ic = OrderedDict(n => 0.5637028610210107, e => 0.7144284900694405, s => 0.8989132938658683, m => 0.16745245354422805, p => 0.8711744856910862)

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
