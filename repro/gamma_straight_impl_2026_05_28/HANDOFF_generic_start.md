# Handoff: `:generic_start` (ab-initio) homotopy seeding — cluster validation

Date: 2026-05-29
Commit: **`5a19c4a`** on `origin/main`
From: local-claude (Opus 4.7) → cluster-claude

## TL;DR — what to do

Pull `origin/main` @ `5a19c4a`. There's a new **opt-in** `EstimationOptions.homotopy_tracking_mode = :generic_start` (**default unchanged** = `:gamma_straight`, so nothing moves unless you set the flag). Run the 3-way receptor e2e A/B + crauste-with-debug, and report whether `:generic_start` fixes the receptor e2e failure and/or helps crauste.

---

## ⚠️ UPDATE (2026-05-29, later commit — pull newest main)

A max-effort code review found the **likely real cause of the `besterror=13.85` receptor failure, and it invalidates the earlier A/B as a mode comparison.** Pull the newest main (commit after `5a19c4a`) before running anything.

- **Root-cause candidate — column scaling was silently OFF on the multipoint path.** The production multipoint solve (`optimized_multishot_estimation.jl:1921`) forwarded only `:show_progress`/`:real_tol` — it **dropped `use_column_scaling`** (pre-existing, since column scaling shipped) **and** the new tracking-mode options. Since the multipoint solutions are **pooled** with the single-point ones for ranking/branch_completion, the pool was contaminated with cs-less, ill-conditioned (spurious) roots. Receptor is the system we *know* fails without cs (recovers 2/2 @0.4% with cs, 0/2 @8.5% without). So `13.85` is most plausibly **cs-off-on-multipoint**, not γ-straight.
- **Consequence for your earlier A/B:** because the multipoint path ignored `homotopy_tracking_mode`, the `:gamma_straight`/`:parameter`/`:generic_start` arms were **partly confounded** (multipoint contribution identical across arms, and cs-less). The newest main **fixes this** — multipoint now forwards cs + the tracking options — so the 3-way A/B is now a *valid* comparison. **Re-run it on the newest main.**
- **Also fixed:** γ RNG is now **deterministic by default** (`gamma_seed==0` ⇒ stable per-problem seed, reproducible; `<0` ⇒ entropy), with separate streams for the generic-start `p0` draw vs the per-point γ — so your A/B arms now see the *same* γ stream and are reproducible run-to-run.
- **NOT changed (deliberately):** `_track_gamma_straight` still keeps the result with the most *total* solutions (not most *real*) — that is correct: real-ness is a property of the target system, γ only changes the path, and complex solutions must be preserved for the downstream pool.

**CAVEAT for the regression-minded:** turning cs ON for the multipoint path is itself a default-behavior change for *every* system that uses multipoint (default on). It passes the 446 contract regression, but cs-on-multipoint recovery quality across the PEB systems is **not** broadly validated — treat it like the original column-scaling rollout and watch for recovery regressions on non-receptor systems.

### Revised priority
1. Re-run the 3-way receptor e2e A/B on newest main (now valid). **Key Q:** does `:gamma_straight` (default) now recover receptor (`besterror ~0.4%`) with cs reaching the pool? If yes → the `13.85` was the cs-drop, not γ, and the default is fine.
2. Broad recovery check (cs-on-multipoint): re-run a representative PEB slice and diff recovery vs the prior stored numbers — confirm cs-on-multipoint doesn't regress non-receptor systems.
3. Then the original `:generic_start` / crauste questions below.

---

## Background — why this exists

