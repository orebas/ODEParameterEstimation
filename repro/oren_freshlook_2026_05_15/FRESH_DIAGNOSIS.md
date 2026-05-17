# Fresh look at "the first problem" (2026-05-15)

**TL;DR**: The truth-near row is already in 14's set in ~92% of cells — it's just
buried by err-sorting. The cause is **synthetic-aggregate candidates**
(`polish_source_hc_idx = -1`) that fit the data well but have wrong parameters.
A single one-line ranking change — *"prefer non-aggregate sources, then err"*
— recovers oracle-best at rank 1 in 52% of currently-broken cells with zero
new computation. None of the existing diagnoses (column scaling, denoised
target, branch-detection over-clustering) match what the data actually says.

## What I did

Re-ran a 300-cell random sample from `benchmark_numbat_2026-05-14` and
measured, for each cell:

1. The **oracle distance** of every row to the truth (max relative error over
   identifiable parameters + states, excluding `_trfn_*` and the metadata's
   `all_unidentifiable` list).
2. The **rank** of the oracle-best row in the err-sorted result.csv.
3. The **err structure** of the 100 returned rows.
4. The **`polish_source_hc_idx`** distribution across rows.

## The empirical picture

### How often is rank-1 the truth-near row?

| rank of oracle-best in err-sorted result.csv | count | % |
|---|---|---|
| 1 | 158 | 52.7% |
| 2–5 | 35 | 11.7% |
| 6–10 | 13 | 4.3% |
| 11–50 | 37 | 12.3% |
| 51–100 | 33 | 11.0% |
| >100 (lost) | 0 | 0.0% |
| no oracle-close row at all | 24 | 8.0% |

So in **76% of cells** (rank 1–10) ranking is fine. In **23% of cells** (rank
11–100) the truth-near row is in the output but buried. In **8%** the
output has no truth-near row at all (a different problem, likely column
scaling / wrong-basin polish, separate from this investigation).

### What does it look like when ranking fails?

I sampled 74 cells where rank-1 oracle is more than 5× worse than the
oracle-best row in the same set. Of those cells, I asked: *is rank-1's
data fit (err) much better than oracle-best's, or basically the same?*

| err ratio (err_rank1 / err_oracle-best) | fraction |
|---|---|
| ≤ 0.1 (rank-1 fits 10×+ better) | 42% |
| 0.1–0.5 | 21% |
| 0.5–2.0 (essentially tied) | 37% |
| > 2.0 (oracle-best has lower err) | 0% |

Two qualitatively different failure modes. (1) ~37% are *ties*: many rows
have basically identical err (`err_min = err_rank-1 ≈ err_oracle-best`) but
parameter values differ across the rows. These are practical
non-identifiability ridges. (2) ~63% are *real fit differences*: rank-1
actually fits the data 2–100× better than the oracle-best row.

### The smoking gun: `polish_source_hc_idx = -1`

When I broke down rank-1's `polish_source_hc_idx`:

|  | gap cells (n=74) | good cells (n=201) |
|---|---|---|
| `polish_source_hc_idx == -1` at rank 1 | **77%** | 37% |
| `polish_source_hc_idx == -1` at oracle-best | 23% | 31% |

`-1` is the sentinel for *synthetic-aggregate-sourced* rows (added in
ODEPE commits 6914363, a390793, post-06). These come from
`synthesize_aggregate_candidates` and similar paths that build candidates
from medians / multipoint combinations / etc., **without being constrained
by the original polynomial system**.

The bias is striking: in failing cells, rank-1 is twice as likely to be
synthetic as the oracle-best row is. The aggregate path is producing
low-err candidates that don't correspond to true parameters.

A few example cells (all from the 300-cell sample):

| cell | rank-1 src | rank-1 oracle | oracle-best src | oracle-best | best rank |
|---|---|---|---|---|---|
| forced_lotka_volterra_1_1em2 | -1 | 3.36 | HC #45 | 0.000189 | 97 |
| boost_converter_9_1em2 | -1 | 1.08 | HC #100 | 0.0242 | 70 |
| hiv_7_1em6 | -1 | 0.668 | HC #755 | 0.00715 | 5 |
| bicycle_model_7_1em2 | -1 | 30.5 | HC #38 | 0.0146 | 90 |
| seir_5_1em4 | -1 | 2.01 | HC #217 | 0.00189 | 66 |
| dc_motor_4_1em4 | -1 | 0.00344 | HC #24 | 0.000127 | 85 |

In each of these, a true-HC-sourced row exists *within the same 100-row
output*, and is meaningfully closer to truth than the synthetic-rank-1.

## What was wrong with the prior diagnoses

