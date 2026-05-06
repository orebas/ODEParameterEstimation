# Log-Space L2 Regularization Sweep

- Generated: `2026-04-28 02:19:05`
- Basis: imported bilby `odepe_nopolish` pools
- Research analysis mode: `ungated`
- Penalty: `RSS(x) + λ * ||log(x)||²` for scalar, equivalent augmented least-squares residual for residual methods
- Lambda grid: `0`, `1e-04`, `1e-03`, `1e-02`, `1e-01`
- Suite filter: positive-box `1e-4` cases, `amigo2 < odepe_polish`, saved `odepe_polish >= 10%`, ratio `>= 2x`, excluding `cstr`

## Oracle Aggregate vs Each Method's `λ = 0`

| Method | λ | Oracle vs same-method `λ=0` | Median runtime ratio |
| --- | ---: | --- | ---: |
| `Scalar log-space` | `0` | 0 better / 20 tie / 0 worse / 0 unsupported | 1.000x |
| `Scalar log-space` | `1e-04` | 10 better / 6 tie / 4 worse / 0 unsupported | 0.977x |
| `Scalar log-space` | `1e-03` | 11 better / 4 tie / 5 worse / 0 unsupported | 0.987x |
| `Scalar log-space` | `1e-02` | 12 better / 5 tie / 3 worse / 0 unsupported | 0.978x |
| `Scalar log-space` | `1e-01` | 10 better / 4 tie / 6 worse / 0 unsupported | 0.978x |
| `Bounded LeastSquaresOptim LM log-space` | `0` | 0 better / 20 tie / 0 worse / 0 unsupported | 1.000x |
| `Bounded LeastSquaresOptim LM log-space` | `1e-04` | 8 better / 6 tie / 6 worse / 0 unsupported | 1.009x |
| `Bounded LeastSquaresOptim LM log-space` | `1e-03` | 7 better / 6 tie / 7 worse / 0 unsupported | 1.010x |
| `Bounded LeastSquaresOptim LM log-space` | `1e-02` | 9 better / 4 tie / 7 worse / 0 unsupported | 0.987x |
| `Bounded LeastSquaresOptim LM log-space` | `1e-01` | 8 better / 4 tie / 8 worse / 0 unsupported | 0.972x |
| `Bounded FastLevenbergMarquardt log-space` | `0` | 0 better / 20 tie / 0 worse / 0 unsupported | 1.000x |
| `Bounded FastLevenbergMarquardt log-space` | `1e-04` | 10 better / 4 tie / 6 worse / 0 unsupported | 1.025x |
| `Bounded FastLevenbergMarquardt log-space` | `1e-03` | 9 better / 4 tie / 7 worse / 0 unsupported | 1.021x |
| `Bounded FastLevenbergMarquardt log-space` | `1e-02` | 9 better / 4 tie / 7 worse / 0 unsupported | 1.031x |
| `Bounded FastLevenbergMarquardt log-space` | `1e-01` | 8 better / 4 tie / 8 worse / 0 unsupported | 1.028x |

## Oracle Aggregate vs Unregularized Bounded LeastSquaresOptim LM

| Arm | λ | Oracle vs `Bounded LeastSquaresOptim LM log-space, λ=0` |
| --- | ---: | --- |
| `Scalar log-space` | `0` | 5 better / 2 tie / 13 worse / 0 unsupported |
| `Scalar log-space` | `1e-04` | 6 better / 2 tie / 12 worse / 0 unsupported |
| `Scalar log-space` | `1e-03` | 6 better / 2 tie / 12 worse / 0 unsupported |
| `Scalar log-space` | `1e-02` | 5 better / 3 tie / 12 worse / 0 unsupported |
| `Scalar log-space` | `1e-01` | 6 better / 2 tie / 12 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `0` | 0 better / 20 tie / 0 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `1e-04` | 8 better / 6 tie / 6 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `1e-03` | 7 better / 6 tie / 7 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `1e-02` | 9 better / 4 tie / 7 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `1e-01` | 8 better / 4 tie / 8 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `0` | 5 better / 4 tie / 11 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `1e-04` | 7 better / 4 tie / 9 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `1e-03` | 8 better / 4 tie / 8 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `1e-02` | 8 better / 4 tie / 8 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `1e-01` | 7 better / 4 tie / 9 worse / 0 unsupported |

## Per-Case Best λ / Oracle View

