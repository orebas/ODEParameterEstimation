# Post-campaign review — 2026-06-10 (supersedes docs/2026-06-09_code_review.md)

Four read-only review lanes over the post-campaign state (suite 755/755 at
`2a4c8e6`): core pipeline, organization/boundaries, interface+PEB usage audit,
test architecture. Findings carry the lanes' VERIFIED/INFERRED tags; the standing
rule applies — **probe empirically before patching** (the previous review's P0
list was 2-for-6 wrong-as-stated).

**Verdict in one line:** the campaign's five fragility classes are materially
reduced, but the *ordering/permutation* class is not closed (three live P0s below
are exactly that family), the multipoint subsystem fails invisibly at default
verbosity, `Pkg.test` is broken (one line, campaign-introduced), and the public
surface (261 unique exports) plus two god files remain the big structural debts.

---

## P0 — correctness / broken-now (probe, then fix)

- [ ] **#1 `process_raw_solution` parameter-ordering self-disagreement.** First pass
  assigns params positionally by `original_parameters` index, solves the ODE and
  computes `err` from that assignment; a second pass then re-keys the same dict by
  `findfirst` in MTK order (`parameter_estimation.jl:779-783` vs `:830-840`; states
  already do it right). Producers disagree too: helpers build `raw` in MTK order,
  the seeded rescue uses `original_parameters` (`optimized_multishot:2778`).
  When MTK ≠ original ordering (the case `OrderedODESystem` exists for), reported
  err/solution and the returned parameter dict describe DIFFERENT vectors.
  VERIFIED code; latent (no CI model reorders). **Probe:** a model whose MTK
  param order differs from declaration order; assert err matches the dict.
- [ ] **#2 `_has_trfn` inspects `p_true`, but trfn vars live in `ic`** —
  always false, so multipoint never disables for transcendental models
  (`optimized_multishot:1731` vs `transcendental_utils.jl:620-633`); downstream
  the count-mismatch fallback bakes PROBE-point data into combo equations
  (`multipoint_template.jl:771-790`) → wrong-time candidates with wrong
  provenance, silently. VERIFIED.
- [ ] **#3 Multipoint→single-point projection fabricates `0.0`** for unmapped vars
  (`optimized_multishot:2457`) — the exact class Phase C exterminated in the data
  evaluators. Fix: NaN (existing finite guards reject). VERIFIED mechanism.
- [ ] **#4 `Pkg.test()` is broken: `Random` missing from the test target**
  (campaign regression — example_canaries.jl now does `using Random`; also confirm
  ModelingToolkit/OrderedCollections are declared for the test target). The
  include-based local gate masks this. Separately: **GitHub Actions red since
  ≥05-29** (nightly Enzyme-ext precompile), pre-existing. VERIFIED.
- [ ] **#5 PEtab extension provably cannot load** (pre-existing): stub includes
  `ext/petab/loader.jl` which doesn't exist (real files under
  `ext/ODEParameterEstimationPEtabExt/src/petab/` with no module file; stale inner
  Project.toml pins MTK 8 vs current 11). Fix include paths or retire. VERIFIED
  structure / INFERRED that no layout loads (not executed).

## P1 — silent failure / state / flakiness

- [ ] **Multipoint failures invisible at default verbosity:** template-build,
  combo-eval, and multipoint-HC catches all gate their `@warn` on
  `opts.diagnostics` (`optimized_multishot:2313,2406,2435`) — incl. the Phase-C5
  one whose comment promises the opposite. Ungate with `maxlog`. VERIFIED.
- [ ] **No varlist-consistency check across accumulated solutions:** per-point /
  per-interpolator varlists overwrite a single variable (`optimized_multishot:
  2268,2272`, `:2153-2155`) and all pooled solutions decode against the last one;
  a degenerate instantiation that drops/reorders one var mis-decodes that point's
  solutions silently. Default param-homotopy path is safe (shared template);
  standard path exposed. Add an isequal assert + drop-with-warn. VERIFIED
  structure / INFERRED trigger.
- [ ] **Threading landmines (dormant at JULIA_NUM_THREADS=1, will fire on the
  threading roadmap):** (a) always-installed timing sinks race on plain `push!`
  from polish `Threads.@spawn` workers (`optimized_multishot:1543`,
  `si_template_integration.jl:78`, `parameter_estimation.jl:2735`); (b)
  `_NOISE_VALIDATION_CACHE` keyed by `objectid` — unbounded session growth +
  GC-reuse wrong-Jacobian collision risk (`noise_frontier_construction.jl:664`).
  VERIFIED growth/race chain; INFERRED collision.
- [ ] **Unseeded RNG in structural decisions + stochastic src paths reachable from
  CI:** `_rank_based_fix_candidates` pivot RNG decides WHICH unidentifiable param
  gets fixed (`parameter_estimation.jl:420`); rank-probe `randn` in template
  stripping (`multipoint_template.jl:135,283` — the NF twin seeds the identical
  probe); terminal direct-opt fallback `randn` starts (`optimized_multishot:2897`,
  the default rescue — same coin-flip class as the canary we seeded);
  `_track_gamma_straight` random γ default (`homotopy_continuation.jl:752`);
  fast_core:1845 unseeded 1e-8 noise. Seed all like noise_frontier does. VERIFIED.
