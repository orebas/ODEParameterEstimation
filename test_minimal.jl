using ODEParameterEstimation

# Test basic interpolator functionality
xs = collect(range(0, 2π, 50))
ys = sin.(xs)

# Test the AAA interpolator
interp1 = aaad(xs, ys)
@assert abs(interp1(π/4) - sin(π/4)) < 0.01

# Test the GPR interpolator
interp2 = aaad_gpr_pivot(xs, ys)
@assert abs(interp2(π/4) - sin(π/4)) < 0.01

# Test derivative calculation
deriv1 = nth_deriv_at(interp1, 1, π/4)
@assert abs(deriv1 - cos(π/4)) < 0.01

deriv2 = nth_deriv_at(interp2, 1, π/4)
@assert abs(deriv2 - cos(π/4)) < 0.1

println("All tests passed!")