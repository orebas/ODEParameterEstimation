# Test 6: Deeper investigation of the "input variable" approach
# Key finding from Test 4C: SI.jl treats states-without-ODEs as inputs.

using StructuralIdentifiability
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

println("=" ^ 70)
println("TEST 6: Input variable approach - deeper investigation")
println("=" ^ 70)

# ---- Scenario A: Two-state system with input ----
println("\n--- Scenario A: 2-state system with sinusoidal input ---")
try
    @parameters k A b
    @variables x1(t) x2(t) u_f(t)
    @variables y1(t) y2(t)

    eqs = [
        D(x1) ~ -k * x1 + A * u_f,
        D(x2) ~ x1 - b * x2,
    ]
    obs = [y1 ~ x1, y2 ~ x2]

    # u_f is a state but has no ODE → SI treats as input
    sys = ODESystem(eqs, t, [x1, x2, u_f], [k, A, b]; name = :two_state_input)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("  Identifiability: $result")
catch e
    println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
end

# ---- Scenario B: Both sin and cos inputs (same frequency) ----
println("\n--- Scenario B: Two inputs u_sin, u_cos (same frequency) ---")
try
    @parameters k A B
    @variables x(t) u_sin(t) u_cos(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * u_sin + B * u_cos]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x, u_sin, u_cos], [k, A, B]; name = :two_inputs)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("  Identifiability: $result")
catch e
    println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
end

# ---- Scenario C: DC motor pattern - input WITHOUT oscillator ODE ----
println("\n--- Scenario C: DC motor with sinusoidal input variable ---")
try
    @parameters R L Kb Kt J b_fric V0 Va
    @variables omega(t) i_arm(t) u_sin(t)
    @variables y1(t)

    V_input = V0 + Va * u_sin

    eqs = [
        D(omega) ~ (Kt * i_arm - b_fric * omega) / J,
        D(i_arm) ~ (V_input - R * i_arm - Kb * omega) / L,
    ]
    obs = [y1 ~ omega]

    sys = ODESystem(eqs, t, [omega, i_arm, u_sin], [R, L, Kb, Kt, J, b_fric, V0, Va]; name = :dc_motor_input)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("  Identifiability: $result")
catch e
    println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
end

# ---- Scenario D: What if the input is also observed? ----
println("\n--- Scenario D: Input as observed (like _identifiable models) ---")
try
    @parameters k A
    @variables x(t) u_f(t)
    @variables y1(t) y2(t)

    eqs = [D(x) ~ -k * x + A * u_f]
    obs = [y1 ~ x, y2 ~ u_f]

    sys = ODESystem(eqs, t, [x, u_f], [k, A]; name = :input_observed)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("  Identifiability: $result")
catch e
    println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
end

# ---- Scenario E: Compare: input var vs placeholder parameter ----
println("\n--- Scenario E: Side-by-side - input var vs placeholder param ---")
println("  (Input var approach:)")
try
    @parameters k A
    @variables x(t) u_f(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * u_f]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x, u_f], [k, A]; name = :as_input)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("    $result")
catch e
    println("    FAILED: $e")
end

println("  (Placeholder param approach:)")
try
    @parameters k A p_sin
    @variables x(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * p_sin]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x], [k, A, p_sin]; name = :as_param)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("    $result")
catch e
    println("    FAILED: $e")
end

# ---- Scenario F: Multiple frequency inputs ----
println("\n--- Scenario F: Two different frequencies ---")
println("  Model: D(x) = -k*x + A*u_sin1 + B*u_sin2")
try
    @parameters k A B
    @variables x(t) u_sin1(t) u_sin2(t)
    @variables y1(t)

    eqs = [D(x) ~ -k * x + A * u_sin1 + B * u_sin2]
    obs = [y1 ~ x]

    sys = ODESystem(eqs, t, [x, u_sin1, u_sin2], [k, A, B]; name = :two_freq)
    result = assess_identifiability(sys; measured_quantities = obs)
    println("  Identifiability: $result")
catch e
    println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
end

println("\n" * "=" ^ 70)
println("TEST 6 COMPLETE")
println("=" ^ 70)
