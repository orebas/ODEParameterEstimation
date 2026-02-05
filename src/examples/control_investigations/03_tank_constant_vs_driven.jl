#=============================================================================
            TANK LEVEL CONTROL: Constant vs Time-Varying Inputs

This example compares TWO approaches to handling control inputs:
  A) Constant input: Qin is a fixed value
  B) Driven input: Qin(t) = Q0 + Qa*sin(omega*t)

LEARNING GOALS:
1. See how time-varying inputs can improve parameter identifiability
2. Understand the trade-off: driven inputs require knowing the signal form
3. Learn when to use each approach
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#-----------------------------------------------------------------------------
# THE SYSTEM: Single Tank Liquid Level
#-----------------------------------------------------------------------------
#
#           Qin (inlet flow - controlled)
#            ↓
#     ┌──────────────┐
#     │              │   h = liquid height
#     │    ~~~~      │
#     │    ~~~~      │
#     └──────┬───────┘
#            │
#            ↓ Qout = k*sqrt(h)  (gravity-driven outflow)
#
# Mass Balance: A * dh/dt = Qin - Qout
#               A * dh/dt = Qin - k*sqrt(h)
#
# Where:
#   A = tank cross-sectional area (m²)
#   k = outflow coefficient (m^2.5/s)
#   h = liquid height (m)
#   Qin = inlet volumetric flow rate (m³/s) - the INPUT
#
# The sqrt(h) outflow comes from Torricelli's law (Bernoulli's principle).
#-----------------------------------------------------------------------------

#=============================================================================
            VERSION A: CONSTANT INPUT (Qin = constant)
=============================================================================#

