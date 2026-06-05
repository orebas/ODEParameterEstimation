# Is the singular locus LOCALIZED to the transient (measure-0, approached only near t≈-0.3) or
# pervasive? Track from ONE clean start (t=0.5) to a sweep of targets clean→transient. If landing
# stays high for clean targets and only drops near t≈-0.3 → LOCALIZED. Then test the SWAP-FIXED-LOCUS
# hypothesis: at a transient stall, is Ca_0≈Cb_0 (the swap-fixed locus where truth=swap), and is the
# Jacobian null-space direction the antisymmetric Ca_k−Cb_k (swap) direction?
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
	return (; spep, mq, tdd, te, data_vars, solve_vars, svname = string.(solve_vars))
end
oracle(S, t) = OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, Float64(t), 12), S.data_vars, S.tdd, S.mq, Float64(t))
gidx(S, b) = findfirst(n -> n == b || n == b*"_0", S.svname)

function main()
	println("=== locality + swap-fixed-locus test ==="); flush(stdout)
	S = setup()
	P_start = ComplexF64.(oracle(S, 0.5))
	targets = [0.3, 0.2, 0.0, -0.2, -0.32, -0.5]
	Ptgt = [ComplexF64.(oracle(S, t)) for t in targets]
	allP = vcat([real.(P_start)], [real.(p) for p in Ptgt])
	hc_system, hc_vars, _ = OPE.convert_to_hc_format_with_params(S.te, S.solve_vars, S.data_vars)
	scales = OPE.compute_column_scales(S.solve_vars, S.data_vars, allP)
	sys = OPE.scale_hc_system(hc_system, hc_vars, scales)
	res0 = HC.solve(sys; target_parameters = P_start, show_progress = false)
	starts = HC.solutions(res0)
	@printf("fresh solve at t=0.5: %d start solutions\n\n", length(starts)); flush(stdout)

	println("track t=0.5 → target  (collapse localized to the transient?):")
	stash = nothing
	for (t, pt) in zip(targets, Ptgt)
		res = HC.solve(sys, starts; start_parameters = P_start, target_parameters = pt, show_progress = false)
		prs = HC.path_results(res)
		landed = count(pr -> pr.return_code == :success, prs)
		@printf("  t=%+.2f : %2d / %2d landed\n", t, landed, length(starts)); flush(stdout)
		t == -0.32 && (stash = (prs, pt))
	end

	# swap-locus + null-space at a transient stall (target t=-0.32)
	println("\n=== swap-fixed-locus check at a t=-0.32 stall ==="); flush(stdout)
	Jsym = Symbolics.jacobian(collect(S.te), S.solve_vars)
	ca0 = gidx(S, "Ca"); cb0 = gidx(S, "Cb"); l0 = gidx(S, "L")
	prs, pt = stash
	shown = 0
	for pr in prs
		pr.return_code == :success && continue
		shown >= 2 && break
		x_true = scales .* pr.solution
		subs = Dict{Any,Any}(); for (i,v) in enumerate(S.solve_vars); subs[v]=x_true[i]; end; for (i,v) in enumerate(S.data_vars); subs[v]=pt[i]; end
		J = [ComplexF64(Symbolics.value(Symbolics.substitute(Jsym[i,j], subs))) for i in 1:size(Jsym,1), j in 1:size(Jsym,2)]
		F = svd(J)
		# top components of the smallest right singular vector (the null/degeneracy direction)
		nullv = abs.(F.V[:, end]); order = sortperm(nullv, rev=true)[1:6]
		@printf("  stall: Ca_0=%.4g  Cb_0=%.4g  (|Ca_0-Cb_0|=%.2e, |Ca_0+Cb_0|=%.2e)  L_0=%.4g\n",
			real(x_true[ca0]), real(x_true[cb0]), abs(x_true[ca0]-x_true[cb0]), abs(x_true[ca0]+x_true[cb0]), real(x_true[l0])); flush(stdout)
		@printf("    null-space top components: %s\n", join(["$(S.svname[k])=$(round(nullv[k],digits=3))" for k in order], ", ")); flush(stdout)
		shown += 1
	end
	println("=== done ==="); flush(stdout)
end
main()
