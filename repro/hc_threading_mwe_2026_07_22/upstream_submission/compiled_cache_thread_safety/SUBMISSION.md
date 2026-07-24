# Submission record

- Upstream base: `cd74c49474959e0b2661f81587affba29a42c5ed`
- Local branch: `fix/compiled-cache-thread-safety`
- Local head: `4b542974fe0984d78e34530a0f8687fc3838362b`
- Commit subject: `Make compiled ModelKit caches thread-safe`
- Patch: `0001-Make-compiled-ModelKit-caches-thread-safe.patch`
- Focused log: `focused-test.log`
- Fork branch: `orebas:fix/compiled-cache-thread-safety`
- Issue: https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/717
- Pull request: https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/pull/720

## Validation

Focused command:

```sh
JULIA_NUM_THREADS=2 julia --startup-file=no --project=. \
  -e 'using Test, HomotopyContinuation; using HomotopyContinuation.ModelKit; include("test/model_kit/compiled_cache_test.jl")'
```

Result: 14 passed, 0 failed.

The complete ModelKit partition was also started after dependency setup. It
produced no test failure, but was stopped after a bounded interval rather than
allowed to block the other submission kits. It is therefore **not recorded as
completed**.

All affected Julia files were formatted with the repository CI pin,
JuliaFormatter 1.0.33. `git diff --check` passed before commit.

## Residual risk

- The retained dynamic corruption evidence covers `TSYSTEM_TABLE`.
  `THOMOTOPY_TABLE` is fixed because it has the same unsafe design, but no
  separate retained corruption campaign exists for it.
- The cache tables remain process-global and grow monotonically; this patch
  addresses thread safety, not eviction or lifetime.
- Lock contention is possible during simultaneous construction, but solving
  and final parametric type construction remain outside the critical section.

Apply independently with:

```sh
git am 0001-Make-compiled-ModelKit-caches-thread-safe.patch
```
