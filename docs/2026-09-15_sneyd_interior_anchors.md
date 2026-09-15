# Sneyd: moving the shooting anchors away from t = 0

This study follows the [fourth-root comparison](2026-09-15_sneyd_fourth_root.md).
It concerns the six-state model with nine independent rates and the linear
observation z = 0.9 A + 0.1 O obtained by fourth-rooting the same clean data.
Excluding t = 0 does not fix the current parameter-homotopy failure: every
tested anchor rejects all seven starting roots before any tracking step. The
[research harness](../repro/sneyd_interior_2026_09_15/README.md) does not modify
production source or dependencies.

## Controlled change

Retain all 201 samples on 0 ≤ t ≤ 0.98, including the t = 0 measurement.
Compute the usual 20 warped shooting indices and remove only index 1. The
remaining 19 anchors start at t = 0.0098. All six initial conditions remain
unknown and are still reported at t = 0; excluding a shooting point does not
fix an initial condition or discard its observation.

The captured HC family and generic complex parameter point match the prior
rooted trial exactly: 72 quadratic equations in 72 unknowns, 292 terms, and
11 observation-derivative parameters. This check includes every polynomial
coefficient and exponent, variable order, and generic data value. The
unchanged representative fixing sets φ₁ = φ₂ = φ₃ = φ₄ = 1. The standard
interpolator list, starting with AGPRobust, and the normal gamma retries and
fresh-solve fallback remain in use.

The previous run retained only the number of generic roots, so this comparison
computed its pool once again. The new harness saves the actual unscaled
roots and verifies a family/environment fingerprint on reuse. Every HC call
also saves individual return codes and path vectors, avoiding the previous
ambiguity in the log's “accounted” count. A retained numerical pool is not a
certificate that all roots were found.

## What the solver actually did

The generic solve completed in 2,173.52 s (36.23 min), returning seven finite
nonsingular complex roots. All 5,491 path records are retained: 5,445 end at
infinity, seven succeed, and 39 fail (20 `polyhedral_failed`, seven
`terminated_accuracy_limit`, six
`terminated_invalid_startvalue_singular_jacobian`, and six
`terminated_max_extended_steps`). The seven returned roots are reusable
numerical starts, not a completeness certificate.

All 19 nonzero anchors pass the existing pre-HC validation. At the first one,
t = 0.0098, each of the five gamma attempts rejects all seven starts with
`terminated_invalid_startvalue_singular_jacobian`. Every path stops at homotopy
coordinate τ = 1, with zero accepted and zero rejected steps. Here τ is the
continuation coordinate, distinct from ODE time t; τ = 1 is the generic start
and τ = 0 is the requested data target. Starting residuals are approximately
3.6 × 10⁻¹⁵ to 2.0 × 10⁻¹⁴, so these records do not describe a failure to land
at an endpoint or paths going to infinity.

The unchanged fallback starts another fresh polyhedral solve. It was stopped
explicitly at 2,444.42 s of estimation, after the failure had been captured,
while the separate cached-root comparison continued. This is **a manual stop,
not a 90-minute timeout or completed fallback**. `external_stop.json` and
`outcome.json` record the reason; the untouched worker/supervisor checkpoints
still say `estimating`, and the process exits from SIGTERM. No raw candidate or
polished trajectory was returned. Later interpolators were not reached.

The separate replay uses the same seven roots, the full run's fixed column
scales, and the same five-gamma stream for every target. Its six targets are
t = 0, 0.0098, 0.196, 0.4949, 0.8281, and 0.98. All **210 path attempts** have
the same initialization rejection, τ = 1, and zero tracking steps. No fresh
polyhedral fallback is used by this diagnostic. The replay completes in
79.96 s including environment loading; after the first call compiles, each
additional five-gamma anchor comparison takes about 0.053 s.

## Scaling control: the immediate failure is at the generic start

The final control holds the HC data parameters fixed at p₀ throughout the
path. With the identical saved roots and gamma:

| Coordinates | Successful roots | Tracking steps | Outcome |
|---|---:|---:|---|
| Original, unscaled | 7 / 7 | 4–5 per path | All reach τ = 0 |
| Ordinary column scaling | 0 / 7 | 0 per path | All rejected at τ = 1 with the same singular-Jacobian initialization code |

This control finishes in 83.06 s including loading and compilation. It
isolates the variable-coordinate transformation as sufficient to trigger the
observed initialization failure. It is not evidence of true algebraic
singularity: the coordinate change is invertible, and HC succeeds on the
unscaled form at the very same p₀.

