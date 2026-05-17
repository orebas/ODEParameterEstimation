# Recommendations from the 2026-05-15 fresh-look deep dive

Status: working draft, integrating evidence from probes 1, 4, 5 (complete)
and probe 2/3 (partial as of writeup). All recommendations are **for
discussion**, not commitments. Confidence markers: **[V]** verified,
**[L]** likely, **[S]** speculative.

---

## Headline

The pipeline is mostly *finding* truth-near rows (92% of cells in our
300-cell sample contain an oracle-close row); it's mostly *not ranking*
them visibly. Several improvements have evidence behind them, in
descending order of confidence and ease.

---

## Tier 1 — Recommend implementing (high confidence, low risk)

### 1.1 Change output sort to `(saturation_count, is_neg1, err)` [V on 275-cell sample]

**Evidence:** Scheme S2 raises rank-1 oracle ≤1% from 71.6% → **77.8%** and
≤10% from 82.2% → **88.0%** on a 275-cell sample, with median rank-1
oracle going slightly *worse* on already-easy cells (3.8e-5 → 6.9e-5) but
p90 dropping dramatically (0.598 → **0.322**). The trade-off is small
median degradation for substantial tail improvement.

Direct test on `biohydrogenation_6_1em6` (production data): scheme S2
moves the truth-near row from rank 87 → **rank 1**; oracle 9.18 → 0.77
(12× improvement). The truth-near is the *only* row with
saturation_count=0; the other 99 all hit the k10 upper bound and scheme
S2 demotes them.

**Implementation cost:** ~10 lines. Adds a `saturation_count` field on
the result row plus a tuple sort in `analysis_utils.jl` around line 650.

**Risk:** very low. Same set of returned rows; only the ordering changes
visibly. Cells without bound-saturation see no change in rank-1
selection.

**Caveats [S]:**
- Requires knowing bounds per-row. Currently uniform `(1e-5, 10)` in all
  benchmark cells; in a general API the bounds may be per-parameter.
- "Saturation threshold ε_sat = 2% of log range" is a heuristic. Worth
  exposing as a knob and seeing if 1%/5% behave differently.

### 1.2 Soft-wall regularization (NOW DEFAULT ON: λ_sw=1e-2, ε=0.10) [V on infrastructure, V on bioh efficacy]

**Update 2026-05-16:** flipped default ON at user request after the 7-config sweep.
Defaults now `polish_softwall_lambda = 1e-2`, `polish_softwall_epsilon = 0.10`.
Set both to 0.0 to disable.
- `test/fast_core.jl`: **258/258 ✓** with new defaults
- `test/feature_regressions.jl`: **133/133 ✓** across 15+ canonical models
- No regressions detected on standard test corpus. Ready for fresh benchmark
  to validate effect on the bilby / numbat suite.

#### Original status (pre-flip):

**Status:** source change committed; `test/fast_core.jl` green; bioh
7-config sweep complete.

**Best configuration on bioh_6_1em6: λ_sw = 1e-2, ε = 0.10**
- Rank-1 oracle: 9.18 → **4.19** (2.2× improvement)
- k10 bound saturation: 97/100 → **0/100**
- Truth-near row at rank 27 (oracle 2.91; same row as in control,
  elevated by removing bound-saturated competitors)

**Sweep takeaways:**
- **λ_sw is essentially "on/off"** — any nonzero strength past ~1e-4
  triggers the effect; further increase doesn't change outcome.
- **ε (band width) is the dominant knob:** larger ε → polish converges
  further from the bound:
  - ε = 0.02: rank-1 oracle 7.89
  - ε = 0.05: rank-1 oracle 6.26
  - ε = 0.10: rank-1 oracle 4.19
- **Soft-wall doesn't find truth** — it cleans up the bound saturation
  but the truth-near row stays at rank ~27. Whatever's blocking polish
  from converging to truth on this cell is *not* the bound.

