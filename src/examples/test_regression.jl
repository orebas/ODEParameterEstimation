#!/usr/bin/env julia
# Quick regression test: verify that existing (non-transcendental) models
# still work after the core changes for transcendental support.

using ODEParameterEstimation
using OrderedCollections

include(joinpath(@__DIR__, "load_examples.jl"))

# Models to test - a representative sample spanning different complexity levels
test_models = [
    :simple,
    :lotka_volterra,
    :harmonic,
    :fitzhugh_nagumo,
    :dc_motor_identifiable,
    :vanderpol,
    :biohydrogenation,
]

opts = EstimationOptions(
    datasize = 21,
    noise_level = 0.0,
    system_solver = SolverHC,
    max_num_points = 1,
    shooting_points = 3,
    diagnostics = false,
    nooutput = false,
)

println("=" ^ 70)
println("REGRESSION TEST: Existing Models After Transcendental Changes")
println("=" ^ 70)

global pass_count = 0
global fail_count = 0
results_summary = []

for model_name in test_models
    println("\n--- Testing: $model_name ---")

    # Delete cached log if any
    logfile = joinpath(@__DIR__, "logs", "$(model_name).log")
    if isfile(logfile)
        rm(logfile)
    end

    try
        pep_fn = STANDARD_MODELS[model_name]
        pep = pep_fn()
        pep_sampled = sample_problem_data(pep, opts)

        elapsed = @elapsed begin
            results = analyze_parameter_estimation_problem(pep_sampled, opts)
        end

        solved_res = results[1][1]
        n_solutions = length(solved_res)

        valid = filter(solved_res) do s
            hasproperty(s, :err) && !isnothing(s.err) && isfinite(s.err)
        end

        if !isempty(valid)
            best = argmin(s -> s.err, valid)
            best_err = best.err
            status = best_err < 1.0 ? "PASS" : "WARN (high error)"
            println("  $n_solutions solutions, best_err=$best_err, time=$(round(elapsed, digits=1))s [$status]")
            push!(results_summary, (model_name, status, best_err, n_solutions))
            if best_err < 1.0
                global pass_count += 1
            else
                global fail_count += 1
            end
        else
            println("  $n_solutions solutions but none valid [FAIL]")
            push!(results_summary, (model_name, "FAIL", Inf, n_solutions))
            global fail_count += 1
        end
    catch e
        println("  ERROR: $e [FAIL]")
        push!(results_summary, (model_name, "FAIL", Inf, 0))
        global fail_count += 1
    end
end

println("\n" * "=" ^ 70)
println("REGRESSION SUMMARY")
println("=" ^ 70)
for (name, status, err, nsol) in results_summary
    println("  $name: $status (err=$(round(err, digits=6)), sols=$nsol)")
end
println("  PASS: $pass_count / $(pass_count + fail_count)")
println("=" ^ 70)
