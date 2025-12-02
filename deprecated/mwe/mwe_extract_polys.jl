# Extract the exact polynomials that StructuralIdentifiability passes to Groebner
# This will help create a pure Groebner MWE

using StructuralIdentifiability
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using Groebner
using Nemo

println("Extracting polynomials from StructuralIdentifiability")
println("Julia version: $(VERSION)")
println("Threads: $(Threads.nthreads())")
println()

# Monkey-patch Groebner.groebner to capture inputs
original_groebner = Groebner.groebner

call_count = Ref(0)
captured_polys = []

function Groebner.groebner(polys::Vector{T}; kwargs...) where T
    call_count[] += 1
    println("\n=== Groebner.groebner call #$(call_count[]) ===")
    println("Polynomial type: $T")
    println("Number of polynomials: $(length(polys))")
    if !isempty(polys)
        println("Ring: $(parent(first(polys)))")
        println("Variables: $(gens(parent(first(polys))))")
    end
    println("Kwargs: $kwargs")
    println()
    println("Polynomials:")
    for (i, p) in enumerate(polys)
        println("  [$i] $p")
    end
    println()

    # Save for later reproduction
    push!(captured_polys, (call=call_count[], polys=deepcopy(polys), kwargs=Dict(pairs(kwargs))))

    # Call original with threading disabled
    return original_groebner(polys; kwargs..., threaded=false)
end

# Simple ODE system
@parameters a b
@variables x1(t) x2(t) y1(t) y2(t)

eqs = [
    D(x1) ~ -a * x2,
    D(x2) ~ b * x1
]

measured = [y1 ~ x1, y2 ~ x2]

@named sys = ODESystem(eqs, t, [x1, x2], [a, b])

println("ODE System:")
println("  x1' = -a*x2")
println("  x2' = b*x1")
println("  y1 = x1, y2 = x2")
println()

println("Calling assess_identifiability (with threading disabled in Groebner)...")
result = assess_identifiability(sys; measured_quantities=measured)
println("\nResult: $result")

println("\n" * "=" ^ 60)
println("Summary: $(length(captured_polys)) Groebner calls captured")
println("=" ^ 60)

for cap in captured_polys
    println("\nCall #$(cap.call): $(length(cap.polys)) polys, kwargs=$(cap.kwargs)")
    if !isempty(cap.polys)
        println("  Ring vars: $(length(gens(parent(first(cap.polys)))))")
    end
end

# Write the captured polynomials to a file for reproduction
println("\n\nWriting captured polynomials to captured_groebner_inputs.jl...")
open("captured_groebner_inputs.jl", "w") do f
    println(f, "# Captured Groebner inputs from StructuralIdentifiability")
    println(f, "# Run with: julia -t 7 captured_groebner_inputs.jl")
    println(f, "")
    println(f, "using Groebner")
    println(f, "using Nemo")
    println(f, "")
    println(f, "println(\"Testing captured Groebner calls\")")
    println(f, "println(\"Threads: \\$(Threads.nthreads())\")")
    println(f, "println()")
    println(f, "")

    for (i, cap) in enumerate(captured_polys)
        if isempty(cap.polys)
            continue
        end
        ring = parent(first(cap.polys))
        varnames = [string(v) for v in gens(ring)]

        println(f, "# Call #$(cap.call)")
        println(f, "println(\"Test $i: $(length(cap.polys)) polynomials in $(length(varnames)) variables\")")
        println(f, "R$i, vars$i = Nemo.polynomial_ring(Nemo.QQ, $(repr(varnames)))")
        println(f, "$(join(varnames, ", ")) = vars$i")
        println(f, "polys$i = [")
        for p in cap.polys
            println(f, "    $p,")
        end
        println(f, "]")
        println(f, "try")
        println(f, "    gb = Groebner.groebner(polys$i)")
        println(f, "    println(\"  SUCCESS: \\$(length(gb)) basis elements\")")
        println(f, "catch e")
        println(f, "    println(\"  FAILED: \\$(typeof(e))\")")
        println(f, "    if e isa CompositeException")
        println(f, "        for inner in e.exceptions")
        println(f, "            if inner isa TaskFailedException")
        println(f, "                println(\"    Task error: \", inner.task.result)")
        println(f, "            end")
        println(f, "        end")
        println(f, "    end")
        println(f, "end")
        println(f, "println()")
        println(f, "")
    end
    println(f, "println(\"Done\")")
end
println("Done")
