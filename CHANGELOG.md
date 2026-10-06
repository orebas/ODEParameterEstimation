# Changelog

## 1.0.0 — registration candidate, 2026-10-05

This is the intended first registered release. Earlier source-install users
should review the development-snapshot changes below. Registration and tagging
are separate from preparing this candidate.

### Release preparation

- Check high derivatives of the optimized noiseless GP against its analytic
  generating curve, with measured BLAS portability budgets. Retain strict
  fixed-parameter upstream contracts and noisy-fit comparisons.
- Record numerical-runtime metadata and preserve resolved CI manifests.
- Build a split reference for the exported API with Documenter 1.19.
- Prepare the `ODEParameterEstimation.jl` repository URL, user documentation,
  and release workflows for Julia 1.12 and 1.13.

### Estimates are refined by default — 2026-10-06

- `polish_solutions` now defaults to `true`: each solution of the equations is
  fitted to the data by least squares before it is returned. On Lotka–Volterra
  with 101 points and 2% noise, the worst parameter error fell from 30% to 2%.
  On exact data the estimates of six models, `hiv` among them, stayed exact.
  `polish_solutions = false` returns the solutions of the equations as they
  are.
- With `compute_uncertainty = true`, the standard errors now describe the
  refined estimate, since that is the one returned.

### One way to choose interpolators — 2026-10-06

- Remove the `interpolator` and `custom_interpolator` options. Beside the
  default `interpolators` list they had no effect: a run that set
  `interpolator = InterpolatorAAAD` used all nine default interpolators. Name
  the interpolators to use in `interpolators`, and give the functions for its
  `InterpolatorCustom` entries in `custom_interpolators`.
- Setting a removed option is an error, and `estimate` points to the list form.
  An empty `interpolators` list is refused, since there is no longer a single
  interpolator to fall back on.
- Tests and examples that set only the removed option ran the default list, and
  still do. The few that emptied the list to reach the single interpolator now
  name it in the list.

### A short path from a model and data to estimates — 2026-10-06

- Add `ParameterEstimationProblem(system, measured_quantities; data, true_values, name, solver)`.
  It takes a ModelingToolkit `System` as it is, completed or compiled or
  neither, and data under the names of the measured quantities: a
  `NamedTuple`, a dictionary, or a table with named columns. True values are
  optional. Numbers the system carries, as in `@parameters a = 0.4`, are used
  when present. The nine-argument constructor is unchanged.
- Add `estimate(problem; options...)`, which returns the solutions found, best
  fit first. A mistyped option name is reported by name.
- Results print as a short table that marks parameters the data cannot
  determine. `result[a]`, `result[:a]` and `result["a"]` look up one value.
- `sample_problem_data(problem; datasize = 51, noise_level = 0.01)` takes its
  options by keyword, as `estimate` does. It reports which true values are
  missing instead of simulating with `NaN`.
- For a model with a `sin(c*t)`, `cos(c*t)` or `exp(c*t)` input, `estimate`
  returns the model's own states only, without the helper states the input is
  rewritten with.
- A model that is not rational is refused before any work is done, in a
  message that quotes the term as it was written. The messages of
  `UnsupportedModelClassError`, `UnsupportedDerivativeOrderError` and
  `SamplingFailureError` are rewritten for users, and the three are documented.
- `create_ordered_ode_system` names the system after its `name` argument. It
  was always named `model`.
- Rewrite the docstrings a user meets first: `EstimationOptions`, which now
  describes every option, `ParameterEstimationProblem`,
  `ParameterEstimationResult`, `ObservationData` and `ObservationSeries`.
  Document `analyze_parameter_estimation_problem` and the package itself.

### Two fixes found while writing the manual — 2026-10-06

- A `sin(c*t)` or `cos(c*t)` input gave a wrong coefficient when the data
  covered a stretch on which the input stayed small. Rescaling halved the
  helper state for the input and doubled its coefficient, while the state's
  values were filled in unscaled. On `forced_decay` over `[-0.5, 0.5]` the
  input's coefficient came back as 4 instead of 2. Helper states are no longer
  rescaled.
- State names that are not ASCII, such as `θ(t)`, raised `StringIndexError` in
  models with a quantity that cannot be determined, because names were cut by
  byte offset.

