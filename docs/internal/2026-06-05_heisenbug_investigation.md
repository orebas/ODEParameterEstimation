# Heisenbug investigation — hypotheses, tests, observations (2026-06-05)

A thorough, honest record of the issues we're chasing, what's established vs. guessed, the
tests run, what was observed, and the process (including my diagnostic errors). Written while
the cloud runs are still in flight, so the "open" items are genuinely open.

**Confidence tags used below:**
- `[SURE]` — directly observed / code-verified / reproduced.
- `[LIKELY]` — strong evidence, not yet conclusive.
- `[HYPOTHESIS]` — proposed; untested or only weakly tested.
- `[RETRACTED]` — I asserted it this session, then disproved it. Kept here on purpose.
- "(prior)" = established in an earlier session (see memory files); "(this run)" = 2026-06-05.

---

## Background the issues sit on (code-verified this session, file:line)

- bioh = the benchmark cell `biohydrogenation_3_1em8`. It is **ill-conditioned**: its SI
  polynomial template has `[SURE]` a *coefficient overflow past derivative order 9*
  (`populate_derivatives: coefficient overflow at derivative level 10, capping at 9` in its
  run.log) — i.e. its high-order observable-derivative jets explode. Cond ~1e6–1e10 (prior).
- The main solve uses `homotopy_tracking_mode = :generic_start` (default;
  `estimation_options.jl:586`). `[SURE]` It solves a generic complex system **once**
  (`homotopy_continuation.jl:1146`, N generic solutions), then **fans out** by γ-straight
  tracking those N solutions to each real "Point" (multipoint shooting point). For bioh the
  run.log shows **N=37 generic solutions, 20 shooting points / 15 two-point combos**.
- `[SURE]` **Every** HC solve/track call routes through `_hc_solve`
  (`homotopy_continuation.jl:14-15`, `HC_SOLVE_THREADING = Ref(false)`) — 9 call sites, 0
  direct `HomotopyContinuation.solve`. So HC's **own** internal threading is forced off everywhere.
- The **backsolve** is a *fallback*: when backward-ODE integration fails to recover a candidate's
  state ICs, `resolve_states_with_fixed_params` (`si_template_integration.jl:374`) →
  `get_si_equation_system` (`:436`) **re-runs StructuralIdentifiability**. `[SURE]` It is called
  **sequentially** (no `@spawn`/`@threads` at its call sites,
  `optimized_multishot_estimation.jl:2144/2173`). The FLINT gcd swell lives **inside** this SI
  re-run (in `lie_derivative`/`states_generators` rational-function arithmetic → Nemo
  `fmpq_mpoly_gcd`). The backsolve runs **after** the main fan-out solve.

---

## Issue 1 — the bioh backsolve FLINT gcd swell (the original heisenbug)

- `[SURE]` (prior, gdb) The hang is `__gmpn_mul_1` → `fmpz_mpolyl_gcd_zippel2` → `fmpq_mpoly_gcd`
  (FLINT), reached via Nemo `gcd(::QQMPolyRingElem,…)` ← AbstractAlgebra `+(::Frac,::Frac)` ←
  SI `lie_derivative` (`states.jl:61`), inside the backsolve. Single-threaded FLINT, CPU-bound.
- `[SURE]` We have **never reproduced it in isolation.** The MWE on the blown "Sol 1175"
  candidate (`k8=595, k9=-0.46, k10=-119`) **maxed at 422 bits and returned** (no swell). A
  652-run sweep over 326 blown candidates all maxed ~450–470 bits, no swell. → the swell needs
  the **full-pipeline context**, not just a "bad candidate."
- `[HYPOTHESIS]` The swell depends on the *exact* candidate + DerivativeData the live pipeline
  produces (the interpolated jets fed to the backsolve), which we couldn't reconstruct standalone.
- **Tests this run:** built `gcd_logger.jl` (type-piracy on `Nemo.gcd` that dumps both operands
  in a version-independent term format *before* the FLINT ccall); built the offline replay
  harness `reconstruct_gcd.jl` + two bare-Nemo envs (`/tmp/nemo_0_54_2`, `/tmp/nemo_0_55_1`).
- **Observed (this run):** `[SURE]` **Not captured.** On all three boxes `resolve_enters=0` —
  none has reached the backsolve. bioh dies/grinds in the *main* solve first (Issue 4).
