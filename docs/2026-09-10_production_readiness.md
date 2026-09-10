# Julia 1.13 and production readiness — 2026-09-10

The current stabilization target is the newer Julia 1.13 dependency stack with
the GP and SIAN compatibility patches. Local validation preserves those versions
with `Pkg.test(...; allow_reresolve=false)`. An earlier successful run on older
registered dependencies is historical comparison evidence, not the current gate.

This pass starts from `7636659`. Its scope is the core estimation workflow,
active tests, dependency interoperability, documentation, and CI. PEtab and
RS/RUR remain unfinished optional integrations. Research and uncertainty
calibration claims retain the limits in the audited August notes.

## Current dependency baseline

| Dependency | Local version/source |
|---|---|
| Julia | 1.13.0 |
| GaussianProcesses | 0.12.6, development checkout `3e896e9dbd0c41341c723ab16dcf0c261fc7b95a` |
| SIAN | 1.8.0, development checkout `2f78ca8a0cc93f99eb2f800f08c1dbd20f8b28d9` |
| StructuralIdentifiability | registered 0.5.31, with the guarded ODEPE bridge |
| ModelingToolkit / Symbolics | 11.42.0 / 7.39.0 |
| Optim / OrderedCollections | 2.3.1 / 2.0.1 |
| OrdinaryDiffEq / SciMLBase | 7.8.1 / 3.53.2 |
| Nemo / AbstractAlgebra | 0.56.1 / 0.50.2 |
| Groebner | 0.10.9 |

The GP and SIAN development checkouts were clean when inspected. They contain
committed patches with compatibility tables; this pass does not edit those
checkouts. Their package version strings alone do not identify the patches.

