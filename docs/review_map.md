# ODEParameterEstimation Review Map

> **⚠️ STALE (flagged 2026-07-21, still true 2026-08-13).** This map's snapshot
> predates: the src/research/ + deprecated/ reorg, the SI-template/noise-frontier
> default flow, RunContext, the 2026-07/08 fix-class arcs, and the current gate
> tiers. Until rewritten, use instead: `docs/2026-07-21_code_review_findings.md`
> (verified review findings), `repro/hc_threading_mwe_2026_07_22/ADJUDICATION_*`
> (audit method), and the gates — `test/fast_unit.jl` (contract tier, seconds),
> `test/fast_core.jl` (~6 min), full `test/runtests.jl` (~15 min, the merge bar).

**Status:** STALE — historical coordination map; do not assign review lanes from it.
**Snapshot date:** 2026-05-29.
**Audience:** AI reviewers first, maintainers second.

This document is the entry point for code review coordination. It classifies
the repo surface, gives agents review lanes, records current known hazards, and
defines the handoff format expected from each reviewer.

## Reviewer Quick Start

- Always run Julia with `--startup-file=no`.
- Use the global Julia environment for this repo: plain `julia`, not
  `julia --project`.
- Treat this file as current coordination truth. Dated files under `docs/`
  are historical evidence unless they are explicitly referenced here.
- Do not clean or overwrite unrelated dirty files in `artifacts/` or `repro/`.
- Start every review by reporting the lane, files inspected, commands run, and
  residual risk.

Primary commands:

```sh
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/runtests.jl")'
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/fast_core.jl")'
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/feature_regressions.jl")'
julia --startup-file=no -e 'using ODEParameterEstimation; include("src/examples/run_examples.jl")'
```

Current caveat: `fast_core.jl` is not a sub-minute quiet unit gate. During the
2026-05-29 planning pass it ran for several minutes, emitted pages of expected
diagnostic noise, and was stopped. Prefer targeted lane tests until a quieter
first-line gate exists.

## Current Health Snapshot

These facts are intentionally time-sensitive. Reverify before treating them as
current blockers.

| Area | Current fact |
|---|---|
| Worktree | Dirty paths existed under `artifacts/diagnostics/forced_decay_polynomialized/` and untracked `repro/receptor_*` scratch directories. Do not revert or prune without explicit owner approval. |
| Active CI entry | `.github/workflows/CI.yml` uses `julia-actions/julia-runtest`, which runs `test/runtests.jl`. |
| Active test includes | `test/runtests.jl` includes `fast_core.jl`, `example_canaries.jl`, `examples_smoke.jl`, `identifiability_regressions.jl`, `result_processing_helpers.jl`, `feature_regressions.jl`, and `test_shade_lm.jl`. |
| Orphaned unit test | `test/column_scaling.jl` passed locally: 12 tests in about 0.9s. It is not included by `test/runtests.jl`. |
| Red orphaned unit test | `test/test_core_types.jl` failed locally: 33 passed, 1 failed, 1 errored. Failures included a stale `data_sample === data_dict` identity expectation and `DerivativeData` Symbol-to-Num constructor drift. |
| Option bridge risk | `EstimationOptions.use_column_scaling` defaults to `true`, but `solve_with_hc_parameterized` reads `get(options, :use_column_scaling, false)` if the dict bridge omits the key. |
| Package load | A simple reflection load is nontrivial because default package load includes examples, diagnostics, and research/benchmark files. |
| Empty catches | Many bare `catch` blocks exist in `src/`; consensus/finalizer paths include silent candidate skips. Reviewers should check `InterruptException` handling on long loops. |

## Architecture Inventory

Line counts are from `wc -l` on 2026-05-29. Classification is for review
coordination, not a public API guarantee.

