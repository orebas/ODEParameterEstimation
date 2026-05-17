# Probe 4b — lognorm reranking vs S2 saturation schemes

Data: 2026-05-14 numbat benchmark, 275 cells with an oracle-close row.
Cell pool: 300 randomly sampled (seed=0) from `/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run`.
Bounds (uniform across the benchmark): `lb=1e-05`, `ub=10.0`.

## Rank-1 oracle stats per scheme

| Scheme | median | mean | p90 | %≤1% | %≤10% |
|---|---|---|---|---|---|
| err_only | 3.8e-05 | 1.18 | 0.598 | 71.6% | 82.2% |
| C: (is_neg1, err) | 6.89e-05 | 0.443 | 0.381 | 77.5% | 87.6% |
| S2: (sat, is_neg1, err) | 6.71e-05 | 0.161 | 0.322 | 77.8% | 88.0% |
| lognorm_err: (Σlog², err) | 0.165 | 0.395 | 1.19 | 22.5% | 43.3% |
| lognorm_neg1_err: (Σlog², is_neg1, err) | 0.165 | 0.395 | 1.19 | 22.5% | 43.3% |
| **Z: oracle-best (lower bound)** | 1.55e-05 | 0.0259 | 0.0458 | 81.8% | 92.4% |

## Pairwise vs S2 baseline (wins = lower rank-1 oracle than S2)

| Scheme | wins | losses | ties |
|---|---|---|---|
| err_only | 43 | 64 | 168 |
| C: (is_neg1, err) | 5 | 8 | 262 |
| lognorm_err: (Σlog², err) | 27 | 237 | 11 |
| lognorm_neg1_err: (Σlog², is_neg1, err) | 27 | 237 | 11 |

Per-cell CSV: `probe4b_per_cell.csv`

---

## Verdict: don't ship lognorm

Across every metric, lognorm reranking is **dramatically worse** than the
current S2 default:

- `%≤1%`: lognorm 22.5% vs S2 77.8% — **3.5× worse**
- `%≤10%`: lognorm 43.3% vs S2 88.0% — 2× worse
- median rank-1 oracle: lognorm 0.165 vs S2 6.7e-5 — many orders of
  magnitude worse
- pairwise: lognorm loses in **237/275 cells**, wins in only 27

The `is_neg1` secondary doesn't help — identical numbers to plain lognorm
because the score primary is fine-grained enough that ties basically
don't happen, so the secondary almost never fires.

## Why lognorm fails (validates user's concern)

The lognorm score `Σ (log p)²` is minimized when *all* parameters are
p=1. But the benchmark cells have truth values that vary across the
full `[1e-5, 10]` range — including parameters genuinely far from 1:

| Cell example | Truth value | log² contribution |
|---|---|---|
| slow_fast k1 | 0.104 | 0.96 |
| biohydrogenation k7 | 0.107 | 0.91 |
| daisy_mamil4 k01 | 0.125 | 0.81 |

Truth rows for these cells already carry non-zero lognorm cost. When the
polish also produces a row with parameters that *happen* to be closer to
1 (and still fit the data adequately), lognorm picks the closer-to-1 row
over truth. The bias is **systematic** — not a tiebreaker among
data-equivalent rows but a strong pull toward the prior.

S2's `saturation_count` doesn't have this problem because it only fires
when parameters are within 2% of a *bound*. A parameter sitting at
k=0.104 (well inside `[1e-5, 10]`) has saturation_count contribution 0 —
the truth row is not penalized. Lognorm penalizes it (log²(0.104) ≈ 0.96)
regardless of how close it is to any bound.

## Decision

- **Keep `:sat_neg1_err` as default.** No production change.
- **Keep the new `:lognorm_err` / `:lognorm_neg1_err` strategy symbols in
  source** (they're exposed via `rank_strategy`) so users with O(1)-only
  parameter regimes can opt in if they want, but document them as
  experimental and not recommended for general use.
- **Skip the live spot-check.** The offline evidence is unambiguous; live
  data would just confirm the same loss.

## What this rules out (and what it doesn't)

This experiment specifically tested **post-hoc reranking by lognorm
score**. It rules out lognorm as a *replacement* for saturation_count's
primary key in S2.

It does NOT rule out:
- L2 regularization in the polish loss itself (`polish_regularization_lambda`),
  which DOES change where the polish converges and could be useful
  alongside (or instead of) the prior-based heuristic — different mechanism,
  separate evaluation needed.
- A hybrid scheme like `sat_neg1_err` when bounds are present and
  `err_only` otherwise (rather than `sat_neg1_err` silently degrading to
  `is_neg1, err` when bounds are missing).
- Per-parameter priors that account for the expected magnitude of each
  parameter (instead of "p=1 for all").