function tank_constant_input()
    #-------------------------------------------------------------------------
    # With constant Qin, the system approaches a steady state where:
    #   Qin = k*sqrt(h_ss)
    #   h_ss = (Qin/k)²
    #
    # The transient dynamics reveal the time scale A/k, but there are
    # potential identifiability issues between A and k if we also
    # estimate Qin.
    #-------------------------------------------------------------------------

    parameters = @parameters A k Qin
    #                        ^  ^  ^
    #                        |  |  └── INPUT: inlet flow rate (constant)
    #                        |  └───── outflow coefficient
    #                        └──────── tank cross-section area

    states = @variables h(t)
    observables = @variables y(t)

    p_true = [
        1.0,    # A: tank area (m²)
        0.3,    # k: outflow coefficient
        0.4,    # Qin: INPUT - constant inlet flow (m³/s)
    ]

    # Start at some initial level
    ic_true = [1.0]   # h(0) = 1.0 m

    equations = [
        D(h) ~ (Qin - k * sqrt(h)) / A,
    ]

    measured_quantities = [y ~ h]

    model, mq = create_ordered_ode_system(
        "tank_constant_input",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "tank_constant_input",
        model,
        mq,
        nothing,
        [0.0, 30.0],    # Long time to see approach to steady state
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
        VERSION B: DRIVEN INPUT (Qin(t) = Q0 + Qa*sin(omega*t))
=============================================================================#

function tank_driven_input()
    #-------------------------------------------------------------------------
    # With time-varying Qin, the system never truly reaches steady state.
    # Instead, it oscillates around a mean level.
    #
    # The oscillating input "excites" the system dynamics in a way that
    # can help distinguish between parameters that might otherwise be
    # confounded.
    #
    # Key insight: The PHASE and AMPLITUDE of the response relative to
    # the input contain information about the system parameters!
    #-------------------------------------------------------------------------

    parameters = @parameters A k Q0 Qa omega
    #                        ^  ^  ^   ^   ^
    #                        |  |  |   |   └── INPUT: oscillation frequency
    #                        |  |  |   └────── INPUT: oscillation amplitude
    #                        |  |  └────────── INPUT: mean flow rate
    #                        |  └───────────── outflow coefficient
    #                        └──────────────── tank area

    states = @variables h(t)
    observables = @variables y(t)

    p_true = [
        1.0,    # A: tank area (m²)
        0.3,    # k: outflow coefficient
        0.4,    # Q0: mean inlet flow (m³/s)
        0.15,   # Qa: flow oscillation amplitude (m³/s)
        0.5,    # omega: oscillation frequency (rad/s)
    ]

    ic_true = [1.0]

    # Qin(t) = Q0 + Qa*sin(omega*t)
    equations = [
        D(h) ~ (Q0 + Qa * sin(omega * t) - k * sqrt(h)) / A,
    ]

    measured_quantities = [y ~ h]

    model, mq = create_ordered_ode_system(
        "tank_driven_input",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "tank_driven_input",
        model,
        mq,
        nothing,
        [0.0, 50.0],    # Longer time to see several oscillation periods
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                    VERSION C: DRIVEN WITH FIXED OMEGA
        In practice, you KNOW the input frequency (you set it!)
=============================================================================#

function tank_driven_fixed_omega()
    #-------------------------------------------------------------------------
    # PRACTICAL INSIGHT: In a real experiment, you CONTROL the input signal.
    # You know omega because you chose it! So don't estimate it.
    #
    # This reduces the number of unknowns and typically improves
    # identifiability of the remaining parameters.
    #-------------------------------------------------------------------------

    # Only estimate A, k, Q0, Qa (not omega)
    parameters = @parameters A k Q0 Qa
    states = @variables h(t)
    observables = @variables y(t)

    # FIXED input frequency (known from experiment design)
    omega_fixed = 0.5   # rad/s - we chose this value

    p_true = [
        1.0,    # A: tank area
        0.3,    # k: outflow coefficient
        0.4,    # Q0: mean inlet flow
        0.15,   # Qa: flow oscillation amplitude
    ]

    ic_true = [1.0]

    # omega is now a FIXED VALUE, not a parameter
    equations = [
        D(h) ~ (Q0 + Qa * sin(omega_fixed * t) - k * sqrt(h)) / A,
    ]

    measured_quantities = [y ~ h]

    model, mq = create_ordered_ode_system(
        "tank_driven_fixed_omega",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "tank_driven_fixed_omega",
        model,
        mq,
        nothing,
        [0.0, 50.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                         COMPARISON RUNNER
=============================================================================#

function run_tank_comparison()
    println("="^70)
    println("TANK LEVEL: Comparing Constant vs Driven Inputs")
    println("="^70)
    println()

    #-------------------------------------------------------------------------
    # Version A: Constant Input
    #-------------------------------------------------------------------------
    println("-"^70)
    println("VERSION A: Constant Input (Qin = 0.4 m³/s)")
    println("-"^70)
    println()
    println("ODE: A * dh/dt = Qin - k*sqrt(h)")
    println()
    println("Parameters: A=1.0, k=0.3, Qin=0.4 (INPUT)")
    println("Steady state: h_ss = (Qin/k)² = (0.4/0.3)² ≈ 1.78 m")
    println()

    problem_a = tank_constant_input()
    opts_a = EstimationOptions(
        datasize = 151,
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts_a = merge_options(opts_a, time_interval = problem_a.recommended_time_interval)
    problem_a_with_data = sample_problem_data(problem_a, opts_a)

    println("Running estimation...")
    results_a = analyze_parameter_estimation_problem(problem_a_with_data, opts_a)
    println()

    #-------------------------------------------------------------------------
    # Version B: Driven Input (estimating omega)
    #-------------------------------------------------------------------------
    println("-"^70)
    println("VERSION B: Driven Input (Qin = Q0 + Qa*sin(omega*t))")
    println("-"^70)
    println()
    println("ODE: A * dh/dt = Q0 + Qa*sin(omega*t) - k*sqrt(h)")
    println()
    println("Parameters: A=1.0, k=0.3, Q0=0.4, Qa=0.15, omega=0.5")
    println("Input oscillates between 0.25 and 0.55 m³/s")
    println()
    println("Note: omega is being estimated (5 parameters total)")
    println()

    problem_b = tank_driven_input()
    opts_b = EstimationOptions(
        datasize = 201,   # More points for oscillating system
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts_b = merge_options(opts_b, time_interval = problem_b.recommended_time_interval)
    problem_b_with_data = sample_problem_data(problem_b, opts_b)

    println("Running estimation...")
    results_b = analyze_parameter_estimation_problem(problem_b_with_data, opts_b)
    println()

    #-------------------------------------------------------------------------
    # Version C: Driven Input with FIXED omega
    #-------------------------------------------------------------------------
    println("-"^70)
    println("VERSION C: Driven Input with FIXED omega")
    println("-"^70)
    println()
    println("Same as Version B, but omega = 0.5 is FIXED (not estimated)")
    println()
    println("Parameters: A=1.0, k=0.3, Q0=0.4, Qa=0.15")
    println("FIXED: omega = 0.5 rad/s (you know this from your experiment!)")
    println()
    println("This is usually the right approach in practice.")
    println()

    problem_c = tank_driven_fixed_omega()
    opts_c = EstimationOptions(
        datasize = 201,
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts_c = merge_options(opts_c, time_interval = problem_c.recommended_time_interval)
    problem_c_with_data = sample_problem_data(problem_c, opts_c)

    println("Running estimation...")
    results_c = analyze_parameter_estimation_problem(problem_c_with_data, opts_c)
    println()

    #-------------------------------------------------------------------------
    # Summary
    #-------------------------------------------------------------------------
    println("="^70)
    println("COMPARISON SUMMARY")
    println("="^70)
    println()
    println("┌─────────────────┬────────────┬──────────────────────────────┐")
    println("│ Version         │ # Params   │ Notes                        │")
    println("├─────────────────┼────────────┼──────────────────────────────┤")
    println("│ A: Constant     │ 3          │ Simple but may have issues   │")
    println("│ B: Driven (all) │ 5          │ More info, but more unknowns │")
    println("│ C: Driven+Fixed │ 4          │ Best: uses known info!       │")
    println("└─────────────────┴────────────┴──────────────────────────────┘")
    println()
    println("KEY INSIGHTS:")
    println()
    println("1. TIME-VARYING INPUTS PROVIDE MORE INFORMATION")
    println("   - Oscillating input → oscillating response")
    println("   - Phase lag and amplitude ratio reveal system parameters")
    println("   - Breaks symmetries that cause identifiability problems")
    println()
    println("2. USE WHAT YOU KNOW")
    println("   - If you control the input, you KNOW its form")
    println("   - Don't estimate omega if you chose it!")
    println("   - Same for amplitude Qa if you set it on your pump")
    println()
    println("3. TRADE-OFFS")
    println("   - Constant input: simpler, but steady state may not identify all")
    println("   - Driven input: richer data, but must know/assume signal form")
    println("   - The best choice depends on your experimental setup")
    println()
    println("4. PRACTICAL RECOMMENDATION")
    println("   - Version C is usually best: driven input with known frequency")
    println("   - If you're designing an experiment, USE oscillating inputs!")
    println()

    return (constant=results_a, driven=results_b, driven_fixed=results_c)
end

#=============================================================================
                              RUN THE EXAMPLE
=============================================================================#

results = run_tank_comparison()

#=============================================================================
                         NEXT STEPS

See 04_oscillator_input_polynomialized.jl to learn how to convert
time-varying inputs into an autonomous system using the "oscillator trick"!
=============================================================================#
