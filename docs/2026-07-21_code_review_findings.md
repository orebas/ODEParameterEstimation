# Code Review Findings — 2026-07-21

Branch: `uq-revamp-wip`. Method: five parallel verified-review lanes (estimation
pipeline, solver/noise-frontier, config/options+provenance, silent-failure
bug-class sweep, test coverage). Read-only; nothing executed. Findings are
tagged CONFIRMED (traced to code) or SUSPECTED (plausible, unverified), and
DEFAULT-PATH (fires in ordinary use) or LATENT (masked today, bites a future
caller). File:line references are current as of this branch.

Two verified facts that set severity:
- `system_construction_policy = :noise_frontier` is the **default** (`estimation_options.jl:538`).
- `auto_rescale = true` is the **default** (`estimation_options.jl:550`).

So the `noise_frontier` construction path and the bounds-rescale path are both on
the production default path, not opt-in.

---

## P1 — Confirmed, default-path, silent-wrong-result or data-loss

### 1. Silent-fallback bounds TRIO (bug class; subsumes the documented transform-bounds bug)
One wrong-length `opt_lb`/`opt_ub` silently disables three separate protections,
with no `@warn`/`@error`/`throw` anywhere:
- `rescale_option_bounds` — `problem_rescaling.jl:472` (`length(v) != length(scales)` → returns `v` untransformed; reached via `analysis_utils.jl:933` whenever `auto_rescale=true`) → a physical bound is shipped **untransformed** into a scaled-coordinate solve.
- `_build_polish_context` — `parameter_estimation.jl:1662-1672` (`length(opts.opt_lb) != p_size` → silently `compute_default_bounds`, the ±1e6 box) → user bounds ignored.
- `_clamp_params_for_backsolve` — `parameter_estimation_helpers.jl:544` (no-op on mismatch) → backsolve clamp skipped → spurious HC candidates with params ~0 diverge (the cstr case this exists to fix).
The transcendental `_trfn_` case (`docs/2026-06-19_transform_bounds_mismatch.md`) is
just the most common trigger of the same class.
**Fix once:** a shared length-validating helper (ideally a `BoundSpec` keyed by
variable identity, resolved after all transforms) that ERRORS on mismatch.
**Gate:** `test_rescaling.jl` + a new bounds-mismatch canary + `feature_regressions.jl`.

### 2. `objectid`-keyed noise-frontier validation cache → wrong compiled Jacobian
`noise_frontier_construction.jl:805-816`. `_NOISE_VALIDATION_CACHE` is a global
`Dict{Any,...}` keyed by `objectid(equations)/objectid(solve_vars)/objectid(data_vars)`
+ lengths + atol, and is **never cleared**. Across multiple estimation calls in one
process (`run_examples.jl`, `test/runtests.jl`, any multi-model driver), a GC'd
candidate's `equations` vector frees its address, a new candidate reuses it →
identical `objectid`; if lengths/atol also match (common on small systems), the
cache returns the **wrong compiled Jacobian**. `validate_noise_frontier_instantiation`
then makes a rank/`valid` decision on the wrong system → can accept a rank-deficient
(positive-dimensional) system (HC hang/garbage) or drop a good shooting point.
Silent either way. Also an unbounded RGF/JIT leak (same class as the
`solve_with_robust` leak in `repro/memory_audit_2026_05_19`). The sibling cache
`_hc_structure_key` (`optimized_multishot_estimation.jl:116-118`) uses a content
`hash` and is safe.
**Fix:** key by a content hash (mirror `_hc_structure_key`); bound/clear it or make
it per-run. **Gate:** `fast_core.jl` noise-frontier probes + a multi-model
in-process test that would trip the false hit. CONFIRMED pattern; false-hit is
reasoned from `objectid`/GC semantics (not reproduced).

