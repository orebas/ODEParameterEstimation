"""
	AbstractInterpolator

Abstract type for interpolation function objects.
All interpolators should be callable with a single argument and return the interpolated value.
"""
abstract type AbstractInterpolator end

"""
	rational_interpolation_coefficients(x, y, n)
CODE COPIED FROM previous version of ParameterEstimation.jl
Perform a rational interpolation of the data `y` at the points `x` with numerator degree `n`.
This function only returns the coefficients of the numerator and denominator polynomials.

# Arguments
- `x`: the points where the data is sampled (e.g. time points).
- `y`: the data sample.
- `n`: the degree of the numerator.

# Returns
- `c`: the coefficients of the numerator polynomial.
- `d`: the coefficients of the denominator polynomial.
"""
function rational_interpolation_coefficients(x, y, n)
	N = length(x)
	m = N - n - 1
	A = zeros(N, N)
	if m > 0
		A_left_submatrix = reduce(hcat, [x .^ (i) for i in 0:(n)])
		A_right_submatrix = reduce(hcat, [x .^ (i) for i in 0:(m-1)])
		A = hcat(A_left_submatrix, -y .* A_right_submatrix)
		b = y .* (x .^ m)
		try
			prob = LinearSolve.LinearProblem(A, b)
			c = LinearSolve.solve(prob)
			return c[1:(n+1)], [c[(n+2):end]; 1]
		catch SingularException
			lu_res = lu(A)
			y = lu_res.L \ lu_res.P * b
			c = lu_res.U \ y
			return c[1:(n+1)], [c[(n+2):end]; 1]
		end

	else
		A = reduce(hcat, [x .^ i for i in 0:n])
		b = y
		prob = LinearSolve.LinearProblem(A, b)
		c = LinearSolve.solve(prob)
		return c, [1]
	end
end





######### TODO(orebas)  REFACTOR into bary_derivs or something similiar
#to use the below, you can just pass vectors of xvalues and yvalues like so:
#F = aaad(xdata, ydata)
#and then F will be a callable, i.e. F(0.5) should work.  Let's please restrict to real xdata, and if so it should be sorted.  F is only defined in the range of the xvalues.

#To construct a derivative, you can do
#derivf(z) = ForwardDiff.derivative(F, z)
#I hope and suspect that other AD frameworks should work as well.

function baryEval(z, f::Vector{T}, x::Vector{T}, w::Vector{T}, tol = 1e-13) where {T}
	@assert(length(f) == length(x) == length(w))
	num = zero(T)
	den = zero(T)
	breakflag = false
	breakindex = -1
	for j in eachindex(f)
		t = w[j] / (z - x[j])
		num += t * f[j]
		den += t
		if ((z - x[j])^2 < sqrt(tol))
			breakflag = true
			breakindex = j
		end
	end
	fz = num / den
	if (breakflag)
		num = zero(T)
		den = zero(T)
		for j in eachindex(f)
			if (j != breakindex)
				t = w[j] / (z - x[j])
				num += t * f[j]
				den += t
			end
		end
		m = z - x[breakindex]
		fz = (w[breakindex] * f[breakindex] + m * num) / (w[breakindex] + m * den)
	end
	return fz
end

"""
	AAADapprox{T} <: AbstractInterpolator

Interpolator using AAA algorithm from BaryRational package.

# Fields
- `internalAAA::T`: Internal AAA representation from BaryRational
"""
struct AAADapprox{T} <: AbstractInterpolator
	internalAAA::T
end

"""
	FHDapprox{T} <: AbstractInterpolator

Interpolator using Floater-Hormann algorithm from BaryRational package.

# Fields
- `internalFHD::T`: Internal Floater-Hormann representation from BaryRational
"""
struct FHDapprox{T} <: AbstractInterpolator
	internalFHD::T
end

"""
	GPRapprox <: AbstractInterpolator

Interpolator using Gaussian Process Regression.

# Fields
- `gp_function::Function`: Callable function for evaluating the GPR prediction
"""
struct GPRapprox <: AbstractInterpolator
	gp_function::Function
end

"""
	AGPInterpolator <: AbstractInterpolator

GP interpolator using AbstractGPs.jl with uncertainty quantification support.

# Fields
- `mean_function::Function`: Returns mean prediction (denormalized)
- `std_function::Function`: Returns standard deviation (denormalized)
- `posterior::Any`: AbstractGPs posterior GP object
- `x_min::Float64`: Minimum x value (for normalization)
- `x_range::Float64`: Range of x values (for normalization)
- `y_mean::Float64`: Mean of y values (for denormalization)
- `y_std::Float64`: Std of y values (for denormalization)

# Usage
When called as `interp(x)`, returns mean prediction only (drop-in compatible).
For uncertainty, use `mean_and_var(interp, x)` to get (mean, variance) tuple.
"""
struct AGPInterpolator <: AbstractInterpolator
	mean_function::Function
	std_function::Function
	posterior::Any
	x_min::Float64
	x_range::Float64
	y_mean::Float64
	y_std::Float64
