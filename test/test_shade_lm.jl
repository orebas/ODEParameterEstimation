using Test
using ODEParameterEstimation

# Smoke-level integration tests for the SHADE+LM hybrid baseline
# (`src/baselines/shade_lm.jl`). Uses `simple()` — a 2-state, 2-param model
# with both states observed (`y1 ~ x1, y2 ~ x2`), fully identifiable. Truth:
# `ic = [0.333, 0.667]`, `p = [0.4, 0.8]`.
#
# We pass explicit narrow `opt_lb`/`opt_ub` because the package-default
# `compute_default_bounds` returns `±1e9 * data_scale` — sensible for the
# multishot pipeline (algebraic seeds land near truth) but unreasonable for
# a derivative-free metaheuristic on a smoke budget. Real benchmark use
# (bilby/quokka/wombat) always passes explicit narrow bounds via the
# chevron template, so this matches the production setup.

# 4 unknowns: x1(0), x2(0), a, b — all positive truth, so positive bounds
# force the `:log` per-variable transform via the `:auto` policy.
const _SHADE_TEST_OPT_LB = fill(1e-3, 4)
const _SHADE_TEST_OPT_UB = fill(5.0, 4)

const _SHADE_TIGHT_OPTS = (
	datasize = 21,
	time_interval = [-0.5, 0.5],
	noise_level = 0.0,
	opt_lb = _SHADE_TEST_OPT_LB,
	opt_ub = _SHADE_TEST_OPT_UB,
	shade_total_max_evals = 12_000,
	shade_total_max_time = 60.0,
	shade_n_local_starts = 3,
	shade_seed = UInt(20260506),
)

function _shade_lm_test_problem(; extra_kwargs...)
	pep = simple()
	opts = EstimationOptions(; _SHADE_TIGHT_OPTS..., extra_kwargs...)
	pep_with_data = sample_problem_data(pep, opts)
	return pep_with_data, opts
end

"""
Max relative parameter+state error against truth.
"""
function _shade_lm_relerr(pep::ParameterEstimationProblem, result::ParameterEstimationResult)
	ic_truth = collect(values(pep.ic))
	p_truth = collect(values(pep.p_true))
	ic_est = Float64[result.states[k] for k in keys(pep.ic)]
	p_est = Float64[result.parameters[k] for k in keys(pep.p_true)]
	truth = vcat(Float64.(ic_truth), Float64.(p_truth))
	est = vcat(ic_est, p_est)
	@assert length(est) == length(truth) "result/truth size mismatch ($(length(est)) vs $(length(truth)))"
	return maximum(abs(est[i] - truth[i]) / max(abs(truth[i]), 1e-10) for i in eachindex(truth))
end

@testset "shade_lm_estimate (`simple` model, zero noise)" begin
	@testset "default polish: PolishLSOBoundedLog (:log transforms)" begin
		pep, opts = _shade_lm_test_problem()
		result = shade_lm_estimate(pep; opts = opts)

		@test result isa ParameterEstimationResult
		@test result.provenance.primary_method === :shade_lm
		@test result.provenance.polish_applied
		@test !isnothing(result.err)
		@test isfinite(result.err)
		# At zero noise on a fully-identifiable model with explicit bounds,
		# LM polish should drive trajectory residual near machine precision
		# and parameters within a couple percent.
		@test result.err < 1e-6
		@test _shade_lm_relerr(pep, result) < 0.05
	end

	@testset "alternate polish: PolishFastLMBoundedLog" begin
		pep, base_opts = _shade_lm_test_problem()
		opts = ODEParameterEstimation.merge_options(base_opts;
			polish_method = PolishFastLMBoundedLog)
		result = shade_lm_estimate(pep; opts = opts)

		@test result isa ParameterEstimationResult
		@test result.provenance.primary_method === :shade_lm
		@test isfinite(result.err)
		@test _shade_lm_relerr(pep, result) < 0.10
	end

	@testset "signed bounds (lb<0 box)" begin
		# Override bounds so lb < 0. The box (-2, 5) is a comparable sign-straddle
		# (|lb| not ≥1 OOM smaller than ub), so the :auto rule selects `:linear` per
		# variable — exercises the signed-bounds path. Truth is well-inside, so it succeeds.
		pep_template = simple()
		n = length(pep_template.ic) + length(pep_template.p_true)
		opts = EstimationOptions(;
			datasize = 21,
			time_interval = [-0.5, 0.5],
			noise_level = 0.0,
			opt_lb = fill(-2.0, n),
			opt_ub = fill( 5.0, n),
			shade_total_max_evals = 12_000,
			shade_total_max_time = 60.0,
			shade_n_local_starts = 3,
			shade_seed = UInt(20260507),
		)
		pep = sample_problem_data(pep_template, opts)
		result = shade_lm_estimate(pep; opts = opts)

		@test result isa ParameterEstimationResult
		@test result.provenance.primary_method === :shade_lm
		@test isfinite(result.err)
		@test _shade_lm_relerr(pep, result) < 0.10
	end
end
