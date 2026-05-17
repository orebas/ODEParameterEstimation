# Session synthesis: 2026-05-15 to 2026-05-17

End-to-end record of the fresh-look investigation, production changes,
empirical validation, and the negative results that closed off several
candidate directions.

---

## Production changes shipped

All changes are default-on, backward-compatible (option flags exist to
revert), and pass `fast_core.jl` (258/258) + `feature_regressions.jl`
(133/133).

| Change | Files | Default flipped |
|---|---|---|
| **Soft-wall regularization** in polish residual | `src/types/estimation_options.jl`, `src/core/parameter_estimation.jl`, `src/core/polish_residual.jl` | `polish_softwall_lambda = 1e-2`, `polish_softwall_epsilon = 0.10` (was 0.0) |
| **Scheme S2 rank strategy** at result.csv output | `src/types/estimation_options.jl`, `src/core/analysis_utils.jl` | `rank_strategy = :sat_neg1_err` (was implicit err-only) |
| **Identifiable-subspace clustering** at output dedup | `src/types/estimation_options.jl`, `src/core/analysis_utils.jl` | `cluster_method = :identifiable_subspace` (was 1e-5 bit-identical) |
| **`branch_top_k`** capped at output stage | `src/types/estimation_options.jl` | `branch_top_k = 20` (was 100; was 20 pre-2026-05-14) |

Additional experimental option exposed but not default-on:
`rank_strategy = :lognorm_err` / `:lognorm_neg1_err` — see "lognorm
investigation" below for why these were not promoted.

---

## Investigation timeline

### Phase 1 — fresh-look probes (2026-05-15)

Five validation probes on the 2026-05-14 numbat benchmark to characterize
ranking failure modes. Full record in
[`RECOMMENDATIONS.md`](RECOMMENDATIONS.md) and
[`probes/PROBE_RESULTS.md`](probes/PROBE_RESULTS.md).

Headline findings:
- **92%** of benchmark cells contain a truth-near row somewhere in result.csv
- The pipeline is mostly *finding* truth; mostly *not ranking* it visibly
- 5 distinct failure modes among the 8% deep-failures (column scaling, low
  observable coefficient, numerical ridge, under-observed+high-noise,
  multi-bound saturation) — refutes a single-root-cause hypothesis

### Phase 2 — defaults flipped + spot-checks (2026-05-16)

Soft-wall, S2, and identifiable-subspace clustering implemented as defaults.

Live spot-checks (`spot_checks_2026_05_16/`):
- **slow_fast_6_1em4**: 504 candidates → 100 reps; truth and mirror basins
  both preserved; rank-1 oracle 0.29% (truth basin, branch_size=172
  cluster). Identifiable-subspace clustering working as designed; the 5%
  within-basin threshold is too tight for the 6-31% practical-non-id
  spread so 38 singletons survive in the tail (does not affect rank-1).
- **biohydrogenation_6_1em6**: k10 saturation eliminated (legacy 18/20
  rows at upper bound → 0/100 today). But the polish settles at a
  **numerical-ridge minimum at k10≈5** for 76 rows or k10≈0.1-0.5 for 22
  rows; truth k10=0.818 is in the gap between basins. Best oracle in
  result.csv: 86.6% at rank 86. The investigation framing turned out to
  be: soft-wall fixes the symptom (bound saturation) but not the cause
  (genuine practical non-identifiability of k10 at this noise level).

### Phase 3 — column-scaling investigation (2026-05-16)

Hypothesis prompted by [`docs/2026-05-01_variable_scaling_investigation.md`](../../docs/2026-05-01_variable_scaling_investigation.md):
biohydrogenation's k10 ridge is downstream of poor column conditioning
(cond(J) = 4.5e10 reported in that doc).

Diagnostic prototype (`column_scaling_2026_05_16/`):

| System | cond(J) raw | cond(J·D_colnorm) | Improvement |
|---|---|---|---|
| biohydrogenation | 1.44 × 10⁹ | 6.81 × 10⁵ | **2114×** |
| daisy_mamil4 | 1.65 × 10⁶ | 1.13 × 10⁶ | 1.5× |
| crauste | 3.67 × 10⁸¹ | rank-deficient | — |

