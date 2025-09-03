include("load_examples.jl")




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
#using AbstractAlgebra, RationalUnivariateRepresentation, RS
#using Symbolics
#using DynamicPolynomials
#using Nemo



#=function solve_with_nlopt(poly_system, varlist;
	start_point = nothing,
	optimizer = GaussNewton(),
	polish_only = false,
	options = Dict())

	#@which GaussNewton()

	# Prepare system for optimization
	prepared_system, mangled_varlist = (poly_system, varlist)

	# Define residual function for NonlinearLeastSquares
	function residual!(res, u, p)
		for (i, eq) in enumerate(prepared_system)
			res[i] = real(Symbolics.value(substitute(eq, Dict(zip(mangled_varlist, u)))))
		end
	end

	# Set up optimization problem
	n = length(varlist)
	m = length(prepared_system)  # Number of equations
	x0 = if isnothing(start_point)
		randn(n)  # Random initialization if no start point provided
	else
		start_point
	end



	# Create NonlinearLeastSquaresProblem
	#@which NonlinearLeastSquaresProblem(NonlinearFunction(residual!, resid_prototype = zeros(m)), x0, nothing;)

	prob = NonlinearLeastSquaresProblem(
		NonlinearFunction(residual!, resid_prototype = zeros(m)),
		x0,
		nothing;  # no parameters needed
	)

	# Set solver options based on polish_only
	solver_opts = if polish_only
		(abstol = 1e-12, reltol = 1e-12, maxiters = 1000)
	else
		(abstol = 1e-8, reltol = 1e-8, maxiters = 10000)
	end

	# Merge with user options
	solver_opts = merge(solver_opts, options)

	# Solve the problem
	#@which solve(prob, optimizer; solver_opts...)
	sol = NonlinearSolve.solve(prob, optimizer; solver_opts...)

	# Check if solution is valid
	if SciMLBase.successful_retcode(sol)
		# Return all four expected values: solutions, variables, trivial_dict, trimmed_varlist
		return [sol.u], mangled_varlist, Dict(), mangled_varlist
	else
		@warn "Optimization did not converge. RetCode: $(sol.retcode)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end
end
=#


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

models_to_run = [:simple, :simple_linear_combination, :onesp_cubed, :threesp_cubed, :lotka_volterra, :lv_periodic, :vanderpol, :brusselator, :harmonic, :substr_test, :global_unident_test, :sum_test, :trivial_unident, :two_compartment_pk, :fitzhugh_nagumo]

using Random
models_to_run = shuffle(models_to_run)

run_parameter_estimation_examples(datasize = 501, noise_level = 0.000, models = models_to_run, use_new_flow = true)
#run_parameter_estimation_examples(datasize = 501, noise_level = 0.000, models = [:simple])


#=
println("ez Running parameter estimation examples with  GPR, no noise, maximum")
run_parameter_estimation_examples(datasize = 1501, noise_level = 0.000, interpolator = test_gpr_function)

println("ez Running parameter estimation examples with  GPR, 1e-8 noise, maximum")
run_parameter_estimation_examples(datasize = 1501, noise_level = 1e-8, interpolator = test_gpr_function)

println("ez Running parameter estimation examples with  GPR, 1e-6 noise, maximum")
run_parameter_estimation_examples(datasize = 1501, noise_level = 1e-6, interpolator = test_gpr_function)

println("ez Running parameter estimation examples with  GPR, 1e-4 noise, maximum")
run_parameter_estimation_examples(datasize = 1501, noise_level = 1e-4, interpolator = test_gpr_function)

println("ez Running parameter estimation examples with  GPR, 1e-2 noise, maximum")
run_parameter_estimation_examples(datasize = 1501, noise_level = 1e-2, interpolator = test_gpr_function)
=#



#run_parameter_estimation_examples(datasize = 1501, noise_level = 0.000, models = :hard)


#run_parameter_estimation_examples(datasize = 1501, noise_level = 0.000, system_solver = solve_with_nlopt, interpolator = aaad, models = [:lv_periodic])
#run_parameter_estimation_examples(datasize = 1501, noise_level = 0.000, models = :hard)
