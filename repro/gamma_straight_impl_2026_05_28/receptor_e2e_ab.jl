# RELIABLE receptor end-to-end A/B: the REAL pipeline (analyze_parameter_estimation_problem), judged by
# the pipeline's OWN error metric (analysis.besterror) + max-relative-error of each returned branch vs
# truth/swap. NO brittle real_tol microscope. aaad interpolator, column scaling on, noise 0, M=2 expected.
# Compares homotopy_tracking_mode = :gamma_straight (new default) vs :parameter (old). Same options o.w.
using ODEParameterEstimation, OrderedCollections, Logging, Printf
const OPE = ODEParameterEstimation

const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)

quiet(f) = redirect_stdout(devnull) do
	redirect_stderr(devnull) do
		with_logger(NullLogger()) do
			f()
		end
	end
end

# max relative error of a result's recovered params vs a reference dict (robust; no real_tol filtering)
function maxrel(result, ref)
	pv = Dict(string(k) => v for (k, v) in result.parameters)
	m = 0.0
	for (k, v) in ref
		haskey(pv, k) || return Inf
		m = max(m, abs(pv[k] - v) / max(abs(v), 1e-12))
	end
	return m
end

function run_mode(mode)
	opts = EstimationOptions(datasize = 201, noise_level = 0.0, use_si_template = true,
		interpolators = [OPE.InterpolatorAAAD], auto_filter_interpolators = false,
		use_column_scaling = true, homotopy_tracking_mode = mode,
		nooutput = true, diagnostics = false, save_system = false)
	pep = OPE.receptor_subtype_binding_branch()
	sampled = OPE.sample_problem_data(pep, opts)
	local raw_results, analysis, uq, t
	try
		t = @elapsed ((raw_results, analysis, uq) = quiet() do
			OPE.analyze_parameter_estimation_problem(sampled, opts)
		end)
	catch e
		@printf("\n=== mode = %s : THREW: %s ===\n", string(mode), sprint(showerror, e)); flush(stdout)
		return (mode = mode, time = NaN, besterror = Inf, best_truth = Inf, best_swap = Inf, n = 0)
	end
	reps = analysis.returned_results
	@printf("\n=== mode = %s  (%.1fs) ===\n", string(mode), t)
	@printf("pipeline besterror = %.3e   #returned_results = %d\n", analysis.besterror, length(reps))
	if !isempty(reps)
		println("  param keys (sanity): ", collect(string.(keys(reps[1].parameters))))
	end
	best_truth = Inf; best_swap = Inf
	for (i, r) in enumerate(reps)
		rt = maxrel(r, TRUTH); rs = maxrel(r, SWAP)
		best_truth = min(best_truth, rt); best_swap = min(best_swap, rs)
		tag = rt < 0.05 ? "TRUTH" : (rs < 0.05 ? "SWAP " : "other")
		@printf("  rep %d [%s]: maxrel_truth=%.2e maxrel_swap=%.2e src=%s err=%s\n",
			i, tag, rt, rs, string(r.interpolator_source),
			r.err === nothing ? "n/a" : @sprintf("%.2e", r.err)); flush(stdout)
	end
	@printf(">> truth recovered: %-5s (%.2e)   swap recovered: %-5s (%.2e)\n",
		string(best_truth < 0.05), best_truth, string(best_swap < 0.05), best_swap); flush(stdout)
	return (mode = mode, time = t, besterror = analysis.besterror, best_truth = best_truth, best_swap = best_swap, n = length(reps))
end

function main()
	println("=== RECEPTOR END-TO-END A/B (real pipeline; aaad; cs on; noise 0; M=2 expected) ==="); flush(stdout)
	summary = []
	for mode in (:gamma_straight, :parameter)
		push!(summary, run_mode(mode)); flush(stdout)
	end
	println("\n=== SUMMARY (judge by pipeline besterror + max-rel-err vs truth/swap) ===")
	for s in summary
		@printf("%-16s time=%7.1fs  besterror=%.2e  truth=%-5s(%.1e)  swap=%-5s(%.1e)  nreps=%d\n",
			string(s.mode), s.time, s.besterror,
			string(s.best_truth < 0.05), s.best_truth, string(s.best_swap < 0.05), s.best_swap, s.n); flush(stdout)
	end
	println("=== done ===")
end
main()
