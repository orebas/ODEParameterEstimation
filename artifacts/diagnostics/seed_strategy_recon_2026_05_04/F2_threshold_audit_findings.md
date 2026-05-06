# F2 — Threshold-gate audit across 3 AMIGO2-only cases

Generated: 2026-05-04 during autonomous research run.

## Method

For each case, read the bilby saved `odepe_nopolish/result.csv` (the post-clustering
pool from the production pipeline). For each row, compute:

- **rel-err**: `max |estimated[k] − true[k]| / |true[k]|` over all params + ICs (truth is known to me as researcher; not visible to the pipeline).
- **loss**: `polish_ctx.optf.f(p_internal, nothing)` — the same closure the polish phase optimizes.

Classify each row as "pre-gate" (`loss < 0.5`) or "post-gate" (`loss ≥ 0.5`). The
pipeline's `MAX_ERROR_THRESHOLD = 0.5` (in `core_types.jl:63`) discards post-gate rows
when ANY pre-gate row exists. When NO pre-gate row exists, it falls back to top
`MAX_SOLUTIONS = 20` by err.

## Results

### Case 1: `flexible_arm_0_1em4`

```
Pool size: 62 rows
Pre-gate (loss<0.5):     0
Post-gate (loss>=0.5):  60
NaN loss:                2
```

Top 5 by truth-rel-err (all dropped):
```
idx 27: rel=0.475, loss=3659     ← truth-best
idx 21: rel=0.561, loss=22370
idx 18: rel=0.630, loss=23780
idx 30: rel=0.827, loss=2475
idx 13: rel=0.845, loss=61310
```

Top 5 by loss:
```
idx 62: loss=0.74,  rel=1.66
idx 60: loss=0.89,  rel=1.91
idx 61: loss=0.99,  rel=2.54
idx 59: loss=2.31,  rel=2.64
idx 58: loss=12.3,  rel=7.63
```

**Diagnosis**: Truth-best (idx 27, rel=0.475) is NOT in top-20 by err → DROPPED via
gate fallback. **Fit and truth are anticorrelated on this case.** The 4 best-rel rows
all have losses ≥2475 (gate-dropped). The 4 best-loss rows are all rel ≥ 1.66.

This is **Class C: the pool contains a usable candidate but ranking discards it**. The
existing pipeline cannot recover this case via any selection strategy on the current
err metric.

### Case 2: `forced_lotka_volterra_0_1em2` (highest-noise total ODEPE failure)

```
Pool size: 65 rows
Pre-gate (loss<0.5):    0
Post-gate (loss>=0.5): 59
NaN loss:               6
```

Top 5 by rel-err:
```
idx 64: rel=0.308, loss=46.5    ← truth-best
idx 63: rel=0.308, loss=46.6
idx 62: rel=0.308, loss=46.6
idx 61: rel=0.330, loss=58.4
idx 58: rel=0.413, loss=77.5
```

Top 5 by loss:
```
idx 65: loss=21.8, rel=1.22
idx 64: loss=46.5, rel=0.308   ← truth-best!
idx 63: loss=46.6, rel=0.308
idx 62: loss=46.6, rel=0.308
idx 61: loss=58.4, rel=0.330
```

**Diagnosis**: Pool's best candidate is rel=30.8% — well past the 10% "useful" threshold.
The pool **fundamentally lacks truth-near candidates** at this noise level (1e-2 is 100×
worse than 1e-4). Truth-best (idx 64) IS in top-20 by loss → the gate fallback retains
it. But it's still 31% off truth.

This is **Class A: pool inadequate, no selection strategy will fix it**. Need either
better data, better interpolators (boundary handling under high noise), or a fundamentally
different pipeline (e.g., AMIGO2's optimization-based approach).

### Case 3: `daisy_mamil3_7_1em4`

```
Pool size: 89 rows
Pre-gate (loss<0.5):  32
Post-gate (loss>=0.5): 55
NaN loss:              2
```

Top 5 by rel-err:
```
idx 89: rel=0.111, loss=7.6e-4   ← truth-best AND fit-best
idx 88: rel=0.115, loss=9.9e-4
idx 86: rel=0.125, loss=1.7e-3
idx 87: rel=0.133, loss=1.3e-3
idx 82: rel=0.166, loss=2.8e-3
```

**Diagnosis**: Best by truth IS best by fit (idx 89). 32 rows pass the gate cleanly.
The pool contains a usable candidate at rel=11.1%. But bilby reported this case as a
"near-miss" with `100% mean rel err, Inf max rel err`.

So the pool has a near-truth candidate in the saved CSV. Bilby's pipeline winner must
be a different row entirely. Possible causes:
- Clustering at the cluster_solutions stage merges the truth-near row into a different
  representative.
- The bilby benchmark's "Max Rel Err" metric is computed differently from mine
  (e.g., exluding states or including unidentifiable params).
- The 89th row in the CSV is at a position the bilby selector doesn't pick.

Worth investigating further but **the saved pool is fine**.

## Cross-case synthesis

| Case | Pool best rel | Fit-best rel | Class | Cause |
|---|---:|---:|---|---|
| flex_arm_0_1em4 | 0.475 | 1.65 | C — ranking miss | Gate fallback discards truth-better rows |
| forced_lv_0_1em2 | 0.308 | 0.31 (same row) | A — pool inadequate | Pool fundamentally insufficient at 1e-2 noise |
| daisy_mamil3_7_1em4 | 0.111 | 0.111 (same row) | C — selection miss | Pool fine; pipeline winner ≠ saved-CSV best |

**Three different failure modes.** No single intervention fixes all three.

For seed-strategy R&D specifically:
- **flex_arm**: needs ranking-side fix (relative threshold or finalists output). Pool
  is fine.
- **forced_lv**: needs better DATA processing or a different pipeline approach. Seed
  strategies operating on this pool can't help.
- **daisy_mamil3_7**: pool fine; pipeline selection logic is the issue. Investigate
  clustering/selection between saved CSV and reported max rel.

## Concrete proposal for the gate fix

The current logic:

```julia
valid_results = filter(x -> x.err < MAX_ERROR_THRESHOLD, scored_results)
if isempty(valid_results)
    sort(scored_results, by = _result_err_key)[1:min(MAX_SOLUTIONS, length(scored_results))]
else
    sort(valid_results, by = _result_err_key)
end
```

A relative-threshold variant:

```julia
sorted_by_err = sort(scored_results, by = _result_err_key)
isempty(sorted_by_err) && return Any[]
best_err = sorted_by_err[1].err
# Keep candidates within k× the best, AND the top-MAX_SOLUTIONS regardless
k = 1000.0  # generous; admits a wide range of plausible candidates
filter(x -> isnothing(x.err) ? true : (x.err <= max(MAX_ERROR_THRESHOLD, k * best_err)),
       sorted_by_err)[1:min(MAX_SOLUTIONS, length(sorted_by_err))]
```

Effect on flex_arm:
- best_err ≈ 0.74; k=1000 → keep rows with err ≤ 740
- Truth-best (idx 27) has err=3659 — STILL dropped (>740)
- Need k=5000 to admit it: err ≤ 3700

So relative threshold helps but you'd need k≥5000 — which is barely better than "keep
all candidates." That's evidence that the err metric itself is the wrong signal, not
the threshold value.

A cleaner alternative: **don't gate at all**. Cluster the entire pool, return all
representatives, let UQ / cross-spread / finalists pick. The team's existing
`research_tryhard_finalists` and `_build_reasonable_tryhard_frontier` machinery
already does this; it just isn't on the production gate path.
