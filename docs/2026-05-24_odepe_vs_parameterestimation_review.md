# ODEPE as a Successor to ParameterEstimation.jl

Date: 2026-05-24

Baseline compared here:

- `ParameterEstimation.jl` public repository:
  `https://github.com/iliailmer/ParameterEstimation.jl`, commit
  `fb9e97b20654bb42292a2e0986d42c034cd5ef33`, version `0.4.4`.
- `ODEParameterEstimation.jl` working repository:
  commit `6ffc6cb54ff42d9afad638e6e9b43f3615f3e233`, plus current local
  worktree notes where explicitly called out.

This document is deliberately evidence-labeled. Some claims are directly
visible in source, some are documented in dated repo notes, and some are
supported by internal benchmark artifacts rather than by a single public
paper-quality table.

Evidence labels used below:

- **Verified in code**: checked in source files.
- **Documented in repo**: supported by repo documentation or handoff notes.
- **Supported by benchmark artifacts**: supported by `repro/`, `artifacts/`,
  or benchmark-analysis notes.
- **Engineering rationale**: reasoned design claim; useful, but not by itself
  a benchmark result.
- **Open / future work**: known limitation or investigation.

## Overview

`ParameterEstimation.jl` and `ODEParameterEstimation.jl` share a central
scientific idea: estimate parameters and initial conditions for ODE models by
turning observed trajectories into algebraic constraints. The original package
was a compact implementation of a symbolic-numeric method: run structural
identifiability analysis, interpolate the measured time series, substitute
observable derivatives into a polynomial system, solve that system, and rank
the resulting candidates by how well they simulate the measured data.

ODEPE keeps that intellectual core but changes the package's center of gravity.
It is no longer just "run the algebraic method on one interpolated system."
It is a larger estimation workbench around that method: a structured problem
type, explicit options, modern SciML integration, multiple solver flows,
template-based SI reuse, multi-shot and multipoint candidate generation,
solution polishing, provenance, diagnostics, PEtab import experiments,
benchmark contracts, and a growing body of failure-mode documentation.

The main upgrade is not one trick. It is operationalization. ODEPE takes the
original method from a promising symbolic-numeric prototype toward a package
that can be run repeatedly on large benchmark suites, audited after failures,
and adapted to difficult model classes without losing track of where a
candidate came from.

## What Stayed the Same

### The Core Algebraic Strategy

**Verified in code.** `ParameterEstimation.jl` exposes:

- `estimate(model, measured_quantities, data_sample; ...)`
- `check_identifiability(...)`
- `filter_solutions(...)`
- `EstimationResult`

The old default estimator runs an identifiability step, loops over a default
interpolator set, solves the resulting polynomial system with
HomotopyContinuation, simulates each candidate with an ODE solver, computes a
data-fit error, clusters/deduplicates, and returns sorted `EstimationResult`
objects. See the public baseline repository files:

- `src/estimation/estimate.jl`
- `src/estimation/serial.jl`
- `src/estimation/fixed_degree.jl`
- `src/estimation/solve.jl`
- `src/filtering.jl`

ODEPE's standard flow is still recognizably this family of methods: symbolic
setup, interpolation-derived derivative values, polynomial solving, ODE
backsolve/error computation, and candidate ranking. The successor package did
not abandon the original theory; it rebuilt the surrounding engineering.

### SIAN / Structural Identifiability as a Front End

**Verified in code.** The old package calls SIAN-derived identifiability
machinery through `check_identifiability` and stores an `IdentifiabilityData`
object. ODEPE still uses SIAN / StructuralIdentifiability, but the integration
is now more explicit and layered:

- `src/core/si_equation_builder.jl`
- `src/core/si_template_integration.jl`
- `src/core/optimized_multishot_estimation.jl`

**Documented in repo.** The current README says the default path is the
SI-template-based standard flow and that structural identifiability comes from
`SI.jl` / `StructuralIdentifiability`.

## User-Facing API and Result Contract

### From Minimal Function Call to Structured Workflow

**Verified in code.** In `ParameterEstimation.jl`, the public surface is
small:

