# Sneyd with independent ODE coefficients

The free-rate rewrite reduces the selected system from 2,362 to 1,306
monomials and maximum degree six to four, but its ordinary HC generic-start
solve **fails after 958.57 seconds with an Int64 multiplication overflow**.
No coefficient fit or completed mixed volume is obtained. The model rewrite
and exact structural checks succeed; this remains a solver-tractability result.

The preceding [HC-boundary experiment](2026-09-15_sneyd_hc_boundary.md) used
**one experiment and the first single-point system**. Its overall configuration
enabled later two-point estimation, but execution stopped at the first
single-point generic-start solve. No multipoint solve was reached.

This follow-up defines a separate native ODEPE problem. Nine effective reaction
rates become independent unknowns. It removes the rational kinetic-parameter
map and its defining constraints, while retaining the six-state reaction
network, shared return coefficient, and original quartic observation. It is
therefore different from the earlier equivalent coefficient lifting, and does
not estimate or backsolve the original kinetic parameters.

## Model and data

Write the independent rates as φ₁,…,φ₉:

```text
S′  = φ₈ O − φ₉ S
R′  = φ₁ O − (φ₂ + φ₃) R + φ₄ I₁
O′  = φ₂ R + φ₆ A + φ₉ S − (φ₁ + φ₅ + φ₈) O
I₂′ = φ₇ A − φ₄ I₂
I₁′ = φ₃ R − φ₄ I₁
A′  = φ₄ I₂ + φ₅ O − (φ₆ + φ₇) A

y   = (0.9 A + 0.1 O)⁴
```

The state dynamics are bilinear in states and rates. There are no parameter
denominators to clear. The sum of all six states is conserved. The two return
transitions retain their shared rate φ₄; other functional relationships among
rates from the original kinetic specification are removed.

| Rate | Transition | Original generator value |
|---|---|---:|
| φ₁ | O → R | 0.0023905150 |
| φ₂ | R → O | 49.22717094 |
| φ₃ | R → I₁ | 0.00001058984722 |
| φ₄ | I₁ → R and I₂ → A | 1.271589187 |
| φ₅ | O → A | 9993.828684 |
| φ₆ | A → O | 2679.456100 |
| φ₇ | A → I₂ | 0.4463769737 |
| φ₈ | O → S | 15.74534018 |
| φ₉ | S → O | 1.914630060 |

The original-data arm uses the exact saved **201 noiseless samples on
[0, 0.98]**, generated with R(0) = 1 and all other states initially zero.
An exact symbolic check verifies all six ODE identities against the retained
SBML coefficient extraction. Independent native integration agrees with the
previous signal to **7.50 × 10⁻¹³ maximum relative signal error**. Estimation
then receives the saved samples, rather than replacement simulation values.

All six ICs remain unknown to the estimator, as in the preceding synthetic
dense-data study. The published initial values generate the data; they are
not imposed as estimation constraints. This is a controlled synthetic
tractability experiment, not a fit to the original noisy PEtab measurements
or its likelihood.

The new parameterization retains the original numerical time scales. The
Float64 eigenvalues of the generating state matrix are approximately

```text
0, −1.27159, −1.32443, −5.53776, −49.22772, −12685.80239.
```

The zero eigenvalue follows exactly from conservation; its numerical residual
is about 7 × 10⁻¹³. The fastest decay time is about 7.88 × 10⁻⁵, whereas sample
spacing is 0.0049, roughly 62 fastest decay times. Thus 201 samples do not
resolve every time scale merely because they are dense compared with the
published measurements. These generator diagnostics are not fit evidence.

## What is identifiable in this separate problem

For the linear output w = 0.9 A + 0.1 O and the 6×6 state matrix B(φ),

```text
χ_B(λ) = λ⁶ + c₅ λ⁵ + c₄ λ⁴ + c₃ λ³ + c₂ λ² + c₁ λ

w⁽⁶⁾ + c₅ w⁽⁵⁾ + c₄ w⁽⁴⁾ + c₃ w⁽³⁾ + c₂ w″ + c₁ w′ = 0.
```

