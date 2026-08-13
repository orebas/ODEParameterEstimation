# Which models are IN-REGIME for single-point unpolished UQ? (2026-08-14)
#
# Scope (Oren 2026-08-14): UQ is claimed only where the unpolished single-point
# algebraic read from ONE SE-kernel GPR is itself a good estimator. This screen
# runs exactly that configuration and classifies each (model, noise) cell:
#
#   in_regime      estimator accurate (med rel err <= tol) AND interval
#                  calibrated (med|z| in a loose band around 0.674)
#   marginal       accurate but the interval is mis-scaled
#   out_of_regime  the estimator itself is not accurate here
#
# Coverage alone is NOT the criterion: an interval wide enough to cover
# everything while saying nothing is out-of-regime, and the median relative
# error column is what exposes it.
#
# EXCLUDED: models with observable-preserving symmetries (e.g. two_exp's
# (x1,k1)<->(x2,k2) swap under y = x1+x2). The solver may return an equally
# valid relabelled root, so name-based scoring is meaningless there — probe
# repro/uq_coverage_harness_2026_08/probe_two_exp_labels.jl demonstrates 4/6
# replicates returning the swapped root.
#
# Run: julia --startup-file=no repro/uq_coverage_harness_2026_08/run_regime_screen.jl

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
	(name = "vanderpol", ctor = ODEParameterEstimation.vanderpol, ti = [0.0, 10.0]),
	(name = "fitzhugh_nagumo", ctor = ODEParameterEstimation.fitzhugh_nagumo, ti = [0.0, 0.03]),
	(name = "lotka_volterra", ctor = ODEParameterEstimation.lotka_volterra, ti = [0.0, 20.0]),
]

const NOISES = [1e-4, 1e-2]
const N_REPS = 10

# Optional CLI filter: `julia run_regime_screen.jl simple onesp_cubed`
const SELECTED = isempty(ARGS) ? MODELS : filter(m -> m.name in ARGS, MODELS)
isempty(SELECTED) && error("no models matched $(ARGS); known: $(join([m.name for m in MODELS], ", "))")

results = Tuple{String, Float64, Symbol, Vector{String}}[]

for m in SELECTED, (ni, noise) in enumerate(NOISES)
	println("\n", "═"^72)
	println("MODEL: ", m.name, "   noise = ", noise, "   (N=", N_REPS, ", single SE-GPR, unpolished, single point)")
	println("═"^72)
	t0 = time()
	try
		res = run_coverage(m.ctor;
			N = N_REPS, noise_level = noise, datasize = 121,
			time_interval = m.ti, seed0 = 9000 + 100 * ni,
			estimator = :full_pipeline, extra_opts = SINGLE_SE_GPR_UNPOLISHED)
		print_coverage(res)
		verdict, notes = regime_verdict(res)
		println("VERDICT: ", verdict)
		for n in notes
			println("   • ", n)
		end
		println("wall: ", round(time() - t0; digits = 1), "s")
		push!(results, (m.name, noise, verdict, notes))
	catch e
		println("CELL FAILED after ", round(time() - t0; digits = 1), "s: ", sprint(showerror, e))
		push!(results, (m.name, noise, :error, [sprint(showerror, e)]))
	end
end

println("\n", "═"^72)
println("REGIME SCREEN SUMMARY (single-point, unpolished, single SE-GPR)")
println("═"^72)
println(rpad("model", 30), rpad("noise", 10), "verdict")
for (name, noise, verdict, _) in results
	println(rpad(name, 30), rpad(string(noise), 10), verdict)
end
println("\nREGIME_SCREEN_DONE")
