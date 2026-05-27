# Quick check that the metric extraction is fixed: run ONE fast cell (simple, polish off) and
# confirm res[1] is the candidate vector and oracle_error_stats yields a tiny best_max (~1e-6).
using ODEParameterEstimation, Printf
const OPE = ODEParameterEstimation
include(joinpath(@__DIR__, "..", "..", "src", "examples", "load_examples.jl"))

function main()
	pep = ALL_MODELS[:simple]()
	opts = EstimationOptions(datasize = 201, noise_level = 0.0, system_solver = SolverHC,
		flow = FlowStandard, interpolator = InterpolatorAAAD, auto_filter_interpolators = false,
		use_si_template = true, use_parameter_homotopy = true, use_multipoint = false,
		use_column_scaling = false, shooting_points = 6, polish_solver_solutions = false,
		polish_solutions = false, nooutput = true, diagnostics = false)
	sampled = sample_problem_data(pep, opts)
	res, _, _ = analyze_parameter_estimation_problem(sampled, opts)
	println("typeof(res)    = ", typeof(res), "   length(res) = ", length(res))
	cands = res[1]
	println("typeof(res[1]) = ", typeof(cands), "   n_candidates = ", length(cands))
	best = Inf
	for c in cands
		s = try OPE.oracle_error_stats(sampled, c) catch e; println("  [stat err] ", sprint(showerror, e)[1:min(100,end)]); nothing end
		s === nothing && continue
		best = min(best, s.maximum)
	end
	@printf("simple best_max = %.3e  (fix OK if ~1e-6; broken if NaN/Inf)\n", best)
end

main()
