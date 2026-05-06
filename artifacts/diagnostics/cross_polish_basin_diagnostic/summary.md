# Cross-Polish Basin Diagnostic

- Generated: `2026-04-24 16:57:31`
- Basis: imported bilby `odepe_nopolish` pools
- Methods: `Scalar log-space`, `Bounded LeastSquaresOptim LM log-space`, `Bounded FastLevenbergMarquardt log-space`
- Same-attractor threshold: `0.001` under `solution_distance(...)`

## Pairwise Transfer Summary

| Source → Target | Attempted | Successful | Same target oracle | Same target selected | Same either | Benchmark improved vs seed | Fit improved vs seed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | 22 | 22 | 1 | 4 | 4 | 12 | 18 |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | 22 | 22 | 1 | 1 | 1 | 10 | 21 |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | 22 | 22 | 3 | 5 | 5 | 12 | 18 |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | 22 | 22 | 1 | 1 | 1 | 12 | 22 |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | 24 | 24 | 4 | 5 | 5 | 18 | 16 |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | 24 | 24 | 1 | 5 | 5 | 18 | 18 |

## Per-Case Diagnosis

| Case | Diagnosis | Successful transfers | Same-attractor transfers | Same-attractor rate |
| --- | --- | ---: | ---: | ---: |
| `seir_3_1em4` | `different_basin_likely` | 22 | 1 | 0.045 |
| `seir_7_1em4` | `different_basin_likely` | 18 | 0 | 0.000 |
| `hiv_7_1em4` | `mixed` | 10 | 6 | 0.600 |
| `hiv_4_1em4` | `mixed` | 20 | 7 | 0.350 |
| `crauste_7_1em4` | `different_basin_likely` | 20 | 0 | 0.000 |
| `hiv_2_1em4` | `mixed` | 14 | 5 | 0.357 |
| `daisy_mamil4_1_1em4` | `different_basin_likely` | 18 | 0 | 0.000 |
| `seir_6_1em4` | `different_basin_likely` | 14 | 2 | 0.143 |

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
| `hiv_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1,top_fit_2` | 19.46% | 19.46% | 2.0390 | 2.0390 |
| `hiv_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 19.46% | 19.46% | 2.0390 | 2.0390 |
| `hiv_4_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 169.34% | 169.34% | 1.9402e+03 | 1.9396e+03 |
| `hiv_4_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,top_fit_2` | 15.31% | 15.31% | 8.3051 | 8.3049 |
| `hiv_4_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 90.35% | 90.35% | 8.3049 | 8.3049 |
| `hiv_4_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_3` | 23.38% | 23.38% | 8.3105 | 8.3049 |
| `hiv_4_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,top_fit_2` | 15.31% | 15.31% | 8.3051 | 8.3049 |
| `hiv_4_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 23.38% | 23.38% | 8.3105 | 8.3049 |
| `hiv_4_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 255.63% | 255.63% | 137.9471 | 75.8914 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 244.57% | 244.57% | 1.2849e+05 | 5.6274e+03 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,top_fit_2` | 35.66% | 35.66% | 2.6629e+05 | 6.9296e+04 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 238.55% | 238.55% | 1.4083e+08 | 1.1400e+08 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_2` | 338.50% | 338.50% | 1.0970e+09 | 1.0349e+06 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_3` | 303.13% | 303.13% | 2.7235e+09 | 7.5181e+04 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 238.55% | 238.55% | 1.4083e+08 | 2.7412e+07 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 338.50% | 338.50% | 1.0970e+09 | 2.4732e+08 |
| `hiv_2_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,top_fit_2` | 10.06% | 10.06% | 4.8567 | 4.8012 |
| `hiv_2_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,top_fit_2` | 10.06% | 10.06% | 4.8567 | 4.8012 |
| `hiv_2_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best` | 14.35% | 14.35% | 4.8012 | 4.8012 |
| `hiv_2_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_selected,top_fit_1,top_fit_2` | 14.98% | 14.98% | 4.8012 | 4.8012 |
| `hiv_2_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_3` | 14.93% | 14.93% | 4.8012 | 4.8012 |
| `hiv_2_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 14.35% | 14.35% | 4.8012 | 4.8012 |
| `hiv_2_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 14.93% | 14.93% | 4.8012 | 4.8012 |
| `hiv_2_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 14.98% | 14.98% | 4.8012 | 4.8012 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 18.28% | 18.28% | 2.7937e-05 | 9.9771e-06 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 18.28% | 18.28% | 2.7937e-05 | 2.7553e-05 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,top_fit_2` | 0.63% | 0.63% | 9.9666e-06 | 9.9665e-06 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 29.92% | 29.92% | 9.9665e-06 | 9.9665e-06 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,top_fit_2` | 0.63% | 0.63% | 9.9666e-06 | 9.9665e-06 |
| `seir_6_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best` | 0.95% | 0.95% | 48.8932 | 48.8932 |
| `seir_6_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_2,top_fit_3` | 1.02% | 1.02% | 48.8932 | 48.8932 |

## Notes

- `summary.tsv` contains one row per transferred seed.
- `case_notes.md` contains from-cold winners and detailed transfer tables per case.
