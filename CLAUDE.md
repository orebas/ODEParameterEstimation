# ODEParameterEstimation.jl Guidelines

## Active integration notes

- [`docs/review_map.md`](docs/review_map.md) — canonical multi-agent review
  coordination map. Read this before starting broad code review, refactors, or
  review-lane assignment.
- [`MULTIPLICITY_INTEGRATION.md`](MULTIPLICITY_INTEGRATION.md) — algebraic
  multiplicity (M) auto-detection: what's in production, the Groebner.jl
  PR #218 dependency, expected behavior, and what PEB needs to change. Read
  before working on result.csv truncation or multiplicity.

## Open investigations (read before starting reconditioning / numerical-stability work)

- **UQ regime + calibration status.** Read
  [`docs/2026-08-14_uq_session_recap.md`](docs/2026-08-14_uq_session_recap.md)
  before touching uncertainty quantification. Key facts: Σ_x is the sampling
  covariance of the *unpolished single-point algebraic estimator* conditioned on
  one SE-kernel GP fit — it is calibrated against that estimator at low noise
  (med |z| ≈ 0.674 target) and becomes overconfident as noise grows; it does
  NOT describe the polished estimate we normally report. `:degenerate` status
  means "out of regime", not "broken". Harness + reproduction commands live in
  `repro/uq_coverage_harness_2026_08/`.

- **Variable (column) scaling of the polynomial system.** Diagnostics on
  the IEEE paper's challenging systems (biohydrogenation, daisy_mamil4)
  show Jacobian condition numbers of 1e+6 to 1e+10 at low noise, driving
  recovery error far above what derivative accuracy alone would predict.
  HC.jl already does Skeel **row** scaling automatically; ODEPE does not
  do **column** scaling. Implementing variable rescaling at the earliest
  level possible is on the wishlist. Three implementation levels and the
  diagnostic numbers are in
  [`docs/2026-05-01_variable_scaling_investigation.md`](docs/2026-05-01_variable_scaling_investigation.md).
  See also the top entry in `TODO`.

## Build/Test Commands
- **Always use `--startup-file=no`** when invoking Julia (Revise.jl causes exit segfaults on Julia 1.12)
- Use global Julia environment (plain `julia`, NOT `julia --project`) for running tests
- Run tests: `julia --startup-file=no -e 'using ODEParameterEstimation; include("test/fast_core.jl")'`
- Run feature regressions: `julia --startup-file=no -e 'using ODEParameterEstimation; include("test/feature_regressions.jl")'`
- Run specific test: `julia --startup-file=no -e 'using ODEParameterEstimation; include("test/specific_test.jl")'`
- Run examples: `julia --startup-file=no -e 'using ODEParameterEstimation; include("src/examples/run_examples.jl")'`
- **Full FAST gate** (the only valid gate for estimation-touching changes — fast_core alone is contracts-only): `julia --startup-file=no -e 'include("test/runtests.jl")'`
- **Benchmark smoke** (seeded, noisy, full-scale recovery guard; NOT in runtests — run before handing a build to the cluster): `julia --startup-file=no -e 'using ODEParameterEstimation; include("test/benchmark_smoke.jl")'`

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
- Default ODE solver: `package_wide_default_ode_solver = AutoVern9(Rodas4P())`
- Algorithm thresholds are defined in core_types.jl

## Naming Conventions
- Error thresholds: Use descriptive names with consistent notation (e.g., `XXX_THRESHOLD`)
- Function parameters: Use consistent names across similar functions:
  - `abstol`/`reltol` for tolerances (not atol/rtol)
  - `interp_func` for interpolation functions
  - Put `problem` or `model` as first parameter when applicable
- File organization: Keep related functionality in the same file or module
