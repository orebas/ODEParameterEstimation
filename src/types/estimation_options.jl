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
	InterpolatorAGPRobustRQ    # agp_gpr_robust with Rational Quadratic kernel
	InterpolatorAGPRobustSEpRQ # agp_gpr_robust with SE + RQ sum kernel
	InterpolatorAGPRobustSExRQ # agp_gpr_robust with SE * RQ product kernel
	InterpolatorAGPRobustMatern52 # agp_gpr_robust with Matérn-5/2 kernel
	InterpolatorS2AAAMLE           # S2 composite: AAA(raw data) → MLE (no GP)
	InterpolatorS3SE               # S3 composite: GP(SE) → AAA → MLE (deprecated — forwards to AdaptSE)
	InterpolatorS3RQ               # S3 composite: GP(RQ) → AAA → MLE (deprecated — forwards to AdaptRQ)
	InterpolatorS3SEpRQ            # S3 composite: GP(SE+RQ) → AAA → MLE (deprecated — forwards to AdaptSEpRQ)
	InterpolatorS3SExRQ            # S3 composite: GP(SE×RQ) → AAA → MLE (deprecated — forwards to AdaptSExRQ)
	InterpolatorS3Matern52         # S3 composite: GP(Matérn-5/2) → AAA → MLE (deprecated — forwards to AdaptMatern52)
	InterpolatorS3AdaptSE          # S3 adaptive-tol: GP(SE) → AAA(adaptive) → MLE
	InterpolatorS3AdaptRQ          # S3 adaptive-tol: GP(RQ) → AAA(adaptive) → MLE
	InterpolatorS3AdaptSEpRQ       # S3 adaptive-tol: GP(SE+RQ) → AAA(adaptive) → MLE
	InterpolatorS3AdaptSExRQ       # S3 adaptive-tol: GP(SE×RQ) → AAA(adaptive) → MLE
	InterpolatorS3AdaptMatern52    # S3 adaptive-tol: GP(Matérn-5/2) → AAA(adaptive) → MLE
	InterpolatorS3BICSE            # S3 BIC: GP(SE) → AAA(BIC-selected) → MLE
	InterpolatorS3BICRQ            # S3 BIC: GP(RQ) → AAA(BIC-selected) → MLE
	InterpolatorS3BICSEpRQ         # S3 BIC: GP(SE+RQ) → AAA(BIC-selected) → MLE
	InterpolatorS3BICSExRQ         # S3 BIC: GP(SE×RQ) → AAA(BIC-selected) → MLE
	InterpolatorS3BICMatern52      # S3 BIC: GP(Matérn-5/2) → AAA(BIC-selected) → MLE
	InterpolatorAGPUQ          # agp_gpr_uq - GP with full UQ (for calibrated uncertainty)
	InterpolatorChebyshevAICc  # Chebyshev polynomial with AICc degree selection (spectral)
	InterpolatorChebyshevBIC   # Chebyshev polynomial with BIC degree selection (spectral)
	InterpolatorFourierAdaptive # FFT spectral differentiation with adaptive filtering
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

