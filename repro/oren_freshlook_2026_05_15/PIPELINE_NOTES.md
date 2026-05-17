# ODEPE pipeline notes — current behavior, with confidence markers

**Status:** working notes, 2026-05-15. Author: claude-during-oren-fresh-look.
Captures the *current* (commit `823cdeb`) default pipeline behavior, what
we know vs guess, and pointers to existing docs that may need updating.

Throughout, confidence is marked inline:

- **[V]** Verified — checked in source code or empirically tested this session.
- **[L]** Likely — strong indirect evidence, but not formally proven.
- **[S]** Speculative — hypothesis worth testing.
- **[H]** Historical — documented somewhere but may now be stale or partial.

This is not a spec. It documents what the code does *today* and where the
decisions are ad hoc enough that experimentation is welcome.

---

## 1. Pipeline summary (one-paragraph version) [V]

`analyze_parameter_estimation_problem(pep, opts)` runs:
**transcendental substitution → SIAN identifiability → SI template construction
(with structural fix set for continuous non-id directions) → 12 shooting points
(exp-warped toward t=0) → 9-method interpolator portfolio → HC.jl
polynomial solving (parameter homotopy by default) → optional multipoint solving
(2-tuples, capped at 20 pairs) → algebraic backsolve → blown-IC rescue →
synthesized aggregate candidates (default ON) → polish (`PolishLSOBoundedLog`,
bounded LM in log-space, λ=0 by default) → 1e-5 dedup → top-100 err-sorted slice
→ result.csv**.

The full stage-by-stage map with file:line citations lives in `PIPELINE_MAP.md`.

---

## 2. What the columns in result.csv mean [V]

| Column | Meaning |
|---|---|
| `<state_name>(t)` | Estimated state at t=0 (i.e., IC) [V]. |
| `<param_name>` | Estimated parameter value [V]. |
| `err` | Post-polish sum-of-squared residuals on raw noisy data [V] (`parameter_estimation.jl:2131-2157`). Same as `post_polish_error` for polished rows [V]. |
| `post_polish_error` | Immutable provenance copy of post-polish err [V]. Same as `err` for polished rows but persists if `err` is later overwritten [L]. |
| `branch_size` | Cluster size at the 1e-5 dedup stage [V]. Counts how many bit-near-identical polished candidates collapsed into this representative [V]. NOT a measure of basin width [V]. |
| `polish_source_hc_idx` | If the row was polished via `_polish_batch_from_context` rep_idx tagging, the index into the polish input vector [V]. **`-1` in CSV means `nothing` in the provenance struct** [V] — written by the PEB template `julia_template_for_estimation_odepe_v2.jl:197-199`. Causes of `-1`: aggregate-synthesized rows, multipoint candidates that bypassed the rep_idx path, fallback rescues, anywhere `set_result_lineage!` was called without `polish_source_hc_idx` [L]. |

> **Note (gap)**: the meaning of `polish_source_hc_idx = -1` is not documented
> anywhere in the user-facing docs as far as we can tell. The most common
> interpretation in prior investigation notes was "synthetic-aggregate-sourced",
> which is *partially* correct (aggregates contribute many of them) but
> misleading (other paths produce -1 too).

---

## 3. The output cap mechanism [V]

After all polishing, the result writer in `analysis_utils.jl:644-656` does:

1. `clusters = cluster_solutions(sorted_results)` where sorted_results is err-ascending [V].
2. Within `cluster_solutions`, merge rows whose pairwise relative distance is
   `< CLUSTERING_THRESHOLD = 1e-5` over all variables [V] (`analysis_utils.jl:50-69`,
   `core_types.jl:62`).
3. `cluster_reps = [first(c) for c in clusters]` — first (= lowest err) of each
   cluster as representative [V].
4. Set `cluster_reps[i].branch_size = length(c)` [V].
5. If `opts.branch_detection = true` (default) and `length(cluster_reps) > opts.branch_top_k`:
   slice to `cluster_reps[1:branch_top_k]` (default 100) [V].
6. Else fall back to oracle-sorting cluster_reps (the "06 cheat") [V] — for
   backward-compat tests only.

> **Note on history:** Commit `f34d28d` (2026-05-14) explicitly removed
> `_detect_branches` from this stage [V]. The function `_detect_branches`
> still exists in `analysis_utils.jl:205` but is only diagnostic [V]. Earlier
> cluster-claude reports describe MAD-normalization at the output stage —
> **those descriptions are now stale** [H].

