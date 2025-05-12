using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections

println("Testing basic interpolator functionality...")

# Test basic interpolator functionality
xs = collect(range(0, 2π, 50))
ys = sin.(xs)

# Test the AAA interpolator
println("Testing AAA interpolator...")
interp1 = aaad(xs, ys)
@assert abs(interp1(π/4) - sin(π/4)) < 0.01
println("AAA interpolator works!")

# Test the GPR interpolator
println("Testing GPR interpolator...")
interp2 = aaad_gpr_pivot(xs, ys)
@assert abs(interp2(π/4) - sin(π/4)) < 0.01
println("GPR interpolator works!")

# Test derivative calculation
println("Testing derivatives...")
deriv1 = nth_deriv_at(interp1, 1, π/4)
@assert abs(deriv1 - cos(π/4)) < 0.01

deriv2 = nth_deriv_at(interp2, 1, π/4)
@assert abs(deriv2 - cos(π/4)) < 0.1
println("Derivatives work!")

# Test create_interpolants function
println("Testing create_interpolants...")
@variables t x(t) y(t)
measured = [x ~ t, y ~ sin(t)]
data_sample = OrderedDict(
    t => xs,
    x => xs,
    y => ys
)
interpolants = create_interpolants(measured, data_sample, xs, aaad)
println("Created interpolants: $(keys(interpolants))")

println("All tests passed!")