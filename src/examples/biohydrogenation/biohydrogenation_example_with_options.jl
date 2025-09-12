"""
Biohydrogenation Example with EstimationOptions

This example demonstrates parameter estimation for a biohydrogenation model
with 4 states, 6 parameters, and 2 observables using the new EstimationOptions structure.

The model represents a biochemical reaction system with Michaelis-Menten kinetics.
"""

using ODEParameterEstimation
using ModelingToolkit, DifferentialEquations
using OrderedCollections
using ModelingToolkit: t_nounits as t, D_nounits as D
using CSV
using ParameterEstimation


name = "biohydrogenation"
parameters = @parameters k5 k6 k7 k8 k9 k10
states = @variables x4(t) x5(t) x6(t) x7(t)
observables = @variables y1(t) y2(t)
state_equations = [
	D(x4) ~ - k5 * x4 / (k6 + x4),
	D(x5) ~ k5 * x4 / (k6 + x4) - k7 * x5/(k8 + x5 + x6),
	D(x6) ~ k7 * x5 / (k8 + x5 + x6) - k9 * x6 * (k10 - x6) / k10,
	D(x7) ~ k9 * x6 * (k10 - x6) / k10,
]
measured_quantities = [
	y1 ~ x4,
	y2 ~ x5,
]
ic = [0.45, 0.813, 0.871, 0.407]
p_true = [0.539, 0.672, 0.582, 0.536, 0.439, 0.617]

time_interval = [-1.0, 1.0]

model, mq = create_ordered_ode_system(
	name,
	states,
	parameters,
	state_equations,
	measured_quantities,
)

data_sample = Dict(vcat("t", map(x -> x.rhs, measured_quantities)) .=> CSV.read(joinpath(@__DIR__, "data.csv"), Tuple, header = false))

pep = ParameterEstimationProblem(
	name,
	model,
	mq,
	data_sample,
	time_interval,
	nothing,
	OrderedDict(parameters .=> p_true),
	OrderedDict(states .=> ic),
	0,
)

# Create EstimationOptions with desired settings
# You can customize these options based on your needs
opts = EstimationOptions(
	# Data and sampling parameters
	datasize = 1001,  # Number of data points (from original example)
	noise_level = 0.0,  # No noise for this example
	time_interval = time_interval,  # Use the specified time interval

	# Solver selection
	system_solver = SolverHC,  # Use HomotopyContinuation (as in original)
	ode_solver = AutoVern9(Rodas4P()),  # Default ODE solver
	interpolator = InterpolatorAAADGPR,  # Default interpolator (AAAD with GPR pivot)

	# Numerical tolerances
	abstol = 1e-14,
	reltol = 1e-14,
	rtol = 1e-12,

	# Solution filtering and validation
	imag_threshold = 1e-8,
	clustering_threshold = 1e-5,
	max_error_threshold = 0.5,
	verification_threshold = 1e-8,

	# Multi-point parameters
	max_num_points = 1,  # Single point estimation
	shooting_points = 8,  # Default shooting points
	point_hint = 0.5,  # Midpoint

	# Optimization parameters
	polish_solutions = false,
	polish_solver_solutions = true,  # Polish raw solver solutions
	polish_method = PolishNewtonTrust,
	polish_maxiters = 10,
	opt_maxiters = 10000,

	# Debug and output flags
	nooutput = false,  # Show output
	diagnostics = true,  # Enable diagnostics
	debug_solver = false,
	debug_cas_diagnostics = false,

	# Feature flags
	flow = FlowStandard,  # Use optimized workflow
	use_si_template = true,  # Use StructuralIdentifiability templates
	try_more_methods = true,  # Try additional methods on failure
	save_system = true,  # Save polynomial systems
	display_system = false,

	# HomotopyContinuation specific
	use_monodromy = false,
	hc_real_tol = 1e-9,
	hc_show_progress = false,

	# Solution limits
	max_solutions = 20,
)

# Alternative option configurations you might want to try:


println("\n" * "="^60)
println("Running Biohydrogenation Example with EstimationOptions")
println("="^60 * "\n")

# Run the analysis with the selected options
meta, results = analyze_parameter_estimation_problem(
	pep,
	opts,  # Use the main opts, or replace with opts_fast, opts_accurate, or opts_noisy
)

# Extract results
(solutions_vector, besterror,
	best_min_error,
	best_mean_error,
	best_median_error,
	best_max_error,
	best_approximation_error,
	best_rms_error) = results

# Create results table
table = merge(
	Dict((string(x) => [each.states[x] for each in solutions_vector] for x in states)),
	Dict((string(x) => [each.parameters[x] for each in solutions_vector] for x in parameters)),
)

# Save results to CSV
result_file = joinpath(@__DIR__, "result_with_options.csv")
CSV.write(result_file, table, header = string.(collect(keys(table))))

println("\n" * "="^60)
println("Parameter Estimation Complete!")
println("="^60)
println("\nResults saved to: ", result_file)
println("Number of solutions found: ", length(solutions_vector))
if !isempty(solutions_vector)
	println("\nBest solution:")
	best_sol = solutions_vector[1]
	println("  States: ", best_sol.states)
	println("  Parameters: ", best_sol.parameters)
	println("  Error metrics:")
	println("    Best error: ", besterror)
	println("    Min error: ", best_min_error)
	println("    Mean error: ", best_mean_error)
	println("    Median error: ", best_median_error)
	println("    Max error: ", best_max_error)
	println("    Approximation error: ", best_approximation_error)
	println("    RMS error: ", best_rms_error)
end
