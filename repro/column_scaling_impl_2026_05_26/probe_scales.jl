# Fast engagement probe (NO HC solve): build each system's SI template, evaluate the observable
# jet at several time points, and call compute_column_scales to see whether the scales are
# non-trivial (>1) or all floored to 1.0. Settles whether column scaling can do anything at all
# on bioh/daisy vs the receptor case where it provably engaged.
using ODEParameterEstimation, Symbolics, Statistics, Printf
const OPE = ODEParameterEstimation
include(joinpath(@__DIR__, "..", "..", "src", "examples", "load_examples.jl"))

function probe(name, modelfn)
	try
		pep = modelfn()
		opts = EstimationOptions(datasize = 201, noise_level = 0.0, use_si_template = true, nooutput = true)
		spep = sample_problem_data(pep, opts)
		setup = OPE.setup_parameter_estimation(spep; interpolator = OPE.aaad, nooutput = true)
		DD = setup.good_DD; mq = spep.measured_quantities; ds = spep.data_sample; tvec = ds["t"]
		model = spep.model
		omodel = model isa OPE.OrderedODESystem ? model : begin (t,meq,ms,mp)=OPE.unpack_ODE(model); OPE.OrderedODESystem(model,ms,mp) end
		te, dd, _, _, _, meta = OPE.get_si_equation_system(omodel, mq, ds; DD = DD, infolevel = 0)
		tdd = OPE.ensure_si_template_dd_support(omodel, mq, DD, dd)
		data_vars = OPE.extract_data_variables_from_DD(tdd); dset = Set(data_vars)
		allv = []; seen = Set(); for eq in te, v in Symbolics.get_variables(eq); if !(v in seen); push!(allv, v); push!(seen, v); end; end
		solve_vars = [v for v in allv if !(v in dset)]
		interps = OPE.create_interpolants(mq, ds, tvec, OPE.aaad)
		ts = collect(range(first(tvec), last(tvec), length = 8))[2:7]
		pvl = [OPE.evaluate_data_vars_at_point(interps, data_vars, tdd, mq, Float64(t)) for t in ts]
		scales = OPE.compute_column_scales(solve_vars, data_vars, pvl)
		# per-order max |observable derivative| across the probe points
		omg = Dict{Int,Float64}()
		for (j, dv) in enumerate(data_vars)
			m = match(r"Differential\(t,\s*(\d+)\)", string(dv)); k = isnothing(m) ? 0 : parse(Int, m.captures[1])
			for pv in pvl; j <= length(pv) && isfinite(pv[j]) && (omg[k] = max(get(omg,k,0.0), abs(pv[j]))); end
		end
		@printf("[%-16s] solve_vars=%d data_vars=%d | SCALE range=(%.2e,%.2e) nontrivial(>1)=%d/%d\n",
			name, length(solve_vars), length(data_vars), minimum(scales), maximum(scales), count(>(1.0), scales), length(scales))
		print("    obs |deriv| by order: "); for k in sort(collect(keys(omg))); @printf("o%d:%.1e ", k, omg[k]); end; println(); flush(stdout)
	catch e
		println("[$name] PROBE ERROR: ", sprint(showerror, e)[1:min(160,end)]); flush(stdout)
	end
end

function main()
	println("=== column-scale engagement probe (no HC solve) ==="); flush(stdout)
	probe("biohydrogenation", () -> ALL_MODELS[:biohydrogenation]())
	probe("daisy_mamil4", () -> ALL_MODELS[:daisy_mamil4]())
	probe("lotka_volterra", () -> ALL_MODELS[:lotka_volterra]())
	probe("receptor", () -> OPE.receptor_subtype_binding_branch())
	println("=== done ==="); flush(stdout)
end

main()
