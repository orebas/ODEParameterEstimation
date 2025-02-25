#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-8
# Generated on: 2025-02-14_06-58-34
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
p_true = OrderedDict(muN => 0.6642786533335934, muEE => 0.5861081360601503, muLE => 0.5314685491496027, muLL => 0.6551485875397942, muM => 0.35456271169192666, muP => 0.35474564122151986, muPE => 0.4299835858860769, muPL => 0.7535390145691844, deltaNE => 0.5023426372003125, deltaEL => 0.8074681550121611, deltaLM => 0.7178950300259989, rhoE => 0.3582706811396349, rhoP => 0.22674666034240973)
ic = OrderedDict(n => 0.5743076404959474, e => 0.39565474332116535, s => 0.7127187916647612, m => 0.20155575961507327, p => 0.3879697387618829)

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
