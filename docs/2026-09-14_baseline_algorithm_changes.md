# Baseline algorithm changes through September 14, 2026

This audit compares **`7636659` (August 16) → `62baa5d` (September 14)**.
There are no intervening commits between August 16 and September 10, so the
checkout both one and two weeks before this report had the same source baseline.
The comparison covers all 37 changed files under `src/` and `ext/`, plus the
dependency and test changes relevant to interpreting results. It distinguishes
ordinary estimation, optional PEtab behavior, and research experiments.

The broad estimation strategy survives this interval: interpolate observations,
construct a derivative system, choose equations using rank and the noise
frontier, solve polynomial systems, backsolve anchor states, and rank candidate
trajectories. There are real fixes to symbolic equations, data handling, and
candidate comparison, as well as compilation improvements. It would be inaccurate
to describe the whole interval as documentation or performance work only.

The September 14 SI/mixed-volume investigation adds research probes and records;
it makes **no further production algorithm or default changes**. See the
[investigation and measured results](2026-09-14_identifiability_cost_and_mixed_volume.md).

## Commit and behavior map

| Commit | Area | Resulting behavior | Scope |
|---|---|---|---|
| `ebdbbdc`, Sep 10 | Julia 1.13 stabilization | Correct mapping conversion and solution comparison; repair derivative helpers and two-sided denominator clearing; update dependency APIs; use scalar ForwardDiff chunks for rank probes. | Ordinary core and test environment. |
| `d33c50e`, Sep 10 | Observation data and PEtab | Each observable can have its own times and replicate rows; physical initial time is explicit; scoring and backsolving use that information. New optional rational PEtab adapter and joint condition representation. | New core data type; optional extension. |
| `45f9a74`, Sep 11 | Experiment blocks | Bounded groups of conditions share parameters and have local states; joint equations use the existing rank/frontier selector. Parameter/state roles come from model declarations. | Opt-in PEtab construction; core role-classification fix and selector refactor. |
| `7e926a7`, Sep 11 | Derivative-cap trials | Permit an explicit PEtab experiment-block cap up to 10. | Opt-in range expansion; default remains 4. |
| `5b485e0`, Sep 11 | SI template instantiation | Evaluate only observation derivatives actually used by the template. | Ordinary core bug fix. |
| `2764654`, Sep 11 | Deferred denominators | Build cleared derivative tables only when needed; build fallback derivatives only after advisory failure. | Ordinary core and optional experiment frontier. |
| `2fd4850`, Sep 14 | Polynomial polishing | Reuse residual/Jacobian kernels across data values; default ForwardDiff chunk becomes 1; add symbolic and finite-difference options. | Ordinary raw-root polishing. |

Other commits in this interval contain harnesses, evidence, or documentation:
`f10dba3`, `74af786`, `fce879d`, `cc0c973`, and `62baa5d`.
In particular, the Fujita monodromy experiment in `62baa5d` is a research script;
it was never installed in the estimator's solving path.

## 1. Correctness and compatibility fixes

**Solution comparison now matches symbolic keys.** Previously,
`solution_distance` zipped vectors produced from mapping iteration. Different
insertion order could compare the wrong parameters; unequal lengths could
silently omit components. It now compares each state and parameter by key,
returns ∞ for incompatible key sets, and preserves the existing component
normalization. This can change clustering when the old bug was triggered.
The clustering threshold itself did not change.

`ParameterEstimationResult` explicitly normalizes dictionaries to the required
`OrderedDict` types for OrderedCollections 2, while preserving already-compatible
ordered mappings. This fixes construction rather than redefining parameter order.

**Denominator clearing handles both sides together.** For example,

```text
x/y = z/w    becomes    xw = zy.
```

Previously the helper could return after clearing only the first side and leave
a rational expression on the other. Fraction simplification, including its GCD
work, remains enabled. Cross multiplication still requires care at poles; this
change does not make denominator-zero solutions valid ODE solutions.

The exported `calculate_higher_derivatives` and
`calculate_higher_derivative_terms` helpers now differentiate both sides with an
explicit independent variable, validate their input, and convert derivative
terms after differentiation. These utility repairs are distinct from the later
change to the main `populate_derivatives` producer.

Calls to the moved `diff2term` API use `Symbolics.diff2term`. This accounts for
small diffs in diagnostics, UQ, examples, and research files; those replacements
do not introduce a different UQ theory or research estimator.