---

## 4. The pre-polish clustering, separate from output clustering [V]

This is a *distinct* clustering pass before polish runs, in
`_polish_cluster_metadata` (`parameter_estimation.jl:2394-2586`).

| | Pre-polish (Stage 14a) | Output (Stage 15) |
|---|---|---|
| Threshold | 0.001 relative on L∞-MAD-normalized identifiable axes [V] | 1e-5 relative on all axes [V] |
| Purpose | Don't waste polish budget on near-duplicates [L] | Don't print near-duplicates [L] |
| Effect on slow_fast | Two basins survive as ~46 + ~46 reps [L] | No further dedup since the two basins are >> 1e-5 apart [V] |
| `branch_err_factor = 100` filter | Drops candidates with err > 100× min err *before* clustering [V] | N/A |

> **Note (gap)**: nobody has documented *why* these thresholds are what
> they are. The 0.001 came from `91b99d7` (2026-05) tightening from 0.05
> [H, from HANDOFF.md]. The 1e-5 is in `core_types.jl` as a constant
> labeled `CLUSTERING_THRESHOLD`. No rationale text [V — checked surrounding
> comments].

---

## 5. Branch detection vs the name [V]

The name "branch detection" is misleading [S, my read]. As of `f34d28d`, it
controls two unrelated things:

- `opts.branch_detection` (default true): gates the use of `_polish_cluster_metadata`
  before polish (the 0.001 clustering) [V] and the top-K cap at output [V].
  Set to false → no pre-polish clustering and fall back to legacy oracle sort
  [V].
- `opts.branch_top_k` (default 100): the cap on output rows [V].
- `opts.branch_cluster_eps` (default 0.001): the pre-polish clustering threshold [V].
- `opts.branch_resid_factor` (default 100): another pre-polish filter [V] —
  Phase A drops candidates with err > 100× min_err *before* clustering.

> **Note (gap)**: there's no doc for these knobs as a coherent set [V]. The
> name suggests these "detect algebraic branches" but actually they're
> generic numerical clustering / capping. Worth renaming if anyone touches
> this area.

---

## 6. Aggregate synthesis: what it is, when it runs [V]

`synthesize_aggregate_candidates = true` by default [V]
(`estimation_options.jl`). Lives in
`src/core/synthesize_aggregates.jl::_maybe_synthesize_aggregate_candidates`.

What it does, per stage notes [V]:
- After single-point and multipoint solving + algebraic backsolve.
- Takes the existing candidate pool (SP + MP).
- Synthesizes "frankenstein" candidates by per-component median, mean,
  25%-trimmed-mean, weighted-median of subgroups of candidates.
- Tags them `provenance.source_type = :synthesized_aggregate` [V].
- Logs lineage to `artifacts/diagnostics/<model>/synthesis_log.csv` [V].

**When it helps** [L, from this session's slow_fast deep dive]:
- When HC produces zero (or few) real candidates that survive filtering (e.g., slow_fast at noise=1e-4), aggregates may be the *only* source of candidates that polish to truth-near or fiber-near points.
- For slow_fast_6_1em4, the 100-row file is entirely aggregate-sourced and yet 50/50 across the two Z/2 mirror basins. Aggregates worked.

**When it doesn't help** [S, hypothesis from rank analysis]:
- In well-determined cells, aggregates may produce extra polished rows that bypass `rep_idx` tracking, which inflates the `-1`-tagged row count without contributing new information.
- In numerical-ridge cells (like biohydrogenation), aggregates don't seem to be the primary problem — the bound-saturation is.

> **Note (open question)**: nobody has measured "what fraction of cells
> would do *equally well* without aggregates". Worth a sweep with
> `synthesize_aggregate_candidates = false` on a small subset.

---

## 7. Polish: what's the default, what's tunable [V]

Defaults [V, from `estimation_options.jl`]:
- `polish_solutions = true`
- `polish_method = PolishLSOBoundedLog`
- `polish_maxiters = 5000`
- `polish_maxtime = 3600` (1 hour cap, hard deadline; see prior fix)
- `polish_divergence_factor = 10.0`
- `polish_stagnation_window = 50`
- `polish_lso_delta = 100.0`
- `polish_lso_x_tol = 1e-08`, `polish_lso_f_tol = 1e-12`, `polish_lso_g_tol = 1e-12`
- `polish_max_concurrency = Threads.nthreads()`
- `polish_regularization_lambda = 0.0`

The method (`PolishLSOBoundedLog`) is:
- Bounded Levenberg-Marquardt in **log-space** per variable [V].
- Internally: variables `x` in `[lb, ub]` mapped to `x_internal` via a
  log-affine transformation so the optimizer works in unbounded coords [V].
- Residual form: `r[i] = y_pred[i] - y_data[i]` over all timepoints and observables [V].
- Optional regularization term appended: `√λ · x_internal` for each unknown [V].

> **Note**: the default was changed to `PolishLSOBoundedLog` in 2026-05
> after the bake-off documented in `temp_plans/2026-05-01_local_polish_default_recommendation.md` [H, verified date].
> Previous default was scalar `PolishBFGS`.

**What's been tried with regularization** [V, from the regularization sweep
`artifacts/diagnostics/local_polish_regularization_1em4_hard/summary.md`]:
- Grid: λ ∈ {0, 1e-4, 1e-3, 1e-2, 1e-1} on 16 hard 1em4 cases.
- Result: 11/16 best at λ=0, 5/16 best at λ=1e-1, 1-2 best at intermediate values.
- Some cells benefit dramatically (seir_6_1em4: 11.5% → 0.07% at λ=1e-3) [V].
- No single nonzero λ is robust across the suite [V].
- **Recommendation in the memo**: stay at λ=0 default, expose the knob, leave per-system tuning open [V].

