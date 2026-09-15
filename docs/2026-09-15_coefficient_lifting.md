# PEtab coefficient extraction and the Sneyd multiplicity trial

This experiment starts at the adapter boundary, preserving parameter-to-rate
definitions before assembling a polynomial problem. It adds an opt-in
extraction helper and a reproducible exact comparison. It does **not** change
the default estimator, SI classification, representative assignments,
interpolators, polynomial solver, or returned branch selection.

## What the adapter can now extract

The optional extension's `petab_coefficient_structure(problem, condition_id)`
reads the original SBML assignment rules and reaction laws. It retains named
assignments, reaction coefficient maps, compact state equations, expanded
maps, and the denominator exclusions encountered before cancellation.

For Sneyd, extraction finds three assignments (L₁, L₃, L₅), nine distinct
reaction coefficients, and six state equations. The coefficients remain
functions of the estimated kinetic parameters and the selected condition.
Published nominal kinetic values are never substituted. The expanded vector
field is checked exactly against the already-loaded PEtab adapter, catching
source-file changes or discrepancies in the importer conventions.

The present extraction scope is explicit rational parameter-only assignments
and linear reaction fluxes in constant unit compartments. Events, rate rules,
algebraic rules, initial assignments, state-dependent assignments, nonlinear
fluxes, and reaction-local parameters are outside this prototype. They fail
explicitly at this optional entry point. The ordinary adapter still follows
its existing support contract.

SBML numeric values are rationalized from their parsed Julia values, matching
the SI model convention. This is not a guarantee of recovering every original
XML decimal literal exactly.

## Equivalent polynomial lifting

The comparison starts with the existing frozen representative-fixed inspection
input from September 14: 74 equations in 73 variables. Its exact coefficients
are also embedded in the earlier standalone Gröbner reproducer. It is not the
unrecorded random sample used by the original production timeout.

The nine representative assignments, 61 ODE derivative constraints, twelve
observation constraints, and the saturation condition are retained. A rate
coefficient

```text
φᵢ = Nᵢ(θ) / Dᵢ(θ)
```

becomes a new unknown with the defining polynomial

```text
Dᵢ(θ) φᵢ − Nᵢ(θ) = 0.
```

The ODE recurrence equations use these coefficient variables. Each recurrence
is checked against its original equation after substituting the definitions,
including the exact state-coordinate scaling of the saved SI model.

The builder verifies that each defining denominator Dᵢ and each factor used
to normalize a recurrence are units on the original domain Q ≠ 0. It retains
every observation polynomial and `zQ − 1` verbatim. These identities establish
an isomorphism of the two localized coordinate rings: each original solution
has a unique lift, including its algebraic multiplicity. No Jacobian-based
equation dropping or new exact-data sample enters this comparison.

The first comparison lifts **effective rates**, expanding the named L
assignments once to obtain those maps. Introducing all intermediate L ratios
would need a separate domain check: their component denominators can vanish
where the currently simplified SI rational expressions have extensions.
The captured source-SBML guards and the frozen SI saturation domain are thus
recorded separately. Whether such exceptional cases contribute additional
branches to the frozen SI count has not been established here.

## Size measurements

| Quantity | Original | Lifted rates |
|---|---:|---:|
| Equations | 74 | 83 |
| Variables | 73 | 82 |
| Monomial occurrences | 2,706 | 1,694 |
| Maximum total degree | 6 | 5 |
| ODE recurrence equations | 61 | 61 |
| ODE recurrence terms | 1,315 | 269 |
| Observation equations | 12 | 12 |
| Observation terms | 1,380 | 1,380 |
| Definition/saturation terms | 11 | 45 |

The source extraction and imported-vector-field verification took 3.64s
after adapter loading in the recorded run. This is a single elapsed-time
observation, not a controlled speed comparison. Polynomial identity checking
and the input files are recorded separately in `evidence/verification.json`.

The largest remaining term contribution is the fourth-power observation and
its derivatives: 1,380 terms, about 81% of the lifted total. Coefficient
lifting therefore removes much of the recurrence expansion without reducing
the observation expansion.

## Validation and bounded solve

The bounded Gröbner experiment uses the production `Groebner.groebner`
defaults, degree-reverse-lexicographic order, the original variable order
followed by the nine coefficient variables, and one Julia thread. It has a
1,200-second external process limit. It reached that limit without returning
a basis or multiplicity (exit 124). The interrupt trace was in F4 symbolic
preprocessing during `_groebner_guess_lucky_prime`, before completion of the
first modular basis. Coefficient lifting alone has therefore not made this
presentation tractable within the tested budget. Other Julia validation
processes ran concurrently, so this is not a controlled runtime comparison.

The worker exited directly on SIGINT, leaving its last JSON status as
`running`; `evidence/count_execution.json` records the external timeout and
the compressed log contains the interrupt trace. The original worker source
is saved with that evidence. The current worker disables Julia's immediate
SIGINT exit so it can save interruption metadata in future runs. No precise
Gröbner-only elapsed time was recovered from this run.

Validation on Julia 1.13.0:

- Optional PEtab contracts: **157/157**, including **29** coefficient contracts.
- Full `Pkg.test` gate through `test/current.jl`: **2,230/2,230**.
- Standalone counting worker on `a² − 1 = 0`: dimension zero and **M = 2**.
- Deliberate worker interruption after setup: final `interrupted` status,
  elapsed time, and traceback saved successfully.
- Frozen Sneyd comparison: all 61 recurrence identities and defining-domain
  checks passed; the final capture produced byte-identical polynomial inputs
  to those used by the bounded trial.

These are the current development environments, retaining the existing GP and
SIAN overrides. Both environment manifests stayed unchanged. The registry-only
gate and recovery benchmark were not rerun for this optional extraction change.

The coefficient contracts include nested definitions, distinct conditions,
reconstruction of the loaded vector field, unchanged estimation models,
source-file changes, cyclic definitions, unsupported expressions, cancellation
poles, finite branches, and a double root. The root-count examples check that
lifting preserves algebraic length, rather than merely distinct-root counts.

No package version or compatibility bound changes are required. The scripts
use the existing optional PEtab environment without resolution; the counting
worker loads only Nemo, Groebner and JSON from it. It does not load PEtab or
the estimator. The default Groebner algorithm is probabilistic despite its
exact arithmetic; the exact lifting equivalence should not be confused with
a formally certified Gröbner computation.

Scripts, commands, polynomial artifacts, and environment records:
[`repro/coefficient_lifting_2026_09_14`](../repro/coefficient_lifting_2026_09_14/README.md).

## Integration boundary

The helper is available through the optional extension for inspection and
experiments. The definitions are not yet passed through the estimator's SI
template, rescaling, multipoint, and result-reconstruction machinery. They
must remain constrained auxiliaries throughout those stages; treating them
as free fit parameters would change identifiability and branch counts.

The current experiment establishes a validated representation and measures
one Gröbner presentation before attempting that larger integration.
