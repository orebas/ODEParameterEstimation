# GP-jet bias: theory, LV mechanism, and decision table

Date: 2026-08-14

Status: investigation and decision record. No production behavior is changed by
this note.

Read with:

- [`2026-08-14_lv_multipoint_uq_conditioning.md`](2026-08-14_lv_multipoint_uq_conditioning.md)
- [`2026-08-14_peb_audited_uq_canaries.md`](2026-08-14_peb_audited_uq_canaries.md)
- [`2026-08-14_estimator_aware_uq.md`](2026-08-14_estimator_aware_uq.md)

## Executive conclusion

The audited LV miss contains two distinct effects:

1. **A real statistical effect:** a fixed GP smoother has deterministic bias for
   a fixed ODE trajectory. The current algebraic UQ propagates observation-noise
   variance through that smoother but does not include its bias.
2. **A newly isolated implementation-level amplifier:** the SE hyperparameters
   are optimized with one Float64 kernel-matrix construction, but the final GP
   factorization uses another. On this ultra-low-noise, dense-grid cell, the
   latter loses positive semidefiniteness to roundoff and triggers a Cholesky
   jitter 59 times larger than the fitted noise variance. That unreported ridge
   changes the GP mean and derivatives materially.

This is therefore not yet evidence that GP-jet estimation is irredeemable. It
is evidence that:

- the present fixed-smoother covariance is not by itself a confidence-interval
  guarantee;
- the low-noise factorization path must be repaired/audited before judging the
  irreducible GP bias;
- derivative tuning and point selection should control *downstream projected
  bias*, not only function fit or algebraic conditioning;
- full-trajectory score-equation UQ remains the most defensible production
  inferential route when trajectory polish is the selected estimator.

## Exact estimator decomposition

For fixed GP hyperparameters, the retained jet estimator is linear in the raw
observations:

```text
d_hat = W y
y     = f + epsilon

d_hat - d_true = (W f - d_true) + W epsilon
                   smoother bias   sampling noise
```

Let `S = -(Jx \ Jd)` be the exact selected-root IFT sensitivity. To first order,

```text
x_hat - x_true = S b_d + S W epsilon,
b_d            = W f - d_true.
```

Current algebraic UQ computes

```text
V_x = S W Sigma_y W' S'.
```

That is the correct repeated-observation covariance for the *fixed linear
smoother* when `W` and `Sigma_y` are treated as fixed. It does not contain the
mean shift `S b_d`, GP-hyperparameter refit variability, or shooting-point
selection variability.

For point estimation, the relevant local loss is approximately

```text
MSE_x = V_x + (S b_d)(S b_d)'.
```

For confidence intervals, minimizing MSE is not enough. The standardized bias

```text
abs((S b_d)[j]) / sqrt(V_x[j,j])
```

must also be small, or it must be estimated and removed with the uncertainty of
that removal included in the standard error.

## Is GPR BLUE?

“GPR is BLUE” is not the guarantee needed here.

- In the Gaussian random-field/kriging model with known mean and covariance,
  the posterior mean is a best linear predictor (and, under the relevant trend
  constraints, a BLUP). “Unbiased” is with respect to that stochastic model and
  trend space.
- With a fixed deterministic trajectory `f`, its repeated-noise expectation is
  `W f`, not generally `d_true`. The GP smoother shrinks spectral components;
  differentiation magnifies the importance of attenuated high-frequency
  components.
- The current implementation estimates lengthscale, signal variance, and noise
  from the same `y`. The complete estimator is therefore not linear in `y`, even
  though it is linear after conditioning on the fitted hyperparameters.
- The current empirical centering reproduces constants: order-zero weights sum
  to one and derivative weights sum to zero. It does not impose the polynomial
  reproduction constraints required to make arbitrary first/second/third
  derivative estimates unbiased over a deterministic function class.
- Marginal likelihood selects a model that balances probability of the observed
  function values against model complexity. It does not optimize derivative
  coverage or downstream ODE-parameter MSE.

Thus GP regression can be Bayes-optimal under its assumed prior and still be
conditionally biased for this particular LV trajectory. These statements are
not contradictory.

## Audited LV facts carried forward

