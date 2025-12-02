# compare_interpolators.jl
# Compares the default GPR interpolator (GaussianProcesses.jl) with the new AGP interpolator (AbstractGPs.jl)

include("load_examples.jl")

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
using Statistics
using Printf

# Model dictionary (same as in load_examples.jl)
model_dict = Dict(
	:simple => simple,
	:simple_linear_combination => simple_linear_combination,
	:onesp_cubed => onesp_cubed,
	:threesp_cubed => threesp_cubed,
	:onevar_exp => onevar_exp,
	:lotka_volterra => lotka_volterra,
	:lv_periodic => lv_periodic,
	:vanderpol => vanderpol,
	:brusselator => brusselator,
	:harmonic => harmonic,
	:seir => seir,
	:biohydrogenation => biohydrogenation,
	:repressilator => repressilator,
	:substr_test => substr_test,
	:global_unident_test => global_unident_test,
	:sum_test => sum_test,
	:trivial_unident => trivial_unident,
	:daisy_ex3 => daisy_ex3,
	:daisy_mamil3 => daisy_mamil3,
	:daisy_mamil4 => daisy_mamil4,
	:slowfast => slowfast,
	:two_compartment_pk => two_compartment_pk,
	:fitzhugh_nagumo => fitzhugh_nagumo,
)

hard_model_dict = Dict(
	:hiv => hiv,
	:crauste => crauste,
	:crauste_corrected => crauste_corrected,
	:crauste_revised => crauste_revised,
	:allee_competition => allee_competition,
)

# Select models to test - start with a subset for quick comparison
test_models = [
	:simple,
	:lotka_volterra,
	:vanderpol,
	:brusselator,
	:harmonic,
	:fitzhugh_nagumo,
	:biohydrogenation,
]

# Uncomment to run more models:
# test_models = [:simple, :lotka_volterra, :vanderpol, :brusselator, :harmonic,
#                :fitzhugh_nagumo, :biohydrogenation, :seir, :repressilator]

# Uncomment to run all models:
# test_models = collect(keys(model_dict))

println("=" ^ 80)
println("INTERPOLATOR COMPARISON: Default GPR vs AbstractGPs (AGP)")
println("=" ^ 80)

# Base options (common to both)
base_opts = Dict(
	:datasize => 501,
	:noise_level => 0.000,
	:system_solver => SolverHC,
	:flow => FlowStandard,
	:use_si_template => true,
	:polish_solver_solutions => true,
	:polish_solutions => false,
	:polish_maxiters => 50,
	:polish_method => PolishLBFGS,
	:opt_ad_backend => :enzyme,
	:diagnostics => false,  # Reduce output
)

# Create options for each interpolator
opts_default = EstimationOptions(;
	base_opts...,
	interpolator = InterpolatorAAADGPR,  # Default: GaussianProcesses.jl
)

opts_agp = EstimationOptions(;
	base_opts...,
	interpolator = InterpolatorAGP,  # New: AbstractGPs.jl
)

# Store results for comparison
results_comparison = Dict{Symbol, NamedTuple}()

println("\nRunning comparison on $(length(test_models)) models...")
println("-" ^ 80)

for model_name in test_models
	println("\n### Model: $model_name ###")

	if !haskey(model_dict, model_name) && !haskey(hard_model_dict, model_name)
		println("   Model not found, skipping...")
		continue
	end

	model_fn = haskey(model_dict, model_name) ? model_dict[model_name] : hard_model_dict[model_name]

	# Get the problem
	pep = nothing
	try
		pep = model_fn()
	catch e
		println("   Error creating model: $e")
		continue
	end

	# Get the time interval
	time_interval = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval

	# Create model-specific options with correct time interval
	model_opts_default = merge_options(opts_default, time_interval = time_interval)
	model_opts_agp = merge_options(opts_agp, time_interval = time_interval)

	# Sample data for the problem (THIS WAS MISSING!)
	pep_with_data = nothing
	try
		pep_with_data = sample_problem_data(pep, model_opts_default)
	catch e
		println("   Error sampling data: $e")
		continue
	end

	# Run with default interpolator (GaussianProcesses.jl)
	println("   [1/2] Running with default GPR (GaussianProcesses.jl)...")
	result_default = nothing
	time_default = 0.0
	try
		time_default = @elapsed begin
			result_default = analyze_parameter_estimation_problem(pep_with_data, model_opts_default)
		end
		println("         Time: $(round(time_default, digits=2))s")
	catch e
		println("         ERROR: $e")
	end

	# Run with AGP interpolator (AbstractGPs.jl) - use same data!
	println("   [2/2] Running with AGP (AbstractGPs.jl)...")
	result_agp = nothing
	time_agp = 0.0
	try
		time_agp = @elapsed begin
			result_agp = analyze_parameter_estimation_problem(pep_with_data, model_opts_agp)
		end
		println("         Time: $(round(time_agp, digits=2))s")
	catch e
		println("         ERROR: $e")
	end

	# Compare results
	if !isnothing(result_default) && !isnothing(result_agp)
		# Extract best errors
		err_default = length(result_default) > 0 ? minimum(r.err for r in result_default) : Inf
		err_agp = length(result_agp) > 0 ? minimum(r.err for r in result_agp) : Inf

		# Count valid solutions
		n_solutions_default = length(result_default)
		n_solutions_agp = length(result_agp)

		results_comparison[model_name] = (
			err_default = err_default,
			err_agp = err_agp,
			time_default = time_default,
			time_agp = time_agp,
			n_solutions_default = n_solutions_default,
			n_solutions_agp = n_solutions_agp,
		)

		# Print comparison
		println("   Results:")
		@printf("         Default GPR: error=%.2e, solutions=%d, time=%.2fs\n",
			err_default, n_solutions_default, time_default)
		@printf("         AGP:         error=%.2e, solutions=%d, time=%.2fs\n",
			err_agp, n_solutions_agp, time_agp)

		if err_agp < err_default
			println("         → AGP is better (lower error)")
		elseif err_default < err_agp
			println("         → Default GPR is better (lower error)")
		else
			println("         → Both have same error")
		end
	elseif !isnothing(result_default)
		err_default = length(result_default) > 0 ? minimum(r.err for r in result_default) : Inf
		results_comparison[model_name] = (
			err_default = err_default,
			err_agp = Inf,
			time_default = time_default,
			time_agp = time_agp,
			n_solutions_default = length(result_default),
			n_solutions_agp = 0,
		)
		println("   Results: Default succeeded, AGP failed")
	elseif !isnothing(result_agp)
		err_agp = length(result_agp) > 0 ? minimum(r.err for r in result_agp) : Inf
		results_comparison[model_name] = (
			err_default = Inf,
			err_agp = err_agp,
			time_default = time_default,
			time_agp = time_agp,
			n_solutions_default = 0,
			n_solutions_agp = length(result_agp),
		)
		println("   Results: AGP succeeded, Default failed")
	else
		println("   Results: Both failed")
	end
