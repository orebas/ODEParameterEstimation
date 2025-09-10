# NOTE: This file needs to be updated to use the new EstimationOptions interface
# See run_examples.jl for the new API usage pattern

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
using ModelingToolkit
using SciMLBase
using Optimization
using OptimizationOptimJL
using OptimizationOptimisers
using OptimizationMOI
using NLSolversBase: NLSolversBase
using NonlinearSolve
using LeastSquaresOptim
using CSV
using DataFrames
using OrdinaryDiffEq
#using AbstractAlgebra, RationalUnivariateRepresentation, RS
#using Symbolics
#using DynamicPolynomials
#using Nemo



#= Central configuration for the analysis =#
const MODELS_TO_RUN = [:lv_periodic, :vanderpol]
const NOISE_LEVELS = [0.0,0.01, 0.05] # 0.001, 0.01, 0.05]
const DATASIZE = 201


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



using AbstractAlgebra
using RationalUnivariateRepresentation
using RS

"""
	exprs_to_AA_polys(exprs, vars)

Convert each symbolic expression in `exprs` into a polynomial in an
AbstractAlgebra polynomial ring in the variables `vars`. This returns
both the ring `R` and the vector of polynomials in `R`.
"""
function exprs_to_AA_polys(exprs, vars)
	# Create a polynomial ring over QQ, using the variable names

	M = Module()
	Base.eval(M, :(using AbstractAlgebra))
	#Base.eval(M, :(using Nemo))
	#	Base.eval(M, :(using RationalUnivariateRepresentation))
	#	Base.eval(M, :(using RS))

	var_names = string.(vars)
	ring_command = "R = @polynomial_ring(QQ, $var_names)"
	#approximation_command = "R(expr::Float64) = R(Nemo.rational_approx(expr, 1e-4))"
	ring_object = Base.eval(M, Meta.parse(ring_command))
	#display(temp)
	#Base.eval(M, Meta.parse(approximation_command))


	a = string.(exprs)
	AA_polys = []
	for expr in exprs
		push!(AA_polys, Base.eval(M, Meta.parse(string(expr))))
	end
	return ring_object, AA_polys

end





function solve_with_rs(poly_system, varlist;
	start_point = nothing,  # Not used but kept for interface consistency
	options = Dict())

	@info "solve_with_rs: Received system" poly_system=poly_system varlist=varlist
	#try
	# Convert symbolic expressions to AA polynomials using existing infrastructure
	R, aa_system = exprs_to_AA_polys(poly_system, varlist)

	println("aa_system")
	println(aa_system)
	println("R")
	println(R)
	# Compute RUR and get separating element
	rur, sep = zdim_parameterization(aa_system, get_separating_element = true)

	# Find solutions
	output_precision = get(options, :output_precision, Int32(20))
	sol = RS.rs_isolate(rur, sep, output_precision = output_precision)
	@info "solve_with_rs: Raw solutions from rs_isolate" sol=sol

	# Convert solutions back to our format
	solutions = []
	display(sol)
	for s in sol
		# Extract real solutions
		#display(s)
		real_sol = [convert(Float64, real(v[1])) for v in s]
		push!(solutions, real_sol)
	end

	@info "solve_with_rs: Processed solutions" solutions=solutions
	#return solutions, varlist, Dict(), varlist
	return solutions, varlist, Dict(), varlist
end
=#
@variables a b
poly_system = [(a^2 + b^2 - 5), (a - 2 * b)]
varlist = [a, b]

display(solve_with_rs(poly_system, varlist))

triv_model_list = [:simple, :simple_linear_combination, :onesp_cubed, :threesp_cubed, :substr_test, :global_unident_test, :sum_test, :trivial_unident]
short_model_list = [:lotka_volterra, :lv_periodic, :vanderpol, :brusselator,  :fitzhugh_nagumo, :seir, :treatment, :biohydrogenation, :repressilator]

shortest_model_list = [ :lv_periodic]