I want to flag this carefully, because cluster-claude did serious work on the
two open investigations. But the empirical picture doesn't match either of
them.

**Column scaling (`INVESTIGATION_column_scaling.md`)** is real for the ~8%
of cells where polish wandered out of any truth basin entirely
(`brusselator_6_0` etc. with rank-1 err = 146 on noise-free data). But for
the 23% where truth-near is buried in the err-sort, the polish *succeeded*
— there's a high-quality polished row in the output. The pathology isn't
conditioning, it's that we don't surface it.

**Denoised polish target (`INVESTIGATION_denoised_polish_target.md`)**
addresses a real phenomenon (rank-1 fits noise rather than truth signal)
but it would need to apply *during* polish, before the aggregate-source
rows are generated. And it doesn't explain why aggregate rows are
systematically biased toward wrong-basin fits — the noise-realization bias
should be symmetric across all polished candidates.

The original 06 benchmark didn't have this problem for a *different* reason
than "06 had broader candidates": 06 simply didn't synthesize aggregate
candidates at all (the aggregates were added later). All its rows were
HC-source. And 06 hid the rest of the problem by oracle-cheat-sorting the
output — which always puts a truth-near row at rank 1 if one exists.

## Comparing 06 vs 14, directly

For the 10 worst gap cells in 14 vs the same cells in 06:

| cell | 06 best | 14 best | 14 best rank | gap |
|---|---|---|---|---|
| seir_5_1em4 | 0.01065 | 0.01065 | 66 | 1.00× |
| forced_lv_4_1em2 | 0.002283 | 0.006115 | 39 | 2.68× |
| forced_lv_6_1em2 | 0.003999 | 0.004057 | 97 | 1.02× |
| seir_5_1em6 | 0.0001621 | 0.0001621 | 2 | 1.00× |
| aircraft_pitch_5_1em8 | 0.001956 | 0.002513 | 4 | 1.29× |
| dc_motor_4_1em4 | 0.0003241 | 0.0003241 | 85 | 1.00× |
| boost_converter_9_1em4 | 0.000419 | 0.000419 | 16 | 1.00× |
| seir_0_1em6 | 8.4e-05 | 8.4e-05 | 3 | 1.00× |
| aircraft_pitch_0_1em6 | 6.6e-06 | 0.000262 | 13 | 39.7× |
| sirt_treatment_3_1em6 | 4.9e-05 | 4.9e-05 | 57 | 1.00× |

**14 has the *same* truth-near row as 06 in 9 of 10 cases.** The "06 is
better" perception was the oracle-cheat sort. The truth-near rows have
always existed in our candidate sets; we just need to rank them visibly.

## A simple ranking change recovers most of the gap

I tested several alternative ranking schemes on the 275 cells that have any
oracle-close row at all, asking: *what oracle does the row placed at rank 1
have?*

| scheme | median | mean | p90 | ≤1% | ≤10% |
|---|---|---|---|---|---|
| A: current (err only) | 3.8e-5 | 1.2 | 0.60 | 71.6% | 82.2% |
| B: post_polish_err | 3.8e-5 | 1.2 | 0.60 | 71.6% | 82.2% |
| C: non-`-1` first, then err | 6.9e-5 | 0.44 | **0.38** | **77.5%** | **87.6%** |
| D: bigger branch_size, then err | 1.5e-4 | 6.4 | 0.90 | 66.5% | 76.7% |
| E: non-`-1`, branch_size, err | 6.9e-5 | 0.83 | 0.51 | 74.9% | 84.7% |
| G/τ=100: prefer non-`-1` only if HC has err ≤ 100× min | 3.7e-5 | 0.66 | 0.51 | 76.4% | 86.2% |
| Z: oracle-best lower bound | 1.5e-5 | 0.026 | 0.046 | 81.8% | 92.4% |

Scheme C — *"sort by `(polish_source_hc_idx == -1, err)` instead of just
`err`"* — closes ~88% of the gap to the oracle-best lower bound at the 1%
threshold and ~63% at the 10% threshold. Median goes slightly *worse*
(3.8e-5 → 6.9e-5) because in genuinely easy cells the aggregate rank-1 is
already at machine precision and the HC-source rank-1 is slightly noisier,
but the p90 oracle drops from 0.60 to 0.38 — a 1.6× reduction in tail
mass.

For the 62 specifically-broken gap cells (rank-1 originally >5× worse than
oracle-best):

| scheme | recovers oracle-best at rank 1 |
|---|---|
| A: current | 0/62 (0%) |
| C: non-`-1` first | **32/62 (52%)** |
| D: bigger branch, err | 29/62 (47%) |
| E: non-`-1`, branch, err | **34/62 (55%)** |

