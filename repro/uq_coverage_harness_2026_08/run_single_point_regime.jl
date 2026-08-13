# Is the UQ calibrated for the estimator it actually describes? (2026-08-14)
#
# Σ_x is the sampling covariance of ONE specific estimator: the single-point
# algebraic solve conditioned on ONE SE-kernel GP fit, unpolished. Every
# coverage number measured so far compared it against a DIFFERENT estimator
# (NLS trajectory fit in the harness; polish in production), which is why
# LV looked vacuous — σ̂ ~ 1e4 wider than a polished estimator's error.
#
# This driver runs the real pipeline restricted to the UQ's own estimand:
#   • one SE-kernel GPR interpolant (InterpolatorAGPUQ), no pool
#   • no polish (polish_solutions / polish_solver_solutions off)
#   • no multipoint
# and compares against the same configuration WITH polish. Prediction: the
# unpolished arm is calibrated (z ~ O(1)) even where σ̂ is large, and the
# polished arm is over-wide (|z| ≈ 0) — the wide interval being CORRECT for
# the estimator it describes, not a defect.
#
# Run: julia --startup-file=no repro/uq_coverage_harness_2026_08/run_single_point_regime.jl

using ODEParameterEstimation
using Statistics
include(joinpath(@__DIR__, "coverage_driver.jl"))

const UNPOLISHED = (
	interpolator = InterpolatorAGPUQ,
	interpolators = InterpolatorMethod[],
	polish_solutions = false,
	polish_solver_solutions = false,
	use_multipoint = false,
	shooting_points = 0,
)
const POLISHED = (
	interpolator = InterpolatorAGPUQ,
	interpolators = InterpolatorMethod[],
	polish_solutions = true,
	polish_solver_solutions = true,
	use_multipoint = false,
	shooting_points = 0,
)

const CASES = [
	(name = "two_exp", ctor = two_exp_pep, ti = [0.0, 1.0], seed0 = 8100),
	(name = "simple", ctor = () -> ODEParameterEstimation.simple(), ti = [0.0, 1.0], seed0 = 8200),
	(name = "vanderpol", ctor = ODEParameterEstimation.vanderpol, ti = [0.0, 10.0], seed0 = 8300),
	(name = "lotka_volterra", ctor = ODEParameterEstimation.lotka_volterra, ti = [0.0, 20.0], seed0 = 8400),
]

const N_REPS = 10

function arm(case, label, extra)
	println("\n── ", case.name, " / ", label, " ──")
	t0 = time()
	try
		res = run_coverage(case.ctor;
			N = N_REPS, noise_level = 0.01, datasize = 121,
			time_interval = case.ti, seed0 = case.seed0,
			estimator = :full_pipeline, extra_opts = extra)
		print_coverage(res)
		nrep = count(s -> !(s in (:no_report, :no_estimate, :no_physicalization)), res.statuses)
		println("reported: ", nrep, "/", N_REPS, "   statuses: ", res.statuses)
		println("wall: ", round(time() - t0; digits = 1), "s")
	catch e
		println("ARM FAILED after ", round(time() - t0; digits = 1), "s: ", sprint(showerror, e))
	end
end

for case in CASES
	println("\n", "═"^72)
	println("MODEL: ", case.name, "   (N=", N_REPS, ", 1% noise, single SE-GPR, single point)")
	println("═"^72)
	arm(case, "UNPOLISHED (the UQ's own estimand)", UNPOLISHED)
	arm(case, "POLISHED (different estimator)", POLISHED)
end
println("\nSINGLE_POINT_REGIME_DONE")
