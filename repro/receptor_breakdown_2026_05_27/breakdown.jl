# What is breaking down in receptor, how bad, and what filter separates garbage from truth.
# Solve receptor at a representative shooting point (scaled, oracle data), enumerate every real finite
# candidate, and for each report: classification (truth/swap/spurious by param match), the 6 param
# values, the order-0 state values (L,Ca,Cb at the eval point), the max jet magnitude, physicality
# (params in [1e-5,10]? occupancies Ca,Cb >= 0? ligand L >= 0?), and the BACKSOLVE outcome (recovered
# IC magnitude at t0 + integration wall time). Also time the main HC solve.
# Tells us: (1) what breaks (which candidates), (2) how bad (magnitudes), (3) the discriminator → filter.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, OrdinaryDiffEq, ModelingToolkit, Printf, LinearAlgebra
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation
const PARAMS = ["R1tot","R2tot","kon1","kon2","koff1","koff2"]
const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)

function setup()
	pep = OPE.receptor_subtype_binding_branch()
	opts = EstimationOptions(datasize=101, noise_level=0.0, use_si_template=true, nooutput=true)
	spep = sample_problem_data(pep, opts)
	s = OPE.setup_parameter_estimation(spep; interpolator=OPE.aaad, nooutput=true)
	DD = s.good_DD; mq = spep.measured_quantities; ds = spep.data_sample
	model = spep.model isa OPE.OrderedODESystem ? spep.model : begin (t,meq,ms,mp)=OPE.unpack_ODE(spep.model); OPE.OrderedODESystem(spep.model, ms, mp) end
	te, dd, _, _, _, meta = OPE.get_si_equation_system(model, mq, ds; DD=DD, infolevel=0)
	tdd = OPE.ensure_si_template_dd_support(model, mq, DD, dd)
	data_vars = OPE.extract_data_variables_from_DD(tdd); dset = Set(data_vars)
	allv=[]; seen=Set(); for eq in te, v in Symbolics.get_variables(eq); if !(v in seen); push!(allv,v); push!(seen,v); end; end
	solve_vars = [v for v in allv if !(v in dset)]
	hc_system, hc_vars, hc_params = OPE.convert_to_hc_format_with_params(te, solve_vars, data_vars)
	return (; spep, mq, tdd, data_vars, solve_vars, svname=string.(solve_vars), hc_system, hc_vars)
end
oracle_params(S, t; maxorder=12) = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, Float64(t), maxorder), S.data_vars, S.tdd, S.mq, Float64(t))
gi(S,s,b) = (i=findfirst(n->n==b||n==b*"_0", S.svname); i===nothing ? NaN : real(s[i]))
function classify(S, c)
	d = Dict(k=>gi(S,c,k) for k in PARAMS)
	all(isfinite(d[k]) && abs(d[k]-TRUTH[k])<0.05*max(abs(TRUTH[k]),1) for k in PARAMS) && return :truth
	all(isfinite(d[k]) && abs(d[k]-SWAP[k]) <0.05*max(abs(SWAP[k]),1)  for k in PARAMS) && return :swap
	return :spurious
end

function main()
	println("=== receptor candidate breakdown @ t=0 (scaled solve, oracle data) ==="); flush(stdout)
	S = setup()
	# ODE pieces for the backsolve
	csys = ModelingToolkit.complete(S.spep.model isa OPE.OrderedODESystem ? S.spep.model.system : S.spep.model)
	mstates = ModelingToolkit.unknowns(csys); mparams = ModelingToolkit.parameters(csys)
	tv = S.spep.data_sample["t"]; t0 = Float64(first(tv)); t_eval = 0.0
	solver = AutoVern9(Rodas5P())

	p = oracle_params(S, t_eval)
	scales = OPE.compute_column_scales(S.solve_vars, S.data_vars, [p])
	sys = OPE.scale_hc_system(S.hc_system, S.hc_vars, scales)
	t_solve = @elapsed res = HC.solve(sys; target_parameters=p, show_progress=false)
	rf = HC.solutions(res; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6)
	cands = [scales .* c for c in rf]   # unscale to true coordinates
	@printf("MAIN solve: %.1fs, %d real finite candidates (mixed_volume tracked %d paths)\n", t_solve, length(cands), HC.ntracked(res)); flush(stdout)
	@printf("%-9s | %-44s | %-22s | phys? | backsolve IC |  t_bs\n", "class", "params [R1tot R2tot kon1 kon2 koff1 koff2]", "states@0 [L Ca Cb] | jetmax"); flush(stdout)
	println(repeat("-", 130))
	nphys=0; nspur=0; nblown_phys=0; nblown_spur=0
	for c in cands
		cls = classify(S, c); cls==:spurious ? (nspur+=1) : (nphys+=1)
		pv = [gi(S,c,k) for k in PARAMS]
		st0 = [gi(S,c,"L"), gi(S,c,"Ca"), gi(S,c,"Cb")]
		jetmax = maximum(abs.(real.(c)))
		params_ok = all(1e-5 .<= pv .<= 10.0)
		states_ok = (st0[1] >= -1e-6) && (st0[2] >= -1e-6) && (st0[3] >= -1e-6)
		phys = params_ok && states_ok
		# backsolve order-0 states from t_eval to t0 with candidate params
		pmap = Dict(mp => pv[findfirst(==(string(mp)), PARAMS)] for mp in mparams if string(mp) in PARAMS)
		smap = Dict(); for ms in mstates; base=replace(string(ms), "(t)"=>""); smap[ms] = base=="L" ? st0[1] : base=="Ca" ? st0[2] : base=="Cb" ? st0[3] : 0.0; end
		bs_mag = NaN; t_bs = 0.0
		try
			t_bs = @elapsed sol = solve(ODEProblem(csys, merge(smap, pmap), (t_eval, t0)), solver; abstol=1e-10, reltol=1e-10)
			bs_mag = maximum(abs(sol(t0; idxs=ms)) for ms in mstates)
		catch; bs_mag = Inf; end
		blown = !isfinite(bs_mag) || bs_mag > 1e9
		cls==:spurious ? (blown && (nblown_spur+=1)) : (blown && (nblown_phys+=1))
		@printf("%-9s | [%s] | [%6.2f %6.2f %6.2f]|%.0e | %s | %9.2e | %.2fs\n",
			string(cls), join([@sprintf("%5.2f",x) for x in pv], " "), st0[1], st0[2], st0[3], jetmax,
			phys ? " yes " : " NO  ", bs_mag, t_bs); flush(stdout)
	end
	println(repeat("-", 130))
	@printf("SUMMARY: %d physical (truth/swap), %d spurious. Backsolve blown: %d/%d spurious, %d/%d physical.\n",
		nphys, nspur, nblown_spur, nspur, nblown_phys, nphys); flush(stdout)
	println("=== done ==="); flush(stdout)
end

main()
