# What IS SIAN's emitted order? Replicate get_si_equation_system's call to get_polynomial_system_from_sian,
# pull result["full_polynomial_system"] (the pre-trim Et, in SIAN's order) + selected/dropped indices, and
# dump for each equation: index, kept/dropped, total degree (1 = linear data-pin, >1 = nonlinear dynamics),
# max derivative order of its variables, and the variables. Then characterize the order.
using ODEParameterEstimation, Nemo, Printf
const OPE = ODEParameterEstimation

var_order(name) = (m = match(r"_(\d+)$", name); m === nothing ? 0 : parse(Int, m.captures[1]))

function main()
	pep = OPE.receptor_subtype_binding_branch()
	model = pep.model isa OPE.OrderedODESystem ? pep.model : begin (t,meq,ms,mp)=OPE.unpack_ODE(pep.model); OPE.OrderedODESystem(pep.model, ms, mp) end
	mq = pep.measured_quantities
	si_ode, symbol_map, gens = OPE.convert_to_si_ode(model, mq)
	params_to_assess = vcat(si_ode.parameters, si_ode.x_vars)
	result = OPE.get_polynomial_system_from_sian(si_ode, params_to_assess; p = 0.99, infolevel = 0)

	Et = result["full_polynomial_system"]
	sel = Set(result["selected_equation_indices"])
	@printf("=== SIAN emitted Et: %d equations, %d selected, %d dropped ===\n",
		length(Et), length(sel), length(Et) - length(sel)); flush(stdout)
	@printf("%-4s %-5s %-4s %-7s  %s\n", "idx", "keep", "deg", "maxord", "variables (sorted)")
	println(repeat("-", 110))
	for (i, eq) in enumerate(Et)
		vs = Nemo.vars(eq); names = sort(string.(vs))
		deg = Nemo.total_degree(eq)
		maxord = isempty(names) ? 0 : maximum(var_order(n) for n in names)
		kept = i in sel ? "KEEP" : "drop"
		@printf("%-4d %-5s %-4d %-7d  %s\n", i, kept, deg, maxord, join(names, ", ")); flush(stdout)
	end

	println("\n=== characterizing the order ===")
	degs   = [Nemo.total_degree(eq) for eq in Et]
	maxords = [(vs = Nemo.vars(eq); isempty(vs) ? 0 : maximum(var_order(string(v)) for v in vs)) for eq in Et]
	@printf("max-derivative-order by Et index: %s\n", maxords)
	@printf("total-degree by Et index:         %s\n", degs)
	deg1 = [i for i in 1:length(Et) if degs[i] == 1]
	@printf("degree-1 (linear/pin) eqs at indices: %s\n", deg1)
	@printf("   of those KEPT:    %s\n", filter(in(sel), deg1))
	@printf("   of those DROPPED: %s\n", filter(!in(sel), deg1))
	@printf("is max-order monotonically non-decreasing in Et index? %s\n", issorted(maxords))
	println("=== done ==="); flush(stdout)
end

main()
