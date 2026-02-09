# Test 3: Directly test eval_at_nemo with transcendental expressions
# This is the exact function that fails in the pipeline.

using StructuralIdentifiability
using Symbolics
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using Nemo

println("=" ^ 70)
println("TEST 3: eval_at_nemo with various expression types")
println("=" ^ 70)

# First, let's understand what eval_at_nemo expects
# It converts Symbolics expressions to Nemo polynomial ring elements

# Set up a simple Nemo polynomial ring
println("\n--- Setting up Nemo ring ---")
try
    # Create variables in Symbolics
    @parameters k A
    @variables x(t)

    # Create a Nemo polynomial ring with matching variables
    R, nemo_vars = Nemo.polynomial_ring(Nemo.QQ, ["k", "A", "x"])
    nemo_k, nemo_A, nemo_x = nemo_vars

    # Build substitution dictionary (Symbolics symbol => Nemo variable)
    subs_dict = Dict(
        Symbolics.value(k) => nemo_k,
        Symbolics.value(A) => nemo_A,
        Symbolics.value(x) => nemo_x,
    )

    # Test A: Simple polynomial
    println("\n--- Test A: Polynomial expression k*x + A ---")
    expr_a = Symbolics.value(k * x + A)
    try
        result = StructuralIdentifiability.eval_at_nemo(expr_a, subs_dict)
        println("  SUCCESS: $result (type: $(typeof(result)))")
    catch e
        println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
    end

    # Test B: Expression with sin
    println("\n--- Test B: Expression with sin(k) ---")
    expr_b = Symbolics.value(sin(k))
    try
        result = StructuralIdentifiability.eval_at_nemo(expr_b, subs_dict)
        println("  SUCCESS: $result")
    catch e
        println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
    end

    # Test C: Expression with sin(5.0*t)
    println("\n--- Test C: Expression with sin(5.0*t) ---")
    # Note: t is the independent variable, may not be in the ring
    expr_c = Symbolics.value(sin(5.0 * t))
    try
        result = StructuralIdentifiability.eval_at_nemo(expr_c, subs_dict)
        println("  SUCCESS: $result")
    catch e
        println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
    end

    # Test D: Expression with a numeric constant (what if sin is pre-evaluated?)
    println("\n--- Test D: Numeric constant 0.958924 (= sin(5.0*1.0)) ---")
    expr_d = Symbolics.value(k * 0.958924 + A)
    try
        result = StructuralIdentifiability.eval_at_nemo(expr_d, subs_dict)
        println("  SUCCESS: $result")
    catch e
        println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
    end

    # Test E: Expression with integer power (should work)
    println("\n--- Test E: k^2 * x ---")
    expr_e = Symbolics.value(k^2 * x)
    try
        result = StructuralIdentifiability.eval_at_nemo(expr_e, subs_dict)
        println("  SUCCESS: $result")
    catch e
        println("  FAILED: $(typeof(e)) - $(sprint(showerror, e))")
    end

catch e
    println("Setup FAILED: $(typeof(e)) - $(sprint(showerror, e))")
    println(sprint(showerror, e, catch_backtrace()))
end

println("\n" * "=" ^ 70)
println("TEST 3 COMPLETE")
println("=" ^ 70)
