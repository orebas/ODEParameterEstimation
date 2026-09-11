# ODEParameterEstimation

[![Build Status](https://github.com/orebas/ODEParameterEstimation.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/orebas/ODEParameterEstimation.jl/actions/workflows/CI.yml?query=branch%3Amain)

`ODEParameterEstimation` estimates parameters and initial conditions for ODE models from observed time-series data. The current default path is the SI-template-based standard flow: structural identifiability comes from `SI.jl` / `StructuralIdentifiability`, numerical identifiability checks are advisory-only, and the analyzed results are returned in a structured tuple.

This README is the landing page. Start with:

- [Reviewer Map](docs/review_map.md) for multi-agent code review coordination
- [User Quickstart](docs/2026-03-17_user_quickstart.md)
- [Results and API](docs/2026-03-17_results_and_api.md)
- [Supported Models and Limitations](docs/2026-03-17_supported_models_and_limitations.md)
- [Benchmark Contract Note](docs/2026-03-17_benchmark_contract.md)
- [Examples Directory Guide](src/examples/README.md)

For the Julia 1.13 dependency baseline, test results, and remaining release work,
see [Production readiness](docs/2026-09-10_production_readiness.md).

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

## Testing

Run package tests from the global Julia environment after developing the checkout:

```bash
julia --startup-file=no test/current.jl
```

`Pkg.test` creates an isolated test environment using `test/Project.toml`.
The wrapper uses `allow_reresolve=false`, preserving your active dependency
versions and development checkouts. A conflict with test dependencies fails
visibly. You do not need test imports installed directly in the global
environment. Always disable the startup file for Julia commands.

The full suite is required for changes affecting estimation. For a quick
contract check or the separate seeded, noisy recovery benchmark:

```bash
julia --startup-file=no test/current.jl unit
julia --startup-file=no test/current.jl benchmark
```

The unit group does not replace the full suite. Run the benchmark before a
cluster handoff. Each full-suite file receives a fixed random seed and its own
testset and module, so a failure in one file is reported while the remaining
files run, without leaking helper definitions. Tests run in temporary working
directories to contain diagnostic sidecars.

To check installation and tests without inheriting local dependency overrides:

```bash
julia --startup-file=no test/registered.jl
```

This develops the checkout in a temporary environment and requires every other
dependency to resolve from the registry. It also accepts `unit` or `benchmark`.
Until the GP and SIAN compatibility patches are released, this can select an
older dependency stack; it does not validate the current development stack.

## Minimal Workflow

```julia
using ODEParameterEstimation

opts = EstimationOptions(
    datasize = 41,
    noise_level = 0.0,
    flow = FlowStandard,
    use_si_template = true,
    interpolators = [InterpolatorAAAD],
    use_parameter_homotopy = false,
    save_system = false,
    polish_solver_solutions = false,
    polish_solutions = false,
)

pep = simple()
sampled = sample_problem_data(pep, opts)
raw_results, analysis, _ = analyze_parameter_estimation_problem(sampled, opts)

best = first(analysis.returned_results)
best.parameters
best.states
best.all_unidentifiable
analysis.best_max_error   # validation metric when ground truth is available
```

`analysis.returned_results` contains the analyzed and clustered results, ranked by the configured strategy (trajectory fit error by default). Its first entry is the selected estimate. Ground truth is used for validation metrics, not for the default ranking.

## Support Model

The package is currently best understood as:

- a standard SI-template workflow for supported polynomial/rational-style models
- an explicit structural-unidentifiability workflow, with representative structural fixes recorded in provenance
- an early-failing workflow for unsupported raw classes like state trig, raw `sqrt(...)`, and raw unsupported transcendental state dependence
- a package with some intentionally hard examples that run but are slower, weaker, or more weakly identified than the simple examples

For the current taxonomy and caveats, see [Supported Models and Limitations](docs/2026-03-17_supported_models_and_limitations.md).

## Notes

- The current public return contract is documented explicitly in [Results and API](docs/2026-03-17_results_and_api.md).
- Uncertainty quantification exists, but it is not part of the recommended default user path and is not the focus of the current user docs.
- The optional [PEtab pilot](docs/petab.md) supports a restricted benchmark
  subset with joint experiments, independent observation grids and exact PEtab
  likelihood scoring. Its integration tests run separately from the core gates.
  RS/RUR restoration remains deferred; see the
  [readiness record](docs/2026-09-10_production_readiness.md#optional-integrations).
- The dated investigation docs under [docs](docs) remain useful historical references, but they are no longer the main user-facing entry point.