**Recommended defaults (if making it opt-in):** `polish_softwall_lambda = 1e-2`,
`polish_softwall_epsilon = 0.10`. Either is also fine without strict
production-quality tuning given the wide plateau in λ_sw.

**What's in:** `polish_softwall_lambda::Float64 = 0.0` and
`polish_softwall_epsilon::Float64 = 0.05` on `EstimationOptions`, plumbed
through to `polish_residual.jl`. Default off — zero behavior change for
existing runs.

**Implementation cost:** Already done (79 lines, see
`probes/probe2_source_diff_summary.md`).

**Risk:** zero at default (off). Activating soft-wall is a per-run
opt-in.

**Pending decision:** whether to make soft-wall default on for cells
that show bound saturation. Need probe 2 results to decide.

### 1.3 Add `cond_J_local` and `saturation_count` as diagnostic columns to result.csv [S, low effort]

Even without using them for sort, expose:
- `saturation_count` (per row): how many params are within ε_sat of either bound
- `cond_J_local` (per row, optional): cond(J) of the local data-residual Jacobian

Users (and downstream tooling) can filter or re-sort. Doesn't change
default behavior.

**Implementation cost:** small. `saturation_count` is ~5 lines.
`cond_J_local` requires per-row Jacobian computation — expensive for
1000+ candidates per cell, so consider making it opt-in or computing
only on top-K cluster reps.

**Evidence for value:**
- Probe 1: on slow_fast, cond(J) cleanly separates two basins (cond ~113
  for truth basin vs ~10 400 for mirror). [V]
- Probe 4: saturation_count usefully complements is_neg1 in ranking. [V]

---

## Tier 2 — Discuss before implementing (medium confidence)

### 2.1 Identifiability taxonomy doc

Probe 5 showed that the 8% deep-failure cells split into at least 5
distinct failure modes:

| Mode | Example | Mechanism | Possible fix |
|---|---|---|---|
| HC failure (column scaling) | brusselator_5_0 | Truncated polynomial system has no real solutions | Column scaling investigation (cluster-claude open thread) |
| Low-observable-coefficient | hiv_9_1em4 | `y = 0.002·vv + 2·yv` makes vv barely visible | Per-parameter sensitivity check; soft-wall might help |
| Numerical ridge | biohydrogenation_6_1em6 | ODE has `(10·k10 - 0.5·x6)/(10·k10) → 1` for k10≫0.02 | Soft-wall, rerank-by-saturation |
| Under-observed + high noise | cstr_0_1em2 | 1 observable for 7 unknowns at noise=1e-2 | Not fixable algorithmically; needs more obs or lower noise |
| Multi-bound saturation | flexible_arm_5_1em2 | 3 params hit lower bound simultaneously | Soft-wall on multiple params |

**Recommendation:** Write a short `IDENTIFIABILITY_TAXONOMY.md` doc in
`docs/` capturing these modes with diagnostic recipes. Already-existing
analysis (`docs/2026-05-01_variable_scaling_investigation.md`) covers HC
failure / column scaling; the others are new framing.

### 2.2 Re-examine the polish_source_hc_idx provenance

Discovered this session: `-1` in result.csv comes from the PEB template's
fallback for `nothing` in the provenance struct, not specifically from
"synthetic aggregate". Many code paths leave `polish_source_hc_idx` unset
even when polish runs. Worth a small audit to either:
- (a) Always populate `polish_source_hc_idx` when polish runs (might
  require API refactoring)
