# estimation_options.jl
# Comprehensive options struct for ODEParameterEstimation.jl

# Enums for type-safe option selection
"""
	SystemSolverMethod

Enum for selecting the polynomial system solver method.
"""
@enum SystemSolverMethod begin
	SolverRS           # solve_with_rs - RealSolutions/RUR based solver (requires extension)
	SolverHC           # solve_with_hc - HomotopyContinuation solver (default)
	SolverNLOpt        # solve_with_nlopt - NonlinearSolve optimization
	SolverFastNLOpt    # solve_with_fast_nlopt - Fast compiled NLOpt
	SolverRobust       # solve_with_robust - Robust solver with multiple fallbacks
end

"""
	InterpolatorMethod

Enum for selecting the data interpolation method.
"""
@enum InterpolatorMethod begin
	InterpolatorAAAD           # aaad - Basic AAA rational interpolation
	InterpolatorAAADGPR        # aaad_gpr_pivot - GPR-based AAA (default)
	InterpolatorAAADOld        # aaad_old_reliable - Conservative AAA
	InterpolatorFHD            # Floater-Hormann interpolation
	InterpolatorAGP            # agp_gpr - AbstractGPs.jl GP interpolation with uncertainty
	InterpolatorAGPRobust      # agp_gpr_robust - Robust GP that handles smooth/noiseless data
	InterpolatorCustom         # User-provided custom interpolator
end

"""
	PolishMethod

Enum for selecting the optimization method for solution polishing.
Note: These correspond to NonlinearSolve.jl and Optim.jl methods.
"""
@enum PolishMethod begin
	PolishNewtonTrust      # NewtonTrustRegion from NonlinearSolve (default)
	PolishLevenberg        # LevenbergMarquardt 
	PolishGaussNewton      # GaussNewton
	PolishBFGS             # BFGS from Optim.jl
	PolishLBFGS            # LBFGS from Optim.jl
end

"""
	EstimationFlow

Enum selecting the high-level workflow used during estimation.

- `FlowDeprecated`: Old/standard workflow
- `FlowStandard`: New optimized multishot workflow (default)
- `FlowDirectOpt`: Direct local optimization workflow (BFGS from random start)
"""
@enum EstimationFlow begin
	FlowDeprecated   # old workflow
	FlowStandard     # optimized_multishot_parameter_estimation
	FlowDirectOpt    # direct_optimization_parameter_estimation
end

