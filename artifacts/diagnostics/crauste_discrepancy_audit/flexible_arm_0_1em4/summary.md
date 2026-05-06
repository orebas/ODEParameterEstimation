# Crauste Discrepancy Audit

- Case: `flexible_arm_0_1em4`
- Comparison-table run ordinal: `1`
- Generated: `2026-04-23T00:44:03.095`
- Benchmark root: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09`
- Goal: bucket the `crauste_3_1em8` mismatch into pool semantics, metric definition, or local polish-path differences

## Pool Semantics

| Variant | Stdout Raw Total | Stdout Saved Count | `result.csv` Rows | Imported Candidate Count |
| --- | ---: | ---: | ---: | ---: |
| `odepe_nopolish` | 124 | 62 | 62 | 62 |
| `odepe_polish` | 123 | 143 | 143 | 143 |

- `odepe_nopolish` saved/exported pool is far smaller than the raw total found during search.
- `odepe_polish` exported pool contains `4 / 62` exact `odepe_nopolish` candidates, plus many additional rows.
- Benchmark-selected `odepe_nopolish` estimate found in exported `odepe_nopolish/result.csv`: `yes, row 27`
- Pool-semantics bucket: `YES`

## Metric Reconciliation

- Benchmark `RMSE` in `summarize_results.py` is plain absolute RMSE over merged states + parameters, optionally filtering `non_identifiable` names.
- Local `combined_rel_rmse` is relative RMSE over merged states + parameters.
- Non-identifiable list for this case: `[]`

| Probe Row | Saved RMSE | Recomputed Benchmark RMSE | Recomputed Local Relative RMSE | Saved Mean Rel Err | Saved Max Rel Err |
| --- | ---: | ---: | ---: | ---: | ---: |
| `run 1` | 0.036014 | 0.036014 | 17.58% | 7.88% | 51.93% |
| `run 3` | 0.009957 | 0.009957 | 3.00% | 2.14% | 5.27% |

| Pool / Arm | Best Benchmark RMSE | Best Local Relative RMSE |
| --- | ---: | ---: |
| Imported `odepe_nopolish` | 0.066186 | 19.70% |
| Imported `odepe_polish` | 0.036014 | 13.08% |
| Local stock polish on imported `odepe_nopolish` | 2.277317 | 973.74% |

- Benchmark-selected `odepe_nopolish` RMSE from analysis CSV: 0.075023
- Benchmark-selected `odepe_polish` RMSE from analysis CSV: 0.036014
- Matching imported `odepe_polish/result.csv` row for the benchmark-selected estimate: `85`
- Metric-definition bucket: `YES`

## Local Stock Polish Trace

| Input Rows | Unique Polish Starts | Polished Pool Rows | Analyzed Rows | Selected Benchmark RMSE | Selected Local Relative RMSE | Best Benchmark RMSE | Best Local Relative RMSE |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 62 | 62 | 124 | 1 | 2.277317 | 973.74% | 2.277317 | 973.74% |

- Saved `odepe_nopolish` selected benchmark RMSE: 0.075023
- Saved `odepe_polish` selected benchmark RMSE: 0.036014
- Local stock-polish bucket: `unresolved`

## Bucket Verdict

- `Pool semantics mismatch`: `YES`
- `Metric-definition mismatch`: `YES`
- `Local polish-path mismatch`: `unresolved`

Current best reading:
- The saved `odepe_nopolish/result.csv` file is not a proxy for the full raw search population, but it does contain the benchmark-selected exported `odepe_nopolish` estimate for this run.
- Prior comparisons mixed absolute benchmark RMSE with local relative RMSE, which inflated apparent disagreement.
- After accounting for those two mismatches, the remaining `crauste` gap is primarily between the exported `odepe_nopolish` pool and the much larger exported `odepe_polish` pool, not an obvious local stock-polish parity failure.
