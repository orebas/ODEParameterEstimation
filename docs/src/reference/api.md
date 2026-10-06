```@meta
CurrentModule = ODEParameterEstimation
```

# Main functions and types

Most uses of the package need only what is on this page.

```@docs
ODEParameterEstimation
```

## Setting up a problem

```@docs
ParameterEstimationProblem(::ModelingToolkit.AbstractSystem, ::AbstractVector{<:ModelingToolkit.Equation})
ParameterEstimationProblem
sample_problem_data
ObservationData
ObservationSeries
observation_times
```

## Estimating

```@docs
estimate
analyze_parameter_estimation_problem
EstimationOptions
```

## The result type

```@docs
ParameterEstimationResult
Base.getindex(::ParameterEstimationResult, ::Any)
```

## Errors

```@docs
UnsupportedModelClassError
UnsupportedDerivativeOrderError
SamplingFailureError
```
