using ODEParameterEstimation
using Test

@testset "ODEParameterEstimation fast suite" begin
    include("fast_core.jl")
    include("example_canaries.jl")
    include("examples_smoke.jl")
    include("identifiability_regressions.jl")
    include("result_processing_helpers.jl")
    include("feature_regressions.jl")
end
