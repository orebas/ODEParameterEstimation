# Residual-Vector Polish Ablation

- Generated: `2026-04-23 04:52:21`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Research analysis mode: `ungated`
- Residual solver roster: `LevenbergMarquardt()`, `FastShortcutNLLSPolyalg()`, `TrustRegion()`, `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptimJL(:dogleg)`, `FastLevenbergMarquardt.lmsolve!()`
- Benchmark success tolerance: `10%` max relative error

| Case | Imported best RMSE | Analyzed imported best RMSE | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LM log best | residual FastShortcut log best | residual TrustRegion log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim Dogleg log best | residual FastLevenbergMarquardt log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 1.22% | 1.22% | 0.01% | 0.01% | 0.01% | 1.22% | Inf | 0.01% | 0.01% | 0.01% | 0.01% |
| `crauste_7_1em4` | 6445.99% | 18751.98% | 19.62% | 167.02% | 322.18% | 411.66% | Inf | 394.46% | 411.66% | 411.66% | 411.66% |
| `fitzhugh_nagumo_2_1em4` | 6.11% | 6.11% | 1.31% | 3.20% | 1.31% | 6.11% | Inf | 1.31% | 1.31% | 1.31% | 1.31% |
| `seir_4_1em4` | 34.09% | 34.09% | 0.05% | 0.63% | 0.05% | 34.09% | Inf | 34.09% | 34.09% | 22.00% | 0.05% |
| `flexible_arm_0_1em4` | 6.62% | 6.62% | 0.54% | 3.60% | 6.62% | 6.62% | Inf | 6.62% | 6.62% | 6.62% | 6.62% |
| `daisy_mamil3_7_1em4` | 3.37% | 3.37% | 0.00% | 0.40% | 0.00% | 3.37% | Inf | 0.00% | 0.00% | 0.00% | 0.00% |
| `daisy_mamil4_6_1em4` | 15.98% | 15.98% | 0.33% | 0.31% | 6.48% | 13.85% | Inf | 0.33% | 13.85% | 0.33% | 1.72% |
| `brusselator_5_1em4` | 0.02% | Inf | 0.03% | 0.05% | Inf | 0.05% | 0.05% | 0.05% | 0.05% | 0.05% | 0.05% |
| `forced_lotka_volterra_0_1em4` | 4.10% | 4.10% | 0.00% | 0.00% | 0.00% | 4.10% | Inf | 0.00% | 0.00% | 0.00% | 0.00% |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LevenbergMarquardt()` | 1 better / 1 tie / 7 worse / 0 unsupported | 1 better / 0 tie / 8 worse / 0 unsupported | 0.488x |
| `FastShortcutNLLSPolyalg()` | 1 better / 0 tie / 0 worse / 8 unsupported | 1 better / 0 tie / 0 worse / 8 unsupported | 11.216x |
| `TrustRegion()` | 2 better / 5 tie / 2 worse / 0 unsupported | 2 better / 4 tie / 3 worse / 0 unsupported | 0.548x |
| `LeastSquaresOptimJL(:lm)` | 1 better / 5 tie / 3 worse / 0 unsupported | 1 better / 4 tie / 4 worse / 0 unsupported | 0.433x |
| `LeastSquaresOptimJL(:dogleg)` | 2 better / 5 tie / 2 worse / 0 unsupported | 1 better / 4 tie / 4 worse / 0 unsupported | 0.560x |
| `FastLevenbergMarquardt.lmsolve!()` | 2 better / 6 tie / 1 worse / 0 unsupported | 2 better / 5 tie / 2 worse / 0 unsupported | 0.517x |

## Case Notes

### `sirt_treatment_0_1em4`

- Imported raw candidate count: `28`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 1.22%
  - analyzed imported selected benchmark RMSE: 1.22%
  - analyzed imported best benchmark RMSE: 1.22%
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
  - runtime: `66.463 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `34.062 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `35.499 s`
  - polished representative count: `28`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `15.389 s`
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
  - runtime: `7.409 s`
  - polished representative count: `28`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `5.857 s`
  - polished representative count: `28`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `7.207 s`
  - polished representative count: `28`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `6.441 s`
  - polished representative count: `28`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `6.421 s`
  - polished representative count: `28`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `4.816 s`
  - polished representative count: `28`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `5.975 s`
  - polished representative count: `28`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `5.968 s`
  - polished representative count: `28`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `tie`

### `crauste_7_1em4`

- Imported raw candidate count: `20`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 6445.99%
  - analyzed imported selected benchmark RMSE: 163909.75%
  - analyzed imported best benchmark RMSE: 18751.98%
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 19.62%
  - `odepe_nopolish` RMSE: 6445.99%
  - `odepe_polish` RMSE: 167.02%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: 198638.81%
  - best-in-set benchmark RMSE: 6445.99%
  - selected local relative RMSE: 554724.09%
  - best-in-set local relative RMSE: 18726.84%
  - runtime: `291.847 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1739.10%
  - best-in-set benchmark RMSE: 322.18%
  - selected local relative RMSE: 2586.33%
  - best-in-set local relative RMSE: 996.34%
  - runtime: `280.717 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 463991.90%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 624462.69%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `77.724 s`
  - polished representative count: `20`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 163909.75%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 220465.73%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `13.977 s`
  - polished representative count: `20`
- residual LM linear vs scalar linear best-in-set benchmark RMSE: `better`
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
  - selected benchmark RMSE: 163909.75%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 220465.73%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `80.245 s`
  - polished representative count: `20`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 486.84%
  - best-in-set benchmark RMSE: 394.46%
  - selected local relative RMSE: 1649.32%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `28.293 s`
  - polished representative count: `20`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 5775.27%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 21084.57%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `207.305 s`
  - polished representative count: `20`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 106274.32%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 393570.34%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `57.274 s`
  - polished representative count: `20`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 163909.75%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 220465.73%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `94.418 s`
  - polished representative count: `20`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 163909.75%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 220465.73%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `33.174 s`
  - polished representative count: `20`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 73762.77%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 206033.81%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `98.885 s`
  - polished representative count: `20`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1209.35%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 5251.97%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `49.423 s`
  - polished representative count: `20`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `worse`

### `fitzhugh_nagumo_2_1em4`

- Imported raw candidate count: `186`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 6.11%
  - analyzed imported selected benchmark RMSE: 6.94%
  - analyzed imported best benchmark RMSE: 6.11%
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 1.31%
  - `odepe_nopolish` RMSE: 6.94%
  - `odepe_polish` RMSE: 3.20%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `114.119 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `23.915 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 6.94%
  - best-in-set benchmark RMSE: 6.11%
  - selected local relative RMSE: 7.83%
  - best-in-set local relative RMSE: 7.08%
  - runtime: `74.396 s`
  - polished representative count: `184`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 6.94%
  - best-in-set benchmark RMSE: 6.11%
  - selected local relative RMSE: 7.83%
  - best-in-set local relative RMSE: 7.08%
  - runtime: `60.900 s`
  - polished representative count: `184`
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
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `26.717 s`
  - polished representative count: `184`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `27.545 s`
  - polished representative count: `184`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `19.320 s`
  - polished representative count: `184`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `39.504 s`
  - polished representative count: `184`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `24.253 s`
  - polished representative count: `184`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `37.969 s`
  - polished representative count: `184`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `21.551 s`
  - polished representative count: `184`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.31%
  - best-in-set benchmark RMSE: 1.31%
  - selected local relative RMSE: 1.48%
  - best-in-set local relative RMSE: 1.48%
  - runtime: `26.634 s`
  - polished representative count: `184`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `tie`

### `seir_4_1em4`

- Imported raw candidate count: `114`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 34.09%
  - analyzed imported selected benchmark RMSE: 110.49%
  - analyzed imported best benchmark RMSE: 34.09%
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.05%
  - `odepe_nopolish` RMSE: 34.09%
  - `odepe_polish` RMSE: 0.63%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `80.222 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `49.974 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 5763.67%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 16327.56%
  - best-in-set local relative RMSE: 67.80%
  - runtime: `71.540 s`
  - polished representative count: `114`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 109.53%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 162.25%
  - best-in-set local relative RMSE: 67.80%
  - runtime: `24.369 s`
  - polished representative count: `114`
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
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `60.302 s`
  - polished representative count: `114`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 109.94%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 162.87%
  - best-in-set local relative RMSE: 67.80%
  - runtime: `35.620 s`
  - polished representative count: `114`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `72.521 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 3927675226114354.50%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 21462706153630360.00%
  - best-in-set local relative RMSE: 68.27%
  - runtime: `57.288 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `46.783 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 22.00%
  - best-in-set benchmark RMSE: 22.00%
  - selected local relative RMSE: 47.44%
  - best-in-set local relative RMSE: 47.44%
  - runtime: `40.561 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `47.029 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `34.668 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `tie`

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
  - runtime: `132.768 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 30.93%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 68.75%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `170.169 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 34.94%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 102.30%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `27.516 s`
  - polished representative count: `62`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 38.87%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 141.70%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `36.759 s`
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
  - runtime: `32.726 s`
  - polished representative count: `62`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `33.133 s`
  - polished representative count: `62`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 35.26%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 104.13%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `9.555 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 32.84%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 93.71%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `28.330 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `7.788 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 34.22%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 95.82%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `18.159 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `7.509 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 34.03%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 93.94%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `25.570 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `tie`

### `daisy_mamil3_7_1em4`

- Imported raw candidate count: `89`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 3.37%
  - analyzed imported selected benchmark RMSE: 4.11%
  - analyzed imported best benchmark RMSE: 3.37%
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.00%
  - `odepe_nopolish` RMSE: 4.11%
  - `odepe_polish` RMSE: 0.40%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `248.552 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `40.358 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 4.11%
  - best-in-set benchmark RMSE: 3.37%
  - selected local relative RMSE: 5.73%
  - best-in-set local relative RMSE: 5.73%
  - runtime: `67.504 s`
  - polished representative count: `89`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 4.11%
  - best-in-set benchmark RMSE: 3.37%
  - selected local relative RMSE: 5.73%
  - best-in-set local relative RMSE: 5.73%
  - runtime: `52.414 s`
  - polished representative count: `89`
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
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `25.853 s`
  - polished representative count: `89`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `22.131 s`
  - polished representative count: `89`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `19.018 s`
  - polished representative count: `89`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `17.334 s`
  - polished representative count: `89`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `36.275 s`
  - polished representative count: `89`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `22.605 s`
  - polished representative count: `89`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `17.096 s`
  - polished representative count: `89`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `20.876 s`
  - polished representative count: `89`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `tie`

### `daisy_mamil4_6_1em4`

- Imported raw candidate count: `119`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 15.98%
  - analyzed imported selected benchmark RMSE: 66.08%
  - analyzed imported best benchmark RMSE: 15.98%
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.33%
  - `odepe_nopolish` RMSE: 33.82%
  - `odepe_polish` RMSE: 0.31%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `318.361 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 23.65%
  - best-in-set benchmark RMSE: 6.48%
  - selected local relative RMSE: 48.11%
  - best-in-set local relative RMSE: 13.60%
  - runtime: `222.976 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 66.08%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 148.28%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `113.106 s`
  - polished representative count: `119`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 27.86%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 59.08%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `71.096 s`
  - polished representative count: `119`
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
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `77.973 s`
  - polished representative count: `119`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `55.159 s`
  - polished representative count: `119`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `116.722 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 25.02%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 71.61%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `96.503 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `74.674 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `51.644 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.02%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.04%
  - runtime: `78.515 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 24.17%
  - best-in-set benchmark RMSE: 1.72%
  - selected local relative RMSE: 49.82%
  - best-in-set local relative RMSE: 4.14%
  - runtime: `38.858 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `better`

### `brusselator_5_1em4`

- Imported raw candidate count: `123`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 0.02%
  - analyzed imported selected benchmark RMSE: Inf
  - analyzed imported best benchmark RMSE: Inf
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
  - runtime: `53.166 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: Inf
  - best-in-set benchmark RMSE: Inf
  - selected local relative RMSE: Inf
  - best-in-set local relative RMSE: Inf
  - runtime: `2.182 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `30.240 s`
  - polished representative count: `42`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `10.948 s`
  - polished representative count: `42`
- residual LM linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LM log vs scalar log best-in-set benchmark RMSE: `better`
- residual FastShortcut linear:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `27.802 s`
  - polished representative count: `42`
- residual FastShortcut log-positive:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `24.480 s`
  - polished representative count: `42`
- residual FastShortcut linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual FastShortcut log vs scalar log best-in-set benchmark RMSE: `better`
- residual TrustRegion linear:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `5.474 s`
  - polished representative count: `42`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `5.903 s`
  - polished representative count: `42`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `2.560 s`
  - polished representative count: `42`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `2.134 s`
  - polished representative count: `42`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `2.547 s`
  - polished representative count: `42`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `2.025 s`
  - polished representative count: `42`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `2.360 s`
  - polished representative count: `42`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 2.32%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 6.23%
  - best-in-set local relative RMSE: 0.09%
  - runtime: `1.694 s`
  - polished representative count: `42`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `better`

### `forced_lotka_volterra_0_1em4`

- Imported raw candidate count: `70`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 4.10%
  - analyzed imported selected benchmark RMSE: 4.10%
  - analyzed imported best benchmark RMSE: 4.10%
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.00%
  - `odepe_nopolish` RMSE: 5.27%
  - `odepe_polish` RMSE: 0.00%
- scalar linear:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `88.467 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `10.739 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 4.10%
  - best-in-set benchmark RMSE: 4.10%
  - selected local relative RMSE: 11.00%
  - best-in-set local relative RMSE: 10.86%
  - runtime: `43.714 s`
  - polished representative count: `52`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 4.10%
  - best-in-set benchmark RMSE: 4.10%
  - selected local relative RMSE: 11.00%
  - best-in-set local relative RMSE: 10.86%
  - runtime: `27.501 s`
  - polished representative count: `52`
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
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `12.104 s`
  - polished representative count: `52`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `11.946 s`
  - polished representative count: `52`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `7.308 s`
  - polished representative count: `52`
- residual LeastSquaresOptim LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `10.268 s`
  - polished representative count: `52`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg linear:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `8.390 s`
  - polished representative count: `52`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `14.899 s`
  - polished representative count: `52`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt linear:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `5.884 s`
  - polished representative count: `52`
- residual FastLevenbergMarquardt log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.00%
  - best-in-set benchmark RMSE: 0.00%
  - selected local relative RMSE: 0.00%
  - best-in-set local relative RMSE: 0.00%
  - runtime: `10.589 s`
  - polished representative count: `52`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `tie`

