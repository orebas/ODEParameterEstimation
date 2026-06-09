# ODEParameterEstimation — Code Review & Recommendations

**Date:** 2026-06-09
**Scope:** `src/core`, `src/types`, the module file, `ext/`, and repo hygiene.
**Method:** Read-only fan-out review (7 parallel reviewers, one per file cluster) +
repo-hygiene pass. Nothing was modified during the review.

> **How to read this:** Findings are deduplicated and prioritized by *impact on
> real (returned) results*, not by file. Severity tags: **BUG** (correctness),
> **ERRORS** (silent failure), **TYPE** (type-instability), **DEAD**
> (dead/duplicate), **PERF**, **HYGIENE**. The P0 items are concrete and
> line-referenced but worth a quick confirm before fixing, since a few sit in
> legacy paths. Checkboxes are for tracking — none are actioned yet.

---

## Cross-cutting themes

1. **Silent error-swallowing is endemic.** Dozens of `try … catch; <sentinel> end`
   blocks across solver, scoring, interpolation, and diagnostics collapse *any*
   exception (incl. `MethodError`) into `NaN`/`Inf`/`0.0`/`nothing` with no
   `@debug`. A systematic failure becomes indistinguishable from "this candidate
   is just bad." Likely masked real failures during the receptor/seir/bioh work.

2. **"Missing/bad data" is silently turned into "wrong answer."** Missing
   interpolants inject `0.0` into the coefficient vector; NaN derivatives are
   stored and propagated; an unknown Nemo coefficient defaults to `1`. Each
   produces a *confidently wrong root* rather than a failure. Most dangerous class.

3. **Pervasive `Any`-typed containers / struct fields** contradict the project's
   stated type-stability mandate — including two `::Any` solver fields on the hot
   path whose docstrings misstate the real type.

4. **Multiple parallel generations of the same subsystem** coexist (consensus
   v1/v2/research/synthesized; four NLopt solvers; three label parsers; ~four DFS
   implementations). ~3k lines of lockstep-maintained research code is the
   dominant maintenance liability.

5. **String round-tripping for symbolic work** — variable-name parsing via greedy
   `_<digits>` regex, and HC system construction via `string()` → `Meta.parse` →
   `eval` — is the most fragile machinery and the likeliest source of silent
   wrong answers on non-standard models.

---

## P0 — Correctness bugs that can affect returned results

- [ ] **#1 Reported `err` is silently deflated.** `parameter_estimation.jl:911-920`
  (`process_raw_solution`) skips the `"t"` key when summing per-observable error
  but divides by `length(data_sample)`, which *includes* `"t"`. Every
  algebraic-path error is scaled by `n_obs/(n_obs+1)`, and `err` feeds candidate
  ranking/selection. **Fix:** divide by `length(data_sample) - 1`.

- [ ] **#2 Complex→real fallback can emit `Inf` "solutions."**
  `homotopy_continuation.jl:1300`. When no real roots exist, the fallback calls
  `HomotopyContinuation.solutions(result)` with *no* keywords — defaulting to
  `only_nonsingular=true` (contradicting its own comment) and omitting
  `only_finite`, so at-infinity endpoints survive; `real(s[j])` then yields `Inf`,
  which flows downstream as a root. Every other call passes `only_nonsingular=false`.
  **Fix:** match the rest + filter non-finite coords.

- [ ] **#3 AAA `baryEval` near-node tolerance is ~5.6e-4 wide and keeps only the
  last coincident node.** `derivatives.jl:82,92`. The exact-point branch fires when
  `(z-x[j])^2 < sqrt(1e-13)` i.e. `|z-x[j]| < 5.6e-4`, and the loop overwrites
  `breakindex` without breaking. On dense support points / short time intervals
  this returns wrong interpolated values that poison every downstream derivative.
  This is the *live* AAA path. **Fix:** `abs(z-x[j]) < tol`, break on first hit.