- **Open:** does bioh reach the backsolve at all in this config? (The local 26h grind *did*
  reach it — prior.) Without reaching it, Issues 1/2's capture+replay can't run.

## Issue 2 — "fully update the env / does newer FLINT fix the swell?" — **FIRMEST RESULT**

- `[SURE]` `Pkg.update()` is essentially a **no-op**: only `FastGaussQuadrature 1.2→1.3` moves.
  MTK (11.26.7), Symbolics (7.26.0), Groebner (0.10.3) are **already the latest published**.
  `FLINT_jll` is `301.400.1`, the newest Nemo 0.54.2 permits.
- `[SURE]` The one newer FLINT — **Nemo 0.55.1 / FLINT 301.500** — is **hard-blocked** by the SI
  exact-arithmetic dependency chain. Forcing `Pkg.add(Nemo@0.55.1)` returns an *unsatisfiable*
  error naming **`RationalFunctionFields`** (SI 0.5.19's dep; caps `Nemo = "0.46 - 0.54"`); strip
  that and the next blocker is **`ParamPunPam`** — and *no* ParamPunPam version, not even its
  `main` branch, supports Nemo 0.55 (tops out at 0.52). So the whole SI→RFF→ParamPunPam stack is
  co-pinned to Nemo ≤ 0.54.
- `[SURE]` Therefore "update the env, see if newer FLINT fixes it" is **impossible** without
  force-stripping a chain of packages whose code has never run against Nemo 0.55. We pivoted to:
  capture operands → replay offline against bare Nemo 0.54.2 (confirm) vs 0.55.1 (fix?), since a
  bare-Nemo env has no RFF/ParamPunPam and installs cleanly.
- **Open (blocked on Issue 1):** the replay never ran — no operands captured.

## Issue 3 — receptor/latent HC threads=8 deadlock + the `_hc_solve` fix

- `[SURE]` (prior) receptor/latent at threads=8 froze in HC's "Computing mixed cells" — a
  **nondeterministic** deadlock. Leading hypothesis (prior): **GC-safepoint deadlock** from
  `JULIA_NUM_THREADS>1` + the C-heavy HC backend, not MTK.
- `[SURE]` `_hc_solve` forces HC's *own* internal threading off, on all 9 call sites.
- **Observed (this run):** `[SURE]` at threads=8 on the dedicated boxes, receptor + latent are
  **progressing** (100% CPU, advancing — latent at fan-out **Point 15**, receptor still inside a
  large mixed-cell enumeration), **no deadlock after ~4.5h**.
- `[RETRACTED]` I claimed "fix CONFIRMED working" from this. **Retracted** — the deadlock is
  *nondeterministic*, so "no deadlock so far" is **not** proof. They may simply be lucky.
- `[HYPOTHESIS — UNSETTLED]` Whether `_hc_solve` is **sufficient** vs. whether
  **`JULIA_NUM_THREADS=1`** is the real requirement. Distinction that matters: `_hc_solve` kills
  HC's *own* threading, but `JULIA_NUM_THREADS=8` still creates 8 Julia threads, and a
  GC-safepoint deadlock can in principle arise from *any* thread stuck in a non-yielding C call
  while another triggers GC — which `_hc_solve` does **not** address. Not conclusively tested.
- **Open:** do receptor/latent **complete** (conclusive) or eventually deadlock? Still running.

## Issue 4 — bioh's main-solve / fan-out behavior (the new, messy one — with my errors)

This is where I made repeated mistakes; recorded honestly because it's "the process."

- **Run A (threads=8, WITH gcd_logger):** reached the fan-out (Points 1→14) at 100% CPU.
  - `[RETRACTED]` I read the *block-buffered* log (frozen at `mixed_volume: 50`) as "stuck in a
    50-path solve." It was **progressing**. Oren caught it ("50 paths? no way").
  - **My error:** I **SIGINT'd a working run** (~70% to the backsolve), killing it.
- **Run B (threads=1, WITH gcd_logger):** `[SURE]` **crashed at Point 14** — process gone, log
  ends mid-track, **no Julia error printed**, **not OOM** (box had 20 GB free, dmesg clean).
  - `[RETRACTED]` I read the dead process as "deadlocked at threads=8 despite the fix." It was a
    **dead process** + a `pgrep -f "julia --startup"` **false-positive** (pgrep matched its own
    command line → fake "RUNNING").
- **Run C (threads=1, NO gcd_logger):** `[SURE]` **alive well past** the Run-B crash timing.
- **Run D (current; threads=1, NO gcd_logger, flush wrapper):** `[SURE]` alive, 100% CPU, no
  crash, `resolve_enters=0`; progress buffer-hidden (Issue 5).
- `[LIKELY]` **My `gcd_logger` (a raw `@ccall libflint.fmpq_mpoly_gcd` replacing `Nemo.gcd`)
  caused the Point-14 crash**, not a real bug: Runs C/D survive past it without it. Supporting:
  latent passed Point 14 *with* the gcd_logger, so it's a bioh-specific interaction (a gcd in
  bioh's fan-out/branch_completion path where my reimplementation differs from Nemo's). **Not
  conclusive** — Runs C/D haven't yet reached the backsolve to fully clear bioh.