end

# Print summary table
println("\n")
println("=" ^ 80)
println("SUMMARY TABLE")
println("=" ^ 80)
println()

@printf("%-20s | %12s | %12s | %10s | %10s | %s\n",
	"Model", "Err (Default)", "Err (AGP)", "Time (Def)", "Time (AGP)", "Winner")
println("-" ^ 80)

for model_name in test_models
	if haskey(results_comparison, model_name)
		r = results_comparison[model_name]
		winner = if !isfinite(r.err_default) && !isfinite(r.err_agp)
			"Both failed"
		elseif !isfinite(r.err_agp)
			"Default"
		elseif !isfinite(r.err_default)
			"AGP"
		elseif r.err_agp < r.err_default
			"AGP"
		elseif r.err_default < r.err_agp
			"Default"
		else
			"Tie"
		end

		err_def_str = isfinite(r.err_default) ? @sprintf("%.2e", r.err_default) : "FAILED"
		err_agp_str = isfinite(r.err_agp) ? @sprintf("%.2e", r.err_agp) : "FAILED"

		@printf("%-20s | %12s | %12s | %10.2fs | %10.2fs | %s\n",
			model_name, err_def_str, err_agp_str, r.time_default, r.time_agp, winner)
	end
end

println("-" ^ 80)

# Overall statistics
if length(results_comparison) > 0
	valid_default = [r.err_default for r in values(results_comparison) if isfinite(r.err_default)]
	valid_agp = [r.err_agp for r in values(results_comparison) if isfinite(r.err_agp)]

	avg_err_default = length(valid_default) > 0 ? mean(valid_default) : NaN
	avg_err_agp = length(valid_agp) > 0 ? mean(valid_agp) : NaN
	avg_time_default = mean([r.time_default for r in values(results_comparison)])
	avg_time_agp = mean([r.time_agp for r in values(results_comparison)])

	wins_default = count(r -> isfinite(r.err_default) && isfinite(r.err_agp) && r.err_default < r.err_agp, values(results_comparison))
	wins_agp = count(r -> isfinite(r.err_default) && isfinite(r.err_agp) && r.err_agp < r.err_default, values(results_comparison))
	ties = count(r -> isfinite(r.err_default) && isfinite(r.err_agp) && r.err_agp == r.err_default, values(results_comparison))
	default_only = count(r -> isfinite(r.err_default) && !isfinite(r.err_agp), values(results_comparison))
	agp_only = count(r -> !isfinite(r.err_default) && isfinite(r.err_agp), values(results_comparison))
	both_failed = count(r -> !isfinite(r.err_default) && !isfinite(r.err_agp), values(results_comparison))

	println("\nOVERALL STATISTICS:")
	@printf("  Average error (Default GPR): %.2e (from %d successful runs)\n", avg_err_default, length(valid_default))
	@printf("  Average error (AGP):         %.2e (from %d successful runs)\n", avg_err_agp, length(valid_agp))
	@printf("  Average time (Default GPR):  %.2fs\n", avg_time_default)
	@printf("  Average time (AGP):          %.2fs\n", avg_time_agp)
	println()
	println("  Head-to-head (both succeeded): Default=$wins_default, AGP=$wins_agp, Ties=$ties")
	if default_only > 0 || agp_only > 0 || both_failed > 0
		println("  Only Default succeeded: $default_only")
		println("  Only AGP succeeded: $agp_only")
		println("  Both failed: $both_failed")
	end
end

println("\n" * "=" ^ 80)
println("Comparison complete!")
println("=" ^ 80)
