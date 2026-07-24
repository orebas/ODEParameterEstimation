#!/usr/bin/env julia
# Test script for transcendental function handling
#
# This script compares manual polynomialization (dc_motor_identifiable)
# against automatic transcendental handling (dc_motor_sinusoidal).
# Both should produce equivalent parameter estimation results.

using ODEParameterEstimation
using OrderedCollections

include(joinpath(@__DIR__, "models/control_systems.jl"))

println("=" ^ 70)
println("TRANSCENDENTAL FUNCTION HANDLING: A/B TEST")
println("=" ^ 70)

# Common estimation options
opts = EstimationOptions(
    datasize = 21,
    noise_level = 0.0,
    system_solver = SolverHC,
    max_num_points = 1,
    shooting_points = 3,
    diagnostics = false,
    nooutput = false,
)

# Helper to safely extract the best solution from results
function get_best_solution(results)
    # analyze_parameter_estimation_problem returns (results_tuple, analyzed_results, uq_result)
    # results_tuple = (solved_res, unident_dict, trivial_dict, all_unidentifiable)
    solved_res = results[1][1]
    if isempty(solved_res)
        return nothing
    end
    # Filter to objects with valid .err field
    valid = filter(solved_res) do s
        hasproperty(s, :err) && !isnothing(s.err) && isfinite(s.err)
    end
    if isempty(valid)
        return nothing
    end
    return argmin(s -> s.err, valid)
end

function count_solutions(results)
    solved_res = results[1][1]
    return length(solved_res)
end

function print_params(solution; skip_trfn=true)
    if isnothing(solution)
        println("    (no valid solution)")
        return
    end
    for (k, v) in solution.parameters
        k_str = string(k)
        if skip_trfn && (startswith(k_str, "_trfn_") || startswith(k_str, "u_sin") || startswith(k_str, "u_cos") || startswith(k_str, "_obs"))
            continue
        end
        println("    $k = $v")
    end
end

# ============================================================================
# Test 1: Detection
# ============================================================================
println("\n" * "=" ^ 70)
println("TEST 1: Transcendental Detection")
println("=" ^ 70)

pep_natural = dc_motor_sinusoidal()
t_var = ODEParameterEstimation.t

equations = ModelingToolkit.equations(pep_natural.model.system)
tr_info = detect_transcendentals(equations, pep_natural.measured_quantities, t_var)

if isnothing(tr_info)
    println("  FAIL: No transcendentals detected in dc_motor_sinusoidal")
else
    println("  PASS: Detected $(length(tr_info.entries)) transcendental(s):")
    for entry in tr_info.entries
        println("    $(entry.func_type)($(entry.frequency) * t) → $(entry.input_variable)")
    end
end

# ============================================================================
# Test 2: Transformation
# ============================================================================
println("\n" * "=" ^ 70)
println("TEST 2: PEP Transformation")
println("=" ^ 70)

pep_natural_sampled = sample_problem_data(pep_natural, opts)
transformed_pep, tr_info2 = transform_pep_for_estimation(pep_natural_sampled, t_var)

if isnothing(tr_info2)
    println("  FAIL: transform_pep_for_estimation returned nothing")
else
    orig_states = ModelingToolkit.unknowns(pep_natural_sampled.model.system)
    new_states = ModelingToolkit.unknowns(transformed_pep.model.system)
    println("  Original: $(length(orig_states)) states")
    println("  Transformed: $(length(new_states)) states (+$(length(new_states) - length(orig_states)) oscillator states)")
    println("  Measured quantities: $(length(transformed_pep.measured_quantities))")
    println("  PASS")
end

# ============================================================================
# Test 3: A/B Comparison - DC Motor
# ============================================================================
println("\n" * "=" ^ 70)
println("TEST 3: A/B Comparison - DC Motor")
println("=" ^ 70)

# Run manual model
println("\n--- Running manual (dc_motor_identifiable) ---")
pep_manual = dc_motor_identifiable()
pep_manual_sampled = sample_problem_data(pep_manual, opts)

manual_results = nothing
manual_time = 0.0
try
    global manual_time = @elapsed begin
        global manual_results = analyze_parameter_estimation_problem(pep_manual_sampled, opts)
    end
    println("  Manual: $(count_solutions(manual_results)) solutions, time=$(round(manual_time, digits=2))s")
catch e
    println("  Manual FAILED: $e")
end

# Run natural model
println("\n--- Running natural (dc_motor_sinusoidal) ---")
natural_results = nothing
natural_time = 0.0
try
    global natural_time = @elapsed begin
        global natural_results = analyze_parameter_estimation_problem(pep_natural_sampled, opts)
    end
    println("  Natural: $(count_solutions(natural_results)) solutions, time=$(round(natural_time, digits=2))s")