Frozen cell: `lotka_volterra_5_1em6`, 750 observations, selected MP rows
`[25, 635]`, times `[0.6408545, 16.9292390]`.

| Fact | Value | Interpretation |
|---|---:|---|
| Maximum physical-coordinate error | `3.26565e-4` | Point recovery is excellent in absolute terms |
| First point GP-jet bias, orders 0--3 | `-9.56, +9.61, +22.48, -20.60 sigma` | Bias, not the noise draw, dominates |
| Second point total errors, orders 0--3 | `0.35, -2.13, 0.41, 1.26 sigma` | No comparable deterministic-bias failure |
| GP learned noise vs design | `+0.73%` | Noise-scale estimation is not the explanation |
| IFT prediction vs actual root error | `3.06e-4` relative disagreement | The inverse map is almost perfectly linear here |
| Raw/equilibrated `cond2(Jx)` | `2.816e7 / 108.7` | Raw condition is scale-sensitive |
| Float64/256-bit IFT disagreement | `1.06e-14` relative | Root sensitivity solve did not lose material digits |

## New finding: the “numerical” GP jitter is a real smoothing parameter

The GP hyperparameter optimizer in `src/core/derivatives.jl` constructs the SE
matrix using the explicit formula

```text
sigma2 * exp.(-D_sq / (2*l^2)).
```

The final `AGPInterpolatorUQ` in
`src/core/uncertainty_quantification.jl` reconstructs the matrix with
`KernelFunctions.kernelmatrix` and then calls `_cholesky_adaptive`.

For the audited LV fit:

| Quantity | Value |
|---|---:|
| Fitted lengthscale | `0.5500114107` |
| First point distance from left boundary | `0.6408544726 = 1.165 lengthscales` |
| Fitted normalized observation-noise variance | `1.687539e-13` |
| Added Cholesky jitter | `1.0e-11` |
| `jitter / fitted_noise_variance` | `59.26` |
| Maximum entrywise difference between the two kernel assemblies | `6.317e-13` |
| Minimum eigenvalue, optimizer-consistent noisy matrix | `+1.291e-13` |
| Minimum eigenvalue, final `kernelmatrix` noisy matrix | `-3.916e-12` |
| Negative eigenvalues in the latter Float64 symmetric matrix | `126` |
| Condition of optimizer-consistent noisy matrix | `7.943e14` |
| Explicit-matrix Cholesky reconstruction residual | `1.789e-16` |

The mathematical SE kernel is positive semidefinite; this is a dense,
near-machine-precision matrix-assembly/factorization problem. Nevertheless, the
fallback is not behaviorally neutral. The stored `chol` and `alpha` use the
extra `1e-11`, so the GP mean itself is more heavily regularized than the model
whose hyperparameters were optimized.

The warning threshold is currently `jitter > 1e-6`, so a jitter that is enormous
*relative to the fitted noise* is silent.

### Exploratory ablation (not a production result)

Holding fitted signal/noise variances fixed and using the optimizer-consistent
explicit matrix:

| Variant at the first point | Maximum absolute bias / sampling sigma |
|---|---:|
| Production factorization (`l`, jitter `1e-11`) | `22.48` |
| Same fitted `l`, no added jitter | about `7.5--7.7` |
| `0.75*l`, no added jitter | `0.65` |
| `0.75*l`, retained `1e-11` jitter | `5.31` |

At `0.75*l` without added jitter, the exploratory order-0--3 total jet RMSEs
were all below the production values. This sweep used oracle truth for
evaluation, did not re-optimize signal/noise, and used a matrix with very high
condition number. It is a lead, not a proposed patch. It shows that both the
factorization floor and lengthscale choice are plausibly actionable.

Before changing production, reproduce the intended factorization with higher
precision or a numerically consistent PSD method and propagate the alternate
jets through the retained LV root.

## Can the derivatives be debiased?

Not by subtracting an exactly known generic correction: the exact bias
`W f - d_true` contains the unknown trajectory and its derivatives. There are,
however, several viable strategies.

### 1. Remove unintended numerical regularization

Use the same kernel construction for optimization and prediction, and make the
factorization method faithful to the fitted covariance. At minimum, report and
gate on `jitter / noise_variance`, not only absolute jitter.