| Case | Scalar best λ | Scalar best RMSE | LSO best λ | LSO best RMSE | FastLM best λ | FastLM best RMSE |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `crauste_5_1em4` | `1e-02` | 41.34% | `1e-01` | 30.08% | `1e-01` | 1.84% |
| `seir_6_1em4` | `1e-03` | 0.10% | `1e-03` | 0.07% | `1e-03` | 0.07% |
| `crauste_6_1em4` | `1e-04` | 41.56% | `1e-01` | 28.91% | `0` | 33.63% |
| `daisy_mamil4_1_1em4` | `1e-02` | 14.11% | `0` | 0.63% | `0` | 6.77% |
| `seir_7_1em4` | `1e-04` | 0.33% | `1e-03` | 1.15% | `1e-03` | 0.12% |
| `crauste_1_1em4` | `1e-01` | 230.37% | `1e-01` | 48.01% | `1e-04` | 88.85% |
| `crauste_0_1em4` | `1e-01` | 37.91% | `1e-01` | 6.47% | `1e-01` | 6.39% |
| `hiv_5_1em4` | `1e-03` | 21.79% | `0` | 2.54% | `0` | 4.89% |
| `brusselator_0_1em4` | `N/A` | Inf | `N/A` | Inf | `N/A` | Inf |
| `crauste_7_1em4` | `1e-01` | 37.00% | `0` | 35.66% | `1e-02` | 23.57% |
| `brusselator_4_1em4` | `1e-01` | 44.18% | `0` | 676.89% | `0` | 676.89% |
| `hiv_2_1em4` | `1e-02` | 26.95% | `0` | 0.33% | `0` | 2.79% |
| `hiv_7_1em4` | `1e-01` | 13.38% | `1e-04` | 8.50% | `1e-04` | 10.45% |
| `crauste_4_1em4` | `0` | 21.65% | `1e-01` | 3.09% | `1e-01` | 13.53% |
| `crauste_2_1em4` | `1e-04` | 36.85% | `1e-02` | 60.48% | `1e-01` | 43.87% |
| `brusselator_3_1em4` | `0` | 24.16% | `0` | 226.46% | `0` | 226.46% |
| `seir_3_1em4` | `1e-03` | 0.10% | `1e-03` | 0.18% | `1e-04` | 0.20% |
| `biohydrogenation_4_1em4` | `1e-02` | 15.60% | `0` | 12.37% | `0` | 16.77% |
| `brusselator_7_1em4` | `N/A` | Inf | `N/A` | Inf | `N/A` | Inf |
| `hiv_4_1em4` | `1e-01` | 25.24% | `1e-03` | 11.63% | `1e-03` | 11.63% |

## Cases Improved vs `λ = 0`

- `Scalar log-space`: crauste_5_1em4 (`1e-02`), seir_6_1em4 (`1e-03`), crauste_6_1em4 (`1e-04`), daisy_mamil4_1_1em4 (`1e-02`), seir_7_1em4 (`1e-04`), crauste_1_1em4 (`1e-01`), hiv_5_1em4 (`1e-03`), crauste_7_1em4 (`1e-01`), brusselator_4_1em4 (`1e-01`), hiv_2_1em4 (`1e-02`), hiv_7_1em4 (`1e-01`), crauste_2_1em4 (`1e-04`), seir_3_1em4 (`1e-03`), biohydrogenation_4_1em4 (`1e-02`), hiv_4_1em4 (`1e-01`)
- `Bounded LeastSquaresOptim LM log-space`: crauste_5_1em4 (`1e-01`), seir_6_1em4 (`1e-03`), crauste_6_1em4 (`1e-01`), seir_7_1em4 (`1e-03`), crauste_1_1em4 (`1e-01`), crauste_0_1em4 (`1e-01`), hiv_7_1em4 (`1e-04`), crauste_4_1em4 (`1e-01`), crauste_2_1em4 (`1e-02`), seir_3_1em4 (`1e-03`), hiv_4_1em4 (`1e-03`)
- `Bounded FastLevenbergMarquardt log-space`: crauste_5_1em4 (`1e-01`), seir_6_1em4 (`1e-03`), seir_7_1em4 (`1e-03`), crauste_1_1em4 (`1e-04`), crauste_0_1em4 (`1e-01`), crauste_7_1em4 (`1e-02`), hiv_7_1em4 (`1e-04`), crauste_4_1em4 (`1e-01`), crauste_2_1em4 (`1e-01`), seir_3_1em4 (`1e-04`), hiv_4_1em4 (`1e-03`)
