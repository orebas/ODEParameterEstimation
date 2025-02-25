#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: hiv
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-13_21-41-34
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@variables a y(t) v(t) d u h lm w(t) x(t) q k b beta z(t) c

using ODEParameterEstimation
using OrderedCollections


# Get the original PEP
original_pep = eval(Symbol("hiv"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(lm => 0.2203686933568445, d => 0.39840613173416806, beta => 0.3399988591613653, a => 0.8084102514816015, k => 0.6941505994270678, u => 0.3504874540477657, c => 0.2043310653604575, q => 0.4071895633303918, b => 0.8330428795958013, h => 0.6521709895833975)
ic = OrderedDict(x => 0.4281077131485791, y => 0.3518816745120452, v => 0.30980134896026124, w => 0.7796082951600992, z => 0.6744334849346558)

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
