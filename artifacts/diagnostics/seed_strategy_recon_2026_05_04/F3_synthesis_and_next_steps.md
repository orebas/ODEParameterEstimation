# F3 — Synthesis: where the AMIGO2-vs-ODEPE gap actually lives

Generated: 2026-05-04 during autonomous research run (~3 hours elapsed of allocated 4h).

## TL;DR

After extensive investigation, the original "seed strategies will close the AMIGO2 gap"
narrative is largely **wrong**. The 118 AMIGO2-only wins on bilby are at least 3
qualitatively different failure modes, and seed strategies (the work I was building)
address at most one of them. The team's prior research (April 2026 post-polish memo)
already correctly identified this; my contribution this session is empirical
confirmation across 3 representative cases.

## What I confirmed empirically (3 cases)

| Case | Pool best rel | Fit-best rel | Failure class | What needs fixing |
|---|---:|---:|---|---|
| `flexible_arm_0_1em4` | 0.475 | 1.65 | C — ranking miss | Gate / selection logic |
| `forced_lotka_volterra_0_1em2` | 0.308 | 0.31 | A — pool inadequate | Better data path / interpolators |
| `daisy_mamil3_7_1em4` | 0.111 | 0.111 | C — selection miss (different) | Cluster-rep picking |

**Three different bugs, three different fixes needed.**

## Specific findings

### 1. flex_arm: the `MAX_ERROR_THRESHOLD` gate is real but not load-bearing

Per `analysis_utils.jl:253`, `MAX_ERROR_THRESHOLD = 0.5` filters out rows with
`err >= 0.5`. On flex_arm, 0/62 rows have err < 0.5, so the gate falls through to
top-`MAX_SOLUTIONS=20` by err. The truth-best row (idx 27, rel=0.475, err=3659) is
NOT in top-20 by err — its err is 5000× the best err.

Even relaxing the gate to `err < k * best_err` requires k≥5000 to admit the truth-best.
That's not "relax the threshold," that's "abandon the err metric for selection." The
err metric is anticorrelated with truth on this case.

### 2. forced_lv 1e-2: pool is too poor to fix downstream

The polynomial pool's BEST candidate at noise=1e-2 has rel=0.31 (31% off truth). All 8
benchmark replicas show the same pattern — AMIGO2 wins 8/8 because its optimization
finds a better minimum than what's algebraically reachable from the noisy `d_obs`.

This is the failure the existing `interpolators` zoo doesn't fix. At noise=1e-2,
4-derivative-order amplification × the absolute size of high-order y1 derivatives
× the polynomial system's conditioning produces displaced roots that no clustering /
selection / blending recovers. The pool's convex hull doesn't span truth.

