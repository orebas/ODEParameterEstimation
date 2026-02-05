#=============================================================================
                YOUR OWN MODEL: A Fillable Template

Use this template to create parameter estimation problems for your own systems.
Replace the <<PLACEHOLDER>> sections with your model-specific content.

Instructions:
1. Copy this file to a new name (e.g., my_motor_model.jl)
2. Replace all <<PLACEHOLDER>> text with your content
3. Follow the comments for guidance
4. Test with: julia --project -e 'include("your_file.jl")'
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#-----------------------------------------------------------------------------
# MODEL DESCRIPTION
#-----------------------------------------------------------------------------
# <<DESCRIBE YOUR SYSTEM HERE>>
#
# Physics:
#   <<EXPLAIN THE PHYSICAL PRINCIPLES>>
#   <<WRITE THE GOVERNING EQUATIONS IN MATHEMATICAL FORM>>
#
# States:
#   <<LIST YOUR STATE VARIABLES AND THEIR MEANING>>
#
# Parameters:
#   <<LIST ALL PARAMETERS AND WHICH ARE INPUTS>>
#
# Observables:
#   <<WHAT CAN YOU MEASURE?>>
#-----------------------------------------------------------------------------

#=============================================================================
            CHOOSE YOUR APPROACH (uncomment the one you want)
=============================================================================#

# Approach A: Constant input
# Approach B: Driven input (non-autonomous)
# Approach C: Polynomialized input (autonomous)

#=============================================================================
                    APPROACH A: CONSTANT INPUT TEMPLATE
=============================================================================#

function my_model_constant()
    #-------------------------------------------------------------------------
    # Step 1: Define symbolic variables
    #-------------------------------------------------------------------------

    # Parameters: List all parameters to estimate
    # Mark inputs with "# INPUT" comment for documentation
    parameters = @parameters p1 p2 u
    #                        ^   ^  ^
    #                        |   |  └── INPUT: <<describe>>
    #                        |   └───── <<describe p2>>
    #                        └──────── <<describe p1>>

    # States: Dynamic variables that evolve in time
    states = @variables x1(t) x2(t)
    #                   ^     ^
    #                   |     └── <<describe state x2>>
    #                   └──────── <<describe state x1>>

    # Observables: What you can measure
    observables = @variables y1(t) y2(t)

    #-------------------------------------------------------------------------
    # Step 2: True parameter values (for synthetic data)
    #-------------------------------------------------------------------------
    # In a real experiment, replace sample_problem_data() with actual data

    p_true = [
        1.0,    # p1: <<value and units>>
        0.5,    # p2: <<value and units>>
        2.0,    # u: INPUT - <<value and units>>
    ]

    ic_true = [
        0.0,    # x1(0): <<initial condition>>
        1.0,    # x2(0): <<initial condition>>
    ]

    #-------------------------------------------------------------------------
    # Step 3: Define the ODE system
    #-------------------------------------------------------------------------
    # Write your equations: D(state) ~ right_hand_side

    equations = [
        D(x1) ~ p1 * x1 + p2 * x2 + u,     # <<describe equation 1>>
        D(x2) ~ -p1 * x2,                   # <<describe equation 2>>
    ]

    #-------------------------------------------------------------------------
    # Step 4: Define measurements
    #-------------------------------------------------------------------------
    # Map observables to expressions of states

    measured_quantities = [
        y1 ~ x1,        # Measure state x1 directly
        y2 ~ x2,        # Measure state x2 directly
        # Or use combinations: y1 ~ x1 + x2, y2 ~ x1 * x2, etc.
    ]

    #-------------------------------------------------------------------------
    # Step 5: Build and return the problem
    #-------------------------------------------------------------------------

    model, mq = create_ordered_ode_system(
        "my_model_constant",    # <<YOUR MODEL NAME>>
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "my_model_constant",               # name
        model,                              # ODE model
        mq,                                 # measured quantities
        nothing,                            # data (will be sampled)
        [0.0, 10.0],                        # <<TIME INTERVAL: [t_start, t_end]>>
        nothing,                            # solver (use default)
        OrderedDict(parameters .=> p_true), # true parameters
        OrderedDict(states .=> ic_true),    # true initial conditions
        0,                                  # expected unidentifiable count
    )
end

#=============================================================================
                APPROACH B: DRIVEN INPUT TEMPLATE (Non-Autonomous)
=============================================================================#

