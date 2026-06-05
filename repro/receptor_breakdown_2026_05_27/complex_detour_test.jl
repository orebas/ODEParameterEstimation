# Test the PAL-confirmed fix + confirm the diagnosis. (1) Reproduce the straight P1→P2 collapse and
# print pr.t (where each lost path stalls — localizes the crossing: t≈0.5 interior = mid-path
# discriminant; t≈0 endpoint = target singularity). (2) Try the complex-MIDPOINT detour P1→p_mid→P2
# (p_mid = midpoint + i·η·|·|·randn, target stays EXACTLY real P2): does it recover the 12 lost paths?
# If yes → discriminant-crossing confirmed AND the fix works. Column scaling ON (production default).
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf, LinearAlgebra, Random
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
nland(res) = count(pr -> pr.return_code == :success, HC.path_results(res))

function main()
	println("=== complex-detour test (confirm discriminant + test fix) ==="); flush(stdout)
	S = setup()
	tv = S.spep.data_sample["t"]
	pidx = OPE.compute_shooting_indices(3, length(tv); warp = true, beta = 3.0)
	P = [ComplexF64.(oracle(S, tv[i])) for i in pidx]
	hc_system, hc_vars, _ = OPE.convert_to_hc_format_with_params(S.te, S.solve_vars, S.data_vars)
	scales = OPE.compute_column_scales(S.solve_vars, S.data_vars, [real.(p) for p in P])
	sys = OPE.scale_hc_system(hc_system, hc_vars, scales)
	res1 = HC.solve(sys; target_parameters = P[1], show_progress = false)
	starts = HC.solutions(res1)
	@printf("point1 fresh: %d start solutions\n", length(starts)); flush(stdout)

	# (1) straight P1→P2 + localize stalls via pr.t
	res_s = HC.solve(sys, starts; start_parameters = P[1], target_parameters = P[2], show_progress = false)
	prs = HC.path_results(res_s); landed_s = count(pr -> pr.return_code == :success, prs)
	@printf("\nSTRAIGHT P1→P2: %d → %d landed (lost %d)\n", length(starts), landed_s, length(starts) - landed_s); flush(stdout)
	println("  lost-path homotopy-parameter t at stall (HC tracks t: 1→0, so 1=start P1, 0=target P2):")
	for (i, pr) in enumerate(prs)
		pr.return_code == :success && continue
		tval = try round(real(pr.t), digits = 4) catch; "?" end
		@printf("    path %2d  %-24s  stall_t=%s\n", i, pr.return_code, tval); flush(stdout)
	end

	# (2) complex-midpoint detour P1 → p_mid → P2  (several random seeds)
	println("\nCOMPLEX-MIDPOINT detour P1 → p_mid → P2  (final target stays exactly real P2):")
	Random.seed!(20260527)
	for trial in 1:4
		mid = 0.5 .* (P[1] .+ P[2])
		η = 0.2
		pmid = mid .+ (im * η) .* (abs.(mid) .+ 1.0) .* randn(ComplexF64, length(mid))
		res_h = HC.solve(sys, starts; start_parameters = P[1], target_parameters = pmid, show_progress = false)
		smid = HC.solutions(res_h)
		res_f = HC.solve(sys, smid; start_parameters = pmid, target_parameters = P[2], show_progress = false)
		lf = nland(res_f)
		nreal = length(HC.solutions(res_f; only_real = true, real_atol = 1e-6, only_nonsingular = false))
		@printf("  trial %d (η=%.2f): leg1 %d→%d, leg2 →%d landed, %d real   [straight baseline: %d]\n",
			trial, η, length(starts), length(smid), lf, nreal, landed_s); flush(stdout)
	end
	println("=== done ==="); flush(stdout)
end
main()
