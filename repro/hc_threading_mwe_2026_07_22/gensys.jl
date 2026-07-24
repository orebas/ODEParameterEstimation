# Dense random polynomial system generator (pure HC.jl).
using HomotopyContinuation
const HC = HomotopyContinuation
using Random

# Build a dense square system: n polynomials in n variables, each a dense
# combination of all monomials up to total degree d, with random real coeffs.
function dense_system(n::Int, d::Int, seed::Int)
    rng = MersenneTwister(seed)
    HC.@var x[1:n]
    # all exponent tuples with total degree <= d
    monos = HC.Expression[]
    function rec(prefix, remaining, k)
        if k == n
            push!(monos, prod(x[i]^prefix[i] for i in 1:n))
            return
        end
        for e in 0:remaining
            rec(vcat(prefix, e), remaining - e, k+1)
        end
    end
    rec(Int[], d, 0)
    polys = HC.Expression[]
    for _ in 1:n
        push!(polys, sum(randn(rng) * m for m in monos))
    end
    return HC.System(polys, variables = collect(x))
end
