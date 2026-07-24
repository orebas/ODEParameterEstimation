# ODEPE / HomotopyContinuation hardening handoff

Created: 2026-07-23; last updated: 2026-07-24 07:23 EDT
(America/New_York)

## Bottom line

The investigated `-t 14` campaign did not reproduce a deadlock: its 180-second
watchdog was shorter than the healthy approximately 260-second workload. There
is no retained evidence of a Julia `apply_type`/id-set race or an HC mid-solve
all-threads-parked deadlock.

There are nevertheless real, independently testable bugs and worthwhile
hardening changes:

| Area | Finding | Status |
| --- | --- | --- |
| HC compiled `ModelKit` caches | Process-global `Dict` reads/writes were not synchronized. Lost updates dynamically establish the `CompiledSystem` cache race; the analogous `CompiledHomotopy` fix follows from the same source design but has no separate retained corruption campaign. Neither is established as the historical hang's cause. | One-commit issue/PR kit, 14/14 focused tests pass |
| HC threaded early stop | An early stop could return before collecting already completed assigned results. | One-commit issue/PR kit, focused 2/2 and `solve_test.jl` 74/74 pass |
| HC polyhedral progress | `show_progress=false` was not forwarded to polyhedral setup. | One-commit issue/PR kit, focused 4/4 and `solve_test.jl` 76/76 pass |
| ODEPE precompile | Package precompilation silently ran a full end-to-end estimation, suppressing output/logging and swallowing errors. This is an operational design bug and a plausible explanation for silent startup work, not a proven explanation of Event 1. | Removed; a source-policy regression prevents reintroduction through high-level entrypoints |
| ODEPE HC configuration | Process-global HC defaults and mutable package-global state created cross-call coupling and potential interference. No retained ODEPE cross-call failure was reproduced. | Preventive hardening: explicit per-call `hc_compile` / `hc_threading`; ODEPE's outer HC entries are serialized while HC's internal threading remains enabled |
| ODEPE observability | Long phases could be silent and output-silence/mtime-only watchdogs mislabeled slow work as hangs. | Task-scoped progress stream, bootstrap/import markers, heartbeats distinguished from algorithmic transitions, and a process-tree watchdog |
| ODEPE test oracle | The SEIR retry assertion expected a partial result at `t=0`, but two seeded runs of source commit `52fbbdf` under the then-current global dependency environment resolved every state at both `t=0` and the shooting point. | Pre-existing stale oracle replaced by a deterministic unit regression for `_shooting_resolve_improves`; the full automatic retry is not exercised end to end |
| Julia/Pkg precompile lifecycle | At the last host-namespace snapshot (2026-07-24 07:23 EDT), a Julia ODEPE compiler worker was idle with three threads, about 2.17 GiB RSS, and only 1m25s cumulative CPU after more than a day. | Real retained anomaly; not minimized or assigned to Julia, Pkg, HC, ODEPE, or dependency teardown |

The original multi-hour production symptom remains open. The new diagnostics
are intended to make the next occurrence classifiable without calling ordinary
slow compilation or HC work a deadlock.

## ODEPE implementation

All ODEPE changes are isolated from the user's dirty checkout:

- branch: `codex/odepe-hardening`
- worktree: `/tmp/odepe-hardening-20260723`
- base: `52fbbdfa462a4fd259cf3a664b6eccf4e7afb6ea`
- head: `776abac47221a6fe1a9bb6906dd6f0ae6b0077f6`

Commit sequence:

1. `8f02d10` — remove the hidden estimation precompile workload
2. `8386043` — scope HC solve configuration per invocation
3. `29670c0` — add task-scoped estimation progress events
4. `533845d` — add the diagnostic ODEPE script entrypoint
5. `3aece9f` — initial Linux watchdog
6. `a24836f` — tighten diagnostic and HC integration contracts
7. `87eb659` — make the algebraic-retry regression deterministic
8. `6c5d26c` — test real entrypoint imports and fix Julia 1.12 world age
9. `e7c915c` — reuse an active progress sink in nested estimation calls
10. `0d48f0c` — guard future precompile workloads from estimation entrypoints
11. `776abac` — replace the initial watchdog with the contract-correct
    Python/Linux process-tree collector

