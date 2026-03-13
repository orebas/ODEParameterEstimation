# Cleanup / Consolidation Review

**Date:** 2026-03-12

**Status:** Review-first recommendations based on the current checked-out tree, targeted code-path inspection, and the current green fast suite.

## Summary

The package is converging on a coherent core, but it still mixes three different kinds of behavior:

1. true algorithmic steps that are part of the intended method,
2. operational scaffolding for structurally unidentifiable variables, and
3. hidden rescue behavior that can mask faults or blur method identity.

The main recommendation is to preserve the first two, but separate and surface them explicitly.

The intended long-term shape should be:

- `FlowStandard` as the supported algebraic workflow
- `FlowDirectOpt` as the separate direct-optimization workflow
- one hardened `EstimationOptions` surface
- explicit rescue policy knobs
- explicit result lineage and provenance
- no generic fabricated values for identifiable variables
- no silent cross-paradigm fallback hidden inside "polishing"

The current fast suite is a useful baseline and passed cleanly at the time of this review:

- `test/runtests.jl`: 129 passed, 0 failed, 0 errored

The new extended lane exists for slow but valuable regressions:

- `test/runtests_extended.jl`

## Current Verified Contract

These behaviors are already effectively part of the current contract and should be treated as intentional unless explicitly changed later:

- `FlowDeprecated` has been removed from the public flow enum. The supported flows are `FlowStandard` and `FlowDirectOpt`.
- Structurally unidentifiable variables may be given representative completion values, but only when they are already in the full `all_unidentifiable` set.
- Missing identifiable parameters or states in SI reconstruction are hard failures.
- Algebraic `t=0` re-solve after a blown backsolve is an intended rescue path for numerically non-backsolvable models.
- Direct optimization can still act as a terminal rescue when no algebraic candidates exist, but this behavior is currently hidden behind `polish_solutions` and only partially surfaced via `return_code`.
- Benchmark/error reporting is supposed to exclude the full `all_unidentifiable` set, not just the subset that received representative values.

## Findings

### Critical

#### 1. Fixed-parameter state resolve still contains generic `0.0` fabrication

**Where:** `src/core/si_template_integration.jl`

`resolve_states_with_fixed_params()` still has an older cascading-substitution fallback that:

- converts failed symbolic-to-Float64 resolutions to `0.0`
- warns and continues
- may return partial solutions whose missing values are later completed elsewhere

This is not the same as the intentional representative completion policy for known structurally unidentifiable variables. It is a generic numeric fabrication path inside the rescue solver itself.

**Recommendation**

- Remove generic `0.0` insertion from `resolve_states_with_fixed_params()`.
- That function should return one of:
  - full algebraic solutions,
  - partial solutions with explicit "missing variables" metadata,
  - or no solutions.
- Representative completion should happen only at one higher layer, after classification:
  - known structurally unidentifiable variable -> allow representative completion
  - unresolved identifiable variable -> fail or enter an explicit seeded rescue lane

**Target ownership**

- Package core

#### 2. Result provenance is fragmented and too weak for debugging, comparison, or benchmarking

**Where:** `src/types/core_types.jl`, `src/core/optimized_multishot_estimation.jl`

The package currently uses:

- `return_code` for some rescue cases
- `interpolator_source` for multi-interpolator attribution
- `all_unidentifiable` and `unident_dict` for identifiability context

This is not enough to reconstruct how a result was actually produced. In particular, it cannot cleanly distinguish:

- ordinary algebraic success
- algebraic success with representative completion for unidentifiable variables
- `t=0` algebraic rescue
- seeded rescue for polishing
- direct-opt fallback
- which shooting point or candidate lineage produced the result
- how much polishing changed the candidate
- whether the final best result originated from AAAD, a multi-interpolator run, or another explicit orchestration path

**Recommendation**

