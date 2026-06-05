# Pull the concrete facts needed for the receptor reference doc: the actual sampled time grid +
# shooting points (resolve [0,8] vs [-0.5,0.5]), the data/solve variables, and the actual trimmed
# SIAN polynomial equations as strings (low-order ones are readable; shows the pin + dynamics structure).
using ODEParameterEstimation, Symbolics, Printf
const OPE = ODEParameterEstimation

function main()
	pep = OPE.receptor_subtype_binding_branch()
	println("p_true: ", pep.p_true)
	println("ic_true: ", pep.ic)
	opts = EstimationOptions(datasize = 201, noise_level = 0.0, use_si_template = true, nooutput = true)
	spep = sample_problem_data(pep, opts)
	t = spep.data_sample["t"]
	@printf("\nsampled data t: %.4f .. %.4f   (n=%d, dt=%.4f)\n", first(t), last(t), length(t), t[2] - t[1])
	idx = OPE.compute_shooting_indices(3, length(t); warp = true, beta = 3.0)
	@printf("shooting indices %s → t = %s\n", idx, [round(t[i], digits = 4) for i in idx]); flush(stdout)

	s = OPE.setup_parameter_estimation(spep; interpolator = OPE.aaad, nooutput = true)
	DD = s.good_DD; mq = spep.measured_quantities; ds = spep.data_sample
	model = spep.model isa OPE.OrderedODESystem ? spep.model : begin (t2,meq,ms,mp)=OPE.unpack_ODE(spep.model); OPE.OrderedODESystem(spep.model, ms, mp) end
	te, dd, _, _, _, _ = OPE.get_si_equation_system(model, mq, ds; DD = DD, infolevel = 0)
	println("\n=== trimmed SIAN template: $(length(te)) equations (strings) ===")
	for (i, eq) in enumerate(te)
		str = string(eq)
		println("eq[$i]: ", length(str) > 240 ? str[1:240] * " …" : str)
	end
	println("\n(measured_quantities: ", mq, ")")
end
main()
