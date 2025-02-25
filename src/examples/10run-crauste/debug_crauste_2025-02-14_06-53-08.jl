#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: crauste
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-14_06-53-08
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
p_true = OrderedDict(muN => 0.8774678137256499, muEE => 0.11184570678571798, muLE => 0.7162747441957241, muLL => 0.49662524737028313, muM => 0.5361724343492021, muP => 0.8743340859667371, muPE => 0.155043143321518, muPL => 0.8785933075112612, deltaNE => 0.7903307614018712, deltaEL => 0.19386084938298628, deltaLM => 0.45824953131308177, rhoE => 0.6483046279880001, rhoP => 0.2668996221058294)
ic = OrderedDict(n => 0.5903531309605092, e => 0.330918065574352, s => 0.6560315250421608, m => 0.5845760107715224, p => 0.33155993739183104)

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
