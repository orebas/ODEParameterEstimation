# Test 7: Symbolic differentiation with transcendental functions
# The user's core idea: differentiation handles sin/cos correctly.
# Verify that Symbolics.jl's derivative engine works with sin/cos/exp.

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

println("=" ^ 70)
println("TEST 7: Symbolic differentiation with transcendental functions")
println("=" ^ 70)

# ---- Test A: Differentiate sin(5t) ----
println("\n--- Test A: d/dt sin(5t) ---")
try
    expr = sin(5.0 * t)
    deriv = Symbolics.derivative(expr, t)
    println("  sin(5t)' = $deriv")
    # Expected: 5.0*cos(5.0*t)
catch e
    println("  FAILED: $e")
end

# ---- Test B: Differentiate cos(3t) ----
println("\n--- Test B: d/dt cos(3t) ---")
try
    expr = cos(3.0 * t)
    deriv = Symbolics.derivative(expr, t)
    println("  cos(3t)' = $deriv")
    # Expected: -3.0*sin(3.0*t)
catch e
    println("  FAILED: $e")
end

# ---- Test C: Differentiate k*sin(5t) + A (with parameters) ----
println("\n--- Test C: d/dt (k*x + A*sin(5t)) where x = x(t) ---")
try
    @parameters k A
    @variables x(t)

    expr = -k * x + A * sin(5.0 * t)
    deriv = Symbolics.derivative(expr, t)
    println("  (-k*x + A*sin(5t))' = $deriv")
    # Expected: -k*D(x) + 5A*cos(5t)
catch e
    println("  FAILED: $e")
end

# ---- Test D: Second derivative ----
println("\n--- Test D: d²/dt² sin(5t) ---")
try
    expr = sin(5.0 * t)
    deriv1 = Symbolics.derivative(expr, t)
    deriv2 = Symbolics.derivative(deriv1, t)
    println("  sin(5t)'' = $deriv2")
    # Expected: -25*sin(5t)
catch e
    println("  FAILED: $e")
end

# ---- Test E: expand_derivatives on D(sin(5t)) ----
println("\n--- Test E: expand_derivatives on D(sin(5t)) ---")
try
    expr = D(sin(5.0 * t))
    expanded = Symbolics.expand_derivatives(expr)
    println("  expand_derivatives(D(sin(5t))) = $expanded")
catch e
    println("  FAILED: $e")
end

# ---- Test F: What does the ODE look like after symbolic differentiation? ----
println("\n--- Test F: Full ODE differentiation ---")
try
    @parameters k A
    @variables x(t)
    @variables y1(t)

    # ODE: D(x) = -k*x + A*sin(5t)
    # Observable: y1 = x → y1' = D(x) = -k*x + A*sin(5t)
    #                       y1'' = D(D(x)) = -k*D(x) + 5A*cos(5t)
    #                            = -k*(-k*x + A*sin(5t)) + 5A*cos(5t)
    #                            = k²x - kA*sin(5t) + 5A*cos(5t)

    rhs = -k * x + A * sin(5.0 * t)
    println("  D(x) = $rhs")

    # First derivative of the RHS (using chain rule with D(x) = rhs)
    drhs = Symbolics.expand_derivatives(D(rhs))
    println("  D(D(x)) = $drhs")

    # Substitute D(x) = rhs in the second derivative
    # This is what the pipeline does - substitute the ODE back in
    Dt_x = Symbolics.variable(:Dx)  # placeholder
    drhs_subst = Symbolics.substitute(drhs, Dict(D(x) => rhs))
    println("  After substituting D(x) back: $drhs_subst")

    # Now at time t=0.5: sin(5*0.5) = sin(2.5), cos(5*0.5) = cos(2.5)
    t_val = 0.5
    sin_val = sin(5.0 * t_val)
    cos_val = cos(5.0 * t_val)
    println("\n  At t=$t_val: sin(5t)=$sin_val, cos(5t)=$cos_val")

    # After substituting t and x(t_val), what remains should be polynomial in k, A
    # y1(t) = x(t) → data
    # y1'(t) = -k*x(t) + A*sin(5t) → substitute data and sin(5t)
    # → polynomial in k, A

    println("\n  Template equation: y1'(t) = -k*x(t) + A*sin(5t)")
    println("  At t=$t_val with x=$sin_val (example):")
    println("    y1' = -k*$sin_val + A*$sin_val")
    println("  → This IS polynomial (linear) in k, A!")
catch e
    println("  FAILED: $(typeof(e))")
    println("  $(sprint(showerror, e))")
end

# ---- Test G: Can we numerically evaluate t-only subexpressions in a Symbolics expr? ----
println("\n--- Test G: Numerical evaluation of t-only subexpressions ---")
try
    @parameters k A
    @variables x(t)

    # Expression: k^2 * x + A * sin(5.0*t) - k * cos(3.0*t)
    expr = k^2 * x + A * sin(5.0 * t) - k * cos(3.0 * t)
    println("  Original: $expr")

    # Substitute t = 0.5
    expr_at_t = Symbolics.substitute(expr, Dict(t => 0.5))
    println("  After t=0.5: $expr_at_t")
    # This should evaluate sin(2.5) and cos(1.5) numerically

    # Check if it's now polynomial in k, A, x
    println("  (Is this now a polynomial in k, A, x(0.5)?)")
catch e
    println("  FAILED: $(typeof(e))")
    println("  $(sprint(showerror, e))")
end

println("\n" * "=" ^ 70)
println("TEST 7 COMPLETE")
println("=" ^ 70)
