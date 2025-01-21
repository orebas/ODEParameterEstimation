using ODEParameterEstimation

# Include all model files
include("models/advanced_systems.jl")
include("models/biological_systems.jl")
include("models/classical_systems.jl")
include("models/simple_models.jl")
include("models/test_models.jl")

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
	datasize = 501,
	noise_level = 0.01,
	showplot = true)

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
		#	:hiv => hiv,
		:seir => seir,
		:treatment => treatment,
		:biohydrogenation => biohydrogenation,
		:repressilator => repressilator,
		:crauste => crauste,
		:sirsforced => sirsforced,

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
		:slowfast => slowfast,
		#	:allee_competition => allee_competition,
		:two_compartment_pk => two_compartment_pk,
		:fitzhugh_nagumo => fitzhugh_nagumo,
	)

	# Determine which models to run
	models_to_run = if models == :all
		collect(keys(model_dict))
	elseif models isa Symbol
		[models]
	else
		models
	end

	# Run each selected model
	for model_name in models_to_run
		@info "Running model: $model_name"
		try
			model_fn = model_dict[model_name]
			pep = model_fn()

			# Use the model's recommended timescale if available, otherwise default to [0.0, 5.0]
			time_interval = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval

			analyze_parameter_estimation_problem(
				sample_problem_data(pep,
					datasize = datasize,
					time_interval = time_interval,
					noise_level = noise_level),
				test_mode = false,
				showplot = showplot)
		catch e
			@warn "Failed to run model $model_name" exception = e
		end
	end
end

# Example usage:
# Run all models:
# run_parameter_estimation_examples()

# Run specific models:
# run_parameter_estimation_examples(models=[:simple, :hiv])

# Run with different parameters:
# run_parameter_estimation_examples(datasize=1001, noise_level=0.05) 