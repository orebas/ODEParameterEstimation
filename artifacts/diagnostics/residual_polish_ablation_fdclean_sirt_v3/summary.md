# Residual-Vector Polish Ablation

- Generated: `2026-04-22 20:45:23`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Residual solver roster: `LevenbergMarquardt()`, `TrustRegion()`, `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptimJL(:dogleg)`, `FastLevenbergMarquardt.lmsolve!()`
- Benchmark success tolerance: `10%` max relative error

| Case | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LM log best | residual TrustRegion log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim Dogleg log best | residual FastLevenbergMarquardt log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 0.01% | 0.01% | 0.01% | 1.22% | 0.01% | 0.01% | 0.01% | 0.01% |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LevenbergMarquardt()` | 0 better / 0 tie / 1 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.445x |
| `TrustRegion()` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 1 tie / 0 worse / 0 unsupported | 0.170x |
| `LeastSquaresOptimJL(:lm)` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 1 tie / 0 worse / 0 unsupported | 0.182x |
| `LeastSquaresOptimJL(:dogleg)` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 1 tie / 0 worse / 0 unsupported | 0.133x |
| `FastLevenbergMarquardt.lmsolve!()` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 1 tie / 0 worse / 0 unsupported | 0.166x |

## Case Notes

### `sirt_treatment_0_1em4`

- Imported raw candidate count: `28`
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.01%
  - `odepe_nopolish` RMSE: 1.22%
  - `odepe_polish` RMSE: 0.01%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `78.374 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `38.756 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `40.634 s`
  - polished representative count: `28`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `17.241 s`
  - polished representative count: `28`
- residual LM linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual LM log vs scalar log best-in-set benchmark RMSE: `worse`
- residual TrustRegion linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `7.846 s`
  - polished representative count: `28`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `6.598 s`
  - polished representative count: `28`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `8.259 s`
  - polished representative count: `28`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `7.066 s`
  - polished representative count: `28`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `6.887 s`
  - polished representative count: `28`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `5.163 s`
  - polished representative count: `28`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `7.386 s`
  - polished representative count: `28`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `6.419 s`
  - polished representative count: `28`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `tie`