"""
	EstimationOptions

A comprehensive options struct that centralizes all configuration parameters for the 
ODEParameterEstimation package. This struct consolidates tolerances, solver selections,
algorithm parameters, and debugging flags into a single, type-stable structure.

# Fields

## Solver and Algorithm Selection
- `system_solver::SystemSolverMethod`: Main polynomial system solver (default: `SolverHC`)
- `ode_solver`: ODE solver for simulation (default: `AutoVern9(Rodas4P())`)
- `interpolator::InterpolatorMethod`: Data interpolation method (default: `InterpolatorAAADGPR`)
- `custom_interpolator::Union{Nothing, Function}`: Custom interpolation function when `interpolator=InterpolatorCustom`

## Numerical Tolerances
- `abstol::Float64`: Absolute tolerance for ODE solving and optimization (default: 1e-14)
- `reltol::Float64`: Relative tolerance for ODE solving and optimization (default: 1e-14)
- `rtol::Float64`: Relative tolerance for matrix rank calculations (default: 1e-12)
- `output_precision::Int32`: Output precision for RUR solver (default: 20)

## Solution Filtering and Validation
- `imag_threshold::Float64`: Threshold for ignoring imaginary components (default: 1e-8)
- `clustering_threshold::Float64`: Threshold for solution clustering (default: 1e-5)
- `max_error_threshold::Float64`: Maximum acceptable error for valid solutions (default: 0.5)
- `verification_threshold::Float64`: Threshold for solution verification (default: 1e-8)
- `complex_threshold::Float64`: Threshold for detecting complex numbers (default: 1e-10)

## Multi-point and Multi-shot Parameters
- `max_num_points::Int`: Maximum number of points for multi-point estimation (default: 1)
- `shooting_points::Int`: Number of shooting points for multi-shot estimation (default: 8)
- `point_hint::Float64`: Hint for time point selection, in [0,1] range (default: 0.5)

## Derivative and Reconstruction Parameters
- `max_deriv_level::Int`: Maximum allowed derivative level (default: 10)
- `max_reconstruction_attempts::Int`: Max attempts to reconstruct non-zero-dimensional systems (default: 10)
- `digits::Int`: Precision for rational number conversion (default: 10)

## Optimization Parameters
- `polish_solutions::Bool`: Whether to polish solutions using optimization (default: false)
- `polish_solver_solutions::Bool`: Polish raw solver solutions with fast NLLS (default: false)
- `polish_method::PolishMethod`: Optimization method for polishing (default: `PolishNewtonTrust`)
- `polish_maxiters::Int`: Maximum iterations for solution polishing (default: 10)
- `opt_maxiters::Int`: Maximum iterations for general optimization (default: 10000)
- `opt_lb::Vector{Float64}`: Lower bounds for optimization (default: fill(-3.0, n_params))
- `opt_ub::Vector{Float64}`: Upper bounds for optimization (default: fill(3.0, n_params))
- `opt_ad_backend::Symbol`: AD backend for optimization: `:forward` (default), `:zygote`, `:enzyme`, `:finite`

## Data Sampling Parameters
- `datasize::Int`: Number of data points to generate (default: 21)
- `time_interval::Vector{Float64}`: Time interval for sampling (default: [-0.5, 0.5])
- `noise_level::Float64`: Level of noise to add to synthetic data (default: 0.0)
- `uneven_sampling::Bool`: Whether to use uneven time sampling (default: false)
- `uneven_sampling_times::Vector{Float64}`: Custom sampling times (default: Float64[])

## Debug and Output Flags
- `nooutput::Bool`: Suppress output messages (default: false)
- `diagnostics::Bool`: Enable diagnostic output (default: true)
- `debug_solver::Bool`: Enable solver debugging (default: false)
- `debug_cas_diagnostics::Bool`: Enable CAS system diagnostics (default: false)
- `debug_dimensional_analysis::Bool`: Enable dimensional analysis debugging (default: false)
- `trap_debug::Bool`: Enable debug trapping with file output (default: false)
- `profile_phases::Bool`: Print per-phase timing/allocation breakdown (default: false)

## Feature Flags
- `flow::EstimationFlow`: Which workflow to run (default: `FlowStandard`)
- `use_si_template::Bool`: Use StructuralIdentifiability.jl templates (default: true)
- `try_more_methods::Bool`: Try additional estimation methods on failure (default: true)
- `save_system::Bool`: Save polynomial systems to files (default: true)
- `display_system::Bool`: Display system being solved (default: false)
- `polish_only::Bool`: Only polish existing solutions (default: false)
- `ideal::Bool`: Use ideal (noise-free) system construction (default: false)
- `compute_uncertainty::Bool`: Compute parameter uncertainty via GP covariance + IFT (default: false)
- `auto_handle_transcendentals::Bool`: Automatically detect and handle sin/cos/exp(c*t) in equations (default: true)

## HomotopyContinuation Specific
- `use_monodromy::Bool`: Use monodromy for HomotopyContinuation (default: false)
- `use_parameter_homotopy::Bool`: Use parameter homotopy for multi-shot estimation (default: false). When enabled, tracks solutions between shooting points instead of solving from scratch at each point. Can provide 2-20x speedup for shooting_points >= 3.
- `hc_real_tol::Float64`: Tolerance for real solutions in HC (default: 1e-9)
- `hc_show_progress::Bool`: Show HC solving progress (default: false)

## StructuralIdentifiability Parameters
- `si_probability::Float64`: Probability threshold for identifiability analysis (default: 0.99)
- `si_p_mod::Float64`: Modified probability parameter (default: 0.0)
- `si_infolevel::Int`: Information level for SI.jl output (default: 0)

## File I/O
- `log_dir::String`: Directory for log files (default: "logs")
- `save_filepath::String`: Path for saving polynomial systems (default: "")

## Solution Limits
- `max_solutions::Int`: Maximum number of solutions to consider (default: 20)

# Constructors

```julia
# Create with all defaults
opts = EstimationOptions()

# Create with custom tolerances
opts = EstimationOptions(abstol=1e-12, reltol=1e-12)

# Create with custom solver and interpolator
opts = EstimationOptions(
	system_solver=solve_with_hc,
	interpolator=aaad,
	use_monodromy=true
)

# Create with debugging enabled
opts = EstimationOptions(
	diagnostics=true,
	debug_solver=true,
	debug_cas_diagnostics=true
)
```

# Notes

- This struct is designed to be immutable for thread safety and performance
- Default values are chosen based on extensive testing and should work well for most problems
- For challenging problems, consider adjusting tolerances and enabling `try_more_methods`
- When debugging, enable relevant debug flags and set `nooutput=false`
"""
Base.@kwdef struct EstimationOptions
	# Solver and Algorithm Selection
	system_solver::SystemSolverMethod = SolverHC
	ode_solver::Any = AutoVern9(Rodas4P())  # Any type due to ODE solver type complexity
	interpolator::InterpolatorMethod = InterpolatorAAADGPR
	custom_interpolator::Union{Nothing, Function} = nothing

	# Numerical Tolerances
	abstol::Float64 = 1e-14
	reltol::Float64 = 1e-14
	rtol::Float64 = 1e-12
	output_precision::Int32 = 20

	# Solution Filtering and Validation
	imag_threshold::Float64 = 1e-8
	clustering_threshold::Float64 = 1e-5
	max_error_threshold::Float64 = 0.5
	verification_threshold::Float64 = 1e-8
	complex_threshold::Float64 = 1e-10

	# Multi-point and Multi-shot Parameters
	max_num_points::Int = 1
	shooting_points::Int = 8
	point_hint::Float64 = 0.5

	# Derivative and Reconstruction Parameters
	max_deriv_level::Int = 10
	max_reconstruction_attempts::Int = 10
	digits::Int = 10

	# Optimization Parameters
	polish_solutions::Bool = false
	polish_solver_solutions::Bool = true
	polish_method::PolishMethod = PolishNewtonTrust
	polish_maxiters::Int = 100
	opt_maxiters::Int = 10000
	opt_lb::Union{Nothing, Vector{Float64}} = nothing
	opt_ub::Union{Nothing, Vector{Float64}} = nothing
	opt_ad_backend::Symbol = :forward

	# Data Sampling Parameters
	datasize::Int = 21
	time_interval::Vector{Float64} = [-0.5, 0.5]
	noise_level::Float64 = 0.0
	uneven_sampling::Bool = false
	uneven_sampling_times::Vector{Float64} = Float64[]

	# Debug and Output Flags
	nooutput::Bool = false
	diagnostics::Bool = true
	debug_solver::Bool = false
	debug_cas_diagnostics::Bool = false
	debug_dimensional_analysis::Bool = false
	trap_debug::Bool = false
	profile_phases::Bool = false  # Print per-phase timing/allocation breakdown

	# Feature Flags
	flow::EstimationFlow = FlowStandard
	use_si_template::Bool = true
	try_more_methods::Bool = true
	save_system::Bool = true
	display_system::Bool = false
	polish_only::Bool = false
	ideal::Bool = false
	compute_uncertainty::Bool = false  # Compute parameter uncertainty via GP covariance + IFT
	auto_handle_transcendentals::Bool = true  # Automatically detect and handle sin/cos/exp in equations

	# HomotopyContinuation Specific
	use_monodromy::Bool = false
	use_parameter_homotopy::Bool = false  # Use parameter homotopy for multi-shot (track solutions between points)
	hc_real_tol::Float64 = 1e-9
	hc_show_progress::Bool = false

	# StructuralIdentifiability Parameters
	si_probability::Float64 = 0.99
	si_p_mod::Float64 = 0.0
	si_infolevel::Int = 0

	# File I/O
	log_dir::String = "logs"
	save_filepath::String = ""

	# Solution Limits
	max_solutions::Int = 100
