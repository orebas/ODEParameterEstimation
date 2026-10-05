# Registry dependency checkpoint

The paired GP script compares GP.jl, robust AGP SE, and AGPUQ on the same
four small deterministic data sets. It reads `inputs.toml` when present; the
first run creates it from the documented seeds. The checked-in input values
are the authoritative draws. Each fit uses its public default fitting policy;
the comparison does not equalize optimizer budgets.

Run from a global environment that develops the desired ODEPE checkout:

```sh
julia --startup-file=no repro/registry_dependency_study_2026_10_04/gp_pair.jl
```

The recorded run loaded the local `main` registry-split worktree based on
`01b816f`, before its cleanup commit. `source_sha256.txt` records the relevant
ODEPE source files. Interpolation source was unchanged from `21072a1`.
`gp_pair_initial.log` is the first successful run; `gp_pair.log` reruns the
same draws while archiving their exact values. The GP and SIAN development
checkouts were `3e896e9` and `2f78ca8`, respectively. The log records package
versions; version strings alone do not distinguish patched checkouts.

These are interpolation and first-derivative errors at off-grid midpoint
locations, not parameter-recovery or UQ-calibration results. Timings include
compilation and should not be used to rank implementations. GP.jl prints
positive-definiteness diagnostics during the clean-data optimization; all
twelve comparisons returned finite predictions and derivatives in the first
run. The decision and its limits are documented on `main` in
`docs/2026-10-04_dependency_decisions.md`.

## Core split validation

`validation.json` records the core code commit, selected dependency versions,
commands, assertion counts, and hashes of uncompressed test logs. The `.log.gz`
files preserve those logs with their full dependency listings. The first local
full run's canary failure is retained alongside the successful rerun; the
explicit-AAA canary correction was committed separately and cherry-picked into
this research branch. Validation of the split refers to the core source on
`main`, not to a new full-suite run of this branch's experimental APIs.
