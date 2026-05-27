# Concrete answers: what are L_k / y1_k, and does the production trimmed system use the y1 data at all?
# Build the receptor SI system, then for EVERY data variable (y1_k, y2_k) report how many trimmed
# equations actually contain it — i.e. whether the system uses that observed derivative. Also detect
# surviving "pins" (equations that are exactly L_k - y1_k) and show which state-derivative unknowns
# appear. No production code modified; reads the real get_si_equation_system output.
using ODEParameterEstimation, Symbolics, Printf
const OPE = ODEParameterEstimation

function main()
	pep = OPE.receptor_subtype_binding_branch()
	opts = EstimationOptions(datasize = 101, noise_level = 0.0, use_si_template = true, nooutput = true)
	spep = sample_problem_data(pep, opts)
	s = OPE.setup_parameter_estimation(spep; interpolator = OPE.aaad, nooutput = true)
	DD = s.good_DD; mq = spep.measured_quantities; ds = spep.data_sample
	model = spep.model isa OPE.OrderedODESystem ? spep.model : begin (t,meq,ms,mp)=OPE.unpack_ODE(spep.model); OPE.OrderedODESystem(spep.model, ms, mp) end

	println("=== receptor observables (measured_quantities) ===")
	for q in mq; println("   ", q.lhs, " ~ ", q.rhs); end
	println("   => y1 observes L directly; y2 observes Ca+Cb.\n"); flush(stdout)

	te, dd, _, _, _, _ = OPE.get_si_equation_system(model, mq, ds; DD = DD, infolevel = 0)
	tdd = OPE.ensure_si_template_dd_support(model, mq, DD, dd)
	data_vars = OPE.extract_data_variables_from_DD(tdd); dset = Set(data_vars)
	allv = []; seen = Set(); for eq in te, v in Symbolics.get_variables(eq); if !(v in seen); push!(allv, v); push!(seen, v); end; end
	solve_vars = [v for v in allv if !(v in dset)]

	# which variables actually appear across the trimmed system
	used = Set(); for eq in te, v in Symbolics.get_variables(eq); push!(used, v); end

	@printf("Trimmed system: %d equations | %d solve_vars | %d data_vars defined\n\n", length(te), length(solve_vars), length(data_vars)); flush(stdout)

	println("=== DATA variables (observed derivatives) — used by the trimmed system? ===")
	for dv in data_vars
		nm = string(dv)
		appears = dv in used
		neq = count(eq -> dv in Set(Symbolics.get_variables(eq)), te)
		@printf("   %-34s  used=%-5s  (in %d eqs)\n", nm, appears, neq)
	end
	# headline grouping by observable
	y1_used = [string(dv) for dv in data_vars if (dv in used) && occursin("y1", string(dv))]
	y2_used = [string(dv) for dv in data_vars if (dv in used) && occursin("y2", string(dv))]
	y1_all  = [string(dv) for dv in data_vars if occursin("y1", string(dv))]
	y2_all  = [string(dv) for dv in data_vars if occursin("y2", string(dv))]
	println()
	@printf(">>> y1 (= L) data: %d/%d derivatives USED by the system\n", length(y1_used), length(y1_all))
	@printf(">>> y2 (= Ca+Cb) data: %d/%d derivatives USED by the system\n", length(y2_used), length(y2_all)); flush(stdout)

	println("\n=== STATE-derivative unknowns present in the trimmed system ===")
	for sv in solve_vars
		nm = string(sv)
		(startswith(nm, "L_") || startswith(nm, "Ca_") || startswith(nm, "Cb_")) || continue
		@printf("   %-8s present\n", nm)
	end

	# detect surviving pins: an equation whose variable set is exactly {L_k, y1_k}
	println("\n=== surviving linear pins (eqs that are exactly L_k - y1_k)? ===")
	npins = 0
	for (i, eq) in enumerate(te)
		vs = collect(Symbolics.get_variables(eq))
		length(vs) == 2 || continue
		ns = sort(string.(vs))
		if any(startswith(n, "L_") for n in ns) && any(occursin("y1", n) for n in ns)
			@printf("   eq[%d]: %s   (vars: %s)\n", i, string(eq), join(ns, ", ")); npins += 1
		end
	end
	npins == 0 && println("   NONE — no L_k = y1_k pin survives in the trimmed system.")
	println("\n=== done ==="); flush(stdout)
end

main()
