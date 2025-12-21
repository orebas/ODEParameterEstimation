#=============================================================================
Plot Generation Script for Driven Control Systems

Generates plots for each driven control system showing:
- State variables over time
- Control/input signals over time
- Observable outputs over time

Usage:
    julia --project src/examples/plot_control_systems.jl
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using OrdinaryDiffEq
using Plots
using Statistics

# Include the driven control systems
include("models/control_systems_driven.jl")

# Output directory for plots
const PLOT_DIR = joinpath(@__DIR__, "plots")
!isdir(PLOT_DIR) && mkpath(PLOT_DIR)

# Define input signal functions for each system
# These match the inputs defined in control_systems_driven.jl

"""
    plot_system(name, pep_fn, input_info)

Simulate a system and create plots for states, controls, and observables.

# Arguments
- `name`: System name for file naming
- `pep_fn`: Function that creates the PEP
- `input_info`: Dict with :name, :formula, :params keys describing the input
"""
function plot_system(name, pep_fn, input_info)
    println("Plotting: $name")

    # Create the PEP
    local pep
    try
        pep = pep_fn()
    catch e
        println("  ERROR creating PEP: $e")
        return false
    end

    # Extract system info
    sys = pep.model.system
    tspan = pep.recommended_time_interval
    if isnothing(tspan)
        tspan = [0.0, 10.0]
    end

    # Build parameter and IC maps
    p_dict = pep.p_true
    ic_dict = pep.ic

    # Structural simplify and solve
    local prob, sol
    try
        sys_simplified = structural_simplify(sys)
        p_map = [k => v for (k, v) in p_dict]
        ic_map = [k => v for (k, v) in ic_dict]
        prob = ODEProblem(sys_simplified, ic_map, tspan, p_map)
        sol = solve(prob, Tsit5(), saveat=(tspan[2]-tspan[1])/500)
    catch e
        println("  ERROR solving ODE: $e")
        return false
    end

    if sol.retcode != SciMLBase.ReturnCode.Success
        println("  WARNING: Solution did not converge")
    end

    # Get state names
    state_names = pep.model.original_states
    n_states = length(state_names)

    # Time vector for control signal
    t_fine = range(tspan[1], tspan[2], length=500)

    # Extract parameter values for input calculation
    p_vals = Dict(string(k) => v for (k, v) in p_dict)

    # Calculate input signal
    input_signal = input_info[:calc_input](t_fine, p_vals)

    # Create figure with subplots
    # Layout: States | Control | Observables

    # Determine plot layout based on number of states
    if n_states <= 2
        layout = @layout [a b c]
        fig_size = (1200, 350)
    elseif n_states <= 4
        layout = @layout [a b c]
        fig_size = (1200, 400)
    else
        layout = @layout [a b c]
        fig_size = (1200, 450)
    end

    # Plot 1: States
    state_colors = [:blue, :red, :green, :purple, :orange, :cyan]
    p1 = plot(title="State Variables", xlabel="Time", ylabel="Value", legend=:outertopright)
    for (i, state_name) in enumerate(state_names)
        state_vals = try
            sol[state_name]
        catch
            sol[i, :]
        end
        color = state_colors[mod1(i, length(state_colors))]
        plot!(p1, sol.t, state_vals, label=string(state_name), color=color, linewidth=2)
    end

    # Plot 2: Control/Input Signal
    p2 = plot(title="Control Input: $(input_info[:name])",
              xlabel="Time", ylabel="$(input_info[:name])", legend=:none)
    plot!(p2, t_fine, input_signal, color=:darkgreen, linewidth=2)
    annotate!(p2, [(mean(tspan), minimum(input_signal) + 0.1*(maximum(input_signal)-minimum(input_signal)),
                   text(input_info[:formula], 8, :left))])

    # Plot 3: Observables (same as measured quantities)
    mq_names = [string(mq.lhs) for mq in pep.measured_quantities]
    p3 = plot(title="Observable Outputs", xlabel="Time", ylabel="Value", legend=:outertopright)

    # Get observable values - typically these are just the first state or a subset
    for (i, mq) in enumerate(pep.measured_quantities)
        # Extract the observable variable name
        obs_name = string(mq.lhs)
        # The RHS tells us what state it corresponds to
        rhs_str = string(mq.rhs)

        # Try to get the observable value from the solution
        obs_vals = try
            # Check if it's a direct state observation
            if rhs_str in [string(s) for s in state_names]
                idx = findfirst(s -> string(s) == rhs_str, state_names)
                sol[idx, :]
            else
                # Otherwise try to access by symbol
                sol[mq.rhs]
            end
        catch
            # Fallback: assume first state if can't find it
            sol[1, :]
        end

        color = state_colors[mod1(i, length(state_colors))]
        plot!(p3, sol.t, obs_vals, label="$obs_name = $rhs_str", color=color, linewidth=2, linestyle=:dash)
    end

    # Combine plots
    fig = plot(p1, p2, p3, layout=layout, size=fig_size, margin=5Plots.mm)

    # Add overall title
    plot!(fig, plot_title="$name - Driven Control System", plot_titlefontsize=12)

    # Save the plot
    filename = replace(lowercase(name), " " => "_", "-" => "_")
    filepath = joinpath(PLOT_DIR, "$(filename).png")
    savefig(fig, filepath)
    println("  Saved: $filepath")

    return true
end

