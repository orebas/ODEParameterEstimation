#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_19-58-28
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
p_true = OrderedDict(muN => 0.3696060015891226, muEE => 0.1978439244217378, muLE => 0.11934822863462476, muLL => 0.4799721697232482, muM => 0.880003423441202, muP => 0.8751701619053174, muPE => 0.4240472722072436, muPL => 0.46861349415465514, deltaNE => 0.8513482579374205, deltaEL => 0.4968395521572331, deltaLM => 0.7346957034908641, rhoE => 0.5678222500181959, rhoP => 0.42566262894293105)
ic = OrderedDict(n => 0.6995363580533513, e => 0.12762535826333166, s => 0.5941826554318811, m => 0.6573290423094186, p => 0.7497498721960899)

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