end

# Define call methods for each interpolator type
(y::FHDapprox)(z) = baryEval(z, y.internalFHD.f, y.internalFHD.x, y.internalFHD.w)
(y::AAADapprox)(z) = baryEval(z, y.internalAAA.f, y.internalAAA.x, y.internalAAA.w)
(y::GPRapprox)(z) = y.gp_function(z)
(y::AGPInterpolator)(z) = y.mean_function(z)

# AbstractInterpolator is defined at the top of the file

"""
	nth_deriv_at_DEPRECATED_USE_NTH_DERIV(f, n::Int, t::Real) -> Real

DEPRECATED: This function uses recursive ForwardDiff which is inefficient for high-order derivatives.
Use nth_deriv() instead, which uses TaylorDiff.

Computes the nth derivative of function f at point t using recursive ForwardDiff.
This becomes exponentially slow for n > 5 and may hang for n > 8.

# Arguments
- `f`: Function or interpolator to differentiate
- `n::Int`: Derivative order
- `t::Real`: Point at which to compute the derivative

# Returns
- Value of the nth derivative of f at t
"""
function nth_deriv_at_DEPRECATED_USE_NTH_DERIV(f, n::Int, t::Real)::Real
	if n == 0
		return f(t)
	elseif n == 1
		return ForwardDiff.derivative(f, t)
	else
		g(t) = nth_deriv_at_DEPRECATED_USE_NTH_DERIV(f, n - 1, t)
		return ForwardDiff.derivative(g, t)
	end
end

# Deprecated: Add specific methods for interpolators
nth_deriv_at_DEPRECATED_USE_NTH_DERIV(f::AbstractInterpolator, n::Int, t::Real)::Real = nth_deriv_at_DEPRECATED_USE_NTH_DERIV(x -> f(x), n, t)

# Keep nth_deriv_at as an alias to nth_deriv for backward compatibility but with a warning
function nth_deriv_at(f, n::Int, t::Real)::Real
	@warn "nth_deriv_at is deprecated due to inefficient recursive ForwardDiff. Using nth_deriv (TaylorDiff) instead." maxlog=1
	return nth_deriv(f isa AbstractInterpolator ? (x -> f(x)) : f, n, t)
end

nth_deriv_at(f::AbstractInterpolator, n::Int, t::Real)::Real = nth_deriv_at(x -> f(x), n, t)

"""
	nth_deriv(f::Function, n::Int, t::Real) -> Real

Computes the nth derivative of function f at point t using TaylorDiff.

# Arguments
- `f::Function`: Function to differentiate
- `n::Int`: Derivative order
- `t::Real`: Point at which to compute the derivative

# Returns
- Value of the nth derivative of f at t
"""
function nth_deriv(f::Function, n::Int, t::Real)::Real
	if n == 0
		return f(t)
	end

	# Use TaylorDiff - no silent fallbacks, fail loudly if it doesn't work
	return TaylorDiff.derivative(f, t, Val(n))
end

"""
	aaad_old_reliable(xs::AbstractArray{T}, ys::AbstractArray{T}) -> AAADapprox

Creates an interpolation function using AAA algorithm from BaryRational.

# Arguments
- `xs::AbstractArray{T}`: X coordinates
- `ys::AbstractArray{T}`: Y coordinates (function values)

# Returns
- AAADapprox interpolator object that can be called as a function
"""
function aaad_old_reliable(xs::AbstractArray{T}, ys::AbstractArray{T})::AAADapprox where {T}
	@assert length(xs) == length(ys) "Input arrays must have same length"
	internalApprox = BaryRational.aaa(xs, ys, verbose = false)
	return AAADapprox(internalApprox)
end

"""
	aaad(xs::AbstractArray{T}, ys::AbstractArray{T}, force_gpr::Bool=false) -> AAADapprox

Standard interpolation function using AAA algorithm.
The force_gpr parameter is kept for backward compatibility but is not used.

# Arguments
- `xs::AbstractArray{T}`: X coordinates
- `ys::AbstractArray{T}`: Y coordinates (function values)
- `force_gpr::Bool`: Unused parameter (for backward compatibility)

# Returns
- AAADapprox interpolator object that can be called as a function
"""
function aaad(xs::AbstractArray{T}, ys::AbstractArray{T}, force_gpr::Bool = false)::AAADapprox where {T}
	return aaad_old_reliable(xs, ys)
end