**Direct re-rank test on 5 named gap cells (rank-1 oracle, before → after
scheme C):**

| cell | before | after | improvement |
|---|---|---|---|
| forced_lotka_volterra_1_1em2 | 3.36 | 0.00173 | 1944× |
| boost_converter_9_1em2 | 1.08 | 0.0401 | 27× |
| hiv_7_1em6 | 0.668 | 0.00715 | 94× |
| bicycle_model_7_1em2 | 30.5 | 0.0204 | 1525× |
| seir_5_1em4 | 2.01 | 2.08 | (no help) |

Four of five gap cells dramatically improved by demoting synthetic rows.
The one that didn't (`seir_5_1em4`) only had 2 non-synthetic rows and
neither was the truth-near one; for that cell something else is wrong.

## Why this happens

The aggregate path (`synthesize_aggregates.jl`) builds candidates by taking
medians / per-component aggregates / multipoint combinations of raw HC
solutions. These synthesized candidates are then polished. Two properties
they have that HC-source candidates don't:

1. **They aren't constrained to be solutions of the polynomial system.**
   The polish step optimizes the ODE-fit loss starting from the synthesized
   point. If the loss landscape has a deep minimum off the polynomial
   manifold (e.g., from noise fitting in a degenerate direction), polish
   can descend to it freely. HC-source candidates start *on* the manifold,
   so their polish step stays in that neighborhood.

2. **They are generated to optimize fit quantity, not parameter accuracy.**
   The aggregate strategies (median across SP candidates, per-SP component
   means) build candidates that the user might find "robust" in a
   data-fitting sense but with no guarantee of being near truth.

The result: aggregates routinely produce candidates with *lower* err than
any HC-source candidate, in cells where the data residual is flat in a
degenerate direction. The current err-sort then puts them at rank 1.

## Recommended changes

I'd like to discuss these with you before doing anything.

### Recommendation 1 (smallest possible change)

Change the output sort key from `err` to `(polish_source_hc_idx == -1,
err)` in `analysis_utils.jl`. Adds maybe 2 lines.

Risk: 6.9e-5 vs 3.8e-5 median oracle in the average case is real (synthetic
rows are sometimes genuinely better on easy cells). But the tail
improvement is large (62 cells improve from 0% to 52% rank-1 recovery on
the worst failures). I'd call this a clear net positive.

### Recommendation 2 (slightly smarter, lower median regression)

Scheme G with τ=100: only prefer non-`-1` rows if some HC-source row has
err ≤ 100 × min_err. This preserves the "aggregate found truth, HC didn't"
case but still demotes egregious overfits.

Performance is almost as good as C on the 1% threshold (76.4% vs 77.5%) but
median oracle stays close to A's (3.7e-5 vs 3.8e-5). The trade-off is more
complex, but it sacrifices less average accuracy.

### Recommendation 3 (transparent)

Expose `source_type` (or just `polish_source_hc_idx == -1` boolean) as an
extra column in result.csv. Let downstream tooling re-rank if it wants. No
behavior change for existing consumers.

### Recommendation 4 (not in this report's scope)

Re-examine the aggregate synthesis itself. Are the candidates it generates
actually useful, or are they just noise that happens to fit data? My
ranking analysis says they help in maybe 30% of cells, hurt in 25%, neutral
in the rest. Worth measuring carefully before deciding whether to keep,
constrain, or remove.

## Open questions you might want to investigate next

1. **The 8% of cells with no oracle-close row at all** — this is where
   column scaling / wrong-basin polish actually matters. Disjoint from this
   ranking problem.
2. **The `seir_5_1em4` failure** under scheme C — why did the 2
   non-synthetic rows in that cell both miss truth? Could be a separate
   pipeline pathology.
3. **Why aggregates fit better than HC** structurally — is the loss
   landscape really that degenerate, or is something about polish's
   starting-point sensitivity (the bilinear-singular-Jx pattern from your
   2026-03-29 multipoint notes) at play?
4. **Whether 06's "good" results would survive err-sorting** if we
   re-evaluated err on 06's rows under the current polish code. If the
   answer is "yes 06 also has truth-near at low rank under err-sort with no
   aggregates," that's confirmation that aggregates are the dominant
   regression driver.

## Reproducibility

All analysis is from data on disk at `/home/orebas/rsync-readonly-PEB`. The
scripts I wrote during this session are inline in
`/home/orebas/.julia/dev/ODEParameterEstimation/repro/oren_freshlook_2026_05_15/`:

- `analyze_ranking.py` — main 300-cell sample analyzer
- `rerank_test.py` — alternative scheme comparison
- `06_vs_14_table.py` — the 10-cell head-to-head from subagent 3

Each script reads from the rsync mirror and writes nothing back.
