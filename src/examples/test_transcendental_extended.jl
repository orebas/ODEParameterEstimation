#!/usr/bin/env julia
# Extended transcendental A/B test: all _identifiable vs _sinusoidal pairs
#
# For each pair, we run both the manual (u_sin/u_cos oscillator) and natural
# (sin(ω*t) directly) versions and compare parameter estimates.

using ODEParameterEstimation
using OrderedCollections

include(joinpath(@__DIR__, "load_examples.jl"))

println("=" ^ 70)
println("EXTENDED TRANSCENDENTAL A/B TEST")
println("=" ^ 70)

opts = EstimationOptions(
    datasize = 21,
    noise_level = 0.0,
    system_solver = SolverHC,
    max_num_points = 1,
    shooting_points = 3,
    diagnostics = false,
    nooutput = false,
)

function get_best_solution(results)
    solved_res = results[1][1]
    if isempty(solved_res)
        return nothing
    end
    valid = filter(solved_res) do s
        hasproperty(s, :err) && !isnothing(s.err) && isfinite(s.err)
    end
    isempty(valid) ? nothing : argmin(s -> s.err, valid)
end

function count_solutions(results)
    return length(results[1][1])
end

# Define A/B test pairs: (manual_name, natural_name, shared_param_names)
ab_pairs = [
    (:magnetic_levitation_identifiable, :magnetic_levitation_sinusoidal, ["m_lin", "k_lin", "b_lin"]),
    (:aircraft_pitch_identifiable, :aircraft_pitch_sinusoidal, ["M_alpha", "M_q", "M_delta_e", "Z_alpha"]),
    (:bicycle_model_identifiable, :bicycle_model_sinusoidal, ["Cf", "Cr", "m_veh", "Iz"]),
    (:boost_converter_identifiable, :boost_converter_sinusoidal, ["L", "C_cap", "R_load"]),
    (:bilinear_system_identifiable, :bilinear_system_sinusoidal, ["a11", "a12", "a21", "a22", "b1", "b2", "n1", "n2"]),
]

global total_natural_pass = 0
global total_natural_fail = 0
results_table = []

for (manual_name, natural_name, param_names) in ab_pairs
    println("\n" * "=" ^ 70)
    println("A/B TEST: $manual_name  vs  $natural_name")
    println("=" ^ 70)

    # Delete cached logs
    for name in [manual_name, natural_name]
        logfile = joinpath(@__DIR__, "logs", "$(name).log")
        if isfile(logfile)
            rm(logfile)
        end
    end

    # --- Run manual model ---
    manual_ok = false
    manual_best = nothing
    try
        pep_manual = STANDARD_MODELS[manual_name]()
        pep_manual_sampled = sample_problem_data(pep_manual, opts)
        manual_elapsed = @elapsed begin
            manual_results = analyze_parameter_estimation_problem(pep_manual_sampled, opts)
        end
        manual_best = get_best_solution(manual_results)
        nsol = count_solutions(manual_results)
        if !isnothing(manual_best)
            println("  Manual: $nsol solutions, best_err=$(round(manual_best.err, digits=8)), time=$(round(manual_elapsed, digits=1))s [PASS]")
            manual_ok = true
        else
            println("  Manual: $nsol solutions, no valid solution [FAIL]")
        end
    catch e
        println("  Manual ERROR: $e")
    end

    # --- Run natural model ---
    natural_ok = false
    natural_best = nothing
    try
        pep_natural = STANDARD_MODELS[natural_name]()
        pep_natural_sampled = sample_problem_data(pep_natural, opts)
        natural_elapsed = @elapsed begin
            natural_results = analyze_parameter_estimation_problem(pep_natural_sampled, opts)
        end
        natural_best = get_best_solution(natural_results)
        nsol = count_solutions(natural_results)
        if !isnothing(natural_best)
            println("  Natural: $nsol solutions, best_err=$(round(natural_best.err, digits=8)), time=$(round(natural_elapsed, digits=1))s [PASS]")
            natural_ok = true
            global total_natural_pass += 1
        else
            println("  Natural: $nsol solutions, no valid solution [FAIL]")
            global total_natural_fail += 1
        end
    catch e
        println("  Natural ERROR: $e")
        global total_natural_fail += 1
    end

    # --- Compare parameters ---
    if manual_ok && natural_ok
        println("\n  Parameter comparison:")
        for pname in param_names
            mv = nothing
            nv = nothing
            for (k, v) in manual_best.parameters
                if string(k) == pname
                    mv = v
                    break
                end
            end
            for (k, v) in natural_best.parameters
                if string(k) == pname
                    nv = v
                    break
                end
            end
            if !isnothing(mv) && !isnothing(nv)
                diff = abs(mv - nv)
                rel_diff = abs(mv) > 1e-10 ? abs(diff / mv) : diff
                status = rel_diff < 0.1 ? "MATCH" : "DIFFER"
                println("    $pname: manual=$(round(mv, digits=6)), natural=$(round(nv, digits=6)), rel_diff=$(round(rel_diff, digits=6)) [$status]")
            else
                println("    $pname: manual=$mv, natural=$nv [MISSING]")
            end
        end
    end

    push!(results_table, (string(natural_name), natural_ok, isnothing(natural_best) ? Inf : natural_best.err))
end

println("\n" * "=" ^ 70)
println("EXTENDED A/B TEST SUMMARY")
println("=" ^ 70)
for (name, ok, err) in results_table
    status = ok ? "PASS" : "FAIL"
    println("  $name: $status (err=$(round(err, digits=8)))")
end
println("  Natural models passed: $total_natural_pass / $(total_natural_pass + total_natural_fail)")
println("=" ^ 70)
