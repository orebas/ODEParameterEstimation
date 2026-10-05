# Changelog

## 1.1.0 — registration candidate, 2026-10-05

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
  [the internalization record](docs/2026-10-04_internal_backends.md).

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
  [production readiness](docs/2026-09-10_production_readiness.md).

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

Oren selected **1.1.0** for the first registered release. The changes above are
relative to earlier unregistered development snapshots; no previous registered
release is being declared compatible. Subsequent registered releases should
follow semantic versioning for the documented public API.