- `FlowStandard`: New optimized multishot workflow (default)
- `FlowDirectOpt`: Direct local optimization workflow (BFGS from random start)
"""
@enum EstimationFlow begin
	FlowStandard     # optimized_multishot_parameter_estimation
	FlowDirectOpt    # direct_optimization_parameter_estimation
end

const SI_PLACEHOLDER_CATEGORY_ALIASES = Dict{Symbol, Symbol}(
	:dd_derivative_unmapped => :observable_derivative_overflow,
	:nonobservable_derivative => :support_jet,
	:state_or_input_jet => :support_jet,
	:unknown_variable => :true_unknown_variable,
)

const SI_PLACEHOLDER_CANONICAL_CATEGORIES = Set((
	:dd_observable_index_oob,
	:observable_derivative_overflow,
	:measured_rhs_jet,
	:state_jet,
	:parameter_or_ic_symbol,
	:transformed_analytic_support,
	:support_jet,
	:no_dd_derivative,
	:sian_auxiliary,
	:true_unknown_variable,
	:late_map_miss,
))

const SI_PLACEHOLDER_VALID_CATEGORIES = union(
	SI_PLACEHOLDER_CANONICAL_CATEGORIES,
	Set(keys(SI_PLACEHOLDER_CATEGORY_ALIASES)),
)

canonicalize_si_placeholder_category(category::Symbol) = get(SI_PLACEHOLDER_CATEGORY_ALIASES, category, category)

normalize_si_placeholder_fail_categories(categories) =
	unique(Symbol[canonicalize_si_placeholder_category(cat) for cat in categories])

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
- `shooting_points::Int`: Number of shooting points for multi-shot estimation (default: 12)
- `shooting_warp::Bool`: Use exponential warp to cluster points near t=0 (default: true)
- `shooting_warp_beta::Float64`: Warp strength; 0≈uniform, 3=default (default: 3.0)
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
- `opt_ad_backend::Symbol`: AD backend for optimization: `:forward` (default), `:enzyme`, `:finite`
- `polish_maxtime::Float64`: Per-solution wall-clock timeout in seconds (default: 300.0)
- `polish_divergence_factor::Float64`: Stop polish if loss exceeds initial_loss * this factor (default: 10.0)
- `polish_stagnation_window::Int`: Stop polish if no improvement in this many iterations (default: 50)
- `polish_ode_maxiters::Int`: ODE solver maxiters inside polish loss function (default: 5000). DiffEq default is 100000 but successful stiff solves typically use 500-2000 steps. Capping at 5000 fails fast on hopeless parameter regions.
- `terminal_fallback::Symbol`: Terminal rescue if algebraic search yields no candidates: `:none` or `:direct_opt` (default: `:none`)
- `backsolve_recovery::Symbol`: Recovery policy for blown backsolves: `:none` or `:algebraic_resolve` (default: `:algebraic_resolve`)
- `t0_state_completion::Symbol`: State completion policy during `t=0` rescue: `:strict` or `:seed_for_polish` (default: `:strict`)

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
- `save_system::Bool`: Save polynomial systems to files (default: true)
- `display_system::Bool`: Display system being solved (default: false)
- `polish_only::Bool`: Only polish existing solutions (default: false)
- `ideal::Bool`: Use ideal (noise-free) system construction (default: false)
- `compute_uncertainty::Bool`: Compute parameter uncertainty via GP covariance + IFT (default: false)
- `uq_failure_policy::Symbol`: Experimental UQ sidecar failure policy: `:return_failed` or `:throw` (default: `:return_failed`)
- `si_placeholder_fail_categories::Vector{Symbol}`: Temporary strictness gate for SI mapping categories. Accepts canonical semantic names and recent compatibility aliases. Empty preserves current behavior.
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
- For challenging problems, use an explicit `interpolators = [...]` list rather than relying on hidden retries
- When debugging, enable relevant debug flags and set `nooutput=false`
"""
Base.@kwdef struct EstimationOptions
	# Solver and Algorithm Selection
	system_solver::SystemSolverMethod = SolverHC
	ode_solver::Any = AutoVern9(Rodas4P())  # Any type due to ODE solver type complexity
	interpolator::InterpolatorMethod = InterpolatorAAADGPR
	custom_interpolator::Union{Nothing, Function} = nothing

	# Multi-interpolator support: when non-empty, overrides `interpolator` field
	interpolators::Vector{InterpolatorMethod} = InterpolatorMethod[]
	custom_interpolators::Vector{Function} = Function[]

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
	shooting_points::Int = 12
	shooting_warp::Bool = true                   # true = exponential warp, false = equidistant
	shooting_warp_beta::Float64 = 3.0            # warp strength (0≈uniform, 3=default)
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
	polish_maxtime::Float64 = 300.0          # Per-solution wall-clock timeout (seconds)
	polish_divergence_factor::Float64 = 10.0 # Stop if loss > initial_loss * this
	polish_stagnation_window::Int = 50       # Stop if no improvement in N iters
	polish_ode_maxiters::Int = 5000          # ODE solver maxiters inside polish loss (DiffEq default: 100000)
	terminal_fallback::Symbol = :none        # :none | :direct_opt
	backsolve_recovery::Symbol = :algebraic_resolve  # :none | :algebraic_resolve
	t0_state_completion::Symbol = :strict    # :strict | :seed_for_polish

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
	save_system::Bool = true
	display_system::Bool = false
	polish_only::Bool = false
	ideal::Bool = false
	compute_uncertainty::Bool = false  # Experimental GP/IFT sidecar
	uq_failure_policy::Symbol = :return_failed  # :return_failed | :throw
	si_placeholder_fail_categories::Vector{Symbol} = Symbol[]
	auto_handle_transcendentals::Bool = true  # Automatically detect and handle sin/cos/exp in equations
	gp_s3_refinement::Bool = false  # If true, each GP interpolator also produces an S3 (GP→AAA→MLE) barycentric
	s3_adapt_k::Float64 = 10.0     # Noise multiplier for S3 adaptive tolerance (higher = fewer support points)

	# HomotopyContinuation Specific
	use_monodromy::Bool = false
	use_parameter_homotopy::Bool = true  # Use parameter homotopy for multi-shot (track solutions between points)
	hc_real_tol::Float64 = 1e-9
	hc_show_progress::Bool = false

	# Multi-point template (combines polynomial systems from N time points)
	use_multipoint::Bool = false  # Enable multi-point polynomial template system
	multipoint_n_points::Int = 2  # Number of time points per evaluation (2 recommended)
	multipoint_max_pairs::Int = 20  # Maximum number of time point pairs to solve

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
	get_interpolator_function(method::InterpolatorMethod, custom::Union{Nothing, Function}=nothing; s3_adapt_k=10.0) -> Function

