# Test 2: What does SIAN.jl do with sin/cos?
# SIAN is used in the pipeline for identifiability + equation generation.

using SIAN
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

println("=" ^ 70)
println("TEST 2: SIAN.jl with transcendental functions")
println("=" ^ 70)

# ---- Scenario A: Polynomial system (baseline) ----
println("\n--- Scenario A: Polynomial system (baseline) ---")
try
    @parameters k A
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k, A]; name = :sian_poly)
    # SIAN's main function
    result = identifiability_ode(sys, obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario B: sin(constant * t) ----
println("\n--- Scenario B: sin(5.0 * t) forcing ---")
try
    @parameters k A
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * sin(5.0 * t)]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k, A]; name = :sian_sin_t)
    result = identifiability_ode(sys, obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario C: sin(state) ----
println("\n--- Scenario C: sin(x(t)) ---")
try
    @parameters k
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * sin(x)]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k]; name = :sian_sin_state)
    result = identifiability_ode(sys, obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

# ---- Scenario D: Placeholder parameter ----
println("\n--- Scenario D: Placeholder approach ---")
try
    @parameters k A p_sin
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * p_sin]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k, A, p_sin]; name = :sian_placeholder)
    result = identifiability_ode(sys, obs)
    println("SUCCESS: $result")
catch e
    println("FAILED: $(typeof(e))")
    println("  Message: $(sprint(showerror, e))")
end

println("\n" * "=" ^ 70)
println("TEST 2 COMPLETE")
println("=" ^ 70)
