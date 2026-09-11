# Sneyd fraction cancellation and Fujita polynomial structure

This inspects the September 11 dense single-experiment attempts at `74af786`.
It changes no production algorithms or dependencies.

## What the GCD is for

[`clear_denoms`](../src/core/math_utils.jl) calls `simplify_fractions` on both
sides, obtains numerator/denominator pairs, and cross-multiplies them. The
simplifier combines rational sums and cancels common polynomial factors. This
use of `simplify_fractions` is present as far back as commit `d9f062c` on
May 31, 2024; it was not introduced for the PEtab pilot. The inspected history
does not contain a separate design justification for choosing that backend.

The mathematical reason to retain cancellation is substantial. For example,

```text
(p² - 1) / ((p - 1) q) = z, with p ≠ 1 and q ≠ 0
```

Cross-multiplying without cancellation gives `(p - 1)(p + 1 - z q) = 0`.
After cancelling the common factor it gives `p + 1 - z q = 0`.
The uncancelled version has higher degree and an entire artificial component
`p = 1`. Even after cancellation, the original denominator exclusions still
matter; cancellation alone does not encode the domain of a rational ODE.

The installed SymbolicUtils implementation performs a cheap structural
`quick_cancel`, combines sums of fractions, converts numerator and denominator
to expanded DynamicPolynomials, and invokes a polynomial GCD. The installed
MultivariatePolynomials implementation recursively isolates one variable,
treats the remaining variables as polynomial coefficients, and uses a
subresultant algorithm. This is considerably more work than multiplying by a
denominator. The current helper does not impose a work budget on simplification.

Sneyd's fixed-condition state equations are linear in six states, but their
coefficients are nested rational expressions in fourteen unknown parameters.
Its observable is a fourth power of a linear state combination. Writing
`x' = A(p)x` and `L = c'x`, its second observation derivative has the compact form

```text
y'' = 12 L² (c'Ax)² + 4 L³ (c'A²x).
```

It is still quartic in the states. Expanding and combining all the rational
parameter coefficients is the expensive part. In particular, the fraction
combiner multiplies denominators; it does not first compute their least common
multiple. Repeated denominators can therefore grow before the GCD removes
their common factors. The original profile first showed polynomial conversion
and expansion, then recursive GCD with Float64 coefficients. Compilation was
also present. The profile establishes these costs, but does not establish an
intrinsic lower bound on the difficulty of simplifying Sneyd.

A [follow-up trace](../repro/petab/dense_single/evidence/sneyd_fraction_expansion_trace.json)
retains the actual second-derivative expression and state equations. Its
210-second whole-worker limit includes loading and model construction, unlike
the earlier 180-second isolated simplification limit. It was interrupted while
expanding the numerator in `to_poly!`, before reaching the GCD-input recording
hook for that expression. It therefore does not supply a completed expanded
input size or a new isolated GCD timing. The hook's `variables` field counts
representation slots, including unused slots; it is not used for support counts.

The previous 0.024-second fraction-flattening measurement is not a validated
replacement for cancellation: it retained a larger representation. Sensible
follow-up experiments are to simplify the small rational rate coefficients
before constructing higher observation derivatives, preserve shared denominator
factors, and compare GCD backends on a captured input. Any replacement must check
the resulting degrees, denominator-zero artifacts, and solver workload.

## Fujita's saved template

The [saved-template report](../repro/petab/dense_single/evidence/fujita_template_support.json)
and [full-pool report](../repro/petab/dense_single/evidence/fujita_full_pool_support.json)
count equations with SymPy, independently of Julia's displayed size diagnostics.
Observable jets are coefficients, not solve unknowns. A constant
term counts as one monomial. Repeated occurrences in different equations count
separately in the total; the cross-equation union is also reported.

| Quantity | Saved template | Full selection pool |
|---|---:|---:|
| Equations | 85 | 88 |
| Algebraic solve unknowns | 85 | 85 |
| Observable-data coefficients actually used | 23 | 26 |
| Monomial occurrences across equations | 466 | 474 |
| Distinct monomials across the entire system | 239 | 244 |
| Terms in one equation | 2–13 | 2–13 |
| Quadratic equations | 65 | 68 |
| Cubic equations | 20 | 20 |
| Highest power of any individual unknown in a monomial | 1 | 1 |

