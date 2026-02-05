#=============================================================================
                    HELLO WORLD: Simplest Control Input Example

This is the simplest possible example of parameter estimation with a control
input. Use this to understand the basic 3-step workflow before moving on to
more complex systems.

LEARNING GOAL: Understand how control inputs are handled - they're just
parameters that we mark with "# INPUT" for documentation purposes.
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#-----------------------------------------------------------------------------
# THE MODEL: First-Order Decay with Constant Input
#-----------------------------------------------------------------------------
#
# Physics: A quantity x decays exponentially while being replenished at a
#          constant rate u. Think of:
#          - A drug concentration in blood (decay + constant IV drip)
#          - Heat in a room (loss to environment + constant heater)
#          - Money in an account (spending rate + constant income)
#
# Equation: dx/dt = -a*x + u
#
# Where:
#   a = decay rate (parameter to estimate)
#   u = input rate (control INPUT - also to estimate, but in practice often known)
#   x = state variable (measured)
#
# Steady state: x_ss = u/a  (when dx/dt = 0)
#-----------------------------------------------------------------------------

function hello_world_constant_input()
    #-------------------------------------------------------------------------
    # STEP 1: Define symbolic variables
    #-------------------------------------------------------------------------
    # Parameters: things we want to estimate
    # Note: u is marked as INPUT to indicate it's a control signal
    parameters = @parameters a u
    #                        ^  ^
    #                        |  └── INPUT: constant forcing/input rate
    #                        └───── decay rate (1/time)

    # States: dynamic variables that evolve according to the ODE
    states = @variables x(t)

    # Observables: what we actually measure (can be states or functions of states)
    observables = @variables y(t)

    #-------------------------------------------------------------------------
    # STEP 2: Specify true values (for synthetic data generation)
    #-------------------------------------------------------------------------
    # In a real experiment, you wouldn't know these - you'd have actual data!
    # Here we use them to generate synthetic "measurement" data.

    p_true = [
        0.5,    # a: decay rate - half the value decays per unit time
        1.0,    # u: INPUT - constant input rate
    ]

    # Initial condition: start at zero and watch the system approach steady state
    # Steady state will be: x_ss = u/a = 1.0/0.5 = 2.0
    ic_true = [0.0]

    #-------------------------------------------------------------------------
    # STEP 3: Define the ODE system
    #-------------------------------------------------------------------------
    # This is the core dynamics: dx/dt = -a*x + u
    # The state x decays proportionally to itself (-a*x) while being
    # replenished at constant rate u.

    equations = [
        D(x) ~ -a * x + u,   # First-order dynamics with constant input
    ]

    #-------------------------------------------------------------------------
    # STEP 4: Define what we measure
    #-------------------------------------------------------------------------
    # Here we directly observe the state x. In more complex systems,
    # you might only observe combinations of states.

    measured_quantities = [y ~ x]

    #-------------------------------------------------------------------------
    # STEP 5: Build the model and return the problem
    #-------------------------------------------------------------------------
    model, mq = create_ordered_ode_system(
        "hello_world_constant_input",
        states,
        parameters,
        equations,
        measured_quantities
    )

    return ParameterEstimationProblem(
        "hello_world_constant_input",      # name
        model,                              # ODE model
        mq,                                 # measured quantities
        nothing,                            # data (will be sampled)
        [0.0, 10.0],                        # time interval (enough to reach steady state)
        nothing,                            # solver (use default)
        OrderedDict(parameters .=> p_true), # true parameters
        OrderedDict(states .=> ic_true),    # true initial conditions
        0,                                  # expected unidentifiable count
    )
end

#=============================================================================
                         RUNNING THE ESTIMATION
=============================================================================#

function run_hello_world()
    println("="^70)
    println("HELLO WORLD: Parameter Estimation with Constant Input")
    println("="^70)
    println()

    #-------------------------------------------------------------------------
    # Create the problem
    #-------------------------------------------------------------------------
    println("Step 1: Creating the estimation problem...")
    problem = hello_world_constant_input()
    println("  Model: dx/dt = -a*x + u")
    println("  True parameters: a = 0.5, u = 1.0 (INPUT)")
    println("  Initial condition: x(0) = 0.0")
    println("  Expected steady state: x_ss = u/a = 2.0")
    println()

    #-------------------------------------------------------------------------
    # Configure options
    #-------------------------------------------------------------------------
    println("Step 2: Configuring estimation options...")
    opts = EstimationOptions(
        datasize = 101,              # Number of data points to sample
        noise_level = 0.0,           # No noise for this simple example
        interpolator = InterpolatorAAAD,  # Adaptive interpolation method
        system_solver = SolverHC,    # Homotopy continuation solver
        flow = FlowStandard,         # Standard polynomial system solving
    )
    println("  Data points: 101")
    println("  Noise level: 0% (perfect data)")
    println("  Solver: Homotopy Continuation (SolverHC)")
    println()

    #-------------------------------------------------------------------------
    # Sample synthetic data
    #-------------------------------------------------------------------------
    println("Step 3: Sampling synthetic data...")
    time_interval = problem.recommended_time_interval
    opts = merge_options(opts, time_interval = time_interval)
    problem_with_data = sample_problem_data(problem, opts)
    println("  Time interval: [$(time_interval[1]), $(time_interval[2])]")
    println()

    #-------------------------------------------------------------------------
    # Run the estimation
    #-------------------------------------------------------------------------
    println("Step 4: Running parameter estimation...")
    println("  (This may take a moment...)")
    results = analyze_parameter_estimation_problem(problem_with_data, opts)
    println()

    #-------------------------------------------------------------------------
    # Interpret results
    #-------------------------------------------------------------------------
    println("="^70)
    println("RESULTS")
    println("="^70)
    println()

    # The results contain estimated parameter values
    # Let's show what we got
    println("True values:     a = 0.5,  u = 1.0")
    println()
    println("Check the results object for estimated values.")
    println("Look for parameter estimates close to the true values.")
    println()

    #-------------------------------------------------------------------------
    # What to look for
    #-------------------------------------------------------------------------
    println("-"^70)
    println("WHAT TO LOOK FOR:")
    println("-"^70)
    println()
    println("1. PARAMETER RECOVERY: Estimates should be close to true values")
    println("   - If a ≈ 0.5 and u ≈ 1.0, estimation succeeded!")
    println()
    println("2. IDENTIFIABILITY: Both parameters should be recoverable")
    println("   - This simple system is structurally identifiable")
    println("   - The steady state x_ss = u/a provides information about u/a")
    println("   - The decay rate is visible in the transient response")
    println()
    println("3. UNIQUENESS: Should get a unique solution (not multiple)")
    println()

    return results
end

#=============================================================================
                              RUN THE EXAMPLE
=============================================================================#

# Execute the example
results = run_hello_world()

#=============================================================================
                         KEY TAKEAWAYS

1. INPUT parameters (like u) are treated identically to other parameters
   - The "# INPUT" comment is just documentation for humans
   - The estimation algorithm doesn't distinguish between them

2. The 3-step workflow:
   a. Define model (parameters, states, equations, observations)
   b. Configure options and sample/load data
   c. Run analyze_parameter_estimation_problem()

3. For simple systems like this, both parameters are identifiable
   - The decay rate 'a' is visible in how fast x approaches steady state
   - The input rate 'u' is visible in the steady state value

4. Next: See 02_rc_circuit_voltage_step.jl for a more realistic example!
=============================================================================#
