# Benchmark Contract Note

This note reflects the package and benchmark alignment state as of 2026-03-17.

It is meant for ODEPE consumers such as `ParameterEstimationBenchmarking`, not for first-time package users.

## ODEPE Return Contract

The current package call is:

```julia
raw_results, analysis, uq = analyze_parameter_estimation_problem(sampled, opts)
```

For benchmark consumers:

- use `analysis[1]` as the analyzed, oracle-ordered solution vector
- use `analysis[2:8]` as the summary scalars
- ignore `uq` unless you are explicitly working on uncertainty quantification

## Flat Result Compatibility

The benchmark-facing compatibility artifact remains the flat `result.csv`.

Current policy:

- keep `result.csv` in the historical flat shape expected by the benchmark collector
- source that flat output from `analysis[1]`, not from raw solver candidates

## Optional Sidecar

Benchmark integrations may also write an optional sidecar such as `odepe_metadata.json`.

This sidecar is additive only. It can include:

- `status`
- raw and analyzed solution counts
- summary metrics
- provenance/debug information for the best analyzed result

The collector should not require this file in order to treat `result.csv` as valid.
