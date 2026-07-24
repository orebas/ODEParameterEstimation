# Test script for parameter homotopy feature
# Compares results and performance with/without parameter homotopy

include("load_examples.jl")

using SciMLBase
using Statistics
using Printf

println("=" ^ 70)
println("Parameter Homotopy A/B Test")
println("=" ^ 70)

# Test a single model with different options
function run_ab_test(model_name::Symbol; shooting_points=5, datasize=101, noise_level=0.0)
    println("\n" * "=" ^ 60)
    println("Testing: $model_name (shooting_points=$shooting_points)")
    println("=" ^ 60)

    # Get the model function from registry
    if !haskey(ALL_MODELS, model_name)
        println("Model $model_name not found in registry")
        return nothing
    end
    model_func = ALL_MODELS[model_name]

    # Common options
    base_opts = EstimationOptions(
        datasize = datasize,
        noise_level = noise_level,
        system_solver = SolverHC,
        shooting_points = shooting_points,
        diagnostics = false,
        nooutput = true,
        save_system = false,
        polish_solver_solutions = false,
        interpolator = InterpolatorAGPRobust,
    )

    # Test A: Without parameter homotopy (control)
    println("\n--- Test A: Standard HC (control) ---")
    opts_control = merge_options(base_opts; use_parameter_homotopy=false)

    time_control = @elapsed begin
        results_control = try
            run_single_model(model_func, opts_control)
        catch e
            @warn "Control test failed" exception=e
            nothing
        end
    end
    @printf("Control time: %.3f seconds\n", time_control)

    # Test B: With parameter homotopy (treatment)
    println("\n--- Test B: Parameter Homotopy (treatment) ---")
    opts_treatment = merge_options(base_opts; use_parameter_homotopy=true)

    time_treatment = @elapsed begin
        results_treatment = try
            run_single_model(model_func, opts_treatment)
        catch e
            @warn "Treatment test failed" exception=e
            nothing
        end
    end
    @printf("Treatment time: %.3f seconds\n", time_treatment)

    # Report results
    println("\n" * "-" ^ 50)
    println("Results Summary:")
    println("-" ^ 50)

    @printf("Control (standard):     %.3f seconds\n", time_control)
    @printf("Treatment (param hom):  %.3f seconds\n", time_treatment)

    if time_treatment > 0
        speedup = time_control / time_treatment
        @printf("Speedup:               %.2fx\n", speedup)
    end

    # Compare solution counts
    if !isnothing(results_control) && !isnothing(results_treatment)
        n_control = length(results_control)
        n_treatment = length(results_treatment)
        println("\nSolution counts:")
        println("  Control:   $n_control solutions")
        println("  Treatment: $n_treatment solutions")
    end

    return (
        model = model_name,
        time_control = time_control,
        time_treatment = time_treatment,
        speedup = time_treatment > 0 ? time_control / time_treatment : NaN,
    )
end

# Helper function to run a single model
function run_single_model(model_func, opts)
    pep = model_func()
    sampled_pep = sample_problem_data(pep, opts)
    result_tuple = analyze_parameter_estimation_problem(sampled_pep, opts)
    # The return can be a complex nested tuple, extract the results
    if result_tuple isa Tuple && length(result_tuple) >= 2 && result_tuple[2] isa Tuple
        # Nested tuple structure from optimized_multishot_parameter_estimation
        inner = result_tuple[2]
        if length(inner) >= 1 && inner[1] isa Vector
            return inner[1]  # Vector of ParameterEstimationResult
        end
    elseif result_tuple isa Tuple && length(result_tuple) >= 1 && result_tuple[1] isa Vector
        return result_tuple[1]
    end
    return []
end

# Run tests
test_models = [:simple, :lotka_volterra, :onevar_exp]
results = []

for model_name in test_models
    try
        r = run_ab_test(model_name; shooting_points=5, datasize=101)
        if !isnothing(r)
            push!(results, r)
        end
    catch e
        @error "Test failed for $model_name" exception=(e, catch_backtrace())
    end
end

# Final summary
if !isempty(results)
    println("\n" * "=" ^ 70)
    println("FINAL SUMMARY")
    println("=" ^ 70)
    println("\n| Model           | Control (s) | Treatment (s) | Speedup |")
    println("|-----------------|-------------|---------------|---------|")

    for r in results
        @printf("| %-15s | %10.3f  | %12.3f  | %6.2fx |\n",
            r.model, r.time_control, r.time_treatment, r.speedup)
    end

    if length(results) > 1
        avg_speedup = mean([r.speedup for r in results if !isnan(r.speedup)])
        println("|-----------------|-------------|---------------|---------|")
        @printf("| Average         |             |               | %6.2fx |\n", avg_speedup)
    end
end
println()
