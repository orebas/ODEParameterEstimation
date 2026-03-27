# Sensitivity Prediction Analysis — 2026-03-22

## Context

After fixing `_obs_trfn_` leaking through the diagnostic pipeline (which caused NaN Jacobians
and polynomial residuals for transcendental models), we investigated how well the sensitivity
analysis predicts actual estimation errors for `forced_lv_sinusoidal`.

Model: forced Lotka-Volterra with sin(2t) forcing, 4 params (α,β,γ,δ), 2 states (x,y).
After transcendental transform: 12×12 polynomial system, 6 data vars, 12 unknowns.

## Key Finding: The Polynomial System Has Alternating Structure

The 12 equations alternate between **data equations** (inject GP interpolation values as
constants) and **structural equations** (encode ODE relationships, always satisfied exactly):

```
Eq1:  y_0 - [GP y2(t_eval)]       = 0   ← data,  δF = 0.040  (order 0)
Eq2:  y_1 + γ·y_0 - δ·x_0·y_0    = 0   ← ODE,   δF = 0
Eq3:  x_0 - [GP y1(t_eval)]       = 0   ← data,  δF = 0.078  (order 0)
Eq4:  x_1 - α·x_0 + β·x_0·y_0    = 0   ← ODE,   δF = 0
Eq5:  y_1 - [GP y2'(t_eval)]      = 0   ← data,  δF = -0.002 (order 1)
Eq6:  (structural for y_2)        = 0   ← ODE,   δF = 0
Eq7:  x_1 - [GP y1'(t_eval)]      = 0   ← data,  δF = 0.095  (order 1)
Eq8:  (structural for x_2)        = 0   ← ODE,   δF = 0
Eq9:  y_2 - [GP y2''(t_eval)]     = 0   ← data,  δF = -0.317 (order 2)
Eq10: (structural for y_3)        = 0   ← ODE,   δF = 0
Eq11: x_2 - [GP y1''(t_eval)]     = 0   ← data,  δF = 2.111  (order 2)  ← DOMINANT ERROR
Eq12: (structural for x_3)        = 0   ← ODE,   δF = 0
```

**All estimation error enters through the 6 data constants.** Errors grow with derivative
order: ~0.05 (order 0), ~0.05 (order 1), ~1.2 (order 2). The order-2 derivatives are
10-50× worse than order-0.

## IFT Prediction = Newton Step from Truth

The sensitivity prediction δx = S·δd is equivalent to one Newton step on the production
polynomial system F_prod(x) = 0, starting from the true values x*:

```
δx_predicted = -J(x*)⁻¹ · F_prod(x*)
```

This works because F_prod(x*) = the residual at truth = the data error propagated through
the equations. The structural equations contribute zero residual.

## Datasize Scaling Experiment

| n_pts | ‖F(x*)‖ | ‖δx‖ | 1-Newton pred err | 2-Newton err | Param rel err range |
|-------|----------|-------|-------------------|--------------|---------------------|
| 31    | 2.14     | 12.57 | **46.7%**         | ~0           | 50–692%             |
| 51    | 0.23     | 2.05  | **23.6%**         | ~0           | 2–110%              |
| 201   | 0.001    | 0.006 | **0.03%**         | ~0           | 0.02–0.4%           |

Key observations:
- **Jacobian cond is constant** (~430-484) across all datasizes — it's intrinsic to the
  polynomial system at this eval point
- **2 Newton steps always converge to machine precision** — confirming only 1 algebraic
  branch (HC.jl finds 1 solution at each shooting point)
- The linear prediction degrades gracefully: perfect at n=201 (ratio≈1.000), off by
  10-40% at n=51, off by 2× at n=31
- Convergence is roughly O(n⁻²) to O(n⁻³) on parameter errors

## Per-Parameter Linear Prediction Quality (n=31)

| Unknown   | δx_actual | δx_predicted | ratio | Notes                    |
|-----------|-----------|--------------|-------|--------------------------|
| y_0       | +0.040    | +0.040       | 1.00  | Linear equation          |
| x_0       | +0.078    | +0.078       | 1.00  | Linear equation          |
| delta_0   | -0.831    | -1.193       | 0.70  | Nonlinear, 30% off       |
| gamma_0   | -2.740    | -3.997       | 0.69  | Nonlinear, 31% off       |
| y_1       | -0.002    | -0.002       | 1.00  | Linear equation          |
| alpha_0   | +0.746    | +0.490       | 1.52  | Nonlinear, 52% off       |
| x_1       | +0.095    | +0.095       | 1.00  | Linear equation          |
| beta_0    | +6.917    | +7.285       | 0.95  | Nearly linear at this pt |
| y_2       | -0.317    | -0.317       | 1.00  | Linear equation          |
| x_2       | +2.111    | +2.111       | 1.00  | Linear equation          |
| y_3       | +0.783    | +1.601       | 0.49  | Highest-order, worst     |
| x_3       | +9.814    | +4.168       | 2.35  | Highest-order, worst     |

