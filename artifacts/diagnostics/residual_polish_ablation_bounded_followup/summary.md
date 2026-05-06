# Residual-Vector Polish Ablation

- Generated: `2026-04-23 13:18:36`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Research analysis mode: `ungated`
- Residual solver roster: `LevenbergMarquardt()`, `FastShortcutNLLSPolyalg()`, `TrustRegion()`, `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptim.optimize!(LevenbergMarquardt(); lower/upper)`, `LeastSquaresOptimJL(:dogleg)`, `LeastSquaresOptim.optimize!(Dogleg(); lower/upper)`, `FastLevenbergMarquardt.lmsolve!()`, `FastLevenbergMarquardt.lmsolve!() with lb/ub`
- Benchmark success tolerance: `10%` max relative error

| Case | Imported best RMSE | Analyzed imported best RMSE | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LM log best | residual FastShortcut log best | residual TrustRegion log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim LM bounded log best | residual LeastSquaresOptim Dogleg log best | residual LeastSquaresOptim Dogleg bounded log best | residual FastLevenbergMarquardt log best | residual FastLevenbergMarquardt bounded log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `crauste_7_1em4` | 6445.99% | 18751.98% | 19.62% | 167.02% | 394.21% | 411.66% | Inf | 394.46% | 411.66% | 35.66% | 411.66% | 396.96% | 411.66% | 222.38% |
| `daisy_mamil4_6_1em4` | 15.98% | 15.98% | 0.33% | 0.31% | 6.48% | 13.85% | Inf | 0.33% | 13.85% | 0.33% | 0.33% | 0.33% | 1.72% | 1.06% |
| `flexible_arm_0_1em4` | 6.62% | 6.62% | 0.54% | 3.60% | 6.62% | 6.62% | Inf | 6.62% | 6.62% | 6.62% | 6.62% | 6.62% | 6.62% | 6.62% |
| `seir_4_1em4` | 34.09% | 34.09% | 0.05% | 0.63% | 0.05% | 34.09% | Inf | 34.09% | 34.09% | 9.24% | 22.00% | 24.87% | 0.05% | 0.05% |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LevenbergMarquardt()` | 0 better / 1 tie / 3 worse / 0 unsupported | 0 better / 0 tie / 4 worse / 0 unsupported | 0.265x |
| `FastShortcutNLLSPolyalg()` | 0 better / 0 tie / 0 worse / 4 unsupported | 0 better / 0 tie / 0 worse / 4 unsupported | Infx |
| `TrustRegion()` | 1 better / 1 tie / 2 worse / 0 unsupported | 1 better / 0 tie / 3 worse / 0 unsupported | 0.231x |
| `LeastSquaresOptimJL(:lm)` | 0 better / 1 tie / 3 worse / 0 unsupported | 0 better / 0 tie / 4 worse / 0 unsupported | 0.307x |
| `LeastSquaresOptim.optimize!(LevenbergMarquardt(); lower/upper)` | 2 better / 1 tie / 1 worse / 0 unsupported | 2 better / 0 tie / 2 worse / 0 unsupported | 0.366x |
| `LeastSquaresOptimJL(:dogleg)` | 1 better / 1 tie / 2 worse / 0 unsupported | 0 better / 0 tie / 4 worse / 0 unsupported | 0.170x |
| `LeastSquaresOptim.optimize!(Dogleg(); lower/upper)` | 1 better / 1 tie / 2 worse / 0 unsupported | 1 better / 0 tie / 3 worse / 0 unsupported | 0.218x |
| `FastLevenbergMarquardt.lmsolve!()` | 1 better / 2 tie / 1 worse / 0 unsupported | 0 better / 1 tie / 3 worse / 0 unsupported | 0.174x |
| `FastLevenbergMarquardt.lmsolve!() with lb/ub` | 2 better / 2 tie / 0 worse / 0 unsupported | 2 better / 1 tie / 1 worse / 0 unsupported | 0.242x |

## Case Notes

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
- scalar original-space:
  - status: `ok`
  - selected benchmark RMSE: 198638.81%
  - best-in-set benchmark RMSE: 6445.99%
  - selected local relative RMSE: 554724.09%
  - best-in-set local relative RMSE: 18726.84%
  - runtime: `297.555 s`
- scalar log-space:
  - status: `ok`
  - selected benchmark RMSE: 1174.81%
  - best-in-set benchmark RMSE: 394.21%
  - selected local relative RMSE: 5182.00%
  - best-in-set local relative RMSE: 1149.50%
  - runtime: `285.037 s`
- residual LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 463991.90%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 624462.69%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `125.847 s`
  - polished representative count: `20`
- residual LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 163909.75%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 220465.73%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `18.232 s`
  - polished representative count: `20`
- residual LM original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual LM log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual FastShortcut original-space:
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
- residual FastShortcut log-space:
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
- residual FastShortcut original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual FastShortcut log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual TrustRegion original-space:
  - status: `ok`
  - selected benchmark RMSE: 163909.75%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 220465.73%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `89.954 s`
  - polished representative count: `20`
- residual TrustRegion log-space:
  - status: `ok`
  - selected benchmark RMSE: 486.84%
  - best-in-set benchmark RMSE: 394.46%
  - selected local relative RMSE: 1649.32%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `32.716 s`
  - polished representative count: `20`
- residual TrustRegion original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual TrustRegion log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 5775.27%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 21084.57%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `220.842 s`
  - polished representative count: `20`
- residual LeastSquaresOptim LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 106274.32%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 393570.34%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `61.721 s`
  - polished representative count: `20`
- residual LeastSquaresOptim LM original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 264.94%
  - best-in-set benchmark RMSE: 264.94%
  - selected local relative RMSE: 1061.44%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `95.624 s`
  - polished representative count: `20`
- residual LeastSquaresOptim LM bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 244.57%
  - best-in-set benchmark RMSE: 35.66%
  - selected local relative RMSE: 1054.20%
  - best-in-set local relative RMSE: 68.07%
  - runtime: `84.765 s`
  - polished representative count: `20`
- residual LeastSquaresOptim LM bounded original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg original-space:
  - status: `ok`
  - selected benchmark RMSE: 163909.75%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 220465.73%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `102.323 s`
  - polished representative count: `20`
- residual LeastSquaresOptim Dogleg log-space:
  - status: `ok`
  - selected benchmark RMSE: 163909.75%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 220465.73%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `35.960 s`
  - polished representative count: `20`
- residual LeastSquaresOptim Dogleg original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 427.41%
  - best-in-set benchmark RMSE: 276.05%
  - selected local relative RMSE: 1314.97%
  - best-in-set local relative RMSE: 598.21%
  - runtime: `51.600 s`
  - polished representative count: `20`
- residual LeastSquaresOptim Dogleg bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 488.20%
  - best-in-set benchmark RMSE: 396.96%
  - selected local relative RMSE: 1626.18%
  - best-in-set local relative RMSE: 756.92%
  - runtime: `40.606 s`
  - polished representative count: `20`
- residual LeastSquaresOptim Dogleg bounded original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg bounded log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt original-space:
  - status: `ok`
  - selected benchmark RMSE: 73762.77%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 206033.81%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `111.239 s`
  - polished representative count: `20`
- residual FastLevenbergMarquardt log-space:
  - status: `ok`
  - selected benchmark RMSE: 1209.35%
  - best-in-set benchmark RMSE: 411.66%
  - selected local relative RMSE: 5251.97%
  - best-in-set local relative RMSE: 871.26%
  - runtime: `53.550 s`
  - polished representative count: `20`
- residual FastLevenbergMarquardt original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 377.96%
  - best-in-set benchmark RMSE: 212.30%
  - selected local relative RMSE: 1253.69%
  - best-in-set local relative RMSE: 561.67%
  - runtime: `56.020 s`
  - polished representative count: `20`
- residual FastLevenbergMarquardt bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 238.55%
  - best-in-set benchmark RMSE: 222.38%
  - selected local relative RMSE: 779.95%
  - best-in-set local relative RMSE: 643.44%
  - runtime: `49.109 s`
  - polished representative count: `20`
- residual FastLevenbergMarquardt bounded original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`

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
- scalar original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `374.650 s`
- scalar log-space:
  - status: `ok`
  - selected benchmark RMSE: 23.65%
  - best-in-set benchmark RMSE: 6.48%
  - selected local relative RMSE: 48.11%
  - best-in-set local relative RMSE: 13.60%
  - runtime: `233.338 s`
