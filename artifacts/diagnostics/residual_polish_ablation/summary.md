# Residual-Vector Polish Ablation

- Generated: `2026-04-22 21:41:43`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Residual solver roster: `LevenbergMarquardt()`, `FastShortcutNLLSPolyalg()`, `TrustRegion()`, `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptimJL(:dogleg)`, `FastLevenbergMarquardtJL()`
- Benchmark success tolerance: `10%` max relative error

| Case | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LM log best | residual FastShortcut log best | residual TrustRegion log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim Dogleg log best | residual FastLevenbergMarquardt log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 0.01% | 0.01% | 0.01% | 1.22% | 0.01% | 0.01% | 0.01% | 0.01% | Inf |
| `flexible_arm_0_1em4` | 0.54% | 3.60% | 30.93% | 32.61% | 0.54% | 32.61% | 0.54% | 0.54% | Inf |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LevenbergMarquardt()` | 0 better / 0 tie / 2 worse / 0 unsupported | 0 better / 0 tie / 2 worse / 0 unsupported | 0.329x |
| `FastShortcutNLLSPolyalg()` | 1 better / 1 tie / 0 worse / 0 unsupported | 1 better / 1 tie / 0 worse / 0 unsupported | 9.901x |
| `TrustRegion()` | 0 better / 1 tie / 1 worse / 0 unsupported | 0 better / 1 tie / 1 worse / 0 unsupported | 0.191x |
| `LeastSquaresOptimJL(:lm)` | 1 better / 1 tie / 0 worse / 0 unsupported | 1 better / 1 tie / 0 worse / 0 unsupported | 0.659x |
| `LeastSquaresOptimJL(:dogleg)` | 1 better / 1 tie / 0 worse / 0 unsupported | 1 better / 1 tie / 0 worse / 0 unsupported | 0.425x |
| `FastLevenbergMarquardtJL()` | 0 better / 0 tie / 0 worse / 2 unsupported | 0 better / 0 tie / 0 worse / 2 unsupported | Infx |

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
  - runtime: `73.145 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `36.709 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `38.785 s`
  - polished representative count: `28`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `15.866 s`
  - polished representative count: `28`
- residual LM linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual LM log vs scalar log best-in-set benchmark RMSE: `worse`
- residual FastShortcut linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `451.933 s`
  - polished representative count: `28`
- residual FastShortcut log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `460.214 s`
  - polished representative count: `28`
- residual FastShortcut linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastShortcut log vs scalar log best-in-set benchmark RMSE: `tie`
- residual TrustRegion linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `9.507 s`
  - polished representative count: `28`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `9.025 s`
  - polished representative count: `28`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `22.713 s`
  - polished representative count: `28`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `20.738 s`
  - polished representative count: `28`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `15.486 s`
  - polished representative count: `28`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `11.929 s`
  - polished representative count: `28`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt linear:
  - status: `error`
  - reason: `StackOverflowError:`
- residual FastLevenbergMarquardt log-positive:
  - status: `error`
  - reason: `StackOverflowError:`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `worse`

### `flexible_arm_0_1em4`

- Imported raw candidate count: `62`
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.54%
  - `odepe_nopolish` RMSE: 7.50%
  - `odepe_polish` RMSE: 3.60%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: 32.64%
  - best-in-set benchmark RMSE: 32.64%
  - selected local relative RMSE: 85.58%
  - best-in-set local relative RMSE: 85.58%
  - runtime: `159.994 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 30.93%
  - best-in-set benchmark RMSE: 30.93%
  - selected local relative RMSE: 68.75%
  - best-in-set local relative RMSE: 68.75%
  - runtime: `219.183 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 34.94%
  - best-in-set benchmark RMSE: 32.61%
  - selected local relative RMSE: 102.30%
  - best-in-set local relative RMSE: 85.12%
  - runtime: `45.679 s`
  - polished representative count: `62`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 38.87%
  - best-in-set benchmark RMSE: 32.61%
  - selected local relative RMSE: 141.70%
  - best-in-set local relative RMSE: 85.12%
  - runtime: `49.615 s`
  - polished representative count: `62`
- residual LM linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LM log vs scalar log best-in-set benchmark RMSE: `worse`
- residual FastShortcut linear:
  - status: `ok`
  - selected benchmark RMSE: 0.54%
  - best-in-set benchmark RMSE: 0.54%
  - selected local relative RMSE: 2.68%
  - best-in-set local relative RMSE: 2.68%
  - runtime: `1.7422e+03 s`
  - polished representative count: `62`
- residual FastShortcut log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.54%
  - best-in-set benchmark RMSE: 0.54%
  - selected local relative RMSE: 2.68%
  - best-in-set local relative RMSE: 2.68%
  - runtime: `1.5924e+03 s`
  - polished representative count: `62`
- residual FastShortcut linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual FastShortcut log vs scalar log best-in-set benchmark RMSE: `better`
- residual TrustRegion linear:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 32.61%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 85.12%
  - runtime: `20.138 s`
  - polished representative count: `62`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 32.61%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 85.12%
  - runtime: `29.696 s`
  - polished representative count: `62`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.54%
  - best-in-set benchmark RMSE: 0.54%
  - selected local relative RMSE: 2.68%
  - best-in-set local relative RMSE: 2.68%
  - runtime: `135.292 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.54%
  - best-in-set benchmark RMSE: 0.54%
  - selected local relative RMSE: 2.68%
  - best-in-set local relative RMSE: 2.68%
  - runtime: `165.180 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 0.54%
  - best-in-set benchmark RMSE: 0.54%
  - selected local relative RMSE: 2.68%
  - best-in-set local relative RMSE: 2.68%
  - runtime: `103.802 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.54%
  - best-in-set benchmark RMSE: 0.54%
  - selected local relative RMSE: 2.68%
  - best-in-set local relative RMSE: 2.68%
  - runtime: `114.888 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt linear:
  - status: `error`
  - reason: `StackOverflowError:`
- residual FastLevenbergMarquardt log-positive:
  - status: `error`
  - reason: `StackOverflowError:`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `worse`

