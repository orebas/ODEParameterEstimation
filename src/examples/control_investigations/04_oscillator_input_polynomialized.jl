#=============================================================================
        POLYNOMIALIZED INPUTS: The Oscillator State Trick

Some ODE solvers and analysis methods require AUTONOMOUS systems
(no explicit time dependence). But how do we handle sin(omega*t)?

SOLUTION: Add auxiliary "oscillator states" that generate the sin/cos signals!

LEARNING GOALS:
1. Understand why autonomous systems are sometimes required
2. Learn the oscillator state trick: u_sin, u_cos auxiliary variables
3. See how this transforms a non-autonomous system to autonomous
4. Understand the trade-off: more states, but fully polynomial dynamics
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#-----------------------------------------------------------------------------
# THE PROBLEM: Non-Autonomous Systems
#-----------------------------------------------------------------------------
#
# A system like:
#   dx/dt = -a*x + u0 + ua*sin(omega*t)
#
# Has EXPLICIT time dependence through sin(omega*t).
# This is called a "non-autonomous" or "driven" system.
#
# Some methods (especially those using polynomial algebra) work better with
# "autonomous" systems where time doesn't appear explicitly.
#
# THE TRICK: sin(omega*t) and cos(omega*t) are themselves solutions to ODEs!
#
# Let:
#   u_sin(t) = sin(omega*t)
#   u_cos(t) = cos(omega*t)
#
# Then:
#   d(u_sin)/dt = omega * cos(omega*t) = omega * u_cos
#   d(u_cos)/dt = -omega * sin(omega*t) = -omega * u_sin
#
# With initial conditions:
#   u_sin(0) = sin(0) = 0
#   u_cos(0) = cos(0) = 1
#
# Now we can write an AUTONOMOUS system using u_sin and u_cos as states!
#-----------------------------------------------------------------------------

#=============================================================================
            VERSION 1: NON-AUTONOMOUS (Original with sin(omega*t))
=============================================================================#