- Replace the current ad hoc mix with a first-class lineage/provenance object on `ParameterEstimationResult`.
- Keep `return_code` only as a temporary compatibility bridge.

**Recommended shape**

```julia
struct ResultProvenance
    primary_method::Symbol
    interpolator_source::Union{Nothing, Symbol}
    rescue_path::Symbol
    source_shooting_index::Union{Nothing, Int}
    source_candidate_index::Union{Nothing, Int}
    pre_polish_error::Union{Nothing, Float64}
    post_polish_error::Union{Nothing, Float64}
    polish_applied::Bool
    representative_assignments::OrderedDict{Num, Float64}
    notes::Vector{Symbol}
end
```

**Required conventions**

- `primary_method`: `:algebraic` or `:direct_opt`
- `rescue_path`: `:none`, `:algebraic_resolve_t0`, `:algebraic_resolve_seeded`, `:direct_opt_fallback`
- `source_shooting_index`: the shooting point that generated the candidate before any later clustering/ranking
- `source_candidate_index`: stable index within the producing phase, for tracing logs and diagnostics
- `pre_polish_error` / `post_polish_error`: allow debugging how much polishing mattered
- `polish_applied`: explicit even when error values are unavailable
- `representative_assignments`: only variables completed because they are in `all_unidentifiable`
- `notes`: optional markers such as `:backsolve_failed`, `:partial_algebraic_resolve`, `:uq_failed`

**Target ownership**

- Package core
- Diagnostics/logging should reuse this metadata instead of maintaining parallel ad hoc reporting

#### 3. Benchmark wrapper contract has drifted from the package API

**Where:** `~/ParameterEstimationBenchmarking/templates/julia_template_for_estimation_odepe.jl`

The benchmark template still destructures:

```julia
meta, results = analyze_parameter_estimation_problem(...)
```

while the package now returns:

```julia
(results_tuple, analysis_tuple, uq_result)
```

This is a hard contract mismatch. It risks incorrect benchmark runs even when the package itself is behaving correctly.

**Recommendation**

- Fix the package contract first; do not let benchmark compatibility dictate package internals during cleanup.
- Update the benchmarking template to consume the real 3-tuple return contract.
- Export provenance and identifiability context into benchmark outputs.
- Do not allow benchmark code to infer method identity from option settings alone; read it from result provenance.

**Target ownership**

- Benchmark layer

### High

#### 4. `try_more_methods` still performs a hidden rerun with warning-only failure handling

**Where:** `src/core/analysis_utils.jl`

`try_more_methods` currently:

- performs a legacy AAAD rerun when `interpolators` is empty
- catches failure of the second pass
- warns and continues

This is still implicit orchestration rather than an explicit caller-chosen sweep.

**Recommendation**

- Deprecate `try_more_methods`.
- Keep explicit `interpolators` lists as the supported in-package sweep/orchestration mechanism.
- If any retry behavior remains, it should be represented by an explicit rescue or orchestration policy object, not a boolean.

**Replacement**

- New users: use `interpolators = [...]`
- Existing boolean path: deprecate, log once, route through explicit orchestration, then remove

**Target ownership**

- Package core

#### 5. UQ is explicitly experimental and its failure semantics are ambiguous

**Where:** `src/core/analysis_utils.jl`, `src/core/uncertainty_quantification.jl`

Top-level UQ is no longer wrapped in a broad catch in `analysis_utils`, which is good, but `estimate_parameter_uncertainty()` still catches many failures internally and returns:

- `success = false`
- `message = "..."`

This is not wrong by itself, but the package does not yet define whether UQ failure is:

- a hard failure of the whole call,
- a soft failure of an optional sidecar,
- or a warning-only diagnostic.

The implementation is also still clearly experimental and should not be presented as a stable package capability.

**Recommendation**

- Mark UQ as experimental in code comments, option help text, and docs.
- Make UQ failure policy explicit.
- Keep UQ outside the stable core contract until the implementation is substantially more mature.

