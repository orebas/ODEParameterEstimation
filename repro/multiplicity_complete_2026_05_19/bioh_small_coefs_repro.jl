### Diagnostic: does Groebner.jl crash because coefficients are 355-digit
### monsters from SIAN's D2-based sampling, or is it a structural issue
### with the monomial/variable layout?
###
### Take bioh's polynomial monomial structure but replace each coefficient
### with a small random integer (∈ [-100, 100]). If Groebner now succeeds,
### the crash is coefficient-size-triggered. If it still crashes, the bug
### is structural.

using Nemo
using Groebner
using Random
Random.seed!(0)

# Build the same ring as bioh_gb_input.jl
R, _gens = Nemo.polynomial_ring(Nemo.QQ, [
    "x5_6", "x4_5", "x6_5", "x5_5", "x4_4", "x6_4", "x5_4", "x4_3", "x6_3", "x5_3",
    "x4_2", "x6_2", "x5_2", "x4_1", "x6_1", "x5_1", "x4_0", "x6_0", "x5_0",
    "z_aux", "x7_0", "k7_0", "k8_0", "k5_0", "k6_0", "k10_0", "k9_0"
], internal_ordering=:degrevlex)
for (i, name) in enumerate(["x5_6", "x4_5", "x6_5", "x5_5", "x4_4", "x6_4", "x5_4", "x4_3", "x6_3", "x5_3", "x4_2", "x6_2", "x5_2", "x4_1", "x6_1", "x5_1", "x4_0", "x6_0", "x5_0", "z_aux", "x7_0", "k7_0", "k8_0", "k5_0", "k6_0", "k10_0", "k9_0"])
    @eval $(Symbol(name)) = _gens[$i]
end

# Load the actual bioh polys (but don't run groebner at the bottom).
# We extract them by `include`-ing a stripped version.
include_path = joinpath(@__DIR__, "bioh_gb_input.jl")
# Read source, drop the last 4 lines (versions print + groebner call)
source = readlines(include_path)
# Keep lines until we hit the println/groebner block
keep_lines = String[]
for line in source
    if startswith(strip(line), "println") || startswith(strip(line), "gb =")
        break
    end
    push!(keep_lines, line)
end
Base.include_string(@__MODULE__, join(keep_lines, "\n"))

println("Loaded original polys: ", length(polys), " in ", length(_gens), " variables")

# Helper: print coefficient magnitude distribution
function coef_magnitudes(ps)
    magnitudes = Int[]
    for p in ps
        for c in coefficients(p)
            n = abs(numerator(c))
            push!(magnitudes, length(string(n)))
        end
    end
    return magnitudes
end

mags_orig = coef_magnitudes(polys)
println("Original coefficient digit counts:")
println("  min  = ", minimum(mags_orig))
println("  max  = ", maximum(mags_orig))
println("  median = ", sort(mags_orig)[length(mags_orig) ÷ 2 + 1])

# Build new polys with small random coefficients, same monomials
function rebuild_with_small_coefs(p)
    ctx = Nemo.MPolyBuildCtx(parent(p))
    for (c, expvec) in zip(coefficients(p), exponent_vectors(p))
        # Random nonzero integer in [-100, 100]
        new_c = rand(-100:100)
        while new_c == 0
            new_c = rand(-100:100)
        end
        Nemo.push_term!(ctx, Nemo.QQ(new_c), expvec)
    end
    return Nemo.finish(ctx)
end

polys_small = [rebuild_with_small_coefs(p) for p in polys]
mags_small = coef_magnitudes(polys_small)
println("\nNew (small) coefficient digit counts:")
println("  min  = ", minimum(mags_small))
println("  max  = ", maximum(mags_small))

println("\nCalling Groebner.groebner on small-coef version...")
gb_small = try
    g = Groebner.groebner(polys_small)
    println("  ✓ SUCCEEDED: gb has $(length(g)) elements")
    println("    → coefficient magnitude was the trigger")
    g
catch err
    println("  ✗ STILL CRASHES on small coefs:")
    if err isa TaskFailedException
        println("    Inner: ", typeof(err.task.exception), ": ", err.task.exception)
    else
        println("    ", typeof(err), ": ", err)
    end
    println("    → bug is structural (monomial layout), not coefficient size")
    nothing
end
