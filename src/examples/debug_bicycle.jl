# Minimal script to reproduce the bicycle_model ForwardDiff error

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

# Create bicycle model inline
function test_bicycle_model()
    parameters = @parameters Cf Cr m Iz lf lr Vx delta
    states = @variables vy(t) r(t)
    observables = @variables y1(t) y2(t)

    p_true = [
        80000.0, 80000.0, 1500.0, 2500.0, 1.2, 1.4, 20.0, 0.02,
    ]
    ic_true = [0.0, 0.0]

    equations = [
        D(vy) ~ (Cf * (delta - (vy + lf * r) / Vx) + Cr * (-(vy - lr * r) / Vx)) / m - Vx * r,
        D(r) ~ (lf * Cf * (delta - (vy + lf * r) / Vx) - lr * Cr * (-(vy - lr * r) / Vx)) / Iz,
    ]

    measured_quantities = [y1 ~ r, y2 ~ vy]

    model, mq = create_ordered_ode_system("bicycle_model", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "bicycle_model",
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

# Run the test
println("Creating bicycle model...")
PEP = test_bicycle_model()

# Test the FULL workflow like analyze_parameter_estimation_problem does
println("\nRunning full analyze_parameter_estimation_problem workflow...")
try
    opts = EstimationOptions(
        flow = FlowStandard,
        nooutput = false,
        time_interval = [0.0, 5.0],
        # Using default GPR interpolator
    )

    # Sample synthetic data first (just like run_parameter_estimation_examples does)
    println("Generating synthetic data...")
    PEP_with_data = sample_problem_data(PEP, opts)

    println("Running parameter estimation...")
    result = analyze_parameter_estimation_problem(PEP_with_data, opts)
    println("SUCCESS: Full analysis completed")
catch e
    println("FAILURE")
    println(e)
    println("\nStacktrace:")
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end
