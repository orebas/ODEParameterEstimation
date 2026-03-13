using ODEParameterEstimation
using Logging

# Include all model files
include("models/advanced_systems.jl")
include("models/biological_systems.jl")
include("models/classical_systems.jl")
include("models/simple_models.jl")
include("models/test_models.jl")
include("models/debug_models.jl")
include("models/control_systems.jl")  # Control theory examples for IEEE TAC

using KernelFunctions  # Must be before GaussianProcesses to avoid Julia 1.12 world age warning
using GaussianProcesses
using LineSearches
using Optim
using Statistics

#=============================================================================
                    SINGLE SOURCE OF TRUTH: MODEL REGISTRIES

All available models are registered here. run_examples.jl and the
run_parameter_estimation_examples() function reference these dicts.
=============================================================================#

"""Models that currently run cleanly and are reasonable to present as straightforward examples."""
const GREEN_MODELS = Dict(
	# Simple models
	:simple => simple,
	:simple_linear_combination => simple_linear_combination,
	:onesp_cubed => onesp_cubed,
	:threesp_cubed => threesp_cubed,
	:onevar_exp => onevar_exp,

	# Classical systems
	:lotka_volterra => lotka_volterra,
	:vanderpol => vanderpol,
	:harmonic => harmonic,

	:sum_test => sum_test,

	# DAISY models
	:daisy_mamil3 => daisy_mamil3,

	# Specialized models
	:slowfast => slowfast,
	:repressilator => repressilator,

	# Control systems and transformed variants that currently estimate well
	:dc_motor => dc_motor,
	:quadrotor_altitude => quadrotor_altitude,
	:thermal_system => thermal_system,
	:bicycle_model => bicycle_model,
	:flexible_arm => flexible_arm,
	:bilinear_system => bilinear_system,
	:maglev_linear => maglev_linear,

	:quadrotor_altitude_identifiable => quadrotor_altitude_identifiable,
	:aircraft_pitch_identifiable => aircraft_pitch_identifiable,
	:tank_level_poly => tank_level_poly,
	:two_tank_poly => two_tank_poly,
	:bicycle_model_identifiable => bicycle_model_identifiable,

	# Natural sinusoidal input models (auto-polynomialized via transcendental handling)
	:quadrotor_sinusoidal => quadrotor_sinusoidal,
	:forced_lv_sinusoidal => forced_lv_sinusoidal,
	:aircraft_pitch_sinusoidal => aircraft_pitch_sinusoidal,
)

"""Models that are intentionally useful as structural-unidentifiability demonstrations."""
const STRUCTURAL_UNIDENTIFIABILITY_MODELS = Dict(
	:substr_test => substr_test,
	:global_unident_test => global_unident_test,
	:trivial_unident => trivial_unident,
	:aircraft_pitch => aircraft_pitch,
	:dc_motor_identifiable => dc_motor_identifiable,
	:mass_spring_damper => mass_spring_damper,
	:two_compartment_pk => two_compartment_pk,
	:treatment => treatment,
)

"""Models that run, but are harder, less accurate, or more experimental than the green set."""
const HARD_MODELS = Dict(
	:hiv => hiv,
	:hiv_old_wrong => hiv_old_wrong,
	:crauste_corrected => crauste_corrected,
	:allee_competition => allee_competition,
	:biohydrogenation => biohydrogenation,
	:fitzhugh_nagumo => fitzhugh_nagumo,
	:boost_converter_identifiable => boost_converter_identifiable,
	:boost_converter_sinusoidal => boost_converter_sinusoidal,
	:daisy_ex3 => daisy_ex3,
	:daisy_mamil4 => daisy_mamil4,
	:brusselator => brusselator,
	:lv_periodic => lv_periodic,
	:forced_lotka_volterra => forced_lotka_volterra,
	:forced_lotka_volterra_identifiable => forced_lotka_volterra_identifiable,
	:bilinear_system_identifiable => bilinear_system_identifiable,
	:bilinear_system_sinusoidal => bilinear_system_sinusoidal,
	:cart_pole_linear => cart_pole_linear,
	:magnetic_levitation_identifiable => magnetic_levitation_identifiable,
	:magnetic_levitation_sinusoidal => magnetic_levitation_sinusoidal,
	:bicycle_model_sinusoidal => bicycle_model_sinusoidal,
	:dc_motor_sinusoidal => dc_motor_sinusoidal,
)

