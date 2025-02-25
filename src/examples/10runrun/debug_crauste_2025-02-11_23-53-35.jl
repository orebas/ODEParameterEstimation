#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_23-53-35
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
p_true = OrderedDict(muN => 0.34656784173187455, muEE => 0.3171121302248936, muLE => 0.36907149599156563, muLL => 0.7080672443521563, muM => 0.6366633746982859, muP => 0.33786997239899585, muPE => 0.6231070756010577, muPL => 0.4358651366757377, deltaNE => 0.7792336308002924, deltaEL => 0.48188794236814025, deltaLM => 0.871937474850103, rhoE => 0.5931304053237555, rhoP => 0.4468099623541397)
ic = OrderedDict(n => 0.7709936492514226, e => 0.7615232459349757, s => 0.5654319973894272, m => 0.899404838065671, p => 0.6130519269706033)

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