The numerical rank probe still uses ForwardDiff. Its chunk configuration is now
explicitly 1. The retained 62 × 49 probe produced identical Jacobians, with the
cold build/evaluation dropping from 38.68 to 1.63 seconds. This is not a switch
from automatic differentiation to an analytic Jacobian.

A guarded compatibility bridge supplies the missing typed-empty-input method
for the affected SI versions on Julia 1.13. It delegates to SI's existing
algorithm. Project compatibility ranges and test imports were updated for the
current stack. The precompile workload uses the intended interpolator option
and isolates generated artifacts in a temporary directory.

## 2. Observation grids, repetitions, and initial time

The old shared-grid `OrderedDict` format remains supported. The new
`ObservationSeries` / `ObservationData` representation stores times per signal,
preserves repeated observations, and records the physical initial epoch.

Interpolation uses each signal's own measurement rows. Candidate anchor times
come from the union of measurement times restricted to the common observed
interval. The current algebraic workflow therefore still requires a nonempty
overlap interval. It does not impute missing observations or average replicates.
Support for duplicate times in a chosen interpolator remains a separate concern.

Trajectory evaluation solves on the union of times and selects the appropriate
indices for each signal, including repeated residual rows. Identical signal
expressions are pooled and scored once. Rescaling carries observation values,
noise standard deviations, and their identities consistently.

An algebraic state belongs to its shooting anchor. Backsolving now targets the
recorded physical initial time even if the earliest common anchor is later.
Result metadata distinguishes the anchor time from the time at which the states
are reported. The ordinary shared-grid format retains its original initial
epoch. Independent-grid UQ is explicitly rejected; it has not been implemented
or validated by these changes.

Automatic transcendental lifting is also explicitly rejected for
`ObservationData`; that combination requires explicit auxiliary states and
initial values. The existing shared-grid lifting path is unchanged. The new
data format does not imply that every pre-existing optional transformation now
supports independent grids.

## 3. Optional PEtab behavior

The extension entrypoint now loads `adapter.jl`, `experiment_blocks.jl`, and
`estimation.jl`. The current public entrypoints are `load_petab_problem` and
`estimate_petab_problem`; the older loader/converter/runner files remain in the
tree but are no longer loaded, and their old extension exports were removed.
This is an optional-integration API replacement. PEtab remains a weak dependency,
with its pilot compatibility restricted to the 5.4.3 patch series and its own
prepared reproduction environment.

The adapter imports the supported rational subset, condition substitutions,
observable formulas, parameter bounds/scales, and initial-value maps. A joint
model gives each experiment its own states while sharing the parameters that
the PEtab specification shares. The experiment-block variant constructs local
jet equations first, then uses joint rank selection over a bounded condition
group. It does not establish a new multi-experiment structural-identifiability
certificate.

Real-data models need not supply truth dictionaries. Core construction and
feasibility diagnostics now use model declarations to classify parameters and
states, rather than treating keys in `p_true` / `ic` as their definitions.

The PEtab wrapper scores candidates with the original PEtab negative
log-likelihood and enforces its parameter bounds. It disables ordinary trajectory
polishing, terminal fallback, UQ, aggregate-candidate synthesis, and system
saving within that wrapper; optional refinement uses the PEtab objective.
This also lets it examine raw candidates before ordinary fit-based truncation.
These choices do not alter the ordinary estimator's option defaults.

**The experiment derivative default is still 4.** The September 11 change
expanded the accepted explicit cap from 8 to 10 and ran cap-10 experiments.
It did not set a new package-wide derivative depth. More details and unsupported
PEtab features are in [the adapter contract](petab.md) and
[the experiment-block trial](2026-09-11_petab_experiment_blocks.md).

## 4. Derivative support and delayed polynomial construction

Fujita's SIAN derivative dictionary contained orders that the actual template
did not use. Instantiation previously evaluated them anyway and reached an
unsupported TaylorDiff order. It now evaluates the template's actual support.
The retained Fujita template uses observation orders 6, 7, 7; the full pool uses
7, 8, 8. This fix removes unused work; it does not raise TaylorDiff's order limit
or lower the derivatives required by the selected equations.

`populate_derivatives(...; include_cleared=true)` retains the legacy default for
direct callers. Rank and SI-support consumers opt out of cleared tables and
request them later through `ensure_cleared_derivatives!`. That helper clears
each **base** equation once and differentiates the resulting polynomial:

