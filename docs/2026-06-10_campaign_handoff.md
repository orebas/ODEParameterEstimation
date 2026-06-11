# Maintainability campaign — in-repo handoff (narrative + roadmap)

**Purpose.** A durable, in-repo narrative of the 2026-06 maintainability campaign and,
especially, the **roadmap of next stages** so the work can be resumed cold. This is the
*narrative*; the *live work tracker* (open P0–P4 items, checkboxes) is
[`docs/2026-06-10_postcampaign_review.md`](2026-06-10_postcampaign_review.md). When the
two disagree on status, the tracker wins.

- **As of:** 2026-06-11. Branch `main` HEAD before this doc: `d709196`. Fast suite:
  **755/755 green** (`julia --startup-file=no -e 'include("test/runtests.jl")'`).
- **Standing goal (Oren):** easier to fix, less fragile, easier to maintain — attack bug
  *classes*, not instances. Gate everything on the FULL `runtests.jl` (fast_core alone is
  contracts-only and NOT a valid gate). Small, root-cause-explicit commits.

---

## 1. Maintainability campaign A–H (done)

Ran 2026-06-09/10 on top of the 2026-06-09 review + P0 bug-fix rounds. ~5.2k lines
archived to the build-excluded `deprecated/`; suite **673 → 755**.

- **A — tests first.** Parser characterization battery (3 known warts LOCKED), a seeded
  1%-noise recovery canary, a diagnose-HTML smoke, `lookup_value` unit tests.
- **B — name-map.** `template_var_map` (explicit MTK→jet-0 map, born at `nemo2mtk`,
  threaded via `si_template_metadata`) replaces string name-guessing on the result path;
  heuristics demoted to a `@debug` last resort. `forward_subst_dict` emptiness is a
  workflow DISCRIMINATOR — never populate it.
- **C — fail-fast.** Missing data → NaN (never silent 0.0) in the HC/multipoint
  evaluators; unconvertible Nemo coefficient → hard error (never silent 1);
  all-sentinel polish → Inf + revert-to-seed + `:polish_all_sentinel`; swallowed
  exceptions at least logged. Suite unaffected ⇒ healthy paths never relied on fallbacks.
- **D — single-implementation.** One jet-label parser (`parse_jet_label`) behind
  contract-preserving adapters; shared NLLS residual closure + exception logging;
  `_quick`/`_testing` solver variants archived.
- **E — surface + UQ.** 7 stored-but-unread `EstimationOptions` fields +
  `get_solver_options_dict` deleted (grep for kwarg passers before deleting fields!);
  the UQ sidecar rewired to the IFT `diagnose_uncertainty` path (FD-Jacobian path
  archived; result contract now `Union{Nothing,UncertaintyReport}`); direct-opt canary
  was an unseeded per-session coin flip — now seeded.
- **F — hygiene.** `derivatives.jl` dead-interpolator island archived; the 5,443-line
  `diagnostics.jl` split into 6 files under `src/core/diagnostics/`.
- **G — wrap-up.** `test/benchmark_smoke.jl`: a seeded, noisy, full-scale,
  best-of-branch recovery guard (deliberately NOT in the fast gate; run before a cluster
  handoff).
- **H — post-campaign re-review.** 4 read-only lanes → the live tracker
  `docs/2026-06-10_postcampaign_review.md`.

Memory/topic files: `project_2026_06_10_maintainability_campaign.md`,
`feedback_maintainability_goal.md`.

## 2. Post-campaign P2 structural batch (done — `1990836..90fa521`)

−2,304 production `src/` lines, suite 755/755 throughout, gate-verified each commit:

- Archived the legacy non-SI-template multishot path (1,037 lines; crashed if reached;
  `use_si_template=false` now errors).
- Archived the `if(false)` dead-diagnostics chain (532 lines; no-op AND uncalled).
- Evicted the research-only result/option types from `core_types.jl` →
  `src/research/research_types.jl` (production `Timing*` types stayed; they were
  interleaved). `core_types.jl` 1,242 → 934 → 947 lines.
- Housekeeping: dropped `untestedlinter.jl`, empty orphans, `src/archives/`, 3 benchmark
  `.txt`; moved `analytical_branch_oracle.jl` out of build; deduped 26 export doubles.
- Moved `AbstractInterpolator` → `core_types.jl` (latent load-order fix: a consumer was
  included 7 files before the definition, surviving only by lazy in-function eval).
- One-directionalized diagnostics (UQ HTML cluster → `html_report.jl`); relocated the
  cross-cutting `_compile_system_function` → `core/analysis_utils.jl` (forward-only).

