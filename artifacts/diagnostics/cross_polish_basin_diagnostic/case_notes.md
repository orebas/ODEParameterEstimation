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

## `seir_7_1em4`

- Imported raw candidate count: `298`
- Research box override: `script_standard_positive_box`
- Saved references:
  - `amigo2_run` RMSE: 4.80%
  - `odepe_nopolish` RMSE: 149.27%
  - `odepe_polish` RMSE: 149.27%
- Case diagnosis: `different_basin_likely`

### From-Cold Winners

| Method | Oracle best RMSE | Fit-selected RMSE | Status |
| --- | ---: | ---: | --- |
| `Scalar log-space` | 11.80% | 11.80% | `ok` |
| `Bounded LeastSquaresOptim LM log-space` | 12.65% | 12.65% | `ok` |
| `Bounded FastLevenbergMarquardt log-space` | 10.70% | 14.18% | `ok` |

### Source Seeds

| Method | Roles | Seed RMSE | Seed fit objective |
| --- | --- | ---: | ---: |
| `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 11.80% | 42.1724 |
| `Scalar log-space` | `top_fit_2` | 12.14% | 42.1724 |
| `Scalar log-space` | `top_fit_3` | 12.27% | 42.1724 |
| `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 12.65% | 42.1724 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 159.92% | 42.1725 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 346.47% | 89.6794 |
| `Bounded FastLevenbergMarquardt log-space` | `oracle_best,top_fit_2` | 10.70% | 42.1724 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 14.18% | 42.1724 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 10.93% | 42.1724 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 11.80% | 11.80% | 11.80% | 0.0145 | 0.0145 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 12.14% | 12.14% | 12.14% | 0.0087 | 0.0087 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 12.27% | 12.27% | 12.27% | 0.0065 | 0.0065 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 11.80% | 11.61% | 11.61% | 0.0156 | 0.5144 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 12.14% | 12.00% | 12.00% | 0.0222 | 0.5191 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 12.27% | 12.17% | 12.17% | 0.0251 | 0.5212 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 12.65% | 12.64% | 12.64% | 0.0145 | 0.0145 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_2` | 159.92% | 119.74% | 119.74% | 0.9938 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_3` | 346.47% | 12.65% | 12.65% | 0.0145 | 0.0145 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 12.65% | 12.64% | 12.64% | 0.0333 | 0.5268 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 159.92% | 92.61% | 92.61% | 0.9813 | 0.6564 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 346.47% | 346.47% | 346.47% | 0.8512 | 0.8513 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best,top_fit_2` | 10.70% | 10.45% | 10.45% | 0.0230 | 0.0230 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 14.18% | 9.80% | 9.80% | 0.4136 | 0.4136 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_3` | 10.93% | 10.70% | 10.70% | 0.0186 | 0.0186 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,top_fit_2` | 10.70% | 10.70% | 10.70% | 0.0333 | 0.0333 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 14.18% | 7.64% | 7.64% | 0.3742 | 0.3742 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 10.93% | 10.93% | 10.93% | 0.0293 | 0.0293 | `false` | `true` | `true` | `ok` |

## `hiv_7_1em4`

- Imported raw candidate count: `256`
- Research box override: `script_standard_positive_box`
- Saved references:
  - `amigo2_run` RMSE: 19.46%
  - `odepe_nopolish` RMSE: 540.40%
  - `odepe_polish` RMSE: 135.65%
- Case diagnosis: `mixed`

### From-Cold Winners

| Method | Oracle best RMSE | Fit-selected RMSE | Status |
| --- | ---: | ---: | --- |
| `Scalar log-space` | 19.46% | 19.46% | `ok` |
| `Bounded LeastSquaresOptim LM log-space` | 19.46% | 19.46% | `ok` |
| `Bounded FastLevenbergMarquardt log-space` | 19.46% | 19.46% | `ok` |

### Source Seeds

| Method | Roles | Seed RMSE | Seed fit objective |
| --- | --- | ---: | ---: |
| `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 19.46% | 2.0390 |
| `Scalar log-space` | `top_fit_2` | 7699.92% | 2.0404 |
| `Scalar log-space` | `top_fit_3` | 9283.80% | 2.0463 |
| `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1,top_fit_2` | 19.46% | 2.0390 |
| `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 19.46% | 2.0390 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 19.46% | 19.46% | 19.46% | 9.6197e-06 | 9.6197e-06 | `true` | `false` | `false` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 7699.92% | 43.19% | 43.19% | 0.4757 | 0.4757 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 9283.80% | 417.98% | 9283.80% | 1.0000 | 1.0000 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 19.46% | 19.46% | 19.46% | 9.6197e-06 | 9.6197e-06 | `true` | `false` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 7699.92% | 306.39% | 7699.92% | 1.0000 | 1.0000 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 9283.80% | 409.12% | 9283.80% | 1.0000 | 1.0000 | `false` | `true` | `false` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1,top_fit_2` | 19.46% | 19.46% | 19.46% | 3.1275e-07 | 3.1275e-07 | `true` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1,top_fit_2` | 19.46% | 19.46% | 19.46% | 3.8695e-06 | 3.8695e-06 | `true` | `false` | `false` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 19.46% | 19.46% | 19.46% | 1.1872e-07 | 1.1872e-07 | `true` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 19.46% | 19.46% | 19.46% | 3.8695e-06 | 3.8695e-06 | `true` | `false` | `false` | `ok` |

## `hiv_4_1em4`

- Imported raw candidate count: `172`
- Research box override: `script_standard_positive_box`
- Saved references:
  - `amigo2_run` RMSE: 90.37%
  - `odepe_nopolish` RMSE: 1268.10%
  - `odepe_polish` RMSE: 180.79%
- Case diagnosis: `mixed`

### From-Cold Winners

| Method | Oracle best RMSE | Fit-selected RMSE | Status |
| --- | ---: | ---: | --- |
| `Scalar log-space` | 169.34% | 242.54% | `ok` |
| `Bounded LeastSquaresOptim LM log-space` | 15.31% | 90.35% | `ok` |
| `Bounded FastLevenbergMarquardt log-space` | 90.35% | 90.35% | `ok` |

### Source Seeds

| Method | Roles | Seed RMSE | Seed fit objective |
| --- | --- | ---: | ---: |
| `Scalar log-space` | `oracle_best` | 169.34% | 1.9402e+03 |
| `Scalar log-space` | `fit_selected,top_fit_1` | 242.54% | 12.3378 |
| `Scalar log-space` | `top_fit_2` | 243.93% | 26.1192 |
| `Scalar log-space` | `top_fit_3` | 5057.53% | 55.5404 |
| `Bounded LeastSquaresOptim LM log-space` | `oracle_best,top_fit_2` | 15.31% | 8.3051 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 90.35% | 8.3049 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 23.38% | 8.3105 |
| `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 90.35% | 8.3049 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 338.02% | 136.9255 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 255.63% | 137.9471 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 169.34% | 169.34% | 169.62% | 0.8530 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 242.54% | 90.35% | 90.35% | 0.9981 | 1.1058e-07 | `true` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 243.93% | 90.35% | 90.35% | 0.9981 | 1.1061e-07 | `true` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 5057.53% | 347.30% | 5057.53% | 0.9992 | 0.8651 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 169.34% | 169.30% | 169.34% | 0.9948 | 0.9948 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 242.54% | 90.35% | 90.35% | 5.9258e-08 | 5.9258e-08 | `true` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 243.93% | 90.35% | 90.35% | 5.9063e-08 | 5.9063e-08 | `true` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 5057.53% | 367.33% | 5057.53% | 0.9138 | 0.9138 | `false` | `true` | `false` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,top_fit_2` | 15.31% | 15.31% | 90.35% | 0.8530 | 0.9992 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 90.35% | 90.35% | 90.35% | 1.0000 | 0.4182 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_3` | 23.38% | 23.38% | 90.35% | 1.0000 | 0.7604 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,top_fit_2` | 15.31% | 15.31% | 90.35% | 0.9981 | 0.9981 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 90.35% | 90.35% | 90.35% | 5.1343e-08 | 5.1343e-08 | `true` | `false` | `false` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 23.38% | 23.38% | 90.35% | 0.5018 | 0.5018 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 90.35% | 90.35% | 90.35% | 1.0000 | 0.4182 | `false` | `false` | `false` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_2` | 338.02% | 90.35% | 90.35% | 1.0000 | 0.4182 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_3` | 255.63% | 145.74% | 145.74% | 1.0000 | 0.8892 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 90.35% | 90.35% | 90.35% | 0.9981 | 5.1343e-08 | `true` | `false` | `false` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 338.02% | 90.35% | 90.35% | 0.9981 | 6.7974e-08 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 255.63% | 255.63% | 255.78% | 0.9992 | 0.7845 | `false` | `false` | `true` | `ok` |

## `crauste_7_1em4`

- Imported raw candidate count: `20`
- Research box override: `script_standard_positive_box`
- Saved references:
  - `amigo2_run` RMSE: 19.62%
  - `odepe_nopolish` RMSE: 6445.99%
  - `odepe_polish` RMSE: 167.02%
- Case diagnosis: `different_basin_likely`

### From-Cold Winners

| Method | Oracle best RMSE | Fit-selected RMSE | Status |
| --- | ---: | ---: | --- |
| `Scalar log-space` | 367.80% | 367.80% | `ok` |
| `Bounded LeastSquaresOptim LM log-space` | 35.66% | 244.57% | `ok` |
| `Bounded FastLevenbergMarquardt log-space` | 222.38% | 238.55% | `ok` |

### Source Seeds

| Method | Roles | Seed RMSE | Seed fit objective |
| --- | --- | ---: | ---: |
| `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 367.80% | 2.1200e+07 |
| `Scalar log-space` | `top_fit_2` | 1042.86% | 1.2703e+09 |
| `Scalar log-space` | `top_fit_3` | 1036.57% | 1.5505e+09 |
| `Bounded LeastSquaresOptim LM log-space` | `oracle_best,top_fit_2` | 35.66% | 2.6629e+05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 244.57% | 1.2849e+05 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 170.75% | 3.3440e+07 |
| `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 222.38% | 4.2298e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 238.55% | 1.4083e+08 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 338.50% | 1.0970e+09 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 303.13% | 2.7235e+09 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 367.80% | 244.95% | 244.95% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 1042.86% | 355.89% | 1042.86% | 1.0000 | 0.9801 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 1036.57% | 355.44% | 1036.57% | 1.0000 | 0.9800 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 367.80% | 260.90% | 367.80% | 1.0000 | 1.0000 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 1042.86% | 267.27% | 1042.86% | 1.0000 | 1.0000 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 1036.57% | 332.01% | 332.01% | 0.9969 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,top_fit_2` | 35.66% | 31.35% | 31.35% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 244.57% | 244.57% | 675.52% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_3` | 170.75% | 168.27% | 168.27% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,top_fit_2` | 35.66% | 35.66% | 101.45% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 244.57% | 244.54% | 244.54% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 170.75% | 169.32% | 169.32% | 0.9971 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best` | 222.38% | 77.77% | 77.77% | 0.9979 | 0.9979 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 238.55% | 238.55% | 555.24% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_2` | 338.50% | 338.50% | 1717.38% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_3` | 303.13% | 303.13% | 809.25% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 222.38% | 217.36% | 217.36% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 238.55% | 238.55% | 326.86% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 338.50% | 338.50% | 363.00% | 1.0000 | 0.9688 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 303.13% | 302.47% | 302.47% | 1.0000 | 0.9873 | `false` | `true` | `true` | `ok` |

## `hiv_2_1em4`

- Imported raw candidate count: `251`
- Research box override: `script_standard_positive_box`
- Saved references:
  - `amigo2_run` RMSE: 14.98%
  - `odepe_nopolish` RMSE: 225.67%
  - `odepe_polish` RMSE: 110.31%
- Case diagnosis: `mixed`

### From-Cold Winners

| Method | Oracle best RMSE | Fit-selected RMSE | Status |
| --- | ---: | ---: | --- |
| `Scalar log-space` | 10.06% | 16.17% | `ok` |
| `Bounded LeastSquaresOptim LM log-space` | 14.35% | 14.98% | `ok` |
| `Bounded FastLevenbergMarquardt log-space` | 14.98% | 14.98% | `ok` |

### Source Seeds

| Method | Roles | Seed RMSE | Seed fit objective |
| --- | --- | ---: | ---: |
| `Scalar log-space` | `oracle_best,top_fit_2` | 10.06% | 4.8567 |
| `Scalar log-space` | `fit_selected,top_fit_1` | 16.17% | 4.8014 |
| `Scalar log-space` | `top_fit_3` | 15.75% | 4.8664 |
| `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 14.35% | 4.8012 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1,top_fit_2` | 14.98% | 4.8012 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 14.93% | 4.8012 |
| `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 14.98% | 4.8012 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,top_fit_2` | 10.06% | 10.06% | 14.98% | 0.3404 | 0.3645 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 16.17% | 14.98% | 14.98% | 0.0242 | 2.9228e-07 | `true` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 15.75% | 14.98% | 14.98% | 0.0242 | 2.9227e-07 | `true` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,top_fit_2` | 10.06% | 10.06% | 14.98% | 0.3645 | 0.3645 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 16.17% | 14.98% | 14.98% | 3.6473e-08 | 3.6473e-08 | `true` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 15.75% | 14.98% | 14.98% | 0.0013 | 0.0013 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best` | 14.35% | 14.35% | 14.98% | 0.3404 | 0.3858 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_selected,top_fit_1,top_fit_2` | 14.98% | 14.98% | 14.98% | 0.3645 | 0.3858 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_3` | 14.93% | 14.93% | 14.98% | 0.3626 | 0.3858 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 14.35% | 14.35% | 14.98% | 0.0242 | 0.0242 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1,top_fit_2` | 14.98% | 14.98% | 14.98% | 2.9227e-07 | 2.9227e-07 | `true` | `false` | `false` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 14.93% | 14.93% | 14.98% | 0.0019 | 0.0019 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 14.98% | 14.98% | 14.98% | 0.3645 | 0.3858 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 14.98% | 14.98% | 14.98% | 0.0242 | 2.9227e-07 | `true` | `false` | `false` | `ok` |

