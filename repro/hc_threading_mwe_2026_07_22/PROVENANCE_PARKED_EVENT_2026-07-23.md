# Provenance audit: the claimed "multi-hour, ~0%-CPU, all-threads-in-pthread_cond_wait" event

Audit date 2026-07-23. Requested scope: provenance only, for the event cited in
`ADJUDICATION_2026-07-23.md` §E6. Sources: this session's transcript
(`~/.claude/projects/.../9e466809-61df-4446-8b7c-1c215da052aa.jsonl`, which records
every command and tool output verbatim, cited below as `L<record>`), the logs now
archived under `logs/provenance_parked_event_20260722/`, and directory
inventories. Per instruction, the two June-2 latent runs are **excluded** as
evidence (their termination stacks show active HC path tracking / LLVM
compilation), and `repro/latent_hc_stall_2026_06_02/` is **not** described as an
existing MWE (verified below).

## Headline finding

**The claimed event does not survive its own provenance.** What the retained
artifacts actually show is: a run under `timeout 400` that received **SIGTERM**
after its 400s deadline, printed Julia's signal-handler death report, and then
remained alive for ~8.6 hours until `kill -9`. The archived file contains no regular application
output, but redirected Julia output was buffered and never flushed; that absence
does **not** locate the interrupted computation. The report's
`pthread_cond_wait` stacks belong to normally-idle parallel-GC and scheduler
helpers, while the remaining stack did not unwind far enough to identify Event
1's active phase. There was **no live `/proc/*/wchan` sampling, no gdb, no
repeated snapshots, and no per-thread CPU measurement — ever.** The phrase
"sampled via /proc/wchan" in ADJUDICATION §E6 was a misrecollection and is
retracted. The evidence neither establishes nor excludes that Event 1 reached an
HC solve; it establishes no mid-solve HC deadlock.

## 1. Exact invocation and environment

**Event 1 (the cited event).**

- Command (verbatim, transcript L701, issued 2026-07-22T03:37:32Z = 2026-07-21 23:37:32 EDT):

  ```bash
  cd ~/.julia/dev/ODEParameterEstimation
  timeout 400 julia --startup-file=no \
    <scratchpad>/diag_sumtest.jl > <scratchpad>/verify_fix_sumtest.log 2>&1
  ```

- Not a benchmark cell: it was the **sum_test M-fix e2e diagnostic**
  (`diag_sumtest.jl`, retained; runs `analyze_parameter_estimation_problem` on
  `sum_test()` with `use_si_template=true`, `InterpolatorAAAD`, no polish;
  the failing expression is `diag_sumtest.jl:13` per the death report).
- PIDs: julia **2084411**, `timeout` wrapper **2084410** (ps snapshot, L718).
- Julia **1.12.6** (juliaup path in the ps cmdline, L718).
- Threads: no `-t` flag or environment override appears in the command.
  `JULIA_NUM_THREADS=7` is the current ambient value and is **presumed**, not
  retained, for Event 1. The fatal report is not an exhaustive OS-thread
  inventory and cannot validate that inference.
- GC threads: not retained. The current environment reports `ngcthreads=7`; the
  fatal report contains 6 parallel-GC helper stacks, but those facts do not imply
  a one-to-one count of dedicated GC threads.
- BLAS threads: **not retained.**
- ODEPE code state: branch `uq-revamp-wip`, HEAD `205db15` **plus the uncommitted
  M-fix working tree** (the M-fix commits `52fbbdf`/`8e4ec20`/`21f6243`/`c54c938`
  landed 2026-07-22 10:39–10:59 EDT, i.e. *after* this run — reconstruction from
  `git log` timestamps, high confidence).
- HC 2.20.0 (`~/.julia/packages/HomotopyContinuation/98yZ2`, from the active manifest).
- HC threading setting: `HC_SOLVE_THREADING[] = true` by default in the code.
  Whether Event 1 reached an HC call is not recoverable (see §4).

