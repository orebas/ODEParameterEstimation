# ODEParameterEstimation review map

Updated 2026-09-14. This is the entry point for reviewing the current source
layout and test coverage. Dependency versions, measured gate results, and
release blockers live in [Production readiness](2026-09-10_production_readiness.md).
The [May coordination map](2026-05-29_review_map.md) is retained as history;
its line counts, open findings, and test classifications are obsolete.

The [dense single-experiment record](2026-09-11_dense_single_experiments.md)
contains current Bruno recovery evidence and focused Fujita/Sneyd performance
profiles using the normal benchmark workflow and existing timing infrastructure.
The [deferred denominator construction record](2026-09-11_deferred_denominator_construction.md)
documents rational rank/support tables, delayed PEtab polynomial construction,
and the rational benchmark validation.
The [reusable polynomial polishing record](2026-09-13_reusable_polynomial_polishing.md)
documents compilation reuse, the Jacobian comparison, and the completed
biohydrogenation run with normal compiler settings.
The [September 14 dense follow-up](2026-09-14_dense_single_followup.md)
records Sneyd's completed rank construction and later global-SI bottleneck,
plus exact Fujita elimination and bounded mixed-volume/path-tracking probes.
The [SI cost and longer mixed-volume investigation](2026-09-14_identifiability_cost_and_mixed_volume.md)
supersedes its solver recommendation, measures the cheaper local SI request,
and separates classification from representative selection. The
[baseline algorithm audit](2026-09-14_baseline_algorithm_changes.md) records all
core and optional-extension behavior changes since the prior August baseline.
The [local-SI implementation record](2026-09-14_local_si_basis.md) documents
the new default structural-fixing request and its validation. Its
[multiplicity correction follow-up](2026-09-14_fixed_multiplicity.md) applies
representative assignments before Gröbner and checks the resulting input.
The [coefficient-lifting trial](2026-09-15_coefficient_lifting.md) adds an
opt-in PEtab source extractor and an equivalent frozen-input experiment;
it is not a change to the default estimator or multiplicity algorithm.

## Start here

Read the canonical instructions in [`CLAUDE.md`](../CLAUDE.md). Use Julia with
`--startup-file=no` from the global environment. Develop this checkout there,
then run:

```sh
julia --startup-file=no test/current.jl unit
julia --startup-file=no test/current.jl
julia --startup-file=no test/current.jl benchmark
```

These commands use `Pkg.test(...; allow_reresolve=false)`: test dependencies
are isolated, while the active dependency versions and development checkouts
are retained. A dependency conflict fails visibly. The full suite is the gate
for estimation changes; the benchmark is also required before a cluster handoff.
`test/registered.jl` separately resolves a fresh registry environment and may
select older versions until upstream compatibility releases are available.

Preserve unrelated files and diagnostic artifacts. Do not run generators or
large research campaigns merely to refresh this map. Reproduce dated review
findings before treating them as open bugs: the July report predates fixes to
bounds validation, cache keys, interrupt propagation, and run context.

## Source and review responsibilities

Paths below are relative to `src/`.

| Area | Entry points | Review focus |
|---|---|---|
| Package/API | `ODEParameterEstimation.jl`, `types/core_types.jl`, `types/estimation_options.jl` | Constructors, exported names, option validation, precompilation, dependency bridges. |
| Estimation | `core/analysis_utils.jl`, `core/optimized_multishot_estimation.jl`, `core/parameter_estimation.jl`, `core/parameter_estimation_helpers.jl` | Candidate generation, fit-based ranking, clustering, returned result/provenance contract. |
| Symbolic construction | `core/si_equation_builder.jl`, `core/si_template_integration.jl`, `core/noise_frontier_construction.jl`, `core/transcendental_utils.jl` | Structural identifiability, symbolic substitutions, equation/variable order, supported model classes. |
| Polynomial solves | `core/homotopy_continuation.jl`, `core/multipoint_template.jl`, `core/robust_system.jl`, `core/solve_with_robust.jl` | Root completeness, parameter homotopy, scaling, direct/parameterized agreement, reusable residual/Jacobian kernels. Read the multiplicity note before changing root retention. |
| Sampling/interpolation | `core/sampling.jl`, `core/derivatives.jl`, `core/pointpicker.jl`, `core/derivative_utils.jl` | Observable identity, noise semantics, derivative accuracy and order limits, point selection. |
| Rescaling/polish | `core/problem_rescaling.jl`, `core/polish_residual.jl`, `core/branch_completion.jl`, `core/sensitivity_seeds.jl` | Units and inverse mapping, timeouts, branch lineage, bounded optimization. |
| Diagnostics/UQ | `core/diagnostics/*.jl`, `core/uncertainty_quantification.jl`, `core/sigma_d.jl`, `core/svg_plots.jl` | Exact returned estimator, covariance propagation, reliability axes, report/artifact correctness. Read the current UQ notes linked by `CLAUDE.md` first. |
| Research | `research/*.jl` | Consensus/sweeps and opt-in correction; these remain loaded/exported but are outside the default estimation pipeline. |
| Baseline/examples | `baselines/shade_lm.jl`, `examples/load_examples.jl`, `examples/models/*.jl` | Recovery comparisons and public example constructors. Other example scripts include historical investigations. |
| Optional integrations | `../ext/` | The PEtab pilot lives in `ext/petab/` with separate contracts in `test/petab/`; see `docs/petab.md` and the dated pilot record for its limits. The older nested PEtab scripts are not loaded. RS/RUR remains deferred. |
| Tests/CI | `../test/`, `../.github/workflows/CI.yml` | Declared imports, dependency version preservation, isolated namespaces/artifacts, substantive assertions. |

