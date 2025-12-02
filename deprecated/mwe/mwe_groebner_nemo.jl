# MWE: Groebner.jl threading bug with Nemo QQMPolyRingElem
#
# Isolated from StructuralIdentifiability.check_primality_zerodim
# The bug is triggered when calling groebner() on Nemo QQ polynomials with threading
#
# Run: julia -t 7 mwe_groebner_nemo.jl
# Works with: julia -t 1 mwe_groebner_nemo.jl
#
# Bug: BoundsError - with 7 threads, tries to access index [8] in 7-element Vector
# Location: Groebner._groebner_learn_and_apply_threaded (groebner.jl:450)

using Groebner
using Nemo

println("=" ^ 60)
println("Groebner.jl threading bug MWE (Nemo QQ polynomials)")
println("=" ^ 60)
println("Julia version: $(VERSION)")
println("Threads: $(Threads.nthreads())")
println("Groebner version: ", pkgversion(Groebner))
println()

# Create Nemo QQ polynomial ring (same as StructuralIdentifiability uses)
R, vars = Nemo.polynomial_ring(Nemo.QQ, ["x1", "x2", "x3", "x4"])
x1, x2, x3, x4 = vars

println("Ring type: ", typeof(R))
println("Polynomial type: ", typeof(x1))
println()

# Test 1: Simple 2-variable system
println("-" ^ 60)
println("Test 1: Simple 2-variable system")
println("-" ^ 60)
R1, (y1, y2) = Nemo.polynomial_ring(Nemo.QQ, ["y1", "y2"])
polys1 = [y1^2 + y2 - 1, y1 + y2^2 - 1]
println("Polynomials: $polys1")
try
    gb = Groebner.groebner(polys1)
    println("SUCCESS: $(length(gb)) basis elements")
catch e
    println("FAILED: ", typeof(e))
    if e isa CompositeException
        for inner in e.exceptions
            if inner isa TaskFailedException
                println("  Task error: ", inner.task.result)
            end
        end
    end
end
println()

# Test 2: 4-variable system (closer to what SI generates)
println("-" ^ 60)
println("Test 2: 4-variable system (like SI's primality check)")
println("-" ^ 60)
polys2 = [
    x1*x2 - x3*x4,
    x1^2 - x2,
    x3^2 - x4,
    x1 + x2 + x3 + x4 - 1
]
println("Polynomials: $(length(polys2)) polys in 4 vars")
try
    gb = Groebner.groebner(polys2)
    println("SUCCESS: $(length(gb)) basis elements")
catch e
    println("FAILED: ", typeof(e))
    if e isa CompositeException
        for inner in e.exceptions
            if inner isa TaskFailedException
                println("  Task error: ", inner.task.result)
            end
        end
    end
end
println()

# Test 3: Multiple groebner calls (SI does this repeatedly)
println("-" ^ 60)
println("Test 3: Multiple groebner calls in sequence")
println("-" ^ 60)
for i in 1:10
    R_temp, (a, b) = Nemo.polynomial_ring(Nemo.QQ, ["a", "b"])
    polys_temp = [a^2 + b*i - 1, a + b^2 - i]
    try
        gb = Groebner.groebner(polys_temp)
        print(".")
    catch e
        println("\nFailed at iteration $i")
        if e isa CompositeException
            for inner in e.exceptions
                if inner isa TaskFailedException
                    println("  Task error: ", inner.task.result)
                end
            end
        end
        break
    end
end
println(" Done")
println()

# Test 4: With Lex ordering explicitly (SI uses Lex)
println("-" ^ 60)
println("Test 4: With explicit Lex ordering")
println("-" ^ 60)
R4, vars4 = Nemo.polynomial_ring(Nemo.QQ, ["z1", "z2", "z3", "z4"])
z1, z2, z3, z4 = vars4
polys4 = [
    z1*z2 - z3,
    z2*z3 - z4,
    z1^2 - 1,
    z4^2 - z2
]
println("Polynomials: $(length(polys4)) polys in 4 vars")
try
    gb = Groebner.groebner(polys4, ordering=Groebner.Lex())
    println("SUCCESS: $(length(gb)) basis elements")
catch e
    println("FAILED: ", typeof(e))
    if e isa CompositeException
        for inner in e.exceptions
            if inner isa TaskFailedException
                println("  Task error: ", inner.task.result)
            end
        end
    end
end
println()

# Test 5: Larger system (8 polynomials)
println("-" ^ 60)
println("Test 5: Larger system (8 polynomials in 6 vars)")
println("-" ^ 60)
R5, vars5 = Nemo.polynomial_ring(Nemo.QQ, ["v$i" for i in 1:6])
v = vars5
polys5 = [
    v[1]^2 + v[2] - 1,
    v[2]^2 + v[3] - 1,
    v[3]^2 + v[4] - 1,
    v[4]^2 + v[1] - 1,
    v[1]*v[3] - v[2]*v[4],
    v[5]^2 - v[1],
    v[6]^2 - v[2],
    v[5]*v[6] - v[3]
]
println("Polynomials: $(length(polys5)) polys in 6 vars")
try
    gb = Groebner.groebner(polys5)
    println("SUCCESS: $(length(gb)) basis elements")
catch e
    println("FAILED: ", typeof(e))
    if e isa CompositeException
        for inner in e.exceptions
            if inner isa TaskFailedException
                println("  Task error: ", inner.task.result)
            end
        end
    end
end
println()

println("=" ^ 60)
println("All tests complete")
println("=" ^ 60)
