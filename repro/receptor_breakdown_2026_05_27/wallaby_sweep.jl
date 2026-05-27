# Does receptor recover parameters across noise under the LITERAL full wallaby (odepe_v2_polish) config?
# Faithful to benchmark_wallaby_2026-05-17 / odepe_v2_polish: 20 warp shooting points, 9-interpolator
# default list + auto_filter, parameter homotopy + multipoint (n=2, max_pairs=15), polish on
# (PolishLSOBoundedLog, maxiters 5000), opt bounds [1e-5,10], abstol/reltol 1e-12. Column scaling = current
# default (on). diagnostics=false / nooutput=true only to keep logs lean (reporting flags, not algorithm).
# ARGS[1] = noise level (e.g. 0.0, 1e-6, 1e-4, 1e-2). Reports recovery of truth AND swap (M=2) + wall time.
using ODEParameterEstimation, Printf, Statistics
const OPE = ODEParameterEstimation
const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)
relerr_vs(c, ref) = (e = Float64[]; for (k,v) in c.parameters; nm=string(k); haskey(ref,nm) && push!(e, abs(v-ref[nm])/max(abs(ref[nm]),1e-9)); end; isempty(e) ? Inf : maximum(e))
best_vs(raw, ref) = isempty(raw) ? Inf : minimum(relerr_vs(c, ref) for c in raw)

function main()
	noise = isempty(ARGS) ? 0.0 : parse(Float64, ARGS[1])
	@printf("##### receptor WALLABY (odepe_v2_polish) sweep: noise=%.0e #####\n", noise); flush(stdout)
	pep = OPE.receptor_subtype_binding_branch()
	n = 9  # 3 states + 6 params
	opts = EstimationOptions(
		datasize = 201, noise_level = noise, system_solver = SolverHC, flow = FlowStandard,
		use_si_template = true,
		shooting_points = 20, shooting_warp = true, shooting_warp_beta = 3.0,
		use_parameter_homotopy = true, use_multipoint = true, multipoint_n_points = 2, multipoint_max_pairs = 15,
		polish_solver_solutions = true, polish_solutions = true, polish_maxiters = 5000, polish_method = PolishLSOBoundedLog,
		opt_maxiters = 200000, opt_lb = 1e-5 * ones(n), opt_ub = 10.0 * ones(n),
		abstol = 1e-12, reltol = 1e-12,
		polish_maxtime = 3600.0, polish_divergence_factor = 10.0, polish_stagnation_window = 50, polish_ode_maxiters = 20000,
		use_column_scaling = true, nooutput = true, diagnostics = false)
	sampled = sample_problem_data(pep, opts)
	t0 = time()
	res, _, _ = try
		analyze_parameter_estimation_problem(sampled, opts)
	catch e
		@printf("[ERROR] noise=%.0e: %s\n", noise, sprint(showerror, e)[1:min(300,end)]); flush(stdout)
		((ParameterEstimationResult[],), nothing, nothing)
	end
	wall = time() - t0
	raw = res[1]
	# top-ranked result (what the pipeline would actually return) + best-in-pool (is truth recoverable at all)
	top_truth = isempty(raw) ? Inf : relerr_vs(raw[1], TRUTH)
	top_swap  = isempty(raw) ? Inf : relerr_vs(raw[1], SWAP)
	pool_truth = best_vs(raw, TRUTH); pool_swap = best_vs(raw, SWAP)
	@printf(">>> noise=%.0e | n_candidates=%d | TOP vs truth=%.3e swap=%.3e | BEST-IN-POOL truth=%.3e swap=%.3e | recovered=%s | wall=%.0fs (%.1f min)\n",
		noise, length(raw), top_truth, top_swap, pool_truth, pool_swap,
		(pool_truth < 1e-2 ? "TRUTH " : "")*(pool_swap < 1e-2 ? "SWAP" : "")*(pool_truth>=1e-2 && pool_swap>=1e-2 ? "NEITHER" : ""),
		wall, wall/60); flush(stdout)
	@printf("##### done noise=%.0e #####\n", noise); flush(stdout)
end

main()
