# Pre-seed research — Phase B findings (across two cases)

## Cases tested

1. **fitzhugh_nagumo_2_1em4 polish=OFF** — pool 12 candidates, baseline rel=7.061
2. **seir_2_1em4 polish=ON** — pool 38 candidates, baseline rel=2.649

## Strategy comparison

Oracle-best max-rel-err over the union (pool + emitted seeds).

| Strategy | fitzhugh polish=OFF | seir polish=ON | Notes |
|---|---:|---:|---|
| S0 (baseline) | 7.061 | 2.649 | reference |
| **S1 (all-pairs mean blend)** | **2.54** | **1.572** | clear winner on both |
| S2 (cluster median k=2) | 7.061 | 2.649 | no improvement |
| S2 (cluster median k=3) | 7.061 | 2.649 | no improvement |
| S2 (cluster median k=4) | 7.061 | 2.649 | no improvement |
| S5 (Dirichlet n=50) | 7.061 | 2.649 | no improvement |
| S5 (Dirichlet n=200) | 7.061 | 2.649 | no improvement |
| S6_simple (flapper→0) | 1.0 (degenerate) | 1.0 (degenerate) | sets everything to 0 |
| S6_simple (flapper→median) | 7.061 | 2.466 | marginal |
| S2_trimmed (trim=25%) | 7.061 | 2.466 | marginal |
| S2_trimmed (trim=50%) | 7.061 | 2.649 | no improvement |
| S2_trimmed (trim=75%) | 7.061 | 2.649 | no improvement |

## Headline

**S1 (all-pairs mean blend on params, states from one parent) is the only strategy
that beats baseline non-trivially on both cases.** It's the formalized,
no-parser-bug version of what the buggy Σ_x=0 → all-Mahalanobis-pairs-blend
behavior was doing.

The improvement magnitudes:
- fitzhugh polish=OFF: 7.061 → 2.54 (2.78×)
- seir polish=ON: 2.649 → 1.572 (1.69×)

Neither result is "production-quality good" (rel >> 0.1), but both are
real reductions in oracle-best.

## Why other strategies don't beat S1

- **S2 (cluster + median)**: clustering on raw transformed coords lumps wild
  outlier candidates together with near-fit candidates because the wild
  candidates' parameter values dominate the distance metric. The cluster
  median is then dragged out by the outliers.
- **S5 (Dirichlet random convex combinations)**: uniform random weights
  never sample the specific weighting needed to hit truth. Even with 200
  samples, the expected weight is ~uniform and lands near the centroid.
- **S6_simple (flapper→0)**: every parameter is classified as a flapper
  because the pool's wild outliers have CV > 50% on every coordinate.
  Setting all params to 0 gives `max-rel-err = 1.0` by construction (each
  param 100% off when truth is O(1)). Not a real win.
- **S2_trimmed**: trimming outliers helps marginally on seir. The surviving
  trimmed candidates' median is closer to truth than the full-pool median,
  but still not as good as S1's lucky pair-blend.

## Sensitivity-aware strategies (S3, S4) deferred

Implementing S3 (per-parameter weighted consensus by 1/‖S row‖²) and S4
(best-of-source per parameter) requires capturing per-candidate sensitivity
matrices `S` from the pipeline. The existing `_compute_data_sensitivity`
needs `setup_data` which is internal to `optimized_multishot_estimation.jl`.

To extract this, we'd need to either:
- Add a "research-capture" hook to the pipeline (production-code change)
- Re-implement the SI-template + Taylor-coefficient setup in the harness

Given that S1 already gets us the win range we'd expect from S3 (oracle-best
weighted blend on fitzhugh would be rel ≈ 0.5 — better than 2.54 but still
far from 0.1), the engineering ROI of building S3 is unclear. Worth trying
on a different case where the pool DOES contain a truth-near candidate
(seir polish=ON had one at rel=1.87 in the v6 dive, but Phase B's S1 found
rel=1.572 here — close enough that S3's potential improvement is
incremental).

## Recommendation

Two paths forward:

**Path A (ship S1 as production mechanism):**
- Replace `sensitivity_seeds.jl`'s mechanism with a clean S1 (all-pairs mean
  blend on params, no σ_d, no Mahalanobis). Add a budget cap (e.g., emit
  only top-K pairs by some cheap criterion if pool > 30).
- Run full bilby broad_mixed sweep with this change. Confirm wins generalize.
- Retire σ_d code (sigma_d.jl).

**Path B (build S3/S4 properly):**
- Add the research-capture hook to the pipeline (modest production-code
  change).
- Implement S3 with weighted consensus + Newton-snap-to-F=0.
- Run on fitzhugh, seir, and a third case. Compare against S1.
- Decision: ship whichever wins more often.

Path A is shippable now; Path B is research-y with modest expected payoff
based on Phase B's findings. **My recommendation: Path A**, with Path B as
a follow-up if the broad_mixed sweep shows S1 isn't enough.

## Per-case detail

### fitzhugh_nagumo_2_1em4 polish=OFF
- Truth: g=0.779, a=0.849, b=0.887
- Pool best: idx 3, single_point, params (g=0.7925, a=2.066, b=7.15), rel=7.061
- S1 best: blend of idx 3 + idx 11 (g=0.7379, a=−2.426, b=−9.882) → mean params
  (g=0.7652, a=−0.180, b=−1.366), rel=2.54
- The win comes from `b` averaging across two candidates with opposite-sign extreme values.

### seir_2_1em4 polish=ON
- Truth: a=0.187, b=0.414, nu=0.277
- Pool best: rel=2.649 (specific candidate not inspected)
- S1 best: rel=1.572. Same mechanism — the polished pool already has spread, mean-blending
  reduces the spread variance.