### A manual — 2026-10-06

- Replace the README and the Documenter site with documentation written for
  someone meeting the package for the first time: a getting-started page,
  tutorials on your own data, noisy data, models with more than one answer and
  uncertainty, guides to supported models, options, results, the method and
  troubleshooting, and a reference split into the main API and everything
  else. Every example runs when the site is built.
- Publish the site from a new `Documentation` workflow.
- Remove `examples/estimation_options_example.jl`, which no longer ran, rewrite
  `src/examples/first_example.jl` for the short path, and move the
  biohydrogenation benchmark script out of the repository root.

### Quiet by default — 2026-10-06

- A run with default options now prints nothing, passes only errors to the
  logger, and writes no files. The defaults changed to `nooutput = true`,
  `diagnostics = false` and `save_system = false`. Estimates are unaffected:
  with a seed, all combinations of these flags gave identical candidate pools
  on `simple` and Lotka–Volterra. Set `nooutput = false` or
  `diagnostics = true` for the earlier output.
- Add `progress = true`, which prints one timestamped line as each phase starts
  and finishes, and nothing else.
- The candidate-synthesis log (`synthesis_log.csv`) is written only with
  `diagnostics = true`. It had been written on every run.
- Options are checked before output is silenced, so configuration warnings and
  errors are still shown.
- Counting the solutions of a candidate system no longer draws
  HomotopyContinuation's progress meter, which has no switch and showed on
  stderr for models slow enough to trigger it.

### Reproducible runs — 2026-10-05

- Add `EstimationOptions(seed = ...)`. With an integer, `sample_problem_data`
  and the estimation entry points each run on their own random stream and then
  restore Julia's default RNG. Repeated runs give identical results, and the
  caller's random stream is untouched. The default, `nothing`, keeps the
  earlier behavior of drawing from the caller's default RNG.
- Without a seed, the candidate pool for `simple` and Lotka–Volterra differed
  on every run and the selected `simple` estimate alternated between two
  candidates. With a seed, fresh processes with one and four threads returned
  identical pools.

### Levenberg–Marquardt name clash — 2026-10-05

- `LevenbergMarquardt` is exported by both NonlinearSolve and LeastSquaresOptim,
  so the unqualified name had been undefined in the package since
  LeastSquaresOptim was added on 2026-05-06. Qualify it in `solve_with_robust`,
  where `:algorithm => :levenberg` returned no solution, and in
  `solve_multipoint_overdetermined`, whose refinement step was silently skipped.
- Remove `PolishLevenberg` and `PolishGaussNewton`. NonlinearSolve algorithms
  are not optimizers for the scalar `Optimization.solve` polish, so the first
  raised `UndefVarError` and the second failed every polish. Use
  `PolishLSOBoundedLog` (the default) or `PolishFastLMBoundedLog` for
  Levenberg–Marquardt polishing.
- Add contracts: every remaining polish method yields a runnable optimizer,
  and no package method references a name that two imports both export.

### Dependency cleanup — 2026-10-05

- Remove eight declared dependencies that the package did not use. `Plots`,
  `Zygote`, `BlackBoxOptim` and `MultivariatePolynomials` were never imported.
  `DynamicPolynomials` and `PolynomialRoots` were imported without a call
  site. `Enzyme` and `SciMLSensitivity` served only the backend removed below.
- Remove `opt_ad_backend = :enzyme`. Enzyme cannot compile the trajectory
  loss, which rebuilds the ODE problem through symbolic indexing. In testing,
  `:enzyme` polishes raised after a long compilation and kept the unpolished
  candidate. `validate_options` now rejects the value before any estimation
  work; `:forward` (the default) and `:finite` are unchanged.
- A fresh registered resolve on Julia 1.13.1 selects 308 packages instead of
  434, adds none, and changes one indirect version (UnsafeAtomics 0.3.2 to
  0.3.3). GPUCompiler, where the advisory nightly job fails, is no longer in
  the graph. Median warm load time fell from 16.3 s to 12.5 s on the
  development machine.

### GP workspace reuse — 2026-10-05

- Reuse covariance, factorization and gradient scratch buffers within each
  internal GP fit, preserving fitting arithmetic and independent posteriors.