**Recommended option**

```julia
uq_failure_policy::Symbol = :return_failed
```

Allowed values:

- `:return_failed` -> keep main estimation result, return `uq_result.success = false`
- `:throw` -> fail the whole call when UQ is requested and UQ cannot be computed

**Recommended default**

- `:return_failed`

Reason: UQ is an experimental sidecar analysis, not the primary estimate.

**Target ownership**

- Package core

#### 6. Direct-opt fallback is coherent, but it is still hanging off the wrong option

**Where:** `src/core/optimized_multishot_estimation.jl`

The direct-opt fallback is conceptually valid as a terminal rescue, but it is currently triggered from `polish_solutions`.

That means a flag that sounds like "refine algebraic candidates" is also controlling "switch paradigms if algebraic estimation produced nothing."

**Recommendation**

- Preserve the fallback, but move control to an explicit option.

**Recommended option**

```julia
terminal_fallback::Symbol = :none
```

Allowed values:

- `:none`
- `:direct_opt`

**Recommended default**

- Package default: `:none`
- Benchmark/experiment presets may opt into `:direct_opt`

**Required provenance**

- Any result produced through this path must carry `primary_method = :direct_opt` and `rescue_path = :direct_opt_fallback`

**Target ownership**

- Package core
- Benchmark profiles may override the default

#### 7. Seeded `t=0` rescue is valuable but should be explicitly experimental

**Where:** `src/core/optimized_multishot_estimation.jl`

The current `t=0` rescue has two tiers:

- strict algebraic re-solve from fixed parameters
- seeded state completion for polish-assisted rescue when strict re-solve is incomplete

This is a reasonable design, but only the first tier should count as the core algebraic method. The seeded tier is an experimental rescue policy.

**Recommendation**

- Keep both tiers, but expose the second one explicitly.

**Recommended options**

```julia
backsolve_recovery::Symbol = :algebraic_resolve
t0_state_completion::Symbol = :strict
```

Allowed values:

- `backsolve_recovery`: `:none`, `:algebraic_resolve`
- `t0_state_completion`: `:strict`, `:seed_for_polish`

**Recommended defaults**

- `backsolve_recovery = :algebraic_resolve`
- `t0_state_completion = :strict`

Benchmark/experimental profiles may opt into `:seed_for_polish`.

**Target ownership**

- Package core with explicit experimental lane

### Medium

#### 8. Representative completion policy should be centralized, not scattered

**Where:** currently split between reconstruction code and result analysis

The intended policy is now clear:

- known structurally unidentifiable parameters may receive representative values
- known structurally unidentifiable states may receive representative values
- identifiable variables may not

This should not be implemented by ad hoc literals spread across the pipeline.

**Recommendation**

- Centralize representative completion in one helper.
- Preserve the established values for compatibility and predictability:
  - parameter representative value -> `1.0`
  - state representative value -> `0.0`

This is acceptable only because the assignments are:

- limited to variables already in `all_unidentifiable`
- recorded explicitly in provenance
- excluded from scored error metrics

**Target ownership**

- Package core

#### 9. Legacy-flow code should be documented before final removal

**Where:** legacy flow code in `src/core/multipoint_estimation.jl`, docs/examples/comments

The public flow enum has been cleaned up, but the old multipoint implementation still exists in the tree and contains a few ideas worth preserving in notes before the code is finally deleted.

**Recommendation**

- Preserve worthwhile ideas in documentation, then remove the remaining dead runtime code.
- Remove stale references from examples, comments, and docs.
- Do not reintroduce a legacy flow selector as part of the public API.

**Target ownership**

- Package core
- Examples/docs

#### 10. The examples directory should be treated as a core package surface

**Where:** `src/examples/`

The examples are not just incidental demos. They are one of the main ways this package is understood, debugged, and validated. Several of the most useful regression models and workflows live there already.

**Recommendation**

