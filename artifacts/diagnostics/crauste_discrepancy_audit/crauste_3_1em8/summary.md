# Crauste Discrepancy Audit

- Case: `crauste_3_1em8`
- Comparison-table run ordinal: `4`
- Generated: `2026-04-17T11:39:50.857`
- Benchmark root: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09`
- Goal: bucket the `crauste_3_1em8` mismatch into pool semantics, metric definition, or local polish-path differences

## Pool Semantics

| Variant | Stdout Raw Total | Stdout Saved Count | `result.csv` Rows | Imported Candidate Count |
| --- | ---: | ---: | ---: | ---: |
| `odepe_nopolish` | 337 | 13 | 13 | 13 |
| `odepe_polish` | 337 | 171 | 171 | 171 |

- `odepe_nopolish` saved/exported pool is far smaller than the raw total found during search.
- `odepe_polish` exported pool contains `13 / 13` exact `odepe_nopolish` candidates, plus many additional rows.
- Benchmark-selected `odepe_nopolish` estimate found in exported `odepe_nopolish/result.csv`: `yes, row 13`
- Pool-semantics bucket: `YES`

## Metric Reconciliation

- Benchmark `RMSE` in `summarize_results.py` is plain absolute RMSE over merged states + parameters, optionally filtering `non_identifiable` names.
- Local `combined_rel_rmse` is relative RMSE over merged states + parameters.
- Non-identifiable list for this case: `[]`

| Probe Row | Saved RMSE | Recomputed Benchmark RMSE | Recomputed Local Relative RMSE | Saved Mean Rel Err | Saved Max Rel Err |
| --- | ---: | ---: | ---: | ---: | ---: |
| `run 4` | 1.311822 | 1.311822 | 291.90% | 181.74% | 850.47% |
| `run 5` | 0.003316 | 0.003316 | 0.72% | 0.37% | 1.76% |

| Pool / Arm | Best Benchmark RMSE | Best Local Relative RMSE |
| --- | ---: | ---: |
| Imported `odepe_nopolish` | 414.661260 | 285819.02% |
| Imported `odepe_polish` | 1.248518 | 291.90% |
| Local stock polish on imported `odepe_nopolish` | 414.661121 | 285819.02% |

- Benchmark-selected `odepe_nopolish` RMSE from analysis CSV: 414.661260
- Benchmark-selected `odepe_polish` RMSE from analysis CSV: 1.311822
- Matching imported `odepe_polish/result.csv` row for the benchmark-selected estimate: `33`
- Metric-definition bucket: `YES`

## Local Stock Polish Trace

| Input Rows | Unique Polish Starts | Polished Pool Rows | Analyzed Rows | Selected Benchmark RMSE | Selected Local Relative RMSE | Best Benchmark RMSE | Best Local Relative RMSE |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 13 | 13 | 26 | 20 | 414.661121 | 285819.07% | 414.661121 | 285819.02% |

- Saved `odepe_nopolish` selected benchmark RMSE: 414.661260
- Saved `odepe_polish` selected benchmark RMSE: 1.311822
- Local stock-polish bucket: `unresolved`

## Bucket Verdict

- `Pool semantics mismatch`: `YES`
- `Metric-definition mismatch`: `YES`
- `Local polish-path mismatch`: `unresolved`

Current best reading:
- The saved `odepe_nopolish/result.csv` file is not a proxy for the full raw search population, but it does contain the benchmark-selected exported `odepe_nopolish` estimate for this run.
- Prior comparisons mixed absolute benchmark RMSE with local relative RMSE, which inflated apparent disagreement.
- After accounting for those two mismatches, the remaining `crauste` gap is primarily between the exported `odepe_nopolish` pool and the much larger exported `odepe_polish` pool, not an obvious local stock-polish parity failure.
