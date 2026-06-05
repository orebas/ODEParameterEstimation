# Precise failure mode: for each stalled parameter-homotopy path, compute WHERE the path is (last point,
# true/unscaled coords) and WHAT THE SYSTEM DOES there — residual ‖F(x;p)‖ (is it on the variety?),
# and the Jacobian ∂F/∂x: smallest singular value σ_min, condition, rank. p is the homotopy parameter
# value at the stall: p(t_stall)=t·P1+(1-t)·P2. If σ_min→0 with ‖F‖ small → the path reached a SINGULAR
# solution (a fold where two solutions merge = a point on the discriminant). Also pairwise distances
# between stalled points → which paths are colliding. Jacobian computed on the UNSCALED system (the
# variety's singularity is scale-invariant; cond shown is the true geometric conditioning).
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf, LinearAlgebra
const OPE = ODEParameterEstimation; const HC = HomotopyContinuation

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
	return (; spep, mq, tdd, te, data_vars, solve_vars)
end
oracle(S, t) = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, Float64(t), 12), S.data_vars, S.tdd, S.mq, Float64(t))

function main()
	println("=== stall-point Jacobian dissection ==="); flush(stdout)
	S = setup()
	tv = S.spep.data_sample["t"]
	pidx = OPE.compute_shooting_indices(3, length(tv); warp = true, beta = 3.0)
	P = [ComplexF64.(oracle(S, tv[i])) for i in pidx]
	hc_system, hc_vars, _ = OPE.convert_to_hc_format_with_params(S.te, S.solve_vars, S.data_vars)
	scales = OPE.compute_column_scales(S.solve_vars, S.data_vars, [real.(p) for p in P])
	sys = OPE.scale_hc_system(hc_system, hc_vars, scales)
	res1 = HC.solve(sys; target_parameters = P[1], show_progress = false)
	starts = HC.solutions(res1)
	res_s = HC.solve(sys, starts; start_parameters = P[1], target_parameters = P[2], show_progress = false)
	prs = HC.path_results(res_s)
	@printf("point1 fresh %d; straight P1→P2 landed %d\n", length(starts), count(pr->pr.return_code==:success, prs)); flush(stdout)

	println("building symbolic Jacobian ∂F/∂x ..."); flush(stdout)
	Jsym = Symbolics.jacobian(collect(S.te), S.solve_vars)
	nv = length(S.solve_vars)
	function evalJF(x_true, p)
		subs = Dict{Any, Any}()
		for (i, v) in enumerate(S.solve_vars); subs[v] = x_true[i]; end
		for (i, v) in enumerate(S.data_vars); subs[v] = p[i]; end
		Fv = [ComplexF64(Symbolics.value(Symbolics.substitute(eq, subs))) for eq in S.te]
		J  = [ComplexF64(Symbolics.value(Symbolics.substitute(Jsym[i, j], subs))) for i in 1:size(Jsym, 1), j in 1:size(Jsym, 2)]
		return norm(Fv), J
	end

	println("\n--- each stalled path: location + system behavior at the stall ---")
	@printf("%-5s %-9s %-10s %-10s %-10s %-10s %-7s\n", "path", "t_stall", "|x_true|", "‖F‖", "σ_min", "cond", "rank")
	println(repeat("-", 78))
	stalls = []
	for (i, pr) in enumerate(prs)
		pr.return_code == :success && continue
		try
			x_true = scales .* pr.solution
			t = real(pr.t)
			p = t .* P[1] .+ (1 - t) .* P[2]
			resn, J = evalJF(x_true, p)
			σ = svdvals(J); σmin = σ[end]; σmax = σ[1]; cnd = σmax / max(σmin, eps())
			rk = count(>(1e-8 * σmax), σ)
			push!(stalls, (i, x_true, t))
			@printf("%-5d %-9.4f %-10.2e %-10.2e %-10.2e %-10.2e %d/%d\n", i, t, maximum(abs.(x_true)), resn, σmin, cnd, rk, nv); flush(stdout)
		catch e
			@printf("%-5d  (eval failed: %s)\n", i, sprint(showerror, e)[1:min(60,end)]); flush(stdout)
		end
	end

	println("\n--- pairwise distances between stalled points (two paths merging = a fold) ---")
	for a in 1:length(stalls), b in (a+1):length(stalls)
		d = norm(stalls[a][2] .- stalls[b][2])
		d < 1e-2 && @printf("  paths %2d & %2d  (t≈%.3f, %.3f):  dist=%.2e  → COLLISION\n", stalls[a][1], stalls[b][1], stalls[a][3], stalls[b][3], d)
	end
	println("=== done ==="); flush(stdout)
end
main()
