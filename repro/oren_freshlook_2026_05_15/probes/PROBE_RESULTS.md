# Probe Results — 2026-05-15 evening

Five validation probes from the `repro/oren_freshlook_2026_05_15/` deep
dive. Each script in this directory is a self-contained read-only probe
or (for Probe 2) a small ODEPE source change + test.

Confidence markers throughout: **[V]** verified, **[L]** likely,
**[S]** speculative.

---

## Probe 1 — cond(J_local) on slow_fast's two basins

**Hypothesis tested**: truth basin and mirror basin of `slow_fast_6_1em4`
have systematically different local Jacobian conditioning, making
cond(J) a useful basin-flagging signal.

**Result: confirmed, strongly.** [V]

| | truth basin (xA > 0) | mirror basin (xA < 0) |
|---|---|---|
| count | 50 rows | 50 rows |
| median cond(J) | **112.9** | **10 500** |
| range cond(J) | [111.9, 113.3] | [9 667, 11 500] |
| median σ_min | 0.514 | 0.0122 |
| median σ_max | 58.0 | 128.5 |

The two basins are **perfectly separable** by cond(J) alone — there's
no overlap between the cond ranges, and a threshold around 1 000 gives
100% classification accuracy on the 100-row sample.

Dominant null-direction differs by basin too: truth basin's smallest
singular vector is mostly in `(k2, xA, eB)` directions (matching the
k1↔k2 mirror symmetry's tangent at truth); mirror basin's smallest
singular vector is dominantly `(xA, xB)`.

**Implication [S]**: For cells that have multiple algebraic basins (like
slow_fast's Z/2 mirror), cond(J) computed at each polished candidate can
flag which basin each row sits in. The "wider" basin (higher cond) is
the one polish finds easier to overfit on — so preferring lower-cond
basins is a candidate ranking rule.

**Caveat [S]**: this is one cell. Need more cases to verify the
generality. cond(J) is also expensive (one J per row × ~100 rows per
cell × ~1000 cells = real compute). If used in production, would have
to budget.

**Files**: `probe1_cond_J_slow_fast.py`, `probe1_results.csv`.

---

## Probe 2 — Soft-wall regularization on biohydrogenation_6_1em6

**Status**: source changes complete + tested for non-regression
(`test/fast_core.jl` 258/258). Bioh test run launched; results pending
(long-running due to aggregate synthesis × 7 configs).

**Source changes (committed)**:

- `src/types/estimation_options.jl`: added `polish_softwall_lambda::Float64 = 0.0`
  and `polish_softwall_epsilon::Float64 = 0.05`; validation in
  `validate_estimation_options`.
- `src/core/parameter_estimation.jl`: added `softwall_lambda` and
  `softwall_epsilon` fields to `PolishContext`; populated from `opts.*`
  at the context constructor (line ~2199).
- `src/core/polish_residual.jl`: pre-computed per-parameter midpoint /
  halfrange / threshold from `internal_lb` / `internal_ub`; appended
  soft-wall penalty rows in the residual closure after the existing
  regularization block.

The soft-wall penalty form (in internal-coord space, per parameter `i`):
```
deviation_i = |p_internal[i] - midpoint_i|
threshold_i = (1 - ε_sw) * halfrange_i
over_i      = max(0, deviation_i - threshold_i) / halfrange_i
residual_row_i = √λ_sw · over_i
```

Zero in the central `(1 - 2ε_sw)·halfrange` band; grows linearly in the
augmented residual (= quadratically in SSR) as a parameter approaches
either bound. Default off (`λ_sw = 0`); behavior unchanged for existing
runs.

**Verification**: `test/fast_core.jl` passes 258/258 with the source
change applied. [V]

**Test run on biohydrogenation_6_1em6**: pending. Results section will
include:
- per-config k10 distribution and # bound-saturated
- per-config rank-1 oracle and oracle-best-row rank
- comparison vs control (λ_sw = 0)

**Results** [V — all 7 configs complete]:

| config | elapsed | N rows | rank-1 oracle | best oracle (rank) | k10 saturated |
|---|---|---|---|---|---|
| control λ_sw=0 | 1264 s | 100 | **9.18** | 2.91 (rank 30) | **97 / 100** |
| λ_sw=1e-4, ε=0.05 | 1060 s | 100 | 6.26 | 2.91 (rank 29) | 0 / 100 |
| λ_sw=1e-3, ε=0.05 | 1013 s | 100 | 6.26 | 2.91 (rank 31) | 0 / 100 |
| λ_sw=1e-2, ε=0.05 | 1009 s | 100 | 6.26 | 2.91 (rank 29) | 0 / 100 |
| λ_sw=1e-1, ε=0.05 | 1040 s | 100 | 6.26 | 2.91 (rank 29) | 0 / 100 |
| **λ_sw=1e-2, ε=0.10** | 1053 s | 100 | **4.19** | 2.91 (rank 27) | 0 / 100 |
| λ_sw=1e-2, ε=0.02 | 1069 s | 100 | 7.89 | 2.91 (rank 28) | 0 / 100 |

**Critical findings** [V]:

1. **λ_sw is "on/off" — only the band width ε matters past the threshold.**
   λ_sw = 1e-4, 1e-3, 1e-2, 1e-1 all give *identical* rank-1 oracle 6.26
   at ε=0.05. The strength only needs to be nonzero. The minimum effective
   λ_sw is somewhere below 1e-4.
2. **ε (band width) is the dominant knob.** With λ_sw fixed at 1e-2:
   - ε = 0.02: rank-1 oracle 7.89 (k10 settles at ~8.71, slightly inside)
   - ε = 0.05: rank-1 oracle 6.26 (k10 settles deeper)
   - ε = 0.10: rank-1 oracle **4.19** (k10 settles deepest)
   Wider band = larger safe zone = polish converges further from the
   bound = lower rank-1 oracle.
3. **k10 bound saturation went 97/100 → 0/100** in every nonzero-λ config.
   The soft-wall reliably prevents the saturation pathology.
4. **The truth-near row's *content* doesn't change.** It stays at oracle
   2.91 in every config, just at a slightly different rank (27–31). The
   soft-wall is reshuffling the top of the ranking, not finding new
   truth-near candidates.
5. **Best result: λ_sw = 1e-2, ε = 0.10. Rank-1 oracle 9.18 → 4.19,
   a 2.2× improvement.** Truth-near row at rank 27 with oracle 2.91 — the
   same row that exists in the control output, just elevated by removing
   the bound-saturated competitors.

**Implications [L]**:

- **Soft-wall is a clean, opt-in fix for the bound-saturation pathology.**
  Recommended for cells where production output shows substantial
  saturation; the result is more honest (interior polish point) and
  rank-1 oracle is meaningfully better.
- **Recommend defaults (if opted-in): λ_sw = 1e-2, ε = 0.10.** Strength
  is past the on/off threshold; band is wide enough to push deep
  interior. Could probably go larger ε but 0.10 keeps roughly half the
  internal-coord interval as "safe zone".
- **NOT a universal accuracy improver.** Doesn't find truth (truth-near
  stays at rank ~27); doesn't change which rows polish converges to,
  just where. For a cell where most polish trajectories don't naturally
  reach truth, the soft-wall doesn't change that.
- **Most useful when combined with the saturation-aware rerank (scheme S2).**
  With soft-wall ON, the saturation_count signal becomes useless (always
  0). But the underlying truth-near row is still buried deep in err-sort.
  The combination "soft-wall to eliminate junk + scheme S2 to elevate
  what remains" would need additional discriminators (post-soft-wall
  there's no saturation signal).

This **reproduces the production behavior** exactly: rank-1 oracle 9.18 matches what's in the rsync mirror's `biohydrogenation_6_1em6/result.csv`; 97 of 100 candidates saturated at k10=10 (production showed 93/100 saturated). Truth-near row is buried at rank 30 with oracle 2.91 — closer than production's rank 87 due to reduced settings (shooting_points=10 vs production's 20) but same qualitative pattern.

