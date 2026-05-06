# Residual-Vector Polish Ablation

- Generated: `2026-04-22 20:42:45`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Residual solver roster: `LevenbergMarquardt()`, `FastShortcutNLLSPolyalg()`, `TrustRegion()`, `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptimJL(:dogleg)`, `FastLevenbergMarquardt.lmsolve!()`
- Benchmark success tolerance: `10%` max relative error

| Case | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LM log best | residual FastShortcut log best | residual TrustRegion log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim Dogleg log best | residual FastLevenbergMarquardt log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 0.01% | 0.01% | 0.01% | 1.22% | Inf | 0.01% | 0.01% | 0.01% | 0.01% |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LevenbergMarquardt()` | 0 better / 0 tie / 1 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.436x |
| `FastShortcutNLLSPolyalg()` | 0 better / 0 tie / 0 worse / 1 unsupported | 0 better / 0 tie / 0 worse / 1 unsupported | Infx |
| `TrustRegion()` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 1 tie / 0 worse / 0 unsupported | 0.186x |
| `LeastSquaresOptimJL(:lm)` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 1 tie / 0 worse / 0 unsupported | 0.222x |
| `LeastSquaresOptimJL(:dogleg)` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 1 tie / 0 worse / 0 unsupported | 0.161x |
| `FastLevenbergMarquardt.lmsolve!()` | 0 better / 1 tie / 0 worse / 0 unsupported | 0 better / 1 tie / 0 worse / 0 unsupported | 0.201x |

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
  - runtime: `85.285 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `41.551 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `43.486 s`
  - polished representative count: `28`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `18.123 s`
  - polished representative count: `28`
- residual LM linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual LM log vs scalar log best-in-set benchmark RMSE: `worse`
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
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `9.615 s`
  - polished representative count: `28`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `7.728 s`
  - polished representative count: `28`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `10.528 s`
  - polished representative count: `28`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `9.206 s`
  - polished representative count: `28`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `9.094 s`
  - polished representative count: `28`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `6.700 s`
  - polished representative count: `28`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `7.981 s`
  - polished representative count: `28`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `8.369 s`
  - polished representative count: `28`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `tie`