```julia
res = estimate(model, outs, data)
```

The old `EstimationResult` contains parameter values, state values, an
interpolation degree label, an error value, interpolants, a return code,
datasize, and report time.

ODEPE's main workflow is:

```julia
sampled = sample_problem_data(pep, opts)
raw_results, analysis, uq = analyze_parameter_estimation_problem(sampled, opts)
```

with first-class types:

- `ParameterEstimationProblem`
- `EstimationOptions`
- `ParameterEstimationResult`
- `ResultProvenance`
- `NumericalIdentifiabilityAdvisory`
- `DerivativeData`

**Documented in repo.** `docs/2026-03-17_results_and_api.md` records the
current return contract, including `raw_results`, `analysis`, and the optional
UQ side output.

**Engineering rationale.** This is an important upgrade for reproducibility.
The old API is convenient for a toy example. The new API makes the benchmark
and debugging contract explicit: raw candidates, analyzed candidates, summary
metrics, uncertainty side output, and provenance can be inspected separately.

### Provenance as a First-Class Result Field

**Verified in code.** ODEPE's `ResultProvenance` records:

- primary method (`:algebraic`, `:direct_opt`, etc.)
- interpolator source
- rescue path
- shooting-point origin
- candidate index
- pre/post polish errors
- structural and residual fix sets
- SI template status
- equation trimming metadata
- practical/numerical-identifiability advisory
- source type (`:single_point`, `:multipoint`, `:synthesized_aggregate`, ...)
- aggregation strategy and source indices
- polish source index

This is a major difference from the old `EstimationResult`, where the user
mostly sees values and an error.

**Engineering rationale.** Provenance matters because ODEPE now deliberately
combines many candidate sources. Without provenance, a good row and a bad row
can look equally mysterious. With provenance, one can ask whether a candidate
came from a single shooting point, a multipoint solve, an aggregate seed, a
direct optimization fallback, or a structural-fix path.

## Algorithmic Upgrades

### SI Template Reuse

**Verified in code.** The old package interpolates data and mutates an
identifiability-derived polynomial system for each interpolation run. ODEPE's
standard path builds an SI template once, then instantiates it at many data
points and under many interpolators.

Important files:

- `src/core/si_equation_builder.jl`
- `src/core/si_template_integration.jl`
- `src/core/optimized_multishot_estimation.jl`

**Engineering rationale.** Template reuse separates symbolic structure from
numeric data substitution. That makes multi-shot estimation, parameter
homotopy, provenance, and diagnostics easier to implement than in a pipeline
where every interpolator run owns its own one-off polynomial system.

### Structural Unidentifiability Handling

**Verified in code.** ODEPE carries explicit structural fix sets in
`ResultProvenance` and reports unidentifiable variables on
`ParameterEstimationResult`.

**Documented in repo.** `docs/2026-03-17_supported_models_and_limitations.md`
states that structurally unidentifiable models are supported, with structural
representative fixes recorded in provenance. Examples include
`trivial_unident`, `global_unident_test`, `substr_test`, and
`two_compartment_pk`.

**Upgrade over PE.** The old package had identifiability results and filtering
logic, but ODEPE makes the structural intervention part of the public result
lineage. That is a practical upgrade: the user can see which directions were
fixed as representatives rather than inferred uniquely.

### Multi-Shot Estimation

**Verified in code.** ODEPE's default `FlowStandard` is
`optimized_multishot_parameter_estimation`. Defaults include:

- `shooting_points = 12`
- `shooting_warp = true`
- `shooting_warp_beta = 3.0`
- `use_parameter_homotopy = true`

**Documented in repo.** `repro/oren_freshlook_2026_05_15/PIPELINE_MAP.md`
describes the current default pipeline as selecting 12 exponentially warped
time points and solving instantiated polynomial systems through HC.jl, with
parameter homotopy used when enabled.

**Upgrade over PE.** The old package defaults to a midpoint-like `at_time` and
loops over interpolators. ODEPE turns the time point itself into a candidate
generation axis. This is important because derivative quality and algebraic
conditioning vary dramatically across the observation interval.