end

"""
	get_solver_function(method::SystemSolverMethod) -> Function

Convert SystemSolverMethod enum to actual solver function.
"""
function get_solver_function(method::SystemSolverMethod)
	if method == SolverRS
		# Check if RS extension is loaded
		if !isdefined(@__MODULE__, :solve_with_rs)
			error("RS solver requested but RS extension is not loaded. Install RS and RationalUnivariateRepresentation packages to use this solver.")
		end
		return solve_with_rs
	elseif method == SolverHC
		return solve_with_hc
	elseif method == SolverNLOpt
		return solve_with_nlopt
	elseif method == SolverFastNLOpt
		return solve_with_fast_nlopt
	elseif method == SolverRobust
		return solve_with_robust
	else
		error("Unknown solver method: $method")
	end
end

"""
	get_interpolator_function(method::InterpolatorMethod, custom::Union{Nothing, Function}=nothing) -> Function

Convert InterpolatorMethod enum to actual interpolator function.
"""
function get_interpolator_function(method::InterpolatorMethod, custom::Union{Nothing, Function} = nothing)
	if method == InterpolatorAAAD
		return aaad
	elseif method == InterpolatorAAADGPR
		return aaad_gpr_pivot
	elseif method == InterpolatorAAADOld
		return aaad_old_reliable
	elseif method == InterpolatorFHD
		return fhd5  # Default to degree 5 FHD
	elseif method == InterpolatorAGP
		return agp_gpr
	elseif method == InterpolatorAGPRobust
		return agp_gpr_robust
	elseif method == InterpolatorCustom
		if isnothing(custom)
			error("InterpolatorCustom selected but no custom_interpolator provided")
		end
		return custom
	else
		error("Unknown interpolator method: $method")
	end
