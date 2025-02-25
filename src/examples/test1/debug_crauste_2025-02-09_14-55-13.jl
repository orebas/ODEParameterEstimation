#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-09_14-55-13
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
p_true = OrderedDict(mu_N => 0.4739340685016685, mu_EE => 0.17907313195181063, mu_LE => 0.4186785792160297, mu_LL => 0.21818773620908374, mu_M => 0.5272372999115782, mu_P => 0.44893761983450486, mu_PE => 0.6686296344167497, mu_PL => 0.7109741871551215, delta_NE => 0.823959452157006, delta_EL => 0.6739672348845464, delta_LM => 0.14745348463916114, rho_E => 0.884495800170779, rho_P => 0.4092512671250641)
ic = OrderedDict(N => 0.6183270357320605, E => 0.6577275896308448, L => 0.8664921455382837, M => 0.41663854307850445, P => 0.3952813671452129)

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
