```@meta
CollapsedDocStrings=true
```

# [PEtab.jl API](@id API)

## PEtabModel

A `PEtabModel` for parameter estimation/inference can be created by importing a PEtab parameter estimation problem in the [standard format](https://petab.readthedocs.io/en/latest/), or it can be directly defined in Julia. For the latter, observables that link the model to measurement data are provided by `PEtabObservable`, parameters to estimate are defined by `PEtabParameter`, and any potential events (callbacks) are specified as `PEtabEvent`.

```@docs
PEtabObservable
PEtabParameter
PEtabEvent
```

Then, given a dynamic model (as `ReactionSystem` or `ODESystem`), measurement data as a `DataFrame`, and potential simulation conditions as a `Dict` (see [this](@ref petab_sim_cond) tutorial), a `PEtabModel` can be created:

```@docs
PEtabModel
```

## PEtabODEProblem

From a `PEtabModel`, a `PEtabODEProblem` can:

```@docs
PEtabODEProblem
```

A `PEtabODEProblem` has numerous configurable options. Two of the most important options are the `ODESolver` and, for models with steady-state simulations, the `SteadyStateSolver`:

```@docs
ODESolver
SteadyStateSolver
```

PEtab.jl provides several functions for interacting with a `PEtabODEProblem`:

```@docs
get_x
remake(::PEtabODEProblem, ::Dict)
```

And additionally, functions for interacting with the underlying dynamic model (`ODEProblem`) within a `PEtabODEProblem`:

```@docs
get_u0
get_ps
get_odeproblem
get_odesol
solve_all_conditions
```

## Parameter Estimation

A `PEtabODEProblem` contains all the necessary information for wrapping a suitable numerical optimization library, but for convenience, PEtab.jl provides wrappers for several available optimizers. In particular, single-start parameter estimation is provided via `calibrate`:

```@docs
calibrate
PEtabOptimisationResult
```

Multi-start (recommended method) parameter estimation, is provided via `calibrate_multistart`:

```@docs
calibrate_multistart
get_startguesses
PEtabMultistartResult
```

Lastly, model selection is provided via `petab_select`:

```@docs
petab_select
```

For each case case, PEtab.jl supports the usage of optimization algorithms from [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl), [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl), and [Fides.py](https://github.com/fides-dev/fides):

```@docs
Fides
IpoptOptimizer
IpoptOptions
```

Parameter estimation results can be visualized using the plot-recipes detailed in [this](@ref optimization_output_plotting) page, and with `get_obs_comparison_plots`:

```@docs
get_obs_comparison_plots
```

As an alternative to the PEtab.jl interface to parameter estimation, a `PEtabODEProblem` can be converted to an `OptimizationProblem` to access the algorithms available via [Optimization.jl](https://github.com/SciML/Optimization.jl):

```@docs
PEtab.OptimizationProblem
```

## Bayesian Inference

PEtab.jl offers wrappers to perform Bayesian inference using state-of-the-art methods such as [NUTS](https://github.com/TuringLang/Turing.jl) (the same sampler used in [Turing.jl](https://github.com/TuringLang/Turing.jl)) or [AdaptiveMCMC.jl](https://github.com/mvihola/AdaptiveMCMC.jl). It should be noted that this part of PEtab.jl is planned to be moved to a separate package, so the syntax will change and be made more user-friendly in the future.

```@docs
PEtabLogDensity
to_prior_scale
to_chains
```
# [Adjoint Sensitivity Analysis (large models)](@id adjoint)

Having access to the gradient is beneficial for parameter estimation, as gradient-based optimization algorithms often perform best [raue2013lessons, villaverde2019benchmarking](@cite). For large model, the most efficient gradient method is adjoint sensitivity analysis [frohlich2017scalable, ma2021comparison](@cite), with a good mathematical description provided in [sapienza2024differentiable](@cite). PEtab.jl supports the adjoint sensitivity algorithms in [SciMLSensitivity.jl](https://github.com/SciML/SciMLSensitivity.jl). For these algorithms, three key options impact performance: which algorithm is used to compute the gradient quadrature, which method is used to compute the Vector-Jacobian-Product (VJP) in the adjoint ODE, and which ODE solver is used. This advanced example covers these considerations and assumes familiarity with gradient methods in PEtab (see [this](@ref gradient_support) page). In addition to this page, further details on tunable options are available in the SciMLSensitivity [documentation](https://github.com/SciML/SciMLSensitivity.jl).

As a working example, we use a published signaling model referred to as the Bachhman model after the first author [bachmann2011division](@cite). The Bachmann model is available in the PEtab standard format (a tutorial on importing problems in the standard format can be found [here](@ref import_petab_problem)), and the PEtab files for this model can be downloaded from [here](https://github.com/sebapersson/PEtab.jl/tree/main/docs/src/assets/bachmann). Given the problem YAML file, we can import the problem as:

```@example 1
using PEtab
path_yaml = joinpath(@__DIR__, "assets", "bachmann", "Bachmann_MSB2011.yaml")
model = PEtabModel(path_yaml)
nothing # hide
```

## Tuning Options

The Bachmann model is a medium-sized model with 25 species in the ODE system and 113 parameters to estimate. Even though `gradient_method=:ForwardDiff` performs best for this model (more on this below), it is a good example for showcasing different tuning options. In particular, when computing the gradient via adjoint sensitivity analysis, the key tunable options for a `PEtabODEProblem` are:

1. `odesolver_gradient`: Which ODE solver and solver tolerances (`abstol` and `reltol`) to use when solving the adjoint ODE system. Currently, `CVODE_BDF()` performs best.
2. `sensealg`: Which adjoint algorithm to use. PEtab.jl supports the `InterpolatingAdjoint`, `QuadratureAdjoint`, and `GaussAdjoint` methods from SciMLSensitivity. For these, the most important tunable option is the VJP method, where `EnzymeVJP` often performs best. If this method does not work, `ReverseDiffVJP(true)` is a good alternative.

As `QuadratureAdjoint` is the least reliable method, we here explore `InterpolatingAdjoint` and `GaussAdjoint`:

```@example 1
using SciMLSensitivity, Sundials
osolver = ODESolver(CVODE_BDF(); abstol_adj = 1e-3, reltol_adj = 1e-6)
petab_prob1 = PEtabODEProblem(model; gradient_method = :Adjoint,
                              odesolver = osolver, odesolver_gradient = osolver,
                              sensealg = InterpolatingAdjoint(autojacvec = EnzymeVJP()))
petab_prob2 = PEtabODEProblem(model; gradient_method = :Adjoint,
                              odesolver = osolver, odesolver_gradient = osolver,
                              sensealg = GaussAdjoint(autojacvec = EnzymeVJP()))
nothing # hide
```

Two things should be noted here. First, to use the adjoint functionality in PEtab.jl, SciMLSensitivity must be loaded. Second, when creating the `ODESolver`, `adj_abstol` sets the tolerances for solving the adjoint ODE (but not the standard forward ODE). From our experience, setting the adjoint tolerances lower than the default `1e-8` improves simulation stability (gradient computations fail less frequently). Given this, we can now compare runtime:

```@example 1
using Printf
x = get_x(petab_prob1)
g1, g2 = similar(x), similar(x)
petab_prob1.grad!(g1, x)
petab_prob2.grad!(g2, x)
b1 = @elapsed petab_prob1.grad!(g1, x) # hide
b2 = @elapsed petab_prob2.grad!(g2, x) # hide
@printf("Runtime InterpolatingAdjoint: %.1fs\n", b1)
@printf("Runtime GaussAdjoint: %.1fs\n", b2)
```

In this case `InterpolatingAdjoint` performs best (this can change dependent on computer). As mentioned above, another important argument is the VJP method; let us explore the best two options for `InterpolatingAdjoint`:

```@example 1
petab_prob1 = PEtabODEProblem(model; gradient_method = :Adjoint,
                              odesolver = osolver, odesolver_gradient = osolver,
                              sensealg = InterpolatingAdjoint(autojacvec = EnzymeVJP()))
petab_prob2 = PEtabODEProblem(model; gradient_method = :Adjoint,
                              odesolver = osolver, odesolver_gradient = osolver,
                              sensealg = InterpolatingAdjoint(autojacvec = ReverseDiffVJP(true)))
petab_prob1.grad!(g1, x) # hide
petab_prob2.grad!(g2, x) # hide
b1 = @elapsed petab_prob1.grad!(g1, x)
b2 = @elapsed petab_prob2.grad!(g2, x)
@printf("Runtime EnzymeVJP() : %.1fs\n", b1)
@printf("Runtime ReverseDiffVJP(true): %.1fs\n", b2)                              
nothing # hide
```

In this case, `ReverseDiffVJP(true)` performs best (this can vary depending on the computer), but often `EnzymeVJP` is the better choice. Generally, `GaussAdjoint` with `EnzymeVJP` is often the best combination, but as seen above, this is not always the case. Therefore, for larger models where runtime can be substantial, we recommend benchmarking different adjoint algorithms and VJP methods to find the best configuration for your specific problem.

Lastly, it should be noted that even if `gradient_method=:Adjoint` is the fastest option for larger models, we still recommend using `:ForwardDiff` if it is not substantially slower. This is because computing the gradient via adjoint methods is much more challenging than with forward methods, as the adjoint approach requires solving a difficult adjoint ODE. In our benchmarks, we have observed that sometimes `:ForwardDiff` successfully computes the gradient, while `:Adjoint` does not. Moreover, forward methods tend to produce more accurate gradients.

## References

```@bibliography
Pages = ["Bachmann.md"]
Canonical = false
```
# [Condition-Specific Parameters](@id Beer_tut)

As discussed in [this](@ref define_conditions) extended tutorial, sometimes a subset of the model parameters to estimate have different values across experimental/simulation conditions. For such models, runtime can drastically improve by setting `split_over_conditions=true` when creating a `PEtabODEProblem`. This example explores this option in more detail, and it assumes that that you are familiar with condition-specific parameters in PEtab (see [this](@ref define_conditions) tutorial) and with the gradient methods in PEtab.jl (see [this](@ref gradient_support) page).

As a working example, we use a published signaling model referred to as the Beer model after the first author [beer2014creating](@cite). The Beer model is available in the PEtab standard format (a tutorial on importing problems in the standard format can be found [here](@ref import_petab_problem)), and the PEtab files for this model can be downloaded from [here](https://github.com/sebapersson/PEtab.jl/tree/main/docs/src/assets/beer). Given the problem YAML file, we can import the problem as:

```@example 1
using PEtab
path_yaml = joinpath(@__DIR__, "assets", "beer", "Beer_MolBioSystems2014.yaml")
model = PEtabModel(path_yaml)
nothing # hide
```

## Efficient Handling of Condition-Specific Parameters

The Beer problem is a small model with 4 species and 9 parameters in the ODE system, but there are 72 parameters to estimate. This is because most parameters are specific to a subset of simulation conditions. For example, `cond1` has a parameter `τ_cond1`, and `cond2` has `τ_cond2`, which map to the ODE model parameter `τ`, respectively. This can be seen by printing some model statistics:

```@example 1
using Catalyst
petab_prob = PEtabODEProblem(model)
println("Number of ODE model species = ", length(unknowns(model.sys)))
println("Number of ODE model parameters = ", length(parameters(model.sys)))
println("Number of parameters to estimate = ", length(petab_prob.xnames))
```

For small ODE models like the Beer model, the most efficient gradient method is `gradient_method=:ForwardDiff`, and it is often feasible to compute the Hessian using `hessian_method=:ForwardDiff` as well (see [this](@ref gradient_support) page for details). Typically, with `:ForwardDiff`, PEtab.jl computes the gradient with a single call to `ForwardDiff.gradient`. However, for the Beer model, this approach is problematic because for each simulation condition, `n` forward passes are required to compute all derivatives, where `n` depends on the number of gradient parameters. Since many parameters only belong to a subset of conditions, actually only `ni < n` forward passes are needed for each condition. To this end, PEtab.jl provides the `split_over_conditions=true` keyword when building the `PEtabODEProblem`, which ensures that one `ForwardDiff.gradient` call is performed per simulation condition. Let us examine how this affects gradient runtime for the Beer model:

```@example 1
using Printf
petab_prob1 = PEtabODEProblem(model; split_over_conditions = true)
petab_prob2 = PEtabODEProblem(model; split_over_conditions = false)
x = get_x(petab_prob1)
g1, g2 = similar(x), similar(x)
petab_prob1.grad!(g1, x) # hide
petab_prob2.grad!(g2, x) # hide
b1 = @elapsed petab_prob1.grad!(g1, x)
b2 = @elapsed petab_prob2.grad!(g2, x)
@printf("Runtime split_over_conditions = true: %.2fs\n", b1)
@printf("Runtime split_over_conditions = false: %.2fs\n", b2)
```

For the Hessian, the difference in runtime is even larger:

```@example 1
h1, h2 = zeros(length(x), length(x)), zeros(length(x), length(x))
_ = petab_prob1.nllh(x) # hide
_ = petab_prob2.nllh(x) # hide
petab_prob1.hess!(h1, x) # hide
petab_prob2.hess!(h2, x) # hide
b1 = @elapsed petab_prob1.hess!(h1, x)
b2 = @elapsed petab_prob2.hess!(h2, x)
@printf("Runtime split_over_conditions = true: %.1fs\n", b1)
@printf("Runtime split_over_conditions = false: %.1fs\n", b2)
```

Given that `split_over_conditions=true` reduces runtime in the example above, a natural question is: why is it not the default option in PEtab.jl? This is because calling `ForwardDiff.gradient` for each simulation condition, instead of once for all conditions, introduces an overhead. Therefore, for models with none or very few condition-specific parameters, `split_over_conditions=false` is faster. Determining exactly how many condition-specific parameters are needed to make `true` the faster option is difficult. Currently, the default is to enable this option when the number of condition-specific parameters is at least twice the number of parameters to estimate in the ODE model. For the Beer model, this means `split_over_conditions=true` is set by default, but this is a rough heuristic. Therefore, for models like these, we recommend benchmarking the two configurations to determine which is fastest.

## References

```@bibliography
Pages = ["Beer.md"]
Canonical = false
```
# [Frequently Asked Questions](@id FAQ)

## How do I check that I implemented my parameter estimation problem correctly?

After creating a `PEtabODEProblem`, it is important to check that everything works as expected. Since PEtab.jl creates parameter estimation problems, this means checking that the objective function (the problem likelihood) is computable, because if not, running parameter estimation will only return `NaN` or `Inf`.

The first step to verify that the likelihood is computable is to check if the objective function can be computed for the nominal parameters:

```julia
x = get_x(petab_prob)
petab_prob.nllh(x)
```

The nominal values can be specified when creating a `PEtabParameter` or in the parameters table if the problem is provided in the PEtab standard format (otherwise, they default to the mean of the parameter bounds). If the problem is correctly specified, the likelihood should be computable for these values. However, sometimes the nominal values can be poor choices (far from the 'true' parameters as we do not know them, hence the need for PEtab.jl), and the code above may return `Inf` because the ODE cannot be solved. If this happens, check if the likelihood can be computed for random parameters:

```julia
get_startguesses(petab_prob, 10)
```

Specially, the [`get_startguesses`](@ref) function tries to find random parameter vectors for which the likelihood can be computed. If this function fails to return a parameter set, there is likely an issue with the problem formulation.

If the objective function cannot be computed, check out the tips below. If none of the suggestions help, please file an [issue](https://github.com/sebapersson/PEtab.jl/issues) on GitHub.

## Why do I get `NaN` or `Inf` when computing the objective function or during parameter estimation?

Sometimes, when computing the likelihood (`petab_prob.nllh(x)`) or during parameter estimation, `Inf` or `NaN` may be returned. This can be due to several reasons.

`Inf` is returned when the ODE model cannot be solved. When this happens, a warning like `Failed to solve ODE model` should be printed. If no ODE solver warning is shown, check that the observable formulas and noise formulas cannot evaluate to `Inf` (e.g., there are no expressions that can evaluate to `log(0)`). If neither of these reasons causes `Inf` to be returned, please file an [issue](https://github.com/sebapersson/PEtab.jl/issues) on GitHub. For how to deal with ODE solver warnings, see one of the questions below.

If `NaN` is returned, the model formulas are likely ill-formulated. In PEtab.jl, the most common cause of `NaN` being returned is that `log` is applied to a negative value, often due to an ill-formulated noise formula. For example, consider the observable `h = PEtabObservable(X, sigma * X)`, where `X` is a model species and `sigma` is a parameter. When computing the objective value (likelihood) for this observable, the `log` of the noise formula `sigma * X` is evaluated. Even if the model uses mass-action kinetics and `X` should never go below zero, in practice, numerical noise during ODE solving can cause `X` to become negative, leading to a negative argument for `log`. Therefore, a more stable noise formula than the one above would be `sigma1 + sigma2 * X`.

## Why do I get the error *MethodError: Cannot convert an object of type Nothing to an object of type Real*?

This error likely occurs because some model parameters have not been defined. For example, consider the observable `h = PEtabObservable(X, sigma)`, where `X` is a model species and `sigma` is a parameter. If `sigma` has not been defined as a `PEtabParameter`, the above error will be thrown when computing the objective function. This also applies to misspellings. For example, if the observable is defined as `h = PEtabObservable(X, sigma1)` but only `sigma` (not `sigma1`) is defined as a `PEtabParameter`, the same error will be thrown.

## Why are my parameter values (e.g., start-guesses) negative?

When creating start-guesses for parameter estimation with [`get_x`](@ref) or [`get_startguesses`](@ref), the values in the returned vector(s) can sometimes be negative. As discussed in the [starting tutorial](@ref tutorial), this is because parameters are estimated on the `log10` scale by default, as this often improves performance. Consequently, when setting new parameter values manually, they should be provided on the parameter scale. It is also possible to change the parameter scale; see [`PEtabParameter`](@ref).

## I get ODE-solver warnings during parameter estimation, is my model wrong?

When doing parameter estimation, it is not uncommon for the warning `Failed to solve ODE model` to be thrown a few times. This is because when estimating model parameters with a numerical optimization algorithm that starts from random points in parameter space (e.g., when using [`calibrate_multistart`](@ref)), poor parameter values that cause difficult dynamics to solve are sometimes generated. However, if the `Failed to solve ODE model` warning is thrown frequently, there is likely a problem with the model structure, or a suboptimal ODE solver is used. We recommend first checking if the issue is related to the ODE solver.

A great collection of tips for dealing with different ODE solver warnings can be found [here](https://docs.sciml.ai/DiffEqDocs/stable/basics/faq/#faq). Briefly, it can be helpful to adjust the tolerances in [`ODESolver`](@ref), as the default settings are quite strict. Further, if `maxiters` warnings are thrown, increasing the number of maximum iterations might help. Lastly, it can also be worthwhile to try different ODE solvers. Even though the [default solver](@ref default_options) often performs well, every problem is unique. For hard-to-solve models, it can therefore be useful to try solvers like `Rodas5P`, `QNDF`, `TRBDF2`, or `KenCarp4`.

If changing ODE solver settings does not help, something may be wrong with the model structure (e.g., the model may not be coded correctly). However, it should also be kept in mind that some models are just hard to solve/simulate. Therefore, even if many warnings are thrown, a multi-start parameter estimation approach can still sometimes find a set of parameters that fits the data well.

## How do I turn off ODE solver printing?

When performing parameter estimation, as discussed above warnings are thrown when the ODE solver fails to solve the underlying ODE model. By default, we do not disable ODE solver warnings, as it can be beneficial to see them. In particular, if warnings are thrown frequently, it may indicate that something is wrong with the model structure (e.g. the model was not coded correctly) or that a sub-optimal (e.g., non-stiff) ODE solver was chosen when a stiff one should be used. Regardless, when running parameter estimation, it might be preferable not to have the terminal cluttered with warnings. You can turn off the warnings by setting the `verbose = false` option in the `ODESolver`:

```julia
osolver = ODESolver(Rodas5P(); verbose = false)
petab_prob = PEtabODEProblem(model; odesolver = osolver)
```

For which ODE solver to choose when manually setting the `ODESolver`, see [this](@ref default_options) page.

## How do I create a parameter estimation problem for an SBML model?

If your model is in the [SBML](https://sbml.org/) standard format, there are two ways to create a parameter estimation problem:

1. Formulate the problem in the [PEtab](https://petab.readthedocs.io/en/latest/) standard format (recommended). PEtab is a standard format for parameter estimation that assumes the model is in the SBML format. We recommend creating problems in this format, as it allows for the exchange of parameter estimation workflows and is more reproducible. A guide on how to create problems in this standard format can be found [here](https://petab.readthedocs.io/en/latest/), and a tutorial on importing problems can be found [here](@ref import_petab_problem).

2. Import the model as a [Catalyst.jl](https://github.com/SciML/Catalyst.jl) `ReactionSystem` with [SBMLImporter.jl](https://github.com/sebapersson/SBMLImporter.jl) (see the SBMLImporter [documentation](https://sebapersson.github.io/SBMLImporter.jl/stable/) for details). As demonstrated in the starting [tutorial](@ref tutorial), a `ReactionSystem` is one of the model formats that PEtab.jl accepts for creating a parameter estimation problem directly in Julia.
# [Default Options](@id default_options)

PEtab.jl supports several gradient and Hessian computation methods, as well as the ODE solvers available in [OrdinaryDiffEq.jl](https://github.com/SciML/OrdinaryDiffEq.jl). As a result, there are many possible choices when creating a `PEtabODEProblem`. To simplify usage, PEtab.jl has benchmark derived heuristics to select appropriate default options based on the size of the parameter estimation problem. This page discusses these default options when creating a `PEtabODEProblem`.

The default options are based on model size, which is determined by the number of ODEs and the number of parameters to estimate. This is because there is typically no "one-size-fits-all" solution: ODE solvers that perform well for small models may not perform well for large models, and gradient methods that are effective for small models may not be suitable for larger ones. It should also be noted that the defaults are based on benchmarks for stiff biological models. For information on how to configure the `PEtabODEProblem` for models outside of biology, see [this](@ref nonstiff_models) page.

!!! note
    These defaults often work well, but they may not be optimal for every model as each problem is unique.

## Small Models ($\leq 20$ Parameters and $\leq 15$ ODEs)

**ODE solver**: For small stiff models, the Rosenbrock `Rodas5P()` solver is typically the fastest and most accurate. While Julia's BDF solvers like `QNDF()` can perform well, they tend to be less reliable and accurate compared to `Rodas5P()` in this regime.

**Gradient method**: For small models, forward-mode automatic differentiation via [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) is usually the fastest method, often being twice as fast as the forward-sensitivity equations approach. For `:ForwardDiff`, it is possible to set the [chunk size](https://juliadiff.org/ForwardDiff.jl/stable/), which can improve performance. However, determining the optimal value can be challenging, and thus we plan to add automatic tuning.

**Hessian method**: For small models, computing the full Hessian via [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) is often computationally feasible. Benchmarks have shown that using the full Hessian improves convergence.

Overall, for small models, the default configuration is:

```julia
petab_prob = PEtabODEProblem(model; odesolver=ODESolver(Rodas5P()),
                             gradient_method=:ForwardDiff, 
                             hessian_method=:ForwardDiff)
```

!!! note
    If a model has many condition-specific parameters that only appear in a subset of simulation conditions (see [this](@ref define_conditions) tutorial), runtime can be improved by setting `split_over_conditions=true` in the `PEtabODEProblem`. For more details, see [this] example.

## Medium-Sized Models ($\leq 75$ Parameters and $\leq 75$ ODEs)

**ODE solver**: For medium-sized stiff models, multi-step BDF solvers like `QNDF()` are generally fast and accurate [stadter2021benchmarking](@cite). However, they can fail for models with many events when using low tolerances. In such cases, `KenCarp4()` is a reliable alternative.

**Gradient method**: As with small models, the most efficient gradient method for medium-sized models is forward-mode automatic differentiation via [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl).

**Hessian method**: For medium-sized models, computing the full Hessian via [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) is often computationally infeasible. Instead, we recommend the Gauss-Newton Hessian approximation, which in behcmarks frequently outperforms the commonly used (L)-BFGS approximation [frohlich2022fides](@cite).

Overall, for medium models, the default configuration is:

```julia
petab_prob = PEtabODEProblem(model; odesolver=ODESolver(QNDF(), abstol=1e-8, reltol=1e-8),
                             gradient_method=:ForwardDiff, 
                             hessian_method=:GaussNewton)
```

!!! note
    If an optimization algorithm computes both the gradient and Hessian simultaneously, and the Hessian is computed using the Gauss-Newton approximation, it is possible to reuse quantities from gradient computations by setting `gradient_method = :ForwardEquations` and `reuse_sensitivities = true`. For more information, see [this](@ref options_optimizers) page on the Fides optimizer.

## Large Models ($\geq 75$ Parameters and $\geq 75$ ODEs)

While PEtab.jl provides default settings for large models, we recommend benchmarking different methods. This is because selecting the best ODE solver and gradient configuration can substantially impact runtime.

**ODE solver**: For efficiently simulating large models, we recommend benchmarking various ODE solvers designed for large problems, such as `QNDF()`, `FBDF()`, `KenCarp4()`, and `CVODE_BDF()`. Further, we recommend trying a sparse Jacobian (`sparse_jacobian = true`) and testing different linear solvers, such as `CVODE_BDF(linsolve=:KLU)`. For more information on solving large stiff models in Julia, see [this](https://docs.sciml.ai/DiffEqDocs/stable/tutorials/advanced_ode_example/) tutorial.

**Gradient method**: For large models, the most efficient gradient method is adjoint sensitivity analysis (`gradient_method=:Adjoint`). PEtab.jl supports the `InterpolatingAdjoint()`, `GaussAdjoint()`, and `QuadratureAdjoint()` algorithms from SciMLSensitivity.jl. The default is `InterpolatingAdjoint(autojacvec = EnzymeVJP())`, but we strongly recommend benchmarking different adjoint methods and different `autojacvec` options. For further details on adjoint options, see the SciMLSensitivity.jl [documentation](https://docs.sciml.ai/SciMLSensitivity/stable/).

**Hessian method**: For large models, computing sensitivities (Gauss-Newton) or a full Hessian is not computationally feasible. Therefore, using an L-(BFGS) approximation is often the best option. BFGS support is built into most available optimizers such as [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl), [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl), and [Fides.py](https://github.com/fides-dev/fides).

Overall, for large models, the default configuration is:

```julia
petab_prob = PEtabODEProblem(model, odesolver=ODESolver(CVODE_BDF()),
                             gradient_method=:Adjoint,
                             sensealg=InterpolatingAdjoint(autojacvec=EnzymeVJP()))
```

## References

```@bibliography
Pages = ["default_options.md"]
Canonical = false
```
# [Gradient and Hessian Methods](@id gradient_support)

PEtab.jl supports several gradient and Hessian computation methods when creating a `PEtabODEProblem`. This section provides a brief overview of each available method and the corresponding tunable options.

## Gradient Methods

PEtab.jl supports three gradient computation methods: forward-mode automatic differentiation (`:ForwardDiff`), forward-sensitivity equations (`:ForwardEquations`), and adjoint sensitivity analysis (`:Adjoint`). A good introduction to the math behind these methods can be found in [sapienza2024differentiable](@cite), and a good introduction to automatic differentitation can be found in [blondel2024elements](@cite). Below is a brief description of each method.

- `:ForwardDiff`: This method uses [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) to compute the gradient via forward-mode automatic differentiation [revels2016forward](@cite). The only tunable option is the `chunksize` (the number of directional derivatives computed in a single forward pass). While the default `chunksize` is typically a good choice, performance can be slightly improved by tuning this parameter, and we plan to add automatic tuning. This method is often the fastest for smaller models [mester2022differential](@cite).
- `:ForwardEquations`: This method computes the gradient by solving an expanded ODE system to obtain the forward sensitivities during the forward pass. These sensitivities are then used to compute the gradient. The tunable option is `sensealg`, where the default option `sensealg=:ForwardDiff` (compute the sensitivities via forward-mode automatic differentiation) is often the fastest. PEtab.jl also supports the `ForwardSensitivity()` and `ForwardDiffSensitivity()` methods from [SciMLSensitivity.jl](https://github.com/SciML/SciMLSensitivity.jl). For more details and tunable options for these two methods, see the SciMLSensitivity [documentation](https://github.com/SciML/SciMLSensitivity.jl).
- `:Adjoint`: This method computes the gradient via adjoint sensitivity analysis, which involves solving an adjoint ODE backward in time. Several benchmark studies have shown that the adjoint method is the most efficient for larger models [frohlich2017scalable, ma2021comparison](@cite). The tunable option is `sensealg`, which specifies the adjoint algorithm from SciMLSensitivity to use. Available algorithms are `InterpolatingAdjoint`, `GaussAdjoint`, and `QuadratureAdjoint`. For information on their tunable options, see the SciMLSensitivity [documentation](https://github.com/SciML/SciMLSensitivity.jl).

!!! note
    To use functionality from SciMLSensitivity (e.g., adjoint sensitivity analysis), the package must be loaded with `using SciMLSensitivity` before creating the `PEtabODEProblem`.

## Hessian Methods

PEtab.jl supports three Hessian computation methods: forward-mode automatic differentiation (`:ForwardDiff`), a block Hessian approximation (`:BlockForwardDiff`), and the Gauss-Newton Hessian approximation (`:GaussNewton`). Below is a brief description of each method.

`:ForwardDiff`: Thsi method computes the Hessian via forward-mode automatic differentiation using [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl). As with the gradient, the only tunable option is the `chunksize`. This method has quadratic complexity, ``O(n^2)``, where ``n`` is the number of parameters, making it feasible only for models with up to ``n = 20`` parameters. However, when computationally feasible, access to the full Hessian can improve the convergence of parameter estimation runs when doing multi-start parameter estimation.

- `:BlockForwardDiff`: This method computes a block Hessian approximation using forward-mode automatic differentiation with [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl). Specifically, for PEtab problems, there are typically two sets of parameters to estimate: the parameters that are part of the ODE system, ``\\mathbf{x}_p``, and those that are not, ``\\mathbf{x}_q``. This block approach computes the Hessian for each block while approximating the cross-terms as zero:

```math
\mathbf{H}_{block} =
\begin{bmatrix}
\mathbf{H}_{p} & \mathbf{0} \\
\mathbf{0} & \mathbf{H}_q
\end{bmatrix}
```

- `:GaussNewton`: This method approximates the Hessian using the [Gauss-Newton](https://en.wikipedia.org/wiki/Gauss%E2%80%93Newton_algorithm) method. This method often performs better than a (L)-BFGS approximation [frohlich2017scalable](@cite), but requires access to forward sensitivities (similar to `:ForwardEquations` above), and computing these for models with more than 75 parameters is often not computationally feasible. For more details on the computations see [raue2015data2dynamics](@cite). Therefore, for larger models, a (L)-BFGS approximation is often the only feasible option.

## References

```@bibliography
Pages = ["grad_hess_methods.md"]
Canonical = false
```
# [Importing PEtab Standard Format](@id import_petab_problem)

[PEtab](https://petab.readthedocs.io/en/latest/), from which PEtab.jl gets its name, is a flexible, table-based standard format for specifying parameter estimation problems [schmiester2021petab](@cite). If a problem is provided in this standard format, PEtab.jl can import it directly. This tutorial covers how to import PEtab problems.

## Input - a Valid PEtab Problem

To import a PEtab problem, a valid PEtab problem is required. A tutorial on creating a PEtab problem can be found in the PEtab [documentation](https://petab.readthedocs.io/en/latest/), and a [linting tool](https://github.com/PEtab-dev/PEtab/tree/main) is available in Python for checking correctness. Additionally, PEtab.jl performs several format checks when importing the problem.

A collection of valid PEtab problems is also available in the PEtab benchmark [repository](https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab). In this tutorial, we will use an already published model from the PEtab benchmark repository. Specifically, we will consider the STAT5 signaling model, referred to here as the Boehm model (after the first author) [boehm2014identification](@cite). The PEtab files for this model can be found [here](https://github.com/sebapersson/PEtab.jl/tree/main/docs/src/assets/boehm).

## Importing a PEtabModel

A PEtab problem consists of five files: an [SBML](https://sbml.org/) model file, a table with simulation conditions, a table with observables, a table with measurements, and a table with parameters to estimate. These are tied together by a YAML file, and to import a problem, you only need to provide the YAML file path:

```@example 1
using PEtab
# path_yaml depends on where the model is saved
path_yaml = joinpath(@__DIR__, "assets", "boehm", "Boehm_JProteomeRes2014.yaml")
model = PEtabModel(path_yaml)
nothing # hide
```

Given a `PEtabModel`, it is straightforward to create a `PEtabODEProblem`:

```@example 1
petab_prob = PEtabODEProblem(model)
```

As described in the starting [tutorial](@ref tutorial), this `PEtabODEProblem` can then be used for parameter estimation, or Bayesian inference. For tunable options when importing a PEtab problem, see the [API](@ref API) documentation.

## What Happens During PEtab Import (Deep Dive)

When importing a PEtab model, several things happen:

1. The SBML file is converted into a [Catalyst.jl](https://github.com/SciML/Catalyst.jl) `ReactionSystem` using the [SBMLImporter.jl](https://github.com/sebapersson/SBMLImporter.jl) package. This `ReactionSystem` is then converted into an `ODESystem`. During this step, the model is symbolically pre-processed, which includes computing the ODE Jacobian symbolically. The latter typically improves simulation performance.
2. The observable PEtab table is translated into Julia functions that compute observables (`h`), measurement noise (`σ`), and initial values (`u0`).
3. Any potential model events are translated into Julia [callbacks](https://docs.sciml.ai/DiffEqDocs/stable/features/callback_functions/).

All of these steps happen automatically. By setting `write_to_file=true` when importing the model, the generated model functions can be found in the `dir_yaml/Julia_model_files/` directory.

## References

```@bibliography
Pages = ["import_petab.md"]
Canonical = false
```
# PEtab.jl

PEtab.jl is a Julia package for creating parameter estimation problems for fitting Ordinary Differential Equation (ODE) models to data in Julia.

## Major highlights

* Support for coding parameter estimation problems directly in Julia, where the dynamic model can be provided as a [Catalyst.jl](https://github.com/SciML/Catalyst.jl) `ReactionSystem`, a [ModelingToolkit.jl](https://github.com/SciML/ModelingToolkit.jl) `ODESystem`, or as an [SBML](https://sbml.org/) file imported via [SBMLImporter.jl](https://github.com/sebapersson/SBMLImporter.jl).
* Direct import and full support for parameter estimation problems in the [PEtab](https://petab.readthedocs.io/en/latest/) standard format
* Support for a wide range of parameter estimation problem features, including multiple observables, multiple simulation conditions, models with events, and models with steady-state pre-equilibration simulations.
* Integration with Julia's [DifferentialEquations.jl](https://docs.sciml.ai/DiffEqDocs/stable/) ecosystem, which, among other things, means PEtab.jl supports the state-of-the-art ODE solvers in [OrdinaryDiffEq.jl](https://github.com/SciML/OrdinaryDiffEq.jl). Consequently, PEtab.jl is suitable for both stiff and non-stiff ODE models.
* Support for efficient forward and adjoint gradient methods, suitable for small and large models, respectively.
* Support for exact Hessian's for small models and good approximations for large models.
* Includes wrappers for performing parameter estimation with optimization packages [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl), [Ipopt](https://coin-or.github.io/Ipopt/), [Optimization.jl](https://github.com/SciML/Optimization.jl), and [Fides.py](https://github.com/fides-dev/fides).
* Includes wrappers for performing Bayesian inference with the state-of-the-art NUTS sampler (the same sampler used in [Turing.jl](https://github.com/TuringLang/Turing.jl)) or with [AdaptiveMCMC.jl](https://github.com/mvihola/AdaptiveMCMC.jl).

!!! note "Star us on GitHub!"
    If you find the package useful in your work please consider giving us a star on [GitHub](https://github.com/sebapersson/PEtab.jl). This will help us secure funding in the future to continue maintaining the package.

!!! tip "Latest news: PEtab.jl v3.0"
    Version 3.0 is a breaking release that added support for ModelingToolkit v9 and Catalyst v14. Along with updating these packages, PEtab.jl underwent a major update, with new functionality added as well as the renaming of several functions to be more consistent with the naming convention in the SciML ecosystem. See the [HISTORY](https://github.com/sebapersson/PEtab.jl/blob/main/HISTORY.md) file for more details.

## Installation

To install PEtab.jl in the Julia REPL enter

```julia
julia> ] add PEtab
```

or alternatively

```julia
julia> using Pkg; Pkg.add("PEtab")
```

PEtab is compatible with Julia version 1.9 and above. For best performance we strongly recommend using the latest Julia version, which most easily can be installed with [juliaup](https://github.com/JuliaLang/juliaup).

## Getting help

If you have any problems using PEtab, here are some helpful tips:

* Read the [FAQ](@ref FAQ) section in the online documentation.
* Post your questions in the `#sciml-sysbio` channel on the [Julia Slack](https://julialang.org/slack/). While PEtab.jl is not exclusively for systems biology, the `#sciml-sysbio` channel is where the package authors are most active.
* If you have encountered unexpected behavior or a bug, please open an issue on [GitHub](https://github.com/sebapersson/PEtab.jl/issues).
# Bayesian Inference

When performing parameter estimation for a model with PEtab.jl, the unknown model parameters are estimated within a frequentist framework, where the goal is to find the maximum likelihood estimate. When prior knowledge about the parameters is available, Bayesian inference offers an alternative approach to fitting a model to data. The aim of Bayesian inference is to infer the posterior distribution of unknown parameters given the data, $\pi(\mathbf{x} \mid \mathbf{y})$, by running a Markov chain Monte Carlo (MCMC) algorithm to sample from the posterior. A major challenge, aside from creating a good model, is to effectively sample the posterior. PEtab.jl supports Bayesian inference via two packages that implement different sampling algorithms:

- **Adaptive Metropolis Hastings Samplers** available in [AdaptiveMCMC.jl](https://github.com/mvihola/AdaptiveMCMC.jl) [vihola2014ergonomic](@cite).
- **Hamiltonian Monte Carlo (HMC) Samplers** available in [AdvancedHMC.jl](https://github.com/TuringLang/AdvancedHMC.jl). The default HMC sampler is the NUTS sampler, which is the default in Stan [hoffman2014no, carpenter2017stan](@cite). HMC samplers are often efficient for continuous targets (models with non-discrete parameters).

This tutorial covers how to create a `PEtabODEProblem` with priors and how to use [AdaptiveMCMC.jl](https://github.com/mvihola/AdaptiveMCMC.jl) and [AdvancedHMC.jl](https://github.com/TuringLang/AdvancedHMC.jl) for Bayesian inference. It should be noted that this part of PEtab.jl is planned to be moved to a separate package, so the syntax will change and be made more user-friendly in the future.

!!! note
    To use the Bayesian inference functionality in PEtab.jl, the Bijectors.jl, LogDensityProblems.jl, and LogDensityProblemsAD.jl packages must be loaded.

## Creating a Bayesian Inference Problem

If a PEtab problem is in the PEtab standard format, priors are defined in the [parameter table](https://petab.readthedocs.io/en/latest/documentation_data_format.html#parameter-table). Here, we focus on the case when the model is defined directly in Julia, using a simple saturated growth model. First, we create the model and simulate some data:

```@example 1
using Distributions, ModelingToolkit, OrdinaryDiffEq, Plots
using ModelingToolkit: t_nounits as t, D_nounits as D
@mtkmodel SYS begin
    @parameters begin
        b1
        b2
    end
    @variables begin
        x(t) = 0.0
    end
    @equations begin
        D(x) ~ b2 * (b1 - x)
    end
end
@mtkbuild sys = SYS()

# Simulate data with normal measurement noise and σ = 0.03
import Random # hide
Random.seed!(1234) # hide
oprob = ODEProblem(sys, [0.0], (0.0, 2.5), [1.0, 0.2])
tsave = range(0.0, 2.5, 101)
dist = Normal(0.0, 0.03)
sol = solve(oprob, Rodas4(), abstol=1e-12, reltol=1e-12, saveat=tsave)
obs = sol[:x] .+ rand(Normal(0.0, 0.03), length(tsave))
default(left_margin=12.5Plots.Measures.mm, bottom_margin=12.5Plots.Measures.mm, size = (600*1.25, 400 * 1.25), palette = ["#CC79A7", "#009E73", "#0072B2", "#D55E00", "#999999", "#E69F00", "#56B4E9", "#F0E442"], linewidth=2.0) # hide
plot(sol.t, obs, seriestype=:scatter, title = "Observed data")
```

Given this, we can now create a `PEtabODEProblem` (for an introduction, see the starting [tutorial](@ref tutorial)):

```@example 1
using DataFrames, PEtab
measurements = DataFrame(obs_id="obs_X", time=sol.t, measurement=obs)
@parameters sigma
obs_X = PEtabObservable(:x, sigma)
observables = Dict("obs_X" => obs_X)
nothing # hide
```

When defining parameters to estimate via `PEtabParameter`, a prior can be assigned using any continuous distribution available in [Distributions.jl](https://github.com/JuliaStats/Distributions.jl). For instance, we can set the following priors:

- `b_1`: Uniform distribution between 0.0 and 5.0; `Uniform(0.0, 5.0)`.
- `log10_b2`: Uniform distribution between -6.0 and log10(5.0); `Uniform(-6.0, log10(5.0))`.
- `sigma`: Gamma distribution with shape and rate parameters both set to 1.0, `Gamma(1.0, 1.0)`.

Using the following code:

```@example 1
p_b1 = PEtabParameter(:b1, value=1.0, lb=0.0, ub=5.0, scale=:log10, prior_on_linear_scale=true, prior=Uniform(0.0, 5.0))
p_b2 = PEtabParameter(:b2, value=0.2, scale=:log10, prior_on_linear_scale=false, prior=Uniform(-6, log10(5.0)))
p_sigma = PEtabParameter(:sigma, value=0.03, lb=1e-3, ub=1e2, scale=:lin, prior_on_linear_scale=true, prior=Gamma(1.0, 1.0))
pest = [p_b1, p_b2, p_sigma]
```

When specifying priors, it is important to keep in mind the parameter scale (where `log10` is the default). In particular, when `prior_on_linear_scale=false`, the prior applies to the parameter scale, so for `b2` above, the prior is on the `log10` scale. If `prior_on_linear_scale=true` (the default), the prior is on the linear scale, which applies to `b1` and `sigma` above. If a prior is not specified, the default prior is a Uniform distribution on the parameter scale, with bounds corresponding to the upper and lower bounds specified for the `PEtabParameter`. With these priors, we can now create the `PEtabODEProblem`.

```@example 1
osolver = ODESolver(Rodas5P(), abstol=1e-6, reltol=1e-6)
model = PEtabModel(sys, observables, measurements, pest)
petab_prob = PEtabODEProblem(model; odesolver=osolver)
```

## Bayesian Inference (General Setup)

The first step in in order to run Bayesian inference is to construct a `PEtabLogDensity`. This structure supports the [LogDensityProblems.jl](https://github.com/tpapp/LogDensityProblems.jl) interface, meaning it contains all the necessary methods for running Bayesian inference:

```@example 1
using Bijectors, LogDensityProblems, LogDensityProblemsAD
target = PEtabLogDensity(petab_prob)
```

When performing Bayesian inference, the settings for the ODE solver and gradient computations are those specified in `petab_prob`. In this case, we use the default gradient method (`ForwardDiff`) and simulate the ODE model using the `Rodas5P` ODE solver.

One important consideration before running Bayesian inference is the starting point. For simplicity, we here use the parameter vector that was used for simulating the data, but note that typically inference should be performed using at least four chains from different starting points [gelman2020bayesian](@cite):

```@example 1
x = get_x(petab_prob)
nothing # hide
```

Lastly, when performing Bayesian inference with PEtab.jl, it is **important** to note that inference is performed on the prior scale. For instance, if a parameter has `scale=:log10`, but the prior is defined on the linear scale (`prior_on_linear_scale=true`), inference is performed on the linear scale. Additionally, Bayesian inference algorithms typically prefer to operate in an unconstrained space, so a bounded prior like `Uniform(0.0, 5.0)` is not ideal. To address this, bounded parameters are [transformed](https://mc-stan.org/docs/reference-manual/change-of-variables.html) to be unconstrained.

In summary, for a parameter vector on the PEtab parameter scale (`x`), for inference we must transform to the prior scale (`xprior`), and then to the inference scale (`xinference`). This can be done via:

```@example 1
xprior = to_prior_scale(petab_prob.xnominal_transformed, target)
xinference = target.inference_info.bijectors(xprior)
```

!!! warn
    To get correct inference results, it is important that the starting value is on the transformed parameter scale (as `xinference` above).

## Bayesian inference with AdvancedHMC.jl (NUTS)

Given a starting point we can run the NUTS sampler with 2000 samples, and 1000 adaptation steps:

```@example 1
using AdvancedHMC
# δ=0.8 - acceptance rate (default in Stan)
sampler = NUTS(0.8)
Random.seed!(1234) # hide
res = sample(target, sampler, 2000; n_adapts = 1000, initial_params = xinference, 
             drop_warmup=true, progress=false)
nothing #hide
```

Any other algorithm found in AdvancedHMC.jl [documentation](https://github.com/TuringLang/AdvancedHMC.jl) can also be used. To get the output in an easy to interact with format, we can convert it to a [MCMCChains](https://github.com/TuringLang/MCMCChains.jl)

```@example 1
using MCMCChains
chain_hmc = PEtab.to_chains(res, target)
```

which we can also plot:

```@example 1
using Plots, StatsPlots
plot(chain_hmc)
```

!!! note
    When converting the output to a `MCMCChains` the parameters are transformed to the prior-scale (inference scale).

## Bayesian inference with AdaptiveMCMC.jl

Given a starting point we can run the robust adaptive MCMC sampler for $100 \, 000$ iterations with:

```@example 1
using AdaptiveMCMC
Random.seed!(123) # hide
# target.logtarget = posterior logdensity
res = adaptive_rwm(xinference, target.logtarget, 100000; progress=false)
nothing #hide
```

and we can convert the output to a `MCMCChains`

```@example 1
chain_adapt = to_chains(res, target)
plot(chain_adapt)
```

Any other algorithm found in AdaptiveMCMC.jl [documentation](https://github.com/mvihola/AdaptiveMCMC.jl) can also be used.

## References

```@bibliography
Pages = ["inference.md"]
Canonical = false
```
# [Non-Biology (Non-Stiff) Models](@id nonstiff_models)

The default options when creating a `PEtabODEProblem` in PEtab.jl are based on extensive benchmarks for dynamic models in biology. A key feature of ODEs in biology is that they are often stiff [stadter2021benchmarking](@cite). While an exact definition of stiffness is elusive, informally, explicit (non-stiff) solvers struggle to efficiently solve stiff models. The degree of stiffness does not impact the choice of the optimal gradient method, as this depends on the number of parameters to estimate rather than the ODE solver. Therefore, using the [default](@ref default_options) gradient method in PEtab.jl is often a good choice. However, for non-stiff models, using a different ODE solver than the default in PEtab.jl can drastically reduce runtime.

If a problem is non-stiff, it is much more computationally efficient to use an explicit (non-stiff) solver, as a non-linear system does not need to be solved at each iteration. However, choosing a purely explicit (non-stiff) solver is often not ideal. When performing multi-start parameter estimation using random initial points, benchmarks have shown that even if the model is non-stiff around the best parameter values, this may not hold for random parameter values. Therefore, for non-stiff (or mildly stiff) models, a good compromise is to use composite solvers that can automatically switch between a stiff and non-stiff solver. Therefore, a good setup often is:

```julia
petab_prob = PEtabODEProblem(model; odesolver=ODESolver(AutoVern7(Rodas5P())))
```

This ODE solver automatically switches between solvers based on stiffness. For more details on non-stiff solver choices, as well as composite solvers, see the [documentation](https://docs.sciml.ai/DiffEqDocs/stable/solvers/ode_solve/) for OrdinaryDiffEq.jl.

## References

```@bibliography
Pages = ["nonstiff_models.md"]
Canonical = false
```
# [Available and Recommended Optimization Algorithms](@id options_optimizers)

For the `calibrate` and `calibrate_multistart` functions, PEtab.jl supports optimization algorithms from several popular optimization packages: [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl), [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl), and [Fides.py](https://github.com/fides-dev/fides). This page provides information on each package, as well as recommendations.

## Recommended Optimization Algorithm

When choosing an optimization algorithm, it is important to keep the **no free lunch** principle in mind: while an algorithm may work well for one problem, there is no universally best method. Nevertheless, benchmark studies have identified algorithms that often perform well for ODE models in biology (and likely beyond) [raue2013lessons, hass2019benchmark, villaverde2019benchmarking](@cite). In particular, the best algorithm to use depends on the size of the parameter estimation problem. This is because the problem considered here is a non-linear continuous optimization problem, and for such problems, having access to a good Hessian approximation improves performance. And, the problem size dictates which type of Hessian approximation can be computed (see this [page](@ref gradient_support) for more details). Following this, we recommend:

- For **small** models (fewer than 10 ODEs and fewer than 20 parameters to estimate) where computing the Hessian is often computationally feasible, the `IPNewton()` method from Optim.jl.
- For **medium sized** models (roughly more than 10 ODEs and fewer than 75 parameters), where a Gauss-Newton Hessian can be computed, Fides. The Gauss-Newton Hessian approximation typically outperforms the more common (L)-BFGS approximation, and benchmarks have shown that Fides performs well with such a Hessian approximation [frohlich2022fides](@cite). If Fides is difficult to install, `Optim.BFGS` also performs well.
- For **large** models (more than 20 ODEs and more than 75 parameters to estimate), where a Gauss-Newton approximation is too computationally expensive, a (L)-BFGS optimizer is recommended, such as Ipopt or `Optim.BFGS`.

## [Optim.jl](@id Optim_alg)

PEtab.jl supports three optimization algorithms from [Optim.jl](https://julianlsolvers.github.io/Optim.jl/stable/): `LBFGS`, `BFGS`, and `IPNewton` (Interior-point Newton). Options for these algorithms can be specified via `Optim.Options()`, and a complete list of options can be found [here](https://julianlsolvers.github.io/Optim.jl/v0.9.3/user/config/). For example, to use `LBFGS` with 10,000 iterations, do:

```julia
using Optim
res = calibrate(petab_prob, x0, Optim.LBFGS();
                options=Optim.Options(iterations = 10000))
```

If no options are provided, the default ones are used:

```julia
Optim.Options(iterations = 1000,
              show_trace = false,
              allow_f_increases = true,
              successive_f_tol = 3,
              f_tol = 1e-8,
              g_tol = 1e-6,
              x_tol = 0.0)
```

For more details on each algorithm and tunable options, see the Optim.jl [documentation](https://julianlsolvers.github.io/Optim.jl/stable/).

## Ipopt

[Ipopt](https://coin-or.github.io/Ipopt/) is an Interior-point Newton method for nonlinear optimization [wachter2006implementation](@cite). In PEtab.jl, Ipopt can be configured to either use the Hessian from the `PEtabODEProblem` or a LBFGS Hessian approximation through the `IpoptOptimizer`:

```@docs; canonical=false
IpoptOptimizer
```

Ipopt offers a wide range of options (perhaps too many, in the words of the authors). A subset of these options can be specified using `IpoptOptions`:

```@docs; canonical=false
IpoptOptions
```

For example, to use Ipopt with 10,000 iterations and the LBFGS Hessian approximation, do:

```julia
using Ipopt
res = calibrate(petab_prob, x0, IpoptOptimizer(true); 
                options=IpoptOptions(max_iter = 10000))
```

For more information on Ipopt and its available options, see the Ipopt [documentation](https://coin-or.github.io/Ipopt/) and the original publication [wachter2006implementation](@cite).

!!! note
    To use Ipopt, the [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl) package must be loaded with `using Ipopt` before running parameter estimation.

## Fides

[Fides.py](https://github.com/fides-dev/fides) is a trust-region Newton method designed for box-constrained optimization problems [frohlich2022fides](@cite). It is particularly efficient when the Hessian is approximated using the [Gauss-Newton](https://en.wikipedia.org/wiki/Gauss%E2%80%93Newton_algorithm) method.

The only drawback with Fides is that it is a Python package, but fortunately, it can be used from PEtab.jl through PyCall. To this end, you must build PyCall with a Python environment that has Fides installed:

```julia
using PyCall
# Path to Python executable with Fides installed
path_python_exe = "path_python"
ENV["PYTHON"] = path_python_exe
# Build PyCall with the Fides Python environment
import Pkg
Pkg.build("PyCall")
```

Fides supports several Hessian approximations, which can be specified in the `Fides` constructor:

```@docs; canonical=false
Fides
```

A notable feature of Fides is that in each optimization step, the objective, gradient, and Hessian are computed simultaneously. This opens up the possibility for efficient reuse of computed quantities, especially when the Hessian is computed via the Gauss-Newton approximation. Because, to compute the Gauss-Newton Hessian the forward sensitivities are used, which can also be used to compute the gradient. Hence, a good `PEtabODEProblem` configuration for Fides with Gauss-Newton is:

```julia
petab_prob = PEtabODEProblem(model; gradient_method = :ForwardEquations, 
                             hessian_method = :GaussNewton,
                             reuse_sensitivities = true)
```

Given this setup, the Hessian method from the `PEtabODEProblem` can be used to run Fides for 200 iterations with:

```julia
using PyCall
res = calibrate(petab_prob, x0, Fides(nothing);
                options=py"{'maxiter' : 1000}")
```

As noted above, for Fides options are specified using a Python dictionary. Available options and their default values can be found in the Fides [documentation](https://fides-optimizer.readthedocs.io/en/latest/generated/fides.constants.html), and more information on the algorithm can be found in the original publication [frohlich2022fides](@cite).

## References

```@bibliography
Pages = ["pest_algs.md"]
Canonical = false
```
# [Wrapping Optimization Packages](@id wrap_est)

A `PEtabODEProblem` contains all the necessary information for wrapping a suitable optimizer to estimate model parameters. Since wrapping a package can be cumbersome, PEtab.jl provides wrappers for performing single-start parameter estimation (with [`calibrate`](@ref)) and multi-start parameter estimation (with [`calibrate_multistart`](@ref)). More details can be found in [this](@ref pest_methods) tutorial. Still, in some cases, it may be necessary to manually wrap one of the optimization packages not supported by PEtab.jl.

This tutorial show how to wrap an existing optimization package, using the `IPNewton` method from [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl) as an example. As a working example, we use the Michaelis-Menten enzyme kinetics model from the starting [tutorial](@ref tutorial). Even though the code below provides the model as a `ReactionSystem`, everything works exactly the same if the model is provided as an `ODESystem`.

```@example 1
using Catalyst, PEtab

# Create the dynamic model
t = default_t()
rn = @reaction_network begin
    @parameters S0 c3=1.0
    @species S(t)=S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end
speciemap = [:E => 50.0, :SE => 0.0, :P => 0.0]

# Observables
@unpack E, S = rn
obs_sum = PEtabObservable(S + E, 3.0)
@unpack P = rn
@parameters sigma
obs_p = PEtabObservable(P, sigma)
observables = Dict("obs_p" => obs_p, "obs_sum" => obs_sum)

# Parameters to estimate
p_c1 = PEtabParameter(:c1)
p_c2 = PEtabParameter(:c2)
p_s0 = PEtabParameter(:S0)
p_sigma = PEtabParameter(:sigma)
pest = [p_c1, p_c2, p_s0, p_sigma]

# Simulate measurement data with 'true' parameters
using OrdinaryDiffEq, DataFrames
ps = [:c1 => 1.0, :c2 => 10.0, :c3 => 1.0, :S0 => 100.0]
u0 = [:S => 100.0, :E => 50.0, :SE => 0.0, :P => 0.0]
tspan = (0.0, 10.0)
oprob = ODEProblem(rn, u0, tspan, ps)
sol = solve(oprob, Rodas5P(); saveat = 0:0.5:10.0)
obs_sum = (sol[:S] + sol[:E]) .+ randn(length(sol[:E]))
obs_p = sol[:P] + .+ randn(length(sol[:P]))
df_sum = DataFrame(obs_id = "obs_sum", time = sol.t, measurement = obs_sum)
df_p = DataFrame(obs_id = "obs_p", time = sol.t, measurement = obs_p)
measurements = vcat(df_sum, df_p)

model = PEtabModel(rn, observables, measurements, pest; speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
nothing # hide
```

## Extracting Relevant Input from a PEtabODEProblem

A numerical optimizer requires an objective function, and derivative-based methods also need a gradient function and, in some cases, a Hessian function. Following the [PEtab standard](https://petab.readthedocs.io/en/latest/), PEtab.jl works with likelihoods, so the objective function corresponds to the negative log-likelihood (`nllh`), which can be accessed with:

```@example 1
x = get_x(petab_prob)
nllh = petab_prob.nllh(x; prior = true)
```

Here, the keyword argument `prior = true` (default) ensures that potential parameter priors are considered when computing the likelihood. Furthermore, the `PEtabODEProblem` provides both in-place and out-of-place gradient functions:

```@example 1
g_inplace = similar(x)
petab_prob.grad!(g_inplace, x; prior = true)
g_outplace = petab_prob.grad(x)
```

as well as in-place and out-of-place Hessian functions:

```@example 1
h_inplace = zeros(length(x), length(x))
petab_prob.hess!(h_inplace, x; prior = true)
h_outplace = petab_prob.hess(x)
```

In the above cases, the input parameter vector is a `ComponentArray`, but a `Vector` input is also accepted, and in this case, the gradient functions will also output a `Vector`. Additionally, the gradients and Hessians are computed using the default methods in the `PEtabODEProblem` (for more details, see [this](@ref default_options) page).

Lastly, for parameter estimation with ODE models, it is often useful to set parameter bounds. Because, without bounds, the optimization algorithm can explore regions where the ODE solver fails to solve the model which prolongs runtime [frohlich2022fides](@cite). The bounds can be accessed via:

```@example 1
lb, ub = petab_prob.lower_bounds, petab_prob.upper_bounds
nothing # hide
```

Both `lb` and `ub` are `ComponentArray`s. If an optimization package does not support `ComponentArray` (as in the example below), they can be converted to a `Vector` by calling `collect`.

## Wrapping Optim.jl IPNewton

From the Optim.jl [documentation](https://julianlsolvers.github.io/Optim.jl/stable/), we can see that in order to use the `IPNewton` method, we need to provide the objective, gradient, Hessian, and parameter bounds, where the latter are provided as vectors. Using the information outlined above, we can do:

```@example 1
using Optim
x0 = collect(get_x(petab_prob))
df = TwiceDifferentiable(petab_prob.nllh, petab_prob.grad!, petab_prob.hess!, x0)
dfc = TwiceDifferentiableConstraints(collect(lb), collect(ub))
nothing # hide
```

Note that we convert any `ComponentArray` to a `Vector` with `collect`. Given this, we can perform parameter estimation with `x0` as the starting point:

```@example 1
res = Optim.optimize(df, dfc, x0, IPNewton())
```

## References

```@bibliography
Pages = ["pest_custom.md"]
Canonical = false
```
```@meta
CollapsedDocStrings=true
```

# [Parameter Estimation Methods](@id pest_methods)

The main function of PEtab.jl is to create parameter estimation problems and provide runtime-efficient gradient and Hessian functions for estimating unknown model parameters using suitable numerical optimization algorithms. Specifically, the parameter estimation problems considered by PEtab.jl are on the form:

```math
\min_{\mathbf{x} \in \mathbb{R}^N} -\ell(\mathbf{x}), \quad \text{subject to} \\
\mathbf{lb} \leq \mathbf{x} \leq \mathbf{ub}
```

Where, since PEtab.jl works with likelihoods (see the [API](@ref API) documentation on `PEtabObservable`), $-\ell(\mathbf{x})$ is a negative log-likelihood, and $\mathbf{lb}$ and $\mathbf{ub}$ are the lower and upper parameter bounds. For a good introduction to parameter estimation for ODE models in biology (which is applicable to other fields as well), see [villaverde2022protocol](@cite).

This advanced section of the documentation focuses on PEtab.jl's parameter estimation functionality, and before reading this part, we recommended the starting [tutorial](@ref tutorial). Specifically, this section of the documentation covers available and recommended optimization algorithms, how to plot optimization results, and how to perform automatic model selection. First though, it covers how to perform parameter estimation. While the `PEtabODEProblem` contains all the necessary information for wrapping a suitable optimizer to solve the problem (see [here](@ref wrap_est)), manually wrapping optimizers is cumbersome. Therefore, PEtab.jl provides convenient wrappers for:

- Single-start parameter estimation
- Multi-start parameter estimation
- Creating an `OptimizationProblem` to access the solvers in [Optimization.jl](https://github.com/SciML/Optimization.jl)

As a working example, we use the Michaelis-Menten enzyme kinetics model from the starting [tutorial](@ref tutorial). Even though the code below presents the model as a `ReactionSystem`, everything works the same if the model is provided as an `ODESystem`.

```@example 1
using Catalyst, PEtab

# Create the dynamic model
t = default_t()
rn = @reaction_network begin
    @parameters S0 c3=1.0
    @species S(t)=S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end
speciemap = [:E => 50.0, :SE => 0.0, :P => 0.0]

# Observables
@unpack E, S = rn
obs_sum = PEtabObservable(S + E, 3.0)
@unpack P = rn
@parameters sigma
obs_p = PEtabObservable(P, sigma)
observables = Dict("obs_p" => obs_p, "obs_sum" => obs_sum)

# Parameters to estimate
p_c1 = PEtabParameter(:c1)
p_c2 = PEtabParameter(:c2)
p_s0 = PEtabParameter(:S0)
p_sigma = PEtabParameter(:sigma)
pest = [p_c1, p_c2, p_s0, p_sigma]

# Simulate measurement data with 'true' parameters
using OrdinaryDiffEq, DataFrames
ps = [:c1 => 1.0, :c2 => 10.0, :c3 => 1.0, :S0 => 100.0]
u0 = [:S => 100.0, :E => 50.0, :SE => 0.0, :P => 0.0]
tspan = (0.0, 10.0)
oprob = ODEProblem(rn, u0, tspan, ps)
sol = solve(oprob, Rodas5P(); saveat = 0:0.5:10.0)
obs_sum = (sol[:S] + sol[:E]) .+ randn(length(sol[:E]))
obs_p = sol[:P] + .+ randn(length(sol[:P]))
df_sum = DataFrame(obs_id = "obs_sum", time = sol.t, measurement = obs_sum)
df_p = DataFrame(obs_id = "obs_p", time = sol.t, measurement = obs_p)
measurements = vcat(df_sum, df_p)

model = PEtabModel(rn, observables, measurements, pest; speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
nothing # hide
```

## Single-Start Parameter Estimation

Single-start parameter estimation is an approach where a numerical optimization algorithm is run from a starting point `x0` until it hopefully reaches a local minimum. When performing parameter estimation, the objective function generated by a `PEtabODEProblem` expects the parameters to be in a specific order. The most straightforward way to obtain a correctly ordered vector is via the `get_x` function:

```@docs; canonical=false
get_x
```

For our working example, we have:

```@example 1
x0 = get_x(petab_prob)
```

As discussed in the starting tutorial, `x0` is a `ComponentArray`, meaning it holds both parameter values and names. Additionally, parameters like `c1` have a `log10` prefix, as the parameter (by default) is estimated on the `log10` scale, which typically improves performance [raue2013lessons, hass2019benchmark](@cite). Interacting with a `ComponentArray` is straightforward, for example, to change `c1` to `10.0` do:

```@example 1
x0.log10_c1 = log10(10.0)
nothing # hide
```

or alteratively:

```@example 1
x0[:log10_c1] = log10(10.0)
nothing # hide
```

!!! note
    When setting values in the starting point vector `x0`, the new value should be provided on the parameter's scale, which is `log10` by default.

Given a starting point, parameter estimation can be performed with the `calibrate` function:

```@docs; canonical=false
calibrate
```

For information and recommendations on algorithms (`alg`), see [this](@ref options_optimizers) page. For our working example, following the recommendations, we use Optim.jl's Interior-Point Newton method (`IPNewton`):

```@example 1
using Optim
res = calibrate(petab_prob, x0, IPNewton())
```

The result from `calibrate` is returned as a `PEtabOptimisationResult` which holds the relevant statistics from the optimization:

```@docs; canonical=false
PEtabOptimisationResult
```

The result from `calibrate` can also be plotted. For example, to see how well the model fits the data, the fit can be plotted as:

```@example 1
using Plots
default(left_margin=12.5Plots.Measures.mm, bottom_margin=12.5Plots.Measures.mm, size = (600*1.25, 400 * 1.25), palette = ["#CC79A7", "#009E73", "#0072B2", "#D55E00", "#999999", "#E69F00", "#56B4E9", "#F0E442"], linewidth=4.0) # hide
plot(res, petab_prob)
```

Information on other available plots can be found on [this](@ref optimization_output_plotting) page. Now, even though the plot above may look good, it is important to remember that the objective function ($-\ell$ above) often has multiple local minima. To ensure the global optimum is found, a global optimization approach is needed. One effective global method is multi-start parameter estimation.

## [Multi-Start Parameter Estimation](@id multistart_est)

Multi-start parameter estimation is an approach where `n` parameter estimation runs are initiated from `n` random starting points. The rationale is that a subset of these runs should, hopefully, converge to the global optimum. While simple, empirical benchmark studies have shown that this method performs well for ODE models in biology [raue2013lessons, raue2013lessons](@cite).

The first step for multi-start parameter estimation is to generate `n` starting points. While random uniform sampling may initially seem like a good approach, random points tend to cluster. Instead, it's better to use a [Quasi-Monte Carlo](https://en.wikipedia.org/wiki/Quasi-Monte_Carlo_method) method, such as [Latin hypercube sampling](https://en.wikipedia.org/wiki/Latin_hypercube_sampling), to generate more spread-out starting points. This approach has been shown to improve performance [raue2013lessons](@cite). The difference can quite clearly be seen generating 100 random points and 50 Latin hypercube-sampled points on the plane.

```@example 1
using Distributions, QuasiMonteCarlo, Plots
import Random # hide
Random.seed!(123) # hide
s1 = QuasiMonteCarlo.sample(100, [-1.0, -1.0], [1.0, 1.0], Uniform())
s2 = QuasiMonteCarlo.sample(100, [-1.0, -1.0], [1.0, 1.0], LatinHypercubeSample())
p1 = plot(s1[1, :], s1[2, :], title = "Uniform sampling", seriestype=:scatter)
p2 = plot(s2[1, :], s2[2, :], title = "Latin Hypercube Sampling", seriestype=:scatter)
p1 = plot(s1[1, :], s1[2, :], title = "Uniform sampling", seriestype=:scatter, label = false) # hide
p2 = plot(s2[1, :], s2[2, :], title = "Latin Hypercube Sampling", seriestype=:scatter, label = false) # hide
plot(p1, p2)
plot(p1, p2; size = (800, 400)) # hide
```

For a `PEtabODEProblem`, Latin hypercube sampled points within the parameter bounds can be generated with the `get_startguesses` function:

```@docs; canonical=false
get_startguesses
```

For our working example, we can generate 50 starting guesses with:

```@example 1
import Random # hide
Random.seed!(123) # hide
x0s = get_startguesses(petab_prob, 50)
nothing # hide
```

In principle, `x0s` can now be used together with `calibrate` to perform multi-start parameter estimation. But, to further simplify this process, PEtab.jl provides a convenient function, `calibrate_multistart`, which combines start-guess generation and parameter estimation in one step:

```@docs; canonical=false
calibrate_multistart
```

Two important keyword arguments for `calibrate_multistart` are `dirsave` and `nprocs`. If `nprocs > 1`, the parameter estimation runs are performed in parallel using the [`pmap`](https://docs.julialang.org/en/v1/stdlib/Distributed/#Distributed.pmap) function from Distributed.jl with `nprocs` processes. Even though `pmap` introduces some overhead because it must load and compile the code on each process, setting `nprocs > 1` often reduces runtime when the parameter estimation is expected to take longer than 5 minutes. Meanwhile, `dirsave` specifies an optional directory to continuously save the results from each individual run. We **strongly recommend** providing such a directory, as parameter estimation for larger models can take hours or even days. If something goes wrong with the computer during that time, it is, to put it mildly, frustrating to lose all the results. For our working example, we can perform 50 multistarts in parallel on two processes with:

```@example 1
ms_res = calibrate_multistart(petab_prob, IPNewton(), 50; nprocs = 2,
                              dirsave="path_to_save_directory")
```

The results are returned as a `PEtabMultistartResult`, which, in addition to printout statistics, contains relevant information for each run:

```@docs; canonical=false
PEtabMultistartResult
```

Finally, a common approach to evaluate the result of multi-start parameter estimation is through plotting. One widely used evaluation plot is the waterfall plot, which shows the final objective values for each run:

```@example 1
plot(ms_res; plot_type=:waterfall)
```

In the waterfall plot, each plateau corresponds to different local optima (represented by different colors). Since many runs (dots) are found on the plateau with the smallest objective value, we can be confident that the global optimum has been found. In addition to waterfall plots, more plotting options can be found on [this](@ref optimization_output_plotting) page.

## Creating an OptimizationProblem

[Optimization.jl](https://github.com/SciML/Optimization.jl) is a Julia package that provides a unified interface for over 100 optimization algorithms (see their [documentation](https://docs.sciml.ai/Optimization/stable/) for the complete list). While Optimization.jl is undoubtedly useful, it is currently undergoing heavy updates, so at the moment we do not recommend it as the default choice for parameter estimation.

The central object in Optimization.jl is the `OptimizationProblem`, and PEtab.jl directly supports converting a `PEtabODEProblem` into an `OptimizationProblem`:

```@docs; canonical=false
PEtab.OptimizationProblem
```

For our working example, we can create an `OptimizationProblem` with:

```@example 1
using Optimization
opt_prob = OptimizationProblem(petab_prob)
```

Given a start-guess `x0`, we can then estimate the parameters using, for example, Optim.jl's `ParticleSwarm()` method, with:

```@example 1
using OptimizationOptimJL
opt_prob.u0 .= x0
res = solve(opt_prob, Optim.ParticleSwarm())
```

which returns an `OptimizationSolution`. For more information on options and how to interact with `OptimizationSolution`, see the Optimization.jl [documentation](https://docs.sciml.ai/Optimization/stable/).

## References

```@bibliography
Pages = ["pest_method.md"]
Canonical = false
```
# [Plots Evaluating Parameter Estimation](@id optimization_output_plotting)

Following parameter estimation, it is prudent to evaluate the estimation results. The most straightforward approach is to simulate the model with the estimated parameters and inspect the fit. While informative, this kind of plot does not help determine whether:

- There are unfound parameter sets that yield better fits than those found (indicating that a local minimum was reached).
- There are additional parameter sets yielding equally good fits to those found (suggesting a *parameter identifiability* problem).

This page demonstrates various plots implemented in PEtab for evaluating parameter estimation results. These plots can be generated by calling `plot` on the output of `calibrate_model` (a `PEtabOptimisationResult` structure) or `calibrate_multistart` (a `PEtabMultistartResult` structure), with the `plot_type` argument allowing you to select the type of plot. There are two main types of plots that can be generated: (i) those that evaluate parameter estimation results (e.g., objective value, model parameter values), and (ii) those that evaluate and visualize how well the model fits the measured data. This tutorial covers both types.

## Parameter Estimation Result Plots

As a working example, we use already pre-computed parameter estimation results for a published signaling model, which we load into a `PEtabMultistartResult` struct (the files to load can be found [here](https://github.com/sebapersson/PEtab.jl/tree/main/docs/src/assets/optimization_results/boehm)):

```@example 1
using PEtab, Plots
path_res = joinpath(@__DIR__, "assets", "optimization_results", "boehm")
ms_res = PEtabMultistartResult(path_res)
default(left_margin=12.5Plots.Measures.mm, bottom_margin=12.5Plots.Measures.mm, size = (600*1.25, 400 * 1.25), palette = ["#CC79A7", "#009E73", "#0072B2", "#D55E00", "#999999", "#E69F00", "#56B4E9", "#F0E442"], linewidth=4.0) # hide
nothing # hide
```

### Objective Function Evaluations Plots

The objective function evaluation plot can be generated by setting `plot_type=waterfall`, and is available for both single-start and multi-start optimization results. This plot shows the objective value for each iteration of the optimization process. For single-start optimization results, a single trajectory of dots is plotted. For multi-start optimization results, each run corresponds to a trajectory of dots.

```@example 1
plot(ms_res; plot_type=:objective)
```

If the objective function fails to successfully simulate the model for a particular parameter set (indicating a poor fit), the trajectory for said run is marked with crosses instead of circles.

In this and other plots for multi-start parameter estimation, different runs are separated by color. The color is assigned via a clustering process that identifies runs converging to the same local minimum (details and tunable options can be found [here](@ref optimization_output_plotting_multirun_indexing)). Additionally, when many multi-starts are performed, plots like the one above can become too cluttered. Therefore, only the 10 best runs are shown by default, but this can be [customized](@ref optimization_output_plotting_multirun_indexing).

### Best Objective Function Evaluations Plots

The best objective function evaluation plot can be generated by setting `plot_type=waterfall`, and is available for both single-start and multi-start optimization results. This plot is similar to the objective function evaluation plot, but instead, it shows the *best value reached so far* during the process (and is therefore a decreasing function). This is the default plot type for single-start parameter estimation.

```@example 1
plot(ms_res; plot_type=:best_objective)
```

### Waterfall Plots

The waterfall plot can be generated by setting `plot_type=waterfall`, and is only available for multi-start optimization results. This plot-type shows final objective values of all runs, sorted from best to worst. Typically, local minima can be identified as plateaus in the plot, and in PEtab runs with similar final objective value are grouped by colors. This plot is also the default for multi-start optimization results.

```@example 1
plot(ms_res; plot_type=:waterfall)
```

We strongly recommend to include a waterfall plot when reporting results from a multistart parameter estimation run. For more information on interpreting a waterfall plot, see Fig. 5 in [raue2013lessons](@cite).

### Parallel Coordinates Plots

The parallel coordinates plot can be generated by setting `plot_type=parallel_coordinates`, and it is available for multi-start optimization results. This plot shows parameter values for the best parameter estimation runs, with each run represented by a line. The parameter values are normalized, where `0` corresponds to the minimum value encountered for that parameter and `1` to the maximum. If several runs share similar parameter values, the runs in this cluster likely converged to the same local minimum. Meanwhile, if runs in the same cluster show widely different values for a particular parameter, it indicates that the parameter is unidentifiable (i.e., multiple values of that parameter fit the data equally well).

```@example 1
plot(ms_res; plot_type=:parallel_coordinates)
```

### Runtime Evaluation Plots

The runtime evaluation plot can be generated by setting the `plot_type=runtime_eval`, and it is only available for multi-start optimization results. It is a scatter plot that shows the relationship between runtime and final objective value for each run:

```@example 1
plot(ms_res; plot_type=:runtime_eval)
```

### [Multi-Start Run Color Clustering](@id optimization_output_plotting_multirun_clustering)

When using the `calibrate_multistart` function, multiple parameter estimation runs are performed. When plotting results for multiple runs, a clustering function is applied by default to identify runs that have likely converged to the same local minimum, and these runs are assigned the same color. The default clustering method is the `objective_value_clustering` function, which clusters runs if their objective function values are within `0.1` of each other. Users can define their own clustering function and supply it to the `plot` command via the `clustering_function` argument. The custom clustering function should take a `Vector{PEtabOptimisationResult}` as input and return a `Vector{Int64}` of the same size, where each index corresponds to the cluster assignment for that run.

### [Sub-selecting Runs to Plot](@id optimization_output_plotting_multirun_indexing)

When plotting multi-start parameter estimation results with the `:objective`, `:best_objective`, or `:parallel_coordinates` plot types, the output becomes hard to read if more than 10 runs are performed. Therefore, for these plot types, only the `10` runs with the best final objective values are plotted by default. This can be adjusted using the `best_idxs_n` optional argument, an `Int64` specifying how many runs to include in the plot (starting with the best one). Alternatively, the `idxs` optional argument can be used to specify the indexes of the runs to plot.

For the `:waterfall` and `:runtime_eval` plot types, all runs are plotted by default. However, both the `best_idxs_n` and `idxs` arguments can be provided.

## Plotting the Model Fit

After fitting the model, it is useful to compare the model output against the measurement data. This can be done by providing both the optimization solution and the `PEtabODEProblem` to the plot command. By default, the plot will show the output solution for all observables for the first simulation condition. However, any subset of observables can be selected using the `obsid` option, and any simulation condition can be specified using the `cid` option.

This tutorial covers how to plot the model fit for different observables and simulation conditions. It assumes you are familiar with PEtab simulation conditions; if not, see this [tutorial](@ref petab_sim_cond). As a working example, we use the Michaelis-Menten enzyme kinetics model from the starting [tutorial](@ref tutorial), which we fit to for two simulation conditions (`cond1` and `cond2`) and two observables (`obs_e` and `obs_p`).  Even though the code below encodes the model as a ReactionSystem, everything works exactly the same if the model is encoded as an `ODESystem`.

```@example 2
using Catalyst
rn = @reaction_network begin
    kB, S + E --> SE
    kD, SE --> S + E
    kP, SE --> P + E
end
u0 = [:E => 1.0, :SE => 0.0, :P => 0.0]
p_true = [:kB => 1.0, :kD => 0.1, :kP => 0.5]

# Simulate data.
using OrdinaryDiffEq
# cond1
oprob_true_cond1 = ODEProblem(rn,  [:S => 1.0; u0], (0.0, 10.0), p_true)
true_sol_cond1 = solve(oprob_true_cond1, Rodas5P())
data_sol_cond1 = solve(oprob_true_cond1, Rodas5P(); saveat=1.0)
cond1_t, cond1_e, cond1_p = (data_sol_cond1.t[2:end], (0.8 .+ 0.1*randn(10)) .*
                             data_sol_cond1[:E][2:end], (0.8 .+ 0.1*randn(10)) .*
                             data_sol_cond1[:P][2:end])

# cond2
oprob_true_cond2 = ODEProblem(rn,  [:S => 0.5; u0], (0.0, 10.0), p_true)
true_sol_cond2 = solve(oprob_true_cond2, Tsit5())
data_sol_cond2 = solve(oprob_true_cond2, Tsit5(); saveat=1.0)
cond2_t, cond2_e, cond2_p = (data_sol_cond2.t[2:end], (0.8 .+ 0.1*randn(10)) .* 
                             data_sol_cond2[:E][2:end], (0.8 .+ 0.1*randn(10)) .* 
                             data_sol_cond2[:P][2:end])

using PEtab
@unpack E, P = rn
obs_e = PEtabObservable(E, 0.5)
obs_p = PEtabObservable(P, 0.5)
observables = Dict("obs_e" => obs_e, "obs_p" => obs_p)

p_kB = PEtabParameter(:kB)
p_kD = PEtabParameter(:kD)
p_kP = PEtabParameter(:kP)
pest = [p_kB, p_kD, p_kP]

cond1 = Dict(:S => 1.0)
cond2 = Dict(:S => 0.5)
conds = Dict("cond1" => cond1, "cond2" => cond2)

using DataFrames
m_cond1_e = DataFrame(simulation_id="cond1", obs_id="obs_e", time=cond1_t,
                      measurement=cond1_e)
m_cond1_p = DataFrame(simulation_id="cond1", obs_id="obs_p", time=cond1_t,
                      measurement=cond1_p)
m_cond2_e = DataFrame(simulation_id="cond2", obs_id="obs_e", time=cond2_t,
                      measurement=cond2_e)
m_cond2_p = DataFrame(simulation_id="cond2", obs_id="obs_p", time=cond2_t,
                      measurement=cond2_p)
measurements = vcat(m_cond1_e, m_cond1_p, m_cond2_e, m_cond2_p)

model = PEtabModel(rn , observables, measurements, pest; simulation_conditions = conds,
                   speciemap=u0)
petab_prob = PEtabODEProblem(model)

using Optim
res = calibrate_multistart(petab_prob, IPNewton(), 50)
nothing #hide
```

Following parameter estimation, we can plot the fitted solution for `P` in the first simulation condition (`cond1`) as:

```@example 2
using Plots
default(left_margin=12.5Plots.Measures.mm, bottom_margin=12.5Plots.Measures.mm, size = (600*1.25, 400 * 1.25), palette = ["#CC79A7", "#009E73", "#0072B2", "#D55E00", "#999999", "#E69F00", "#56B4E9", "#F0E442"], linewidth=4.0) # hide
plot(res, petab_prob; obsids=["obs_p"], cid="cond1", linewidth = 2.0)
```

To instead wish to plot both observables for the second simulation condition (`cond2`), do:

```@example 2
plot(res, petab_prob; obsids=["obs_e", "obs_p"], cid="cond2", linewidth = 2.0)
```

In this example, the `obsid` option is technically not required, as plotting all observables is the default behavior. Furthermore, by default, the observable formula is shown in the legend or label. If the observable formula is long (e.g., the sum of all model species), this can make the plot unreadable. To address this, you can display only the observable ID in the label by setting `obsid_label = true`:

```@example 2
plot(res, petab_prob; obsids=["obs_e", "obs_p"], cid="cond2", linewidth = 2.0, obsid_label = true)
```

If as above a parameter estimation result (`res`) is provided, the fit for the best-found parameter vector is plotted. It can also be useful to plot the fit for another parameter vector, such as the initial values `x0`. This can be easily done, as the `plot_fit` function also works for any parameter vector that is in the correct order expected by PEtab.jl (for more on parameter order, see [`get_x`](@ref)). For example, to plot the fit for the initial value for parameter estimation run 1, do:

```@example 2
x0 = res.runs[1].x0
plot(x0, petab_prob; obsids=["obs_e", "obs_p"], cid="cond2", linewidth = 2.0)
```

Finally, it is possible to retrieve a dictionary containing plots for all combinations of observables and simulation conditions with:

```@example 2
comp_dict = get_obs_comparison_plots(res, petab_prob; linewidth = 2.0)
nothing # hide
```

Here, `comp_dict` contains one entry for each condition (with keys corresponding to their condition IDs). Each entry is itself a dictionary that contains one entry for each observable (with keys corresponding to their observable IDs). To retrieve the plot for `E` and `cond1` do:

```@example 2
comp_dict["cond1"]["obs_e"]
```

The input to `get_obs_comparison_plots` can also be a parameter vector.

## References

```@bibliography
Pages = ["pest_plot.md"]
Canonical = false
```
# Model Selection with PEtab Select

Sometimes we have competing hypotheses (model structures) that we want to compare to ultimately select the best model/hypothesis. There are [various approaches](https://en.wikipedia.org/wiki/Stepwise_regression) for model selection, such as forward search, backward search, and exhaustive search, where models are compared based on information criteria like AIC or BIC. Additionally, there are efficient algorithms that combine both backward and forward search, such as Famos [gabel2019famos](@cite). All these model selection methods are supported by the Python package [PEtab Select](https://github.com/PEtab-dev/petab_select), for which PEtab.jl provides an interface.

This advanced documentation page assumes that you know how to import and crate PEtab problems in the standard format (a tutorial can be found [here](@ref import_petab_problem)) as well as the basics of multi-start parameter estimation with PEtab.jl (a tutorial can be found [here](@ref pest_methods)). Additionally, since PEtab Select is a Python package, to run this code you need to have [PyCall.jl](https://github.com/JuliaPy/PyCall.jl) installed, and you must build PyCall with a Python environment that has [petab_select](https://github.com/PEtab-dev/petab_select) installed:

```julia
using PyCall
# Path to Python executable with PEtab Select installed
path_python_exe = "path_python"
ENV["PYTHON"] = path_python_exe
# Build PyCall with the PEtab Select Python environment
import Pkg
Pkg.build("PyCall")
```

!!! note
    Model selection is currently only possible for problem in the [PEtab Select](https://github.com/PEtab-dev/petab_select) standard format. We plan to add a Julia interface.

## Model Selection Example

PEtab.jl provides support for PEtab Select through the `petab_select` function:

```@docs; canonical=false
petab_select
```

As an example, for a simple signaling model (files can be downloaded from [here](https://github.com/sebapersson/PEtab.jl/tree/main/docs/src/assets/petab_select)), you can run PEtab Select with the `IPNewton()` algorithm:

```julia
using Optim, PEtab, PyCall
path_yaml = joinpath(@__DIR__, "assets", "petab_select", "petab_select_problem.yaml")
path_res = petab_select(path_yaml, IPNewton(); nmultistarts=10)
```
```julia
┌ Info: PEtab select problem info
│ Method: brute_force
└ Criterion: AIC
[ Info: Model selection round 1 with 1 candidates - as the code compiles in this round it takes extra long time https://xkcd.com/303/
[ Info: Callibrating model M1_1
[ Info: Saving results for best model at /home/sebpe/.julia/dev/PEtab/docs/build/assets/petab_select/PEtab_select_brute_force_AIC.yaml
```

Where the YAML file storing the model selection results is saved at `path_res`.

```@bibliography
Pages = ["pest_select.md"]
Canonical = false
```
# [Simulation Condition-Specific Parameters](@id define_conditions)

Sometimes, a subset of model parameters to be estimated can have different values across experimental conditions. For example, the parameter to estimate `c1` might have one value for condition `cond1` and a different value for condition `cond2`. In such cases, these condition-specific parameters need to be handled separately in the parameter estimation process.

This tutorial covers how to handle condition-specific parameters when creating a `PEtabModel`. It requires that you are familiar with PEtab simulation conditions, if not; see [this](@ref petab_sim_cond) tutorial. As a working example, we use the Michaelis-Menten enzyme kinetics model from the starting [tutorial](@ref tutorial). Even though the code below encodes the model as a `ReactionSystem`, everything works exactly the same if the model is encoded as an `ODESystem`.

```@example 1
using Catalyst, PEtab

t = default_t()
rn = @reaction_network begin
    @parameters S0 c3=1.0
    @species S(t)=S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end
speciemap = [:E => 50.0, :SE => 0.0, :P => 0.0]

@unpack E, S, P = rn
@parameters sigma
obs_sum = PEtabObservable(S + E, 3.0)
obs_p = PEtabObservable(P, sigma)
observables = Dict("obs_p" => obs_p, "obs_sum" => obs_sum)

p_S0 = PEtabParameter(:S0)
p_c2 = PEtabParameter(:c2)
p_sigma = PEtabParameter(:sigma)
nothing # hide
```

## Specifying Condition-Specific Parameters

Condition-specific parameters are handled by first defining them as `PEtabParameter`, followed by linking the model parameter to the appropriate `PEtabParameter` in the simulation conditions. For instance, assume the value of the model parameter `c1` for condition `cond1` should be given by `c1_cond1`, and for condition `cond2` by `c1_cond2`, then the first step is to define `c1_cond1` and `c1_cond2` as `PEtabParameter`:

```@example 1
p_c1_cond1 = PEtabParameter(:c1_cond1)
p_c1_cond2 = PEtabParameter(:c1_cond2)
pest = [p_c1_cond1, p_c1_cond2, p_S0, p_c2, p_sigma]
nothing # hide
```

Next, the model parameter `c1` must be mapped to the correct `PEtabParameter` in the simulation conditions:

```@example 1
cond1 = Dict(:E => 5.0, :c1 => :c1_cond1)
cond2 = Dict(:E => 2.0, :c1 => :c1_cond2)
conds = Dict("cond1" => cond1, "cond2" => cond2)
```

Note that each simulation condition we also define the initial value for specie `E`. Finally, as usual, each measurement must be assigned to a simulation condition:

```@example 1; ansicolor=false
using DataFrames
measurements = DataFrame(simulation_id=["cond1", "cond1", "cond2", "cond2"],
                         obs_id=["obs_p", "obs_sum", "obs_p", "obs_sum"],
                         time=[1.0, 10.0, 1.0, 20.0],
                         measurement=[0.7, 0.1, 1.0, 1.5])
```

Given a `Dict` with simulation conditions and `measurements` in the correct format, it is then straightforward to create a PEtab problem with condition-specific parameters by simply providing the condition `Dict` under the `simulation_conditions` keyword:

```@example 1; ansicolor=false
model = PEtabModel(rn, observables, measurements, pest; speciemap = speciemap,
                   simulation_conditions = conds)
petab_prob = PEtabODEProblem(model)
```

With this setup, the value for the model parameter `c1` is given by `c1_cond1` when simulating the model for `cond1`, and by `c1_cond2` for `cond2`. Additionally, during parameter estimation, both `c1_cond1` and `c1_cond2` are estimated.

For models with many condition-specific parameters, runtime performance may improve by setting `split_over_conditions=true` (PEtab.jl tries to determine when to do this automatically, but it is a hard problem) when building the `PEtabODEProblem`. For more information on this, see [this](@ref Beer_tut) example.

## Additional Possible Configurations

In this tutorial, the condition-specific parameters `[c1_cond1, c1_cond2]` map to one model parameter. It is also possible for condition specific parameters to map to multiple parameters. For example, the following is allowed:

```julia
cond1 = Dict(:c1 => :c1_cond1, :c2 => :c1_cond1)
```
```@meta
CollapsedDocStrings=true
```

# [Events (callbacks, dosages, etc.)](@id define_events)

To account for experimental interventions, such as the addition of a substrate, changes in experimental conditions (e.g., temperature), or automatic dosages, events (often called [callbacks](https://docs.sciml.ai/DiffEqDocs/stable/features/callback_functions/), dosages, etc.) can be used. When creating a `PEtabModel` in Julia, events should be encoded as a `PEtabEvent`:

```@docs; canonical=false
PEtabEvent
```

This tutorial covers how to specify two types of events: those triggered at specific time points and those triggered by a species (e.g., when a specie exceeds a certain concentration). As a working example, we use the Michaelis-Menten enzyme kinetics model from the starting [tutorial](@ref tutorial). Even though the code below provides the model as a `ReactionSystem`, everything works exactly the same if the model is provided as an `ODESystem`.

```@example 1
using Catalyst, DataFrames, PEtab

t = default_t()
rn = @reaction_network begin
    @parameters S0 c3=1.0
    @species S(t)=S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end
speciemap = [:E => 2.0, :SE => 0.0, :P => 0.0]

@unpack E, S, P = rn
@parameters sigma
obs_sum = PEtabObservable(S + E, 3.0)
obs_p = PEtabObservable(P, sigma)
observables = Dict("obs_p" => obs_p, "obs_sum" => obs_sum)

# Set values for better plots
p_c1 = PEtabParameter(:c1; value = 1.0)
p_c2 = PEtabParameter(:c2; value = 2.0)
p_s0 = PEtabParameter(:S0; value = 5.0)
p_sigma = PEtabParameter(:sigma)
pest = [p_c1, p_c2, p_s0, p_sigma]

# Smaller dataset compared to starting tutorial
measurements = DataFrame(obs_id=["obs_p", "obs_sum", "obs_p", "obs_sum"],
                         time=[1.0, 10.0, 1.0, 20.0],
                         measurement=[0.7, 0.1, 1.0, 1.5])
using Plots # hide
default(left_margin=12.5Plots.Measures.mm, bottom_margin=12.5Plots.Measures.mm, size = (600*1.25, 400 * 1.25), palette = ["#CC79A7", "#009E73", "#0072B2", "#D55E00", "#999999", "#E69F00", "#56B4E9", "#F0E442"], linewidth=4.0) # hide
nothing # hide
```

!!! note
    Events/callbacks can be directly encoded in a Catalyst `ReactionNetwork` or a ModelingToolkit `ODESystem` model. However, we strongly recommend using `PEtabEvent` for optimal performance, and to ensure the correct evaluation of the objective function and especially its derivative [frohlich2017parameter](@cite).

## Time-Triggered Events

Time-triggered events are activated at specific time points. The trigger value can be either a constant value (e.g., `t == 2.0`) or a model parameter (e.g., `t == c2`). For example, to trigger an event at `t = 2`, where species `S` is updated as `S <- S + 2`, do:

```@example 1
@unpack S = rn
event = PEtabEvent(t == 2.0, S + 2, S)
```

Then, to ensure the event is included when building the `PEtabModel`, include the `event` under the `events` keyword:

```@example 1
model = PEtabModel(rn, observables, measurements, pest; events=event, speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
nothing # hide
```

From solving the dynamic ODE model, it is clear that at `t == 2`, `S` is incremented by 2:

```@example 1
using Plots
x = get_x(petab_prob)
sol = get_odesol(x, petab_prob)
plot(sol; linewidth = 2.0)
```

The trigger time can also be a model parameter, where the parameter is allowed to be estimated. For instance, to trigger the event when `t == c2` and assign `c1` as `c1 <- 2.0`, do:

```@example 1
@unpack c2 = rn
event = PEtabEvent(t == c2, 5.0, :c1)
```

From plotting the solution, it is clear that a change in dynamics occurs at `t == c2`:

```@example 1
model = PEtabModel(rn, observables, measurements, pest; events=event, speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
sol = get_odesol(x, petab_prob)
plot(sol; linewidth = 2.0)
```

!!! note
    If the condition and target are single parameters or species, they can be specified as `Num` (from `@unpack`) or a `Symbol` (`:c1` above). If the event involves multiple parameters or species, they must be provided as a `Num` equation (see below).

## Specie-Triggered Events

Specie-triggered events are activated when a species-dependent Boolean condition transitions from `false` to `true`. For example, suppose we have a dosage machine that triggers when the substrate `S` drops below the threshold value of `2.0`, and at that point, the machine updates `S` as `S <- S + 1`. This can be encoded as:

```@example 1
@unpack S = rn
event = PEtabEvent(S == 0.2, 1.0, S)
```

Plotting the solution, we can clearly see how `S` is incremented every time it reaches `0.2`:

```@example 1
model = PEtabModel(rn, observables, measurements, pest; events=event, speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
sol = get_odesol(x, petab_prob)
plot(sol; linewidth = 2.0)
```

With species-triggered events, the direction can matter. For instance, with `S == 0.2`, the event is triggered when `S` approaches `0.2` from either above or below. To activate the event only when `S` drops below `0.2`, write:

```@example 1
event = PEtabEvent(S < 0.2, 1.0, S)
model = PEtabModel(rn, observables, measurements, pest; events=event, speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
sol = get_odesol(x, petab_prob)
plot(sol; linewidth = 2.0)
```

Because events only trigger when the condition (`S < 0.2`) transitions from `false` to `true`, this event is triggered when `S` approaches from above. Meanwhile, if we write `S > 0.2`, the event is never triggered:

```@example 1
event = PEtabEvent(S > 0.2, 1.0, S)
model = PEtabModel(rn, observables, measurements, pest; events=event, speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
sol = get_odesol(x, petab_prob)
plot(sol; linewidth = 2.0)
```

## Multiple Event Targets

Sometimes an event can affect multiple species and/or parameters. In this case, both `affect` and `target` should be provided as vectors. For example, suppose an event is triggered when the substrate fulfills`S < 0.2`, where `S` is updated as `S <- S + 2` and `c1` is updated as `c1 <- 2.0`. This can be encoded as:

```@example 1
event = PEtabEvent(S < 0.2, [S + 2, 2.0], [S, :c1])
```

The event is provided as usual to the `PEtabModel`:

```@example 1
model = PEtabModel(rn, observables, measurements, pest; events=event, speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
sol = get_odesol(x, petab_prob)
plot(sol; linewidth = 2.0)
```

When there are multiple targets, the length of the `affect` vector must match the length of the `target` vector.

## Multiple Events

Sometimes a model can have multiple events, which then should be provided as `Vector` of `PEtabEvent`. For example, suppose `event1` is triggered when the substrate fulfills `S < 0.2`, where `S` is updated as `S <- S + 2`, and `event2` is triggered when `t == 1.0`, where `c1` is updated as `c1 <- 2.0`. This can be encoded as:

```@example 1
@unpack S, c1 = rn
event1 = PEtabEvent(S < 0.2, 1.0, S)
event2 = PEtabEvent(1.0, 2.0, :c1)
events = [event1, event2]
```

These events are then provided as usual to the `PEtabModel`:

```@example 1
model = PEtabModel(rn, observables, measurements, pest; events=event, speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
sol = get_odesol(x, petab_prob)
plot(sol; linewidth = 2.0)
```

In this example, two events are provided, but with your imagination as the limit, any number of events can be provided.

## Modifying Event Parameters for Different Simulation Conditions

The trigger time (`condition`) and/or `affect` can be made specific to different simulation conditions by introducing control parameters (here `c_time` and `c_value`) and setting their values accordingly in the simulation conditions:

```@example 1
rn = @reaction_network begin
    @parameters c3=1.0 S0 c_time c_value
    @species S(t) = S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end

cond1 = Dict(:S => 5.0, :c_time => 1.0, :c_value => 2.0)
cond2 = Dict(:S => 2.0, :c_time => 4.0, :c_value => 3.0)
conds = Dict("cond1" => cond1, "cond2" => cond2)

measurements = DataFrame(simulation_id=["cond1", "cond1", "cond2", "cond2"],
                         obs_id=["obs_P", "obs_Sum", "obs_P", "obs_Sum"],
                         time=[1.0, 10.0, 1.0, 20.0],
                         measurement=[0.7, 0.1, 1.0, 1.5])
nothing # hide
```

In this setup, when the event is defined as:

```@example 1
event = PEtabEvent(:c_time, :c_value, :c1)
```

the `c_time` parameter controls when the event is triggered, so for condition `c0`, the event is triggered at `t=1.0`, while for condition `c1`, it is triggered at `t=4.0`. Additionally, for conditions `cond1` and `cond2`, the parameter `c1` takes on the corresponding `c_value` values, which is `2.0` and `3.0`, respectively, which can clearly be seen when plotting the solution for `cond1`

```@example 1
model = PEtabModel(rn, observables, measurements, pest; events=event, speciemap = speciemap,
                   simulation_conditions = conds)
petab_prob = PEtabODEProblem(model)
sol_cond1 = get_odesol(x, petab_prob; cid=:cond1)
plot(sol_cond1; linewidth = 2.0)
```

and `cond2`

```@example 1
sol = get_odesol(x, petab_prob; cid=:cond2)
plot(sol; linewidth = 2.0)
```

## References

```@bibliography
Pages = ["petab_event.md"]
Canonical = false
```
# [Noise and Observable Parameters](@id time_point_parameters)

Sometimes a model observable (e.g., a protein) is measured using different experimental assays. This can result in measurement noise parameter `σ` being different between measurements for the same observable. Additionally, if the observable is measured on a relative scale, the observable offset and scale parameters that link the model output scale to the measurement data scale might differ between measurements. From a modeling viewpoint, this can be handled by introducing time-point-specific noise and/or observable parameters.

This tutorial covers how to specify time-point specific observable and noise parameters for a `PEtabModel`. As a working example, we use the Michaelis-Menten enzyme kinetics model from the starting [tutorial](@ref tutorial). Even though the code below encodes the model as a `ReactionSystem`, everything works exactly the same if the model is encoded as an `ODESystem`.

```@example 1
using Catalyst, PEtab

t = default_t()
rn = @reaction_network begin
    @parameters S0 c3=1.0
    @species S(t)=S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end
speciemap = [:E => 50.0, :SE => 0.0, :P => 0.0]

p_c1 = PEtabParameter(:c1)
p_c2 = PEtabParameter(:c2)
p_s0 = PEtabParameter(:S0)
p_sigma = PEtabParameter(:sigma)
pest = [p_c1, p_c2, p_s0, p_sigma]
nothing # hide
```

## Specifying Noise and Observable Parameters

Time-point-specific parameters are handled by encoding observable and noise parameters in the `PEtabObservable`, followed by setting values for these parameters in the measurements `DataFrame`. For instance, assume that the measurement noise is time-point specific for the observable `obs_sum`. Then, the first step is to add a noise parameter of the form `noiseParameter...` in the `PEtabObservable`:

```@example 1
@unpack E, S = rn
@parameters noiseParameter1_obs_sum
obs_sum = PEtabObservable(S + E, noiseParameter1_obs_sum)
```

Additionally, assume that data is measured on a relative scale, where the scale and offset parameters vary between time points for the observable `obs_p`. Then, the first step for this observable is to add observable parameters of the form `observableParameter...`:

```@example 1
@unpack P = rn
@parameters observableParameter1_obs_p observableParameter2_obs_p
obs_p = PEtabObservable(observableParameter1_obs_p * P + observableParameter2_obs_p, 3.0)
```

Given this, the observables are collected in a `Dict` as usual:

```@example 1
observables = Dict("obs_p" => obs_p, "obs_sum" => obs_sum)
nothing # hide
```

!!! note
    Noise and observable parameters must follow the format `observableParameter${n}_${observableId}` and `noiseParameter${n}_${observableId}`, with `n` starting from 1, to ensure correct parameter mapping when building the PEtab problem. This follows the PEtab specification, and more details can be found [here](https://petab.readthedocs.io/en/latest/index.html).

## Mapping Measurements to Time-Point Specific Parameters  

To link the measurements to time-point-specific noise and/or observable parameters, values for these parameters must be specified in the measurements `DataFrame`. These values can be either constant numerical values or any defined `PEtabParameter`. For our working example, a valid measurement table would look like this (the column names matter, but not the order):

| obs_id (str) | time (float) | measurement (float) | observable_parameters (str \| float) | noise_parameters (str \| float) |
|--------------|--------------|---------------------|--------------------------------------|---------------------------------|
| obs_p        | 1.0          | 0.7                 |                                      | sigma                           |
| obs_sum      | 10.0         | 0.1                 | 3.0; 4.0                             |                                 |
| obs_p        | 1.0          | 1.0                 |                                      | sigma                           |
| obs_sum      | 20.0         | 1.5                 | 2.0; 3.0                             |                                 |

In particular, the follow consideration apply to the measurements table:

- If an observable does not have noise or observable parameters (e.g., `obs_p` above lacks observable parameters), the corresponding column should be left empty.
- For multiple parameters, values are separated by a semicolon (e.g., for `obs_sum`, we have `3.0; 4.0`).
- The values for noise and observable parameters can be either numerical values or any defined `PEtabParameter` (e.g., `sigma` above). Combinations are also allowed, so `sigma;1.0` is valid.
- If an observable has noise and/or observable parameters, values for these must be specified for each measurement of that observable.

For our working example, the measurement data would in Julia look like:

```@example 1
using DataFrames
measurements = DataFrame(
    obs_id=["obs_p", "obs_sum", "obs_p", "obs_sum"],
    time=[1.0, 10.0, 1.0, 20.0],
    measurement=[0.7, 0.1, 1.0, 1.5], 
    observable_parameters=[missing, "3.0;4.0", missing, "2.0;3.0"],
    noise_parameters=["sigma", missing, "sigma", missing]
)
```

## Bringing It All Together

Given `observables` and `measurements` in the correct format, it is straightforward to create a PEtab problem with time-point-specific parameters by creating the `PEtabModel` as usual:

```@example 1
model = PEtabModel(rn, observables, measurements, pest; speciemap = speciemap)
petab_prob = PEtabODEProblem(model)
```
# [Steady-State Simulations (Pre-Equilibration)](@id define_with_ss)

Sometimes, such as with perturbation experiments, the model should be at a steady state at time zero before performing the simulation that is compared against data. From a modeling perspective, this can be handled by first simulating the model to reach a steady state and then, possibly by changing some control parameters, perform the main simulation. In PEtab.jl, this is handled by defining pre-equilibration simulation conditions.

This tutorial covers how to specify pre-equilibration conditions for a `PEtabModel`. It requires that you are familiar with PEtab simulation conditions, if not; see this [tutorial](@ref petab_sim_cond). As a working example, we use the Michaelis-Menten enzyme kinetics model from the starting [tutorial](@ref tutorial). Even though the code below encodes the model as a `ReactionSystem`, everything works exactly the same if the model is encoded as an `ODESystem`.

```@example 1
using Catalyst, PEtab

t = default_t()
rn = @reaction_network begin
    @parameters S0 c3=1.0
    @species S(t)=S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end
speciemap = [:E => 50.0, :SE => 0.0, :P => 0.0]

@unpack E, S, P = rn
@parameters sigma
obs_sum = PEtabObservable(S + E, 3.0)
obs_p = PEtabObservable(P, sigma)
observables = Dict("obs_p" => obs_p, "obs_sum" => obs_sum)

# Unlike the starting tutorial we do not estimate S0 here as it below 
# dictates simulation conditions
p_c1 = PEtabParameter(:c1)
p_c2 = PEtabParameter(:c2)
p_sigma = PEtabParameter(:sigma)
pest = [p_c1, p_c2, p_sigma]
nothing # hide
```

## Specifying Pre-equilibration Conditions

Pre-equilibration conditions are specified in the same way as simulation conditions. For instance, assume we have two simulation conditions for which we have measurement data (`cond1` and `cond2`), where in `cond1`, the parameter value for `S0` is `3.0`, and in `cond2`, the value for `S0` is `5.0`:

```@example 1
cond1 = Dict(:S0 => 3.0)
cond2 = Dict(:S0 => 5.0)
nothing # hide
```

Additionally, assume that before gathering measurements for conditions `cond1` and `cond2`, the system should be at a steady state starting from `S0 = 2.0`. This pre-equilibration condition (the conditions under which the system reaches steady state) is defined just like any other simulation condition:

```@example 1
cond_preeq = Dict(:S0 => 2.0)
nothing # hide
```

As usual, the condition should be collected in a `Dict`:

```@example 1
conds = Dict("cond_preeq" => cond_preeq, "cond1" => cond1, "cond2" => cond2)
```

## Mapping Measurements to Pre-equilibration Conditions

To properly link the measurements to a specific simulation configuration, both the main simulation ID and the pre-equilibration ID must be specified in the measurements `DataFrame`. For our working example, a valid measurement table would look like this (the column names matter, but not the order):

| simulation_id (str) | pre\_eq\_id (str) | obs_id (str) | time (float) | measurement (float) |
|---------------------|-------------------|--------------|--------------|---------------------|
| cond1               | cond_preeq        | obs_p        | 1.0          | 0.7                 |
| cond1               | cond_preeq        | obs_sum      | 10.0         | 0.1                 |
| cond2               | cond_preeq        | obs_p        | 1.0          | 1.0                 |
| cond2               | cond_preeq        | obs_sum      | 20.0         | 1.5                 |

For each measurement, the simulation configuration is interpreted as follows: the model is first simulated to a steady state using the condition specified in the `pre_eq_id` column, and then the model is simulated and compared against the data using the condition in the `simulation_id`. In Julia this measurement table would look like:

```@example 1
using DataFrames
measurements = DataFrame(simulation_id=["cond1", "cond1", "cond2", "cond2"],
                         pre_eq_id=["cond_preeq", "cond_preeq", "cond_preeq", "cond_preeq"],
                         obs_id=["obs_p", "obs_sum", "obs_p", "obs_sum"],
                         time=[1.0, 10.0, 1.0, 20.0],
                         measurement=[0.7, 0.1, 1.0, 1.5])                         
```

## Bringing It All Together

Given a `Dict` with simulation conditions and `measurements` in the correct format, it is straightforward to create a PEtab problem with pre-equilibration conditions by providing the condition `Dict` under the `simulation_conditions` keyword:

```@example 1
model = PEtabModel(rn, observables, measurements, pest;
                   simulation_conditions = conds)
petab_prob = PEtabODEProblem(model)
```

From the printout, we see that the `PEtabODEProblem` now has a `SteadyStateSolver`. The default steady-state solver is generally a good choice, but if you are interested in more details, see to the [API](@ref API) and [this] ADD! example.

## Additional Possible Pre-equilibration Configurations

In the example above, each measurement has the same pre-equilibration condition, and all observations have a pre-equilibration condition. PEtab.jl also allows for more flexibility, and the following configurations are supported:

- **Different pre-equilibration conditions**: If measurements have different pre-equilibration conditions, simply define these as simulation conditions, and specify the corresponding condition in the `pre_eq_id` column of the measurements table.
- **No pre-equilibration for some measurements**: If some measurements do not require pre-equilibration, leave the entry in the `pre_eq_id` column empty for these measurements.
# [Simulation Conditions](@id petab_sim_cond)

Sometimes measurements are collected under various experimental conditions, where, for example, the initial concentration of a substrate differs between conditions. From a modeling viewpoint, experimental conditions correspond to different simulation conditions where the model is simulated with different initial values and/or different values for a set of control parameters for each simulation condition. In other words, for each simulation condition, a unique model simulation is performed.

This tutorial covers how to specify simulation conditions for a `PEtabModel`. As a working example, we use the Michaelis-Menten enzyme kinetics model from the starting [tutorial](@ref tutorial). Even though the code below encodes the model as a `ReactionSystem`, everything works exactly the same if the model is encoded as an `ODESystem`.

```@example 1
using Catalyst, PEtab

t = default_t()
rn = @reaction_network begin
    @parameters S0 c3=1.0
    @species S(t)=S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end
speciemap = [:E => 50.0, :SE => 0.0, :P => 0.0]

@unpack E, S, P = rn
@parameters sigma
obs_sum = PEtabObservable(S + E, 3.0)
obs_p = PEtabObservable(P, sigma)
observables = Dict("obs_p" => obs_p, "obs_sum" => obs_sum)

p_c1 = PEtabParameter(:c1)
p_c2 = PEtabParameter(:c2)
p_s0 = PEtabParameter(:S0)
p_sigma = PEtabParameter(:sigma)
pest = [p_c1, p_c2, p_s0, p_sigma]
using Plots # hide
default(left_margin=12.5Plots.Measures.mm, bottom_margin=12.5Plots.Measures.mm, size = (600*1.25, 400 * 1.25), palette = ["#CC79A7", "#009E73", "#0072B2", "#D55E00", "#999999", "#E69F00", "#56B4E9", "#F0E442"], linewidth=4.0) # hide
nothing # hide
```

## Specifying Simulation Conditions

Simulation conditions should be encoded as a `Dict`, where for **each** condition, the parameters and/or initial values that change are specified. For instance, assume we have two simulation conditions (`cond1` and `cond2`), where in `cond1`, the initial value for `E` is `0.0` and the parameter `c3` is `1.0`, whereas in `cond2`, the initial value for `E` is `3.0` and the parameter `c3` is `2.0`. This is encoded as:

```@example 1
cond1 = Dict(:E => 50.0, :c3 => 1.0)
cond2 = Dict(:E => 100.0, :c3 => 2.0)
conds = Dict("cond1" => cond1, "cond2" => cond2)
```

In more detail, if a specie is specified (e.g., `E` above), its initial value is set to the provided value. Meanwhile, if a parameter is specified (e.g., `c3` above), the parameter is set to the provided value.

!!! note
    If a parameter or species is specified for one simulation condition, it must be specified for all simulation conditions. This to prevent ambiguity when simulating the model.

## Mapping Measurements to Simulation Conditions

To properly link the measurements to a specific simulation condition, the condition ID for each measurement must be specified in the measurement `DataFrame`. For our working example, a valid measurement table would look like (the column names matter, but not the order):

| simulation_id (str) | obs_id (str) | time (float) | measurement (float) |
|---------------------|--------------|--------------|---------------------|
| cond1               | obs_p        | 1.0          | 0.7                 |
| cond1               | obs_sum      | 10.0         | 0.1                 |
| cond2               | obs_p        | 1.0          | 1.0                 |
| cond2               | obs_sum      | 20.0         | 1.5                 |

In Julia this would look like:

```@example 1
using DataFrames
measurements = DataFrame(simulation_id=["cond1", "cond1", "cond2", "cond2"],
                         obs_id=["obs_p", "obs_sum", "obs_p", "obs_sum"],
                         time=[1.0, 10.0, 1.0, 20.0],
                         measurement=[0.7, 0.1, 1.0, 1.5])
```

## Bringing It All Together

Given a `Dict` with simulation conditions and `measurements` in the correct format, it is straightforward to create a PEtab problem with multiple simulation conditions by providing the condition `Dict` under the `simulation_conditions` keyword:

```@example 1
model = PEtabModel(rn, observables, measurements, pest; simulation_conditions = conds)
petab_prob = PEtabODEProblem(model)
```

From plotting the solution of the ODE model for `cond1` and `cond2`, we can clearly see that both the dynamics and initial value for specie `E` differs:

```@example 1
using Plots
x = get_x(petab_prob)
sol_cond1 = get_odesol(x, petab_prob; cid = "cond1")
sol_cond2 = get_odesol(x, petab_prob; cid = "cond2")
p1 = plot(sol_cond1, title = "cond1")
p2 = plot(sol_cond2, title = "cond2")
plot(p1, p2)
plot(p1, p2; size = (800, 400)) # hide
```
# References

Throughout the documentation, references related to parameter estimation for ODE models can be found. This page contains a complete list of all references mentioned in the documentation.

```@bibliography
```
# [Tutorial](@id tutorial)

This overarching tutorial of PEtab.jl covers how to create a parameter estimation problem in Julia (a `PEtabODEProblem`) and how to estimate the unknown parameters for the created problem.

## Input Problem

As a working example, this tutorial considers the Michaelis-Menten enzyme kinetics chemical reaction model:

```math
S + E \xrightarrow{c_1} SE \\
SE \xrightarrow{c_2} S + E \\
SE \xrightarrow{c_3} S + P,
```

Which, via the [law of mass action](https://en.wikipedia.org/wiki/Law_of_mass_action), can be converted to a system of Ordinary Differential Equations (ODEs):

```math
\begin{align*}
    \frac{\mathrm{d}S}{\mathrm{d}t} &= c_1 S \cdot E - c_2 SE \\
    \frac{\mathrm{d}E}{\mathrm{d}t} &= c_1 S \cdot E - c_2 SE \\
    \frac{\mathrm{d}SE}{\mathrm{d}t} &= -c_1 S \cdot E + c_2 SE - c_3 SE \\
    \frac{\mathrm{d}P}{\mathrm{d}t} &= c_3 SE
\end{align*}
```

For the working example, we assume that the initial values for the species `[S, E, SE, P]` are:

```math
S(t_0) = S_0, \quad E(t_0) = 50.0, \quad SE(t_0) = 0.0, \quad P(t_0) = 0.0
```

And that the observables for which we have time-lapse measurement data are the sum of `S + E` as well as `P`:

```math
\begin{align*}
    obs_1 &= S + E \\
    obs_2 &= P
\end{align*}
```

For the parameter estimation, we aim to estimate the parameters `[c1, c2]` and the initial value `S(t_0) = S0` (a total of three parameters), while assuming `c3 = 1.0` is known. This tutorial demonstrates how to set up this parameter estimation problem (create a `PEtabODEProblem`) and estimate parameters using [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl).

## Creating the Parameter Estimation Problem

To define a parameter estimation problem we need four components:

1. **Dynamic Model**: The dynamic model can be provided as either a [Catalyst.jl](https://petab.readthedocs.io/en/latest/) `ReactionSystem` or a [ModellingToolkit.jl](https://github.com/SciML/ModelingToolkit.jl) `ODESystem`.
2. **Observable Formulas**: To link the model to the measurement data, we need observable formulas. Since real-world data often comes with measurement noise, PEtab also requires that noise formulas and noise distributions are provided for each observable. All of this is specified with the `PEtabObservable`.
3. **Parameters to Estimate**: A parameter estimation problem needs parameters to be estimated. Since often only a subset of the dynamic model parameters is estimated, PEtab explicitly requires that the parameters to be estimated are specified as a `PEtabParameter`. It is also possible to set priors on these parameters.
4. **Measurement Data**: To estimate parameters, measurement data is required. This data should be provided as a `DataFrame` in the format explained below.
5. **Simulation Conditions (Optional)**: Measurements are often collected under various experimental conditions, which correspond to different simulation conditions. Details on how to handle such conditions are provided in [this](@ref petab_sim_cond) tutorial.

### Defining the Dynamic Model

The dynamic model can be either a [Catalyst.jl](https://github.com/SciML/Catalyst.jl) `ReactionSystem` or a [ModelingToolkit.jl](https://github.com/SciML/ModelingToolkit.jl) `ODESystem`. For the Michaelis-Menten model above, the Catalyst representation is given by:

```@example 1
using Catalyst
t = default_t()
rn = @reaction_network begin
    @parameters S0 c3=1.0
    @species S(t)=S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end
```

Parameters that are constant (`c3`) and those that set initial values (`S0`) should be defined in the `parameters` block. Values for parameters that are to be estimated (here `[c1, c2, S0]`) do not need to be specified. Similarly, for species, only those with a parameter-dependent initial value need to be defined in the `species` block, while species with a constant initial value can be defined directly in the system (similar to `c3` above) or as a specie map:

```@example 1
speciemap = [:E => 50.0, :SE => 0.0, :P => 0.0]
```

Any species or parameters with undeclared initial values default to 0. For additional details on how to create a `ReactionSystem`, see the excellent Catalyst [documentation](https://docs.sciml.ai/Catalyst/stable/).

Using a ModelingToolkit `ODESystem`, the model is defined as:

```@example 1
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@mtkmodel SYS begin
    @parameters begin
        S0
        c1
        c2
        c3 = 1.0
    end
    @variables begin
        S(t) = S0
        E(t) = 50.0
        SE(t) = 0.0
        P(t) = 0.0
    end
    @equations begin
        D(S) ~ -c1 * S * E + c2 * SE
        D(E) ~ -c1 * S * E + c2 * SE + c3 * SE
        D(SE) ~ c1 * S * E - c2 * SE - c3 * SE
        D(P) ~ c3 * SE
    end
end
@mtkbuild sys = SYS()
```

For an `ODESystem`, all parameters and species must be declared in the `@mtkmodel` block. If the value of a parameter or species is left empty (e.g., `c2` above) and the parameter is not set to be estimated, it defaults to 0. For additional details on how to create an `ODESystem` model, see the ModelingToolkit [documentation](https://docs.sciml.ai/ModelingToolkit/dev/).

### Defining the Observables

To connect the model with measurement data, we need an observable formula. Additionally, since measurement data is typically noisy, PEtab requires a measurement noise formula.

For example, let us assume we have observed the sum `E + S` ($obs_1$ above) with a known normally distributed measurement error (`σ = 3.0`). This in encoded as:

```@example 1
using PEtab
@unpack E, S = rn
obs_sum = PEtabObservable(S + E, 3.0)
```

In `PEtabObservable`, the first argument is the observed formula, and the second argument is the formula for the measurement error. In this case, we assumed a known measurement error (`σ = 3.0`), but often the measurement error is unknown and needs to be estimated. For example, let us assume we have observed `P` ($obs_2$) with an unknown measurement error `sigma`. This in encoded as:

```@example 1
@unpack P = rn
@parameters sigma
obs_p = PEtabObservable(P, sigma)
```

By defining `sigma` as a `PEtabParameter` (explained below), it is estimated along with the other parameters. To complete the definition of the observables, we need to group all `PEtabObservable`s together into a `Dict` and assign an appropriate name for each observable:

```@example 1
observables = Dict("obs_p" => obs_p, "obs_sum" => obs_sum)
```

More formally, a `PEtabObservable` defines a likelihood function for an observable. By default, a normally distributed error and corresponding likelihood is assumed, but log-normal distribution is also supported. For more details, see the [API](@ref API).

### Defining Parameters to Estimate

To set up a parameter estimation problem, we need to specify the parameters to estimate via `PEtabParameter`. To set `c1` to be estimated, use:

```@example 1
p_c1 = PEtabParameter(:c1)
```

From the printout, we see that by default `c1` is assigned bounds `[1e-3, 1e3]`. This is because benchmarks have shown that using bounds is advantageous, as it prevents simulation failures during parameter estimation[frohlich2022fides](@cite). Furthermore, we see that by default `c1` is estimated on a `log10` scale. Benchmarks have demonstrated that estimating parameters on a `log10` scale improves performance [raue2013lessons, hass2019benchmark](@cite). Naturally, it is possible to change the bounds and/or scale; see the [API](@ref API) for details.

When specifying a `PEtabParameter` we can also provide prior information. For example, assume we know that `c2` should have a value around 10. To account for this we can provide a [prior](https://en.wikipedia.org/wiki/Prior_probability) for the parameter using any continuous distribution from [Distributions.jl](https://github.com/JuliaStats/Distributions.jl). For example, to assign a `Normal(10.0, 0.3)` prior to `c2`, do:

```@example 1
using Distributions
p_c2 = PEtabParameter(:c2; prior = Normal(10.0, 0.3))
```

By default, the prior is on a linear scale (not the default `log10` scale), but this can be changed if needed. For more details, see the [API](@ref API).

To complete the definition of the parameters to estimate, we need to assign a `PEtabParameter` for each unknown and group them into a `Vector`:

```@example 1
p_s0 = PEtabParameter(:S0)
p_sigma = PEtabParameter(:sigma)
pest = [p_c1, p_c2, p_s0, p_sigma]
```

### Measurement Data Format

The measurement data should be provided in a `DataFrame` with the following format (the column names matter, but not the order):

| obs_id (str) | time (float) | measurement (float) |
|--------------|--------------|---------------------|
| id           | val          | val                 |
| ...          | ...          | ...                 |

Where the columns correspond to:

- `obs_id`: The observable to which the measurement corresponds. It must match one of the `keys` in the `PEtabObservable` `Dict`.
- `time`: The time point at which the measurement was collected.
- `measurement`: The measurement value.

For our working example, using simulated data, a valid measurement table would look like:

```@example 1
using OrdinaryDiffEq, DataFrames
# Simulate with 'true' parameters
ps = [:c1 => 1.0, :c2 => 10.0, :c3 => 1.0, :S0 => 100.0]
u0 = [:S => 100.0, :E => 50.0, :SE => 0.0, :P => 0.0]
tspan = (0.0, 10.0)
oprob = ODEProblem(rn, u0, tspan, ps)
sol = solve(oprob, Rodas5P(); saveat = 0:0.5:10.0)
obs_sum = (sol[:S] + sol[:E]) .+ randn(length(sol[:E]))
obs_p = sol[:P] .+ randn(length(sol[:P]))
df_sum = DataFrame(obs_id = "obs_sum", time = sol.t, measurement = obs_sum)
df_p = DataFrame(obs_id = "obs_p", time = sol.t, measurement = obs_p)
measurements = vcat(df_sum, df_p)
first(measurements, 5) # hide
```

It is important to note that the measurement table follows a [tidy](https://r4ds.hadley.nz/data-tidy) format [wickham2014tidy](@cite), where each row corresponds to **one** measurement. Therefore, for repeated measurements at a single time point, one row should be added for each repeat.

### Bringing It All Together

Given a model, observables, parameters to estimate, and measurement data, it is possible to create a `PEtabODEProblem`, which contains all the information needed for parameter estimation. This is done in a two-step process, where the first step is to create a `PEtabModel`. For our `ReactionSystem` or `ODESystem` model, this is done as:

```@example 1
model_sys = PEtabModel(sys, observables, measurements, pest)
model_rn = PEtabModel(rn, observables, measurements, pest; speciemap = speciemap)
nothing # hide
```

Note that any potential `speciemap` or `parametermap` must be provided as a keyword. Given a `PEtabModel`, it is straightforward to create a `PEtabODEProblem`:

```@example 1
petab_prob = PEtabODEProblem(model_rn)
```

The printout shows relevant statistics for the `PEtabODEProblem`. First, we see that there are 4 parameters to estimate. Additionally, we see that the ODE solver used for simulating the model is the stiff `Rodas5P` solver, and that both the gradient and Hessian are computed via forward-mode automatic differentiation using [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl). These [defaults](@ref default_options) are based on extensive benchmarks and typically do not need to be changed for models in biology. For models outside of biology, a discussion of the options can be found [here](@ref default_options). While the defaults generally perform well, they are not always perfect. Therefore, when creating a `PEtabODEProblem`, anything from the `ODESolver` to the gradient methods can be customized. For details, see the [API](@ref).

Overall, the `PEtabODEProblem` contains all the information needed for performing parameter estimation. Next, this tutorial covers how to estimate unknown model parameters given a `PEtabODEProblem`.

## Parameter estimation

A `PEtabODEProblem` (which we defined above) contains all the information needed to wrap a numerical optimization library to perform parameter estimation, and details on how to do this can be found [here](@ref wrap_est). However, wrapping existing optimization libraries is cumbersome, therefore PEtab.jl provides wrappers for [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl), [Ipopt](https://coin-or.github.io/Ipopt/), [Optimization.jl](https://github.com/SciML/Optimization.jl), and [Fides.py](https://github.com/fides-dev/fides).

This section of the tutorial covers how to use Optim.jl to estimate parameters given a starting guess `x0`. Moreover, since the objective function to minimize for ODE models often contains multiple local minima, the tutorial also covers how to perform global optimization using multistart parameter estimation.

### Single-Start Parameter Estimation

To perform parameter estimation with a numerical optimization algorithm, we typically need a starting point `x0`, where it is important that `x0` follows the parameter order expected by the `PEtabODEProblem`. One way to obtain such a vector is by retrieving the `PEtabODEProblem`'s vector of nominal values, which correspond to the optional parameter values specified in `PEtabParameter` (if unspecified, these values default to the mean of the lower and upper bounds). This vector can be retrieved with `get_x`:

```@example 1
x0 = get_x(petab_prob)
```

From the printout we see that `x0` is a `ComponentArray`, so in addition to the parameter values, it also holds the parameter names. Additionally, we see that parameters like `log10_c1` have a `log10` prefix. This is because the parameter (by default) is estimated on the `log10` scale, which, as mentioned above, often improves parameter estimation performance [hass2019benchmark](@cite). Consequently, when changing the value for this parameter, the new value should be provided on the `log10` scale. For example, to change `c1` to `10.0` do:

```@example 1
x0.log10_c1 = log10(10.0)
nothing # hide
```

For more details on how to interact with a `ComponentArray`, see the ComponentArrays.jl [documentation](https://github.com/jonniedie/ComponentArrays.jl). `get_x` is not the only way, and generally not the recommended way to retrieve a starting point. To avoid biasing the parameter estimation, it is recommended to use a random starting guess within the parameter bounds. This can be generated with `get_startguesses`:

```@example 1
using Random # hide
Random.seed!(123) # hide
x0 = get_startguesses(petab_prob, 1)
nothing # hide
```

Given a starting point `x0`, we can now perform the parameter estimation. As this is a small problem with only 4 parameters to estimate, we use the Interior-point Newton method from Optim.jl (for algorithm recommendations, see [this](@ref options_optimizers) page):

```@example 1
using Optim
res = calibrate(petab_prob, x0, IPNewton())
```

The printout shows parameter estimation statistics, such as the final objective value `fmin` (which, since PEtab works with likelihoods, corresponds to the negative log-likelihood). We can further obtain the minimizing parameter vector:

```@example 1
res.xmin
```

This vector is close to the true parameters used to simulate the data above. For information on additional statistics stored in `res`, see the [API](@ref) on `PEtabOptimisationResult`.

Lastly, to evaluate the parameter estimation, it is useful to plot how well the model fits the data. Using the built-in plotting functionality in PEtab, this is straightforward:

```@example 1
using Plots
default(left_margin=12.5Plots.Measures.mm, bottom_margin=12.5Plots.Measures.mm, size = (600*1.25, 400 * 1.25), palette = ["#CC79A7", "#009E73", "#0072B2", "#D55E00", "#999999", "#E69F00", "#56B4E9", "#F0E442"], linewidth=4.0) # hide
plot(res, petab_prob; linewidth = 2.0)
plot(res, petab_prob; linewidth = 2.0) # hide
```

Even though the plot looks good, it is important to remember that ODE models often have multiple local minima [raue2013lessons](@cite). To ensure the global optimum is found, a global optimization approach is required. One effective method is multi-start parameter estimation, which we cover next.

### Multi-Start Parameter Estimation

In multi-start parameter estimation, `n` parameter estimation runs are initiated from `n` random starting points. The rationale is that a subset of these runs should converge to the global optimum, and even though this is a simple global optimization approach, benchmarks have shown that it performs well for ODE models in biology [raue2013lessons, villaverde2019benchmarking](@cite).

The first step in multi-start parameter estimation is to generate `n` starting points. Simple uniform sampling is not preferred, as randomly generated points tend to cluster. Instead, a [Quasi-Monte Carlo](https://en.wikipedia.org/wiki/Quasi-Monte_Carlo_method) method, such as [Latin hypercube sampling](https://en.wikipedia.org/wiki/Latin_hypercube_sampling), is better suited to generate well-spread starting points. In `get_startguesses`, `LatinHypercubeSample` is the default method used. Therefore, `n = 50` Latin hypercube-sampled starting points can be generated with:

```@example 1
Random.seed!(123) # hide
x0s = get_startguesses(petab_prob, 50)
nothing # hide
```

Besides `LatinHypercubeSample`, `get_startguesses` also supports other sampling methods; for details, see the [API](@ref API). Given our starting points, we can perform multi-start parameter estimation:

```@example 1
res = Any[]
for x0 in x0s
    push!(res, calibrate(petab_prob, x0, IPNewton()))
end
nothing # hide
```

As manually generating start guesses and calling `calibrate` can be cumbersome, PEtab.jl provides a convenience function, `calibrate_multistart`. For example, to run `n = 50` multistarts, do:

```@example 1
Random.seed!(123) # hide
ms_res = calibrate_multistart(petab_prob, IPNewton(), 50)
```

The printout shows parameter estimation statistics, such as the best objective value `fmin` across all runs. For further details on what is stored in `ms_res` see the [API](@ref API) documentation for `PEtabMultistartResult`.

!!! tip "Parallelize Parameter Estimation"
    Runtime of `calibrate_multistart` can often be reduced by performing parameter estimation runs in parallel. To do this, set the `nprocs` keyword argument, more details can be found [here](@ref multistart_est).

Following multi-start parameter estimation, it is important to evaluate the results. One common evaluation approach is plotting, and a frequently used evaluation plot is the waterfall plot, which in a sorted manner shows the final objective values for each run:

```@example 1
plot(ms_res; plot_type=:waterfall)
```

In the waterfall plot, each plateau corresponds to different local optima. Since many runs (dots) are found on the plateau with the smallest objective value, we can be confident that the global optimum has been found. Further, we can check how well the best run fits the data:

```@example 1
plot(ms_res, petab_prob; linewidth = 2.0)
```

## Next Steps

This overarching tutorial provides an overview of how to create a parameter estimation problem in Julia. As an introduction, it showcases only a subset of the features supported by PEtab.jl for creating parameter estimation problems. In the extended tutorials, you will find how to handle:

- **Simulation conditions**: Sometimes data is gathered under various experimental conditions, where, for example, the initial concentration of a substrate differs between condition. To learn how to setup a problem with such simulation conditions see [this](@ref petab_sim_cond) tutorial.
- **Steady-State Initialization**: Sometimes the model should be at a steady state at time zero, before it is simulated and compared against data. To learn how to set up a problem with such pre-equilibration criteria, see [this](@ref define_with_ss) tutorial.
- **Events**: Sometimes a model may incorporate events like substrate addition at specific time points or parameter changes when a state/species reaches a certain value. To learn how to add model events see [this](@ref define_events) tutorial.
- **Condition-Specific System/Model Parameters**: Sometimes a subset of model parameters to estimate, such as protein synthesis rates, varies between simulation conditions, while other parameters remain constant across all conditions. To learn how to handle condition-specific parameters, see [this](@ref define_conditions) tutorial.
- **Time-Point Specific Parameters**: Sometimes one observable is measured with different assays. This can be handled by introducing different observable parameters (e.g., scale and offset) and noise parameters for different measurements. To learn how to add time-point-specific measurement and noise parameters, see [this](@ref time_point_parameters) tutorial.
- **Import PEtab Models**: PEtab is a standard table-based format for parameter estimation. If a problem is provided in this standard format, PEtab.jl can import it directly. To learn how to import models in the standard format, see [this](@ref import_petab_problem) tutorial.

Besides creating a parameter estimation problem, this overarching tutorial demonstrated how to perform parameter estimation using [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl). In addition, PEtab.jl also supports using [Ipopt](https://coin-or.github.io/Ipopt/), [Optimization.jl](https://github.com/SciML/Optimization.jl), and [Fides.py](https://github.com/fides-dev/fides). More information on available algorithms for parameter estimation can be found on [this](@ref pest_methods) page. Besides frequentist parameter estimation, PEtab.jl also supports Bayesian inference with state-of-the-art samplers such as [NUTS](https://github.com/TuringLang/Turing.jl) (the same sampler used in [Turing.jl](https://github.com/TuringLang/Turing.jl)) and [AdaptiveMCMC.jl](https://github.com/mvihola/AdaptiveMCMC.jl). For more information, see the Bayesian inference [page].

Lastly, when creating a `PEtabODEProblem` there are many configurable options (see the [API](@ref API)). The default options are based on extensive benchmarks for dynamic models in biology, see [this](@ref default_options) page. For how to configure models outside of biology, see [this](@ref nonstiff_models) page. Additionally, for a discussion on available gradient and Hessian methods, see [this](@ref gradient_support) page.

## Copy Pasteable Example

```@example 1
using Catalyst, PEtab
# Create the dynamic model(s)
t = default_t()
rn = @reaction_network begin
    @parameters S0 c3=1.0
    @species S(t)=S0
    c1, S + E --> SE
    c2, SE --> S + E
    c3, SE --> P + E
end
speciemap = [:E => 50.0, :SE => 0.0, :P => 0.0]

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
@mtkmodel SYS begin
    @parameters begin
        S0
        c1
        c2
        c3 = 1.0
    end
    @variables begin
        S(t) = S0
        E(t) = 50.0
        SE(t) = 0.0
        P(t) = 0.0
    end
    @equations begin
        D(S) ~ -c1 * S * E + c2 * SE
        D(E) ~ -c1 * S * E + c2 * SE + c3 * SE
        D(SE) ~ c1 * S * E - c2 * SE - c3 * SE
        D(P) ~ c3 * SE
    end
end
@mtkbuild sys = SYS()

# Observables
@unpack E, S = rn
obs_sum = PEtabObservable(S + E, 3.0)
@unpack P = rn
@parameters sigma
obs_p = PEtabObservable(P, sigma)
observables = Dict("obs_p" => obs_p, "obs_sum" => obs_sum)

# Parameters to estimate
using Distributions
p_c1 = PEtabParameter(:c1)
p_c2 = PEtabParameter(:c2; prior = Normal(10.0, 0.3))
p_s0 = PEtabParameter(:S0)
p_sigma = PEtabParameter(:sigma)
pest = [p_c1, p_c2, p_s0, p_sigma]

# Simulate measurement data with 'true' parameters
using OrdinaryDiffEq, DataFrames
ps = [:c1 => 1.0, :c2 => 10.0, :c3 => 1.0, :S0 => 100.0]
u0 = [:S => 100.0, :E => 50.0, :SE => 0.0, :P => 0.0]
tspan = (0.0, 10.0)
oprob = ODEProblem(rn, u0, tspan, ps)
sol = solve(oprob, Rodas5P(); saveat = 0:0.5:10.0)
obs_sum = (sol[:S] + sol[:E]) .+ randn(length(sol[:E]))
obs_p = sol[:P] + .+ randn(length(sol[:P]))
df_sum = DataFrame(obs_id = "obs_sum", time = sol.t, measurement = obs_sum)
df_p = DataFrame(obs_id = "obs_p", time = sol.t, measurement = obs_p)
measurements = vcat(df_sum, df_p)

model_sys = PEtabModel(sys, observables, measurements, pest)
model_rn = PEtabModel(rn, observables, measurements, pest; speciemap = speciemap)
petab_prob = PEtabODEProblem(model_rn)

# Parameter estimation
using Optim, Plots
x0 = get_startguesses(petab_prob, 1)
res = calibrate(petab_prob, x0, IPNewton())
plot(res, petab_prob; linewidth = 2.0)

ms_res = calibrate_multistart(petab_prob, IPNewton(), 50)
plot(ms_res; plot_type=:waterfall)
plot(ms_res, petab_prob; linewidth = 2.0)
nothing # hide
```

## References

```@bibliography
Pages = ["tutorial.md"]
Canonical = false
```
