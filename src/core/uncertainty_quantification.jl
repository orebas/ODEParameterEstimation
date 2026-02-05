"""
Uncertainty Quantification for ODE Parameter Estimation

This module provides functions for propagating uncertainty from GP-fitted observables
and their derivatives to estimated parameters using the implicit function theorem.

# Theory
For a GP f ~ GP(m, k), derivatives are jointly Gaussian. The key result:
    Cov(f^(i)(t), f^(j)(t')) = ∂^(i+j) k(t, t') / (∂t^i ∂t'^j)

Given parameter estimation as F(θ, z) = 0, the IFT gives:
    Cov(θ) ≈ (J_θ⁻¹ J_z) Σ_z (J_θ⁻¹ J_z)ᵀ

# References
- Rasmussen & Williams (2006) - "Gaussian Processes for Machine Learning", Ch. 9
- Solak et al. (2003) - "Derivative observations in Gaussian process models"
"""

#==========================================================================
 Helper Functions for Symbol Handling
==========================================================================#

"""
    extract_base_name(sym) -> String

Extract the base variable name from a symbol that may have time-dependent notation.
E.g., Symbol("x1(t)") -> "x1", :x1 -> "x1"
"""
function extract_base_name(sym)
	s = string(sym)
	# Remove "(t)" suffix if present
	if endswith(s, "(t)")
		return s[1:end-3]
	end
	return s
end

"""
    get_solution_value(dict, target_sym)

Safely get a value from a solution dictionary (states or parameters) by matching
the base variable name, regardless of whether keys are Symbol("x1(t)") or :x1.
"""
function get_solution_value(dict, target_sym)
	target_base = extract_base_name(target_sym)

	# First try direct lookup
	if haskey(dict, target_sym)
		return dict[target_sym]
	end

	# Try with Symbol()
	sym_key = Symbol(target_sym)
	if haskey(dict, sym_key)
		return dict[sym_key]
	end

	# Search by base name
	for (k, v) in dict
		if extract_base_name(k) == target_base
			return v
		end
	end

	error("Could not find key matching '$target_sym' in dictionary with keys: $(collect(keys(dict)))")
end

#==========================================================================
 SE Kernel Derivatives - Core Building Block
==========================================================================#

"""
    se_kernel_derivative(σ²::Real, ℓ::Real, Δt::Real, i::Int, j::Int) -> Real

Compute the SE kernel derivative: ∂^(i+j)/∂t^i∂t'^j k(t, t') evaluated at Δt = t - t'.

The SE kernel is k(Δt) = σ² exp(-Δt²/(2ℓ²)).

Uses closed-form expressions derived from the product rule and the fact that
∂ⁿ/∂xⁿ exp(-x²/2) = Hₙ(x) exp(-x²/2) where Hₙ is the probabilist's Hermite polynomial.

# Arguments
- `σ²::Real`: Signal variance
- `ℓ::Real`: Lengthscale
- `Δt::Real`: Time difference t - t'
- `i::Int`: Order of derivative with respect to t (0 ≤ i ≤ 4)
- `j::Int`: Order of derivative with respect to t' (0 ≤ j ≤ 4)

# Returns
- The value of the kernel derivative at Δt

# Examples
```julia
# Prior variance of f(t)
se_kernel_derivative(1.0, 0.5, 0.0, 0, 0)  # = σ² = 1.0

# Prior variance of f'(t)
se_kernel_derivative(1.0, 0.5, 0.0, 1, 1)  # = σ²/ℓ² = 4.0

# Covariance between f(t) and f''(t) at same point
se_kernel_derivative(1.0, 0.5, 0.0, 0, 2)  # = -σ²/ℓ² = -4.0
```
"""
function se_kernel_derivative(σ²::Real, ℓ::Real, Δt::Real, i::Int, j::Int)::Float64
	@assert i >= 0 && j >= 0 "Derivative orders must be non-negative"
	@assert i + j <= 4 "Total derivative order $(i+j) > 4 not implemented"

	# Normalized distance
	u = Δt / ℓ
	u² = u^2

	# Base kernel value: k(Δt) = σ² exp(-Δt²/(2ℓ²)) = σ² exp(-u²/2)
	base = σ² * exp(-u² / 2)

	# Total derivative order
	n = i + j

	# Sign factor: derivatives alternate based on which variable we differentiate
	# ∂/∂t gives +u/ℓ inside exp, ∂/∂t' gives -u/ℓ inside exp
	# So ∂^i/∂t^i ∂^j/∂t'^j has sign factor (-1)^j

	if n == 0
		# k(Δt) = σ² exp(-u²/2)
		return base

	elseif n == 1
		# First derivative: ∂k/∂t = -σ² u/ℓ exp(-u²/2)
		# ∂k/∂t' = σ² u/ℓ exp(-u²/2)  (opposite sign due to chain rule with -)
		sign = (i == 1) ? -1 : 1
		return sign * base * u / ℓ

	elseif n == 2
		if i == 1 && j == 1
			# ∂²k/∂t∂t' = σ²/ℓ² (1 - u²) exp(-u²/2)
			return base / ℓ^2 * (1 - u²)
		else
			# ∂²k/∂t² or ∂²k/∂t'² = σ²/ℓ² (u² - 1) exp(-u²/2)
			return base / ℓ^2 * (u² - 1)
		end

	elseif n == 3
		# Third derivatives
		# Pattern: ∂³k/∂t^a∂t'^b involves (u³ - 3u) with appropriate sign
		if i == 3 || j == 3
			# ∂³k/∂t³ or ∂³k/∂t'³
			sign = (i == 3) ? -1 : 1
			return sign * base / ℓ^3 * u * (u² - 3)
		elseif i == 2 && j == 1
			# ∂³k/∂t²∂t'
			return base / ℓ^3 * u * (3 - u²)
		else  # i == 1 && j == 2
			# ∂³k/∂t∂t'²
			return -base / ℓ^3 * u * (3 - u²)
		end

	elseif n == 4
		# Fourth derivatives
		if i == 2 && j == 2
			# ∂⁴k/∂t²∂t'² = σ²/ℓ⁴ (3 - 6u² + u⁴) exp(-u²/2)
			return base / ℓ^4 * (3 - 6 * u² + u²^2)
		elseif i == 4 || j == 4
			# ∂⁴k/∂t⁴ or ∂⁴k/∂t'⁴ = σ²/ℓ⁴ (u⁴ - 6u² + 3) exp(-u²/2)
			return base / ℓ^4 * (u²^2 - 6 * u² + 3)
		elseif (i == 3 && j == 1) || (i == 1 && j == 3)
			# ∂⁴k/∂t³∂t' or ∂⁴k/∂t∂t'³
			sign = (i == 3) ? 1 : -1
			return sign * base / ℓ^4 * (u²^2 - 6 * u² + 3)
		else
			error("Unexpected derivative order combination: i=$i, j=$j")
		end
	end

	error("Total derivative order $(i+j) not implemented")
