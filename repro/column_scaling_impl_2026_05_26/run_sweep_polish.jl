# Wave 2 — production-realistic complement to run_sweep.jl: hard systems with POLISH ON, off vs on.
# Measures the DELIVERED (polished) recovery, vs run_sweep.jl which measures raw-HC basin reach.
# Kept tractable with use_multipoint=false + shooting_points=6 (the 22-min/cell pre-crash run had
# multipoint ON + 12 points). Writes results_polish.csv.
#
# Run:  julia --startup-file=no repro/column_scaling_impl_2026_05_26/run_sweep_polish.jl
using ODEParameterEstimation, Printf, Statistics
const OPE = ODEParameterEstimation
include(joinpath(@__DIR__, "..", "..", "src", "examples", "load_examples.jl"))
const OUTCSV = joinpath(@__DIR__, "results_polish.csv")

function mkopts(noise, cs)
	EstimationOptions(
		datasize = 201,
		noise_level = noise,
		system_solver = SolverHC,
		flow = FlowStandard,
		interpolator = InterpolatorAAAD,
		auto_filter_interpolators = false,
		use_si_template = true,
		use_parameter_homotopy = true,
		use_multipoint = false,
		use_column_scaling = cs,
		shooting_points = 6,
		polish_solver_solutions = true,   # PRODUCTION-realistic: refine HC candidates
		polish_solutions = false,
		nooutput = true,
		diagnostics = false,
	)
end

function run_cell(sym, noise, cs)
	pep = ALL_MODELS[sym]()
	opts = mkopts(noise, cs)
	sampled = sample_problem_data(pep, opts)
	t0 = time()
	res, _a, _u = analyze_parameter_estimation_problem(sampled, opts)
	wall = time() - t0
	candidates = res[1]   # results_tuple = (solved_res, unident, trivial, all_unident); [1] = candidate vector
	best_max = Inf; best_med = Inf
	for c in candidates
		s = try OPE.oracle_error_stats(sampled, c) catch; nothing end
		s === nothing && continue
		if s.maximum < best_max
			best_max = s.maximum; best_med = s.median
		end
	end
	return (n = length(candidates), best_max = isfinite(best_max) ? best_max : NaN,
		best_med = isfinite(best_med) ? best_med : NaN, wall = wall)
end

function main()
	open(OUTCSV, "w") do io
		println(io, "system,noise,use_column_scaling,n_candidates,best_max_relerr,best_median_relerr,wall_s")
	end
	@printf("%-16s %-8s | %-24s | %-24s\n", "system(POLISH)", "noise", "OFF  bmax  bmed  s", "ON   bmax  bmed  s"); flush(stdout)
	println(repeat("-", 84)); flush(stdout)
	cells = [(:biohydrogenation, 0.0), (:daisy_mamil4, 0.0), (:slowfast, 0.0), (:biohydrogenation, 1e-8)]
	for (sym, noise) in cells
		res = Dict{Bool, NamedTuple}()
		for cs in (false, true)
			r = try run_cell(sym, noise, cs) catch e
				println("   [ERROR] $sym noise=$noise cs=$cs: ", sprint(showerror, e)[1:min(120, end)]); flush(stdout)
				(n = 0, best_max = NaN, best_med = NaN, wall = NaN)
			end
			res[cs] = r
			open(OUTCSV, "a") do io
				@printf(io, "%s,%g,%s,%d,%.3e,%.3e,%.1f\n", sym, noise, cs, r.n, r.best_max, r.best_med, r.wall)
			end
		end
		o = res[false]; n = res[true]
		@printf("%-16s %-8g | %8.2e %8.2e %4.0f | %8.2e %8.2e %4.0f\n",
			sym, noise, o.best_max, o.best_med, o.wall, n.best_max, n.best_med, n.wall); flush(stdout)
	end
	println("\nWrote ", OUTCSV)
end

main()
