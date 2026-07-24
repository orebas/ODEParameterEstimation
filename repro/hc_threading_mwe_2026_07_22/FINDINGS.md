# HC.jl "threading deadlock" — root-caused (2026-07-22)

> **STATUS (2026-07-23): partially retracted after independent adversarial review +
> re-testing — see [`ADJUDICATION_2026-07-23.md`](ADJUDICATION_2026-07-23.md).**
> Finding #2 (unlocked cache Dicts) stands and was independently reproduced. Finding #1
> (mixed-cells wallpaper) stands. Finding #3 and the causal chain are retracted:
> the production solve path compiles **per-support, not per-solve** (verified:
> `TSYSTEM_TABLE` does not grow across coefficient-varying solves; 34.6s cold → 0.06s
> warm), solver construction precedes tracker spawn, `jl_as_global_root` writes are
> locked in 1.12.6, the hang/segfault campaign below was confounded (work scaled with
> thread count; loaded box; watchdog thresholds ≈ healthy durations; the retained
> "hang" dump shows ticks advancing to completion), and the only retained segfault came
> from the Dict-corrupting stress arm. The original multi-hour ~0%-CPU production hang
> remains **unexplained**.

Goal: a minimal, ODEPE-free reproducer for the intermittent multi-thread
`HomotopyContinuation.solve` freeze on Julia 1.12 (HC issues #594 / #668 / #702;
the historical last-painted line "Computing mixed cells").