This is an engineering correction, not statistical debiasing, but it must come
first because the current jitter materially changes the estimator.

### 2. Derivative-oriented undersmoothing

Choose a shorter lengthscale than the function-value marginal-likelihood
optimum, increasing variance to reduce derivative bias. The covariance already
knows how to propagate the resulting fixed-`W` observation variance.

For inference, choose the amount of undersmoothing so projected bias is small
relative to projected standard error. A function-value MSE optimum generally
need not be an inference optimum.

Risk: arbitrarily shortening the lengthscale eventually makes high-order
derivative variance explode. The LV sweep already displays this bias/variance
tradeoff.

### 3. Boundary-aware point selection

The bad LV point is only `1.165` lengthscales from the boundary; the good point
is much farther from a boundary. Candidate selection currently measures the
algebraic system but not smoother boundary reliability.

Test a lengthscale- and derivative-order-aware boundary buffer, or penalize
candidate points whose jets are unstable under a small lengthscale/kernel
ladder. This may solve LV without changing the smoother globally.

### 4. More points, lower derivative order

Use additional shooting points to trade high derivative order for more
low-order constraints where the algebra permits it. This directly targets the
fact that bias and variance worsen rapidly with derivative order. It is aligned
with the original reason to pursue multipoint estimation.

### 5. Generic robust bias correction

Use a higher-order/local-polynomial pilot to estimate the leading derivative
bias, subtract it, and include the pilot's variance in the final covariance.
Local-polynomial robust-bias-correction theory covers derivative functionals and
boundaries, making it a serious comparator.

This would replace or augment the current SE-GP derivative route. It requires a
new exact influence/covariance producer before it can support estimator-aware
UQ.

### 6. Model-assisted one-step correction

ODEPE has more structure than generic nonparametric regression. Given an
initial algebraic estimate `theta0`, solve the ODE to obtain its model trajectory
`f_theta0`, then estimate the smoother's bias by

```text
b_hat(theta0) = W f_theta0 - L f_theta0,
```

where `L f_theta0` is the exact model jet. Correct the observed jet with

```text
d_corrected = W y - b_hat(theta0)
```

and re-solve once, or apply the corresponding one-step IFT correction. If
`theta0` is close, `b_hat(theta0)` may approximate the unknown `b(f_true)` very
well. The audited LV estimate is already close enough to make this especially
plausible.

Equivalently, define an estimating equation that applies the same smoother to
the observed and model-generated trajectories. At the true parameter its
expectation is centered even though `W` is a biased derivative operator.

This is the most ODE-specific “just debias it” route. Caveats:

- it changes the estimator;
- the correction depends on the noisy pilot estimate;
- UQ must differentiate through the correction/fixed-point map or refit it in a
  calibrated bootstrap;
- a wrong initial branch can produce a wrong correction;
- it approaches trajectory fitting conceptually, so it must earn its place by
  being cheaper or more robust than ordinary polish.

### 7. Avoid derivatives in the final inferential estimator

When trajectory polish wins, use its retained full-trajectory score/Hessian UQ.
The multipoint algebraic estimator can remain the basin/branch finder. This
route does not use high-order GP jets as the final estimating equation.

Integral/weak-form estimating equations are another possible long-term route:
integration transfers derivatives away from noisy data, but this is a larger
estimator redesign.

## Decision table

