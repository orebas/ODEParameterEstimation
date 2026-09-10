# Changelog

## Unreleased (1.1.0-DEV line) — 2026-08/09

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
  versions, declare test imports, and contain diagnostic sidecars. CI checks
  both registered dependencies and reproducible modern GP/SIAN/SI patches.
- Update the quickstart, result contract, and review map. Verified environments,
  gate results, and remaining release work are recorded in
  [production readiness](docs/2026-09-10_production_readiness.md).

### BREAKING (intentional pre-release breaks; package is 1.1.0-DEV)

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

These breaks ride the 1.1.0-DEV pre-release line deliberately. If a registered
release is cut from this line, decide then between shipping as a breaking minor
(pre-1.0-style practice does not apply — this package is >1.0) or bumping to
2.0.0. Tracked decision, owner: Oren.
