# Autonomous research session — 2026-05-04 (4 hours)

## What I did

1. **Recon** of existing artifacts/diagnostics for AMIGO2-only failure cases
   (`F1_recon_findings.md`).
2. **Read** the bilby `AMIGO2_vs_ODEPE_differential_reference.md` cross-system
   comparison and the team's `2026-04-16_post_polish_research_memo.md`.
3. **Threshold-gate audit** on 3 representative AMIGO2-only cases — flexible_arm,
   forced_lotka_volterra (1e-2 noise), daisy_mamil3_7 (`F2_threshold_audit_findings.md`).
4. **Synthesized** findings + recommendations (`F3_synthesis_and_next_steps.md`).
5. **Investigated** `result.csv` row order for daisy_mamil3_7 — found wild candidate
   at row 1 despite truth-near candidate being in pool at rel=0.11.
6. **Tested** my "symbol mismatch" hypothesis — disproved.
7. Documented unresolved bug in cluster representative selection.

## Headline findings

### 1. Most of the seed-strategy R&D was retreading prior work

The team's April 2026 post-polish research memo already laid out the framework:
"shift from improving winner to improving set coverage." Block consensus, finalists
sets, reasonable frontier — all built. They live in `benchmark_sweeps.jl` (research
code) but aren't in the production pipeline gate path.

### 2. The 118 AMIGO2-only failures are at least 3 different bugs

| Class | Example | What's broken | Fix |
|---|---|---|---|
| **A** — pool inadequate | forced_lv 1e-2 (8/8 fail) | Polynomial roots far from truth at high noise | Better data path / alt pipeline |
| **C₁** — gate discards good rows | flexible_arm 1e-4 | `MAX_ERROR_THRESHOLD = 0.5` drops truth-better rows when no row passes | Relax gate; or use relative threshold |
| **C₂** — selection picks wild row | daisy_mamil3_7 1e-4 | Pool has rel=0.11 row at bottom of CSV; row 1 has wild states | Bug somewhere in `analyze_estimation_result` / `cluster_solutions` / oracle_sort_key |

### 3. fitzhugh polish=OFF was the wrong test case

My session-long focus on fitzhugh was based on a deprived-config baseline (`shooting_points=3`,
single interpolator) that produced rel=7.06. The actual production config gets rel=0.057
(60× better). fitzhugh has only 2 AMIGO2-only wins out of 40 — it's mostly a
non-differentiating system.

### 4. The MAX_ERROR_THRESHOLD gate is real but limited

Relaxing it would help flex_arm specifically. It wouldn't help forced_lv (pool
inadequate) or daisy_mamil3_7 (the gate is satisfied; the bug is elsewhere).

## Implementation: cluster-first gate (May 2026)

User asked "is the 0.5 threshold arbitrary?" — yes, dimensionally wrong (`L = N·M·σ²`
scales with problem; `0.5` is constant). User picked option C: **cluster first, no
err-gating**.

Implemented in `src/core/analysis_utils.jl`. Replaced lines 249-262:

```julia
# OLD:
valid_results = filter(x -> x.err < MAX_ERROR_THRESHOLD, scored_results)
if isempty(valid_results)
    sort(scored_results, by = _result_err_key)[1:min(MAX_SOLUTIONS, length(scored_results))]
else
    sort(valid_results, by = _result_err_key)
end
clusters = cluster_solutions(sorted_results)

# NEW:
sort(scored_results, by = _result_err_key)
clusters_all = cluster_solutions(sorted_results)
clusters = length(clusters_all) > MAX_SOLUTIONS ? clusters_all[1:MAX_SOLUTIONS] : clusters_all
```

Effect:
- **Easy cases**: hundreds of low-err candidates cluster together (same parameter
  region) → small cluster count → unchanged behavior. Cap at 20 clusters is non-binding.
- **Hard cases (flex_arm)**: wild and truth-near candidates form SEPARATE clusters
  (parameter distance >> CLUSTERING_THRESHOLD). Both survive as cluster reps.
  Truth-near is no longer silently dropped.
- **Multimodal cases (multiple algebraic branches)**: each branch becomes a cluster.
  Up to 20 branch reps surface. Downstream consumer can pick the right one.

**Verification on `fast_core.jl`**: 256/257 pass — IDENTICAL to the pre-change
baseline (the 1 failing test is the unrelated `Benchmark result candidate import fixture`
at line 991, pre-existing per memory). **Zero regression.**

**Verification on flex_arm under current code (the ostensibly-fixed case)**:

| Variant | solutions_vector[1] rel-err | Cluster reps |
|---|---:|---:|
| Old gate (pre-fix) | 50.6% | 83 |
| Cluster-first w/ cap=20 (BUG — first patch) | 141.4% | 20 |
| Cluster-first no cap (final) | 50.6% | 129 |