### 3. Auto-detected multiplicity truncates globally-identifiable systems to ONE row
`optimized_multishot_estimation.jl:744-748` (set) → `analysis_utils.jl:982-992`
(override when `opts.algebraic_multiplicity===nothing`, the default) →
`analysis_utils.jl:858-869` (truncate to `min(M, branch_top_k)`). For a structurally
globally-identifiable system the quotient-basis dimension is 1 → `auto_m=1` →
`result.csv` collapses to the single lowest-SSE candidate. When fit-best ≠
truth-near (ill-conditioned, moderate noise), the truth-near candidate that used to
sit at row 2–20 is silently dropped. **Direct callers** of
`analyze_parameter_estimation_problem` with default options are exposed; PEB bypasses
by injecting per-system `algebraic_multiplicity`.
Note: this may partly reframe the selection-study conclusion ("leftover precision is
a POOL problem, not selection") — some of it may be an OUTPUT-TRUNCATION problem.
**Fix:** require explicit opt-in before consuming auto-M, or only truncate when M>1.
**Gate:** `identifiability_regressions.jl` + a multi-basin canary.

### 4. `cluster_method` silently overridden to bit-identical whenever `branch_completion` on
`analysis_utils.jl:652-660`. The output-stage clustering gate keys off the *feature
flag* `branch_completion` (default `true`), not off whether completion actually fired
(a no-op unless M>1). So in the common case the output is always tight 1e-5
bit-identical dedup and the documented default `cluster_method=:identifiable_subspace`
**never runs** on the output stage (it DOES run for anchor selection at `:397-403` —
internally inconsistent). Near-duplicate candidates can crowd a distinct truth-near
basin past `branch_top_k`.
**Fix:** honor `cluster_method` at the output stage regardless of `branch_completion`;
thread a "pool_was_completed" flag instead of gating on the option.
**Gate:** same as #3.

### 5. `lookup_value` live `startswith` prefix fallback (name round-tripping; owner's #1 class)
`parameter_estimation.jl:1294-1296`. The P0#4 wrong-variable mechanism (a param
`k_1` bound to `k_10`) is still present as a last-resort
`startswith(string(final_varlist[i]), base_name*"_")` match. Mitigated only because
the full-name attempt (`k_1_0`, line 1264) is tried first; if it ever misses, the
prefix match can still silently return the wrong variable's value.
**Fix:** match by canonical variable identity / structured `(base,order)` key; remove
the prefix fallback. **Gate:** `test_label_parsers.jl` + `refactor_safety_net.jl` +
an underscore-digit-param canary.

---

## P2 — Confirmed but latent/masked, or high-value maintainability

### 6. Option-bridge default mismatches (bug class; root cause: `get_solver_options_dict` deleted 2026-06-10)
Lower layers now read hand-built `Dict`s with `get(options, :key, DEFAULT)` whose
DEFAULT disagrees with the struct default:
- `use_column_scaling`: struct `true` (`:559`) vs read `false` (`homotopy_continuation.jl:843`).
- `homotopy_tracking_mode`: struct `:generic_start` (`:577`) vs read `:gamma_straight` (`:844`).
- `abstol`/`reltol`: struct `1e-14` (`:291-292`) vs read `1e-8`/`1e-6` (`solve_with_robust.jl:57-58`); both callers additionally hardcode `1e-12` → **struct tolerances never reach `SolverRobust`** (this one is already live-disconnected, not just latent).
Masked in the SP/MP hot paths (they pass keys explicitly, `:1174-1182`, `:1556-1560`),
but `select_time_point_pairs_homotopy_probed` (`multipoint_template.jl:1547-1548`,
exported + in `test_point_selection.jl`) omits both keys.
**Fix once:** make read-site defaults equal struct defaults, or reinstate a single
options→dict bridge builder. **Gate:** `column_scaling.jl` + a bridge-default
consistency unit test.

### 7. Swallowed interrupts / silent candidate drops (bug class; systemic)
Zero references to `InterruptException` in all of `src/`; ~199 `catch` blocks, none
filter interrupts. A bare `catch` catches `InterruptException`, so Ctrl-C during long
polish/solve/fan-out loops silently becomes `Inf`/`continue`. Worse, the multipoint
fan-out `catch → continue` sites (`multipoint_template.jl:1436-1584`) drop a candidate
with **no provenance record** — a genuinely-better candidate can vanish invisibly.
Hot-loop swallowers: `parameter_estimation.jl:1822-1827` (`_trajectory_sse`),
`:1997-2006`, `:2475-2479`; `optimized_multishot_estimation.jl:2044-2048`.
**Fix once:** an `_is_fatal(e)= e isa InterruptException && rethrow()` guard (or a
`@catch_nonfatal` macro) at every loop-body catch; emit a skip/provenance record on
candidate drops. **Gate:** a "dropped candidate leaves a record" assertion.

