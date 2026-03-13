"""
Biohydrogenation Example with EstimationOptions

This variant uses a more configurable option preset than the main
biohydrogenation example while still following the current package API.
"""

include("biohydrogenation_example.jl")

function biohydrogenation_options_profile(; smoke = false)
	return EstimationOptions(
		datasize = smoke ? 101 : 1001,
		noise_level = 0.0,
		time_interval = [-1.0, 1.0],
		system_solver = SolverHC,
		ode_solver = AutoVern9(Rodas4P()),
		interpolator = InterpolatorAAADGPR,
		flow = FlowStandard,
		use_si_template = true,
		shooting_points = smoke ? 2 : 8,
		point_hint = 0.5,
		polish_solutions = false,
		polish_solver_solutions = true,
		polish_method = PolishNewtonTrust,
		polish_maxiters = 10,
		opt_maxiters = 10000,
		imag_threshold = 1e-8,
		clustering_threshold = 1e-5,
		max_error_threshold = 0.5,
		verification_threshold = 1e-8,
		use_monodromy = false,
		hc_real_tol = 1e-9,
		hc_show_progress = false,
		max_solutions = 20,
		save_system = false,
		nooutput = smoke,
		diagnostics = !smoke,
		debug_solver = false,
		debug_cas_diagnostics = false,
	)
end

function run_biohydrogenation_example_with_options(; smoke = false, write_csv = false)
	return run_biohydrogenation_example(
		smoke = smoke,
		opts = biohydrogenation_options_profile(smoke = smoke),
		write_csv = write_csv,
		result_filename = "result_with_options.csv",
	)
end

if abspath(PROGRAM_FILE) == @__FILE__
	run_biohydrogenation_example_with_options(write_csv = true)
end
