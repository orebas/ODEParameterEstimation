using ODEParameterEstimation
using Test

@testset "Exported bindings are defined" begin
    undefined = filter(name -> !isdefined(ODEParameterEstimation, name),
                       names(ODEParameterEstimation))
    @test isempty(undefined)
end