**Event 2 (the "debug rerun" hang, same morning — included for completeness).**

- Command (L756, 2026-07-22T12:26:17Z): identical script with
  `JULIA_NUM_THREADS=1 timeout 400 ... > verify_fix_sumtest_dbg.log 2>&1`.
- PIDs: julia **194099**, timeout **194098**; ps at L772 shows `etime 01:25:15`,
  julia cumulative CPU `00:01:09`. Killed at L776, 13:59:38Z.

## 2. Contemporaneous artifacts (exhaustive)

Retained:

| Artifact | Path | Content |
|---|---|---|
| Event-1 stdout+stderr | `logs/provenance_parked_event_20260722/verify_fix_sumtest.log` (9,350 B, mtime 2026-07-21 23:44:26 EDT) | SIGTERM death report — `[2084411] signal 15: Terminated`, 14 thread stacks, `Allocations:` footer. No flushed application output. |
| Event-2 stdout+stderr | `logs/provenance_parked_event_20260722/verify_fix_sumtest_dbg.log` (4,603 B, mtime 08:33:35 EDT) | SIGTERM death report; the interrupted task is **actively inside LLVM JIT** (`SelectionDAG/FoldingSet → PassManager → SimpleCompiler → jl_compile_codeinst_now → jl_compile_method_internal`). No flushed application output. |
| Healthy control | `logs/provenance_parked_event_20260722/verify_fix_sumtest_t1.log` (73,810 B) | Same script, `JULIA_NUM_THREADS=1`, `timeout 500` (L728, 12:21:38Z): **completed at 12:23:37Z** (L738/L740) — full 19-row pool printout, `SELECTED best`, `pool-min ... at index 2`. |
| The exact script | `logs/provenance_parked_event_20260722/diag_sumtest.jl` (2,337 B) | Exact retained driver |
| Wrapper outputs | `logs/provenance_parked_event_20260722/{bcwlkv73o,bizs8sr6j,bkm4trn0j}.output` | Background-command results for Event 1, the healthy control, and Event 2 |
| Transcript excerpt | `logs/provenance_parked_event_20260722/TRANSCRIPT_EXCERPT.md` | Selected commands, timestamps, process checks, kills, and the complete transcript's archival hash |
| ps snapshot (Event 1) | transcript L712/L718 (12:18:54Z) | `2084411 ... TIME 1:00` — **one** snapshot, cumulative CPU |
| Kill record (Event 1) | transcript L723/L724 (12:19:55Z) | `kill -9 2084411 2084410` |
| ps snapshot (Event 2) | transcript L766/L772 (13:58:42Z) | `etime 01:25:15`, CPU `00:01:09` — one snapshot |
| Kill record (Event 2) | transcript L776 (13:59:38Z) | `kill -9 194099 194098` |

**Not retained** (explicitly): `/proc/PID/task/*/wchan` or `stat` samples (never
taken), gdb or `jlbacktrace` stacks (never taken), per-thread CPU times (never
taken), repeated snapshots of any kind (never taken), screenshots (none), serialized
polynomial systems (none — the run set `save_system=false`, and the
`latent_hc_stall` export hook was never applied to anything).

## 3. Did snapshots show application threads parked with work pending? — **No.**

- There was **one** ps snapshot per event, ~8.6 h (Event 1) / at least ~1h26m
  (Event 2) after the respective fatal-report file timestamps, showing cumulative
  CPU only (1:00 and 1:09). Per-thread CPU and CPU deltas were never measured;
  flatness was never established. Each sole late cumulative value gives only a
  low whole-process lifetime average.
- The `pthread_cond_wait` stacks in the Event-1 death report are:
  **6× `jl_parallel_gc_threadfun`** (parallel-GC workers — parked whenever GC is not
  running; their normal state) and **7× `ijl_task_get_next → poptask → wait →
  task_done_hook`** (scheduler workers with no runnable tasks; their normal idle
  state). The remaining stack is 2 unwalkable frames ending in `operator delete`;
  it did not unwind far enough to identify the active phase. Event 2 is different:
  its interrupted-task stack is captured inside LLVM/JIT.