> Lesson, recurring: **every P2 tracker claim was optimistic or wrong** ("zero uses" =
> "only the export line"; "empty dir" had a subdir; "diagnostics-local" was cross-cutting
> with 5 callers). Probe empirically before patching — that discipline kept the suite green.

## 3. The hiv / polish / ill-scaling investigation (P0 #0, CORRECTED)

A long thread (2026-06-11) that started as "hiv recovery regression" and ended as a
**reproduction artifact + a set of real latent fragilities**. Full record:
`docs/2026-06-10_postcampaign_review.md` P0 #0; memory `project_2026_06_11_hiv_regression.md`.

- **Not a regression.** The canary used the repo `hiv()` — raw physical scales
  (`beta=2e-5 … k=50`, `x(0)=1000`, ~8 orders) — with **no optimization bounds**. The
  2026-05-29 benchmark used a DIFFERENT, nondimensionalized **O(1)** hiv (params/ICs all
  in `[0.15, 0.9]`) WITH `SEARCH_BOUNDS=[1e-5,10]` that contain it → well-conditioned
  log-space polish → recovers to 6e-11. Different model + config.
- **Re-test on the repo model** isolates it as a bounds/scaling effect: no-bounds
  best-of-branch **43.7** (linear-coord polish diverges to negative-beta garbage),
  PEB-bounds `[1e-5,10]` **3.05** (clamps `k=50`/`x=1000`), wide positive `[1e-8,1e4]`
  **5.5e-4 RECOVERS**.
- **Retracted en route** (cautionary — three wrong theories before landing): "truth
  deduplicated away" (no — the polish seeds ARE the truth, err 1.14e-10); "polish crashed
  / Optim non-finite" (no — zero exceptions; the residual path sentinel-fills 1e6
  gracefully; that warning was a mis-read old-commit log); "benchmark regression" (no).
- **Real latent fragilities** (the valuable catch — every link only fires once polish
  produces garbage, which needs absent/non-containing bounds on an ill-scaled model):
  1. **Unbounded polish uses `:linear` coordinates** (`_choose_polish_transforms` →
     `:linear` when bounds are absent/non-positive; `compute_default_bounds` returns
     SYMMETRIC ±1e9·scale → also non-positive → `:linear`). On an ill-scaled Jacobian an
     LM step from the truth seed overshoots to garbage. → wants data-driven scaling
     regardless of user bounds.
  2. **The revert guard can return worse-than-seed**: it keeps the polished point when
     `final_norm ≤ initial_norm`, but with mis-bounded coords the truth seed itself
     evaluates huge, so garbage wins. A polish stage that silently degrades its input.
  3. **Ranking `:sat_neg1_err` lets an `is_untagged` provenance flag VETO a 13-orders
     better `err`** (a perfect-but-untagged truth loses to a tagged-but-garbage rep);
     then **auto-M=1 truncates** to that single wrong rep.
- **This motivates the rescaling work** (§4): make the problem O(1) up front so the solve
  and polish are well-conditioned irrespective of bounds. See
  `docs/2026-05-01_variable_scaling_investigation.md`.

## 4. The rescaling work (designed; this is R1 below)

Automatic **power-of-2 problem rescaling** — a low-risk, opt-in pre/post wrapper
(`src/core/problem_rescaling.jl`) mirroring the transcendental `transform_pep_for_estimation`
pattern. It rescales states / parameters / observables / data to O(1) (powers of 2 only;
time scaling deferred), runs the unchanged estimation, and un-rescales the results.
Default OFF (`auto_rescale::Bool=false`) → byte-identical until enabled. Fix mechanism =
**conditioning** (O(1) variables → well-conditioned solve + polish). Full design and
correctness traps: the campaign plan + `docs/2026-06-10_postcampaign_review.md`.

---

## 5. ROADMAP — next stages (ordered, resumable)