> **Note (gap)**: the regularization is L2 in *log-coordinates*, which
> means it biases toward `x_internal = 0`, which is the midpoint of the
> log-bound interval (geometric mean of lb and ub) [S — from reading
> `polish_residual.jl:135-138`]. This is *not* the same as biasing toward
> a prior parameter value. If you want to bias toward a specific prior,
> you'd need a different regularization term.

> **Note (open question)**: adaptive λ. Per-system or per-rank-cluster
> λ choice has not been tried [V, no doc found]. Cluster-claude's
> `INVESTIGATION_denoised_polish_target.md` is a related but different
> idea (modify the residual *target*, not add a parameter penalty).

---

## 8. Two distinct identifiability problems we keep conflating [L]

This session clarified that "the same parameter spread in result.csv" comes
from at least three different mechanisms:

1. **Discrete algebraic fiber (Z/d symmetry)** [V on slow_fast]:
   - Two or more parameter vectors give *exactly* the same observable
     trajectory.
   - SIAN says structurally identifiable (no continuous orbit), but generic
     algebraic degree is d > 1.
   - Example: `slow_fast_6_*` has a k1↔k2 mirror (degree 2).
   - In result.csv: rows split into d clusters with NO continuous transition
     between them.

2. **Practical non-identifiability from SIAN-detected orbit** [V on slow_fast
   handling at the SIAN stage]:
   - SIAN flags a continuous direction as non-identifiable.
   - Pipeline pegs that direction via `structural_fix_set` in template construction
     (`parameter_estimation.jl:641-707`).
   - Result.csv should NOT have spread in this direction (it's pegged).

3. **Numerical ridge that isn't an algebraic ridge** [V on biohydrogenation_6_1em6]:
   - SIAN says identifiable (correctly — there's no continuous orbit *theoretically*).
   - But the data residual is essentially flat along some direction in
     parameter space *over the relevant scale*. Example: in biohydrogenation,
     `k10 >> x6/20` makes the factor `(10k10 - 0.5x6)/(10k10) → 1`, so k10
     effectively drops out of the dynamics.
   - Polish slides along the ridge and most rows hit the bound (k10 = upper_bound).
   - In result.csv: continuous-looking spread, often pinning at bounds.

> **Note (open question)**: there's no clear pipeline-level distinction
> between these in the current output. result.csv doesn't say "this is a
> discrete fiber" vs "this is a numerical ridge". Hand-classifying cells
> by which they are seems like a useful step before designing any output
> shaping. Maybe `cond(J)` at the polished candidates is a good proxy:
> tight cond → discrete fiber, large cond → numerical ridge [S].

---

## 9. Concrete failure mode inventory (this session's empirical map)

[All [V] empirical, [L] / [S] for the interpretations.]

| Failure pattern | Example cell | Symptom in result.csv | Root cause |
|---|---|---|---|
| Z/2 mirror, both basins recovered | `slow_fast_6_1em4` | 50/50 split, two basins with ~46 rows each, large param differences but tiny SSR between basins | Z/2 algebraic symmetry; pipeline works as designed but doesn't label the basins [L] |
| Numerical ridge with bound-saturation | `biohydrogenation_6_1em6` | ~93/100 rows at upper bound on k10; rank-1 wrong; truth-near rank-87 | k10 in `(10k10 - 0.5x6)/(10k10)` becomes irrelevant for k10 >> 0.02; polish slides to bound [L] |
| Buried-truth in mixed origins | `forced_lv_1_1em2` | rank-1 oracle=3.36 (synthetic), rank-97 oracle=2e-4 (HC-source) | Aggregates fit noise lower than HC-source; err-sort buries the truth-near HC row [L] |
| No oracle-close row at all | `brusselator_*_0` (3 of 10 noise-free) | best oracle still > 10% | Likely stiff ODE + ill-conditioned polish [H, cluster-claude column-scaling investigation]. Not investigated this session. |

---

## 10. Existing docs that may need updating [V — paths checked]

These are docs whose pipeline descriptions may now be stale or partial.

| Doc | Reason to update |
|---|---|
| `docs/2026-03-17_results_and_api.md` | Doesn't document `polish_source_hc_idx = -1` semantics or the `branch_*` knobs as a coherent group [V]. |
| `docs/2026-03-17_benchmark_contract.md` | Hasn't been updated for the post-2026-05 polish default change [L — file date 03-17]. |
| `results/numbat_analysis/three_way/HANDOFF.md` (PEB) | Describes `_detect_branches` at output, which is no longer the case after `f34d28d` [V]. Worth a short addendum. |
| `temp_plans/2026-05-01_local_polish_default_recommendation.md` | Solid as a snapshot; doesn't address what regularization could be tried in 2026-05+ context (e.g., on the slow_fast / biohydrogenation pathologies we just dug into) [S]. |
| `docs/2026-05-01_variable_scaling_investigation.md` | The brusselator / column-scaling investigation is still open; this session didn't move it forward [V]. |
| `CLAUDE.md` top entry | Mentions "variable (column) scaling" as the top open item, still accurate [V]. |

> **Note (proposed addition)**: the "what columns mean" table (Section 2 of
> this doc) could go into `docs/2026-03-17_results_and_api.md`. The "two
> identifiability problems" framing (Section 8) might deserve its own
> doc — call it `IDENTIFIABILITY_TAXONOMY.md` or similar.

---

## 11. Open experimentation directions [S throughout]

In rough order of "smallest change to try":

1. **Test the rerank-by-source heuristic** on a larger sample [S].
   This session's prototype: sort by `(polish_source_hc_idx == -1, err)`
   raised "rank-1 oracle ≤ 1%" from 71.6% to 77.5% on a 275-cell sample.
   Worth re-running on a different sample and checking for regressions.
2. **Auto-flag bound-saturated polish results** [S].
   Post-polish, if any parameter is within ε of a bound, mark the row.
   In rank/cluster summaries, prefer non-saturated rows when err is comparable.
   Would help biohydrogenation-style cases directly.
3. **Per-cluster λ regularization** [S].
   The regularization sweep showed nonzero λ helps some cells but no
   single value works. Try selecting λ adaptively (e.g., escalating λ if
   polish hits a bound).
4. **`cond(J)` at polished candidate as basin-width signal** [S].
   Small cond → tight basin (good polish solution); large cond → ridge.
   Use this to distinguish discrete-fiber from numerical-ridge cells
   automatically.
5. **Empirical algebraic degree estimator** [S].
   Cluster polished rows in identifiable subspace at a noise-aware threshold;
   count distinct clusters. Compare to HC.jl's complex-solution count as a
   sanity check.
6. **Run pipeline with `synthesize_aggregate_candidates = false`** [S].
   Measure: which cells now have empty / underpopulated result.csv? Which
   improve in ranking?

---

## 12. What's *not* in this document

- Per-system tuning recipes.
- Step-by-step debugging guides for specific failure modes (those should
  go in dedicated `temp_plans/` notes if anyone investigates further).
- A definitive ranking scheme — we converged toward "containment matters
  more than rank-1", but the specific output strategy is still open.
- A doc-of-doc-updates. The "may need updating" table above is a starting
  point; actually editing the user-facing docs should happen separately
  once the team agrees on the framing.
