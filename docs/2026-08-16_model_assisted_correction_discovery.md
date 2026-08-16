# Model-assisted one-step correction: discovery results

Date: 2026-08-16

Status: research prototype and one-draw mechanism screen. The default estimator
is unchanged. Corrected uncertainty is explicitly unavailable pending a derived
pilot-through-correction influence map and repeated-noise validation.

The repeated-noise validation is now complete in
[`2026-08-16_model_assisted_repeated_noise.md`](2026-08-16_model_assisted_repeated_noise.md).
It supersedes this document for policy conclusions: the FHN rescue below did
not generalize across selected routes, while screened slow--fast and Van der
Pol corrections advanced to repeated polish.

## Question

For the exact algebraic estimator selected by production, can the model itself
estimate and remove the retained GP smoother's derivative bias cheaply enough
to do one of three useful things?

1. repair an inaccurate unpolished estimate;
2. reach polished-quality accuracy without trajectory optimization; or
3. provide a better seed for trajectory polish.

The implemented correction is

```text
b_hat(theta0) = W f_theta0 - L f_theta0
d_corrected    = W y - b_hat(theta0)
```

where `W` is the exact retained fixed GP smoother, `L f_theta0` is the
model-exact observable jet, and `theta0` is reconstructed from the selected
SP/MP algebraic root. The prototype returns both the literal IFT update
`x1 = x0 - S*b_hat` and a damped-Newton re-solve of the same polynomial branch
at `d_corrected`. It does not run LBFGS or any other trajectory optimizer.

## Protocol

- Models and truths come from the SHA-pinned paper-benchmark constructors, not
  the package's known-flaky registry examples.
- Every cell uses the full audited 750-point grid and a new additive-noise draw.
- Within a model, the same standardized draw is reused across noise levels.
- The estimator pool is explicitly `uq_only`: an exact retained
  `AGPInterpolatorUQ` is required to apply the same `W` to the pilot trajectory.
  These are therefore tests of the model-assisted mechanism, not reproductions
  of each paper cell's historical winning interpolator.
- Rank one is selected by the production analysis path. Its exact SP/MP points,
  template, root, and interpolants are consumed; no new best-SSE root is chosen.
- The table is one draw per cell. It can discover a mechanism or reject a
  catastrophic arm, but it cannot establish expected risk or coverage.

## Estimation results

Errors are worst-coordinate relative errors over parameters and initial states.
`raw corrected` is the same-branch local polynomial re-solve. `screen` is a
truth-free decision: retain the lower-SSE corrected candidate only if it lowers
the reconstructed pilot's observed-data trajectory SSE.

| Model | Noise | Selected route | Pilot error | Raw corrected error | Trajectory SSE change | Screen |
|---|---:|---|---:|---:|---:|---|
| Lotka--Volterra | `1e-6` | MP `[25,635]` | 0.0177% | 0.0185% | `1.47e-3 -> 8.13e-4` | accept |
| Lotka--Volterra | `1e-5` | MP `[25,635]` | 0.0991% | 0.103% | `1.92e-3 -> 1.60e-2` | reject |
| Lotka--Volterra | `1e-4` | MP `[25,635]` | 3.77% | 3.79% | `6.36 -> 23.9` | reject |
| Lotka--Volterra | `1e-2` | MP `[36,635]` | 41.9% | 54.1% | `344 -> 772` | reject |
| FitzHugh--Nagumo | `1e-6` | SP `[223]` | 5.63% | **0.0385%** | `1.50e-7 -> 7.24e-8` | accept |
| FitzHugh--Nagumo | `1e-5` | MP `[124,750]` | 35.9% | 33.7% | `3.58e-6 -> 1.67e-5` | reject |
| FitzHugh--Nagumo | `1e-4` | SP `[223]` | 33.6% | 132% | `5.11e-5 -> 9.78e-5` | reject |
| FitzHugh--Nagumo | `1e-2` | MP `[124,750]` | 2699% | unusable | corrected trajectory failed | reject |
| Slow--fast | `1e-6` | SP `[374]` | 0.0168% | **0.00861%** | `2.07e-8 -> 7.26e-9` | accept |
| Slow--fast | `1e-5` | SP `[374]` | 0.0619% | 0.0698% | `5.49e-7 -> 5.43e-7` | accept |
| Slow--fast | `1e-4` | SP `[374]` | 0.158% | 0.193% | `2.95e-5 -> 3.04e-5` | reject |
| Van der Pol | `1e-6` | SP `[374]` | 0.242% | **0.135%** | `6.88e-4 -> 2.15e-4` | accept |
| Van der Pol | `1e-5` | SP `[374]` | 0.442% | 1.58% | `2.29e-3 -> 2.92e-2` | reject |
| Van der Pol | `1e-4` | SP `[374]` | 5.35% | 11.1% | `0.326 -> 1.33` | reject |
| Van der Pol | `1e-2` | SP `[374]` | 45.5% | 65.6% | `47.5 -> 117` | reject |

