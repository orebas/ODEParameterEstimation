# Residual-Vector Polish Ablation

- Generated: `2026-04-22 20:43:09`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Residual solver roster: `LevenbergMarquardt()`, `FastShortcutNLLSPolyalg()`, `TrustRegion()`, `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptimJL(:dogleg)`, `FastLevenbergMarquardt.lmsolve!()`
- Benchmark success tolerance: `10%` max relative error

| Case | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LM log best | residual FastShortcut log best | residual TrustRegion log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim Dogleg log best | residual FastLevenbergMarquardt log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 0.01% | 0.01% | 0.01% | 1.22% | Inf | 0.01% | Inf | Inf | Inf |
| `flexible_arm_0_1em4` | 0.54% | 3.60% | 30.93% | 32.61% | Inf | 32.61% | Inf | Inf | Inf |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LevenbergMarquardt()` | 0 better / 0 tie / 2 worse / 0 unsupported | 0 better / 0 tie / 2 worse / 0 unsupported | 0.342x |
| `FastShortcutNLLSPolyalg()` | 0 better / 0 tie / 0 worse / 2 unsupported | 0 better / 0 tie / 0 worse / 2 unsupported | Infx |
| `TrustRegion()` | 0 better / 1 tie / 1 worse / 0 unsupported | 0 better / 1 tie / 1 worse / 0 unsupported | 0.192x |
| `LeastSquaresOptimJL(:lm)` | 0 better / 0 tie / 0 worse / 2 unsupported | 0 better / 0 tie / 0 worse / 2 unsupported | Infx |
| `LeastSquaresOptimJL(:dogleg)` | 0 better / 0 tie / 0 worse / 2 unsupported | 0 better / 0 tie / 0 worse / 2 unsupported | Infx |
| `FastLevenbergMarquardt.lmsolve!()` | 0 better / 0 tie / 0 worse / 2 unsupported | 0 better / 0 tie / 0 worse / 2 unsupported | Infx |

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
  - runtime: `89.454 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `38.715 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `45.990 s`
  - polished representative count: `28`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 1.22%
  - best-in-set benchmark RMSE: 1.22%
  - selected local relative RMSE: 1.77%
  - best-in-set local relative RMSE: 1.77%
  - runtime: `19.551 s`
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
  - runtime: `8.648 s`
  - polished representative count: `28`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 0.01%
  - best-in-set benchmark RMSE: 0.01%
  - selected local relative RMSE: 0.01%
  - best-in-set local relative RMSE: 0.01%
  - runtime: `7.541 s`
  - polished representative count: `28`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `tie`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `tie`
- residual LeastSquaresOptim LM linear:
  - status: `error`
  - reason: `MethodError: no method matching select_jacobian_autodiff(::NonlinearLeastSquaresProblem{Vector{Float64}, true, SciMLBase.NullParameters, NonlinearFunction{true, SciMLBase.FullSpecialize, var"#residual!#28"{ODEParameterEstimation.PolishContext}, UniformScaling{Bool}, Nothing, Nothing, var"#30#31"{var"#residual_vec#29"{var"#residual!#28"{ODEParameterEstimation.PolishContext}, Int64}}, Nothing, Nothing, Matrix{Float64}, Matrix{Float64}, Nothing, Nothing, Nothing, typeof(SciMLBase.DEFAULT_OBSERVED_NO_TIME), Nothing, Nothing, Vector{Float64}, Nothing}, Base.Pairs{Symbol, Union{}, Nothing, @NamedTuple{}}, Nothing, Nothing}, ::Symbol)
