# Per-model NOISE THRESHOLD for single-point unpolished UQ (2026-08-14).
#
# The 2026-08-14 regime screen showed the deliverable is not a list of models
# but a per-model noise ceiling: at 1e-4 the single-point IFT UQ is genuinely
# calibrated on small systems (med|z| 0.5-0.9 vs the standard-normal 0.674,
# p90|z| 1.0-1.7 vs 1.64, σ̂ matching the realized error), and it degrades
# OVERCONFIDENTLY as noise grows (σ̂ 2-3x too small, coverage 50-70% at 1e-2).
# That is the first-order delta method failing as the data perturbation grows
# — the documented curvature/second-order limitation, now quantified.
#
# This sweep finds, for each model, the largest noise level at which every
# coordinate is still calibrated.
#
# Run: julia --startup-file=no repro/uq_coverage_harness_2026_08/run_noise_threshold.jl [model ...]

using ODEParameterEstimation
using Statistics
include(joinpath(@__DIR__, "coverage_driver.jl"))

const SINGLE_SE_GPR_UNPOLISHED = (
	interpolator = InterpolatorAGPUQ,
	interpolators = InterpolatorMethod[],
	polish_solutions = false,
	polish_solver_solutions = false,
	use_multipoint = false,
	shooting_points = 0,
)

const MODELS = [
	(name = "simple", ctor = () -> ODEParameterEstimation.simple(), ti = [0.0, 1.0]),
	(name = "simple_linear_combination", ctor = () -> ODEParameterEstimation.simple_linear_combination(), ti = [0.0, 1.0]),
	(name = "onesp_cubed", ctor = () -> ODEParameterEstimation.onesp_cubed(), ti = [0.0, 1.0]),
	(name = "threesp_cubed", ctor = () -> ODEParameterEstimation.threesp_cubed(), ti = [0.0, 1.0]),
]

const NOISES = [1e-6, 1e-5, 1e-4, 1e-3, 1e-2]
const N_REPS = 10

const SELECTED = isempty(ARGS) ? MODELS : filter(m -> m.name in ARGS, MODELS)
isempty(SELECTED) && error("no models matched $(ARGS)")

grid = Dict{String, Vector{Tuple{Float64, Symbol}}}()

for m in SELECTED
	cells = Tuple{Float64, Symbol}[]
	for (ni, noise) in enumerate(NOISES)
		print(rpad(m.name, 28), rpad(string(noise), 9))
		t0 = time()
		verdict = try
			res = run_coverage(m.ctor;
				N = N_REPS, noise_level = noise, datasize = 121,
				time_interval = m.ti, seed0 = 9500 + 100 * ni,
				estimator = :full_pipeline, extra_opts = SINGLE_SE_GPR_UNPOLISHED)
			v, notes = regime_verdict(res)
			medz = [round(median(abs.(get(res.zs, l, [NaN]))); sigdigits = 2) for l in res.labels]
			relerr = maximum([isempty(get(res.rel_errs, l, Float64[])) ? NaN :
							  median(res.rel_errs[l]) for l in res.labels])
			println(rpad(string(v), 16), "med|z| = ", medz,
				"   worst relerr = ", round(100 * relerr; sigdigits = 3), "%",
				"   (", round(time() - t0; digits = 1), "s)")
			v
		catch e
			println("ERROR: ", sprint(showerror, e))
			:error
		end
		push!(cells, (noise, verdict))
	end
	grid[m.name] = cells
end

println("\n", "═"^72)
println("NOISE-THRESHOLD GRID (single-point, unpolished, single SE-GPR)")
println("═"^72)
println(rpad("model", 28), join([rpad(string(n), 11) for n in NOISES]))
for m in SELECTED
	cells = grid[m.name]
	println(rpad(m.name, 28), join([rpad(string(v), 11) for (_, v) in cells]))
end
println("\nthreshold = largest noise with verdict in_regime")
for m in SELECTED
	ok = [n for (n, v) in grid[m.name] if v === :in_regime]
	println("  ", rpad(m.name, 28), isempty(ok) ? "none" : string(maximum(ok)))
end
println("\nNOISE_THRESHOLD_DONE")