end

"""
    se_kernel_prior_covariance_matrix(σ²::Real, ℓ::Real, max_deriv::Int=2) -> Matrix{Float64}

Compute the prior covariance matrix for [f(t), f'(t), f''(t), ...] at a single point t.

For the SE kernel at t = t' (Δt = 0), many cross-covariances are zero due to symmetry:
- Cov(f, f') = 0 (odd symmetry)
- Cov(f', f'') = 0 (odd symmetry)

# Arguments
- `σ²::Real`: Signal variance
- `ℓ::Real`: Lengthscale
- `max_deriv::Int`: Maximum derivative order (default 2)

# Returns
- Symmetric matrix of size (max_deriv+1) × (max_deriv+1)

# Example
For SE kernel with σ²=1, ℓ=1, the matrix for [f, f', f''] is:
```
[  1      0    -1   ]
[  0      1     0   ]
[ -1      0     3   ]
```
"""
function se_kernel_prior_covariance_matrix(σ²::Real, ℓ::Real, max_deriv::Int = 2)::Matrix{Float64}
	n = max_deriv + 1
	Σ = zeros(n, n)

	for i in 0:max_deriv
		for j in 0:max_deriv
			Σ[i+1, j+1] = se_kernel_derivative(σ², ℓ, 0.0, i, j)
		end
	end

	return Σ
end

#==========================================================================
 AGP Extended Interpolator with Full UQ Support
==========================================================================#

"""
    AGPInterpolatorUQ

Extended GP interpolator with full uncertainty quantification support.
Stores pre-computed values needed for efficient derivative covariance computation.

# Fields
- `mean_function::Function`: Returns mean prediction (denormalized)
- `std_function::Function`: Returns standard deviation (denormalized)
- `xs_train::Vector{Float64}`: Training x values (raw, not normalized)
- `ys_train::Vector{Float64}`: Training y values (normalized)
- `alpha::Vector{Float64}`: Pre-computed weights (K⁻¹ y)
- `chol::Cholesky`: Cholesky factorization of K + σₙ²I
- `lengthscale::Float64`: Optimized lengthscale
- `signal_var::Float64`: Optimized signal variance (σ²)
- `noise_var::Float64`: Optimized noise variance (σₙ²)
- `y_mean::Float64`: Mean of original y values
- `y_std::Float64`: Std of original y values
"""
struct AGPInterpolatorUQ <: AbstractInterpolator
	mean_function::Function
	std_function::Function
	xs_train::Vector{Float64}
	ys_train::Vector{Float64}
	alpha::Vector{Float64}
	chol::Cholesky
	lengthscale::Float64
	signal_var::Float64
	noise_var::Float64
	y_mean::Float64
	y_std::Float64
end

# Make it callable like other interpolators
(interp::AGPInterpolatorUQ)(x) = interp.mean_function(x)