"""Models retained in-package but currently best treated as limitations or active failure cases."""
const LIMITATION_MODELS = Dict(
	:seir => seir,
	:cart_pole => cart_pole,
	:tank_level => tank_level,
	:cstr => cstr,
	:ball_beam => ball_beam,
	:swing_equation => swing_equation,
	:magnetic_levitation => magnetic_levitation,
	:two_tank => two_tank,
	:boost_converter => boost_converter,
	:crauste => crauste,
	:crauste_revised => crauste_revised,
	:cstr_reparametrized => cstr_reparametrized,
	:cstr_fixed_activation => cstr_fixed_activation,
	:sirsforced => sirsforced,
)

"""Default runnable set: green examples plus the explicit structural-unidentifiability demos."""
const STANDARD_MODELS = merge(GREEN_MODELS, STRUCTURAL_UNIDENTIFIABILITY_MODELS)

"""All available models (standard + hard)."""
const ALL_MODELS = merge(STANDARD_MODELS, HARD_MODELS, LIMITATION_MODELS)

"""Get list of all available model names."""
available_models() = sort(collect(keys(ALL_MODELS)))

"""Get a dictionary of model registries by category name."""
function available_model_categories()
	return Dict(
		:green => GREEN_MODELS,
		:structural_unidentifiability => STRUCTURAL_UNIDENTIFIABILITY_MODELS,
		:standard => STANDARD_MODELS,
		:hard => HARD_MODELS,
		:limitations => LIMITATION_MODELS,
		:all => ALL_MODELS,
	)
end













