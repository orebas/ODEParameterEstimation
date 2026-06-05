# Pure-Groebner MWE for the non-termination reported in README.md.
#
# Usage:  julia --startup-file=no mwe.jl /tmp/gb_capture_<n>polys.jls
#
# The .jls file is the exact `Vector{QQMPolyRingElem}` that StructuralIdentifiability's
# check_primality_zerodim passes to Groebner.groebner — a (near-)positive-dimensional ideal
# over QQ with large rational coefficients. groebner() does not terminate on Groebner v0.10.3.
using Groebner, Serialization, Nemo

length(ARGS) >= 1 || error("usage: julia mwe.jl <path-to-gb_capture_*.jls>")
J = deserialize(ARGS[1])
println("loaded ", length(J), " polynomials")
println("ring: ", parent(first(J)))
println("variables: ", gens(parent(first(J))))
println("max total degree: ", maximum(total_degree, J))
flush(stdout)

println("calling Groebner.groebner(J) — expect this to hang (no termination)...")
@time gb = Groebner.groebner(J)
println("returned a ", length(gb), "-element basis (NOT expected to reach here)")
