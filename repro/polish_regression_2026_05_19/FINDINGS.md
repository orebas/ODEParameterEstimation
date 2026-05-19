# Wallaby polish-precision regression — root cause and fix

## TL;DR

The wallaby polish regression vs numbat-14 (1-4pp at fine thresholds; 47
cells regressed >1.5× at ≤1e-4) is caused by **the `is_neg1` secondary key
in `rank_strategy = :sat_neg1_err`** (the S2 default introduced in 282fe1a).

S2 demotes rows with `polish_source_hc_idx = -1` (synthesized aggregates,
multipoint candidates, fallback rescues) below rows with explicit HC
indices. Under the 282fe1a pipeline, the truth-near polish result is often
`psh=-1` and gets buried in result.csv. **The 14-era pipeline produced
fewer psh=-1 rows, so the heuristic was harmless there but actively
harmful on the wallaby candidate distribution.**

**Fix:** revert `rank_strategy` default to `:err_only`.

## Evidence

### Phase 1 (refuted): OrdinaryDiffEq 6.x pin

Investigation doc hypothesized OrdinaryDiffEq 6→7 jump. I built env_ode6
(OrdinaryDiffEq 6.111, SciMLBase 2.155, current source) and re-ran
`bicycle_model_7_1em8`:

| Run | rank-1 post_polish_error |
|---|---|
| numbat-14 (14 stack + source f34d28d) | **2.6e-7** ✓ |
| wallaby (current stack + source 282fe1a) | **4.3e-4** ✗ |
| **env_ode6** (OrdinaryDiffEq 6.111 + source 282fe1a) | **3.5e-4** ✗ |

Marginal change only — OrdinaryDiffEq pin refuted.

### Plot twist: investigation doc misidentified the stack delta

Checking the actual numbat-14 manifest (PEB commit 272f64319):

| Package | numbat-14 | wallaby |
|---|---|---|
| OrdinaryDiffEq | **7.0.0** | 7.0.0 (unchanged!) |
| SciMLBase | 3.10.0 | 3.13.0 |
| MTK | 11.26.0 | 11.26.3 |
| DiffEqBase | 7.3.0 | 7.5.0 |
| LinearSolve | 3.76.0 | 3.80.0 |
| Symbolics | 7.22.0 | 7.24.0 |

**Numbat-14 already had OrdinaryDiffEq 7.0.0.** The 6→7 bump happened
pre-14, not into wallaby.

### Phase 1b: exact numbat-14 stack + current source

Built env_n14 with the exact numbat-14 Manifest.toml (PEB 272f64319) +
current ODEPE source (282fe1a):

| Run | rank-1 post_polish_error |
|---|---|
| **env_n14** (14 stack + 282fe1a source) | **3.5e-4** ✗ |

Same regression. **The stack is not the cause; the source is.**

### Smoking gun: S2 sort mis-ranking

In env_n14's result.csv for `bicycle_model_7_1em8`, the truth-near row
DOES exist — at rank 4, not rank 1:

| Sort | Rank 1 row |
|---|---|
| `:err_only` | err=1.65e-7, psh=-1 (truth-near) |
| `:sat_neg1_err` (S2) | err=3.46e-4, psh=69 (HC-tagged but wrong) |

Under err_only, the truth-near row wins. Under S2, the is_neg1 secondary
key demotes psh=-1 rows below psh-tagged rows, and a worse-but-tagged row
gets surfaced.

### Prevalence

Offline scan of 47-cell regression set: **12 of 47 cells** have S2 picking
a row with ≥2× worse post_polish than err_only's pick.

Full wallaby polish benchmark (1147 cells) under each scheme:

| Scheme | ≤1e-9 | ≤1e-4 | ≤1e-3 | ≤0.1 | median rank-1 post_polish |
|---|---|---|---|---|---|
| **err_only** | **36.3%** | **69.7%** | **79.3%** | **87.0%** | **1.82e-7** |
| **sat_err** (proposed alt) | 36.3% | 69.6% | 78.6% | 84.8% | 1.82e-7 |
| **sat_neg1_err** (S2, current default) | 32.2% | 60.2% | 67.9% | 77.9% | 3.24e-6 |

**S2 is -9.5pp at ≤1e-4 and -11.4pp at ≤1e-3 vs err_only on wallaby data.**
`sat_err` (S2 without is_neg1) is essentially identical to err_only —
the saturation primary key is benign; the is_neg1 secondary is the
killer.

## Why this didn't show in probe4c

Probe4c (2026-05-17) re-sorted **14-era** result.csvs under S2 and
reported +5.3pp at ≤1% over err_only. That gain was real on the 14
candidate distribution. The 282fe1a pipeline produces a *different*
candidate distribution — more `psh=-1` rows from soft-wall + IS clustering
keeping truth-finder aggregate/multipoint candidates that 14 had been
losing.

So:
- On 14 data, is_neg1 = useful tiebreaker among HC-mostly rows
- On 282fe1a data, is_neg1 = systematic demoter of new truth-finders

The candidate-distribution shift made the heuristic backfire.

## Fix

`src/types/estimation_options.jl`: change default
`rank_strategy = :sat_neg1_err` → `:err_only`.

Also add `:sat_err` as a valid option (sat primary, no is_neg1, err
tertiary). For users who want bound-saturation demotion without the
provenance penalty.

Other 282fe1a defaults are unchanged:
- `polish_softwall_lambda = 1e-2`, `polish_softwall_epsilon = 0.10` (soft-wall)
- `cluster_method = :identifiable_subspace` (IS clustering)
- `branch_top_k = 20`

## Open questions

1. **The other 35 of 47 regression cells** (where S2 and err_only pick
   the same rank-1 row) — what's causing those regressions? Stack bumps?
   Some interaction with IS clustering? Needs follow-up.
2. Should `:sat_err` ever be the default in a future iteration if we want
   bound-saturation demotion? Today's data says no — err_only is marginally
   better at every threshold. Defer.

## Files

- `repro/polish_regression_2026_05_19/env_ode6/` — OrdinaryDiffEq 6.111 pin (refuted)
- `repro/polish_regression_2026_05_19/env_n14/` — exact numbat-14 stack
- `repro/polish_regression_2026_05_19/bicycle_model_7_1em8/` — Phase 1 probe
- `repro/polish_regression_2026_05_19/bicycle_model_7_1em8_n14/` — Phase 1b probe
- This document: `repro/polish_regression_2026_05_19/FINDINGS.md`

## Reproducibility

```bash
# Re-build env_n14
cd repro/polish_regression_2026_05_19/env_n14
julia --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'

# Re-run probe under exact 14 stack
cd ../bicycle_model_7_1em8_n14
julia --startup-file=no script.jl > stdout.txt 2> stderr.txt

# Offline scheme comparison across all wallaby polish cells
python3 repro/polish_regression_2026_05_19/sort_scheme_compare.py  # to be added
```