#=
function aaad_in_testing(xs::AbstractArray{T}, ys::AbstractArray{T}; save_plot::Union{String, Nothing} = "plot.png") where {T}
	@assert length(xs) == length(ys)

	# First smooth with GP
	# Use shorter lengthscale for more local fitting
	ll = log(std(xs) / 8)  # Changed from /4 to /8 for shorter lengthscale
	lσ = 1.0  # Increased signal variance (was 0.0)
	kernel = SEIso(ll, lσ)
	mZero = MeanZero()

	# Start with smaller noise for tighter fit
	log_noise = -2.0  # Decreased from 0.0 for less noise/smoother fit
	gp = GaussianProcesses.GP(xs, ys, mZero, kernel, log_noise)

	try
		optimize!(gp, method = BFGS(linesearch = LineSearches.BackTracking()))
	catch e
		@warn "GP optimization failed, using unoptimized GP" exception = e
	end

	# Get smoothed predictions at original points
	ys_smooth, _ = predict_y(gp, xs)

	# Save plot if requested
	if !isnothing(save_plot)
		# Create dense grid for smooth plotting
		x_plot = range(minimum(xs), maximum(xs), length = 200)
		y_plot, var_plot = predict_y(gp, x_plot)

		# Plot GP fit with confidence intervals
		p = Plots.plot(x_plot, y_plot, ribbon = 2 * sqrt.(var_plot),
			label = "GP fit", fillalpha = 0.2)
		# Add original data points
		scatter!(xs, ys, label = "Data", markersize = 3)

		# Save plot
		savefig(p, save_plot)
	end

	# Fit AAA to smoothed data
	internalApprox = BaryRational.aaa(xs, ys_smooth, verbose = false)
	return AAADapprox(internalApprox)
end=#




function fhd(xs::AbstractArray{T}, ys::AbstractArray{T}, N::Int) where {T}
	#@suppress begin
	@assert length(xs) == length(ys)
	internalApprox = BaryRational.FHInterp(xs, ys, order = N, verbose = false)
	return FHDapprox(internalApprox)
	#end
end

function fhdn(n)
	fh(xs, ys) = fhd(xs, ys, n)
	return fh
end


####################

"""
	FourierSeries <: AbstractInterpolator

Interpolator using Fourier series.

# Fields
- `m::Float64`: Scaling factor
- `b::Float64`: Offset factor
- `K::Float64`: Constant term
- `cosines::Vector{Float64}`: Coefficients for cosine terms
- `sines::Vector{Float64}`: Coefficients for sine terms
"""
struct FourierSeries <: AbstractInterpolator
	m::Float64
	b::Float64
	K::Float64
	cosines::Vector{Float64}
	sines::Vector{Float64}
end

"""
	fourierEval(x::Real, FS::FourierSeries) -> Float64

Evaluates a Fourier series at a given point.

# Arguments
- `x::Real`: Point at which to evaluate
- `FS::FourierSeries`: Fourier series object

# Returns
- Interpolated value at x
"""
function fourierEval(x::Real, FS::FourierSeries)::Float64
	z = FS.m * x + FS.b
	result = FS.K

	# Sum cosine terms
	for k in eachindex(FS.cosines)
		result += FS.cosines[k] * cos((k) * z)
	end

	# Sum sine terms
	for k in eachindex(FS.sines)
		result += FS.sines[k] * sin((k) * z)
	end

	return result
end

# Define call method for FourierSeries
(y::FourierSeries)(z) = fourierEval(z, y)



function FourierInterp(xs, ys)
	@assert length(xs) == length(ys)
	N = length(xs)
	width = xs[end] - xs[begin]
	m = pi / width
	b = -pi * (xs[begin] / width + 0.5)
	f(t) = m * t + b
	scaledxs = f.(xs)
	sinescount = (N - 1) ÷ 2
	cosinescount = N - 1 - sinescount
	A = zeros(Float64, N, N)
	for i ∈ 1:N, j ∈ 1:N
		if (j == 1)
			A[i, 1] = 1
		elseif (j <= (cosinescount + 1))
			A[i, j] = cos((j - 1) * scaledxs[i])
		else
			temp = (j - cosinescount - 1)
			A[i, j] = sin(temp * scaledxs[i])
		end
	end

	prob = LinearProblem(A, ys, LinearSolve.OperatorCondition.VeryIllConditioned)
	sol = LinearSolve.solve(prob)
	X = sol.u
	temp = FourierSeries(m, b, X[begin], X[2:(cosinescount+1)], X[(cosinescount+2):end])
	return temp
end



struct BaryLagrange{T <: AbstractArray}
	x::T
	f::T
	w::T
end

function BarycentricLagrange(xs, ys)
	@assert length(xs) == length(ys)
	N = length(xs)
	w = ones(Float64, N)
	for k in eachindex(xs)
		for j in eachindex(xs)
			if (k != j)
				w[k] *= (xs[k] - xs[j])
			end
		end
		w[k] = 1 / w[k]
	end
	return BaryLagrange(xs, ys, w)
end

(y::BaryLagrange)(z) = baryEval(z, y.f, y.x, y.w)

struct RationalFunction{T <: AbstractArray}
	a::T
	b::T
end

(y::RationalFunction)(z) = rationaleval(z, y.a, y.b)
rationaleval(z, a, b) = evalpoly(z, a) / evalpoly(z, b)