There are five independent characteristic coefficients. Their map from nine
rates has generic rank five: at the exact rational rate point
(2,3,5,7,11,13,17,19,23), a 5×5 Jacobian minor is −9,962,816,668. At the same
point the six-state observability determinant is
16,021,470,469,634,469 / 625, hence the six unknown states can supply arbitrary
initial w-jets locally. The rate map therefore leaves a generic
**four-dimensional continuous ambiguity** when all ICs are free. These are
exact nonzero-minor proofs, not floating-point rank estimates.

The quartic observation y = w⁴ preserves this local dimension where w ≠ 0;
it adds branch ambiguity rather than additional independent rate information.
The actual trajectory starts at w = 0, so this local statement is applied at
generic interior anchors, not at that special endpoint.

Recovering all nine generating rates uniquely is consequently not the success
criterion for this experiment. A fitted trajectory and agreement of identifiable
coefficient combinations would be informative. The ordinary ODEPE structural
fixing step must still choose a representative of the continuous ambiguity.
The previous rational-kinetic M = 544 does not apply to this free-rate model.

## Selected algebraic system

The normal local-SI request takes 3.20 seconds including compilation and selects
four representative assignments, φ₁ = φ₂ = φ₃ = φ₄ = 1 in solver coordinates.
The template reaches HC after 190.52 seconds of estimation, following 95.17
seconds of package/model preparation. Candidate selection itself takes 52.642
seconds and chooses K = 10. These are instrumented cold-run timings, not a
controlled performance comparison.

| Quantity | Previous rational kinetics | Independent rates |
|---|---:|---:|
| Equations / unknowns | 72 / 72 | 72 / 72 |
| Free parameters after representative fixing | 5 | 5 |
| Anchor states | 6 | 6 |
| Auxiliary state derivatives | 61 | 61 |
| Observation derivative orders | 0–10 | 0–10 |
| Monomials | 2,362 | 1,306 |
| Maximum equation degree in unknowns | 6 | 4 |
| Largest equation | 272 monomials | 272 monomials |

The new equations comprise **19 linear, 42 quadratic and 11 quartic** rows.
The quartic observation still generates the largest expressions. Rate lifting
removes the rational coefficients and lowers degrees, but does not eliminate
the auxiliary state jets in the ordinary construction.

The ordinary generic-start method returns no starts after **958.568 seconds**,
logging:

```text
OverflowError("-4798045382528 * -11403264 overflowed for type Int64")
```

Total estimation time is 1,150.25 seconds, within its 1,800-second cap; the
supervisor records 1,273.44 seconds including loading/preparation and shutdown.
This is an actual arithmetic failure, not a watchdog timeout. The last
displayed partial mixed volume is 2,389,842; it is **not a completed volume,
an established lower bound, a root count, or M**. No tracked roots or trajectory
candidates are returned. Execution stops during the first configured
interpolator's generic-start solve; the nine interpolators and twenty real
anchor solves are not completed.

Live stacks place the computation inside `MixedSubdivisions.fine_mixed_cells`
while constructing the polyhedral starts. The production wrapper records the
exception message, not its throwing backtrace, so this evidence does not
identify the overflowing operands' precise meaning. In particular it does not
show that the true root count exceeds Int64. The explicit multiplication error
also differs from the preceding experiment's generic
`Cannot compute a start system` wrapper error.

The generic complex data-jet solve precedes the actual measured-jet targets.
For the same selected support, changing interpolators or the generating rates
would not remove this structural mixed-cell calculation. This result supports
reducing the algebraic representation further; it is not a proof that every
coefficient-based formulation is intractable.

## A separate positivity issue with the representative

