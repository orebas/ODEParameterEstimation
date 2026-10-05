# ODEParameterEstimation.jl registry preparation

This is a living checklist for a possible first registration in Julia's General
registry. It records what is known from checkout `21072a1` on 2026-10-02 and
the first preparation milestone agreed on 2026-10-04. It does not certify a
release. The release version and repository URL still need attention, and the
release commit needs fresh registered-dependency validation. The dated
[production-readiness record](2026-09-10_production_readiness.md)
retains the detailed dependency and test history; this document tracks the work
needed to turn that history into a release decision.

## Priority order and first milestone

1. Preserve the current tracked research tree on a `research` branch in the
   namesake repository, record its starting commit, and publish selected
   provenance-checked local results there. Keep `main` as the installable core.
2. Remove research and benchmark APIs, the PEtab pilot, and the unfinished
   RS/RUR extension from `main`. Keep the standard estimator, maintained
   examples, diagnostics, and opt-in UQ. Retain tests needed for that surface.
3. Compare the GaussianProcesses.jl default interpolator with AGP/AGPUQ on
   frozen, paired inputs, including any reproducible case where GP.jl wins.
4. Map SIAN's equation-construction calls and decide whether an internal
   prototype is justified. Keep StructuralIdentifiability.jl's classification
   role separate.
5. Apply the resulting dependency decisions and complete release checks.
   The follow-up now implements private SIAN and GP backends; see the
   [internalization record](2026-10-04_internal_backends.md). No registry
   submission is part of this work.

The research line receives selected core fixes by cherry-pick. Merging the
`main` cleanup commit into `research` would remove the files that branch exists
to preserve. Ignored generated output remains local unless deliberately
promoted with provenance and a hash; the branch alone cannot preserve it.