function run_and_save_analysis()
    # Use the global configuration
    models_to_run = MODELS_TO_RUN
    noise_levels = NOISE_LEVELS
    interpolators_to_run = Dict("GPR" => aaad_gpr_pivot, "aaad" => aaad)

    results_df = DataFrame(
        model_name = String[],
        noise_level = Float64[],
        interpolator_method = String[],
        estimator = String[],
        variable_name = String[],
        variable_type = String[],
        true_value = Float64[],
        estimated_value = Float64[],
        rel_error = Float64[],
        cluster_id = Int[],
        solution_in_cluster = Int[],
        overall_problem_error = Float64[],
    )

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


    for (interpolator_name, interpolator_func) in interpolators_to_run
        for model_name in models_to_run
            for noise in noise_levels
                @info "Running analysis for $model_name with noise $noise and interpolator $interpolator_name"
                
                if model_name in keys(hard_model_dict)
                    model_fn = hard_model_dict[model_name]
                else
                    model_fn = model_dict[model_name]
                end
                pep = model_fn()
                time_interval = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval
                
                data_sample = sample_problem_data(pep; datasize = DATASIZE, time_interval = time_interval, noise_level = noise).data_sample
                
                # Get true parameters and initial conditions
                true_params = pep.p_true

                kwargs = Dict{Symbol, Any}(:nooutput => true)
                if !isnothing(interpolator_func)
                    kwargs[:interpolator] = interpolator_func
                end

                raw_results, processed_results = analyze_parameter_estimation_problem(
                    sample_problem_data(pep, datasize=DATASIZE, time_interval=time_interval, noise_level=noise),
                    ;kwargs... 
                )

                # process raw_results[1] which is a vector of solutions
                for (cluster_idx, cluster) in enumerate(cluster_solutions(raw_results[1]))
                     for (sol_idx, solution) in enumerate(cluster)
                        # process states
                        for (var, est_val) in solution.states
                            true_val = pep.ic[var]
                            rel_err = abs(est_val - true_val) / (abs(true_val) < 1e-6 ? 1.0 : abs(true_val))
                            push!(results_df, (
                                model_name = String(model_name),
                                noise_level = noise,
                                interpolator_method = interpolator_name,
                                estimator = "PE",
                                variable_name = string(var),
                                variable_type = "state",
                                true_value = true_val,
                                estimated_value = est_val,
                                rel_error = rel_err,
                                cluster_id = cluster_idx,
                                solution_in_cluster = sol_idx,
                                overall_problem_error = solution.err
                            ))
                        end
                        # process parameters
                        for (var, est_val) in solution.parameters
                             if haskey(pep.p_true, var)
                                true_val = pep.p_true[var]
                                rel_err = abs(est_val - true_val) / (abs(true_val) < 1e-6 ? 1.0 : abs(true_val))
                                push!(results_df, (
                                    model_name = String(model_name),
                                    noise_level = noise,
                                    interpolator_method = interpolator_name,
                                    estimator = "PE",
                                    variable_name = string(var),
                                    variable_type = "parameter",
                                    true_value = true_val,
                                    estimated_value = est_val,
                                    rel_error = rel_err,
                                    cluster_id = cluster_idx,
                                    solution_in_cluster = sol_idx,
                                    overall_problem_error = solution.err
                                ))
                            end
                        end
                    end
                end
            end
        end
    end
    CSV.write("ifac_analysis_results.csv", results_df)
end


