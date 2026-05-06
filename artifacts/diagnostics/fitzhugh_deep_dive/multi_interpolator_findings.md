# Multi-interpolator results on fitzhugh polish=OFF

The previous deep-dive pool used **one interpolator** (`InterpolatorAAADGPR`).
The package's *default* is to use **nine** when `interpolators` is not explicitly empty.
The validation script set `interpolators = []` (empty), which silently fell back to single-
interpolator mode using the AAADGPR default. **This was the bug in our test setup, not in
the package.**

## Per-interpolator results

7 configurations tested. Each uses `shooting_points = 3, polish=OFF, multipoint enabled`.

| Config | elapsed (s) | pool size | best rel | median rel |
|---|---:|---:|---:|---:|
| Single `InterpolatorAAADGPR` (the one I had been testing) | 113.6 | 12 | 7.061 | 54.8 |
| Single `InterpolatorAAAD` (pure AAA rational) | 12.4 | 12 | 13.63 | 39.03 |
| Single `InterpolatorAGPRobust` (pure GP, SE kernel) | 117.9 | 12 | 7.061 | 54.8 |
| Single `InterpolatorAGPRobustMatern52` | 159.5 | 1 | 3.7e9 | 3.7e9 |
| **Single `InterpolatorAGPRobustSExRQ` (GP, SE×RQ kernel)** | **253.6** | **12** | **0.998** | **27.04** |
| Multi (AAAD + AGPRobust + AAADGPR — 3 interp) | 62.0 | 36 | 7.061 | 39.03 |
| **Multi (full default 9-interpolator set)** | **254.1** | **108** | **0.704** | **52.02** |

**Headline**: with the full default 9-interpolator multi-run, **best rel-err = 0.704**.
Under 1.0 — meaning `b` is within its own magnitude (~0.887) of truth, not 7× off.

The previous "best rel = 7.061" we'd been working from is a 10× artifact of using one
interpolator in a single-source mode.

## Why does SExRQ (and presumably others in the 9-set) help?

The SE×RQ kernel GP is non-stationary — it captures both smooth-and-periodic structure
and abrupt-spike-like structure. fitzhugh's data has both: smooth recovery, sharp upstroke.
Standard SE-kernel GP is stationary and either overestimates noise on the smooth part or
underestimates it on the sharp part. Pure AAA places near-real poles near boundaries
and fails on high-order derivatives there. SE×RQ avoids both failure modes.

The AAADGPR default is "AAA with GP-pivot regularization" — it tries to combine the two,
but the combination doesn't dominate either pure approach on this case. SExRQ alone wins.

## Multi-interpolator effect

The 9-interpolator run gives 0.704, which is BETTER than any single interpolator (best
single is SExRQ at 0.998). So the gain isn't just "use SExRQ" — the multi-run pool also
contains something that SExRQ alone didn't find. The per-interpolator breakdown shown
in the run only labels 4 interpolators distinctly (`aaad`, `aaad_gpr`, `agp_robust`,
`agp_robust_se_times_rq`); the other 5 (S3AdaptSE/SExRQ, ChebyshevBIC/AICc, S2AAAMLE)
must have their `provenance.interpolator_source` either un-set or aliased to one of the
shown four. So the 0.704 candidate's exact origin needs more digging.

## Implications for the bigger story

- **The original "fitzhugh polish=OFF is rel=7.06" baseline is wrong** — it's an
  artifact of `interpolators=[]` silently disabling the multi-interpolator default.
  Real production-default baseline is **0.704** (10× lower).
- **All the seed-strategy work** (S0 through S6) was solving a non-problem in the
  default setting. The default already gets to rel<1 via cross-interpolator diversity.
- **The validation harness needs to be re-run** with `interpolators` set correctly
  (i.e., NOT empty) before drawing any conclusions about pool quality.
- **The buggy mean-blend "win" from rel=7.06 to rel=2.54** was operating on the wrong
  baseline. Even in the buggy state, mean-blend never beats what the default
  multi-interpolator gives.

## What I want to verify next

- Re-run the v6 broad_mixed sweep with `interpolators` left at default (or explicitly
  set to a multi-interp list) instead of empty, on at least 3 cases. See if "the
  buggy mean-blend wins on fitzhugh" holds when the baseline is rel=0.704 instead of
  rel=7.06.
- Identify which interpolator gave the 0.704 candidate (need to fix the
  provenance-naming or print explicit per-candidate info).
- Run on seir polish=ON with multi-interp enabled — does it also drop the rel=2.649
  baseline by 10×?

This is the biggest "gotcha" of this entire investigation. The multi-interpolator default
was always there; we just weren't using it.
