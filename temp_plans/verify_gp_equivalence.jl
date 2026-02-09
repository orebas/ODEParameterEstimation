# Verification script for GP kernel optimization
# Run this to verify the optimized implementation produces correct results

using ODEParameterEstimation
using Random
using Statistics
using KernelFunctions

println("=" ^ 60)
println("GP Kernel Optimization Verification")
println("=" ^ 60)

Random.seed!(42)

# Test data
n = 201  # Similar to production scale (but smaller for quick testing)
xs = collect(range(0.0, 10.0, length=n))
ys = sin.(xs) .+ 0.05 .* randn(n)

println("\nTest data: $n points, sin(x) + noise")
println("-" ^ 60)

for kernel_type in [:se, :matern52]
    println("\n▶ Testing kernel_type = :$kernel_type")

    # Time the function
    t0 = time()
    interp = ODEParameterEstimation.agp_gpr_robust(xs, ys; kernel_type=kernel_type)
    elapsed = time() - t0
    println("  Time: $(round(elapsed, digits=3))s")

    # Check predictions at training points
    train_errors = [abs(interp.mean_function(x) - y) for (x, y) in zip(xs, ys)]
    println("  Training MAE: $(round(mean(train_errors), digits=6))")
    println("  Training Max Error: $(round(maximum(train_errors), digits=6))")

    # Check predictions at interpolation points
    test_xs = collect(0.05:0.5:9.95)
    test_preds = [interp.mean_function(x) for x in test_xs]
    test_true = sin.(test_xs)
    test_errors = abs.(test_preds .- test_true)
    println("  Interpolation MAE: $(round(mean(test_errors), digits=6))")

    # Verify std predictions
    test_stds = [interp.std_function(x) for x in test_xs]
    all_positive = all(s -> s >= 0.0, test_stds)
    all_finite = all(isfinite, test_stds)
    println("  Std predictions valid: $(all_positive && all_finite)")
end

println("\n" * "=" ^ 60)
println("Verifying mathematical equivalence of kernel formulas")
println("=" ^ 60)

# Verify that manual kernel computation matches KernelFunctions.jl
n_verify = 50
xs_verify = collect(range(0.0, 10.0, length=n_verify))
l, σ² = 1.5, 2.0

# Precompute squared distances
D² = [abs2(xs_verify[i] - xs_verify[j]) for i in 1:n_verify, j in 1:n_verify]

println("\nSqExponential kernel:")
k_se = σ² * (SqExponentialKernel() ∘ ScaleTransform(1.0 / l))
K_se_kf = kernelmatrix(k_se, xs_verify)
inv_2l² = 1.0 / (2.0 * l * l)
K_se_manual = [σ² * exp(-D²[i, j] * inv_2l²) for i in 1:n_verify, j in 1:n_verify]
max_diff_se = maximum(abs.(K_se_kf .- K_se_manual))
println("  Max difference from KernelFunctions.jl: $max_diff_se")
println("  Match: $(max_diff_se < 1e-10 ? "✓ PASS" : "✗ FAIL")")

println("\nMatern52 kernel:")
k_m52 = σ² * (Matern52Kernel() ∘ ScaleTransform(1.0 / l))
K_m52_kf = kernelmatrix(k_m52, xs_verify)
const_sqrt5 = sqrt(5.0)
inv_l = 1.0 / l
K_m52_manual = Matrix{Float64}(undef, n_verify, n_verify)
for j in 1:n_verify
    for i in 1:n_verify
        d = sqrt(D²[i, j])
        r = d * inv_l
        sqrt5r = const_sqrt5 * r
        r² = r * r
        K_m52_manual[i, j] = σ² * (1.0 + sqrt5r + 5.0 * r² / 3.0) * exp(-sqrt5r)
    end
end
max_diff_m52 = maximum(abs.(K_m52_kf .- K_m52_manual))
println("  Max difference from KernelFunctions.jl: $max_diff_m52")
println("  Match: $(max_diff_m52 < 1e-10 ? "✓ PASS" : "✗ FAIL")")

println("\n" * "=" ^ 60)
println("Verification complete!")
println("=" ^ 60)