function run_optimization_analysis()
    # Use the global configuration
    models_to_run = MODELS_TO_RUN
    noise_levels = NOISE_LEVELS

    # Load existing results (created by run_and_save_analysis)
    results_df = if isfile("ifac_analysis_results.csv")
        CSV.read("ifac_analysis_results.csv", DataFrame)
    else
        println("Warning: Starting with an empty DataFrame for optimization results.")
        DataFrame(
            model_name = String[],
            noise_level = Float64[],
            interpolator_method = String[],
            estimator = String[],
            variable_name = String[],
            variable_type = String[],
            true_value = Float64[],
            estimated_value = Float64[],
            rel_error = Float64[],
            cluster_id = Int[],
            solution_in_cluster = Int[],
            overall_problem_error = Float64[],
        )
    end

    model_dict = Dict(:vanderpol => vanderpol, :lv_periodic => lv_periodic)

    for model_name in models_to_run
        for noise in noise_levels
            @info "Running OPTIMIZATION for $model_name with noise $noise"

            pep = model_dict[model_name]()
            time_interval = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval

            # Prepare a noisy (or noise-free) data sample that will be used as the target signal
            data_sample = sample_problem_data(pep; datasize = DATASIZE, time_interval = time_interval, noise_level = noise).data_sample
            
            # Get true parameters and initial conditions
            true_params = pep.p_true
            true_ic = pep.ic
            
            # Extract ordered state and parameter symbols
            state_syms = ModelingToolkit.unknowns(pep.model.system)
            param_syms = ModelingToolkit.parameters(pep.model.system)

            # Build ordered vectors for the initial condition and the true parameters
            u0_vec = [pep.ic[sym] for sym in state_syms]
            p_true_vec = [pep.p_true[sym] for sym in param_syms]

            # Create a base ODEProblem that we will remake inside the loss function
            prob0 = ODEProblem(ModelingToolkit.complete(pep.model.system), u0_vec, (time_interval[1], time_interval[2]), p_true_vec)

            # ------------------------------------------------------------
            # Loss function: sum of squared errors w.r.t. data_sample
            # ------------------------------------------------------------
            function loss_function(p_vec, _)
                # Create a new problem with the current parameter vector
                prob = ODEProblem(ModelingToolkit.complete(pep.model.system), u0_vec, (time_interval[1], time_interval[2]), p_vec)
                
                # Solve with a robust default solver
                sol = solve(prob, AutoVern9(Rodas4P()), saveat = data_sample["t"])

                # If the solver failed, return Inf so that the optimizer steers away
                sol.retcode == :Success || return Inf

                loss = 0.0
                for (obs, measured) in data_sample
                    obs == "t" && continue
                    loss += sum((sol[obs] .- measured) .^ 2)
                end
                return loss
            end

            # ------------------------------------------------------------
            # Set up and run the optimization
            # ------------------------------------------------------------
            p_guess = p_true_vec .* (1 .+ 0.1 .* randn(length(p_true_vec)))
            opt_func = OptimizationFunction(loss_function, Optimization.AutoForwardDiff())
            opt_prob = OptimizationProblem(opt_func, p_guess)
            opt_sol = solve(opt_prob, BFGS())
            estimated_params_vec = opt_sol.u

            # Final loss with the best parameters found
            final_loss = loss_function(estimated_params_vec, nothing)

            # ------------------------------------------------------------
            # Persist results
            # ------------------------------------------------------------
            # States (initial conditions) – assumed to be known
            for (var, true_val) in pep.ic
                push!(results_df, (
                    model_name = String(model_name), noise_level = noise, interpolator_method = "N/A",
                    estimator = "Opt", variable_name = string(var), variable_type = "state",
                    true_value = true_val, estimated_value = true_val, rel_error = 0.0,
                    cluster_id = 1, solution_in_cluster = 1, overall_problem_error = final_loss,
                ))
            end

            # Parameters
            for (idx, sym) in enumerate(param_syms)
                true_val = pep.p_true[sym]
                est_val = estimated_params_vec[idx]
                rel_err = abs(est_val - true_val) / (abs(true_val) < 1e-6 ? 1.0 : abs(true_val))
                push!(results_df, (
                    model_name = String(model_name), noise_level = noise, interpolator_method = "N/A",
                    estimator = "Opt", variable_name = string(sym), variable_type = "parameter",
                    true_value = true_val, estimated_value = est_val, rel_error = rel_err,
                    cluster_id = 1, solution_in_cluster = 1, overall_problem_error = final_loss,
                ))
            end
        end
    end

    CSV.write("ifac_analysis_results.csv", results_df)
end


#println("Running parameter estimation examples, no noise, maximum")
#run_parameter_estimation_examples(datasize = 301, noise_level = 0.000, models = [:lv_periodic, :vanderpol, :brusselator, :fitzhugh_nagumo, :seir])
 run_and_save_analysis()
 run_optimization_analysis()

 #run_parameter_estimation_examples(datasize = 501, noise_level = 0.000, models = :hard)


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
