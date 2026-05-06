# Cross-Polish Basin Diagnostic

- Generated: `2026-04-24 21:20:05`
- Basis: imported bilby `odepe_nopolish` pools
- Methods: `Scalar log-space`, `Bounded LeastSquaresOptim LM log-space`, `Bounded FastLevenbergMarquardt log-space`
- Source seed mode: `full analyzed representative pool`
- Same-attractor threshold: `0.001` under `solution_distance(...)`

## Pairwise Transfer Summary

| Source → Target | Attempted | Successful | Same target oracle | Same target selected | Same either | Benchmark improved vs seed | Fit improved vs seed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | 156 | 156 | 1 | 1 | 2 | 118 | 156 |
| `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | 156 | 156 | 0 | 8 | 8 | 111 | 156 |
| `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | 150 | 150 | 0 | 0 | 0 | 111 | 149 |
| `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | 150 | 150 | 0 | 2 | 2 | 102 | 149 |
| `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | 85 | 85 | 0 | 1 | 1 | 68 | 80 |
| `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | 85 | 85 | 1 | 0 | 1 | 69 | 82 |

## Per-Case Diagnosis

| Case | Diagnosis | Successful transfers | Same-attractor transfers | Same-attractor rate |
| --- | --- | ---: | ---: | ---: |
| `seir_3_1em4` | `different_basin_likely` | 108 | 1 | 0.009 |
| `daisy_mamil4_1_1em4` | `different_basin_likely` | 554 | 11 | 0.020 |
| `crauste_7_1em4` | `different_basin_likely` | 120 | 2 | 0.017 |

## Fit Improves But Benchmark Worsens

| Case | Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Source fit | Transfer selected fit |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| `seir_3_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 5.03% | 5.03% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 1.04% | 1.04% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 5.03% | 5.03% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_3` | 4.74% | 4.74% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 1.04% | 1.04% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_1` | 5.05% | 5.05% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_2` | 4.92% | 4.92% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_3` | 4.00% | 4.00% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_4` | 3.89% | 3.89% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 5.05% | 5.05% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 4.92% | 4.92% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_4` | 3.89% | 3.89% | 5.9881 | 5.9881 |
| `seir_3_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_5` | 10.48% | 10.48% | 5.9881 | 5.9881 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_8` | 41.05% | 41.05% | 2.6963e-05 | 9.9771e-06 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_10` | 18.28% | 18.28% | 2.7937e-05 | 9.9771e-06 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_11` | 43.29% | 43.29% | 3.2558e-05 | 1.1045e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_12` | 27.69% | 27.69% | 1.1850e-04 | 1.0793e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_13` | 26.26% | 26.26% | 1.6180e-04 | 1.0651e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_14` | 34.30% | 34.30% | 1.9827e-04 | 1.0660e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_16` | 29.86% | 29.86% | 6.0335e-04 | 5.2748e-04 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_29` | 39.72% | 39.72% | 0.0014 | 1.0391e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_30` | 39.77% | 39.77% | 0.0014 | 1.0402e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_32` | 34.69% | 34.69% | 0.0014 | 1.0431e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_33` | 39.86% | 39.86% | 0.0014 | 1.0394e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_76` | 36.39% | 36.39% | 0.0024 | 0.0024 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_78` | 30.64% | 30.64% | 0.0072 | 5.3367e-04 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_79` | 32.12% | 32.12% | 0.0124 | 2.2154e-04 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_10` | 18.28% | 18.28% | 2.7937e-05 | 2.7553e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 43.29% | 43.29% | 3.2558e-05 | 1.0969e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_12` | 27.69% | 27.69% | 1.1850e-04 | 1.0828e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 26.26% | 26.26% | 1.6180e-04 | 1.0715e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_14` | 34.30% | 34.30% | 1.9827e-04 | 1.0646e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_16` | 29.86% | 29.86% | 6.0335e-04 | 5.3468e-04 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_26` | 34.79% | 34.79% | 0.0014 | 1.0502e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_30` | 39.77% | 39.77% | 0.0014 | 1.5708e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_31` | 34.74% | 34.74% | 0.0014 | 2.4971e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_32` | 34.69% | 34.69% | 0.0014 | 1.8721e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_33` | 39.86% | 39.86% | 0.0014 | 1.0577e-05 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_36` | 78.47% | 78.47% | 0.0024 | 2.6234e-04 |
| `daisy_mamil4_1_1em4` | `Scalar log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_79` | 32.12% | 32.12% | 0.0124 | 5.6521e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_1` | 29.92% | 29.92% | 9.9665e-06 | 9.9665e-06 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_2` | 0.63% | 0.63% | 9.9666e-06 | 9.9665e-06 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_20` | 35.21% | 35.21% | 1.6595e-05 | 9.9715e-06 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_21` | 10.22% | 10.22% | 2.0818e-05 | 9.9717e-06 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_35` | 31.47% | 31.47% | 4.1314e-04 | 9.9740e-06 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_36` | 32.42% | 32.42% | 4.3938e-04 | 1.0999e-05 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_37` | 25.86% | 25.86% | 4.5438e-04 | 3.0732e-05 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_38` | 31.48% | 31.48% | 4.9779e-04 | 4.7398e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_47` | 31.90% | 31.90% | 5.3094e-04 | 5.2626e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_48` | 31.88% | 31.88% | 5.3127e-04 | 5.2633e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_51` | 31.82% | 31.82% | 5.3303e-04 | 5.2652e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_52` | 31.77% | 31.77% | 5.3305e-04 | 5.2658e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_53` | 31.39% | 31.39% | 5.3355e-04 | 5.2310e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_59` | 31.75% | 31.75% | 5.3451e-04 | 5.2667e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_61` | 31.69% | 31.69% | 5.3507e-04 | 5.2647e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_67` | 31.66% | 31.66% | 5.3547e-04 | 5.2607e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_71` | 31.65% | 31.65% | 5.3669e-04 | 5.2612e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_73` | 31.66% | 31.66% | 5.3698e-04 | 5.2654e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_76` | 31.66% | 31.66% | 5.3774e-04 | 5.2610e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_77` | 31.69% | 31.69% | 5.3800e-04 | 5.2670e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_78` | 31.62% | 31.62% | 5.3802e-04 | 5.2642e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_79,fit_rank_83` | 31.64% | 31.64% | 5.3834e-04 | 5.2669e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_80` | 31.64% | 31.64% | 5.3853e-04 | 5.2619e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_82` | 31.64% | 31.64% | 5.3902e-04 | 5.2626e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_84` | 31.64% | 31.64% | 5.3959e-04 | 5.2605e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_85` | 31.66% | 31.66% | 5.3960e-04 | 5.2646e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_88` | 31.63% | 31.63% | 5.4026e-04 | 5.2661e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_96` | 31.69% | 31.69% | 5.4263e-04 | 5.2671e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_97` | 31.61% | 31.61% | 5.4266e-04 | 5.2626e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_99` | 31.66% | 31.66% | 5.4336e-04 | 5.2657e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_100` | 31.70% | 31.70% | 5.4406e-04 | 5.2668e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_102` | 31.64% | 31.64% | 5.4543e-04 | 5.2640e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_103` | 31.73% | 31.73% | 5.4644e-04 | 5.2670e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_104` | 31.79% | 31.79% | 5.4879e-04 | 5.2671e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_106` | 31.86% | 31.86% | 5.5431e-04 | 5.2668e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_116` | 38.41% | 38.41% | 9.8450e-04 | 1.0658e-05 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_117` | 31.39% | 31.39% | 0.0011 | 1.0491e-05 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_122,fit_rank_123` | 36.40% | 36.40% | 0.0024 | 0.0024 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 0.63% | 0.63% | 9.9666e-06 | 9.9665e-06 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_33` | 96.77% | 96.77% | 2.3300e-04 | 2.3292e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_34` | 72.53% | 72.53% | 2.3518e-04 | 2.3511e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_36` | 32.42% | 32.42% | 4.3938e-04 | 4.2538e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_52` | 31.77% | 31.77% | 5.3305e-04 | 5.2482e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_53` | 31.39% | 31.39% | 5.3355e-04 | 5.2019e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_59` | 31.75% | 31.75% | 5.3451e-04 | 5.2481e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_61` | 31.69% | 31.69% | 5.3507e-04 | 5.2407e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_67` | 31.66% | 31.66% | 5.3547e-04 | 5.2379e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_71` | 31.65% | 31.65% | 5.3669e-04 | 5.2361e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_73` | 31.66% | 31.66% | 5.3698e-04 | 5.2419e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_76` | 31.66% | 31.66% | 5.3774e-04 | 5.2367e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_77` | 31.69% | 31.69% | 5.3800e-04 | 5.2527e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_78` | 31.62% | 31.62% | 5.3802e-04 | 5.2401e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_79,fit_rank_83` | 31.64% | 31.64% | 5.3834e-04 | 5.2479e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_80` | 31.64% | 31.64% | 5.3853e-04 | 5.2366e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_82` | 31.64% | 31.64% | 5.3902e-04 | 5.2357e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_84` | 31.64% | 31.64% | 5.3959e-04 | 5.2233e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_85` | 31.66% | 31.66% | 5.3960e-04 | 5.2382e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_88` | 31.63% | 31.63% | 5.4026e-04 | 5.2450e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_96` | 31.69% | 31.69% | 5.4263e-04 | 5.2482e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_97` | 31.61% | 31.61% | 5.4266e-04 | 5.2266e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_99` | 31.66% | 31.66% | 5.4336e-04 | 5.2406e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_100` | 31.70% | 31.70% | 5.4406e-04 | 5.2419e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_102` | 31.64% | 31.64% | 5.4543e-04 | 5.2270e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_103` | 31.73% | 31.73% | 5.4644e-04 | 5.2462e-04 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_116` | 38.41% | 38.41% | 9.8450e-04 | 1.0419e-05 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_117` | 31.39% | 31.39% | 0.0011 | 1.0432e-05 |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_122,fit_rank_123` | 36.40% | 36.40% | 0.0024 | 0.0024 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_69` | 88.52% | 88.52% | 2.3074e-04 | 2.0233e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_74` | 65.55% | 65.55% | 2.3818e-04 | 2.1618e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_75` | 68.64% | 68.64% | 2.3840e-04 | 2.2428e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_76` | 91.51% | 91.51% | 2.3934e-04 | 2.1908e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_77` | 88.65% | 88.65% | 2.4003e-04 | 2.1721e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_78` | 63.81% | 63.81% | 2.4071e-04 | 2.1492e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_79` | 89.43% | 89.43% | 2.4137e-04 | 2.2150e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_80` | 94.15% | 94.15% | 2.4271e-04 | 2.3546e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_81` | 83.72% | 83.72% | 2.4686e-04 | 2.1407e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_82` | 63.48% | 63.48% | 2.4915e-04 | 2.2552e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_83` | 61.78% | 61.78% | 2.5216e-04 | 2.2034e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_84` | 63.47% | 63.47% | 2.5648e-04 | 2.3169e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_85` | 81.98% | 81.98% | 2.5851e-04 | 2.2680e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_86` | 80.72% | 80.72% | 2.6301e-04 | 2.2910e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_87` | 81.02% | 81.02% | 2.6403e-04 | 2.2893e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_88` | 80.48% | 80.48% | 2.6524e-04 | 2.2988e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_89` | 79.57% | 79.57% | 2.6748e-04 | 2.2994e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_90` | 59.44% | 59.44% | 2.7252e-04 | 2.3796e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_91` | 58.36% | 58.36% | 2.7666e-04 | 2.3674e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_92` | 76.20% | 76.20% | 2.7719e-04 | 2.3208e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_93` | 74.52% | 74.52% | 2.8560e-04 | 2.3440e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_94` | 57.61% | 57.61% | 2.9245e-04 | 2.3958e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_95` | 57.59% | 57.59% | 2.9587e-04 | 2.3919e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_96` | 56.11% | 56.11% | 2.9757e-04 | 2.1519e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_98` | 60.64% | 60.64% | 3.3452e-04 | 2.3980e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_99` | 70.96% | 70.96% | 3.5186e-04 | 2.4354e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_103` | 30.89% | 30.89% | 4.3672e-04 | 9.9730e-06 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_105` | 85.17% | 85.17% | 4.6085e-04 | 2.4328e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_106,fit_rank_107` | 84.35% | 84.35% | 5.1214e-04 | 2.4297e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_69` | 88.52% | 88.52% | 2.3074e-04 | 1.9567e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_70` | 64.42% | 64.42% | 2.3169e-04 | 1.9884e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_72` | 87.89% | 87.89% | 2.3368e-04 | 1.9709e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_74` | 65.55% | 65.55% | 2.3818e-04 | 2.1083e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_75` | 68.64% | 68.64% | 2.3840e-04 | 2.1923e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_76` | 91.51% | 91.51% | 2.3934e-04 | 2.1319e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_77` | 88.65% | 88.65% | 2.4003e-04 | 2.1182e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_78` | 63.81% | 63.81% | 2.4071e-04 | 2.0911e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_79` | 89.43% | 89.43% | 2.4137e-04 | 2.1655e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_80` | 94.15% | 94.15% | 2.4271e-04 | 2.3238e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_81` | 83.72% | 83.72% | 2.4686e-04 | 2.0995e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_82` | 63.48% | 63.48% | 2.4915e-04 | 2.2297e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_83` | 61.78% | 61.78% | 2.5216e-04 | 2.1917e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_84` | 63.47% | 63.47% | 2.5648e-04 | 2.2838e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_85` | 81.98% | 81.98% | 2.5851e-04 | 2.2359e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_86` | 80.72% | 80.72% | 2.6301e-04 | 2.2443e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_87` | 81.02% | 81.02% | 2.6403e-04 | 2.2617e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_88` | 80.48% | 80.48% | 2.6524e-04 | 2.2810e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_89` | 79.57% | 79.57% | 2.6748e-04 | 2.2597e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_90` | 59.44% | 59.44% | 2.7252e-04 | 2.3408e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_91` | 58.36% | 58.36% | 2.7666e-04 | 2.3225e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_92` | 76.20% | 76.20% | 2.7719e-04 | 2.2763e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_93` | 74.52% | 74.52% | 2.8560e-04 | 2.2940e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_94` | 57.61% | 57.61% | 2.9245e-04 | 2.3451e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_95` | 57.59% | 57.59% | 2.9587e-04 | 2.3370e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_96` | 56.11% | 56.11% | 2.9757e-04 | 2.1058e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_98` | 60.64% | 60.64% | 3.3452e-04 | 2.3124e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_99` | 70.96% | 70.96% | 3.5186e-04 | 2.3444e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_101` | 71.30% | 71.30% | 3.9620e-04 | 2.3369e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_105` | 85.17% | 85.17% | 4.6085e-04 | 2.2769e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_106,fit_rank_107` | 84.35% | 84.35% | 5.1214e-04 | 2.3141e-04 |
| `daisy_mamil4_1_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_116` | 31.89% | 31.89% | 0.0016 | 1.0500e-05 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_1` | 244.57% | 244.57% | 1.2849e+05 | 5.6274e+03 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_5` | 331.90% | 331.90% | 2.1133e+09 | 6.7067e+05 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_6` | 332.34% | 332.34% | 2.2826e+09 | 5.0407e+05 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_7` | 311.04% | 311.04% | 4.1878e+09 | 5.1738e+05 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_8` | 311.14% | 311.14% | 4.1991e+09 | 5.6597e+05 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_9` | 317.20% | 317.20% | 1.2005e+10 | 9.7699e+07 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_11` | 217.03% | 217.03% | 2.1034e+10 | 1.5664e+08 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_16` | 487.45% | 487.45% | 5.6793e+10 | 5.6793e+10 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Scalar log-space` | `fit_rank_18` | 480.15% | 480.15% | 5.9525e+10 | 5.9478e+10 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_2` | 35.66% | 35.66% | 2.6629e+05 | 6.9296e+04 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_4` | 294.72% | 294.72% | 3.6291e+07 | 3.0759e+07 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_5` | 331.90% | 331.90% | 2.1133e+09 | 2.1072e+09 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_6` | 332.34% | 332.34% | 2.2826e+09 | 2.2706e+09 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_7` | 311.04% | 311.04% | 4.1878e+09 | 4.1615e+09 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_8` | 311.14% | 311.14% | 4.1991e+09 | 4.1726e+09 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_9` | 317.20% | 317.20% | 1.2005e+10 | 8.0290e+08 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_11` | 217.03% | 217.03% | 2.1034e+10 | 7.6820e+09 |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` → `Bounded FastLevenbergMarquardt log-space` | `fit_rank_13` | 292.26% | 292.26% | 3.3018e+10 | 3.2442e+10 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_1` | 238.55% | 238.55% | 1.4083e+08 | 1.1400e+08 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_2` | 338.50% | 338.50% | 1.0970e+09 | 1.0349e+06 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_3` | 303.13% | 303.13% | 2.7235e+09 | 7.5181e+04 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_4` | 381.55% | 381.55% | 2.8291e+09 | 3.8830e+05 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_5` | 279.17% | 279.17% | 7.6596e+09 | 5.3052e+07 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_6` | 287.37% | 287.37% | 1.2251e+10 | 1.5470e+05 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_9` | 470.52% | 470.52% | 2.2663e+10 | 8.5754e+05 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_10` | 423.00% | 423.00% | 2.5077e+10 | 8.7854e+05 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_11` | 600.58% | 600.58% | 3.3683e+10 | 3.1698e+07 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_12` | 246.42% | 246.42% | 3.8549e+10 | 9.5957e+07 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_14` | 363.77% | 363.77% | 4.5921e+10 | 8.9425e+05 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Scalar log-space` | `fit_rank_18` | 611.75% | 611.75% | 5.9091e+10 | 1.8058e+08 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_1` | 238.55% | 238.55% | 1.4083e+08 | 2.7412e+07 |
| `crauste_7_1em4` | `Bounded FastLevenbergMarquardt log-space` → `Bounded LeastSquaresOptim LM log-space` | `fit_rank_2` | 338.50% | 338.50% | 1.0970e+09 | 2.4732e+08 |

## Notes

- `summary.tsv` contains one row per transferred seed.
- `case_notes.md` contains from-cold winners and detailed transfer tables per case.