function linear_system_driven()
    #-------------------------------------------------------------------------
    # This is the ORIGINAL non-autonomous system with explicit sin(omega*t)
    # We include it for comparison purposes.
    #-------------------------------------------------------------------------

    parameters = @parameters a u0 ua omega
    #                        ^  ^   ^   ^
    #                        |  |   |   └── input frequency
    #                        |  |   └────── input oscillation amplitude
    #                        |  └────────── input DC offset
    #                        └───────────── decay rate

    states = @variables x(t)
    observables = @variables y(t)

    p_true = [
        0.5,    # a: decay rate
        1.0,    # u0: DC offset of input
        0.3,    # ua: oscillation amplitude
        2.0,    # omega: oscillation frequency (rad/s)
    ]

    ic_true = [0.0]   # Start at zero

    # Non-autonomous: explicit sin(omega*t)
    equations = [
        D(x) ~ -a * x + u0 + ua * sin(omega * t),
    ]

    measured_quantities = [y ~ x]

    model, mq = create_ordered_ode_system(
        "linear_system_driven",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "linear_system_driven",
        model,
        mq,
        nothing,
        [0.0, 10.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
    VERSION 2: POLYNOMIALIZED (Autonomous with oscillator states)
=============================================================================#

function linear_system_polynomialized()
    #-------------------------------------------------------------------------
    # THE KEY TRANSFORMATION:
    #
    # Original: dx/dt = -a*x + u0 + ua*sin(omega*t)
    #
    # Becomes:  dx/dt = -a*x + u0 + ua*u_sin
    #           d(u_sin)/dt = omega * u_cos
    #           d(u_cos)/dt = -omega * u_sin
    #
    # Now there's NO explicit 't' in the equations!
    # The system is AUTONOMOUS.
    #
    # IMPORTANT: omega is now FIXED, not estimated!
    # Why? Because u_sin and u_cos have FIXED initial conditions:
    #   u_sin(0) = 0  (= sin(0))
    #   u_cos(0) = 1  (= cos(0))
    #
    # If omega were unknown, the oscillator states wouldn't match the data!
    #-------------------------------------------------------------------------

    # omega is FIXED (you know it from your experiment)
    omega_fixed = 2.0   # rad/s

    # Parameters to estimate (omega is NOT here!)
    parameters = @parameters a u0 ua

    # States now include the oscillator variables
    states = @variables x(t) u_sin(t) u_cos(t)
    #                   ^     ^        ^
    #                   |     |        └── cos(omega*t) generator
    #                   |     └────────── sin(omega*t) generator
    #                   └──────────────── original state

    observables = @variables y1(t) y2(t) y3(t)

    p_true = [
        0.5,    # a: decay rate
        1.0,    # u0: DC offset
        0.3,    # ua: oscillation amplitude
    ]

    # Initial conditions: x starts at 0, oscillator at (0, 1)
    ic_true = [
        0.0,    # x(0) = 0
        0.0,    # u_sin(0) = sin(0) = 0
        1.0,    # u_cos(0) = cos(0) = 1
    ]

    # AUTONOMOUS equations (no explicit 't')
    equations = [
        D(x) ~ -a * x + u0 + ua * u_sin,           # Main dynamics
        D(u_sin) ~ omega_fixed * u_cos,             # Oscillator equation 1
        D(u_cos) ~ -omega_fixed * u_sin,            # Oscillator equation 2
    ]

    # IMPORTANT: We must also OBSERVE the oscillator states!
    # Why? Because we need to know the input signal to identify parameters.
    # In practice, this means knowing when you applied your sinusoidal input.
    measured_quantities = [
        y1 ~ x,           # Measure the actual state
        y2 ~ u_sin,       # Measure (or know) the input signal phase
        y3 ~ u_cos,       # Measure (or know) the input signal
    ]

    model, mq = create_ordered_ode_system(
        "linear_system_polynomialized",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "linear_system_polynomialized",
        model,
        mq,
        nothing,
        [0.0, 10.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
    VERSION 3: POLYNOMIALIZED WITH KNOWN INPUT (More realistic)
=============================================================================#

function linear_system_poly_known_input()
    #-------------------------------------------------------------------------
    # In practice, if you KNOW the input signal completely (u0, ua, omega),
    # you shouldn't estimate them! This version fixes all input parameters.
    #
    # This is the most realistic scenario: you control the input, so you
    # know u0, ua, and omega. You only estimate the system parameters (a).
    #-------------------------------------------------------------------------

    # ALL input parameters are FIXED (known from experiment design)
    omega_fixed = 2.0
    u0_fixed = 1.0
    ua_fixed = 0.3

    # Only the system parameter 'a' is estimated
    parameters = @parameters a

    states = @variables x(t) u_sin(t) u_cos(t)
    observables = @variables y1(t) y2(t) y3(t)

    p_true = [0.5]    # Only 'a' to estimate

    ic_true = [0.0, 0.0, 1.0]

    # Input is now completely determined by fixed values
    equations = [
        D(x) ~ -a * x + u0_fixed + ua_fixed * u_sin,
        D(u_sin) ~ omega_fixed * u_cos,
        D(u_cos) ~ -omega_fixed * u_sin,
    ]

    measured_quantities = [y1 ~ x, y2 ~ u_sin, y3 ~ u_cos]

    model, mq = create_ordered_ode_system(
        "linear_system_poly_known_input",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "linear_system_poly_known_input",
        model,
        mq,
        nothing,
        [0.0, 10.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                         DEMONSTRATION RUNNER
=============================================================================#

function run_polynomialization_demo()
    println("="^70)
    println("POLYNOMIALIZATION: Converting to Autonomous Systems")
    println("="^70)
    println()

    #-------------------------------------------------------------------------
    # Explain the concept
    #-------------------------------------------------------------------------
    println("THE PROBLEM:")
    println("  Non-autonomous ODEs have explicit time dependence:")
    println("    dx/dt = -a*x + u0 + ua*sin(omega*t)")
    println()
    println("THE SOLUTION (Oscillator Trick):")
    println("  Replace sin(omega*t) with state variables u_sin, u_cos:")
    println()
    println("    dx/dt      = -a*x + u0 + ua*u_sin")
    println("    d(u_sin)/dt = omega * u_cos")
    println("    d(u_cos)/dt = -omega * u_sin")
    println()
    println("  Initial conditions: u_sin(0)=0, u_cos(0)=1")
    println()
    println("  Now the system is AUTONOMOUS (no explicit 't')!")
    println()

    #-------------------------------------------------------------------------
    # Version 1: Original non-autonomous
    #-------------------------------------------------------------------------
    println("-"^70)
    println("VERSION 1: Non-Autonomous (sin(omega*t) in equations)")
    println("-"^70)
    println()
    println("ODE: dx/dt = -a*x + u0 + ua*sin(omega*t)")
    println("Parameters to estimate: a, u0, ua, omega")
    println()

    problem1 = linear_system_driven()
    opts1 = EstimationOptions(
        datasize = 151,
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

    #-------------------------------------------------------------------------
    # Version 2: Polynomialized
    #-------------------------------------------------------------------------
    println("-"^70)
    println("VERSION 2: Polynomialized (Autonomous)")
    println("-"^70)
    println()
    println("ODEs (autonomous):")
    println("  dx/dt      = -a*x + u0 + ua*u_sin")
    println("  d(u_sin)/dt = omega * u_cos    [omega=2.0 FIXED]")
    println("  d(u_cos)/dt = -omega * u_sin")
    println()
    println("Parameters to estimate: a, u0, ua")
    println("FIXED: omega = 2.0 (known from experiment)")
    println()
    println("Note: We observe u_sin and u_cos (we know the input timing)")
    println()

    problem2 = linear_system_polynomialized()
    opts2 = EstimationOptions(
        datasize = 151,
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
    # Version 3: Known input
    #-------------------------------------------------------------------------
    println("-"^70)
    println("VERSION 3: Polynomialized with FULLY KNOWN Input")
    println("-"^70)
    println()
    println("Same as Version 2, but ALL input parameters are fixed:")
    println("  FIXED: omega=2.0, u0=1.0, ua=0.3")
    println()
    println("Parameters to estimate: a (only)")
    println()
    println("This is the most realistic: you control the input!")
    println()

    problem3 = linear_system_poly_known_input()
    opts3 = EstimationOptions(
        datasize = 151,
        noise_level = 0.0,
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    opts3 = merge_options(opts3, time_interval = problem3.recommended_time_interval)
    problem3_with_data = sample_problem_data(problem3, opts3)

    println("Running estimation...")
    results3 = analyze_parameter_estimation_problem(problem3_with_data, opts3)
    println()

    #-------------------------------------------------------------------------
    # Summary
    #-------------------------------------------------------------------------
    println("="^70)
    println("POLYNOMIALIZATION SUMMARY")
    println("="^70)
    println()
    println("THE OSCILLATOR TRICK:")
    println("  1. Introduce auxiliary states: u_sin, u_cos")
    println("  2. Add their dynamics: ")
    println("       d(u_sin)/dt = omega * u_cos")
    println("       d(u_cos)/dt = -omega * u_sin")
    println("  3. Set ICs: u_sin(0)=0, u_cos(0)=1")
    println("  4. Replace sin(omega*t) → u_sin in main equations")
    println()
    println("KEY POINTS:")
    println()
    println("  1. OMEGA MUST BE FIXED")
    println("     - The oscillator ICs assume omega is known")
    println("     - If omega were unknown, u_sin ≠ sin(omega*t)")
    println()
    println("  2. OSCILLATOR STATES MUST BE OBSERVED")
    println("     - Or their values must be known")
    println("     - This corresponds to knowing when input was applied")
    println()
    println("  3. TRADE-OFF: MORE STATES FOR AUTONOMY")
    println("     - Autonomous systems work with more methods")
    println("     - Cost: 2 extra states per oscillatory input")
    println()
    println("  4. WORKS FOR ANY PERIODIC INPUT")
    println("     - Saw wave, square wave can be Fourier expanded")
    println("     - Add sin/cos pairs for each harmonic needed")
    println()
    println("WHEN TO USE:")
    println("  - Solver requires autonomous systems")
    println("  - Polynomial methods (Gröbner bases, etc.)")
    println("  - When you want clean algebraic structure")
    println()

    return (driven=results1, poly=results2, poly_known=results3)
end

#=============================================================================
                              RUN THE EXAMPLE
=============================================================================#

results = run_polynomialization_demo()

#=============================================================================
                         MATHEMATICAL BACKGROUND

The oscillator states work because sin and cos satisfy a coupled ODE:

  d/dt[sin(ωt)] = ω·cos(ωt)
  d/dt[cos(ωt)] = -ω·sin(ωt)

Or in matrix form:
  d/dt [u_sin]   [0    ω ] [u_sin]
       [u_cos] = [-ω   0 ] [u_cos]

This is a harmonic oscillator! The eigenvalues are ±iω (pure imaginary),
giving oscillatory solutions.

With IC: [u_sin(0), u_cos(0)] = [0, 1]
We get: u_sin(t) = sin(ωt), u_cos(t) = cos(ωt)  ✓
=============================================================================#
