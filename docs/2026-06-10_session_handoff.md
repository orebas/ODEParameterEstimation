# Session handoff — 2026-06-10 (maintainability campaign A–H + open findings)

Pick-up doc for the next session. Authoritative trackers:
- **`docs/2026-06-10_postcampaign_review.md`** — the live prioritized work list (P0–P4).
- Off-repo ledger (richer history): `~/.claude/plans/ok-let-s-make-sure-cryptic-fiddle.md`
  and memory `project_2026_06_10_maintainability_campaign.md`.

## Where we are

HEAD `fee81bc` on `main`, tree clean except 3 generated artifacts
(`artifacts/diagnostics/forced_decay_polynomialized/*`,
`repro/.../variable_cost_trim.jsonl`). Fast suite **755/755 green**;
`test/benchmark_smoke.jl` 7/7 (~5 min, not in the gate).

Campaign phases **A–H complete** (~28 commits `a09f33f..fee81bc`):
- A tests-first; B explicit `template_var_map` (kills name-guessing); C fail-fast
  fallbacks; D parser + NLopt dedup; E zombie-options + UQ→IFT rewire; F derivatives
  archive + diagnostics.jl split ×6; G benchmark smoke guard; H 4-lane re-review →
  the new tracker doc + the `Pkg.test` Random-dep fix.
- ~5.2k lines archived to build-excluded `deprecated/`; suite 673→755.

## Verified discipline (carry forward)

Full `runtests.jl` is the only valid gate (fast_core is contracts-only). Probe
empirically before patching any review finding (last two reviews each had
wrong-as-stated items). `sed -i` invalidates Edit read-state. Kill bg julia by PID,
never bare `pkill -f`. `test_*.jl` is gitignored (needs `!` exceptions). Seed any
randn-touching test. Commit file-deleting refactors ATOMICALLY (a split F1/F2 commit
left an unloadable tree once). `Pkg.test` ≠ the local include gate — verify both.

## Next steps (from the tracker, in order)

1. **P0 probe+fix batch**: process_raw_solution param-ordering self-disagreement;
   `_has_trfn` checks p_true not ic; multipoint→SP projection fabricates 0.0; the
   cheap P1s (ungate multipoint warns, seed structural RNG, guard final polish solve).
2. **P2 structural batch**: archive the legacy non-SI multishot path (~1,050 lines,
   zero callers, contains an undefined-var crash) + the `if(false)` dead chain
   (~400 lines); move `AbstractInterpolator` and the research-types block to
   types/research; housekeeping bundle; diagnostics one-directionalization.
3. **P4 test batch**: track-or-lose (deprecated UQ test exists only on this machine;
   track test_gp_kernel_optimization; fix/delete runtests_legacy); de-flake seeds;
   cheap coverage holes (:legacy policy, :exp trfn, polish_solver_solutions default);
   `test/research/` mv of ~30 harnesses.
4. **Phase I** interface shrink: lane-3 tier lists are ready (~91 public / ~70
   internal-but-used / ~82 unexport; PEB per-template hard floor documented). Decide
   tiers with Oren; fix the docstring P0s (analyze_parameter_estimation_problem has
   NONE). Tasks #8/#9 in the session task list.
5. **PEtab extension** fix-or-retire decision (Oren) — provably can't load.

## OPEN FINDING — :generic_start MP fanout perf bug (codex report 2026-06-10)

Reported by codex on a 17h cstr_0_1em8 cell; adjudicated as **REAL, pre-existing,
NOT touched by the campaign** — a PERFORMANCE bug, not correctness.
**FIXED 2026-06-10** (commit following this doc's): the completeness target now
bumps with the fresh solve's FINITE solution count, never the only_finite=false
path/endpoint count; plus an undercoverage `@warn` tripwire — which FIRED on its
first probe run (fresh 7 finite vs anchor N=3 on a cstr MP combo), making the
anchor-repair follow-up (monodromy_solve + trace test, design in the postcampaign
review doc) non-speculative. Efficacy probe verified mechanics (no count-branch
fresh-solves possible; this reduced config sits fully in the at-infinity blind spot
so its fresh-solves are genuine); the original cell's 15h collapse is implied by
codex's logged `3 < 393 genuinely short` discarded-finite pattern + arithmetic,
not re-measured. Was at `src/core/homotopy_continuation.jl:943-964`.

Root cause: in the `:generic_start` (default) MP path, after point 1's fanout comes
up short and triggers a fresh `_hc_solve`, line 964 bumps the loop-persistent
`initial_solution_count` (init line 904, the legitimate completeness target = N
generic solutions) to the FRESH solve's `only_finite=false` endpoint count — i.e.
the homotopy PATH count (~Bezout/BKK, e.g. 393), which includes ~390 at-infinity
endpoints. But every subsequent point's fanout tracks only N (=3) generic paths
(`target_count = length(generic_start_solutions)`, line 949), so its `n_accounted`
can never exceed 3 → the test `n_accounted < initial_solution_count` (3 < 393) is
permanently unsatisfiable → EVERY later MP point fresh-solves. On the cstr cell:
135 MP combos × fresh solve ≈ 15.4h.

Trigger condition: point 1's fanout must be short/empty (the documented at-infinity
"blind spot" for cstr/receptor-class systems). Easy models track point 1 cleanly,
never bump, never hit it — which is why it's a hard-cell-only blowup.

Two distinct issues (codex's framing, confirmed):
1. **The bump conflates two quantities** (generic SOLUTION count N vs fresh-solve
   PATH count) — the proximate, guaranteed-trigger defect. Fix candidates: never
   bump `initial_solution_count` past N; or cap the comparison at the fanout's
   trackable max (N); or compare finite-vs-finite on both sides; or invalidate
   generic-start for the batch once point 1 fresh-solves and switch to chained
   γ-straight / fresh+track.
2. **Generic anchor returning only N=3 for a ~48-var MP system** + losing all paths
   to infinity at the first real point — deeper; may be genuine generic undercoverage
   OR the known at-infinity blind spot (see memory project_2026_05_26_receptor_solution_count:
   truth coords span ~1e7, unscaled polyhedral can't track → column scaling / monodromy
   was the receptor fix). Needs its own probe before any fix.

Correctness note: results are NOT corrupted — the fresh solve still finds the
solutions; it's pure wasted time. Confidence: HIGH on the bump logic (read +
git-verified scoping & history); MEDIUM on issue-2 mechanism (matches documented
blind spot, not re-probed this session).

**Before fixing:** probe-first per discipline — confirm on the cstr MWE that capping
`initial_solution_count` at N collapses the 135 fresh-solves to fanouts without
changing recovered solutions; and separately probe whether N=3 is the true generic
finite count (vs undercoverage) via `solutions(fresh; only_finite=true)` count.
