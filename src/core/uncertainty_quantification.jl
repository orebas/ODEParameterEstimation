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

	# Normalized distance
	u = Δt / ℓ
	u² = u^2

	# Base kernel value: k(Δt) = σ² exp(-Δt²/(2ℓ²)) = σ² exp(-u²/2)
	base = σ² * exp(-u² / 2)

	# Total derivative order
	n = i + j

	# General sign pattern: (-1)^i · σ²/ℓ^(i+j) · He_{i+j}(u) · exp(-u²/2)
	# where He_n is the probabilist's Hermite polynomial
	# This comes from ∂/∂t = +∂/∂Δ and ∂/∂t' = -∂/∂Δ

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
	end

	# For n ≥ 3: general formula (-1)^i · σ²/ℓⁿ · Heₙ(u) · exp(-u²/2)
	# Hermite recurrence: He₀=1, He₁=u, He_{k+1} = u·Heₖ - k·He_{k-1}
	He_prev, He_curr = 1.0, u
	for k in 1:(n - 1)
		He_prev, He_curr = He_curr, u * He_curr - k * He_prev
	end
	return (iseven(i) ? 1 : -1) * base / ℓ^n * He_curr
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

"""
    se_kernel_cross_time_covariance_matrix(σ²::Real, ℓ::Real, delta_t::Real, max_deriv::Int=2) -> Matrix{Float64}

Compute the prior covariance matrix between derivative vectors at two time points separated by `delta_t`.

Entry [a+1, b+1] = Cov(f^(a)(t), f^(b)(t')) where t - t' = delta_t.

Reduces to `se_kernel_prior_covariance_matrix` when `delta_t == 0`.

# Arguments
- `σ²::Real`: Signal variance
- `ℓ::Real`: Lengthscale
- `delta_t::Real`: Time difference t - t'
- `max_deriv::Int`: Maximum derivative order (default 2)

# Returns
- Matrix of size (max_deriv+1) × (max_deriv+1)
"""
function se_kernel_cross_time_covariance_matrix(σ²::Real, ℓ::Real, delta_t::Real, max_deriv::Int = 2)::Matrix{Float64}
	n = max_deriv + 1
	Σ = zeros(n, n)

	for i in 0:max_deriv
		for j in 0:max_deriv
			Σ[i+1, j+1] = se_kernel_derivative(σ², ℓ, delta_t, i, j)
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
	cholesky_jitter::Float64
	hyperparams_optimized::Bool
end

# Backward-compatible 11-arg constructor (defaults: jitter=0.0, optimized=true)
function AGPInterpolatorUQ(
	mean_function, std_function, xs_train, ys_train, alpha, chol,
	lengthscale, signal_var, noise_var, y_mean, y_std,
)
	return AGPInterpolatorUQ(
		mean_function, std_function, xs_train, ys_train, alpha, chol,
		lengthscale, signal_var, noise_var, y_mean, y_std,
		0.0, true,
	)
end

# Make it callable like other interpolators
(interp::AGPInterpolatorUQ)(x) = interp.mean_function(x)

"""
    _build_K_star_n(interp::AGPInterpolatorUQ, t::Real, max_deriv::Int) -> Matrix{Float64}

Build the K_*n matrix: covariance between test derivatives at `t` and training points.

K_star_n[d+1, k] = Cov(f^(d)(t), f(x_k)) = ∂^d/∂t^d k(t, x_k)

# Returns
- Matrix of size (max_deriv+1) × n_train
"""
function _build_K_star_n(interp::AGPInterpolatorUQ, t::Real, max_deriv::Int)::Matrix{Float64}
	σ² = interp.signal_var
	ℓ = interp.lengthscale
	xs = interp.xs_train
	n_train = length(xs)
	n_derivs = max_deriv + 1

	K_star_n = zeros(n_derivs, n_train)
	for d in 0:max_deriv
		for k in 1:n_train
			Δt = t - xs[k]
			K_star_n[d+1, k] = se_kernel_derivative(σ², ℓ, Δt, d, 0)
		end
	end

	return K_star_n
end

"""
	nth_deriv(f::AGPInterpolatorUQ, n::Int, t::Real) -> Real

Analytic nth derivative of the GP posterior mean. Uses the closed-form SE kernel
derivative formula via `_build_K_star_n` — avoids TaylorDiff and is exact.

The GP posterior mean is: μ(t) = y_std * K_*n(t) · α + y_mean
Its nth derivative is:  μ^(n)(t) = y_std * K_*n[n+1, :] · α
"""
function nth_deriv(f::AGPInterpolatorUQ, n::Int, t::Real)::Real
	if n == 0
		return f(t)
	end
	K_star_n = _build_K_star_n(f, t, n)
	return f.y_std * dot(K_star_n[n+1, :], f.alpha)
end

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
	alpha = interp.alpha
	C = interp.chol
	n_derivs = max_deriv + 1

	# 1. Build prior covariance for [f(t), f'(t), ..., f^(max_deriv)(t)]
	Σ_prior = se_kernel_prior_covariance_matrix(σ², ℓ, max_deriv)

	# 2. Build K_*n matrix using extracted helper
	K_star_n = _build_K_star_n(interp, t, max_deriv)

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

