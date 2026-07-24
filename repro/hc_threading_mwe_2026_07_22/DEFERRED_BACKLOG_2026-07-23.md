# Deferred follow-ups from the HC/ODEPE threading investigation

These items are intentionally outside the small confirmed fixes prepared on
2026-07-23. None should be folded into those submissions without separate
evidence and review.

## HC callback concurrency contract

`stop_early_cb` can currently run concurrently in threaded solves. The immediate
empty-result bug does not require changing that behavior.

Before changing it, decide and document one of:

1. callbacks must be thread-safe; or
2. HC serializes callbacks and guarantees at most one true-trigger.

If serialization is chosen, test callback count, ordering expectations, and the
result set after an early stop. Avoid running arbitrary user code under an
unrelated internal lock.

## HC compiled-cache design and lifetime

The prepared lock fix makes current registry transactions safe. It does not
change the value-as-type design or the process-lifetime growth of
`TSYSTEM_TABLE` and `THOMOTOPY_TABLE`.

A separate design investigation should measure:

- number and memory cost of retained entries in long-lived processes;
- compilation latency for repeated supports versus genuinely new supports;
- whether weak/lifecycle-aware registries are compatible with generated
  `interpret(::Type)` calls;
- whether stable support keys can avoid minting unnecessary concrete types.

## ProgressMeter task-migration hypothesis

The historical concern about a `threadid()`-based locking heuristic is a source
review hypothesis, not a reproduced failure in this investigation. Minimize it
against the current ProgressMeter release before filing anything. A valid
reproducer must demonstrate concurrent mutation or corrupt output under task
migration without involving HC's cache race.

## ODEPE process-global diagnostic state

Several older timing and auto-multiplicity paths still use process-global
mutable state, including timing/result `Ref`s and mutable context stacks. The
new live-progress path does not add to that state, but it also does not repair
the older paths.

Refactor these separately using invocation-scoped state. Required tests:

- two overlapping estimations do not exchange timing, reuse, multiplicity, or
  context records;
- nested capture scopes restore their caller's state after success and error;
- ordinary calls retain their current public result shape.

## Julia termination-path linger

No Julia issue is ready. The retained observations establish post-SIGTERM
lingering, but not a Base-only cause. Continue only through the dependency
ladder in `PROVENANCE_PARKED_EVENT_2026-07-23.md`.

File upstream only if a repeatable Base/JIT-only reproducer survives
minimization and includes:

- flushed phase markers;
- the completed fatal-report footer;
- proof that the PID remains alive past the stated grace interval;
- repeated per-thread CPU and wait-channel samples;
- native/Julia stacks when ptrace policy permits them.
