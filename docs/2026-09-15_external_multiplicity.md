# Separate multiplicity counting and the Sneyd bypass experiment

## Running with a supplied or unknown M

`EstimationOptions(algebraic_multiplicity=M)` now skips automatic multiplicity
computation. Previously the value controlled result processing but the SI
template still computed M. The same skip decision reaches state rescue and
aggregate reconstruction, so those paths do not restart the calculation.

For an exploratory run with no established count:

```julia
opts = EstimationOptions(compute_algebraic_multiplicity=false)
```

This leaves `analysis.algebraic_multiplicity === nothing` and uses ordinary
`branch_top_k` filtering. It does not claim M = 1 or put a fabricated count in
the results. A supplied positive M retains its existing result-processing
semantics, including the M ≥ 2 branch handling. The default remains automatic
counting when no value is supplied. Structural classification, representative
fixing, derivative construction, and polynomial solving still run.

## A smaller, model-specific side calculation

The adapter extraction is useful here even though lifting all rate variables
did not unblock the original 73-variable Gröbner input. At one fixed condition,
Sneyd has linear state dynamics with rational parameter coefficients:

```text
x′ = A(θ)x
w  = 4 O + 9 A_state
y  = w⁴ / 2500                         (saved SI state/output coordinates)
χ_A(λ) = λ⁶ + c₅λ⁵ + c₄λ⁴ + c₃λ³ + c₂λ² + c₁λ
```

Conservation gives the zero constant coefficient of χ. After the same nine
representative assignments used by the dense diagnostic, five kinetic
parameters remain: `l4, l6, l_2, l_4, l_6`. Their maps to `c₁,…,c₅` are explicit
rational functions. Fixing a generic coefficient vector therefore gives five
polynomial equations in these five parameters, plus the original saturation
equation `zQ − 1 = 0`. This counter has **6 equations, 6 variables, 235 terms
after target substitution, and maximum degree 7**. Its parameterized family
has 283 terms. No rank-based equation deletion enters this side counter.

The exact matrix matches the saved rescaled SI model entry by entry. The
counter retains the original SI denominator domain, including factors that
may disappear when matrix entries are simplified. Its reference kinetic
point is `(2,3,5,7,11)`, chosen independently of the published nominal values
and the dense-data generator. This is a fresh generic reference fibre, not
the earlier frozen random output jet.

To relate this count to the state/parameter problem, twelve derivatives of
`y` give four choices for nonzero `w(0)` and then unique derivatives of `w`
for each choice. A nonsingular five-by-five moment matrix determines the
five characteristic coefficients through

```text
w⁽ʳ⁺⁶⁾ + c₅w⁽ʳ⁺⁵⁾ + ⋯ + c₁w⁽ʳ⁺¹⁾ = 0.
```

For an observable kinetic solution, the six-by-six observability matrix
`[C; CA; …; CA⁵]` uniquely reconstructs the six anchor states. There are then
four state branches per kinetic solution. The scripts check the moment and
observability ranks at the reference point, and the final fibre check tests
observability throughout the finite kinetic quotient.

This reduction is a Sneyd research script. It is not automatic coefficient
reparameterization in the estimator, and it does not impose the original
PEtab initial preparation. The dense experiment estimates all six initial
states freely. Physical bounds and positivity are not part of this complex
algebraic count.

## Root-count evidence

HC monodromy found **109 roots** in 60.73 seconds and stopped after ten loops
without a new root. HC's distinct-root certification accepted all 109.
Three roots had poor Float64 reconstruction residuals; refinement against
the exact rational equations at 100 decimal digits validated **all 109**,
including all twelve reconstructed linear-observable derivatives. They
account for 436 state/parameter branches.

The independent QQ Gröbner calculation completed in **107.97 seconds** and
returned dimension zero and quotient length **136**. Thus 109 did not account
for the full algebraic length. Monodromy's heuristic stopping condition is
not a completeness result; the [HC documentation](https://www.juliahomotopycontinuation.org/HomotopyContinuation.jl/stable/monodromy/)
also distinguishes root certification from completeness checking.

The follow-up quotient check confirms that both the observability determinant
and the six-equation Jacobian determinant are units in the finite QQ algebra.
It specializes the monic basis at prime 2,147,483,647, verifies good coefficient
denominators, the Gröbner property, unchanged leading monomials and quotient
dimension, then checks that adjoining either determinant gives the unit ideal.
The standard-monomial module specializes freely; a nonzero multiplication
determinant modulo this prime implies a nonzero determinant over QQ.

Thus all **136 kinetic solutions are simple and observable** at this reference
fibre, and the full state/parameter count is **4 × 136 = 544**. The check took
135.55 seconds, including a fresh 102.88-second QQ basis computation. The
109-root monodromy result missed 27 kinetic solutions.

The Gröbner calculations use exact arithmetic with the library's production
probabilistic algorithm. These records do not constitute a formally certified
Gröbner basis. Timings are individual measurements from concurrent validation
runs, not a controlled comparison of solvers.

## Dense estimation outcomes

Both runs use the existing single-condition diagnostic: 201 clean simulated
samples, nine interpolators, 20 shooting anchors, two-point multipoint
construction, and the same bounds and refinement settings. The ordinary
estimator receives the original ODE and fourth-power observation; it does
not use the smaller coefficient counter to solve the data-fitting problem.

With M left unknown, the run built the **72-equation, 72-unknown SI template**
and entered equation selection. The 1,200-second stage watchdog interrupted
`_noise_mixed_volume` inside `_noise_candidate_from_indices`, during mixed-volume
scoring of a candidate basis. This is after the M calculation was skipped,
before an estimation root was obtained. The worker measured 1,174.62 seconds
of estimation; the supervisor's wall-clock stage timer reported 1,200.79
seconds. Both clocks are retained in the evidence.

The supplied-M follow-up (`algebraic_multiplicity=544`) reached its shorter
600-second stage cap during `Symbolics.simplify` in
`_apply_prefixed_substitutions`. Both template passes logged that multiplicity
was skipped. The worker measured 586.38 seconds of estimation; the supervisor
reported 600.74 seconds. The input data are byte-identical to the first run,
the model records match, and the only option differences are the two M fields.

The worker reports `failed` with a `RuleRewriteError`, while the supervisor
records `timeout`. The interrupted stack is in SymbolicUtils rule matching;
its installed `Rule` implementation catches every exception and replaces it
with `RuleRewriteError`, dropping the original cause. This record treats the
run as a watchdog timeout, not evidence that the displayed algebraic rule is
incorrect. Neither run obtained parameter estimates. The shorter run does
not establish that supplying M makes simplification slower.

Knowing M does not remove mixed-volume work used by equation selection or
polyhedral solving. M describes the exact, consistent, representative-fixed
model fibre; a square subsystem with independently interpolated derivative
values can have a different algebraic solution count. The side count is not
used as a stopping target for that solver.

## Validation and reproduction

- Focused multiplicity contracts: **88/88**.
- Full Julia 1.13 `Pkg.test` gate: **2,247/2,247**.
- New end-to-end checks recover the small model with M unknown, with supplied
  M = 7, and with automatic M = 1. Timing metadata proves counting was skipped
  in the first two cases and performed in the last.
- No dependency versions or compatibility bounds changed. Tests retain the
  existing GP and SIAN development overrides; the registry-only gate and
  recovery benchmark were not rerun.

Commands, inputs, raw outcomes, and source hashes are in
[`repro/separate_m_2026_09_15`](../repro/separate_m_2026_09_15/README.md).
