# Residual-Vector Polish Ablation

- Generated: `2026-04-23 02:07:01`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Research analysis mode: `ungated`
- Residual solver roster: `LevenbergMarquardt()`, `FastShortcutNLLSPolyalg()`, `TrustRegion()`, `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptimJL(:dogleg)`, `FastLevenbergMarquardt.lmsolve!()`
- Benchmark success tolerance: `10%` max relative error

| Case | Imported best RMSE | Analyzed imported best RMSE | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LM log best | residual FastShortcut log best | residual TrustRegion log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim Dogleg log best | residual FastLevenbergMarquardt log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `flexible_arm_0_1em4` | 6.62% | 6.62% | 0.54% | 3.60% | 6.62% | 6.62% | Inf | 6.62% | 6.62% | 6.62% | 6.62% |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LevenbergMarquardt()` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.212x |
| `FastShortcutNLLSPolyalg()` | 0 better / 0 tie / 0 worse / 1 unsupported | 0 better / 0 tie / 0 worse / 1 unsupported | Infx |
| `TrustRegion()` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.180x |
| `LeastSquaresOptimJL(:lm)` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.158x |
| `LeastSquaresOptimJL(:dogleg)` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.102x |
| `FastLevenbergMarquardt.lmsolve!()` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.146x |

## Case Notes

### `flexible_arm_0_1em4`

- Imported raw candidate count: `62`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 6.62%
  - analyzed imported selected benchmark RMSE: 32.64%
  - analyzed imported best benchmark RMSE: 6.62%
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.54%
  - `odepe_nopolish` RMSE: 7.50%
  - `odepe_polish` RMSE: 3.60%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: 32.64%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.58%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `138.755 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 30.93%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 68.75%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `162.655 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 34.94%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 102.30%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `46.567 s`
  - polished representative count: `62`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 38.87%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 141.70%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `34.551 s`
  - polished representative count: `62`
- residual LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastShortcut linear:
  - status: `error`
  - reason: `
If you are using Enzyme by selecting the `AutoEnzyme` object from ADTypes, you may want to try setting the `function_annotation` option as follows:

	AutoEnzyme(; function_annotation=Enzyme.Duplicated)

This hint appears because DifferentiationInterface and Enzyme are both loaded. It does not necessarily imply that Enzyme is being called through DifferentiationInterface.

EnzymeMutabilityException: Function argument passed to autodiff cannot be proven readonly.
If the the function argument cannot contain derivative data, instead call autodiff(Mode, Const(f), ...)
See https://enzyme.mit.edu/index.fcgi/julia/stable/faq/#Activity-of-temporary-storage for more information.
The potentially writing call is   store ptr addrspace(10) %.fca.0.0.1.extract, ptr %.fca.0.0.1.gep, align 8, !dbg !17, !noalias !38, using   %.fca.0.0.1.gep = getelementptr inbounds { [1 x { ptr addrspace(10), ptr addrspace(10), i64, i64, ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), [2 x double], ptr addrspace(10), double, double, ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), i64 }], [1 x i8], [1 x { [1 x { ptr addrspace(10), ptr addrspace(10), i64, i64, ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), [2 x double], ptr addrspace(10), double, double, ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), i64 }], i64 }], ptr addrspace(10), ptr addrspace(10), ptr addrspace(10) }, ptr %"f::NonlinearFunction.innerparm", i64 0, i32 0, i64 0, i32 1, !dbg !17
`
- residual FastShortcut log-positive:
  - status: `error`
  - reason: `
If you are using Enzyme by selecting the `AutoEnzyme` object from ADTypes, you may want to try setting the `function_annotation` option as follows:

	AutoEnzyme(; function_annotation=Enzyme.Duplicated)

This hint appears because DifferentiationInterface and Enzyme are both loaded. It does not necessarily imply that Enzyme is being called through DifferentiationInterface.

EnzymeMutabilityException: Function argument passed to autodiff cannot be proven readonly.
If the the function argument cannot contain derivative data, instead call autodiff(Mode, Const(f), ...)
See https://enzyme.mit.edu/index.fcgi/julia/stable/faq/#Activity-of-temporary-storage for more information.
The potentially writing call is   store ptr addrspace(10) %.fca.0.0.1.extract, ptr %.fca.0.0.1.gep, align 8, !dbg !17, !noalias !38, using   %.fca.0.0.1.gep = getelementptr inbounds { [1 x { ptr addrspace(10), ptr addrspace(10), i64, i64, ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), [2 x double], ptr addrspace(10), double, double, ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), i64 }], [1 x i8], [1 x { [1 x { ptr addrspace(10), ptr addrspace(10), i64, i64, ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), [2 x double], ptr addrspace(10), double, double, ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), ptr addrspace(10), i64 }], i64 }], ptr addrspace(10), ptr addrspace(10), ptr addrspace(10) }, ptr %"f::NonlinearFunction.innerparm", i64 0, i32 0, i64 0, i32 1, !dbg !17
`
- residual FastShortcut linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual FastShortcut log vs scalar log best-in-set benchmark RMSE: `worse`
- residual TrustRegion linear:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `40.005 s`
  - polished representative count: `62`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `29.337 s`
  - polished representative count: `62`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 35.26%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 104.13%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `10.412 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 32.84%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 93.71%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `25.649 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `7.649 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 34.22%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 95.82%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `16.587 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `7.948 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 34.03%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 93.94%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `23.816 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `tie`

