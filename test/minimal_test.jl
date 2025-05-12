using ODEParameterEstimation
using Test

@testset "Minimal Test" begin
    @test 1 == 1
    @test ODEParameterEstimation.clear_denoms isa Function
end