### Multipoint Polynomial Templates

**Verified in code.** ODEPE includes `src/core/multipoint_template.jl` and
default options:

- `use_multipoint = true`
- `multipoint_n_points = 2`
- `multipoint_max_pairs = 20`

**Engineering rationale.** Single-time derivative constraints can be
over-sensitive to local interpolation error or local algebraic degeneracy.
Multipoint systems combine constraints across time points, which can reject
some spurious single-point roots and expose branch structure more reliably.

**Supported by benchmark artifacts.** The `experiments/multipoint/` and
`repro/multiplicity_complete_2026_05_19/` directories contain the working
record behind this line of development.

### Parameter Homotopy

**Verified in code.** ODEPE exposes `solve_with_hc_parameterized` and uses
parameter homotopy in the standard flow when enabled.

**Engineering rationale.** In a multi-shot setting, adjacent polynomial
systems differ mainly by substituted derivative/data values. Parameter
homotopy exploits that continuity instead of solving each instantiated system
as a completely unrelated problem.

### Solver Portfolio and Optional Extensions

**Verified in code.** Old `ParameterEstimation.jl` supports `:homotopy` and
has an `:msolve` path that is not implemented in the current public checkout.

ODEPE exposes:

- `SolverHC`
- `SolverRS` through optional extension
- `SolverNLOpt`
- `SolverFastNLOpt`
- `SolverRobust`
- direct optimization flow
- SHADE+LM baseline

The RS functionality is isolated in `ext/ODEParameterEstimationRSExt`, and
PEtab support is isolated in `ext/ODEParameterEstimationPEtabExt`.

**Upgrade over PE.** Solver backends are now explicit options rather than
ad hoc symbols. Optional heavyweight functionality can live in Julia package
extensions rather than forcing every user into every dependency path.

## Interpolation and Derivative Estimation

### Old Interpolator Set

**Verified in code.** The public `ParameterEstimation.jl` baseline defaults to
AAA and Floater-Hormann variants:

- `"AAA" => aaad`
- `"FHD3" => fhdn(3)`
- `"FHD8" => fhdn(8)` when `datasize > 10`

See the baseline repository's `src/rational_interpolation/bary_derivs.jl`.

### ODEPE Interpolator Portfolio

**Verified in code.** ODEPE has a much larger enum of interpolation methods:

- AAAD variants
- FHD
- robust GP interpolators
- rational quadratic and composite kernels
- S2 and S3 GP/AAA/MLE composites
- Chebyshev AICc/BIC
- Fourier adaptive
- UQ-oriented GP interpolation
- custom interpolator hook

The default `interpolators` vector currently includes robust GP variants,
S3 adaptive variants, Chebyshev variants, AAADGPR, AAAD, and S2AAAMLE.

**Supported by benchmark artifacts.** The dated interpolation notes record
why this portfolio is not simply "more is better." `docs/2026-05-06_interpolator_gating_spec.md`
documents observed cases where pure AAA/S2 and boundary spectral/FHD methods
can become catastrophic under noise or near interval boundaries.

### Noise-Based Interpolator Gating

**Verified in code.** ODEPE has `auto_filter_interpolators = true`, which
filters AAA-family methods by data-driven estimated noise before the
shooting-point loop.

**Upgrade over PE.** The old package uses a small default interpolator
portfolio without a first-class noise-gating policy. ODEPE's policy is still
heuristic, but it encodes an empirical lesson: candidate diversity helps only
when bad interpolators are not allowed to poison the pool indiscriminately.

## Polishing and Candidate Ranking

### From ODE Error Filtering to Residual-Mode Polish

**Verified in code.** Old PE computes an ODE simulation error after candidate
generation and sorts/filter clusters by that error. ODEPE keeps ODE-fit error
as a central signal but adds multiple polish stages:

- `polish_solver_solutions = true`: fast polish of raw solver solutions.
- `polish_method = PolishLSOBoundedLog`: bounded least-squares polish in
  transformed coordinates.