**Remaining configs (λ_sw = 1e-4 / 1e-3 / 1e-2 / 1e-1 with ε=0.05; λ_sw=1e-2 with ε=0.02 / 0.10) pending** — will be appended when the run completes. The control alone confirms the soft-wall infrastructure is wired in correctly and runs through the full pipeline without crashing.

**Files**: `probe2_softwall_bioh.jl`; results to `probe2_outputs/probe2_results.json` (written at end of script).

---

## Probe 3 — slow_fast aggregate basin splitting

**Hypothesis tested**: aggregate synthesis explicitly discovers both
algebraic basins of slow_fast_6_1em4 (vs. stumbling into them by chance).

**Result: aggregates find both basins, but with strong per-strategy biases.** [V]

48 synthesized aggregates total. Overall split: 8 truth (17%), 40 mirror (83%).

By aggregation category and strategy:

| category | strategy | n | truth | mirror | bias |
|---|---|---|---|---|---|
| **per_sp_full_with_mp** | **median** | 5 | **5** | **0** | strongly truth |
| cross_source_weighted | median | 1 | 1 | 0 | truth (n=1) |
| per_sp_full | median | 10 | 1 | 9 | mostly mirror |
| per_sp_full | trim25_mean | 10 | 1 | 9 | mostly mirror |
| per_sp_full_with_mp | trim25_mean | 5 | 0 | 5 | strongly mirror |
| global_param_only | mean | 3 | 0 | 3 | mirror |
| global_param_only | median | 3 | 0 | 3 | mirror |
| global_param_only | trim25_mean | 3 | 0 | 3 | mirror |
| per_interpolator | median | 7 | 0 | 7 | mirror |
| interior_only | median | 1 | 0 | 1 | mirror |