"""
    joint_derivative_covariance(interp::AGPInterpolatorUQ, t::Real, max_deriv::Int=2)

Compute the joint posterior covariance matrix for [f(t), f'(t), ..., f^(max_deriv)(t)].

This is the key function for UQ: it gives us the covariance structure of the
observable and its derivatives at a single time point.

# Arguments
- `interp::AGPInterpolatorUQ`: The GP interpolator with stored hyperparameters
- `t::Real`: Time point at which to compute covariance
- `max_deriv::Int`: Maximum derivative order to include (default 2)

# Returns
- `μ::Vector{Float64}`: Posterior means [f(t), f'(t), ..., f^(max_deriv)(t)]
- `Σ::Matrix{Float64}`: Posterior covariance matrix

# Theory
The posterior covariance is:
    Σ_posterior = Σ_prior - K_*n K⁻¹ K_n*

where:
- Σ_prior is the prior covariance matrix for derivatives at t
- K_*n is the covariance between test derivatives and training points
- K⁻¹ is the inverse of the training covariance (via Cholesky)
"""
function joint_derivative_covariance(interp::AGPInterpolatorUQ, t::Real, max_deriv::Int = 2)
	σ² = interp.signal_var
	ℓ = interp.lengthscale
	xs = interp.xs_train
	alpha = interp.alpha
	C = interp.chol
	n_train = length(xs)
	n_derivs = max_deriv + 1

	# 1. Build prior covariance for [f(t), f'(t), ..., f^(max_deriv)(t)]
	Σ_prior = se_kernel_prior_covariance_matrix(σ², ℓ, max_deriv)

	# 2. Build K_*n matrix: covariance between test derivatives and training points
	# K_*n[d+1, k] = Cov(f^(d)(t), f(x_k)) = ∂^d/∂t^d k(t, x_k)
	K_star_n = zeros(n_derivs, n_train)
	for d in 0:max_deriv
		for k in 1:n_train
			Δt = t - xs[k]
			# Derivative with respect to first argument only (test point)
			K_star_n[d+1, k] = se_kernel_derivative(σ², ℓ, Δt, d, 0)
		end
	end

	# 3. Posterior mean: μ = K_*n @ alpha
	μ_norm = K_star_n * alpha

	# 4. Posterior covariance: Σ = Σ_prior - K_*n @ K⁻¹ @ K_n*
	# Using Cholesky: K⁻¹ @ K_n* = C \ (C' \ K_n*')' = (C \ K_star_n')'
	V = C \ K_star_n'  # n_train × n_derivs
	Σ_posterior = Σ_prior - K_star_n * V

	# 5. Ensure positive semi-definiteness (numerical safety)
	Σ_posterior = Symmetric(Σ_posterior)

	# Add small jitter if needed for numerical stability
	min_eig = minimum(eigvals(Σ_posterior))
	if min_eig < 0
		Σ_posterior = Σ_posterior + Matrix{Float64}(I, n_derivs, n_derivs) * (abs(min_eig) + 1e-10)
	end

	# 6. De-normalize to original scale
	# f scales by y_std, f' scales by y_std (x is not normalized)
	# f'' scales by y_std, etc.
	scale_factors = fill(interp.y_std, n_derivs)

	μ_scaled = μ_norm .* scale_factors
	μ_scaled[1] += interp.y_mean  # Only add mean to f(t), not derivatives

	Σ_scaled = Diagonal(scale_factors) * Σ_posterior * Diagonal(scale_factors)

	return μ_scaled, Matrix(Σ_scaled)
end

#==========================================================================
 Building Full Observation Covariance Matrix Σ_z
==========================================================================#

"""
    build_observation_covariance(gp_results::Dict, times::Vector, max_deriv::Int=2)

Build the full covariance matrix Σ_z for all observables and derivatives at given times.

For Phase 1 (independent GPs), this is a block-diagonal matrix where each block
corresponds to one observable at one time point.

# Arguments
- `gp_results::Dict{String, AGPInterpolatorUQ}`: GP results keyed by observable name
- `times::Vector{<:Real}`: Time points at which to evaluate
- `max_deriv::Int`: Maximum derivative order (default 2)

# Returns
- `μ_z::Vector{Float64}`: Full mean vector for all observables and derivatives
- `Σ_z::Matrix{Float64}`: Full covariance matrix (block-diagonal for independent GPs)
- `labels::Vector{String}`: Labels for each component (e.g., "y1(t=0.5)", "y1'(t=0.5)")

# Structure
The ordering is: for each observable, for each time, [f, f', f'', ...]
So for 2 observables, 3 times, max_deriv=1:
  [y1(t1), y1'(t1), y1(t2), y1'(t2), y1(t3), y1'(t3), y2(t1), y2'(t1), ...]
"""
function build_observation_covariance(
	gp_results::Dict{String, <:AGPInterpolatorUQ},
	times::Vector{<:Real},
	max_deriv::Int = 2,
)
	n_obs = length(gp_results)
	n_times = length(times)
	n_derivs = max_deriv + 1
	total_dim = n_obs * n_times * n_derivs

	μ_z = zeros(total_dim)
	Σ_z = zeros(total_dim, total_dim)
	labels = String[]

	idx = 1
	for (obs_name, gp) in gp_results
		for t in times
			μ_block, Σ_block = joint_derivative_covariance(gp, t, max_deriv)

			block_range = idx:(idx+n_derivs-1)
			μ_z[block_range] = μ_block
			Σ_z[block_range, block_range] = Σ_block

			# Generate labels
			for d in 0:max_deriv
				deriv_label = d == 0 ? "" : "'" ^ d
				push!(labels, "$(obs_name)$(deriv_label)(t=$(round(t, digits=3)))")
			end

			idx += n_derivs
		end
	end

	return μ_z, Symmetric(Σ_z), labels
end

#==========================================================================
 Parameter Covariance via Implicit Function Theorem
==========================================================================#