"""
	run_parameter_estimation_examples(; models=:all, opts=EstimationOptions(), ...)

Run parameter estimation examples on the specified models.

# Arguments
- `models`: Symbol or Vector{Symbol} specifying which models to run.
		   Use :all for all models, :hard for challenging models only,
		   or specify individual models like [:simple, :hiv]
- `opts`: EstimationOptions struct containing all estimation parameters
- Additional keyword arguments for backward compatibility (will be merged into opts)

# Available models
Use `available_models()` to get the full list. Models are organized into:
- `GREEN_MODELS`: straightforward, maintained examples
- `STRUCTURAL_UNIDENTIFIABILITY_MODELS`: explicit identifiability demos
- `HARD_MODELS`: running but harder / less reliable examples
- `LIMITATION_MODELS`: retained in-package but currently limitation / failure cases
"""
function run_parameter_estimation_examples(;
	models = :all,
	opts::EstimationOptions = EstimationOptions(),
	datasize = nothing,
	noise_level = nothing,
	interpolator = nothing,
	system_solver = nothing,
	log_dir = "logs",
	doskip = true,
	shooting_points = nothing,
	use_new_flow = nothing,
	use_si_template = nothing,
)
	# Merge any provided keyword arguments with EstimationOptions
	if !isnothing(datasize) || !isnothing(noise_level) || !isnothing(interpolator) ||
	   !isnothing(system_solver) || !isnothing(shooting_points) ||
	   !isnothing(use_new_flow) || !isnothing(use_si_template)
		# Build keyword dict for merging
		merge_kwargs = Dict{Symbol, Any}()
		!isnothing(datasize) && (merge_kwargs[:datasize] = datasize)
		!isnothing(noise_level) && (merge_kwargs[:noise_level] = noise_level)
		!isnothing(shooting_points) && (merge_kwargs[:shooting_points] = shooting_points)
		!isnothing(use_new_flow) && (merge_kwargs[:use_new_flow] = use_new_flow)
		!isnothing(use_si_template) && (merge_kwargs[:use_si_template] = use_si_template)

		# Handle special cases for interpolator and system_solver
		if !isnothing(interpolator)
			if interpolator == aaad_gpr_pivot
				merge_kwargs[:interpolator] = InterpolatorAAADGPR
			elseif interpolator == aaad
				merge_kwargs[:interpolator] = InterpolatorAAAD
			else
				merge_kwargs[:custom_interpolator] = interpolator
			end
		end

		if !isnothing(system_solver)
			# Check if RS extension is loaded for RS solver comparison
			if isdefined(ODEParameterEstimation, :solve_with_rs) &&
			   (system_solver == solve_with_rs || system_solver == solve_with_rs_new)
				merge_kwargs[:system_solver] = SolverRS
			elseif system_solver == solve_with_hc
				merge_kwargs[:system_solver] = SolverHC
			elseif system_solver == solve_with_nlopt
				merge_kwargs[:system_solver] = SolverNLOpt
			elseif system_solver == solve_with_fast_nlopt
				merge_kwargs[:system_solver] = SolverFastNLOpt
			end
		end

		# Backward-compat: map the old boolean onto the supported flow enum
		if haskey(merge_kwargs, :use_new_flow)
			merge_kwargs[:use_new_flow] || error("use_new_flow=false is no longer supported. Use flow=FlowStandard or flow=FlowDirectOpt explicitly.")
			merge_kwargs[:flow] = FlowStandard
			delete!(merge_kwargs, :use_new_flow)
		end

		opts = merge_options(opts; merge_kwargs...)
	end

	# Create log directory if it doesn't exist
	!isdir(log_dir) && mkpath(log_dir)

	model_categories = available_model_categories()

	# Determine which models to run from the named registries above
	models_to_run = if models == :all
		collect(keys(model_categories[:all]))
	elseif models == :hard
		collect(keys(model_categories[:hard]))
	elseif models == :green
		collect(keys(model_categories[:green]))
	elseif models == :structural_unidentifiability
		collect(keys(model_categories[:structural_unidentifiability]))
	elseif models == :limitations
		collect(keys(model_categories[:limitations]))
	elseif models == :standard
		collect(keys(model_categories[:standard]))
	elseif models isa Symbol
		[models]
	else
		models
	end

	# Run each selected model
	original_stdout = stdout
	original_stderr = stderr
	for model_name in models_to_run
		log_file_path = joinpath(log_dir, "$(model_name).log")
		if isfile(log_file_path) && doskip
			log_content = read(log_file_path, String)
			if occursin("SUCCESS", log_content)
				println(original_stdout, "Skipping completed model: $model_name")
				continue
			end
		end

		println(original_stdout, "Running model: $model_name")
		open(log_file_path, "w") do log_stream
			with_logger(ConsoleLogger(log_stream)) do
				redirect_stdout(log_stream) do
					redirect_stderr(log_stream) do
						try
							model_fn = ALL_MODELS[model_name]
							pep = model_fn()

							# Use the model's recommended timescale if available, otherwise default to [0.0, 5.0]
							time_interval =
								isnothing(pep.recommended_time_interval) ? [0.0, 5.0] :
								pep.recommended_time_interval

							if opts.flow == FlowStandard
								println("Using NEW optimized workflow")
							elseif opts.flow == FlowDirectOpt
								println("Using direct optimization workflow")
							end

							# Create options for this specific model with the correct time interval
							model_opts = merge_options(opts, time_interval = time_interval)

							@time analyze_parameter_estimation_problem(
								sample_problem_data(pep, model_opts),
								model_opts,
							)
							println("SUCCESS")
							println(original_stdout, "Model $model_name ran successfully.")
						catch e
							println("FAILURE")
							println(
								original_stderr,
								"Model $model_name failed. See $(log_file_path) for details.",
							)
							showerror(log_stream, e, catch_backtrace())
						end
					end
				end
			end
		end
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
