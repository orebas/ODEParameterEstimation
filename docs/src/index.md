```@meta
CurrentModule = ODEParameterEstimation
```

# ODEParameterEstimation.jl

ODEParameterEstimation.jl fits the parameters and initial conditions of an ODE
model to time-series data. You give it the model and the measurements. It
returns every parameter set that fits them, and tells you which parameters the
data cannot determine.

It works by solving equations rather than by searching. Derivatives of the data
are estimated, the model turns them into polynomial equations for the unknowns,
and those equations are solved for all their solutions, which are then refined
against the data. Because the equations must be polynomial, the model has to be
built from polynomials and ratios of polynomials. That covers mass-action
kinetics, population and epidemic models, compartment models and most linear
systems.

```julia
using ODEParameterEstimation, ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

@parameters α β γ δ
@variables prey(t) predators(t) y1(t) y2(t)
@named lotka_volterra = System([
    D(prey) ~ α * prey - β * prey * predators,
    D(predators) ~ δ * prey * predators - γ * predators,
], t)

problem = ParameterEstimationProblem(lotka_volterra, [y1 ~ prey, y2 ~ predators];
    data = (t = times, y1 = prey_counts, y2 = predator_counts))

results = estimate(problem)
```

[Getting started](@ref) runs this example and explains each line.

## Finding your way

- **Tutorials** each work through one situation:
  [your own data](@ref "Your own data"), [noisy data](@ref "Noisy data"),
  [models with more than one answer](@ref "More than one answer") and
  [uncertainty](@ref "Uncertainty").
- **Guides** cover one topic each: [which models work](@ref "Which models work"),
  the [options](@ref "Options") worth knowing, how to read
  [results](@ref "Results"), [how the method works](@ref "How it works"), and
  [what to try when something goes wrong](@ref "Troubleshooting").
- **Reference** documents [the main functions and types](@ref "Main functions and types").

## Citing

If you use this package in your work, please cite the papers it is based on:

> O. Bassik, A. Demin, A. Ovchinnikov. *Practical algebraic parameter estimation
> for noisy data via Gaussian process regression.*
> [arXiv:2609.30451](https://arxiv.org/abs/2609.30451) (2026).

> O. Bassik, Y. Berman, S. Go, H. Hong, I. Ilmer, A. Ovchinnikov, C. Rackauckas,
> P. Soto, C. Yap. *Robust parameter estimation for rational ordinary
> differential equations.* Applied Mathematics and Computation 509 (2026).
> [doi:10.1016/j.amc.2025.129638](https://doi.org/10.1016/j.amc.2025.129638)
