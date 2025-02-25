using ODEParameterEstimation

# Include all model files
include("models/advanced_systems.jl")
include("models/biological_systems.jl")
include("models/classical_systems.jl")
include("models/simple_models.jl")
include("models/test_models.jl")



using GaussianProcesses
using LineSearches
using Optim
using Statistics



#=
function test_gpr_function(xs::AbstractArray{T}, ys::AbstractArray{T}) where {T}
	# For 1D input data, we need a matrix of size 1 × (degree+1)
	# The +1 is because we include the constant term (degree 0)
	#degree = 2
	#β = zeros(1, degree + 1)  # Initialize coefficients matrix
	#poly_mean = MeanPoly(β)

	# Add small noise proportional to y standard deviation to avoid conditioning issues
	ys_std = Statistics.std(ys)
	noise_level = 1e-6 * ys_std
	ys_noisy = ys .+ noise_level * randn(length(ys))

	# Initial kernel parameters
	initial_lengthscale = log(std(xs) / 8)
	initial_variance = 0.0
	initial_noise = -2.0

	println("\nGPR Hyperparameters:")
	println("  Initial lengthscale: $(exp(initial_lengthscale))")
	println("  Initial variance: $(exp(initial_variance))")
	println("  Initial noise: $(exp(initial_noise))")

	kernel = SEIso(initial_lengthscale, initial_variance)
	gp = GP(xs, ys_noisy, MeanZero(), kernel, initial_noise)
	GaussianProcesses.optimize!(gp; method = LBFGS(linesearch = LineSearches.BackTracking()))

	# Print optimized parameters
	println("\nOptimized GPR Hyperparameters:")
	println(fieldnames(typeof(gp)))
	println(fieldnames(typeof(gp.kernel)))

	noise_level = exp(gp.logNoise.value)

	println("  Lengthscale: $(exp(gp.kernel.ℓ2/2))")
	println("  Variance: $(exp(gp.kernel.σ2))")
	println("  Noise: $(noise_level)")

	# Create callable function
	gpr_func = x -> begin
		pred, _ = predict_f(gp, [x])
		return pred[1]
	end
	return gpr_func
end=#












"""
	run_parameter_estimation_examples(; models=:all, datasize=501, noise_level=0.01, showplot=true)

Run parameter estimation examples on the specified models.

# Arguments
- `models`: Symbol or Vector{Symbol} specifying which models to run. 
		   Use :all for all models, or specify individual models like [:simple, :hiv]
- `datasize`: Number of data points to generate for each model
- `noise_level`: Level of noise to add to the synthetic data
- `showplot`: Whether to show plots of the results

# Available models
Simple models: :simple, :simple_linear_combination, :onesp_cubed, :threesp_cubed
Classical systems: :lotka_volterra, :lv_periodic, :vanderpol, :brusselator
Biological systems: :hiv, :seir, :treatment, :biohydrogenation, :repressilator, :crauste, :sirsforced
Test models: :substr_test, :global_unident_test, :sum_test, :trivial_unident
DAISY models: :daisy_ex3, :daisy_mamil3, :daisy_mamil4
Specialized models: :slowfast, :allee_competition, :two_compartment_pk, :fitzhugh_nagumo
"""
function run_parameter_estimation_examples(;
	models = :all,
	datasize = 1501,
	noise_level = 1e-2,
	interpolator = nothing,
	system_solver = nothing)

	# Dictionary mapping model names to their constructor functions
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

	# Determine which models to run
	models_to_run = if models == :all
		collect(keys(model_dict))
	elseif models == :hard
		collect(keys(hard_model_dict))

	elseif models isa Symbol
		[models]
	else
		models
	end

	# Run each selected model
	for model_name in models_to_run
		@info "Running model: $model_name"
		#	try
		if model_name in keys(hard_model_dict)
			model_fn = hard_model_dict[model_name]
		else
			model_fn = model_dict[model_name]
		end
		pep = model_fn()

		# Use the model's recommended timescale if available, otherwise default to [0.0, 5.0]
		time_interval = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval

		analyze_parameter_estimation_problem(
			sample_problem_data(pep,
				datasize = datasize,
				time_interval = time_interval,
				noise_level = noise_level),
			interpolator = interpolator, system_solver = system_solver)
		#	catch e
		#		@warn "Failed to run model $model_name" exception = e
		#	end
	end
end

# Example usage:
# Run all models:
#run_parameter_estimation_examples(datasize = 1501, noise_level = 0.0)
#run_parameter_estimation_examples(datasize = 1501, noise_level = 0.0, models = :hard)
#run_parameter_estimation_examples(datasize = 201, noise_level = 0.01, interpolator = test_gpr_function)

# Run specific models:
# run_parameter_estimation_examples(models=[:simple, :hiv])

# Run with different parameters:
# run_parameter_estimation_examples(datasize=1001, noise_level=0.05) 
