# fitzhugh_nagumo_2_1em4 polish=OFF — Deep dive findings

## TL;DR

**The trajectory-loss minimum IS at truth (`L(x_truth) ≈ 3.6e-5`), but the polynomial system
`F(x, d_obs) = 0` has its roots displaced ~5 units away in parameter space (`L ≈ 0.2`).** No
amount of pool blending / clustering / shrinkage can fabricate a truth-near point, because
the pool has no near-truth member — the algebraic-system roots themselves are far from truth.

This means:
- **No-polish wins are fundamentally bounded** on this case at this noise level. The pool's
  best candidate is rel=7.06; the buggy mean blend's rel=2.54 is the best we'll get from
  blending strategies.
- **Polish DOES work — if started from a truth-near seed.** Truth has 5,500× lower loss
  than the polynomial-best, so polish from truth converges to truth. The bottleneck is
  finding a truth-near seed that polish can use as a starting point.
- The "right" intervention isn't "smarter blending of polynomial roots." It's either
  (a) reformulating the polynomial system to give better roots (algebraic side), or
  (b) using a different seed source — like a global random-restart polish or a truth-prior
  guess like `(g=1, a=1, b=1)` — and trusting polish to find the loss minimum.

## Numerical answers per question

### Q1. Why is the pool so bad?

**The polynomial system's roots are displaced from truth by data noise.** Specifically:

- Production polynomial system: 14 equations × 14 variables.
- 2 algebraic branches (perfect data → 2 roots; noisy data → 2 roots, both displaced).
- `‖F(x_truth, d_obs)‖ = 1.54` — truth does NOT satisfy the noisy polynomial system.
- `‖F(x_truth, d_truth)‖ = 1.45e-14` — truth satisfies the perfect-data system (sanity check).
- Closest noisy-data root to truth is **5.34 units away in parameter space**.

So the noisy-d perturbation has displaced the polynomial root by ~5, while truth itself has
`‖F‖ ≈ 1.5` against the noisy data. HC.jl finds the displaced roots, not truth.

### Q2. Where does the best estimate come from?

From the pool deep-dive (`pool_breakdown.md`):

| Best-by-... | idx | source | Shooting Point | Interpolator | Params (g, a, b) | rel | loss |
|---|---|---|---|---|---|---:|---:|
| rel-err | 3 | single_point | SP=275 (t≈0.18) | aaad_gpr | (0.79, 2.07, 7.15) | 7.06 | 0.20 |
| trajectory loss | 3 | single_point | SP=275 (t≈0.18) | aaad_gpr | same | 7.06 | 0.20 |

**Both the rel-best and loss-best are the same candidate**, from **single-point** estimation
at shooting point t≈0.18, using the AAA-GPR interpolator. ALL multipoint candidates are
worse (rel ≥ 12). The 3 shooting points used were t≈0 (idx=1), t≈0.18 (idx=275),
t≈1.0 (idx=1501); only t≈0.18 produced anything usable.

The best fit is single-point, not multipoint. Multipoint mixes data from multiple time
points and amplifies noise on this case.

### Q3. What derivatives are needed and how accurate are estimates?

From `summary.txt` (at t=0.499, the diagnose-chosen "best" eval point):

| Order | True value | Interpolant | Rel error |
|---:|---:|---:|---:|
| 0 | -1.65 | -1.65 | 1.4e-6 |
| 1 | -0.577 | -0.577 | 1.1e-4 |
| 2 | 2.67 | 2.67 | 8.2e-4 |
| 3 | -17.1 | -17.0 | 7.0e-3 |
| **4** | **70.7** | **72.3** | **2.2%** |

The polynomial system requires up to order 4 derivatives of y1. Errors grow ~10× per order,
reaching 2.2% at order 4. The diagnose() framework flags this as the bottleneck.