- Reduce allocated bytes by 98% on the measured 201-point fit (50.6 MB to
  0.99 MB); median fitting time fell from 34.9 ms to 32.0 ms in the paired run.
  Frozen fits still match upstream through derivative order six on Julia
  1.12 and 1.13. Add workspace recovery, ownership and allocation contracts.

### Internal dependency backends — 2026-10-04

- Replace the used SIAN-Julia helpers and GaussianProcesses.jl dense SE fit
  with private modules under `src/internal`, retaining upstream MIT notices
  and documented replacement boundaries.
- Preserve the GP interpolator option, fitting policy and higher derivatives;
  retain AGP/AGPUQ as separate implementations. Remove GP, SIAN and the direct
  PDMats dependency, including the GP-specific global method bridge.
- Replace CI's dependency fork checkouts with registered default and modern
  dependency profiles. Add frozen upstream contracts and optional paired
  recovery/performance tools outside the standard test dependency graph.
- Remove the wall-clock cap from the direct-optimizer UQ convergence canary;
  retain its iteration limit and numerical assertions. Production timeouts and
  their dedicated tests are unchanged.
- Record equivalence results, performance costs and remaining release work in
  [the internalization record](docs/internal/2026-10-04_internal_backends.md).

### Julia 1.13 stabilization

- Normalize dictionary inputs in all `ParameterEstimationResult` constructors
  explicitly for OrderedCollections 2, preserving already typed ordered maps.
- Match states and parameters by symbolic key when clustering results.
- Repair exported derivative utilities and clear equation denominators on both
  sides; restore their tests to the unit and full gates.
- Use `Symbolics.diff2term` at symbolic conversion sites and bound ForwardDiff
  chunk size in the noise-frontier rank probe to reduce compilation cost.
- Bridge the autonomous-model SI dispatch issue only on affected versions that
  lack the upstream method; patched SI checkouts receive no redundant bridge.
- Run isolated test files through `Pkg.test`, preserve active development
  versions, declare test imports, and contain diagnostic sidecars. CI initially
  checked registered dependencies and reproducible modern GP/SIAN/SI patches;
  the October internalization supersedes that patched setup.
- Update the quickstart, result contract, and review map. Verified environments,
  gate results, and remaining release work are recorded in
  [production readiness](docs/internal/2026-09-10_production_readiness.md).

### Changes from earlier development snapshots

- **`EstimationOptions`: 13 fields removed** (2026-08-12/13 dead-options
  cleanup): `rtol`, `output_precision`, `imag_threshold`, `branch_resid_factor`,
  `branch_min_size`, `max_deriv_level`, `trap_debug`, `display_system`,
  `use_monodromy`, `si_infolevel`, `log_dir`, `polish_only`, `ideal`. None had a
  live consumer (audit-verified; PEB sets none). Setting one now errors loudly
  at construction. Four previously-dead fields were WIRED instead (defaults
  preserve old behavior exactly): `clustering_threshold`, `si_probability`,
  `point_hint`, `save_filepath`. New fields: `hc_threading`, `hc_compile_mode`,
  `heartbeat`.
- **`ResultProvenance`: `residual_fix_set` removed;
  `template_status_before/after_residual_fix` collapsed to `template_status`**
  (2026-08-12; the pair was identical by construction and the set always empty —
  no residual-repair mechanism ever existed). Metadata writers should use the
  new exported `provenance_metadata_dict`.
- `solve_with_hc` lost its dead `use_monodromy`/`display_system` kwargs.

### Added

- `provenance_metadata_dict(::ResultProvenance)` — exported single source for
  the `odepe_metadata.json` provenance block (consumed by PEB + experiments
  templates).
- Default-on `[HB]` phase heartbeats (`EstimationOptions.heartbeat`).
- Scoped `RunContext` (auto-M hand-off, timing, per-analysis HC solver config).
- `_rethrow_if_interrupt` cancellation discipline across all production catches.

### Versioning note

Oren selected **1.0.0** for the first registered release. The changes above are
relative to earlier unregistered development snapshots; no previous registered
release is being declared compatible. Subsequent registered releases should
follow semantic versioning for the documented public API.
