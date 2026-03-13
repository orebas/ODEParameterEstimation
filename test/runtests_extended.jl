using ODEParameterEstimation
using Test

@testset "ODEParameterEstimation extended suite" begin
    include("runtests.jl")
    include("extended_regressions.jl")
    include("examples_extended_smoke.jl")
end