The strongest result is FHN at `1e-6`: a selected unpolished estimate with
5.63% worst-coordinate error is repaired to 0.0385% by one model-assisted
correction. Slow--fast and Van der Pol also improve at `1e-6`. LV begins so
accurate that the truth change is negligible and slightly adverse even though
the observable trajectory SSE nearly halves.

The transition is sharp. At `1e-5`, LV and Van der Pol regress, while FHN's
truth error improves only modestly (`35.9% -> 33.7%`) at the cost of a much
worse trajectory fit. Slow--fast lowers trajectory SSE by 1.2%, so the screen
accepts it, but truth error slips from `0.0619%` to `0.0698%`. Every tested
`1e-4`/`1e-2` raw correction regresses or fails.

Across all 15 cells, the trajectory-SSE screen accepts the four `1e-6` cells
and slow--fast at `1e-5`, rejecting the other ten. It is useful as a catastrophe
screen, but not as a parameter-risk certificate: accepted LV at `1e-6` and
slow--fast at `1e-5` are counterexamples. We deliberately did not tune a
minimum-SSE-improvement threshold after seeing this panel.

## Interaction with polishing

Two `1e-6` fixed-seed comparisons used the same production-default polish
method and one shared polish context.

| Model | Pilot | Corrected | Polish from pilot | Polish from corrected | Call order; pilot/corrected time |
|---|---:|---:|---:|---:|---:|
| Lotka--Volterra | 0.0177% | 0.0185% | `1.76e-5%` | `1.76e-5%` | pilot -> corrected; `25.0 s / 0.059 s` |
| FitzHugh--Nagumo | 5.63% | **0.0385%** | 0.0466% | 0.0466% | corrected -> pilot; `0.029 s / 26.5 s` |

Both seeds reach the same polished basin. The roughly 25-second cost follows
the first-called arm (pilot for LV, corrected for FHN), while the second call
is below 0.06 seconds. It is therefore compilation/order cost, not evidence
that either seed is intrinsically slower. The current evidence supports
"standalone low-noise repair" on FHN, but gives no accuracy evidence for a
better polishing seed: both seeds polish to effectively identical answers.
Steady-state timing needs explicit warm-up and repeated alternation, and this
fixed-seed experiment does not measure the larger cost of polishing an entire
production candidate pool.

## Software and inference contract

- The feature is research-only and has no `EstimationOptions` switch or default
  path.
- Corrected candidates have explicit estimator kinds
  `:model_assisted_linear` and `:model_assisted_local_resolve`, retain their
  selected parent candidate and exact time-point provenance, and are scored by
  a fresh ODE trajectory.
- The report retains observed, pilot-smoothed, model-exact, bias, and corrected
  values for every algebraic data coordinate, plus all roots and residuals.
- The screened arm never uses truth. It is absent when corrected trajectory SSE
  does not improve.
- Estimator-aware UQ returns typed `UQUnavailable(:unsupported_estimator)` for
  both corrected kinds. Reusing the parent SP/MP covariance is forbidden.

## Interpretation and next gates

The results match the bias theory. At very low noise, deterministic GP-jet bias
can dominate sampling error and a sufficiently close model pilot can estimate
that bias well. At higher noise, `f_theta0` is not a faithful enough proxy for
the unknown trajectory, so subtracting its full estimated smoothing bias can
overshoot.

Next work should therefore be bounded and predeclared:

1. Run paired `N=10` at the advancing `1e-6` cells. Report raw and screened
   success, false-accept/false-reject rates, parameter RMSE, and runtime.
2. Compare a bounded damping ladder or line search only after the undamped
   result is frozen. The objective screen must choose a step without truth.
3. Replace or augment the in-sample trajectory screen with a predeclared
   cross-fitted/held-out rule before treating it as a risk selector.
4. Repeat the polish comparison across draws after explicit warm-up and record
   iterations/function evaluations as well as order-balanced steady-state time.
5. For the resolved estimator, derive and finite-difference-test the child map
   `S1 * (W - B*A0)`, where `A0` is the pilot influence and `B` differentiates
   the model-assisted bias through the pilot. No corrected interval advances
   without that gate and fixed-recipe repeated-sampling coverage.

Atomic per-cell records live under
`repro/uq_coverage_harness_2026_08/results/model_assisted_discovery_20260816/`.
The two polish comparison records are kept separately so a no-polish discovery
cell is never silently overwritten.