- `polish_softwall_lambda = 1e-2`, `polish_softwall_epsilon = 0.10`: soft-wall
  penalty near optimization bounds.
- `polish_maxtime = 3600.0` and bounded concurrency controls.

Important files:

- `src/core/polish_residual.jl`
- `src/core/parameter_estimation.jl`
- `src/types/estimation_options.jl`

**Supported by benchmark artifacts.** `repro/oren_freshlook_2026_05_15/` and
`repro/polish_regression_2026_05_19/FINDINGS.md` document the polishing and
ranking investigations, including cases where a heuristic helped one benchmark
distribution and hurt another.

**Important caution.** The current default `rank_strategy = :sat_neg1_err`
is not an unqualified improvement. The option comments say it favors coarse
paper-relevant thresholds but can hurt fine precision thresholds relative to
`:err_only`. The review should present this as a tradeoff learned from
benchmarks, not as a monotonic upgrade.

### Candidate Synthesis

**Verified in code.** ODEPE can synthesize aggregate candidates from existing
single-point and multipoint candidates:

- `synthesize_aggregate_candidates = true`
- median, mean, trimmed-mean, and weighted-median style aggregation
- provenance tags for aggregation strategy and source indices

**Engineering rationale.** This is a pragmatic layer on top of algebraic
solving. If multiple noisy candidates cluster around a basin, aggregation can
produce a better seed for local polish than any one raw candidate.

**Caution.** Aggregation is heuristic. It should be described as candidate
generation and polish seeding, not as new algebraic information.

## Branches, Multiplicity, and Output Size

### Algebraic Multiplicity

**Documented in repo.** `MULTIPLICITY_INTEGRATION.md` describes production
work to auto-compute algebraic multiplicity `M` during SI template build and
truncate returned candidates to `min(M, branch_top_k, length(cluster_reps))`.
The handoff says this was verified against 23 wallaby systems plus synthetic
cases.

**Verified in code / local worktree.** Current options include:

- `algebraic_multiplicity::Union{Int, Nothing} = nothing`
- `branch_top_k = 20`
- `branch_diversity_selection = true`
- `branch_diversity_eps = 0.01`

`src/core/analysis_utils.jl` contains branch-diverse representative selection
when `M > 1`.

**Upgrade over PE.** The old package returns whatever survives filtering and
clustering. ODEPE increasingly treats "how many branches should be visible?"
as part of the mathematical output contract.

### Branch Diversity

**Verified in code.** The current local worktree includes branch-diverse
selection at final truncation: when `algebraic_multiplicity` requests multiple
rows, ODEPE prefers representatives separated by a relative solution-distance
threshold before filling from rank order.

**Engineering rationale.** This is a user-experience upgrade for locally
identifiable systems. If a system has two algebraic branches, returning two
near-duplicates from one branch is less informative than returning one row from
each branch, provided both branches were found.

**Caution.** Diversity selection cannot invent a branch that was not generated
or survived earlier filtering.

## Diagnostics and Failure-Mode Literacy

### Diagnostic Surface

**Verified in code.** ODEPE exports diagnostic tools:

- `diagnose`
- `diagnose_model`
- `diagnose_derivative_accuracy`
- `diagnose_polynomial_system`
- `diagnose_sensitivity`
- uncertainty diagnostics
- error-budget reports
- cross-solution spread reports

Old PE has tests and filtering utilities but not an equivalent diagnostic
framework.

### Failure Taxonomy

**Documented in repo.** Current docs distinguish:

- supported polynomial/rational-style systems
- structurally unidentifiable but supported systems
- hard but valid systems
- unsupported raw transcendental classes
- high observable-derivative backend limits

See:

- `docs/2026-03-17_supported_models_and_limitations.md`
- `docs/2026-03-17_model_taxonomy.md`
- `docs/2026-03-17_high_order_si_derivative_limit.md`
- `TRANSCENDENTAL_FUNCTIONS_DESIGN.md`
- `docs/2026-05-01_variable_scaling_investigation.md`

