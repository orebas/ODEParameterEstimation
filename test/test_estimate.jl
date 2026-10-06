# estimate (2026-10-06): the short path from a ModelingToolkit system and
# measured data to ranked results.

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrdinaryDiffEq
using Test

const _ESTIMATE_QUICK_OPTS = (;
	datasize = 31, interpolators = [InterpolatorAAAD], use_parameter_homotopy = false, polish_solutions = false,
)

@testset "Estimating from measured data" begin
	@parameters a b
	@variables x1(t) x2(t) y1(t) y2(t)
	@named oscillator = System([D(x1) ~ -a * x2, D(x2) ~ b * x1], t)
	measured = [y1 ~ x1, y2 ~ x2]

	# Measurements made outside the package: a separate solve of the same equations.
	truth = (a = 0.4, b = 0.8, x1 = 1.0, x2 = 0.5)
	times = collect(range(0.0, 2.0; length = 41))
	reference = solve(
		ODEProblem((u, p, _) -> [-p[1] * u[2], p[2] * u[1]], [truth.x1, truth.x2], (0.0, 2.0), [truth.a, truth.b]),
		Vern9(); saveat = times, abstol = 1e-12, reltol = 1e-12,
	)
	problem = ParameterEstimationProblem(oscillator, measured; data = (t = times, y1 = reference[1, :], y2 = reference[2, :]))

	# Default options, true values withheld.
	results = estimate(problem)
	@test results isa Vector{ParameterEstimationResult}
	@test length(results) == 1
	best = first(results)
	@test best[a] ≈ truth.a rtol = 1e-6
	@test best[b] ≈ truth.b rtol = 1e-6
	@test best[x1] ≈ truth.x1 rtol = 1e-6
	@test best[x2] ≈ truth.x2 rtol = 1e-6
	@test best.report_time == 0.0
	@test best.err < 1e-10
	@test isempty(best.all_unidentifiable)
	@test startswith(sprint(show, MIME"text/plain"(), best), "ParameterEstimationResult\n  Parameters\n    a = 0.4\n    b = 0.8\n")

	# The keyword form and the options form give the results that
	# analyze_parameter_estimation_problem ranks.
	options = EstimationOptions(; _ESTIMATE_QUICK_OPTS..., seed = 3)
	_, analysis, uq = analyze_parameter_estimation_problem(problem, options)
	fingerprint(found) = [(collect(values(result.parameters)), collect(values(result.states)), result.err) for result in found]
	@test uq === nothing
	@test analysis.best_max_error == Inf   # nothing to compare with
	@test fingerprint(estimate(problem, options)) == fingerprint(analysis.returned_results)
	@test fingerprint(estimate(problem; _ESTIMATE_QUICK_OPTS..., seed = 3)) == fingerprint(analysis.returned_results)
	@test issorted(analysis.returned_results; by = result -> result.err)
end

@testset "Simulating data from the values a system carries" begin
	@parameters a = 0.4 b = 0.8
	@variables x1(t) = 1.0 x2(t) = 0.5 y1(t) y2(t)
	@named oscillator = System([D(x1) ~ -a * x2, D(x2) ~ b * x1], t)
	problem = ParameterEstimationProblem(oscillator, [y1 ~ x1, y2 ~ x2])

	options = EstimationOptions(; _ESTIMATE_QUICK_OPTS..., time_interval = [0.0, 2.0])
	simulated = sample_problem_data(problem, options)
	by_keyword = sample_problem_data(problem; datasize = 31, time_interval = [0, 2])
	@test collect(values(by_keyword.data_sample)) == collect(values(simulated.data_sample))
	@test length(sample_problem_data(problem).data_sample["t"]) == EstimationOptions().datasize
	@test simulated.name == "oscillator"
	@test simulated.data_sample["t"] ≈ range(0.0, 2.0; length = 31)
	@test first(simulated.data_sample[Num(x1)]) ≈ 1.0
	@test first(simulated.data_sample[Num(x2)]) ≈ 0.5

	_, analysis, _ = analyze_parameter_estimation_problem(simulated, options)
	@test analysis.best_max_error < 1e-6
	best = first(estimate(simulated, options))
	@test best[a] ≈ 0.4 rtol = 1e-6
	@test best[x2] ≈ 0.5 rtol = 1e-6
end
