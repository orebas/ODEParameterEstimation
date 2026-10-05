# Adapted from GaussianProcesses.jl 3e896e9 (MIT). See LICENSE and README.md.
module GPBackend

using LinearAlgebra
using Statistics
using Optim
using LineSearches

# Correctly rounded log(2π), matching upstream's IrrationalConstants value.
# log(2*pi) first rounds 2π and differs by one ulp, changing clean-fit searches.
const LOG_TWO_PI = 1.837877066409345483560659472811

"""Private dense SE posterior; parameters are (log noise SD, log ℓ, log signal SD)."""
struct SEGPFit
    xs::Vector{Float64}
    log_parameters::Vector{Float64}
    covariance::Matrix{Float64}
    factor::Cholesky{Float64,Matrix{Float64}}
    alpha::Vector{Float64}
    nll::Float64
    converged::Bool
    iterations::Int
end

"""
    evaluate_se(xs, ys, parameters; gradient=false)

# Arguments
- `xs`, `ys`: One-dimensional training data, already normalized by the caller.
- `parameters`: Log noise standard deviation, log length scale, log signal SD.
- `gradient`: Compute the analytic negative marginal-likelihood gradient.

# Returns
Covariance, Cholesky factor, weights, negative log likelihood, and gradient.
The arithmetic and gradient accumulation order follow the upstream dense SE
path. There is no added jitter: failed Cholesky trials are rejected by fitting.
"""
function evaluate_se(xs::Vector{Float64}, ys::Vector{Float64}, parameters::AbstractVector;
    gradient::Bool=false)
    length(parameters) == 3 || throw(ArgumentError("SE fitting requires three log parameters"))
    all(isfinite, parameters) || throw(ArgumentError("GP log parameters must be finite"))
    noise = exp(2parameters[1])
    ell2 = exp(2parameters[2])
    signal = exp(2parameters[3])
    n = length(xs)
    K = Matrix{Float64}(undef,n,n)
    for j in 1:n, i in 1:n
        K[i,j] = signal * exp(-0.5*(xs[i]-xs[j])^2/ell2)
    end
    for i in 1:n
        K[i,i] += noise
    end
    C = cholesky!(Symmetric(copy(K), :U))
    alpha = C \ ys
    nll = (dot(ys,alpha) + logdet(C) + LOG_TWO_PI*n)/2
    grad = zeros(3)
    if gradient
        A = -Matrix{Float64}(I,n,n)
        ldiv!(C,A)
        BLAS.ger!(1.0,alpha,alpha,A)
        grad[1] = -noise * tr(A)
        # Upstream sums each diagonal followed by its lower-triangular column.
        for j in 1:n
            grad[3] -= (2signal) * A[j,j]/2.0
            for i in j+1:n
                r = (xs[i]-xs[j])^2
                k = signal * exp(-0.5*r/ell2)
                grad[2] -= (r/ell2*k) * A[i,j]
                grad[3] -= (2k) * A[i,j]
            end
        end
    end
    return (; covariance=K, factor=C, alpha, nll, gradient=grad)
end

"""
    fit_se(xs, ys; log_lengthscale=log(std(xs)/8), log_signal_std=0, log_noise_std=-2)

# Arguments
- `xs`, `ys`: Training positions and normalized observations.
- Log parameters: Initial length scale, signal SD and observation noise SD.

# Returns
A private `SEGPFit` optimized with the upstream unconstrained LBFGS policy.
Expected invalid trials return Inf to the optimizer; unexpected failures and
interrupts propagate. A failed final factorization is never silently replaced.
"""
function fit_se(xs::AbstractVector, ys::AbstractVector;
    log_lengthscale::Real=log(std(xs)/8), log_signal_std::Real=0.0,
    log_noise_std::Real=-2.0)::SEGPFit
    length(xs) == length(ys) || throw(DimensionMismatch("GP positions and observations must have equal length"))
    isempty(xs) && throw(ArgumentError("GP training data must not be empty"))
    x, y = Float64.(xs), Float64.(ys)
    all(isfinite,x) && all(isfinite,y) || throw(ArgumentError("GP training data must be finite"))
    # SEIso stores exp(2logℓ), then reconstructs logℓ for Optim. Preserve that
    # round trip, including its last-bit effects on nearly noiseless fits.
    initial = [Float64(log_noise_std), log(exp(2Float64(log_lengthscale)))/2,
        log(exp(2Float64(log_signal_std)))/2]
    function target(parameters, storage=nothing)
        try
            state = evaluate_se(x,y,parameters; gradient=!isnothing(storage))
            isnothing(storage) || copyto!(storage,state.gradient)
            return state.nll
        catch err
            if err isa PosDefException || err isa ArgumentError
                return Inf
            end
            rethrow()
        end
    end
    f(p) = target(p)
    g!(g,p) = (target(p,g); nothing)
    fg!(g,p) = target(p,g)
    objective = Optim.OnceDifferentiable(f,g!,fg!,initial)
    result = Optim.optimize(objective,initial,LBFGS(linesearch=LineSearches.BackTracking()))
    parameters = Optim.minimizer(result)
    state = evaluate_se(x,y,parameters)
    return SEGPFit(x,copy(parameters),state.covariance,state.factor,state.alpha,
        state.nll,Optim.converged(result),Optim.iterations(result))
end

"""
    predict_mean(fit, x)

# Arguments
- `fit`: Dense SE fit in normalized observation units.
- `x`: Scalar query, including ForwardDiff or TaylorDiff scalar types.

# Returns
The posterior mean. Only elementary kernel arithmetic depends on the query.
"""
function predict_mean(fit::SEGPFit, x::Real)
    ell2 = exp(2fit.log_parameters[2])
    signal = exp(2fit.log_parameters[3])
    cross = [signal * exp(-0.5*(t-x)^2/ell2) for t in fit.xs]
    # Match the upstream n×1 cross-covariance matrix multiplication. BLAS dot
    # uses a different reduction order, visible in nearly noiseless posteriors.
    return only(reshape(cross,:,1)' * fit.alpha)
end

end
