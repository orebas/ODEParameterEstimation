# Residual-Vector Polish Ablation

- Generated: `2026-04-23 00:43:41`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Residual solver roster: `LevenbergMarquardt()`, `FastShortcutNLLSPolyalg()`, `TrustRegion()`, `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptimJL(:dogleg)`, `FastLevenbergMarquardt.lmsolve!()`
- Benchmark success tolerance: `10%` max relative error

| Case | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LM log best | residual FastShortcut log best | residual TrustRegion log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim Dogleg log best | residual FastLevenbergMarquardt log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `brusselator_5_1em4` | 0.03% | 0.05% | Inf | 0.24% | 0.24% | 0.24% | 0.24% | 0.24% | 0.24% |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LevenbergMarquardt()` | 1 better / 0 tie / 0 worse / 0 unsupported | 1 better / 0 tie / 0 worse / 0 unsupported | 4.824x |
| `FastShortcutNLLSPolyalg()` | 1 better / 0 tie / 0 worse / 0 unsupported | 1 better / 0 tie / 0 worse / 0 unsupported | 11.557x |
| `TrustRegion()` | 1 better / 0 tie / 0 worse / 0 unsupported | 1 better / 0 tie / 0 worse / 0 unsupported | 2.579x |
| `LeastSquaresOptimJL(:lm)` | 1 better / 0 tie / 0 worse / 0 unsupported | 1 better / 0 tie / 0 worse / 0 unsupported | 0.929x |
| `LeastSquaresOptimJL(:dogleg)` | 1 better / 0 tie / 0 worse / 0 unsupported | 1 better / 0 tie / 0 worse / 0 unsupported | 0.908x |
| `FastLevenbergMarquardt.lmsolve!()` | 1 better / 0 tie / 0 worse / 0 unsupported | 1 better / 0 tie / 0 worse / 0 unsupported | 0.735x |

## Case Notes

### `brusselator_5_1em4`

- Imported raw candidate count: `123`
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.03%
  - `odepe_nopolish` RMSE: 0.34%
  - `odepe_polish` RMSE: 0.05%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: Inf
  - best-in-set benchmark RMSE: Inf
  - selected local relative RMSE: Inf
  - best-in-set local relative RMSE: Inf
  - runtime: `58.731 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: Inf
  - best-in-set benchmark RMSE: Inf
  - selected local relative RMSE: Inf
  - best-in-set local relative RMSE: Inf
  - runtime: `2.163 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `31.066 s`
  - polished representative count: `42`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `10.437 s`
  - polished representative count: `42`
- residual LM linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LM log vs scalar log best-in-set benchmark RMSE: `better`
- residual FastShortcut linear:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `95.399 s`
  - polished representative count: `42`
- residual FastShortcut log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `25.004 s`
  - polished representative count: `42`
- residual FastShortcut linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual FastShortcut log vs scalar log best-in-set benchmark RMSE: `better`
- residual TrustRegion linear:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `6.414 s`
  - polished representative count: `42`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `5.580 s`
  - polished representative count: `42`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `4.395 s`
  - polished representative count: `42`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `2.010 s`
  - polished representative count: `42`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `2.934 s`
  - polished representative count: `42`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `1.965 s`
  - polished representative count: `42`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `3.611 s`
  - polished representative count: `42`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.24%
  - best-in-set benchmark RMSE: 0.24%
  - selected local relative RMSE: 0.80%
  - best-in-set local relative RMSE: 0.80%
  - runtime: `1.589 s`
  - polished representative count: `42`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `better`

