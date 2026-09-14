# Local SI classification and coordinate representative fixing

Follow-up: the [representative-fixed multiplicity correction](2026-09-14_fixed_multiplicity.md)
addresses the separate ordering/rank defects found below. This document
records the earlier local-SI implementation and its validation.

## Change and scope

`EstimationOptions(si_fix_strategy=:local_basis)` uses
`StructuralIdentifiability.assess_local_identifiability` with `type=:SE`,
assessing parameters and free initial states together and requesting `trbasis`.
It replaces both the full local/global classification request and the separate
`find_identifiable_functions` request. Replacing only classification would
leave Sneyd's input–output elimination bottleneck in place.

The comparison option `:identifiable_functions` retains the previous global SI
classification and identifiable-function Jacobian/QR fix selection. After the
focused contracts, both-method recovery regressions, frozen rational runs, and
the full validation gate passed, `:local_basis` is the production default.
No dependency versions are changed.

The public `trbasis` keyword and the same basis pivot ordering are present in
the [SI 0.5.25 source](https://github.com/SciML/StructuralIdentifiability.jl/blob/v0.5.25/src/local_identifiability.jl),
the minimum version already permitted by `Project.toml`. This is a source API
check; runtime validation uses SI 0.5.31. No compatibility bound is raised.

For `si_probability=p`, the local probability is `1 − (1 − p)/10`, matching
the local stage of SI 0.5.31's full classification call: 0.999 at the default
p = 0.99. This is single-experiment identifiability; it makes no new claim
about identifiability gained by combining experiments.

## Meaning of the basis

For x′ = (a + b)x, y = x, both a and b are individually nonidentifiable,
but there is only one continuous freedom. The basis selects one coordinate
to fix. Fixing both would constrain the identifiable sum a + b.

SI supplies nonpivot coordinates of its generic local observation-Jacobian
calculation. Its pivot ordering places states before parameters, preferring
parameter fixes when those span the available freedoms. The basis can also
contain state values. The assignment applies to x₀ at the shooting anchor,
not to the whole trajectory x(t), and is substituted into the polynomial
equations. The ODE retains its original dynamics. Each selected coordinate is
assigned 1 in the current coordinates, as in the previous representative
convention; automatic problem rescaling can change its value in original units.

A locally identifiable quantity can have finitely many branches. For
x′ = a²x, y = x, the new method fixes no coordinate and preserves the ±a
ambiguity. It does not assert global identifiability or compute an explicit
description of identifiable functions. In its template metadata,
`identifiable_funcs === nothing` means **not computed**, rather than an empty
list passed into the old fixing heuristic.

Neither the new basis nor the previous local QR selection proves that fixing
coordinates to 1 preserves every global branch or admits a positive bounded
representative. Generic local rank is the claim; physical feasibility still
needs recovery and trajectory validation.

## Reuse and diagnostics

A `SIStructuralAnalysis` is computed on the detection pass and reused on the
final polynomial-template pass. Reuse requires the same model object,
observations, method, and probability. There is no process-global analysis
cache. A state rescue with numerically fixed parameters uses fresh analysis
of its changed model, inheriting the chosen method and probability.

Both strategies receive this reuse. The legacy comparison therefore preserves
its fixing algorithm but avoids its former duplicate SI requests; the two
randomized SIAN polynomial-construction passes still run as before. Avoiding
duplicate SI requests changes random-number consumption, so bitwise identical
later HC candidates are not promised even for the legacy option.

The six-value `get_si_equation_system` return shape is retained. Its metadata
now contains `structural_analysis` and `structural_analysis_reused`. Completed
run timing records include the chosen strategy, coordinate basis, structural
analysis timings, and reuse flag separately from SIAN construction and
algebraic multiplicity timings. The original structural nonidentifiable set
remains available in result provenance even after representative assignments.

Two accompanying bookkeeping fixes keep the representations consistent. Fixed
quantities are removed from the template's remaining-unidentifiable set by
name, since its old `Symbol` lookup did not match the `Num` keys actually used
for assignments. The legacy substitution helper now preserves analysis
metadata and substitutes the full equation pool as well as its selected
equations. Original structural nonidentifiability is still reported separately.
Research template-cache reuse also checks the selected SI strategy and
probability, preventing a cache built with one fixing convention from being
used under the other.

No changes are made to multiplicity calculation, HC solving, mixed-volume
budgets, interpolator selection, or trajectory polishing. Monodromy is not
introduced.

## Validation record

The new default passed the **full Julia 1.13 gate: 2,159/2,159**
(17m21.1s testset time) and **benchmark smoke: 10/10** (10m55.9s).
Dependency re-resolution was disabled. The focused contracts passed **197/197**
(2m00.5s testset time); the existing identifiability regressions passed **50/50**
across both methods (2m43.6s). The focused contracts cover analytical sum/product
confounding, two independent freedoms, parameter–IC confounding, state-only
freedoms, agreement with the old nonidentifiable classification, analysis reuse
guards, and actual recovery retaining finite ±a branches. The existing
identifiability regressions now run with both strategies. The first focused run
had 196 passes and one test-expression error: Symbolics overloads membership in
a two-element tuple as a domain declaration. Replacing it with an explicit
`any(isequal(...), ...)` assertion resolved the error; estimator code did not
change for that correction.

The frozen FitzHugh–Nagumo run completed in 543.2s, with maximum relative
parameter error 7.06 × 10⁻¹¹ and maximum relative initial-state error
1.22 × 10⁻¹⁰. Local SI classification and basis extraction took 3.129s and
were reused on the second template pass. This is an observed elapsed time,
not a controlled speed comparison; independent validation workers overlapped.

Benchmark best-of-branch maximum relative parameter errors were 5.63 × 10⁻⁵
(noisy LV), 6.35 × 10⁻⁹ (noisy simple), 1.02 × 10⁻¹⁰ (clean LV), and
3.42 × 10⁻⁸ (clean HIV with rescaling). The first three match the previous
gate's recorded errors. HIV differs from its previous 2.50 × 10⁻⁹, while
remaining well within the recovery guard; later randomized work need not be
bitwise identical after duplicate SI calls are removed.

The frozen biohydrogenation run completed in 1,666.1s on its worker timer.
Its best-result parameter/state recovery record and fit error are **exactly
equal** to the prior reusable-polisher run: k₁₀ = 5.01169618 versus generating
0.741, with fit error 9.37588463 × 10⁻¹⁰. This is preservation of the existing
result, not successful k₁₀ recovery. The model, data, and active dependency
manifest hashes match. Local SI took 3.240s; the basis was only x₇. The fixed
value is 1 in rescaled template coordinates, corresponding to x₇ = 4 in the
returned original-coordinate state. Its template remains 25 × 25.

The first repressilator run had a 1,800s cap and timed out in trajectory
processing after all seven noise-eligible interpolators completed polynomial
solving. Its retained baseline took 2,431.4s, so that cap was insufficient for
a completion comparison. The rerun with a 4,200s cap completed in 2,240.4s
on the worker timer. Maximum relative parameter error is 1.73146 × 10⁻⁴ and
maximum relative initial-state error is 4.85207 × 10⁻⁴, using the same 1,501
samples per observable and seven noise-eligible interpolators. All nine fitted
coordinates agree with the retained baseline to within 2.88 × 10⁻¹⁰ in
absolute value; fit error is 6.45176 × 10⁻⁵. Local SI took 3.176s, selected no
free coordinates, and was reused on the second pass. The retained September 11
baseline predates the reusable-polisher change, so this checks recovery across
the intervening changes rather than isolating the effect of local SI.

The rational and dense-data supervisors accept
`--si-fix-strategy local_basis` for explicit comparison with frozen settings.
Artifacts and reproduction commands live in
[`repro/local_si_basis_2026_09_14`](../repro/local_si_basis_2026_09_14/README.md).

## Sneyd: SI bottleneck removed, multiplicity still blocks completion

The ordinary dense single-condition experiment (`Ca_dose_response__1`, 201
clean samples, nine interpolators configured, 20 anchors, two-point MP) now
finishes local SI analysis in **3.54755s**. All 14 parameters and six free
initial states remain individually nonidentifiable. It selects these nine
parameter coordinates as its representative basis:

```
l₂, k₋₄, k₋₃, k₋₂, k₋₁, k₄, k₃, k₂, k₁
```

In actual model identifiers these are `l2, k_4, k_3, k_2, k_1, k4, k3,
k2, k1`. No global classification or identifiable-function calculation is
requested on this path. The first SIAN construction had 73 polynomial
equations and trimmed one dependent equation. The final construction started
with the saved structural analysis and nine representative assignments.

The run then hit its requested 1,800s estimation cap **inside
`Groebner.groebner` in the existing algebraic-multiplicity calculation**.
It did not reach HC solving and returned no estimates. The worker's monotonic
estimation timer reports 1,640.5s, while the supervisor's wall-clock stage
timer reports 1,800.5s; these clocks disagree, so the cap should not be
described as 1,800 measured monotonic seconds. The worker exits with status 1.

The multiplicity step still runs before the chosen coordinates are substituted
into the polynomial template. Thus the new basis selection does not simplify
that Gröbner input. Also, SIAN's separate `theta_l` probe must have been
nonempty for this branch to run, despite local SI classifying every individual
quantity as nonidentifiable. A concrete next audit is its rank criterion:
it compares the reduced Jacobian rank with the **number of equations**, before
the later trimming of dependent rows. On a row-dependent system this can
mistake row redundancy for individual identifiability. This is a code-level
hypothesis for the discrepancy, not a validated multiplicity fix.

The rank criterion has a simple counterexample: with known data d, take
F = (a + b − d, 2a + 2b − 2d). Its Jacobian is

```
    ⎡1  1⎤
J = ⎣2  2⎦,    rank(J) = 1.
```

Deleting either parameter column leaves rank 1. Comparing that rank with two
equations labels both coordinates identifiable, although only a + b is fixed
by the data. A rank-loss comparison against the full Jacobian rank would avoid
this failure. Applying and validating that correction in ODEPE's SIAN adapter
is a separate change; the present implementation leaves multiplicity intact.

No multiplicity bypass, new root-count convention, or solver fallback is
introduced in this change. Sneyd confirms the intended SI improvement but is
still an incomplete estimation benchmark.
