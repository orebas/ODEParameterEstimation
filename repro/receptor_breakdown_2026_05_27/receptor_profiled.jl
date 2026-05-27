# Real per-phase timing for receptor (no guessing): profile_phases=true makes the pipeline print
# _print_phase_profile at the end — Setup / SI Template / Equation construction + Solving / Result
# processing / Synthesize aggregates / Branch completion. cs=true (production default), one rep.
using ODEParameterEstimation, Printf
const OPE = ODEParameterEstimation
const TRUTH = Dict("R1tot"=>1.10,"R2tot"=>0.70,"kon1"=>0.80,"kon2"=>1.30,"koff1"=>0.40,"koff2"=>0.60)
const SWAP  = Dict("R1tot"=>0.70,"R2tot"=>1.10,"kon1"=>1.30,"kon2"=>0.80,"koff1"=>0.60,"koff2"=>0.40)
relerr_vs(c, ref) = (e = Float64[]; for (k,v) in c.parameters; nm=string(k); haskey(ref,nm) && push!(e, abs(v-ref[nm])/max(abs(ref[nm]),1e-9)); end; isempty(e) ? Inf : maximum(e))
best_vs(raw, ref) = isempty(raw) ? Inf : minimum(relerr_vs(c, ref) for c in raw)

function main()
	pep = OPE.receptor_subtype_binding_branch()
	opts = EstimationOptions(datasize = 201, noise_level = 0.0, system_solver = SolverHC, flow = FlowStandard,
		interpolator = InterpolatorAAAD, auto_filter_interpolators = false, use_si_template = true,
		use_parameter_homotopy = true, use_multipoint = false, use_column_scaling = true,
		shooting_points = 3, polish_solver_solutions = false, polish_solutions = false,
		profile_phases = true, nooutput = true, diagnostics = false)
	sampled = sample_problem_data(pep, opts)
	t0 = time()
	res, _, _ = analyze_parameter_estimation_problem(sampled, opts)
	wall = time() - t0
	raw = res[1]
	@printf(">>> receptor profiled: n=%d truth=%.3e swap=%.3e wall=%.0fs\n", length(raw), best_vs(raw,TRUTH), best_vs(raw,SWAP), wall)
end

main()
