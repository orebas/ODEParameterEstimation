# Log-Space L2 Regularization Sweep

- Generated: `2026-04-26 20:19:15`
- Basis: imported bilby `odepe_nopolish` pools
- Research analysis mode: `ungated`
- Penalty: `RSS(x) + λ * ||log(x)||²` for scalar, equivalent augmented least-squares residual for residual methods
- Lambda grid: `0`, `1e-04`, `1e-03`, `1e-02`, `1e-01`
- Suite filter: positive-box `1e-4` cases, `amigo2 < odepe_polish`, saved `odepe_polish >= 10%`, ratio `>= 2x`, excluding `cstr`

## Oracle Aggregate vs Each Method's `λ = 0`

| Method | λ | Oracle vs same-method `λ=0` | Median runtime ratio |
| --- | ---: | --- | ---: |
| `Scalar log-space` | `0` | 0 better / 16 tie / 0 worse / 0 unsupported | 1.000x |
| `Scalar log-space` | `1e-04` | 10 better / 4 tie / 2 worse / 0 unsupported | 0.994x |
| `Scalar log-space` | `1e-03` | 7 better / 4 tie / 5 worse / 0 unsupported | 0.992x |
| `Scalar log-space` | `1e-02` | 6 better / 4 tie / 6 worse / 0 unsupported | 0.972x |
| `Scalar log-space` | `1e-01` | 7 better / 4 tie / 5 worse / 0 unsupported | 0.992x |
| `Bounded LeastSquaresOptim LM log-space` | `0` | 0 better / 16 tie / 0 worse / 0 unsupported | 1.000x |
| `Bounded LeastSquaresOptim LM log-space` | `1e-04` | 7 better / 5 tie / 4 worse / 0 unsupported | 0.995x |
| `Bounded LeastSquaresOptim LM log-space` | `1e-03` | 5 better / 5 tie / 6 worse / 0 unsupported | 1.018x |
| `Bounded LeastSquaresOptim LM log-space` | `1e-02` | 7 better / 3 tie / 6 worse / 0 unsupported | 1.010x |
| `Bounded LeastSquaresOptim LM log-space` | `1e-01` | 7 better / 3 tie / 6 worse / 0 unsupported | 0.975x |
| `Bounded FastLevenbergMarquardt log-space` | `0` | 0 better / 16 tie / 0 worse / 0 unsupported | 1.000x |
| `Bounded FastLevenbergMarquardt log-space` | `1e-04` | 8 better / 3 tie / 5 worse / 0 unsupported | 1.022x |
| `Bounded FastLevenbergMarquardt log-space` | `1e-03` | 7 better / 3 tie / 6 worse / 0 unsupported | 1.070x |
| `Bounded FastLevenbergMarquardt log-space` | `1e-02` | 7 better / 3 tie / 6 worse / 0 unsupported | 1.048x |
| `Bounded FastLevenbergMarquardt log-space` | `1e-01` | 7 better / 3 tie / 6 worse / 0 unsupported | 1.037x |

## Oracle Aggregate vs Unregularized Bounded LeastSquaresOptim LM

| Arm | λ | Oracle vs `Bounded LeastSquaresOptim LM log-space, λ=0` |
| --- | ---: | --- |
| `Scalar log-space` | `0` | 2 better / 2 tie / 12 worse / 0 unsupported |
| `Scalar log-space` | `1e-04` | 3 better / 2 tie / 11 worse / 0 unsupported |
| `Scalar log-space` | `1e-03` | 4 better / 2 tie / 10 worse / 0 unsupported |
| `Scalar log-space` | `1e-02` | 3 better / 2 tie / 11 worse / 0 unsupported |
| `Scalar log-space` | `1e-01` | 3 better / 2 tie / 11 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `0` | 0 better / 16 tie / 0 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `1e-04` | 7 better / 5 tie / 4 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `1e-03` | 5 better / 5 tie / 6 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `1e-02` | 7 better / 3 tie / 6 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `1e-01` | 7 better / 3 tie / 6 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `0` | 4 better / 3 tie / 9 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `1e-04` | 6 better / 3 tie / 7 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `1e-03` | 6 better / 3 tie / 7 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `1e-02` | 6 better / 3 tie / 7 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `1e-01` | 6 better / 3 tie / 7 worse / 0 unsupported |