## `daisy_mamil4_1_1em4`

- Imported raw candidate count: `132`
- Research box override: `script_standard_positive_box`
- Saved references:
  - `amigo2_run` RMSE: 1.17%
  - `odepe_nopolish` RMSE: 42.13%
  - `odepe_polish` RMSE: 41.05%
- Case diagnosis: `different_basin_likely`

### From-Cold Winners

| Method | Oracle best RMSE | Fit-selected RMSE | Status |
| --- | ---: | ---: | --- |
| `Scalar log-space` | 18.28% | 45.73% | `ok` |
| `Bounded LeastSquaresOptim LM log-space` | 0.63% | 29.92% | `ok` |
| `Bounded FastLevenbergMarquardt log-space` | 6.77% | 6.77% | `ok` |

### Source Seeds

| Method | Roles | Seed RMSE | Seed fit objective |
| --- | --- | ---: | ---: |
| `Scalar log-space` | `oracle_best` | 18.28% | 2.7937e-05 |
| `Scalar log-space` | `fit_selected,top_fit_1` | 45.73% | 1.1083e-05 |
| `Scalar log-space` | `top_fit_2,top_fit_3` | 50.46% | 1.1083e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `oracle_best,top_fit_2` | 0.63% | 9.9666e-06 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 29.92% | 9.9665e-06 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 33.46% | 1.0094e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 6.77% | 9.9696e-06 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 14.34% | 9.9915e-06 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 21.47% | 1.0057e-05 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 18.28% | 18.28% | 22.38% | 0.5347 | 0.9437 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 45.73% | 45.47% | 45.47% | 0.8186 | 0.8645 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2,top_fit_3` | 50.46% | 50.28% | 50.28% | 0.8629 | 0.9411 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 18.28% | 18.28% | 18.28% | 0.6578 | 0.6578 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 45.73% | 45.61% | 45.61% | 0.6811 | 0.6811 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2,top_fit_3` | 50.46% | 50.36% | 50.36% | 0.8829 | 0.8829 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,top_fit_2` | 0.63% | 0.63% | 1.17% | 0.5347 | 0.8213 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 29.92% | 29.92% | 29.92% | 0.9437 | 0.8651 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_3` | 33.46% | 30.36% | 30.36% | 0.6096 | 0.9216 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,top_fit_2` | 0.63% | 0.63% | 1.17% | 0.1032 | 0.1032 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 29.92% | 29.92% | 29.92% | 0.6198 | 0.6198 | `false` | `false` | `false` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 33.46% | 28.83% | 28.83% | 0.6616 | 0.6616 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 6.77% | 2.63% | 2.63% | 0.5766 | 0.7757 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_2` | 14.34% | 8.91% | 8.91% | 0.6968 | 0.6343 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_3` | 21.47% | 15.75% | 15.75% | 0.8033 | 0.4832 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 6.77% | 1.26% | 1.26% | 0.0124 | 0.5445 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 14.34% | 4.99% | 4.99% | 0.0769 | 0.5935 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 21.47% | 11.07% | 11.07% | 0.1673 | 0.6929 | `false` | `true` | `true` | `ok` |

## `seir_6_1em4`

- Imported raw candidate count: `276`
- Research box override: `script_standard_positive_box`
- Saved references:
  - `amigo2_run` RMSE: 1.33%
  - `odepe_nopolish` RMSE: 162.09%
  - `odepe_polish` RMSE: 82.04%
- Case diagnosis: `different_basin_likely`

### From-Cold Winners

| Method | Oracle best RMSE | Fit-selected RMSE | Status |
| --- | ---: | ---: | --- |
| `Scalar log-space` | 34.31% | 34.31% | `ok` |
| `Bounded LeastSquaresOptim LM log-space` | 11.51% | 11.51% | `ok` |
| `Bounded FastLevenbergMarquardt log-space` | 0.95% | 1.33% | `ok` |

### Source Seeds

| Method | Roles | Seed RMSE | Seed fit objective |
| --- | --- | ---: | ---: |
| `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 34.31% | 48.8932 |
| `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 11.51% | 48.8932 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_2` | 13.97% | 48.8932 |
| `Bounded LeastSquaresOptim LM log-space` | `top_fit_3` | 499.45% | 49.2198 |
| `Bounded FastLevenbergMarquardt log-space` | `oracle_best` | 0.95% | 48.8932 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_selected,top_fit_1` | 1.33% | 48.8932 |
| `Bounded FastLevenbergMarquardt log-space` | `top_fit_2,top_fit_3` | 1.02% | 48.8932 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best,fit_selected,top_fit_1` | 34.31% | 34.31% | 34.31% | 0.7181 | 0.7181 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 34.31% | 34.31% | 34.31% | 0.5079 | 0.5152 | `false` | `true` | `false` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `oracle_best,fit_selected,top_fit_1` | 11.51% | 1.59% | 1.59% | 0.5205 | 0.5205 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_2` | 13.97% | 1.92% | 1.92% | 0.5270 | 0.5270 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `top_fit_3` | 499.45% | 44.39% | 44.39% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `oracle_best,fit_selected,top_fit_1` | 11.51% | 1.33% | 1.33% | 0.0072 | 4.2176e-08 | `true` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_2` | 13.97% | 1.33% | 1.33% | 0.0072 | 1.8400e-06 | `true` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `top_fit_3` | 499.45% | 23.52% | 23.52% | 0.3088 | 0.3023 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `oracle_best` | 0.95% | 0.95% | 1.32% | 0.5079 | 0.5079 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_selected,top_fit_1` | 1.33% | 1.33% | 1.33% | 0.5152 | 0.5152 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `top_fit_2,top_fit_3` | 1.02% | 1.02% | 1.33% | 0.5093 | 0.5093 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `oracle_best` | 0.95% | 0.95% | 0.95% | 0.1715 | 0.1715 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_selected,top_fit_1` | 1.33% | 1.33% | 1.33% | 0.1645 | 0.1645 | `false` | `false` | `false` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `top_fit_2,top_fit_3` | 1.02% | 1.02% | 1.02% | 0.1701 | 0.1701 | `false` | `true` | `true` | `ok` |