end

"""
	get_polish_optimizer(method::PolishMethod)

Convert PolishMethod enum to actual optimizer object/type.
Returns the optimizer constructor that can be used with NonlinearSolve or Optim.
"""
function get_polish_optimizer(method::PolishMethod)
	if method == PolishNewtonTrust
		return NewtonTrustRegion
	elseif method == PolishLevenberg
		return LevenbergMarquardt
	elseif method == PolishGaussNewton
		return GaussNewton
	elseif method == PolishBFGS
		return BFGS
	elseif method == PolishLBFGS
		return LBFGS
	else
		error("Unknown polish method: $method")
	end
end

"""
	merge_options(base::EstimationOptions; kwargs...) -> EstimationOptions

Create a new EstimationOptions struct by merging keyword arguments with an existing options struct.
This is useful for temporarily overriding specific options.

# Examples
```julia
base_opts = EstimationOptions()
new_opts = merge_options(base_opts; abstol=1e-10, debug_solver=true)
```
"""
function merge_options(base::EstimationOptions; kwargs...)
	# Get all field names and their values from base
	fields = fieldnames(EstimationOptions)
	values = Dict(f => getfield(base, f) for f in fields)

	# Override with any provided kwargs
	for (k, v) in kwargs
		if k in fields
			values[k] = v
		else
			@warn "Unknown option: $k"
		end
	end

	# Create new struct
	return EstimationOptions(; values...)
end

"""
	validate_options(opts::EstimationOptions) -> Bool

Validate that the options struct has sensible values.
Throws warnings for potentially problematic configurations.

# Returns
- `true` if options are valid
- `false` if there are critical issues
"""
function validate_options(opts::EstimationOptions)
	valid = true

	# Check tolerances
	if opts.abstol <= 0 || opts.reltol <= 0
		@error "Tolerances must be positive"
		valid = false
	end

	if opts.abstol < 1e-16 || opts.reltol < 1e-16
		@warn "Extremely small tolerances may cause numerical issues"
	end

	# Check thresholds
	if opts.imag_threshold < 0 || opts.clustering_threshold < 0
		@error "Thresholds must be non-negative"
		valid = false
	end

	# Check multi-point parameters
	if opts.max_num_points < 1
		@error "max_num_points must be at least 1"
		valid = false
	end

	if opts.shooting_points < 2
		@warn "shooting_points should be at least 2 for multi-shot estimation"
	end

	# Check point_hint
	if opts.point_hint < 0 || opts.point_hint > 1
		@error "point_hint must be in [0, 1]"
		valid = false
	end

	# Check derivative level
	if opts.max_deriv_level < 2
		@error "max_deriv_level must be at least 2"
		valid = false
	end

	if opts.max_deriv_level > 20
		@warn "Very high derivative levels (>20) may cause numerical instability"
	end

	# Check optimization bounds
	if !isnothing(opts.opt_lb) && !isnothing(opts.opt_ub)
		if length(opts.opt_lb) != length(opts.opt_ub)
			@error "Optimization bounds must have the same length"
			valid = false
		end
		if any(opts.opt_lb .> opts.opt_ub)
			@error "Lower bounds must not exceed upper bounds"
			valid = false
		end
	end

	# Check data parameters
	if opts.datasize < 3
		@warn "Very small datasize (<3) may lead to underdetermined systems"
	end

	if length(opts.time_interval) != 2 || opts.time_interval[1] >= opts.time_interval[2]
		@error "time_interval must be [t_start, t_end] with t_start < t_end"
		valid = false
	end

	if opts.noise_level < 0
		@error "noise_level must be non-negative"
		valid = false
	end

	# Check SI parameters
	if opts.si_probability <= 0 || opts.si_probability > 1
		@error "si_probability must be in (0, 1]"
		valid = false
	end

	# Warn about conflicting options
	if opts.polish_only && !opts.polish_solutions
		@warn "polish_only=true but polish_solutions=false; no polishing will occur"
	end

	if opts.nooutput && opts.diagnostics
		@info "diagnostics=true but nooutput=true; diagnostic output will be suppressed"
	end

	if opts.ideal && opts.noise_level > 0
		@warn "ideal=true but noise_level > 0; these options may conflict"
	end

	return valid
