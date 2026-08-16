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
    include("test_run_context.jl")            # scoped RunContext contracts 2026-07-24
    include("test_gp_kernel_optimization.jl") # recovered 2026-08-12 (gitignore-trap survivor, Feb 2026)
    include("test_cross_observable_covariance.jl")  # recovered 2026-08-12 (joint-GP covariance, Mar 2026)
    include("test_polish_maxtime.jl")         # recovered 2026-08-12 (polish_maxtime enforcement, May 2026)
    include("test_hc_sanitize.jl")            # HC name injectivity + cross-list dedup 2026-08-12
    include("test_options_contracts.jl")      # dead-options cleanup contracts 2026-08-12
    include("test_taylor_propagation.jl")     # estimate-conditioned Taylor cores 2026-08-13
    include("test_estimate_conditioned_uq.jl") # estimate-conditioned S = default UQ path 2026-08-13
    include("test_uq_coverage_smoke.jl")      # N=20 two_exp coverage tripwires (repro/ harness) 2026-08-13
    include("test_exact_index_matching.jl")   # per-point index lists + exact obs-name match 2026-08-13
    include("test_stacked_jet_covariance.jl") # cross-time W-stack Σ_d core (MC-validated) 2026-08-13
    include("test_ift_solve.jl")              # factorized IFT, loud degradation 2026-08-13
    include("test_multipoint_sensitivity.jl") # multipoint estimate-conditioned S + FD validation 2026-08-14
    include("test_estimator_aware_uq.jl") # exact rank-one target + typed outcome/lineage contract 2026-08-14
    include("test_gp_factorization_consistency.jl") # one SE recipe + scale-relative jitter telemetry 2026-08-15
end
