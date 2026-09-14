# Multiplicity after structural representative fixing

## Problem and correction

After the local-SI change, Sneyd reached ODEPE's algebraic-multiplicity
calculation, but its nine representative assignments had not yet been applied
there. The full unfixed polynomial ideal was sent to Gröbner before the caller
substituted those assignments into the estimation template.

The multiplicity input now uses the same representative assignments as the
estimation template. When assignments are present, SIAN's existing
`sample_point(...; known_states_jet_form, known_values)` generates an exact
synthetic output jet on that slice. This API is also present in the installed
registered SIAN 1.8.0 source; no dependency changes are required.

The assignments are substituted into every original polynomial and the common
denominator Q. Fixed coordinates are removed from the polynomial ring before
adding the saturation equation zQ − 1 = 0. The code checks that the sample
satisfies every model polynomial and rejects assignments that make Q
identically zero. State assignments affect only their anchor values; the
original ODE generates their higher derivatives.

All original polynomial constraints are retained for multiplicity. Jacobian
row dependence at a generic sample is not sufficient to prove that deleting
a polynomial preserves all global algebraic branches. The existing template
construction and later template substitutions remain separate from this
multiplicity input preparation.

M now counts algebraic solutions of the representative-fixed problem,
including algebraic multiplicity. This does not establish that every global
branch of the unfixed model intersects the chosen slice, or that every slice
solution is physically feasible. Those limitations already apply to the
representative convention described in the
[local SI record](2026-09-14_local_si_basis.md).

## Coordinate rank test

The SIAN adapter previously classified a coordinate by comparing the Jacobian
rank after deleting its column against the number of equations. On Sneyd,
73 model equations have rank 72, so every comparison reported a rank deficit
and all 20 rate/initial-state coordinates were incorrectly labelled locally
identifiable. This incorrectly enabled the multiplicity step even when the
separate local SI analysis found every individual coordinate nonidentifiable.

The corrected test compares against the full Jacobian rank. The Jacobian is
evaluated once, and removing a coordinate must lower its rank to indicate
local identifiability. Multiplicity uses this test again on the fixed system.
Classification for template construction still evaluates the unfixed system;
structural result provenance still comes from the original SI analysis.

The projection helper's explanatory comments also incorrectly equated finite
ambiguity with global identifiability and described continuous freedoms as
locally identifiable. These comments are corrected; the projection algorithm
is retained for positive-dimensional inputs with finite-valued coordinates.

## Sneyd input measurement

The inspection script reconstructs the exact rescaled SI model retained by the
earlier SI-cost probe. It uses the current production construction prefix and
input-preparation helper, stopping before Gröbner. The fresh random seed is
20260914; these are not the stalled run's original random coefficients.

| Quantity | Unfixed | Fixed |
|---|---:|---:|
| Polynomials, including saturation | 74 | 74 |
| Ring variables, including z | 82 | 73 |
| Terms summed across polynomials | 2,919 | 2,706 |
| Maximum total polynomial degree | 10 | 6 |
| Model Jacobian rank, excluding saturation | 72 | 72 |
| Variables minus rank, excluding z | 9 | 0 |
| Largest coefficient numerator, decimal digits | 958 | 559 |
| Largest coefficient denominator, decimal digits | 807 | 413 |

The fixed input has 5 rate parameters, 6 anchor states, 61 higher state jets,
and z. All eleven remaining rate/anchor coordinates pass the local rank test.
Its exact sample satisfies all 74 polynomials, including saturation. This is
an input/rank check, not a completed Gröbner calculation.

The actual observation equations in this input use orders 0 through 11. The
previously logged derivative-support dictionary extends through order 21;
that dictionary maximum is not the maximum output order present here.

## Validation

The focused contracts passed **71/71** on Julia 1.13 (5.7s testset time).
They cover dependent-row
classification, parameter and state-at-anchor assignments, finite sign
branches, fractional fixed values, consistent synthetic jets, denominator
substitution/poles, and redundant observations that remove an algebraic
branch.

The full isolated `Pkg.test` gate passed **2,230/2,230** (23m18.5s testset
time), including the new contracts and the existing identifiability,
estimation, rational-derivative, and UQ regressions. Source and test hashes
were verified after the gates. Dependency versions and the global and
optional-PEtab manifests are unchanged; these runs retain the existing
GaussianProcesses and SIAN development checkouts.

Benchmark smoke passed **10/10** (15m26.0s testset time). The four reported
best-of-branch errors match the previous local-SI run exactly:

| Case | Maximum relative parameter error |
|---|---:|
| Noisy Lotka–Volterra | 5.62764 × 10⁻⁵ |
| Simple | 6.35091 × 10⁻⁹ |
| Clean Lotka–Volterra | 1.01690 × 10⁻¹⁰ |
| HIV with rescaling | 3.41889 × 10⁻⁸ |

The frozen FitzHugh–Nagumo recovery completed in 550.0s on the worker timer.
Its best recovery record and fit error match the previous local-SI run
exactly: maximum relative parameter error 7.06050 × 10⁻¹¹, maximum relative
initial-state error 1.22446 × 10⁻¹⁰, fit error 1.84493 × 10⁻²³, and M = 1.

Biohydrogenation completed in 1,836.4s on the worker timer. Both ranked
recovery records and fit errors match the previous local-SI run exactly, with
M = 2. Its selected fit error is 9.37588 × 10⁻¹⁰, but k₁₀ remains 5.011696
against the generating value 0.741 (576.3% relative error). This is an
unchanged recovery limitation, not successful recovery of every parameter.
The unobserved x₇ anchor is the single fixed coordinate; its representative
value is not compared with the generating initial state as a recovery target.

Both comparisons use identical model/data hashes and options. All ranked
recovery dictionaries match exactly, not just the summary errors. Additional
representative-conditioned sampling can change downstream random-number
consumption; intermediate candidate counts and ordering need not match.
The overlapping cold runs do not support a runtime-speedup claim.

## Bounded Sneyd estimation

The production dense run used 201 clean samples, the normal nine
interpolators, 20 anchors, two-point multipoint estimation, and the local-SI
strategy. Local SI took 3.91229s. The flushed production log confirms the
same fixed input sizes as the inspection: 74 polynomials, 73 ring variables,
2,706 terms, maximum degree 6, nine assignments, and sampled linearized
dimension zero.

The run hit its configured 2,400s stage watchdog in the **initial modular F4
calculation**, inside `_groebner_guess_lucky_prime`. The final exception and
repeated stack samples identify that phase. No basis, multiplicity, HC solve,
or parameter estimates were obtained. Applying the substitutions corrects
the input but has not resolved Sneyd's Gröbner bottleneck.

The worker measured **2,162.2s (36m02.2s)** of estimation with its monotonic
timer, after 193.9s of preparation. The existing supervisor uses wall time
for its stage deadline and reported 2,404.1s; its monotonic total was
2,396.8s. These clocks disagreed during the run, so the configured 40-minute
limit should not be read as 40 minutes of measured estimation. The raw
records retain both durations. No runtime-speedup claim is supported.

Gröbner settings and the polynomial solver are unchanged. There is no new
timeout fallback or monodromy path in this correction.

Artifacts and reproduction commands:
[`repro/fixed_multiplicity_2026_09_14`](../repro/fixed_multiplicity_2026_09_14/README.md).
