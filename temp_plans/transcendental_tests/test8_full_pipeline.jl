# Test 8: Full pipeline test through ODEParameterEstimation
# Test whether the "input variable" approach works end-to-end

# Load ODEPE which brings in all dependencies
include("/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/load_examples.jl")

using SciMLBase

println("=" ^ 70)
println("TEST 8: Full pipeline with input variable approach")
println("=" ^ 70)

# ---- Test A: Can we even create an ODESystem with a state that has no ODE? ----
println("\n--- Test A: Create PEP with input variable ---")
try
    _k, _A = @parameters k A
    _x = only(@variables x(t))
    _u_f = only(@variables u_f(t))
    _y1 = only(@variables y1(t))
    _y2 = only(@variables y2(t))

    _eqs = [D(_x) ~ -_k * _x + _A * _u_f]
    _obs = [_y1 ~ _x, _y2 ~ _u_f]

    _states = [_x, _u_f]
    _params = [_k, _A]

    println("  Creating ODESystem...")
    _model, _mq = create_ordered_ode_system("input_test", _states, _params, _eqs, _obs)
    println("  create_ordered_ode_system: SUCCESS")
    println("  Model equations: $(ModelingToolkit.equations(_model.system))")
    println("  Model states: $(ModelingToolkit.unknowns(_model.system))")

    # Create PEP
    _pep = ParameterEstimationProblem(
        "input_test", _model, _mq, nothing,
        [0.0, 2.0], nothing,
        OrderedDict(_params .=> [0.5, 1.0]),
        OrderedDict(_states .=> [1.0, 0.0]),
        0,
    )
    println("  PEP created: SUCCESS")
    println("  PEP ic: $(_pep.ic)")
    println("  PEP p_true: $(_pep.p_true)")
catch e
    println("  FAILED: $(typeof(e))")
    println("  $(sprint(showerror, e))")
end

# ---- Test B: Try sample_problem_data ----
println("\n--- Test B: sample_problem_data with input variable ---")
println("  (This will try ODE integration - u_f has no ODE equation)")
try
    _k, _A = @parameters k A
    _x = only(@variables x(t))
    _u_f = only(@variables u_f(t))
    _y1 = only(@variables y1(t))
    _y2 = only(@variables y2(t))

    _eqs = [D(_x) ~ -_k * _x + _A * _u_f]
    _obs = [_y1 ~ _x, _y2 ~ _u_f]

    _model, _mq = create_ordered_ode_system("sample_test", [_x, _u_f], [_k, _A], _eqs, _obs)

    _pep = ParameterEstimationProblem(
        "sample_test", _model, _mq, nothing,
        [0.0, 2.0], nothing,
        OrderedDict([_k, _A] .=> [0.5, 1.0]),
        OrderedDict([_x, _u_f] .=> [1.0, 0.0]),
        0,
    )

    _opts = EstimationOptions(datasize = 21, noise_level = 0.0, system_solver = SolverHC,
                              max_num_points = 2, shooting_points = 1)

    println("  Calling sample_problem_data...")
    _sampled = sample_problem_data(_pep, _opts)
    println("  sample_problem_data: SUCCESS")
    println("  Data sample keys: $(keys(_sampled.data_sample))")
catch e
    println("  FAILED: $(typeof(e))")
    println("  $(sprint(showerror, e))")
    bt = catch_backtrace()
    for (i, frame) in enumerate(stacktrace(bt))
        i > 10 && break
        println("    $frame")
    end
end

# ---- Test C: What if we provide the data externally (pre-computed)? ----
println("\n--- Test C: Provide pre-computed data for input variable ---")
println("  If ODE integration fails, we could compute u_f(t)=sin(5t) ourselves")
println("  and inject it into the data_sample OrderedDict")
try
    # Create a simple polynomial model first (just D(x) = -k*x + A*u_f)
    # with u_f as a parameter this time, so ODE integration works
    _k, _A, _omega = @parameters k A omega_val
    _x = only(@variables x(t))
    _u_s = only(@variables u_sin(t))
    _u_c = only(@variables u_cos(t))
    _y1 = only(@variables y1(t))
    _y2 = only(@variables y2(t))
    _y3 = only(@variables y3(t))

    # Full polynomial model WITH oscillator ODEs
    _eqs = [
        D(_x) ~ -_k * _x + _A * _u_s,
        D(_u_s) ~ _omega * _u_c,
        D(_u_c) ~ -_omega * _u_s,
    ]
    _obs = [_y1 ~ _x, _y2 ~ _u_s, _y3 ~ _u_c]

    omega_true = 5.0
    _model, _mq = create_ordered_ode_system("poly_model", [_x, _u_s, _u_c], [_k, _A, _omega], _eqs, _obs)

    _pep = ParameterEstimationProblem(
        "poly_model", _model, _mq, nothing,
        [0.0, 2.0], nothing,
        OrderedDict([_k, _A, _omega] .=> [0.5, 1.0, omega_true]),
        OrderedDict([_x, _u_s, _u_c] .=> [1.0, 0.0, 1.0]),
        0,
    )

    _opts = EstimationOptions(datasize = 51, noise_level = 0.0, system_solver = SolverHC,
                              max_num_points = 2, shooting_points = 2, diagnostics = true)

    println("  Sampling polynomial model...")
    _sampled = sample_problem_data(_pep, _opts)
    println("  sample_problem_data: SUCCESS")

    println("  Running analysis...")
    _result = analyze_parameter_estimation_problem(_sampled, _opts)
    println("  Analysis: SUCCESS")
    println("  Result type: $(typeof(_result))")
catch e
    println("  FAILED: $(typeof(e))")
    println("  $(sprint(showerror, e))")
    bt = catch_backtrace()
    for (i, frame) in enumerate(stacktrace(bt))
        i > 10 && break
        println("    $frame")
    end
end

# ---- Test D: Substitution of sin() with numerical value in Symbolics ----
println("\n--- Test D: Symbolics.substitute with sin() subexpressions ---")
try
    _k, _A = @parameters k A
    _x = only(@variables x(t))

    # Expression with sin(5t)
    expr = -_k * _x + _A * sin(5.0 * t)
    println("  Expression: $expr")

    # Method 1: Substitute t directly
    expr1 = Symbolics.substitute(expr, Dict(t => 0.5))
    println("  After t=0.5: $expr1")

    # Method 2: Substitute sin(5.0*t) directly with its value
    sin_val = sin(5.0 * 0.5)
    expr2 = Symbolics.substitute(expr, Dict(sin(5.0 * t) => sin_val))
    println("  After sin(5t)->$sin_val: $expr2")

    # Method 3: Substitute both t AND evaluate
    # First identify the t-only subexpressions, evaluate, then substitute
    println("\n  Method 3: Build substitution dict for all transcendentals at t=0.5")
    subst_dict = Dict(
        sin(5.0 * t) => sin(5.0 * 0.5),
        cos(5.0 * t) => cos(5.0 * 0.5),  # in case derivatives create cos terms
    )
    expr3 = Symbolics.substitute(expr, subst_dict)
    println("  Result: $expr3")

    # Is this now purely polynomial in k, A, x?
    println("  Variables remaining: $(Symbolics.get_variables(expr3))")
catch e
    println("  FAILED: $(typeof(e))")
    println("  $(sprint(showerror, e))")
end

println("\n" * "=" ^ 70)
println("TEST 8 COMPLETE")
println("=" ^ 70)