- [ ] **#4 `parse_derivative_variable_name` mis-orders any name ending in `_<digit>`.**
  `si_equation_builder.jl:1241`, used at `:349` and `multipoint_template.jl:23`.
  Greedy `^(.+)_(\d+)$` parses a bare param `k_2` as `(base=k, order=2)`. The
  transcendental code guards against this (`_parse_trfn_base_name` first), but
  `classify_si_ring_variable` and `_multipoint_deriv_order` do **not**. Any model
  with an underscore-digit-suffixed state/param name is silently misclassified.

- [ ] **#5 Legacy FD-Jacobian UQ produces meaningless covariance.**
  `uncertainty_quantification.jl:850-887`. `compute_constraint_jacobians` maps
  every observable to `state_idx=1` then overrides by *substring* match (`y1`
  matches `y12`), and forces derivative constraints to `0` at both time boundaries
  → zeroed `J_θ` rows → corrupt `S = -J_θ⁻¹J_z`. **Likely dead** (live report uses
  the analytic IFT path in `diagnostics.jl`) — confirm and delete (~400 lines),
  else it's a covariance landmine.

- [ ] **#6 Printed "95% CI" (±1.96σ) disagrees with the ✓/✗ coverage test (±2σ).**
  `diagnostics.jl`. Coverage uses `|true−est| < 2σ` (`4972, 5045, 5217, 5331, 5369`)
  but the interval is drawn at `±1.96σ` (`5329-5330, 5367-5368, 5445-5446`). A value
  at 1.96σ–2σ renders outside the box yet marked "covered." Pick one constant.
  Most user-visible UQ bug.

**Latent (currently only reachable via dead/legacy paths — fix when re-enabling):**
- `optimized_multishot_estimation.jl:3028` — `use_adaptive_id` undefined; non-SI
  path throws `UndefVarError` (masked because the SI path returns at `:2990`).
- `parameter_estimation.jl:228` — `opts` referenced but not a parameter of
  `construct_multipoint_equation_system!`; hidden because its sole caller is in an
  `if (false)` block.
- `derivatives.jl:1689` (`_chebyshev_deriv_coeffs`) — recurrence is wrong and unused.

---

## P1 — Silent failures & "bad data → wrong root"

- [ ] Inject-`0.0`-for-missing-interpolant: `homotopy_continuation.jl:1414-1420`,
  `multipoint_template.jl:1010-1012` warn then `push!(values, 0.0)`. Propagate `NaN`.
- [ ] NaN derivative stored/propagated: `si_template_integration.jl:157-168` warns
  but stores the NaN; only a late guard at `solve_with_hc_parameterized:1322` catches
  it. Fail at the source.
