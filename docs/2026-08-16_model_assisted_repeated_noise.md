# Model-assisted correction: repeated-noise protocol and results

Date: 2026-08-16

Status: protocol frozen before the repeated-noise cells were run. Results will
be appended below without changing the advancement rules.

## Purpose

The one-draw discovery screen showed a large `1e-6` repair for FHN, smaller
improvements for slow--fast and Van der Pol, and a nearly neutral adverse change
for an already accurate LV estimate. This campaign asks whether those are
repeatable properties of the estimator rather than lucky noise draws.

## Frozen experiment

- Audited PEB constructors, truths, hashes, and full 750-row grids.
- Models: `lotka_volterra_5_1em6`, `fitzhugh_nagumo_9_1em6`,
  `slow_fast_5_1em6`, and `vanderpol_2_1em4`.
- Additive noise `1e-6`.
- Ten fresh seeds: `8163101:8163110`. None appeared in the one-draw discovery.
- Production candidate generation, clustering, ranking, and rank-one selection.
- `uq_only` interpolation pool, because the correction requires the exact
  retained `AGPInterpolatorUQ` smoother.
- No trajectory polish in the primary campaign.
- The correction, exact same-branch local re-solve, and screen are unchanged
  from commits `e29d98c` / `faa69c9`.

The deployable screened policy means: use the corrected candidate only when it
lowers the observed-data trajectory SSE; otherwise retain the original pilot.
Truth is used only by the offline aggregation below.

## Metrics

For every model, report:

1. usable raw corrections out of 10;
2. raw corrections with lower worst-coordinate truth error than the paired
   pilot;
3. screen accepts, false accepts, and false rejects;
4. relative-error RMSE across all parameter and initial-state coordinates,
   separately for pilot, raw correction, and screened policy;
5. parameter-only and state-only RMSE;
6. median paired worst-coordinate error ratio and correction time;
7. the selected estimator kind and exact point-set frequency.

## Advancement rules

These rules are frozen before inspecting the ten new draws.

The correction mechanism advances to damping/cross-fitting work for a model
only if:

- at least 9/10 raw corrections are usable;
- at least 7/10 raw corrections lower paired worst-coordinate error; and
- raw all-coordinate relative RMSE is at most 80% of pilot RMSE.

The screened estimator advances to a disjoint repeated-polish experiment only
if:

- it makes at most one false accept; and
- its all-coordinate relative RMSE is at most 90% of pilot RMSE.

Failure to advance does not invalidate the low-noise bias mechanism. It means
the current full correction and in-sample SSE screen are not yet a deployable
estimator for that model.

## Repeated-polish contingency

Only models satisfying the screened-estimator rule will be run on fresh polish
seeds. The first cell is an excluded compilation warm-up; five subsequent
draws alternate pilot-first and corrected-first order. Report final paired
accuracy and steady-state time. Corrected UQ remains unavailable throughout.

## Results

Pending.