The function `select_jacobian_autodiff` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::AbstractADType)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:85
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::Nothing)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:97
`
- residual LeastSquaresOptim LM log-positive:
  - status: `error`
  - reason: `MethodError: no method matching select_jacobian_autodiff(::NonlinearLeastSquaresProblem{Vector{Float64}, true, SciMLBase.NullParameters, NonlinearFunction{true, SciMLBase.FullSpecialize, var"#residual!#28"{ODEParameterEstimation.PolishContext}, UniformScaling{Bool}, Nothing, Nothing, var"#30#31"{var"#residual_vec#29"{var"#residual!#28"{ODEParameterEstimation.PolishContext}, Int64}}, Nothing, Nothing, Matrix{Float64}, Matrix{Float64}, Nothing, Nothing, Nothing, typeof(SciMLBase.DEFAULT_OBSERVED_NO_TIME), Nothing, Nothing, Vector{Float64}, Nothing}, Base.Pairs{Symbol, Union{}, Nothing, @NamedTuple{}}, Nothing, Nothing}, ::Symbol)
The function `select_jacobian_autodiff` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::AbstractADType)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:85
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::Nothing)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:97
`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg linear:
  - status: `error`
  - reason: `MethodError: no method matching select_jacobian_autodiff(::NonlinearLeastSquaresProblem{Vector{Float64}, true, SciMLBase.NullParameters, NonlinearFunction{true, SciMLBase.FullSpecialize, var"#residual!#28"{ODEParameterEstimation.PolishContext}, UniformScaling{Bool}, Nothing, Nothing, var"#30#31"{var"#residual_vec#29"{var"#residual!#28"{ODEParameterEstimation.PolishContext}, Int64}}, Nothing, Nothing, Matrix{Float64}, Matrix{Float64}, Nothing, Nothing, Nothing, typeof(SciMLBase.DEFAULT_OBSERVED_NO_TIME), Nothing, Nothing, Vector{Float64}, Nothing}, Base.Pairs{Symbol, Union{}, Nothing, @NamedTuple{}}, Nothing, Nothing}, ::Symbol)
The function `select_jacobian_autodiff` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::AbstractADType)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:85
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::Nothing)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:97
`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `error`
  - reason: `MethodError: no method matching select_jacobian_autodiff(::NonlinearLeastSquaresProblem{Vector{Float64}, true, SciMLBase.NullParameters, NonlinearFunction{true, SciMLBase.FullSpecialize, var"#residual!#28"{ODEParameterEstimation.PolishContext}, UniformScaling{Bool}, Nothing, Nothing, var"#30#31"{var"#residual_vec#29"{var"#residual!#28"{ODEParameterEstimation.PolishContext}, Int64}}, Nothing, Nothing, Matrix{Float64}, Matrix{Float64}, Nothing, Nothing, Nothing, typeof(SciMLBase.DEFAULT_OBSERVED_NO_TIME), Nothing, Nothing, Vector{Float64}, Nothing}, Base.Pairs{Symbol, Union{}, Nothing, @NamedTuple{}}, Nothing, Nothing}, ::Symbol)
The function `select_jacobian_autodiff` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::AbstractADType)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:85
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::Nothing)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:97
`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt linear:
  - status: `error`
  - reason: `MethodError: no method matching iterate(::Nothing)
The function `iterate` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  iterate(!Matched::LLVM.StructTypeElementSet)
   @ LLVM ~/.julia/packages/LLVM/fEIbx/src/core/type.jl:484
  iterate(!Matched::LLVM.StructTypeElementSet, !Matched::Any)
   @ LLVM ~/.julia/packages/LLVM/fEIbx/src/core/type.jl:484
  iterate(!Matched::Base.Iterators.ProductIterator{Tuple{}})
   @ Base iterators.jl:1122
  ...
`
- residual FastLevenbergMarquardt log-positive:
  - status: `error`
  - reason: `MethodError: no method matching iterate(::Nothing)
The function `iterate` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  iterate(!Matched::LLVM.StructTypeElementSet)
   @ LLVM ~/.julia/packages/LLVM/fEIbx/src/core/type.jl:484
  iterate(!Matched::LLVM.StructTypeElementSet, !Matched::Any)
   @ LLVM ~/.julia/packages/LLVM/fEIbx/src/core/type.jl:484
  iterate(!Matched::Base.Iterators.ProductIterator{Tuple{}})
   @ Base iterators.jl:1122
  ...
