# Specimen #3: exit-path malloc-arena self-deadlock — CAPTURED with native backtrace

2026-07-24. The first hang specimen caught live with a full backtrace, and it
root-causes the "process fails to exit after a termination signal" class from
`PROVENANCE_PARKED_EVENT_2026-07-23.md` — for this specimen definitively, and
plausibly (same family, not proven) for the two 2026-07-22 post-SIGTERM
lingerers (8.6h / 1.4h).

## Identity & provenance

- PID 1686904 — an **ODEPE precompilation worker**:
  `julia -C native -J.../sys.so -g1 --startup-file=no --output-o
  .../compiled/v1.12/ODEParameterEstimation/jl_9hb9G3 --output-ji .../jl_8LjlOu
  --output-incremental=yes ... -` (script on stdin).
- Started **2026-07-22 16:09:02 EDT** — during the MWE-hunt window in which
  watchdogs were killing julia parents (`driver2/3.sh`, `timeout -k`). Parent
  died; worker reparented to `/init` (PPID 394107 = WSL init).
- Discovered 2026-07-24 ~16:45 EDT: **~46 h alive, 0% CPU**.
- Evidence discipline (per the provenance-audit standard): TWO snapshots 60 s
  apart — per-thread utime/stime **identical** (`8128/425`, `0/0`, `0/0`),
  all threads `S`; main thread wchan `futex_do_wait`. Formally flat, formally
  parked. gdb attach yama-blocked for same-uid; captured via `sudo gdb`.

## The backtrace (thread 1 = main; verbatim)

```
#0  futex_wait (private=0, expected=2, futex_word=0x77f056a03ac0 <main_arena>)
#1  __GI___lll_lock_wait_private (futex=0x77f056a03ac0 <main_arena>)
#2  0x000077f0568aeb70 in __libc_calloc (n=40, elem_size=1) at ./malloc/malloc.c:3725
#3  jl_getFunctionInfo_impl (...) at src/debuginfo.cpp:1266
#4  jl_print_native_codeloc (ip=...) at src/stackwalk.c:661
#5  jl_print_bt_entry_codeloc (...) at src/stackwalk.c:756
#6  jl_critical_error (sig=<optimized out>, si_code=0, context=0x0, ct=0x77f03cdfc010)
        at src/signal-handling.c:650
#7  jl_exit_thread0_cb () at src/signals-unix.c:563
```

Thread 2 (signal listener): idle in `sigwaitinfo` (signals-unix.c:975) — it had
already dispatched the exit request to thread 0. Thread 3: dead io_uring helper.

## Mechanism (textbook async-signal-safety violation)

1. Termination is delivered → Julia's signal path runs `jl_exit_thread0_cb` on
   thread 0 (signals-unix.c:563).
2. The exit path calls `jl_critical_error`, which prints a backtrace of the
   interrupted computation (the "death report").
3. Symbolicating a frame (`jl_getFunctionInfo_impl`, debuginfo.cpp:1266)
   **allocates** (`calloc`).
4. The interrupted thread-0 context was itself inside glibc malloc **holding
   the `main_arena` lock** (a precompile worker allocates near-continuously),
   so the handler's `calloc` waits on a lock its own interrupted frame holds.
5. Self-deadlock: `futex_wait(expected=2)` forever. No further signals except
   SIGKILL can help; CPU is exactly 0.

No race with other threads is required — this is a single-thread self-deadlock,
which is why it can strike any process that receives a termination signal at an
unlucky allocation instant. Probability scales with allocation density at
signal time (precompile / compile-heavy phases are worst).

## Relation to the other specimens

- Specimens #1/#2 (2026-07-22, `verify_fix_sumtest{,_dbg}.log`): SIGTERM →
  death report **completed** → process lingered 8.6h/1.4h in teardown. Same
  signal-driven exit path; they survived symbolication, so their block point is
  later in teardown and remains uncaptured. Same family: "Julia 1.12.6
  termination path performs unsafe/blocking work after the signal." Not proven
  identical.
- The supervisor lesson (independent of the Julia bug): **kill the whole
  process tree and verify it died** — the parent's death orphaned this worker,
  exactly the review's improvement #5.

## Filing notes (JuliaLang)

- Search first for existing reports of malloc-in-signal-path deadlocks
  (profiling/`jl_print_native_codeloc` family) before opening new.
- This report carries: exact frames with source lines (1.12.6), the
  glibc-arena mechanism, flat-CPU provenance, and a plausible reproduction
  recipe: SIGTERM a busy precompile worker repeatedly (allocation-dense →
  highest hit probability).
- ODEPE-side mitigations independent of upstream: supervisors use
  TERM → bounded grace → KILL **on the process group**; and note
  `jl_critical_error`'s report can be suppressed via... (check: signal exit
  verbosity env vars) — not pursued yet.

Process reaped with SIGKILL after capture (2026-07-24).