"""
    joint_derivative_covariance_cross_time(interp::AGPInterpolatorUQ, t_a::Real, t_b::Real, max_deriv::Int=2)

Compute the posterior cross-covariance between derivative vectors at two different time points.

Returns the matrix Σ where Σ[a+1, b+1] = Cov_posterior(f^(a)(t_a), f^(b)(t_b)).

When `t_a == t_b`, this is equivalent to `joint_derivative_covariance`.

# Arguments
- `interp::AGPInterpolatorUQ`: The GP interpolator
- `t_a::Real`: First time point
- `t_b::Real`: Second time point
- `max_deriv::Int`: Maximum derivative order (default 2)

# Returns
- `Σ_cross::Matrix{Float64}`: Cross-covariance matrix (NOT necessarily PSD — this is an off-diagonal block)

# Theory
The posterior cross-covariance is:
    Σ_cross = Σ_prior_cross(t_a - t_b) - K_*n(t_a) K⁻¹ K_n*(t_b)
"""
function joint_derivative_covariance_cross_time(interp::AGPInterpolatorUQ, t_a::Real, t_b::Real, max_deriv::Int = 2)
	σ² = interp.signal_var
	ℓ = interp.lengthscale
	C = interp.chol

	# Prior cross-covariance at delta_t = t_a - t_b
	Σ_prior_cross = se_kernel_cross_time_covariance_matrix(σ², ℓ, t_a - t_b, max_deriv)

	# Build K_*n matrices for both time points
	K_star_n_a = _build_K_star_n(interp, t_a, max_deriv)
	K_star_n_b = _build_K_star_n(interp, t_b, max_deriv)

	# Posterior cross-covariance: Σ_prior_cross - K_*n(t_a) K⁻¹ K_n*(t_b)
	V_b = C \ K_star_n_b'  # n_train × n_derivs
	Σ_cross = Σ_prior_cross - K_star_n_a * V_b

	# De-normalize to original scale
	scale_factors = fill(interp.y_std, max_deriv + 1)
	Σ_cross_scaled = Diagonal(scale_factors) * Σ_cross * Diagonal(scale_factors)

	# NO PSD enforcement — this is an off-diagonal block, not a covariance matrix
	return Matrix(Σ_cross_scaled)
end

#==========================================================================
 Building Full Observation Covariance Matrix Σ_z
==========================================================================#