`
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
  - runtime: `167.551 s`
- scalar log-positive:
  - status: `ok`
  - selected benchmark RMSE: 30.93%
  - best-in-set benchmark RMSE: 30.93%
  - selected local relative RMSE: 68.75%
  - best-in-set local relative RMSE: 68.75%
  - runtime: `215.055 s`
- residual LM linear:
  - status: `ok`
  - selected benchmark RMSE: 34.94%
  - best-in-set benchmark RMSE: 32.61%
  - selected local relative RMSE: 102.30%
  - best-in-set local relative RMSE: 85.12%
  - runtime: `29.429 s`
  - polished representative count: `62`
- residual LM log-positive:
  - status: `ok`
  - selected benchmark RMSE: 38.87%
  - best-in-set benchmark RMSE: 32.61%
  - selected local relative RMSE: 141.70%
  - best-in-set local relative RMSE: 85.12%
  - runtime: `38.350 s`
  - polished representative count: `62`
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
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 32.61%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 85.12%
  - runtime: `33.802 s`
  - polished representative count: `62`
- residual TrustRegion log-positive:
  - status: `ok`
  - selected benchmark RMSE: 32.61%
  - best-in-set benchmark RMSE: 32.61%
  - selected local relative RMSE: 85.12%
  - best-in-set local relative RMSE: 85.12%
  - runtime: `40.757 s`
  - polished representative count: `62`
- residual TrustRegion linear vs scalar linear best-in-set benchmark RMSE: `better`
- residual TrustRegion log vs scalar log best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM linear:
  - status: `error`
  - reason: `MethodError: no method matching select_jacobian_autodiff(::NonlinearLeastSquaresProblem{Vector{Float64}, true, SciMLBase.NullParameters, NonlinearFunction{true, SciMLBase.FullSpecialize, var"#residual!#28"{ODEParameterEstimation.PolishContext}, UniformScaling{Bool}, Nothing, Nothing, var"#30#31"{var"#residual_vec#29"{var"#residual!#28"{ODEParameterEstimation.PolishContext}, Int64}}, Nothing, Nothing, Matrix{Float64}, Matrix{Float64}, Nothing, Nothing, Nothing, typeof(SciMLBase.DEFAULT_OBSERVED_NO_TIME), Nothing, Nothing, Vector{Float64}, Nothing}, Base.Pairs{Symbol, Union{}, Nothing, @NamedTuple{}}, Nothing, Nothing}, ::Symbol)
The function `select_jacobian_autodiff` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::AbstractADType)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:85
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::Nothing)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:97
`
- residual LeastSquaresOptim LM log-positive:
  - status: `error`
  - reason: `MethodError: no method matching select_jacobian_autodiff(::NonlinearLeastSquaresProblem{Vector{Float64}, true, SciMLBase.NullParameters, NonlinearFunction{true, SciMLBase.FullSpecialize, var"#residual!#28"{ODEParameterEstimation.PolishContext}, UniformScaling{Bool}, Nothing, Nothing, var"#30#31"{var"#residual_vec#29"{var"#residual!#28"{ODEParameterEstimation.PolishContext}, Int64}}, Nothing, Nothing, Matrix{Float64}, Matrix{Float64}, Nothing, Nothing, Nothing, typeof(SciMLBase.DEFAULT_OBSERVED_NO_TIME), Nothing, Nothing, Vector{Float64}, Nothing}, Base.Pairs{Symbol, Union{}, Nothing, @NamedTuple{}}, Nothing, Nothing}, ::Symbol)