function my_model_driven()
    #-------------------------------------------------------------------------
    # For time-varying inputs: u(t) = u0 + ua*sin(omega*t)
    #-------------------------------------------------------------------------

    parameters = @parameters p1 p2 u0 ua omega
    #                        ^   ^  ^   ^   ^
    #                        |   |  |   |   └── INPUT: oscillation frequency
    #                        |   |  |   └────── INPUT: oscillation amplitude
    #                        |   |  └────────── INPUT: mean/offset value
    #                        |   └───────────── <<describe p2>>
    #                        └──────────────── <<describe p1>>

    states = @variables x1(t) x2(t)
    observables = @variables y1(t) y2(t)

    p_true = [
        1.0,    # p1
        0.5,    # p2
        2.0,    # u0: mean input
        0.5,    # ua: oscillation amplitude
        3.0,    # omega: oscillation frequency (rad/s)
    ]

    ic_true = [0.0, 1.0]

    # Input as function of time: u(t) = u0 + ua*sin(omega*t)
    equations = [
        D(x1) ~ p1 * x1 + p2 * x2 + (u0 + ua * sin(omega * t)),
        D(x2) ~ -p1 * x2,
    ]

    measured_quantities = [y1 ~ x1, y2 ~ x2]

    model, mq = create_ordered_ode_system(
        "my_model_driven",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "my_model_driven",
        model,
        mq,
        nothing,
        [0.0, 15.0],    # <<LONGER TIME for oscillating systems>>
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
            APPROACH C: POLYNOMIALIZED TEMPLATE (Autonomous)
=============================================================================#

function my_model_polynomialized()
    #-------------------------------------------------------------------------
    # Convert sin(omega*t) to auxiliary oscillator states
    # IMPORTANT: omega is FIXED, not estimated!
    #-------------------------------------------------------------------------

    # FIXED input frequency (you know this from your experiment)
    omega_fixed = 3.0   # rad/s

    # Parameters to estimate (omega is NOT included)
    parameters = @parameters p1 p2 u0 ua

    # States include oscillator variables
    states = @variables x1(t) x2(t) u_sin(t) u_cos(t)
    #                   ^     ^     ^        ^
    #                   |     |     |        └── cos(omega*t) generator
    #                   |     |     └────────── sin(omega*t) generator
    #                   |     └──────────────── original state
    #                   └────────────────────── original state

    observables = @variables y1(t) y2(t) y3(t) y4(t)

    p_true = [
        1.0,    # p1
        0.5,    # p2
        2.0,    # u0
        0.5,    # ua
    ]

    ic_true = [
        0.0,    # x1(0)
        1.0,    # x2(0)
        0.0,    # u_sin(0) = sin(0) = 0  <<ALWAYS 0>>
        1.0,    # u_cos(0) = cos(0) = 1  <<ALWAYS 1>>
    ]

    # AUTONOMOUS equations (no explicit 't')
    equations = [
        D(x1) ~ p1 * x1 + p2 * x2 + u0 + ua * u_sin,
        D(x2) ~ -p1 * x2,
        D(u_sin) ~ omega_fixed * u_cos,       # Oscillator eq 1
        D(u_cos) ~ -omega_fixed * u_sin,      # Oscillator eq 2
    ]

    # MUST observe oscillator states (or know them exactly)
    measured_quantities = [
        y1 ~ x1,
        y2 ~ x2,
        y3 ~ u_sin,   # <<You must know/observe the input signal>>
        y4 ~ u_cos,
    ]

    model, mq = create_ordered_ode_system(
        "my_model_polynomialized",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "my_model_polynomialized",
        model,
        mq,
        nothing,
        [0.0, 15.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                         RUN YOUR MODEL
=============================================================================#

function run_my_model()
    println("="^70)
    println("<<YOUR MODEL NAME>>: Parameter Estimation")
    println("="^70)
    println()

    # Choose which version to run (comment/uncomment as needed)

    #----- Constant Input -----
    println("Running with CONSTANT input...")
    problem = my_model_constant()

    #----- OR: Driven Input -----
    # println("Running with DRIVEN input...")
    # problem = my_model_driven()

    #----- OR: Polynomialized -----
    # println("Running with POLYNOMIALIZED input...")
    # problem = my_model_polynomialized()

    #-------------------------------------------------------------------------
    # Configure estimation options
    #-------------------------------------------------------------------------
    opts = EstimationOptions(
        datasize = 101,              # <<ADJUST: more points for complex dynamics>>
        noise_level = 0.0,           # <<ADJUST: 0.01 = 1% noise>>
        interpolator = InterpolatorAAAD,
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )

    #-------------------------------------------------------------------------
    # Run estimation
    #-------------------------------------------------------------------------
    time_interval = problem.recommended_time_interval
    opts = merge_options(opts, time_interval = time_interval)
    problem_with_data = sample_problem_data(problem, opts)

    println("Time interval: ", time_interval)
    println("Running parameter estimation...")
    println()

    results = analyze_parameter_estimation_problem(problem_with_data, opts)

    println()
    println("="^70)
    println("Done! Check 'results' for estimated parameters.")
    println("="^70)

    return results
end

#=============================================================================
                              RUN IT
=============================================================================#

# Uncomment to run:
# results = run_my_model()

#=============================================================================
                         CHECKLIST BEFORE RUNNING

[ ] Replaced all <<PLACEHOLDER>> text
[ ] Defined all parameters with correct names
[ ] Defined all states
[ ] Wrote correct ODE equations
[ ] Specified what you can measure
[ ] Set appropriate true parameter values
[ ] Set appropriate initial conditions
[ ] Chose reasonable time interval
[ ] Selected the right approach (constant/driven/poly)

TROUBLESHOOTING:
- Solver fails: Check for identifiability issues or try FlowDirectOpt as fallback
- Poor accuracy: Increase datasize
- Multiple solutions: Check identifiability; add more observations
- Numerical issues: Check parameter scales and time interval
=============================================================================#