function simpleratinterp(xs, ys, d1::Int)
	@assert length(xs) == length(ys)
	N = length(xs)
	d2 = N - d1 - 1
	A = zeros(Float64, N, N)
	for j in 1:N
		A[j, 1] = 1
		for k in 1:d1
			A[j, k+1] = xs[j]^k
		end
		for k in 1:d2
			A[j, d1+1+k] = -1.0 * ys[j] * xs[j]^k
		end
	end
	prob = LinearProblem(A, ys, LinearSolve.OperatorCondition.VeryIllConditioned)
	sol = LinearSolve.solve(prob)
	X = sol.u
	return RationalFunction(
		X[1:(d1+1)],
		[1; X[(d1+2):end]])
end






function betterratinterp(xs, ys, d1::Int)
	@assert length(xs) == length(ys)
	N = length(xs)
	(c, d) = rational_interpolation_coefficients(xs, ys, d1)
	return RationalFunction(c, d)
end



function SimpleRationalInterp(numerator_degree::Int)
	f(xs, ys) = simpleratinterp(xs, ys, numerator_degree)
	return f
end

function SimpleRationalInterpOld(numerator_degree::Int)
	f(xs, ys) = betterratinterp(xs, ys, numerator_degree)
	return f
end


"""
	default_interpolator(datasize::Int) -> Dict{String, Function}

Returns a dictionary of default interpolation functions based on data size.

# Arguments
- `datasize::Int`: Number of data points available

# Returns
- Dictionary mapping interpolator names to interpolation functions
"""
function default_interpolator(datasize::Int)::Dict{String, Function}
	# Create dictionary with basic interpolators
	interpolators = Dict{String, Function}(
		"AAA" => aaad,
		"GPR" => aaad_gpr_pivot,
		"FHD3" => fhdn(3),
	)

	# Add additional interpolators for larger datasets
	if datasize > 10
		interpolators["FHD8"] = fhdn(8)

		# Add Fourier interpolation for periodic data with enough points
		if datasize > 20
			interpolators["Fourier"] = FourierInterp
		end
	end

	return interpolators
end








"""
	aaad_gpr_pivot(xs::AbstractArray{T}, ys::AbstractArray{T}) -> GPRapprox

Creates an interpolation function using Gaussian Process Regression.
Normalizes input data, applies GPR with optimized hyperparameters,
and returns a callable interpolator.

# Arguments
- `xs::AbstractArray{T}`: X coordinates
- `ys::AbstractArray{T}`: Y coordinates (function values)

# Returns
- GPRapprox interpolator object that can be called as a function
"""
function aaad_gpr_pivot(xs::AbstractArray{T}, ys::AbstractArray{T})::GPRapprox where {T}
	@assert length(xs) == length(ys) "Input arrays must have same length"

	# 1. Normalize y values
	y_mean = mean(ys)
	y_std = std(ys)
	ys_normalized = (ys .- y_mean) ./ max(y_std, 1e-8)  # Avoid division by very small numbers

	# Configure initial GP hyperparameters
	initial_lengthscale = log(std(xs) / 8)
	initial_variance = 0.0
	initial_noise = -2.0

	# Add small amount of jitter to avoid numerical issues
	kernel = SEIso(initial_lengthscale, initial_variance)
	jitter = 1e-8
	ys_jitter = ys_normalized .+ jitter * randn(length(ys))

	# 2. Do GPR approximation on normalized data
	local gp
	gp = GaussianProcesses.GP(xs, ys_jitter, MeanZero(), kernel, initial_noise)
	GaussianProcesses.optimize!(gp; method = LBFGS(linesearch = LineSearches.BackTracking()))

	# Create a function that evaluates the GPR prediction and denormalizes the output
	function denormalized_gpr(x)
		pred, _ = predict_f(gp, [x])
		return y_std * (pred[1]) + y_mean
	end

	return GPRapprox(denormalized_gpr)
end