Bauer-Skeel column-norm scaling drops bioh cond by 2114×. Looked
promising. **But the level-0 prototype** (script-level substitution of
scaled parameters, no source changes) showed:
- Truth-magnitude scaling: ~5× cond reduction, **no change** in rank-1
  oracle. k10 still lands at 5.012.
- Column-norm scaling (would give 2114×): **crashes SI** with
  `"The new subfield generators are not correct"` — the small rational
  scales (9e-4) blow up `RationalFunctionFields.simplified_generating_set`.

**Hypothesis refuted on bioh.** The cond(J) was measuring practical
non-identifiability as much as column imbalance; coordinate transforms
can't add information the data doesn't contain. The diagnostic remains
useful as a *failure-mode classifier* (distinguish imbalance from
near-null from rank-deficiency) but the implementation isn't warranted.
See [`column_scaling_2026_05_16/PROTOTYPE_FINDINGS.md`](column_scaling_2026_05_16/PROTOTYPE_FINDINGS.md).

### Phase 4 — lognorm reranking investigation (2026-05-17)

Motivated by S2's hard dependency on user-provided `opt_lb`/`opt_ub`
(silent degradation when bounds missing). Proposal: post-hoc sort by
`Σ(log₁₀ p)²` — bound-free, symmetric to upper- and lower-bound
saturation, post-hoc analog of `polish_regularization_lambda` toward x=1
in log-coords.

Implemented as `:lognorm_err` and `:lognorm_neg1_err` (experimental
options; default unchanged). Offline reranker `probes/probe4b_rerank_lognorm.py`:

| Scheme | %≤1% | %≤10% | p90 |
|---|---|---|---|
| err_only | 71.6% | 82.2% | 0.598 |
| C: (is_neg1, err) | 77.5% | 87.6% | 0.381 |
| **S2 (default)** | **77.8%** | **88.0%** | **0.322** |
| **lognorm_err** | **22.5%** | **43.3%** | 1.19 |
| **lognorm_neg1_err** | **22.5%** | **43.3%** | 1.19 |

Lognorm loses to S2 in 237/275 cells. **Why it fails:** truth values
genuinely far from 1 (slow_fast k1=0.104, bioh k7=0.107, daisy_mamil4
k01=0.125) carry ~0.9 log² penalty on the truth row itself; when the
polish also produces a row with parameters incidentally closer to 1 that
fits the data adequately, lognorm picks the closer-to-1 row over truth.
The bias is systematic, not a tiebreaker. **Don't ship as default.**
Full writeup in [`probes/probe4b_results.md`](probes/probe4b_results.md).

### Phase 5 — full-benchmark K-recall analysis (2026-05-17)

Walked all 1136 cells of the 2026-05-14 numbat benchmark to characterize
S2 vs err_only and the K-recall ceiling. Output in
[`probes/probe4c_results.md`](probes/probe4c_results.md).

**Full-benchmark numbers (S2 sort on existing 14-era result.csvs):**

| K | err_only %≤10% | S2 %≤10% | Δ vs ceiling |
|---|---|---|---|
| 1 | 73.4% | 78.9% | -4.6pp |
| 5 | 78.6% | 82.5% | -1.0pp |
| 10 | 79.8% | 83.0% | -0.5pp |
| **20** | 81.1% | **83.5%** | **0.0pp** |
| 100 | 83.5% | 83.5% | 0.0pp |
| **ceiling** | — | — | **83.5%** |

**At ≤1%:** same shape; S2 ceiling at K=100 is 74.1%, K=20 hits 73.6%
(99.3% of ceiling).

**Required K distribution:** bimodal — 78.9% of cells at K=1, 16.5%
"never reach truth-near," near-nothing in between. **The 17% deep-failure
pool is the real ceiling**, separate from ranking.

Key insight: **`branch_top_k = 100` was over-allocated by 5×**. K=20 is
the natural ceiling under S2. Hence the K=100 → K=20 change in this
session.

### Phase 6 — 06 vs 14 apples-to-apples ceiling (2026-05-17)

