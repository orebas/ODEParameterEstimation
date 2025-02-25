#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: hiv
# Datasize: 1001
# Time Interval: [[-0.5, 0.5][1], [-0.5, 0.5][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-11_06-28-29
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
p_true = OrderedDict(lm => 0.29667067544361725, d => 0.6662117689811324, beta => 0.14398031960527097, a => 0.2238814504178155, k => 0.1769655375150687, u => 0.36598744775247505, c => 0.43534825353998996, q => 0.7795514464973589, b => 0.20870039282871844, h => 0.4748416479359755)
ic = OrderedDict(x => 0.26675102602624656, y => 0.6354998243262184, v => 0.7526115866027888, w => 0.1684604508484357, z => 0.6950506880748176)

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
