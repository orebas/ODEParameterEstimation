#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-09_14-48-56
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
p_true = OrderedDict(mu_N => 0.4496132354210326, mu_EE => 0.34650672724207815, mu_LE => 0.4856180275540404, mu_LL => 0.4887000477582085, mu_M => 0.10362853492201288, mu_P => 0.43204449385009724, mu_PE => 0.26054977481333763, mu_PL => 0.16024301882929964, delta_NE => 0.3677114368007047, delta_EL => 0.2589264966179119, delta_LM => 0.6415768108170788, rho_E => 0.7523438064482482, rho_P => 0.10179478096626378)
ic = OrderedDict(N => 0.25297433594279073, E => 0.6365755577735709, L => 0.7631374668671272, M => 0.4499378447012028, P => 0.3874939003974114)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-1.0, 1.0][1], [-1.0, 1.0][2]], noise_level = 1.0e-6)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
