include("load_examples.jl")

# Additional dependencies for advanced solvers
using SciMLBase
using Optimization
using OptimizationOptimJL
using OptimizationOptimisers
#using OptimizationMOI
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
EXCLUDED_MODELS = [:sirsforced, :treatment, :crauste, :cstr, :cstr_reparametrized,  :cstr_fixed_activation, :hiv_old_wrong, :hiv, :tank_level, :ball_beam, :crauste_revised, :two_tank, :cart_pole, :magnetic_levitation, :swing_equation, boost_converter, boost_converter_sinusoidal]
#EXCLUDED_MODELS = []
EXCLUDED_MODELS = [:magnetic_levitation, :cstr,
:swing_equation, :two_tank,
:ball_beam, :crauste_revised,
:cart_pole, :boost_converter,  :crauste] 
models_to_run = filter(x -> x ∉ EXCLUDED_MODELS, collect(keys(ALL_MODELS)))
models_to_run = shuffle(models_to_run)



models_to_run = [:simple]
# Alternative model selections (uncomment to use):
# models_to_run = collect(keys(STANDARD_MODELS))  # Only standard models
# models_to_run = collect(keys(HARD_MODELS))      # Only hard models
# models_to_run = [:simple, :lotka_volterra, :onevar_exp]      # Specific models

#models_to_run = [:bicycle_model]

# Create EstimationOptions with desired settings
standard_opts = EstimationOptions(
	use_parameter_homotopy = true,
	datasize = 1001,
	noise_level = 1e-8,
	system_solver = SolverHC,
	flow = FlowStandard,
	use_si_template = true,
	polish_solver_solutions = true,
	polish_solutions = false,
	polish_maxiters = 50,
	polish_method = PolishLBFGS,
	opt_ad_backend = :enzyme,
	#interpolator = InterpolatorAGP,
	#interpolator = InterpolatorAAADGPR,
	#interpolator = InterpolatorAAAD,
	interpolator = InterpolatorAGPRobust,
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
