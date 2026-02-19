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

"""Standard models that typically work well with default settings."""
const STANDARD_MODELS = Dict(
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
	:slowfast => slowfast,
	:two_compartment_pk => two_compartment_pk,
	:fitzhugh_nagumo => fitzhugh_nagumo,

	# Control systems (original, may have transcendental inputs)
	:dc_motor => dc_motor,
	:mass_spring_damper => mass_spring_damper,
	:cart_pole => cart_pole,
	:tank_level => tank_level,
	:cstr => cstr,
	:quadrotor_altitude => quadrotor_altitude,
	:thermal_system => thermal_system,
	:ball_beam => ball_beam,
	:bicycle_model => bicycle_model,
	:swing_equation => swing_equation,
	:magnetic_levitation => magnetic_levitation,
	:aircraft_pitch => aircraft_pitch,
	:two_tank => two_tank,
	:boost_converter => boost_converter,
	:flexible_arm => flexible_arm,
	:bilinear_system => bilinear_system,
	:forced_lotka_volterra => forced_lotka_volterra,
	:cart_pole_linear => cart_pole_linear,
	:maglev_linear => maglev_linear,

	# Polynomialized / identifiable control systems
	:dc_motor_identifiable => dc_motor_identifiable,
	:quadrotor_altitude_identifiable => quadrotor_altitude_identifiable,
	:magnetic_levitation_identifiable => magnetic_levitation_identifiable,
	:aircraft_pitch_identifiable => aircraft_pitch_identifiable,
	:bicycle_model_identifiable => bicycle_model_identifiable,
	:boost_converter_identifiable => boost_converter_identifiable,
	:bilinear_system_identifiable => bilinear_system_identifiable,
	:forced_lotka_volterra_identifiable => forced_lotka_volterra_identifiable,
	:tank_level_poly => tank_level_poly,
	:two_tank_poly => two_tank_poly,
	:cstr_reparametrized => cstr_reparametrized,
	:cstr_fixed_activation => cstr_fixed_activation,

	# Natural sinusoidal input models (auto-polynomialized via transcendental handling)
	:dc_motor_sinusoidal => dc_motor_sinusoidal,
	:quadrotor_sinusoidal => quadrotor_sinusoidal,
	:forced_lv_sinusoidal => forced_lv_sinusoidal,
	:magnetic_levitation_sinusoidal => magnetic_levitation_sinusoidal,
	:aircraft_pitch_sinusoidal => aircraft_pitch_sinusoidal,
	:bicycle_model_sinusoidal => bicycle_model_sinusoidal,
	:boost_converter_sinusoidal => boost_converter_sinusoidal,
	:bilinear_system_sinusoidal => bilinear_system_sinusoidal,
)

"""Models that are more challenging (stiff, ill-conditioned, or computationally expensive)."""
const HARD_MODELS = Dict(
	:hiv => hiv,
	:crauste => crauste,
	:crauste_corrected => crauste_corrected,
	:crauste_revised => crauste_revised,
	:allee_competition => allee_competition,
	:sirsforced => sirsforced,
)

"""All available models (standard + hard)."""
const ALL_MODELS = merge(STANDARD_MODELS, HARD_MODELS)

"""Get list of all available model names."""
available_models() = sort(collect(keys(ALL_MODELS)))













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
Use `available_models()` to get the full list. Models are defined in:
- STANDARD_MODELS: typical models that work well with defaults
- HARD_MODELS: challenging models (stiff, ill-conditioned, expensive)
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
	try_more_methods = nothing,
	use_new_flow = nothing,
	use_si_template = nothing,
)
	# Merge any provided keyword arguments with EstimationOptions
	if !isnothing(datasize) || !isnothing(noise_level) || !isnothing(interpolator) ||
	   !isnothing(system_solver) || !isnothing(shooting_points) || !isnothing(try_more_methods) ||
	   !isnothing(use_new_flow) || !isnothing(use_si_template)
		# Build keyword dict for merging
		merge_kwargs = Dict{Symbol, Any}()
		!isnothing(datasize) && (merge_kwargs[:datasize] = datasize)
		!isnothing(noise_level) && (merge_kwargs[:noise_level] = noise_level)
		!isnothing(shooting_points) && (merge_kwargs[:shooting_points] = shooting_points)
		!isnothing(try_more_methods) && (merge_kwargs[:try_more_methods] = try_more_methods)
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

		# Backward-compat: map legacy boolean to new flow enum
		if haskey(merge_kwargs, :use_new_flow)
			merge_kwargs[:flow] = merge_kwargs[:use_new_flow] ? FlowStandard : FlowDeprecated
			delete!(merge_kwargs, :use_new_flow)
		end

		opts = merge_options(opts; merge_kwargs...)
	end

	# Create log directory if it doesn't exist
	!isdir(log_dir) && mkpath(log_dir)

	# Determine which models to run (using module-level STANDARD_MODELS and HARD_MODELS)
	models_to_run = if models == :all
		collect(keys(ALL_MODELS))
	elseif models == :hard
		collect(keys(HARD_MODELS))
	elseif models == :standard
		collect(keys(STANDARD_MODELS))
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
							elseif opts.flow == FlowDeprecated
								println("Using standard workflow")
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