**Upgrade over PE.** The original package is easier to summarize but harder to
debug when things go wrong. ODEPE has a more explicit support boundary: some
classes should succeed, some should fail early, and some are research stress
cases.

## Transcendentals and Inputs

**Documented in repo.** ODEPE has an explicit design record for handling
transcendental functions through auxiliary variables or known-input treatment.
The current standard path includes `auto_handle_transcendentals = true`.

**Verified in code.** `src/core/transcendental_utils.jl` is included in the
main module before SI template integration.

**Upgrade over PE.** The old package is primarily framed around rational ODEs.
ODEPE still relies on polynomial/rational algebra internally, but it has a
more explicit pathway for recognizing and transforming some differentially
algebraic time-dependent expressions.

**Open / future work.** This does not mean arbitrary transcendental state
dependence is solved. The supported-model docs still classify raw state
trigonometric dependence, raw `sqrt`, and unsupported transcendental state
dependence as expected early failures.

## Direct Optimization and Baselines

**Verified in code.** ODEPE has `FlowDirectOpt` and
`direct_optimization_parameter_estimation`, which bypass algebraic solving and
optimize the ODE trajectory fit directly. It also includes a SHADE+LM baseline
under `src/baselines/shade_lm.jl`.

**Upgrade over PE.** This makes ODEPE more useful as an experimental platform:
the algebraic method can be compared against direct optimization within the
same package vocabulary.

**Engineering rationale.** Direct optimization is not a replacement for the
symbolic-numeric method, but it is a useful terminal fallback and sanity check,
especially when algebraic candidate generation fails.

## PEtab and External Problem Sources

**Verified in code.** ODEPE has optional PEtab entry points:

- `load_petab_problem`
- `convert_petab_model`
- `validate_petab_model`

When PEtab is not loaded, these functions return clear optional-extension
errors. PEtab support lives under `ext/ODEParameterEstimationPEtabExt`.

**Documented in repo.** `docs/2026-05-21_petab_problem_sources.md` records the
first-pass PEtab source plan and intentionally narrow compatibility filter.

**Upgrade over PE.** This points ODEPE toward external benchmark ingestion.
The current PEtab importer is not a general PEtab implementation, but it is a
practical bridge to curated PEtab problem databases.

**Open / future work.** The importer is narrow by design: one YAML, one SBML
model, one simulation condition, no pre-equilibration, no condition-specific
overrides, complete observable-by-time grid, linear observable transform, and
MTK-exposable ODE dynamics.

## Benchmark Integration

**Documented in repo.** ODEPE has a benchmark-facing contract:

- `docs/2026-03-17_benchmark_contract.md`
- `raw_results, analysis, uq = analyze_parameter_estimation_problem(...)`
- flat `result.csv` compatibility
- optional metadata sidecars

**Supported by benchmark artifacts.** The repo contains extensive benchmark
and regression notes:

- `repro/oren_freshlook_2026_05_15/`
- `repro/polish_regression_2026_05_19/`
- `repro/multiplicity_complete_2026_05_19/`
- `artifacts/diagnostics/`

**Upgrade over PE.** ODEPE is built to be evaluated repeatedly by a separate
benchmark harness. That design pressure explains many seemingly fussy
features: stable return contracts, provenance, result truncation, sidecars,
rank strategies, and diagnostic dumps.

## SciML Stack and Package Engineering

**Verified in code.** Current ODEPE uses the modern SciML stack directly:

- `OrdinaryDiffEq`
- `SciMLBase`
- `NonlinearSolve`
- `Optim`
- `Optimization`
- `LeastSquaresOptim`
- `FastLevenbergMarquardt`
- `ModelingToolkit`
- `StructuralIdentifiability`
- `HomotopyContinuation`

The default ODE solver is `AutoVern9(Rodas5P())`.

The old `ParameterEstimation.jl` baseline depends on `DifferentialEquations`,
`LinearSolve`, `TaylorSeries`, `ProgressMeter`, `Suppressor`, and a smaller
solver/interpolation surface.

