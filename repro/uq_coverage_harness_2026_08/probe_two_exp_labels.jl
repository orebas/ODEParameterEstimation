# Is two_exp's apparent miscalibration a LABEL-SWITCHING artifact?
# y = x1 + x2 is invariant under (x1,k1) <-> (x2,k2), so the algebraic solver
# may legitimately return the swapped root; comparing by NAME then yields huge
# |z| even though the fit is perfect. Print estimate vs truth per replicate.

using ODEParameterEstimation
using Statistics
using Random
using Logging
include(joinpath(@__DIR__, "coverage_driver.jl"))

opts = EstimationOptions(
	datasize = 121, time_interval = [0.0, 1.0], noise_level = 0.01,
	nooutput = true, diagnostics = false, compute_uncertainty = true,
	interpolator = InterpolatorAGPUQ, interpolators = InterpolatorMethod[],
	polish_solutions = false, polish_solver_solutions = false,
	use_multipoint = false, shooting_points = 0)

println("truth: k1=0.6 k2=3.0 x1(0)=2.0 x2(0)=1.5   (y = x1 + x2)")
println(rpad("rep", 5), rpad("k1_hat", 12), rpad("k2_hat", 12), rpad("x1_hat", 12),
	rpad("x2_hat", 12), "verdict")

for i in 1:6
	Random.seed!(8100 + i)
	pep = two_exp_pep()
	pep_data = ODEParameterEstimation.sample_problem_data(pep, opts)
	raw, analysis, uq = _cov_quiet() do
		ODEParameterEstimation.analyze_parameter_estimation_problem(pep_data, opts)
	end
	best = ODEParameterEstimation._best_scored_result(raw[1])
	if isnothing(best)
		println(rpad(i, 5), "no estimate")
		continue
	end
	g(d, name) = begin
		for (k, v) in d
			replace(string(k), r"\(.*\)" => "") == name && return v
		end
		NaN
	end
	k1h = g(best.parameters, "k1"); k2h = g(best.parameters, "k2")
	x1h = g(best.states, "x1");     x2h = g(best.states, "x2")
	# distance to the identity assignment vs the swapped assignment
	d_id = abs(k1h - 0.6) / 0.6 + abs(k2h - 3.0) / 3.0
	d_sw = abs(k1h - 3.0) / 3.0 + abs(k2h - 0.6) / 0.6
	verdict = d_sw < d_id ? "SWAPPED" : "identity"
	println(rpad(i, 5),
		rpad(round(k1h; sigdigits = 5), 12), rpad(round(k2h; sigdigits = 5), 12),
		rpad(round(x1h; sigdigits = 5), 12), rpad(round(x2h; sigdigits = 5), 12),
		verdict, "  (d_id=", round(d_id; sigdigits = 3), " d_sw=", round(d_sw; sigdigits = 3), ")")
end
println("\nLABEL_PROBE_DONE")
