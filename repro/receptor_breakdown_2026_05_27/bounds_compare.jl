# Does passing opt_lb/opt_ud=[1e-5,10] (which activates the param-clamp before backsolve) change
# receptor's [RESOLVE] fire count / wall time / recovery vs no bounds? Runs the REAL pipeline (so the
# real backsolve + the real _clamp_params_for_backsolve), cs=true, one rep. ARGS[1] = "none"|"bounded".
# Grep the log afterward for "[RESOLVE] Re-running SIAN" (fire count) and "blown backsolves".
using ODEParameterEstimation, Printf, Statistics, Random
const OPE = ODEParameterEstimation
const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)

function relerr_vs(candidate, ref)
	errs = Float64[]
	for (k, v) in candidate.parameters
		nm = string(k); haskey(ref, nm) || continue
		push!(errs, abs(v - ref[nm]) / max(abs(ref[nm]), 1e-9))
	end
	isempty(errs) ? Inf : maximum(errs)
end
best_vs(raw, ref) = isempty(raw) ? Inf : minimum(relerr_vs(c, ref) for c in raw)

function mkopts(; bounds::Bool)
	n = 9  # receptor: 3 states (L,Ca,Cb) + 6 params -> opt_lb/opt_ub length must be n_states+n_params
	lb = bounds ? fill(1e-5, n) : nothing
	ub = bounds ? fill(10.0, n) : nothing
	EstimationOptions(datasize = 201, noise_level = 0.0, system_solver = SolverHC, flow = FlowStandard,
		interpolator = InterpolatorAAAD, auto_filter_interpolators = false, use_si_template = true,
		use_parameter_homotopy = true, use_multipoint = false, use_column_scaling = true,
		shooting_points = 3, polish_solver_solutions = false, polish_solutions = false,
		opt_lb = lb, opt_ub = ub, nooutput = true, diagnostics = false)
end

function main()
	mode = isempty(ARGS) ? "none" : ARGS[1]
	bounds = (mode == "bounded")
	println("##### receptor bounds_compare: mode=$mode (bounds=$bounds) #####"); flush(stdout)
	pep = OPE.receptor_subtype_binding_branch()
	opts = mkopts(; bounds = bounds)
	sampled = sample_problem_data(pep, opts)
	t0 = time()
	res, _, _ = analyze_parameter_estimation_problem(sampled, opts)
	wall = time() - t0
	raw = res[1]
	bt = best_vs(raw, TRUTH); bs = best_vs(raw, SWAP)
	@printf(">>> mode=%s: n_candidates=%d  truth_relerr=%.3e  swap_relerr=%.3e  %s  wall=%.0fs\n",
		mode, length(raw), bt, bs, (bt<1e-2 ? "TRUTH " : "")*(bs<1e-2 ? "SWAP" : ""), wall); flush(stdout)
	println("##### done mode=$mode #####"); flush(stdout)
end

main()