catch e
    println("  Natural FAILED: $e")
end

# Compare results
if !isnothing(manual_results) && !isnothing(natural_results)
    best_manual = get_best_solution(manual_results)
    best_natural = get_best_solution(natural_results)

    println("\n  Best manual solution (err=$(isnothing(best_manual) ? "N/A" : best_manual.err)):")
    print_params(best_manual)

    println("\n  Best natural solution (err=$(isnothing(best_natural) ? "N/A" : best_natural.err)):")
    print_params(best_natural)

    # Compare common parameters
    if !isnothing(best_manual) && !isnothing(best_natural)
        println("\n  Parameter comparison (real parameters only):")
        for (mk, mv) in best_manual.parameters
            mk_str = string(mk)
            if startswith(mk_str, "u_sin") || startswith(mk_str, "u_cos") || startswith(mk_str, "_")
                continue
            end
            for (nk, nv) in best_natural.parameters
                nk_str = string(nk)
                if startswith(nk_str, "_trfn_") || startswith(nk_str, "_obs")
                    continue
                end
                if nk_str == mk_str
                    diff = abs(mv - nv)
                    rel_diff = abs(mv) > 1e-10 ? abs(diff / mv) : diff
                    status = rel_diff < 0.1 ? "MATCH" : "DIFFER"
                    println("    $mk_str: manual=$(round(mv,digits=6)), natural=$(round(nv,digits=6)), rel_diff=$(round(rel_diff, digits=6)) [$status]")
                end
            end
        end
    end
else
    println("  Cannot compare: one or both models failed")
end

# ============================================================================
# Test 4: Quadrotor sinusoidal
# ============================================================================
println("\n" * "=" ^ 70)
println("TEST 4: Quadrotor Sinusoidal")
println("=" ^ 70)

pep_quad = quadrotor_sinusoidal()
pep_quad_sampled = sample_problem_data(pep_quad, opts)

quad_results = nothing
quad_time = 0.0
try
    global quad_time = @elapsed begin
        global quad_results = analyze_parameter_estimation_problem(pep_quad_sampled, opts)
    end
    println("  Quadrotor: $(count_solutions(quad_results)) solutions, time=$(round(quad_time, digits=2))s")
    best = get_best_solution(quad_results)
    if !isnothing(best)
        println("  Best solution (err=$(best.err)):")
        print_params(best)
    else
        println("  No valid solutions found")
    end
catch e
    println("  Quadrotor FAILED: $e")
end

# ============================================================================
# Test 5: Forced Lotka-Volterra sinusoidal
# ============================================================================
println("\n" * "=" ^ 70)
println("TEST 5: Forced Lotka-Volterra Sinusoidal")
println("=" ^ 70)

pep_lv = forced_lv_sinusoidal()
pep_lv_sampled = sample_problem_data(pep_lv, opts)

lv_results = nothing
lv_time = 0.0
try
    global lv_time = @elapsed begin
        global lv_results = analyze_parameter_estimation_problem(pep_lv_sampled, opts)
    end
    println("  Forced LV: $(count_solutions(lv_results)) solutions, time=$(round(lv_time, digits=2))s")
    best = get_best_solution(lv_results)
    if !isnothing(best)
        println("  Best solution (err=$(best.err)):")
        print_params(best)
    else
        println("  No valid solutions found")
    end
catch e
    println("  Forced LV FAILED: $e")
end

# ============================================================================
# Summary
# ============================================================================
println("\n" * "=" ^ 70)
println("SUMMARY")
println("=" ^ 70)
println("  Test 1 (Detection):      $(isnothing(tr_info) ? "FAIL" : "PASS")")
println("  Test 2 (Transformation): $(isnothing(tr_info2) ? "FAIL" : "PASS")")

manual_ok = !isnothing(manual_results) && !isnothing(get_best_solution(manual_results))
natural_ok = !isnothing(natural_results) && !isnothing(get_best_solution(natural_results))
println("  Test 3 (DC Motor A/B):   Manual=$(manual_ok ? "PASS" : "FAIL"), Natural=$(natural_ok ? "PASS" : "FAIL")")

quad_ok = !isnothing(quad_results) && !isnothing(get_best_solution(quad_results))
println("  Test 4 (Quadrotor):      $(quad_ok ? "PASS" : "FAIL")")

lv_ok = !isnothing(lv_results) && !isnothing(get_best_solution(lv_results))
println("  Test 5 (Forced LV):      $(lv_ok ? "PASS" : "FAIL")")

println("=" ^ 70)