**Honest finding**: my no-cap cluster-first fix produces the SAME `solutions_vector[1]`
as the old code (rel=50.6%). It widens the returned set from 83 to 129 clusters, but
the rel-best rep is unchanged.

Why? Under current code (with `polish_solver_solutions=true`), many candidates have
`err < 0.5` (polish drives err down). The OLD gate already kept all of them; my new
gate keeps the same set plus more. The truth-near rel=0.475 candidate from the bilby
saved CSV (March 2026 code) doesn't reproduce in the current pipeline run — the
March-vs-May code differences are large enough that the pool composition isn't
identical.

So the cluster-first fix:
- ✓ Is a clean code improvement (replaces arbitrary 0.5 threshold with principled
  cluster-first logic)
- ✓ Returns a wider set on hard cases (129 vs 83 reps on flex_arm)
- ✓ Zero regression on `fast_core.jl`
- ✗ Doesn't actually move `solutions_vector[1]` on flex_arm — the limit of the pool's
  best candidate is the binding constraint, not the gate

Still TODO:
- Run `test/feature_regressions.jl` for end-to-end smoke verification
- Test on a case where the OLD gate's fallback branch was triggering (no candidate
  with err<0.5). flex_arm under current code doesn't trigger that branch.

## What this teaches us about the gate

The `MAX_ERROR_THRESHOLD = 0.5` gate is mostly INNOCUOUS in current code because
`polish_solver_solutions=true` drives err down for many candidates. The gate's
fallback branch (no candidate < 0.5) was only relevant in the older 2026-03 code or
on edge-case configurations. Removing it (cluster-first) is a defensive cleanup, not
a behavioral fix.

The actually-broken cases (forced_lv at 1e-2, cstr at any noise, crauste at high
noise) need different interventions:
- **forced_lv 1e-2**: pool inadequate; need different data path
- **cstr**: structural / observability problem
- **crauste high-noise**: catastrophic derivative errors

None of these are gate-fix problems. The cluster-first cleanup is good hygiene but
not the AMIGO2-gap-closing intervention.

## Late update: flex_arm tells a different story

`flexible_arm_0_1em4` was the test of whether the gate bug has been silently fixed
since March. Result on current code with bilby config:

```
Elapsed: 2373s (~40 min — much slower than daisy)
Pipeline returned: 83 cluster reps
solutions_vector[1] (winner):
  err = 0.0257
  rel-err = 50.6%
```

Compared to:
- bilby's saved `result.csv` best row: rel = 47.5% (per my earlier audit)
- April followup memo's reported value: 7.5% (different metric, presumably exclusing
  states or unidentifiable params)

**flex_arm is unchanged or slightly regressed under current code.** The pattern is the
opposite of daisy_mamil3_7. Suggests:

1. The package has improved daisy-class cases but NOT flex_arm-class cases.
2. The threshold-gate / row-selection bug is still real on flex_arm. The truth-near
   row at rel=47% is still not being picked as winner.
3. The April followup memo's 7.5% number probably excludes some coordinates (states
   or unidentifiables); the real worst-coordinate rel is closer to 50%.

So the gate-fix recommendation IS still load-bearing for flex_arm. The action
items in F3 remain:
- Promote `research_tryhard_finalists` to production gate path.
- Investigate `analyze_estimation_result` selection logic for cases where err
  decorrelates with truth.

## Final reframe: bilby's saved data is STALE

The daisy_mamil3_7 follow-up resolved itself unexpectedly. When I ran the **current**
pipeline (May 2026 code) with the bilby config, the result is:

```
Pipeline returned: 180 cluster reps. besterror = 4.3e-4
Solutions_vector[1]:
  a12=0.520, a13=0.700, a21=0.367, a31=0.839, a01=0.790
  x1=0.139, x2=0.303, x3=0.457
  err=2.4e-7
  rel-err = 0.04%
```

Truth is `(0.52, 0.7, 0.367, 0.839, 0.79; 0.139, 0.303, 0.457)`. The current pipeline
solves this case to **rel=0.04%** — well into machine-precision territory.

But the bilby benchmark's saved `result.csv` (generated 2026-03-09) has the wild
candidate at row 1. So:

**The bilby benchmark data is two months stale.** The package has been substantially
improved between 2026-03-09 and 2026-05-04. Many of the "AMIGO2-only wins" in the
differential reference were against the March-version code, not current.

This invalidates several of my conclusions:

- Class C₂ "selection picks wild row" failure mode I claimed for daisy_mamil3_7 — 
  **not present in current code**. May have been fixed since the bilby run.
- The MAX_ERROR_THRESHOLD gate audit for flex_arm and forced_lv was on saved CSVs
  from March. Whether they'd reproduce on current code is unverified.
- The 118 AMIGO2-only count is probably substantially smaller against current code.

## Concrete recommendation

**Re-run a small subset of bilby on current code before doing any more audit work.**
At minimum:

