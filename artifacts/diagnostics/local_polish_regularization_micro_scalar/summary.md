# Log-Space L2 Regularization Sweep

- Generated: `2026-04-26 01:44:41`
- Basis: imported bilby `odepe_nopolish` pools
- Research analysis mode: `ungated`
- Penalty: `RSS(x) + λ * ||log(x)||²` for scalar, equivalent augmented least-squares residual for residual methods
- Lambda grid: `0`
- Suite filter: positive-box `1e-4` cases, `amigo2 < odepe_polish`, saved `odepe_polish >= 10%`, ratio `>= 2x`, excluding `cstr`

## Oracle Aggregate vs Each Method's `λ = 0`

| Method | λ | Oracle vs same-method `λ=0` | Median runtime ratio |
| --- | ---: | --- | ---: |
| `Scalar log-space` | `0` | 0 better / 1 tie / 0 worse / 0 unsupported | 1.000x |

## Oracle Aggregate vs Unregularized Bounded LeastSquaresOptim LM

| Arm | λ | Oracle vs `Bounded LeastSquaresOptim LM log-space, λ=0` |
| --- | ---: | --- |
| `Scalar log-space` | `0` | 0 better / 0 tie / 0 worse / 1 unsupported |

## Per-Case Best λ / Oracle View

| Case | Scalar best λ | Scalar best RMSE | LSO best λ | LSO best RMSE | FastLM best λ | FastLM best RMSE |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `seir_3_1em4` | `0` | 1.04% | `N/A` | Inf | `N/A` | Inf |

## Cases Improved vs `λ = 0`

- `Scalar log-space`: none
