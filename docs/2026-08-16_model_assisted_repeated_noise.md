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

All 40 primary cells completed successfully at the frozen PEB SHA
`c94e0a3eb5bbd8ab95c73e30f203cbad73485d7b`. Every cell used schema 2,
the exact ten-seed set, the full 750 observations, and the deployable
screened-policy fallback.

| Model | Usable | Raw truth wins | Raw/pilot RMSE | Screen accepts | False accept / reject | Policy/pilot RMSE | Raw mechanism | Screened policy |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Lotka--Volterra | 10/10 | 4/10 | 0.734 | 3 | 3 / 4 | 1.008 | stop | stop |
| FitzHugh--Nagumo | 10/10 | 4/10 | 2.274 | 2 | 0 / 2 | 0.967 | stop | stop |
| Slow--fast | 10/10 | 4/10 | 0.806 | 4 | 1 / 1 | **0.447** | stop | advance |
| Van der Pol | 10/10 | 5/10 | 0.767 | 5 | 0 / 0 | **0.579** | stop | advance |

No model passed the frozen raw-mechanism rule. The full undamped correction is
therefore not a generally improving estimator even in the favorable `1e-6`
regime. Slow--fast and Van der Pol passed only the screened-policy rule and
triggered the preregistered polish follow-up.

The aggregate RMSE and paired outcomes tell different but compatible stories.
LV's raw RMSE falls by 27%, but its median paired worst-error ratio is 1.05 and
the trajectory screen is anti-informative in this sample: it accepts three
regressions and rejects all four truth improvements. FHN is worse overall
(`2.27x` pilot RMSE), although four individual multipoint draws improve. The
screened fallback makes FHN only 3.3% better in RMSE, below the frozen 10%
threshold. Slow--fast and Van der Pol contain large enough screen-detectable
improvements to lower policy RMSE despite the full correction's inconsistent
sign.

### Route dependence

Route stability explains much of the difference.

- Van der Pol and slow--fast select the same SP point `[374]` in all ten
  draws. The Van der Pol screen exactly separates five improvements from five
  regressions. Slow--fast accepts three improvements and one mild regression,
  while rejecting one improvement.
- LV always selects an MP route, but varies among `[25,635]`, `[8,635]`, and
  `[36,635]`. Its small truth changes are not ordered by trajectory SSE.
- FHN selects six MP and four SP routes. All four selected SP corrections
  worsen; four of six MP corrections improve, and the screen catches only two
  of those four. The discovery result used SP point `[223]`, which production
  did not select in any repeated draw. Its `5.63% -> 0.0385%` repair was thus a
  real fixed-draw mechanism result, not a representative FHN policy result.

One repeated FHN MP draw still demonstrates the attractive failure-repair
mode: seed `8163108` moves from 7.76% to 1.31% worst-coordinate error. The
current SSE screen rejects that improvement, so the remaining problem is not
only correction strength; it is also truth-free step selection.

After compilation, the correction itself is cheap. Median correction times are
0.050 s (LV), 0.043 s (FHN), 0.057 s (slow--fast), and 0.040 s (Van der Pol).
The expensive part of these cells remains production candidate construction
and estimation, especially the order-9 slow--fast system.

### Repeated interaction with polish

Van der Pol used the declared fresh warm-up seed `8163200`, then five fresh
evaluation seeds. Slow--fast's declared warm-up was screened out, so it never
executed the code that needed warming. That rejected record is retained; a
known accepted, non-evaluation seed (`8163101`) was then used as a technical
polish warm-up. Both slow--fast warm-up records are excluded, and the original
five evaluation seeds and alternating call order are unchanged.

| Model | Evaluation draws | Accepted / paired | Median corrected-seed / pilot error | Max paired final-estimate difference | Pilot / corrected polish median | Median paired time ratio |
|---|---:|---:|---:|---:|---:|---:|
| Slow--fast | 5 | 4 / 4 | **0.111** | `1.06e-10` relative | 0.066 / 0.080 s | 1.51 |
| Van der Pol | 5 | 5 / 5 | **0.583** | `1.20e-12` relative | 0.043 / 0.061 s | 1.62 |

Every accepted correction in both follow-ups lowers paired truth error. The
single rejected slow--fast draw is a true regression, so these fresh samples
contain no screen mistake. Slow--fast's accepted corrections are substantial:
their median worst-error is 11% of the paired pilot. Van der Pol's is 58%.

That improvement does not carry through trajectory polish. Within numerical
tolerance, both starts converge to the same final estimate on every paired
draw. Median polished worst-coordinate errors are `2.74e-6` for slow--fast and
`1.43e-7` for Van der Pol, independent of the start. Corrected-start polish is
not faster; it is modestly slower in these small samples. The current evidence
therefore supports a cheap standalone low-noise improvement on screened
slow--fast/Van der Pol draws, but not an LBFGS replacement and not a better
polishing seed.

### Decision

The bias mechanism is real but conditional. A close pilot can predict a useful
component of fixed-smoother jet bias, and a model-assisted step can sometimes
repair an estimate cheaply. Pilot error, selected point/route, high derivative
order, and the nonlinear backsolve can just as easily rotate or amplify that
step. GPR bias is not removed merely by evaluating the model at an estimated
trajectory.

Consequently:

1. keep the feature research-only and default-off;
2. do not promote the undamped full correction for any tested model;
3. do not add corrected UQ yet—the pilot-through-correction influence remains
   required and the estimator rule is not stable enough to justify that work;
4. next test a frozen damping ladder with a held-out or cross-fitted trajectory
   rule, aimed specifically at recovering false rejects without LV-style false
   accepts; and
5. do not spend more effort on polish seeding until a case has a material
   steady-state polishing cost or basin failure. These two advancing cases do
   not.

Atomic primary records are in
`repro/uq_coverage_harness_2026_08/results/model_assisted_n10_1em6_20260816/`,
with the frozen aggregate in
`model_assisted_n10_1em6_20260816_summary.toml`. Polish records are in the
matching `model_assisted_polish_{vdp,slow_fast}_n5_20260816/` directories, and
their warm-up-aware combined aggregate is
`model_assisted_polish_n5_20260816_summary.toml`.