end

"""
	print_options(io::IO, opts::EstimationOptions; compact=false)

Pretty-print the options struct.

# Arguments
- `io::IO`: Output stream
- `opts::EstimationOptions`: Options to print
- `compact::Bool`: If true, only print non-default values
"""
function print_options(io::IO, opts::EstimationOptions; compact = false)
	defaults = EstimationOptions()

	println(io, "EstimationOptions:")

	categories = [
		("Solver and Algorithm", [:system_solver, :ode_solver, :interpolator]),
		("Tolerances", [:abstol, :reltol, :rtol, :output_precision]),
		("Solution Validation", [:imag_threshold, :clustering_threshold, :max_error_threshold,
			:verification_threshold, :complex_threshold]),
		("Multi-point/Multi-shot", [:max_num_points, :shooting_points, :point_hint]),
		("Derivatives and Reconstruction", [:max_deriv_level, :max_reconstruction_attempts, :digits]),
		("Optimization", [:polish_solutions, :polish_solver_solutions, :polish_method, :polish_maxiters, :opt_maxiters,
			:opt_lb, :opt_ub]),
		("Data Sampling", [:datasize, :time_interval, :noise_level, :uneven_sampling,
			:uneven_sampling_times]),
		("Debug Flags", [:nooutput, :diagnostics, :debug_solver, :debug_cas_diagnostics,
			:debug_dimensional_analysis, :trap_debug, :profile_phases]),
		("Feature Flags", [:flow, :use_si_template, :try_more_methods, :save_system,
			:display_system, :polish_only, :ideal, :compute_uncertainty, :auto_handle_transcendentals]),
		("HomotopyContinuation", [:use_monodromy, :use_parameter_homotopy, :hc_real_tol, :hc_show_progress]),
		("StructuralIdentifiability", [:si_probability, :si_p_mod, :si_infolevel]),
		("File I/O", [:log_dir, :save_filepath]),
		("Limits", [:max_solutions]),
	]

	for (category, fields) in categories
		printed_header = false
		for field in fields
			val = getfield(opts, field)
			default_val = getfield(defaults, field)

			if !compact || val != default_val
				if !printed_header
					println(io, "\n  $category:")
					printed_header = true
				end

				# Special formatting for functions
				if isa(val, Function)
					val_str = string(val)
				else
					val_str = repr(val)
				end

				if compact && val != default_val
					println(io, "    $field: $val_str (default: $(repr(default_val)))")
				else
					println(io, "    $field: $val_str")
				end
			end
		end
	end
end

# Define show method for pretty printing
Base.show(io::IO, opts::EstimationOptions) = print_options(io, opts; compact = true)

"""
	get_solver_options_dict(opts::EstimationOptions) -> Dict

Extract solver-specific options as a Dict for backward compatibility with existing solver functions.
"""
function get_solver_options_dict(opts::EstimationOptions)
	return Dict(
		:debug_solver => opts.debug_solver,
		:debug_cas_diagnostics => opts.debug_cas_diagnostics,
		:debug_dimensional_analysis => opts.debug_dimensional_analysis,
		:output_precision => opts.output_precision,
		:abstol => opts.abstol,
		:reltol => opts.reltol,
		:display_system => opts.display_system,
		:save_system => opts.save_system,
		:save_filepath => opts.save_filepath,
		:use_monodromy => opts.use_monodromy,
		:real_tol => opts.hc_real_tol,
		:show_progress => opts.hc_show_progress,
		:polish_only => opts.polish_only,
		:maxiters => opts.opt_maxiters,
	)
end
