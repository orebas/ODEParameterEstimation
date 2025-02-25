#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_08-55-13
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
p_true = OrderedDict(muN => 0.8680899306834842, muEE => 0.38127689716266844, muLE => 0.19503226631342685, muLL => 0.4971181402342627, muM => 0.517498628084965, muP => 0.20750427822586498, muPE => 0.6698330161663957, muPL => 0.7133217671365623, deltaNE => 0.4305919254859434, deltaEL => 0.2773929173772647, deltaLM => 0.6515128065516821, rhoE => 0.14347474063151555, rhoP => 0.3377591937925667)
ic = OrderedDict(n => 0.7634043789231127, e => 0.41381148104037324, s => 0.4294084535844853, m => 0.10184254539827338, p => 0.13569569486022273)

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
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-0.5, 0.5][1], [-0.5, 0.5][2]], noise_level = 1.0e-8)

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
