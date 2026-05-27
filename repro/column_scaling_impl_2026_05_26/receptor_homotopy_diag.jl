# Explain (not assume) receptor's parameter-homotopy behavior, with vs without column scaling.
# Seed a FULL solution set at a good point, then TRACK leftward toward the blind region, logging at
# each step: tracked count, finite count, and the per-path RETURN-CODE breakdown. This decides:
#   * losses as :at_infinity  -> solutions genuinely leave the finite chart (count varies; homotopy
#     working correctly; the pipeline "collapse" is a conservative count-triggered fallback, not a bug)
#   * losses as :terminated_* -> numerical tracking failure (a real failure; the kind scaling should fix)
# and whether SCALING reduces the losses. Tracking is ~18 paths/step (cheap); only the 2 seed fresh
# solves (one per mode) cost the 6402-path polyhedral time.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf, LinearAlgebra
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation
const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)

function setup_all()
	pep = OPE.receptor_subtype_binding_branch()
	opts = EstimationOptions(datasize=101, noise_level=0.0, use_si_template=true, nooutput=true)
	spep = sample_problem_data(pep, opts)
	setup = OPE.setup_parameter_estimation(spep; interpolator=OPE.aaad, nooutput=true)
	DD = setup.good_DD; mq = spep.measured_quantities; ds = spep.data_sample
	model = spep.model
	omodel = model isa OPE.OrderedODESystem ? model : begin (t,meq,ms,mp)=OPE.unpack_ODE(model); OPE.OrderedODESystem(model,ms,mp) end
	te, dd, _, _, _, meta = OPE.get_si_equation_system(omodel, mq, ds; DD=DD, infolevel=0)
	tdd = OPE.ensure_si_template_dd_support(omodel, mq, DD, dd)
	data_vars = OPE.extract_data_variables_from_DD(tdd); dset = Set(data_vars)
	allv=[]; seen=Set(); for eq in te, v in Symbolics.get_variables(eq); if !(v in seen); push!(allv,v); push!(seen,v); end; end
	solve_vars = [v for v in allv if !(v in dset)]
	hc_system, hc_vars, hc_params = OPE.convert_to_hc_format_with_params(te, solve_vars, data_vars)
	return (; spep, mq, tdd, data_vars, solve_vars, svname=string.(solve_vars), hc_system, hc_vars)
end
oracle_params(S, t; maxorder=12) = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, Float64(t), maxorder), S.data_vars, S.tdd, S.mq, Float64(t))
gi(S,s,b) = (i=findfirst(n->n==b||n==b*"_0", S.svname); i===nothing ? NaN : real(s[i]))
function hit(S, realsols)  # realsols already unscaled
	t=false; sw=false
	for x in realsols
		d=Dict(k=>gi(S,x,k) for k in keys(TRUTH))
		all(isfinite(d[k]) && abs(d[k]-TRUTH[k])<0.05*max(abs(TRUTH[k]),1) for k in keys(TRUTH)) && (t=true)
		all(isfinite(d[k]) && abs(d[k]-SWAP[k]) <0.05*max(abs(SWAP[k]),1)  for k in keys(SWAP))  && (sw=true)
	end
	(t ? "TRUTH " : "")*(sw ? "SWAP" : "")
end
code_hist(prs) = (h=Dict{Symbol,Int}(); for r in prs; h[r.return_code]=get(h,r.return_code,0)+1; end; join(["$k=$v" for (k,v) in sort(collect(h),by=x->-x[2])], " "))

function chain(S, sys, scales, pts, label)
	println("\n----- $label -----"); flush(stdout)
	p1 = oracle_params(S, pts[1])
	res = HC.solve(sys; target_parameters=p1, show_progress=false)
	sols = HC.solutions(res; only_nonsingular=false, only_finite=true)
	rf = HC.solutions(res; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6)
	@printf("  t=%+.2f FRESH seed: finite=%2d  %s\n", pts[1], length(sols), hit(S, [scales .* s for s in rf])); flush(stdout)
	prev = sols; prevp = p1
	for t in pts[2:end]
		p = oracle_params(S, t)
		res = HC.solve(sys, prev; start_parameters=prevp, target_parameters=p, show_progress=false)
		prs = HC.path_results(res)
		af = HC.solutions(res; only_nonsingular=false, only_finite=true)
		rf = HC.solutions(res; only_nonsingular=false, only_finite=true, only_real=true, real_atol=1e-6)
		@printf("  t=%+.2f TRACK: in=%2d finite_out=%2d | codes[%s] | %s\n",
			t, length(prev), length(af), code_hist(prs), hit(S, [scales .* s for s in rf])); flush(stdout)
		prev = af; prevp = p
	end
end

function main()
	println("=== receptor parameter-homotopy mechanism: scaled vs unscaled, leftward tracking ==="); flush(stdout)
	S = setup_all()
	pts = [0.0, -0.1, -0.2, -0.3, -0.4]   # seed at good point t=0, track into the blind region
	scales = OPE.compute_column_scales(S.solve_vars, S.data_vars, [oracle_params(S, t) for t in pts])
	@printf("scale range=(%.2e,%.2e) nontrivial=%d/%d\n", minimum(scales), maximum(scales), count(>(1.0),scales), length(scales)); flush(stdout)
	ones_v = ones(Float64, length(S.hc_vars))
	chain(S, S.hc_system, ones_v, pts, "UNSCALED homotopy")
	scaled_sys = OPE.scale_hc_system(S.hc_system, S.hc_vars, scales)
	chain(S, scaled_sys, scales, pts, "SCALED homotopy")
	println("\n=== done ==="); flush(stdout)
end
main()
