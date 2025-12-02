# MWE: Groebner.jl threading bug
#
# Bug: BoundsError in _groebner_learn_and_apply_threaded
# With JULIA_NUM_THREADS=7, tries to access index [8] of 7-element Vector
#
# Run with: julia -t auto mwe_groebner_threading.jl
# Workaround: julia -t 1 mwe_groebner_threading.jl

using Groebner
using Nemo
using AbstractAlgebra

println("Groebner.jl threading bug MWE")
println("Julia version: $(VERSION)")
println("Threads: $(Threads.nthreads())")
println("Groebner version: ", pkgversion(Groebner))
println()

# Test 1: Simple Nemo polynomials
println("=" ^ 50)
println("Test 1: Simple Nemo QQ polynomials")
println("=" ^ 50)
R, (x1, x2) = Nemo.polynomial_ring(Nemo.QQ, ["x1", "x2"])
polys1 = [x1^2 + x2 - 1, x1 + x2^2 - 1]
println("Polynomials: ", polys1)
try
    gb = Groebner.groebner(polys1)
    println("SUCCESS")
catch e
    println("FAILED: ", e)
end
println()

# Test 2: More variables (like the actual failing case)
println("=" ^ 50)
println("Test 2: 4 variables (like identifiability problem)")
println("=" ^ 50)
R2, vars = Nemo.polynomial_ring(Nemo.QQ, ["a", "b", "x1", "x2"])
a, b, x1, x2 = vars
# Polynomials similar to what StructuralIdentifiability generates
polys2 = [
    a*x1 - b*x2,
    a^2 - 1,
    b^2 - a,
    x1*x2 - a*b
]
println("Polynomials: ", length(polys2), " polys in 4 vars")
try
    gb = Groebner.groebner(polys2)
    println("SUCCESS: ", length(gb), " basis elements")
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

# Test 3: Larger system
println("=" ^ 50)
println("Test 3: Larger polynomial system (8 polys)")
println("=" ^ 50)
R3, vars3 = Nemo.polynomial_ring(Nemo.QQ, ["x$i" for i in 1:6])
x = vars3
polys3 = [
    x[1]^2 + x[2] - 1,
    x[2]^2 + x[3] - 1,
    x[3]^2 + x[4] - 1,
    x[4]^2 + x[1] - 1,
    x[1]*x[3] - x[2]*x[4],
    x[5]^2 - x[1],
    x[6]^2 - x[2],
    x[5]*x[6] - x[3]
]
println("Polynomials: ", length(polys3), " polys in 6 vars")
try
    gb = Groebner.groebner(polys3)
    println("SUCCESS: ", length(gb), " basis elements")
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

# Test 4: Call groebner multiple times in succession (like SI does)
println("=" ^ 50)
println("Test 4: Multiple groebner calls in succession")
println("=" ^ 50)
for i in 1:5
    R4, (y1, y2) = Nemo.polynomial_ring(Nemo.QQ, ["y1", "y2"])
    polys4 = [y1^i + y2 - 1, y1 + y2^i - 1]
    try
        gb = Groebner.groebner(polys4)
        println("  Call $i: SUCCESS")
    catch e
        println("  Call $i: FAILED - ", typeof(e))
        if e isa CompositeException
            for inner in e.exceptions
                if inner isa TaskFailedException
                    println("    Task error: ", inner.task.result)
                end
            end
        end
    end
end
println()

println("=" ^ 50)
println("All tests complete")
println("=" ^ 50)
