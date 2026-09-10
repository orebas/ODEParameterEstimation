using ODEParameterEstimation
using Test
using Logging
using Random

@testset "Autonomous identifiability on supported dependencies" begin
    si = ODEParameterEstimation.StructuralIdentifiability
    nemo = ODEParameterEstimation.Nemo
    ring, (x, a, y) = nemo.polynomial_ring(nemo.QQ, ["x", "a", "y"])
    P = typeof(x)
    ode = si.ODE{P}(Dict(x => -a * x), Dict(y => x), P[])

    # Independent analytic reference: x(t) = 3 exp(-2t). The public integer
    # input method also exercises its conversion to rational field elements.
    series = si.power_series_solution(
        ode, Dict(a => 2), Dict(x => 3), Dict{P,Vector{Int}}(), 6,
    )
    for order in 0:5
        expected = nemo.QQ(3 * (-2)^order) / factorial(order)
        @test nemo.coeff(series[x], order) == expected
        @test nemo.coeff(series[y], order) == expected
    end

    # This reaches the upstream Wronskian path that failed on Julia 1.13 when
    # its empty input comprehension inferred Dict{Any,Any}.
    Random.seed!(913)
    identified = with_logger(NullLogger()) do
        si.assess_identifiability(ode)
    end
    @test length(identified) == 2
    @test all(==(:globally), values(identified))

    # Malformed input data must never be discarded by the compatibility bridge.
    @test_throws Union{ArgumentError,MethodError} si.power_series_solution(
        ode, Dict(a => 2), Dict(x => 3), Dict{Any,Any}(:invalid => [1]), 6,
    )
end