- (b) Document the actual semantics ("-1 = polish path didn't tag this
  row") in result.csv column docs

### 2.3 Probe 2 results inform whether soft-wall becomes a recommended default

Pending probe 2 completion. If soft-wall at some (λ_sw, ε_sw) cleanly
improves biohydrogenation_6_1em6 without hurting it elsewhere, consider
expanding the probe to other bound-saturation cells (daisy_mamil4, hiv).

---

## Tier 3 — Worth investigating later (speculative / bigger scope)

### 3.1 Sensitivity-aware practical-identifiability check

The "low-observable-coefficient" cells (hiv_9_1em4 etc.) have parameters
whose 1% sensitivity is below the data noise floor. A check at template
construction time could compute per-parameter sensitivity at the
mid-bound point (or at a quick low-noise pre-pass result), and:
- Flag parameters that are below the practical-identifiability threshold
- Either peg them, regularize them, or warn the user

Already speculated about in `BIOH_AND_REGULARIZATION_MEDITATION.md`.

### 3.2 Cluster output on identifiable subspace

Currently output dedup is at 1e-5 relative distance across all params.
For cells with practical non-identifiability, dozens of rows are
near-duplicates on identifiable axes but spread on non-identifiable
axes. Clustering on the IDENTIFIABLE subspace only (projecting out
near-null directions of J) would condense these to a small number of
representatives.

Saw this empirically in probe 1: 50 rows in slow_fast's mirror basin are
essentially identical on (k1, k2, eA, eC, xC) but spread on (xA, xB, eB).
Cluster on the identifiable subspace and we'd return 2 representatives
(one per basin), not 100.

### 3.3 Algebraic degree detection (currently hard)

Per user feedback: HC.jl's solution count overcounts due to truncation
spurious roots. The "true" generic algebraic degree (for adaptive set
sizing) isn't computed today. Multiple proxies could be tried:
- Cluster polished outputs in identifiable subspace at a noise-aware
  threshold; count clusters → empirical degree.
- Run pipeline at noise=0 (synthetic, when truth is known) and observe
  how many distinct basins emerge.
- Per-system manually-set degree as metadata.

Not a single clear path forward yet.

---

## What to NOT do

- **Don't make polish_softwall_lambda default on yet.** Probe 2 results
  haven't shown it works broadly. Single-cell evidence (biohydrogenation,
  pending) is suggestive but not enough for a default flip.

- **Don't change `branch_top_k = 100` default yet.** The set size
  conversation (5–20 rows scaled by algebraic degree) is the longer-term
  vision. Until algebraic degree detection is solid, keeping 100 lets
  users see the spread and helps the empirical / diagnostic workflow.

- **Don't try to "fix" all 8% deep-failure cells with one change.**
  Probe 5 refutes that hypothesis. They're 5 distinct failure modes;
  different fixes for each.

- **Don't silently drop `synthesize_aggregate_candidates`.** Probe 3 confirms
  it's doing real, structured work — different aggregation strategies have
  systematic biases toward different basins. `per_sp_full_with_mp` median
  reliably found the truth basin on slow_fast (5/5 ✓); other categories
  systematically landed in the mirror basin. The path is producing
  structured signal, not random noise. Removing it would lose
  truth-finding candidates on cells where HC fails.

  **Possible follow-up [S]:** explicitly tag the
  `per_sp_full_with_mp` median candidates as "high-confidence
  truth-finder" candidates and elevate them in ranking. (Untested
  beyond one cell.)

---

## Updated runbook for someone picking this up

If you're picking this up after the session:

1. Read `PIPELINE_NOTES.md` for what the pipeline currently does. Read
   `PIPELINE_MAP.md` for stage-by-stage with file:line refs.
2. Read `BIOH_AND_REGULARIZATION_MEDITATION.md` for the regularization
   thinking and improvement-ideas list.
3. Read `probes/PROBE_RESULTS.md` for empirical findings.
4. Read this doc for recommended next steps.
5. Run `probes/probe4_rerank_saturation.py` first if you want to verify
   the rerank result on a fresh sample. The expected output table is in
   PROBE_RESULTS.md Probe 4.
6. The cleanest small change is Tier 1.1 (sort by `(saturation_count,
   is_neg1, err)`). Implementation is a tuple-sort change in
   `analysis_utils.jl` around line 650.