### 8. Global mutable state (bug class)
- `_LAST_ESTIMATION_AUTO_M` (`optimized_multishot_estimation.jl:19`): module `Ref`,
  thread-unsafe; consume at `analysis_utils.jl:982` is NOT in a `finally` (persists if
  analysis throws before consume); drives output-row truncation but the truncation is
  not recorded in provenance. The timing sinks (`_RESOLVE_TIMING_SINK`,
  `si_template_integration.jl:32`, save/restore in a `finally` at
  `optimized_multishot_estimation.jl:2146-2148`) are the correct template to copy.
- `_NOISE_VALIDATION_CACHE` — see #2.
**Fix:** thread auto-M through as a return value or a `finally`-guarded scoped value;
content-hash + bound the noise cache.

### 9. `residual_fix_set` never populated (provenance honesty gap)
`core_types.jl` field is only ever READ (`parameter_estimation_helpers.jl:455`,
logged `optimized_multishot_estimation.jl:786`) and hardcoded empty on the
branch-completion path (`parameter_estimation.jl:575`); nothing in
`si_template_integration.jl`/`si_equation_builder.jl` assigns it. So values fabricated
to repair *residual* template underdetermination leave NO lineage — unlike
`structural_fix_set`, which IS populated. The one place a "filled-in to make solvable"
value is invisible. **Fix:** populate it where residual repair happens, or delete the
field if residual repair no longer occurs.

### 10. Dead / paper-only option surface (bug class; 17 of 117 fields confirmed dead)
Read only inside `validate_options`/`print_options`/`merge_options`, never
functionally consumed (behavior comes from a hardcoded local or module const):
`rtol`, `max_deriv_level` (hardcoded magic `10` at `parameter_estimation_helpers.jl:498`),
`point_hint`, `si_probability`, `si_infolevel`, `imag_threshold`, `clustering_threshold`,
`output_precision`, `use_monodromy`, `display_system`, `polish_only`, `ideal`,
`trap_debug`, `log_dir`, `save_filepath`, `branch_resid_factor`, `branch_min_size`.
Plus `interpolator`/`custom_interpolator` (singular) are dead-by-default (shadowed by
the non-empty `interpolators` list); `gp_s3_refinement` is deprecated-but-exported.
`validate_options:1364` even WARNS about `polish_only` (a dead field). Highest-value
(a user expects them to work but they silently no-op): `max_deriv_level`,
`si_probability`, `si_infolevel`, `point_hint`, `use_monodromy`.
**Fix:** delete (after a PEB grep — PEB injects some fields) or actually wire up the
user-expected ones. **Gate:** option validation tests + PEB grep before deletion.

### 11. Validation coherence gaps (`validate_options`)
- `InterpolatorCustom` + `custom_interpolator=nothing` passes validation, errors deep at `get_interpolator_function:630`.
- `opt_ad_backend` invalid symbol not enum-checked (errors at `get_ad_backend:1117`).
- `rank_strategy=:sat_neg1_err` silently degrades without `opt_lb`/`opt_ub`.
- `compute_uncertainty=true` with a non-GP interpolator unchecked (SUSPECTED).

---

## P3 — Robustness / readability / refactor

- `solve_with_robust.jl:221-230` multistart uses unseeded `randn`/`rand` (masked: production callers pass `start_point`+`polish_only` → `multistart=false`). Thread a seeded RNG.
- `_noise_rank_matrix` (`noise_frontier_construction.jl:563-568`) swallows ForwardDiff failure as a finite rank-0 probe → a systematically failing compiled Jacobian is invisible at that layer.
- Scalar-polish best-iterate can return worse-than-seed under Fminbox (`parameter_estimation.jl:1921-2011`) — MITIGATED (non-default polish; residual path has a correct revert-to-seed guard; seed retained in pool). Seed the best-iterate comparison from the seed's TRUE loss.
- Soft-wall penalty (`polish_softwall_lambda=1e-2`) is inert under the default `err_only` ranking — wasted polish work, not a wrong result. Disable by default under `err_only` or score on the penalized objective.
- `solve_multipoint_overdetermined` (`multipoint_template.jl:1113`) drops solver options → inner solve uses default `real_tol` regardless of `opts.hc_real_tol`.
- `real_atol` vs `real_tol` inconsistency — both work (`real_tol` is a deprecated HC.jl alias). Standardize on `real_atol`.
- Stale docstring: `analysis_utils.jl:840-846` claims default `rank_strategy=:sat_neg1_err`; actual default is `:err_only`.
- Dead `1e10` sentinel init in `process_estimation_results` (`parameter_estimation_helpers.jl:665-666`) — unreachable under the always-on SI workflow; `NaN` would fail louder.
- `convert_to_hc_format` textual variable replacement (`homotopy_continuation.jl:397-411`) is fragile (substring/sci-notation collisions); a symbolic→ModelKit builder would be safer.
- `solution_distance` (`analysis_utils.jl:12-37`) compares state/param dicts positionally, relying on an unenforced key-ordering convention across candidate sources (SUSPECTED). Compare by shared key order.

