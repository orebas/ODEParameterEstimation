#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 0.0
# Generated on: 2025-02-09_14-30-28
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
p_true = OrderedDict(mu_N => 0.7668101151363464, mu_EE => 0.21841092623731023, mu_LE => 0.869650718968982, mu_LL => 0.31222749510650616, mu_M => 0.8007486063683277, mu_P => 0.6024398111494524, mu_PE => 0.41886533930182934, mu_PL => 0.6975896822391443, delta_NE => 0.40493872736714287, delta_EL => 0.2954021437919132, delta_LM => 0.6386420591481696, rho_E => 0.7568744658129306, rho_P => 0.15461862572524698)
ic = OrderedDict(N => 0.5020837424143471, E => 0.509405347453868, L => 0.37741934501108654, M => 0.8984421943879658, P => 0.2695923977199419)

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
