# test/fast_unit.jl
#
# Fast, quiet unit gate. Pure/near-pure CONTRACT tests only — no
# `analyze_parameter_estimation_problem`, no SIAN / HomotopyContinuation / ODE
# solves, no consensus or benchmark rendering. Runs in a few seconds after the
# package loads. Use this for rapid iteration while refactoring.
#
# This is NOT a substitute for the full FAST gate. Per CLAUDE.md, any
# estimation-touching change must still be verified with:
#     julia --startup-file=no -e 'include("test/runtests.jl")'
#
# Composition: standalone unit-test files verified green on 2026-07-21. Files
# excluded on purpose because they were red that day: test_math_utils.jl
# (calculate_timeseries_stats), test_derivative_utils.jl (Differential API drift).
#
#     julia --startup-file=no -e 'using ODEParameterEstimation; include("test/fast_unit.jl")'

using ODEParameterEstimation
using Test

@testset "fast_unit (quiet contract gate)" begin
	include("test_core_types.jl")        # Result/PEP/DerivativeData type contracts + constants
	include("column_scaling.jl")         # compute_column_scales / scale_hc_system / order_mag
	include("test_model_utils.jl")       # ordered model construction helpers
	include("test_label_parsers.jl")     # SIAN/Symbolics derivative-name parsing (name round-tripping)
	include("test_run_context.jl")       # scoped RunContext contracts (auto-M hand-off, sinks, isolation)
	include("test_hc_sanitize.jl")       # HC name injectivity + cross-list dedup (silent-collision class)
end