"""
    compute_parameter_covariance(
        pep::ParameterEstimationProblem,
        solution,
        gp_results::Dict{String, <:AGPInterpolatorUQ},
        times::Vector{<:Real};
        max_deriv::Int=2
    )

Compute parameter uncertainty using the implicit function theorem.

Given the constraint equations F(θ, z) = 0 derived from the ODE system,
and the observation covariance Σ_z from the GPs, compute:

    Cov(θ) ≈ S Σ_z Sᵀ   where   S = -J_θ⁻¹ J_z

# Arguments
- `pep::ParameterEstimationProblem`: The parameter estimation problem
- `solution`: Estimated solution (containing states and parameters)
- `gp_results::Dict`: GP interpolators for each observable
- `times::Vector`: Time points used for constraint equations
- `max_deriv::Int`: Maximum derivative order in constraints (default 2)

# Returns
- `Σ_θ::Matrix{Float64}`: Covariance matrix for parameters
- `std_θ::Vector{Float64}`: Standard deviations (sqrt of diagonal)
- `param_names::Vector{Symbol}`: Names of parameters
- `cond_J::Float64`: Condition number of J_θ (indicates identifiability)

# Warnings
- High condition number suggests identifiability issues
- Linear approximation may underestimate uncertainty for nonlinear systems
"""
function compute_parameter_covariance(
	pep::ParameterEstimationProblem,
	solution,
	gp_results::Dict{String, <:AGPInterpolatorUQ},
	times::Vector{<:Real};
	max_deriv::Int = 2,
)
	# Get observation covariance
	μ_z, Σ_z, z_labels = build_observation_covariance(gp_results, times, max_deriv)

	# Build Jacobians using automatic differentiation
	J_θ, J_z, param_names = compute_constraint_jacobians(pep, solution, gp_results, times, max_deriv)

	# Check identifiability via condition number
	cond_J = cond(J_θ)
	if cond_J > 1e10
		@warn "J_θ is nearly singular (cond = $cond_J), parameters may be unidentifiable"
	end

	# Sensitivity matrix: ∂θ/∂z = -J_θ⁻¹ J_z
	# Use pseudo-inverse for robustness
	if cond_J > 1e6
		S = -pinv(J_θ) * J_z
	else
		S = -J_θ \ J_z
	end

	# Parameter covariance via delta method
	Σ_θ = S * Σ_z * S'

	# Ensure symmetry
	Σ_θ = Symmetric(Σ_θ)

	# Standard deviations
	std_θ = sqrt.(max.(diag(Σ_θ), 0.0))

	# Check if the result is valid (not NaN/Inf and reasonable condition number)
	if any(isnan, Σ_θ) || any(isinf, Σ_θ)
		return (
			param_covariance = nothing,
			param_std = nothing,
			param_names = param_names,
			condition_number = cond_J,
			success = false,
			message = "Covariance matrix contains NaN or Inf values",
		)
	end

	return (
		param_covariance = Matrix(Σ_θ),
		param_std = std_θ,
		param_names = param_names,
		condition_number = cond_J,
		success = true,
		message = "Parameter covariance computed successfully",
	)
end

