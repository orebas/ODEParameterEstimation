# Test 5: End-to-end test of placeholder approach through our actual pipeline
# Compare: manual polynomial model vs placeholder-substituted model

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

println("=" ^ 70)
println("TEST 5: Full pipeline test with placeholder approach")
println("=" ^ 70)

# ---- Model A: Manually polynomialized (known working pattern) ----
# This is similar to dc_motor_identifiable - uses u_sin/u_cos auxiliary states
println("\n--- Model A: Manual polynomialization (u_sin/u_cos oscillator) ---")
function test_model_manual_poly()
    @parameters k A omega_val
    @variables x(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    omega_true = 5.0

    eqs = [
        D(x) ~ -k * x + A * u_sin,          # original: A * sin(omega*t)
        D(u_sin) ~ omega_val * u_cos,         # auxiliary oscillator
        D(u_cos) ~ -omega_val * u_sin,        # auxiliary oscillator
    ]
    obs = [y1 ~ x, y2 ~ u_sin, y3 ~ u_cos]

    states = [x, u_sin, u_cos]
    parameters = [k, A, omega_val]

    model, mq = create_ordered_ode_system("manual_poly", states, parameters, eqs, obs)

    return ParameterEstimationProblem(
        "manual_poly", model, mq, nothing,
        [0.0, 2.0], nothing,
        OrderedDict(parameters .=> [0.5, 1.0, omega_true]),
        OrderedDict(states .=> [1.0, 0.0, 1.0]),  # sin(0)=0, cos(0)=1
        0,
    )
end

# ---- Model B: Placeholder approach ----
# Replace sin(5t) with a parameter p_forcing, keep the model polynomial
println("\n--- Model B: Placeholder parameter approach ---")
function test_model_placeholder()
    @parameters k A p_forcing
    @variables x(t)
    @variables y1(t)

    # p_forcing stands in for sin(5.0 * t)
    # SI.jl will see this as a polynomial system with 3 parameters
    eqs = [D(x) ~ -k * x + A * p_forcing]
    obs = [y1 ~ x]

    states = [x]
    parameters = [k, A, p_forcing]

    model, mq = create_ordered_ode_system("placeholder", states, parameters, eqs, obs)

    return ParameterEstimationProblem(
        "placeholder", model, mq, nothing,
        [0.0, 2.0], nothing,
        OrderedDict(parameters .=> [0.5, 1.0, 0.0]),  # p_forcing = sin(5*0) = 0
        OrderedDict(states .=> [1.0]),
        0,
    )
end

# Run Model A through SIAN/SI to see what template equations look like
println("\n--- Running Model A (manual poly) through pipeline ---")
try
    pep_a = test_model_manual_poly()
    opts = EstimationOptions(datasize = 51, noise_level = 0.0, system_solver = SolverHC,
                             max_num_points = 2, shooting_points = 1, diagnostics = true)
    sampled = sample_problem_data(pep_a, opts)
    result = analyze_parameter_estimation_problem(sampled, opts)
    println("Model A SUCCESS - got results")
    if result isa Tuple && length(result) >= 1
        println("  Result type: $(typeof(result))")
    end
catch e
    println("Model A FAILED: $(typeof(e))")
    println("  $(sprint(showerror, e))")
end

# Run Model B through SIAN/SI
println("\n--- Running Model B (placeholder) through pipeline ---")
try
    pep_b = test_model_placeholder()
    opts = EstimationOptions(datasize = 51, noise_level = 0.0, system_solver = SolverHC,
                             max_num_points = 2, shooting_points = 1, diagnostics = true)
    sampled = sample_problem_data(pep_b, opts)
    result = analyze_parameter_estimation_problem(sampled, opts)
    println("Model B SUCCESS - got results")
    if result isa Tuple && length(result) >= 1
        println("  Result type: $(typeof(result))")
    end
catch e
    println("Model B FAILED: $(typeof(e))")
    println("  $(sprint(showerror, e))")
end

# ---- Model C: Try the raw transcendental (expect failure - but let's see the error) ----
println("\n--- Model C: Raw sin(5.0*t) - expect failure ---")
function test_model_raw_sin()
    @parameters k A
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * sin(5.0 * t)]
    obs = [y1 ~ x]

    states = [x]
    parameters = [k, A]

    model, mq = create_ordered_ode_system("raw_sin", states, parameters, eqs, obs)

    return ParameterEstimationProblem(
        "raw_sin", model, mq, nothing,
        [0.0, 2.0], nothing,
        OrderedDict(parameters .=> [0.5, 1.0]),
        OrderedDict(states .=> [1.0]),
        0,
    )
end

try
    pep_c = test_model_raw_sin()
    opts = EstimationOptions(datasize = 51, noise_level = 0.0, system_solver = SolverHC,
                             max_num_points = 2, shooting_points = 1, diagnostics = true)
    sampled = sample_problem_data(pep_c, opts)
    result = analyze_parameter_estimation_problem(sampled, opts)
    println("Model C SUCCESS (unexpected!) - got results")
catch e
    println("Model C FAILED (expected): $(typeof(e))")
    println("  $(sprint(showerror, e))")
end

println("\n" * "=" ^ 70)
println("TEST 5 COMPLETE")
println("=" ^ 70)
