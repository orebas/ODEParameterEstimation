# Benchmark fleet v2 — plan (what the DO/local run taught us → the Hetzner run)

> Migrated into the repo on 2026-06-04 from the working plan file (previously only in
> `~/.claude/plans/`, not version-controlled). **This is the canonical home for the v2 /
> Hetzner-run plan**, including the solver-side threading section. Related docs:
> `2026-05-25_quoll_benchmark_handoff_spec.md` (the run just completed); benchmark-*design*
> methodology (run variants, manifests) lives in PEB's `NEXT_BENCHMARK_RECOMMENDATIONS.md`.
> Most "Critical files" below are in the **PEB repo** (`cloud/hetzner/`, `docker/`, `src/`).

## Context
The fleet concept is **proven**: a 3-provider + local, filesystem-coordinated fleet ran the quoll broad matrix; every completed system recovered to machine precision (13/13 < 1e-3, besterror down to ~1e-28), and wall times were clean vs wallaby (all 0.5–1.7×, no regressions). But the run surfaced several **mechanical** problems — none about the science, all about the harness — that we should fix *before* committing the Hetzner run (256 vCPU granted, dedicated CCX). This plan captures the lessons and the v2 design. The biggest is not "latent is slow" — it's that **the harness threw away work latent had already finished.**

## Lessons from the run (the "why")
1. **Shard-atomic collection discards completed work.** `fleet.py` rsyncs a box only in the *success* path (after `/work/DONE`, lines 201-202); the `finally: destroy()` (≈215) runs on timeout/error **without rsyncing**. The container *does* write each cell's `result.csv` to disk as it finishes — so the latent cells weren't slow-and-lost, they were **done-and-deleted** when the 12 h timeout fired. This is the #1 fix.
2. **The bottleneck systems aren't slow — the shared hardware is.** latent_branch = **~57 min/cell on the local box (recovered 4.47e-12)** vs ~2.3 h on a DO shared 8-vCPU droplet — a ~2.4× penalty, plus shared-core jitter (a lone brusselator cell hit 5.3 h). crauste is the *only* genuinely slow one (~2.5 h/cell even local).
3. **Hard cells are serial.** crauste used ~1 CPU (102%) of 4 allocated threads; latent/bioh ~2.25. So **threads-per-cell don't help these solves — concurrency does**; boxes ran ~56 % utilized. ccx33-vs-ccx43 is a wash for them.
4. **Coarse shards = coarse failure.** A 24-cell shard dies whole on one timeout; SLURM's per-cell model would lose one cell.
5. **AMIGO2 online-licensing contention at conc 16** → 49 cells failed with MATLAB error 5001/5006 in time-windowed blocks; no auto-retry, manual re-run needed. Detector `rerun_failed.sh` keys on `===END===`, which estimate.py writes *even on failure* — wrong signal.
6. **Config drift:** the run used `POLISH_MAXTIME=600` while the reference/default is 3600 (`config_quoll_broad.json` vs `config.json`).
7. **Active cron monitoring caught all of it** — but these fixes belong *in the fleet*, not in a human-in-the-loop.

## v2 improvements (prioritized)

### P0 — Failure-safe collection + cell-level resume  *(the critical fix; design validated by Plan agent)*
**Goal:** a timeout / error / abrupt box death loses **at most ~20 min** of completed cells, and a re-run finishes only the **missing** cells.
- **Pull-before-destroy.** Add `pull_results(ip, dest)` (the existing `rsync -az root@ip:/work/ → dest`); move `dest=RESULTS/run_id/label` above the `try`; **delete** the success-path rsync (200-202); in `finally`, `pull_results()` **then** `destroy()`. Now every exit path (success/timeout/error) pulls first. `fleet.py` `run_shard` 168-216.
- **Periodic incremental pull.** Replace `wait_for(...DONE...)` (198) with a wait-loop that does a best-effort `pull_results` every ~15-20 min while polling DONE — covers the case where the coordinator can't reach a dying box at the end. Same idempotent rsync, so periodic + final is safe.
- **Pin the bench-dir DATE (load-bearing).** `run-benchmark.sh:19` uses box-local `$(date +%Y-%m-%d)`; a cross-day resume would create a *second* `benchmark_*` tree under `dest` and corrupt the merge (`collect.py:30`). Thread a run-stable `--date` from `fleet.py` → `run-on-box.sh` → `run-benchmark.sh` so the tree name is idempotent across pulls/re-runs.
- **Cell-level resume.** Split `already_done()` (93-95) into `shard_progress()` (present-vs-expected per-cell `result.csv`) + `fully_done()` (`present>=expected` OR top-level merged csv exists). A partial shard is re-dispatched but runs only missing cells: ship prior partials to the box (`--prior`, a bind-mount), have `run_lane()` (run-benchmark.sh 125-135) **filter the xargs index list** to drop cells whose `result.csv` exists, and `cp -a` prior cell outputs forward so the in-box `collect` still emits a complete merged csv. `result.csv`-on-success is already the right sentinel (estimate.py writes none on failure) → **no estimate.py/template changes**.
- Edge cases handled in design: double-pull (impossible — single pull in finally), hung-rsync holding a pool slot (bound via SSH keepalive / `--timeout`), DO 45 s destroy delay (pull precedes destroy), coordinator death (re-dispatch + resume).