The GP combined branch is local, but its component fixes are published. CI
assembles the same files from immutable public revisions and verifies tree hash
`923ee3cb984865e3d207fa5d408593d7c256e7fb`. That assembly was checked locally
against the development checkout. The SIAN compatibility commit is published on
[`orebas/SIAN-Julia`](https://github.com/orebas/SIAN-Julia/commit/2f78ca8a0cc93f99eb2f800f08c1dbd20f8b28d9).

StructuralIdentifiability's autonomous-model dispatch issue is already fixed
by merged [upstream PR #555](https://github.com/SciML/StructuralIdentifiability.jl/pull/555).
An isolated comparison on Nemo 0.56.1 / AbstractAlgebra 0.50.2 reproduced the
registered 0.5.31 failure and passed exact exponential-series and global
identifiability checks on upstream `b7919dae8fbde2a65aeab19663277c5e522f42ef`.
ODEPE's bridge checks both the package version and method availability, so an
upstream checkout that still reports 0.5.31 receives no redundant methods.

`Project.toml` bounds every direct dependency and the test extras. The bounds
admit the current versions, including the newer major versions above; they do
not cap StructuralIdentifiability at 0.5.31. Several older dependency families
from the initial baseline remain admissible, but arbitrary combinations and
minimum versions have not each been tested. The Julia floor is 1.12; only 1.13
is installed for local validation.

## Changes and regression coverage

- `ParameterEstimationResult` explicitly normalizes dictionary inputs instead
  of relying on the implicit `Dict` to `OrderedDict` conversion rejected by
  OrderedCollections 2. The 10-, 12-, and 13-argument forms are covered, including
  raw symbolic keys, integer values, provenance, branch size, and preservation
  of already typed ordered mappings.
- Clustering compares values by symbolic key. Identical results with different
  insertion orders now have zero distance; different variable sets have infinite
  distance instead of silently comparing truncated positional vectors.
- Exported derivative helpers use current symbolic differentiation, preserve
  input arrays, support an explicit independent variable, and convert nested
  derivative terms after differentiating. Analytic multi-order regressions run
  in both gates. `clear_denoms` now clears fractions on both sides together.
- Calls to the removed `ModelingToolkit.diff2term` name use the owning package,
  `Symbolics`. This qualification change spans core, diagnostics, and research
  call sites without changing their algorithms.
- The noise-frontier rank probe uses scalar ForwardDiff chunks. In the isolated
  62-equation / 49-variable comparison, compilation plus evaluation took 1.63s
  versus 38.68s with the default chunk size 10. The Jacobians were identical;
  relative disagreement with central finite differences was 1.35e-11. Linear
  Jacobian and nonlinear rank-deficiency regressions cover this path. This
  trades more function evaluations for less compilation; see the
  [ForwardDiff guide](https://juliadiff.org/ForwardDiff.jl/stable/user/advanced/#Configuring-Chunk-Size).
- Test imports are declared in `test/Project.toml`. The numeric CSV fixtures
  use DelimitedFiles and the serialization check uses JSON, avoiding a test-only
  CSV/JSON3 restriction to Parsers 2 in a stack using Parsers 3.
- Test files have separate modules, RNG seeds, and temporary working directories.
  Shared canary helpers are explicitly included. Example scripts stay in their
  test module. Package precompilation also contains diagnostic sidecars in a
  temporary directory. Undefined exports have a regression check.
- README examples and the precompilation workload select their intended
  interpolator through the plural `interpolators` option. Results documentation
  describes fit-based ranking and the named analysis fields.

## Test commands and measured results

```sh
# Preserve the active versions and development paths; verify this checkout:
julia --startup-file=no test/current.jl unit
julia --startup-file=no test/current.jl
julia --startup-file=no test/current.jl benchmark

# Focus a failure through Pkg.test; this does not replace the full gate:
julia --startup-file=no test/current.jl test_model_assisted_correction.jl

# Independently resolve registered dependencies in a temporary environment:
julia --startup-file=no test/registered.jl
```

The modern full suite passed **1,776/1,776 assertions across 41 files in
12m45.8s**, with no failures, errors, or broken tests. The unit suite passed
**388/388 assertions in 16.1s**. These timings exclude package loading and
precompilation. Both used the current dependency baseline above with version
re-resolution disabled. The separate recovery benchmark passed **10/10
assertions in 21m17.0s**, including noisy LV/simple recovery, clean LV, and
HIV recovery with automatic rescaling. Recovery tolerances were unchanged.
The full suite and benchmark overlapped in separate processes; their testset
timings are recorded independently.

| Recovery case | Best-of-branch maximum relative parameter error | Gate bound |
|---|---:|---:|
| LV, noise 1e-8, polish | 5.63e-5 | 1e-2 |
| Simple, noise 1e-8, polish | 6.35e-9 | 1e-2 |
| LV, clean, no polish | 1.02e-10 | 1e-6 |
| HIV, clean, rescaling and polish | 2.50e-9 | 1e-2 |

The model-assisted regression now uses the perturbed data in both its retained
artifact and its problem. It checks screening against the exact exponential
trajectory: correction is not assumed to improve every fit. The original
parameter-continuity bound is unchanged.

Historical comparison: before the newer-stack constructor and utility fixes,
a fresh registry environment passed **1,662 assertions / 37 files / 19m12s**,
with Optim 1.13.3, OrderedCollections 1.8.2, OrdinaryDiffEq 6.111.0,
SciMLBase 2.155.2, Nemo 0.54.2, and SI 0.5.25. Its initial benchmark passed
10 assertions in 32m49s. Those results do not certify the final checkout or the
current dependency stack. The benchmark tests best-of-branch recovery, not
rank-one accuracy or uncertainty calibration.

CI has registered-dependency jobs on Julia 1.12, 1.13, and advisory nightly,
plus separate Julia 1.13 full and benchmark jobs using prepared GP, SIAN, and
merged SI checkouts. The modern profile requires Optim 2, OrdinaryDiffEq 7,
SciMLBase 3, and OrderedCollections 2 in a fresh temporary environment.
Fresh registered-dependency resolution passed with the final compatibility
ranges. The fresh patched CI profile also passed the **15-assertion SI
interoperability regression in 2.0s**, using the assembled GP tree, patched SIAN,
and merged SI fix. That fresh resolution selected ModelingToolkit 11.42.1 and
SymbolicUtils 4.46.4; the full-suite result above uses the fixed local baseline.
Hosted [CI run 34536335730](https://github.com/orebas/ODEParameterEstimation/actions/runs/34536335730)
checks stabilization commit
[`ebdbbdc`](https://github.com/orebas/ODEParameterEstimation/commit/ebdbbdc6ad78cdeebdfac0cb507b4b1d3c295d3c),
pushed directly to `main` at the user's request.
The run completed successfully: all four required Julia 1.12/1.13 jobs passed.

| Hosted check | Result | Testset time, excluding loading/precompilation |
|---|---|---|
| Julia 1.13, registered dependencies, full suite | 1,777/1,777 passed | 20m13.5s |
| Julia 1.13, modern patched dependencies, full suite | 1,777/1,777 passed | 13m28.2s |
| Julia 1.12, registered dependencies, full suite | 1,777/1,777 passed | 23m17.3s |
| Julia 1.13, modern patched dependencies, recovery benchmark | 10/10 passed | 31m33.9s |
| Julia nightly, registered dependencies | Failed before tests; advisory | Not run |

The full-suite count can differ by one: the model-assisted screening regression
has an additional assertion when the correction improves the trajectory fit.
Both acceptance and rejection are checked against the analytic reference.

The nightly job used Julia 1.14.0-DEV.3160 and failed with a segmentation fault
during GPUCompiler 1.23.0 precompilation (`src/precompile.jl:7`). Enzyme and its
dependent packages then could not precompile. ODEPE's test files did not run on
nightly; this is not a passing nightly result or an ODEPE assertion failure.
The job retains its existing advisory status.

## Optional integrations

RS/RUR restoration is deferred at the user's request. PEtab's immediate goal
is evaluation on a suitable subset of public benchmarks; the
[source assessment and proposed first case](2026-09-10_public_benchmark_triage.md)
record the actual data and model limitations. No public PEtab benchmark was
run in this stabilization pass.

The core test suite does not load these extensions. They need separate repair
and representative fixtures before being included in a supported release:

- **PEtab:** the extension entry point includes nonexistent relative paths;
  the nested loader/converter names do not match its exports. The validation
  file is a research script with top-level model loops and stale includes,
  not a safe library include. Its nested project targets an older PEtab/MTK
  stack. Do not fix this merely by pointing the entry point at those scripts.
- **RS/RUR:** the weak dependencies are absent from the inspected General
  registry. The extension imports an absent core helper and injects main-module
  bindings during initialization. The root-conversion and solver behavior need
  a dedicated audit and tests before `SolverRS` is supported.

The source is retained for restoration. Describing it here does not make its
loading or behavior production-ready. Older multipoint experiments and other
scripts outside the active runner are inventoried in the refreshed
[review map](review_map.md).

## Release work

Core stabilization and its local and hosted validation are complete. The
remaining work below concerns a future supported release, not unfinished core
test repairs. PEtab benchmarking remains a separate follow-up.

1. Once GP/SIAN/SI fixes are registered, validate a fresh environment selecting
   those releases and remove temporary CI patch assembly and dependency bridges
   when their supported version floors make them unnecessary.
2. Decide whether to restore or omit the unfinished optional extensions from
   the first supported release. Their presence must not imply support.
3. Choose a release version (the checkout remains `1.1.0-DEV`) and check registry
   installation, loading, compatibility, license, and naming requirements. See
   the [General AutoMerge guidelines](https://juliaregistries.github.io/RegistryCI.jl/stable/guidelines/).
   This pass does not register or publish a release.

For UQ changes, follow the audited canaries and estimator-specific contracts in
`CLAUDE.md`. Single-point calibration evidence does not establish multipoint or
polished-estimator coverage.