## Active test coverage

The authoritative full-suite list is [`test/runtests.jl`](../test/runtests.jl).
Each file receives a fixed RNG seed, a separate module, and a temporary working
directory. A file error is recorded without preventing the remaining files
from running. The unit group is assembled in
[`test/fast_unit.jl`](../test/fast_unit.jl).

| Coverage | Representative active files |
|---|---|
| Public types/options/utilities | `test_core_types.jl`, `test_model_utils.jl`, `test_math_utils.jl`, `test_derivative_utils.jl`, `test_solution_distance.jl`, `test_options_contracts.jl` |
| Dependency interoperability | `dependency_compat.jl`, `test_noise_rank_matrix.jl`, `test_gp_kernel_optimization.jl` |
| Deferred denominator construction | `test_deferred_derivatives.jl`; optional eager/deferred rational basis and pole contracts in `test/petab/runtests.jl` |
| Estimation and examples | `fast_core.jl`, `refactor_safety_net.jl`, `feature_regressions.jl`, `example_canaries.jl`, `examples_smoke.jl`, `identifiability_regressions.jl` |
| Scaling/HC/polish | `test_rescaling.jl`, `column_scaling.jl`, `test_hc_sanitize.jl`, `test_robust_system.jl`, `test_polish_maxtime.jl`, `test_shade_lm.jl` |
| State and result contracts | `test_run_context.jl`, `test_interrupt_propagation.jl`, `result_processing_helpers.jl`, `test_label_parsers.jl` |
| Independent grids and preparation | `test_observation_data.jl`; optional joint PEtab mapping and likelihood contracts in `test/petab/runtests.jl` |
| Multipoint/UQ/campaigns | `test_multipoint_pipeline.jl`, `test_multipoint_sensitivity.jl`, `test_estimator_aware_uq.jl`, `test_polish_uq_pipeline.jl`, `test_branch_uq_pipeline.jl`, covariance/IFT/campaign contract files in the runner |
| Recovery benchmark | `benchmark_smoke.jl`, selected with the `benchmark` group; separate from the default full suite |

Files outside the runner are not implicitly passing tests. In particular:

- `test_point_selection.jl` is a strategy comparison script with no assertions.
- `test_multipoint_estimation.jl` uses stale constructor arguments;
  `test_multipoint_template.jl` and `test_multipoint_homotopy.jl` are older,
  separate model experiments. The active multipoint pipeline and sensitivity
  suites are the current production gates.
- `test_solve_with_rs.jl` requires the unfinished optional RS/RUR integration.
- `generate_*`, `render_*`, audit scripts, `runtests_legacy.jl`, and
  `runtests_extended.jl` are opt-in research or historical entry points.

## Review handoff

Lead with reproduced defects and their impact. For each finding, identify the
source path, trigger, and supporting test or probe. State exactly which gate
ran, its dependency environment, and any remaining limits. A passing unit test
is not a full estimation gate; recovery success is not an uncertainty coverage
certificate. Do not reinterpret historical benchmark or UQ results as evidence
for a changed estimator.

The [September 11 experiment-block trial](2026-09-11_petab_experiment_blocks.md)
adds bounded condition groups, shared-parameter classification without truth
values, and retained public runs. Its new equations use local observation jets
and joint multipoint rank selection; no new structural-identifiability or UQ
certificate is claimed. The readiness note records existing Julia 1.12/nightly
CI failures separately from the passing Julia 1.13 validation.
