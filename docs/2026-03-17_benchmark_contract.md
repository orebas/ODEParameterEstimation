# Benchmark Contract Note

Started 2026-03-17; default result ordering updated 2026-09-10. External collector
behavior described below has not been re-audited in this update.

It is meant for ODEPE consumers such as `ParameterEstimationBenchmarking`, not for first-time package users.

## ODEPE Return Contract

The current package call is:

```julia
raw_results, analysis, uq = analyze_parameter_estimation_problem(sampled, opts)
```

For benchmark consumers:

- use `analysis.returned_results` (also `analysis[1]`) as the analyzed solution vector, ranked by trajectory fit error by default
- use the named summary fields documented in [Results and API](2026-03-17_results_and_api.md)
- ignore `uq` unless you are explicitly working on uncertainty quantification

Report selected-estimate accuracy separately from best-of-branch recovery. The
first returned result is the selected estimate; the best ground-truth error
over a pool is a validation metric and may belong to another candidate. The
summary scalars can also refer to candidates omitted by output selection.

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