"""
	agp_gpr_manual(xs, ys; kernel_type=:se) -> AGPInterpolator

BACKUP: Manual GP implementation using direct kernel matrix computation.
Kept as fallback in case Zygote-based optimization has issues.

Creates GP interpolator using AbstractGPs.jl with manual hyperparameter optimization.
Uses direct Cholesky factorization instead of AbstractGPs logpdf for performance.

# Arguments
- `xs::AbstractArray{T}`: X coordinates (e.g., time points)
- `ys::AbstractArray{T}`: Y coordinates (observations)
- `kernel_type::Symbol`: `:se` (Squared Exponential) or `:matern52`

# Returns
- `AGPInterpolator` - callable as `interp(x)` for mean, or use `mean_and_var(interp, x)`
"""
function agp_gpr_manual(xs::AbstractArray{T}, ys::AbstractArray{T};
                        kernel_type::Symbol = :se)::AGPInterpolator where {T}
	@assert length(xs) == length(ys) "Input arrays must have same length"
	@assert length(xs) >= 3 "Need at least 3 points for GP interpolation"

	# Handle constant data edge case
	y_std_raw = std(ys)
	if y_std_raw < 1e-10
		constant_val = mean(ys)
		return AGPInterpolator(
			x -> constant_val,
			x -> 0.0,
			nothing,
			0.0, 1.0, constant_val, 1.0
		)
	end

	# Normalize X to [0, 1]
	x_min, x_max = extrema(xs)
	x_range = max(x_max - x_min, 1e-10)
	xs_norm = (collect(xs) .- x_min) ./ x_range

	# Standardize Y (zero mean, unit variance)
	y_mean = mean(ys)
	y_std = max(y_std_raw, 1e-8)
	ys_norm = (collect(ys) .- y_mean) ./ y_std

	# Initial hyperparameters (in normalized space)
	# Match the default GPR implementation's approach
	initial_lengthscale = std(xs_norm) / 8  # Data-dependent, like default
	initial_variance = 1.0
	initial_noise_var = exp(-2.0)  # ~0.135, same as default's initial_noise = -2.0

	# Build kernel using KernelFunctions.jl
	base_kernel = kernel_type == :matern52 ? Matern52Kernel() : SqExponentialKernel()

	# Create GP with AbstractGPs.jl
	kernel = initial_variance * (base_kernel ∘ ScaleTransform(1.0 / initial_lengthscale))
	f = AbstractGPs.GP(kernel)

	# Add observation noise and condition on data
	# In AbstractGPs, noise is passed as second argument to FiniteGP: f(x, noise_var)
	f_posterior = AbstractGPs.posterior(f(xs_norm, initial_noise_var), ys_norm)

	# Pre-compute fixed parts for optimization (PERFORMANCE: avoid GP object creation)
	n = length(xs_norm)
	I_n = Matrix{Float64}(I, n, n)
	ys_norm_vec = collect(ys_norm)  # Ensure it's a Vector

	# Optimize hyperparameters using direct kernel matrix computation
	# This avoids creating new GP objects on every optimization iteration
	function neg_logpdf(θ)
		l = exp(θ[1])      # lengthscale
		σ² = exp(θ[2])     # signal variance
		σₙ² = exp(θ[3])    # noise variance

		# Build kernel matrix directly (no GP object needed)
		scaled_kernel = base_kernel ∘ ScaleTransform(1.0 / l)
		K = σ² * kernelmatrix(scaled_kernel, xs_norm)
		K_noisy = K + σₙ² * I_n

		try
			# Cholesky factorization for log-likelihood
			C = cholesky(Symmetric(K_noisy))
			α = C \ ys_norm_vec

			# Log marginal likelihood: -0.5 * (y'α + logdet(K) + n*log(2π))
			loglik = -0.5 * (dot(ys_norm_vec, α) + logdet(C) + n * log(2π))
			return -loglik
		catch
			return Inf
		end
	end

	# Initial values in log space (like GaussianProcesses.jl)
	θ0 = [log(initial_lengthscale), log(initial_variance), log(initial_noise_var)]

	# Bounds for log hyperparameters to ensure numerical stability
	lower = [-5.0, -5.0, -10.0]  # exp(-5) ≈ 0.007, exp(-10) ≈ 4.5e-5
	upper = [5.0, 5.0, 2.0]      # exp(5) ≈ 148, exp(2) ≈ 7.4

	# Optimized hyperparameters (will be updated if optimization succeeds)
	l_opt = initial_lengthscale
	σ²_opt = initial_variance
	σₙ²_opt = initial_noise_var

	try
		# Use bounded LBFGS with BackTracking line search for robustness
		result = Optim.optimize(neg_logpdf, lower, upper, θ0,
			Fminbox(LBFGS(linesearch = LineSearches.BackTracking())),
			Optim.Options(iterations = 100))
		θ_opt = Optim.minimizer(result)
		l_opt = exp(θ_opt[1])
		σ²_opt = exp(θ_opt[2])
		σₙ²_opt = exp(θ_opt[3])
	catch e
		@warn "AbstractGPs hyperparameter optimization failed, using defaults" exception = e
	end

	# Pre-compute cached values for fast predictions (PERFORMANCE: O(n) per prediction)
	scaled_kernel_opt = base_kernel ∘ ScaleTransform(1.0 / l_opt)
	K_train = σ²_opt * kernelmatrix(scaled_kernel_opt, xs_norm)
	K_noisy = K_train + σₙ²_opt * I_n
	C_opt = cholesky(Symmetric(K_noisy))
	alpha = C_opt \ ys_norm_vec  # Pre-computed weights for mean prediction

	# Also create posterior for variance computation (needed for std_pred)
	kernel_opt = σ²_opt * scaled_kernel_opt
	f_opt = AbstractGPs.GP(kernel_opt)
	f_posterior = AbstractGPs.posterior(f_opt(xs_norm, σₙ²_opt), ys_norm)

	# Prediction functions using cached alpha (PERFORMANCE: O(n) per prediction)
	function mean_pred(x::Real)
		x_n = (x - x_min) / x_range
		# Compute k_star = kernel vector between x_n and training points
		k_star = [σ²_opt * scaled_kernel_opt(x_n, xi) for xi in xs_norm]
		# Mean = k_star' * alpha
		return y_std * dot(k_star, alpha) + y_mean
	end

	function std_pred(x::Real)
		x_n = (x - x_min) / x_range
		# For variance, still use posterior (could optimize further if needed)
		pred_dist = f_posterior([x_n])
		return y_std * sqrt(AbstractGPs.var(pred_dist)[1])
	end

	return AGPInterpolator(mean_pred, std_pred, f_posterior, x_min, x_range, y_mean, y_std)
