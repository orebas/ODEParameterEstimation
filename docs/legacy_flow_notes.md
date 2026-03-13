# Legacy Flow Notes

**Date:** 2026-03-12

This document records potentially useful ideas from the removed legacy flow so they are not lost now that the old workflow surface has disappeared.

## Summary

The legacy flow that used to live in `src/core/multipoint_estimation.jl` was not worth keeping as a supported runtime path, but it did encode a few ideas that are still useful to remember:

- a clear three-phase structure: setup, solve, process
- a simple point-hint sweep model for multishot estimation
- a midpoint-offset heuristic when `shooting_points == 0`

None of these require keeping the legacy flow alive as a public execution mode.

## Ideas Worth Preserving

### 1. Explicit setup / solve / process phase split

The legacy flow made the decomposition obvious:

- `setup_parameter_estimation(...)`
- `solve_parameter_estimation(...)`
- `process_estimation_results(...)`

This is still a good mental model for the package, even though the supported standard flow now has more orchestration and rescue logic around it.

Why preserve it:

- easier debugging
- cleaner profiling
- easier future refactors toward a more explicit pipeline

Why not preserve the old flow for this:

- the current standard flow already reuses much of this decomposition internally
- keeping two public workflows just to preserve the phase model would create more confusion than value

### 2. Point-hint sweep as a simple multishot concept

The legacy `multishot_parameter_estimation(...)` did something straightforward:

- sweep `point_hint` values across the interval
- call the single-point estimator repeatedly
- pool the resulting candidates

This is algorithmically simpler than the current optimized multishot flow and may still be useful as:

- a debugging baseline
- a pedagogical example
- a fallback experimental script outside the core package path

Why preserve it only as a note:

- the optimized standard flow already supersedes it for supported use
- the simple sweep does not justify a second public flow with overlapping semantics

### 3. Midpoint offset when `shooting_points == 0`

The legacy multishot code special-cased:

- `shooting_points == 0` -> use `point_hint = 0.499`

instead of exactly `0.5`.

Intent:

- avoid pathological midpoint behavior in some symbolic/numeric constructions

This is a real heuristic, not just noise. It should be kept in mind if midpoint-specific regressions appear again.

Why it is not a legacy-flow reason to keep old code:

- if the heuristic is still useful, it should be documented or reintroduced explicitly where needed in the supported flow
- it does not require preserving the old workflow surface

## Ideas Not Worth Preserving as Runtime Surface

### 1. Public `FlowDeprecated` selection

This no longer helps users. It creates:

- duplicate semantics
- confusing documentation
- unsupported combinations
- extra validation/maintenance burden

### 2. Legacy compatibility shims around “new flow” selection

The old boolean compatibility language (`use_new_flow`) obscures what the real supported workflows are now.

## Recommendation

- Remove `FlowDeprecated` from the public API.
- Remove obvious legacy-selection language from examples/docs/comments.
- Keep this note as the posterity record for the few ideas that may still matter.
- If one of these ideas is worth reviving later, reintroduce it as:
  - an explicit helper,
  - an experimental option,
  - or a standalone example/debugging workflow,
  not as a second supported core flow.
