# GP and SIAN dependency decisions — 2026-10-04

The user subsequently chose to internalize both dependencies. The implementation
and validation are recorded in [Internal backends](2026-10-04_internal_backends.md).
The initial retain-for-release decision below is preserved as historical context;
it no longer describes the package dependency graph.

## Initial decision (superseded)

Keep both GaussianProcesses.jl and SIAN as direct dependencies for the first
release candidate. Do not copy their implementations into ODEPE in this
milestone. Keep the GP.jl interpolator in the candidate pool. Seek registered
compatibility fixes upstream and retain the existing patched-dependency CI lane
until a fresh registered-only lane passes on the chosen release stack. Revisit
internalization only after the paired end-to-end gates below show that a
replacement preserves the recovered fits and SI templates.

This is a maintenance decision, not a finding that the dependency update
problem is solved. General cannot publish a release that requires unregistered
fork commits; the package must resolve and run with registered versions alone.

## GaussianProcesses.jl

ODEPE's use is narrow. [`aaad_gpr_pivot`](../src/core/derivatives.jl) standardizes
the observed values, creates a zero-mean squared-exponential GP with log
lengthscale `log(std(xs)/8)`, log signal standard deviation `0`, and log noise
standard deviation `-2`, calls
`GaussianProcesses.optimize!` with LBFGS, and uses `predict_f` for the fitted
mean. This is available as `InterpolatorAAADGPR`, the singular option default,
and is still in the default *multi-interpolator pool*. The separate
[`PDMats` `ldiv!` bridge](../src/ODEParameterEstimation.jl) resolves a method
ambiguity on some registered dependency combinations. Removing GP.jl would
change a public selection route and the candidate pool, even though ODEPE also
has `agp_gpr`, `agp_gpr_robust`, and `agp_gpr_uq` implementations.

The fitting policies differ even for the same SE kernel. GP.jl uses log
standard deviations (so its initial noise variance is `exp(-4)`) and the
unconstrained LBFGS route. Robust AGP and AGPUQ optimize variances through a
softplus transform with bounds and initialize noise from second-difference
roughness. AGPUQ also uses a shared explicit covariance recipe for optimization
and the retained factor. These are plausible sources of different optima or
roundoff behavior; this checkpoint does not isolate their individual effects.

The local GP checkout `3e896e9` reports package version 0.12.6 and carries six
commits after its fetched `origin/master` at `564cb52` (2026-06-10). The
changes cover Optim 2 / StatsFuns 2 compatibility, the PDMats ambiguity,
Julia 1.13 autodiff and Cholesky behavior, and test stability. The combined
tree is used by the patched CI lane. The source is MIT licensed; copying any
substantial part into the GPL-3.0 package would require preserving its notice.

### Paired interpolation checkpoint