### P1 — Right hardware + concurrency + finer slow-shards
- **Put the LPT (slow) systems on dedicated cores**, not shared droplets: Hetzner **CCX** (dedicated, no jitter, ~2.4× faster than DO shared) or the local box. This alone turns the "3-day latent" into ~a day.
- **Concurrency ≈ #cores, threads = 1-2** for the serial hard cells (not the current threads=4). Tune `HEAVY_GB` down (latent used ~7 GB, not the assumed 10) → the heavy lane goes from conc 2 to conc ~4 on a 32 GB box. `run-benchmark.sh:25,61,65`.
- **Box size is a wash** for serial cells → choose ccx by *shard-vCPU / concurrency* need, not "16 cores = faster cell." (Refines the earlier "16× ccx43" answer to Hetzner: fine, but for concurrency headroom, not per-cell speed.)
- **Finer shards for the slow systems** — shard them `[system, arm, noise]` (8-cell shards) so a failure's blast radius is small and parallelism is higher; keep easy systems coarse `[system, arm]` to amortize the ~2.5 min provision + 8.65 GB image pull. `compute_shards` + `tiers.json shard_by`.

### P1 — Config hygiene
- **Pin `POLISH_MAXTIME` deliberately.** Decide 600 (faster) vs 3600 (reference/wallaby) **after** the still-pending recovery-vs-wallaby comparison shows whether 600 under-polishes the hard/noisy cells; for an IEEE-paper-faithful run, match the reference unless 600 is shown equivalent.
- Pin DATE (above), and record the exact config diff vs the reference run in the run manifest.

### P2 — AMIGO2 licensing robustness  *(local-only, MATLAB)*
- **Cap MATLAB concurrency ≤ 4-6** for `-licmode onlinelicensing` + **stagger** startups (the contention was a synchronized-checkout burst at 16).
- **Detect failures by missing `result.csv`, not `===END===`** (the latter is written on failure).
- **Auto-retry licensing errors** (5001/5006): a small wrapper around `estimate.py`'s matlab subprocess that re-tries with backoff before giving up — so a license blip doesn't silently drop a cell.

## Threading & HC solver safety (2026-06-04) — the "we need threading" dependency
P1 above wants concurrency on dedicated cores; this is the **solver-side blocker** we hit and provisionally fixed. **Status: DEV / uncommitted / fix NOT yet empirically confirmed.**

- **The deadlock (root cause).** At `JULIA_NUM_THREADS=8`, `latent_subpopulation` / `receptor` cells nondeterministically deadlock at ~0% CPU. `HomotopyContinuation.solve` defaults `threading = nthreads()>1` (HC `solve.jl:445`), so at threads>1 it multithreads its path tracker + polyhedral mixed-cell C/FLINT code; HC's own docstring warns *"Some CPUs hang when using multiple threads."* Leading hypothesis: a **GC-safepoint deadlock** (the C backend doesn't yield to safepoints → a stop-the-world GC on another thread waits forever). It's a **Heisenbug** — same HC 2.18.2 froze ~2/3 runs and ran fine otherwise (verified: no version change between freeze and non-freeze). **Honest caveat:** not cleanly reproducible on demand, and my homegrown A/B detector was flawed (couldn't tell the ~4-min startup-idle from deadlock-idle; its "threads=1 deadlocked" verdict was a false positive — the killed proc had a 0-byte log). The fix rests on two historical freezes + HC's warning + the mechanism, **not** a clean repro. Proper confirmation needs a *transition-based* detector (arm only after compute starts) + multiple trials.

- **The fix (implemented).** `src/core/homotopy_continuation.jl:13-15` routes all 10 `HomotopyContinuation.solve` calls through `_hc_solve`, passing `threading = HC_SOLVE_THREADING[]` (default `false`):
  ```julia
  const HC_SOLVE_THREADING = Ref(false)
  _hc_solve(args...; kwargs...) = HomotopyContinuation.solve(args...; threading = HC_SOLVE_THREADING[], kwargs...)
  ```
  HC solve goes single-threaded (no internal C-thread race); the polish keeps all threads. No-op at threads=1; default-safe; 2-line revert. **Refines lesson #3:** threads don't help the HC *solve*, but the *polish* IS thread-parallel — and the polish dominates wall time on the hard cells.

- **⚠ OPEN — Oren's concern (UNVERIFIED): does `threading=false` make HC much slower?** We expect the HC *solve phase* to slow (serial path tracking, up to ~Nx), but **the magnitude is unmeasured.** The polish stays parallel and dominates on the hard systems, so end-to-end impact may be modest — but that's a hypothesis, not data. **Must measure** (same cell, threads=8, solve-phase wall time, `true` vs `false`) before `threading=false` becomes a global default. If the slowdown is large on well-behaved systems: keep HC threading **on** except for the hang-prone ones (per-system policy via the `Ref`/an `EstimationOptions` field), or move solve parallelism to **process level**.