| File | LOC | Review class | Notes |
|---|---:|---|---|
| `src/ODEParameterEstimation.jl` | 243 | Front door/API | Main module, includes, exports, precompile workload. |
| `src/types/core_types.jl` | 1241 | Types/config | Result, diagnostic, consensus, report, and template types. |
| `src/types/estimation_options.jl` | 1508 | Types/config | `EstimationOptions`, enums, validation, option bridge. |
| `src/core/analysis_utils.jl` | 1163 | Production core | Top-level analysis, result processing policy. |
| `src/core/benchmark_sweeps.jl` | 2754 | Research/benchmark | Bilby sweeps, tryhard finalist research, artifact rendering. |
| `src/core/block_consensus_v2.jl` | 1288 | Research/benchmark | Block consensus strategy. |
| `src/core/branch_completion.jl` | 463 | Production core | Branch completion/rescue support. |
| `src/core/branch_consensus_v1.jl` | 1191 | Research/benchmark | Branch consensus strategy. |
| `src/core/consensus_estimation.jl` | 1180 | Research/benchmark | Family consensus research path. |
| `src/core/consensus_reporting.jl` | 719 | Research/benchmark | Consensus reports and markdown rendering. |
| `src/core/derivative_utils.jl` | 85 | Production core | Derivative utility helpers. |
| `src/core/derivatives.jl` | 1949 | Production core | Interpolators and derivative approximation. |
| `src/core/diagnostics.jl` | 5460 | Diagnostics | Diagnostic analysis, UQ sidecar, HTML/text report rendering. |
| `src/core/homotopy_continuation.jl` | 1316 | Solver core | HC conversion, parameterized solve, scaling bridge. |
| `src/core/logging_utils.jl` | 90 | Production core | Logging helpers. |
| `src/core/math_utils.jl` | 143 | Production core | Polynomial/math helpers. |
| `src/core/model_utils.jl` | 74 | Production core | Ordered model construction helpers. |
| `src/core/multipoint_template.jl` | 1569 | Solver core | Multipoint template build/evaluate/solve. |
| `src/core/optimized_multishot_estimation.jl` | 2587 | Production core | Main SI-template estimation pipeline. |
| `src/core/parameter_estimation.jl` | 2835 | Production core | Interpolants, polishing, clustering, local solve helpers. |
| `src/core/parameter_estimation_helpers.jl` | 1036 | Production core | Identifiability setup and result compatibility helpers. |
| `src/core/pointpicker.jl` | 185 | Production core | Shooting/support point selection. |
| `src/core/polish_residual.jl` | 361 | Production core | Residual polish objective and timeout support. |
| `src/core/robust_conversion.jl` | 4 | Production core | Placeholder/include stub. |
| `src/core/sampling.jl` | 210 | Production core | Sample data generation/noise. |
| `src/core/sensitivity_seeds.jl` | 538 | Production core | Sensitivity-aware seed generation. |
| `src/core/si_equation_builder.jl` | 1328 | Solver core | SI/SIAN polynomial system construction. |
| `src/core/si_template_integration.jl` | 718 | Solver core | SI template instantiation and state resolve. |
| `src/core/sigma_d.jl` | 217 | Production core | Derivative uncertainty helper. |
| `src/core/solve_with_robust.jl` | 391 | Solver core | Robust nonlinear solve fallback. |
| `src/core/svg_plots.jl` | 966 | Diagnostics | SVG plot/report support. |
| `src/core/synthesize_aggregates.jl` | 856 | Production core | Synthesized aggregate candidate generation. |
| `src/core/synthesized_finalizer.jl` | 801 | Research/benchmark | Synthesized finalizer research path. |
| `src/core/transcendental_utils.jl` | 941 | Production core | Transcendental model transformation. |
| `src/core/uncertainty_quantification.jl` | 1311 | Diagnostics | Experimental UQ implementation. |
| `src/baselines/shade_lm.jl` | 247 | Baseline | SHADE plus LM baseline estimator. |
| `src/diagnostics/analytical_branch_oracle.jl` | 682 | Diagnostics/research | Analytical branch oracle script/module. |
| `src/examples/load_examples.jl` | 288 | Examples | Included by default package front door. |
| `src/petab_loader.jl` | 11 | Extension/legacy | Potential duplicate/legacy PEtab loader surface. |
| `src/untestedlinter.jl` | 79 | Tooling | Included before types. |

### Extension Inventory

