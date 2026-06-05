# Replicate receptor's worst parameter-homotopy collapse (point1 t=-0.5 → point2 t=-0.32, the blind
# spot, where tracking lost ~12 of 16) and dissect it: per-path return_code + step count + Jacobian
# condition + start/end coordinate norms; then PROBE HC.jl tracker options (more steps, extended
# precision, conservative params, tighter accuracy) to see if any recovers the lost paths; finally a
# stiffness-vs-collision signal (do the lost paths start from higher-coordinate solutions?).
# Column scaling ON (production default) — so this is the failure that SURVIVES scaling.
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

pcode(pr) = pr.return_code
psteps(pr) = try (hasproperty(pr, :accepted_steps) ? pr.accepted_steps : 0) + (hasproperty(pr, :rejected_steps) ? pr.rejected_steps : 0) catch; -1 end
pcond(pr)  = try Float64(pr.condition_jacobian) catch; (try Float64(HC.condition_jacobian(pr)) catch; NaN end) end
psol(pr)   = try pr.solution === nothing ? Float64[] : abs.(pr.solution) catch; Float64[] end

function track_report(label, sys, starts, ps, pt; kw...)
	res = HC.solve(sys, starts; start_parameters = ps, target_parameters = pt, show_progress = false, kw...)
	prs = HC.path_results(res)
	landed = count(pr -> pcode(pr) == :success, prs)
	codes = Dict{Symbol, Int}(); for pr in prs; c = pcode(pr); codes[c] = get(codes, c, 0) + 1; end
	@printf("[%-24s] %2d → %2d landed (lost %2d) | %s\n", label, length(starts), landed, length(starts) - landed,
		join(["$k=$v" for (k, v) in sort(collect(codes), by = x -> -x[2])], "  ")); flush(stdout)
	return prs, landed
end

function main()
	println("=== receptor parameter-homotopy path diagnostics ==="); flush(stdout)
	try
		to = HC.TrackerOptions()
		@printf("HC.TrackerOptions() defaults: max_steps=%s  min_step_size=%s  extended_precision=%s\n",
			getfield(to, :max_steps), (hasproperty(to, :min_step_size) ? to.min_step_size : "?"), (hasproperty(to, :extended_precision) ? to.extended_precision : "?"))
	catch e; println("TrackerOptions introspection: ", sprint(showerror, e)[1:min(120,end)]); end

	S = setup()
	tv = S.spep.data_sample["t"]
	pidx = OPE.compute_shooting_indices(3, length(tv); warp = true, beta = 3.0)
	@printf("shooting points %s  t=%s\n", pidx, [round(Float64(tv[i]), digits = 3) for i in pidx]); flush(stdout)
	P = [oracle(S, tv[i]) for i in pidx]
	hc_system, hc_vars, _ = OPE.convert_to_hc_format_with_params(S.te, S.solve_vars, S.data_vars)
	scales = OPE.compute_column_scales(S.solve_vars, S.data_vars, P)
	sys = OPE.scale_hc_system(hc_system, hc_vars, scales)

	t1 = @elapsed res1 = HC.solve(sys; target_parameters = P[1], show_progress = false)
	starts = HC.solutions(res1)
	@printf("point 1 (t=%.2f) FRESH: %d start solutions  (%.0fs)\n", Float64(tv[pidx[1]]), length(starts), t1); flush(stdout)

	println("\n--- baseline: track point1 → point2 (the worst collapse) ---")
	prs2, landed2 = track_report("p1→p2 default", sys, starts, P[1], P[2])

	println("\n--- PathResult fields available: ", propertynames(prs2[1]), " ---"); flush(stdout)
	println("--- per-path detail (p1→p2) ---")
	for (i, pr) in enumerate(prs2)
		sn = maximum(abs.(starts[i])); en = (e = psol(pr); isempty(e) ? NaN : maximum(e))
		@printf("  path %2d: %-26s steps=%-6s cond=%.2e  |start|=%.2e |end|=%.2e\n", i, pcode(pr), psteps(pr), pcond(pr), sn, en); flush(stdout)
	end

	println("\n--- option probes: can we recover the lost paths on p1→p2? ---")
	for (desc, kw) in [
			("max_steps×50", (tracker_options = HC.TrackerOptions(max_steps = 500_000),)),
			("ext_precision",  (tracker_options = HC.TrackerOptions(extended_precision = true),)),
			("no_ext_prec",    (tracker_options = HC.TrackerOptions(extended_precision = false),)),
			("conservative",   (tracker_options = HC.TrackerOptions(parameters = :conservative),)),
		]
		try; track_report("p1→p2 " * desc, sys, starts, P[1], P[2]; kw...); catch e; @printf("  [%s] FAILED: %s\n", desc, sprint(showerror, e)[1:min(90,end)]); flush(stdout); end
	end

	println("\n--- stiffness-vs-collision signal ---")
	lost = [i for (i, pr) in enumerate(prs2) if pcode(pr) != :success]
	land = [i for (i, pr) in enumerate(prs2) if pcode(pr) == :success]
	cn(idxs) = isempty(idxs) ? "—" : @sprintf("%.2e .. %.2e (median %.2e)", minimum(maximum(abs.(starts[i])) for i in idxs), maximum(maximum(abs.(starts[i])) for i in idxs), sort([maximum(abs.(starts[i])) for i in idxs])[cld(length(idxs),2)])
	println("  LOST   paths start |coord|: ", cn(lost))
	println("  LANDED paths start |coord|: ", cn(land))
	println("=== done ==="); flush(stdout)
end
main()
