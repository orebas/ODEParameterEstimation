#=============================================================================
Validation Script for Control Systems with Time-Varying Inputs

This script simulates each driven control system and prints text-based
diagnostics for LLM review:
- Min/max/mean of each state variable
- Sample values at t=0, t_mid, t_end
- Check for NaN/Inf (blown-up dynamics)
- Verify states aren't constant (input affects output)

Usage:
    julia --project src/examples/validate_control_systems.jl
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using OrdinaryDiffEq
using Statistics

# Include the driven control systems
include("models/control_systems_driven.jl")

# List of all driven systems to validate
const DRIVEN_SYSTEMS = [
    ("DC Motor", dc_motor_driven),
    ("Mass-Spring-Damper", mass_spring_damper_driven),
    ("Cart-Pole", cart_pole_driven),
    ("Tank Level", tank_level_driven),
    ("CSTR", cstr_driven),
    ("Quadrotor Altitude", quadrotor_altitude_driven),
    ("Thermal System", thermal_system_driven),
    ("Ball-Beam", ball_beam_driven),
    ("Bicycle Model", bicycle_model_driven),
    ("Swing Equation", swing_equation_driven),
    ("Magnetic Levitation", magnetic_levitation_driven),
    ("Aircraft Pitch", aircraft_pitch_driven),
    ("Two-Tank", two_tank_driven),
    ("Boost Converter", boost_converter_driven),
    ("Flexible Arm", flexible_arm_driven),
    ("Bilinear System", bilinear_system_driven),
    ("Forced Lotka-Volterra", forced_lotka_volterra_driven),
]

"""
    validate_system(name, pep_fn)

Simulate a system and print diagnostic information.
"""
function validate_system(name, pep_fn)
    println("\n" * "="^70)
    println("SYSTEM: $name")
    println("="^70)

    # Create the PEP
    local pep
    try
        pep = pep_fn()
    catch e
        println("ERROR creating PEP: $e")
        return false
    end

    # Extract system info
    sys = pep.model.system
    tspan = pep.recommended_time_interval
    if isnothing(tspan)
        tspan = [0.0, 10.0]
    end

    # Build parameter and IC vectors
    p_dict = pep.p_true
    ic_dict = pep.ic

    println("\nTime span: $(tspan[1]) to $(tspan[2])")
    println("Parameters: $(length(p_dict))")
    println("States: $(length(ic_dict))")

    # Print parameter values
    println("\nParameter values:")
    for (k, v) in p_dict
        println("  $k = $v")
    end

    println("\nInitial conditions:")
    for (k, v) in ic_dict
        println("  $k = $v")
    end

    # Create ODEProblem
    local prob, sol
    try
        # Structural simplify the system
        sys_simplified = structural_simplify(sys)

        # Build parameter map
        p_map = [k => v for (k, v) in p_dict]
        ic_map = [k => v for (k, v) in ic_dict]

        prob = ODEProblem(sys_simplified, ic_map, tspan, p_map)
        sol = solve(prob, Tsit5(), saveat=(tspan[2]-tspan[1])/100)
    catch e
        println("\nERROR solving ODE: $e")
        return false
    end

    # Check solution status
    println("\nSolution status: $(sol.retcode)")
    if sol.retcode != :Success && sol.retcode != SciMLBase.ReturnCode.Success
        println("WARNING: Solution did not converge successfully!")
    end

    # Analyze each state variable
    state_names = pep.model.original_states
    println("\n--- State Variable Analysis ---")

    all_ok = true
    for (i, state_name) in enumerate(state_names)
        state_sym = Symbol(state_name)

        # Get state values
        local state_vals
        try
            state_vals = sol[state_name]
        catch
            # Try accessing by index
            state_vals = sol[i, :]
        end

        # Check for NaN/Inf
        has_nan = any(isnan, state_vals)
        has_inf = any(isinf, state_vals)

        # Statistics
        min_val = minimum(state_vals)
        max_val = maximum(state_vals)
        mean_val = mean(state_vals)
        std_val = std(state_vals)
        range_val = max_val - min_val

        # Sample points
        t_mid = (tspan[1] + tspan[2]) / 2
        n = length(sol.t)
        mid_idx = max(1, n ÷ 2)  # Ensure at least index 1

        val_start = state_vals[1]
        val_mid = n > 1 ? state_vals[mid_idx] : state_vals[1]
        val_end = state_vals[end]

        # Is it constant?
        is_constant = range_val < 1e-10 * (abs(mean_val) + 1e-10)

        println("\n  State: $state_name")
        println("    Min: $min_val")
        println("    Max: $max_val")
        println("    Mean: $mean_val")
        println("    Std: $std_val")
        println("    Range: $range_val")
        println("    t=0: $val_start")
        println("    t=mid: $val_mid")
        println("    t=end: $val_end")

        if has_nan
            println("    *** PROBLEM: Contains NaN ***")
            all_ok = false
        end
        if has_inf
            println("    *** PROBLEM: Contains Inf ***")
            all_ok = false
        end
        if is_constant
            println("    *** WARNING: State appears constant (input may not affect it) ***")
        end
    end

    # Summary
    println("\n--- Summary ---")
    if all_ok
        println("OK: No NaN/Inf detected")
    else
        println("PROBLEMS DETECTED: Check state analysis above")
    end

    return all_ok
end

"""
    run_validation()

Run validation on all driven control systems.
"""
function run_validation()
    println("="^70)
    println("CONTROL SYSTEMS VALIDATION")
    println("="^70)
    println("Validating $(length(DRIVEN_SYSTEMS)) driven control systems")

    results = Dict{String, Bool}()

    for (name, fn) in DRIVEN_SYSTEMS
        results[name] = validate_system(name, fn)
    end

    # Final summary
    println("\n\n" * "="^70)
    println("FINAL SUMMARY")
    println("="^70)

    passed = sum(values(results))
    total = length(results)
    println("Passed: $passed / $total")

    if passed < total
        println("\nFailed systems:")
        for (name, ok) in results
            if !ok
                println("  - $name")
            end
        end
    end

    return results
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_validation()
end