Convert InterpolatorMethod enum to actual interpolator function.
The `s3_adapt_k` keyword controls the noise multiplier for S3 adaptive-tolerance methods.
"""
function get_interpolator_function(method::InterpolatorMethod, custom::Union{Nothing, Function} = nothing;
                                   s3_adapt_k::Float64 = 10.0)
	if method == InterpolatorCustom
		if isnothing(custom)
			error("InterpolatorCustom selected but no custom_interpolator provided")
		end
		return custom
	end
	# If a custom override was provided (e.g., from GP caching layer), use it
	if custom !== nothing
		return custom
	end
	if method == InterpolatorAAAD
		return aaad
	elseif method == InterpolatorAAADGPR
		return aaad_gpr_pivot
	elseif method == InterpolatorAAADOld
		return aaad_old_reliable
	elseif method == InterpolatorFHD
		return fhdn(5)  # Default to degree 5 FHD
	elseif method == InterpolatorAGP
		return agp_gpr_robust
	elseif method == InterpolatorAGPUQ
		return agp_gpr_uq
	elseif method == InterpolatorAGPRobust
		return agp_gpr_robust
	elseif method == InterpolatorAGPRobustRQ
		return (xs, ys) -> agp_gpr_robust(xs, ys; kernel_type=:rq)
	elseif method == InterpolatorAGPRobustSEpRQ
		return (xs, ys) -> agp_gpr_robust(xs, ys; kernel_type=:se_plus_rq)
	elseif method == InterpolatorAGPRobustSExRQ
		return (xs, ys) -> agp_gpr_robust(xs, ys; kernel_type=:se_times_rq)
	elseif method == InterpolatorAGPRobustMatern52
		return (xs, ys) -> agp_gpr_robust(xs, ys; kernel_type=:matern52)
	elseif method == InterpolatorS2AAAMLE
		return s2_aaa_mle_interpolator
	# --- S3 Adaptive tolerance ---
	elseif method == InterpolatorS3AdaptSE
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3AdaptRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3AdaptSEpRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_plus_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3AdaptSExRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_times_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3AdaptMatern52
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_matern52_interpolator(xs, ys; k = k)
	# --- S3 BIC model selection ---
	elseif method == InterpolatorS3BICSE
		return s3_bic_se_interpolator
	elseif method == InterpolatorS3BICRQ
		return s3_bic_rq_interpolator
	elseif method == InterpolatorS3BICSEpRQ
		return s3_bic_se_plus_rq_interpolator
	elseif method == InterpolatorS3BICSExRQ
		return s3_bic_se_times_rq_interpolator
	elseif method == InterpolatorS3BICMatern52
		return s3_bic_matern52_interpolator
	# --- Old S3 names (deprecated, forward to adaptive) ---
	elseif method == InterpolatorS3SE
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3RQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3SEpRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_plus_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3SExRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_times_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3Matern52
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_matern52_interpolator(xs, ys; k = k)
	elseif method == InterpolatorChebyshevAICc
		return chebyshev_aicc
	elseif method == InterpolatorChebyshevBIC
		return chebyshev_bic
	elseif method == InterpolatorFourierAdaptive
		return fourier_adaptive
	else
		error("Unknown interpolator method: $method")
	end
end

"""
	interpolator_method_to_symbol(method::InterpolatorMethod) -> Symbol

