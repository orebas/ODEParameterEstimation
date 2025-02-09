using Plots

# Use the specified time interval and sample size.
pep = sample_problem_data(pep, datasize = 1001, time_interval = [[-1.0, 1.0][1], [-1.0, 1.0][2]], noise_level = 1.0e-6)

# Plot the generated data and its derivatives
t = pep.data_sample["t"]
y1 = pep.data_sample["y1"]
y2 = pep.data_sample["y2"]

# Create interpolation objects for debugging
using Interpolations
itp_y1 = CubicSplineInterpolation(t, y1)
itp_y2 = CubicSplineInterpolation(t, y2)

# Calculate derivatives at a few points for debugging
debug_points = [-0.5, 0.0, 0.5]
println("\nDEBUG: Derivative values at key points:")
for tp in debug_points
	println("\nAt t = $tp:")
	println("y1: ", itp_y1(tp))
	println("y1': ", Interpolations.derivative(itp_y1, tp))
	println("y1'': ", Interpolations.derivative(Interpolations.derivative(itp_y1, tp)))
	println("y2: ", itp_y2(tp))
	println("y2': ", Interpolations.derivative(itp_y2, tp))
	println("y2'': ", Interpolations.derivative(Interpolations.derivative(itp_y2, tp)))
end

# Plot original data
p1 = plot(t, y1, label = "y1", title = "Original Data")
plot!(p1, t, y2, label = "y2")

# Plot first derivatives
dy1 = [Interpolations.derivative(itp_y1, ti) for ti in t]
dy2 = [Interpolations.derivative(itp_y2, ti) for ti in t]
p2 = plot(t, dy1, label = "dy1/dt", title = "First Derivatives")
plot!(p2, t, dy2, label = "dy2/dt")

# Plot second derivatives
d2y1 = [Interpolations.derivative(Interpolations.derivative(itp_y1, ti)) for ti in t]
d2y2 = [Interpolations.derivative(Interpolations.derivative(itp_y2, ti)) for ti in t]
p3 = plot(t, d2y1, label = "d²y1/dt²", title = "Second Derivatives")
plot!(p3, t, d2y2, label = "d²y2/dt²")

# Combine plots
plot(p1, p2, p3, layout = (3, 1), size = (800, 1000))

# Run the estimation.
res = analyze_parameter_estimation_problem(pep)

println("Estimation Done!")
