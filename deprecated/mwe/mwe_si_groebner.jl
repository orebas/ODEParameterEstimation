# MWE: StructuralIdentifiability.jl triggering Groebner.jl threading bug
#
# This isolates the bug to StructuralIdentifiability's usage of Groebner
# The bug occurs in field_contains_algebraic -> groebner call
#
# Run: julia -t 7 mwe_si_groebner.jl

using StructuralIdentifiability
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

println("StructuralIdentifiability + Groebner threading bug MWE")
println("Julia version: $(VERSION)")
println("Threads: $(Threads.nthreads())")
println()

# Define a simple ODE system (same as 'simple' model that triggers the bug)
@parameters a b
@variables x1(t) x2(t) y1(t) y2(t)

eqs = [
    D(x1) ~ -a * x2,
    D(x2) ~ b * x1
]

measured = [y1 ~ x1, y2 ~ x2]

@named sys = ODESystem(eqs, t, [x1, x2], [a, b])

println("ODE System defined")
println("States: x1, x2")
println("Parameters: a, b")
println("Measured: y1 = x1, y2 = x2")
println()

println("Calling assess_identifiability (this triggers the Groebner bug)...")
result = assess_identifiability(sys; measured_quantities=measured)
println("SUCCESS!")
println("Result: ", result)


try
catch e
    println("FAILED!")
    println("Error type: $(typeof(e))")
    if e isa CompositeException
        println("Inner exceptions:")
        for (i, inner) in enumerate(e.exceptions)
            println("  [$i] $(typeof(inner))")
            if inner isa TaskFailedException
                err = inner.task.result
                println("      Error: ", typeof(err))
                if err isa BoundsError
                    println("      BoundsError: ", err)
                end
            end
        end
    end
    println()
    println("Full stacktrace:")
    showerror(stdout, e, catch_backtrace())
end

println()
println("MWE complete")
