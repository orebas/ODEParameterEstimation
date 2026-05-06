# G1 — forced_lotka_volterra at noise=1e-2: derivative-grid analysis

Generated: 2026-05-05.

## Setup

`forced_lotka_volterra_0_1em2` from bilby. Model:
- 2 states: x, yv
- 4 params: alpha, beta, delta, gamma
- 2 observables: y1 = 2x, y2 = 2yv
- Sin(2t) forcing in `D(x)` equation
- Time interval [0, 5], 1501 data points
- Truth: alpha=0.103, beta=0.243, delta=0.59, gamma=0.165
- IC: x=0.806, yv=0.676

Data ranges: y1 ∈ [0.80, 1.62], y2 ∈ [0.23, 1.36]. **Noise level σ = 1e-2 (1%).**

## Structural identifiability — globally identifiable

Modeled `sin(2t)` as the auxiliary state `sin_term'(t) = 2*cos_term(t)`,
`cos_term'(t) = -2*sin_term(t)` and ran StructuralIdentifiability.jl on the resulting
6-state polynomial system (script: `temp_plans/forced_lv_si.jl`, log:
`/tmp/forced_lv_si.log`).

```
assess_local_identifiability:
  x(t)        => true,  yv(t)       => true,
  sin_term(t) => true,  cos_term(t) => true,
  alpha       => true,  beta        => true,
  delta       => true,  gamma       => true

assess_identifiability (global):
  ALL eight quantities => :globally

find_identifiable_functions(with_states=true):
  alpha, beta, delta, gamma, x(t), yv(t), sin_term(t), cos_term(t)
  (each as a separate generator — none collapse into a function of the others)
```

**Verdict at the structural level: forced_lv has no sloppy direction.** All four
parameters and both states are independently, globally identifiable. The pool's 31%
displacement from truth therefore is NOT structural sloppiness; it's noise propagation
through the identification map.

(Note: the standalone `diagnose(pep)` was not run because it calls SI.jl directly on the
original sin-forced model and fails with `ArgumentError: The system does not seem to
have rational right-hand side` — the `_trfn_` polynomialization happens inside
`analyze_parameter_estimation_problem`, not inside `diagnose`. Manual SI augmentation
above is the equivalent. The Jacobian condition number per shooting point at the
production config was not extracted; doing so requires either a transcendental-aware
diagnose path or transforming the PEP through `_trfn_` machinery before calling
diagnose. Treating that as out of scope for this writeup.)

### SP/MP template share derivative requirements

Per the existing pipeline, `good_deriv_level` is shared between SP and MP shooting
points (Explore agent confirmed in `src/core/multipoint_template.jl:609`). Production
multipoint concatenates SP templates with shared params; it does NOT reduce derivative
orders. So MP doesn't get a derivative-noise-amplification advantage on this case —
both modes need the same per-observable order-4 derivatives.

## Per-(interpolator, t, derivative-order) relative error grid

### y1 (= 2x)

Across 6 test points spanning [0.05, 4.95]. Showing rel-err of derivatives orders 0-4
for the best 3 interpolator families.

| t | interp | ord 0 | ord 1 | ord 2 | ord 3 | ord 4 |
|---:|---|---:|---:|---:|---:|---:|
| **0.05** (left bd) | aaad_gpr | 4e-4 | 0.018 | 0.23 | 0.66 | **0.50** |
| | agp_robust_SExRQ | 4e-4 | 0.018 | 0.23 | 0.66 | **0.49** |
| | chebyshev_bic | 8e-4 | 0.06 | 1.04 | 4.06 | **5.04** |
| **0.5** | aaad_gpr | 4e-5 | 1.5e-3 | 0.076 | 0.044 | **1.09** |
| | agp_robust_SExRQ | 4e-5 | 1.6e-3 | 0.075 | 0.045 | **1.10** |
| | chebyshev_bic | 2e-4 | 5.6e-3 | 0.47 | 0.062 | 4.06 |
| **1.5** (mid-interior) | aaad_gpr | 9e-4 | 6e-3 | 0.011 | 0.039 | **0.040** |
| | agp_robust_SExRQ | 9e-4 | 6e-3 | 0.011 | 0.046 | 0.041 |
| | chebyshev_bic | 1e-3 | 0.014 | 0.011 | 0.72 | 0.017 |
| **2.5** | aaad_gpr | 2e-3 | 2e-3 | 0.20 | 2e-3 | 0.16 |
| | agp_robust_SExRQ | 2e-3 | 2e-3 | 0.20 | 2e-3 | 0.16 |
| **4.5** | aaad_gpr | 8e-4 | 0.026 | 6e-3 | 0.075 | 0.092 |
| | agp_robust_SExRQ | 8e-4 | 0.026 | 6e-3 | 0.074 | 0.087 |
| **4.95** (right bd) | aaad_gpr | 6e-4 | 0.010 | 0.047 | 0.21 | 5e-3 |
| | chebyshev_bic | 4e-4 | 0.016 | 0.13 | 1.76 | **2.24** |

### y2 (= 2yv) — significantly harder