| Option | Point-estimate benefit | Honest-CI benefit | Effort/risk | Recommended role |
|---|---|---|---|---|
| Consistent kernel assembly + jitter-ratio gate | Potentially large at ultra-low noise | Removes a hidden estimator mismatch; does not remove all bias | Low/moderate; numerical validation required | **First** |
| Boundary-aware point/pair selection | Potentially large if LV is localized | Helps only if stability proxy tracks bias | Moderate | **First experiment** |
| Derivative-oriented undersmoothing | Direct bias/variance tradeoff | Can make bias negligible relative to SE | Moderate; needs tuning rule | **Prototype** |
| More MP points / lower derivative order | Likely improves difficult systems | Reduces reliance on fragile high-order jets | Moderate/high algebraic cost | **Prototype after pair map** |
| Model-assisted one-step correction | Could remove most of the observed bias cheaply | Requires a new influence calculation or full refit | Moderate/high, but unusually well matched to ODEPE | **High-value research prototype** |
| Local-polynomial robust bias correction | Strong generic derivative theory | Designed for derivative coverage, including boundaries | High integration cost | **Comparator / fallback** |
| GP posterior covariance or scalar noise inflation | Does not remove mean bias | No general frequentist guarantee | Easy but conceptually wrong | **Do not use as the fix** |
| Ordinary bootstrap around the fitted smoother | Captures noise conditional on fitted curve | Usually misses deterministic smoother bias | Moderate | **Insufficient alone** |
| Full trajectory polish + score UQ | Improves/retains final fit | Avoids GP derivatives in final estimating equation | Already implemented; can fail weak-curvature gates | **Primary supported route when it wins** |

## Concrete next experiment

Use only audited PEB cells; do not run the package's known-flaky registry as a
scientific benchmark.

1. **Numerical ablation on the retained LV artifact**
   - reproduce the fitted SE system with optimizer-consistent kernel assembly;
   - compare Float64, high precision, and a stable PSD factorization;
   - sweep *relative* jitter and lengthscale;
   - propagate each jet through the exact retained-root IFT;
   - record parameter bias, variance, MSE, and standardized projected bias.
2. **Production candidate-map audit**
   - evaluate all production LV shooting points/pairs on the noiseless frozen
     trajectory;
   - record boundary distance in fitted lengthscales, maximum derivative order,
     jet bias, `S b`, `S Sigma_d S'`, and equilibrated conditioning;
   - determine whether equally accurate, low-bias pairs already exist.
3. **Three estimator prototypes**
   - repaired current GP;
   - derivative-undersmoothed/boundary-aware GP;
   - one-step model-assisted bias correction.
4. **Fixed-pair repeated-noise coverage**
   - freeze the production pair and the best non-oracle rule-selected pair;
   - run at least 60 replicates;
   - measure empirical mean bias, covariance, 95% coverage, and prediction of
     both by the UQ report.
5. **Adaptive-selection coverage**
   - restore point selection and GP-hyperparameter fitting per replicate;
   - quantify the extra variability omitted by fixed-artifact UQ.
6. **Trajectory-polish comparator**
   - run the same data through the selected full-trajectory estimator and its
     score-equation UQ.
7. **External validity**
   - repeat only on two or three audited serious cells preselected for excellent
     unpolished estimation.

## Provisional production contract

- Do not relax LV to `:ok` merely because equilibrated `cond(Jx)` is small.
- Add separate numerical-factorization and smoother-validity diagnostics; do
  not let one accidental raw-condition warning stand in for the other.
- A selected trajectory-polish/direct result receives score-equation UQ.
- A selected algebraic SP/MP result receives fixed-smoother conditional
  sampling covariance. Confidence-interval language requires demonstrated
  coverage in the relevant model/noise/derivative regime.
- If the GP factorization uses jitter large relative to learned observation
  noise, report it as material regularization rather than invisible numerical
  stabilization.

## Literature anchors

- Rasmussen and Williams, *Gaussian Processes for Machine Learning*, ch. 2:
  GP regression as a linear smoother and its equivalent-kernel interpretation.
  <https://gaussianprocess.org/gpml/chapters/RW2.pdf>
- Liu and Li, *Optimal plug-in Gaussian processes for modelling derivatives*:
  positive rate results for GP derivative estimation under specified function
  classes and hyperparameter scaling. <https://arxiv.org/abs/2210.11626>
- Hadji and Szabo, *Can we trust Bayesian uncertainty quantification from
  Gaussian process priors with squared exponential covariance kernel?*:
  examples where standard empirical-Bayes SE credible sets are overconfident,
  plus modified procedures under additional conditions.
  <https://arxiv.org/abs/1904.01383>
- Calonico, Cattaneo, and Farrell, *Coverage Error Optimal Confidence Intervals
  for Local Polynomial Regression*: robust bias correction for function and
  derivative inference, including boundary behavior.
  <https://arxiv.org/abs/1808.01398>
