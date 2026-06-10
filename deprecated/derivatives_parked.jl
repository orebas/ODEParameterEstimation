# Archived 2026-06-10 from src/core/derivatives.jl — NOT part of the build.
# Dead interpolator island (verified zero live callers each; the fhdn and
# chebyshev_*/fourier_adaptive/S3 families are LIVE and remain in core):
#   - aaad_in_testing (was already a commented-out block)
#   - FourierSeries/fourierEval/FourierInterp (old Fourier path; distinct from
#     the live FourierApprox/fourier_adaptive) — was exported, export removed
#   - BarycentricLagrange, RationalFunction, simpleratinterp, betterratinterp,
#     SimpleRationalInterp, SimpleRationalInterpOld, default_interpolator
#     (the registry that was these functions' only reachability)
#   - agp_gpr_manual (docstring said BACKUP for Zygote issues; Zygote has been
#     disabled in favor of ForwardDiff+LBFGS — rationale stale)
#   - _chebyshev_deriv_coeffs (zero callers; the review also flagged its
#     recurrence as suspect — do NOT resurrect without a finite-difference test)
# ============================================================================

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

	# Precompute squared distance matrix for ForwardDiff-compatible NLL
	D²_norm = [abs2(xs_norm[i] - xs_norm[j]) for i in 1:n, j in 1:n]

	# Manual NLL — ForwardDiff-compatible (allocating, no KernelFunctions dispatch)
	function neg_logpdf(θ)
		l = exp(θ[1])      # lengthscale
		σ² = exp(θ[2])     # signal variance
		σₙ² = exp(θ[3])    # noise variance

		inv_2l² = 1.0 / (2.0 * l * l)
		K = σ² .* exp.((-inv_2l²) .* D²_norm) + σₙ² * I_n

		try
			C = cholesky(Symmetric(K))
			α = C \ ys_norm_vec
			return 0.5 * (dot(ys_norm_vec, α) + 2.0 * sum(log.(diag(C.U))) + n * log(2π))
		catch e
			@debug "GP log-likelihood evaluation failed (Cholesky)" exception = e
			return 1e8 + sum(abs2, θ)  # smooth penalty for ForwardDiff
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
		# Use bounded LBFGS with ForwardDiff exact gradients
		od = Optim.OnceDifferentiable(neg_logpdf, θ0; autodiff = AutoForwardDiff())
		result = Optim.optimize(od, lower, upper, θ0,
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
	C_opt, _jitter_used = _cholesky_adaptive(K_noisy)
	alpha = C_opt \ ys_norm_vec  # Pre-computed weights for mean prediction

	# Also create posterior for variance computation (needed for std_pred)
	kernel_opt = σ²_opt * scaled_kernel_opt
	f_opt = AbstractGPs.GP(kernel_opt)
	effective_noise_manual = σₙ²_opt + _jitter_used
	f_posterior = AbstractGPs.posterior(f_opt(xs_norm, effective_noise_manual), ys_norm)

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

function _chebyshev_deriv_coeffs(c::Vector{Float64})
	d = length(c) - 1
	d <= 0 && return [0.0]
	dc = zeros(d)
	for j in d:-1:1
		k = j - 1
		c_prime_k_plus_2 = (j + 2 <= d) ? dc[j+2] : 0.0
		dc[j] = c_prime_k_plus_2 + 2 * (k + 1) * c[k + 2]
	end
	dc[1] /= 2
	return dc
end
