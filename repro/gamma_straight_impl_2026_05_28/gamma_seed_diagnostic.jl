# Is γ-straight's receptor truth/swap loss SYSTEMATIC or run-to-run NOISE?
# The 3-mode production-wiring test (n=1) showed :parameter keeping truth+swap at all 3 points while
# :gamma_straight lost them — the OPPOSITE of codex's isolated-tracking probe. But point 1 is a FRESH
# solve (no mode), yet differed across modes → there IS run-to-run noise (unseeded fresh solves + 5%
# present() tol). This sweeps :gamma_straight across gamma_seeds to tell signal from noise. Column
# scaling ON (production default). Note: gamma_seed only seeds the TRACKING γ, NOT the point-1 fresh
# solve (HC internal RNG), so some variation persists regardless.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf
const OPE = ODEParameterEstimation
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
oracle(S, t) = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, Float64(t), 12), S.data_vars, S.tdd, S.mq, Float64(t))
gi(S, sol, b) = (i = findfirst(n -> n == b || n == b*"_0", S.svname); i === nothing ? NaN : sol[i])
present(S, sols, ref) = any(sol -> all(isfinite(gi(S,sol,k)) && abs(gi(S,sol,k)-v) < 0.05*max(abs(v),1) for (k,v) in ref), sols)

function run_one(S, P, mode, seed)
	opts = Dict(:homotopy_tracking_mode => mode, :use_column_scaling => true, :debug => false,
		:gamma_max_seeds => 5, :gamma_seed => seed, :real_tol => 1e-9)
	t = @elapsed sbp = OPE.solve_with_hc_parameterized(S.te, S.solve_vars, S.data_vars, P; options = opts)
	@printf("  %-22s seed=%d (%6.1fs): ", string(mode), seed, t)
	for (i, sols) in enumerate(sbp)
		@printf("p%d[%2d %s%s] ", i, length(sols), present(S,sols,TRUTH) ? "T" : ".", present(S,sols,SWAP) ? "S" : ".")
	end
	println(); flush(stdout)
end

function main()
	println("=== γ-straight seed sweep (receptor, 3pt). format p<i>[<realcount> T?S?] ==="); flush(stdout)
	S = setup()
	tv = S.spep.data_sample["t"]
	pidx = OPE.compute_shooting_indices(3, length(tv); warp = true, beta = 3.0)
	P = [oracle(S, tv[i]) for i in pidx]
	@printf("shooting t = %s\n\n", [round(Float64(tv[i]), digits = 3) for i in pidx]); flush(stdout)
	for seed in 1:5
		run_one(S, P, :gamma_straight, seed)
	end
	println("--- :parameter control (1 extra sample; seed ignored by :parameter, re-runs fresh-solve noise) ---")
	run_one(S, P, :parameter, 1)
	println("=== done ==="); flush(stdout)
end
main()
