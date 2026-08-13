# High-N calibration confirmation (2026-08-14).
#
# WHY: the N=10 screens could not resolve calibration. For N replicates the
# sampling sd of median|z| is ~ 1/(2 f(0.674) sqrt(N)) = 0.787/sqrt(N)
# (f = density of |z| at its median). At N=10 that is 0.25, so a perfectly
# calibrated coordinate lands anywhere in ~[0.17, 1.17] at 2 sigma — and with
# 4-6 coordinates per cell, a quarter of cells get flagged "marginal" purely by
# chance. An earlier N=10 cell reading med|z| = 1.46 was re-run at different
# seeds as 0.65; the apparent "overconfident degradation with noise" was seed
# noise, not signal.
#
# At N=60 the sd falls to ~0.10, which distinguishes calibrated (0.674) from
# 1.5x-overconfident (1.0) at about 3 sigma.
#
# Run: julia --startup-file=no repro/uq_coverage_harness_2026_08/run_calibration_confirm.jl

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

const N_REPS = 60
const MED_Z_SE = 0.787 / sqrt(N_REPS)   # sampling sd of median|z| at this N

# Cells chosen to test the three claims that the N=10 data could not settle:
#   simple @1e-4 / @1e-2  — is there ANY noise degradation?
#   onesp_cubed @1e-5     — is the low-noise conservatism real?
const CELLS = [
	(name = "simple", ctor = () -> ODEParameterEstimation.simple(), ti = [0.0, 1.0], noise = 1e-4, seed0 = 20000),
	(name = "simple", ctor = () -> ODEParameterEstimation.simple(), ti = [0.0, 1.0], noise = 1e-2, seed0 = 21000),
	(name = "onesp_cubed", ctor = () -> ODEParameterEstimation.onesp_cubed(), ti = [0.0, 1.0], noise = 1e-5, seed0 = 22000),
]

println("N = ", N_REPS, "   sampling sd of median|z| ≈ ", round(MED_Z_SE; digits = 3),
	"   (calibrated target = 0.674)")

for c in CELLS
	println("\n", "═"^72)
	println("CELL: ", c.name, " @ noise = ", c.noise, "   (N=", N_REPS, ")")
	println("═"^72)
	t0 = time()
	try
		res = run_coverage(c.ctor;
			N = N_REPS, noise_level = c.noise, datasize = 121,
			time_interval = c.ti, seed0 = c.seed0,
			estimator = :full_pipeline, extra_opts = SINGLE_SE_GPR_UNPOLISHED)
		print_coverage(res)
		println("\nper-coordinate calibration (med|z| vs 0.674 ± ", round(2 * MED_Z_SE; digits = 2), " at 2σ):")
		for l in res.labels
			az = abs.(get(res.zs, l, Float64[]))
			isempty(az) && continue
			m = median(az)
			dev = (m - 0.674) / MED_Z_SE
			tag = abs(dev) <= 2 ? "calibrated" : (m > 0.674 ? "OVERCONFIDENT" : "conservative")
			println("   ", rpad(l, 12), "med|z| = ", rpad(round(m; sigdigits = 3), 8),
				"(", round(dev; digits = 1), "σ)  ", tag)
		end
		v, notes = regime_verdict(res)
		println("verdict: ", v, "   ", join(notes, "; "))
		println("wall: ", round(time() - t0; digits = 1), "s")
	catch e
		println("CELL FAILED: ", sprint(showerror, e))
	end
end
println("\nCALIBRATION_CONFIRM_DONE")
