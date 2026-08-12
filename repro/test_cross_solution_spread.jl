"""
Test cross-solution spread on several models to see practical identifiability in action.
"""

using ODEParameterEstimation, Printf

function run_spread_test(name, pep_func; datasize=51, noise=0.0, kwargs...)
    println("\n" * "=" ^ 60)
    println("$name (datasize=$datasize, noise=$noise)")
    println("=" ^ 60)

    pep = pep_func()
    pep_data = sample_problem_data(pep, EstimationOptions(; datasize=datasize, noise_level=noise, kwargs...))

    opts = EstimationOptions(; datasize=datasize, noise_level=noise, kwargs...)
    result_tuple = analyze_parameter_estimation_problem(pep_data, opts)
    results = result_tuple[2][1]
    println("  $(length(results)) solutions found")

    if length(results) < 2
        println("  Too few solutions for spread analysis")
        return nothing
    end

    spread = compute_cross_solution_spread(pep_data, results)
    println("  Spread computed across $(spread.n_solutions) solutions\n")

    @printf("  %-14s %10s %10s %10s  [%10s, %10s]  %s\n",
        "Name", "True", "Median", "CV", "IQR lo", "IQR hi", "Class")
    println("  " * "-" ^ 82)

    for e in spread.param_spread
        cv_s = isinf(e.cv) ? "Inf" : isnan(e.cv) ? "NaN" : @sprintf("%.1f%%", e.cv * 100)
        cls_mark = e.classification == :tight ? "" : e.classification == :moderate ? " *" : " **"
        @printf("  %-14s %10.4f %10.4f %10s  [%10.4f, %10.4f]  %s%s\n",
            e.name, e.true_val, e.median, cv_s, e.iqr_low, e.iqr_high, e.classification, cls_mark)
    end
    println()
    for e in spread.state_spread
        cv_s = isinf(e.cv) ? "Inf" : isnan(e.cv) ? "NaN" : @sprintf("%.1f%%", e.cv * 100)
        cls_mark = e.classification == :tight ? "" : e.classification == :moderate ? " *" : " **"
        @printf("  %-14s %10.4f %10.4f %10s  [%10.4f, %10.4f]  %s%s\n",
            e.name, e.true_val, e.median, cv_s, e.iqr_low, e.iqr_high, e.classification, cls_mark)
    end

    return spread
end

# ═══════════════════════════════════════════════════════════════════════════
# Run on several models
# ═══════════════════════════════════════════════════════════════════════════

println("Cross-Solution Spread Test Suite")
println("================================\n")

# 1. Simple (2 params, 2 states, noiseless — should be all tight)
run_spread_test("simple", simple; datasize=51, noise=0.0)

# 2. Lotka-Volterra (3 params, 2 states, noiseless)
run_spread_test("lotka_volterra", lotka_volterra; datasize=51, noise=0.0)

# 3. Lotka-Volterra with noise (should see some moderate/loose)
run_spread_test("lotka_volterra (noise 1e-2)", lotka_volterra; datasize=51, noise=0.01)

# 4. SEIR (4 params, 4 states — interesting identifiability structure)
run_spread_test("seir", seir; datasize=51, noise=0.0)

# 5. daisy_mamil3 (5 params, 3 states, latent x3 — expect loose a31/a13/a01)
run_spread_test("daisy_mamil3", daisy_mamil3; datasize=51, noise=0.0)

println("\n\nDone!")
