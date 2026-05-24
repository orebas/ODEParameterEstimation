# Research TODO: Estimator-Covariance UQ for Algebraic Parameter Estimation

Date: 2026-05-24

## Status

The current UQ implementation in `src/core/uncertainty_quantification.jl` is an
experimental sidecar. It already has pieces of an IFT/delta-method architecture:

- a vector of estimated observable values and derivatives,
- a parameter/root solution,
- a local sensitivity map,
- propagation of an observation covariance to parameter covariance.

The weak link is the covariance assigned to the derivative-estimate vector. The
current implementation uses squared-exponential GP posterior derivative
covariance. That covariance is a Bayesian latent-function posterior covariance
under the GP model. It is not, by itself, a calibrated frequentist sampling
covariance for the actual derivative estimator used by ODEPE.

Empirically, the resulting intervals do not pass basic repeated-noise coverage
checks. Treat the current UQ output as experimental and not publication-grade.

## Desired Target

Define the algebraic estimation problem locally as

```text
F(theta, z) = 0
```

where `theta` contains the selected branch/root parameters and `z` is the vector
of observable values and derivatives used by the algebraic equations. Around a
regular branch with nonsingular `F_theta`, the implicit function theorem gives

```text
S = -F_theta^{-1} F_z
Cov(theta_hat) approx S Cov(z_hat) S'
```

The research problem is to construct a useful, calibrated `Cov(z_hat)` without
running inference-time Monte Carlo.

## Recommended Direction

Estimate `Cov(z_hat)` as the sampling covariance of the derivative estimator,
not as GP posterior latent-function covariance.

For fixed GP hyperparameters, the GP posterior mean derivative estimator is a
linear smoother:

```text
z_hat = W y
```

where `y` is the measured data vector and `W` is the stacked derivative
influence matrix. Each row of `W` is a derivative-evaluation weight vector, e.g.

```text
W_d(t) = d_t^d k(t, X)' (K + sigma_n^2 I)^{-1}
```

for derivative order `d` at time `t`.

If measurement noise has covariance `Sigma_y`, then

```text
Cov(z_hat) approx W Sigma_y W'
```

This is the covariance object that should be fed into the algebraic IFT funnel.

## Noise-Covariance Options

1. Known synthetic noise:

```text
Sigma_y = sigma^2 I
```

or heteroscedastic diagonal noise if the benchmark supplies pointwise variances.

2. Estimated homoscedastic noise:

Use residuals from the smoother and an effective degrees-of-freedom correction.
For smoother matrix

```text
H = K (K + sigma_n^2 I)^{-1}
```

a practical estimate is

```text
df_resid = n - 2 tr(H) + tr(H' H)
sigma_hat^2 = ||(I - H)y||^2 / df_resid
Sigma_y = sigma_hat^2 I
```

3. Heteroscedastic or misspecified noise:

Use a sandwich/HC-style covariance:

```text
Cov(z_hat) approx W Diagonal(r_i^2 / (1 - h_i)^2) W'
```

where `r_i` are smoother residuals and `h_i` are leverages from `H`.

## Bias Caveat

`W Sigma_y W'` captures variance from measurement noise, not smoothing bias.
Coverage can still fail if GP smoothing bias is material, especially for high
derivatives, short lengthscales, boundaries, or model misspecification.

Possible guards:

- avoid boundary evaluation points,
- include derivative-order-specific calibration factors,
- estimate bias from held-out residual behavior,
- calibrate inflation factors from the derivative-estimation benchmark,
- report conditioning and linearization diagnostics alongside intervals.

Do not silently interpret uncalibrated `1.96 * std` intervals as 95% coverage.

## Implementation Sketch

1. Add a function that builds the derivative influence matrix `W` for an
   `AGPInterpolatorUQ`, a set of evaluation times, and derivative orders.
2. Add a function that estimates `Sigma_y` from known noise metadata or smoother
   residuals.
3. Replace or add an alternative to GP posterior `build_observation_covariance`
   that returns `Cov(z_hat) = W Sigma_y W'`.
4. Feed that covariance into the existing IFT propagation path.
5. Add repeated-noise coverage tests on simple identifiable systems before
   exposing the method as anything other than experimental.

## Validation Gate

A candidate UQ implementation should pass repeated-noise checks before it is
used in papers or user-facing documentation:

- simulate the same problem many times at fixed noise;
- run the full estimator;
- compute intervals without inference-time Monte Carlo;
- measure empirical coverage by parameter and by system;
- stratify failures by derivative order, condition number, branch/root choice,
  and residual fit quality.

Target behavior: nominal 95% intervals should be close to 95% coverage on
well-conditioned systems where the selected branch is correct. Bad coverage on
ill-conditioned or wrong-branch cases should be explained by diagnostics, not
hidden.