General requires an OSI-approved license and registered dependencies. Its
AutoMerge checks also cover package and repository naming, a release version
without prerelease data, bounded compatibility entries, installation, and
loading. See the [General registration guide](https://github.com/JuliaRegistries/General/blob/master/README.md#registering-a-package-in-general)
and [RegistryCI AutoMerge guidelines](https://juliaregistries.github.io/RegistryCI.jl/stable/guidelines/).

## Registration checks

| Check | Current evidence | Next action |
| --- | --- | --- |
| License | The root [LICENSE](../LICENSE) contains GPL-3.0, an OSI-approved license. | Review third-party code, model data, and retained fixtures for attribution or separate license obligations. |
| Package identity | [Project.toml](../Project.toml) has the package name and UUID. No exact name match appeared in the local General snapshot inspected on 2026-10-02; similarity checks have not run. | Check name similarity against General when preparing the registration PR. |
| Release version | `Project.toml` says `1.1.0-DEV`; AutoMerge rejects prerelease data. | Choose a public version and set it only for the release commit. Decide whether its version number accurately describes the intended API commitment. |
| Repository URL | The configured remote and [README](../README.md) use `https://github.com/orebas/ODEParameterEstimation.git`. AutoMerge expects a URL ending in `/ODEParameterEstimation.jl.git`. | Rename the GitHub repository, update the local remote and links, and verify redirects, or plan for manual registry review. |
| Compatibility | The core dependency list has bounded `[compat]` entries. The deferred PEtab and RS/RUR weak dependencies have been removed from `main`. | Recheck all bounds against the chosen registered stack after the SIAN/GP decisions. |
| Installation and loading | After internalization, fresh registered-only full suites passed on Julia 1.12.7 and 1.13.1 (2,176 assertions each). | Repeat on the final release commit and every supported Julia version. See the [validation record](2026-10-04_internal_backends.md). |

The local General snapshot did not contain `RS` or
`RationalUnivariateRepresentation` on 2026-10-02. General
[does not accept unregistered dependencies](https://github.com/JuliaRegistries/General/blob/master/README.md#can-my-package-in-this-registry-depend-on-unregistered-packages).
The [RS/RUR extension on `research`](https://github.com/orebas/ODEParameterEstimation/tree/research/ext/ODEParameterEstimationRSExt)
also imports a missing core helper and has no active integration gate, according
to the [readiness record](2026-09-10_production_readiness.md#optional-integrations).

## Supported release surface

The documented core is the `FlowStandard` SI-template estimator for supported
polynomial and rational-style ODE models, with structural representative fixes,
algebraic candidate solving, trajectory-fit ranking, and explicit early errors
for unsupported raw model classes. Use the [quickstart](2026-03-17_user_quickstart.md),
[result contract](2026-03-17_results_and_api.md), and
[model limits](2026-03-17_supported_models_and_limitations.md) as the initial
user-facing contract. Confirm that examples and default options still match it
at the release commit.

The first-milestone release-surface decisions are:

- **PEtab:** The [restricted pilot](https://github.com/orebas/ODEParameterEstimation/tree/research/ext/petab)
  stays on `research` and is absent from the first core release surface.
- **RS/RUR:** The unfinished extension, `SolverRS`, and its unregistered weak
  dependencies stay on `research`.
- **Uncertainty quantification:** Production code exists, but the default user
  path leaves it off. The audited single-point calibration result does not
  establish nonlinear multipoint or polished-estimator coverage. State this
  limit wherever UQ is exposed; use the [UQ contract](2026-08-14_estimator_aware_uq.md)
  and [audited campaign](2026-08-16_audited_repeated_uq_campaign.md) before
  making release claims.
- **Research API:** Consensus, model-assisted correction, and SHADE+LM APIs
  stay on `research`. Core timing support remains on `main` because the
  production estimator uses it.

## Publishable main and continuing research

The namesake GitHub repository's default `main` branch should be the package
people install and the branch used for registration. Its README, CI, and source
tree must describe the same supported release. The active investigations and
their evidence must remain available for continued work; reducing the published
tree must not discard them.

The [research branch](https://github.com/orebas/ODEParameterEstimation/tree/research)
was created and pushed from commit `01b816f` before the `main` cleanup. Its
selected previously ignored raw results and provenance manifest are in commit
`c4358bd`. The frozen GP comparison is in `dd27080`. All 4,498 files removed
from `main` were checked against `research` and retain identical Git blobs.
The resulting core tree is about 3.5 MB before Git history. Existing Git
history remains part of a full Git clone even when the release tree becomes
smaller. Local research outputs remain in place and are ignored on `main`.
Links from retained documentation to moved evidence now point at the preserved
research commit; the PEtab guide explicitly applies to `research`.

- [x] Inventory `src/research/`, `repro/`, `artifacts/`, `experiments/`,
  `deprecated/`, and example scripts. For each item, identify whether package
  loading, active tests, documentation, or an ongoing study requires it.
- [x] Inventory ignored and untracked outputs separately. A branch or fork
  preserves tracked files, but cannot preserve local-only generated PEtab models
  and other ignored evidence without an explicit retention decision.
- [x] Choose the branch, fork, or separate-repository arrangement. Preserve an
  immutable reference to the current research tree before slimming `main`, keep
  reproducibility instructions and source attribution intact, and document how
  future core changes reach ongoing studies. Cherry-pick selected core commits
  into `research`; do not merge the `main` deletion commit into it.
- [x] Check the resulting `main` with the normal package gates and a fresh
  registered environment. Retain the research source, provenance, and
  reproduction instructions against identified commits. The research branch's
  full experimental suite was not rerun as part of the core split validation.
  Do not infer a smaller Git clone from a smaller release tree: retained
  history still contributes to clone size.

## Study whether to bring dependency functionality into ODEPE

The initial dependency study is preserved in
[the decision record](2026-10-04_dependency_decisions.md). The user subsequently
chose to own the required functionality. Private `SIANBackend` and `GPBackend`
modules now replace the external packages; GP's fitting policy remains distinct
from AGP. See [implementation and validation](2026-10-04_internal_backends.md).
The release gates apply to these replacements, including fresh registered-only
installation and recovery checks.

- [x] **SIAN scope and first decision:** Map the calls in
  [SI equation construction](../src/core/si_equation_builder.jl), including
  jet equations, generic sampling, variable ordering, rank selection, and
  polynomial template construction. Keep this distinct from
  `StructuralIdentifiability.jl`'s identifiability classification. Compare a
  narrow internal implementation, upstream repair, and a maintained fork. The
  initial preference for upstream repair was superseded by internalization.
  The internal backend must agree on
  representative models' equations, variable roles, structural fixes,
  multiplicity, and candidate recovery, with acceptable construction time.
- [x] **GaussianProcesses.jl scope and first decision:** Map the
  [GP-pivoted interpolator](../src/core/derivatives.jl) and the related PDMats
  compatibility bridge in [the main module](../src/ODEParameterEstimation.jl).
  Compare retaining the registered dependency, upstream repair, a narrow
  internal GP fit, and improvements to the existing AGP path. The old
  [interpolator comparison script on `research`](https://github.com/orebas/ODEParameterEstimation/blob/research/src/examples/compare_interpolators.jl)
  is exploratory. The new paired checkpoint found a small GP.jl win on a
  clean smooth curve; internalization preserves that fitting policy.
- [x] Validate the internal GP against its original implementation at fixed
  parameters, after optimization, and on frozen ODE recovery data. Preserve
  higher derivatives and GP-only/default-pool recovery. This replacement does
  not consolidate AGP policies or change the UQ fitting path.
- [x] Write a [first decision record](2026-10-04_dependency_decisions.md) with
  measured tradeoffs and the APIs to retain. If code is later adapted from
  upstream, review its license and preserve required attribution. Remove a
  dependency or compatibility bridge only after the replacement passes the
  registered-dependency full suite, recovery benchmark, and relevant focused
  contracts.

## Validation required for a release commit

- [ ] Resolve the checkout with only registered dependency versions and no
  development overrides. Run `julia --startup-file=no test/registered.jl` from
  the repository root; record the Julia version, resolved dependency versions,
  commit, and assertion results. This script develops the checkout in a fresh
  temporary environment and then invokes `Pkg.test`.
- [ ] Run the full suite on each currently released Julia version claimed by
  the release documentation and CI. Currently `julia = "1.12"` admits Julia
  1.12 and later 1.x releases, while CI has required jobs for 1.12 and 1.13. A
  [September 11 CI follow-up](2026-09-10_production_readiness.md#september-11-follow-up)
  records a Julia 1.12.7 UQ test failure after earlier green runs. The October
  internalization worktree passes the full Julia 1.12.7 suite after the test
  portability and compilation-budget corrections documented below. Recheck
  the eventual release commit. Julia nightly is advisory in the current
  [CI matrix](../.github/workflows/CI.yml); its recorded GPUCompiler
  precompilation crash is a separate dependency issue.
- [ ] Run the seeded recovery benchmark with registered dependencies on the
  selected release stack. The full and benchmark commands are documented in
  [CLAUDE.md](../CLAUDE.md). A passing unit group alone is insufficient for an
  estimation change; recovery accuracy does not certify UQ coverage.
- [x] If SIAN or GaussianProcesses.jl functionality moves inside ODEPE, run
  paired behavior and performance comparisons before and after the change on
  frozen inputs. Keep both winning and losing cases in the decision record;
  preserve the existing GP route until a replacement earns its removal.
- [ ] Verify a clean install, `import ODEParameterEstimation`, the README's
  minimal example, and the published documentation links from the release
  commit. Test the repository URL that Registrator will use.

An attempted fresh registered-dependency unit run on 2026-10-02 did not reach
package tests: the workspace's Julia depot was read-only, and a retry with a
temporary writable depot could not resolve network hosts needed to download a
registered dependency. This is an environment limitation, not evidence that the
package passed or failed the gate. Earlier results in the readiness record are
historical and must not be presented as validation of a later release commit.

### October 4 implementation validation

Package loading passed on Julia 1.13.1 using a writable temporary depot.
The local unit gate passed **419/419** assertions. This environment uses the
GP and SIAN development checkouts identified in the dependency decision record.
The first full run reached 2,054 passing assertions but failed four checks in
the DC-motor example canary: its singular `interpolator` option was overridden
by the default pool, whose selected synthesized aggregate did not carry the
single-point template provenance assumed by the test. A paired probe confirmed
that an explicit AAA pool returns the expected provenance. The shared fast
canary options now select AAA explicitly. Production estimation was unchanged
by this test-configuration correction.

The local full rerun passed **2,058/2,058** assertions in 13m30.3s. The
recovery benchmark passed **10/10** in 10m12.2s, including the noisy LV/simple,
clean LV, and rescaled HIV cases. These durations exclude dependency
precompilation. The canary fix is commit `b2a7e2d` and has also been cherry-picked
onto `research` as `e39230e`.

The fresh registered-dependency full gate also passed **2,058/2,058** in
11m22.1s after precompilation. Its resolver selected GP 0.12.6, SIAN 1.8.1,
SI 0.5.25, Nemo 0.54.2, Optim 1.13.3, and OrderedCollections 1.8.2; this is
distinct from the modern local development stack.

The validated core code is commit `02ff196`. Exact dependency versions,
commands, compressed logs, and hashes are in the
[validation record on `research`](https://github.com/orebas/ODEParameterEstimation/tree/aab64fc/repro/registry_dependency_study_2026_10_04).
These results establish the split's Julia 1.13.1 baseline. Supported-Julia CI,
the registered-stack recovery benchmark, the final release version, repository
naming, and attribution review remain release work.

### October 4 internalization follow-up

The [internalization record](2026-10-04_internal_backends.md) supersedes the
GP/SIAN dependency graph and patched CI setup above. Both used backends now
live in private modules with MIT notices and documented replacement boundaries.
The public GP candidate remains in the pool. Normal installation and testing
use neither external package, and CI now resolves both dependency profiles
entirely from registered packages.

The Julia 1.13.1 registered modern full suite and Julia 1.12.7 registered full
suite each passed **2,176/2,176**. The Julia 1.13.1 registered recovery benchmark
passed **10/10**. The local unit/full/benchmark
gates passed **419/419**, **2,176/2,176** and **10/10**, respectively. The first
registered full run exposed a compilation-sensitive wall-clock limit in the
direct-UQ convergence canary; a forced-timeout reproduction and the test-only
budget correction are documented in the implementation record.
The initial Julia 1.12 run also exposed five new fixture portability failures;
explicit symbolic input ordering and a measured high-derivative tolerance
resolved them. Independent upstream/internal comparisons match exactly on
both Julia versions. Production numerical code was unchanged by these fixes.

All eight frozen GP-only/default-pool recovery comparisons preserve the measured
errors and candidate counts exactly, including the unsuccessful biohydrogenation
parameter-recovery cases. SIAN fixture costs are comparable; the compact GP fit
allocates more and takes about 25% more time on the measured 201-point workload
(38 ms versus 30 ms). The record retains the full paired performance panel.
These worktree results still require validation of the eventual release commit.

## Repository and documentation review

- [ ] Review the first-release source tree. Before the split, Git tracked
  4,735 files totaling about 95 MB; `repro/` accounts for 3,641 files and about
  67 MB. It holds investigation scripts, frozen inputs, logs, and evidence for
  PEtab, Sneyd, UQ, HC threading, multiplicity, scaling, and polishing. It is
  outside the normal runtime path, but two active UQ tests loaded harness files
  from it. The UQ smoke helper has moved to `test/support`; campaign-only tests
  remain on `research`. Preserve research
  evidence while deciding which tracked artifacts need to accompany the
  installable package. Ignored local output is additional disk use, not part of
  those tracked-size figures.
- [ ] Review the bundled examples, datasets, and third-party material for
  provenance and license notices. Keep the GPL-3.0 package license visible.
- [ ] Update the README's repository URL, status wording, support limits, and
  example if the release choices change. Keep the release guide short and link
  to the detailed technical records rather than copying their results.
- [ ] Keep the existing [TagBot](../.github/workflows/TagBot.yml) and
  [CompatHelper](../.github/workflows/CompatHelper.yml) workflows aligned with
  the final repository URL and supported dependency versions.

## Registration sequence

1. Preserve `research` and isolate the core release surface on `main`; complete
   the SIAN/GP dependency studies and make the resulting source changes.
2. Complete the registered-dependency, supported-Julia, recovery, and optional
   extension checks on the exact commit to be registered. Record the evidence
   here with dates and commit identifiers.
3. Set a release version in `Project.toml`, verify the repository URL and license,
   then invoke [Registrator](https://github.com/JuliaRegistries/Registrator.jl#via-the-github-app)
   on that commit. [General normally holds new-package PRs for three days](https://github.com/JuliaRegistries/General/blob/master/README.md#automatic-merging-of-pull-requests)
   for community review.
4. Address any RegistryCI or maintainer feedback on a new commit and retrigger
   Registrator. After the registry PR merges, verify that TagBot creates the
   corresponding tag and that users can install and load the registered package.