| File | LOC | Review class | Notes |
|---|---:|---|---|
| `ext/ODEParameterEstimationPEtabExt.jl` | 14 | Extension | PEtab extension root; exports PEtab load/convert/validate names. |
| `ext/ODEParameterEstimationPEtabExt/src/petab/convert_petab.jl` | 202 | Extension | PEtab conversion. |
| `ext/ODEParameterEstimationPEtabExt/src/petab/loader.jl` | 19 | Extension | PEtab loading. |
| `ext/ODEParameterEstimationPEtabExt/src/petab/petab-runner.jl` | 163 | Extension | PEtab runner. |
| `ext/ODEParameterEstimationPEtabExt/src/petab/validate_petab.jl` | 144 | Extension | PEtab validation; note include path should be checked. |
| `ext/ODEParameterEstimationRSExt/ODEParameterEstimationRSExt.jl` | 47 | Extension | RS/RUR extension root; mutates main module exports in `__init__`. |
| `ext/ODEParameterEstimationRSExt/homotopy_continuation_rs.jl` | 469 | Extension | RS solver implementation. |
| `ext/ODEParameterEstimationRSExt/optimized_multishot_rs.jl` | 131 | Extension | RS integration pieces. |
| `ext/ODEParameterEstimationRSExt/robust_conversion_rs.jl` | 453 | Extension | RS robust conversion. |

### Examples And Support Inventory

| Area | Review class | Notes |
|---|---|---|
| `src/examples/load_examples.jl` | Examples/API surface | Loads model registries and is included by the package front door. |
| `src/examples/models/*.jl` | Examples/API surface | Example model definitions exported from the main module. |
| `src/examples/control_investigations/` | Examples/research | Control-system investigation scripts and README. |
| `src/examples/benchmarks/` | Benchmark scratch | Benchmark scripts and saved text results; do not treat as active CI. |
| `src/examples/biohydrogenation/` | Example/research | Biohydrogenation example, data, and historical diagnostics. |
| `src/examples/cstr_adiabatic/` | Example/research | CSTR scripts and model probes. |
| `src/examples/failing/` | Failure corpus | Intentionally hard/failing cases and logs. |
| `src/examples/hiv_identifiability_test/` | Example/research | HIV-specific probes. |
| `src/examples/petab/` | Example/extension | PEtab example runner and docs. |
| `src/examples/profiling/` | Profiling | Allocation/profile scripts and shell helper. |
| Top-level `src/examples/*.jl` | Examples/research | Mixed runnable examples, demos, probes, and comparison scripts. |
| `CLAUDE.md` | Agent guidance | Canonical agent instructions. |
| `AGENTS.md` | Agent guidance | Mirror of `CLAUDE.md` for non-Claude agents. |
| `MULTIPLICITY_INTEGRATION.md` | Active integration note | Multiplicity integration details. |
| `TODO` | Planning scratch | Long-lived technical TODOs and research notes. |

## Public Surface Inventory

The main module exports many symbols from `src/ODEParameterEstimation.jl`.
Reviewers should classify changes as stable, experimental, research, or
examples before changing names/defaults.

| Group | Current exported surface |
|---|---|
| Core types | `OrderedODESystem`, `ParameterEstimationProblem`, `ParameterEstimationResult`, `ResultProvenance`, `NumericalIdentifiabilityAdvisory`, `DerivativeData`, error types, derivative-order constants. |
| Core constants | `package_wide_default_ode_solver`, clustering/error thresholds, solution caps. |
| Estimation entrypoints | `analyze_parameter_estimation_problem`, `optimized_multishot_parameter_estimation`, `direct_optimization_parameter_estimation`, `solve_with_hc`, `solve_with_robust`, baseline `shade_lm_estimate`. |
| Utilities | Model construction, sampling/noise helpers, result analysis, clustering, polynomial helpers, logging helpers, derivative utilities, compatibility helpers. |
| Interpolators | AAA/AAAD, GP, FHD, Chebyshev, Fourier, robust GP, S2/S3 adaptive and BIC variants, deprecated S3 names, custom interpolator hooks. |
| Solver helpers | HC parameterized solve/conversion, multipoint templates and solves, support-point selection. |
| Diagnostics/UQ | `diagnose*`, diagnostic report types, error budget/spread helpers, UQ covariance and print helpers. |
| Research consensus | `ConsensusOptions`, `SynthesizedFinalizerOptions`, `BranchConsensusOptions`, `BlockConsensusOptions`, `TryhardFinalistOptions`, report/evidence types, and `research_*` entrypoints. |
| Examples | `simple`, `lotka_volterra`, `biohydrogenation`, `daisy_mamil*`, branch-stress examples, receptor examples, and other example models. |
| Config enums/options | `EstimationOptions`, solver/interpolator/polish/flow enums, option resolution and validation helpers. |
| Extension exports | PEtab extension exports `load_model`, `load_petab_model`, `convert_petab_model`, `validate_petab_model`; RS extension injects `solve_with_rs*`, conversion helpers, and RUR helpers into the main module when loaded. |