- residual LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 66.08%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 148.28%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `111.063 s`
  - polished representative count: `119`
- residual LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 27.86%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 59.08%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `70.096 s`
  - polished representative count: `119`
- residual LM original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LM log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual FastShortcut original-space:
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
- residual FastShortcut log-space:
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
- residual FastShortcut original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual FastShortcut log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual TrustRegion original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `76.951 s`
  - polished representative count: `119`
- residual TrustRegion log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `55.254 s`
  - polished representative count: `119`
- residual TrustRegion original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual TrustRegion log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `125.334 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.02%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 71.61%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `92.673 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `99.583 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `101.326 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM bounded original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `74.200 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `49.722 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `60.256 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `68.546 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg bounded original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt original-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.02%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.04%
  - runtime: `76.436 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt log-space:
  - status: `ok`
  - selected benchmark RMSE: 24.17%
  - best-in-set benchmark RMSE: 1.72%
  - selected local relative RMSE: 49.82%
  - best-in-set local relative RMSE: 4.14%
  - runtime: `37.464 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.02%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.04%
  - runtime: `77.417 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 1.06%
  - best-in-set benchmark RMSE: 1.06%
  - selected local relative RMSE: 2.51%
  - best-in-set local relative RMSE: 2.51%
  - runtime: `72.684 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt bounded original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`

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
- scalar original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.64%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.58%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `125.193 s`
- scalar log-space:
  - status: `ok`
  - selected benchmark RMSE: 30.93%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 68.75%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `158.787 s`
- residual LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 34.94%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 102.30%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `27.403 s`
  - polished representative count: `62`
- residual LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 38.87%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 141.70%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `36.407 s`
  - polished representative count: `62`
- residual LM original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LM log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual FastShortcut original-space:
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
- residual FastShortcut log-space:
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
- residual FastShortcut original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual FastShortcut log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual TrustRegion original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `24.706 s`
  - polished representative count: `62`
- residual TrustRegion log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `35.864 s`
  - polished representative count: `62`
- residual TrustRegion original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual TrustRegion log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 35.26%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 104.13%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `9.365 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.84%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 93.71%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `27.735 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `7.409 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.23%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 86.99%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `23.949 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM bounded original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM bounded log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `7.709 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg log-space:
  - status: `ok`
  - selected benchmark RMSE: 34.22%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 95.82%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `18.006 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `7.899 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `19.673 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg bounded original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg bounded log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `6.697 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt log-space:
  - status: `ok`
  - selected benchmark RMSE: 34.03%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 93.94%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `24.885 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `5.921 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.90%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 88.41%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `18.019 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt bounded original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt bounded log-space vs scalar log-space best-in-set benchmark RMSE: `tie`

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
- scalar original-space:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `83.069 s`
- scalar log-space:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `53.380 s`
- residual LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 5763.67%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 16327.56%
  - best-in-set local relative RMSE: 67.80%
  - runtime: `72.692 s`
  - polished representative count: `114`
- residual LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 109.53%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 162.25%
  - best-in-set local relative RMSE: 67.80%
  - runtime: `24.880 s`
  - polished representative count: `114`
- residual LM original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LM log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual FastShortcut original-space:
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
- residual FastShortcut log-space:
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
- residual FastShortcut original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual FastShortcut log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual TrustRegion original-space:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `62.092 s`
  - polished representative count: `114`
- residual TrustRegion log-space:
  - status: `ok`
  - selected benchmark RMSE: 109.94%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 162.87%
  - best-in-set local relative RMSE: 67.80%
  - runtime: `36.908 s`
  - polished representative count: `114`
- residual TrustRegion original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual TrustRegion log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `72.149 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 3927675226114354.50%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 21462706153630360.00%
  - best-in-set local relative RMSE: 68.27%
  - runtime: `57.173 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `58.192 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 9.24%
  - best-in-set benchmark RMSE: 9.24%
  - selected local relative RMSE: 17.87%
  - best-in-set local relative RMSE: 17.87%
  - runtime: `48.696 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM bounded original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM bounded log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg original-space:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `46.118 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg log-space:
  - status: `ok`
  - selected benchmark RMSE: 22.00%
  - best-in-set benchmark RMSE: 22.00%
  - selected local relative RMSE: 47.44%
  - best-in-set local relative RMSE: 47.44%
  - runtime: `41.287 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.65%
  - best-in-set benchmark RMSE: 23.80%
  - selected local relative RMSE: 55.42%
  - best-in-set local relative RMSE: 33.59%
  - runtime: `51.543 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 24.87%
  - best-in-set benchmark RMSE: 24.87%
  - selected local relative RMSE: 57.50%
  - best-in-set local relative RMSE: 57.50%
  - runtime: `44.059 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg bounded original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg bounded log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt original-space:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `47.721 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt log-space:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `34.976 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 17.71%
  - best-in-set benchmark RMSE: 8.70%
  - selected local relative RMSE: 33.58%
  - best-in-set local relative RMSE: 21.12%
  - runtime: `48.461 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `49.403 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt bounded original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt bounded log-space vs scalar log-space best-in-set benchmark RMSE: `tie`

