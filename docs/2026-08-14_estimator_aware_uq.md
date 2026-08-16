# Estimator-aware UQ contract — 2026-08-14

This note describes the production contract introduced after the calibration
work summarized in `2026-08-14_uq_session_recap.md`. The recap remains the
evidence record for the single-point estimator; this document is the routing
and API contract.

## Target and estimand

When `compute_uncertainty=true`, UQ targets exactly
`analysis.returned_results[1]`, after clustering, ranking, diversity selection,
and output truncation. It never independently minimizes SSE and never falls
back to another candidate.

The estimand is the sampling covariance conditional on:

- the selected estimator and candidate;
- its selected point set, optimizer basin, or algebraic branch;
- fixed plug-in GP hyperparameters; and
- the current active-bound set (interior optima are required today).

Candidate-selection uncertainty, GP-hyperparameter sampling uncertainty, and
uncertainty across alternative algebraic branches are not included.

## Canonical estimator identity

Every value-producing stage assigns a run-scoped `EstimatorIdentity` containing
the candidate ID, final estimator kind, data scope, exact point indices and
times, interpolator source, and durable parent IDs. `ResultProvenance` keeps the
legacy flat fields for compatibility, but `estimator_identity` is canonical.

The heavy numerical recipe is retained only while UQ capture is enabled and is
stored in the scoped `RunContext`, keyed by candidate ID. This avoids both
global cross-run leakage and provenance-based reconstruction of a different
system.

## Implemented routes

- `single_point_algebraic`: exact retained symbolic solve/data partition,
  production root, point, and fitted `AGPInterpolatorUQ` objects. The IFT is
  evaluated at that root.
- `multipoint_algebraic`: exact unprojected multipoint root and
  `MultiPointEvaluation`. `DataVarMeta` maps each row into stacked
  `W_stack * Sigma_y * W_stack'`, preserving same-observable cross-time blocks.
  If production reports a directly observed state that was eliminated from the
  polynomial root, UQ appends the exact raw sample used at the first selected
  point as a supplemental estimator input. Its unit raw-data influence retains
  the raw-vs-jet cross-covariance; it is never replaced by a GP posterior mean
  or assigned zero variance.
- `trajectory_polish` and `direct_optimization`: observed full score/Hessian
  IFT for the retained trajectory objective and exact optimizer-space point,
  including coordinate transforms and, for residual polish, its regularization
  and soft-wall terms. The identity records the complete observation-time grid.
  The score and data influence use the same first-order AD Jacobian as the
  production least-squares solver; the full Hessian uses central differences of
  the retained scalar objective to avoid nested-Dual ODE compilation failures
  on Julia 1.12.
  The result is conditional on the selected optimizer basin. Nonconvergence, a
  material score, active bounds, non-positive local curvature, or a failed
  Hessian factorization produce a typed unavailable outcome.
- `branch_completed`: first computes the retained anchor estimator's
  covariance, then propagates it through exact anchor observable jets and the
  selected sibling-root IFT. The finite-difference anchor-to-jet map is checked
  at two step sizes and degrades loudly when unstable. Propagation retains the
  anchor's full raw-observation influence map, which is required to preserve
  covariance between derived jets and directly observed child-state outputs.

Unpolished synthesized aggregates, sensitivity seeds, state-resolve candidates,
legacy/imported rows, and unsupported interpolators currently return a typed
`UQUnavailable`. They never inherit a single-point covariance by accident.

## Noise covariance

`uq_noise_source` selects the raw-observation covariance producer:

- `:learned_gp_homoscedastic` (default): the fitted GP observation-noise
  variance in raw observation units;
- `:smoother_residual_edf`: residual variance divided by the exact linear
  smoother residual effective degrees of freedom
  `n - 2 tr(H) + tr(H'H)`.

An `InterpolatorAGPUQ` must be explicitly present in the configured
interpolator list. Enabling UQ does not alter the estimator pool. Algebraic UQ
requires that the winning algebraic candidate itself used that retained fit;
trajectory objectives use the explicitly configured fit as their observation
noise provider. Failures while retaining an optional UQ artifact cannot remove
or modify an estimator candidate; they surface later as a typed unavailable
outcome if that candidate wins.

## Return and sidecar contract

The public three-tuple is unchanged. Its third element is:

- `nothing` only when UQ is disabled;
- `UncertaintyReport` when a covariance was computed; or
- `UQUnavailable` when UQ was requested but cannot be computed honestly.

With `uq_failure_policy=:throw`, unavailable or degenerate outcomes throw
`UQComputationError`.

`UncertaintyReport` records the selected-estimate center separately from truth.
Operational CV and practical-identifiability status use the estimate; truth is
validation-only, so real-data runs with unknown truth cannot falsely report
`:ok` merely because all truth coordinates were skipped.

`provenance_metadata_dict` serializes the estimator identity, and
`uq_metadata_dict` provides a JSON-friendly additive UQ sidecar block. Existing
`result.csv` shape does not change. Non-finite floating-point values are emitted
as `null`, so a real report (including intentionally unavailable truth and
linearization fields) can be passed directly to a standards-compliant JSON
encoder.

`uq_reliability(outcome)` separates five axes that the legacy `status` field
historically conflated: availability, numerical linearization, interval width,
selection scope, and empirical calibration. The last axis is always
`:not_assessed_by_single_run` on an individual report; only a frozen
repeated-sampling campaign can establish coverage. The legacy field remains for
source compatibility and is also retained in the sidecar as `status`.

## Numerical gates

Algebraic reports retain absolute/relative root residual and Jacobian condition.
Optimizer reports retain score norm, observed-Hessian condition, and active
bounds, and require positive local curvature before inversion. A degraded gate
always forces the backward-compatible summary `status=:degenerate`; automatic
power-of-two unscaling cannot erase that status.

The covariance remains useful for audit when a residual or conditioning gate is
degraded, but neither `status=:ok` nor an accepted numerical-linearization axis
is an empirical calibration claim. Singular systems and
unsupported artifacts return `UQUnavailable` rather than a pseudoinverse or
zero covariance.

## Validation boundary

The N=60 low-noise single-point result in the session recap remains the clean
calibration result for that estimator. Exact multipoint routing has
finite-difference and contract tests. Polish/direct/branch propagation has
software-contract coverage and explicit numerical gates, but end-to-end
nonlinear coverage campaigns remain separate validation work. A green software
gate establishes routing and calculus consistency, not empirical coverage for
LV/FHN/Van der Pol.

The exact frozen-model checks in
[`2026-08-14_peb_audited_uq_canaries.md`](2026-08-14_peb_audited_uq_canaries.md)
are the current nonlinear estimator/provenance canaries. They establish correct
selected-row routing on audited data, while deliberately making no coverage
claim.
