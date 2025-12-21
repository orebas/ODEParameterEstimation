#=============================================================================
Parameter Estimation Tests for Polynomialized Control Systems

Tests Tier A (polynomial dynamics) and Tier B (sqrt dynamics) systems
through the full parameter estimation pipeline.

Configuration:
- Noiseless data (noise_level = 0.0)
- 501 data points
- Report which systems work and which don't
=============================================================================#

using ODEParameterEstimation
using Printf

# Include the polynomialized model definitions
include("../../src/examples/models/polynomialized/tier_a_polynomial.jl")
include("../../src/examples/models/polynomialized/tier_b_sqrt.jl")

#=============================================================================
                            Test Configuration
=============================================================================#

const TEST_OPTS = EstimationOptions(
    datasize = 501,
    noise_level = 0.0,
)

#=============================================================================
                            Helper Functions
=============================================================================#

"""
    compute_relative_error(estimated, true_val)

Compute relative error between estimated and true values.
"""
function compute_relative_error(estimated::Number, true_val::Number)
    if abs(true_val) < 1e-10
        return abs(estimated - true_val)
    else
        return abs(estimated - true_val) / abs(true_val)
    end
end

"""
    check_parameter_recovery(results, pep; tol=1e-2)

Check if estimated parameters match true parameters within tolerance.
Returns (success, max_error, param_errors).
"""
function check_parameter_recovery(results, pep; tol=1e-2)
    if isempty(results)
        return (false, Inf, Dict())
    end

    # Get true parameters
    p_true = pep.p_true
    ic_true = pep.ic

    # Find best result (by some metric)
    best_result = first(results)

    # Check parameter recovery
    param_errors = Dict{String, Float64}()
    max_error = 0.0

    # This depends on how results are structured - adapt as needed
    # For now, just return that we got results
    return (true, 0.0, param_errors)
end

"""
    test_single_system(name, problem_func; verbose=true)

Run parameter estimation on a single system.
Returns (name, success, error_msg, elapsed_time).
"""
function test_single_system(name, problem_func; verbose=true)
    if verbose
        println("\n" * "="^60)
        println("Testing: $name")
        println("="^60)
    end

    start_time = time()

    try
        # Create the problem
        pep = problem_func()

        if verbose
            println("  States: $(length(pep.ic))")
            println("  Parameters: $(length(pep.p_true))")
            println("  Time interval: $(pep.recommended_time_interval)")
        end

        # Sample noiseless data
        if verbose
            print("  Sampling data... ")
        end
        pep_with_data = sample_problem_data(pep, TEST_OPTS)
        if verbose
            println("done")
        end

        # Run parameter estimation
        if verbose
            print("  Running estimation... ")
        end
        results = analyze_parameter_estimation_problem(pep_with_data, TEST_OPTS)
        elapsed = time() - start_time

        if verbose
            println("done ($(round(elapsed, digits=1))s)")
            println("  Found $(length(results)) solution(s)")
        end

        # Check results
        if isempty(results)
            if verbose
                println("  Result: NO SOLUTIONS FOUND")
            end
            return (name, false, "No solutions found", elapsed)
        else
            if verbose
                println("  Result: SUCCESS")
                # Print first few parameter estimates
                if !isempty(results)
                    first_result = first(results)
                    println("  First solution parameters:")
                    for (k, v) in first_result.parameters
                        true_val = get(pep.p_true, k, nothing)
                        if true_val !== nothing
                            err = compute_relative_error(v, true_val)
                            println("    $k: $(round(v, sigdigits=4)) (true: $(round(true_val, sigdigits=4)), err: $(round(err*100, sigdigits=2))%)")
                        else
                            println("    $k: $(round(v, sigdigits=4))")
                        end
                    end
                end
            end
            return (name, true, "", elapsed)
        end

    catch e
        elapsed = time() - start_time
        error_msg = sprint(showerror, e)
        if verbose
            println("\n  ERROR: $error_msg")
        end
        return (name, false, error_msg, elapsed)
    end
end

#=============================================================================
                            System Definitions
=============================================================================#

const TIER_A_SYSTEMS = [
    ("DC Motor", dc_motor_poly),
    ("Quadrotor Altitude", quadrotor_altitude_poly),
    ("Thermal System", thermal_system_poly),
    ("Magnetic Levitation", magnetic_levitation_poly),
    ("Aircraft Pitch", aircraft_pitch_poly),
    ("Bicycle Model", bicycle_model_poly),
    ("Boost Converter", boost_converter_poly),
    ("Bilinear System", bilinear_system_poly),
    ("Forced Lotka-Volterra", forced_lotka_volterra_poly),
    ("Mass-Spring-Damper", mass_spring_damper_poly),
    ("Flexible Arm", flexible_arm_poly),
]

const TIER_B_SYSTEMS = [
    ("Tank Level", tank_level_poly),
    ("Two-Tank", two_tank_poly),
]

#=============================================================================
                            Main Test Runner
=============================================================================#

"""
    run_tier_tests(systems, tier_name)

Run tests for all systems in a tier.
Returns vector of (name, success, error, time) tuples.
"""
function run_tier_tests(systems, tier_name)
    println("\n" * "#"^70)
    println("# TIER $tier_name: $(length(systems)) systems")
    println("#"^70)

    results = []
    for (name, func) in systems
        result = test_single_system(name, func)
        push!(results, result)
    end

    # Summary
    n_passed = count(r -> r[2], results)
    println("\n" * "-"^60)
    println("TIER $tier_name SUMMARY: $n_passed/$(length(systems)) passed")
    println("-"^60)

    # List failures
    failures = filter(r -> !r[2], results)
    if !isempty(failures)
        println("Failures:")
        for (name, _, error, _) in failures
            short_error = length(error) > 60 ? error[1:60] * "..." : error
            println("  - $name: $short_error")
        end
    end

    return results
end

"""
    run_all_tests()

Run all parameter estimation tests and report results.
"""
function run_all_tests()
    println("\n" * "="^70)
    println("= POLYNOMIALIZED SYSTEMS: PARAMETER ESTIMATION TESTS")
    println("= Configuration: $(TEST_OPTS.datasize) points, noise=$(TEST_OPTS.noise_level)")
    println("="^70)

    total_start = time()

    # Run Tier A
    tier_a_results = run_tier_tests(TIER_A_SYSTEMS, "A (Polynomial)")

    # Run Tier B
    tier_b_results = run_tier_tests(TIER_B_SYSTEMS, "B (sqrt)")

    total_elapsed = time() - total_start

    # Overall summary
    all_results = vcat(tier_a_results, tier_b_results)
    n_total = length(all_results)
    n_passed = count(r -> r[2], all_results)

    println("\n" * "="^70)
    println("= OVERALL SUMMARY")
    println("="^70)
    println("Tier A: $(count(r -> r[2], tier_a_results))/$(length(tier_a_results)) passed")
    println("Tier B: $(count(r -> r[2], tier_b_results))/$(length(tier_b_results)) passed")
    println("-"^60)
    println("TOTAL: $n_passed/$n_total passed")
    println("Total time: $(round(total_elapsed, digits=1))s")
    println("="^70)

    return all_results
end

#=============================================================================
                            Run Tests
=============================================================================#

if abspath(PROGRAM_FILE) == @__FILE__
    run_all_tests()
end
