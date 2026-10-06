# Results and API

Started 2026-03-17; reviewed for the 1.0.0 registration candidate, 2026-10-05.

## Main User-Facing Workflow

The current public workflow is:

```julia
sampled = sample_problem_data(pep, opts)
raw_results, analysis, uq = analyze_parameter_estimation_problem(sampled, opts)
```

The main public types and entry points are exported from [ODEParameterEstimation.jl](../../src/ODEParameterEstimation.jl):

- `ParameterEstimationProblem`
- `EstimationOptions`
- `ParameterEstimationResult`
- `ResultProvenance`
- `sample_problem_data`
- `analyze_parameter_estimation_problem`

For a runnable first example, see [2026-03-17_user_quickstart.md](2026-03-17_user_quickstart.md).

## What `analyze_parameter_estimation_problem` Returns

The current return value is a 3-tuple:

```julia
(raw_results, analysis, uq)
```

### `raw_results`

This is the raw solver-stage output before clustering and analysis. It is useful for debugging and benchmarking, but most package users should read from `analysis`.

### `analysis`

`analysis` is a named tuple. Prefer named fields; positional access remains available:

| Field | Position | Meaning |
|---|---|---|
| `returned_results` | 1 | Analyzed cluster representatives, ranked by the configured strategy |
| `besterror` | 2 | Best maximum relative error on identifiable quantities |
| `best_min_error` | 3 | Best minimum relative error |
| `best_mean_error` | 4 | Best mean relative error |
| `best_median_error` | 5 | Best median relative error |
| `best_max_error` | 6 | Best maximum relative error; same metric as `besterror` |
| `best_approximation_error` | 7 | Best trajectory-fit error among scored candidates |
| `best_rms_error` | 8 | Best RMS relative error |
| `algebraic_multiplicity` | 9 | Multiplicity recorded for the output policy |

With the defaults (`branch_detection=true`, `rank_strategy=:err_only`),
`first(analysis.returned_results)` is the selected estimate by trajectory fit
error. Ground truth is not used for this default ordering. The legacy
`branch_detection=false` path retains oracle-based ordering.

The relative-error fields require meaningful ground-truth values and summarize
the candidate pool before output selection. Their minima can come from different
candidates, including candidates absent from the returned subset. They therefore
do not describe the parameter error of the selected estimate automatically.

### `uq`

`uq` is the opt-in uncertainty-quantification output, targeting the returned
rank-one estimator. The audited single-point calibration result does not
establish coverage for nonlinear multipoint or polished estimators. A
single-run reliability status is not a calibration certificate. See the
[UQ contract](2026-08-14_estimator_aware_uq.md) before interpreting intervals.

## Reading `ParameterEstimationResult`

The most important fields on `ParameterEstimationResult` are:

- `parameters`
  Estimated parameter values.
- `states`
  Estimated state values.
- `err`
  Candidate trajectory-fit error, used by the default ranking.
- `all_unidentifiable`
  Structural-unidentifiable variables surfaced by the current flow.
- `provenance`
  Structured lineage metadata about how the result was produced.

The struct is defined in [core_types.jl](../../src/types/core_types.jl).

## Reading Provenance

`best.provenance` is useful when you need to understand how a result was obtained.

Common fields:

- `primary_method`
  Usually `:algebraic` or `:direct_opt`.
- `interpolator_source`
  Which interpolator produced the candidate.
- `rescue_path`
  Whether a non-core rescue path was used.
- `source_shooting_index`
  Which shooting point produced the candidate.
- `source_candidate_index`
  Candidate index within that phase.
- `structural_fix_set`
  Representative structural fixes derived from SI structural outputs.
- `template_status`
  SI template dimension status after structural fixing. (2026-08: replaced the
  vestigial `residual_fix_set` + `template_status_before/after_residual_fix`
  triple — no residual-repair mechanism ever existed, so the pair was identical
  by construction and the set always empty.)
- `practical_identifiability_status`
  Current practical/numerical-identifiability headline for the run.
- `numerical_advisory`
  Best-effort advisory-only numerical diagnostics.

## Reproducibility

Several steps draw random numbers: generic sample points for the SI template,
solver start points, and probe points. By default these come from Julia's
default RNG, so two runs on the same data can differ in the last digits and,
occasionally, in which candidate ranks first.

Set `seed` in `EstimationOptions` for identical results on repeated runs:

```julia
opts = EstimationOptions(datasize = 41, noise_level = 1e-3, seed = 7)
sampled = sample_problem_data(pep, opts)   # same noise on every call
_, analysis, _ = analyze_parameter_estimation_problem(sampled, opts)
```

The seed is scoped. Sampling and estimation each run on their own stream
derived from it, and Julia's default RNG is restored afterwards, so your own
`rand` calls are unaffected. With a fixed seed every `sample_problem_data`
call returns the same noise; use a different seed per replicate when you want
independent draws. Leaving `seed = nothing` keeps the earlier behavior, where
calling `Random.seed!` before each step controls it.

## Current Contract Notes

As of this doc:

- structural identifiability in the standard SI flow comes from `SI.jl` / `StructuralIdentifiability`
- the older numerical Jacobian/nullspace layer is advisory-only
- structural representative fixing is explicit and recorded in provenance
- non-square SI templates after structural fixing fail early instead of being repaired heuristically

For the current support boundaries, see [2026-03-17_supported_models_and_limitations.md](2026-03-17_supported_models_and_limitations.md).
