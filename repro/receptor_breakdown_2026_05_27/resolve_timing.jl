# How long is ONE [RESOLVE] (the per-candidate states-only solve the pipeline runs when a backsolve
# blows)? Bake params (truth + a spurious set from the breakdown) into the receptor model, build the
# states-only SIAN system (time the BUILD), substitute oracle data + solve the small system (time the
# SOLVE). x ~30 resolves/run tells us whether resolves are receptor's 87-min cost or a rounding error
# vs the silent 6402-path main solves (the breakdown measured one of those at ~67s).
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf, OrderedCollections
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation

function setup()
	pep = OPE.receptor_subtype_binding_branch()
	opts = EstimationOptions(datasize = 101, noise_level = 0.0, use_si_template = true, nooutput = true)
	spep = sample_problem_data(pep, opts)
	s = OPE.setup_parameter_estimation(spep; interpolator = OPE.aaad, nooutput = true)
	model = spep.model isa OPE.OrderedODESystem ? spep.model : begin (t,meq,ms,mp)=OPE.unpack_ODE(spep.model); OPE.OrderedODESystem(spep.model, ms, mp) end
	return (; spep, model, mq = spep.measured_quantities, ds = spep.data_sample, DD = s.good_DD)
end

function time_one(S, label, pdict)
	# BUILD: bake params -> states-only SIAN system (what resolve does each call)
	t_build = @elapsed begin
		fixed_model, fixed_mq = OPE.apply_prefixed_params_to_model(S.model, S.mq, OrderedDict{Any,Any}(pdict))
		te, dd, _, _, _, _ = OPE.get_si_equation_system(fixed_model, fixed_mq, S.ds; DD = S.DD, infolevel = 0)
	end
	tdd = OPE.ensure_si_template_dd_support(fixed_model, fixed_mq, S.DD, dd)
	data_vars = OPE.extract_data_variables_from_DD(tdd); dset = Set(data_vars)
	allv = []; seen = Set(); for eq in te, v in Symbolics.get_variables(eq); if !(v in seen); push!(allv, v); push!(seen, v); end; end
	solve_vars = [v for v in allv if !(v in dset)]
	hc_system, hc_vars, hc_params = OPE.convert_to_hc_format_with_params(te, solve_vars, data_vars)
	# oracle data at t=0 (coeff values; solve TIME is structure-driven, exact point doesn't matter)
	p = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, 0.0, 12), data_vars, tdd, fixed_mq, 0.0)
	# SOLVE: the small states-only system (what [RESOLVE] times as "Solving square system with HC.jl")
	t_solve = @elapsed res = HC.solve(hc_system; target_parameters = p, show_progress = false)
	nsol = length(HC.solutions(res; only_nonsingular = false, only_finite = true))
	@printf("[%-9s] build=%6.2fs  solve=%6.3fs  | n_eqs=%d  n_solve_vars=%d  paths=%d  n_sol=%d\n",
		label, t_build, t_solve, length(te), length(solve_vars), HC.ntracked(res), nsol); flush(stdout)
	return t_build, t_solve
end

function main()
	println("=== per-[RESOLVE] cost (build + solve) — receptor states-only system ==="); flush(stdout)
	S = setup()
	truth    = OrderedDict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
	spurious = OrderedDict("R1tot"=>2.45,"R2tot"=>1.90,"kon1"=>-1.58,"kon2"=>1.10,"koff1"=>0.04,"koff2"=>-2.81)
	time_one(S, "warmup", truth)   # absorb first-call JIT
	bt, st = time_one(S, "truth", truth)
	bs, ss = time_one(S, "spurious", spurious)
	avg = ((bt+st)+(bs+ss))/2
	@printf("\nPer-resolve (warm) ≈ %.2fs (build+solve). x30 resolves ≈ %.1f min.  Compare: main 6402-path solve ≈ 67s.\n", avg, 30*avg/60); flush(stdout)
	println("=== done ==="); flush(stdout)
end

main()
