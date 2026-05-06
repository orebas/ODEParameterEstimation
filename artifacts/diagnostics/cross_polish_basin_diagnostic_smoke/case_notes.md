# Cross-Polish Case Notes

## `seir_3_1em4`

- Imported raw candidate count: `345`
- Research box override: `script_standard_positive_box`
- Saved references:
  - `amigo2_run` RMSE: 7.04%
  - `odepe_nopolish` RMSE: 322.86%
  - `odepe_polish` RMSE: 30.19%
- Case diagnosis: `different_basin_likely`

### From-Cold Winners

| Method | Oracle best RMSE | Fit-selected RMSE | Status |
| --- | ---: | ---: | --- |
| `Scalar log-space` | 1.04% | 8.11% | `ok` |
| `Bounded LeastSquaresOptim LM log-space` | 27.90% | 27.90% | `ok` |
| `Bounded FastLevenbergMarquardt log-space` | 3.89% | 5.05% | `ok` |

### Source Seeds

| Method | Roles | Seed RMSE | Seed fit objective |
| --- | --- | ---: | ---: |
| `Scalar log-space` | `oracle_best` | 1.04% | 5.9881 |
| `Scalar log-space` | `fit_selected,top_fit_1` | 8.11% | 5.9881 |
| `Scalar log-space` | `top_fit_2` | 5.03% | 5.9881 |
| `Scalar log-space` | `top_fit_3` | 4.74% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 27.90% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 27.97% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 28.20% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 3.89% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 5.05% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 4.92% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 4.00% | 5.9881 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 1.04% | 1.04% | 1.04% | 0.3932 | 0.3932 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 8.11% | 8.11% | 8.11% | 0.3874 | 0.3874 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 5.03% | 5.03% | 5.03% | 0.3825 | 0.3825 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 4.74% | 4.74% | 4.74% | 0.3840 | 0.3840 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 1.04% | 1.04% | 1.04% | 0.0710 | 0.0875 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 8.11% | 7.54% | 7.54% | 0.0512 | 0.0346 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 5.03% | 5.03% | 6.56% | 0.0162 | 3.9527e-04 | `true` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 4.74% | 4.74% | 6.00% | 0.1241 | 0.1403 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 27.90% | 23.14% | 23.14% | 0.3102 | 0.3690 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_2` | 27.97% | 23.18% | 23.18% | 0.3110 | 0.3692 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_3` | 28.20% | 23.33% | 23.33% | 0.3138 | 0.3699 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 27.90% | 20.40% | 20.40% | 0.3008 | 0.3158 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 27.97% | 20.42% | 20.42% | 0.3009 | 0.3159 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 28.20% | 20.52% | 20.52% | 0.3016 | 0.3166 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best` | 3.89% | 3.89% | 5.16% | 0.0710 | 0.0590 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 5.05% | 5.05% | 5.94% | 0.0875 | 0.0424 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_2` | 4.92% | 4.92% | 5.80% | 0.0856 | 0.0443 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_3` | 4.00% | 4.00% | 5.02% | 0.0726 | 0.0574 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 3.89% | 3.89% | 3.89% | 0.3866 | 0.3866 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 5.05% | 5.05% | 5.05% | 0.3824 | 0.3824 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 4.92% | 4.92% | 4.92% | 0.3829 | 0.3829 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 4.00% | 4.00% | 4.00% | 0.3862 | 0.3862 | `false` | `true` | `true` | `ok` |

