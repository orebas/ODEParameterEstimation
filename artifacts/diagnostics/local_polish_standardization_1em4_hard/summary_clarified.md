# Local Polish Standardization Sweep

- Generated: `2026-04-24 12:39:55`
- Basis: imported bilby `odepe_nopolish` pools
- Research analysis mode: `ungated`
- Decision metric: `best-in-set / oracle view`
- Suite filter: positive-box `1e-4` cases, `amigo2 < odepe_polish`, saved `odepe_polish >= 10%`, ratio `>= 2x`, excluding `cstr`
- Shortlist: `Scalar original-space`, `Scalar log-space`, `Bounded LeastSquaresOptim LM log-space`, `Bounded FastLevenbergMarquardt log-space`

## Suite

| Case | Saved `amigo2` | Saved `odepe_polish` | Gap Ratio |
| --- | ---: | ---: | ---: |
| `crauste_5_1em4` | 0.94% | 134.08% | 142.73x |
| `seir_6_1em4` | 1.33% | 82.04% | 61.87x |
| `crauste_6_1em4` | 5.35% | 199.55% | 37.32x |
| `daisy_mamil4_1_1em4` | 1.17% | 41.05% | 35.03x |
| `seir_7_1em4` | 4.80% | 149.27% | 31.11x |
| `crauste_1_1em4` | 14.93% | 336.70% | 22.55x |
| `crauste_0_1em4` | 9.96% | 214.81% | 21.56x |
| `hiv_5_1em4` | 5.52% | 78.88% | 14.28x |
| `brusselator_0_1em4` | 54.30% | 633.03% | 11.66x |
| `crauste_7_1em4` | 19.62% | 167.02% | 8.51x |
| `brusselator_4_1em4` | 267.65% | 2033.43% | 7.60x |
| `hiv_2_1em4` | 14.98% | 110.31% | 7.37x |
| `hiv_7_1em4` | 19.46% | 135.65% | 6.97x |
| `crauste_4_1em4` | 18.66% | 126.63% | 6.79x |
| `crauste_2_1em4` | 28.77% | 173.50% | 6.03x |
| `brusselator_3_1em4` | 45.93% | 226.46% | 4.93x |
| `seir_3_1em4` | 7.04% | 30.19% | 4.29x |
| `biohydrogenation_4_1em4` | 11.99% | 43.18% | 3.60x |
| `brusselator_7_1em4` | 210.62% | 613.69% | 2.91x |
| `hiv_4_1em4` | 90.37% | 180.79% | 2.00x |

## Best-In-Set / Oracle View

