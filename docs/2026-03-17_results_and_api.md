# Results and API

This guide reflects the package state as of 2026-03-17.

## Main User-Facing Workflow

The current public workflow is:

```julia
sampled = sample_problem_data(pep, opts)
raw_results, analysis, uq = analyze_parameter_estimation_problem(sampled, opts)
```

The main public types and entry points are exported from [ODEParameterEstimation.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/ODEParameterEstimation.jl):

- `ParameterEstimationProblem`
- `EstimationOptions`
- `ParameterEstimationResult`
- `ResultProvenance`
- `sample_problem_data`
- `analyze_parameter_estimation_problem`
- `estimate`

For a runnable first example, see [2026-03-17_user_quickstart.md](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_user_quickstart.md).

## What `analyze_parameter_estimation_problem` Returns

The current return value is a 3-tuple:

```julia
(raw_results, analysis, uq)
```

### `raw_results`

This is the raw solver-stage output before clustering and analysis. It is useful for debugging and benchmarking, but most package users should read from `analysis`.

### `analysis`

`analysis` is the main user-facing summary tuple:

```julia
(
    analyzed_solutions,
    besterror,
    best_min_error,
    best_mean_error,
    best_median_error,
    best_max_error,
    best_approximation_error,
    best_rms_error,
)
```

Meaning:

- `analysis[1]`
  The analyzed, clustered, oracle-ordered solution vector.
- `analysis[1][1]`
  The canonical best analyzed result.
- `analysis[2]`
  Best max relative error on identifiable quantities.
- `analysis[3]`
  Best minimum relative error.
- `analysis[4]`
  Best mean relative error.
- `analysis[5]`
  Best median relative error.
- `analysis[6]`
  Best maximum relative error.
- `analysis[7]`
  Best approximation error.
- `analysis[8]`
  Best RMS relative error.

When ground-truth values are known, the analyzed solutions are ordered by oracle-style error over identifiable quantities. In that setting, `analysis[1][1]` is the best result to report or benchmark.

### `uq`

`uq` is the uncertainty-quantification side output. It exists, but it is not part of the recommended default user path and is not the focus of the current user docs.

## Reading `ParameterEstimationResult`

The most important fields on `ParameterEstimationResult` are:

- `parameters`
  Estimated parameter values.
- `states`
  Estimated state values.
- `err`
  Candidate-level error summary.
- `all_unidentifiable`
  Structural-unidentifiable variables surfaced by the current flow.
- `provenance`
  Structured lineage metadata about how the result was produced.

The struct is defined in [core_types.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/types/core_types.jl).

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
- `residual_fix_set`
  Residual template repair set. In the supported default flow this is normally empty.
- `template_status_before_residual_fix` and `template_status_after_residual_fix`
  SI template dimension status.
- `practical_identifiability_status`
  Current practical/numerical-identifiability headline for the run.
- `numerical_advisory`
  Best-effort advisory-only numerical diagnostics.

## Current Contract Notes

As of this doc:

- structural identifiability in the standard SI flow comes from `SI.jl` / `StructuralIdentifiability`
- the older numerical Jacobian/nullspace layer is advisory-only
- structural representative fixing is explicit and recorded in provenance
- non-square SI templates after structural fixing fail early instead of being repaired heuristically

For the current support boundaries, see [2026-03-17_supported_models_and_limitations.md](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_supported_models_and_limitations.md).
