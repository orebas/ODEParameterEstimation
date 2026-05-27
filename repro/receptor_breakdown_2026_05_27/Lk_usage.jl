# Where do the higher L-derivative UNKNOWNS (L_1..L_7) appear in the trimmed system, given their
# y1-pins (L_k=y1_k) were dropped? For each state-derivative unknown, count equations and show which.
# Then print the actual equations containing L_6 and L_7 to see HOW they're constrained (dynamics, not data).
using ODEParameterEstimation, Symbolics, Printf
const OPE = ODEParameterEstimation

function main()
	pep = OPE.receptor_subtype_binding_branch()
	opts = EstimationOptions(datasize = 101, noise_level = 0.0, use_si_template = true, nooutput = true)
	spep = sample_problem_data(pep, opts)
	s = OPE.setup_parameter_estimation(spep; interpolator = OPE.aaad, nooutput = true)
	DD = s.good_DD; mq = spep.measured_quantities; ds = spep.data_sample
	model = spep.model isa OPE.OrderedODESystem ? spep.model : begin (t,meq,ms,mp)=OPE.unpack_ODE(spep.model); OPE.OrderedODESystem(spep.model, ms, mp) end
	te, dd, _, _, _, _ = OPE.get_si_equation_system(model, mq, ds; DD = DD, infolevel = 0)
	tdd = OPE.ensure_si_template_dd_support(model, mq, DD, dd)
	data_vars = OPE.extract_data_variables_from_DD(tdd); dset = Set(data_vars)
	# variable sets per equation
	eqvars = [Set(string.(Symbolics.get_variables(eq))) for eq in te]

	println("=== equations each state-derivative unknown appears in ==="); flush(stdout)
	for base in ("L", "Ca", "Cb")
		for k in 0:8
			nm = "$(base)_$k"
			idxs = [i for i in 1:length(te) if nm in eqvars[i]]
			isempty(idxs) && continue
			@printf("   %-6s appears in %d eq(s): %s\n", nm, length(idxs), string(idxs))
		end
	end

	# show the actual equations that constrain L_6 and L_7 (to see they're dynamics, coupling other vars)
	for nm in ("L_5", "L_6", "L_7")
		println("\n=== equations containing $nm ===")
		for (i, eq) in enumerate(te)
			if nm in eqvars[i]
				vs = sort(collect(eqvars[i]))
				@printf("   eq[%d]: vars = %s\n", i, join(vs, ", "))
			end
		end
	end
	println("\n=== done ==="); flush(stdout)
end

main()
