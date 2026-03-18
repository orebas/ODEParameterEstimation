# ODEParameterEstimation

[![Build Status](https://github.com/orebas/ODEParameterEstimation.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/orebas/ODEParameterEstimation.jl/actions/workflows/CI.yml?query=branch%3Amain)

`ODEParameterEstimation` estimates parameters and initial conditions for ODE models from observed time-series data. The current default path is the SI-template-based standard flow: structural identifiability comes from `SI.jl` / `StructuralIdentifiability`, numerical identifiability checks are advisory-only, and the analyzed results are returned in a structured tuple.

This README is the landing page. For the current package behavior as of 2026-03-17, start with:

- [User Quickstart](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_user_quickstart.md)
- [Results and API](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_results_and_api.md)
- [Supported Models and Limitations](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_supported_models_and_limitations.md)
- [Benchmark Contract Note](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_benchmark_contract.md)
- [Examples Directory Guide](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/README.md)

## Installation

If you are working from source, the simplest setup is to develop a local checkout:

```julia
using Pkg
Pkg.develop(path="/path/to/ODEParameterEstimation")
```

If you are installing directly from GitHub instead:

```julia
using Pkg
Pkg.add(url="https://github.com/orebas/ODEParameterEstimation.jl")
```

## Minimal Workflow

```julia
using ODEParameterEstimation

opts = EstimationOptions(
    datasize = 41,
    noise_level = 0.0,
    flow = FlowStandard,
    use_si_template = true,
    interpolator = InterpolatorAAAD,
    use_parameter_homotopy = false,
    save_system = false,
    polish_solver_solutions = false,
    polish_solutions = false,
)

pep = simple()
sampled = sample_problem_data(pep, opts)
raw_results, analysis, _ = analyze_parameter_estimation_problem(sampled, opts)

best = analysis[1][1]
best.parameters
best.states
best.all_unidentifiable
analysis[2]   # best max relative error on identifiable quantities
```

`analysis[1]` is the analyzed, clustered, oracle-ordered solution vector. `analysis[1][1]` is the canonical best analyzed result.

## Support Model

The package is currently best understood as:

- a standard SI-template workflow for supported polynomial/rational-style models
- an explicit structural-unidentifiability workflow, with representative structural fixes recorded in provenance
- an early-failing workflow for unsupported raw classes like state trig, raw `sqrt(...)`, and raw unsupported transcendental state dependence
- a package with some intentionally hard examples that run but are slower, weaker, or more weakly identified than the simple examples

For the current taxonomy and caveats, see [Supported Models and Limitations](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_supported_models_and_limitations.md).

## Notes

- The current public return contract is documented explicitly in [Results and API](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_results_and_api.md).
- Uncertainty quantification exists, but it is not part of the recommended default user path and is not the focus of the current user docs.
- The dated investigation docs under [docs](/home/orebas/.julia/dev/ODEParameterEstimation/docs) remain useful historical references, but they are no longer the main user-facing entry point.
