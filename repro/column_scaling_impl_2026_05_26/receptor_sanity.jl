# Known-positive sanity: run receptor_subtype_binding_branch (M=2 branch model, the system whose
# t≈-0.3 blind spot column scaling fixed in Exp K) through the STANDARD pipeline, off vs on.
# Confirms: (1) column scaling ENGAGES in production (diagnostics=true -> "[HC-PARAM] Column scaling
# ON" line with a nontrivial scale count), (2) recovery is intact / not broken with scaling on.
# use_multipoint=false forces the parameterized HC path so scaling is exercised.
#
# Run:  julia --startup-file=no repro/column_scaling_impl_2026_05_26/receptor_sanity.jl
using ODEParameterEstimation, Printf, Statistics
const OPE = ODEParameterEstimation

function run_one(cs)
	pep = OPE.receptor_subtype_binding_branch()
	opts = EstimationOptions(
		datasize = 201,
		noise_level = 0.0,
		system_solver = SolverHC,
		flow = FlowStandard,
		interpolator = InterpolatorAAAD,
		auto_filter_interpolators = false,
		use_si_template = true,
		use_parameter_homotopy = true,
		use_multipoint = false,            # force the parameterized HC path
		use_column_scaling = cs,
		shooting_points = 6,
		polish_solver_solutions = false,   # clean raw-HC signal + much faster on this 6402-path system
		polish_solutions = false,
		nooutput = true,
		diagnostics = true,                # so the [HC-PARAM] Column scaling ON line prints
	)
	sampled = sample_problem_data(pep, opts)
	res, _, _ = analyze_parameter_estimation_problem(sampled, opts)
	candidates = res[1]   # results_tuple = (solved_res, ...); [1] = candidate vector
	best_max = Inf; best_med = Inf
	for c in candidates
		s = try OPE.oracle_error_stats(sampled, c) catch; nothing end
		s === nothing && continue
		s.maximum < best_max && (best_max = s.maximum; best_med = s.median)
	end
	@printf(">>> receptor cs=%-5s : n=%d best_max=%.3e best_med=%.3e\n",
		cs, length(candidates), isfinite(best_max) ? best_max : NaN, isfinite(best_med) ? best_med : NaN)
	flush(stdout)
end

function main()
	println("=== receptor sanity: column scaling engages + recovery intact ==="); flush(stdout)
	for cs in (false, true)
		println("\n----- use_column_scaling = $cs -----"); flush(stdout)
		try run_one(cs) catch e; println("ERROR cs=$cs: ", sprint(showerror, e)[1:min(200,end)]) end
	end
	println("\n(grep this log for '[HC-PARAM] Column scaling ON' to confirm scaling engaged for cs=true)")
end

main()