| Case | Imported best | Saved `amigo2` | Saved `odepe_polish` | Scalar original-space | Scalar log-space | Bounded LeastSquaresOptim LM log-space | Bounded FastLevenbergMarquardt log-space |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `crauste_5_1em4` | 1094.98% | 0.94% | 134.08% | 1094.96% | 70.21% | 32.17% | 25.33% |
| `seir_6_1em4` | 162.09% | 1.33% | 82.04% | 129.17% | 33.66% | 11.51% | 0.95% |
| `crauste_6_1em4` | 187.73% | 5.35% | 199.55% | 180.28% | 187.73% | 30.41% | 33.63% |
| `daisy_mamil4_1_1em4` | 42.13% | 1.17% | 41.05% | 42.13% | 18.28% | 0.63% | 6.77% |
| `seir_7_1em4` | 149.27% | 4.80% | 149.27% | 84.07% | 9.44% | 12.65% | 10.70% |
| `crauste_1_1em4` | 36378.43% | 14.93% | 336.70% | 36378.48% | 537.39% | 48.17% | 329.36% |
| `crauste_0_1em4` | 429.57% | 9.96% | 214.81% | 416.65% | 14.32% | 9.96% | 9.96% |
| `hiv_5_1em4` | 650.76% | 5.52% | 78.88% | 650.76% | 5.81% | 2.54% | 4.89% |
| `brusselator_0_1em4` | Inf | 54.30% | 633.03% | Inf | Inf | Inf | Inf |
| `crauste_7_1em4` | 6445.99% | 19.62% | 167.02% | 6445.99% | 333.74% | 35.66% | 222.38% |
| `brusselator_4_1em4` | 2033.43% | 267.65% | 2033.43% | 2033.43% | 2033.43% | 676.89% | 676.89% |
| `hiv_2_1em4` | 225.67% | 14.98% | 110.31% | 225.67% | 7.95% | 0.33% | 2.79% |
| `hiv_7_1em4` | 540.40% | 19.46% | 135.65% | 540.40% | 4.96% | 13.83% | 15.36% |
| `crauste_4_1em4` | 21.65% | 18.66% | 126.63% | 16.70% | 14.73% | 15.28% | 15.48% |
| `crauste_2_1em4` | 2597.41% | 28.77% | 173.50% | 2597.41% | 224.56% | 60.71% | 98.54% |
| `brusselator_3_1em4` | 226.46% | 45.93% | 226.46% | 226.46% | 226.46% | 226.46% | 226.46% |
| `seir_3_1em4` | 322.86% | 7.04% | 30.19% | 112.95% | 1.04% | 27.90% | 3.89% |
| `biohydrogenation_4_1em4` | 28.69% | 11.99% | 43.18% | 28.69% | 16.73% | 12.37% | 16.77% |
| `brusselator_7_1em4` | Inf | 210.62% | 613.69% | Inf | Inf | Inf | Inf |
| `hiv_4_1em4` | 1268.10% | 90.37% | 180.79% | 1257.05% | 39.70% | 15.31% | 90.35% |

## Fit-Selected / Operational View

| Case | Scalar original-space | Scalar log-space | Bounded LeastSquaresOptim LM log-space | Bounded FastLevenbergMarquardt log-space |
| --- | ---: | ---: | ---: | ---: |
| `crauste_5_1em4` | 5262.08% | 70.21% | 32.17% | 25.33% |
| `seir_6_1em4` | 129.17% | 34.31% | 11.51% | 1.33% |
| `crauste_6_1em4` | 5075.69% | 264.06% | 33.91% | 80.89% |
| `daisy_mamil4_1_1em4` | 100.04% | 45.73% | 29.92% | 6.77% |
| `seir_7_1em4` | 122.08% | 11.80% | 12.65% | 14.18% |
| `crauste_1_1em4` | 55020.18% | 1819.02% | 48.17% | 380.37% |
| `crauste_0_1em4` | 416.65% | 19.19% | 9.96% | 9.96% |
| `hiv_5_1em4` | 4015.65% | 5.81% | 5.52% | 5.52% |
| `brusselator_0_1em4` | Inf | Inf | Inf | Inf |
| `crauste_7_1em4` | 198638.81% | 1257.51% | 244.57% | 238.55% |
| `brusselator_4_1em4` | 7827225.99% | 625245.84% | 676.89% | 676.89% |
| `hiv_2_1em4` | 169207.58% | 11.41% | 14.98% | 14.98% |
| `hiv_7_1em4` | 140547.80% | 19.46% | 19.46% | 19.46% |
| `crauste_4_1em4` | 16.70% | 14.73% | 15.28% | 15.48% |
| `crauste_2_1em4` | 5004.89% | 224.56% | 62.43% | 225.43% |
| `brusselator_3_1em4` | 254362.06% | 1285748.58% | 682.87% | 682.87% |
| `seir_3_1em4` | 127.50% | 8.11% | 27.90% | 5.05% |
| `biohydrogenation_4_1em4` | 33.88% | 30.58% | 25.58% | 26.23% |
| `brusselator_7_1em4` | Inf | Inf | Inf | Inf |
| `hiv_4_1em4` | 101429.00% | 13642.52% | 90.35% | 90.35% |

## Aggregate Comparison vs `Scalar log-space`

