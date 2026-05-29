# Handoff: `:generic_start` (ab-initio) homotopy seeding — cluster validation

Date: 2026-05-29
Commit: **`5a19c4a`** on `origin/main`
From: local-claude (Opus 4.7) → cluster-claude

## TL;DR — what to do

Pull `origin/main` @ `5a19c4a`. There's a new **opt-in** `EstimationOptions.homotopy_tracking_mode = :generic_start` (**default unchanged** = `:gamma_straight`, so nothing moves unless you set the flag). Run the 3-way receptor e2e A/B + crauste-with-debug, and report whether `:generic_start` fixes the receptor e2e failure and/or helps crauste.

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