- **Concurrent `HC.solve` from our own threads (Oren's catch) — verified safe today.** `threading=false` only disables HC's *internal* threads; it would NOT help if two of *our* threads called `solve()` at once (HC/FLINT isn't reentrant). Verified they never do today: the only `@spawn` region (the polish, `parameter_estimation.jl:2740`) runs pure-Julia ODE/ForwardDiff and never calls HC.solve; all HC.solve calls are sequential on the main thread. But it's a latent landmine. **Panel (gpt-5.5 + gemini-3.1-pro + opus-4.7, 3-0): do NOT add a `ReentrantLock`** — it's GC-safe but would silently serialize a future accidental parallel loop into a phantom perf bug. Add a **non-blocking atomic fail-fast guard** instead (errors loudly on concurrent entry; **do not** use `threadid()==1` — Julia 1.7+ task migration → false positives):
  ```julia
  const _HC_IN_FLIGHT = Threads.Atomic{Int}(0)
  function _hc_solve(args...; kwargs...)
      prev = Threads.atomic_add!(_HC_IN_FLIGHT, 1)
      try
          prev == 0 || error("HC.solve invoked concurrently — HC/FLINT not reentrant.")
          HomotopyContinuation.solve(args...; threading = HC_SOLVE_THREADING[], kwargs...)
      finally
          Threads.atomic_sub!(_HC_IN_FLIGHT, 1)
      end
  end
  ```
  If concurrent HC ever becomes a feature: **process pool**, not in-process lock. Lock the contract with a CI test (2 spawned tasks → assert it errors).

- **Open actions:** (1) confirm the deadlock fix empirically (transition-based detector + multi-trial true-vs-false); (2) **measure the `threading=false` slowdown** (Oren's concern) → global default vs per-system; (3) add the atomic guard + doc + CI test, or hold; (4) bump **MTK ≥ 11.26.7** (fixes the `biohydrogenation` alias-elim GCD swell — independent, solid; applied to the local benchmark env 2026-06-04).

## The Hetzner transition
- 256 vCPU granted (we answered the support question; ccx43 requested, but size is a wash → pick for concurrency). `--provider hetzner` is already built and was validated (lotka 9.45e-12 on a ccx33). Dedicated cores remove the DO jitter and the ~2.4× penalty.
- Tier map: easy systems → many ccx33 (coarse shards, concurrency≈cores); slow/LPT systems (latent/crauste/bioh) → CCX, finer shards, P0 safety on; receptor → its own CCX pool, no timeout (now non-destructive thanks to P0). Reserve receptor's vCPU so it never gates the main run.

## Immediate application (resolves the pending slow-systems re-run)
The P0 fix + the "local is ~2.4× faster" finding reframe the open decision: **re-run latent/crauste/bioh on fast dedicated hardware (local now, CCX when live) with failure-safe collection** — so we never again lose a 12 h shard. latent + bioh are cheap (~1 h/cell); crauste is the one real cost (~2.5 h/cell). (We already have 6 good local latent polish cells + all 40 AMIGO2.)

## Verification
- **Resume smoke:** start a multi-cell shard, `kill` it mid-run, confirm completed cells are already in `dest`; re-dispatch and confirm only the missing cells run and the merged `result.csv` is complete.
- **Licensing:** run a 20-cell amigo2 batch at conc 4 → expect 0 fresh 5001/5006.
- **Cross-day:** force two pulls spanning a date change → confirm a single `benchmark_*` tree (DATE pinned).
- **Hetzner full run:** per-system besterror matches local quoll; zero shards lost to timeout; receptor completes off the critical path.

## Critical files (all in the PEB repo unless noted)
- `cloud/hetzner/fleet.py` — `run_shard` (168-216), `already_done`→`shard_progress`/`fully_done` (93-95), new `pull_results`/`wait_for_done_pulling` (near 148-165), env dispatch (193-196), `compute_shards` (62-86), `DONE_TIMEOUT_S` (42, already 7 d).
- `cloud/hetzner/run-on-box.sh` — env defaults (16-17), docker run (24-37): add `PRIOR`/`DATE`.
- `docker/run-benchmark.sh` — `run_lane` (125-135), heavy lane (25/61/65), DATE (19): add `--prior` filter + copy-forward + pinned `--date`.
- `cloud/hetzner/tiers.json` — finer `shard_by` + concurrency/threads/HEAVY for slow systems.
- AMIGO2: `src/estimate.py` `get_cmd` (26-32) + a retry wrapper; `config/config_quoll_broad.json` (POLISH_MAXTIME).
- Solver (ODEPE repo): `src/core/homotopy_continuation.jl:13-15` (`_hc_solve` / `HC_SOLVE_THREADING`).
