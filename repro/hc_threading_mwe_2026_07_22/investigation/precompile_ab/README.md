# Precompile A/B capture audit

## Bottom line

The retained material does **not** constitute a valid causal A/B for commit
`8f02d10` (`precompile: remove hidden estimation workload`). There is one valid
operational capture of the selected “before” setup reaching the configured RSS
guard, but there is no dependency-matched, revision-isolated, clean-cache
“after” capture with which to compare it.

In particular, these captures do not prove a hang or deadlock, do not measure
unique memory, and do not establish how much memory was caused by ODEPE's former
`@compile_workload` rather than concurrent dependency precompilation.

The classifications below use:

- **valid**: the capture faithfully records the stated setup and outcome;
- **excluded**: a known setup failure or contamination makes it unusable for
  the intended comparison;
- **interrupted**: the run has no terminal outcome because it was stopped
  outside the recorded watchdog policy; and
- **inconclusive**: the capture records real activity, but revision or
  environment confounds prevent the intended inference.

“Valid” means valid for its narrow operational observation, not that it supplies
a complete A/B by itself.

## Critical environment and revision facts

1. The global Julia 1.12 manifest used as the reference when these runs were
   prepared contained `PrecompileTools` but did **not** contain `ScopedValues`.
   This was sufficient for the baseline source, but not for the later stacked
   hardening HEAD, whose `Project.toml` and front door import `ScopedValues`.
   Later package-development activity may change the live global manifest; that
   does not repair the environment mismatch in the retained captures.
2. The “after” source was `/tmp/odepe-hardening-20260723`, at a final stacked
   hardening HEAD rather than the isolated precompile-policy commit `8f02d10`.
   That stack also contained HC configuration, progress, entrypoint, watchdog,
   and subsequent hardening changes. The capture metadata records a mutable
   source path, not a detached commit ID. Consequently, no observed difference
   can be attributed specifically to removal of the precompile workload.
3. The attempted space-saving global-cache clone used hardlinks. Existing
   cache files therefore shared inodes and kernel page-cache state with the
   template and global depot. New pidfiles and temporary/cache entries appeared
   in the active clone. We did not establish that any shared file was modified
   in place, so this is a cache-independence and auditability problem—not proof
   that the global depot was modified.
4. `after_compilecache_globaloverlay` was manually stopped. Its
   `metadata.json` has no `finished_utc`, child return code, outcome, termination
   reason, or termination record. It is not a watchdog-completed run.

## Capture-by-capture classification

| Capture | Classification | Exact failure or confound | What can be inferred | What cannot be inferred |
| --- | --- | --- | --- | --- |
| `before/` | **excluded** | The package-directory `LOAD_PATH` overlay selected `/tmp/odepe-seir-baseline-20260723/ODEParameterEstimation`, but that loading mode did not provide the package's dependency resolution. Import failed in about five seconds with “Package ModelingToolkit … does not seem to be installed.” | The attempted loader setup was invalid. The watchdog correctly recorded `child_failed`. | Nothing about ODEPE precompile time, memory, completion, the hidden workload, or a hang. |
| `before_valid/` | **excluded** | Despite its name, it repeated the same invalid package-directory loading approach and the same missing-`ModelingToolkit` failure. It never reached a successful ODEPE import. | Same as `before/`; renaming the capture did not make the environment valid. | No precompile comparison or performance conclusion. |
| `before_controlled/` | **valid**, narrowly | It used the explicit environment `/tmp/odepe-precompile-before-env-20260723` and a separately copied depot. The baseline import remained active and exceeded the configured aggregate RSS cap at the first five-second interval: 4391.62 MiB, 15 live processes, 33 threads, and about 319% aggregate CPU. The watchdog sent `SIGTERM` and recorded a complete `rss_limit` outcome. | In this exact controlled setup, aggregate process-tree RSS crossed the operational 4096 MiB cap before import completed. The process tree was CPU-active, not evidence of low-CPU no-progress. | Whether it would have completed, its completion time or peak memory, unique memory usage, or how much RSS came specifically from ODEPE's `@compile_workload` rather than dependency precompilation. It is only the “before” half and has no valid matched “after.” |
| `after_compilecache/` | **inconclusive** | `Base.compilecache` targeted the mutable final hardening source, not isolated `8f02d10`, while dependency resolution came from the global v1.12 environment that lacked the new direct dependency `ScopedValues`. The run never printed `phase=after_compilecache`; after about 330 seconds it crossed the RSS cap at 4703.35 MiB and was terminated. | This mismatched, stacked-source compile attempt was still active, used substantial CPU, spawned dependency precompile workers, and exceeded the configured aggregate RSS cap. It was not classified as suspected no-progress. | Whether isolated `8f02d10` improves precompilation; whether the final source could complete in a correct environment; whether the run would eventually fail on missing `ScopedValues`; or whether any observed cost was caused by the removed workload. |
| `after_compilecache_retry1/` | **excluded** | This reused the partially populated overlay left by the prior capped compile. `run.log` reports stale pidfiles, and the retry crossed 4096 MiB in about 25 seconds while recovering/recompiling multiple dependencies. It retained the same stacked-source and missing-`ScopedValues` mismatch. | The reused overlay was dirty and capable of another high-RSS precompile fan-out. | It is not an independent cold repeat, a clean warm-cache measurement, or evidence about `8f02d10`. Its 25-second result must not be compared with `before_controlled/`. |
| `after_compilecache_globaloverlay/` | **interrupted** | This attempted to reuse a global-style cache overlay produced through the hardlink-clone experiment. The active clone had already acquired new pidfiles and temporary/cache entries, while its pre-existing cache files shared inodes and kernel cache state with the template. The run was then manually stopped. Its final metadata is incomplete; the log contains only `phase=before_compilecache`. | Through the final retained sample (about 170 seconds), the observed tree was CPU-active and below the 4096 MiB cap, with 1710.23 MiB aggregate RSS at the last sample. This is only a prefix of a run. | Completion, failure, final/peak memory, watchdog outcome, hang status, or any before/after conclusion. The absence of a recorded terminal RSS event is not evidence that it would stay below the cap. |

