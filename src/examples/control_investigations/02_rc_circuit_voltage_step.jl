#=============================================================================
                    RC CIRCUIT: A Real Engineering Example

This example uses an RC circuit - one of the most fundamental systems in
electrical engineering. Every EE student has analyzed this circuit!

LEARNING GOALS:
1. Apply parameter estimation to a physically meaningful system
2. Understand structural identifiability through a concrete example
3. See why some parameter combinations are identifiable but not individuals
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#-----------------------------------------------------------------------------
# THE SYSTEM: RC Circuit Charging
#-----------------------------------------------------------------------------
#
#     V_in ────[R]────┬────── V_c
#                     │
#                    [C]
#                     │
#     GND ───────────┴──────
#
# Physics:
#   - A voltage source V_in is applied through resistor R
#   - Capacitor C charges up toward V_in
#   - The voltage across the capacitor is V_c
#
# Kirchhoff's Voltage Law: V_in = V_R + V_c = R*i + V_c
# Capacitor current: i = C * dV_c/dt
#
# Combining: V_in = R*C*(dV_c/dt) + V_c
# Rearranging: dV_c/dt = (V_in - V_c) / (R*C)
#
# Defining the time constant: tau = R*C
#
# Final ODE: dV_c/dt = (V_in - V_c) / tau
#
# Solution: V_c(t) = V_in * (1 - exp(-t/tau))  [starting from V_c(0) = 0]
#-----------------------------------------------------------------------------

#=============================================================================
                    VERSION 1: MOST COMMON PARAMETERIZATION
        Time constant tau and input voltage V_in as parameters
=============================================================================#