- **`:gamma_straight` was shipped as the default (`2604a7f`).** The faithful receptor end-to-end test (real pipeline, `analysis.besterror`) then **failed**: `besterror = 13.85` (baseline ~0.4%), 2 returned branches **200–1000% off** truth/swap, from `src=branch_completion`, satisfying the *trimmed algebraic system* to ~1e-6 but with a *trajectory* error of 13.85 → **spurious roots** (receptor's trim admits ~16). It converged *confidently to the wrong roots*.
- **Cause is NOT yet isolated.** This session shipped **two** new defaults — `:gamma_straight` *and* `branch_completion` — and the e2e used an **aaad-only** interpolator config. Any of the three could be the culprit. The `:parameter` arm of the e2e was still running at handoff time.
- **The anchor flaw (Oren spotted it):** the multishot anchors `initial_solution_count` to point 1's *real-data* fresh solve and uses it as both the γ early-stop target and the fresh-fallback threshold. A deficient point-1 solve silently caps the whole run and suppresses the fallback.
- **crauste (your finding):** its fresh polyhedral solve is unreliable at the real targets — 0–6 solutions on noise-free data, 17 outright zeros — which is *upstream* of any tracking strategy.

## What `:generic_start` does

In `solve_with_hc_parameterized` (homotopy_continuation.jl): solve **once** at a generic **complex** parameter point `p0 = randn(rng, ComplexF64, n)` — off the discriminant w.p. 1 ⇒ the full generic root count `N`, well-conditioned — then **fan out**, tracking `p0 → p_i` (γ-straight) to *every* real shooting point (no chaining). Sets `initial_solution_count = N` (the true generic count, fixing the anchor flaw). Degrades to the per-point fresh + γ-straight chain if the generic solve itself returns empty/throws. (Textbook ab-initio / coefficient-parameter homotopy; monodromy is the v2 robustification, not yet wired in.)

## Tests (priority order)

1. **Receptor e2e 3-way (highest priority).** Run `repro/gamma_straight_impl_2026_05_28/receptor_e2e_ab.jl` as-is — it loops `(:generic_start, :parameter, :gamma_straight)` and reports pipeline `besterror` + truth/swap recovery per mode.
   - **Key Q1:** does `:generic_start` recover receptor (`besterror ~0.4%`, truth+swap) where `:gamma_straight` failed (`13.85`)?
   - **Key Q2 (isolation):** does `:parameter` recover it? `:parameter` recovers ⇒ γ-bug; `:parameter` also fails ⇒ branch_completion or the aaad-only config is the culprit, not γ.

2. **crauste with `:generic_start` + `debug=true`.** Watch the `[HC-PARAM] Generic-start:` line.
   - Generic-`p0` solve finds **N>0** ⇒ generic-start *sidesteps* crauste's deficient real-target solves (the win).
   - Generic solve **also returns 0** ⇒ crauste is nasty-everywhere (coordinate-conditioning); generic-start degrades safely to per-point fresh+γ (no worse than now), and the fix is the scaling lever, not this.

3. **cstr / hiv / bioh.** Recovery + the `[HC-PARAM]` fan-out/fresh counts under `:generic_start` vs `:parameter` — confirm no regression on the systems that already work.

## Caveats to watch

- **Structurally-fixed params:** if a system's data-var "parameters" include fixed values (`_trfn_`, hard pins), randomizing `p0` could change the system. Flag if the generic count looks wrong or a *known-good* system stops recovering under `:generic_start`.
- **Failure-mode scope:** generic-start fixes the **divergence/anchor** mode, NOT **coordinate-conditioning** (that's column scaling). Your decider (`75244`) routes it: `at_infinity` verdict ⇒ expect generic-start to help; coordinate-explosion verdict ⇒ expect it not to.

## What the results decide

- `:generic_start` recovers receptor **and** `:parameter` also recovers ⇒ γ-straight was the culprit ⇒ consider making `:generic_start` (or `:parameter`) the default, pending broad validation.
- `:parameter` **also** fails the receptor e2e ⇒ branch_completion or the aaad-only config is the culprit ⇒ investigate those, not γ.
- crauste: generic `N>0` + recovery ⇒ generic-start cracks it; else it's upstream/coordinate (scaling lever).