All equations are multiaffine: each individual variable appears only to the
first power, although products of two or three different unknowns occur.
This does not make an 85-dimensional mixed-volume computation automatically easy.

The unknowns comprise fourteen remaining kinetic/observable-scale parameters,
nine state values at the anchor, and sixty-two higher state derivatives at that
same anchor. Before fixing two structural representatives, there were sixteen
parameters. The saved template has 62 differentiated ODE equations and 23
observation equations.

| State | Jet orders retained |
|---|---|
| `EGFR` | 0–5 |
| `EGF_EGFR`, `Akt` | 0–6 |
| `pEGFR`, `pEGFR_Akt`, `S6` | 0–7 |
| `pAkt`, `pAkt_S6`, `pS6` | 0–8 |

The observation coefficients are `y1` orders 0–6 and `y2`/`y3` orders 0–7.
`pAkt_8` means the eighth derivative of `pAkt` at the current anchor; it is not
another physical state or another experiment.

For example, using `P=pS6`, `C=pAkt_S6`, `A=pAkt`, `S=S6`, and abbreviating rate
and scale names, actual equations from the internally rescaled template are

```text
y3_0 - s3 P_0 = 0
P_1 - k6 C_0 + k8 P_0 = 0
C_1 - S_0 A_0 + (k5b + k6) C_0 = 0
C_3 - S_0 A_2 - 2 S_1 A_1 - S_2 A_0 + (k5b + k6) C_2 = 0
```

Here `reaction_5_k1` was fixed to 1 as a structural representative in the
rescaled coordinates. The binomial coefficients in higher equations come from
Leibniz's rule. Cubic terms occur where an unknown rate multiplies two state
jets, for example `reaction_2_k1_0 * Akt_1 * pEGFR_0`.

The original run's retained `noise_rank_matrix` record gives the larger
selection pool as **88 equations, 85 unknowns, numerical rank 85**. The saved
85-equation template is not a capture of the exact basis inside the interrupted
mixed-volume call. The selection code considers square rank-complete bases and
computes their mixed volumes before printing the final selected candidate.

For this inspection, the low-level SIAN constructor was rerun with its existing
`compute_multiplicity=false` option, avoiding global SI, multiplicity, and HC.
The SIAN call completed in 38.8 seconds, excluding import/model preparation.
The same two representative substitutions were then applied. All 85 previously
saved equations matched the reconstructed pool exactly up to sign and ordering.
The three additional equations are

```text
y3_8 - s3 pS6_8 = 0
y2_8 - s2 (pAkt_8 + pAkt_S6_8) = 0
y1_7 - s1 (pEGFR_7 + pEGFR_Akt_7) = 0
```

Thus the full pool includes observation derivatives through order 8. The earlier
statement about order 7 applies to the saved, rank-trimmed template. The unused
order-21 failure remains spurious in either case. A square rank-complete basis
submitted to mixed volume has 85 equations and 85 unknowns; the exact row choice
at the interrupted call was not saved, so its individual monomial count is not
claimed to be exactly 466.

Readable [saved-template equations](../repro/petab/dense_single/evidence/fujita_template_equations.txt)
and [all 88 pool equations](../repro/petab/dense_single/evidence/fujita_full_pool_equations.txt)
are retained alongside the JSON reports.

Mixed volume uses the supports as Newton polytopes and performs a combinatorial
mixed-cell computation. It need not be cheap merely because the input is sparse
and cubic. The interrupt was inside `MixedSubdivisions.next_cell!`, before HC
root tracking. We still do not have its mixed-volume value.

The 20-minute cutoff covered the entire estimator, with 738.8 seconds in SI
template preparation. It was not a separate 20-minute mixed-volume allowance.

There is nevertheless concrete structure to investigate: the higher state jets
have triangular, unit-coefficient defining ODE equations. Eliminating all 62
would leave 23 anchor-state/parameter unknowns, but could greatly increase
degrees and monomial counts. Controlled elimination, with support counts after
each step, is a more informative next experiment than declaring the underlying
recovery problem infeasible. No elimination policy has been changed here.
