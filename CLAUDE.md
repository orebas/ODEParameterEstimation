# ODEParameterEstimation.jl Guidelines

## Active integration notes

- [`docs/review_map.md`](docs/review_map.md) — canonical multi-agent review
  coordination map. Read this before starting broad code review, refactors, or
  review-lane assignment.
- [`MULTIPLICITY_INTEGRATION.md`](MULTIPLICITY_INTEGRATION.md) — algebraic
  multiplicity (M) auto-detection: production behavior, the registered Groebner
  baseline and historical PR #218 fix, and PEB integration context. Read
  before working on result.csv truncation or multiplicity.

## Open investigations (read before starting reconditioning / numerical-stability work)

- **UQ regime + production contract.** Start with the audited PEB LV/VDP/FHN
  canaries
  [`docs/2026-08-14_peb_audited_uq_canaries.md`](docs/2026-08-14_peb_audited_uq_canaries.md),
  then read the current routing/API contract
  [`docs/2026-08-14_estimator_aware_uq.md`](docs/2026-08-14_estimator_aware_uq.md)
  and empirical recap
  [`docs/2026-08-14_uq_session_recap.md`](docs/2026-08-14_uq_session_recap.md)
  and the GP-jet bias decision note
  [`docs/2026-08-14_gp_jet_bias_decision_note.md`](docs/2026-08-14_gp_jet_bias_decision_note.md)
  and the staged research protocol
  [`docs/2026-08-15_estimation_uq_research_program.md`](docs/2026-08-15_estimation_uq_research_program.md)
  and its completed LV Stage 1--3 decision record
  [`docs/2026-08-16_lv_multipoint_bias_results.md`](docs/2026-08-16_lv_multipoint_bias_results.md)
  and the model-assisted correction prototype/discovery record
  [`docs/2026-08-16_model_assisted_correction_discovery.md`](docs/2026-08-16_model_assisted_correction_discovery.md)
  and its repeated-noise/polish decision record
  [`docs/2026-08-16_model_assisted_repeated_noise.md`](docs/2026-08-16_model_assisted_repeated_noise.md)
  and the clean-revision audited hard-model campaign
  [`docs/2026-08-16_audited_repeated_uq_campaign.md`](docs/2026-08-16_audited_repeated_uq_campaign.md)
  before touching uncertainty quantification. Production UQ targets exactly the
  returned rank-one estimator and supports retained SP/MP algebraic roots,
  trajectory polish/direct score equations, and branch propagation. The N=60
  low-noise calibration result applies to the single-point estimator; nonlinear
  MP/polish coverage remains to be established. The older package-constructor
  pilot is routing stress, not audited model evidence. `:degenerate` is only the
  legacy summary flag: inspect `uq_reliability`'s separate numerical and
  interval-width axes, and never read a single-run status as a calibration
  certificate.

- **Variable (column) scaling of the polynomial system.** ODEPE now has
  power-of-2 problem rescaling (`auto_rescale`) and column scaling for
  parameterized HC systems (`use_column_scaling`), both enabled by default.
  Start with [`src/core/problem_rescaling.jl`](src/core/problem_rescaling.jl),
  [`src/core/homotopy_continuation.jl`](src/core/homotopy_continuation.jl),
  and their tests in `test/test_rescaling.jl` and `test/column_scaling.jl`.
  HC.jl also performs Skeel row scaling automatically. The diagnostic numbers
  and proposed implementation levels in
  [`docs/2026-05-01_variable_scaling_investigation.md`](docs/2026-05-01_variable_scaling_investigation.md)
  predate these implementations; use them as historical evidence when
  investigating remaining conditioning problems.

## Build/Test Commands
- **Always use `--startup-file=no`** when invoking Julia (Revise.jl caused exit segfaults on Julia 1.12).
- Start local tests from the global Julia environment (plain `julia`, not `julia --project`). `Pkg.test` creates the isolated test environment and installs the dependencies declared in `test/Project.toml`.
- **Full FAST gate** (required for estimation-touching changes):
  `julia --startup-file=no -e 'using Pkg; Pkg.test("ODEParameterEstimation"; allow_reresolve=false)'`
- **Quiet unit contracts** (does not replace the full gate):
  `julia --startup-file=no -e 'using Pkg; Pkg.test("ODEParameterEstimation"; allow_reresolve=false, test_args=["unit"])'`
- **Benchmark smoke** (seeded, noisy, full-scale recovery guard; run before handing a build to the cluster):
  `julia --startup-file=no -e 'using Pkg; Pkg.test("ODEParameterEstimation"; allow_reresolve=false, test_args=["benchmark"])'`
- `test/current.jl` wraps these commands, records the active environment, and verifies that it points at this checkout. `allow_reresolve=false` preserves dependency versions and local development paths; a test dependency conflict must fail visibly.
- The full gate includes feature regressions and example smoke tests. Direct `include("test/...")` commands require their imports to be direct dependencies of the active environment; they are not a substitute for checking `Pkg.test`.
- For dependency/registration checks, run `julia --startup-file=no test/registered.jl` to resolve and test a fresh temporary environment using registered dependencies. Do not infer reproducibility from a global environment containing local development overrides. The current baseline and remaining release work are in [`docs/2026-09-10_production_readiness.md`](docs/2026-09-10_production_readiness.md).

## Code Style Guidelines
- Imports: Group related packages, with ModelingToolkit, OrdinaryDiffEq first
- Types: Use concrete types for function arguments, especially core types
- Functions: Document with docstrings using the triple quote format with Arguments/Returns sections
- Naming: Use snake_case for functions/variables, PascalCase for types
- Error handling: Use informative error messages with try/catch for numerical operations
- Parameters: Use OrderedDict for parameters and states to maintain consistent ordering
- ODE convention: Use t as the independent variable, D for differentiation
- Documentation: Document complex algorithms with explanatory inline comments

## Type Stability Guidelines
- Avoid `Any` type in struct fields and function signatures
- Ensure functions return consistent types
- Use concrete parameter types instead of generic ones
- Add explicit return type annotations to complex functions
- Prefer using Union types over Any when multiple specific types are possible
- Use @code_warntype to check for type instabilities in critical functions

## Constants and Configuration
- Default ODE solver: `package_wide_default_ode_solver = AutoVern9(Rodas5P())`
- Algorithm thresholds are defined in core_types.jl

## Naming Conventions
- Error thresholds: Use descriptive names with consistent notation (e.g., `XXX_THRESHOLD`)
- Function parameters: Use consistent names across similar functions:
  - `abstol`/`reltol` for tolerances (not atol/rtol)
  - `interp_func` for interpolation functions
  - Put `problem` or `model` as first parameter when applicable
- File organization: Keep related functionality in the same file or module