Convert an InterpolatorMethod enum value to a Symbol for tagging results.
"""
function interpolator_method_to_symbol(method::InterpolatorMethod)
	method == InterpolatorAAAD && return :aaad
	method == InterpolatorAAADGPR && return :aaad_gpr
	method == InterpolatorAAADOld && return :aaad_old
	method == InterpolatorFHD && return :fhd
	method == InterpolatorAGP && return :agp
	method == InterpolatorAGPUQ && return :agp_uq
	method == InterpolatorAGPRobust && return :agp_robust
	method == InterpolatorAGPRobustRQ && return :agp_robust_rq
	method == InterpolatorAGPRobustSEpRQ && return :agp_robust_se_plus_rq
	method == InterpolatorAGPRobustSExRQ && return :agp_robust_se_times_rq
	method == InterpolatorAGPRobustMatern52 && return :agp_robust_matern52
	method == InterpolatorS2AAAMLE && return :s2_aaa_mle
	method == InterpolatorS3SE && return :s3_se
	method == InterpolatorS3RQ && return :s3_rq
	method == InterpolatorS3SEpRQ && return :s3_se_plus_rq
	method == InterpolatorS3SExRQ && return :s3_se_times_rq
	method == InterpolatorS3Matern52 && return :s3_matern52
	method == InterpolatorS3AdaptSE && return :s3_adapt_se
	method == InterpolatorS3AdaptRQ && return :s3_adapt_rq
	method == InterpolatorS3AdaptSEpRQ && return :s3_adapt_se_plus_rq
	method == InterpolatorS3AdaptSExRQ && return :s3_adapt_se_times_rq
	method == InterpolatorS3AdaptMatern52 && return :s3_adapt_matern52
	method == InterpolatorS3BICSE && return :s3_bic_se
	method == InterpolatorS3BICRQ && return :s3_bic_rq
	method == InterpolatorS3BICSEpRQ && return :s3_bic_se_plus_rq
	method == InterpolatorS3BICSExRQ && return :s3_bic_se_times_rq
	method == InterpolatorS3BICMatern52 && return :s3_bic_matern52
	method == InterpolatorChebyshevAICc && return :chebyshev_aicc
	method == InterpolatorChebyshevBIC && return :chebyshev_bic
	method == InterpolatorFourierAdaptive && return :fourier_adaptive
	method == InterpolatorCustom && return :custom
	return :unknown
end

"""
	is_gp_interpolator(method::InterpolatorMethod) -> Bool

Returns true if the interpolator method is a GP-based method that supports S3 refinement.
"""
function is_gp_interpolator(method::InterpolatorMethod)::Bool
	return method in (InterpolatorAGPRobust, InterpolatorAGPRobustRQ,
	                  InterpolatorAGPRobustSEpRQ, InterpolatorAGPRobustSExRQ,
	                  InterpolatorAGPRobustMatern52,
	                  InterpolatorAGP, InterpolatorAGPUQ)
end

"""
	is_matern_interpolator(method::InterpolatorMethod) -> Bool

Returns true if the interpolator is Matérn-5/2, which is only C² smooth and
cannot produce valid 3rd+ order derivatives from raw GP output.
"""
function is_matern_interpolator(method::InterpolatorMethod)::Bool
	return method in (InterpolatorAGPRobustMatern52,
	                  InterpolatorS3Matern52, InterpolatorS3AdaptMatern52, InterpolatorS3BICMatern52)
end

"""
	s3_symbol(method::InterpolatorMethod) -> Symbol

