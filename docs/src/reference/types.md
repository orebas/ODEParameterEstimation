```@meta
CurrentModule = ODEParameterEstimation
```

# Other types

The package exports many more names than everyday use needs: the individual
interpolators and solvers, the stages of the estimation, and the tools used to
study how it behaves. This page and [the next](@ref "Other functions") list
them as they are documented in the source. The names meant for everyday use
are on [the previous page](@ref "Main functions and types").

The types to do with uncertainty, `UncertaintyReport` and those around it,
belong to an experimental part of the package. See [Uncertainty](@ref).

```@autodocs
Modules = [ODEParameterEstimation]
Order = [:type]
Private = false
Filter = t -> !(t in (ParameterEstimationProblem, ObservationData, ObservationSeries, EstimationOptions, ParameterEstimationResult, UnsupportedModelClassError, UnsupportedDerivativeOrderError, SamplingFailureError))
```