The automatic algebraic representative need not intersect the physical positive
parameter region for a particular trajectory. Here the chosen φ₄ = 1 is also
one in physical time units: this follows directly from the captured
I₁′ + I₁ − R equation. State rescaling cancels out of a diagonal coefficient,
and current automatic problem rescaling does not rescale time.

For strictly positive rates, this bidirectional tree generator is diagonally
similar to a symmetric matrix. The principal block of its negative generator
on the two leaves I₁ and I₂ is φ₄ I₂. Eigenvalue interlacing then gives

```text
smallest nonzero decay rate ≤ φ₄.
```

The native generating trajectory excites and observes all six modes: exact
rational observability and initial-vector Krylov determinants are nonzero.
Its five nonzero decay rates all exceed one; an exact root count on [0, 1]
of the degree-five characteristic factor confirms zero roots there. Therefore
the fixed φ₄ = 1 slice cannot reproduce that **complete trajectory exactly
with strictly positive rates**. This statement is about the raw algebraic
representative. It does not exclude approximate agreement at finite samples,
or later trajectory polishing that releases the representative parameters.

This is distinct from the computational cost of the generic complex HC solve.
It also means that a future positive recovery control should use compatible
representatives or target the five identifiable coefficient combinations
directly, rather than interpret a lack of positive roots on this slice as a
failure of the free-rate model class itself. No production fixing policy was
changed during this trial.

## A smaller coefficient problem to try next

Estimating the nine reaction rates is different from estimating the five
input-output coefficients c₁,…,c₅. The latter admit a small linear system:

```text
Σⱼ₌₁⁵ cⱼ w⁽ʲ⁺ʳ⁾ = −w⁽⁶⁺ʳ⁾,    r = 0,…,4.
```

Given w-jets through order ten, these are five equations linear in five
unknown coefficients. At a nonzero observation anchor, w⁴ = y and its
successive derivatives determine w-jets triangularly after choosing a fourth
root for w. Multiplying that branch by a fourth root of unity multiplies every
row's two sides by the same factor, leaving the c's unchanged.

This suggests a substantially smaller research inverse problem than the
expanded state-jet HC system. It does not itself demonstrate estimation from
sampled data: recovering high-order derivatives, especially an unresolved
fast mode, remains a numerical question. A subsequent map back to nine
reaction rates would again be nonunique without additional information.
This linear-coefficient estimator is a proposed next experiment, not an
implemented production change or a successful fit claimed by this record.

## Estimator settings and reproduction

The trial explicitly uses one experiment and single-point estimation only:
20 separately solved shooting locations, exponential warp β = 3, and all nine
usual interpolators. Twenty anchors are not a coupled twenty-point system.
Data are noiseless. Both root polishing and bounded-log trajectory polishing
are enabled, with 120 seconds per trajectory polish and ODE tolerances 10⁻¹².
The bounds are broad [0, 10⁶] on states and independent rates, since the old
kinetic-parameter box does not induce a rectangular box on the free rates.
Terminal direct optimization and UQ are disabled.

M counting and candidate-selection MV scoring are disabled using existing
options. Ordinary HC polyhedral generic-start solving is retained. A research
hook records the selected family, then invokes the original production method;
if it returns no starts, this diagnostic stops instead of triggering fresh
solves at each anchor. The complete settings are saved with the result.

The [standalone reproducer](../repro/sneyd_free_coefficients_2026_09_15/README.md)
contains the exact source extraction checks, native Julia model, bounded
worker, and independent characteristic-coefficient analysis. All changes in
this follow-up are research scripts and documentation; production source and
dependency manifests are unchanged.

The [retained evidence](../repro/sneyd_free_coefficients_2026_09_15/evidence/validation.json)
verifies the bit-identical samples, source snapshots, selected-system hash,
unchanged dependency manifests, and exact invariant checks. Two preliminary
driver attempts failed on data-key container types before entering estimation;
their preparation records are retained separately. The one actual estimation
attempt is the run described above. Python/Julia syntax checks pass. The full
production gate was not rerun for these research-only additions.