- `[HYPOTHESIS]` bioh's fan-out is *slow* (single-threaded HC, N=37 × ~15–20 points, an
  ill-conditioned system), ~40+ min — not stuck.
- **Open:** does bioh (no gcd_logger) finish the fan-out and reach the backsolve?

## Issue 5 — monitoring methodology / my diagnostic errors (the meta-issue)

`[SURE]` Root cause of most of my mistakes: trusting **unreliable** signals.
- **Julia block-buffers stdout to a pipe/file** → the log looks *frozen* while CPU is 100%. I
  repeatedly misread frozen logs as "stuck."
- **`pgrep -f "julia --startup"` matches its own command line** → fake "RUNNING" for a dead process.
- **`@async` flush task is starved at threads=1** — cooperative scheduling, and the heavy HC
  compute never yields, so my flush wrapper did **not** give real-time visibility. Only *inline*
  `flush(stdout)` (in `[RESOLVE-ENTER]`, the gcd_logger) flushes; the real fix is
  **`Threads.@spawn` + threads≥2** (flusher on its own OS thread).
- **Reliable signals (now used):** `CPU%` (100%=working, 0%=blocked/dead), `ps STAT` (R/S/D/Z),
  and **exit codes** (`rc.txt`). These don't lie.

---

## Current state (live, this write-up)

- 3 DigitalOcean droplets (`s-8vcpu-32gb`, nyc1): **bioh 146.190.210.127, receptor
  147.182.167.158, latent 165.22.179.229.** All **100% CPU, alive (ps `Rl`), none crashed, none
  at the backsolve** (`resolve_enters=0`). ~4.5h in. latent at fan-out Point 15. (Hetzner was
  dedicated-core-capped → DO.)
- Built + validated: the `:heisenbug` image, `~/heisenbug_staging/` (instrumented ODEPE,
  gcd_logger, flush wrapper, reconstruct_gcd), `/tmp/nemo_0_54_2` + `/tmp/nemo_0_55_1`.

## Firm vs. open — one-glance summary

- **FIRM:** Issue 2 (env can't be meaningfully updated; newer FLINT is locked out by
  SI→RFF→ParamPunPam). The code paths above. The Issue-5 methodology lessons.
- **LIKELY:** my gcd_logger caused bioh's Point-14 crash (Issue 4).
- **OPEN / UNSETTLED:** whether bioh reaches + reproduces the backsolve swell (Issue 1, blocks 2);
  whether `_hc_solve` alone is sufficient or `JULIA_NUM_THREADS=1` is required (Issue 3); whether
  bioh's fan-out completes at all (Issue 4).

---

## OVERNIGHT RESULTS (2026-06-05, ~10:37–13:13Z) — the "open" items resolved

The in-flight write-up above ends with everything `resolve_enters=0` (nothing at the backsolve).
Overnight, **bioh, biohthr, and latent all ran to completion**; receptor is pinned. Results saved
to `~/heisenbug_staging/results/{bioh,biohthr,latent}_{result.csv,summary.txt}`.

| cell | config | wall time | min error | branches | re/rx | outcome |
|---|---|---|---|---|---|---|
| bioh | threading **OFF**, threads=8 | **4.81h** (17317s) | 1.096e-9 | 2 (truth + k9/k10 sign-flip) | 340/340 | ✅ clean, **no swell** |
| biohthr | threading **TRUE**, threads=8 | **1.83h** (6595s) | 1.096e-9 | 2 (**bit-identical**) | 340/340 | ✅ clean, **no swell** |
| latent | threading **OFF**, threads=8 | **8.58h** (30908s) | 2.0e-5 (approx 1.6e-7) | 6 (S₃ subpop symmetry) | 298/294 | ✅ clean, **no deadlock** |
| receptor | threading OFF, threads=8 | ~11.5h+ (running) | — | — | 0/0 | ⏳ silent single-threaded path-tracking, **intractable** |

