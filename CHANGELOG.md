# Changelog

## Unreleased (1.1.0-DEV line) — 2026-08

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
