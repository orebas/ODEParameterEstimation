#!/usr/bin/env julia
#
# This script reproduces a problematic parameter estimation case.
# Model Name: harmonic
# Datasize: 1001
# Time Interval: [[-1.0, 1.0][1], [-1.0, 1.0][2]]
# Noise Level: 1.0e-6
# Generated on: 2025-02-08_19-46-20
#
# Predefine ModelingToolkit variables used in the PEP
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using Plots
#pythonplot()
@variables a x1(t) b x2(t)

using ODEParameterEstimation
using OrderedCollections
#using Interpolations


# Get the original PEP
original_pep = eval(Symbol("harmonic"))()

# Create new PEP with our specific parameters and initial conditions
p_true = OrderedDict(a => 0.1297385343772234, b => 0.6249065687864864)
ic = OrderedDict(x1 => 0.7486499144822791, x2 => 0.713216066328752)

pep = ParameterEstimationProblem(
	original_pep.name,
	original_pep.model,
	original_pep.measured_quantities,
	original_pep.data_sample,
	original_pep.recommended_time_interval,
	original_pep.solver,
	p_true,
	ic,
	original_pep.unident_count,
)


# Use the specified time interval and sample size.
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-1.0, 1.0][1], [-1.0, 1.0][2]], noise_level = 1.0e-6)

# Debug interpolation

# Replicate create_interpolants function
function create_interpolants(measured_quantities, data_sample, t_vector, interpolator)
	interpolants = Dict()
	for j in measured_quantities
		r = j.rhs
		key = haskey(data_sample, r) ? r : Symbolics.wrap(j.lhs)
		y_vector = data_sample[key]
		interpolants[r] = interpolator(t_vector, y_vector)
	end
	return interpolants
end

# Create interpolants using CubicSplineInterpolation
t_vector = pep.data_sample["t"]
interpolants = create_interpolants(pep.measured_quantities, pep.data_sample, t_vector, aaad_gpr_pivot)


interpolants_keys = collect(keys(interpolants))
for i in interpolants_keys
	println(i)
end

# Create evenly spaced points for evaluation
eval_points = range(-1.0, 1.0, length = 1001)

# Plot each interpolant
# Create a single plot with multiple subplots side by side

plots = []
for (i, key) in enumerate(interpolants_keys)
	interp = interpolants[key]
	y_values = [interp(t) for t in eval_points]
	y0prime_values = [nth_deriv_at(interp, 0, t) for t in eval_points]
	y1prime_values = [nth_deriv_at(interp, 1, t) for t in eval_points]
	y2prime_values = [nth_deriv_at(interp, 2, t) for t in eval_points]

	# Add subplot
	newplot = plot(eval_points, y_values,
		label = "value",
		title = "Interpolant for $(key)",
		xlabel = "t",
		ylabel = "value")
	plot!(eval_points, y0prime_values,
		label = "0th derivative")
	plot!(eval_points, y1prime_values,
		label = "1st derivative")
	plot!(eval_points, y2prime_values,
		label = "2nd derivative")



	push!(plots, newplot)



end

full_plot = plot(plots..., layout = (1, length(interpolants_keys)), size = (800, 300))


# Display the combined plot
display(full_plot)






# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