Map a GP interpolator method to its S3 companion tag symbol.
"""
function s3_symbol(method::InterpolatorMethod)::Symbol
	method == InterpolatorAGPRobust && return :s3_adapt_se
	method == InterpolatorAGPRobustRQ && return :s3_adapt_rq
	method == InterpolatorAGPRobustSEpRQ && return :s3_adapt_se_plus_rq
	method == InterpolatorAGPRobustSExRQ && return :s3_adapt_se_times_rq
	method == InterpolatorAGPRobustMatern52 && return :s3_adapt_matern52
	method == InterpolatorAGP && return :s3_adapt_se
	return :s3_unknown
end

"""
	resolve_interpolator_list(opts::EstimationOptions) -> Vector{Tuple{InterpolatorMethod, Union{Nothing, Function}}}

Resolve the list of interpolators to run. If `opts.interpolators` is empty, falls back to
the single `opts.interpolator` field for backward compatibility.

Returns a vector of `(method, custom_func_or_nothing)` tuples.
"""
function resolve_interpolator_list(opts::EstimationOptions)
	if isempty(opts.interpolators)
		result = Tuple{InterpolatorMethod, Union{Nothing, Function}}[(opts.interpolator, opts.custom_interpolator)]
	else
		result = Vector{Tuple{InterpolatorMethod, Union{Nothing, Function}}}()
		custom_idx = 0
		for method in opts.interpolators
			if method == InterpolatorCustom
				custom_idx += 1
				func = custom_idx <= length(opts.custom_interpolators) ? opts.custom_interpolators[custom_idx] : nothing
				push!(result, (method, func))
			else
				push!(result, (method, nothing))
			end
		end
	end

	# Backward compat: auto-expand GP methods when gp_s3_refinement=true
	if opts.gp_s3_refinement
		@warn "gp_s3_refinement is deprecated. Add InterpolatorS3AdaptSE etc. to your interpolators list directly." maxlog=1
		gp_to_s3 = Dict(
			InterpolatorAGPRobust => InterpolatorS3AdaptSE,
			InterpolatorAGPRobustRQ => InterpolatorS3AdaptRQ,
			InterpolatorAGPRobustSEpRQ => InterpolatorS3AdaptSEpRQ,
			InterpolatorAGPRobustSExRQ => InterpolatorS3AdaptSExRQ,
			InterpolatorAGPRobustMatern52 => InterpolatorS3AdaptMatern52,
		)
		for (m, _) in copy(result)
			haskey(gp_to_s3, m) && push!(result, (gp_to_s3[m], nothing))
		end
	end

	# Inject GP caching for shared kernels
	_inject_gp_caching!(result; s3_adapt_k = opts.s3_adapt_k)

	return result
end

"""
	_gp_kernel_of(method::InterpolatorMethod) -> Union{Nothing, Symbol}

Map any GP-based interpolator method to its kernel type, or `nothing` if not GP-based.
"""
function _gp_kernel_of(method::InterpolatorMethod)::Union{Nothing, Symbol}
	method == InterpolatorAGPRobust && return :se
	method == InterpolatorAGPRobustRQ && return :rq
	method == InterpolatorAGPRobustSEpRQ && return :se_plus_rq
	method == InterpolatorAGPRobustSExRQ && return :se_times_rq
	method == InterpolatorAGPRobustMatern52 && return :matern52
	# Old S3 names
	method == InterpolatorS3SE && return :se
	method == InterpolatorS3RQ && return :rq
	method == InterpolatorS3SEpRQ && return :se_plus_rq
	method == InterpolatorS3SExRQ && return :se_times_rq
	method == InterpolatorS3Matern52 && return :matern52
	# S3 Adaptive
	method == InterpolatorS3AdaptSE && return :se
	method == InterpolatorS3AdaptRQ && return :rq
	method == InterpolatorS3AdaptSEpRQ && return :se_plus_rq
	method == InterpolatorS3AdaptSExRQ && return :se_times_rq
	method == InterpolatorS3AdaptMatern52 && return :matern52
	# S3 BIC
	method == InterpolatorS3BICSE && return :se
	method == InterpolatorS3BICRQ && return :rq
	method == InterpolatorS3BICSEpRQ && return :se_plus_rq
	method == InterpolatorS3BICSExRQ && return :se_times_rq
	method == InterpolatorS3BICMatern52 && return :matern52
	return nothing
end

"""
	_is_s3_method(method::InterpolatorMethod) -> Bool

