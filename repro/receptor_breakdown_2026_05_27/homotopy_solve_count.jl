# Where do receptor's 87 minutes go, and is it a parameter-homotopy failure?
# Faithfully replicate solve_with_hc_parameterized's loop (optimized_multishot calls it ONCE with the
# 3 shooting points): point-1 FRESH polyhedral solve, then TRACK those solutions to each later point,
# and if tracking lands fewer than the start count, fire a FRESH-FALLBACK. Same system, same column
# scaling, same shooting indices (compute_shooting_indices) as the e2e; oracle data (the homotopy
# collapse is a tracking-geometry failure, data-independent per receptor_homotopy_diag). Time every
# solve. Output answers: #solves, solutions each, what triggers the fallback, and the total = the e2e's
# solve-phase cost (compare to the 87-min wall).
using ODEParameterEstimation, HomotopyContinuation, Symbolics, Printf
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

function main()
	println("=== receptor parameter-homotopy solve breakdown (faithful replica of solve_with_hc_parameterized) ==="); flush(stdout)
	S = setup()
	t_vector = S.spep.data_sample["t"]
	pidx = OPE.compute_shooting_indices(3, length(t_vector); warp = true, beta = 3.0)
	@printf("shooting points: indices %s  t = %s\n", pidx, [round(Float64(t_vector[i]), digits = 3) for i in pidx]); flush(stdout)
	param_values_list = [OPE.evaluate_data_vars_at_point(OPE.build_perfect_interpolants(S.spep, Float64(t_vector[i]), 12), S.data_vars, S.tdd, S.mq, Float64(t_vector[i])) for i in pidx]

	# mirror solve_with_hc_parameterized 1000-1021: convert + column-scale (cs ON, the production default)
	hc_system, hc_variables, hc_params = OPE.convert_to_hc_format_with_params(S.te, S.solve_vars, S.data_vars)
	col_scales = OPE.compute_column_scales(S.solve_vars, S.data_vars, param_values_list)
	hc_system = OPE.scale_hc_system(hc_system, hc_variables, col_scales)
	@printf("system: %d vars, %d eqs, scale range %s\n", length(hc_variables), length(S.te), extrema(col_scales)); flush(stdout)

	real_tol = 1e-9
	prev_all = nothing; prev_p = nothing; initial_count = 0
	total = 0.0; n_fresh = 0; n_track = 0; n_fallback = 0
	println(repeat("-", 90))
	for (i, p) in enumerate(param_values_list)
		if i == 1 || prev_all === nothing || isempty(prev_all)
			t = @elapsed res = HC.solve(hc_system; target_parameters = p, show_progress = false)
			all_sols = HC.solutions(res); initial_count = length(all_sols); total += t; n_fresh += 1
			nreal = length(HC.solutions(res; only_real = true, real_tol = real_tol))
			@printf("point %d  FRESH        : %6.1fs  → %3d total, %2d real   (paths tracked %d)\n", i, t, length(all_sols), nreal, HC.ntracked(res)); flush(stdout)
		else
			t = @elapsed res = HC.solve(hc_system, prev_all; start_parameters = prev_p, target_parameters = p, show_progress = false)
			landed = HC.solutions(res); total += t; n_track += 1
			nreal = length(HC.solutions(res; only_real = true, real_tol = real_tol))
			lost = length(landed) < initial_count
			@printf("point %d  TRACK %3d→    : %6.1fs  → %3d landed, %2d real   %s\n", i, length(prev_all), t, length(landed), nreal, lost ? "[LOST PATHS: $(length(landed)) < $initial_count → fallback]" : "[ok]"); flush(stdout)
			all_sols = landed
			if lost
				t2 = @elapsed res = HC.solve(hc_system; target_parameters = p, show_progress = false)
				all_sols = HC.solutions(res); initial_count = max(initial_count, length(all_sols)); total += t2; n_fallback += 1
				nreal = length(HC.solutions(res; only_real = true, real_tol = real_tol))
				@printf("point %d  FRESH-FALLBK : %6.1fs  → %3d total, %2d real\n", i, t2, length(all_sols), nreal); flush(stdout)
			end
		end
		prev_all = all_sols; prev_p = p
	end
	println(repeat("-", 90))
	@printf("SOLVES: %d fresh + %d track + %d fresh-fallback = %d HC.solve calls\n", n_fresh, n_track, n_fallback, n_fresh + n_track + n_fallback)
	@printf("TOTAL parameterized-solve time (3 pts, scaled, oracle): %.1fs = %.1f min\n", total, total / 60)
	println("(compare to the receptor e2e wall ≈ 87 min: this is the solve-phase share)")
	println("=== done ==="); flush(stdout)
end

main()
