# Test 1: What does StructuralIdentifiability.jl do with sin/cos in ODEs?
# We try several scenarios to see what fails and what works.

using StructuralIdentifiability
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

println("=" ^ 70)
println("TEST 1: StructuralIdentifiability.jl with transcendental functions")
println("=" ^ 70)

# ---- Scenario A: Pure polynomial system (baseline - should work) ----
println("\n--- Scenario A: Polynomial system (baseline) ---")
try
    @parameters k A
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k, A]; name = :poly_test)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $e")
end

# ---- Scenario B: sin(constant * t) as forcing ----
println("\n--- Scenario B: sin(5.0 * t) forcing ---")
try
    @parameters k A
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * sin(5.0 * t)]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k, A]; name = :sin_const_t)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario C: sin(parameter * t) as forcing ----
println("\n--- Scenario C: sin(omega * t) forcing (omega is parameter) ---")
try
    @parameters k A omega
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * sin(omega * t)]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k, A, omega]; name = :sin_param_t)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario D: sin(state) - state-dependent transcendental ----
println("\n--- Scenario D: sin(x(t)) - state-dependent ---")
try
    @parameters k
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * sin(x)]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k]; name = :sin_state)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario E: cos(constant * t) as forcing ----
println("\n--- Scenario E: cos(3.0 * t) forcing ---")
try
    @parameters k A
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * cos(3.0 * t)]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k, A]; name = :cos_const_t)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario F: Placeholder parameter approach ----
println("\n--- Scenario F: Placeholder approach (replace sin(5t) with parameter p_sin) ---")
try
    @parameters k A p_sin
    @variables x(t)
    @variables y1(t)

    # Instead of sin(5t), use parameter p_sin
    eqs = [D(x) ~ -k * x + A * p_sin]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k, A, p_sin]; name = :placeholder_test)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("SUCCESS: $result")
    println("  (Note: p_sin would be substituted with sin(5*t_k) at solve time)")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

println("\n" * "=" ^ 70)
println("TEST 1 COMPLETE")
println("=" ^ 70)
