# Agent instructions for ODEParameterEstimation.jl

This file mirrors `CLAUDE.md` so non-Claude agents (Codex, etc.) pick up
the same guidance. The canonical version lives in `CLAUDE.md`; if the two
drift, prefer `CLAUDE.md`.

## Active integration notes

- [`docs/review_map.md`](docs/review_map.md) — canonical multi-agent review
  coordination map. Read this before starting broad code review, refactors, or
  review-lane assignment.

## Open investigations (read before starting reconditioning / numerical-stability work)

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

- **Always use `--startup-file=no`** when invoking Julia (Revise.jl
  causes exit segfaults on Julia 1.12).
- Use the global Julia environment (plain `julia`, NOT `julia --project`)
  for running tests.
- Run tests:
  `julia --startup-file=no -e 'using ODEParameterEstimation; include("test/fast_core.jl")'`
- Run feature regressions:
  `julia --startup-file=no -e 'using ODEParameterEstimation; include("test/feature_regressions.jl")'`
- Run examples:
  `julia --startup-file=no -e 'using ODEParameterEstimation; include("src/examples/run_examples.jl")'`

## Code Style

- Imports: group related packages; ModelingToolkit and OrdinaryDiffEq first.
- Types: prefer concrete types in function arguments, especially for core types.
- Functions: docstring with Arguments / Returns sections.
- Naming: snake_case for functions and variables, PascalCase for types.
- Parameters: use `OrderedDict` for parameters and states to maintain order.
- ODE convention: `t` is the independent variable; `D` is differentiation.
- Avoid `Any` in struct fields and signatures; ensure functions return
  consistent types; check critical functions with `@code_warntype`.

## Constants and Configuration

- Default ODE solver: `package_wide_default_ode_solver = AutoVern9(Rodas4P())`.
- Algorithm thresholds in `core_types.jl`.

## Naming Conventions

- Error thresholds: `XXX_THRESHOLD`.
- Tolerance argument names: `abstol` / `reltol` (not `atol` / `rtol`).
- Interpolant argument: `interp_func`.
- First positional argument: `problem` or `model` when applicable.
