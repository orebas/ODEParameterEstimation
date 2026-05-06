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
| `Scalar log-space` | `fit_rank_1` | 8.11% | 5.9881 |
| `Scalar log-space` | `fit_rank_2` | 5.03% | 5.9881 |
| `Scalar log-space` | `fit_rank_3` | 4.74% | 5.9881 |
| `Scalar log-space` | `fit_rank_4` | 1.04% | 5.9881 |
| `Scalar log-space` | `fit_rank_5` | 21.89% | 5.9881 |
| `Scalar log-space` | `fit_rank_6` | 25.71% | 5.9881 |
| `Scalar log-space` | `fit_rank_7` | 33.28% | 5.9881 |
| `Scalar log-space` | `fit_rank_8` | 34.35% | 5.9881 |
| `Scalar log-space` | `fit_rank_9` | 37.40% | 5.9881 |
| `Scalar log-space` | `fit_rank_10` | 33.39% | 5.9881 |
| `Scalar log-space` | `fit_rank_11` | 52.35% | 5.9881 |
| `Scalar log-space` | `fit_rank_12` | 50.63% | 5.9881 |
| `Scalar log-space` | `fit_rank_13,fit_rank_14` | 50.90% | 5.9881 |
| `Scalar log-space` | `fit_rank_15` | 70.84% | 5.9881 |
| `Scalar log-space` | `fit_rank_16` | 51.21% | 5.9881 |
| `Scalar log-space` | `fit_rank_17` | 71.13% | 5.9881 |
| `Scalar log-space` | `fit_rank_18` | 51.99% | 5.9881 |
| `Scalar log-space` | `fit_rank_19` | 72.11% | 5.9881 |
| `Scalar log-space` | `fit_rank_20` | 52.53% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 27.90% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 27.97% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_3` | 28.20% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 28.36% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 43.99% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_6,fit_rank_7` | 28.72% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8,fit_rank_9` | 30.17% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10` | 30.57% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_11` | 30.90% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_12` | 31.61% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13` | 32.06% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_14` | 34.97% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_15` | 35.94% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 54.43% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_17,fit_rank_18,fit_rank_20` | 36.55% | 5.9881 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_19` | 54.61% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_1` | 5.05% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 4.92% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_3` | 4.00% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 3.89% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 10.48% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6` | 15.85% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_7` | 15.24% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8` | 20.29% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_9` | 18.28% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10` | 18.64% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 19.04% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_12` | 21.67% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 25.13% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_14` | 38.81% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_15` | 40.05% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 47.85% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_17,fit_rank_18` | 48.76% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_19` | 50.18% | 5.9881 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_20` | 33.11% | 5.9881 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 8.11% | 8.11% | 8.11% | 0.3874 | 0.3874 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 5.03% | 5.03% | 5.03% | 0.3825 | 0.3825 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_3` | 4.74% | 4.74% | 4.74% | 0.3840 | 0.3840 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 1.04% | 1.04% | 1.04% | 0.3932 | 0.3932 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 21.89% | 16.23% | 16.23% | 0.4723 | 0.4723 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_6` | 25.71% | 18.94% | 18.94% | 0.4964 | 0.4964 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_7` | 33.28% | 24.22% | 24.22% | 0.5378 | 0.5378 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8` | 34.35% | 24.95% | 24.95% | 0.5429 | 0.5429 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_9` | 37.40% | 26.93% | 26.93% | 0.5563 | 0.5563 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10` | 33.39% | 22.66% | 22.66% | 0.1048 | 0.1048 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_11` | 52.35% | 35.41% | 35.41% | 0.6045 | 0.6045 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_12` | 50.63% | 27.44% | 27.44% | 0.0084 | 0.0084 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13,fit_rank_14` | 50.90% | 27.50% | 27.50% | 0.0074 | 0.0074 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_15` | 70.84% | 42.65% | 42.65% | 0.6358 | 0.6358 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 51.21% | 27.56% | 27.56% | 0.0062 | 0.0062 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_17` | 71.13% | 42.73% | 42.73% | 0.6361 | 0.6361 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_18` | 51.99% | 27.71% | 27.71% | 0.0034 | 0.0034 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_19` | 72.11% | 43.00% | 43.00% | 0.6371 | 0.6371 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_20` | 52.53% | 27.81% | 27.81% | 0.0016 | 0.0016 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_1` | 8.11% | 7.54% | 7.54% | 0.0512 | 0.0346 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 5.03% | 5.03% | 6.56% | 0.0162 | 3.9527e-04 | `true` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_3` | 4.74% | 4.74% | 6.00% | 0.1241 | 0.1403 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 1.04% | 1.04% | 1.04% | 0.0710 | 0.0875 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 21.89% | 16.31% | 16.31% | 0.1628 | 0.1466 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6` | 25.71% | 18.88% | 18.88% | 0.1917 | 0.1757 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_7` | 33.28% | 24.39% | 24.39% | 0.2478 | 0.2321 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8` | 34.35% | 25.04% | 25.04% | 0.2538 | 0.2382 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_9` | 37.40% | 26.96% | 26.96% | 0.2712 | 0.2557 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10` | 33.39% | 23.16% | 23.16% | 0.3170 | 0.3318 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 52.35% | 35.77% | 35.77% | 0.3393 | 0.3246 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_12` | 50.63% | 28.29% | 28.29% | 0.3926 | 0.3884 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13,fit_rank_14` | 50.90% | 28.31% | 28.31% | 0.3929 | 0.3888 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_15` | 70.84% | 43.78% | 43.78% | 0.3952 | 0.3911 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 51.21% | 27.47% | 27.47% | 0.3799 | 0.3757 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_17` | 71.13% | 43.80% | 43.80% | 0.3954 | 0.3912 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_18` | 51.99% | 27.61% | 27.61% | 0.3820 | 0.3778 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_19` | 72.11% | 44.11% | 44.11% | 0.3985 | 0.3944 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_20` | 52.53% | 28.65% | 28.65% | 0.3981 | 0.3940 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_1` | 27.90% | 23.14% | 23.14% | 0.3102 | 0.3690 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_2` | 27.97% | 23.18% | 23.18% | 0.3110 | 0.3692 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_3` | 28.20% | 23.33% | 23.33% | 0.3138 | 0.3699 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_4` | 28.36% | 23.43% | 23.43% | 0.3157 | 0.3703 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_5` | 43.99% | 36.13% | 36.13% | 0.4029 | 0.2931 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_6,fit_rank_7` | 28.72% | 23.64% | 23.64% | 0.3199 | 0.3714 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_8,fit_rank_9` | 30.17% | 24.39% | 24.39% | 0.3339 | 0.3747 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_10` | 30.57% | 24.74% | 24.74% | 0.3402 | 0.3762 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_11` | 30.90% | 24.94% | 24.94% | 0.3438 | 0.3770 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_12` | 31.61% | 25.33% | 25.33% | 0.3508 | 0.3785 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_13` | 32.06% | 25.48% | 25.48% | 0.3534 | 0.3791 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_14` | 34.97% | 27.00% | 27.00% | 0.3791 | 0.3846 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_15` | 35.94% | 27.50% | 27.50% | 0.3870 | 0.3862 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_16` | 54.43% | 43.09% | 43.09% | 0.4425 | 0.3691 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_17,fit_rank_18,fit_rank_20` | 36.55% | 27.80% | 27.80% | 0.3918 | 0.3871 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_19` | 54.61% | 43.22% | 43.22% | 0.4431 | 0.3704 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_1` | 27.90% | 20.40% | 20.40% | 0.3008 | 0.3158 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 27.97% | 20.42% | 20.42% | 0.3009 | 0.3159 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_3` | 28.20% | 20.52% | 20.52% | 0.3016 | 0.3166 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 28.36% | 20.60% | 20.60% | 0.3022 | 0.3171 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 43.99% | 31.48% | 31.48% | 0.3084 | 0.2933 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6,fit_rank_7` | 28.72% | 20.80% | 20.80% | 0.3035 | 0.3184 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8,fit_rank_9` | 30.17% | 21.33% | 21.33% | 0.3068 | 0.3217 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10` | 30.57% | 21.48% | 21.48% | 0.3077 | 0.3226 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 30.90% | 21.56% | 21.56% | 0.3082 | 0.3231 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_12` | 31.61% | 22.41% | 22.41% | 0.3130 | 0.3279 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 32.06% | 22.64% | 22.64% | 0.3143 | 0.3291 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_14` | 34.97% | 23.55% | 23.55% | 0.3190 | 0.3338 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_15` | 35.94% | 23.88% | 23.88% | 0.3205 | 0.3353 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 54.43% | 36.63% | 36.63% | 0.3451 | 0.3304 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_17,fit_rank_18,fit_rank_20` | 36.55% | 24.05% | 24.05% | 0.3213 | 0.3361 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_19` | 54.61% | 36.72% | 36.72% | 0.3457 | 0.3310 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_1` | 5.05% | 5.05% | 5.94% | 0.0875 | 0.0424 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_2` | 4.92% | 4.92% | 5.80% | 0.0856 | 0.0443 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_3` | 4.00% | 4.00% | 5.02% | 0.0726 | 0.0574 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_4` | 3.89% | 3.89% | 5.16% | 0.0710 | 0.0590 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_5` | 10.48% | 9.20% | 9.20% | 0.1439 | 0.0148 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_6` | 15.85% | 13.13% | 13.13% | 0.1938 | 0.0660 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_7` | 15.24% | 12.97% | 12.97% | 0.1637 | 0.2870 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_8` | 20.29% | 17.11% | 17.11% | 0.2400 | 0.1142 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_9` | 18.28% | 16.05% | 16.05% | 0.1944 | 0.3190 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_10` | 18.64% | 16.41% | 16.41% | 0.1973 | 0.3223 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_11` | 19.04% | 16.72% | 16.72% | 0.1998 | 0.3251 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_12` | 21.67% | 18.75% | 18.75% | 0.2142 | 0.3419 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_13` | 25.13% | 20.85% | 20.85% | 0.2637 | 0.3564 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_14` | 38.81% | 32.25% | 32.25% | 0.3768 | 0.2601 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_15` | 40.05% | 33.21% | 33.21% | 0.3836 | 0.2674 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_16` | 47.85% | 38.75% | 38.75% | 0.4189 | 0.3224 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_17,fit_rank_18` | 48.76% | 39.10% | 39.10% | 0.4209 | 0.3262 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_19` | 50.18% | 40.36% | 40.36% | 0.4280 | 0.3399 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_20` | 33.11% | 25.64% | 25.64% | 0.3562 | 0.3797 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 5.05% | 5.05% | 5.05% | 0.3824 | 0.3824 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 4.92% | 4.92% | 4.92% | 0.3829 | 0.3829 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_3` | 4.00% | 4.00% | 4.00% | 0.3862 | 0.3862 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 3.89% | 3.89% | 3.89% | 0.3866 | 0.3866 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 10.48% | 10.48% | 10.48% | 0.4141 | 0.4141 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_6` | 15.85% | 11.95% | 11.95% | 0.4299 | 0.4299 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_7` | 15.24% | 12.23% | 12.23% | 0.3146 | 0.3146 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8` | 20.29% | 15.15% | 15.15% | 0.4620 | 0.4620 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_9` | 18.28% | 14.52% | 14.52% | 0.2770 | 0.2770 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10` | 18.64% | 14.80% | 14.80% | 0.2719 | 0.2719 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_11` | 19.04% | 15.11% | 15.11% | 0.2662 | 0.2662 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_12` | 21.67% | 16.88% | 16.88% | 0.2311 | 0.2311 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13` | 25.13% | 18.97% | 18.97% | 0.1862 | 0.1862 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_14` | 38.81% | 27.78% | 27.78% | 0.5618 | 0.5618 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_15` | 40.05% | 28.51% | 28.51% | 0.5664 | 0.5664 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 47.85% | 33.11% | 33.11% | 0.5928 | 0.5928 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_17,fit_rank_18` | 48.76% | 33.61% | 33.61% | 0.5954 | 0.5954 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_19` | 50.18% | 34.35% | 34.35% | 0.5993 | 0.5993 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_20` | 33.11% | 22.55% | 22.55% | 0.1072 | 0.1072 | `false` | `true` | `true` | `ok` |

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
| `Scalar log-space` | `fit_rank_1` | 45.73% | 1.1083e-05 |
| `Scalar log-space` | `fit_rank_2,fit_rank_3,fit_rank_4` | 50.46% | 1.1083e-05 |
| `Scalar log-space` | `fit_rank_5` | 50.59% | 1.1089e-05 |
| `Scalar log-space` | `fit_rank_6` | 52.59% | 1.7519e-05 |
| `Scalar log-space` | `fit_rank_7` | 52.59% | 1.9079e-05 |
| `Scalar log-space` | `fit_rank_8` | 41.05% | 2.6963e-05 |
| `Scalar log-space` | `fit_rank_9` | 58.08% | 2.7564e-05 |
| `Scalar log-space` | `fit_rank_10` | 18.28% | 2.7937e-05 |
| `Scalar log-space` | `fit_rank_11` | 43.29% | 3.2558e-05 |
| `Scalar log-space` | `fit_rank_12` | 27.69% | 1.1850e-04 |
| `Scalar log-space` | `fit_rank_13` | 26.26% | 1.6180e-04 |
| `Scalar log-space` | `fit_rank_14` | 34.30% | 1.9827e-04 |
| `Scalar log-space` | `fit_rank_15` | 34.69% | 5.8419e-04 |
| `Scalar log-space` | `fit_rank_16` | 29.86% | 6.0335e-04 |
| `Scalar log-space` | `fit_rank_17` | 37.01% | 6.0398e-04 |
| `Scalar log-space` | `fit_rank_18` | 34.05% | 6.8982e-04 |
| `Scalar log-space` | `fit_rank_19` | 36.89% | 6.9062e-04 |
| `Scalar log-space` | `fit_rank_20` | 34.02% | 7.0741e-04 |
| `Scalar log-space` | `fit_rank_21` | 36.32% | 7.7800e-04 |
| `Scalar log-space` | `fit_rank_22` | 275.03% | 0.0011 |
| `Scalar log-space` | `fit_rank_23` | 235.27% | 0.0012 |
| `Scalar log-space` | `fit_rank_24` | 34.72% | 0.0013 |
| `Scalar log-space` | `fit_rank_25` | 184.38% | 0.0014 |
| `Scalar log-space` | `fit_rank_26` | 34.79% | 0.0014 |
| `Scalar log-space` | `fit_rank_27` | 39.66% | 0.0014 |
| `Scalar log-space` | `fit_rank_28` | 34.80% | 0.0014 |
| `Scalar log-space` | `fit_rank_29` | 39.72% | 0.0014 |
| `Scalar log-space` | `fit_rank_30` | 39.77% | 0.0014 |
| `Scalar log-space` | `fit_rank_31` | 34.74% | 0.0014 |
| `Scalar log-space` | `fit_rank_32` | 34.69% | 0.0014 |
| `Scalar log-space` | `fit_rank_33` | 39.86% | 0.0014 |
| `Scalar log-space` | `fit_rank_34` | 208.76% | 0.0014 |
| `Scalar log-space` | `fit_rank_35` | 162.39% | 0.0023 |
| `Scalar log-space` | `fit_rank_36` | 78.47% | 0.0024 |
| `Scalar log-space` | `fit_rank_37,fit_rank_38,fit_rank_39,fit_rank_40,fit_rank_43,fit_rank_45,fit_rank_46,fit_rank_49,fit_rank_53,fit_rank_54,fit_rank_55,fit_rank_60,fit_rank_61,fit_rank_62,fit_rank_65,fit_rank_67,fit_rank_68,fit_rank_69,fit_rank_73,fit_rank_75` | 40.65% | 0.0024 |
| `Scalar log-space` | `fit_rank_41,fit_rank_42,fit_rank_44,fit_rank_47,fit_rank_48,fit_rank_50,fit_rank_51,fit_rank_52,fit_rank_56,fit_rank_57,fit_rank_58,fit_rank_59,fit_rank_63,fit_rank_64,fit_rank_66,fit_rank_70,fit_rank_71,fit_rank_72,fit_rank_74` | 36.40% | 0.0024 |
| `Scalar log-space` | `fit_rank_76` | 36.39% | 0.0024 |
| `Scalar log-space` | `fit_rank_77` | 40.61% | 0.0024 |
| `Scalar log-space` | `fit_rank_78` | 30.64% | 0.0072 |
| `Scalar log-space` | `fit_rank_79` | 32.12% | 0.0124 |
| `Scalar log-space` | `fit_rank_80` | 1919.06% | 0.0140 |
| `Scalar log-space` | `fit_rank_81` | 37.99% | 0.0150 |
| `Scalar log-space` | `fit_rank_82` | 11651.74% | 0.0414 |
| `Scalar log-space` | `fit_rank_83` | 22709.20% | 0.0449 |
| `Scalar log-space` | `fit_rank_84` | 27905.37% | 0.0477 |
| `Scalar log-space` | `fit_rank_85` | 26756.05% | 0.0500 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 29.92% | 9.9665e-06 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 0.63% | 9.9666e-06 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_3` | 33.46% | 1.0094e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 27.01% | 1.0163e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 38.92% | 1.0298e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_6` | 34.37% | 1.0412e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_7` | 36.17% | 1.0494e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8` | 36.72% | 1.0521e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_9` | 38.68% | 1.0624e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10` | 45.16% | 1.0664e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_11` | 45.37% | 1.0673e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_12` | 45.51% | 1.0687e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13` | 48.56% | 1.0918e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_14` | 49.11% | 1.0964e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_15` | 44.76% | 1.1011e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 50.19% | 1.1059e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_17` | 45.59% | 1.1072e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_18,fit_rank_19` | 45.73% | 1.1083e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_20` | 35.21% | 1.6595e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_21` | 10.22% | 2.0818e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_22` | 33.86% | 4.4938e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_23` | 34.38% | 4.6733e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_24` | 48.33% | 5.1793e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_25` | 56.30% | 5.5924e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_26` | 68.87% | 9.9396e-05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_27` | 47.10% | 1.1365e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_28` | 76.81% | 1.3892e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_29` | 54.03% | 1.4614e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_30` | 84.45% | 1.7629e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_31` | 60.10% | 1.7697e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_32` | 92.26% | 2.1275e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_33` | 96.77% | 2.3300e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_34` | 72.53% | 2.3518e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_35` | 31.47% | 4.1314e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_36` | 32.42% | 4.3938e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_37` | 25.86% | 4.5438e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_38` | 31.48% | 4.9779e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_39` | 31.52% | 5.1237e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_40` | 31.53% | 5.1344e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_41` | 31.13% | 5.1396e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_42` | 31.81% | 5.1855e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_43,fit_rank_44` | 31.82% | 5.2422e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_45` | 31.94% | 5.3013e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_46` | 31.94% | 5.3026e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_47` | 31.90% | 5.3094e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_48` | 31.88% | 5.3127e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_49` | 33.65% | 5.3209e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_50` | 33.68% | 5.3295e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_51` | 31.82% | 5.3303e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_52` | 31.77% | 5.3305e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_53` | 31.39% | 5.3355e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_54` | 33.74% | 5.3365e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_55` | 33.73% | 5.3420e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_56,fit_rank_57,fit_rank_58` | 33.76% | 5.3432e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_59` | 31.75% | 5.3451e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_60` | 33.78% | 5.3486e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_61` | 31.69% | 5.3507e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_62` | 33.77% | 5.3512e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_63,fit_rank_64,fit_rank_70` | 33.81% | 5.3522e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_65,fit_rank_66` | 33.79% | 5.3532e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_67` | 31.66% | 5.3547e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_68,fit_rank_72` | 33.83% | 5.3590e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_69` | 33.85% | 5.3604e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_71` | 31.65% | 5.3669e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_73` | 31.66% | 5.3698e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_74` | 33.88% | 5.3713e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_75` | 33.92% | 5.3757e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_76` | 31.66% | 5.3774e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_77` | 31.69% | 5.3800e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_78` | 31.62% | 5.3802e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_79,fit_rank_83` | 31.64% | 5.3834e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_80` | 31.64% | 5.3853e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_81` | 33.96% | 5.3897e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_82` | 31.64% | 5.3902e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_84` | 31.64% | 5.3959e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_85` | 31.66% | 5.3960e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_86` | 33.99% | 5.3977e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_87` | 34.07% | 5.3985e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_88` | 31.63% | 5.4026e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_89` | 34.01% | 5.4026e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_90,fit_rank_93` | 34.06% | 5.4051e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_91` | 33.99% | 5.4082e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_92` | 33.96% | 5.4169e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_94,fit_rank_98` | 34.16% | 5.4233e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_95` | 34.12% | 5.4241e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_96` | 31.69% | 5.4263e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_97` | 31.61% | 5.4266e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_99` | 31.66% | 5.4336e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_100` | 31.70% | 5.4406e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_101` | 34.24% | 5.4466e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_102` | 31.64% | 5.4543e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_103` | 31.73% | 5.4644e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_104` | 31.79% | 5.4879e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_105` | 33.40% | 5.4938e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_106` | 31.86% | 5.5431e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_107` | 34.53% | 5.5475e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_108` | 34.82% | 5.5894e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_109` | 31.99% | 5.6358e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_110` | 35.06% | 5.6597e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_111` | 35.28% | 5.7406e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_112` | 33.11% | 6.0823e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_113` | 33.58% | 6.3980e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_114` | 35.90% | 6.4421e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_115` | 34.20% | 9.0956e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_116` | 38.41% | 9.8450e-04 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_117` | 31.39% | 0.0011 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_118` | 36.58% | 0.0022 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_119` | 36.38% | 0.0024 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_120,fit_rank_121,fit_rank_131` | 40.65% | 0.0024 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_122,fit_rank_123` | 36.40% | 0.0024 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_124,fit_rank_125` | 283.00% | 0.0024 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_126,fit_rank_129,fit_rank_130` | 301.06% | 0.0024 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_127,fit_rank_128` | 301.06% | 0.0024 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_132` | 413.71% | 0.1170 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_1` | 6.77% | 9.9696e-06 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 14.34% | 9.9915e-06 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_3` | 21.47% | 1.0057e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 21.70% | 1.0060e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 26.32% | 1.0147e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6` | 36.01% | 1.0202e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_7` | 32.35% | 1.0437e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8` | 37.34% | 1.0553e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_9` | 43.42% | 1.0588e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10,fit_rank_11,fit_rank_12` | 38.44% | 1.0617e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 38.70% | 1.0626e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_14` | 44.82% | 1.0641e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_15` | 39.18% | 1.0660e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 45.17% | 1.0662e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_17,fit_rank_18,fit_rank_19` | 39.34% | 1.0670e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_20,fit_rank_21` | 39.58% | 1.0684e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_22` | 39.96% | 1.0698e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_23,fit_rank_24` | 45.91% | 1.0718e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_25` | 40.58% | 1.0735e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_26` | 46.17% | 1.0739e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_27,fit_rank_36` | 46.39% | 1.0757e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_28` | 40.08% | 1.0759e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_29,fit_rank_31` | 46.61% | 1.0764e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_30` | 46.54% | 1.0767e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_32` | 46.78% | 1.0786e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_33,fit_rank_34` | 46.90% | 1.0786e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_35` | 47.07% | 1.0810e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_37,fit_rank_38,fit_rank_39,fit_rank_40` | 47.51% | 1.0834e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_41,fit_rank_42` | 47.60% | 1.0839e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_43` | 47.92% | 1.0865e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_44` | 48.01% | 1.0872e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_45` | 42.98% | 1.0886e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_46` | 43.20% | 1.0911e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_47` | 49.09% | 1.0962e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_48` | 49.46% | 1.0995e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_49` | 44.76% | 1.1011e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_50,fit_rank_51` | 50.54% | 1.1111e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_52` | 55.14% | 1.8203e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_53` | 56.20% | 2.3810e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_54` | 53.73% | 2.4585e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_55` | 52.17% | 2.9993e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_56` | 57.76% | 3.5716e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_57` | 57.65% | 4.3706e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_58` | 59.07% | 4.9483e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_59` | 47.92% | 5.4797e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_60` | 14.16% | 6.0952e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_61` | 64.72% | 6.6511e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_62` | 43.38% | 9.1919e-05 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_63` | 78.82% | 1.3583e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_64` | 44.81% | 1.6428e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_65` | 81.47% | 1.8203e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_66` | 86.61% | 2.1338e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_67` | 87.12% | 2.2505e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_68` | 65.05% | 2.2827e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_69` | 88.52% | 2.3074e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_70` | 64.42% | 2.3169e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_71` | 92.84% | 2.3366e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_72` | 87.89% | 2.3368e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_73` | 73.40% | 2.3793e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_74` | 65.55% | 2.3818e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_75` | 68.64% | 2.3840e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_76` | 91.51% | 2.3934e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_77` | 88.65% | 2.4003e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_78` | 63.81% | 2.4071e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_79` | 89.43% | 2.4137e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_80` | 94.15% | 2.4271e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_81` | 83.72% | 2.4686e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_82` | 63.48% | 2.4915e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_83` | 61.78% | 2.5216e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_84` | 63.47% | 2.5648e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_85` | 81.98% | 2.5851e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_86` | 80.72% | 2.6301e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_87` | 81.02% | 2.6403e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_88` | 80.48% | 2.6524e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_89` | 79.57% | 2.6748e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_90` | 59.44% | 2.7252e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_91` | 58.36% | 2.7666e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_92` | 76.20% | 2.7719e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_93` | 74.52% | 2.8560e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_94` | 57.61% | 2.9245e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_95` | 57.59% | 2.9587e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_96` | 56.11% | 2.9757e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_97` | 103.85% | 3.1116e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_98` | 60.64% | 3.3452e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_99` | 70.96% | 3.5186e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_100` | 131.71% | 3.5601e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_101` | 71.30% | 3.9620e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_102` | 71.85% | 3.9751e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_103` | 30.89% | 4.3672e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_104` | 101.93% | 4.4247e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_105` | 85.17% | 4.6085e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_106,fit_rank_107` | 84.35% | 5.1214e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_108` | 102.50% | 5.4683e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_109` | 134.67% | 6.4942e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_110` | 87.24% | 7.4861e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_111` | 109.34% | 8.3702e-04 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_112` | 145.01% | 0.0013 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_113` | 139.06% | 0.0014 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_114` | 183.40% | 0.0015 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_115` | 187.10% | 0.0016 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_116` | 31.89% | 0.0016 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_117` | 127.04% | 0.0017 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_118` | 252.02% | 0.0111 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_119` | 309.98% | 0.0114 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_120` | 352.29% | 0.0169 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_121` | 427.05% | 0.0178 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_122` | 350.03% | 0.0255 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_123` | 342.73% | 0.0272 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_124` | 382.89% | 0.0280 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_125` | 343.86% | 0.0286 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_126` | 337.04% | 0.0380 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_127` | 414.08% | 0.0703 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_128` | 436.47% | 0.0836 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_129` | 478.97% | 0.0860 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_130` | 343.43% | 0.1269 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_131` | 483.47% | 0.2410 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_132` | 411.19% | 0.2641 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 45.73% | 45.47% | 45.47% | 0.8186 | 0.8645 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2,fit_rank_3,fit_rank_4` | 50.46% | 50.28% | 50.28% | 0.8629 | 0.9411 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 50.59% | 50.27% | 50.27% | 0.8629 | 0.9410 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_6` | 52.59% | 45.52% | 45.52% | 0.8191 | 0.8646 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_7` | 52.59% | 45.52% | 45.52% | 0.8191 | 0.8646 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8` | 41.05% | 41.05% | 45.78% | 0.8213 | 0.4682 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_9` | 58.08% | 50.29% | 50.29% | 0.8629 | 0.9412 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10` | 18.28% | 18.28% | 22.38% | 0.5347 | 0.9437 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_11` | 43.29% | 43.29% | 50.04% | 0.8272 | 0.9437 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_12` | 27.69% | 27.69% | 41.53% | 0.8213 | 0.7571 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13` | 26.26% | 26.26% | 39.16% | 0.8213 | 0.6990 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_14` | 34.30% | 34.30% | 45.18% | 0.6699 | 0.9437 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_15` | 34.69% | 33.14% | 33.14% | 0.5983 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 29.86% | 29.86% | 32.00% | 0.6739 | 0.6787 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_17` | 37.01% | 30.21% | 30.21% | 0.6213 | 0.2899 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_18` | 34.05% | 31.92% | 31.92% | 0.8213 | 0.4887 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_19` | 36.89% | 32.75% | 32.75% | 0.5959 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_20` | 34.02% | 31.84% | 31.84% | 0.8210 | 0.4679 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_21` | 36.32% | 31.79% | 31.79% | 0.5950 | 0.9429 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_22` | 275.03% | 45.59% | 45.59% | 0.8198 | 0.8648 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_23` | 235.27% | 50.40% | 50.40% | 0.8633 | 0.9428 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_24` | 34.72% | 31.97% | 31.97% | 0.6475 | 0.8216 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_25` | 184.38% | 50.40% | 50.40% | 0.8633 | 0.9428 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_26` | 34.79% | 31.70% | 31.70% | 0.6433 | 0.8205 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_27` | 39.66% | 39.56% | 39.56% | 0.8208 | 0.6552 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_28` | 34.80% | 34.48% | 34.48% | 0.6855 | 0.8312 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_29` | 39.72% | 39.72% | 40.79% | 0.8213 | 0.9434 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_30` | 39.77% | 39.77% | 41.00% | 0.8213 | 0.9431 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_31` | 34.74% | 33.55% | 33.55% | 0.6718 | 0.8278 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_32` | 34.69% | 34.69% | 34.80% | 0.8210 | 0.9437 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_33` | 39.86% | 39.86% | 40.86% | 0.8212 | 0.9435 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_34` | 208.76% | 45.65% | 45.65% | 0.8204 | 0.8649 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_35` | 162.39% | 50.40% | 50.40% | 0.8633 | 0.9429 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_36` | 78.47% | 50.40% | 50.40% | 0.8633 | 0.9429 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_37,fit_rank_38,fit_rank_39,fit_rank_40,fit_rank_43,fit_rank_45,fit_rank_46,fit_rank_49,fit_rank_53,fit_rank_54,fit_rank_55,fit_rank_60,fit_rank_61,fit_rank_62,fit_rank_65,fit_rank_67,fit_rank_68,fit_rank_69,fit_rank_73,fit_rank_75` | 40.65% | 40.53% | 40.53% | 0.8213 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_41,fit_rank_42,fit_rank_44,fit_rank_47,fit_rank_48,fit_rank_50,fit_rank_51,fit_rank_52,fit_rank_56,fit_rank_57,fit_rank_58,fit_rank_59,fit_rank_63,fit_rank_64,fit_rank_66,fit_rank_70,fit_rank_71,fit_rank_72,fit_rank_74` | 36.40% | 36.38% | 36.38% | 0.8213 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_76` | 36.39% | 36.39% | 36.40% | 0.8213 | 0.9426 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_77` | 40.61% | 40.60% | 40.60% | 0.8213 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_78` | 30.64% | 30.64% | 31.52% | 0.6739 | 0.9437 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_79` | 32.12% | 32.12% | 69.48% | 0.5347 | 0.9437 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_80` | 1919.06% | 87.15% | 87.15% | 0.8136 | 0.5512 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_81` | 37.99% | 36.11% | 36.11% | 0.8213 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_82` | 11651.74% | 28.84% | 28.84% | 0.5773 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_83` | 22709.20% | 31.51% | 31.51% | 0.8213 | 0.4682 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_84` | 27905.37% | 28.70% | 28.70% | 0.5532 | 0.0794 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_85` | 26756.05% | 29.04% | 29.04% | 0.5824 | 0.2147 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_1` | 45.73% | 45.61% | 45.61% | 0.6811 | 0.6811 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2,fit_rank_3,fit_rank_4` | 50.46% | 50.36% | 50.36% | 0.8829 | 0.8829 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 50.59% | 50.31% | 50.31% | 0.8828 | 0.8828 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6` | 52.59% | 51.90% | 51.90% | 0.6824 | 0.6824 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_7` | 52.59% | 51.96% | 51.96% | 0.6824 | 0.6824 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8` | 41.05% | 41.05% | 41.05% | 0.6824 | 0.6824 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_9` | 58.08% | 57.21% | 57.21% | 0.9012 | 0.9012 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10` | 18.28% | 18.28% | 18.28% | 0.6578 | 0.6578 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 43.29% | 43.29% | 49.18% | 0.8518 | 0.8518 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_12` | 27.69% | 27.69% | 42.09% | 0.6824 | 0.6824 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 26.26% | 26.26% | 40.29% | 0.6824 | 0.6824 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_14` | 34.30% | 34.30% | 44.99% | 0.7527 | 0.7527 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_15` | 34.69% | 32.70% | 32.70% | 0.6794 | 0.6794 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 29.86% | 29.86% | 30.91% | 0.7567 | 0.7567 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_17` | 37.01% | 36.92% | 36.92% | 0.7115 | 0.7115 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_18` | 34.05% | 31.51% | 31.51% | 0.7245 | 0.7245 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_19` | 36.89% | 33.14% | 33.14% | 0.6826 | 0.6826 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_20` | 34.02% | 31.21% | 31.21% | 0.7231 | 0.7231 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_21` | 36.32% | 36.32% | 36.32% | 0.7192 | 0.7192 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_22` | 275.03% | 108.19% | 108.19% | 0.6897 | 0.6897 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_23` | 235.27% | 108.45% | 108.45% | 0.9516 | 0.9516 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_24` | 34.72% | 34.35% | 34.35% | 0.5818 | 0.5818 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_25` | 184.38% | 88.55% | 88.55% | 0.9401 | 0.9401 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_26` | 34.79% | 34.79% | 36.37% | 0.6807 | 0.6807 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_27` | 39.66% | 33.88% | 33.88% | 0.7424 | 0.7424 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_28` | 34.80% | 24.63% | 24.63% | 0.6080 | 0.6080 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_29` | 39.72% | 34.58% | 34.58% | 0.7408 | 0.7408 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_30` | 39.77% | 39.77% | 41.70% | 0.7545 | 0.7545 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_31` | 34.74% | 34.74% | 36.15% | 0.6823 | 0.6823 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_32` | 34.69% | 34.69% | 36.84% | 0.6821 | 0.6821 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_33` | 39.86% | 39.86% | 43.99% | 0.7541 | 0.7541 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_34` | 208.76% | 102.56% | 102.56% | 0.6824 | 0.6824 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_35` | 162.39% | 88.11% | 88.11% | 0.9397 | 0.9397 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_36` | 78.47% | 78.47% | 85.86% | 0.9274 | 0.9274 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_37,fit_rank_38,fit_rank_39,fit_rank_40,fit_rank_43,fit_rank_45,fit_rank_46,fit_rank_49,fit_rank_53,fit_rank_54,fit_rank_55,fit_rank_60,fit_rank_61,fit_rank_62,fit_rank_65,fit_rank_67,fit_rank_68,fit_rank_69,fit_rank_73,fit_rank_75` | 40.65% | 40.65% | 40.65% | 0.7493 | 0.7493 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_41,fit_rank_42,fit_rank_44,fit_rank_47,fit_rank_48,fit_rank_50,fit_rank_51,fit_rank_52,fit_rank_56,fit_rank_57,fit_rank_58,fit_rank_59,fit_rank_63,fit_rank_64,fit_rank_66,fit_rank_70,fit_rank_71,fit_rank_72,fit_rank_74` | 36.40% | 36.40% | 36.40% | 0.7567 | 0.7567 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_76` | 36.39% | 36.39% | 36.39% | 0.7567 | 0.7567 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_77` | 40.61% | 40.61% | 40.61% | 0.7490 | 0.7490 | `false` | `false` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_78` | 30.64% | 30.63% | 30.63% | 0.7567 | 0.7567 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_79` | 32.12% | 32.12% | 37.17% | 0.6578 | 0.6578 | `false` | `false` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_80` | 1919.06% | 81.90% | 81.90% | 0.6566 | 0.6566 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_81` | 37.99% | 36.15% | 36.15% | 0.7567 | 0.7567 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_82` | 11651.74% | 35.98% | 35.98% | 0.7546 | 0.7546 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_83` | 22709.20% | 34.16% | 34.16% | 0.7061 | 0.7061 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_84` | 27905.37% | 29.31% | 29.31% | 0.7005 | 0.7005 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_85` | 26756.05% | 28.45% | 28.45% | 0.6487 | 0.6487 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_1` | 29.92% | 29.92% | 29.92% | 0.9437 | 0.8651 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_2` | 0.63% | 0.63% | 1.17% | 0.5347 | 0.8213 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_3` | 33.46% | 30.36% | 30.36% | 0.6096 | 0.9216 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_4` | 27.01% | 21.13% | 21.13% | 0.8616 | 0.3704 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_5` | 38.92% | 34.61% | 34.61% | 0.7585 | 0.9469 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_6` | 34.37% | 28.57% | 28.57% | 0.8970 | 0.2301 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_7` | 36.17% | 30.60% | 30.60% | 0.8972 | 0.1959 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_8` | 36.72% | 31.24% | 31.24% | 0.8965 | 0.1855 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_9` | 38.68% | 33.32% | 33.32% | 0.8915 | 0.1530 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_10` | 45.16% | 41.03% | 41.03% | 0.8008 | 0.9920 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_11` | 45.37% | 41.61% | 41.61% | 0.8039 | 0.9922 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_12` | 45.51% | 41.41% | 41.41% | 0.8029 | 0.9921 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_13` | 48.56% | 46.57% | 46.57% | 0.8268 | 0.9932 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_14` | 49.11% | 47.56% | 47.56% | 0.8308 | 0.9933 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_15` | 44.76% | 43.42% | 43.42% | 0.9568 | 0.0238 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_16` | 50.19% | 49.68% | 49.68% | 0.8387 | 0.9937 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_17` | 45.59% | 45.16% | 45.16% | 0.9894 | 0.0057 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_18,fit_rank_19` | 45.73% | 45.64% | 45.64% | 0.9982 | 9.4449e-04 | `true` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_20` | 35.21% | 35.21% | 36.84% | 1.0000 | 0.8512 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_21` | 10.22% | 10.22% | 11.65% | 0.2192 | 0.9158 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_22` | 33.86% | 32.23% | 32.23% | 0.8946 | 0.1698 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_23` | 34.38% | 22.41% | 22.41% | 0.1065 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_24` | 48.33% | 36.55% | 36.55% | 1.0000 | 0.8324 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_25` | 56.30% | 41.35% | 41.35% | 1.0000 | 0.8185 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_26` | 68.87% | 46.74% | 46.74% | 1.0000 | 0.8031 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_27` | 47.10% | 25.65% | 25.65% | 0.1600 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_28` | 76.81% | 57.40% | 57.40% | 1.0000 | 0.7511 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_29` | 54.03% | 38.26% | 38.26% | 0.2933 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_30` | 84.45% | 71.48% | 71.48% | 1.0000 | 0.6953 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_31` | 60.10% | 47.74% | 47.74% | 0.3625 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_32` | 92.26% | 86.72% | 86.72% | 1.0000 | 0.6429 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_33` | 96.77% | 94.88% | 94.88% | 1.0000 | 0.6316 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_34` | 72.53% | 71.17% | 71.17% | 0.4961 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_35` | 31.47% | 31.47% | 40.46% | 0.8999 | 0.9241 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_36` | 32.42% | 32.42% | 47.35% | 1.0000 | 0.9290 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_37` | 25.86% | 25.86% | 30.69% | 0.3706 | 0.8754 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_38` | 31.48% | 31.48% | 31.75% | 1.0000 | 0.9477 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_39` | 31.52% | 31.45% | 31.45% | 1.0000 | 0.9485 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_40` | 31.53% | 31.45% | 31.45% | 1.0000 | 0.9488 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_41` | 31.13% | 29.78% | 29.78% | 0.4333 | 0.9081 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_42` | 31.81% | 30.79% | 30.79% | 0.4422 | 0.9131 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_43,fit_rank_44` | 31.82% | 31.70% | 31.70% | 1.0000 | 0.9545 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_45` | 31.94% | 31.86% | 31.86% | 0.9997 | 0.9558 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_46` | 31.94% | 31.90% | 31.90% | 0.9999 | 0.9561 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_47` | 31.90% | 31.90% | 31.91% | 0.9789 | 0.9631 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_48` | 31.88% | 31.88% | 31.91% | 0.9761 | 0.9634 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_49` | 33.65% | 33.06% | 33.06% | 0.5355 | 0.9216 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_50` | 33.68% | 33.09% | 33.09% | 0.5367 | 0.9217 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_51` | 31.82% | 31.82% | 31.92% | 0.9678 | 0.9643 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_52` | 31.77% | 31.77% | 31.92% | 0.9626 | 0.9648 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_53` | 31.39% | 31.39% | 31.68% | 0.9366 | 0.9645 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_54` | 33.74% | 33.12% | 33.12% | 0.5379 | 0.9217 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_55` | 33.73% | 33.07% | 33.07% | 0.5359 | 0.9216 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_56,fit_rank_57,fit_rank_58` | 33.76% | 33.13% | 33.13% | 0.5383 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_59` | 31.75% | 31.75% | 31.93% | 0.9565 | 0.9660 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_60` | 33.78% | 33.11% | 33.11% | 0.5377 | 0.9217 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_61` | 31.69% | 31.69% | 31.91% | 0.9504 | 0.9663 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_62` | 33.77% | 33.13% | 33.13% | 0.5385 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_63,fit_rank_64,fit_rank_70` | 33.81% | 33.14% | 33.14% | 0.5388 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_65,fit_rank_66` | 33.79% | 33.14% | 33.14% | 0.5386 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_67` | 31.66% | 31.66% | 31.89% | 0.9485 | 0.9661 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_68,fit_rank_72` | 33.83% | 33.14% | 33.14% | 0.5390 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_69` | 33.85% | 33.12% | 33.12% | 0.5382 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_71` | 31.65% | 31.65% | 31.89% | 0.9430 | 0.9674 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_73` | 31.66% | 31.66% | 31.92% | 0.9419 | 0.9679 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_74` | 33.88% | 33.13% | 33.13% | 0.5386 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_75` | 33.92% | 33.15% | 33.15% | 0.5390 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_76` | 31.66% | 31.66% | 31.89% | 0.9448 | 0.9671 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_77` | 31.69% | 31.69% | 31.93% | 0.9438 | 0.9679 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_78` | 31.62% | 31.62% | 31.91% | 0.9377 | 0.9681 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_79,fit_rank_83` | 31.64% | 31.64% | 31.93% | 0.9367 | 0.9688 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_80` | 31.64% | 31.64% | 31.89% | 0.9411 | 0.9678 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_81` | 33.96% | 33.14% | 33.14% | 0.5388 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_82` | 31.64% | 31.64% | 31.89% | 0.9346 | 0.9693 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_84` | 31.64% | 31.64% | 31.88% | 0.9386 | 0.9684 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_85` | 31.66% | 31.66% | 31.90% | 0.9343 | 0.9697 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_86` | 33.99% | 33.15% | 33.15% | 0.5391 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_87` | 34.07% | 33.15% | 33.15% | 0.5391 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_88` | 31.63% | 31.63% | 31.92% | 0.9300 | 0.9702 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_89` | 34.01% | 33.14% | 33.14% | 0.5388 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_90,fit_rank_93` | 34.06% | 33.15% | 33.15% | 0.5392 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_91` | 33.99% | 33.14% | 33.14% | 0.5390 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_92` | 33.96% | 33.15% | 33.15% | 0.5391 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_94,fit_rank_98` | 34.16% | 33.15% | 33.15% | 0.5392 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_95` | 34.12% | 33.15% | 33.15% | 0.5391 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_96` | 31.69% | 31.69% | 31.93% | 0.9377 | 0.9696 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_97` | 31.61% | 31.61% | 31.89% | 0.9222 | 0.9718 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_99` | 31.66% | 31.66% | 31.91% | 0.9242 | 0.9722 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_100` | 31.70% | 31.70% | 31.92% | 0.9259 | 0.9726 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_101` | 34.24% | 33.15% | 33.15% | 0.5392 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_102` | 31.64% | 31.64% | 31.90% | 0.9272 | 0.9711 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_103` | 31.73% | 31.73% | 31.91% | 0.9212 | 0.9743 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_104` | 31.79% | 31.79% | 31.92% | 0.9208 | 0.9756 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_105` | 33.40% | 32.68% | 32.68% | 0.5204 | 0.9206 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_106` | 31.86% | 31.86% | 31.91% | 0.9227 | 0.9763 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_107` | 34.53% | 33.15% | 33.15% | 0.5392 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_108` | 34.82% | 33.12% | 33.12% | 0.5382 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_109` | 31.99% | 31.92% | 31.92% | 0.9995 | 0.9563 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_110` | 35.06% | 33.15% | 33.15% | 0.5392 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_111` | 35.28% | 33.15% | 33.15% | 0.5392 | 0.9218 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_112` | 33.11% | 31.92% | 31.92% | 0.9999 | 0.9563 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_113` | 33.58% | 31.85% | 31.85% | 0.9988 | 0.9559 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_114` | 35.90% | 31.51% | 31.51% | 1.0000 | 0.9517 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_115` | 34.20% | 32.22% | 32.22% | 0.6313 | 0.9346 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_116` | 38.41% | 38.41% | 45.17% | 0.8747 | 0.9890 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_117` | 31.39% | 31.39% | 36.16% | 0.9408 | 0.7660 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_118` | 36.58% | 35.45% | 35.45% | 0.9988 | 0.9588 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_119` | 36.38% | 36.35% | 36.35% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_120,fit_rank_121,fit_rank_131` | 40.65% | 40.65% | 40.65% | 1.0000 | 0.9922 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_122,fit_rank_123` | 36.40% | 36.40% | 36.40% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_124,fit_rank_125` | 283.00% | 45.73% | 45.73% | 0.9999 | 2.7462e-05 | `true` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_126,fit_rank_129,fit_rank_130` | 301.06% | 53.04% | 53.04% | 0.8517 | 0.9942 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_127,fit_rank_128` | 301.06% | 50.46% | 50.46% | 0.8414 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_132` | 413.71% | 16.88% | 16.88% | 0.5079 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_1` | 29.92% | 29.92% | 29.92% | 0.6198 | 0.6198 | `false` | `false` | `false` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 0.63% | 0.63% | 1.17% | 0.1032 | 0.1032 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_3` | 33.46% | 28.83% | 28.83% | 0.6616 | 0.6616 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 27.01% | 15.60% | 15.60% | 0.1677 | 0.1677 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 38.92% | 31.68% | 31.68% | 0.6973 | 0.6973 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6` | 34.37% | 23.46% | 23.46% | 0.3560 | 0.3560 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_7` | 36.17% | 25.48% | 25.48% | 0.3968 | 0.3968 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8` | 36.72% | 26.16% | 26.16% | 0.4095 | 0.4095 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_9` | 38.68% | 29.27% | 29.27% | 0.4645 | 0.4645 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10` | 45.16% | 36.75% | 36.75% | 0.8324 | 0.8324 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 45.37% | 38.23% | 38.23% | 0.8400 | 0.8400 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_12` | 45.51% | 38.54% | 38.54% | 0.8414 | 0.8414 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 48.56% | 44.25% | 44.25% | 0.8646 | 0.8646 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_14` | 49.11% | 45.62% | 45.62% | 0.8692 | 0.8692 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_15` | 44.76% | 41.64% | 41.64% | 0.6389 | 0.6389 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 50.19% | 48.91% | 48.91% | 0.8791 | 0.8791 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_17` | 45.59% | 44.51% | 44.51% | 0.6700 | 0.6700 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_18,fit_rank_19` | 45.73% | 45.46% | 45.46% | 0.6796 | 0.6796 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_20` | 35.21% | 31.84% | 31.84% | 0.6056 | 0.6056 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_21` | 10.22% | 2.02% | 2.02% | 0.1581 | 0.1581 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_22` | 33.86% | 18.70% | 18.70% | 0.2377 | 0.2377 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_23` | 34.38% | 34.27% | 34.27% | 0.6578 | 0.6578 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_24` | 48.33% | 41.36% | 41.36% | 0.5715 | 0.5715 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_25` | 56.30% | 43.70% | 43.70% | 0.6306 | 0.6306 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_26` | 68.87% | 68.86% | 68.86% | 0.6824 | 0.6824 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_27` | 47.10% | 25.22% | 25.22% | 0.6577 | 0.6577 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_28` | 76.81% | 76.81% | 76.81% | 0.6824 | 0.6824 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_29` | 54.03% | 54.03% | 54.03% | 0.6578 | 0.6578 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_30` | 84.45% | 84.45% | 84.45% | 0.6824 | 0.6824 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_31` | 60.10% | 60.10% | 60.10% | 0.6578 | 0.6578 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_32` | 92.26% | 92.26% | 92.26% | 0.6824 | 0.6824 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_33` | 96.77% | 96.77% | 96.77% | 0.6906 | 0.6906 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_34` | 72.53% | 72.53% | 72.53% | 0.6578 | 0.6578 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_35` | 31.47% | 30.08% | 30.08% | 0.6183 | 0.6183 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_36` | 32.42% | 32.42% | 32.54% | 0.6870 | 0.6870 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_37` | 25.86% | 25.86% | 25.86% | 0.6578 | 0.6578 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_38` | 31.48% | 31.48% | 31.48% | 0.7058 | 0.7058 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_39` | 31.52% | 31.52% | 31.52% | 0.7103 | 0.7103 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_40` | 31.53% | 31.53% | 31.53% | 0.7106 | 0.7106 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_41` | 31.13% | 31.13% | 31.13% | 0.6724 | 0.6724 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_42` | 31.81% | 31.81% | 31.81% | 0.6751 | 0.6751 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_43,fit_rank_44` | 31.82% | 31.82% | 31.82% | 0.7137 | 0.7137 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_45` | 31.94% | 31.80% | 31.80% | 0.7137 | 0.7137 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_46` | 31.94% | 31.83% | 31.83% | 0.7139 | 0.7139 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_47` | 31.90% | 31.83% | 31.83% | 0.7139 | 0.7139 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_48` | 31.88% | 31.83% | 31.83% | 0.7139 | 0.7139 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_49` | 33.65% | 32.68% | 32.68% | 0.6783 | 0.6783 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_50` | 33.68% | 32.69% | 32.69% | 0.6783 | 0.6783 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_51` | 31.82% | 31.82% | 31.82% | 0.7138 | 0.7138 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_52` | 31.77% | 31.77% | 31.83% | 0.7227 | 0.7227 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_53` | 31.39% | 31.39% | 31.66% | 0.7225 | 0.7225 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_54` | 33.74% | 32.71% | 32.71% | 0.6784 | 0.6784 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_55` | 33.73% | 32.65% | 32.65% | 0.6782 | 0.6782 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_56,fit_rank_57,fit_rank_58` | 33.76% | 32.71% | 32.71% | 0.6784 | 0.6784 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_59` | 31.75% | 31.75% | 31.82% | 0.7239 | 0.7239 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_60` | 33.78% | 32.68% | 32.68% | 0.6783 | 0.6783 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_61` | 31.69% | 31.69% | 31.79% | 0.7242 | 0.7242 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_62` | 33.77% | 32.71% | 32.71% | 0.6784 | 0.6784 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_63,fit_rank_64,fit_rank_70` | 33.81% | 32.78% | 32.78% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_65,fit_rank_66` | 33.79% | 32.78% | 32.78% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_67` | 31.66% | 31.66% | 31.78% | 0.7241 | 0.7241 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_68,fit_rank_72` | 33.83% | 32.79% | 32.79% | 0.6787 | 0.6787 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_69` | 33.85% | 32.69% | 32.69% | 0.6783 | 0.6783 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_71` | 31.65% | 31.65% | 31.77% | 0.7253 | 0.7253 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_73` | 31.66% | 31.66% | 31.79% | 0.7258 | 0.7258 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_74` | 33.88% | 32.69% | 32.69% | 0.6783 | 0.6783 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_75` | 33.92% | 32.77% | 32.77% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_76` | 31.66% | 31.66% | 31.77% | 0.7251 | 0.7251 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_77` | 31.69% | 31.69% | 31.82% | 0.7258 | 0.7258 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_78` | 31.62% | 31.62% | 31.77% | 0.7261 | 0.7261 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_79,fit_rank_83` | 31.64% | 31.64% | 31.79% | 0.7267 | 0.7267 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_80` | 31.64% | 31.64% | 31.77% | 0.7257 | 0.7257 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_81` | 33.96% | 32.76% | 32.76% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_82` | 31.64% | 31.64% | 31.76% | 0.7272 | 0.7272 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_84` | 31.64% | 31.64% | 31.73% | 0.7263 | 0.7263 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_85` | 31.66% | 31.66% | 31.76% | 0.7276 | 0.7276 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_86` | 33.99% | 32.77% | 32.77% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_87` | 34.07% | 32.77% | 32.77% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_88` | 31.63% | 31.63% | 31.78% | 0.7281 | 0.7281 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_89` | 34.01% | 32.68% | 32.68% | 0.6783 | 0.6783 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_90,fit_rank_93` | 34.06% | 32.76% | 32.76% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_91` | 33.99% | 32.76% | 32.76% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_92` | 33.96% | 32.76% | 32.76% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_94,fit_rank_98` | 34.16% | 32.82% | 32.82% | 0.6788 | 0.6788 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_95` | 34.12% | 32.81% | 32.81% | 0.6788 | 0.6788 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_96` | 31.69% | 31.69% | 31.80% | 0.7275 | 0.7275 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_97` | 31.61% | 31.61% | 31.72% | 0.7296 | 0.7296 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_99` | 31.66% | 31.66% | 31.76% | 0.7300 | 0.7300 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_100` | 31.70% | 31.70% | 31.76% | 0.7304 | 0.7304 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_101` | 34.24% | 32.74% | 32.74% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_102` | 31.64% | 31.64% | 31.73% | 0.7290 | 0.7290 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_103` | 31.73% | 31.73% | 31.76% | 0.7321 | 0.7321 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_104` | 31.79% | 31.76% | 31.76% | 0.7141 | 0.7141 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_105` | 33.40% | 32.11% | 32.11% | 0.6765 | 0.6765 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_106` | 31.86% | 31.74% | 31.74% | 0.7137 | 0.7137 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_107` | 34.53% | 32.74% | 32.74% | 0.6786 | 0.6786 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_108` | 34.82% | 32.66% | 32.66% | 0.6783 | 0.6783 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_109` | 31.99% | 31.76% | 31.76% | 0.7142 | 0.7142 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_110` | 35.06% | 32.70% | 32.70% | 0.6784 | 0.6784 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_111` | 35.28% | 32.83% | 32.83% | 0.6790 | 0.6790 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_112` | 33.11% | 31.77% | 31.77% | 0.7140 | 0.7140 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_113` | 33.58% | 31.74% | 31.74% | 0.7142 | 0.7142 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_114` | 35.90% | 35.90% | 35.90% | 0.6824 | 0.6824 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_115` | 34.20% | 22.33% | 22.33% | 0.5829 | 0.5829 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_116` | 38.41% | 38.41% | 41.28% | 0.7463 | 0.7463 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_117` | 31.39% | 31.39% | 34.86% | 0.6495 | 0.6495 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_118` | 36.58% | 36.57% | 36.57% | 0.7413 | 0.7413 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_119` | 36.38% | 36.38% | 36.38% | 0.7567 | 0.7567 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_120,fit_rank_121,fit_rank_131` | 40.65% | 40.65% | 40.65% | 0.7493 | 0.7493 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_122,fit_rank_123` | 36.40% | 36.40% | 36.40% | 0.7567 | 0.7567 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_124,fit_rank_125` | 283.00% | 110.41% | 110.41% | 0.6962 | 0.6962 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_126,fit_rank_129,fit_rank_130` | 301.06% | 97.84% | 97.84% | 0.9459 | 0.9459 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_127,fit_rank_128` | 301.06% | 92.88% | 92.88% | 0.9429 | 0.9429 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_132` | 413.71% | 43.67% | 43.67% | 0.5675 | 0.5675 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_1` | 6.77% | 2.63% | 2.63% | 0.5766 | 0.7757 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_2` | 14.34% | 8.91% | 8.91% | 0.6968 | 0.6343 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_3` | 21.47% | 15.75% | 15.75% | 0.8033 | 0.4832 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_4` | 21.70% | 14.94% | 14.94% | 0.7922 | 0.5008 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_5` | 26.32% | 19.00% | 19.00% | 0.8415 | 0.4143 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_6` | 36.01% | 32.37% | 32.37% | 0.6890 | 0.9353 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_7` | 32.35% | 25.71% | 25.71% | 0.8900 | 0.2813 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_8` | 37.34% | 31.21% | 31.21% | 0.8965 | 0.1860 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_9` | 43.42% | 39.22% | 39.22% | 0.7906 | 0.9916 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_10,fit_rank_11,fit_rank_12` | 38.44% | 31.53% | 31.53% | 0.8960 | 0.1808 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_13` | 38.70% | 32.91% | 32.91% | 0.8928 | 0.1594 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_14` | 44.82% | 39.12% | 39.12% | 0.7900 | 0.9915 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_15` | 39.18% | 33.98% | 33.98% | 0.8892 | 0.1432 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_16` | 45.17% | 40.90% | 40.90% | 0.8001 | 0.9920 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_17,fit_rank_18,fit_rank_19` | 39.34% | 34.70% | 34.70% | 0.8862 | 0.1327 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_20,fit_rank_21` | 39.58% | 34.96% | 34.96% | 0.8850 | 0.1291 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_22` | 39.96% | 35.01% | 35.01% | 0.8848 | 0.1284 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_23,fit_rank_24` | 45.91% | 41.35% | 41.35% | 0.8025 | 0.9921 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_25` | 40.58% | 35.44% | 35.44% | 0.8827 | 0.1223 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_26` | 46.17% | 42.34% | 42.34% | 0.8077 | 0.9923 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_27,fit_rank_36` | 46.39% | 42.71% | 42.71% | 0.8095 | 0.9924 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_28` | 40.08% | 35.24% | 35.24% | 0.8837 | 0.1250 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_29,fit_rank_31` | 46.61% | 42.92% | 42.92% | 0.8105 | 0.9925 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_30` | 46.54% | 42.76% | 42.76% | 0.8098 | 0.9924 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_32` | 46.78% | 41.84% | 41.84% | 0.8051 | 0.9922 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_33,fit_rank_34` | 46.90% | 42.02% | 42.02% | 0.8060 | 0.9923 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_35` | 47.07% | 43.41% | 43.41% | 0.8129 | 0.9926 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_37,fit_rank_38,fit_rank_39,fit_rank_40` | 47.51% | 43.13% | 43.13% | 0.8116 | 0.9925 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_41,fit_rank_42` | 47.60% | 44.35% | 44.35% | 0.8173 | 0.9927 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_43` | 47.92% | 44.12% | 44.12% | 0.8162 | 0.9927 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_44` | 48.01% | 44.02% | 44.02% | 0.8157 | 0.9927 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_45` | 42.98% | 38.40% | 38.40% | 0.8647 | 0.0826 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_46` | 43.20% | 40.17% | 40.17% | 0.8937 | 0.0606 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_47` | 49.09% | 47.75% | 47.75% | 0.8315 | 0.9934 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_48` | 49.46% | 48.01% | 48.01% | 0.8325 | 0.9934 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_49` | 44.76% | 42.65% | 42.65% | 0.9421 | 0.0322 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_50,fit_rank_51` | 50.54% | 50.41% | 50.41% | 0.8412 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_52` | 55.14% | 50.42% | 50.42% | 0.8412 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_53` | 56.20% | 49.83% | 49.83% | 0.8392 | 0.9937 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_54` | 53.73% | 50.42% | 50.42% | 0.8412 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_55` | 52.17% | 45.60% | 45.60% | 0.9976 | 0.0013 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_56` | 57.76% | 45.69% | 45.69% | 0.9992 | 4.4960e-04 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_57` | 57.65% | 45.81% | 45.81% | 1.0000 | 0.8084 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_58` | 59.07% | 38.09% | 38.09% | 0.8668 | 0.0865 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_59` | 47.92% | 31.24% | 31.24% | 0.8965 | 0.1855 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_60` | 14.16% | 10.87% | 10.87% | 0.2769 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_61` | 64.72% | 45.69% | 45.69% | 0.9993 | 3.8894e-04 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_62` | 43.38% | 23.42% | 23.42% | 0.1245 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_63` | 78.82% | 50.30% | 50.30% | 0.8408 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_64` | 44.81% | 41.36% | 41.36% | 0.8026 | 0.9921 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_65` | 81.47% | 45.73% | 45.73% | 1.0000 | 3.5539e-06 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_66` | 86.61% | 80.51% | 80.51% | 1.0000 | 0.6543 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_67` | 87.12% | 86.21% | 86.21% | 1.0000 | 0.6406 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_68` | 65.05% | 63.84% | 63.84% | 0.4486 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_69` | 88.52% | 88.52% | 88.65% | 1.0000 | 0.6184 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_70` | 64.42% | 63.29% | 63.29% | 0.4472 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_71` | 92.84% | 50.38% | 50.38% | 0.8411 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_72` | 87.89% | 87.40% | 87.40% | 1.0000 | 0.6334 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_73` | 73.40% | 73.10% | 73.10% | 0.5334 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_74` | 65.55% | 65.55% | 66.46% | 0.4921 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_75` | 68.64% | 68.64% | 69.26% | 0.5103 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_76` | 91.51% | 91.51% | 92.33% | 1.0000 | 0.6248 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_77` | 88.65% | 88.65% | 91.15% | 1.0000 | 0.6177 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_78` | 63.81% | 63.81% | 65.59% | 0.4872 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_79` | 89.43% | 89.43% | 92.62% | 1.0000 | 0.6199 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_80` | 94.15% | 94.15% | 97.18% | 1.0000 | 0.6319 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_81` | 83.72% | 83.72% | 89.94% | 1.0000 | 0.6136 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_82` | 63.48% | 63.48% | 68.86% | 0.5107 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_83` | 61.78% | 61.78% | 67.29% | 0.5019 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_84` | 63.47% | 63.47% | 70.74% | 0.5237 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_85` | 81.98% | 81.98% | 93.22% | 1.0000 | 0.6078 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_86` | 80.72% | 80.72% | 93.82% | 1.0000 | 0.6064 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_87` | 81.02% | 81.02% | 94.46% | 1.0000 | 0.6057 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_88` | 80.48% | 80.48% | 94.68% | 1.0000 | 0.6166 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_89` | 79.57% | 79.57% | 94.16% | 1.0000 | 0.6515 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_90` | 59.44% | 59.44% | 72.74% | 0.8069 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_91` | 58.36% | 58.36% | 71.99% | 0.9068 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_92` | 76.20% | 76.20% | 94.87% | 1.0000 | 0.8215 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_93` | 74.52% | 74.52% | 95.38% | 1.0000 | 0.9295 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_94` | 57.61% | 57.61% | 72.10% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_95` | 57.59% | 57.59% | 72.17% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_96` | 56.11% | 56.11% | 62.35% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_97` | 103.85% | 45.70% | 45.70% | 0.9994 | 3.1194e-04 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_98` | 60.64% | 60.64% | 70.10% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_99` | 70.96% | 70.96% | 93.98% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_100` | 131.71% | 45.70% | 45.70% | 0.9994 | 3.1356e-04 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_101` | 71.30% | 69.24% | 69.24% | 0.5349 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_102` | 71.85% | 67.37% | 67.37% | 0.5095 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_103` | 30.89% | 30.89% | 38.89% | 0.8647 | 0.9320 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_104` | 101.93% | 50.46% | 50.46% | 0.8413 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_105` | 85.17% | 85.17% | 88.51% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_106,fit_rank_107` | 84.35% | 84.35% | 91.82% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_108` | 102.50% | 87.24% | 87.24% | 1.0000 | 0.6145 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_109` | 134.67% | 45.70% | 45.70% | 0.9995 | 2.8858e-04 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_110` | 87.24% | 69.63% | 69.63% | 0.5069 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_111` | 109.34% | 50.22% | 50.22% | 0.8405 | 0.9937 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_112` | 145.01% | 50.44% | 50.44% | 0.8413 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_113` | 139.06% | 50.25% | 50.25% | 0.8407 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_114` | 183.40% | 45.72% | 45.72% | 0.9998 | 9.2594e-05 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_115` | 187.10% | 45.73% | 45.73% | 1.0000 | 6.4623e-06 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_116` | 31.89% | 17.22% | 17.22% | 0.0637 | 0.9504 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_117` | 127.04% | 50.46% | 50.46% | 0.8413 | 0.9938 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_118` | 252.02% | 21.65% | 21.65% | 0.1002 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_119` | 309.98% | 84.87% | 84.87% | 1.0000 | 0.6087 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_120` | 352.29% | 29.90% | 29.90% | 0.5890 | 0.9176 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_121` | 427.05% | 30.06% | 30.06% | 0.9535 | 0.8640 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_122` | 350.03% | 10.00% | 10.00% | 0.7158 | 0.6098 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_123` | 342.73% | 38.41% | 38.41% | 0.8646 | 0.0825 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_124` | 382.89% | 82.93% | 82.93% | 1.0000 | 0.6191 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_125` | 343.86% | 39.54% | 39.54% | 0.8809 | 0.0684 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_126` | 337.04% | 40.75% | 40.75% | 0.7993 | 0.9920 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_127` | 414.08% | 63.26% | 63.26% | 0.5137 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_128` | 436.47% | 21.48% | 21.48% | 0.0884 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_129` | 478.97% | 45.47% | 45.47% | 1.0000 | 0.8104 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_130` | 343.43% | 9.98% | 9.98% | 0.4362 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_131` | 483.47% | 53.03% | 53.03% | 0.4852 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_132` | 411.19% | 78.13% | 78.13% | 1.0000 | 0.6668 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 6.77% | 1.26% | 1.26% | 0.0124 | 0.5445 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 14.34% | 4.99% | 4.99% | 0.0769 | 0.5935 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_3` | 21.47% | 11.07% | 11.07% | 0.1673 | 0.6929 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 21.70% | 11.29% | 11.29% | 0.1713 | 0.6969 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 26.32% | 15.44% | 15.44% | 0.2527 | 0.7406 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_6` | 36.01% | 29.86% | 29.86% | 0.6052 | 0.2703 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_7` | 32.35% | 21.09% | 21.09% | 0.3776 | 0.7709 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8` | 37.34% | 26.69% | 26.69% | 0.5144 | 0.7987 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_9` | 43.42% | 35.22% | 35.22% | 0.7950 | 0.5023 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10,fit_rank_11,fit_rank_12` | 38.44% | 28.14% | 28.14% | 0.5514 | 0.8053 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13` | 38.70% | 28.50% | 28.50% | 0.5608 | 0.8069 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_14` | 44.82% | 36.86% | 36.86% | 0.8057 | 0.5616 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_15` | 39.18% | 29.18% | 29.18% | 0.5782 | 0.8099 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 45.17% | 37.30% | 37.30% | 0.8083 | 0.5771 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_17,fit_rank_18,fit_rank_19` | 39.34% | 29.39% | 29.39% | 0.5837 | 0.8109 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_20,fit_rank_21` | 39.58% | 29.75% | 29.75% | 0.5931 | 0.8124 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_22` | 39.96% | 30.31% | 30.31% | 0.6076 | 0.8148 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_23,fit_rank_24` | 45.91% | 38.30% | 38.30% | 0.8141 | 0.6122 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_25` | 40.58% | 31.27% | 31.27% | 0.6324 | 0.8188 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_26` | 46.17% | 38.69% | 38.69% | 0.8162 | 0.6254 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_27,fit_rank_36` | 46.39% | 39.24% | 39.24% | 0.8191 | 0.6443 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_28` | 40.08% | 30.50% | 30.50% | 0.6125 | 0.8156 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_29,fit_rank_31` | 46.61% | 39.58% | 39.58% | 0.8208 | 0.6556 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_30` | 46.54% | 39.45% | 39.45% | 0.8202 | 0.6515 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_32` | 46.78% | 39.89% | 39.89% | 0.8225 | 0.6662 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_33,fit_rank_34` | 46.90% | 40.12% | 40.12% | 0.8236 | 0.6738 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_35` | 47.07% | 40.45% | 40.45% | 0.8252 | 0.6849 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_37,fit_rank_38,fit_rank_39,fit_rank_40` | 47.51% | 41.31% | 41.31% | 0.8293 | 0.7136 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_41,fit_rank_42` | 47.60% | 41.29% | 41.29% | 0.8293 | 0.7130 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_43` | 47.92% | 42.05% | 42.05% | 0.8327 | 0.7377 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_44` | 48.01% | 42.26% | 42.26% | 0.8337 | 0.7448 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_45` | 42.98% | 36.25% | 36.25% | 0.7105 | 0.8376 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_46` | 43.20% | 37.00% | 37.00% | 0.7206 | 0.8401 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_47` | 49.09% | 44.97% | 44.97% | 0.8448 | 0.8316 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_48` | 49.46% | 46.23% | 46.23% | 0.8495 | 0.8711 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_49` | 44.76% | 41.20% | 41.20% | 0.7728 | 0.8532 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_50,fit_rank_51` | 50.54% | 50.24% | 50.24% | 0.8628 | 0.9406 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_52` | 55.14% | 50.30% | 50.30% | 0.8630 | 0.9414 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_53` | 56.20% | 49.85% | 49.85% | 0.8616 | 0.9350 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_54` | 53.73% | 50.30% | 50.30% | 0.8630 | 0.9415 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_55` | 52.17% | 45.46% | 45.46% | 0.8185 | 0.8645 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_56` | 57.76% | 45.54% | 45.54% | 0.8193 | 0.8647 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_57` | 57.65% | 45.80% | 45.80% | 0.8211 | 0.4680 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_58` | 59.07% | 32.36% | 32.36% | 0.6536 | 0.8232 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_59` | 47.92% | 25.04% | 25.04% | 0.4730 | 0.7908 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_60` | 14.16% | 8.66% | 8.66% | 0.2061 | 0.4835 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_61` | 64.72% | 45.58% | 45.58% | 0.8197 | 0.8647 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_62` | 43.38% | 22.40% | 22.40% | 0.5346 | 0.9436 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_63` | 78.82% | 50.30% | 50.30% | 0.8630 | 0.9414 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_64` | 44.81% | 37.11% | 37.11% | 0.8072 | 0.5704 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_65` | 81.47% | 45.53% | 45.53% | 0.8192 | 0.8646 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_66` | 86.61% | 81.34% | 81.34% | 0.8213 | 0.5270 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_67` | 87.12% | 85.98% | 85.98% | 0.8213 | 0.5462 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_68` | 65.05% | 63.33% | 63.33% | 0.5486 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_69` | 88.52% | 88.52% | 88.59% | 0.7252 | 0.5611 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_70` | 64.42% | 64.42% | 64.59% | 0.5553 | 0.7197 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_71` | 92.84% | 50.30% | 50.30% | 0.8630 | 0.9414 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_72` | 87.89% | 87.89% | 88.89% | 0.7241 | 0.5595 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_73` | 73.40% | 71.93% | 71.93% | 0.5785 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_74` | 65.55% | 65.55% | 67.14% | 0.5591 | 0.7223 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_75` | 68.64% | 68.64% | 68.98% | 0.5690 | 0.7292 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_76` | 91.51% | 91.51% | 92.35% | 0.7316 | 0.5705 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_77` | 88.65% | 88.65% | 92.05% | 0.7262 | 0.5626 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_78` | 63.81% | 63.81% | 66.77% | 0.5531 | 0.7182 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_79` | 89.43% | 89.43% | 93.09% | 0.7279 | 0.5651 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_80` | 94.15% | 94.15% | 96.63% | 0.7371 | 0.5783 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_81` | 83.72% | 83.72% | 91.65% | 0.7161 | 0.5481 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_82` | 63.48% | 63.48% | 69.80% | 0.5514 | 0.7170 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_83` | 61.78% | 61.78% | 68.96% | 0.5449 | 0.7124 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_84` | 63.47% | 63.47% | 71.03% | 0.5510 | 0.7167 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_85` | 81.98% | 81.98% | 94.65% | 0.7129 | 0.5434 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_86` | 80.72% | 80.72% | 94.83% | 0.7100 | 0.5393 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_87` | 81.02% | 81.02% | 95.22% | 0.7108 | 0.5404 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_88` | 80.48% | 80.48% | 95.66% | 0.7095 | 0.5386 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_89` | 79.57% | 79.57% | 95.18% | 0.7073 | 0.5354 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_90` | 59.44% | 59.44% | 72.34% | 0.5296 | 0.7017 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_91` | 58.36% | 58.36% | 71.91% | 0.5220 | 0.6963 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_92` | 76.20% | 76.20% | 95.55% | 0.6983 | 0.5227 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_93` | 74.52% | 74.52% | 95.95% | 0.6932 | 0.5154 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_94` | 57.61% | 57.61% | 72.43% | 0.5068 | 0.6855 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_95` | 57.59% | 57.59% | 72.25% | 0.5033 | 0.6830 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_96` | 56.11% | 56.11% | 67.09% | 0.4815 | 0.6673 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_97` | 103.85% | 45.56% | 45.56% | 0.8195 | 0.8647 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_98` | 60.64% | 60.64% | 71.68% | 0.5140 | 0.6679 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_99` | 70.96% | 70.96% | 97.07% | 0.6563 | 0.5978 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_100` | 131.71% | 45.57% | 45.57% | 0.8196 | 0.8647 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_101` | 71.30% | 71.30% | 72.24% | 0.6258 | 0.6704 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_102` | 71.85% | 71.03% | 71.03% | 0.5757 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_103` | 30.89% | 29.82% | 29.82% | 0.5379 | 0.0048 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_104` | 101.93% | 50.32% | 50.32% | 0.8630 | 0.9416 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_105` | 85.17% | 85.17% | 95.56% | 0.6171 | 0.7286 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_106,fit_rank_107` | 84.35% | 84.35% | 96.40% | 0.6209 | 0.7233 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_108` | 102.50% | 96.11% | 96.11% | 0.8213 | 0.5820 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_109` | 134.67% | 45.56% | 45.56% | 0.8195 | 0.8647 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_110` | 87.24% | 71.28% | 71.28% | 0.5765 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_111` | 109.34% | 50.31% | 50.31% | 0.8630 | 0.9416 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_112` | 145.01% | 50.36% | 50.36% | 0.8632 | 0.9423 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_113` | 139.06% | 50.32% | 50.32% | 0.8630 | 0.9417 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_114` | 183.40% | 45.62% | 45.62% | 0.8201 | 0.8648 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_115` | 187.10% | 45.61% | 45.61% | 0.8200 | 0.8648 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_116` | 31.89% | 31.89% | 36.29% | 0.8203 | 0.9437 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_117` | 127.04% | 50.36% | 50.36% | 0.8632 | 0.9423 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_118` | 252.02% | 7.44% | 7.44% | 0.1781 | 0.4582 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_119` | 309.98% | 94.96% | 94.96% | 0.8213 | 0.5783 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_120` | 352.29% | 29.92% | 29.92% | 0.5369 | 1.9067e-08 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_121` | 427.05% | 45.81% | 45.81% | 0.8213 | 0.4682 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_122` | 350.03% | 7.42% | 7.42% | 0.1122 | 0.6299 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_123` | 342.73% | 28.73% | 28.73% | 0.5667 | 0.8080 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_124` | 382.89% | 92.95% | 92.95% | 0.8212 | 0.5717 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_125` | 343.86% | 28.86% | 28.86% | 0.5699 | 0.8085 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_126` | 337.04% | 35.42% | 35.42% | 0.7508 | 0.3977 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_127` | 414.08% | 69.65% | 69.65% | 0.5712 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_128` | 436.47% | 308.76% | 308.76% | 0.8737 | 0.9730 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_129` | 478.97% | 363.04% | 363.04% | 0.9794 | 0.9029 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_130` | 343.43% | 34.64% | 34.64% | 0.5347 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_131` | 483.47% | 27.33% | 27.33% | 0.5649 | 0.9437 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_132` | 411.19% | 90.14% | 90.14% | 0.8211 | 0.5620 | `false` | `true` | `true` | `ok` |

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
| `Scalar log-space` | 336.67% | 336.67% | `ok` |
| `Bounded LeastSquaresOptim LM log-space` | 35.66% | 244.57% | `ok` |
| `Bounded FastLevenbergMarquardt log-space` | 222.38% | 238.55% | `ok` |