User question: did 14-era clustering/capping lose ceiling vs the 06
benchmark (which returned ~378 rows median per cell)?

Output in [`probes/probe4d_results.md`](probes/probe4d_results.md):

| Threshold | 06 ceiling | 14 ceiling | Δ |
|---|---|---|---|
| ≤1% | 77.1% | 74.4% | **-2.7pp** |
| ≤10% | 85.1% | 83.9% | **-1.2pp** |
| ≤50% | 92.5% | 90.1% | -2.4pp |

So 13/14 clustering+capping cost ~1-3pp of ceiling vs 06. Concentrated
on seir (-14pp), lotka_volterra (-8pp), brusselator, sirt_treatment.
Crauste *improved* +7pp under the 14 pipeline.

Investigation of lost cells: all 18 lost cells (06 ≤10%, 14 >10%) were
**at the 100-row cap** in 14. But the truth-near row from 06 was *not
just below the cap* — it was absent from 14's set entirely (parameter
distance to closest 14 row: 17-65% per axis). So the rows were dropped
upstream of the cap (pre-polish clustering, different polish algorithm,
or never generated by 14's HC.jl + multipoint flow).

### Phase 7 — 8-cell recheck under current code (2026-05-17)

8 lost cells (stratified across seir, lotka_volterra, brusselator, cstr,
biohydrogenation, sirt_treatment) re-run via local slurm with current
defaults (soft-wall + S2 + identifiable-subspace clustering). Output in
[`06_lost_recheck/`](../06_lost_recheck/).

**Result: 8/8 ceiling recovered at ≤10%. 5 of 8 have NEW ceiling
matching 06 to 4+ decimal places** (literally the same row reappeared).
1 of 8 (sirt_treatment) is *better* than 06. **6 of 8 even have the
truth-near row at rank 1** under current pipeline.

| Cell | 06 ceil | 14 ceil | NEW ceil | NEW rank-1 |
|---|---|---|---|---|
| seir_2_1em4 | 0.0438 | 0.130 | 0.0438 | 0.0438 ✓ |
| seir_8_1em6 | 0.0152 | 0.136 | 0.0721 | 0.0721 ✓ |
| lotka_volterra_1_1em2 | 0.0014 | 0.200 | 0.0014 | 0.0014 ✓ |
| lotka_volterra_2_1em2 | 0.0022 | 0.102 | 0.0022 | 0.0022 ✓ |
| brusselator_3_1em2 | 0.0202 | 0.117 | 0.0202 | 0.0202 ✓ |
| cstr_6_1em8 | 0.0093 | 0.252 | 0.0456 | 274.9 (in tail) |
| biohydrogenation_2_1em6 | 0.0794 | 0.595 | 0.0794 | 4.27 (in tail) |
| sirt_treatment_5_1em2 | 0.0940 | 0.144 | 0.0664 | 0.0940 ✓ |

**Conclusion:** the 1.2pp ceiling loss from 06 → 14 was an artifact of
the 14-era pipeline, not a fundamental clustering problem. Current code
recovers the candidates that 14 was losing. The 2 cells where rank-1
isn't truth-near (cstr, bioh) are the practical-non-id / numerical-ridge
failures we already characterized — separate problems.

---

## What's still open

| Issue | Status |
|---|---|
| **Practical non-identifiability** (bioh k10, cstr 1-obs systems) | Soft-wall doesn't fix; column scaling doesn't fix. Real cells where the data genuinely permits multiple solutions at this noise level. Diagnose() classifies these correctly via cross-solution spread. Open: should the pipeline accept this and report rather than try to find truth? |
| **Full-benchmark validation of session's changes** | Pending. Recommend 200-cell stratified polish-only sample (~12-24h on local 24-core node) as first move, then full polish sweep (~3 days) if needed. |
| **Nopolish behavior** | Untested this session. Soft-wall doesn't affect nopolish, but S2 and clustering do. Could go either way. |
| **`subspace_cluster_eps` too tight on slow_fast** (38 singletons in tail) | Cosmetic; doesn't change rank-1 outcome. Defer. |
| **daisy_mamil4 uniformly weak** (27-44% across all noise) | Not noise-specific; suggests structural SI/HC.jl issue. Worth separate investigation. |
| **crauste rank-deficient** (5/43 zero-norm columns) | Different from imbalance — needs Level C from the column-scaling doc (reformulate algebraic problem) or a pre-pass that drops zero-norm columns. |

---

## Repository layout

```
repro/oren_freshlook_2026_05_15/
├── BIOH_AND_REGULARIZATION_MEDITATION.md   # Phase 1 thinking
├── FRESH_DIAGNOSIS.md
├── INVESTIGATION_LOG.md
├── PIPELINE_MAP.md
├── PIPELINE_NOTES.md
├── RECOMMENDATIONS.md                       # Phase 1 deliverable
├── SESSION_2026_05_15_TO_17_SYNTHESIS.md   # this file
├── analyze_ranking.py
├── rerank_test.py
├── slow_fast_mirror_proof.py
├── probes/
│   ├── PROBE_RESULTS.md                     # Phase 1 probes 1-5
│   ├── probe1_cond_J_slow_fast.py
│   ├── probe1_results.csv
│   ├── probe2_softwall_bioh.jl              # → led to soft-wall default flip
│   ├── probe2_source_diff_summary.md
│   ├── probe2_outputs/
│   ├── probe3_analyze.py
│   ├── probe3_slow_fast_aggregates.jl
│   ├── probe3_outputs/
│   ├── probe4_rerank_saturation.py          # original 300-cell S2 evidence
│   ├── probe4b_rerank_lognorm.py            # Phase 4 — lognorm refuted
│   ├── probe4b_results.md
│   ├── probe4b_per_cell.csv
│   ├── probe4c_full_benchmark.py            # Phase 5 — 1136-cell K-recall
│   ├── probe4c_results.md
│   ├── probe4c_per_cell.csv
│   ├── probe4d_06_vs_14_ceiling.py          # Phase 6 — apples-to-apples
│   ├── probe4d_results.md
│   ├── probe4d_per_cell.csv
│   ├── probe5_deep_failure_sample.py
│   └── probe5_cell_diagnostics/             # 5 mini-reports
├── spot_checks_2026_05_16/
│   ├── SPOT_CHECK_SUMMARY.md                # Phase 2
│   ├── biohydrogenation_6_1em6/             # — k10 saturation eliminated
│   └── slow_fast_6_1em4/                    # — basins preserved, rank-1 0.29%

repro/column_scaling_2026_05_16/
├── PROTOTYPE_FINDINGS.md                    # Phase 3 — falsified
├── diagnose_column_scaling.jl
├── column_scaling_results.csv
├── {biohydrogenation,daisy_mamil4,crauste}_noise_*.txt
└── level0_bioh/                             # falsifying level-0 prototype
    ├── script_scaled.jl
    ├── result_truth.csv
    ├── run_truth.log
    └── run_colnorm.log                      # SI crash

repro/06_lost_recheck/                       # Phase 7 — 8/8 recovered
├── run_one_cell.s                           # local-slurm runner
├── seir_2_1em4/        ... etc (8 cells)
└── <jobid>_06_lost_recheck.{out,err}
```

---

## Reproducibility

All artifacts under `repro/` are read-only references to data in
`~/rsync-readonly-PEB/` (the benchmark archives). Tests:

```bash
# Smoke tests (~7 minutes total)
cd ~/.julia/dev/ODEParameterEstimation
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/fast_core.jl")'
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/feature_regressions.jl")'

# Offline probes (~1 minute each, Python)
cd repro/oren_freshlook_2026_05_15/probes
python3 probe4_rerank_saturation.py
python3 probe4b_rerank_lognorm.py
python3 probe4c_full_benchmark.py
python3 probe4d_06_vs_14_ceiling.py

# Live cell recheck (40-60 min per cell × 8 cells)
cd repro/06_lost_recheck
for c in seir_2_1em4 seir_8_1em6 lotka_volterra_1_1em2 lotka_volterra_2_1em2 \
         brusselator_3_1em2 cstr_6_1em8 biohydrogenation_2_1em6 sirt_treatment_5_1em2; do
  sbatch run_one_cell.s "$(pwd)/$c"
done
```