- Treat examples as part of the maintained package surface.
- Keep them current with the actual supported contract.
- Make example compatibility a standing acceptance gate for every cleanup wave, not a late catch-up task.
- Reorganize them into a clearer structure once the core contract is stabilized.

**Recommended organization goal**

- `models/` for reusable constructors and canonical test models
- `workflows/` or similar for runnable example pipelines
- `failing/` only for intentionally parked investigations
- clear distinction between:
  - stable examples
  - experimental examples
  - benchmark-specific scripts

**Target ownership**

- Package core
- Examples/docs

**Implementation guidance**

- Each cleanup wave should name a curated example subset that must remain runnable.
- Example breakage caused by package-contract changes should be fixed within the same wave, not deferred.
- Larger rewriting, regrouping, and pruning still belong later, but compatibility maintenance does not.

#### 11. `EstimationOptions` mixes core behavior, orchestration, diagnostics, and experimental controls

**Where:** `src/types/estimation_options.jl`

The single options struct is the right overall shape, but it currently mixes:

- core workflow selection
- interpolation/orchestration
- polishing/rescue
- diagnostics/debugging
- UQ
- legacy compatibility

This makes precedence and illegal combinations harder to reason about.

**Recommendation**

- Keep one struct.
- Reorganize fields conceptually and in printing/documentation into sections:
  - workflow
  - interpolation/orchestration
  - rescue/polish
  - optimization bounds/tolerances
  - UQ
  - diagnostics/debug
- Add validation for every cross-group illegal combination.
- Remove deprecated compatibility knobs once replacements exist.

**Target ownership**

- Package core

#### 12. Several local numerical fallbacks still need classification

**Where:** notably `derivatives.jl`, `homotopy_continuation.jl`, `pointpicker.jl`

Examples:

- GP hyperparameter optimization failures falling back to defaults
- `build_function` failures falling back to substitute/value execution
- point variability scoring defaulting to `0.0`
- homotopy fresh-solve fallback when continuation loses solutions

Some of these are justified robustness steps. Some are likely papering over faults. They need a systematic classification instead of case-by-case drift.

**Recommendation**

- Run a follow-up audit that labels each fallback as:
  - core algorithmic robustness
  - explicit rescue behavior
  - benchmark convenience
  - hidden behavior to remove

Do not remove them blindly. Classify first, then tighten.

**Target ownership**

- Package core

### Low

#### 13. Reporting and naming still reflect historical implementation rather than current semantics

Examples:

- "Using NEW optimized parameter estimation flow"
- "polishing" code paths that also perform rescue
- comments describing "backward compat" around behaviors that should be deprecated instead

**Recommendation**

- Align log messages, comments, and docs with actual semantics.
- Prefer names that match behavior:
  - "rescue"
  - "orchestration"
  - "representative completion"
  - "direct-opt fallback"

## Recommended Target Behavior

This is the recommended end-state behavior to implement after this review phase.

### Core workflows

- Support `FlowStandard` and `FlowDirectOpt`
- Remove `FlowDeprecated`

### Reconstruction rules

- Identifiable variable missing -> hard failure
- Structurally unidentifiable variable missing -> representative completion allowed
- Representative completion values:
  - parameters -> `1.0`
  - states -> `0.0`
- Representative completions must be recorded explicitly in result provenance

### Rescue rules

- Blown backsolve -> may trigger algebraic `t=0` re-solve
- `t=0` re-solve success -> core algebraic rescue
- `t=0` re-solve incomplete + `t0_state_completion = :seed_for_polish` -> experimental seeded rescue
- No algebraic candidates + `terminal_fallback = :direct_opt` -> direct-opt rescue

### Orchestration rules

- Explicit sweeps via `interpolators = [...]` are supported
- `try_more_methods` is deprecated and should be removed

### UQ rules

- UQ is an optional experimental sidecar
- Default failure policy is `:return_failed`
- `:throw` is allowed for strict callers