Returns true if the interpolator method is an S3 composite (GP→AAA→MLE).
"""
function _is_s3_method(method::InterpolatorMethod)::Bool
	return method in (InterpolatorS3SE, InterpolatorS3RQ, InterpolatorS3SEpRQ,
	                  InterpolatorS3SExRQ, InterpolatorS3Matern52,
	                  InterpolatorS3AdaptSE, InterpolatorS3AdaptRQ, InterpolatorS3AdaptSEpRQ,
	                  InterpolatorS3AdaptSExRQ, InterpolatorS3AdaptMatern52,
	                  InterpolatorS3BICSE, InterpolatorS3BICRQ, InterpolatorS3BICSEpRQ,
	                  InterpolatorS3BICSExRQ, InterpolatorS3BICMatern52)
end

"""
	_is_s3_adapt_method(method::InterpolatorMethod) -> Bool

Returns true for S3 adaptive-tolerance methods (including deprecated old S3 names).
"""
function _is_s3_adapt_method(method::InterpolatorMethod)::Bool
	return method in (InterpolatorS3AdaptSE, InterpolatorS3AdaptRQ, InterpolatorS3AdaptSEpRQ,
	                  InterpolatorS3AdaptSExRQ, InterpolatorS3AdaptMatern52,
	                  InterpolatorS3SE, InterpolatorS3RQ, InterpolatorS3SEpRQ,
	                  InterpolatorS3SExRQ, InterpolatorS3Matern52)
end

"""
	_is_s3_bic_method(method::InterpolatorMethod) -> Bool

Returns true for S3 BIC model-selection methods.
"""
function _is_s3_bic_method(method::InterpolatorMethod)::Bool
	return method in (InterpolatorS3BICSE, InterpolatorS3BICRQ, InterpolatorS3BICSEpRQ,
	                  InterpolatorS3BICSExRQ, InterpolatorS3BICMatern52)
end

"""
	_make_cached_gp_func(kernel_type, cache) -> Function

Create a closure that fits a GP and stores it in the shared cache, keyed by `hash(ys)`.
"""
function _make_cached_gp_func(kernel_type::Symbol, cache::Dict{UInt64, Any})
	return function(xs, ys)
		key = hash(ys)
		gp = agp_gpr_robust(Vector{Float64}(xs), Vector{Float64}(ys); kernel_type = kernel_type)
		cache[key] = gp
		return gp
	end
end

"""
	_make_cached_s3_func(kernel_type, cache) -> Function

Create a closure that reuses a cached GP (if available) for S3 refinement.
On cache miss, fits the GP internally.
DEPRECATED: use `_make_cached_s3_adapt_func` instead.
"""
function _make_cached_s3_func(kernel_type::Symbol, cache::Dict{UInt64, Any})
	return _make_cached_s3_adapt_func(kernel_type, cache)
end

"""
	_make_cached_s3_adapt_func(kernel_type, cache; k=10.0) -> Function

Create a closure that reuses a cached GP for S3 adaptive-tolerance refinement.
"""
function _make_cached_s3_adapt_func(kernel_type::Symbol, cache::Dict{UInt64, Any}; k::Float64 = 10.0)
	return function(xs, ys)
		key = hash(ys)
		t_vec = Vector{Float64}(xs)
		y_vec = Vector{Float64}(ys)
		gp = get(cache, key, nothing)
		if gp === nothing
			gp = agp_gpr_robust(t_vec, y_vec; kernel_type = kernel_type)
		end
		return s3_refine_gp_adaptive(gp, t_vec, y_vec; k = k)
	end
end

"""
	_make_cached_s3_bic_func(kernel_type, cache) -> Function