Environment: Julia 1.12.6 (also tested 1.11.5), HomotopyContinuation 2.20.0
(`~/.julia/packages/HomotopyContinuation/98yZ2`), MixedSubdivisions 1.2.0 (`Er7IW`),
ProgressMeter 1.11.0, SymEngine_jll (WITH_SYMENGINE_THREAD_SAFE **on**, checked both
artifacts' `symengine_config.h`), 14-core AMD Ryzen, Linux WSL2. Box was heavily
oversubscribed during the hunt (load 20-60) — deliberately, to widen race windows.

## Executive summary — three concrete, evidenced findings

1. **The primary hypothesis is REFUTED: MixedSubdivisions.jl contains no threading at
   all** (no `threadid`/`@spawn`/locks anywhere in v1.1.5 or v1.2.0). "Computing mixed
   cells..." is wallpaper: MS's `fine_mixed_cells` defaults `show_progress=true` and HC
   calls it with **no kwargs** (`polyhedral.jl:22`), so that meter runs during *every*
   fresh polyhedral solve even under `solve(...; show_progress=false)` — any freeze
   during/after a fresh solve leaves that line last on screen.

2. **HC 2.20.0 bug (proven at runtime): the global compiled-system caches are plain
   `Dict`s mutated with NO lock.**
   `src/model_kit/compiled_system_homotopy.jl:1` `TSYSTEM_TABLE::Dict{UInt,Vector{System}}`
   and `:86` `THOMOTOPY_TABLE` are written by every `CompiledSystem` / `CompiledHomotopy`
   construction (`haskey/push!/setindex!`, lines 41-56 / 128-142) and read by `interpret`
   (lines 67, 159) — i.e. touched by every `solve` that compiles (always, under
   `compile = :all`, which ODEPE sets). Base.Dict is not thread-safe. Measured with
   `mwe_tsystem_race.jl` / `tsys_stress.jl` (constructions are all distinct, so entries
   must equal constructions — single-worker control is exact):
   - 1 worker, 24,000 constructions → **24,000/24,000 entries, 0 collisions** (exact).
   - 6 workers × 4,000 (-t 8)     → **23,990/24,000 (10 LOST), 25 spurious bucket merges**.
   - 6 workers × 30,000 (-t 8)    → **178,937/180,000 (1,063 LOST ≈ 0.6%)**.
   - 12 workers × 60,000 (-t 14)  → **SIGSEGV within ~20 s** (`logs/ts14_r1.log`).
   Lost entries are delayed bombs: that `CompiledSystem{(h,k)}`'s `interpret` later hits
   `KeyError` or a wrong system. The tables also grow unboundedly (every distinct-
   coefficient system inserts forever → leak in long-lived processes).

3. **Julia 1.12.6 runtime bug (proven WITHOUT HC): concurrent `apply_type` with fresh
   bits-tuple parameters segfaults/hangs.** The HC crash backtrace is
   `jl_egal_/idset_eq/jl_smallintset_lookup/jl_idset_get ← jl_as_global_root ←
   inst_datatype_inner ← ijl_apply_type ← CompiledSystem` (compiled_system_homotopy.jl:57
   — `CompiledSystem{(h,k)}` mints a **fresh parametric type per compiled system**).
   `typeinst_control.jl` (30 lines, **stdlib only**) does just `Foo{(rand(UInt), k)}`
   from N tasks and **segfaulted on Julia 1.12.6 at -t 14** with the same
   global-roots/idset path; a second identical run survived >500 s (nondeterministic;
   see `logs/typeinst_campaign.txt` for the outcome table). This matches open upstream
   issue **JuliaLang/julia#58171** (`ijl_apply_type → inst_datatype_inner →
   jl_as_global_root → jl_idset_put_idx / smallintset_rehash`, reported on 1.11,
   *speculated* fixed by PR #57392 in 1.12 — our 1.12.6 repro shows it is not fully fixed).

**How this produces the observed "deadlock":** corrupted idset/Dict probing loops
allocate nothing, so the spinning thread never reaches a GC safepoint; the next
stop-the-world freezes every other thread permanently. The frozen screen shows whatever
meter painted last — "Computing mixed cells...". Signal handlers still respond (our
frozen processes answered SIGUSR1), matching field reports where Ctrl-C is swallowed.

## Additional captured failure mode: whole-process compilation convoys (not a deadlock)

Two watchdog captures (`hangs/fo14off_r7_*`, `hangs/fo14on_r2_*`): 8 concurrent
first-solves (fanout arms) froze **all output for 420-432+ s**. gdb shows 5-6 threads
spinning on **`jl_typeinf_lock`**, several parked in **`jl_unique_gcsafe_lock::wait`**
(the 1.12 codegen engine), one thread inside LLVM (`emit_function` /
`BasicBlock::renumberInstructions`) — i.e. every worker serialized behind Julia's global
inference/codegen locks (R-state spinners, so CPU burns while nothing progresses).
With `compile = :all` and per-solve fresh symbols (ODEPE's `convert_to_hc_format`
pattern), *every* solve is a first solve. Under load this produces multi-minute
whole-log freezes that operators (and watchdogs) read as deadlocks. This is
starvation/convoy, not a lock cycle — but it is the most probable explanation for a
large share of "hangs" in fleet logs, and it also maximizes exposure to finding #3
(inference/codegen hammer the type-instantiation path concurrently).

## Runtime hunt volume (all pure-HC, external watchdog + hard timeout per process)

| arm      | -t | mode      | HC threading | shape             | solve() calls | result |
|----------|----|-----------|--------------|-------------------|--------------|--------|
| g14/g28  | 14/28 | seq    | on           | dense mix 6-11 vars | 640+ / 680+ (running) | clean |
| chr14on  | 14 | seq       | on           | 4x2 churn (16 paths) | 12,000     | clean |
| capd14on | 14 | seq       | on           | **captured ODEPE daisy_mamil4 32x32 jet systems** | 1,200 | clean |
| fo14off  | 14 | fanout×8  | off          | mix               | 288+         | 1 convoy freeze captured |
| fo14on   | 14 | fanout×8  | on           | mix               | 48+          | 1 convoy freeze captured |
| sq8off   | 8  | seq       | off          | mix               | 80+          | clean |
| pt14on   | 14 | fanout×8  | on           | parameter-homotopy γ-tracking | ~2,080+ (running) | clean |
| pt8off   | 8  | seq       | off          | parameter-homotopy γ-tracking | ~1,250+ (running) | clean |
| long14on | 14 | seq       | on           | 13x2 (8,192 paths) | 12+ (running) | clean |
| ctl1off  | 1  | seq       | off          | mix               | 20           | clean (control) |
| ctl2on   | 2  | seq       | on           | mix               | 20           | clean (maintainer's config) |
| ts14     | 14 | fanout×12 | —            | CompiledSystem stress | ~700,000 constructions | **SIGSEGV round 1** |

≈18,600 `solve()` calls total: **no permanent deadlock was caught in single-task
(production-shaped) arms**; both freezes required concurrent solves. Caveats for the
negative: production hangs were on early-June Julia 1.12.x (likely 1.12.4/5; version not
recoverable from logs) vs 1.12.6 here, and the June "receptor hang" is now known to have
been legitimate 10.5 h single-threaded tracking of 63,577 paths (CPU 100%), not a hang —
some historical "deadlocks" were compute or convoys.

Also noted in passing:
- HC `solve.jl:639` `started` atomic is never incremented → after an interrupt,
  `1:started[]` collects 0 results (cosmetic bug).
- ProgressMeter 1.11.0 `is_threading` (`ProgressMeter.jl:452-462`) decides locking by
  comparing `Threads.threadid()` to the creator's id — unsafe under task migration
  (unsynchronized counter/IO writes; corruption, not deadlock).

## Files (this directory)

- `mwe_tsystem_race.jl` — **the maintainer-facing MWE** for finding #2 (30 s run,
  deterministic counting: lost entries / spurious collisions / KeyErrors).
- `typeinst_control.jl` — **the JuliaLang-facing MWE** for finding #3 (stdlib-only).
- `tsys_stress.jl` — driver-compatible heavy version of #2 (produced the segfault).
- `attempt.jl` (fresh solves; seq/fanout × HC-threading on/off × shapes incl.
  `capdir:` captured systems), `ptrack.jl` (γ-straight parameter tracking),
  `scheduler_control.jl` (HC-free scheduler/GC churn), `hunt.jl` (earlier variant).
- `driver2.sh` / `driver3.sh` — watchdogs: mtime-stall detection → gdb all-thread bt,
  /proc states, SIGUSR1 Julia task dump, then kill; hard `timeout` belt-and-suspenders.
  (Known wart: the round-accounting `grep -c || echo` can end a drive early after a
  hang/crash capture — captures themselves are always preserved.)
- `capture_run.jl` — ran ODEPE daisy_mamil4 with a temp hook (since **reverted**;
  `src/` and `test/` are clean) to export production fresh systems →
  `captured_systems/daisy4_*.jl` (60 pure-HC 32x32 systems) + tiny `sum_test_*`.
- `hangs/<label>_<round>_<ts>/` — HANG.txt, run.log, gdb_bt.txt, proc_status/tasks,
  run_after_usr1.log for each capture.
- `logs/` — per-round logs, per-arm summaries, `typeinst_campaign.txt`,
  `tsys_campaign.txt` (outcome tables; appended as campaigns finish).

## Recommendations

1. **File with HomotopyContinuation.jl** (fixes #594/#668/#702 class):
   put a lock around `TSYSTEM_TABLE` / `THOMOTOPY_TABLE` (or key the cache per-task /
   use `Base.@lock` + `ReentrantLock`), and reconsider minting a fresh
   `CompiledSystem{(h,k)}` datatype per system (it both leaks and drives the Julia
   runtime's concurrent-apply_type path). Attach `mwe_tsystem_race.jl` + the ts14
   segfault log.
2. **File with JuliaLang** (or comment on #58171): `typeinst_control.jl` +
   the two crash logs — concurrent `apply_type` with fresh tuple params
   segfaults 1.12.6; #57392 did not fully fix the global-roots idset race.
3. **ODEPE / fleet mitigations** until upstream fixes: prefer
   `compile = :none` (InterpretedSystem) or reuse one parameterized system per
   estimation instead of per-solve fresh symbol sets (kills both the convoy and the
   table/typeinst traffic); keep `JULIA_NUM_THREADS=1` for solver processes, or at
   minimum never issue HC solves from concurrent tasks in-process.

## References

- HC #594 hang backtrace in partr (`multiq_deletemin`/`trypoptask`):
  https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/594
- HC #668 threadid()-indexing (fixed by PR #669 rework; absent in 2.20 solve path):
  https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/668
- HC #702 nondeterministic hang, AMD Ryzen + WSL (this environment):
  https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/702
- JuliaLang/julia#58171 (same idset/global-roots crash path, 1.11) — our
  `typeinst_control.jl` reproduces on 1.12.6:
  https://github.com/JuliaLang/julia/issues/58171
- Julia PSA "don't use threadid()": https://julialang.org/blog/2023/07/PSA-dont-use-threadid/

---

# ADDENDUM — final campaign numbers (evening 2026-07-22)

## A. `typeinst_control.jl` outcome table (150k fresh-tuple `apply_type` per worker; stdlib-only)

| julia   | -t | run1 | run2 | run3 |
|---------|----|------|------|------|
| 1.12.6  | 14 | HANG | HANG | **SEGFAULT** |
| 1.12.6  | 8  | HANG | OK   | HANG |
| 1.12.6  | 4  | OK ×6 (two blocks) | | |
| 1.12.6  | 2  | OK   | OK   | (cut) |
| 1.11.5  | 14 | HANG | HANG | HANG |

(HANG = a ~seconds workload still not finished at the 180 s kill; box load ~10-50 during runs.)
Thread-count gradient is monotone: never fails ≤4 threads, fails most runs at 8, and
essentially always at 14 — exactly why HC's maintainer (2 threads) cannot reproduce
what fleet boxes (8-32 threads) hit. **1.11.5 hangs too** → this is a long-standing
Julia runtime problem (consistent with JuliaLang/julia#58171 being filed on 1.11), not
a 1.12 regression; on 1.12.6 it can also segfault.
One hang was caught live with all task states sampled: **11 threads R (spinning),
1 D, 24 S** — active spin, no progress, for a workload that takes seconds when healthy.
(gdb note: that particular process hung before reaching the script's prctl(PR_SET_PTRACER)
line, so yama blocked attach — the hang can strike during script startup compilation.)

## B. `tsys_stress.jl` (HC CompiledSystem, 12 workers × 60,000, -t 14) outcome table

| run | outcome |
|-----|---------|
| 1 | complete; 718,239/720,000 entries (**1,761 lost**) |
| 2 | complete; 717,437/720,000 (**2,563 lost**) |
| 3 | complete; 717,804/720,000 (**2,196 lost**) |
| 4 | complete; 699,567/720,000 (**20,433 lost ≈ 2.8%**) |
| 5 | **HANG** (frozen at W3 iter 44,000; killed at 300 s) |
| (earlier drive round) | **SEGFAULT** (`logs/ts14_r1.log`, apply_type/global-roots path) |

So the HC-level stress reproduces all three terminal manifestations: silent corruption
(always), hang, and segfault.

## C. The production-shaped arm DID freeze once load conditions were right

The earlier-variant seq drives (hunt.jl: **sequential** `solve(F; threading=true)`,
one solve at a time — exactly ODEPE's call shape) caught two freezes at -t 14
(`hangs/g14_t14_r18_*`, `g14_t14_r19_*`; r19 frozen ≥184 s **mid-"Computing mixed
cells" meter paint on the first solve**, the verbatim production symptom). gdb for r19:
**12 threads waiting on `jl_typeinf_lock`, 3 in `jl_unique_gcsafe_lock::wait`
(including the main thread), 1 thread inside LLVM `slpvectorizer::BoUpSLP::getSpillCost`.**

Mechanism: with `threading=true`, each solve spawns nthreads tracker tasks; because
every solve mints a **fresh `CompiledSystem{(h,k)}` type**, all tracker methods must be
re-inferred/re-compiled **every solve**, so all 14 tasks pile onto the global inference
lock and the codegen engine while LLVM compiles one function at a time. For large
systems the generated straight-line function is huge and LLVM's SLP vectorizer is
superlinear — single compiles can take minutes-to-pathological. This convoys the whole
process (mixed-cells meter freezes mid-line) even though it is "only" compilation, and
it maximizes concurrent traffic into the racy apply_type/global-roots path (finding #3)
and the unlocked tables (finding #2), which is what converts a convoy into a permanent
hang or a segfault.

## D. Bottom line for the two upstream reports

1. **HomotopyContinuation.jl**: `TSYSTEM_TABLE`/`THOMOTOPY_TABLE` need a lock
   (5-line fix), and the per-system fresh type parameter `(h,k)` defeats compilation
   caching (every solve recompiles trackers under `jl_typeinf_lock`) and hammers the
   racy runtime path. MWE: `mwe_tsystem_race.jl` (corruption counts in 30 s) +
   `tsys_stress.jl` outcome table + the two fanout convoy captures.
2. **JuliaLang** (comment on #58171): `typeinst_control.jl` — 30 lines, stdlib-only,
   hangs/segfaults 1.11.5 and 1.12.6 at ≥8 threads on this box; gradient table above;
   crash backtrace `ijl_apply_type → inst_datatype_inner → jl_as_global_root →
   jl_smallintset_lookup/idset_eq` (`logs/ts14_r1.log`, and the typeinst campaign logs).