end

"""
	agp_gpr(xs, ys; kernel_type=:se) -> AGPInterpolator

Creates GP interpolator using AbstractGPs.jl with Zygote-based hyperparameter optimization.
This is the recommended approach - uses automatic differentiation for efficient gradient
computation, following the AbstractGPs.jl best practices.

Normalizes both X (to [0,1]) and Y (standardize) for numerical stability.

# Arguments
- `xs::AbstractArray{T}`: X coordinates (e.g., time points)
- `ys::AbstractArray{T}`: Y coordinates (observations)
- `kernel_type::Symbol`: `:se` (Squared Exponential) or `:matern52`

# Returns
- `AGPInterpolator` - callable as `interp(x)` for mean, or use `mean_and_var(interp, x)`

# Example
```julia
interp = agp_gpr(t_data, y_data)
prediction = interp(1.5)                      # Mean only
mean_val, variance = mean_and_var(interp, 1.5)  # With uncertainty
```
"""
function agp_gpr(xs::AbstractArray{T}, ys::AbstractArray{T};
                 kernel_type::Symbol = :se)::AGPInterpolator where {T}
	@assert length(xs) == length(ys) "Input arrays must have same length"
	@assert length(xs) >= 3 "Need at least 3 points for GP interpolation"

	# Handle constant data edge case
	y_std_raw = std(ys)
	if y_std_raw < 1e-10
		constant_val = mean(ys)
		return AGPInterpolator(
			x -> constant_val,
			x -> 0.0,
			nothing,
			0.0, 1.0, constant_val, 1.0
		)
	end

	# NO X normalization - use raw X values like GPR does
	# This avoids chain rule complications when computing derivatives with TaylorDiff
	xs_raw = collect(xs)

	# Standardize Y only (zero mean, unit variance)
	y_mean = mean(ys)
	y_std = max(y_std_raw, 1e-8)
	ys_norm = (collect(ys) .- y_mean) ./ y_std

	# Add small jitter to avoid numerical issues (matching GPR)
	jitter = 1e-8
	ys_norm = ys_norm .+ jitter * randn(length(ys_norm))

	# Initial hyperparameters (in log space for unconstrained optimization)
	# Match GPR: use raw xs std (not normalized)
	initial_log_lengthscale = log(std(xs_raw) / 8)
	initial_log_variance = 0.0  # log(1.0)
	initial_log_noise = -2.0    # ~0.135

	# Build base kernel using KernelFunctions.jl
	base_kernel = kernel_type == :matern52 ? Matern52Kernel() : SqExponentialKernel()

	# Loss function using AbstractGPs - Zygote can differentiate through this
	# NO floors on exp() - this preserves gradients for optimization
	# Handle numerical issues via try/catch like GaussianProcesses.jl does
	function neg_logpdf_agp(θ)
		l = exp(θ[1])      # lengthscale
		σ² = exp(θ[2])     # signal variance - NO floor
		σₙ² = exp(θ[3])    # noise variance - NO floor

		# Build kernel with current hyperparameters
		k = σ² * (base_kernel ∘ ScaleTransform(1.0 / l))
		gp = AbstractGPs.GP(k)

		# Compute negative log marginal likelihood (using raw X)
		try
			return -logpdf(gp(xs_raw, σₙ²), ys_norm)
		catch
			return Inf
		end
	end

	# Gradient function using Zygote
	function grad_neg_logpdf(θ)
		g = Zygote.gradient(neg_logpdf_agp, θ)[1]
		# Handle case where gradient is nothing or has NaN
		if isnothing(g) || any(isnan, g) || any(isinf, g)
			return zeros(3)
		end
		return g
	end

	# Initial values
	θ0 = [initial_log_lengthscale, initial_log_variance, initial_log_noise]

	# Optimized hyperparameters (defaults in case optimization fails)
	l_opt = exp(initial_log_lengthscale)
	σ²_opt = 1.0
	σₙ²_opt = exp(initial_log_noise)

	try
		# Use unbounded LBFGS to match GPR behavior exactly
		result = Optim.optimize(
			neg_logpdf_agp,
			grad_neg_logpdf,
			θ0,
			LBFGS(linesearch = LineSearches.BackTracking()),
			Optim.Options();  # Default iterations (1000)
			inplace = false
		)
		θ_opt = Optim.minimizer(result)
		l_opt = exp(θ_opt[1])
		σ²_opt = exp(θ_opt[2])   # NO floor - trust optimizer result
		σₙ²_opt = exp(θ_opt[3]) # NO floor - trust optimizer result
	catch e
		@warn "AbstractGPs hyperparameter optimization failed, using defaults" exception = e
	end

	# Build final GP with optimized hyperparameters (using raw X)
	scaled_kernel_opt = base_kernel ∘ ScaleTransform(1.0 / l_opt)
	kernel_opt = σ²_opt * scaled_kernel_opt
	f_opt = AbstractGPs.GP(kernel_opt)
	f_posterior = AbstractGPs.posterior(f_opt(xs_raw, σₙ²_opt), ys_norm)

	# Pre-compute cached alpha for TaylorDiff-compatible predictions
	# This avoids going through AbstractGPs/KernelFunctions/Distances which don't support TaylorScalar
	n = length(xs_raw)
	I_n = Matrix{Float64}(I, n, n)
	K_train = σ²_opt * kernelmatrix(scaled_kernel_opt, xs_raw)
	K_noisy = K_train + σₙ²_opt * I_n
	C_opt = cholesky(Symmetric(K_noisy))
	alpha = C_opt \ collect(ys_norm)  # Pre-computed weights for mean prediction

	# Prediction using cached alpha - TaylorDiff compatible (only basic arithmetic)
	# This is O(n) per prediction and works with TaylorScalar because kernel(x, xi)
	# is just exp(-0.5 * (x - xi)^2 / l^2) - basic math operations
	# NO X normalization - use raw x directly like GPR
	function mean_pred(x::Real)
		# Compute k_star = kernel vector between x and training points (raw X)
		# Using manual evaluation instead of kernelmatrix to support TaylorScalar
		k_star = [σ²_opt * scaled_kernel_opt(x, xi) for xi in xs_raw]
		# Mean = k_star' * alpha
		return y_std * dot(k_star, alpha) + y_mean
	end

	function std_pred(x::Real)
		# For variance, still use posterior (not used in TaylorDiff path)
		pred_var = AbstractGPs.var(f_posterior([x]))[1]
		return y_std * sqrt(pred_var)
	end

	# Store dummy values for x_min/x_range since we're not using X normalization
	return AGPInterpolator(mean_pred, std_pred, f_posterior, 0.0, 1.0, y_mean, y_std)