- Therefore the retained evidence cannot show — and does not show — application
  threads abnormally parked while work was unfinished.

## 4. Phase and solve invocation — **not recoverable for Event 1**

`diag_sumtest.jl:13` is the single top-level
`analyze_parameter_estimation_problem` call, so the death reports establish only
that both processes had entered that call. They do not identify its nested phase.
Regular Julia logging redirected with `> log 2>&1` remains buffered while the
process is alive; this was acknowledged contemporaneously in transcript L727 and
confirmed by a direct control on 2026-07-23. Because both event processes were
forcibly killed, their missing regular output was never flushed. The empty
application portion of the logs therefore cannot place either event before SIAN
or HC.

Event 1's non-helper stack failed to unwind beyond `operator delete`; its active
phase at SIGTERM is unknown. Event 2 was actively compiling in LLVM/JIT at
SIGTERM. It was launched 18 seconds after a source edit, so cold invalidation/JIT
work is a direct confound. The claimed overlap with the healthy `_t1` control did
not occur: the control completed at 12:23:37Z (L738/L740), and Event 2 launched at
12:26:17Z (L756).

**The one solid, twice-retained anomaly is different from the original claim:** in
both events, Julia printed a SIGTERM death report and allocation footer, then the
process remained alive until manual `kill -9`. Event 1 survived for ~8h35m after
its report; Event 2 survived from at least the report's 12:33:35Z file timestamp
until 13:59:38Z, about 1h26m. The exact Event 2 SIGTERM time was not retained.
This is a post-SIGTERM **termination-path linger** observed on Julia 1.12.6. The
retained evidence does not identify its owner: Julia runtime teardown,
package/native finalization, and other termination-path causes remain
undistinguished. It also does not establish a pre-SIGTERM stall; Event 1 is
unknown, and Event 2 was active in LLVM when signalled. GNU `timeout` was not
given `--kill-after`, so its continued presence merely reflects that it was
waiting for the Julia child; it is not a second failure.

If the termination anomaly is pursued separately, use a minimal controlled
driver with explicitly flushed phase markers and
`timeout --signal=TERM --kill-after=15s`; do not treat another silent timeout as
an HC reproducer.

## 5. Raw evidence vs. recollection/inference — explicit corrections

- **Retained raw:** the three logs, script, and wrapper outputs archived in
  `logs/provenance_parked_event_20260722/`, plus the transcript ps/kill records,
  git timestamps, and directory inventories. `SHA256SUMS` records the archived
  files' hashes.
- **Inference (marked):** ambient `JULIA_NUM_THREADS=7` and `ngcthreads=7` then
  (both measured only in the current environment). The single cumulative CPU
  readings do not establish flatness during any interval.
- **Misrecollection, now retracted:** (a) "*sampled via /proc/wchan*" — no such
  sampling exists in the transcript; the wording entered my memory notes and
  ADJUDICATION §E6 from a compressed reading of the death-report stacks. (b) "*all
  threads park in pthread_cond_wait, ~0 CPU, hangs for HOURS*" as a description of
  a **mid-solve deadlock** — the captured waiters are normal idle helpers, the
  hours are post-SIGTERM, and no live stack or CPU series captured unfinished
  application work. (c) "*hung during full estimations / the HC solve path*" —
  unsupported: the exact runs were `diag_sumtest.jl` diagnostics, and Event 1's
  nested phase is unrecoverable.
- **Also corrected per this audit:** `repro/latent_hc_stall_2026_06_02/` contains
  `README.md`, `mwe_hc_solve.jl`, `run.sh` **only**; the README states "harness
  READY, run **DEFERRED**"; there are **no dumped systems and no results**. Prior
  references to it as "an existing MWE" are retracted — it is an un-run harness
  whose export hook was never applied.