Option counts from reflection on 2026-05-29:

| Type | Field count |
|---|---:|
| `EstimationOptions` | 118 |
| `ConsensusOptions` | 9 |
| `SynthesizedFinalizerOptions` | 10 |
| `BranchConsensusOptions` | 18 |
| `BlockConsensusOptions` | 10 |
| `TryhardFinalistOptions` | 16 |

## Test Inventory

| File/group | LOC | Current lane | Notes |
|---|---:|---|---|
| `test/runtests.jl` | 12 | Active CI | Default package test entry. |
| `test/runtests_extended.jl` | 8 | Extended | Includes active CI suite plus extended regressions and examples. |
| `test/runtests_legacy.jl` | 700 | Orphaned/legacy | Includes older utility/UQ tests; not active CI. |
| `test/fast_core.jl` | 2069 | Active CI, noisy | Broad contracts plus research/report fixtures; not a true fast unit gate. |
| `test/feature_regressions.jl` | 738 | Active CI | Feature regressions, includes solver and interpolation paths. |
| `test/example_canaries.jl` | 188 | Active CI | Example-level canaries. |
| `test/examples_smoke.jl` | 57 | Active CI | Example script smoke tests. |
| `test/identifiability_regressions.jl` | 75 | Active CI | Identifiability regressions. |
| `test/result_processing_helpers.jl` | 228 | Active CI | Result processing helper tests. |
| `test/test_shade_lm.jl` | 107 | Active CI | Baseline estimator tests. |
| `test/column_scaling.jl` | 57 | Orphaned unit | Fast helper tests; passed locally but not included by CI. |
| `test/test_core_types.jl` | 173 | Orphaned unit, red | Stale type/constructor tests; failed locally. |
| `test/test_model_utils.jl`, `test/test_math_utils.jl`, `test/test_derivative_utils.jl` | 287 total | Orphaned unit | Included by legacy runner only. |
| `test/test_uncertainty_quantification.jl` | 995 | Orphaned/slow | Large UQ suite; included by legacy runner only. |
| `test/test_multipoint*.jl`, `test/test_point_selection.jl`, `test/test_agp_interpolator.jl`, `test/test_gp_kernel_optimization.jl`, `test/test_cross_*` | 1208 total | Orphaned/specialized | Targeted subsystem tests, not active CI unless included indirectly. |
| `test/generate_*.jl`, `test/render_*.jl`, audit scripts | large | Generator/research | Many write into `artifacts/diagnostics`; run only intentionally. |
| `test/polynomialized_tests/` | data/results | Research artifacts | Contains result documents plus a runner. |

### Recommended Review Gates By Lane

| Lane | Minimum gate |
|---|---|
| Docs/review map only | Link/path checks; no Julia suite required. |
| Types/options | `test/test_core_types.jl` after fixing rot, targeted `validate_options` checks, `test/column_scaling.jl` if option bridge touched. |
| HC/solver core | `test/column_scaling.jl`, targeted HC/multipoint tests, then `feature_regressions.jl`. |
| Estimation pipeline | Relevant `example_canaries.jl`, `identifiability_regressions.jl`, and `feature_regressions.jl`. |
| Diagnostics/UQ | Targeted diagnostics/UQ files; avoid artifact-writing generators unless explicitly requested. |
| Research consensus/benchmarks | Relevant `fast_core.jl` testsets and `test/generate_*` scripts only with explicit artifact-output expectations. |
| Extensions | Load extension dependencies explicitly; main CI may not cover weakdeps. |

## Review Lanes

Use these lanes for multi-agent assignment. Agents may inspect adjacent code, but
the handoff should stay lane-scoped.