Variables that appear linearly in the equations (state derivative = data value) have ratio
exactly 1.0. Parameters and high-order state derivatives, which appear in nonlinear products,
have ratios 0.5–2.4 — the Jacobian changes significantly between x* and x_sol.

## Hessian / Halley Correction

Since 2 Newton steps converge exactly but 1 Newton step is 47% off, a natural question:
does the Hessian (2nd-order information) help?

A **Halley step** uses the directional second derivative:
```
δx_halley = δx_newton - ½·J⁻¹·H(δx_newton, δx_newton)
```

where H(v,v) = vᵀ·(∂²F/∂x²)·v for each equation, computed cheaply via two nested
ForwardDiff derivative calls (no need to materialize the full Hessian tensor).

### Results (n=31)

| Method              | ‖δx - δx_HC‖ | Relative error |
|---------------------|---------------|----------------|
| 1 Newton (= S·δd)  | 5.87          | **46.7%**      |
| Halley (+ Hessian)  | 0.61          | **4.8%**       |
| 2 Newton steps      | 6.0e-16       | ~0             |

The Halley step cuts the error by **10×** — from 47% to 5%.

Per-variable Halley/HC ratios: most are 0.88-1.02 (much tighter than Newton's 0.5-2.4).
The remaining outlier is y_3 (Halley/HC = 0.59) — cubic+ terms matter at that order.

The Halley correction magnitude is 63% of the Newton step — confirming massive nonlinearity
at n=31. At n=201 this ratio would be ~0.

## Practical Uses of the Hessian (Non-Oracle Setting)

In practice we don't know x*. We only have x_sol from HC.jl. Three potential uses:

### 1. Nonlinearity Credibility Score

At x_sol, compute S and a typical perturbation δd ~ σ_max · e_max (largest eigenvector of
the GP posterior covariance Σ_d). Then:
- δx_linear = S · δd
- Halley correction = ½ · J⁻¹ · H(δx_linear, δx_linear)
- **Nonlinearity index** = ‖correction‖ / ‖δx_linear‖

This tells the user whether to trust the linear UQ confidence intervals:
- < 0.1: green — "linear UQ is reliable"
- 0.1–0.3: yellow — "moderate nonlinearity, UQ may be optimistic"
- > 0.3: red — "UQ confidence intervals are unreliable; increase datasize"

Cost: one Hessian-vector-vector product (2 ForwardDiff calls), very cheap.

### 2. Bias Detection

Even with unbiased GP (E[δd] = 0), nonlinearity introduces systematic bias:
```
E[δx] ≈ ½ · Σ_jk T_ijk · Σ_d[j,k]    (NOT zero!)
```
The curvature means symmetric data errors → asymmetric parameter errors. The Hessian + Σ_d
lets you estimate this bias. If comparable to σ_x, the point estimate is suspect.

### 3. Corrected Error Bars

Use Halley-corrected sensitivity for UQ confidence intervals instead of raw S·δd. Same
cost as above.

## ODE-Constrained Interpolation Ideas (Not Implemented)

### Level 5a: Iterative Derivative Correction (easiest, ~50 lines)

After solving the polynomial system with GP-derived data values:
1. GP → initial derivatives → solve for rough params p̂  (existing pipeline)
2. Use p̂ + ODE structure + accurate GP order-0 values → recompute order-1,2,3 derivatives
3. Re-substitute corrected derivatives → re-solve polynomial system
4. Iterate until convergence

**How step 2 works precisely:**

Keep order-0 from GP (accurate):
```
x_0 = GP_y1(t_eval),  y_0 = GP_y2(t_eval)
```

Recompute order-1 from ODE:
```
x_1_corrected = α̂·x_0 - β̂·x_0·y_0
y_1_corrected = δ̂·x_0·y_0 - γ̂·y_0
```

Recompute order-2 by differentiating ODE:
```
x_2_corrected = α̂·x_1 - β̂·(x_1·y_0 + x_0·y_1)
y_2_corrected = δ̂·(x_1·y_0 + x_0·y_1) - γ̂·y_1
```

This replaces the noisy GP estimates (δF up to 2.111) with ODE-derived values that are
constrained by physical structure but depend on the accuracy of p̂.

**Concern:** If p̂ is badly wrong (e.g., β̂ = 7.9 vs truth 1.0), ODE-predicted derivatives
could be WORSE than GP. A safer version blends:
```
d_corrected = w · d_ODE(p̂) + (1-w) · d_GP
```
with w chosen per-derivative-order based on GP posterior uncertainty σ_GP. Order-0: w≈0.
Order-2: w≈0.8 (GP very uncertain → trust ODE prediction more).

**Open question:** Does this converge when initial params are 7× off? Needs empirical testing.

### Level 5b: Physics-Informed GPs (medium, changes GP itself)

References: Raissi, Perdikaris & Karniadakis (2017-2018)

Add pseudo-observations to the GP that the ODE residual ≈ 0 at collocation points:
```
Real data:      y1(t_i) = data_i           (with noise σ_n)
ODE constraint: y1'(t_j) - f(y1,y2,p)|_j = 0  (with small noise ε)
```

Since derivatives of a GP are also GPs with analytically known covariance (we already
compute se_kernel_derivative for UQ), this augments the kernel matrix from n×n to
(n+m)×(n+m) where m = collocation points × ODE equations. The posterior GP automatically
satisfies the ODE approximately and its derivatives are much tighter.

Parameter problem: ODE residual involves unknown p. Options:
- **Profile:** Joint optimization of (GP hyperparams, ODE params) via marginal likelihood
- **Iterate:** Use current p̂ to build constrained GP, extract derivatives, re-estimate p
- **Structure only:** Don't use specific p values; just constrain y1' to be a polynomial
  in y1, y2 (SIAN already knows the polynomial structure)

### Level 5c: Latent Force Models (hardest, most principled)

References: Álvarez, Luengo & Lawrence (2009, 2013)

GP prior on unknown inputs/forces → derive implied covariance on observables through ODE
Green's function. Analytically tractable for linear ODEs; requires linearization for nonlinear.

## Other Levers Discussed

### Sensitivity-Weighted Eval Point Selection (Lever 1, easy)

Current grid picks "best" t_eval by overall derivative error. Could instead minimize:
```
score(t) = ‖S(t) · δd(t)‖    not just    ‖δd(t)‖
```

A point where the SENSITIVE data variables happen to be well-interpolated would score better.
All infrastructure exists — just change the selection criterion.

### Per-Observable Interpolator Selection (Lever 2, medium)

Multi-interpolator framework already tries ~10 methods, but uses the same method for ALL
observables. Could mix-and-match: AAAD for y2 (if sensitivity says y2'' matters most),
GP for y1 (smooth, low-order sufficient). Sensitivity tells you which observable is worth
spending compute on.

### Adaptive GP Lengthscale (Lever 3, medium)

For the critical observable identified by sensitivity, do a targeted grid search over
lengthscales, scoring by predicted ‖S · σ_d‖² for that column of S. ~10 GP fits for one
observable — cheap.

## GP Hyperparameter Status (Clarification)

Zygote was already disabled and replaced with ForwardDiff+LBFGS (bounded Fminbox).
Optimization CONVERGES successfully for forced_lv_sinusoidal:
```
x(t): optimized=true  l=0.4374  σ²=0.8908  σₙ²=0.07413
y(t): optimized=true  l=0.3741  σ²=0.8763  σₙ²=0.07435
```

A silent fallback to adaptive defaults (lengthscale=std(xs)/8, signal_var=1.0,
noise from smoothness metric) exists but did NOT trigger in any tested case.
The `hyperparams_optimized::Bool` field tracks convergence but nothing downstream
currently gates on it.

## Bugs Fixed During This Session

### 1. `_obs_trfn_` leaking through diagnostic pipeline
- **Root cause:** `construct_equation_system_from_si_template` (line 181) only substituted
  `_trfn_*` variables, not `_obs_trfn_*` observable wrappers
- **Fix:** Added `evaluate_obs_trfn_template_variable` fallback in si_template_integration.jl
- **Belt-and-suspenders:** Added `_obs_trfn_` fallback + `t_eval` param to `_lookup_true_value`
  in diagnostics.jl (previously hardcoded t=0.0 for transcendental evaluation)
- **HTML fix:** `_write_html_data_sensitivity_section` used `jacobian_col_labels` (wrong set)
  instead of `data_sensitivity_unknown_labels` for the S matrix rows

### 2. Data points missing from SVG trajectory plots
- **Root cause:** `_evaluate_observable_on_solution` used `sol.prob.p[i]` (integer indexing)
  which throws BoundsError on modern MTK's `MTKParameters` objects
- **Fix:** Changed to symbolic parameter lookup via `sol.prob.ps[p]`
- **Affected:** All transformed PEPs (any model with `_trfn_` states)

### 3. Stale memory note about Zygote/GP defaults
- Updated memory: Zygote disabled, ForwardDiff+LBFGS works, optimization converges.
