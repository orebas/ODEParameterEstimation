# `flexible_arm` / `brusselator` Follow-up

Generated: `2026-04-23`

## Purpose

This note records two follow-up checks after the residual-polish solver shootout:

1. verify that the scalar `Inf` row on `brusselator_5_1em4` was a local harness bug, not a real scalar result
2. clarify whether `flexible_arm_0_1em4` is mainly a search/pool gap or a local same-pool path discrepancy

## Scalar `Inf` on `brusselator_5_1em4`

In the expanded residual-polish artifact, the scalar rows for `brusselator_5_1em4` were:

- `scalar linear`: `Inf`
- `scalar log`: `Inf`

That was caused by a local reporting bug, not by scalar polish returning infinite benchmark RMSE. The failure was:

- `_best_fit_raw_candidate(::Vector{Any})`

The fix was applied in:

- [generate_log_polish_ablation.jl](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_log_polish_ablation.jl)
- [generate_residual_polish_ablation.jl](/home/orebas/.julia/dev/ODEParameterEstimation/test/generate_residual_polish_ablation.jl)

The change normalizes `analyzed_candidates` back to `Vector{ParameterEstimationResult}` before selection.

## `flexible_arm_0_1em4`

Benchmark comparison-table selected rows:

- saved `odepe_nopolish`: `7.50%`
- saved `odepe_polish`: `3.60%`
- saved `amigo2_run`: `0.54%`

Exported pool sizes:

- exported `odepe_nopolish/result.csv`: `62` rows
- exported `odepe_polish/result.csv`: `143` rows

Imported-pool stage audit:

- best imported `odepe_nopolish` row under current local importer: `6.62%` (row `21`)
- benchmark-selected `odepe_nopolish` row survives import: `yes` (row `27`, `7.50%`)
- best imported row fit error: `22356.53`
- best imported row fit rank: `34 / 62`
- imported candidates with `err < MAX_ERROR_THRESHOLD`: `2`
- best analyzed-pre-polish row after `analyze_estimation_result(...)`: `32.11%`

But the local same-pool solver shootout only achieved:

- `scalar linear`: `32.64%`
- `scalar log`: `30.93%`
- best residual result: `18.75%` (`LeastSquaresOptimJL(:lm)` in log-space)

Conclusion:

- `flexible_arm_0_1em4` is not just a “good basin absent from the imported `odepe_nopolish` pool” case.
- The imported `odepe_nopolish` pool already contains materially better rows (`6.62%` best, `7.50%` benchmark-selected) than the downstream local ablation preserved.
- The primary culprit is the analysis gate in [analysis_utils.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/core/analysis_utils.jl#L249), not polish:
  - once any candidates satisfy `err < MAX_ERROR_THRESHOLD`, `analyze_estimation_result(...)` keeps only those fit-good rows
  - on this case, that means only `2` candidates survive to clustering
  - both truth-better rows are discarded before polish because their fit errors are far too large
- There may still be a separate exported-pool reconciliation issue, but it is no longer needed to explain the local same-pool failure.

## `brusselator_5_1em4`

Benchmark comparison-table selected rows:

- saved `odepe_nopolish`: `0.34%`
- saved `odepe_polish`: `0.05%`
- saved `amigo2_run`: `0.03%`

Exported per-case CSVs:

- exported `odepe_nopolish/result.csv`: `123` rows
- exported `odepe_polish/result.csv`: `123` rows
- the two exported CSVs are byte-identical

Recomputed best benchmark RMSE over the exported pools:

- best exported `odepe_nopolish` row: `1.56%`
- best exported `odepe_polish` row: `0.00035%`

Conclusion:

- the local scalar `Inf` row was a harness bug
- but there is also a separate benchmark/export inconsistency here
- the comparison-table selected rows and the exported per-case pools are not lining up in any simple one-object way

## Current Read

- `flexible_arm_0_1em4` now points to a real local same-pool path discrepancy, not only a search-breadth gap
- `brusselator_5_1em4` mixes:
  - a fixed local scalar-report bug
  - a remaining benchmark/export inconsistency
