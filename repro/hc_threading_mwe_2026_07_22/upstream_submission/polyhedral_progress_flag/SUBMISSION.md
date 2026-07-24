# Submission record

- Upstream base: `cd74c49474959e0b2661f81587affba29a42c5ed`
- Local branch: `fix/polyhedral-progress-flag`
- Local head: `c6279ce8b5d76e5ce957e82508842851e5b44074`
- Commit subject: `Honor show_progress during polyhedral setup`
- Patch: `0001-Honor-show_progress-during-polyhedral-setup.patch`
- Focused log: `focused-test.log`
- Fork branch: `orebas:fix/polyhedral-progress-flag`
- Issue: https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/719
- Pull request: https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/pull/722

## Validation

Focused result with `JULIA_NUM_THREADS=4`: 4 passed, 0 failed.

Broader focused file:

```sh
JULIA_NUM_THREADS=4 julia --startup-file=no --project=. \
  -e 'using Test, LinearAlgebra, HomotopyContinuation; const HC = HomotopyContinuation; set_default_compile(:none); include("test/test_systems.jl"); include("test/solve_test.jl")'
```

Result: 76 passed, 0 failed in 2m35.3s.

The full `HC_TESTSET=non_model_kit` partition was not run. All affected Julia
files were formatted with JuliaFormatter 1.0.33, and `git diff --check`
passed before commit.

## Residual risk

ProgressMeter suppresses output for operations that finish before its display
threshold. The direct regression therefore also checks the pre-fix
unsupported-keyword warning, rather than relying only on visible meter text.

Apply independently with:

```sh
git am 0001-Honor-show_progress-during-polyhedral-setup.patch
```