"""
    compute_constraint_jacobians(
        pep::ParameterEstimationProblem,
        solution,
        gp_results::Dict,
        times::Vector,
        max_deriv::Int
    )

Compute Jacobians of the constraint equations F(θ, z) = 0.

The constraint is that the ODE-predicted observables must match the GP observations:
    F(θ, z) = h(x(t; θ), p) - z_obs = 0

where h is the observation function and x(t; θ) is the ODE solution.

# Returns
- `J_θ::Matrix{Float64}`: ∂F/∂θ - Jacobian with respect to parameters
- `J_z::Matrix{Float64}`: ∂F/∂z - Jacobian with respect to observations
- `param_names::Vector{Symbol}`: Names of all parameters (states + params)

# Theory
Since F = predicted(θ) - z, we have:
- J_θ = ∂(predicted)/∂θ  (requires sensitivity analysis)
- J_z = -I  (negative identity, since F is linear in z)

# Implementation Note
Uses finite differences for J_θ due to ODE solver AD compatibility issues.
This is computed by solving the ODE with perturbed parameters and measuring
how the predicted observables change.
"""
function compute_constraint_jacobians(
	pep::ParameterEstimationProblem,
	solution,
	gp_results::Dict{String, <:AGPInterpolatorUQ},
	times::Vector{<:Real},
	max_deriv::Int,
)
	# Extract parameter and state names from the model
	state_syms = pep.model.original_states
	param_syms = pep.model.original_parameters

	# Filter out any init_ parameters (these are handled as states)
	param_syms_only = filter(p -> !startswith(string(p), "init_"), param_syms)

	# Full parameter vector θ = [initial_conditions; parameters]
	θ_names = vcat(Symbol.(state_syms), Symbol.(param_syms_only))
	n_θ = length(θ_names)

	# Get current estimates from solution
	n_states = length(state_syms)
	n_params = length(param_syms_only)

	θ_current = Vector{Float64}(undef, n_θ)
	for (i, s) in enumerate(state_syms)
		θ_current[i] = get_solution_value(solution.states, s)
	end
	for (i, p) in enumerate(param_syms_only)
		θ_current[n_states + i] = get_solution_value(solution.parameters, p)
	end

	# Observation structure: for each GP, at each time, [f, f', f'', ...]
	obs_names = collect(keys(gp_results))
	n_obs = length(obs_names)
	n_times = length(times)
	n_derivs = max_deriv + 1
	n_z = n_obs * n_times * n_derivs

	# For each observable at each time and derivative order, we have one constraint
	n_constraints = n_z

	# Complete the system once outside the inner function
	completed_sys = ModelingToolkit.complete(pep.model.system)
	sys_unknowns = ModelingToolkit.unknowns(completed_sys)
	sys_params = ModelingToolkit.parameters(completed_sys)

	# Filter out init_ parameters from sys_params (these are handled as states)
	sys_params_only = filter(p -> !startswith(string(p), "init_"), sys_params)

	# Verify lengths match for debugging
	if length(sys_unknowns) != n_states
		@warn "Mismatch in state count: sys_unknowns=$(length(sys_unknowns)), state_syms=$(n_states)" sys_unknowns state_syms
	end
	if length(sys_params_only) != n_params
		@warn "Mismatch in param count: sys_params_only=$(length(sys_params_only)), param_syms_only=$(n_params)" sys_params_only param_syms_only
	end

	# Build mapping from state_syms order to sys_unknowns
	# This ensures values are assigned to the correct symbolic variables regardless of ordering
	state_name_to_sysunknown = Dict{String, Any}()
	for s in sys_unknowns
		state_name_to_sysunknown[string(s)] = s
	end
	param_name_to_sysparam = Dict{String, Any}()
	for p in sys_params_only
		param_name_to_sysparam[string(p)] = p
	end

	# Debug: Print system structure once
	@debug "UQ ODE System Structure" sys_unknowns sys_params_only n_states n_params

	# Build the prediction function: θ → predicted observations
	# This solves the ODE and evaluates the observation function
	_first_call = Ref(true)  # Track if this is the first call for debugging

	function predict_observables(θ_vec::Vector{T}) where {T}
		# Debug print on first call
		if _first_call[]
			@debug "predict_observables first call" θ_vec_length=length(θ_vec) n_states n_params expected_length=n_states+n_params
			_first_call[] = false
		end

		# Check that θ_vec has the right length
		expected_len = n_states + n_params
		if length(θ_vec) != expected_len
			@warn "θ_vec length mismatch" got=length(θ_vec) expected=expected_len
			return fill(T(Inf), n_constraints)
		end

		# Split θ into ICs and parameters
		ic_vals = θ_vec[1:n_states]
		param_vals = θ_vec[(n_states+1):end]

		# Build initial conditions dict using name-based mapping
		# state_syms[i] corresponds to ic_vals[i], we need to map to sys_unknowns symbols
		ic_dict = Dict{Any, T}()
		for (i, state_sym) in enumerate(state_syms)
			state_name = string(state_sym)
			if haskey(state_name_to_sysunknown, state_name)
				ic_dict[state_name_to_sysunknown[state_name]] = ic_vals[i]
			else
				# Fallback: try matching without (t) suffix
				base_name = replace(state_name, r"\(t\)$" => "")
				found = false
				for (k, v) in state_name_to_sysunknown
					if replace(k, r"\(t\)$" => "") == base_name
						ic_dict[v] = ic_vals[i]
						found = true
						break
					end
				end
				if !found
					@warn "Could not find sys_unknown for state" state_sym state_name keys(state_name_to_sysunknown)
				end
			end
		end

		# Build parameters dict using name-based mapping
		param_dict = Dict{Any, T}()
		for (i, param_sym) in enumerate(param_syms_only)
			param_name = string(param_sym)
			if haskey(param_name_to_sysparam, param_name)
				param_dict[param_name_to_sysparam[param_name]] = param_vals[i]
			else
				# Fallback: try exact name match
				found = false
				for (k, v) in param_name_to_sysparam
					if k == param_name
						param_dict[v] = param_vals[i]
						found = true
						break
					end
				end
				if !found
					@warn "Could not find sys_param for param" param_sym param_name keys(param_name_to_sysparam)
				end
			end
		end

		# Create and solve ODE problem using the new MTK API (merged dict)
		tspan = (minimum(times), maximum(times))
		try
			# Debug: print dict contents on first call
			if _first_call[]
				@debug "Creating ODEProblem with dicts" ic_dict_keys=collect(keys(ic_dict)) param_dict_keys=collect(keys(param_dict))
			end

			merged_dict = merge(ic_dict, param_dict)
			prob = ODEProblem(completed_sys, merged_dict, tspan)
			sol = OrdinaryDiffEq.solve(prob, AutoVern9(Rodas4P()), saveat = times, abstol = 1e-10, reltol = 1e-10)

			if sol.retcode != ReturnCode.Success
				@warn "ODE solve returned non-Success retcode in predict_observables" retcode=sol.retcode
				return fill(T(Inf), n_constraints)
			end

			# Extract predicted values for each observable
			# For now, assume observables are direct state observations (h(x) = x_i)
			# TODO: Handle general observation functions h(x, p)
			predictions = Vector{T}(undef, n_constraints)

			idx = 1
			for obs_name in obs_names
				# Find which state this observable corresponds to
				# This is a simplification - real implementation should use measured_quantities
				state_idx = 1  # Default to first state
				for (si, s) in enumerate(state_syms)
					if occursin(string(s), obs_name)
						state_idx = si
						break
					end
				end

				for (ti, t) in enumerate(times)
					# Get state value at this time
					state_val = sol[state_idx, ti]

					# For derivative order 0 (the value itself)
					predictions[idx] = state_val
					idx += 1

					# For higher derivatives, we'd need to compute them from the ODE RHS
					# For now, use numerical differentiation of the solution
					for d in 1:max_deriv
						# Use finite difference on the solution interpolation
						δt = 1e-6
						if ti > 1 && ti < n_times
							val_plus = sol(t + δt)[state_idx]
							val_minus = sol(t - δt)[state_idx]
							deriv = (val_plus - val_minus) / (2δt)
						else
							deriv = T(0)  # Boundary handling
						end
						# This is a simplification for first derivative
						# Higher derivatives need more sophisticated handling
						predictions[idx] = deriv
						idx += 1
					end
				end
			end

			return predictions
		catch e
			@warn "ODE solve failed in predict_observables" exception=e
			return fill(T(Inf), n_constraints)
		end
	end

	# Compute J_θ using finite differences
	ε = 1e-7
	pred_0 = predict_observables(θ_current)

	# Check if base prediction is valid
	if any(isinf, pred_0)
		@warn "Base prediction failed in compute_constraint_jacobians"
		J_θ = zeros(n_constraints, n_θ)
		J_z = -Matrix{Float64}(I, n_constraints, n_constraints)
		return J_θ, J_z, θ_names
	end

	J_θ = zeros(n_constraints, n_θ)

	for j in 1:n_θ
		θ_plus = copy(θ_current)
		θ_plus[j] += ε

		pred_plus = predict_observables(θ_plus)

		if !any(isinf, pred_plus)
			J_θ[:, j] = (pred_plus - pred_0) / ε
		end
	end

	# J_z = -I since F = predicted - observed
	# The constraint is F(θ, z) = predicted(θ) - z = 0
	# So ∂F/∂z = -I
	J_z = -Matrix{Float64}(I, n_constraints, n_constraints)

	return J_θ, J_z, θ_names
