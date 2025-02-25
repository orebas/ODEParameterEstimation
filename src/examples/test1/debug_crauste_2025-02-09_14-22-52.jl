#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 0.0
# Generated on: 2025-02-09_14-22-52
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
p_true = OrderedDict(mu_N => 0.33031413982859836, mu_EE => 0.38490163717459946, mu_LE => 0.5750392122165189, mu_LL => 0.37108949334286745, mu_M => 0.3082633870615885, mu_P => 0.35458929426907937, mu_PE => 0.38754486051101666, mu_PL => 0.5487211859466127, delta_NE => 0.345431328785351, delta_EL => 0.8322985115221572, delta_LM => 0.29348169553715187, rho_E => 0.6432945248188199, rho_P => 0.380660140149104)
ic = OrderedDict(N => 0.8544688314746487, E => 0.6654077962169703, L => 0.4412191224383152, M => 0.5391564263569592, P => 0.2015950380422149)

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
