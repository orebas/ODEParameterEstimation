#=============================================================================
        COMPARING ALL THREE APPROACHES: A Side-by-Side Study

This file runs the same underlying physical system using all three
input modeling approaches, allowing direct comparison of results.

We use a simplified DC motor model as the test case - a system every
control engineer knows well.

LEARNING GOALS:
1. See all three approaches applied to ONE system
2. Compare parameter recovery accuracy
3. Understand when to use each approach
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#-----------------------------------------------------------------------------
# THE SYSTEM: Simplified DC Motor (First-Order Approximation)
#-----------------------------------------------------------------------------
#
# Full DC motor has electrical (L*di/dt + R*i = V - Kb*ω) and
# mechanical (J*dω/dt = Kt*i - b*ω) dynamics.
#
# For a SIMPLIFIED model (fast electrical dynamics, L→0):
#   J*dω/dt = (Kt/R)*V - (b + Kt*Kb/R)*ω
#
# Defining:
#   K = Kt/R  (input gain)
#   tau_m = J/(b + Kt*Kb/R)  (mechanical time constant)
#
# The simplified model becomes:
#   tau_m * dω/dt = K*V - ω
#
# Or: dω/dt = (K*V - ω) / tau_m
#
# This is a first-order system with input V (voltage).
#-----------------------------------------------------------------------------

#=============================================================================
                    APPROACH 1: CONSTANT INPUT
=============================================================================#

