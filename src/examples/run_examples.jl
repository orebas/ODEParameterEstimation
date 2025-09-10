include("load_examples.jl")



ez_models = [:simple, :simple_linear_combination, :onesp_cubed, :threesp_cubed, :lotka_volterra, :lv_periodic, :vanderpol, :brusselator, :substr_test, :global_unident_test, :sum_test, :trivial_unident, :two_compartment_pk, :fitzhugh_nagumo]

#using Optim
#using ModelingToolkit
using SciMLBase
using Optimization
using OptimizationOptimJL
using OptimizationOptimisers
using OptimizationMOI
using NLSolversBase: NLSolversBase
using NonlinearSolve
using LeastSquaresOptim
#using AbstractAlgebra, RationalUnivariateRepresentation, RS
#using Symbolics
#using DynamicPolynomials
#using Nemo




using AbstractAlgebra
using RationalUnivariateRepresentation
using RS


#display(solve_with_rs(poly_system, varlist))

#println("Running parameter estimation examples, no noise, maximum")
#run_parameter_estimation_examples(datasize = 501, noise_level = 0.000, models = [:seir])

#run_parameter_estimation_examples(datasize = 501, noise_level = 0.000)
# To run all models:
# run_parameter_estimation_examples(datasize = 501, noise_level = 0.000, models = :all)

# To run a specific set of models, provide a list of symbols:

model_dict = Dict(
	# Simple models
	:simple => simple,
	:simple_linear_combination => simple_linear_combination,
	:onesp_cubed => onesp_cubed,
	:threesp_cubed => threesp_cubed,
	:onevar_exp => onevar_exp,

	# Classical systems
	:lotka_volterra => lotka_volterra,
	:lv_periodic => lv_periodic,
	:vanderpol => vanderpol,
	:brusselator => brusselator,
	:harmonic => harmonic,

	# Biological systems

	:seir => seir,
	:treatment => treatment,
	:biohydrogenation => biohydrogenation,
	:repressilator => repressilator,
	:hiv_old_wrong => hiv_old_wrong,


	# Test models
	:substr_test => substr_test,
	:global_unident_test => global_unident_test,
	:sum_test => sum_test,
	:trivial_unident => trivial_unident,

	# DAISY models
	:daisy_ex3 => daisy_ex3,
	:daisy_mamil3 => daisy_mamil3,
	:daisy_mamil4 => daisy_mamil4,

	# Specialized models
	:slowfast => slowfast, :two_compartment_pk => two_compartment_pk,
	:fitzhugh_nagumo => fitzhugh_nagumo,
)

hard_model_dict = Dict(
	:hiv => hiv,
	:crauste => crauste,
	:crauste_corrected => crauste_corrected,
	:crauste_revised => crauste_revised,
	:allee_competition => allee_competition,
	:sirsforced => sirsforced,
)

# Determine which models to run

models_to_run = filter(x -> x != :sirsforced && x != :treatment, collect(keys(merge(model_dict, hard_model_dict))))
#models_to_run = filter(x -> x != :sirsforced, collect(keys(merge(model_dict, hard_model_dict))))

#models_to_run = filter(x -> true, collect(keys(merge(model_dict, hard_model_dict))))

#models_to_run = [:onevar_exp, :simple, :simple_linear_combination, :onesp_cubed, :threesp_cubed, :lotka_volterra, :lv_periodic, :vanderpol, :brusselator, :harmonic, :substr_test, :global_unident_test, :sum_test, :trivial_unident, :two_compartment_pk, :fitzhugh_nagumo]

#models_to_run = [:simple, :onevar_exp]
#models_to_run = [:onevar_exp]

using Random
models_to_run = shuffle(models_to_run)

# Create EstimationOptions with desired settings
opts = EstimationOptions(
	datasize = 501,
	noise_level = 0.000,
	system_solver = SolverHC,
	use_new_flow = true,
	use_si_template = true,
	polish_solver_solutions = true, diagnostics = true)

run_parameter_estimation_examples(models = models_to_run, opts = opts)

# Alternative usage examples:

# Example 1: Use default options with just a few overrides
# run_parameter_estimation_examples(models = [:simple], opts = EstimationOptions(datasize = 1001))

# Example 2: Backward compatibility - keyword arguments still work
# run_parameter_estimation_examples(datasize = 501, noise_level = 0.01, models = [:simple])

# Example 3: Create reusable option presets
# opts_fast = EstimationOptions(datasize = 101, shooting_points = 2, try_more_methods = false)
# opts_accurate = EstimationOptions(datasize = 2001, shooting_points = 20, abstol = 1e-14)
# run_parameter_estimation_examples(models = [:lotka_volterra], opts = opts_accurate)



