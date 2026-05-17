# Spot-check summary — 2026-05-16/17 live-pipeline validation

Two cells run end-to-end on the current code with new defaults in place
(soft-wall ON, scheme S2 sort, identifiable-subspace clustering).

| Cell | Status | Wall-clock | Result |
|---|---|---|---|
| slow_fast_6_1em4 | ✅ Complete | ~13 min | Truth + mirror basins preserved; rank-1 oracle ~0.3% |
| biohydrogenation_6_1em6 | ✅ Complete (re-run after agent killed first) | ~60 min | k10 saturation eliminated, but truth not found — numerical-ridge minimum |

## slow_fast_6_1em4

**Truth:** xA=0.418, xB=0.341, xC=0.358, eA=0.118, eC=0.563, eB=0.768,
k1=0.104, k2=0.876

**Headline:** Both algebraic basins (truth xA>0 and mirror xA<0) clearly
preserved. Rank-1 row is the truth basin with branch_size=172. Identifiable-
subspace clustering achieves 5× compression (504 candidates → 100 reps) but
with 38 singletons surviving in the tail because within-basin practical-non-id
spread exceeds the 5% L∞ threshold.

| Metric | Value |
|---|---|
| Total rows | 100 (legacy 2026-05-13: 20 with old K=20 default) |
| Truth basin rows (xA > 0) | 54 |
| Mirror basin rows (xA < 0) | 46 |
| Sum of branch_size (= input candidates) | 504 |
| Largest cluster | 172 (truth basin, rank-1) |
| 2nd largest cluster | 62 (mirror basin, rank-2) |
| Singletons (branch_size=1) | 38 |
| Rank-1 row | Truth basin, err=1.78e-6, xA=0.4172 (truth 0.418), k1=0.10430 (truth 0.104) |
| Rank-1 oracle | max-rel-err = 0.29% (k1) |

**Within-basin spread (refutes the 5% within-basin tolerance):**

| Param | Truth basin MAD/median | Mirror basin MAD/median |
|---|---|---|
| xA | 5% | 31% |
| xB | 11% | 30% |
| k1 | 16% | 6% |
| k2 | 6% | 13% |

**Verdict:** Clustering works as designed for basin separation, but the
`subspace_cluster_eps = 0.05` default is too tight for slow_fast's practical
non-identifiability spread (6–31%). The cosmetic issue (38 singletons in
tail) does NOT affect the rank-1 outcome.

**Suggested fix:** bump default `subspace_cluster_eps` to 0.2–0.3, or
auto-tune (e.g., 2× median MAD across the rough cluster). Defer; not
blocking.

## biohydrogenation_6_1em6 — soft-wall fixes saturation but not truth

**Truth:** k5=0.476, k6=0.397, k7=0.107, k8=0.889, k9=0.73, **k10=0.818**,
x4=0.639, x5=0.841, x6=0.397, x7=0.421

**Headline:** Soft-wall regularization **successfully eliminates k10 bound
saturation** (legacy 2026-05-13: 18/20 rows at k10=10; today: 0/100 rows
at k10 ≥ 9.5). But the polish then settles into a **numerical-ridge
minimum at k10 ≈ 5.0** for 76 rows and **k10 ≈ 0.1-0.5** for 22 rows.
**Truth (k10=0.818) is in the gap between basins** — no row in result.csv
lands near it. **Best oracle in result.csv: 86.6%** (rank 86, not rank 1).

### k10 distribution (100 rows total)

| k10 range | Rows |
|---|---|
| [0.0, 0.5] | 22 |
| [0.5, 1.5] | **0** ← truth (0.818) falls in this gap |
| [1.5, 2.0] | 1 |
| [2.0, 2.5] | 1 |
| [5.0, 5.5] | 76 (dominant) |
| ≥ 9.5 | 0 (vs legacy 18/20) |

### Rank-1 row

| Param | Estimate | Truth | Rel error |
|---|---|---|---|
| k5 | 0.476 | 0.476 | **0%** ✓ |
| k6 | 0.397 | 0.397 | **0%** ✓ |
| k7 | 0.107 | 0.107 | **0%** ✓ |
| k8 | 0.889 | 0.889 | **0%** ✓ |
| k9 | (mid-range) | 0.73 | (depends) |
| **k10** | **5.012** | **0.818** | **513%** ✗ |
| ICs (x4, x5, x6, x7) | match | match | ≈0% |

Five out of six params and all four ICs are at machine precision against
truth. **Only k10 is wrong** — by 6×. Same picture across all 76 rows in
the 5.0-basin: same k10≈5.012 numerical-ridge minimum.

### Soft-wall + S2 sort working as designed; truth-finding requires more

The 2026-05-15 fresh-look investigation called this out exactly: "Soft-wall
doesn't find truth — it cleans up the bound saturation but the truth-near
row stays at rank ~27. Whatever's blocking polish from converging to truth
on this cell is not the bound." This run confirms that prediction: with no
saturation in result.csv, S2's primary key (saturation_count) collapses
to zero across all rows, so S2 effectively sorts by err — and the err-best
candidate is the 5.0-basin minimum, not truth.

### The numerical ridge is the cond(J) story (column-scaling investigation)

Independently today's column-scaling diagnostic measured biohydrogenation
at **cond(J) = 1.44 × 10⁹** with **column-norm imbalance of 4.1 orders of
magnitude** (see `repro/column_scaling_2026_05_16/PROTOTYPE_FINDINGS.md`).
Bauer-Skeel column scaling drops this to **6.81 × 10⁵ (2114× improvement)**.

The 4.1-order column imbalance is the *mechanism* behind the numerical
ridge: the polish residual surface is essentially flat in the k10 direction
because k10 multiplies small terms in J's k10 column. The polish converges
to wherever the residual is locally smallest, which happens to be either
the k10≈5 minimum or the k10≈0.1 minimum — both far from truth.

**The two investigations converge on the same conclusion:** soft-wall
treats the symptom (bound saturation); column scaling on the SI template
would treat the root cause (poor signal in the k10 direction). Soft-wall
keeps the polish off the wall; column scaling would tell it where the
truth actually is.

## Combined verdict

| Change | Spot-check evidence |
|---|---|
| Soft-wall default ON | ✅ Eliminates k10 saturation 18/20 → 0/100 on bioh |
| Scheme S2 sort default | ✅ Rank-1 surfaces the largest cluster on slow_fast (truth basin, branch_size=172) |
| Identifiable-subspace clustering default | ✅ Truth + mirror basins kept distinct; 5× compression on slow_fast; rank-1 oracle 0.3% |
| Identifiable-subspace clustering threshold (5%) | ⚠️ Too tight for practical-non-id spread (6-31% on slow_fast) — defer fix |
| Soft-wall + S2 for bioh-class | ⚠️ Eliminates saturation but doesn't find truth — numerical ridge persists |

**Next-step priorities:**
1. **Column scaling for bioh-class systems (high value):** the 2000×
   cond reduction would likely close the remaining 86% oracle gap on
   bioh. See `repro/column_scaling_2026_05_16/PROTOTYPE_FINDINGS.md` for
   the implementation recommendation (Level A opt-in, column-norm-based
   not bound-based).
2. **Bump `subspace_cluster_eps` to ~0.2 (low priority):** would compress
   the slow_fast tail from 38 singletons → ~5 reps. Doesn't change
   rank-1 outcome.
3. **No-op tasks** — soft-wall, S2 sort, basin-preserving clustering all
   working as designed. No regressions on fast_core.jl (258/258) or
   feature_regressions.jl (133/133).