end

"""
	mean_and_var(interp::AGPInterpolator, x::Real) -> (Float64, Float64)

Returns both mean prediction and variance at point x.

# Arguments
- `interp::AGPInterpolator`: The GP interpolator
- `x::Real`: Point at which to evaluate

# Returns
- Tuple of (mean, variance) - both denormalized to original data scale
"""
function mean_and_var(interp::AGPInterpolator, x::Real)
	mean_val = interp.mean_function(x)
	std_val = interp.std_function(x)
	return (mean_val, std_val^2)
end

"""
	agp_gpr_robust(xs, ys; kernel_type=:se) -> AGPInterpolator

Robust GP interpolator that fixes failures on smooth/noiseless data.

Uses softplus reparameterization (hyperparams are always strictly positive),
bounded optimization via Fminbox(LBFGS), and direct Cholesky log-likelihood
(avoids ScaledKernel in the optimization loop). Automatically detects smooth
data and initializes noise variance low.

Returns an `AGPInterpolator` compatible with TaylorDiff for derivative computation.

# Arguments
- `xs::AbstractArray{T}`: Input x-values
- `ys::AbstractArray{T}`: Output y-values
- `kernel_type::Symbol`: Kernel type, `:se` (default) or `:matern52`

# Returns
- `AGPInterpolator`: GP interpolator with mean and std prediction functions
"""
function agp_gpr_robust(xs::AbstractArray{T}, ys::AbstractArray{T};
                        kernel_type::Symbol = :se)::AGPInterpolator where {T}
	@assert length(xs) == length(ys) "Input arrays must have same length"
	@assert length(xs) >= 3 "Need at least 3 points for GP interpolation"

	# --- Softplus helpers (overflow-safe) ---
	_softplus(x::Real) = x > 34.0 ? x : log(1.0 + exp(x))
	_inv_softplus(y::Real) = y > 34.0 ? y : log(exp(y) - 1.0)

	# Handle constant data edge case (same as agp_gpr)
	y_std_raw = std(ys)
	if y_std_raw < 1e-10
		constant_val = mean(ys)
		return AGPInterpolator(
			x -> constant_val,
			x -> 0.0,
			nothing,
			0.0, 1.0, constant_val, 1.0
		)
	end

	# NO X normalization (same as agp_gpr, required for TaylorDiff)
	xs_raw = collect(Float64, xs)
	n = length(xs_raw)

	# Standardize Y only (zero mean, unit variance)
	y_mean = mean(ys)
	y_std = max(y_std_raw, 1e-8)
	ys_norm = (collect(Float64, ys) .- y_mean) ./ y_std

	# Add small jitter to avoid numerical issues (matching agp_gpr)
	jitter = 1e-8
	ys_norm = ys_norm .+ jitter * randn(length(ys_norm))

	# --- Smoothness detection via second finite differences ---
	if n >= 3
		d2 = [ys_norm[i+2] - 2.0 * ys_norm[i+1] + ys_norm[i] for i in 1:(n-2)]
		roughness = mean(abs.(d2))
	else
		roughness = 1.0
	end

	if roughness < 0.1
		init_noise = 1e-6    # very smooth data
	elseif roughness < 1.0
		init_noise = 1e-4    # moderate
	else
		init_noise = 0.01    # noisy
	end

	# Build base kernel
	base_kernel = kernel_type == :matern52 ? Matern52Kernel() : SqExponentialKernel()

	# Initial hyperparameters
	init_lengthscale = std(xs_raw) / 8.0
	init_signal_var = 1.0

	# --- Optimization in softplus-reparameterized space ---
	# θ = [θ_l, θ_σ², θ_σₙ²] where actual = softplus(θ)
	θ0 = [_inv_softplus(init_lengthscale), _inv_softplus(init_signal_var), _inv_softplus(init_noise)]

	# Bounds in θ-space (mapped through softplus to actual hyperparameter bounds)
	θ_lower = [_inv_softplus(1e-3), _inv_softplus(1e-8), _inv_softplus(1e-10)]
	θ_upper = [_inv_softplus(150.0), _inv_softplus(150.0), _inv_softplus(10.0)]

	# Identity matrix (pre-allocate)
	I_n = Matrix{Float64}(I, n, n)

	# Negative log marginal likelihood using direct Cholesky (no ScaledKernel)
	function neg_logpdf_robust(θ)
		l = _softplus(θ[1])
		σ² = _softplus(θ[2])
		σₙ² = _softplus(θ[3])

		# Build kernel matrix directly: σ² * K(X,X) + σₙ² * I
		k_base = base_kernel ∘ ScaleTransform(1.0 / l)
		K = σ² * kernelmatrix(k_base, xs_raw) + σₙ² * I_n

		try
			C = cholesky(Symmetric(K))
			# log marginal likelihood: -0.5 * (y'K⁻¹y + log|K| + n*log(2π))
			alpha_local = C \ ys_norm
			data_fit = dot(ys_norm, alpha_local)
			log_det = 2.0 * sum(log.(diag(C.U)))
			return 0.5 * (data_fit + log_det + n * log(2π))
		catch
			return Inf
		end
	end

	# Defaults in case optimization fails
	l_opt = init_lengthscale
	σ²_opt = init_signal_var
	σₙ²_opt = init_noise

	try
		result = Optim.optimize(
			neg_logpdf_robust,
			θ_lower,
			θ_upper,
			θ0,
			Fminbox(LBFGS(linesearch = LineSearches.BackTracking())),
			Optim.Options(iterations = 1000);
		)
		θ_opt = Optim.minimizer(result)
		l_opt = _softplus(θ_opt[1])
		σ²_opt = _softplus(θ_opt[2])
		σₙ²_opt = _softplus(θ_opt[3])
	catch e
		@warn "agp_gpr_robust: hyperparameter optimization failed, using adaptive defaults" exception = e
	end

	# --- Build final GP with optimized hyperparameters ---
	scaled_kernel_opt = base_kernel ∘ ScaleTransform(1.0 / l_opt)

	# Build posterior via AbstractGPs for std predictions
	kernel_opt = σ²_opt * scaled_kernel_opt
	f_opt = AbstractGPs.GP(kernel_opt)
	f_posterior = AbstractGPs.posterior(f_opt(xs_raw, σₙ²_opt), ys_norm)

	# Pre-compute alpha for TaylorDiff-compatible mean predictions
	K_train = σ²_opt * kernelmatrix(scaled_kernel_opt, xs_raw)
	K_noisy = K_train + σₙ²_opt * I_n
	C_opt = cholesky(Symmetric(K_noisy))
	alpha = C_opt \ collect(ys_norm)

	# Prediction using cached alpha - TaylorDiff compatible (only basic arithmetic)
	function mean_pred(x::Real)
		k_star = [σ²_opt * scaled_kernel_opt(x, xi) for xi in xs_raw]
		return y_std * dot(k_star, alpha) + y_mean
	end

	function std_pred(x::Real)
		pred_var = AbstractGPs.var(f_posterior([x]))[1]
		return y_std * sqrt(max(pred_var, 0.0))
	end

	return AGPInterpolator(mean_pred, std_pred, f_posterior, 0.0, 1.0, y_mean, y_std)
end
