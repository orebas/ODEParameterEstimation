# Residual-Vector Polish Ablation

- Generated: `2026-04-23 12:50:27`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Research analysis mode: `ungated`
- Residual solver roster: `LevenbergMarquardt()`, `FastShortcutNLLSPolyalg()`, `TrustRegion()`, `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptim.optimize!(LevenbergMarquardt(); lower/upper)`, `LeastSquaresOptimJL(:dogleg)`, `LeastSquaresOptim.optimize!(Dogleg(); lower/upper)`, `FastLevenbergMarquardt.lmsolve!()`, `FastLevenbergMarquardt.lmsolve!() with lb/ub`
- Benchmark success tolerance: `10%` max relative error

| Case | Imported best RMSE | Analyzed imported best RMSE | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LM log best | residual FastShortcut log best | residual TrustRegion log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim LM bounded log best | residual LeastSquaresOptim Dogleg log best | residual LeastSquaresOptim Dogleg bounded log best | residual FastLevenbergMarquardt log best | residual FastLevenbergMarquardt bounded log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `daisy_mamil4_6_1em4` | 15.98% | 15.98% | 0.33% | 0.31% | 6.48% | 13.85% | Inf | 0.33% | 13.85% | 0.33% | 0.33% | 0.33% | 1.72% | 1.06% |
| `flexible_arm_0_1em4` | 6.62% | 6.62% | 0.54% | 3.60% | 6.62% | 6.62% | Inf | 6.62% | 6.62% | 6.62% | 6.62% | 6.62% | 6.62% | 6.62% |
| `seir_4_1em4` | 34.09% | 34.09% | 0.05% | 0.63% | 0.05% | 34.09% | Inf | 34.09% | 34.09% | 9.24% | 22.00% | 24.87% | 0.05% | 0.05% |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LevenbergMarquardt()` | 0 better / 1 tie / 2 worse / 0 unsupported | 0 better / 0 tie / 3 worse / 0 unsupported | 0.272x |
| `FastShortcutNLLSPolyalg()` | 0 better / 0 tie / 0 worse / 3 unsupported | 0 better / 0 tie / 0 worse / 3 unsupported | Infx |
| `TrustRegion()` | 1 better / 1 tie / 1 worse / 0 unsupported | 0 better / 0 tie / 3 worse / 0 unsupported | 0.193x |
| `LeastSquaresOptimJL(:lm)` | 0 better / 1 tie / 2 worse / 0 unsupported | 0 better / 0 tie / 3 worse / 0 unsupported | 0.339x |
| `LeastSquaresOptim.optimize!(LevenbergMarquardt(); lower/upper)` | 1 better / 1 tie / 1 worse / 0 unsupported | 1 better / 0 tie / 2 worse / 0 unsupported | 0.363x |
| `LeastSquaresOptimJL(:dogleg)` | 1 better / 1 tie / 1 worse / 0 unsupported | 0 better / 0 tie / 3 worse / 0 unsupported | 0.179x |
| `LeastSquaresOptim.optimize!(Dogleg(); lower/upper)` | 1 better / 1 tie / 1 worse / 0 unsupported | 0 better / 0 tie / 3 worse / 0 unsupported | 0.244x |
| `FastLevenbergMarquardt.lmsolve!()` | 1 better / 2 tie / 0 worse / 0 unsupported | 0 better / 1 tie / 2 worse / 0 unsupported | 0.137x |
| `FastLevenbergMarquardt.lmsolve!() with lb/ub` | 1 better / 2 tie / 0 worse / 0 unsupported | 1 better / 1 tie / 1 worse / 0 unsupported | 0.268x |

## Case Notes

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
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.08%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.17%
  - runtime: `282.247 s`
- scalar log-space:
  - status: `ok`
  - selected benchmark RMSE: 23.65%
  - best-in-set benchmark RMSE: 6.48%
  - selected local relative RMSE: 48.11%
  - best-in-set local relative RMSE: 13.60%
  - runtime: `271.545 s`
- residual LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 66.08%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 148.28%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `117.591 s`
  - polished representative count: `119`
- residual LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 27.86%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 59.08%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `73.734 s`
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
  - runtime: `73.047 s`
  - polished representative count: `119`
- residual TrustRegion log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `52.367 s`
  - polished representative count: `119`
- residual TrustRegion original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual TrustRegion log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `114.623 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.02%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 71.61%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `92.003 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `97.929 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `98.444 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM bounded original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `72.788 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `48.689 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `58.364 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `66.176 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg bounded original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt original-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.02%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.04%
  - runtime: `75.479 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt log-space:
  - status: `ok`
  - selected benchmark RMSE: 24.17%
  - best-in-set benchmark RMSE: 1.72%
  - selected local relative RMSE: 49.82%
  - best-in-set local relative RMSE: 4.14%
  - runtime: `37.120 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.02%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.04%
  - runtime: `103.153 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 1.06%
  - best-in-set benchmark RMSE: 1.06%
  - selected local relative RMSE: 2.51%
  - best-in-set local relative RMSE: 2.51%
  - runtime: `72.703 s`
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
  - runtime: `150.875 s`
