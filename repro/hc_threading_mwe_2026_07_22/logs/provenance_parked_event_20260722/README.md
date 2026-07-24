# Archived evidence for the 2026-07-22 `diag_sumtest.jl` events

Archived on 2026-07-23 from Claude session
`9e466809-61df-4446-8b7c-1c215da052aa`. The copies preserve the source
files' timestamps. Verify them with:

```bash
sha256sum -c SHA256SUMS
```

## Files

| File | Original location | Purpose |
|---|---|---|
| `diag_sumtest.jl` | session `scratchpad/` | Exact diagnostic driver used by both timed runs and the healthy control |
| `verify_fix_sumtest.log` | session `scratchpad/` | Event 1 SIGTERM death report |
| `verify_fix_sumtest_dbg.log` | session `scratchpad/` | Event 2 SIGTERM death report, with the interrupted task in LLVM/JIT |
| `verify_fix_sumtest_t1.log` | session `scratchpad/` | Healthy one-thread control |
| `bcwlkv73o.output` | session `tasks/` | Event 1 background wrapper result |
| `bizs8sr6j.output` | session `tasks/` | Healthy-control wrapper result |
| `bkm4trn0j.output` | session `tasks/` | Event 2 background wrapper result |
| `TRANSCRIPT_EXCERPT.md` | selected session transcript records | Commands, timestamps, process observations, kills, and full-transcript hash |

The original session root was:

```text
/tmp/claude-1000/-home-orebas--julia-dev-ODEParameterEstimation/9e466809-61df-4446-8b7c-1c215da052aa
```

The complete Claude transcript at archival time was:

```text
/home/orebas/.claude/projects/-home-orebas--julia-dev-ODEParameterEstimation/9e466809-61df-4446-8b7c-1c215da052aa.jsonl
```

Relevant transcript records are 701-724 (Event 1 launch, observation, and
kill), 728-746 (healthy-control launch and completion), and 756-779 (Event
2 launch, observation, and kill). The relevant fields are preserved locally
in `TRANSCRIPT_EXCERPT.md`; that file also records the complete transcript's
archival hash.

## Evidentiary limits

Regular Julia logging redirected to a file is buffered; these logs did not
flush before the processes were forcibly killed. Consequently, the absence
of application output does not locate either process before SIAN or
HomotopyContinuation. Event 1's active phase at SIGTERM is unknown. Event 2
was in LLVM/JIT at SIGTERM. The retained evidence supports post-SIGTERM
process lingering, but does not establish a mid-solve HC deadlock or its
owner.