function motor_constant_input()
    #-------------------------------------------------------------------------
    # V is constant → motor reaches steady state ω_ss = K*V
    #-------------------------------------------------------------------------

    parameters = @parameters K tau_m V
    #                        ^  ^     ^
    #                        |  |     └── INPUT: applied voltage (constant)
    #                        |  └──────── mechanical time constant
    #                        └─────────── input gain

    states = @variables omega(t)
    observables = @variables y(t)

    p_true = [
        0.5,    # K: input gain (rad/s per volt)
        0.2,    # tau_m: time constant (seconds)
        10.0,   # V: INPUT - constant voltage (V)
    ]

    ic_true = [0.0]   # Start from rest

    equations = [
        D(omega) ~ (K * V - omega) / tau_m,
    ]

    measured_quantities = [y ~ omega]

    model, mq = create_ordered_ode_system(
        "motor_constant_input",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "motor_constant_input",
        model,
        mq,
        nothing,
        [0.0, 2.0],    # A few time constants
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                    APPROACH 2: DRIVEN INPUT (Non-Autonomous)
=============================================================================#

function motor_driven_input()
    #-------------------------------------------------------------------------
    # V(t) = V0 + Va*sin(omega_in*t)
    # Motor speed oscillates around mean value
    #-------------------------------------------------------------------------

    parameters = @parameters K tau_m V0 Va omega_in
    #                        ^  ^     ^   ^   ^
    #                        |  |     |   |   └── INPUT: oscillation frequency
    #                        |  |     |   └────── INPUT: oscillation amplitude
    #                        |  |     └────────── INPUT: mean voltage
    #                        |  └──────────────── mechanical time constant
    #                        └─────────────────── input gain

    states = @variables omega(t)
    observables = @variables y(t)

    p_true = [
        0.5,    # K: input gain
        0.2,    # tau_m: time constant
        10.0,   # V0: mean voltage
        2.0,    # Va: voltage oscillation amplitude
        5.0,    # omega_in: input frequency (rad/s)
    ]

    ic_true = [0.0]

    # Non-autonomous: explicit sin(omega_in * t)
    equations = [
        D(omega) ~ (K * (V0 + Va * sin(omega_in * t)) - omega) / tau_m,
    ]

    measured_quantities = [y ~ omega]

    model, mq = create_ordered_ode_system(
        "motor_driven_input",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "motor_driven_input",
        model,
        mq,
        nothing,
        [0.0, 5.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
            APPROACH 3: POLYNOMIALIZED (Autonomous with Oscillator)
=============================================================================#

function motor_polynomialized()
    #-------------------------------------------------------------------------
    # Same as driven, but converted to autonomous form using oscillator states.
    # omega_in is FIXED (known from experiment).
    #-------------------------------------------------------------------------

    # FIXED input frequency
    omega_in_fixed = 5.0   # rad/s

    parameters = @parameters K tau_m V0 Va

    states = @variables omega(t) u_sin(t) u_cos(t)
    observables = @variables y1(t) y2(t) y3(t)

    p_true = [
        0.5,    # K: input gain
        0.2,    # tau_m: time constant
        10.0,   # V0: mean voltage
        2.0,    # Va: voltage oscillation amplitude
    ]

    ic_true = [0.0, 0.0, 1.0]   # omega=0, u_sin=0, u_cos=1

    # AUTONOMOUS equations
    equations = [
        D(omega) ~ (K * (V0 + Va * u_sin) - omega) / tau_m,
        D(u_sin) ~ omega_in_fixed * u_cos,
        D(u_cos) ~ -omega_in_fixed * u_sin,
    ]

    # Observe motor speed AND oscillator states
    measured_quantities = [y1 ~ omega, y2 ~ u_sin, y3 ~ u_cos]

    model, mq = create_ordered_ode_system(
        "motor_polynomialized",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "motor_polynomialized",
        model,
        mq,
        nothing,
        [0.0, 5.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                    APPROACH 3B: POLYNOMIALIZED + KNOWN INPUT
            (Most practical: you KNOW the input parameters!)
=============================================================================#

function motor_poly_known_input()
    #-------------------------------------------------------------------------
    # The most realistic scenario: you know V0, Va, omega_in completely
    # because YOU set them on your power supply/function generator!
    #
    # Only estimate system parameters: K, tau_m
    #-------------------------------------------------------------------------

    # ALL INPUT PARAMETERS FIXED
    omega_in_fixed = 5.0
    V0_fixed = 10.0
    Va_fixed = 2.0

    # Only system parameters to estimate
    parameters = @parameters K tau_m

    states = @variables omega(t) u_sin(t) u_cos(t)
    observables = @variables y1(t) y2(t) y3(t)

    p_true = [
        0.5,    # K: input gain
        0.2,    # tau_m: time constant
    ]

    ic_true = [0.0, 0.0, 1.0]

    equations = [
        D(omega) ~ (K * (V0_fixed + Va_fixed * u_sin) - omega) / tau_m,
        D(u_sin) ~ omega_in_fixed * u_cos,
        D(u_cos) ~ -omega_in_fixed * u_sin,
    ]

    measured_quantities = [y1 ~ omega, y2 ~ u_sin, y3 ~ u_cos]

    model, mq = create_ordered_ode_system(
        "motor_poly_known_input",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "motor_poly_known_input",
        model,
        mq,
        nothing,
        [0.0, 5.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                         COMPREHENSIVE COMPARISON
=============================================================================#

function run_comprehensive_comparison()
    println("="^70)
    println("COMPREHENSIVE COMPARISON: All Three Input Approaches")
    println("="^70)
    println()
    println("System: Simplified DC Motor")
    println("Model:  dω/dt = (K*V - ω) / tau_m")
    println()
    println("True parameters: K = 0.5, tau_m = 0.2")
    println("Input voltage:   V = 10 + 2*sin(5*t) for driven cases")
    println()

    # Common options
    common_datasize = 151

    results_all = Dict{String, Any}()

    #-------------------------------------------------------------------------
    # Approach 1: Constant Input
    #-------------------------------------------------------------------------
    println("-"^70)
    println("APPROACH 1: CONSTANT INPUT")
    println("-"^70)
    println("V = 10 V (constant)")
    println("Parameters: K, tau_m, V (3 params)")
    println()

    prob1 = motor_constant_input()
    opts1 = EstimationOptions(
        datasize = common_datasize,
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts1 = merge_options(opts1, time_interval = prob1.recommended_time_interval)
    prob1_data = sample_problem_data(prob1, opts1)
    println("Running...")
    results_all["constant"] = analyze_parameter_estimation_problem(prob1_data, opts1)
    println()

    #-------------------------------------------------------------------------
    # Approach 2: Driven (Non-Autonomous)
    #-------------------------------------------------------------------------
    println("-"^70)
    println("APPROACH 2: DRIVEN INPUT (Non-Autonomous)")
    println("-"^70)
    println("V(t) = V0 + Va*sin(omega_in*t)")
    println("Parameters: K, tau_m, V0, Va, omega_in (5 params)")
    println()

    prob2 = motor_driven_input()
    opts2 = EstimationOptions(
        datasize = common_datasize,
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts2 = merge_options(opts2, time_interval = prob2.recommended_time_interval)
    prob2_data = sample_problem_data(prob2, opts2)
    println("Running...")
    results_all["driven"] = analyze_parameter_estimation_problem(prob2_data, opts2)
    println()

    #-------------------------------------------------------------------------
    # Approach 3A: Polynomialized
    #-------------------------------------------------------------------------
    println("-"^70)
    println("APPROACH 3A: POLYNOMIALIZED (Autonomous)")
    println("-"^70)
    println("Oscillator states: u_sin, u_cos")
    println("FIXED: omega_in = 5.0 rad/s")
    println("Parameters: K, tau_m, V0, Va (4 params)")
    println()

    prob3a = motor_polynomialized()
    opts3a = EstimationOptions(
        datasize = common_datasize,
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts3a = merge_options(opts3a, time_interval = prob3a.recommended_time_interval)
    prob3a_data = sample_problem_data(prob3a, opts3a)
    println("Running...")
    results_all["poly"] = analyze_parameter_estimation_problem(prob3a_data, opts3a)
    println()

    #-------------------------------------------------------------------------
    # Approach 3B: Polynomialized + Known Input
    #-------------------------------------------------------------------------
    println("-"^70)
    println("APPROACH 3B: POLYNOMIALIZED with KNOWN INPUT")
    println("-"^70)
    println("FIXED: V0=10, Va=2, omega_in=5 (all input params known)")
    println("Parameters: K, tau_m (2 params only!)")
    println()

    prob3b = motor_poly_known_input()
    opts3b = EstimationOptions(
        datasize = common_datasize,
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts3b = merge_options(opts3b, time_interval = prob3b.recommended_time_interval)
    prob3b_data = sample_problem_data(prob3b, opts3b)
    println("Running...")
    results_all["poly_known"] = analyze_parameter_estimation_problem(prob3b_data, opts3b)
    println()

    #-------------------------------------------------------------------------
    # SUMMARY TABLE
    #-------------------------------------------------------------------------
    println("="^70)
    println("COMPARISON SUMMARY")
    println("="^70)
    println()
    println("┌──────────────────────┬────────┬────────┬─────────────────────────┐")
    println("│ Approach             │ Params │ States │ Key Feature             │")
    println("├──────────────────────┼────────┼────────┼─────────────────────────┤")
    println("│ 1. Constant          │   3    │   1    │ Simplest; steady state  │")
    println("│ 2. Driven            │   5    │   1    │ Rich dynamics; non-auto │")
    println("│ 3A. Polynomialized   │   4    │   3    │ Autonomous; ω fixed     │")
    println("│ 3B. Poly+Known Input │   2    │   3    │ Fewest unknowns!        │")
    println("└──────────────────────┴────────┴────────┴─────────────────────────┘")
    println()

    #-------------------------------------------------------------------------
    # RECOMMENDATIONS
    #-------------------------------------------------------------------------
    println("RECOMMENDATIONS:")
    println()
    println("Use CONSTANT INPUT (Approach 1) when:")
    println("  - Your experimental setup only allows constant inputs")
    println("  - System is simple and identifiable with constant forcing")
    println("  - You want the simplest possible model")
    println()
    println("Use DRIVEN INPUT (Approach 2) when:")
    println("  - You can apply time-varying inputs")
    println("  - Non-autonomous ODEs are acceptable for your solver")
    println("  - Input parameters may be uncertain")
    println()
    println("Use POLYNOMIALIZED (Approach 3A) when:")
    println("  - Solver requires autonomous systems")
    println("  - Using polynomial algebraic methods")
    println("  - You know the input frequency precisely")
    println()
    println("Use POLY+KNOWN INPUT (Approach 3B) when:")
    println("  - You control the experiment completely")
    println("  - Input signal is accurately known")
    println("  - Want maximum identifiability of system params")
    println("  - THIS IS USUALLY THE BEST CHOICE IN PRACTICE!")
    println()

    #-------------------------------------------------------------------------
    # WHAT TO EXAMINE
    #-------------------------------------------------------------------------
    println("-"^70)
    println("EXAMINE THE RESULTS:")
    println("-"^70)
    println()
    println("For each approach, check:")
    println("  1. Did K recover close to 0.5?")
    println("  2. Did tau_m recover close to 0.2?")
    println("  3. Are there multiple solutions? (indicates non-identifiability)")
    println("  4. What's the solution accuracy?")
    println()
    println("EXPECTED:")
    println("  - All should recover K and tau_m well")
    println("  - Approach 3B should be most accurate (fewest unknowns)")
    println("  - Approach 1 might have more sensitivity to noise")
    println()

    return results_all
end

#=============================================================================
                              RUN THE COMPARISON
=============================================================================#

results = run_comprehensive_comparison()

#=============================================================================
                         FINAL THOUGHTS

This comparison demonstrates that:

1. The SAME physical system can be modeled multiple ways
2. Each approach has trade-offs in complexity vs. information used
3. The "right" choice depends on:
   - What you know about the input
   - What your solver can handle
   - How many parameters you need to estimate

GOLDEN RULE: Use all the information you have!
  - If you know the input frequency → fix it (don't estimate)
  - If you control the input amplitude → fix it
  - Only estimate what you truly don't know

See 06_your_own_model_template.jl for a template to create your own models!
=============================================================================#