- scalar log-space:
  - status: `ok`
  - selected benchmark RMSE: 30.93%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 68.75%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `194.671 s`
- residual LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 34.94%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 102.30%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `51.250 s`
  - polished representative count: `62`
- residual LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 38.87%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 141.70%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `36.759 s`
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
  - runtime: `26.607 s`
  - polished representative count: `62`
- residual TrustRegion log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `35.887 s`
  - polished representative count: `62`
- residual TrustRegion original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual TrustRegion log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 35.26%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 104.13%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `10.012 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.84%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 93.71%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `27.670 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `7.355 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.23%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 86.99%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `23.687 s`
  - polished representative count: `62`
- residual LeastSquaresOptim LM bounded original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM bounded log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `7.667 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg log-space:
  - status: `ok`
  - selected benchmark RMSE: 34.22%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 95.82%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `18.036 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `8.132 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `20.130 s`
  - polished representative count: `62`
- residual LeastSquaresOptim Dogleg bounded original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg bounded log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `6.771 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt log-space:
  - status: `ok`
  - selected benchmark RMSE: 34.03%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 93.94%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `25.488 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `6.097 s`
  - polished representative count: `62`
- residual FastLevenbergMarquardt bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 32.90%
  - best-in-set benchmark RMSE: 6.62%
  - selected local relative RMSE: 88.41%
  - best-in-set local relative RMSE: 19.70%
  - runtime: `18.350 s`
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
  - runtime: `88.900 s`
- scalar log-space:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `56.943 s`
- residual LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 5763.67%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 16327.56%
  - best-in-set local relative RMSE: 67.80%
  - runtime: `77.460 s`
  - polished representative count: `114`
- residual LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 109.53%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 162.25%
  - best-in-set local relative RMSE: 67.80%
  - runtime: `26.061 s`
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
  - runtime: `67.105 s`
  - polished representative count: `114`
- residual TrustRegion log-space:
  - status: `ok`
  - selected benchmark RMSE: 109.94%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 162.87%
  - best-in-set local relative RMSE: 67.80%
  - runtime: `39.557 s`
  - polished representative count: `114`
- residual TrustRegion original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual TrustRegion log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `78.077 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 3927675226114354.50%
  - best-in-set benchmark RMSE: 34.09%
  - selected local relative RMSE: 21462706153630360.00%
  - best-in-set local relative RMSE: 68.27%
  - runtime: `61.284 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `61.034 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 9.24%
  - best-in-set benchmark RMSE: 9.24%
  - selected local relative RMSE: 17.87%
  - best-in-set local relative RMSE: 17.87%
  - runtime: `52.147 s`
  - polished representative count: `114`
- residual LeastSquaresOptim LM bounded original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM bounded log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg original-space:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `49.330 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg log-space:
  - status: `ok`
  - selected benchmark RMSE: 22.00%
  - best-in-set benchmark RMSE: 22.00%
  - selected local relative RMSE: 47.44%
  - best-in-set local relative RMSE: 47.44%
  - runtime: `42.593 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim Dogleg log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.65%
  - best-in-set benchmark RMSE: 23.80%
  - selected local relative RMSE: 55.42%
  - best-in-set local relative RMSE: 33.59%
  - runtime: `54.346 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 24.87%
  - best-in-set benchmark RMSE: 24.87%
  - selected local relative RMSE: 57.50%
  - best-in-set local relative RMSE: 57.50%
  - runtime: `45.871 s`
  - polished representative count: `114`
- residual LeastSquaresOptim Dogleg bounded original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg bounded log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt original-space:
  - status: `ok`
  - selected benchmark RMSE: 37.08%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 99.64%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `49.520 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt log-space:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `36.562 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt original-space vs scalar original-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt log-space vs scalar log-space best-in-set benchmark RMSE: `tie`
- residual FastLevenbergMarquardt bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 17.71%
  - best-in-set benchmark RMSE: 8.70%
  - selected local relative RMSE: 33.58%
  - best-in-set local relative RMSE: 21.12%
  - runtime: `51.586 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 0.05%
  - best-in-set benchmark RMSE: 0.05%
  - selected local relative RMSE: 0.10%
  - best-in-set local relative RMSE: 0.10%
  - runtime: `49.710 s`
  - polished representative count: `114`
- residual FastLevenbergMarquardt bounded original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt bounded log-space vs scalar log-space best-in-set benchmark RMSE: `tie`

