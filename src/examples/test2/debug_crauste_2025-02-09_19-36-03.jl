#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 0.0
# Generated on: 2025-02-09_19-36-03
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables mu_N mu_LE mu_P delta_LM mu_PE delta_EL L(t) P(t) delta_NE mu_EE mu_LL mu_M rho_E N(t) rho_P mu_PL M(t) E(t)

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("crauste"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(mu_N => 0.2749739763656336, mu_EE => 0.6239211774431193, mu_LE => 0.3248705851454477, mu_LL => 0.3918341143013969, mu_M => 0.777979783749415, mu_P => 0.6489569949285154, mu_PE => 0.6593806373431585, mu_PL => 0.38271733905362193, delta_NE => 0.1528551928524065, delta_EL => 0.2556085240011632, delta_LM => 0.8710482685094068, rho_E => 0.38752347562362344, rho_P => 0.7234293773996265)
ic = OrderedDict(N => 0.6690180215326035, E => 0.7333902275811901, L => 0.15915793178672458, M => 0.6566732688774409, P => 0.1804954545901324)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-1.0, 1.0][1], [-1.0, 1.0][2]], noise_level = 0.0)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