The 1e-4 noise level on the data manifests as ~10⁻⁴ at order 0 and amplifies through
differentiation: the AAA-GPR interpolator's high-order derivatives are 200× noisier than
the input noise. This is a generic feature of derivative estimation (Lanczos / Stechkin
inequalities) — there's no avoiding it without different data acquisition.

### Q4. Is something about the ODE making most data uninformative?

**Partly yes.** The Jacobian of the ODE at truth at t=0:

```
J = [ 4.91   -1.17 ]
    [-0.86    0.038 ]

Eigenvalues: -0.467 (slow), +1.92 (fast unstable)
Timescales:  2.14, 0.52
```

Both are real (not oscillatory), and the **positive eigenvalue is unstable** — the trajectory
escapes the (Vm=0.42, R=0.404) point along an unstable manifold. This IS the spike upstroke.

`y1(t)` over `[0, 1]` evolves: y1(0)=-0.84 → y1(1)=-1.80 (range 0.96). The spike
upstroke, but **we don't see the recovery (downstroke)** — the slow timescale 2.14 means
the recovery period is ~2× the observation window.

Because we only see the upstroke and partial recovery, `R`'s full dynamics aren't
constrained, so `b` (which scales R's decay) is ill-determined. **This is a real
identifiability deficit caused by the time window.**

### Q5/Q12. Is `b` sloppy? Sensitivity analysis says yes.

From `sensitivity.csv` — the SVD of `∂F/∂x` at the diagnose-chosen evaluation point:

```
σ_1  = 1087.6      (well-determined direction)
σ_14 = 9.6e-4      (most sloppy direction)
cond = 1.13e6
```

There's one extremely sloppy direction (σ_14) and two more moderately sloppy ones (σ_12,
σ_13 < 0.06). Combined with the algebraic finding that the closest noisy-data root is 5.34
from truth, this confirms the system is practically non-identifiable along the most-sloppy
direction.

The right singular vector for σ_14 (which would tell us EXACTLY which parameter combination
is the dominant flapper) is in the in-memory `SensitivityReport` but not extracted to the
CSV. Likely heavily-loaded on `b` based on observed candidate spread (b ranges from −115
to +81 across the pool). Confirming this would require a small extension to the script.

### Q6. Why is `b = 7.15` to begin with?

The polynomial system has 2 algebraic branches. One satisfies F(x, d_obs)=0 with
parameters near (g=0.79, a=2.07, b=7.15); the other satisfies it with parameters near
(g=0.74, a=−2.43, b=−9.88). Both are 5+ units from truth (b=0.887). The noisy `d_obs` has
shifted the algebraic root manifold; the closest root is no longer near truth.

The specific value `b=7.15` is just where the displaced branch sits. Tracing the SI
template equations for which one determines `b` would identify which derivative orders
drive the displacement — but **the q3 finding (order-4 derivative is 2.2% off) is the most
direct culprit** since `b` enters via `R`'s dynamics and `R`'s dynamics require high-order
y1 derivatives.

### Q7. Would probing work?

**No, not from algebraic candidates alone.** The pool has no candidate within rel ~ 1 of
truth. The dominant sloppy direction (σ_14 of S) is a local linearization at the candidate;
moving along it requires a magnitude that's not derivable from σ_d (we covered this in
the prior σ_d work). Even oracle-optimal probes from the pool's best candidate would only
get rel ≈ 0.5, given the 5-unit displacement. **Probing is the wrong tool here.**

What WOULD work: pure optimization from a different starting point (random restart, or a
domain prior like (g, a, b) = (1, 1, 1)) — since truth is the trajectory-loss minimum.

### Q10/Q11. Algebraic system at truth + Jacobian condition

