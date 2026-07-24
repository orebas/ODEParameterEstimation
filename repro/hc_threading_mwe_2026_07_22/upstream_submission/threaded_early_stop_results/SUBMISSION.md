# Submission record

- Upstream base: `cd74c49474959e0b2661f81587affba29a42c5ed`
- Local branch: `fix/threaded-early-stop-results`
- Local head: `673ff92d21ac9c2f49a68b21b2a40817bcce8b10`
- Commit subject: `Preserve results after threaded early stop`
- Patch: `0001-Preserve-results-after-threaded-early-stop.patch`
- Focused log: `focused-test.log`
- Fork branch: `orebas:fix/threaded-early-stop-results`
- Issue: https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/718
- Pull request: https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/pull/721

## Validation

Focused result with `JULIA_NUM_THREADS=4`: 2 passed, 0 failed.

Broader focused file:

```sh
JULIA_NUM_THREADS=4 julia --startup-file=no --project=. \
  -e 'using Test, LinearAlgebra, HomotopyContinuation; const HC = HomotopyContinuation; set_default_compile(:none); include("test/test_systems.jl"); include("test/solve_test.jl")'
```

Result: 74 passed, 0 failed in 2m59.7s.

The full `HC_TESTSET=non_model_kit` partition was not run. All affected Julia
files were formatted with JuliaFormatter 1.0.33, and `git diff --check`
passed before commit.

## Residual risk

The callback itself remains concurrent. This PR only ensures that completed
assigned results are returned after early termination.

Apply independently with:

```sh
git am 0001-Preserve-results-after-threaded-early-stop.patch
```