## Net effect on ADJUDICATION §E6

Item (a) of "what survives as genuinely unexplained" is **withdrawn as stated**. The
correctly-characterized retained anomalies are now:

1. **Post-SIGTERM termination-path lingering** on Julia 1.12.6 (two retained
   instances, ~8.6 h and at least ~1h26m after their fatal reports). The owner is
   unknown; this is a separate, minimally testable problem if it matters
   operationally.
2. No pre-SIGTERM stall is established by these two events. Event 1's active
   phase is unknown; Event 2 was active in LLVM/JIT when signalled.
3. June cluster-era hang reports — **not audited here** (artifacts live in the
   cluster/rsync mirror); per the requester's own audit, the June-2 latent runs'
   termination stacks show *active* HC tracking/LLVM, i.e. compute, not parking.

No retained artifact, in this repo or this session, documents a mid-solve,
all-threads-parked deadlock.

## Later orphaned precompile observation (live at last host snapshot; not causal evidence)

**Correction, 2026-07-23 19:44 EDT:** the earlier statement that this process
"disappeared" was a PID-namespace inspection error. A host-namespace check
confirmed that the same PID, exact command/output paths, and thread IDs were
still present. Rendered wall-clock start times differ across the retained
snapshots and are not used as identity evidence. No signal was sent to it.

PID 1686904 is an ODEParameterEstimation precompile worker
(`--output-o` / `--output-ji`) started during the evening of 2026-07-22. At more
than 26 hours elapsed, host-level read-only snapshots showed:

- cumulative CPU unchanged at 1m25s and RSS 2,272,232 KiB (high-water
  2,525,452 KiB);
- exactly three threads;
- main thread in `futex_do_wait`, the io_uring helper in `io_sq_thread`, and the
  signal thread in `do_sigtimedwait`;
- the same CPU times and wait channels in snapshots 4m10s apart;
- orphan parent `/init` and precompile stdout/stderr still connected to pipes;
- no queued io_uring work and one eventfd with count 1.

ODEPE's then-current `@compile_workload` ran a small HC-backed estimation while
suppressing both output streams, so the command line and silence still do not
identify the nested phase or the owner of the wait. GDB attachment and
`/proc/PID/syscall` were blocked by host ptrace policy, so no user-space stack
was obtained.

This is a retained example of a package-precompile worker observed idle more
than 26 hours after process start. It is strong operational justification for
removing the hidden end-to-end workload and supervising future precompile
experiments. It does **not** by itself prove whether the underlying wait belongs
to Julia, HC, another dependency, or the old workload's teardown. It started
after both timeout events audited above and therefore cannot localize or explain
them.

**Correction to the 21:06 lifecycle conclusion, 2026-07-23 23:34 EDT:** the
claim that the process had exited is withdrawn. A host-namespace snapshot found
the same PID, exact compile-cache command, output paths, 1m25s cumulative CPU,
2,272,232 KiB RSS, and three-thread wait pattern still present after more than
29 hours. The negative 21:06 check was made from a process namespace in which
the host PID was not visible; it was not a lifecycle event. At that final
23:34 host snapshot, the process was orphaned to `/init`, had no pending signal,
and had not been touched by this investigation. The corrected raw record is in
`investigation/orphaned_precompile_final_observation.txt`.

**Later host observation, 2026-07-24 07:23 EDT:** PID 1686904 was still
present with the exact compile-cache command, 1m25s cumulative CPU,
2,272,232 KiB RSS, and the same three wait channels. One GDB attachment
attempt was rejected by Yama/ptrace policy before attachment; it obtained no
stack and sent no signal. A host process/thread snapshot immediately afterward
showed the worker unaffected. The exact command and error are retained in
`investigation/orphaned_precompile_gdb_attempt_2026-07-24.txt`.