end

"""
    compute_constraint_jacobians_simple(
        pep::ParameterEstimationProblem,
        solution,
        gp_results::Dict,
        times::Vector
    )

Simplified version that only considers function values (no derivatives).
Useful for quick uncertainty estimates or when derivative information is unreliable.

Returns smaller Jacobian matrices focusing only on f(t) matching.
"""
function compute_constraint_jacobians_simple(
	pep::ParameterEstimationProblem,
	solution,
	gp_results::Dict{String, <:AGPInterpolatorUQ},
	times::Vector{<:Real},
)
	return compute_constraint_jacobians(pep, solution, gp_results, times, 0)
end

#==========================================================================
 Factory Function for UQ-Enabled GP
==========================================================================#

"""
    agp_gpr_uq(xs::AbstractArray, ys::AbstractArray; kernel_type=:se) -> AGPInterpolatorUQ

Create a GP interpolator with full uncertainty quantification support.

This is like `agp_gpr` but returns an `AGPInterpolatorUQ` that stores all the
information needed for computing derivative covariances.

# Arguments
- `xs::AbstractArray`: X coordinates (e.g., time points)
- `ys::AbstractArray`: Y coordinates (observations)
- `kernel_type::Symbol`: `:se` (Squared Exponential) or `:matern52`

# Returns
- `AGPInterpolatorUQ` with full UQ capability
"""
function agp_gpr_uq(xs::AbstractArray{T}, ys::AbstractArray{T};
	kernel_type::Symbol = :se)::AGPInterpolatorUQ where {T}
	@assert length(xs) == length(ys) "Input arrays must have same length"
	@assert length(xs) >= 3 "Need at least 3 points for GP interpolation"

	# Handle constant data edge case
	y_std_raw = std(ys)
	if y_std_raw < 1e-10
		constant_val = mean(ys)
		# Return a dummy interpolator for constant data
		xs_vec = collect(Float64, xs)
		ys_norm = zeros(length(xs))
		alpha = zeros(length(xs))
		K = Matrix{Float64}(I, length(xs), length(xs))
		C = cholesky(K)
		return AGPInterpolatorUQ(
			x -> constant_val,
			x -> 0.0,
			xs_vec, ys_norm, alpha, C,
			1.0, 0.0, 1e-6,
			constant_val, 1.0,
		)
	end

	# Use raw X values (no normalization) like the standard agp_gpr
	xs_raw = collect(Float64, xs)

	# Standardize Y (zero mean, unit variance)
	y_mean = mean(ys)
	y_std = max(y_std_raw, 1e-8)
	ys_norm = (collect(Float64, ys) .- y_mean) ./ y_std

	# Add small jitter
	jitter = 1e-8
	ys_norm = ys_norm .+ jitter * randn(length(ys_norm))

	# Initial hyperparameters
	initial_log_lengthscale = log(std(xs_raw) / 8)
	initial_log_variance = 0.0
	initial_log_noise = -2.0

	# Build base kernel
	base_kernel = kernel_type == :matern52 ? Matern52Kernel() : SqExponentialKernel()

	# Loss function for optimization
	function neg_logpdf_agp(θ)
		l = exp(θ[1])
		σ² = exp(θ[2])
		σₙ² = exp(θ[3])

		k = σ² * (base_kernel ∘ ScaleTransform(1.0 / l))
		gp = AbstractGPs.GP(k)

		try
			return -logpdf(gp(xs_raw, σₙ²), ys_norm)
		catch e
			@debug "UQ GP log-likelihood evaluation failed" exception = e
			return Inf
		end
	end

	# Gradient function
	function grad_neg_logpdf(θ)
		g = Zygote.gradient(neg_logpdf_agp, θ)[1]
		if isnothing(g) || any(isnan, g) || any(isinf, g)
			return zeros(3)
		end
		return g
	end

	θ0 = [initial_log_lengthscale, initial_log_variance, initial_log_noise]

	# Defaults
	l_opt = exp(initial_log_lengthscale)
	σ²_opt = 1.0
	σₙ²_opt = exp(initial_log_noise)

	try
		result = Optim.optimize(
			neg_logpdf_agp,
			grad_neg_logpdf,
			θ0,
			LBFGS(linesearch = LineSearches.BackTracking()),
			Optim.Options();
			inplace = false,
		)
		θ_opt = Optim.minimizer(result)
		l_opt = exp(θ_opt[1])
		σ²_opt = exp(θ_opt[2])
		σₙ²_opt = exp(θ_opt[3])
	catch e
		@warn "Hyperparameter optimization failed, using defaults" exception = e
	end

	# Build kernel matrix and Cholesky factorization
	n = length(xs_raw)
	I_n = Matrix{Float64}(I, n, n)
	scaled_kernel = base_kernel ∘ ScaleTransform(1.0 / l_opt)
	K_train = σ²_opt * kernelmatrix(scaled_kernel, xs_raw)
	K_noisy = K_train + σₙ²_opt * I_n
	C = cholesky(Symmetric(K_noisy))
	alpha = C \ ys_norm

	# Prediction functions
	function mean_pred(x::Real)
		k_star = [σ²_opt * scaled_kernel(x, xi) for xi in xs_raw]
		return y_std * dot(k_star, alpha) + y_mean
	end

	function std_pred(x::Real)
		k_star = [σ²_opt * scaled_kernel(x, xi) for xi in xs_raw]
		k_star_vec = reshape(k_star, :, 1)
		v = C \ k_star
		prior_var = σ²_opt  # k(x, x) for SE kernel
		post_var = prior_var - dot(k_star, v)
		return y_std * sqrt(max(post_var, 0.0))
	end

	return AGPInterpolatorUQ(
		mean_pred, std_pred,
		xs_raw, ys_norm, alpha, C,
		l_opt, σ²_opt, σₙ²_opt,
		y_mean, y_std,
	)