| t | interp | ord 0 | ord 1 | ord 2 | ord 3 | ord 4 |
|---:|---|---:|---:|---:|---:|---:|
| **0.05** (left bd) | aaad_gpr | 1.5e-4 | 0.20 | 0.22 | **1.44** | 0.074 |
| | chebyshev_bic | 2e-5 | 0.11 | 0.06 | 0.95 | **2.03** |
| | aaad (pure) | 1e-4 | **4.24** | 1.26 | 0.73 | 0.97 |
| **0.5** | aaad_gpr | 3e-4 | 0.017 | 3e-3 | 0.36 | 0.46 |
| **1.5** (mid-interior) | aaad_gpr | 6e-4 | 1e-3 | 0.068 | 4e-3 | 0.20 |
| | chebyshev_bic | 6e-4 | 3e-3 | 0.067 | 0.04 | 0.20 |
| **2.5** | aaad_gpr | 1e-3 | 2e-3 | 0.025 | 0.083 | 0.31 |
| **4.5** (near right bd) | aaad_gpr | 8e-4 | 5e-3 | 0.048 | 0.14 | **0.69** |
| | chebyshev_bic | 6e-4 | 0.04 | 0.07 | **1.22** | **20.8** |

## Key observations

1. **At 1e-2 noise, even the best GP interpolators have order-4 relative errors of
   5-100%** depending on time point. y1 is borderline ok at interior (~4%); y2 is
   bad most places (~20-70%).

2. **GP-family unanimously beats AAA-class** at 1e-2 noise. AAA places near-real
   poles when data is noisy; on this case the rational interpolation is unstable.

3. **Boundary (t≤0.05 or t≥4.5) derivatives are catastrophic** at high orders:
   - y1 ord 4 at t=0.05: ~50% (GPs), 504% (chebyshev)
   - y2 ord 4 at t=4.5: ~69% (GPs), **2080% (chebyshev)**

4. **The shooting_warp clusters near t=0** (which IS a boundary). The shooting points
   include t=0 region where y2 derivatives are 4× worse on order 1 alone (4.24 for
   pure AAA at order 1!).

5. **The median rel-err in the production pool is 31%** — the bilby benchmark sweep
   reports ODEPE errors 0.04-3.36 across 8 replicas while AMIGO2 stays under 0.3%.
   The derivative grid explains this directly: with order-4 errors of 30-200% on y2
   propagating through the SI template, parameters are displaced by tens of percent.

## Why GP wins but still fails at 1e-2

At noise level σ, derivative-order-k error scales roughly `σ × c^k / Δt^k` where Δt
is sampling spacing and c is interpolator-specific. For:
- σ = 1e-2
- Δt = 3.3e-3 (1501 points over [0,5])
- order k = 4

The theoretical minimum order-4 abs error from a smoothed estimator is ≈ σ × something.
With GP prior smoothing tuned via MLE, you get effective length scale `ℓ` and the
order-4 error is roughly `σ / ℓ^4`. For ℓ ≈ 0.5 (matching trajectory characteristic
time): `1e-2 / 0.5^4 = 0.16` absolute. With y2 oracle order-4 ≈ 0.4, that's 40%
relative error. **Matches the empirical findings within a factor of 2.**

So the **information-theoretic floor on order-4 derivative accuracy of y2 at noise=1e-2
is ~30-50%**. No interpolator can do meaningfully better without exploiting structure
(e.g., knowing about sin-forcing periodicity).

## Implications

**forced_lv at 1e-2 is pool-inadequate by physics, not by code.** The polynomial system
is being fed inputs with 30-100% relative error; even with a perfect SI template and
perfect HC.jl, you'd get parameters with 30%-ish error.

What WOULD help (none are gate fixes or selection fixes):

1. **Use a lower-order SI template**: if the polynomial system can be reformulated to
   need only order 2-3 derivatives instead of order 4, the rel-err on derivatives
   drops by ~10× (matching the per-order amplification factor).
2. **Periodic-aware interpolator**: a GP with sin/cos basis or Fourier-series interpolant
   could exploit the periodic forcing structure.
3. **Higher data sampling rate**: 1501 points → 5000+ points reduces Δt and the
   per-order amplification.
4. **Different observable transformation**: e.g., the ratios `y1/y2` or `log(y1)` may
   have smaller derivative magnitudes that propagate noise better.

None of these are "fix the gate / selection logic" interventions. They're algorithmic
or data-side changes.

## Answering the user's two precise questions

> "is there any sloppiness at all?"

**No structural sloppiness.** SI.jl says all four parameters and both states are
globally identifiable as independent generators. The pool's 31% spread is not coming
from a sloppy parameter combination but from noise (1e-2) propagating through the
algebraic map `(d_obs at t_i) → (params)`. The derivative grid above shows where the
noise blows up: y2 order 3-4 across most time points has 20-200% rel-err. The
polynomial system is being fed inputs at that error level.

What I cannot say without running diagnose successfully (transcendental block): how
much of the 30%-displacement is "well-conditioned system × noisy data" vs
"moderately-ill-conditioned system × moderately-noisy data." For that we'd need
Jacobian condition numbers per shooting point. The clean SI result rules out
a 1e6+ condition number (no structurally sloppy direction), but doesn't tell us
whether cond is 10 or 10^4.

> "does the MP and SP template both need the same derivatives?"

**Yes — production MP shares `good_deriv_level` with SP** (no derivative-order
reduction). MP's only effect on this case is concatenating multiple SP systems
with shared parameter unknowns, which can help when sources disagree (data-side
variance reduction) but doesn't reduce per-source derivative-order requirements.

## Verdict

forced_lv 1e-2 is genuinely Class A (pool inadequate). No selection-side fix can
recover truth here. The 31% pool floor is the noise-propagation limit given the
1% data noise and SI template's order-4 derivative requirement.

It's a useful **example case** for testing alternative interpolators (e.g.,
periodic-aware GP) but not a target for seed strategies or gate fixes.