## Why no causal A/B survives

A defensible A/B would hold the Julia version, Project/Manifest, dependency
depot, cache warmth, watchdog policy, and source revision constant except for
the single change under test. These captures do not:

- the usable “before” points at the baseline source, while “after” points at a
  multi-commit final hardening worktree;
- the global manifest resolves `PrecompileTools` but, at capture time, not
  `ScopedValues`, so the two source trees do not have symmetric dependency
  support;
- the retry starts from a partially compiled depot;
- the global-overlay attempt uses a non-independent hardlink clone with
  additional files created during compilation; and
- the last run was manually interrupted.

The retained captures are therefore diagnostic history, not evidence for a
numeric speedup, memory reduction, or hang fix.

## Concise command inventory

The child commands are preserved verbatim in each `metadata.json`. The common
watchdog policy was a 600-second wall limit, 120-second stall threshold,
five-second samples, three low-CPU samples below 1%, a 4096 MiB aggregate RSS
cap, and a 15-second TERM grace period. In schematic reproducible form:

```bash
python3 /tmp/odepe-hardening-20260723/tools/diagnostics/odepe_watchdog.py \
  --output investigation/precompile_ab/CAPTURE \
  --wall-seconds 600 \
  --stall-seconds 120 \
  --sample-seconds 5 \
  --low-cpu-samples 3 \
  --cpu-threshold-percent 1 \
  --max-rss-mb 4096 \
  --term-grace-seconds 15 \
  -- COMMAND
```

The retained child command variants were:

```bash
# Invalid package-directory attempts: before/, before_valid/
julia --startup-file=no investigation/precompile_ab/import_probe.jl

# Controlled baseline: before_controlled/
julia --startup-file=no \
  --project=/tmp/odepe-precompile-before-env-20260723 \
  investigation/precompile_ab/import_probe.jl

# All compilecache “after” attempts
julia --startup-file=no \
  --project=/home/orebas/.julia/environments/v1.12 \
  investigation/precompile_ab/compilecache_probe.jl \
  /tmp/odepe-hardening-20260723/src/ODEParameterEstimation.jl
```

`import_probe.jl` prints markers immediately before and after
`using ODEParameterEstimation`. `compilecache_probe.jl` prints markers
immediately before and after:

```julia
Base.compilecache(
    Base.PkgId(
        Base.UUID("482fc905-5656-4c69-b8fe-7a66cd0f77b3"),
        "ODEParameterEstimation",
    ),
    source_path,
)
```

Environment variables selecting `JULIA_LOAD_PATH` and `JULIA_DEPOT_PATH` were
not captured in `metadata.json`; they must not be reconstructed from directory
names as though they were authoritative. A future replay should record them,
use ordinary copies or immutable lower layers rather than hardlinks, and
compare `52fbbdf` with a source tree differing only by deletion of the
`@compile_workload` body while retaining the same dependency graph. Testing
the whole `8f02d10` commit is a different, two-factor comparison because that
commit also removes `PrecompileTools`.
