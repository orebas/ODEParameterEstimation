# Pre-seed research — Phase B findings on fitzhugh polish=OFF

## Setup

- Test case: `fitzhugh_nagumo_2_1em4`, `polish_solutions = false`
- Pool: 12 candidates (6 single_point, 6 multipoint)
- Truth: `g=0.779, a=0.849, b=0.887`
- Pool baseline (S0): min rel-err = 7.061, max = 131.2

## Strategy comparison (oracle-best rel-err over union of pool + seeds)

| Strategy | n_seeds emitted | Union best rel-err | vs. S0 baseline |
|---|---:|---:|---|
| S0 (baseline, no seeds) | 0 | 7.061 | — |
| S1 (all-pairs mean blend) | 66 | **2.54** | 2.78× better |
| S2 (cluster median k=2) | 1 | 7.061 | no change |
| S2 (cluster median k=3) | 2 | 7.061 | no change |
| S2 (cluster median k=4) | 3 | 7.061 | no change |
| S5 (Dirichlet n=50) | 50 | 7.061 | no change |
| S5 (Dirichlet n=200) | 200 | 7.061 | no change |
| S6_simple (flapper→0) | 12 | **1.0** | degenerate |
| S6_simple (flapper→median) | 12 | 7.061 | no change |
| S2_trimmed (trim=25%) | 1 | 7.061 | no change |
| S2_trimmed (trim=50%) | 1 | 7.061 | no change |
| S2_trimmed (trim=75%) | 1 | 7.061 | no change |

## Diagnosis

1. **S1 reproduces the parser-bug win (rel=2.54)** by construction — it's all-pairs mean blend
   on params, which is exactly what the buggy Σ_x=0 → all-pairs Mahalanobis-passes did. The
   "win" comes from a single pair (idx 3 with `b=7.15` and idx 11 with `b=−9.88`) whose mean
   `b=−1.37` is closer to truth `b=0.887` than either parent. Still 250% off in `b` — not a
   real solution.

2. **S6_simple's rel=1 is degenerate.** All three params `(g, a, b)` get classified as
   flappers because the pool contains both "near-fit" candidates (e.g., `g≈0.79`) and
   "wild" candidates (e.g., `g=−5.68`). High pool CV across all params → `S6_simple` sets
   everything to 0 → `max-rel-err = max(|0−0.779|/0.779, ...) = 1.0`. This is just "everything
   100% wrong," not a useful estimate.

3. **None of the smarter strategies beat S1** on this case:
   - S2 (cluster median): clustering on raw transformed coords lumps wild candidates with
     near-fit ones → median is dragged to outliers.
   - S5 (Dirichlet): random convex combinations stay inside the pool's convex hull but uniform
     weights miss the specific (~0.63 / 0.37) weighting needed to hit truth.
   - S2_trimmed: trimming outliers gives the median of "good" candidates, but the surviving
     candidates' `b` values still don't straddle truth.

4. **Truth is technically in the convex hull of the pool** (`b=0.887 ∈ [−10, +7.15]`), but
   reaching it requires per-parameter weighting that knows the truth's location for each
   parameter — which is the original problem.

## What this means

On a case where the pool fundamentally lacks a truth-near candidate, no blending /
clustering / shrinkage trick can fabricate one. We can get to "less-wrong" via
all-pairs blending, but not to "right." This matches the user's earlier observation that
the algebraic pool may genuinely not contain the answer at the given (noise level,
shooting points, interpolator) trio.

## What I think we should test next

Two questions are open after Phase B:

**Q1: Does post-polish behavior change the picture?** Pre-polish rel-err is a proxy; the
real question is "do these seeds help polish converge to truth?" A seed at rel=2.54 might
land in a different polish basin than fit-best at rel=7.06, even with the same loss
landscape.

**Q2: Are there cases where the pool DOES contain truth-near candidates that aren't
fit-best?** seir polish=ON in the v6 dive showed an oracle-best at rel=1.87 (from a
sensitivity seed) vs fit-best at rel=27.6 — i.e., the pool *did* contain a near-truth
candidate, just not the one fit-rank picks. On such cases, a "consensus + Newton-snap"
strategy might surface the existing truth-near candidate without fabricating one.

Most informative next experiment: **run the full strategy set on seir polish=ON**, where
the v6 dive showed the pool has a 14× gap between oracle-best and fit-best.
