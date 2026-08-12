# Test script for AGPInterpolator - run in global Julia environment
# Usage: julia test_agp_interpolator.jl

println("=" ^ 60)
println("Testing AGPInterpolator (AbstractGPs.jl-based GP interpolation)")
println("=" ^ 60)

# Load the package
println("\n[1] Loading ODEParameterEstimation...")
using ODEParameterEstimation
using Statistics

println("   Package loaded successfully!")

# Test 1: Basic interpolation
println("\n[2] Testing basic interpolation...")
xs = collect(range(0, 2, length=15))
ys = sin.(xs)

interp = agp_gpr(xs, ys)
println("   Created interpolator: $(typeof(interp))")

# Test at a known point
test_x = 1.0
pred = interp(test_x)
true_val = sin(test_x)
println("   At x=$test_x: predicted=$pred, true=$(true_val), error=$(abs(pred - true_val))")

# Test 2: Uncertainty access
println("\n[3] Testing uncertainty access...")
mean_val, variance = mean_and_var(interp, 0.5)
println("   At x=0.5: mean=$mean_val, variance=$variance, std=$(sqrt(variance))")

# Test 3: TaylorDiff compatibility (derivatives)
println("\n[4] Testing TaylorDiff compatibility...")
deriv1 = ODEParameterEstimation.nth_deriv(x -> interp(x), 1, 1.0)
true_deriv = cos(1.0)
println("   1st derivative at x=1.0: predicted=$deriv1, true=$true_deriv, error=$(abs(deriv1 - true_deriv))")

deriv2 = ODEParameterEstimation.nth_deriv(x -> interp(x), 2, 1.0)
true_deriv2 = -sin(1.0)
println("   2nd derivative at x=1.0: predicted=$deriv2, true=$true_deriv2, error=$(abs(deriv2 - true_deriv2))")

# Test 4: Kernel switching
println("\n[5] Testing kernel switching...")
interp_matern = agp_gpr(xs, ys; kernel_type=:matern52)
pred_matern = interp_matern(1.0)
println("   Matern52 kernel prediction at x=1.0: $pred_matern")

# Test 5: Edge case - constant data
println("\n[6] Testing edge case: constant data...")
ys_const = fill(5.0, length(xs))
interp_const = agp_gpr(xs, ys_const)
println("   Constant data (all 5.0) prediction at x=0.5: $(interp_const(0.5))")

# Test 6: Large offset data
println("\n[7] Testing large offset data...")
xs_large = [1000.0, 1001.0, 1002.0, 1003.0, 1004.0]
ys_large = [1e6, 2e6, 1.5e6, 2.5e6, 2e6]
interp_large = agp_gpr(xs_large, ys_large)
pred_large = interp_large(1002.5)
println("   Large offset prediction at x=1002.5: $pred_large (should be ~2e6)")

# Test 7: Using with EstimationOptions
println("\n[8] Testing with EstimationOptions...")
interp_func = get_interpolator_function(InterpolatorAGPRobust)
println("   get_interpolator_function(InterpolatorAGPRobust) returned: $(interp_func)")
println("   Function matches agp_gpr: $(interp_func === agp_gpr)")

# Summary
println("\n" * "=" ^ 60)
println("All tests completed!")
println("=" ^ 60)
println("\nThe AGPInterpolator is ready to use. Example usage:")
println("""
    # As drop-in replacement in EstimationOptions:
    opts = EstimationOptions(interpolator = InterpolatorAGPRobust)

    # Direct usage:
    interp = agp_gpr(t_data, y_data)
    prediction = interp(t_new)           # Mean only
    m, v = mean_and_var(interp, t_new)   # With uncertainty
""")
