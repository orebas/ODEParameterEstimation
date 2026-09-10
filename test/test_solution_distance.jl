using ODEParameterEstimation
using Test
using OrderedCollections
using Symbolics

@testset "Solution distance matches variable identities" begin
    @variables x y a b c
    result(states, parameters) = ParameterEstimationResult(
        parameters, states, 0.0, 0.0, nothing, 0, nothing, nothing,
        Set{Num}(), nothing,
    )
    first_result = result(OrderedDict(x => 1.0, y => 4.0), OrderedDict(a => 2.0, b => 8.0))
    reordered = result(OrderedDict(y => 4.0, x => 1.0), OrderedDict(b => 8.0, a => 2.0))
    @test ODEParameterEstimation.solution_distance(first_result, reordered) == 0.0
    @test ODEParameterEstimation.solution_distance(reordered, first_result) == 0.0
    @test length(ODEParameterEstimation.cluster_solutions([first_result, reordered])) == 1

    changed = result(reordered.states, OrderedDict(b => 10.0, a => 2.0))
    @test ODEParameterEstimation.solution_distance(first_result, changed) ≈ 2 / 18
    @test ODEParameterEstimation.solution_distance(changed, first_result) ≈ 2 / 18
    @test length(ODEParameterEstimation.cluster_solutions([first_result, changed])) == 2

    for incompatible in (
        result(first_result.states, OrderedDict(a => 2.0, c => 8.0)),
        result(first_result.states, OrderedDict(a => 2.0)),
        result(OrderedDict(x => 1.0), first_result.parameters),
    )
        @test isinf(ODEParameterEstimation.solution_distance(first_result, incompatible))
        @test isinf(ODEParameterEstimation.solution_distance(incompatible, first_result))
    end
end
