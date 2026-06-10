# Benchmark-style smoke guard — added 2026-06-10 (maintainability campaign Phase G).
#
# WHY: the fast CI suite (runtests.jl, ~13 min) is canary-scale — small datasize,
# mostly zero noise, mechanics-focused. The 2026-06-10 tire-kick showed it never
# exercises noisy, benchmark-scale end-to-end recovery, which is exactly what the
# benchmark (PEB) stresses. This file is that guard.
#
# DELIBERATELY NOT included in runtests.jl (it adds ~5-10 min of estimation).
# Run on demand, e.g. before handing a build to the cluster:
#
#   julia --startup-file=no -e 'using ODEParameterEstimation; include("test/benchmark_smoke.jl")'
#
# Design notes:
# - Seeded (Julia's default RNG is seeded randomly per session; unseeded
#   estimation tests are coin flips — see the direct-opt canary history, ddb06b4).
# - Metric = BEST-OF-BRANCH max relative parameter error (min over returned
#   clusters), the benchmark's headline metric — NOT first-cluster-by-fit-error,
#   which mis-scores M>1 models whose lead cluster is a sibling branch.
# - Models are IDENTIFIABLE ones: practical non-identifiability (e.g. seir's
#   a↔nu/b ambiguity, fit 1e-14 with wrong params) is a model property no code
#   change can affect, so such models cannot serve as regression guards.
# - Thresholds are LOOSE on purpose (regression tripwires, not quality targets);
#   calibrated 2026-06-10: LV at 1e-8 additive noise recovers ≲1e-3; bound 1e-2.

using Test
using Random

function _smoke_best_of_branch(ctor; datasize, noise, polish)
	pep = ctor()
	opts = EstimationOptions(
		datasize = datasize,
		noise_level = noise,
		nooutput = true,
		diagnostics = false,
		polish_solutions = polish,
		save_system = false,
	)
	Random.seed!(20260610)
	sampled = ODEParameterEstimation.sample_problem_data(pep, opts)
	_, analysis, _ = ODEParameterEstimation.analyze_parameter_estimation_problem(sampled, opts)
	isempty(analysis[1]) && return (Inf, 0, analysis[2])
	bob = minimum(
		maximum(abs(get(c.parameters, p, NaN) - tv) / max(abs(tv), 1e-12) for (p, tv) in sampled.p_true)
		for c in analysis[1]
	)
	return (bob, length(analysis[1]), analysis[2])
end

@testset "Benchmark smoke (seeded, noisy, full-scale)" begin
	@testset "lotka_volterra @ 1e-8 noise, polish on" begin
		bob, nclusters, besterror = _smoke_best_of_branch(
			ODEParameterEstimation.lotka_volterra; datasize = 201, noise = 1e-8, polish = true)
		@test isfinite(besterror)
		@test nclusters >= 1
		@test bob < 1e-2
	end

	@testset "simple @ 1e-8 noise, polish on" begin
		bob, nclusters, besterror = _smoke_best_of_branch(
			ODEParameterEstimation.simple; datasize = 201, noise = 1e-8, polish = true)
		@test isfinite(besterror)
		@test nclusters >= 1
		@test bob < 1e-2
	end

	@testset "lotka_volterra clean is machine precision (sanity anchor)" begin
		bob, _, _ = _smoke_best_of_branch(
			ODEParameterEstimation.lotka_volterra; datasize = 201, noise = 0.0, polish = false)
		@test bob < 1e-6
	end
end