# Define all systems with their input information
const SYSTEMS_TO_PLOT = [
    (
        name = "DC Motor",
        fn = dc_motor_driven,
        input = Dict(
            :name => "V(t)",
            :formula => "V(t) = V0 + Va*sin(omega*t)",
            :calc_input => (t, p) -> p["V0"] .+ p["Va"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Mass-Spring-Damper",
        fn = mass_spring_damper_driven,
        input = Dict(
            :name => "F(t)",
            :formula => "F(t) = F0*(1-exp(-t/tau)) + Fa*sin(omega*t)",
            :calc_input => (t, p) -> p["F0"] .* (1 .- exp.(-t ./ p["tau_r"])) .+ p["Fa"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Cart-Pole",
        fn = cart_pole_driven,
        input = Dict(
            :name => "F(t)",
            :formula => "F(t) = Fa*sin(omega*t)",
            :calc_input => (t, p) -> p["Fa"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Tank Level",
        fn = tank_level_driven,
        input = Dict(
            :name => "Qin(t)",
            :formula => "Qin(t) = Q0 + Qa*sin(omega*t)",
            :calc_input => (t, p) -> p["Q0"] .+ p["Qa"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "CSTR",
        fn = cstr_driven,
        input = Dict(
            :name => "Tc(t)",
            :formula => "Tc(t) = Tc0 + Tca*sin(omega*t)",
            :calc_input => (t, p) -> p["Tc0"] .+ p["Tca"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Quadrotor Altitude",
        fn = quadrotor_altitude_driven,
        input = Dict(
            :name => "T(t)",
            :formula => "T(t) = m*g + Ta*sin(omega*t)",
            :calc_input => (t, p) -> p["m"] * p["g"] .+ p["Ta"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Thermal System",
        fn = thermal_system_driven,
        input = Dict(
            :name => "Q(t)",
            :formula => "Q(t) = Q0*(1 + Qa_rel*sin(omega*t))",
            :calc_input => (t, p) -> p["Q0"] .* (1 .+ p["Qa_rel"] .* sin.(p["omega"] .* t))
        )
    ),
    (
        name = "Ball-Beam",
        fn = ball_beam_driven,
        input = Dict(
            :name => "tau(t)",
            :formula => "tau(t) = tau_a*sin(omega*t)",
            :calc_input => (t, p) -> p["tau_a"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Bicycle Model",
        fn = bicycle_model_driven,
        input = Dict(
            :name => "delta(t)",
            :formula => "delta(t) = delta_a*sin(omega*t)",
            :calc_input => (t, p) -> p["delta_a"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Swing Equation",
        fn = swing_equation_driven,
        input = Dict(
            :name => "Pm(t)",
            :formula => "Pm(t) = Pm0 + Pma*sin(omega*t)",
            :calc_input => (t, p) -> p["Pm0"] .+ p["Pma"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Magnetic Levitation",
        fn = magnetic_levitation_driven,
        input = Dict(
            :name => "V(t)",
            :formula => "V(t) = V0 + Va*sin(omega*t)",
            :calc_input => (t, p) -> p["V0"] .+ p["Va"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Aircraft Pitch",
        fn = aircraft_pitch_driven,
        input = Dict(
            :name => "delta_e(t)",
            :formula => "delta_e(t) = delta_e0 + delta_ea*sin(omega*t)",
            :calc_input => (t, p) -> p["delta_e0"] .+ p["delta_ea"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Two-Tank",
        fn = two_tank_driven,
        input = Dict(
            :name => "Qin(t)",
            :formula => "Qin(t) = Q0 + Qa*sin(omega*t)",
            :calc_input => (t, p) -> p["Q0"] .+ p["Qa"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Boost Converter",
        fn = boost_converter_driven,
        input = Dict(
            :name => "d(t)",
            :formula => "d(t) = d0 + da*sin(omega*t)",
            :calc_input => (t, p) -> p["d0"] .+ p["da"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Flexible Arm",
        fn = flexible_arm_driven,
        input = Dict(
            :name => "tau(t)",
            :formula => "tau(t) = tau0*(1-exp(-t/tau_r)) + tau_a*sin(omega*t)",
            :calc_input => (t, p) -> p["tau0"] .* (1 .- exp.(-t ./ p["tau_r"])) .+ p["tau_a"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Bilinear System",
        fn = bilinear_system_driven,
        input = Dict(
            :name => "u(t)",
            :formula => "u(t) = u0 + ua*sin(omega*t)",
            :calc_input => (t, p) -> p["u0"] .+ p["ua"] .* sin.(p["omega"] .* t)
        )
    ),
    (
        name = "Forced Lotka-Volterra",
        fn = forced_lotka_volterra_driven,
        input = Dict(
            :name => "u(t)",
            :formula => "u(t) = u0*(1 + ua_rel*sin(omega*t))",
            :calc_input => (t, p) -> p["u0"] .* (1 .+ p["ua_rel"] .* sin.(p["omega"] .* t))
        )
    ),
]

"""
    generate_all_plots()

Generate plots for all driven control systems.
"""
function generate_all_plots()
    println("="^60)
    println("GENERATING CONTROL SYSTEM PLOTS")
    println("="^60)
    println("Output directory: $PLOT_DIR")
    println("Number of systems: $(length(SYSTEMS_TO_PLOT))")
    println()

    results = Dict{String, Bool}()

    for sys_info in SYSTEMS_TO_PLOT
        results[sys_info.name] = plot_system(sys_info.name, sys_info.fn, sys_info.input)
    end

    # Summary
    println()
    println("="^60)
    println("SUMMARY")
    println("="^60)
    passed = sum(values(results))
    total = length(results)
    println("Successfully plotted: $passed / $total systems")

    if passed < total
        println("\nFailed systems:")
        for (name, ok) in results
            if !ok
                println("  - $name")
            end
        end
    end

    println("\nPlots saved to: $PLOT_DIR")
    return results
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    generate_all_plots()
end