"""
    build_observation_covariance(gp_results::Dict, times::Vector, max_deriv::Int=2)

Build the full covariance matrix Σ_z for all observables and derivatives at given times.

Includes **within-observable cross-time covariance blocks** from the GP posterior.
Cross-observable blocks remain zero (independent GPs for different sensors).

# Arguments
- `gp_results::Dict{String, AGPInterpolatorUQ}`: GP results keyed by observable name
- `times::Vector{<:Real}`: Time points at which to evaluate
- `max_deriv::Int`: Maximum derivative order (default 2)

# Returns
- `μ_z::Vector{Float64}`: Full mean vector for all observables and derivatives
- `Σ_z::Matrix{Float64}`: Full covariance matrix
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
	obs_block_size = n_times * n_derivs  # size of per-observable block
	total_dim = n_obs * obs_block_size

	μ_z = zeros(total_dim)
	Σ_z = zeros(total_dim, total_dim)
	labels = String[]

	obs_offset = 0  # tracks starting row/col for current observable

	for (obs_name, gp) in gp_results
		σ² = gp.signal_var
		ℓ = gp.lengthscale
		C = gp.chol
		alpha = gp.alpha
		scale_factors = fill(gp.y_std, n_derivs)
		scale_diag = Diagonal(scale_factors)

		# Pre-compute K_star_n and V = C \ K_star_n' for all time points
		K_stars = Vector{Matrix{Float64}}(undef, n_times)
		Vs = Vector{Matrix{Float64}}(undef, n_times)
		for ti in 1:n_times
			K_stars[ti] = _build_K_star_n(gp, times[ti], max_deriv)
			Vs[ti] = C \ K_stars[ti]'  # n_train × n_derivs
		end

		for ti in 1:n_times
			row_start = obs_offset + (ti - 1) * n_derivs + 1
			row_range = row_start:(row_start + n_derivs - 1)

			# Posterior mean
			μ_norm = K_stars[ti] * alpha
			μ_scaled = μ_norm .* scale_factors
			μ_scaled[1] += gp.y_mean
			μ_z[row_range] = μ_scaled

			# Generate labels for this time point
			for d in 0:max_deriv
				deriv_label = d == 0 ? "" : "'" ^ d
				push!(labels, "$(obs_name)$(deriv_label)(t=$(round(times[ti], digits=3)))")
			end

			# Diagonal block: same-time covariance (ti, ti)
			Σ_prior_diag = se_kernel_prior_covariance_matrix(σ², ℓ, max_deriv)
			Σ_post_diag = Σ_prior_diag - K_stars[ti] * Vs[ti]

			# PSD enforcement on diagonal block
			Σ_post_diag = Symmetric(Σ_post_diag)
			min_eig = minimum(eigvals(Σ_post_diag))
			if min_eig < 0
				Σ_post_diag = Σ_post_diag + Matrix{Float64}(I, n_derivs, n_derivs) * (abs(min_eig) + 1e-10)
			end

			# De-normalize
			Σ_z[row_range, row_range] = scale_diag * Σ_post_diag * scale_diag

			# Off-diagonal (cross-time) blocks within this observable
			for tj in (ti+1):n_times
				col_start = obs_offset + (tj - 1) * n_derivs + 1
				col_range = col_start:(col_start + n_derivs - 1)

				# Prior cross-covariance at delta_t = times[ti] - times[tj]
				Σ_prior_cross = se_kernel_cross_time_covariance_matrix(σ², ℓ, times[ti] - times[tj], max_deriv)

				# Posterior cross-covariance: Σ_prior_cross - K_*n(ti) K⁻¹ K_n*(tj)
				Σ_cross = Σ_prior_cross - K_stars[ti] * Vs[tj]

				# De-normalize (no PSD enforcement for off-diagonal blocks)
				Σ_cross_scaled = scale_diag * Σ_cross * scale_diag

				Σ_z[row_range, col_range] = Σ_cross_scaled
				Σ_z[col_range, row_range] = Σ_cross_scaled'  # symmetric
			end
		end

		# PSD enforcement on the full per-observable block
		obs_range = (obs_offset + 1):(obs_offset + obs_block_size)
		Σ_obs = Symmetric(Σ_z[obs_range, obs_range])
		min_eig_obs = minimum(eigvals(Σ_obs))
		if min_eig_obs < 0
			Σ_z[obs_range, obs_range] .+= Matrix{Float64}(I, obs_block_size, obs_block_size) * (abs(min_eig_obs) + 1e-10)
		end

		obs_offset += obs_block_size
	end

	return μ_z, Symmetric(Σ_z), labels
end

#==========================================================================
 Parameter Covariance via Implicit Function Theorem
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
	n = length(xs_raw)

	# Standardize Y (zero mean, unit variance)
	y_mean = mean(ys)
	y_std = max(y_std_raw, 1e-8)
	ys_norm = (collect(Float64, ys) .- y_mean) ./ y_std

	# No data jitter — adding noise to observations destroys high-order derivatives.
	# Numerical stability is handled by adaptive Cholesky jitter on the kernel matrix.

	# Use shared SE hyperparameter optimizer (same as agp_gpr_robust :se path)
	D_sq = [abs2(xs_raw[i] - xs_raw[j]) for i in 1:n, j in 1:n]
	hp = _optimize_se_hyperparams(xs_raw, ys_norm, D_sq)
	l_opt, σ²_opt, σₙ²_opt, hp_optimized = hp.l, hp.sigma2, hp.noise, hp.converged
	if !hp_optimized
		@warn "[UQ] GP hyperparameter optimization did not converge"
	end

	# Build kernel matrix and Cholesky factorization
	base_kernel = kernel_type == :matern52 ? Matern52Kernel() : SqExponentialKernel()
	I_n = Matrix{Float64}(I, n, n)
	scaled_kernel = base_kernel ∘ ScaleTransform(1.0 / l_opt)
	K_train = σ²_opt * kernelmatrix(scaled_kernel, xs_raw)
	K_noisy = K_train + σₙ²_opt * I_n
	C, jitter_used = _cholesky_adaptive(K_noisy)
	alpha = C \ ys_norm

	if jitter_used > 1e-6
		@warn "[UQ] GP kernel matrix required large Cholesky jitter ($jitter_used)" lengthscale = l_opt
	end

	# Prediction functions
	# mean_pred uses explicit SE kernel math (no KernelFunctions dependency)
	# so that TaylorDiff can differentiate through it for the estimation pipeline.
	inv_2l2 = 1.0 / (2.0 * l_opt^2)
	function mean_pred(x)
		k_star = [σ²_opt * exp(-(x - xi)^2 * inv_2l2) for xi in xs_raw]
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
		jitter_used, hp_optimized,
	)
end

#==========================================================================
 Validation and Testing Utilities
==========================================================================#


"""
	print_uncertainty_results(uq::UncertaintyReport; io = stdout)

Terminal summary of the IFT-based parameter uncertainty report (the legacy
FD-Jacobian variant is archived in deprecated/uq_fd_path.jl).
"""
function print_uncertainty_results(uq::UncertaintyReport; io = stdout)
	println(io, "\nParameter Uncertainty (GP posterior + IFT propagation)")
	println(io, "-"^60)
	println(io, "Status: $(uq.status)   max CV: $(round(uq.max_cv; sigdigits = 3))")
	println(io, rpad("Parameter", 16), " | ", rpad("Std. Dev.", 12), " | 95% CI half-width")
	println(io, "-"^60)
	for (i, name) in enumerate(uq.param_labels)
		σ = uq.param_std[i]
		@printf(io, "%-16s | %12.6g | %12.6g\n", name, σ, UQ_CI_Z * σ)
	end
	for w in uq.warnings
		println(io, "  ! ", w)
	end
	println(io, "-"^60)
end