- [ ] **`lookup_value` prefix fallback survives:** last-resort
  `startswith(base*"_")` mapping can still bind wrong on overlapping prefixes and
  the heuristic chain is `@debug`-only observable (`parameter_estimation.jl:
  1623-1626,1542`). Demote to warn-or-error. VERIFIED code / INFERRED collision.
- [ ] **Partial data substitution solves a different system** when
  `data_values` shorter than `data_vars` (`multipoint_template.jl:1062,1139`);
  legacy range-builder admits non-contiguity the NF builder sorts away. Assert
  equality. VERIFIED code / INFERRED trigger.
- [ ] **Unguarded final ODE re-solve in polish** kills the whole estimation in the
  nothing-else-worked path (`parameter_estimation.jl:2375`; bare callers
  `optimized_multishot:2910`, `parameter_estimation.jl:2836`). Wrap like the loss.
  VERIFIED.
- [ ] `populate_derivatives` overflow check matches `occursin("Inf", …)` — a state
  named `Infected` would silently truncate derivative levels
  (`parameter_estimation.jl:59`). Word-boundary regex. VERIFIED mechanism.
- [ ] Hot-path unconditional logging: full varlist `@info` per template
  instantiation (`si_template_integration.jl:249,252`), `[ODEPE SOLUTIONS]`
  println ignoring `nooutput` (`parameter_estimation_helpers.jl:888`), ~8
  unconditional `@info` per resolve rescue. VERIFIED.

## P2 — organization & structure (mostly behavior-preserving moves)

- [ ] **Adjudicate the legacy non-SI-template multishot path (~1,050 lines):**
  zero external callers, `use_si_template=false` set NOWHERE, and the branch
  hard-crashes anyway (`use_adaptive_id` undefined at `optimized_multishot:3041`;
  `process_single_solution` defined nowhere). Archive it + make
  `use_si_template=false` error clearly. This also deletes the heaviest
  unconditional-println offenders. VERIFIED.
- [ ] **The `if (false)` dead chain** (~400 lines): helpers:922-1010 →
  `construct_multipoint_equation_system!` (contains its own undefined-`opts`
  crash) → `construct_equation_system` → `evaluate_poly_system`. Archive.
  VERIFIED.
- [ ] **Move `abstract type AbstractInterpolator` to types/core_types.jl**
  (currently `derivatives.jl:7`; one fragile load-order class). S/BP.
- [ ] **Evict the ~300-line research-only types block** (`core_types.jl:848-1148`,
  zero production uses) → `src/research/research_types.jl`. M/BP.
- [ ] **One-directionalize the diagnostics chunks** (move 4 `_write_html_uq*`
  writers + `_ROLE_*`/`_tokenize_equation` into html_report;
  `_compile_system_function` into feasibility_sensitivity; relocate svg_plots.jl
  under diagnostics/). S/BP.
- [ ] **God-file split maps ready** (lane-2 §3): optimized_multishot →
  timing/legacy/main(+seams); parameter_estimation → 7 clusters incl. a
  `core/polish/` pairing with polish_residual.jl. Execute after the P0/P1 fixes
  settle. M/BP.
- [ ] Housekeeping bundle (one commit): delete `src/untestedlinter.jl` (zero
  uses), empty `src/examples/pointpicker.jl`, empty `src/archives/`; move
  `src/diagnostics/analytical_branch_oracle.jl` → research/repro; dedupe export
  list (26 doubles); fix module:75 include-order comment; evict `.txt`/`.py`
  artifacts from `src/examples/benchmarks/`; fix-or-delete the broken
  `src/examples/petab/petab-ODEPE.jl`. S/BP.
- [ ] Dead consts in core_types (`IMAG_THRESHOLD` 0 uses; `MAX_ERROR_THRESHOLD`/
  `MAX_SOLUTIONS` comment-only) duplicate option fields; `cluster_solutions`
  ignores `opts.clustering_threshold` in favor of the const. Reconcile. S/SEM-lite.

## P3 — interface & docs (feeds Phase I)

- [ ] **Tier proposal (lane 3, the Phase-I foundation):** 261 unique exports →
  Tier-1 ≈ 91 (intentional API incl. model registry + enum blocks), Tier-2 ≈ 70
  (internal-but-used by PEB/repro/test — keep working, per-name user list
  captured), Tier-3 ≈ 82 genuine unexport candidates after treating enum values
  as blocks. PEB production hard floor documented per template. Decide tiers with
  Oren, then trim.
- [ ] **Docstring P0s:** `analyze_parameter_estimation_problem` — the #1 entry
  point used by every PEB template — has NO docstring; `EstimationOptions`
  constructor example passes functions to enum-typed fields (would throw);
  the `interpolators` (9-element default) silently overrides the documented
  `interpolator` scalar — document the precedence; `sample_problem_data` docstring
  shows pre-options kwargs; `ParameterEstimationResult` missing `branch_size`.