```text
q(x,p)x′ − n(x,p) = 0,
D[q(x,p)x′ − n(x,p)] = 0, …
```

It does not replace this representation with separately expanded and cleared
high-order rational Lie derivatives. Existing cleared prefixes are reused.
The optional experiment frontier also defers materialization until rank allows
construction. Required polynomial support scoring still happens afterward.

The expensive fallback derivative producer formerly ran before attempting the
normal numerical advisory. It now runs only if the advisory fails. Its depth
formula and the existing overflow guard were not changed. In particular, this
work did not introduce the deep fallback that appeared in earlier diagnostics.

Eager/deferred comparisons, including biohydrogenation, checked the actual
derivative equations and Jacobians; the biohydrogenation comparison found exact
table equality and zero Jacobian difference. The change was not responsible for
making that model's polynomial expressions larger. See
[the construction and rational-validation record](2026-09-11_deferred_denominator_construction.md).

## 5. Reusable polynomial polishing

Previously raw-root polishing substituted each anchor's observed derivatives
into the symbolic equations before compiling. Changing the numerical data
therefore generated another function and triggered more Julia/ForwardDiff
compilation. The new representation keeps those values as runtime arguments:

```text
F(z, d),       J(z, d) = ∂F/∂z,
∇(½‖F‖²) = JᵀF.
```

`PreparedRobustSystem` and a cache scoped to one estimation run reuse kernels for
identical equations and ordered unknown/data symbols. The key also includes the
Jacobian method and chunk size. Data values are bound through the reusable
numeric interface. The older direct/concrete-system path remains available.

ForwardDiff remains the default. Two new options expose
`polish_solver_jacobian = :forwarddiff | :symbolic | :finitediff` and
`polish_solver_chunk_size = 1` (0 restores automatic chunk selection).
Rectangular residual/Jacobian storage and finite-difference buffer ordering were
also corrected. The trust-region/LM/BFGS sequence, tolerances, and acceptance
criteria were not replaced.

On the retained biohydrogenation configuration, the normal-compiler run now
finishes in **1,502.6 seconds**, with **585 raw-polish calls totaling 24.66
seconds** and one prepared-cache miss versus 179 hits. It still estimates
k₁₀ ≈ 5.01170 when the generating value is 0.741. Resolving compilation did not
resolve that existing recovery error. See the
[full Jacobian comparison and validation](2026-09-13_reusable_polynomial_polishing.md).

## What stayed in place

The `EstimationOptions` diff adds the two polynomial-polisher options; it changes
no pre-existing option default. The nine-interpolator portfolio and its filtering,
ordinary single/multipoint construction, parameter homotopy, complex-γ handling,
power-of-two problem rescaling, column scaling, and ODE solver policy remain.
Trajectory polishing is still opt-in in the default options; the dense benchmark
harness enables it explicitly. That harness's 20 anchors and two-point systems
are recorded experiment settings, not a new universal library configuration.

Global SI classification followed by identifiable-function generation is also
unchanged across this interval. Those requests can be traced to September 2025.
Mixed-volume basis scoring and the generic-start caches predate this work.
No new default monodromy fallback was added. Existing multiplicity, branch
completion, ranking thresholds, and root-retention policies remain; the
key-based distance correction above is the relevant clustering behavior change.

## Validation and limits

The latest ordinary Julia 1.13 gate passed **1,934/1,934** assertions, and the
separate recovery benchmark passed **10/10**, after the reusable-polisher change.
The deferred-denominator gate previously passed 1,839/1,839 and the optional
PEtab contracts 128/128. These are recorded runs, not freshly rerun claims.
Research-only changes after that source revision do not require another full
estimation gate. The exact commands, dependency versions, and remaining registry
constraints are in [Production readiness](2026-09-10_production_readiness.md).

The test environment now declares its imports, isolates test files in modules
and temporary directories, and uses fixed seeds. `test/current.jl` preserves
the active dependency versions and development paths with
`Pkg.test(...; allow_reresolve=false)`. `test/registered.jl` separately resolves
a fresh registry environment. These environment changes are essential context
for comparing gate results; a successful older registered resolution is not
evidence for the current Julia 1.13 development stack.

Passing these gates does not make Fujita or Sneyd complete recovery examples.
Bruno's dense synthetic recovery is established; Fujita still has starting-root
enumeration/basis-selection work, and Sneyd still has the SI/representative
selection and sampling issues described in the investigation. No broad public
PEtab ranking against competitors has been established by the isolated probes.