Notable contracts:

- `_hc_solve` is the sole direct `HomotopyContinuation.solve` call.
- `hc_compile=:all` and `hc_threading=true` are explicit defaults and propagate
  through every ODEPE path; no call mutates HC's process-global default.
- ODEPE serializes concurrent outer HC solve entry, avoiding cross-call cache
  construction overlap. The `threading` keyword still controls HC's own
  internal path tracking.
- Progress is task-scoped through `ScopedValues`, fail-open, and warn-once.
  Nested estimation calls reuse the outer sink, so sequence numbers remain
  monotonic and only one TSV header is emitted.
- Heartbeats prove scheduler activity but never reset the algorithmic
  no-transition clock.
- The entrypoint emits a bootstrap marker before importing ODEPE. Calls into a
  freshly loaded package use `Base.invokelatest`, which avoids the Julia 1.12
  world-age failure found by the real subprocess test.
- The watchdog always enforces the wall deadline, samples the whole descendant
  tree, treats low CPU plus algorithmic quiet only as suspected no-progress,
  defaults that suspicion to capture-only, and performs TERM → grace → KILL
  cleanup. It has distinct exit codes for wall, opt-in stall termination, RSS,
  usage, and internal failure.

Example supervised run:

```bash
python3 tools/diagnostics/odepe_watchdog.py \
  --output capture-001 \
  --wall-seconds 7200 \
  --stall-seconds 1800 \
  --sample-seconds 10 \
  --low-cpu-samples 3 \
  --cpu-threshold-percent 1 \
  -- \
  julia --startup-file=no tools/diagnostics/odepe_entrypoint.jl script.jl
```

## HC issue / PR kits

Every HC change is based directly on upstream
`cd74c49474959e0b2661f81587affba29a42c5ed`, is exactly one commit, and can be
submitted independently:

| Kit | Branch | Head |
| --- | --- | --- |
| Compiled cache thread safety | `fix/compiled-cache-thread-safety` | `4b542974fe0984d78e34530a0f8687fc3838362b` |
| Threaded early-stop results | `fix/threaded-early-stop-results` | `673ff92d21ac9c2f49a68b21b2a40817bcce8b10` |
| Polyhedral progress flag | `fix/polyhedral-progress-flag` | `c6279ce8b5d76e5ce957e82508842851e5b44074` |

Each kit contains `ISSUE.md`, `PR.md`, `SUBMISSION.md`, a `git format-patch`
patch, and a focused log. Patch hashes and independent audit results are in
`upstream_submission/SHA256SUMS`, `VERIFICATION.md`, and
`INDEPENDENT_AUDIT.md`. The three issue / pull-request pairs are:

