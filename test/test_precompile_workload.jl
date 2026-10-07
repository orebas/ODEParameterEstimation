# The estimation the package runs while it is precompiled (2026-10-06). It is a
# default run like any other: quiet and accurate, and it leaves the caller's
# random stream alone. A freshly loaded package carries nothing over from it.

using ODEParameterEstimation
using Logging
using Random
using Test

include(joinpath(@__DIR__, "support", "observe_run.jl"))

const _ODEPE = ODEParameterEstimation

@testset "The precompile workload is an ordinary default run" begin
	rng = Random.default_rng()
	Random.seed!(rng, 53)
	# The comparison is made inside the observed run: making a temporary
	# directory, as `_observe_run` does, moves the random stream by itself.
	run = _observe_run() do
		before = copy(rng)
		results = _ODEPE._precompile_workload()
		(; results, rng_untouched = copy(rng) == before)
	end
	@test run.value.rng_untouched
	@test isempty(run.printed)
	@test isempty(run.logs)
	@test isempty(run.files)

	result = only(run.value.results)
	for (name, truth) in ("k1" => 0.6, "k2" => 0.3, "k3" => 0.8, "k4" => 0.2, "x1" => 1.0, "x2" => 0.5)
		@test isapprox(result[name], truth; rtol = 1e-6)
	end
end

@testset "Session state can be cleared" begin
	# The run above left its reuse bundle behind, as every estimation does.
	@test !isnothing(_ODEPE._LAST_ESTIMATION_REUSE[])
	_ODEPE._reset_session_state!()
	@test isnothing(_ODEPE._LAST_ESTIMATION_REUSE[])
	@test isnothing(_ODEPE._LAST_BRANCH_COMPLETION_DEBUG[])
	@test isempty(_ODEPE._NOISE_VALIDATION_CACHE)
end

@testset "A freshly loaded package carries nothing over from precompilation" begin
	# Earlier test files have run estimations in this process, so ask a new one.
	script = """
		using ODEParameterEstimation
		const O = ODEParameterEstimation
		print(O._WORKLOAD_STATUS[], " ", isnothing(O._LAST_ESTIMATION_REUSE[]), " ",
			isnothing(O._LAST_BRANCH_COMPLETION_DEBUG[]), " ", length(O._NOISE_VALIDATION_CACHE))
		"""
	command = `$(Base.julia_cmd()) --startup-file=no --project=$(Base.active_project()) -e $script`
	# `skipped` is what a developer who turned the workload off sees.
	@test read(command, String) in ("ok true true 0", "skipped true true 0")
end