Create a closure that reuses a cached GP for S3 BIC model-selection refinement.
"""
function _make_cached_s3_bic_func(kernel_type::Symbol, cache::Dict{UInt64, Any})
	return function(xs, ys)
		key = hash(ys)
		t_vec = Vector{Float64}(xs)
		y_vec = Vector{Float64}(ys)
		gp = get(cache, key, nothing)
		if gp === nothing
			gp = agp_gpr_robust(t_vec, y_vec; kernel_type = kernel_type)
		end
		return s3_refine_gp_bic(gp, t_vec, y_vec)
	end
end

"""
	_inject_gp_caching!(interpolator_list; s3_adapt_k=10.0)

For interpolator methods that share a GP kernel (e.g., AGPRobust + S3SE both use SE),
inject closure-wrapped functions that share a `Dict` cache so the GP is fitted only once.
"""
function _inject_gp_caching!(interpolator_list::Vector{Tuple{InterpolatorMethod, Union{Nothing, Function}}};
                              s3_adapt_k::Float64 = 10.0)
	# Count how many methods share each GP kernel
	kernel_counts = Dict{Symbol, Int}()
	for (method, _) in interpolator_list
		kt = _gp_kernel_of(method)
		kt !== nothing && (kernel_counts[kt] = get(kernel_counts, kt, 0) + 1)
	end
	shared_kernels = Set(k for (k, c) in kernel_counts if c > 1)
	isempty(shared_kernels) && return

	# Create per-kernel caches
	caches = Dict(k => Dict{UInt64, Any}() for k in shared_kernels)

	# Replace functions for methods that share a kernel
	for i in eachindex(interpolator_list)
		method, custom = interpolator_list[i]
		custom !== nothing && continue  # don't override user-provided functions
		kt = _gp_kernel_of(method)
		kt === nothing && continue
		kt ∉ shared_kernels && continue
		cache = caches[kt]
		if _is_s3_bic_method(method)
			interpolator_list[i] = (method, _make_cached_s3_bic_func(kt, cache))
		elseif _is_s3_method(method)  # covers adapt + old S3
			interpolator_list[i] = (method, _make_cached_s3_adapt_func(kt, cache; k = s3_adapt_k))
		else
			interpolator_list[i] = (method, _make_cached_gp_func(kt, cache))
		end
	end
end

"""
	compute_shooting_indices(n_points, n_total; warp=true, beta=3.0) -> Vector{Int}

Compute shooting point indices across a time vector of length `n_total`.

When `warp=true` and `beta > 0`, uses an exponential warp to cluster more points
near the start of the interval (where transient dynamics are typically richest).
When `warp=false` or `beta ≈ 0`, returns equidistant indices.

