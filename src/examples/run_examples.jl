include("load_examples.jl")

# Additional dependencies for advanced solvers
using SciMLBase
using Optimization
using OptimizationOptimJL
using OptimizationOptimisers
using OptimizationMOI
using NLSolversBase: NLSolversBase
using NonlinearSolve
using LeastSquaresOptim
using AbstractAlgebra
using Random

#=============================================================================
                         MODEL SELECTION

Models are defined in load_examples.jl:
  - STANDARD_MODELS: typical models
  - HARD_MODELS: challenging models
  - ALL_MODELS: combined dict
  - available_models(): list all model names

Modify the filter below to exclude problematic models.
=============================================================================#

# Exclude models that are known to be problematic or slow
EXCLUDED_MODELS = [:sirsforced, :treatment, :crauste]

models_to_run = filter(x -> x ∉ EXCLUDED_MODELS, collect(keys(ALL_MODELS)))
models_to_run = shuffle(models_to_run)

# Alternative model selections (uncomment to use):
# models_to_run = collect(keys(STANDARD_MODELS))  # Only standard models
# models_to_run = collect(keys(HARD_MODELS))      # Only hard models
# models_to_run = [:simple, :lotka_volterra]      # Specific models

# Create EstimationOptions with desired settings
standard_opts = EstimationOptions(
	datasize = 501,
	noise_level = 0.0000001,
	system_solver = SolverHC,
	flow = FlowStandard,
	use_si_template = true,
	polish_solver_solutions = true,
	polish_solutions = false,
	polish_maxiters = 50,
	polish_method = PolishLBFGS,
	opt_ad_backend = :enzyme,
	#interpolator = InterpolatorAGP,
	interpolator = InterpolatorAAADGPR,
	diagnostics = true)

nlopts = EstimationOptions(
	datasize = 501,
	noise_level = 0.000,
	flow = FlowDirectOpt,
	opt_maxiters = 200000)

run_parameter_estimation_examples(models = models_to_run, opts = standard_opts)

# Alternative usage examples:

# Example 1: Use default options with just a few overrides
# run_parameter_estimation_examples(models = [:simple], opts = EstimationOptions(datasize = 1001))

# Example 2: Backward compatibility - keyword arguments still work
# run_parameter_estimation_examples(datasize = 501, noise_level = 0.01, models = [:simple])

# Example 3: Create reusable option presets
# opts_fast = EstimationOptions(datasize = 101, shooting_points = 2, try_more_methods = false)
# opts_accurate = EstimationOptions(datasize = 2001, shooting_points = 20, abstol = 1e-14)
# run_parameter_estimation_examples(models = [:lotka_volterra], opts = opts_accurate)