function rc_circuit_tau()
    #-------------------------------------------------------------------------
    # Symbolic Variables
    #-------------------------------------------------------------------------
    # We parameterize with tau (time constant) and V_in (input voltage)
    # This is the most natural parameterization for this system

    parameters = @parameters tau V_in
    #                        ^    ^
    #                        |    └── INPUT: applied voltage (what we control)
    #                        └─────── time constant = R*C (what we want to find)

    states = @variables V_c(t)
    #                   ^
    #                   └── capacitor voltage (what we measure)

    observables = @variables y(t)

    #-------------------------------------------------------------------------
    # True Values
    #-------------------------------------------------------------------------
    p_true = [
        1.0,    # tau: time constant (seconds) - R*C product
        5.0,    # V_in: INPUT - applied voltage (volts)
    ]

    # Start with discharged capacitor
    ic_true = [0.0]   # V_c(0) = 0 V

    #-------------------------------------------------------------------------
    # ODE System
    #-------------------------------------------------------------------------
    # Classic first-order charging equation
    equations = [
        D(V_c) ~ (V_in - V_c) / tau,
    ]

    measured_quantities = [y ~ V_c]

    #-------------------------------------------------------------------------
    # Build Problem
    #-------------------------------------------------------------------------
    model, mq = create_ordered_ode_system(
        "rc_circuit_tau",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "rc_circuit_tau",
        model,
        mq,
        nothing,
        [0.0, 5.0],    # ~5 time constants to reach steady state
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                    VERSION 2: R AND C SEPARATELY
        What happens when we try to estimate R and C individually?
=============================================================================#

function rc_circuit_separate()
    #-------------------------------------------------------------------------
    # THIS DEMONSTRATES A KEY CONCEPT: Non-Identifiability
    #-------------------------------------------------------------------------
    # If we parameterize with R and C separately (instead of tau = R*C),
    # we cannot uniquely identify R and C from the voltage measurement alone!
    #
    # Why? Because the dynamics only depend on the PRODUCT R*C:
    #   dV_c/dt = (V_in - V_c) / (R*C)
    #
    # Any (R, C) pair with the same product gives identical behavior:
    #   R=2, C=0.5 gives tau=1  -->  Same dynamics as
    #   R=1, C=1   gives tau=1  -->  Same dynamics as
    #   R=0.5, C=2 gives tau=1
    #
    # This is called "structural non-identifiability"
    #-------------------------------------------------------------------------

    parameters = @parameters R C V_in
    #                        ^  ^  ^
    #                        |  |  └── INPUT: applied voltage
    #                        |  └───── capacitance (F)
    #                        └──────── resistance (Ohms)

    states = @variables V_c(t)
    observables = @variables y(t)

    p_true = [
        2.0,    # R: resistance (Ohms)
        0.5,    # C: capacitance (Farads)
        5.0,    # V_in: INPUT - applied voltage (V)
    ]
    # Note: R*C = 2.0 * 0.5 = 1.0 (same tau as Version 1)

    ic_true = [0.0]

    equations = [
        D(V_c) ~ (V_in - V_c) / (R * C),
    ]

    measured_quantities = [y ~ V_c]

    model, mq = create_ordered_ode_system(
        "rc_circuit_separate",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "rc_circuit_separate",
        model,
        mq,
        nothing,
        [0.0, 5.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        1,  # ONE unidentifiable parameter! (R and C only identifiable as product)
    )
end

#=============================================================================
                         RUNNING THE EXAMPLES
=============================================================================#

function run_rc_circuit_examples()
    println("="^70)
    println("RC CIRCUIT: Parameter Estimation with Physical System")
    println("="^70)
    println()

    #-------------------------------------------------------------------------
    # EXAMPLE 1: Identifiable parameterization (tau, V_in)
    #-------------------------------------------------------------------------
    println("-"^70)
    println("EXAMPLE 1: Time Constant Parameterization (tau, V_in)")
    println("-"^70)
    println()
    println("Circuit: V_in --[R]--+-- V_c")
    println("                     |")
    println("                    [C]")
    println("                     |")
    println("         GND -------+")
    println()
    println("ODE: dV_c/dt = (V_in - V_c) / tau")
    println()
    println("Parameters to estimate:")
    println("  - tau: time constant R*C (true = 1.0 s)")
    println("  - V_in: INPUT voltage (true = 5.0 V)")
    println()

    # Create and solve
    problem1 = rc_circuit_tau()
    opts1 = EstimationOptions(
        datasize = 101,
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts1 = merge_options(opts1, time_interval = problem1.recommended_time_interval)
    problem1_with_data = sample_problem_data(problem1, opts1)

    println("Running estimation...")
    results1 = analyze_parameter_estimation_problem(problem1_with_data, opts1)
    println()
    println("EXPECTED: Both tau and V_in should be recovered accurately!")
    println("  - tau determines how fast the circuit charges (visible in dynamics)")
    println("  - V_in determines the final voltage (visible in steady state)")
    println()

    #-------------------------------------------------------------------------
    # EXAMPLE 2: Non-identifiable parameterization (R, C, V_in)
    #-------------------------------------------------------------------------
    println("-"^70)
    println("EXAMPLE 2: Separate R and C Parameterization")
    println("-"^70)
    println()
    println("Same circuit, but parameterized differently:")
    println()
    println("ODE: dV_c/dt = (V_in - V_c) / (R*C)")
    println()
    println("Parameters to estimate:")
    println("  - R: resistance (true = 2.0 Ohms)")
    println("  - C: capacitance (true = 0.5 F)")
    println("  - V_in: INPUT voltage (true = 5.0 V)")
    println()
    println("WARNING: R and C are NOT individually identifiable!")
    println("         Only their product R*C = tau can be determined.")
    println()

    problem2 = rc_circuit_separate()
    opts2 = EstimationOptions(
        datasize = 101,
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts2 = merge_options(opts2, time_interval = problem2.recommended_time_interval)
    problem2_with_data = sample_problem_data(problem2, opts2)

    println("Running estimation...")
    results2 = analyze_parameter_estimation_problem(problem2_with_data, opts2)
    println()

    #-------------------------------------------------------------------------
    # Summary
    #-------------------------------------------------------------------------
    println("="^70)
    println("KEY LESSONS FROM RC CIRCUIT EXAMPLE")
    println("="^70)
    println()
    println("1. IDENTIFIABILITY DEPENDS ON PARAMETERIZATION")
    println("   - (tau, V_in): IDENTIFIABLE - both can be uniquely determined")
    println("   - (R, C, V_in): R and C are NOT individually identifiable")
    println()
    println("2. PHYSICAL INSIGHT HELPS")
    println("   - The dynamics depend only on tau = R*C")
    println("   - No voltage measurement can distinguish R=2,C=0.5 from R=1,C=1")
    println("   - To identify R and C separately, you'd need current measurement!")
    println()
    println("3. PRACTICAL IMPLICATIONS")
    println("   - In a real experiment: What parameters can you actually measure?")
    println("   - If V_in is known (you set the power supply), don't estimate it!")
    println("   - Consider what measurements are available")
    println()
    println("4. INPUT PARAMETERS")
    println("   - V_in is the INPUT (control signal)")
    println("   - In practice, you often KNOW the input (it's what you applied)")
    println("   - But if unknown (e.g., power supply drift), can estimate it")
    println()

    return (results1, results2)
end

#=============================================================================
                              RUN THE EXAMPLE
=============================================================================#

results = run_rc_circuit_examples()

#=============================================================================
                         NEXT STEPS

After understanding this example, move on to:
  03_tank_constant_vs_driven.jl - See how time-varying inputs can improve
                                   identifiability!
=============================================================================#
