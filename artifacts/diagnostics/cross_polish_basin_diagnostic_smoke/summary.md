# Cross-Polish Basin Diagnostic

- Generated: `2026-04-24 12:57:37`
- Basis: imported bilby `odepe_nopolish` pools
- Methods: `Scalar log-space`, `Bounded LeastSquaresOptim LM log-space`, `Bounded FastLevenbergMarquardt log-space`
- Same-attractor threshold: `0.001` under `solution_distance(...)`

## Pairwise Transfer Summary

| Source → Target | Attempted | Successful | Same target oracle | Same target selected | Same either | Benchmark improved vs seed | Fit improved vs seed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | 4 | 4 | 0 | 0 | 0 | 1 | 4 |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | 4 | 4 | 0 | 0 | 0 | 0 | 4 |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | 3 | 3 | 0 | 0 | 0 | 3 | 3 |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | 3 | 3 | 0 | 0 | 0 | 3 | 3 |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | 4 | 4 | 0 | 1 | 1 | 1 | 4 |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | 4 | 4 | 0 | 0 | 0 | 2 | 4 |

## Per-Case Diagnosis

| Case | Diagnosis | Successful transfers | Same-attractor transfers | Same-attractor rate |
| --- | --- | ---: | ---: | ---: |
| `seir_3_1em4` | `different_basin_likely` | 22 | 1 | 0.045 |

## Fit Improves But Benchmark Worsens

| Case | Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Source fit | Transfer selected fit |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| `seir_3_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 1.04% | 1.04% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 5.03% | 5.03% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 1.04% | 1.04% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 5.03% | 5.03% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 4.74% | 4.74% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best` | 3.89% | 3.89% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 5.05% | 5.05% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_2` | 4.92% | 4.92% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_3` | 4.00% | 4.00% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 3.89% | 3.89% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 5.05% | 5.05% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 4.92% | 4.92% | 5.9881 | 5.9881 |

## Notes

- `summary.tsv` contains one row per transferred seed.
- `case_notes.md` contains from-cold winners and detailed transfer tables per case.
