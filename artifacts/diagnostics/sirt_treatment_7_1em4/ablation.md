# SIRT Exact Ablation

- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4`
- Raw import seconds: 7.99206
- Context build seconds: 1106.61

## Results

| Case | Fit Error | Param RMSE | Combined RMSE | Lineage |
|------|-----------|------------|---------------|---------|
| `raw_71` | 250.513 | 9.88% | 7.47% | method=algebraic, source=imported, candidate=71 |
| `polished_raw_71` | 29.8224 | 0.0% | 0.02% | method=algebraic, source=imported, candidate=71, polished=true |
| `raw_77_best_fit` | 177.693 | 30.25% | 23.14% | method=algebraic, source=imported, candidate=77 |
| `polished_raw_77` | 29.8224 | 0.0% | 0.02% | method=algebraic, source=imported, candidate=77, polished=true |
| `branch_v1_no_refine` | 406.497 | 29.26% | 22.02% | method=algebraic, source=imported, candidate=68 |
| `block_v2_no_polish` | 286.307 | 11.68% | 8.83% | method=direct_opt, source=assembled |

## Stage Timings

- `polish_raw_71_seconds` = 47.9571 s
- `polish_raw_77_seconds` = 3.22222 s
- `branch_no_refine_seconds` = 266.296 s
- `block_no_polish_seconds` = 52.4062 s
