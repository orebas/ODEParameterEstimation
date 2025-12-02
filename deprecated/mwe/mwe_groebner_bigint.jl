# MWE: Groebner.jl threading bug with Rational{BigInt} coefficients
#
# The bug is triggered when using Rational{BigInt} coefficients,
# which is what StructuralIdentifiability uses internally.
#
# Run: julia -t 7 mwe_groebner_bigint.jl
# Works with: julia -t 1 mwe_groebner_bigint.jl

using Groebner
using AbstractAlgebra

println("Groebner.jl threading bug MWE (BigInt rationals)")
println("Julia version: $(VERSION)")
println("Threads: $(Threads.nthreads())")
println("Groebner version: ", pkgversion(Groebner))
println()

# Create polynomial ring with Rational{BigInt} coefficients
# This is what StructuralIdentifiability uses
R, (x1, x2) = AbstractAlgebra.polynomial_ring(AbstractAlgebra.QQ, ["x1", "x2"])

println("Coefficient type: ", typeof(one(AbstractAlgebra.QQ)))
println("Ring: ", R)
println()

# Simple polynomials - same structure as SI's field_contains_algebraic
polys = [
    x1^2 + x2 - 1,
    x1 + x2^2 - 1
]

println("Input polynomials:")
for p in polys
    println("  ", p, " (coeffs: ", typeof(AbstractAlgebra.coefficients(p)), ")")
end
println()

println("Calling Groebner.groebner()...")
try
    gb = Groebner.groebner(polys)
    println("SUCCESS!")
    println("Groebner basis:")
    for p in gb
        println("  ", p)
    end
catch e
    println("FAILED!")
    println("Error: ", typeof(e))
    if e isa CompositeException
        for (i, inner) in enumerate(e.exceptions)
            println("  Inner [$i]: ", typeof(inner))
            if inner isa TaskFailedException
                err = inner.task.result
                println("    ", err)
            end
        end
    end
    println()
    showerror(stdout, e, catch_backtrace())
end

println()
println("Done")