**Upgrade over PE.** ODEPE has moved more of the runtime behavior into
explicit package choices and options. The extension split for RS and PEtab is
also an ecosystem compatibility improvement: users who do not need those paths
do not have to load their APIs.

**Caution.** ODEPE's dependency surface is much larger. This is a capability
upgrade, but also a maintenance burden.

## What Is Not Yet Solved

### Practical Non-Identifiability

**Supported by benchmark artifacts.** The fresh-look and wallaby notes show
cases where the pipeline finds multiple fits that are hard to distinguish from
the data at the given noise level. Biohydrogenation and some CSTR cases are
recurring examples.

**Open / future work.** Better reporting may be more honest than trying to
force a single "truth" row in these cases. Diagnostics such as cross-solution
spread and uncertainty reports are the right direction.

### Conditioning and Column Scaling

**Documented in repo.** `docs/2026-05-01_variable_scaling_investigation.md`
records a serious investigation into variable/column scaling of polynomial
systems. It found large condition numbers on hard cases and identifies column
scaling as a plausible future lever, but later prototype notes complicate the
story.

**Open / future work.** HC.jl already does row scaling; ODEPE does not yet
have robust column scaling through the symbolic/SI pipeline. This remains
research territory rather than a production upgrade.

### Ranking Heuristics

**Supported by benchmark artifacts.** The ranking story is empirical and
non-monotone. S2-style ranking helped some coarse benchmark metrics and hurt
fine polish precision on wallaby-like candidate distributions.

**Open / future work.** A principled likelihood/noise-aware ranking objective
would be cleaner than fixed residual or provenance thresholds. See
`docs/2026-05-24_likelihood_guarded_output_ranking.md` for a proposed
direction.

### Unsupported Model Classes

**Documented in repo.** ODEPE is not a general nonlinear ODE parameter
estimator for every symbolic expression. Raw unsupported transcendental state
dependence, raw `sqrt`, and derivative-order explosions remain real support
boundaries.

## Summary Table

| Area | ParameterEstimation.jl | ODEPE |
| --- | --- | --- |
| Main API | `estimate(model, outs, data)` | `ParameterEstimationProblem` + `EstimationOptions` + `analyze_parameter_estimation_problem` |
| Result | `EstimationResult` with values/error/interpolants | `ParameterEstimationResult` with values/error/UQ/provenance |
| SI integration | direct identifiability result | SI templates, structural fixes, provenance, advisories |
| Time points | midpoint-like default `at_time` | multi-shot, warped time points, parameter homotopy |
| Multipoint systems | not a main surfaced feature | default multipoint template path |
| Interpolation | AAA/FHD defaults | GP, AAA, S2/S3, Chebyshev, Fourier, custom, gating |
| Solvers | HomotopyContinuation; msolve stub | HC, RS extension, NonlinearSolve/NLOpt variants, robust path, direct opt |
| Polishing | ODE simulation error filtering | raw-solver polish, residual LM polish, soft-wall, concurrency controls |
| Branch handling | clustering/filtering | algebraic multiplicity, branch top-K, branch diversity |
| Diagnostics | limited | derivative/system/sensitivity/UQ diagnostics |
| External formats | no PEtab layer in baseline | optional PEtab extension, narrow importer |
| Benchmarking | tests and examples | explicit benchmark contract and result sidecars |
| Support boundaries | less formalized | documented supported/hard/unsupported classes |

## Bottom Line

ODEPE is best understood as the operational successor to
`ParameterEstimation.jl`. The original package demonstrated a compelling
symbolic-numeric estimation method. ODEPE turns that method into a broader
engineering system: more structured inputs and outputs, more robust candidate
generation, richer interpolation choices, explicit provenance, modern solver
integration, diagnostics, benchmark contracts, and a growing account of where
the method fails.

The review should not claim that every new layer is uniformly better. Some
layers are principled upgrades, some are empirical hardening, and some are
still research scaffolding. The honest story is stronger: ODEPE preserves the
original algebraic insight while making it inspectable, benchmarkable, and
usable on a much larger and messier class of parameter-estimation experiments.
