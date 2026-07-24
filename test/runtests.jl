using ODEParameterEstimation
using Test

@testset "ODEParameterEstimation fast suite" begin
    include("fast_core.jl")
    include("refactor_safety_net.jl")
    include("test_label_parsers.jl")
    include("example_canaries.jl")
    include("examples_smoke.jl")
    include("identifiability_regressions.jl")
    include("result_processing_helpers.jl")
    include("feature_regressions.jl")
    include("test_shade_lm.jl")
    include("test_rescaling.jl")
    include("test_core_types.jl")     # re-homed 2026-07-21 (was orphaned + red; now green)
    include("column_scaling.jl")      # re-homed 2026-07-21 (was orphaned; green)
    include("test_interrupt_propagation.jl")  # Ctrl-C class fix 2026-07-24 (_rethrow_if_interrupt)
end
