# Goal-2 test: does receptor become a "normal" benchmark system with column scaling ON?
# Run receptor_subtype_binding_branch END-TO-END through the production pipeline (parameter
# homotopy — the config whose homotopy-collapse made receptor fail), scaling OFF vs ON, noise=0,
# multiple reps (HC seed varies). Success = recovering BOTH M=2 branches (truth AND swap).
# diagnostics=false to avoid the heavy diagnostic machinery that made the earlier run take 95 min.
#
# Run:  julia --startup-file=no repro/column_scaling_impl_2026_05_26/receptor_e2e.jl
using ODEParameterEstimation, Printf, Statistics, Random
const OPE = ODEParameterEstimation
const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)
const OUT = joinpath(@__DIR__, "receptor_e2e.csv")

# worst-component relative error of a candidate vs a reference param set (matched by name)
function relerr_vs(candidate, ref)
	errs = Float64[]
	for (k, v) in candidate.parameters
		nm = string(k)
		haskey(ref, nm) || continue
		push!(errs, abs(v - ref[nm]) / max(abs(ref[nm]), 1e-9))
	end
	isempty(errs) ? Inf : maximum(errs)
end
best_vs(raw, ref) = isempty(raw) ? Inf : minimum(relerr_vs(c, ref) for c in raw)

mkopts(cs) = EstimationOptions(
	datasize = 201, noise_level = 0.0, system_solver = SolverHC, flow = FlowStandard,
	interpolator = InterpolatorAAAD, auto_filter_interpolators = false, use_si_template = true,
	use_parameter_homotopy = true, use_multipoint = false, use_column_scaling = cs,
	shooting_points = 3, polish_solver_solutions = false, polish_solutions = false,
	nooutput = true, diagnostics = false)

function main()
	open(OUT, "w") do io; println(io, "use_column_scaling,rep,n_candidates,best_relerr_truth,best_relerr_swap,truth_ok,swap_ok,wall_s") end
	println("=== receptor end-to-end: recover truth + swap (M=2) with scaling OFF vs ON? ==="); flush(stdout)
	pep = OPE.receptor_subtype_binding_branch()
	tol = 1e-2
	for cs in (true, false)
		nt = 0; ns = 0; nrep = 2
		for rep in 1:nrep
			opts = mkopts(cs)
			sampled = sample_problem_data(pep, opts)
			t0 = time()
			res, _, _ = try analyze_parameter_estimation_problem(sampled, opts) catch e
				println("   [err] cs=$cs rep=$rep: ", sprint(showerror,e)[1:min(100,end)]); ((Any[],),nothing,nothing) end
			wall = time() - t0
			raw = res[1]
			bt = best_vs(raw, TRUTH); bs = best_vs(raw, SWAP)
			tok = bt < tol; sok = bs < tol; tok && (nt += 1); sok && (ns += 1)
			@printf("  cs=%-5s rep=%d : n=%-3d truth=%.2e swap=%.2e  %s (%.0fs)\n",
				cs, rep, length(raw), bt, bs, (tok ? "TRUTH " : "")*(sok ? "SWAP" : ""), wall); flush(stdout)
			open(OUT, "a") do io
				@printf(io, "%s,%d,%d,%.3e,%.3e,%d,%d,%.1f\n", cs, rep, length(raw), bt, bs, tok, sok, wall)
			end
		end
		@printf(">>> cs=%-5s : truth recovered %d/%d, swap recovered %d/%d\n", cs, nt, nrep, ns, nrep); flush(stdout)
	end
	println("\nwrote ", OUT)
end

main()
