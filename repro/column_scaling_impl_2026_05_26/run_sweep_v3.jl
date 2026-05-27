# Controlled column-scaling test (fixes the v2 confound). For each (system, noise):
#   * sample data ONCE (fixed seed) and run BOTH off and on on the SAME data (deepcopy per run),
#     so the only systematic off-vs-on difference is column scaling — NOT the noise realization.
#   * run NREP reps per setting (HC draws a fresh internal seed each solve) and compare the
#     DISTRIBUTIONS (median, min of best_max) so HC-seed variance is averaged out.
# Answers: does column scaling actually help under noise on hard systems, above seed/noise variance?
#
# Run:  julia --startup-file=no repro/column_scaling_impl_2026_05_26/run_sweep_v3.jl
using ODEParameterEstimation, Printf, Statistics, Random
const OPE = ODEParameterEstimation
include(joinpath(@__DIR__, "..", "..", "src", "examples", "load_examples.jl"))
const OUT = joinpath(@__DIR__, "results_v3.csv")

mkopts(noise, cs) = EstimationOptions(
	datasize = 201, noise_level = noise, system_solver = SolverHC, flow = FlowStandard,
	interpolator = InterpolatorAAAD, auto_filter_interpolators = false, use_si_template = true,
	use_parameter_homotopy = true, use_multipoint = false, use_column_scaling = cs,
	shooting_points = 6, polish_solver_solutions = false, polish_solutions = false,
	nooutput = true, diagnostics = false)

function bestmax(sampled, opts)
	res, _, _ = analyze_parameter_estimation_problem(deepcopy(sampled), opts)
	b = Inf
	for c in res[1]
		s = try OPE.oracle_error_stats(sampled, c) catch; nothing end
		s === nothing && continue
		b = min(b, s.maximum)
	end
	return isfinite(b) ? b : NaN
end

function cell(sym, noise; nrep = 3, dataseed = 20260526)
	pep = ALL_MODELS[sym]()
	Random.seed!(dataseed)
	sampled = sample_problem_data(pep, mkopts(noise, false))   # ONE shared data realization
	res = Dict{Bool, Vector{Float64}}()
	for cs in (false, true)
		bs = Float64[]
		for rep in 1:nrep
			b = try bestmax(sampled, mkopts(noise, cs)) catch e; (println("   [err] $sym $noise $cs rep$rep: ", sprint(showerror,e)[1:min(90,end)]); NaN) end
			push!(bs, b)
			@printf("   %-15s noise=%g cs=%-5s rep=%d best_max=%.3e\n", sym, noise, cs, rep, b); flush(stdout)
		end
		res[cs] = bs
	end
	f(v) = (w = filter(isfinite, v); isempty(w) ? NaN : w)
	mo, mn = f(res[false]), f(res[true])
	medoff = mo isa Float64 ? NaN : median(mo); minoff = mo isa Float64 ? NaN : minimum(mo)
	medon  = mn isa Float64 ? NaN : median(mn); minon  = mn isa Float64 ? NaN : minimum(mn)
	@printf(">>> %-15s noise=%g | OFF med=%.2e min=%.2e | ON med=%.2e min=%.2e\n",
		sym, noise, medoff, minoff, medon, minon); flush(stdout)
	open(OUT, "a") do io
		@printf(io, "%s,%g,%.3e,%.3e,%.3e,%.3e\n", sym, noise, medoff, minoff, medon, minon)
	end
end

function main()
	open(OUT, "w") do io; println(io, "system,noise,off_med,off_min,on_med,on_min") end
	println("=== CONTROLLED column-scaling sweep (same data per cell; reps vary HC seed) ==="); flush(stdout)
	cell(:biohydrogenation, 1e-8; nrep = 4)
	cell(:biohydrogenation, 1e-6; nrep = 3)
	cell(:daisy_mamil4,     1e-8; nrep = 3)
	cell(:lotka_volterra,   1e-8; nrep = 2)
	println("\nwrote ", OUT)
end

main()
