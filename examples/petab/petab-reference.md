# PEtab.jl Core Specification

## Primary Types & Constructors

```julia
PEtabParameter(id::Symbol; value=nothing, lb=1e-3, ub=1e3, scale=:log10, prior=nothing, prior_on_linear_scale=true)
PEtabObservable(formula::Num, noise_formula::Union{Num,Number})
PEtabEvent(condition::Union{Num,Number}, affect::Union{Vector,Num,Number}, target::Union{Vector,Symbol,Num})
PEtabModel(model::Union{ReactionSystem,ODESystem}, observables::Dict, measurements::DataFrame, parameters::Vector{PEtabParameter}; kwargs...)
PEtabODEProblem(model::PEtabModel; kwargs...)
```

## Core Problem Creation Pipeline

1. Define dynamic model (ReactionSystem/ODESystem)
2. Define observables (PEtabObservable)
3. Define parameters to estimate (PEtabParameter) 
4. Provide measurements DataFrame:
   - Required columns: obs_id, time, measurement
   - Optional columns: simulation_id, pre_eq_id, observable_parameters, noise_parameters
5. Create PEtabModel
6. Create PEtabODEProblem

## Parameter Estimation Methods

### Single-start:
```julia
calibrate(prob::PEtabODEProblem, x0::AbstractVector, alg; kwargs...)
```

### Multi-start:
```julia
calibrate_multistart(prob::PEtabODEProblem, alg, n::Int; kwargs...)
get_startguesses(prob::PEtabODEProblem, n::Int)
```

### Supported Optimizers:
- Optim.jl: LBFGS(), BFGS(), IPNewton()
- Ipopt: IpoptOptimizer(use_hessian::Bool)
- Fides: Fides(hessian_update::Union{Nothing,String})

## Key Configuration Options

### ODESolver:
```julia
ODESolver(alg; abstol=1e-8, reltol=1e-8, maxiters=Int(1e5))
```

### Gradient Methods:
- :ForwardDiff (default for small models)
- :ForwardEquations 
- :Adjoint (default for large models)

### Hessian Methods:
- :ForwardDiff (small models)
- :BlockForwardDiff
- :GaussNewton (medium models)
- LBFGS (large models)

## Advanced Features

### Simulation Conditions:
- Provided as Dict of Dicts
- Maps simulation_id to parameter/species values
- Required in measurements DataFrame

### Pre-equilibration:
- Specified via pre_eq_id in measurements
- Requires SteadyStateSolver configuration

### Events:
- Time-triggered: t == value
- Species-triggered: species == value
- Multiple targets supported
- Condition-specific via control parameters

### Noise & Observable Parameters:
- Format: observableParameter${n}_${obsId}
- Format: noiseParameter${n}_${obsId}
- Specified in measurements DataFrame

## Default Behaviors

Small Models (≤20 params, ≤15 ODEs):
- Solver: Rodas5P()
- Gradient: :ForwardDiff
- Hessian: :ForwardDiff

Medium Models (≤75 params/ODEs):
- Solver: QNDF()
- Gradient: :ForwardDiff
- Hessian: :GaussNewton

Large Models (>75 params/ODEs):
- Solver: CVODE_BDF()
- Gradient: :Adjoint
- Hessian: LBFGS

## Critical Implementation Notes

1. Parameters estimated on log10 scale by default
2. ComponentArrays used for parameter vectors
3. Parameter order must match PEtabODEProblem expectation
4. Events should use PEtabEvent not native callbacks
5. Gradient/Hessian methods not shared between artifacts/analysis tool