### Source Seeds

| Method | Roles | Seed RMSE | Seed fit objective |
| --- | --- | ---: | ---: |
| `Scalar log-space` | `fit_rank_1` | 336.67% | 1.8256e+07 |
| `Scalar log-space` | `fit_rank_2` | 880.04% | 2.2661e+07 |
| `Scalar log-space` | `fit_rank_3` | 701.82% | 2.7944e+07 |
| `Scalar log-space` | `fit_rank_4` | 576.06% | 6.3667e+07 |
| `Scalar log-space` | `fit_rank_5` | 411.97% | 1.3025e+08 |
| `Scalar log-space` | `fit_rank_6` | 1636.54% | 5.2357e+08 |
| `Scalar log-space` | `fit_rank_7` | 1307.26% | 7.9998e+08 |
| `Scalar log-space` | `fit_rank_8` | 415.06% | 5.2836e+09 |
| `Scalar log-space` | `fit_rank_9` | 394.21% | 1.4560e+10 |
| `Scalar log-space` | `fit_rank_10` | 163909.75% | 2.0876e+10 |
| `Scalar log-space` | `fit_rank_11` | 486.75% | 2.0876e+10 |
| `Scalar log-space` | `fit_rank_12` | 488.66% | 2.1102e+10 |
| `Scalar log-space` | `fit_rank_13` | 163909.78% | 2.1102e+10 |
| `Scalar log-space` | `fit_rank_14` | 373.56% | 3.2350e+10 |
| `Scalar log-space` | `fit_rank_15` | 454.04% | 4.1620e+10 |
| `Scalar log-space` | `fit_rank_16` | 459.05% | 4.5801e+10 |
| `Scalar log-space` | `fit_rank_17` | 18751.98% | 5.2787e+10 |
| `Scalar log-space` | `fit_rank_18` | 1589716.23% | 5.8939e+10 |
| `Scalar log-space` | `fit_rank_19` | 509630.58% | 6.0345e+10 |
| `Scalar log-space` | `fit_rank_20` | 563828.35% | 6.0365e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 244.57% | 1.2849e+05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 35.66% | 2.6629e+05 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_3` | 170.75% | 3.3440e+07 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 294.72% | 3.6291e+07 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 331.90% | 2.1133e+09 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_6` | 332.34% | 2.2826e+09 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_7` | 311.04% | 4.1878e+09 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8` | 311.14% | 4.1991e+09 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_9` | 317.20% | 1.2005e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10` | 163909.75% | 2.0876e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_11` | 217.03% | 2.1034e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_12` | 163909.78% | 2.1102e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13` | 292.26% | 3.3018e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_14` | 18751.98% | 5.2787e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_15` | 428.43% | 5.6001e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 487.45% | 5.6793e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_17` | 1589716.23% | 5.8939e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_18` | 480.15% | 5.9525e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_19` | 509630.58% | 6.0345e+10 |
| `Bounded LeastSquaresOptim LM log-space` | `fit_rank_20` | 563828.35% | 6.0365e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_1` | 238.55% | 1.4083e+08 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 338.50% | 1.0970e+09 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_3` | 303.13% | 2.7235e+09 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 381.55% | 2.8291e+09 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 279.17% | 7.6596e+09 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6` | 287.37% | 1.2251e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_7` | 163909.75% | 2.0876e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8` | 163909.78% | 2.1102e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_9` | 470.52% | 2.2663e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10` | 423.00% | 2.5077e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 600.58% | 3.3683e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_12` | 246.42% | 3.8549e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 222.38% | 4.2298e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_14` | 363.77% | 4.5921e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_15` | 382.01% | 4.6930e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 18751.98% | 5.2787e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_17` | 1589716.23% | 5.8939e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_18` | 611.75% | 5.9091e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_19` | 509630.58% | 6.0345e+10 |
| `Bounded FastLevenbergMarquardt log-space` | `fit_rank_20` | 563828.35% | 6.0365e+10 |

### Transfer Rows

| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 336.67% | 238.56% | 336.67% | 1.0000 | 1.0000 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 880.04% | 99.32% | 99.32% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_3` | 701.82% | 51.15% | 51.15% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 576.06% | 251.57% | 251.57% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 411.97% | 354.11% | 354.11% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_6` | 1636.54% | 303.79% | 1636.54% | 1.0000 | 0.9637 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_7` | 1307.26% | 352.56% | 1307.26% | 1.0000 | 0.9768 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8` | 415.06% | 127.86% | 127.86% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_9` | 394.21% | 35.69% | 35.69% | 0.8363 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10` | 163909.75% | 331.90% | 331.90% | 1.0000 | 0.9762 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_11` | 486.75% | 331.90% | 331.90% | 1.0000 | 0.9762 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_12` | 488.66% | 332.34% | 332.34% | 1.0000 | 0.9807 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13` | 163909.78% | 332.34% | 332.34% | 1.0000 | 0.9807 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_14` | 373.56% | 68.18% | 68.18% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_15` | 454.04% | 399.21% | 399.21% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 459.05% | 234.48% | 234.48% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_17` | 18751.98% | 35.66% | 35.66% | 0.0000 | 1.0000 | `true` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_18` | 1589716.23% | 487.45% | 487.45% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_19` | 509630.58% | 480.15% | 480.15% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_20` | 563828.35% | 428.43% | 428.43% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_1` | 336.67% | 238.53% | 336.67% | 1.0000 | 0.9733 | `false` | `true` | `false` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 880.04% | 219.88% | 219.88% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_3` | 701.82% | 259.46% | 259.46% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 576.06% | 250.88% | 250.88% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 411.97% | 351.90% | 351.90% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6` | 1636.54% | 35.03% | 35.03% | 0.9992 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_7` | 1307.26% | 152.25% | 152.25% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8` | 415.06% | 341.38% | 341.38% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_9` | 394.21% | 340.84% | 340.84% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10` | 163909.75% | 303.13% | 303.13% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 486.75% | 303.13% | 303.13% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_12` | 488.66% | 381.55% | 381.55% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 163909.78% | 381.55% | 381.55% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_14` | 373.56% | 80.27% | 80.27% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_15` | 454.04% | 369.58% | 369.58% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 459.05% | 246.83% | 246.83% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_17` | 18751.98% | 338.50% | 338.50% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_18` | 1589716.23% | 600.58% | 600.58% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_19` | 509630.58% | 279.17% | 279.17% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_20` | 563828.35% | 611.75% | 611.75% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_1` | 244.57% | 244.57% | 675.52% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_2` | 35.66% | 31.35% | 31.35% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_3` | 170.75% | 168.27% | 168.27% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_4` | 294.72% | 271.14% | 271.14% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_5` | 331.90% | 331.90% | 1558.63% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_6` | 332.34% | 332.34% | 1526.81% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_7` | 311.04% | 311.04% | 1418.77% | 0.9992 | 0.9992 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_8` | 311.14% | 311.14% | 1509.03% | 0.9992 | 0.9992 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_9` | 317.20% | 317.20% | 821.61% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_10` | 163909.75% | 1562.78% | 1562.78% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_11` | 217.03% | 217.03% | 2785.84% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_12` | 163909.78% | 1610.13% | 1610.13% | 0.9999 | 0.9999 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_13` | 292.26% | 94.00% | 94.00% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_14` | 18751.98% | 287.23% | 287.23% | 0.5510 | 0.5510 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_15` | 428.43% | 428.43% | 428.43% | 1.0000 | 1.0000 | `false` | `false` | `false` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_16` | 487.45% | 487.45% | 487.45% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_17` | 1589716.23% | 273.97% | 273.97% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_18` | 480.15% | 480.15% | 480.34% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_19` | 509630.58% | 288.27% | 288.27% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_20` | 563828.35% | 386.10% | 386.10% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_1` | 244.57% | 244.54% | 244.54% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 35.66% | 35.66% | 101.45% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_3` | 170.75% | 169.32% | 169.32% | 0.9971 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 294.72% | 294.72% | 393.49% | 0.9971 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 331.90% | 331.90% | 400.44% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6` | 332.34% | 332.34% | 400.11% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_7` | 311.04% | 311.04% | 381.06% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8` | 311.14% | 311.14% | 381.34% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_9` | 317.20% | 317.20% | 337.35% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10` | 163909.75% | 303.13% | 303.13% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 217.03% | 217.03% | 360.02% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_12` | 163909.78% | 381.55% | 381.55% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 292.26% | 292.26% | 379.27% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_14` | 18751.98% | 338.50% | 338.50% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_15` | 428.43% | 342.46% | 342.46% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 487.45% | 450.07% | 450.07% | 1.0000 | 0.9999 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_17` | 1589716.23% | 600.58% | 600.58% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_18` | 480.15% | 427.76% | 427.76% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_19` | 509630.58% | 279.17% | 279.17% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_20` | 563828.35% | 611.75% | 611.75% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_1` | 238.55% | 238.55% | 555.24% | 0.9729 | 0.9729 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_2` | 338.50% | 338.50% | 1717.38% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_3` | 303.13% | 303.13% | 809.25% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_4` | 381.55% | 381.55% | 1323.26% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_5` | 279.17% | 279.17% | 507.60% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_6` | 287.37% | 287.37% | 1214.67% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_7` | 163909.75% | 1562.78% | 1562.78% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_8` | 163909.78% | 1610.13% | 1610.13% | 0.9999 | 0.9999 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_9` | 470.52% | 470.52% | 1708.97% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_10` | 423.00% | 423.00% | 1710.20% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_11` | 600.58% | 600.58% | 841.58% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_12` | 246.42% | 246.42% | 685.87% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_13` | 222.38% | 77.77% | 77.77% | 0.9978 | 0.9978 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_14` | 363.77% | 363.77% | 2106.34% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_15` | 382.01% | 107.78% | 107.78% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_16` | 18751.98% | 287.23% | 287.23% | 0.5510 | 0.5510 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_17` | 1589716.23% | 273.97% | 273.97% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_18` | 611.75% | 611.75% | 731.31% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_19` | 509630.58% | 288.27% | 288.27% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_20` | 563828.35% | 386.10% | 386.10% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 238.55% | 238.55% | 326.86% | 1.0000 | 1.0000 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 338.50% | 338.50% | 363.00% | 1.0000 | 0.9688 | `false` | `false` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_3` | 303.13% | 302.47% | 302.47% | 1.0000 | 0.9873 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 381.55% | 291.20% | 291.20% | 1.0000 | 0.9753 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 279.17% | 253.58% | 253.58% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_6` | 287.37% | 265.36% | 265.36% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_7` | 163909.75% | 331.90% | 331.90% | 1.0000 | 0.9762 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8` | 163909.78% | 332.34% | 332.34% | 1.0000 | 0.9807 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_9` | 470.52% | 409.36% | 409.36% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10` | 423.00% | 409.21% | 409.21% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_11` | 600.58% | 425.71% | 425.71% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_12` | 246.42% | 245.91% | 245.91% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13` | 222.38% | 217.36% | 217.36% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_14` | 363.77% | 333.13% | 333.13% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_15` | 382.01% | 304.96% | 304.96% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 18751.98% | 35.66% | 35.66% | 0.0000 | 1.0000 | `true` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_17` | 1589716.23% | 487.45% | 487.45% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_18` | 611.75% | 611.75% | 611.75% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_19` | 509630.58% | 480.15% | 480.15% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_20` | 563828.35% | 428.43% | 428.43% | 1.0000 | 1.0000 | `false` | `true` | `true` | `ok` |