The function `select_jacobian_autodiff` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::AbstractADType)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:85
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::Nothing)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:97
`
- residual LeastSquaresOptim LM linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM log vs scalar log best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg linear:
  - status: `error`
  - reason: `MethodError: no method matching select_jacobian_autodiff(::NonlinearLeastSquaresProblem{Vector{Float64}, true, SciMLBase.NullParameters, NonlinearFunction{true, SciMLBase.FullSpecialize, var"#residual!#28"{ODEParameterEstimation.PolishContext}, UniformScaling{Bool}, Nothing, Nothing, var"#30#31"{var"#residual_vec#29"{var"#residual!#28"{ODEParameterEstimation.PolishContext}, Int64}}, Nothing, Nothing, Matrix{Float64}, Matrix{Float64}, Nothing, Nothing, Nothing, typeof(SciMLBase.DEFAULT_OBSERVED_NO_TIME), Nothing, Nothing, Vector{Float64}, Nothing}, Base.Pairs{Symbol, Union{}, Nothing, @NamedTuple{}}, Nothing, Nothing}, ::Symbol)
The function `select_jacobian_autodiff` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::AbstractADType)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:85
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::Nothing)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:97
`
- residual LeastSquaresOptim Dogleg log-positive:
  - status: `error`
  - reason: `MethodError: no method matching select_jacobian_autodiff(::NonlinearLeastSquaresProblem{Vector{Float64}, true, SciMLBase.NullParameters, NonlinearFunction{true, SciMLBase.FullSpecialize, var"#residual!#28"{ODEParameterEstimation.PolishContext}, UniformScaling{Bool}, Nothing, Nothing, var"#30#31"{var"#residual_vec#29"{var"#residual!#28"{ODEParameterEstimation.PolishContext}, Int64}}, Nothing, Nothing, Matrix{Float64}, Matrix{Float64}, Nothing, Nothing, Nothing, typeof(SciMLBase.DEFAULT_OBSERVED_NO_TIME), Nothing, Nothing, Vector{Float64}, Nothing}, Base.Pairs{Symbol, Union{}, Nothing, @NamedTuple{}}, Nothing, Nothing}, ::Symbol)
The function `select_jacobian_autodiff` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::AbstractADType)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:85
  select_jacobian_autodiff(::SciMLBase.AbstractNonlinearProblem, !Matched::Nothing)
   @ NonlinearSolveBase ~/.julia/packages/NonlinearSolveBase/Rw8Vf/src/autodiff.jl:97
`
- residual LeastSquaresOptim Dogleg linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg log vs scalar log best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt linear:
  - status: `error`
  - reason: `MethodError: no method matching iterate(::Nothing)
The function `iterate` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  iterate(!Matched::LLVM.StructTypeElementSet)
   @ LLVM ~/.julia/packages/LLVM/fEIbx/src/core/type.jl:484
  iterate(!Matched::LLVM.StructTypeElementSet, !Matched::Any)
   @ LLVM ~/.julia/packages/LLVM/fEIbx/src/core/type.jl:484
  iterate(!Matched::Base.Iterators.ProductIterator{Tuple{}})
   @ Base iterators.jl:1122
  ...
`
- residual FastLevenbergMarquardt log-positive:
  - status: `error`
  - reason: `MethodError: no method matching iterate(::Nothing)
The function `iterate` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  iterate(!Matched::LLVM.StructTypeElementSet)
   @ LLVM ~/.julia/packages/LLVM/fEIbx/src/core/type.jl:484
  iterate(!Matched::LLVM.StructTypeElementSet, !Matched::Any)
   @ LLVM ~/.julia/packages/LLVM/fEIbx/src/core/type.jl:484
  iterate(!Matched::Base.Iterators.ProductIterator{Tuple{}})
   @ Base iterators.jl:1122
  ...
`
- residual FastLevenbergMarquardt linear vs scalar linear best-in-set benchmark RMSE: `worse`
- residual FastLevenbergMarquardt log vs scalar log best-in-set benchmark RMSE: `worse`

