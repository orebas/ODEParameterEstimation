# Julia SIGTERM termination ladder

This is a small control experiment for the retained post-SIGTERM termination
anomaly described in `../../PROVENANCE_PARKED_EVENT_2026-07-23.md`. It does not
run an ODEPE estimation or benchmark.

The three tiers are:

1. `base_idle.jl`: Base Julia's main task reaches an `Event` wait.
2. `hc_idle.jl`: load HomotopyContinuation, complete the two-root system
   `x^2 - 1`, then put its main task in an `Event` wait.
3. `odepe_idle.jl`: import ODEParameterEstimation, then put its main task in an
   `Event` wait. It does not call `analyze_parameter_estimation_problem` or any
   solver.

“Event wait” is intentionally narrow: the marker proves where the main Julia
task is. It does not claim that every Julia helper thread is idle.

The Python runner launches each Julia command in a private process group. It
waits for the flushed, case-specific `READY` marker, sends `SIGTERM`, allows
exactly 15 seconds for the group to disappear, and sends `SIGKILL` only if
needed. Startup is separately bounded. One JSON record is flushed after every
run.

A `term_exit` result requires all four facts: `READY` was observed, the
`killpg(SIGTERM)` call succeeded, the private process group disappeared, and no
`SIGKILL` was sent. The runner separately classifies an exit between `READY` and
the TERM attempt, or a failed TERM delivery. It records the TERM-grace elapsed
time separately from any post-KILL cleanup time, with timestamps taken
immediately before each `killpg` call.

## Invocation

From this directory:

```bash
env \
  JULIA_LOAD_PATH=/tmp/odepe-hardening-20260723:@stdlib \
  JULIA_DEPOT_PATH=/tmp/odepe-hardening-depot-20260723:/home/orebas/.julia \
  python3 run_ladder.py \
    --output results-final \
    --repetitions 3 \
    --expected-odepe-root /tmp/odepe-hardening-20260723 \
    --ready-timeout-seconds 180 \
    --term-grace-seconds 15 \
    --kill-wait-seconds 5
```

Every Julia command is plain global Julia, per repository policy:

```text
julia --startup-file=no /absolute/path/to/CASE_idle.jl
```

The runner inherits `JULIA_NUM_THREADS` and `JULIA_NUM_GC_THREADS` and records
their values rather than silently overriding them.

The isolated ODEPE arm is invoked without `--project`, but with an explicit
integration source environment and depot:

```bash
env \
  JULIA_LOAD_PATH=/tmp/odepe-hardening-20260723:@stdlib \
  JULIA_DEPOT_PATH=/tmp/odepe-hardening-depot-20260723:/home/orebas/.julia \
  python3 run_ladder.py \
    --output results-odepe-integration \
    --case odepe_idle \
    --repetitions 3 \
    --expected-odepe-root /tmp/odepe-hardening-20260723 \
    --ready-timeout-seconds 180 \
    --term-grace-seconds 15 \
    --kill-wait-seconds 5
```

For a selective continuation, repeat `--case` and optionally set the first
repetition label:

```bash
python3 run_ladder.py \
  --output results-controls-rep3 \
  --case base_idle \
  --case hc_idle \
  --repetitions 1 \
  --repetition-start 3
```

## Final result

The complete 3-by-3 matrix passed:

| Tier | READY seconds | TERM-to-group-gone seconds | Result |
|---|---:|---:|---:|
| Base idle | 0.553, 0.452, 0.452 | 0.150, 0.100, 0.100 | 3/3 `term_exit` |
| HC solved then idle | 37.991, 36.085, 35.970 | 0.401, 0.351, 0.401 | 3/3 `term_exit` |
| ODEPE imported then idle | 19.066, 16.962, 16.509 | 0.501, 0.551, 0.501 | 3/3 `term_exit` |

All nine READY markers and their provenance checks passed. All nine private
process groups disappeared within 0.552 seconds after `SIGTERM`; none required
`SIGKILL`, and no cleanup failed. `results-final/summary.json` contains the
authoritative full-precision timings.

The tested runtime was Julia 1.12.6 with 7 Julia and 7 GC threads.
HomotopyContinuation was 2.17.2. ODEParameterEstimation was 1.1.0-DEV from the
clean integration worktree `/tmp/odepe-hardening-20260723`, commit
`776abac47221a6fe1a9bb6906dd6f0ae6b0077f6`, tree
`7fcf6e4d0159d48d3257808cdb8aebe0c5208552`. The exact executable, active
project, expanded load/depot paths, package source path, and dirty status are
retained in every applicable READY record.

This ladder therefore did **not** reproduce the retained post-SIGTERM linger in
an already-initialized, main-task-`Event`-wait state at any of the three tested
initialization levels. It does not refute the historical anomaly: that event
was signalled before the application emitted output, and a termination bug may
require active JIT/GC/finalizers, a particular workload state, lock contention,
or prior memory corruption. Testing those states requires a separate
phase-aware interruption experiment.

## Artifacts

- `results-final/run_metadata.json`: host, environment, commands, and bounds.
- `results-final/results.jsonl`: one durable machine-readable record per run.
- `results-final/summary.json`: counts and timings by tier.
- `results-final/logs/*.log`: each Julia process's combined stdout/stderr, including
  its `READY` marker and any SIGTERM report.

The metadata also inventories Julia processes already present at ladder start;
the runner never signals those processes. That inventory is namespace-local and
documentary; it is not an exhaustive host process inventory.

Each accepted READY marker must be a complete line with the exact case name and
the PID spawned by the runner. It records Julia's executable, active project,
expanded `LOAD_PATH`/`DEPOT_PATH`, and package versions. The ODEPE tier also
records `pathof(ODEParameterEstimation)`, its source root, Git commit/tree, and
dirty status. Run metadata separately records inherited `JULIA_LOAD_PATH` and
`JULIA_DEPOT_PATH`. The isolated invocation also requires the ODEPE source root,
active project, and expanded load path to match the integration worktree.

Summaries contain both actual and expected run counts. `complete`,
`all_ready`, and `all_exited_on_term` remain false until every requested record
exists; an empty or interrupted run cannot pass vacuously.

## Invalidated preliminary ODEPE arm

The interrupted `results/` directory is retained as provenance, not as the
final matrix. Its first ODEPE attempt used the global base checkout during a
cold precompile, executed that checkout's hidden estimation workload, contended
with another full-suite run, and never emitted READY. That record is invalid
for the import-then-wait tier and must not be counted. The runner terminated the
attempt after its READY bound without needing SIGKILL.

Passing this ladder shows only that already-idle processes at these three
initialization levels terminate under the tested conditions. It cannot exclude
a termination-path bug that requires an active JIT, GC, package finalizer,
particular workload state, or prior memory corruption.
