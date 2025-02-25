#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-12_05-15-24
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
p_true = OrderedDict(muN => 0.8272784960452195, muEE => 0.4967988061659424, muLE => 0.28487027120109226, muLL => 0.47230937580886023, muM => 0.17851757717863156, muP => 0.7622725965444896, muPE => 0.33235865441077717, muPL => 0.26159173485866916, deltaNE => 0.7838025938421652, deltaEL => 0.6488653010216272, deltaLM => 0.2902850738671705, rhoE => 0.5245134699820895, rhoP => 0.3475154524409907)
ic = OrderedDict(n => 0.8850156655419259, e => 0.14261827250552628, s => 0.3530546810739036, m => 0.3334036621671008, p => 0.3676201977176832)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 0.0001)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