**R1 — Rescaling integration (LANDED, DEFAULT ON — validated 2026-06-11).**
Default flipped to `auto_rescale=true` after: full gate 864/864 green WITH it on; an
on-vs-off breadth sweep where every model IMPROVED, none regressed (vanderpol
6.9e-6→3.8e-6, fitzhugh 3.5e-3→1.6e-3, brusselator 9.9e-4→9.9e-5, daisy_mamil3
6.4e-2→2.0e-2). Better conditioning helps well-scaled models too, not just broken ones.
NOTE for the PEB fleet: with default-on, user-supplied `opt_lb/opt_ub` are interpreted
in SCALED coordinates (a `@warn` fires). For PEB's nondimensionalized O(1) models the
scaling is near-identity so bounds ≈ unchanged, but auto-rescaling user bounds is a
clean follow-up (R1c); pass `auto_rescale=false` in a driver to opt out.
`src/core/problem_rescaling.jl` (`choose_scales` via least-squares over
equation/observable/data-anchor rows rounded to integer power-of-2 exponents;
`rescale_pep`/`unrescale_results`); `auto_rescale::Bool=false`; wired after the
transcendental block, un-rescaled after `analyze_estimation_result` (UQ runs before
un-rescale; `.err`/`.solution` left in scaled units, documented). **PAYOFF CONFIRMED:**
the raw-scaled repo `hiv()` (params 2e-5…50, x(0)=1000) goes from best-of-branch
**43.7 (garbage) → 1.2e-3 (recovers)** with `auto_rescale=true`. 109 unit tests
(`test/test_rescaling.jl`, in the gate) + the hiv payoff in `benchmark_smoke.jl`.
Fix mechanism = conditioning (the scaled-value log2 spread drops ~26→~11 bits).
Remaining flip-on bar before default-ON: full suite unchanged with it forced ON across
the registry + a PEB benchmark sweep showing net gain (default-OFF makes it byte-identical
today). MVP scales states/params/observables/data only — TIME scaling is the deferred
follow-up (R1b).

**R2 — Polish robustness** (P0 #0 fragilities 1–2): keep the HC provenance tag when a
polish result is reverted (a reverted solution is still HC-sourced); make the revert
guard never return worse-than-seed (treat a sentinel/non-finite *seed* evaluation as
"can't judge → keep seed"); stop unbounded `:linear` divergence (data-driven polish
coordinates regardless of user bounds — partly subsumed by R1).

**R3 — Ranking overtuning fix** (P0 #0 fragility 3; **awaits Oren's steer** on his
2026-05-15 `:sat_neg1_err` tuning): don't let `is_untagged` veto a large `err` gap — make
`err` the primary key when errors differ by >~1–2 orders, or restrict the untagged
tie-break to comparable-`err` candidates. Validate against the M≥2 cases (seir,
daisy_mamil4, biohydrogenation, flexible_arm) the heuristic was built for.

**R4 — God-file split** (P2; maps ready in the tracker): `optimized_multishot` →
timing/legacy/main(+seams); `parameter_estimation` → ~7 clusters incl. a `core/polish/`
pairing with `polish_residual.jl`. Execute after R1–R3 settle.

**R5 — Phase I export/API tiering** (tracker P3, task #9): 261 exported names → tiered
public/internal (PEB usage audit captured in `docs/2026-06-10_phaseI_api_usage_audit.md`
— PEB uses *qualified* access, so unexporting is safer than the count implies); docstring
P0s (`analyze_parameter_estimation_problem` has none); the option `# Fields` catalog is
behind. Needs Oren's tier sign-off.

**R6 — `:generic_start` anchor-completeness follow-up** (tracker; first firing observed):
monodromy_solve + trace-test anchor repair — re-track when a fresh solve reveals the
generic anchor undercovered.

**R7 — PEtab extension** fix-or-retire (provably can't load) — Oren decision.

**Backlog (P1/P4):** multipoint varlist-consistency assert; threading landmines;
`test_*.jl` track-or-lose + coverage holes (`:legacy` policy e2e, `:exp` trfn,
polish_solver default); dead consts in `core_types` (export-tied → fold into R5);
`cluster_solutions` vs `opts.clustering_threshold` reconcile.

---

## 6. Verified discipline (carry forward)

- The ONLY valid estimation gate is full `julia --startup-file=no -e 'include("test/runtests.jl")'`
  (~13 min); `fast_core.jl` is contracts-only. Run `test/benchmark_smoke.jl` before a
  cluster handoff (seeded, ~5 min, not in the gate).
- **Probe empirically before patching** any review/tracker finding (the last two reviews
  were each ~2-for-6 wrong-as-stated; the hiv thread took three wrong theories).
- `test_*.jl` is repo-gitignored — new CI test files need an explicit `!` exception AND a
  `git ls-tree HEAD` check that they landed.
- Seed any test touching `randn`/RNG paths (`Random.seed!`) — Julia seeds per session.
- Kill background julia by PID (`pgrep -f … | head -1`), never bare `pkill -f` (self-match).
- Commit file-deleting refactors ATOMICALLY (stage rename+content together).
- `Pkg.test` ≠ the local include-gate (separate `test/Project.toml` deps).
- `sed -i` invalidates the Edit read-state → Read again before editing.