| Arm | Oracle best-in-set | Fit-selected | Median runtime ratio |
| --- | --- | --- | ---: |
| `Scalar original-space` | 1 better / 3 tie / 15 worse / 1 unsupported | 1 better / 1 tie / 17 worse / 1 unsupported | 1.038x |
| `Bounded LeastSquaresOptim LM log-space` | 13 better / 2 tie / 4 worse / 1 unsupported | 13 better / 2 tie / 4 worse / 1 unsupported | 0.732x |
| `Bounded FastLevenbergMarquardt log-space` | 11 better / 2 tie / 6 worse / 1 unsupported | 13 better / 2 tie / 4 worse / 1 unsupported | 0.546x |

## Surprise Cases

- Clear `Bounded LeastSquaresOptim LM log-space` wins: `daisy_mamil4_1_1em4`, `crauste_1_1em4`, `hiv_5_1em4`, `crauste_7_1em4`, `hiv_2_1em4`, `crauste_2_1em4`, `biohydrogenation_4_1em4`, `hiv_4_1em4`
- Clear `Bounded FastLevenbergMarquardt log-space` wins: `crauste_5_1em4`, `seir_6_1em4`
- Clear `Scalar log-space` wins: `hiv_7_1em4`, `seir_3_1em4`
- Large oracle-vs-selected gaps on the oracle-winning arm: `daisy_mamil4_1_1em4`, `hiv_5_1em4`, `crauste_7_1em4`, `hiv_2_1em4`, `hiv_7_1em4`, `brusselator_3_1em4`, `seir_3_1em4`, `biohydrogenation_4_1em4`, `hiv_4_1em4`

## Per-Case Oracle Winners

| Case | Oracle winner | Oracle RMSE | Fit-selected RMSE on winner |
| --- | --- | ---: | ---: |
| `crauste_5_1em4` | `Bounded FastLevenbergMarquardt log-space` | 25.33% | 25.33% |
| `seir_6_1em4` | `Bounded FastLevenbergMarquardt log-space` | 0.95% | 1.33% |
| `crauste_6_1em4` | `Bounded LeastSquaresOptim LM log-space` | 30.41% | 33.91% |
| `daisy_mamil4_1_1em4` | `Bounded LeastSquaresOptim LM log-space` | 0.63% | 29.92% |
| `seir_7_1em4` | `Scalar log-space` | 9.44% | 11.80% |
| `crauste_1_1em4` | `Bounded LeastSquaresOptim LM log-space` | 48.17% | 48.17% |
| `crauste_0_1em4` | `Bounded LeastSquaresOptim LM log-space` | 9.96% | 9.96% |
| `hiv_5_1em4` | `Bounded LeastSquaresOptim LM log-space` | 2.54% | 5.52% |
| `brusselator_0_1em4` | `N/A` | Inf | Inf |
| `crauste_7_1em4` | `Bounded LeastSquaresOptim LM log-space` | 35.66% | 244.57% |
| `brusselator_4_1em4` | `Bounded LeastSquaresOptim LM log-space` | 676.89% | 676.89% |
| `hiv_2_1em4` | `Bounded LeastSquaresOptim LM log-space` | 0.33% | 14.98% |
| `hiv_7_1em4` | `Scalar log-space` | 4.96% | 19.46% |
| `crauste_4_1em4` | `Scalar log-space` | 14.73% | 14.73% |
| `crauste_2_1em4` | `Bounded LeastSquaresOptim LM log-space` | 60.71% | 62.43% |
| `brusselator_3_1em4` | `Scalar original-space` | 226.46% | 254362.06% |
| `seir_3_1em4` | `Scalar log-space` | 1.04% | 8.11% |
| `biohydrogenation_4_1em4` | `Bounded LeastSquaresOptim LM log-space` | 12.37% | 25.58% |
| `brusselator_7_1em4` | `N/A` | Inf | Inf |
| `hiv_4_1em4` | `Bounded LeastSquaresOptim LM log-space` | 15.31% | 90.35% |