In notation, the handoff changes F(x; p) to G(u; p) = F(Du; p), with saved
starts u₀ = D⁻¹x₀ and JᵤG = JₓF · D. Here the diagonal scales range from 1 to
2.67937 × 10²⁰. Across the seven roots, nonzero unscaled component magnitudes
range from about 0.00327 to 344.68; some scaled components are as small as
2.89 × 10⁻²³. Exact rank is preserved, while numerical initialization changes
dramatically. This is the current numerical problem at the
[generic-root handoff](../src/core/homotopy_continuation.jl).

Real-data solving with a different scaling policy remains untested. The
appropriate next investigation is this handoff using the retained cache;
the derivative-accuracy problem below remains a separate obstacle. No global
scaling default or shooting-point policy was changed by this study.

## Interpolated derivatives

An independent first-interpolator probe uses the same rescaled model, all
samples, and ordinary AGPRobust implementation. **All 19 derivative vectors
and the column-scale vector match the actual full worker exactly.** Its
column-scale maximum with all anchors reproduces the prior recorded value
exactly, 3.1647071096714147 ×
10²⁰. Removing t = 0 lowers that maximum to 2.6793746433935452 × 10²⁰; it does
not eliminate the large scale range. The default gamma RNG also depends on the
target list, so the full-run comparison does not freeze its gamma stream.

For this independent-rate model, the generator is linear in its states:

```text
ẋ = Qx,                  z = cx,     c = (0.9, 0, 0, 0.1, 0, 0)
z⁽ᵏ⁾(t) = c Qᵏ exp(Qt) x₀.
```

Evaluating this expression with 90 decimal digits gives a diagnostic reference
for the derivatives. The generating rates and initial state are used only for
this comparison, never as estimator inputs or starts. The fourth power of its
zeroth derivative agrees with the retained samples at the compared times to
maximum absolute discrepancy 5.56 × 10⁻¹⁴. The following numbers are in physical
observation units, after undoing the observable scale of 0.5.

| t | Reference z′ | Interpolated z′ | Reference z⁽¹⁰⁾ | Interpolated z⁽¹⁰⁾ |
|---:|---:|---:|---:|---:|
| 0 | 4.92272 | 34.9037 | 2.65045 × 10³⁸ | 1.58235 × 10²⁰ |
| 0.0098 | 21.2689 | 21.2932 | −4.09750 × 10¹⁶ | 1.22414 × 10²⁰ |
| 0.1960 | −1.02154 | −1.02158 | −4.28240 × 10¹² | 9.86169 × 10¹⁷ |
| 0.4949 | −0.197710 | −0.197710 | −7.89210 × 10⁵ | 1.68525 × 10¹⁵ |
| 0.9800 | −0.0147901 | −0.0143339 | 6.50098 × 10⁴ | 1.56637 × 10¹⁸ |

The first derivative improves markedly after leaving t = 0. High-order errors
remain substantial in the interior, and the right endpoint has poor higher
derivatives too. For example, at t = 0.4949 the relative errors at orders 1–4
are about 1.77 × 10⁻⁶, 1.04 × 10⁻⁴, 0.00515, and 0.229, respectively; order 5
already has the wrong sign and relative error 14.4. This supports testing
interior anchors but does not establish that excluding t = 0 resolves HC's
failure or produces a useful fitted candidate.

## Validation

The observer/cache check on x² − d = 0 recovers both generic roots, reloads
them exactly, and reaches both roots at real target data through the ordinary
parameterized solver. A separate saved-family replay reconstructs all
coefficients exactly, reaches ±1 at both test anchors, and reports zero target
residual and actual `success` path codes. A t² interpolant checks the recorded
zeroth, first, and second derivatives. These are research harness checks;
production estimation code has not changed.

Completed evidence is retained with lossless compression and per-file hashes
under [`repro/sneyd_interior_2026_09_15/evidence`](../repro/sneyd_interior_2026_09_15/evidence):
`exclude_zero`, `anchor_replay`, `generic_scaling_control`, `derivatives`, and
`harness_validation`. The first directory includes the full polynomial family,
all generic roots, every HC path record, actual interpolated target vectors,
and the explicit manual-stop record. The original and optional Julia manifest
hashes are unchanged from the previous study. Production files are identical
to those at revision `de79d87527551600c027e924ab48d6ba50c0fcf2`; their most
recent change was `4dc6fedbf9bf5438dc28d3a4c116b5fa17d4bf26`.