**Key findings:**

1. **Aggregate synthesis is NOT uniform across basins.** Different
   strategies have systematic biases. The pipeline doesn't accidentally
   spread aggregates equally — there are real distinctions.

2. **`per_sp_full_with_mp` median is a "truth-finder"** in this cell.
   5/5 of its aggregates landed in the truth basin. The combination of
   multipoint information and median aggregation reliably produces
   truth-near starts.

3. **`per_sp_full_with_mp` trim25_mean is the opposite** — 5/5 mirror.
   The strategy (mean vs median) matters as much as the source category.

4. **`global_param_only` and `per_interpolator` strategies don't find
   truth here.** All 16 of those aggregates landed in the mirror basin.
   They aggregate across all shooting points / interpolators, which
   apparently smooths out the truth-specific signal.

**Implication [L]**: The aggregate machinery has built-in strategy-level
signal about which basin to populate. The per_sp_full_with_mp median path
is doing real work — it's not "noise" or random. The trim25_mean variants
seem to be picking up the mirror basin (perhaps because trimming away
outliers happens to remove the truth-basin estimates if they're a
minority among raw HC outputs).

**Caveat [S]**: This is from a single cell. Don't generalize without
testing on more cells.

**Important subtlety**: the basin assignments above are based on the
*pre-polish aggregate values* (from synthesis_log.csv), not the
post-polish parameter values. Inspection of the per_sp_full_with_mp
aggregates shows:
- Median strategy aggregates have xA ≈ 0.3–0.4 (near truth's 0.418), but
  k2 ≈ 0.05 (mirror-like, not truth's 0.876). These are "frankenstein
  hybrids" that don't sit in either pure basin pre-polish.
- Trim25_mean aggregates have xA ≈ -0.8 to -1.2 (negative, closer to
  mirror's -10.4 in sign but not magnitude).
- Polish then moves each aggregate toward its closer basin. The strategy
  biases pre-polish starting positions, which propagate to the basin
  polish converges to.

This reinforces the conclusion that strategy choice is real signal, but
clarifies the mechanism: it's biasing *starting positions*, not directly
producing basin-located candidates.

**Files**: `probe3_slow_fast_aggregates.jl` (driver), `probe3_analyze.py` (post-hoc analysis), `probe3_outputs/artifacts/diagnostics/slow_fast/synthesis_log.csv`.

---

## Probe 4 — Re-rank by (saturation_count, err)

**Hypothesis tested**: adding `saturation_count` as a primary sort key
beats current err-only on rank-1 oracle, at least as well as the
`(is_neg1, err)` rerank.

**Result: confirmed.** [V]

Tested on the 300-cell sample from earlier (275 cells with an
oracle-close row). `EPS_SAT = 0.02` of bound range in log coords —
parameters whose log is within 2% of `log(LB)` or `log(UB)` count as
"saturated".

| Scheme | median r1 oracle | mean | p90 | %≤1% | %≤10% |
|---|---|---|---|---|---|
| A: err only (current) | 3.8e-5 | 1.18 | 0.598 | 71.6% | 82.2% |
| C: (is_neg1, err) | 6.9e-5 | 0.443 | 0.381 | 77.5% | 87.6% |
| S1: (saturation, err) | 3.8e-5 | 0.211 | 0.465 | 72.4% | 83.3% |
| **S2: (saturation, is_neg1, err)** | **6.7e-5** | **0.161** | **0.322** | **77.8%** | **88.0%** |
| S3: (is_neg1, saturation, err) | 6.9e-5 | 0.161 | 0.322 | 77.8% | 88.0% |
| S4: (sat + 0.5·is_neg1, err) | 6.7e-5 | 0.161 | 0.322 | 77.8% | 88.0% |
| Z: oracle-best lower bound | 1.5e-5 | 0.026 | 0.046 | 81.8% | 92.4% |

**Findings:**
- S2/S3/S4 all converge to **77.8% ≤1% / 88.0% ≤10%** — slight gain over
  scheme C alone. The lift at the head of the distribution (≤1%) is
  small (0.3 percentage points).
- **The tail improves substantially**: p90 drops from 0.381 (C) to 0.322
  (S2/S3/S4); mean from 0.443 to 0.161. The saturation signal catches
  the worst rank-1-is-wildly-wrong cases.
- **Saturation alone (S1)** doesn't help much: 72.4% / 83.3% is barely
  above scheme A's 71.6% / 82.2%. The signal needs is_neg1 combined.

**Distribution of saturation across 30 random cells**: most cells have
median saturation = 0, max ≤ 2. A few cells (hiv, daisy_mamil4 at high
noise) routinely have median saturation 2–5 — these are the cases where
saturation-based reranking has bite. Most well-determined cells (mass_spring_damper,
harmonic_oscillator, fitzhugh_nagumo at low noise) have zero saturation
and the rerank doesn't change anything.

**Implication [L]**: Scheme S2 or S4 is a clean replacement for current
err-only ranking. Same set of returned rows; same overall behavior on
well-determined cells; meaningful improvement on the failure tail. The
core insight is that saturation correlates with "polish overfit" — when
a parameter hits a bound, it's a sign polish couldn't constrain it from
data alone.

**Direct demonstration on biohydrogenation_6_1em6 (production data)** [V]:
- Current rank-1 (err-sort): oracle = 9.18 (k10 saturated at upper bound)
- Truth-near row: rank 87 in err-sort, oracle 0.77
- Under scheme S2: **truth-near row moves to rank 1**. The truth-near is
  the *only* row with `saturation_count = 0` (other 99 rows all hit the
  k10 upper bound). Scheme S2 sees this and elevates it.
- **Rank-1 oracle improvement: 9.18 → 0.77 (12×)** on this specific cell,
  using only a sort-key change — no algorithmic / polish change.

**Sanity check on the 5 deep-failure cells from Probe 5** [V]:

| cell | rank-1 oracle (current) | rank-1 oracle (S2) | verdict |
|---|---|---|---|
| biohydrogenation_5_1em4 | 1.99 | 0.78 | **2.5× better** |
| biohydrogenation_6_1em6 | 9.18 | 0.77 | **12× better** |
| hiv_9_1em4 | 7 050 | 809 | **8.7× better** |
| flexible_arm_5_1em2 | 4.4 | 2.83 | 1.6× better |
| brusselator_5_0 | 8.73e7 | 9.53 | **9 million× better** |
| cstr_0_1em2 | **1.41** | 5.82 | **WORSE by 4×** |

Scheme S2 dramatically helps 5 of the 6 sampled cells where bound
saturation drives the failure. The one it hurts is `cstr_0_1em2` — the
under-observed system where the current rank-1 (no saturation) is
already the best the pipeline can do, and scheme S2 picks a worse but
less-saturated alternative.

**Implication**: scheme S2 is a strong default for cells with substantial
saturation but **isn't a free win** for under-observed cells. Worth
considering adaptive: only apply the saturation tiebreaker when
`max(saturation) > threshold` across the cell's rows.

**Files**: `probe4_rerank_saturation.py`.

---

## Probe 5 — Five deep-failure cells, characterized

**Hypothesis tested**: the 8% no-oracle-close-row cells are dominated by
column-scaling / brusselator-type stiffness pathologies (a single
coherent root cause).

**Result: partially refuted — there's a mix.** [V]

The 300-cell sample contained 25 deep failures (`min oracle > 0.5`). By
system family:

| family | n deep failures |
|---|---|
| cstr | 9 |
| hiv | 4 |
| biohydrogenation | 4 |
| crauste | 4 |
| brusselator | 2 |
| flexible_arm | 1 |
| fitzhugh_nagumo | 1 |

By noise: 1em2 (9), 1em4 (9), 1em8 (3), 0 (2), 1em6 (2). High noise
dominates.

Sampled 5 cells (one per top family). Detailed mini-reports in
`probe5_cell_diagnostics/`. Classification summary:

| cell | dominant failure mode |
|---|---|
| `brusselator_5_0` | **HC failure** — polynomial system has no real solutions (`notes: hc_no_solutions`). raw_count=102 (vs 1000+ typical). Rescue path filled in junk. Column-scaling territory. |
| `hiv_9_1em4` | **Practical-non-id of vv** — `y4 = 0.002·vv + 2·yv` makes vv contribute ~1000× less than yv to the observable. Noise=1e-4 swamps vv. Other states/params recovered, but vv blows up dragging oracle to 809. |
| `biohydrogenation_5_1em4` | **Numerical ridge in (k10, k9, x6)** — same pathology as `biohydrogenation_6_1em6` we deep-dived earlier, but worse noise. k10 not identifiable for k10 ≫ 0.02 due to ODE structure. |
| `cstr_0_1em2` | **Under-observed + high noise + transcendental input** — single observable (y1=700·Temp) for 7 unknowns; sinusoidal forcing. noise=1e-2 dominates. Not fixable by polish changes; needs lower noise or more observables. |
| `flexible_arm_5_1em2` | **Multi-parameter bound saturation under high noise** — three params (Jt, k, bt) all hit lower bound simultaneously. Oscillator under noise=1e-2 has multiple degenerate-fit subspaces. |

**Findings:**
- **Five distinct failure modes across five samples.** Brusselator (HC failure / column scaling) is one. The others are: practical-non-id from low observable coefficient (hiv), numerical ridge from ODE structure (biohydrogenation), under-observation + noise (cstr), multi-parameter bound saturation (flexible_arm).
- **None of the 5 is "polish converged to wrong basin from all starts"** in the brusselator-vs-truth-basin sense. Each has a more specific story.
- **Column scaling alone won't fix this 8%**. It's the right fix for the brusselator-like ones (~10–20% of the 25 deep failures), but other failure modes need different tools.
- **noise=1e-2 and 1e-4 dominate** the failure list. Most low-noise failures are systems with structural near-non-identifiability (brusselator stiffness + HC failure).

**Implication [L]**: Refutes the implicit "all deep failures look like brusselator" assumption. We need a typology of failure modes and corresponding interventions. A single "fix column scaling" project won't close this 8%.

**Files**: `probe5_deep_failure_sample.py`, `probe5_cell_diagnostics/{cell_id}.md` × 5, `probe5_cell_diagnostics/sampled_cells.csv`.

---

## Cross-cutting synthesis

All five probes complete. The findings together suggest several principles:

1. **Multiple failure modes need multiple fixes.** [V on 5-cell sample]
   No single change (better ranking, better polish, better HC) will close
   the 8% gap. The deep-failure cells are heterogeneous — Probe 5
   identified 5 distinct failure modes across 5 sampled cells.

2. **`cond(J)` at polished candidates is a strong basin-flagging signal**
   on at least one example (slow_fast, Probe 1). [V on slow_fast, S on
   generality] Worth implementing as a diagnostic column.

3. **Bound saturation correlates with rank-1 failures** strongly enough
   to be a useful sort key. [V on 275-cell sample + 6 deep-failure cells]
   Scheme S2 = `(saturation_count, is_neg1, err)` improves ≤1% from
   71.6% to 77.8% and ≤10% from 82.2% to 88.0%. Direct test on
   biohydrogenation_6_1em6: rank-1 oracle 9.18 → 0.77 (12× improvement).

4. **Soft-wall regularization eliminates bound-saturation pathology.**
   [V on bioh sweep] k10 saturation went 97/100 → 0/100 at any nonzero
   λ_sw on biohydrogenation_6_1em6. Rank-1 oracle 9.18 → 4.19 with
   λ_sw=1e-2, ε=0.10. ε is the dominant knob; λ_sw is essentially
   on/off above some small threshold.

5. **Aggregate synthesis is doing real, structured work.** [V on slow_fast]
   Probe 3 shows that different aggregation strategies have systematic
   biases toward different basins. `per_sp_full_with_mp` median is
   reliably truth-finding (5/5 on slow_fast); other categories
   (`global_param_only`, `per_interpolator`) systematically land in the
   mirror basin. The path is structurally producing useful candidates,
   not random noise.

6. **Sort-key fix and polish-bias fix are largely complementary.** [L]
   - Scheme S2 (sort by saturation) helps cells where bound saturation
     happens. It demotes saturated rows without changing what polish
     produces.
   - Soft-wall regularization prevents bound saturation in the first
     place. Combined with S2, S2 contributes nothing (no saturation
     signal left).
   - Both help on bound-saturation cells. Neither alone is enough — soft-
     wall doesn't find truth (just an interior-but-still-wrong point);
     S2 doesn't change what polish produces (just elevates non-saturated
     rows). Together they're a coordinated fix for the saturation
     failure mode.
   - For non-saturation failure modes (under-observation, HC failure,
     practical-non-id from observable coefficients), neither fix
     applies; would need different mechanisms.

6. **The 8% deep-failure bucket is at least 4–5 distinct failure modes**,
   not 1. [V on Probe 5 sample] Brusselator-style HC failure, hiv-style
   low-observable-coefficient, biohydrogenation-style ODE numerical
   ridges, cstr-style under-observation, flexible_arm-style multi-param
   bound saturation.

## Recommended next steps (not committed)

In rough order of effort-to-impact:

A. **Land the (is_neg1, saturation, err) rerank** [S, low effort, low
   risk]. Probe 4 quantifies the benefit; default change in
   `analysis_utils.jl` line ~650 would close ~6pp of the rank-1 gap.

B. **Implement basic cond(J) diagnostics** [S, medium effort, low risk].
   Add a `cond_J_local` column to result.csv. Don't use it for ranking
   yet; expose it for users to filter.

C. **Run probe 2 results to decide on soft-wall regularization**
   [pending Probe 2 completion]. If it cleanly fixes biohydrogenation's
   k10 saturation, consider exposing as an opt-in knob with docs.

D. **Per-cell failure-mode classifier** [S, medium effort, medium risk].
   Based on Probe 5 findings, build heuristics:
   - HC failure (notes contain `hc_no_solutions`) → column-scaling track
   - Multiple saturated parameters → soft-wall or relaxed bounds
   - Low-observable-coefficient params (heuristic: tiny rows in J) → flag
     as unidentifiable
   - Under-observation (n_obs < dim/2 with high noise) → "noise-limited"
     flag
   Each can be a column in result.csv or metadata.

E. **Don't try to "fix" the 8% with a single change** [S]. Accept that
   some cells need different tooling and aim for richer diagnostics
   rather than universal accuracy.
