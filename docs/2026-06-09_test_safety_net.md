# Test Safety Net — companion to the 2026-06-09 code review

**Goal:** before touching anything from `docs/2026-06-09_code_review.md`, make sure
we can tell whether a change broke something. Two distinct needs:

- **Refactors** (dead-code removal, dedup, type annotations, file splits — the bulk
  of the work) must **not** change behavior. Net = a green end-to-end suite + a few
  characterization locks on the exact functions being moved.
- **Bug fixes** (the P0 items) **intentionally** change behavior. Net = a test that
  asserts the *correct* result, written now as `@test_broken` so it (a) documents the
  bug, (b) stays out of the green signal, and (c) flips to "Unexpectedly Pass" the
  moment the fix lands.

---

## Baseline

CI suite (`test/runtests.jl`) = 7 files:
`fast_core`, `example_canaries`, `examples_smoke`, `identifiability_regressions`,
`result_processing_helpers`, `feature_regressions`, `test_shade_lm`.

**Before any change:** run it and record green.
```
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/runtests.jl")'
```
(For a faster inner-loop signal, `include("test/fast_core.jl")`.)

> ⚠️ The working tree is **dirty** (20 modified tracked files, nothing committed,
> plus a `petab-import-wip` stash). The baseline is therefore against *uncommitted*
> work. Recommendation: commit or stash the current delta first so refactors can be
> `git diff`'d against a clean known-good point.

---

## Coverage map vs. the planned work

| Planned change | Existing CI coverage | Gap |
|---|---|---|
| **P0#1** err divisor (`process_raw_solution`) | `result_processing_helpers.jl` exercises the fn but only asserts `err < 1e-8` — the bug *deflates* err, so the test passes **with** the bug | **YES** — need a test pinning the divisor → added |
| **P0#2** HC `solutions()` keyword / `Inf` roots | end-to-end recovery (canaries) would catch gross breakage | partial — covered indirectly; a direct "no Inf in returned roots" assertion is hard at unit level |
| **P0#3** `baryEval` near-node tolerance | AAA only exercised end-to-end (`feature_regressions`, `fast_core`); no direct accuracy test | **YES** — interior-accuracy lock added; dense-grid near-node repro noted |
| **P0#4** `parse_derivative_variable_name` callers | `identifiability_regressions.jl` "substring-heavy names" (end-to-end) | parser has **no** unit test → characterization lock added (the real fix is caller-side) |
| **P0#5** legacy FD-Jacobian UQ (likely dead) | none | confirm-dead-then-delete; no test needed if unreachable |
| **P0#6** CI 1.96σ vs 2σ | `feature_regressions` touches `diagnose`/sigma_d but not this constant | minor; could add a UQ consistency assert later |
| **Refactor:** consensus sandbox dedup/deprecate | LIVE paths `branch_completion` (`fast_core`), `synthesize_aggregates` (`fast_core`+`feature_regressions`), `diagnose_uncertainty` (`feature_regressions`) are all touched in CI | adequate — keep those green while deleting the research-only v1/v2 |
| **Refactor:** split `diagnostics.jl`, dedup NLopt solvers, type annotations | end-to-end canaries + feature_regressions | adequate (behavior-preserving moves) |

**Verdict:** existing CI is a *solid* refactor net (end-to-end recovery accuracy on
several models + contracts + the live consensus paths). The real holes are direct
tests for the three pure-ish functions the P0 fixes touch. Those are added in
`test/refactor_safety_net.jl`.

---

## `test/refactor_safety_net.jl` — what it adds

Convention inside the file:
- `@test` → behavior to **lock** (green now, must stay green through refactors).
- `@test_broken` → **correct** behavior the P0 fix should produce (red now → flips on fix).

1. **`parse_derivative_variable_name`** — locks documented behavior on normal SIAN
   names; documents the `k_2`→`("k",2)` ambiguity so the caller-side P0#4 fix has a
   guard. (The fix is in `classify_si_ring_variable` / `_multipoint_deriv_order`,
   which must check known params *before* parsing — not in the parser itself.)
2. **`aaad` / `baryEval`** — locks interior interpolation + first-derivative accuracy
   on a normal grid so the P0#3 tolerance fix cannot regress the common case.
3. **`process_raw_solution` error divisor** — offsets `simple()`'s two observables by
   a known δ and recomputes the per-observable sum from the *same* `ode_solution`;
   asserts the current `/(n_obs+1)` behavior (`@test`) and the correct `/n_obs`
   behavior (`@test_broken`). Robust to solver tolerance because it reuses the
   returned solution rather than predicting an absolute magnitude.

Run standalone:
```
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/refactor_safety_net.jl")'
```
Once green, it is wired into `test/runtests.jl`.

---

## Not yet covered (future, lower priority)

- A "returned roots are all finite" assertion to pin P0#2 at integration level.
- A UQ test asserting the printed CI half-width equals the coverage-test multiplier (P0#6).
- A dense-grid (`spacing < 5.6e-4`) AAA case that actually *triggers* the
  two-nodes-in-window bug for P0#3 (the interior lock covers the regression risk; this
  would additionally demonstrate the bug).
