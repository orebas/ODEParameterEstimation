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

# Define call methods for each interpolator type
(y::FHDapprox)(z) = baryEval(z, y.internalFHD.f, y.internalFHD.x, y.internalFHD.w)
(y::AAADapprox)(z) = baryEval(z, y.internalAAA.f, y.internalAAA.x, y.internalAAA.w)
(y::GPRapprox)(z) = y.gp_function(z)

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

	# Prefer TaylorDiff for moderate orders; fall back for very high orders
	if n <= 20
		try
			return TaylorDiff.derivative(f, t, Val(n))
		catch e
			# Fall through to robust fallback below
		end
	end

	# Fallback: recursive ForwardDiff (slower, but avoids factorial overflow limits)
	return nth_deriv_at_DEPRECATED_USE_NTH_DERIV(f, n, t)
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
	gp = GP(xs, ys, mZero, kernel, log_noise)

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
	gp = GP(xs, ys_jitter, MeanZero(), kernel, initial_noise)
	GaussianProcesses.optimize!(gp; method = LBFGS(linesearch = LineSearches.BackTracking()))

	# Create a function that evaluates the GPR prediction and denormalizes the output
	function denormalized_gpr(x)
		pred, _ = predict_f(gp, [x])
		return y_std * (pred[1]) + y_mean
	end

	return GPRapprox(denormalized_gpr)
end
