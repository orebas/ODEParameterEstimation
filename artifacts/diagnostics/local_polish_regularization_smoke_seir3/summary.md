# Log-Space L2 Regularization Sweep

- Generated: `2026-04-26 01:53:30`
- Basis: imported bilby `odepe_nopolish` pools
- Research analysis mode: `ungated`
- Penalty: `RSS(x) + λ * ||log(x)||²` for scalar, equivalent augmented least-squares residual for residual methods
- Lambda grid: `0`, `1e-03`
- Suite filter: positive-box `1e-4` cases, `amigo2 < odepe_polish`, saved `odepe_polish >= 10%`, ratio `>= 2x`, excluding `cstr`

## Oracle Aggregate vs Each Method's `λ = 0`

| Method | λ | Oracle vs same-method `λ=0` | Median runtime ratio |
| --- | ---: | --- | ---: |
| `Scalar log-space` | `0` | 0 better / 1 tie / 0 worse / 0 unsupported | 1.000x |
| `Scalar log-space` | `1e-03` | 0 better / 0 tie / 1 worse / 0 unsupported | 1.144x |
| `Bounded LeastSquaresOptim LM log-space` | `0` | 0 better / 1 tie / 0 worse / 0 unsupported | 1.000x |
| `Bounded LeastSquaresOptim LM log-space` | `1e-03` | 1 better / 0 tie / 0 worse / 0 unsupported | 0.908x |
| `Bounded FastLevenbergMarquardt log-space` | `0` | 0 better / 1 tie / 0 worse / 0 unsupported | 1.000x |
| `Bounded FastLevenbergMarquardt log-space` | `1e-03` | 1 better / 0 tie / 0 worse / 0 unsupported | 1.079x |

## Oracle Aggregate vs Unregularized Bounded LeastSquaresOptim LM

| Arm | λ | Oracle vs `Bounded LeastSquaresOptim LM log-space, λ=0` |
| --- | ---: | --- |
| `Scalar log-space` | `0` | 1 better / 0 tie / 0 worse / 0 unsupported |
| `Scalar log-space` | `1e-03` | 1 better / 0 tie / 0 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `0` | 0 better / 1 tie / 0 worse / 0 unsupported |
| `Bounded LeastSquaresOptim LM log-space` | `1e-03` | 1 better / 0 tie / 0 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `0` | 1 better / 0 tie / 0 worse / 0 unsupported |
| `Bounded FastLevenbergMarquardt log-space` | `1e-03` | 1 better / 0 tie / 0 worse / 0 unsupported |

## Per-Case Best λ / Oracle View

| Case | Scalar best λ | Scalar best RMSE | LSO best λ | LSO best RMSE | FastLM best λ | FastLM best RMSE |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `seir_3_1em4` | `0` | 1.04% | `1e-03` | 0.18% | `1e-03` | 0.90% |

## Cases Improved vs `λ = 0`

- `Scalar log-space`: none
- `Bounded LeastSquaresOptim LM log-space`: seir_3_1em4 (`1e-03`)
- `Bounded FastLevenbergMarquardt log-space`: seir_3_1em4 (`1e-03`)
