# Nonlinear mid-tier validation of estimate-conditioned UQ (2026-08-13).
# Oren: "a few of the models, from the benchmark, on which most things
# succeeded, but which are nonlinear and 'a little harder'."
#
# Models: lotka_volterra (3 params, predator LATENT — only prey observed),
# vanderpol (2 params, both states observed), fitzhugh_nagumo (3 params,
# only V observed; benchmark 30ms window). N=20 replicates each at 1%
# additive noise, estimate-conditioned S, NLS-polish stand-in estimator.
#
# Run: julia --startup-file=no repro/uq_coverage_harness_2026_08/run_nonlinear_validation.jl

using ODEParameterEstimation
include(joinpath(@__DIR__, "coverage_driver.jl"))

const CASES = [
	(name = "lotka_volterra", ctor = ODEParameterEstimation.lotka_volterra,
		time_interval = [0.0, 20.0], seed0 = 7100),
	(name = "vanderpol", ctor = ODEParameterEstimation.vanderpol,
		time_interval = [0.0, 10.0], seed0 = 7200),
	(name = "fitzhugh_nagumo", ctor = ODEParameterEstimation.fitzhugh_nagumo,
		time_interval = [0.0, 0.03], seed0 = 7300),
]

for case in CASES
	println("\n", "═"^70)
	println("MODEL: ", case.name, "  (interval ", case.time_interval, ", N=20, 1% noise)")
	println("═"^70)
	t0 = time()
	try
		res = run_coverage(case.ctor;
			N = 20, noise_level = 0.01, datasize = 121,
			time_interval = case.time_interval, seed0 = case.seed0)
		print_coverage(res)
		println("statuses: ", res.statuses)
		println("wall_seconds: ", round(time() - t0; digits = 1))
	catch e
		println("MODEL-LEVEL FAILURE after ", round(time() - t0; digits = 1), "s:")
		showerror(stdout, e, catch_backtrace())
		println()
	end
end
println("\nNONLINEAR_VALIDATION_DONE")
