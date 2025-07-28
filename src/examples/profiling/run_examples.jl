include("../load_examples.jl")




#=list of models:
	:simple => simple,
		:simple_linear_combination => simple_linear_combination,
		:onesp_cubed => onesp_cubed,
		:threesp_cubed => threesp_cubed,

		# Classical systems
		:lotka_volterra => lotka_volterra,
		:lv_periodic => lv_periodic,
		:vanderpol => vanderpol,
		:brusselator => brusselator,

		# Biological systems

		:seir => seir,
		:treatment => treatment,
		:biohydrogenation => biohydrogenation,
		:repressilator => repressilator,


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
		:allee_competition => allee_competition,
		:sirsforced => sirsforced,
	)
=#

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
using AbstractAlgebra
using RationalUnivariateRepresentation
using RS

using Profile
#using AbstractAlgebra, RationalUnivariateRepresentation, RS
#using Symbolics
#using DynamicPolynomials
#using Nemo




model_dict = Dict(
	# Simple models
	:simple => simple,
	:simple_linear_combination => simple_linear_combination,
	:onesp_cubed => onesp_cubed,
	:threesp_cubed => threesp_cubed,

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
models_to_run = filter(x -> x != :sirsforced, collect(keys(merge(model_dict, hard_model_dict))))

#models_to_run = [:simple, :simple_linear_combination, :onesp_cubed, :threesp_cubed, :lotka_volterra, :lv_periodic, :vanderpol, :brusselator, :harmonic, :substr_test, :global_unident_test, :sum_test, :trivial_unident, :two_compartment_pk, :fitzhugh_nagumo]

models_to_run = [:simple, :simple_linear_combination, :onesp_cubed, :threesp_cubed, :lv_periodic]

#using Random
#models_to_run = shuffle(models_to_run)

run_parameter_estimation_examples(datasize = 201, noise_level = 0.000, models = models_to_run, system_solver = solve_with_nlopt_quick)
