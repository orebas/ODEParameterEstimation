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
4. Map and prototype the narrower SIAN equation-construction functionality.
   Keep StructuralIdentifiability.jl's classification role separate.
5. Apply the resulting dependency decisions and complete release checks in a
   later milestone. No registry submission is part of this first milestone.

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
| Repository URL | The configured remote is `https://github.com/orebas/ODEParameterEstimation.git`. AutoMerge expects a URL ending in `/ODEParameterEstimation.jl.git`; the [README](../README.md) already uses the `.jl` URL. | Rename the GitHub repository, update the local remote and links, and verify redirects, or plan for manual registry review. |
| Compatibility | All 45 direct dependencies in `Project.toml` have `[compat]` entries. `RS` and `RationalUnivariateRepresentation` are weak dependencies without entries. | Resolve the RS/RUR decision below; add bounded compatibility if those dependencies remain. Recheck all bounds against the chosen registered stack. |
| Installation and loading | Historical CI runs exercised registered dependencies, but there is no fresh registered-only pass for this release candidate. | From a clean, networked environment, resolve registered dependencies, install the release commit, and import the package on every supported Julia version. |

The local General snapshot did not contain `RS` or
`RationalUnivariateRepresentation` on 2026-10-02. General
[does not accept unregistered dependencies](https://github.com/JuliaRegistries/General/blob/master/README.md#can-my-package-in-this-registry-depend-on-unregistered-packages).
Recheck the registry when deciding the extension's fate. The existing
[RS/RUR extension](../ext/ODEParameterEstimationRSExt/ODEParameterEstimationRSExt.jl)
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

The following choices need explicit decisions before registration:

- **PEtab:** The [restricted pilot](petab.md) is an optional extension with
  separate contracts and a narrow tested version range. Decide whether it ships
  in the first release. If it does, run its own registered-dependency import and
  contract checks, and retain the stated support limits.
- **RS/RUR:** Restoration is deferred, while `SolverRS` and its weak dependencies
  remain in the project. The recommended first-release action is to remove the
  unsupported extension and its public selection path from the release surface;
  retaining it instead requires registered dependencies, a repaired extension,
  compatibility bounds, and substantive tests.
- **Uncertainty quantification:** Production code exists, but the default user
  path leaves it off. The audited single-point calibration result does not
  establish nonlinear multipoint or polished-estimator coverage. State this
  limit wherever UQ is exposed; use the [UQ contract](2026-08-14_estimator_aware_uq.md)
  and [audited campaign](2026-08-16_audited_repeated_uq_campaign.md) before
  making release claims.
- **Research API:** [The main module](../src/ODEParameterEstimation.jl) loads and
  exports `src/research/` functions even though they are outside the default
  estimator. Decide which names are supported public API and which should move
  out of the release interface. Make that decision before choosing the public
  version.

## Publishable main and continuing research

The namesake GitHub repository's default `main` branch should be the package
people install and the branch used for registration. Its README, CI, and source
tree must describe the same supported release. The active investigations and
their evidence must remain available for continued work; reducing the published
tree must not discard them.

Compare these ways to maintain that separation before moving files:

| Arrangement | Benefit | Cost to resolve |
| --- | --- | --- |
| Research branch in the namesake repository | One repository and preserved tracked history; `main` can have a smaller release tree. | Ongoing core fixes must be merged or cherry-picked into the research branch. Old files remain in Git history even when absent from a release tree. |
| Research fork with the namesake repository as upstream | A separate default branch and CI for experiments, while the namesake `main` stays publishable. | Synchronization, issues, and review span two repositories. |
| Separate research repository | Independent layout and retention policy for large studies. | Moving scripts, fixtures, references, and their history requires more coordination. |

- [ ] Inventory `src/research/`, `repro/`, `artifacts/`, `experiments/`,
  `deprecated/`, and example scripts. For each item, identify whether package
  loading, active tests, documentation, or an ongoing study requires it.
- [ ] Inventory ignored and untracked outputs separately. A branch or fork
  preserves tracked files, but cannot preserve local-only generated PEtab models
  and other ignored evidence without an explicit retention decision.
- [ ] Choose the branch, fork, or separate-repository arrangement. Preserve an
  immutable reference to the current research tree before slimming `main`, keep
  reproducibility instructions and source attribution intact, and document how
  future core changes reach ongoing studies.
- [ ] Check the resulting `main` with the normal package gates and a fresh
  install. Confirm that research retained elsewhere can still be reproduced
  against an identified ODEPE commit. Do not infer a smaller Git clone from a
  smaller release tree: retained history still contributes to clone size.

## Study whether to bring dependency functionality into ODEPE

The current development baseline and patched CI profile use prepared
[GaussianProcesses.jl and SIAN checkouts](2026-09-10_production_readiness.md#current-dependency-baseline).
This has created recurring compatibility work. Study the narrow functionality
ODEPE needs before deciding whether to maintain it internally, keep an upstream
dependency, or use another maintained implementation. Record the current
registered releases, dependency conflicts, required local patches, upstream
prospects, maintenance cost, and license obligations as part of that decision.

- [ ] **SIAN scope:** Map the calls in
  [SI equation construction](../src/core/si_equation_builder.jl), including
  jet equations, generic sampling, variable ordering, rank selection, and
  polynomial template construction. Keep this distinct from
  `StructuralIdentifiability.jl`'s identifiability classification. Compare a
  narrow internal implementation, upstream repair, and a maintained fork. Any
  replacement must agree on representative models' equations, variable roles,
  structural fixes, multiplicity, and candidate recovery, with acceptable
  construction time.
- [ ] **GaussianProcesses.jl scope:** Map the
  [GP-pivoted interpolator](../src/core/derivatives.jl) and the related PDMats
  compatibility bridge in [the main module](../src/ODEParameterEstimation.jl).
  Compare retaining the registered dependency, upstream repair, a narrow
  internal GP fit, and improvements to the existing AGP path. Evaluate the
  GaussianProcesses.jl and AGP/AGPUQ paths on the same sampled data and fitting
  budget. Record prediction fit, derivative-jet error at actual shooting
  points, selected parameter recovery, solver availability, time, and UQ
  behavior where applicable. Include noise and model regimes where the
  GaussianProcesses.jl fit wins; similarity of implementation alone is not a
  reason to remove it. The old
  [interpolator comparison script](../src/examples/compare_interpolators.jl)
  is exploratory and needs a current, audited comparison before it can support
  a release decision.
- [ ] For each dependency, write a decision record with the measured tradeoffs
  and exact APIs to retain. If code is adapted from upstream, review its license
  and preserve required attribution. Remove a dependency or compatibility
  bridge only after the replacement passes the registered-dependency full suite,
  recovery benchmark, and relevant focused contracts.

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
  records a Julia 1.12.7 UQ test failure after earlier green runs. Reproduce
  and fix it, or raise the supported Julia floor after checking the resulting
  compatibility and CI policy. Julia nightly is advisory in the current
  [CI matrix](../.github/workflows/CI.yml); its recorded GPUCompiler
  precompilation crash is a separate dependency issue.
- [ ] Run the seeded recovery benchmark with registered dependencies on the
  selected release stack. The full and benchmark commands are documented in
  [CLAUDE.md](../CLAUDE.md). A passing unit group alone is insufficient for an
  estimation change; recovery accuracy does not certify UQ coverage.
- [ ] If SIAN or GaussianProcesses.jl functionality moves inside ODEPE, run
  paired behavior and performance comparisons before and after the change on
  frozen inputs. Keep both winning and losing cases in the decision record;
  preserve the existing GP route until a replacement earns its removal.
- [ ] If PEtab ships, run the optional PEtab CI contracts on its advertised
  version range. Keep those results separate from the core gate.
- [ ] Verify a clean install, `import ODEParameterEstimation`, the README's
  minimal example, and the published documentation links from the release
  commit. Test the repository URL that Registrator will use.

An attempted fresh registered-dependency unit run on 2026-10-02 did not reach
package tests: the workspace's Julia depot was read-only, and a retry with a
temporary writable depot could not resolve network hosts needed to download a
registered dependency. This is an environment limitation, not evidence that the
package passed or failed the gate. Earlier results in the readiness record are
historical and must not be presented as validation of a later release commit.

## Repository and documentation review

- [ ] Review the first-release source tree. At this snapshot, Git tracks
  4,735 files totaling about 95 MB; `repro/` accounts for 3,641 files and about
  67 MB. It holds investigation scripts, frozen inputs, logs, and evidence for
  PEtab, Sneyd, UQ, HC threading, multiplicity, scaling, and polishing. It is
  outside the normal runtime path and active test runner. Preserve research
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

1. Choose how publishable `main` and continuing research are maintained. Settle
   the release surface and the SIAN/GP dependency studies, then make the
   required source and documentation changes.
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
