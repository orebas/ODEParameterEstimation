#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 0.0001
# Generated on: 2025-02-12_03-32-58
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
p_true = OrderedDict(muN => 0.4963704975171753, muEE => 0.24160882069343703, muLE => 0.6347623867420187, muLL => 0.7525067557500852, muM => 0.1412642877715393, muP => 0.1812418794040153, muPE => 0.10440982155644828, muPL => 0.49112439992996293, deltaNE => 0.46153846925380726, deltaEL => 0.6162022351765227, deltaLM => 0.49613972585684896, rhoE => 0.49807694570950234, rhoP => 0.20536899602900904)
ic = OrderedDict(n => 0.4510178100216502, e => 0.7581979863861807, s => 0.5757324692745395, m => 0.827917028827588, p => 0.8328359234475365)

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
