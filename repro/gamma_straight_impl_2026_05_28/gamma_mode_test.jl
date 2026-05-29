# Production-wiring test for the new homotopy_tracking_mode: call solve_with_hc_parameterized directly
# on receptor's 3 shooting points under each mode and report, per point, how many real solutions land
# and whether truth+swap survived. Expectation: :parameter loses truth/swap on the later points
# (the collapse); :gamma_straight (and :gamma_straight_fallback) keep them. Column scaling ON.
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation
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

function main()
	println("=== gamma_mode_test: solve_with_hc_parameterized per mode (receptor, 3 points) ==="); flush(stdout)
	S = setup()
	tv = S.spep.data_sample["t"]
	pidx = OPE.compute_shooting_indices(3, length(tv); warp = true, beta = 3.0)
	P = [oracle(S, tv[i]) for i in pidx]
	@printf("shooting t = %s\n\n", [round(Float64(tv[i]), digits = 3) for i in pidx]); flush(stdout)
	for mode in (:parameter, :gamma_straight, :gamma_straight_fallback)
		opts = Dict(:homotopy_tracking_mode => mode, :use_column_scaling => true, :debug => false,
			:gamma_max_seeds => 5, :gamma_seed => 1, :real_tol => 1e-9)
		t = @elapsed sbp = OPE.solve_with_hc_parameterized(S.te, S.solve_vars, S.data_vars, P; options = opts)
		println("mode = $mode   ($(round(t, digits=1))s)")
		for (i, sols) in enumerate(sbp)
			@printf("   point %d (t=%+.2f): %2d real sols   truth=%-5s swap=%-5s\n",
				i, Float64(tv[pidx[i]]), length(sols), present(S, sols, TRUTH), present(S, sols, SWAP)); flush(stdout)
		end
		println()
	end
	println("=== done ==="); flush(stdout)
end
main()