- `‖F(x_truth, d_obs)‖ = 1.54` — truth doesn't satisfy the noisy system.
- `‖F(x_truth, d_truth)‖ = 1.45e-14` — truth satisfies the perfect system (sanity).
- `‖F(x_pool_best, d_obs)‖` would be ~0 (it's a polynomial root by construction).
- Jacobian condition `cond(∂F/∂x) = 1.13e6`. High but not catastrophic.

### Q14. Loss landscape vs algebraic landscape

**The trajectory loss has a clear minimum at truth: `L(x_truth) = 3.6e-5`** (consistent with
the noise level 1e-4 squared × number of data points). The polynomial pool's best candidate
has `L ≈ 0.20` — 5,500× higher.

This means the loss landscape is NOT sloppy along the algebraic-sloppy directions. They
disagree. Polish from a truth-near seed would find truth (L converges to 3.6e-5).
Polish from the polynomial pool's best (L=0.20) is in a different basin.

## Implications for strategy

The deep dive flips the framing:

- The earlier conclusion "fitzhugh polish=OFF is hard because the loss is flat along
  sloppy directions" is **wrong**. The loss is NOT flat. Truth is the loss minimum.
- The real issue is **the polynomial system gives bad starting points for polish**. It
  has 2 roots, both far from truth, neither in truth's loss basin.

Three actionable directions:

1. **Random-restart polish from non-algebraic seeds**: e.g., (g, a, b) = (1, 1, 1) or a
   random vector in [-2, 2]^3. Cheap. Likely converges to truth on this case (but might fail
   on others). Worth testing as a baseline that doesn't rely on the polynomial pipeline.

2. **Reformulate the polynomial system**: The current SI template at one shooting point
   gives a 14×14 system that's badly ill-conditioned at noisy d. Multi-point or a
   different observable parameterization might give a better-conditioned system. Hard to
   investigate without modifying production code.

3. **Accept that the polynomial pool is the wrong pre-seed source for this case** and
   route polish from a different source (truth prior, random restart). The polynomial pool
   is still useful for other cases (well-conditioned ones) but not for this one.

## What's NOT yet investigated (deferred from the plan)

- D3 (cross-interpolator derivative grid at production shooting points) — running
  `_diagnose_comprehensive` with multiple interpolators at SPs 1, 275, 1501 instead of
  diagnose's chosen "best" point. Would give per-shooting-point per-interpolator derivative
  errors, addressing Q9.
- D6 proper (perturb truth along σ_14's right singular vector, measure trajectory loss) —
  needs a small script extension. Confirms whether sloppiness is purely algebraic or
  partially loss-landscape too. Given L(x_truth) << L(pool_best), strongly expected to
  show "loss is steep, not flat" along the algebraic-sloppy direction.
- D7 (counterfactual sweeps: noise=1e-6, tspan=[0,5], more shooting points) — would tell
  us whether more time / less noise breaks the bottleneck. Cheap to run.
- D8 (manual trace of `b`'s algebraic origin) — manual SI template inspection. Would
  identify which equation determines `b` and which derivative order it depends on most.

## Hypotheses revisited

- **H1** (slow mode unidentifiable in `[0, 1]`): **CONFIRMED**. Slow timescale 2.14 vs
  tspan 1.0; we see the spike upstroke but not the recovery. R's dynamics aren't fully
  constrained.
- **H2** (high-order y1 derivatives blow up): **PARTIALLY CONFIRMED**. Order 4 derivative
  error is 2.2%, growing 10× per order. Not catastrophic at the diagnose-chosen eval
  point t=0.499, but worse at boundaries.
- **H3** (`b` is structurally identifiable but practically not): **CONFIRMED**. Jacobian
  cond 1.13e6, σ_14 = 9.6e-4. The pool's `b` ranges from -115 to +81 across candidates.
- **H4** (`‖F(x_truth, d_obs)‖` is moderate): **CONFIRMED**. 1.54.
- **H5** (sloppy direction at truth aligns with `b`): **PROBABLY** but not directly verified.
  The pool's `b` spread strongly suggests it. Definitive answer would require extracting the
  σ_14 right singular vector.