- [ ] Unknown Nemo coefficient → `1`: `si_equation_builder.jl:1311-1314` `@error`s
  (doesn't halt) then sets `coeff_val = 1` (corrupt polynomial). Should `error()`.
- [ ] All-sentinel polish reports a finite error: `polish_residual.jl:156-178` fills
  `1e6` on every failed solve; if *all* fail, the revert-guard still passes and a
  plausible `final_obj` is returned. Flag "all-sentinel" in provenance. (Same
  objective-vs-true-loss family as the prior Fminbox barrier bug.)
- [ ] Bare `catch; end` swallowing whole evaluations:
  `optimized_multishot_estimation.jl:2404` (multipoint combos),
  `:686-689` (`extract_variables` drops a solve variable), `:1382-1406` (solver
  crash looks like "no roots here"); scoring sentinels in
  `consensus_estimation.jl:69-73,536-539,758-775`, `synthesize_aggregates.jl:681-684`.
  Min fix: `opts.diagnostics && @warn … exception=e`.
- [ ] GP/AAA degrade to *un-optimized* hyperparameters on Cholesky/LBFGS failure
  (`derivatives.jl:699-724, 854-884, 1020-1050, 1267-1303`) with only a `@warn`.
  The SE path already computes `converged` — propagate it on the interpolator.
- [ ] BOBYQA hard-codes `[-100,100]` bounds (`solve_with_robust.jl:340-341`)
  regardless of scale — unreachable true values on large-coordinate systems; returns
  "converged" wrong roots. Scale to data/start point.

---

## P2 — Type stability (project priority)

- [ ] Two `::Any` solver fields on the hot path with lying docstrings:
  `core_types.jl:55` (`ParameterEstimationProblem.solver`), `estimation_options.jl:279`
  (`EstimationOptions.ode_solver`). Type as `Union{Nothing, SciMLBase.AbstractODEAlgorithm}`.
- [ ] `Any` symbolic fields in live structs: `MultiPointTemplate.solve_vars/data_vars::Vector{Any}`
  (`core_types.jl:1211-1212`), `NoiseFrontierCandidate` equation/var fields
  (`noise_frontier_construction.jl:18-38`, **production**). Narrow to `Vector{Num}`.
- [ ] `AGPInterpolator` stores `mean_function::Function`, `posterior::Any`
  (`derivatives.jl:168-176`) — dynamic dispatch on every `interp(x)`, differentiated
  thousands of times. Parameterize the struct (`AGPInterpolator{F1,F2,P}`).
- [ ] Untyped accumulators: `results_vec = []`, `OrderedDict()`, `Dict()` throughout
  `parameter_estimation.jl` (`679, 860-861, 1422, 1429…`), `all_solutions = []` in
  `solve_with_robust.jl`. `PolishContext` `Dict` fields are trivially `Dict{Num,Int}`
  (`parameter_estimation.jl:1872-1873`).

---

## P3 — Dead code & duplication (biggest cleanup lever)

- [ ] **Consensus sandbox (~3k lines):** `consensus_estimation`, `branch_consensus_v1`,
  `block_consensus_v2`, `synthesized_finalizer`, `consensus_reporting` never feed
  estimation results — only tests/sweeps. Four parallel generations of "cluster →
  score → pick winner." Declare one canonical, mark the rest `# RESEARCH-ONLY`/
  deprecate. Within: two byte-identical `*_confidence_tier`, ~4 near-identical DFS
  connected-components, `uq_volume_proxy` always `NaN`, an `a31`-hardcoded report column.
  - **LIVE production paths (concentrate test/review here):** `noise_frontier_construction.jl`
    (now the *default* system builder), `synthesize_aggregates.jl` (default-on),
    `branch_completion.jl` (opt-in).
- [ ] Four near-identical NLopt solvers: `homotopy_continuation.jl:42, 171, 291, 440`
  (~80% duplicated incl. a 5-frame stacktrace printer ×5). Collapse to one.
- [ ] Two duplicated string→HC builders: `convert_to_hc_format` (`:634`) /
  `convert_to_hc_format_with_params` (`:863`).
- [ ] Three drifting label parsers: `_parse_data_label` (diagnostics),
  `parse_sensitivity_label` (sigma_d — docstring says `Tuple{Int,Int}`, returns
  `Tuple{String,Int}`), multipoint var-order parser. Must stay in lockstep for
  Σ_d↔S alignment. Consolidate.
- [ ] Dead functions/paths: `_detect_branches` + `_branch_cluster_linf` (~170 lines,
  `analysis_utils.jl:515-686`), `record_representative_assignment!`,
  `get_next_deriv_increment`, `pick_points_old` + its scoring stack
  (`pointpicker.jl:13-185`), `agp_gpr_manual` ("BACKUP"), several unused
  rational/Fourier interpolators; `robust_conversion.jl` is a 5-line empty stub;
  orphaned docstrings at `optimized_multishot_estimation.jl:726-744`.
- [ ] ~15 dead `EstimationOptions` fields (`estimation_options.jl`): `max_solutions`,
  `imag_threshold`, `complex_threshold`, `verification_threshold`, `use_monodromy`,
  `point_hint`, `polish_only`, `display_system`, `save_filepath`, … several with
  authoritative docstrings promising behavior that no longer exists. The dead bridge
  `get_solver_options_dict` (exported, never called) used to consume them.
- [ ] Orphaned duplicate module: `src/petab_loader.jl` (`module PEtabLoader`) is never
  `include`d; live loader is in `ext/`. Delete.

---

## P4 — Performance

- [ ] Unconditional debug printing in hot construction path:
  `parameter_estimation.jl:1506-1581` does per-equation regex/`string()` + heavy I/O
  on *every* call, ignoring `diagnostics`. Also `println` spew in
  `solve_at_shooting_point`/`create_equation_template`. Gate behind the flag.
- [ ] HC system rebuilt + `eval`'d per solve: `convert_to_hc_format_with_params`
  re-runs `Meta.parse`/`eval`/`set_default_compile` per invocation inside per-candidate
  scans. Build once and reuse.
- [ ] `build_multipoint_template` rebuilt inside candidate loops
  (`multipoint_template.jl:552` + Jacobian-probe strips, O(n²) symbolic traversals).
- [ ] `complete(model.system)` re-run per solution: `parameter_estimation_helpers.jl:658-659`
  + `:880` — hoist out of the loop.
- [ ] O(n²) buffer allocs: `objective`/Jacobian closures allocate per call
  (`solve_with_robust.jl:119-123, 160-168`); `equilibrate_jacobian` slices per row/col
  (`parameter_estimation.jl:975-988`, use `@views`).
- [ ] `diagnose_uncertainty` computes GP posterior covariance twice per observable
  (`diagnostics.jl:4355` and `:4383`); GP band loop does 500 eigendecompositions/plot.
- [ ] Pure-Julia O(N²) DFT in the Fourier derivative path (`derivatives.jl:1838-1894`)
  at N=500. Opt-in; lower severity.

---

## Repo hygiene & packaging

- [ ] **`[compat]` section is empty** (`Project.toml`). No bounds on ~40 deps — can't
  be registered cleanly, fragile to breaking upstream releases. Add at least
  major-version bounds for `ModelingToolkit`, `Symbolics`, `HomotopyContinuation`,
  `OrdinaryDiffEq`, `SIAN`, `StructuralIdentifiability`, etc.
- [ ] Tracked debug scripts: `debug_equation_count.jl`, `debug_si_template.jl` are
  committed at repo root (the `test_*.jl` gitignore rule doesn't match `debug_*`).
  The 312 KB / 121 KB `debug_*.log` are gitignored but in the tree. Move/delete; add
  `debug_*.jl` to `.gitignore`.
- [ ] Root clutter: ~11 stray `.jl`/`.log` files at top level. Consider `scratch/`.
- [ ] Test suite vs CI gap: 63 files in `test/`, `runtests.jl` runs only 7. 21
  `generate_*` research harnesses live alongside 16 real `test_*` files. Move
  `generate_*` to `benchmark/`/`repro/`.
- [ ] Load-time global side effects: `logging_utils.jl:86-90` mutates the process
  `global_logger` at module load; `using Enzyme` unconditionally despite Enzyme being
  non-default and known to fail through ODE solvers (TTFX cost). Move to
  `__init__`/extension/lazy load. Redundant re-`using` at `ODEParameterEstimation.jl:37`;
  duplicate enum exports at `:125-129` vs `:186`.

---

## Recommended structural refactors

1. **Split `diagnostics.jl` (5,460 lines)** along its comment seams:
   `diagnostics_taylor.jl`, `_analysis.jl`, `_multipoint.jl`, `_orchestrator.jl`,
   `_uq.jl`, `_html.jl` (~2k lines — home for a single `_h(s)` HTML-escape helper;
   a few unescaped name/label interpolations exist today, e.g. `:3063, 3216`).
2. **Hoist shared helpers**: one label parser (diagnostics + sigma_d + sensitivity_seeds),
   one `_psd_clip_and_scale(Σ; rel)` (the PSD jitter is reimplemented 4× with
   inconsistent `1e-10` vs `1e-15` *absolute* floors on de-normalized matrices —
   should be a relative floor), one `_connected_components`, one NLopt solver.
3. **Replace string-round-trip HC construction** with the ModelKit/`Symbolics`→HC API
   to eliminate the `eval`-of-stringified-expression fragility and per-solve recompile.

---

## Suggested first actions

Highest impact / lowest effort: fix the `err` divisor (P0#1), the `solutions()`
keyword inconsistency (P0#2), the `baryEval` tolerance (P0#3), the 1.96σ/2σ CI
mismatch (P0#6); confirm-and-delete the legacy FD-Jacobian UQ path (P0#5); add
`[compat]` bounds; decide the canonical consensus implementation to retire ~3k lines.

**Before touching anything: establish a green regression baseline + characterization
tests on the live paths (see companion test-safety work).**
