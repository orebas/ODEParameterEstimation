# GATE spike for caching the per-candidate SIAN rebuild in resolve_states_with_fixed_params.
# The cache rests on ONE premise: the param-fixed SIAN template STRUCTURE (deriv_dict, equation set,
# solve-var set) is independent of the candidate's param VALUES (only coefficients differ). Test it
# directly: bake two DIFFERENT physical param sets + one rank-collapse set into the receptor model,
# run get_si_equation_system on each, and compare structure + time.
#   * truth vs perturbed structure IDENTICAL  -> caching the template across candidates is sound.
#   * rank-collapse structure DIFFERS          -> the cache MUST detect non-square / fall back.
#   * per-call time ~seconds                    -> confirms it's the bottleneck worth caching.
# READ-ONLY to src (calls public functions only).
using ODEParameterEstimation, Symbolics, Printf, OrderedCollections
const OPE = ODEParameterEstimation

function setup()
	pep = OPE.receptor_subtype_binding_branch()
	opts = EstimationOptions(datasize = 101, noise_level = 0.0, use_si_template = true, nooutput = true)
	spep = sample_problem_data(pep, opts)
	s = OPE.setup_parameter_estimation(spep; interpolator = OPE.aaad, nooutput = true)
	model = spep.model isa OPE.OrderedODESystem ? spep.model : begin (t,meq,ms,mp)=OPE.unpack_ODE(spep.model); OPE.OrderedODESystem(spep.model, ms, mp) end
	return (; model, mq = spep.measured_quantities, ds = spep.data_sample, DD = s.good_DD)
end

# structural fingerprint of a get_si_equation_system result (value-independent parts)
function fingerprint(te, deriv_dict)
	eqset = sort(string.(te))                                   # equation strings (coefficients differ; structure may not)
	dd = sort([string(k) * "=>" * string(v) for (k, v) in deriv_dict])
	vars = sort(unique(vcat([string.(Symbolics.get_variables(eq)) for eq in te]...)))
	return (n_eq = length(te), deriv = dd, vars = vars, eqset = eqset)
end

function build(S, label, pdict)
	fixed_model, fixed_mq = OPE.apply_prefixed_params_to_model(S.model, S.mq, OrderedDict{Any,Any}(pdict))
	t = @elapsed begin
		te, deriv_dict, _unid, _idf, _summ, _meta = OPE.get_si_equation_system(fixed_model, fixed_mq, S.ds; DD = S.DD, infolevel = 0)
	end
	fp = fingerprint(te, deriv_dict)
	@printf("[%-13s] %.1fs | n_eq=%d  n_derivvars=%d  n_vars=%d\n", label, t, fp.n_eq, length(fp.deriv), length(fp.vars)); flush(stdout)
	return fp
end

function main()
	println("=== resolve-cache GATE spike: is the param-fixed SIAN template structure value-independent? ==="); flush(stdout)
	S = setup()
	truth   = OrderedDict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
	pert    = OrderedDict(k => v*1.37 + 0.05 for (k,v) in truth)        # different physical-ish values
	collapse= OrderedDict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.0,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)  # kon1=0: Ca decouples

	a = build(S, "truth", truth)
	b = build(S, "perturbed", pert)
	c = try build(S, "rank-collapse", collapse) catch e; println("  rank-collapse build errored: ", sprint(showerror,e)[1:min(90,end)]); nothing end

	println()
	same_struct = (a.n_eq == b.n_eq) && (a.deriv == b.deriv) && (a.vars == b.vars)
	same_eqset  = (a.eqset == b.eqset)
	@printf("truth vs perturbed: n_eq/deriv/vars identical? %s | full eq-STRING set identical? %s\n", same_struct, same_eqset)
	println("  (structure identical + eq-strings differ ⇒ only COEFFICIENTS depend on param values ⇒ cache is sound)")
	if c !== nothing
		@printf("rank-collapse vs truth: n_eq %d vs %d, structure identical? %s  (if NO ⇒ cache must fall back here)\n",
			c.n_eq, a.n_eq, (c.n_eq==a.n_eq && c.deriv==a.deriv && c.vars==a.vars))
	end
	println()
	println(same_struct ? ">>> GATE PASS: template structure is value-independent → caching is sound (re-instantiate coefficients per candidate)." :
						   ">>> GATE FAIL: structure differs across physical param values → caching NOT safe as designed.")
	flush(stdout)
end

main()