- cache thread safety: [issue #717](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/717),
  [PR #720](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/pull/720)
- threaded early-stop results: [issue #718](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/718),
  [PR #721](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/pull/721)
- polyhedral progress flag: [issue #719](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/719),
  [PR #722](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/pull/722)

## Verification

Completed focused ODEPE checks:

- precompile policy: 3/3
- HC configuration and serialization: 35/35
- live progress: 38/38
- nested progress: 8/8
- progress failure handling: 16/16
- HC lock events: 5/5
- real diagnostic entrypoint: 18/18
- watchdog contract: 60/60, four consecutive runs (240 assertions)
- earlier package gates: `fast_unit.jl` 125/125,
  `feature_regressions.jl` 201/201, column scaling 12/12

Final combined suite: **1,215/1,215 pass in 21m24.8s** on Julia 1.12.6.
The retained log is
`investigation/full_suite_hardening_canonical_2026-07-23.log`.

An earlier over-isolated run passed 1,205 tests and errored in two fixture
testsets because its `JULIA_LOAD_PATH` omitted the global environment containing
the suite's undeclared `CSV` dependency. A probe verified that the corrected
load path selected both `CSV` 0.10.16 and the integration worktree, after which
the complete suite passed. The environmental run is retained as
`investigation/full_suite_hardening_2026-07-23.log`; it is not counted as a
product failure.

The independently reviewed SIGTERM ladder also completed:

- complete/provenance-verified matrix: 9/9
- Base main-task `Event` wait: 3/3 TERM exits in 0.100–0.150s
- HC after a two-root solve, then main-task `Event` wait: 3/3 in 0.351–0.401s
- hardened ODEPE import, then main-task `Event` wait: 3/3 in 0.501–0.551s
- SIGKILLs: 0; cleanup failures: 0; surviving ladder processes: 0
- runner contract tests: 9/9

This rules out a general shutdown failure in those initialized idle controls.
It does not exercise termination during active JIT, GC, finalizers, estimation,
or the historical process state.

A full benchmark campaign was intentionally not run. The original campaign's
relevant healthy duration had already been measured, and the requested work
was implementation plus bounded verification.

## Precompile hypothesis: evidence boundary

The static mechanism is confirmed: the baseline source executes
`analyze_parameter_estimation_problem` inside `@compile_workload` while
suppressing stdout, stderr, logging, and exceptions. Editing `src/` invalidates
the package cache, so Claude's explanation is a plausible fit for a silent,
CPU-active startup interval.

The attempted dynamic A/B is not causal evidence. The usable baseline arm
crossed a 4 GiB aggregate process-tree guard while dependency compilers were
active. The “after” attempts had unmatched manifests/caches, and the last arm
used the final stacked hardening source even though the reference manifest
lacked its new `ScopedValues` dependency. It was stopped once this validity
error was found. The retained audit gives capture-by-capture classifications:
`investigation/precompile_ab/README.md`.

A defensible timing A/B would compare the base with a tree differing only by
deletion of the workload body, keep `PrecompileTools` and an identical manifest,
use independent clean depots, run a counterbalanced order, set the guard above
the 4,703.35 MiB highest sampled aggregate process-tree RSS from the mismatched
after run, and allow at least 30 minutes per arm. Aggregate RSS can double-count
shared pages, and that cap-triggering sample was neither a unique-memory nor a
dependency-only peak. Such a replay is a separate resource-intensive
experiment. It could measure direct compilecache cost; it still could not prove
Event 1's historical cause.

## Runtime anomaly and filing threshold

At the last host-namespace snapshot (2026-07-24 07:23 EDT), PID 1686904 was an
ODEPE compile-cache worker orphaned to `/init`, whose main thread was in
`futex_do_wait`; its other threads were an io_uring helper and Julia signal
thread. It had no pending signal. Earlier reports that it had exited were
caused by inspecting a different PID namespace.

A host-level GDB attachment was attempted once after the final test matrix.
Yama/ptrace policy rejected it before attachment, so no user-space stack was
obtained and the target was not stopped or signalled. A subsequent host
snapshot showed the same identity, resources, and wait pattern.

The hidden end-to-end precompile workload independently justifies its removal;
this retained orphan reinforces the operational case for process-tree cleanup
but does not establish a cleanup defect. It is not yet enough for a
high-quality Julia issue because there is no minimal reproducer, user-space
stack, owner of the futex, or demonstrated signal/exit contract violation for
this particular worker. The process was left alive; no diagnostic in this
investigation signalled it.

## Deferred work

- File the three HC issues/PRs independently after owner review.
- Revisit HC cache lifetime/eviction separately from the locking fix.
- Decide and document the callback concurrency contract separately from the
  early-stop result-preservation fix.
- Consider replacing package-global diagnostic registries with task-local or
  explicit run objects.
- Pursue the existing variable/column-scaling investigation; HC already applies
  row scaling, while ODEPE's ill-conditioned systems can still have Jacobian
  condition numbers around `1e6`–`1e10`.
- If a production stall recurs, run it under the new entrypoint/watchdog with
  an hours-scale wall and require both algorithmic quiet and repeated low CPU
  before termination.
- File a Julia/Pkg issue only after a minimized precompile/termination
  reproducer or a captured stack establishes the owning subsystem.

## Workspace safety

The original `uq-revamp-wip` checkout's three pre-existing dirty tracked files
were not altered by the implementation; ODEPE code changes live in the separate
clean worktree. This repro directory intentionally contains the new and updated
evidence, submission kits, and handoff. The three HC branches and their issue /
pull-request pairs listed above are public; no other upstream work was
published.