- [ ] Options `# Fields` catalog is ~39 fields behind the struct (whole families
  undocumented: branch_*, multipoint_*, shade_*, gamma_*, sensitivity_seed*…).

## P4 — test architecture

- [ ] **Track-or-lose:** commit `deprecated/test_uncertainty_quantification.jl`
  (currently untracked+gitignored = exists only on this machine); track
  `test_gp_kernel_optimization.jl`; delete or repoint broken `runtests_legacy.jl`
  (includes the moved UQ test file; shadows ParameterEstimationProblem with an
  inline struct). VERIFIED.
- [ ] **Coverage holes:** `system_construction_policy=:legacy` (zero tests, live
  branch), `:exp` transcendental class, `polish_solver_solutions=true` (the
  production default — CI forces it off), `homotopy_tracking_mode` non-default
  modes, RS ext (only via broken legacy runner), PEtab ext (none). The
  terminal-fallback testset is nominal-only (model never has an empty pool) and
  its provenance assert is a tautology (`feature_regressions:309-311`).
- [ ] **Quality:** `analysis[2] < 1e-2` on a zero-noise homotopy run masks ~4
  orders (`feature_regressions:283`); synth A/B assertions inside
  `if n_synth > 0` pass when synthesis is inert (`:769`); triplicated
  quiet-call/fixture helpers; 3 CI files can't run standalone (include-order
  coupling on canary helpers).
- [ ] **Runtime (~3-4 min cuttable):** 12-interpolator list in the synth A/B (3
  suffice); shared forced_decay fixture (3 testsets re-sample); research-consensus
  smokes (fast_core:527-1614) → opt-in lane.
- [ ] **Placement:** single `git mv` of ~30 research harnesses → `test/research/`
  (include chains preserved if moved together; two `..` paths need +1 hop).

---

## Designed follow-up — :generic_start anchor repair (Oren's go-back question, 2026-06-10)

The MP fan-out perf fix (target bumps with the fresh FINITE count, never the path
count) leaves a designed-but-unbuilt follow-up. If the new `@warn` tripwire
("fresh solve found more finite solutions than the generic-start anchor count")
EVER fires in a real run, the anchor undercovered. **STATUS: first firing OBSERVED
2026-06-10 on the cstr efficacy probe itself** (point 4 of an MP combo: fresh found
7 finite vs anchor N=3; all complex/projected — dedup-verify step 1 below matters
before trusting the 7). The follow-up is no longer speculative. — and since #isolated-finite at
any parameter ≤ the generic count, that means the p0 anchor solve LOST roots, which
also silently invalidates earlier points' "complete" fan-out verdicts. Plan (build
on first observed firing, not speculatively):
1. Dedup/verify the fresh M-solution set (clustered singular endpoints can inflate it).
2. Repair the ANCHOR: γ-track the M solutions p_i → p0 (complex), merge into
   `generic_start_solutions` → corrected N for all future points.
3. Re-fan-out the repaired anchor to points 1..i-1 and dedup-merge into their kept
   sets (tracking-priced, not fresh-solve-priced; all results are assembled before
   return so go-back is local to solve_with_hc_parameterized).
4. The deeper systematic fix is anchor-side completeness, and it is CHEAP (verified
   against installed HC.jl, 2026-06-10): after the one-time anchor solve at p0, run
   `monodromy_solve(...; trace_test = true)` seeded with the anchor solutions —
   tops up missing roots AND certifies completeness via the trace test (LRS18);
   standalone checker `verify_solution_completeness`. Cost is O(N_true) path-tracks
   (~seconds at N=3..18), vs the mixed-cells + BKK-paths fresh solve (CPU-hours;
   cstr MP: 393 paths for 3 solutions; receptor: 6402 for 18). Caveats: numerical
   certificate (pass ⇒ high confidence; fail ⇒ investigate — false negatives
   possible per HC's own docs); multi-component families make the trace fail
   honestly (seed more, e.g. from one fresh solve's finite set). FREE cross-check
   for SP systems: auto-M (quotient-basis dim) is already computed — anchor_N ≠ M
   is an exact undercoverage detector. Column-scaled anchor solve additionally
   reduces blind-spot path loss at p0 (receptor lesson). Detection via fan-out
   shortfall alone is opportunistic and misses the all-fan-outs-track-cleanly
   undercoverage case — the certificate closes that hole.

## Suggested execution order

1. **Now:** P0#4 test-target deps (one line, our regression) → commit.
2. **Quick correctness batch** (probe-first): P0#1 ordering, P0#2 `_has_trfn`,
   P0#3 projection-NaN + the P1 ungated-warn/seeding/guarded-resolve items —
   small, high-value, mostly in files we already steward.
3. **P2 structural batch:** legacy-path + if(false) archival (kills ~1,450 dead
   lines incl. two latent crashes), AbstractInterpolator/research-types moves,
   housekeeping bundle, diagnostics one-directionalization.
4. **P4 test batch:** track-or-lose, de-flake seeds, cheap coverage holes,
   runtime cuts, test/research mv.
5. **Phase I:** tier decision with Oren (lane-3 lists ready), docstring P0s,
   export trim + PEB coordination.
6. PEtab ext: fix-or-retire decision (Oren).