The frozen comparison script and its raw output are retained on the
[`research` commit `dd27080`](https://github.com/orebas/ODEParameterEstimation.jl/tree/dd27080/repro/registry_dependency_study_2026_10_04).
It fits the same data for each method, with MersenneTwister seeds
`20261005`–`20261008`, observations on `[0,4]`, and off-grid midpoint evaluation.
The metric is RMSE against the known generating function and its first
derivative. It ran with Julia 1.13.1 and ODEPE `1.1.0-DEV` from the local
checkout. The installed GP checkout was `3e896e9`; this was a patched stack,
not a registered-only validation. The script calls the same
`_estimation_derivative` helper used by estimation. The output includes GP
optimization's positive-definiteness diagnostics on the clean fit.

| Case | N | Noise SD | GP prediction / derivative RMSE | AGP SE prediction / derivative RMSE | AGPUQ prediction / derivative RMSE |
| --- | ---: | ---: | ---: | ---: | ---: |
| Smooth clean | 41 | 0 | 2.06e-9 / 2.68e-8 | 1.90e-8 / 2.06e-7 | 9.14e-9 / 1.14e-7 |
| Smooth noisy | 41 | 0.03 | 0.0127 / 0.0459 | 0.0127 / 0.0459 | 0.0127 / 0.0459 |
| Mixed scale | 61 | 0.01 | 0.00380 / 0.0327 | 0.00380 / 0.0327 | 0.00380 / 0.0327 |
| Transient | 41 | 0.01 | 0.00763 / 0.0240 | 0.00763 / 0.0240 | 0.00763 / 0.0240 |

The clean case confirms a GP.jl win in this small interpolation sample, though
all three errors are tiny. The noisy values agree to the precision shown.
Elapsed fit times in the raw output mix compilation and warm runs and are not
a fair performance comparison. This experiment does not measure higher-order
jets, chosen shooting points, parameter recovery, or UQ coverage. The older
[`compare_interpolators.jl` script](https://github.com/orebas/ODEParameterEstimation.jl/blob/research/src/examples/compare_interpolators.jl)
uses shared sampled data for two full estimator paths, but has no frozen result
record or current registered-stack gate. It is a starting point, not evidence
for removing GP.jl.

**Decision rationale:** The dependency is a small call surface, while replacing
its optimized fit would create another maintained implementation of a path
that can still win. Improve and compare AGP, but retain the GP candidate until
frozen LV, VDP, FHN, and at least one hard-model run compare prediction,
derivative jets at selected points, rank-one parameter recovery, and time on
identical draws. A proposed replacement must pass the registered full gate and
recovery benchmark before deleting the GP route or bridge. The UQ path has its
own audited estimator contract and must be assessed separately.

## SIAN-Julia

[`get_polynomial_system_from_sian`](../src/core/si_equation_builder.jl) already
contains ODEPE's own rank-selected template assembly. It calls SIAN for jet
equations and recurrences (`get_equations`, `get_x_eq`, `get_y_eq`), exact
generic samples (`sample_point`, `insert_zeros_to_vals`), Jacobians and jet
ordering (`jacobi_matrix`, `get_vars`, `get_order_var`, `get_order_var2`,
`compare_diff_var`), and rational-ring transformations (`unpack_fraction`,
`add_to_var`, `parent_ring_change`). The multiplicity path calls some of those
again to form a representative-fixed exact ideal. ODEPE's structural
classification calls **StructuralIdentifiability.jl** separately; its
`assess_local_identifiability` / `assess_identifiability` role must not be
conflated with the SIAN jet builder.

This is a broad internal API dependency rather than one callable fit. A narrow
local replacement would need to reproduce ring identity, jet ordering,
denominator handling, exact sampling, rank decisions, and multiplicity
construction. A pure adapter around those SIAN calls would still require SIAN
and would not solve the user's update problem. A copied implementation would
also need its own tests and maintenance. SIAN is MIT licensed; copied code
would retain the upstream notice.

The local SIAN checkout `2f78ca8` reports version 1.8.0 and changes only
`Project.toml`: it widens Nemo to 0.56 and OrderedCollections to 2. Its fetched
upstream `origin/main` at `deab355` (2026-09-24) reports 1.8.1 and describes a
weighted-monomial-order default change. These two branches need a behavioral
comparison before treating their versions as interchangeable. The historical
registered-stack pass used older, compatible Nemo and OrderedCollections
versions; it does not prove the newer stack or this split commit.

The fresh environment resolved during this split selects registered SIAN
1.8.1, GaussianProcesses 0.12.6, StructuralIdentifiability 0.5.25, Nemo 0.54.2,
Optim 1.13.3, and OrderedCollections 1.8.2. This confirms that a registered
solution exists, at the cost of selecting older dependency families. That
environment's full suite subsequently passed 2,058/2,058 assertions on Julia
1.13.1; the [registry checklist](registry_preparation.md) links the exact source
commit, versions, and logs. The supported-Julia matrix and registered recovery
benchmark remain release gates.

**Decision rationale:** Do not internalize SIAN for the first release. The
local patch is a two-line compatibility expansion, while a faithful internal
implementation would be a substantial algebraic subsystem. First seek an
upstream registered release with compatible bounds and compare the weighted
ordering behavior on representative templates. If upstream support stalls and
registered dependency resolution blocks the release, reassess a maintained
fork versus an internal jet-builder module using exact equation, variable-role,
structural-fix, multiplicity, candidate-recovery, and construction-time
contracts. The existing `test_si_*`, fast-core, and recovery gates are the
minimum behavioral baseline.

## Release gate for either decision to change

1. Record the exact registered GP/SIAN/StructuralIdentifiability, Nemo,
   Optim, and OrderedCollections versions selected in a clean environment.
2. Run `test/registered.jl`, the full and benchmark `Pkg.test` gates on the
   release commit, and the supported Julia CI matrix. Resolve any failure
   before claiming reproducibility.
3. For GP removal, compare full estimator outputs on identical frozen model
   data; keep cases where either route wins. For SIAN replacement, compare
   exact symbolic templates and multiplicity before comparing final estimates.