| Lane | Primary files | Review focus | High-risk questions |
|---|---|---|---|
| Front Door/API | `src/ODEParameterEstimation.jl`, README, docs | Includes, exports, package load cost, stable vs research surface | What is loaded/exported by default? What should be stable? |
| Config/Options | `src/types/estimation_options.jl`, `src/types/core_types.jl` | Defaults, validation, option bridges, public enum compatibility | Do struct defaults match lower-level dict defaults? Which knobs are deprecated? |
| Solver/HC | `homotopy_continuation.jl`, `multipoint_template.jl`, SI template files | Polynomial systems, scaling, parameter homotopy, multipoint solves | Are numerical switches deterministic and tested? |
| Estimation Pipeline | `optimized_multishot_estimation.jl`, `parameter_estimation*.jl`, `analysis_utils.jl` | Main flow, candidate generation, polishing, clustering, result contract | Can failures be traced through provenance? |
| Results/Provenance | `core_types.jl`, result processing helpers, analysis utilities | Result shape, lineage, compatibility fields, benchmark contract | Are rescue/completion paths visible in results? |
| Diagnostics/UQ | `diagnostics.jl`, `uncertainty_quantification.jl`, `svg_plots.jl` | Report correctness, optional sidecars, artifact writes, UQ failure policy | Which failures are non-fatal and why? |
| Research Consensus | `consensus_*`, `branch_consensus_*`, `block_consensus_*`, `benchmark_sweeps.jl`, `synthesized_finalizer.jl` | Research strategies, benchmark rendering, silent skips, artifact shape | Are candidate drops visible? Are interrupts swallowed? |
| Extensions/Examples | `ext/`, `src/examples/`, `src/petab_loader.jl` | Weakdeps, example import side effects, duplicate PEtab paths | Does package load require examples? Are extension paths valid? |
| Tests/CI/Artifacts | `test/`, `.github/`, `.gitignore` | Active vs orphaned tests, artifact-writing scripts, quiet gates | What protects a refactor in under a minute? |

## Known Review Traps

- `src/ODEParameterEstimation.jl` includes `examples/load_examples.jl` by
  default, so example model exports are part of package load today.
- Research/benchmark consensus files live under `src/core/` and are exported
  from the main module, so file location alone does not identify production
  code.
- `EstimationOptions` is a large public struct. Removing or renaming fields is
  an API change unless explicitly deprecated.
- Deprecated S3 interpolator names still forward to supported methods and are
  exported.
- Empty `catch` blocks are common. Long loops should rethrow
  `InterruptException` and leave an observable failure record.
- Many tests and generators write under `artifacts/diagnostics`. Do not treat a
  changed artifact as a package-code change without checking the command that
  produced it.
- `CLAUDE.md` and `AGENTS.md` mirror each other, but `CLAUDE.md` is canonical.
- Some agent guidance can drift from code. For example, verify constants in
  source before relying on copied instruction text.
- The RS extension mutates the main module in `__init__`; ordinary export
  searches in the main module do not show the whole loaded surface.
- PEtab extension and `src/petab_loader.jl` should be reviewed together before
  changing PEtab behavior.

## Refresh Commands

Run these when updating this map:

```sh
git status --short
find src ext test docs .github -maxdepth 5 -type f | sort
wc -l src/ODEParameterEstimation.jl src/core/*.jl src/types/*.jl src/baselines/*.jl src/diagnostics/*.jl src/examples/load_examples.jl src/petab_loader.jl src/untestedlinter.jl ext/ODEParameterEstimationPEtabExt.jl ext/ODEParameterEstimationPEtabExt/src/petab/*.jl ext/ODEParameterEstimationRSExt/*.jl test/*.jl .github/workflows/*.yml Project.toml
rg -n "^export\\b|include\\(" src/ODEParameterEstimation.jl ext src/core src/types src/baselines src/diagnostics test/runtests*.jl .github/workflows/CI.yml
rg -n "@testset|include\\(" test .github
rg -n "catch\\s*$|InterruptException|rethrow" src test -g '*.jl'
julia --startup-file=no -e 'using ODEParameterEstimation; for T in (EstimationOptions, ConsensusOptions, SynthesizedFinalizerOptions, BranchConsensusOptions, BlockConsensusOptions, TryhardFinalistOptions); println(string(T, " fields=", length(fieldnames(T)))); end'
```

Cheap health probes:

```sh
julia --startup-file=no -e 'using ODEParameterEstimation, Test; include("test/column_scaling.jl")'
julia --startup-file=no -e 'using ODEParameterEstimation, Test; include("test/test_core_types.jl")'
```

Do not run generator scripts or full benchmark sweeps just to refresh this map.

## Reviewer Handoff Template

Each reviewer should return:

```md
## Lane
<lane name>

## Files inspected
- path: reason

## Commands run
- command: pass/fail/notes

## Findings
1. Severity: file:line - concise issue and impact

## Residual risk
- What was not checked and why

## Suggested next tests or changes
- Concrete follow-up
```

Findings should lead with bugs, regressions, missing tests, silent failure
paths, and API contract drift. Summaries and refactor suggestions should follow
after evidence.
