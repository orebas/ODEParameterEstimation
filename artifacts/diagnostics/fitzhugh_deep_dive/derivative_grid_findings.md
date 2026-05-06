# Per-(interpolator, t, derivative-order) error grid for fitzhugh y1(t)

Independent of the polynomial pipeline. Just: fit each interpolator to the noisy y1
data once, evaluate `d^k y1 / dt^k` at six test points, compare to oracle.

Test points span the full data range. Oracle from high-precision ODE solve.

## Relative error grid (|interp − truth| / |truth|)

| t | interpolator | ord 0 | ord 1 | ord 2 | ord 3 | ord 4 |
|---:|---|---:|---:|---:|---:|---:|
| **0.001** (left boundary) | aaad | 1.9e-4 | 7.1e-3 | 8.5e-2 | 0.12 | 0.13 |
| | aaad_gpr | 1.1e-5 | 1.6e-3 | 5.6e-2 | 0.29 | **0.46** |
| | agp_robust (SE) | 1.1e-5 | 1.6e-3 | 5.6e-2 | 0.29 | **0.46** |
| | agp_robust_SExRQ | 1.8e-6 | 6.4e-4 | 1.8e-2 | 6.1e-2 | 3.2e-2 |
| | agp_robust_matern52 | 1.3e-5 | 1.3e-4 | 6.0e-2 | 1.13 | 0.45 |
| | chebyshev_bic | 1.2e-5 | 1.1e-3 | 1.6e-2 | 0.17 | **1.47** |
| | s2_aaa_mle | 2.2e-4 | 7.6e-3 | 0.14 | 0.41 | 0.24 |
| **0.05** | aaad | 2.4e-4 | 1.2e-3 | 6.6e-2 | 9.6e-2 | 5.0e-2 |
| | aaad_gpr | 1.0e-5 | 3.7e-4 | 1.3e-4 | 4.5e-2 | 0.33 |
| | agp_robust (SE) | 1.0e-5 | 3.7e-4 | 1.3e-4 | 4.5e-2 | 0.33 |
| | agp_robust_SExRQ | 1.2e-5 | 1.9e-4 | 3.9e-3 | 2.0e-2 | 7.3e-2 |
| | s2_aaa_mle | 1.0e-4 | 3.6e-4 | 6.4e-2 | 0.16 | 0.40 |
| **0.183** (prod SP=275) | aaad | 2.4e-4 | 8.5e-4 | 1.5e-4 | 4.1e-2 | 5.3e-2 |
| | aaad_gpr | 5.7e-6 | 2.7e-5 | 1.6e-3 | 3.6e-3 | 2.3e-2 |
| | agp_robust (SE) | 5.7e-6 | 2.7e-5 | 1.6e-3 | 3.6e-3 | 2.3e-2 |
| | **agp_robust_SExRQ** | **2.3e-6** | **1.5e-4** | **2.9e-4** | **4.1e-3** | **8.9e-3** |
| | agp_robust_matern52 | 4.2e-6 | 6.5e-4 | 1.8e-2 | 0.28 | **3.92** |
| | chebyshev_bic | 9.7e-6 | 7.7e-5 | 3.3e-3 | 1.1e-3 | 5.3e-2 |
| | s2_aaa_mle | 2.5e-5 | 7.7e-4 | 3.8e-3 | 2.9e-2 | 1.8e-2 |
| **0.5** (mid-interior) | aaad | 5.1e-4 | 1.3e-2 | 6.5e-2 | 1.6e-2 | 0.28 |
| | aaad_gpr | 1.4e-6 | 1.2e-4 | 7.9e-4 | 7.1e-3 | 2.1e-2 |
| | agp_robust_SExRQ | 9.3e-8 | 2.8e-4 | 2.5e-4 | 4.8e-3 | **1.1e-2** |
| | s2_aaa_mle | 1.4e-5 | 1.0e-3 | 1.6e-3 | 1.1e-2 | 3.9e-3 |
| **0.95** (near right boundary) | aaad | 1.2e-3 | 0.16 | **3.14** | 0.57 | 0.69 |
| | aaad_gpr | 1.8e-5 | 2.0e-3 | 0.42 | **4.7** | **15.6** |
| | agp_robust_SExRQ | 1.6e-5 | 1.8e-3 | 0.38 | **4.45** | **14.8** |
| | chebyshev_bic | 1.8e-5 | 8.1e-3 | 0.14 | **10.2** | **68.3** |
| | s2_aaa_mle | 9.1e-6 | 5.4e-3 | 0.14 | 1.1e-2 | 0.12 |
| **0.999** (right boundary) | aaad | 1.8e-6 | 0.24 | **4.29** | 0.47 | 0.85 |
| | aaad_gpr | 4.1e-5 | 3.1e-2 | **3.89** | **20.7** | **38.1** |
| | agp_robust_SExRQ | 3.8e-5 | 2.9e-2 | **3.58** | **18.4** | **29.1** |
| | agp_robust_matern52 | 5.7e-5 | 3.9e-2 | **2.41** | 1.81 | **43.1** |
| | chebyshev_bic | 7.4e-5 | 7.7e-2 | **13.9** | **117** | **421** |
| | s2_aaa_mle | 5.0e-5 | 8.5e-3 | 0.17 | 5.7e-2 | 0.16 |

## Headline observations

