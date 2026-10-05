# Internal dense SE Gaussian process

This private module implements the zero-mean, one-dimensional dense SE fit
used by `aaad_gpr_pivot`. It imports only LinearAlgebra, Statistics, Optim and
LineSearches; it does not depend on GaussianProcesses, PDMats or ODEPE.

Adapted from <https://github.com/STOR-i/GaussianProcesses.jl> and the locally
validated revision `3e896e9dbd0c41341c723ab16dcf0c261fc7b95a`. Relevant source
is `GP.jl`, `GPE.jl`, `optimize.jl`, `kernels/se_iso.jl`, and the isotropic
kernel/distance helpers. The MIT notice is retained in `LICENSE`.

## Preserved fitting policy

- Parameter order: log noise SD, log length scale, log signal SD.
- The wrapper standardizes observations; initial parameters are -2,
  log(std(times)/8), and 0. Noise variance therefore starts at exp(-4).
- Dense SE covariance, analytic marginal-likelihood gradients and unconstrained
  LBFGS with BackTracking, using Optim's default stopping options.
- The fitted noise variance is the diagonal nugget. There is no adaptive
  jitter escalation. Invalid Cholesky trials return Inf; unexpected errors and
  interrupts propagate. The final covariance must factor successfully.
- Prediction uses elementary kernel arithmetic and supports TaylorDiff and
  ForwardDiff queries. Only the fitted mean is needed by the public wrapper.

The extraction uses a private typed posterior and Julia's Cholesky directly.
It omits upstream likelihood/sampler/kernel hierarchies, covariance prediction,
sparse/elastic storage, plotting, priors, and external-type method extensions.

## Replacement boundary

`aaad_gpr_pivot` is the sole production adapter: `fit_se` accepts normalized
observations and `predict_mean` returns a normalized scalar mean. Replace those
two calls and remove the parent include to excise the module. `GPRapprox`,
`InterpolatorAAADGPR`, and the default candidate pool remain public contracts.
AGP/AGPUQ keep their own fitting policies and uncertainty contracts.

Tests contain upstream fixed-parameter fixtures, independent SE derivative
identities and analytic-gradient checks. Optional upstream comparisons live in
`test/reference`, outside the ordinary dependency graph.