Returns a sorted vector of unique indices in `[1, n_total]`.
"""
function compute_shooting_indices(n_points::Int, n_total::Int; warp::Bool = true, beta::Float64 = 3.0)
	n_total <= 0 && return Int[]
	n_total == 1 && return [1]
	n_total == 2 && return [1, 2]
	n_points <= 0 && return [max(1, n_total ÷ 2)]
	n_points == 1 && return [1]
	n_points >= n_total && return collect(1:n_total)

	if !warp || abs(beta) < 1e-10
		# Equidistant
		indices = round.(Int, range(1, n_total, length = n_points))
	else
		u = range(0.0, 1.0, length = n_points)
		frac = (exp.(beta .* u) .- 1) ./ (exp(beta) - 1)
		indices = round.(Int, 1 .+ frac .* (n_total - 1))
		indices = clamp.(indices, 1, n_total)
	end
	return unique(indices)
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
	get_ad_backend(backend::Symbol)

Convert AD backend symbol to an Optimization.jl AD type.

# Supported backends
- `:forward` → `AutoForwardDiff()` (default, works with most problems)
- `:enzyme` → `AutoEnzyme()` (compiler-based AD)
- `:finite` → `AutoFiniteDiff()` (fallback, no AD required)

Note: `:zygote` was removed — Zygote segfaults Julia 1.12's JIT compiler.
ForwardDiff is the recommended backend (only one that works through adaptive ODE solvers).
"""
function get_ad_backend(backend::Symbol)
	backend === :forward && return Optimization.AutoForwardDiff()
	# backend === :zygote && return Optimization.AutoZygote()  # Disabled: segfaults Julia 1.12
	backend === :enzyme && return Optimization.AutoEnzyme()
	backend === :finite && return Optimization.AutoFiniteDiff()
	error("Unknown AD backend :$backend. Supported backends: :forward, :enzyme, :finite")
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
			error("Unknown option: $k")
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

	if opts.shooting_points < 0
		@error "shooting_points must be non-negative"
		valid = false
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

	# Check polish safeguard parameters
	if opts.polish_maxtime <= 0
		@warn "polish_maxtime must be positive; using default (300s)"
	end
	if opts.polish_stagnation_window < 5
		@warn "polish_stagnation_window < 5 is too aggressive; may stop prematurely"
	end
	if !(opts.terminal_fallback in (:none, :direct_opt))
		@error "terminal_fallback must be :none or :direct_opt"
		valid = false
	end
	if !(opts.backsolve_recovery in (:none, :algebraic_resolve))
		@error "backsolve_recovery must be :none or :algebraic_resolve"
		valid = false
	end
	if !(opts.t0_state_completion in (:strict, :seed_for_polish))
		@error "t0_state_completion must be :strict or :seed_for_polish"
		valid = false
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

	if opts.terminal_fallback != :none && opts.flow == FlowDirectOpt
		@error "terminal_fallback only applies to FlowStandard. FlowDirectOpt already is the terminal optimizer."
		valid = false
	end

	if opts.backsolve_recovery != :none && opts.flow != FlowStandard
		@info "backsolve_recovery is ignored outside FlowStandard"
	end

	if opts.t0_state_completion != :strict && opts.flow != FlowStandard
		@info "t0_state_completion is ignored outside FlowStandard"
	end

	if opts.t0_state_completion == :seed_for_polish && !opts.polish_solutions
		@warn "t0_state_completion=:seed_for_polish requires polish_solutions=true to be useful"
	end

	if !(opts.uq_failure_policy in (:return_failed, :throw))
		@error "uq_failure_policy must be :return_failed or :throw"
		valid = false
	end

	invalid_placeholder_categories = [cat for cat in opts.si_placeholder_fail_categories if !(cat in SI_PLACEHOLDER_VALID_CATEGORIES)]
	if !isempty(invalid_placeholder_categories)
		@error "Unknown si_placeholder_fail_categories: $(invalid_placeholder_categories)"
		valid = false
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
		("Solver and Algorithm", [:system_solver, :ode_solver, :interpolator, :interpolators]),
		("Tolerances", [:abstol, :reltol, :rtol, :output_precision]),
		("Solution Validation", [:imag_threshold, :clustering_threshold, :max_error_threshold,
			:verification_threshold, :complex_threshold]),
		("Multi-point/Multi-shot", [:max_num_points, :shooting_points, :shooting_warp, :shooting_warp_beta, :point_hint]),
		("Derivatives and Reconstruction", [:max_deriv_level, :max_reconstruction_attempts, :digits]),
		("Optimization", [:polish_solutions, :polish_solver_solutions, :polish_method, :polish_maxiters, :opt_maxiters,
			:opt_lb, :opt_ub, :polish_maxtime, :polish_divergence_factor, :polish_stagnation_window, :polish_ode_maxiters]),
		("Rescue Policy", [:terminal_fallback, :backsolve_recovery, :t0_state_completion]),
		("Data Sampling", [:datasize, :time_interval, :noise_level, :uneven_sampling,
			:uneven_sampling_times]),
		("Debug Flags", [:nooutput, :diagnostics, :debug_solver, :debug_cas_diagnostics,
			:debug_dimensional_analysis, :trap_debug, :profile_phases]),
		("Feature Flags", [:flow, :use_si_template, :save_system,
			:display_system, :polish_only, :ideal, :compute_uncertainty, :uq_failure_policy, :si_placeholder_fail_categories, :auto_handle_transcendentals, :gp_s3_refinement]),
		("HomotopyContinuation", [:use_monodromy, :use_parameter_homotopy, :hc_real_tol, :hc_show_progress, :use_multipoint, :multipoint_n_points, :multipoint_max_pairs]),
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