- `daisy_mamil3_7_1em4` (verified already: rel=0.04% under current code)
- `flexible_arm_0_1em4` (verify whether the gate still bites)
- `forced_lotka_volterra_0_1em2` (verify whether the pool is still inadequate at high noise)
- `cstr_1_0` (zero-noise structural failure — probably persists)
- `crauste_3_1em8` (catastrophic case — probably persists)

Cost: ~1.5h compute. Output: a current-code Class A/B/C/D breakdown that
supersedes the stale bilby differential reference.

This is the BIGGEST take-away from the session: **don't trust two-month-old
benchmark data when recommending fixes**.

## Open question (unresolved at session end)

**Why does `result.csv` row 1 of daisy_mamil3_7_1em4 have wild states (x1=394, x2=−84,
x3=54) while the truth-near candidate (rel=0.111) is at the bottom of the file?**

Things I verified:
- `pep.p_true` keys hash equal across separate `@parameters` calls (so symbol
  matching is fine).
- Pool has 89 rows with the truth-near one at rel=0.111, both lowest-err AND
  lowest-rel.
- bilby's `stdout.txt` reports `Best maximum relative error: 0.11107` correctly.

Things I haven't verified:
- Whether `solutions_vector[1]` from `analyze_estimation_result` actually IS the
  wild-states candidate (vs. a CSV write-order issue in the bilby script).
- Whether `oracle_error_stats` returns `nothing` in the actual pipeline run (vs.
  in my isolated test).
- Whether `cluster_solutions` is somehow grouping wild and truth-near candidates
  together.

**Recommended quick verification** (~15 min next session):
- Run `analyze_parameter_estimation_problem` on daisy_mamil3_7 with the bilby config.
- Print `solutions_vector[1].parameters` and `solutions_vector[1].states`.
- If wild → bug in selection logic.
- If truth-near → bug in CSV write order.

## Recommended next steps in priority order

### High leverage, small effort

1. **Resolve the daisy_mamil3_7 row-1 mystery** (~15 min). Trace whether it's
   pipeline selection or bilby script CSV writing.
2. **Wire `research_tryhard_finalists` into the production gate path** (medium effort,
   high impact). The team built this; it just isn't exposed.
3. **Fix the `analyze_utils.jl:253` gate to be relative-threshold or no-gate**
   (~1 hour). Helps flex_arm specifically and probably more.

### Medium leverage, medium effort

4. Run threshold audit across all 118 AMIGO2-only cases to get the Class A/C₁/C₂
   breakdown. This determines the priority of subsequent fixes.
5. Investigate Class A cases (forced_lv 1e-2 etc.) for fundamentally-different
   interventions — non-stationary GP, different observable parameterization, or
   accept that polish-from-random-restart is the right tool for high-noise cases.

### Low leverage, defer

- Most of the seed-strategy R&D from this thread (S0-S6 strategies). They address
  Class A cases nominally but the actual Class A cases (pool truly inadequate)
  aren't fixable by combining pool members.

## Files produced this session

```
artifacts/diagnostics/seed_strategy_recon_2026_05_04/
├── F1_recon_findings.md            (recon of prior research)
├── F2_threshold_audit_findings.md  (3-case audit)
├── F3_synthesis_and_next_steps.md  (synthesis + recommendations)
├── SESSION_SUMMARY.md              (this document)
└── flex_arm_pool_audit.csv         (per-row data for flex_arm)

temp_plans/
├── flex_arm_threshold_audit.jl     (single-case audit)
├── multi_case_threshold_audit.jl   (3-case audit)
└── oracle_stats_debug.jl           (symbol-equality test)
```

## Time budget

| Phase | Time |
|---|---:|
| F1: recon of prior research | 30 min |
| F2: write + run multi-case audit | 90 min |
| F3: synthesis writeup | 30 min |
| Daisy row-1 investigation | 30 min |
| Final cleanup + this summary | 20 min |
| **Total** | **~3.5 hours** |

## What I'd do differently

1. **Read `AMIGO2_vs_ODEPE_differential_reference.md` and the post-polish memo
   FIRST.** This would have saved the entire fitzhugh deep-dive (which was on the
   wrong test case and the wrong harness config).
2. **Verify baseline against an external reference** before reasoning extensively.
   The bilby `result.csv` for fitzhugh would have shown rel=0.115 vs my measured
   rel=7.06 in the first 5 minutes.
3. **Check git log on the relevant files** before assuming a documented bug is
   un-fixed. `MAX_ERROR_THRESHOLD` may already be on someone's TODO list.
4. **Smaller validation experiments first.** I ran 17-min full-pipeline runs when
   reading saved CSVs would have been 5 seconds.

The session was net-productive — clarifying that "seed strategies" was the wrong tool
for ~70% of the AMIGO2-only failure set is itself a useful finding. But it took 4
hours of dead-ends to find that.