## Public Interface Recommendations

### `ParameterEstimationResult`

Keep the current result object but add:

- `provenance::ResultProvenance`

Deprecate eventual reliance on:

- `return_code` as the primary provenance mechanism

### `EstimationOptions`

Keep one options type, but add explicit rescue-policy controls:

- `terminal_fallback::Symbol = :none`
- `backsolve_recovery::Symbol = :algebraic_resolve`
- `t0_state_completion::Symbol = :strict`
- `uq_failure_policy::Symbol = :return_failed`

Deprecate:

- `try_more_methods`

Remove after migration:

- `FlowDeprecated`

## Test and Benchmark Implications

### Tests

Keep:

- `test/runtests.jl` as the fast gate
- `test/runtests_extended.jl` as the slower lane

Current high-value cases:

- `trivial_unident`
- `global_unident_test`
- `sum_test`
- `substr_test`
- `onesp_cubed`
- `threesp_cubed`
- `treatment` (extended)
- `biohydrogenation` (extended)

Required future assertions:

- representative completion occurs only for variables in `all_unidentifiable`
- result provenance records candidate lineage, shooting-point origin, and polishing effect
- seeded rescue is provenance-visible
- direct-opt fallback is provenance-visible
- examples remain synchronized with the supported package contract

### Benchmarking

Benchmark outputs should eventually record at least:

- primary method
- rescue path
- interpolator source
- `all_unidentifiable`
- representative assignments

Benchmark comparisons and paper tables must:

- exclude the full `all_unidentifiable` set from parameter error scoring
- separate pure algebraic successes from rescue-assisted or direct-opt fallback results

## Ordered Remediation Waves

### Wave 1: Behavior hardening

- Remove generic fabricated values from `resolve_states_with_fixed_params()`
- Centralize representative completion for known unidentifiables
- Keep strict failure for missing identifiable values

### Wave 2: Provenance contract

- Add `ResultProvenance`
- Migrate current `return_code` and `interpolator_source` usage into it
- Propagate shooting-point origin, candidate lineage, and pre/post-polish information
- Update result reporting and benchmark export to consume provenance

### Wave 3: Rescue/orchestration options

- Add explicit rescue-policy options
- Deprecate `try_more_methods`
- Decouple terminal direct-opt fallback from `polish_solutions`

### Wave 4: API and legacy cleanup

- Remove `FlowDeprecated`
- Reorganize `EstimationOptions` docs/validation
- Remove stale compatibility shims and misleading log messages

### Wave 5: Examples and docs alignment

- Update examples/docs to describe rescue and provenance explicitly
- Reorganize examples into maintained, experimental, and investigation-oriented areas
- Keep runnable examples aligned with the supported package contract

### Example compatibility track (runs across every wave)

- Maintain a curated example smoke set as an acceptance gate for each package wave
- Update example option shims and runnable workflows whenever package-contract changes would otherwise leave examples behind
- Classify examples into maintained/stable, experimental, and investigation/parked lanes
- Treat example fixes as package cleanup work, not benchmark cleanup

### Wave 6: Benchmark alignment

- Update `ParameterEstimationBenchmarking` template to match the package return contract
- Export provenance and identifiability data needed for honest comparison
- Ensure benchmark reporting distinguishes core method from rescue path

## Assumptions

- Breaking changes are acceptable when they improve clarity and truthfulness.
- The package should preserve broad experimentation, but experimental behavior must be clearly labeled and explicitly enabled.
- The package should be cleaned up first; benchmark-harness alignment should follow once the package contract is settled.
- The examples directory is a first-class package surface and should be kept current and organized.
- Example maintenance is continuous across all waves; Wave 5 is for broader example/docs consolidation and reorganization.
- The benchmark repo is in scope for later contract alignment, but the paper repo is reference material, not a refactor target.
- This document is the decision baseline for the next implementation phase.
