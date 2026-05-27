# End-to-end sweep: does data-driven column scaling (EstimationOptions.use_column_scaling) help the
# HC solve LAND the truth basin on hard systems, and stay benign on easy ones?
#
# Design choices for a clean, fast solver A/B (see notes):
#   * polish OFF  -> compare the RAW HC parameter estimates to truth (the thing column scaling
#                    actually affects); avoids slow per-candidate ODE polish that also masks/confounds.
#   * multipoint OFF -> isolate the parameterized single-point HC path (where scaling lives) and halve work.
#   * shooting_points=6 -> >=3 for the parameter-homotopy path, fewer solves.
#   * interpolator fixed to AAAD, auto-filter off -> the ONLY variable between off/on is column scaling.
# Metric: min over candidates of oracle_error_stats(.).maximum  (best basin's worst-component rel error).
#
# Run:  julia --startup-file=no repro/column_scaling_impl_2026_05_26/run_sweep.jl
using ODEParameterEstimation, Printf, Statistics
const OPE = ODEParameterEstimation
include(joinpath(@__DIR__, "..", "..", "src", "examples", "load_examples.jl"))
const OUTCSV = joinpath(@__DIR__, "results.csv")

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
		polish_solver_solutions = false,
		polish_solutions = false,
		nooutput = true,
		diagnostics = false,
	)
end

# Returns (n_candidates, best_max_relerr, best_median_relerr, wall_s).
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

function logrow(io, sym, noise, cs, r)
	@printf(io, "%s,%g,%s,%d,%.3e,%.3e,%.1f\n", sym, noise, cs, r.n, r.best_max, r.best_med, r.wall)
end

function main()
	open(OUTCSV, "w") do io
		println(io, "system,noise,use_column_scaling,n_candidates,best_max_relerr,best_median_relerr,wall_s")
	end
	@printf("%-16s %-8s | %-24s | %-24s\n", "system", "noise", "OFF  bmax  bmed  s", "ON   bmax  bmed  s"); flush(stdout)
	println(repeat("-", 84)); flush(stdout)

	# core matrix at noise=0 (clean solver signal); + biohydrogenation at noise=1e-8.
	cells = [(:biohydrogenation, 0.0), (:daisy_mamil4, 0.0), (:lotka_volterra, 0.0), (:simple, 0.0),
			 (:biohydrogenation, 1e-8)]
	for (sym, noise) in cells
		res = Dict{Bool, NamedTuple}()
		for cs in (false, true)
			r = try run_cell(sym, noise, cs) catch e
				println("   [ERROR] $sym noise=$noise cs=$cs: ", sprint(showerror, e)[1:min(120, end)]); flush(stdout)
				(n = 0, best_max = NaN, best_med = NaN, wall = NaN)
			end
			res[cs] = r
			open(OUTCSV, "a") do io; logrow(io, sym, noise, cs, r) end
		end
		o = res[false]; n = res[true]
		@printf("%-16s %-8g | %8.2e %8.2e %4.0f | %8.2e %8.2e %4.0f\n",
			sym, noise, o.best_max, o.best_med, o.wall, n.best_max, n.best_med, n.wall); flush(stdout)
	end

	# biohydrogenation seed-fraction at noise=0 (only HC's internal seed varies run-to-run)
	println("\n=== biohydrogenation seed-fraction @ noise=0 (recovered if best_max < 1e-3) ==="); flush(stdout)
	for cs in (false, true)
		nrec = 0; nrep = 4; maxes = Float64[]
		for rep in 1:nrep
			r = try run_cell(:biohydrogenation, 0.0, cs) catch; (n=0,best_max=NaN,best_med=NaN,wall=NaN) end
			push!(maxes, r.best_max)
			(isfinite(r.best_max) && r.best_max < 1e-3) && (nrec += 1)
			@printf("   cs=%-5s rep=%d best_max=%.2e (%.0fs)\n", cs, rep, r.best_max, r.wall); flush(stdout)
		end
		@printf(">>> biohydrogenation cs=%-5s: recovered %d/%d; maxes=%s\n", cs, nrec, nrep, string(round.(maxes, sigdigits=2))); flush(stdout)
	end

	println("\nWrote ", OUTCSV)
end

main()
