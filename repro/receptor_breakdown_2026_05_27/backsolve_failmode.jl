# ACTUAL garbage-candidate numbers + the backsolve FAILURE MODE (retcode), at a real e2e shooting point.
# Solve receptor (scaled, oracle) at shoot point t=0.5 (e2e's point 3, 14 real candidates), then backsolve
# each candidate's states from t_shoot to t0=-0.5 with the production stiff solver — capturing the solver
# RETCODE (Success / MaxIters / Unstable / DtLessThanMin / ...), the recovered |IC|, and the wall time.
# Maps candidate values onto the MODEL's own state/param objects (prints their names to verify), and does
# NOT swallow the exception. Classifies truth / swap / spurious so we see which candidates fail and how.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, OrdinaryDiffEq, ModelingToolkit, Printf, LinearAlgebra
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation
const PARAMS = ["R1tot","R2tot","kon1","kon2","koff1","koff2"]
const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)

function setup()
	pep = OPE.receptor_subtype_binding_branch()
	opts = EstimationOptions(datasize = 201, noise_level = 0.0, use_si_template = true, nooutput = true)
	spep = sample_problem_data(pep, opts)
	s = OPE.setup_parameter_estimation(spep; interpolator = OPE.aaad, nooutput = true)
	DD = s.good_DD; mq = spep.measured_quantities; ds = spep.data_sample
	model = spep.model isa OPE.OrderedODESystem ? spep.model : begin (t,meq,ms,mp)=OPE.unpack_ODE(spep.model); OPE.OrderedODESystem(spep.model, ms, mp) end
	te, dd, _, _, _, _ = OPE.get_si_equation_system(model, mq, ds; DD = DD, infolevel = 0)
	tdd = OPE.ensure_si_template_dd_support(model, mq, DD, dd)
	data_vars = OPE.extract_data_variables_from_DD(tdd); dset = Set(data_vars)
	allv = []; seen = Set(); for eq in te, v in Symbolics.get_variables(eq); if !(v in seen); push!(allv, v); push!(seen, v); end; end
	solve_vars = [v for v in allv if !(v in dset)]
	return (; spep, mq, tdd, te, data_vars, solve_vars, svname = string.(solve_vars))
end
gi(S, s, b) = (i = findfirst(n -> n == b || n == b*"_0", S.svname); i === nothing ? NaN : real(s[i]))
function classify(S, c)
	d = Dict(k => gi(S, c, k) for k in PARAMS)
	all(isfinite(d[k]) && abs(d[k]-TRUTH[k]) < 0.05*max(abs(TRUTH[k]),1) for k in PARAMS) && return "truth"
	all(isfinite(d[k]) && abs(d[k]-SWAP[k])  < 0.05*max(abs(SWAP[k]),1)  for k in PARAMS) && return "swap"
	return "SPURIOUS"
end

function main()
	println("=== receptor backsolve FAILURE MODE @ shoot t=0.5 → t0=-0.5 (production stiff solver) ==="); flush(stdout)
	S = setup()
	csys = ModelingToolkit.complete(S.spep.model isa OPE.OrderedODESystem ? S.spep.model.system : S.spep.model)
	states = ModelingToolkit.unknowns(csys); params = ModelingToolkit.parameters(csys)
	println("model states: ", string.(states))            # verify the names we map onto
	println("model params: ", string.(params)); flush(stdout)
	tv = S.spep.data_sample["t"]; t0 = Float64(tv[1]); t_shoot = Float64(tv[end])
	solver = AutoVern9(Rodas5P())
	pname(p) = replace(string(p), "(t)" => "")

	p = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, t_shoot, 12), S.data_vars, S.tdd, S.mq, t_shoot)
	scales = OPE.compute_column_scales(S.solve_vars, S.data_vars, [p])
	hc_system, hc_vars, _ = OPE.convert_to_hc_format_with_params(S.te, S.solve_vars, S.data_vars)
	sys = OPE.scale_hc_system(hc_system, hc_vars, scales)
	res = HC.solve(sys; target_parameters = p, show_progress = false)
	cands = [scales .* c for c in HC.solutions(res; only_nonsingular = false, only_finite = true, only_real = true, real_atol = 1e-6)]
	@printf("%d real candidates at t=%.2f\n", length(cands), t_shoot); flush(stdout)
	println(repeat("-", 120))
	for c in cands
		cls = classify(S, c)
		pv = [gi(S, c, k) for k in PARAMS]
		stsh = Dict("L" => gi(S,c,"L"), "Ca" => gi(S,c,"Ca"), "Cb" => gi(S,c,"Cb"))
		smap = Dict(s => stsh[pname(s)] for s in states)
		pmap = Dict(pp => pv[findfirst(==(pname(pp)), PARAMS)] for pp in params)
		retcode = :THREW; icmax = NaN; t_bs = 0.0; ic = Float64[]
		try
			t_bs = @elapsed sol = ModelingToolkit.solve(ODEProblem(csys, merge(smap, pmap), (t_shoot, t0)), solver; abstol = 1e-12, reltol = 1e-12)
			retcode = sol.retcode
			ic = Float64[Float64(real(sol(t0, idxs = s))) for s in states]
			icmax = isempty(ic) ? NaN : maximum(abs.(ic))
		catch e
			retcode = Symbol("THREW:" * sprint(showerror, e)[1:min(40,end)])
		end
		@printf("[%-8s] params=%s  states@shoot=[L=%.2f Ca=%.2f Cb=%.2f]\n            → retcode=%s  time=%.3fs  |IC|max=%.3e  IC=%s\n",
			cls, string([round(x, digits=3) for x in pv]),
			stsh["L"], stsh["Ca"], stsh["Cb"], retcode, t_bs, icmax,
			isempty(ic) ? "—" : string([round(x, digits=3) for x in ic])); flush(stdout)
	end
	println(repeat("-", 120))
	println("=== done ==="); flush(stdout)
end

main()
