#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.01
# Generated on: 2025-02-14_04-07-31
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
p_true = OrderedDict(muN => 0.6465288050138772, muEE => 0.4342312040358768, muLE => 0.23168506621563412, muLL => 0.4858366594003565, muM => 0.4573683866010899, muP => 0.707154439853273, muPE => 0.46184032411662723, muPL => 0.7353457378663314, deltaNE => 0.6720706630944744, deltaEL => 0.16799284206282517, deltaLM => 0.1806804377659475, rhoE => 0.3147257575533764, rhoP => 0.1652429154856878)
ic = OrderedDict(n => 0.8490551006524332, e => 0.8748454980414218, s => 0.6736218579366245, m => 0.6889787536196506, p => 0.27777987834410967)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 0.01)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
