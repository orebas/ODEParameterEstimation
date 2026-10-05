# ODEParameterEstimation.jl

[![Build Status](https://github.com/orebas/ODEParameterEstimation.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/orebas/ODEParameterEstimation.jl/actions/workflows/CI.yml?query=branch%3Amain)

`ODEParameterEstimation` estimates parameters and initial conditions for ODE models from observed time-series data. The current default path is the SI-template-based standard flow: structural identifiability comes from `SI.jl` / `StructuralIdentifiability`, numerical identifiability checks are advisory-only, and the analyzed results are returned in a structured tuple.

This README is the landing page. Start with:

- [Reviewer Map](docs/review_map.md) for multi-agent code review coordination
- [User Quickstart](docs/2026-03-17_user_quickstart.md)
- [Results and API](docs/2026-03-17_results_and_api.md)
- [Supported Models and Limitations](docs/2026-03-17_supported_models_and_limitations.md)
- [Benchmark Contract Note](docs/2026-03-17_benchmark_contract.md)
- [Examples Directory Guide](src/examples/README.md)

For the ordered work toward registration, see [Registry preparation](docs/registry_preparation.md).
The complete experimental source, historical benchmark scripts, PEtab pilot,
and evidence remain on the [research branch](https://github.com/orebas/ODEParameterEstimation.jl/tree/research).

The GaussianProcesses.jl fitting route and SIAN equation-construction helpers
are maintained in isolated internal modules with upstream attribution. Neither
external package is required to install or test ODEPE. See
[internal backends](docs/2026-10-04_internal_backends.md) for provenance and validation.

## Installation

Version **1.1.0** is being prepared for first registration. Until it is
registered, install from GitHub or a local checkout. Julia 1.12 or later is
required; the release CI covers Julia 1.12 and 1.13.

If you are working from source, the simplest setup is to develop a local checkout:

```julia
using Pkg
Pkg.develop(path="/path/to/ODEParameterEstimation")
```

If you are installing directly from GitHub instead:

```julia
using Pkg
Pkg.add(url="https://github.com/orebas/ODEParameterEstimation.jl.git")
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
Add a second argument, `modern`, to require the newer supported dependency
families, for example `julia --startup-file=no test/registered.jl benchmark modern`.
Both profiles reject GaussianProcesses and SIAN in the resolved dependency graph.

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
- Uncertainty quantification is opt-in. Audited single-point calibration does
  not establish coverage for nonlinear multipoint or polished estimators;
  see the [UQ contract](docs/2026-08-14_estimator_aware_uq.md).
- The PEtab pilot, RS/RUR extension, consensus research APIs, and SHADE+LM
  comparison baseline are retained on the research branch. They are outside
  this branch's package API.
- The dated investigation docs under [docs](docs) remain historical references.

## License and attribution

The package uses [GPL-3.0](LICENSE). The adapted GP and SIAN modules retain
their upstream MIT notices. Source and fixture provenance is summarized in
the [release attribution review](docs/registry_preparation.md#provenance-and-attribution).