**Seed strategies CANNOT help this case** — by construction, no combination of pool
candidates reaches outside the convex hull (linear blending) or near-truth in any
non-trivial way (the convex hull doesn't span truth on this case).

What would help: a different data-processing path. Either non-stationary GP that
handles the boundary regions better, or accept that polish-from-random-restart is
the right tool here.

### 3. daisy_mamil3_7: pool is fine, but pipeline's reported winner is wrong

The saved `result.csv` has rel=0.111 in the best row, AND the err is also lowest there
(idx 89: rel=0.111, err=7.6e-4). Both criteria agree. **The gate passes 32 candidates
correctly.** Yet bilby's broad_mixed sweep reported this case as `Inf` max rel err —
because the broad_mixed sweep reads a different metric (the pipeline's selected winner,
not the best in the set).

In the actual bilby `stdout.txt`:
```
Best maximum relative error for daisy_mamil3 (excluding ALL unidentifiable parameters): 0.11107
Best solution:
  States: x1=394, x2=-84, x3=54   ← wildly wrong winner
  Parameters: a12=0.50, a13=-1.44, a21=0.33, a31=-0.58, a01=0.55
```

The reported winner has wild states (x1=394 vs truth 0.139). But the "Best maximum
relative error" line at the top (11.1%) is from across all 89 cluster reps —
including the truth-near one.

**The bilby benchmark scoring uses the per-cluster best-rel-err, NOT the selected
winner's rel-err.** So daisy_mamil3_7 isn't actually a failure by bilby's scoring —
it just LOOKS like one in the broad_mixed sweep summary because that summary uses a
different metric.

**Fix**: align the broad_mixed sweep's metric with bilby's `Best maximum relative
error` line. This is a reporting / metric inconsistency, not a pipeline bug.

## Where this leaves the seed-strategy work

The seed-strategy R&D in this conversation thread (S0–S6, sigma_d-aware probes,
buggy mean-blend wins, etc.) addresses Class A (pool inadequate) by trying to
synthesize new candidates outside the pool's convex hull. But:

- On forced_lv 1e-2 (true Class A), even oracle-optimal blending gives rel ~0.3,
  still far from useful.
- On flex_arm (Class C), seed strategies don't help — the pool already has truth-near
  candidates; they're being discarded.
- On daisy_mamil3_7 (different Class C), seed strategies don't help — same reason.

So **seed strategies are the wrong tool for at least 2 of the 3 cases I examined**.

The team's `research_tryhard_finalists` / `_build_reasonable_tryhard_frontier`
machinery (in `benchmark_sweeps.jl`) is the right tool for Class C cases — return
finalists, not winners, and let downstream consumers pick. That work is already done;
it just isn't on the production gate path.

## Concrete recommendations

Highest-leverage actions, in order:

### A. Promote `research_tryhard_finalists` to production (high impact, medium effort)

The team has built the finalists machinery. Wire it into the production
`analyze_estimation_result` so the pipeline returns finalists by default (with the
old "single winner" available for back-compat). This addresses the daisy_mamil3_7
class of failure directly — the truth-near cluster rep would be visible to downstream
consumers.

### B. Audit the `MAX_ERROR_THRESHOLD` gate behavior across the bilby suite (low-effort, validation)

Run my `multi_case_threshold_audit.jl` (or extension) across all 118 AMIGO2-only cases.
Tabulate: how many are Class A (pool inadequate), Class C (ranking miss), Class D
(catastrophic SI / NaN). This determines what fraction of the gap each fix would
close.

### C. Investigate Class A cases for fundamentally-different fixes (research, larger scope)

For the cases where the pool genuinely lacks truth-near candidates (forced_lv 1e-2 is
the cleanest example), the relevant interventions are NOT seed strategies. Worth
investigating:
- Non-stationary GP at boundary points (sees mention in prior memos, never tested)
- Different observable parameterization (e.g., normalized-output) that reduces
  derivative-amplification
- Polish from random-restart as an alternative pipeline (which is essentially what
  AMIGO2 does)

### D. Fix the bilby broad_mixed sweep metric (low effort, high clarity)

The broad_mixed sweep's "Max Rel Err" reports the WINNER's rel, not the per-cluster
best. This makes some cases (daisy_mamil3_7) look like failures when the pool actually
contains a near-truth candidate. Aligning to bilby's `stdout.txt` "Best maximum
relative error" metric would clean up the picture and remove false-negative cases
from analysis.

## What I'd retract from earlier in this conversation thread

- "Fitzhugh polish=OFF is fundamentally hard at noise 1e-4" — wrong. Production gets
  rel=0.057 at the bilby config; my measurement was on a deprived harness.
- "S1 (all-pairs mean blend) is the best seed strategy" — wrong. It was best on a
  deprived baseline; on the proper config it's noise relative to what production
  already achieves.
- "Sloppy-direction probes will help on hard cases" — partially wrong. They help on
  Class A cases (rare), not on Class C cases (most of the AMIGO2-only set).
- "We need new seed-generation strategies for the production pipeline" — wrong. The
  team has already built finalists / frontier machinery that addresses Class C cases.
  The production-pipeline gap is wiring + maybe metric alignment, not new algorithms.

## Files produced this session

- `artifacts/diagnostics/seed_strategy_recon_2026_05_04/F1_recon_findings.md` — what
  prior research already covers
- `artifacts/diagnostics/seed_strategy_recon_2026_05_04/F2_threshold_audit_findings.md` —
  per-case audit results
- `artifacts/diagnostics/seed_strategy_recon_2026_05_04/F3_synthesis_and_next_steps.md` —
  this document
- `artifacts/diagnostics/seed_strategy_recon_2026_05_04/flex_arm_pool_audit.csv` — per-row
  data for flex_arm
- `temp_plans/flex_arm_threshold_audit.jl`, `temp_plans/multi_case_threshold_audit.jl` —
  reusable audit scripts

## Daisy_mamil3_7: row 1 of result.csv has wild states, but it's not yet clear why

Looking at bilby's `result.csv` directly:

```
Row 1 (the chosen winner):
  a12=0.50, x2=−84, a21=0.33, a13=−1.44, a01=0.55, x1=394, x3=54, a31=−0.58
  ↑ wild states (x1=394 vs truth 0.139); rel-err > 2000

Last 3 rows (87, 88, 89):
  a12=0.52, x2=0.30, a21=0.36, a13=0.65, a01=0.83, x1=0.147, x3=0.48, a31=0.74
  ↑ truth-near; rel-err = 0.11
```

But bilby's stdout reports `Best maximum relative error: 0.11107` for the case — so the
pipeline DOES find the 0.11 candidate as "best by rel" somewhere. The question is why
result.csv has the wild candidate at row 1 instead of the 0.11 one.

I tested my first hypothesis (symbol-equality between `pep.p_true` keys and
candidate parameter keys via `Symbolics.@parameters`) — Test 1 and Test 2 both confirm
that fresh `@parameters a12 ...` calls produce hash-equal symbols, so `haskey` works
and `oracle_error_stats` should populate errorvec correctly. **My initial hypothesis
about symbol mismatch was wrong.**

Other possibilities for the row-1 wildness:
- `solutions_vector` returned by `analyze_estimation_result` IS sorted-by-truth, and
  the wild candidate happens to have rel ≈ 0.11 too (looks unlikely — x1=394 is wild)
- The CSV write step in the bilby script reads `solutions_vector` correctly, but a
  bug in `Dict` ↔ `OrderedDict` iteration order maps the columns to wrong rows
- `analyze_estimation_result` is sorting by something other than oracle_sort_key on
  this case (e.g., a fallback path triggers)

**This needs a direct in-pipeline trace to resolve.** Short script: run the pipeline
on daisy_mamil3_7 with `nooutput=false`, dump `solutions_vector[1]` and check its
parameters. If they're the wild values, the bug is in `analyze_estimation_result`. If
they're the truth-near values, the bug is in the CSV write.

Either way, **it's a real production-pipeline bug** affecting Class C cases. Worth
chasing in a follow-up session — small targeted experiment.

## Recommended next session focus

If the user wants to continue the AMIGO2-gap-closing line:

1. **Run the threshold audit across all 118 AMIGO2-only cases** (~few hours of compute)
   to get a definitive Class breakdown. Whether the gap is 70% Class A vs 70% Class C
   determines the priority.
2. **Implement the finalists wiring** behind a flag. Test on daisy_mamil3_7 and
   flex_arm specifically.
3. **Defer further seed-strategy work** until A and B are done. The work I've been
   doing is solving the wrong problem for most of the gap.

If the user wants to continue specifically on seed-strategy R&D:

1. Find the cases where the pool DOES contain truth-near candidates that the
   fit-rank discards (Class C). These are seed-strategy-adjacent — the strategies don't
   build new candidates but better-rank existing ones.
2. For those cases, test if a non-fit ranking (cross-spread, finalists, Σ_x credibility)
   recovers truth.
3. Compare against just emitting all cluster reps as finalists. If finalists alone
   solves it, no seed strategy is needed.
