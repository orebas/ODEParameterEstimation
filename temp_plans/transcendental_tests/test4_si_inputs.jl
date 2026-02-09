# Test 4: Does SI.jl support known inputs / known time-varying functions?
# If so, we could declare sin(5t) as a known input rather than a parameter.

using StructuralIdentifiability
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

println("=" ^ 70)
println("TEST 4: SI.jl with known inputs")
println("=" ^ 70)

# ---- Scenario A: Try using a known input function ----
println("\n--- Scenario A: u(t) as explicit input via @variables ---")
try
    @parameters k A
    @variables x(t) u(t)
    @variables y1(t)

    # u(t) is a known input (sinusoidal forcing)
    eqs = [D(x) ~ -k * x + A * u]
    obs = [y1 ~ x]

    # SI.jl ODE constructor with known inputs
    # Check if SI has a way to declare inputs
    sys = ODESystem(eqs, t, [x], [k, A]; name = :input_test)

    # Try assess_identifiability with known_ic
    result = assess_identifiability(sys; measured_quantities = obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario B: SI.jl's own ODE type with inputs ----
println("\n--- Scenario B: Using SI.jl's ODE type directly ---")
try
    # SI.jl has its own ODE type that supports inputs
    # Let's check the constructor signature
    println("  SI.ODE methods:")
    for m in methods(StructuralIdentifiability.ODE)
        println("    $m")
    end
catch e
    println("  Could not list methods: $e")
end

# ---- Scenario C: Try SI's ODE with an input field ----
println("\n--- Scenario C: SI.ODE with inputs ---")
try
    # Try to construct an SI ODE with known inputs
    # The SI.jl ODE type might have an `inputs` field
    @parameters k A
    @variables x(t) u(t)
    @variables y1(t)

    # Check if we can pass inputs to assess_identifiability
    eqs = [D(x) ~ -k * x + A * u]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x, u], [k, A]; name = :input_test2)

    # Some versions of SI support `known_ic` or `funcs_to_check`
    result = assess_identifiability(sys; measured_quantities = obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario D: What if u(t) is in measured_quantities? ----
println("\n--- Scenario D: u(t) as measured (observable) ---")
try
    @parameters k A
    @variables x(t) u(t)
    @variables y1(t) y2(t)

    eqs = [D(x) ~ -k * x + A * u]
    obs = [y1 ~ x, y2 ~ u]  # u is also observed (known signal)

    sys = ODESystem(eqs, t, [x, u], [k, A]; name = :input_observed)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario E: Check if SI has `known_inputs` kwarg ----
println("\n--- Scenario E: Check assess_identifiability kwargs ---")
try
    println("  assess_identifiability methods:")
    for m in methods(StructuralIdentifiability.assess_identifiability)
        println("    $m")
    end
catch e
    println("  Could not list methods: $e")
end

println("\n" * "=" ^ 70)
println("TEST 4 COMPLETE")
println("=" ^ 70)