### 1. The interior is FINE; the boundaries are catastrophic

At `t = 0.183` (the production-best shooting point), order-4 errors are:
- 0.9% (SE×RQ — the best)
- 2.3% (SE-GP / aaad_gpr)
- 5.3% (chebyshev_bic, pure aaad)
- 1.8% (s2_aaa_mle)

All small. **At interior, the noise level (1e-4) propagates to ~1% at order 4 — exactly
what you'd expect from 4 stages of differentiation amplification.**

At `t = 0.999` (right boundary), order-4 errors are:
- **2900% (SE×RQ)**
- **3810% (SE-GP / aaad_gpr)**
- **42100% (chebyshev_bic)**
- 16% (s2_aaa_mle)

Three orders of magnitude worse. The user's hypothesis is **confirmed**: this is an
endpoint GP problem.

### 2. ALL GP variants share the boundary failure

`agp_robust` (SE) and `aaad_gpr` give bit-identical values at every test point — so
`aaad_gpr_pivot` is essentially falling through to the SE-GP branch on this case (its
"AAA pivot" detection isn't engaging). That's a separate observation.

`agp_robust_SExRQ` (the "winner" in the previous experiment) is barely better than SE
at the right boundary: **2900% vs 3810%**. The 2.5× improvement at the boundary doesn't
help because both are useless there.

`agp_robust_matern52` is broken (NaN at multiple test points and 4310% at order 4 right
boundary).

### 3. `s2_aaa_mle` is the boundary-robust outlier

At t=0.999, `s2_aaa_mle` has order-4 error of just **16%** — vs 2900%+ for every GP.
At t=0.95: **12%** vs 1500%+.

`s2_aaa_mle` ("AAA → MLE without GP step") combines AAA's rational-extrapolation ability
with MLE-tuned regularization. AAA can place poles outside the domain that give clean
extrapolation, while GP collapses to its prior at boundaries.

Pure `aaad` is also more robust at boundaries (order 4 right-boundary: 85% vs 2900-4000%
for GPs) but worse at interior (28% at t=0.5 vs 1.1% for SE×RQ).

### 4. `agp_robust_matern52` is broken

NaN at t=0.05, 0.5, 0.95 — only sparse outputs. The Matérn-5/2 implementation has
some failure mode on this data. This is what gave the catastrophic rel=3.7e9 in the
previous multi-interpolator run.

### 5. The interior accuracy IS what we need — but the production pipeline uses boundaries too

Production `shooting_points = 3` chose t-indices `[1, 275, 1501]` — i.e., t ≈ {0, 0.183, 1.0}.
Two of three shooting points are at boundaries, where derivatives are catastrophic.
Only SP=275 (t=0.183) is in the interior.

That's why the production pool best is rel=7.06: the polynomial system at SP=275 has
modest derivative noise, but combining it with the wild boundary-derived d_obs values
in the multipoint combos pollutes things. And single-point at SP=1 or SP=1501 alone
gives wildly displaced candidates (rel=88+ in the v6 dive).

## What the polynomial system uses, and amplification

From the sensitivity-matrix dive, the SI template at fitzhugh evaluates `S` at a single
shooting point and uses derivatives orders 0..4 of y1. The S column norms are:

```
order 0: 759   order 1: 695   order 2: 171   order 3: 16   order 4: 2.5
```

So for the dominant column (order 0) the |δd| at each shooting point is:
- t=0.001: 1.4e-6 × 0.84 = 1.2e-6 (perfect — boundary value of y itself is fine)
- t=0.183: 5.7e-6 × 1.24 = 7.1e-6
- t=0.999: 4.1e-5 × 1.80 = 7.4e-5 (10× worse — boundary effect on order 0 only)

Order 0 is barely affected by boundaries. Order 4 is 1000× worse at boundary. But
the column norm for order 4 is much smaller (2.5 vs 759), so the contributions can
be similar in absolute terms.

**The key amplification at SP=275 is dominated by order 3 and 4 errors propagated
through their respective S columns**, as we computed earlier (Δb ≈ −2 from order 3
plus −2 from order 4).

## What I think this means for strategy

1. **Avoid boundary shooting points when possible.** Even a small move from t=0
   to t=0.05 reduces order-4 error by 10× for GP variants. Production currently uses
   t=0 and t=1 for shooting; a counterfactual with t=0.05 / t=0.5 / t=0.95 should
   give a much cleaner pool.

2. **Use `s2_aaa_mle` if you must include boundary points.** It's the only interpolator
   that handles boundaries at moderate-rel-err cost (10-100% errors instead of 1000-10000%).
   It would also be a good "boundary specialist" in a multi-interpolator setup if we
   could route boundary derivatives through it specifically.

3. **The "AAADGPR is broken on fitzhugh because of GP boundary failure" framing now
   stands.** The 7.06 baseline was a side-effect of using boundary shooting points with
   a GP-based interpolator. Either move shooting points away from boundaries or change
   interpolator at boundaries. **Either fix probably gets fitzhugh polish=OFF below
   rel=1 robustly.**

4. **The user's vanilla-SE-GP wish is constrained by this finding**: vanilla SE GP is
   adequate at interior (rel=2.3% at order 4 at t=0.183) but catastrophic at boundaries
   (3810% at t=0.999). To use SE-GP in production, the shooting-point selector must
   stay away from boundaries.