## Per-Case Best λ / Oracle View

| Case | Scalar best λ | Scalar best RMSE | LSO best λ | LSO best RMSE | FastLM best λ | FastLM best RMSE |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `crauste_5_1em4` | `1e-02` | 34.71% | `1e-01` | 30.08% | `1e-01` | 1.84% |
| `seir_6_1em4` | `1e-03` | 0.07% | `1e-03` | 0.07% | `1e-03` | 0.07% |
| `crauste_6_1em4` | `0` | 146.44% | `1e-01` | 28.91% | `0` | 33.63% |
| `daisy_mamil4_1_1em4` | `1e-04` | 7.43% | `0` | 0.63% | `0` | 6.77% |
| `seir_7_1em4` | `1e-02` | 0.27% | `1e-03` | 1.15% | `1e-03` | 0.12% |
| `crauste_1_1em4` | `1e-01` | 537.39% | `1e-01` | 48.01% | `1e-04` | 88.85% |
| `crauste_0_1em4` | `1e-03` | 13.69% | `1e-01` | 6.47% | `1e-01` | 6.39% |
| `hiv_5_1em4` | `1e-04` | 4.36% | `0` | 2.54% | `0` | 4.89% |
| `brusselator_0_1em4` | `N/A` | Inf | `N/A` | Inf | `N/A` | Inf |
| `crauste_7_1em4` | `1e-04` | 273.84% | `0` | 35.66% | `1e-02` | 23.57% |
| `brusselator_4_1em4` | `0` | 2033.43% | `0` | 676.89% | `0` | 676.89% |
| `hiv_2_1em4` | `1e-04` | 3.49% | `0` | 0.33% | `0` | 2.79% |
| `hiv_7_1em4` | `1e-04` | 10.48% | `1e-04` | 8.50% | `1e-04` | 10.45% |
| `crauste_4_1em4` | `1e-01` | 12.23% | `1e-01` | 3.09% | `1e-01` | 13.53% |
| `crauste_2_1em4` | `1e-01` | 193.23% | `1e-02` | 60.48% | `1e-01` | 43.87% |
| `brusselator_3_1em4` | `0` | 226.46% | `0` | 226.46% | `0` | 226.46% |

## Cases Improved vs `λ = 0`

- `Scalar log-space`: crauste_5_1em4 (`1e-02`), seir_6_1em4 (`1e-03`), daisy_mamil4_1_1em4 (`1e-04`), seir_7_1em4 (`1e-02`), crauste_0_1em4 (`1e-03`), hiv_5_1em4 (`1e-04`), crauste_7_1em4 (`1e-04`), hiv_2_1em4 (`1e-04`), hiv_7_1em4 (`1e-04`), crauste_4_1em4 (`1e-01`), crauste_2_1em4 (`1e-01`)
- `Bounded LeastSquaresOptim LM log-space`: crauste_5_1em4 (`1e-01`), seir_6_1em4 (`1e-03`), crauste_6_1em4 (`1e-01`), seir_7_1em4 (`1e-03`), crauste_1_1em4 (`1e-01`), crauste_0_1em4 (`1e-01`), hiv_7_1em4 (`1e-04`), crauste_4_1em4 (`1e-01`), crauste_2_1em4 (`1e-02`)
- `Bounded FastLevenbergMarquardt log-space`: crauste_5_1em4 (`1e-01`), seir_6_1em4 (`1e-03`), seir_7_1em4 (`1e-03`), crauste_1_1em4 (`1e-04`), crauste_0_1em4 (`1e-01`), crauste_7_1em4 (`1e-02`), hiv_7_1em4 (`1e-04`), crauste_4_1em4 (`1e-01`), crauste_2_1em4 (`1e-01`)