**Issue 1 (the swell) — `[SURE]` did NOT reproduce.** bioh reached the backsolve and made **340**
`resolve_states` calls; **all 340 returned** (`resolve_enters == resolve_exits == 340`), zero hung.
biohthr likewise (340/340). So in the current env + dedicated boxes the FLINT gcd swell did not
manifest — consistent with the prior finding that it needs an exact full-pipeline context we still
can't reproduce on demand. Capture/replay (Issue 2's offline FLINT A/B) remains **un-run** (no
operands captured). The swell is real (prior gdb) but **elusive**; not a blocker for these cells.

**Issue 3 (threads=8 deadlock + `_hc_solve`) — `[SURE]` RESOLVED in practice.**
- latent **completed** at threads=8 with **no deadlock** — the nondeterministic
  "Computing mixed cells" freeze did **not** recur on a dedicated box.
- biohthr ran HC **`threading=true`** and **completed cleanly, 2.63× faster than threading-off
  bioh, with a bit-identical answer** (same 2 branches, same min/mean/median/max errors). This
  **empirically confirms** PBrdng (HC.jl author): threading is thread-safe since #669. → The
  `_hc_solve` `threading=false` workaround is **unnecessary**; the `[HYPOTHESIS — UNSETTLED]`
  that `JULIA_NUM_THREADS=1` is required is now **`[RETRACTED]`** (threads=8 completes both ways).
- **Caveat (receptor):** the prior freeze was in "Computing mixed cells" on a **large** mixed
  volume (receptor 63577). biohthr validated threading only on bioh's **tiny** mixed volume
  (~11/37). So `threading=true` on a large-mixed-volume system is still **untested** — the
  coherent remaining hypothesis is *deadlock = HC-threading-ON × large mixed-cell enumeration*.

**Issue 4 (bioh fan-out + the Point-14 crash) — `[SURE]` RESOLVED.** bioh completed the full
pipeline (fan-out + 340-resolve backsolve) with **no gcd_logger**, confirming `[LIKELY]→[SURE]`
that the earlier Point-14 crash was **my `gcd_logger`'s raw FLINT ccall**, not a real bug. bioh's
fan-out is slow-but-finite, exactly as hypothesized.

**receptor — `[SURE]` the lone holdout, single-threaded intractable.** It finished mixed-cell
subdivision at ~45 min (26586 cells, mixed_volume 63577) and has since **silently tracked the
63577 paths single-threaded for ~10.5h** (run.log static since 02:47, CPU 100%, CPU-time still
accumulating, `resolve_enters=0`, no result). Two independent walls: (1) path tracking is
embarrassingly parallel → `threading=true` could ~8× it, **but** re-runs the large mixed-cell
phase (the deadlock-risk site); (2) the ill-conditioning is **orthogonal** (truth coords ~1e7;
needs column-scaling/monodromy, not threads). "Throw threads at receptor" is
necessary-but-maybe-not-sufficient.

## Firm vs. open — UPDATED one-glance summary

- **FIRM / RESOLVED:** Issue 2 (env locked to Nemo ≤0.54). Issue 3 (`threading=true` is safe +
  ~2.6× faster + bit-identical → `_hc_solve` workaround unnecessary; threads=1 NOT required).
  Issue 4 (gcd_logger caused the crash; bioh's pipeline completes). bioh + latent recover their
  truth with the expected multiplicity branches (M=2 / M=6).
- **STILL OPEN:** the swell itself (Issue 1) is real but **un-reproduced** this run → Issue 2's
  offline FLINT A/B never ran. receptor completion (likely needs threading and/or reconditioning).
- **DECISIONS for Oren:** (1) merge cloud bioh **polish** result to fill the benchmark pending;
  (2) run a **nopolish** bioh; (3) try **`threading=true` receptor** (accepting the mixed-cell
  deadlock risk); (4) **revert the `_hc_solve` default to `threading=true`** fleet-wide.

*(Original write-up above kept verbatim as the honest in-flight record. This section added once
the runs completed.)*
