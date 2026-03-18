# User Quickstart

This guide reflects the package state as of 2026-03-17.

The normal workflow is:

1. Construct a `ParameterEstimationProblem`.
2. Choose `EstimationOptions`.
3. Generate or attach data with `sample_problem_data`.
4. Run `analyze_parameter_estimation_problem`.
5. Read the analyzed solutions from `analysis[1]`.

For a broader description of the current API, see [2026-03-17_results_and_api.md](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_results_and_api.md).

## Happy Path Example

`simple()` is a good first model because it is small and currently behaves like a supported clean example.

```julia
using ODEParameterEstimation

opts = EstimationOptions(
    datasize = 41,
    noise_level = 0.0,
    flow = FlowStandard,
    use_si_template = true,
    interpolator = InterpolatorAAAD,
    use_parameter_homotopy = false,
    nooutput = true,
    diagnostics = false,
    save_system = false,
    polish_solver_solutions = false,
    polish_solutions = false,
)

pep = simple()
sampled = sample_problem_data(pep, opts)
raw_results, analysis, _ = analyze_parameter_estimation_problem(sampled, opts)

best = analysis[1][1]
println(best.parameters)
println(best.states)
println(analysis[2])
```

What to expect:

- `raw_results[1]` contains raw candidate solutions from the estimation workflow.
- `analysis[1]` contains clustered, analyzed solutions.
- `analysis[1][1]` is the canonical best analyzed result.
- `analysis[2]` is the best max relative error on identifiable quantities.

## Structural-Unidentifiability Example

`trivial_unident()` is a good example of the supported structural-unidentifiability path.

```julia
using ODEParameterEstimation

opts = EstimationOptions(
    datasize = 41,
    noise_level = 0.0,
    flow = FlowStandard,
    use_si_template = true,
    interpolator = InterpolatorAAAD,
    use_parameter_homotopy = false,
    nooutput = true,
    diagnostics = false,
    save_system = false,
    polish_solver_solutions = false,
    polish_solutions = false,
)

pep = trivial_unident()
sampled = sample_problem_data(pep, opts)
_, analysis, _ = analyze_parameter_estimation_problem(sampled, opts)

best = analysis[1][1]
println(best.all_unidentifiable)
println(best.provenance.structural_fix_set)
```

What to expect:

- `best.all_unidentifiable` contains the structural-unidentifiable variables.
- `best.provenance.structural_fix_set` records the representative structural fix set used to make the SI template determined.
- The supported default flow does not do the old heuristic residual square repair anymore.

## Beginner Options That Matter

For a first run, these options matter most:

- `datasize`
  Number of sampled data points.
- `noise_level`
  Synthetic noise level when using `sample_problem_data`.
- `flow`
  Usually `FlowStandard`.
- `use_si_template`
  Usually `true` for the standard path.
- `interpolator`
  Start with `InterpolatorAAAD` or `InterpolatorAAADGPR`.
- `use_parameter_homotopy`
  Can speed up multi-shot runs when enabled.
- `polish_solver_solutions` and `polish_solutions`
  Keep these `false` for a fast first run unless you are specifically testing polishing.
- `diagnostics`
  Turn this on when you want detailed logs.

The full options surface is defined in [estimation_options.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/types/estimation_options.jl), but most users should start with a small subset.

## Where to Look Next

- [2026-03-17_results_and_api.md](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_results_and_api.md) for the current return contract and result interpretation
- [2026-03-17_supported_models_and_limitations.md](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_supported_models_and_limitations.md) for what the package currently supports
- [src/examples/README.md](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/README.md) for the maintained example surface