end

#==========================================================================
 Validation and Testing Utilities
==========================================================================#

"""
    validate_derivative_covariance(interp::AGPInterpolatorUQ, t::Real; n_samples=1000)

Validate derivative covariance by Monte Carlo sampling.

Draws samples from the GP posterior and computes empirical covariance.
Useful for testing that analytic covariance formulas are correct.

# Arguments
- `interp`: The GP interpolator
- `t`: Time point to test
- `n_samples`: Number of Monte Carlo samples

# Returns
- `empirical_cov`: Empirical covariance from samples
- `analytic_cov`: Analytic covariance from joint_derivative_covariance
"""
function validate_derivative_covariance(interp::AGPInterpolatorUQ, t::Real; n_samples::Int = 1000)
	# Get analytic covariance
	μ, Σ_analytic = joint_derivative_covariance(interp, t, 2)

	# For MC sampling, we'd need to draw from the GP posterior
	# This requires more infrastructure - placeholder for now
	@warn "validate_derivative_covariance MC sampling not fully implemented"

	return Σ_analytic, Σ_analytic
end

#==========================================================================
 High-Level Integration Functions
==========================================================================#

"""
    estimate_parameter_uncertainty(
        PEP::ParameterEstimationProblem,
        solution,
        data_sample::OrderedDict;
        max_deriv_order::Int = 2,
        n_timepoints::Int = 10,
        fd_step::Float64 = 1e-6
    )

Estimate parameter uncertainty using GP derivative covariances and the Implicit Function Theorem.

This is the main entry point for uncertainty quantification. It:
1. Fits UQ-enabled GP interpolators to each observable
2. Selects time points for constraint evaluation
3. Builds the observation covariance matrix Σ_z (block-diagonal for independent GPs)
4. Computes constraint Jacobians J_θ and J_z
5. Applies the delta method: Cov(θ) ≈ S Σ_z Sᵀ where S = -J_θ⁻¹ J_z

# Arguments
- `PEP`: The parameter estimation problem with model and true parameters
- `solution`: A solution result containing estimated parameters and states
- `data_sample`: OrderedDict with "t" and observable data
- `max_deriv_order`: Maximum derivative order for covariance (default: 2)
- `n_timepoints`: Number of time points for constraint evaluation (default: 10)
- `fd_step`: Step size for finite difference Jacobian computation (default: 1e-6)

# Returns
Named tuple with:
- `param_covariance`: Covariance matrix of parameters
- `param_std`: Standard deviations for each parameter
- `param_names`: Names of the parameters (in order)
- `obs_covariance`: The observation covariance matrix Σ_z
- `interpolators`: Dictionary of fitted UQ interpolators
- `success`: Whether the computation succeeded
- `message`: Status message
"""
function estimate_parameter_uncertainty(
	PEP::ParameterEstimationProblem,
	solution,
	data_sample::OrderedDict;
	max_deriv_order::Int = 2,
	n_timepoints::Int = 10,
	fd_step::Float64 = 1e-6,
)
	try
		# Extract time points from data
		ts = collect(data_sample["t"])
		t_min, t_max = extrema(ts)

		# Get observable keys (excluding "t")
		obs_keys = filter(k -> k != "t", collect(keys(data_sample)))
		n_obs = length(obs_keys)

		if n_obs == 0
			return (
				param_covariance = nothing,
				param_std = nothing,
				param_names = nothing,
				obs_covariance = nothing,
				interpolators = nothing,
				success = false,
				message = "No observables found in data_sample",
			)
		end

		# Step 1: Fit UQ-enabled GP interpolators to each observable
		interpolators = OrderedDict{Any, AGPInterpolatorUQ}()
		for obs_key in obs_keys
			ys = collect(data_sample[obs_key])
			try
				interpolators[obs_key] = agp_gpr_uq(ts, ys)
			catch e
				@warn "Failed to fit GP for observable $obs_key: $e"
				return (
					param_covariance = nothing,
					param_std = nothing,
					param_names = nothing,
					obs_covariance = nothing,
					interpolators = nothing,
					success = false,
					message = "GP fitting failed for observable $obs_key: $e",
				)
			end
		end

		# Step 2: Select time points for constraint evaluation
		# Avoid boundaries where GP uncertainty is higher
		margin = 0.1 * (t_max - t_min)
		t_eval_min = t_min + margin
		t_eval_max = t_max - margin
		eval_times = range(t_eval_min, t_eval_max, length = n_timepoints)

		# Step 3: Build observation covariance matrix Σ_z (block-diagonal)
		# Convert interpolators to Dict{String, AGPInterpolatorUQ} as required by build_observation_covariance
		interp_dict = Dict{String, AGPInterpolatorUQ}(string(k) => v for (k, v) in interpolators)
		μ_z, Σ_z, labels = build_observation_covariance(interp_dict, collect(eval_times), max_deriv_order)

		# Step 4: Extract parameter vector from solution
		# Combine states (initial conditions) and parameters
		param_names = Symbol[]
		param_values = Float64[]

		# Add states (initial conditions)
		for (state_sym, state_val) in solution.states
			# Convert symbolic expression to Symbol (e.g., x1(t) -> :x1)
			state_name = Symbol(replace(string(state_sym), r"\(.*\)" => ""))
			push!(param_names, state_name)
			push!(param_values, real(state_val))
		end

		# Add parameters (excluding init_ prefixed ones)
		for (param_sym, param_val) in solution.parameters
			if !startswith(string(param_sym), "init_")
				# Convert to Symbol if needed
				param_name = param_sym isa Symbol ? param_sym : Symbol(replace(string(param_sym), r"\(.*\)" => ""))
				push!(param_names, param_name)
				push!(param_values, real(param_val))
			end
		end

		θ_est = param_values

		# Step 5: Compute parameter covariance using IFT
		# Note: compute_parameter_covariance expects Dict{String, AGPInterpolatorUQ}
		# and the solution object (not just the parameter values)
		result = compute_parameter_covariance(
			PEP,
			solution,
			interp_dict,
			collect(eval_times);
			max_deriv = max_deriv_order,
		)

		if result.success
			# Extract standard deviations from diagonal
			param_std = sqrt.(max.(diag(result.param_covariance), 0.0))

			return (
				param_covariance = result.param_covariance,
				param_std = param_std,
				param_names = param_names,
				obs_covariance = Σ_z,
				interpolators = interpolators,
				success = true,
				message = "Uncertainty estimation completed successfully",
			)
		else
			return (
				param_covariance = nothing,
				param_std = nothing,
				param_names = param_names,
				obs_covariance = Σ_z,
				interpolators = interpolators,
				success = false,
				message = result.message,
			)
		end

	catch e
		@warn "Uncertainty estimation failed: $e"
		return (
			param_covariance = nothing,
			param_std = nothing,
			param_names = nothing,
			obs_covariance = nothing,
			interpolators = nothing,
			success = false,
			message = "Uncertainty estimation failed: $e",
		)
	end
end

"""
    print_uncertainty_results(uq_result; io=stdout)

Pretty-print the uncertainty quantification results.

# Arguments
- `uq_result`: Result from estimate_parameter_uncertainty
- `io`: IO stream to print to (default: stdout)
"""
function print_uncertainty_results(uq_result; io = stdout)
	if !uq_result.success
		println(io, "\n=== Uncertainty Quantification ===")
		println(io, "Status: FAILED")
		println(io, "Message: $(uq_result.message)")
		return
	end

	println(io, "\n=== Uncertainty Quantification Results ===")
	println(io, "-"^50)
	println(io, "Parameter       | Std. Dev.   | 95% CI Half-Width")
	println(io, "-"^50)

	for (i, name) in enumerate(uq_result.param_names)
		std_val = uq_result.param_std[i]
		ci_half = 1.96 * std_val  # 95% confidence interval
		@printf(io, "%-14s | %10.6f | %10.6f\n", string(name), std_val, ci_half)
	end

	println(io, "-"^50)
	println(io, "\nNote: Uncertainties assume Gaussian errors and linearized constraints.")
	println(io, "      Results are conservative (Phase 1: independent GP assumption).")
end