---

## Provenance verdict
Sound overall: `sync_result_contract!` is called at all 17 result-producing sites,
and rescue/fallback paths stamp honestly (`:algebraic_resolve_*`, `:direct_opt_fallback`,
`:synthesized_aggregate`, `:sensitivity_seed`, `:multipoint`). A fallback result does
not trivially masquerade as clean. Gaps: #9 (`residual_fix_set`), the auto-M global
truncation not in provenance (#8/#3), and the bare short constructor defaulting to a
clean `ResultProvenance` (latent future-masquerade if a new site forgets to stamp).

---

## Test / coverage reality (gates everything)
`review_map.md` has rotted (2026-05-29): `runtests.jl` now includes 10 files (adds
`refactor_safety_net.jl`, `test_label_parsers.jl`, `test_rescaling.jl`); research
files moved `src/core/` → `src/research/`; `noise_frontier_construction.jl` is absent
from the map; `test_uncertainty_quantification.jl` moved to `deprecated/`;
`runtests_legacy.jl` is BROKEN (includes 5 non-existent files).

Biggest holes:
- **Multipoint solve** — `build_multipoint_template`, `solve_multipoint_direct/_parameterized/_overdetermined`, `select_time_point_pairs*` are exported production entrypoints with ZERO direct active-CI coverage (only orphaned `test_multipoint_*.jl`).
- **`noise_frontier_construction.jl`** — tested only at `noise_level=0.0` on `simple()`. The noise-robust selection it exists for is UNVERIFIED.
- **UQ covariance exports partially dark** — `joint_derivative_covariance(_cross_time)`, `se_kernel_*`, `build_observation_covariance`, `compute_practical_identifiability_index` have 0 CI refs; all UQ tests are noise=0 (no under-noise calibration check).
- `test_core_types.jl` is RED (cheap ~15 min fix: `===`→`isequal`, concrete-typed dict, real `@variables` Nums).
- No genuine <1 min quiet gate; `fast_core.jl` is ~40% research/bilby rendering and calls SIAN/HC/ODE.

Proposed: a new `test/fast_unit.jl` (pure/near-pure contract sets only — no `analyze_*`,
no SIAN, no consensus rendering) + adopt the orphaned pure-unit files (`column_scaling.jl`,
`test_math_utils.jl`, `test_model_utils.jl`, `test_derivative_utils.jl`) and the fixed
`test_core_types.jl`. The `src/research/` consensus/bilby cluster (~340 KB, paper-only,
smoke-only) is what makes `fast_core` slow+noisy → candidate to move behind a
non-exported research namespace and out of the first-line gate.

---

## Suggested fix sequence
0. **Stand up the gate** (cheap, protects everything): fix RED `test_core_types.jl`,
   create `test/fast_unit.jl`, adopt orphaned pure-unit files. Refresh `review_map.md`.
1. **P1 default-path correctness:** bounds trio (#1) → objectid cache (#2) →
   output-truncation pair (#3, #4) → `lookup_value` fallback (#5). Each a small
   verified commit with its gate.
2. **P2 bug-class refactors:** option-bridge unify (#6), interrupt/skip guard (#7),
   global-state discipline (#8), `residual_fix_set` (#9).
3. **Dead-surface trim** (#10, #11) after a PEB grep.
4. **P3 nits** opportunistically.
