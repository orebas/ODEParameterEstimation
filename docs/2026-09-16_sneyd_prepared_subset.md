# Sneyd: subset selection on the complete prepared system

The existing ODEPE subset selector successfully reduces the full prepared
27-row problem to 12 original equations in all 12 unknowns. It selects three
first-, four second-, and five third-derivative rows. Independent exact checks
confirm rank 12 at both generating vectors. HC's affine polyhedral setup
needs 1,864 start paths and computes the mixed cells in about two seconds.
The direct 12-variable HC solve recovers the moderate generating vector to
about 8×10⁻¹³ relative error and satisfies all 27 original rational rows.
The nominal solve does not recover a root, with either HC compilation backend.

The preceding [manual HC study](2026-09-16_sneyd_manual_hc.md) instead inferred eight
combinations from data before solving a four-variable system. That
data-dependent reduction is not performed here.

## Problem and construction

Use all nine PEtab condition records (eight distinct Ca/IP3 pairs), the known
initial state `(A,I₁,I₂,O,R,S) = (0,0,0,0,1,0)`, and the rooted observable
`z = (9A + O)/10`. The 12 unknowns remain

```text
η = (L₁, U₁, V₁, L₅, U₅, V₅, k₂, k₋₂, ℓ₄, ℓ₋₄, k₃, k₋₃).
```

For each condition, the three rows are

```text
g₁(η) = φ₂/10
g₂(η) = φ₂(9φ₅ − u − v)/10
g₃(η) = φ₂[u² + φ₁φ₂ + φ₄φ₃ + (v−9φ₅)(u+v)
             − 8φ₅φ₆ − 9φ₅φ₇ + φ₈φ₉]/10,

u = φ₂ + φ₃,    v = φ₁ + φ₅ + φ₈,
gₖ(η; Caₑ, IP3ₑ) − zₑ⁽ᵏ⁾(0) = 0.
```

The input-dependent φ formulas are exactly those in the
[prepared-rank report](2026-09-16_sneyd_prepared_jets.md). Initial states are
already substituted; none are unknown. There are no interpolators, estimated
derivative values, random state anchors, or kinetic values supplied to the
solver. Exact derivative targets come from powers of the independently
SBML-validated generator Q. Both the moderate and SBML nominal datasets from
the previous study are retained.

SymPy polynomial arithmetic exports exact numerator/denominator pairs for
each rational gₖ. After multiplying through the denominator, each row is
`Nₖ(η) − dₖDₖ(η)`, with dₖ still symbolic during selection:

| Derivative | Degree in η | Numerator terms | Denominator terms | Terms with data substituted |
|---|---:|---:|---:|---:|
| z′ | 4 | 2 | 3 | 5 |
| z″ | 9 | 31 | 12 | 43 |
| z‴ | 15 | 462 | 42 | 504 |

The exact construction is checked against matrix-power derivatives at both
datasets. A separate implementation also checks the exported rational maps
at a generic probe and both generating vectors over each of two finite
fields. The full rank profile is 3, 7, 12 through orders 1, 2, 3.

## Selector settings

`select.jl` calls the actual `ODEParameterEstimation._noise_select_pool`.
Its rank matrix uses the rational observation map, before clearing
denominators. The existing materialization callback supplies the polynomials
only when the derivative cap admits full rank. The supplied model provides
symbol roles; its trajectory is never solved.

The candidate limit is 64, beam width 16, rank tolerance 10⁻⁸, and there are
three seeded generic Jacobian probes. Candidate mixed-volume scoring is
explicitly **disabled**. The existing support-score and tie-breaking branch
chooses a subset, whose HC solve then performs its required polyhedral setup.
This avoids paying for many candidate mixed-volume calculations and is not a
measurement of the default mixed-volume-ranked selector.

Selection takes 20.32 seconds, including 18.46 seconds of Julia compilation.
Total process wall time is 426.08 seconds including cold package loading and
pool construction. The selector returns 18 candidates; its chosen row indices
are `1 2 3 4 5 6 10 11 12 14 15 21` (one-based, condition-major order).

| Ca | IP3 | Selected derivatives |
|---:|---:|---|
| 0.1 | 10 | z′, z″, z‴ |
| 0.2 | 10 | z′, z″, z‴ |
| 1 | 10 | z′, z″, z‴ |
| 3 | 10 | z″, z‴ |
| 0.4 | 3 | z‴ |

The selected equations contain 2,707 terms after substituting derivative data.
Their total-degree product bound is 318,864,600,000; the much smaller polyhedral
count reflects their sparse structure. The remaining 15 rows are validation
constraints.

Seventeen candidates have the same derivative histogram (3,4,5) and identical
polynomial support multisets. Their mixed volumes therefore agree. The last
candidate uses (0,4,8), with a different support multiset; its mixed volume is
not measured here. Candidate support scores are 250.088–250.349 for the former
group and 346.05 for the latter. The chosen candidate's generic unscaled
Jacobian condition proxy is about 1.05×10¹¹. Rank completeness does not imply
good numerical conditioning.

## HC experiment

The selected original rows enter HC in all 12 variables. No parameter is
eliminated from data, no equations are combined by row operations, and no
generating root is supplied. Rows are divided by their largest exact
coefficient and cast to Float64 at the HC boundary. HC uses its default
affine polyhedral setup, seed 20260916, and one thread. Both `compile=:all`
and HC's existing interpreted backend (`compile=false`) are tested.
Unknown kinetic coordinates are not rescaled. Returned endpoints are
retained for checking all 27 rational equations, including unselected rows.

The compiled nominal solve spends about 16 minutes before its first completed
path, with repeated profiles in LLVM register allocation. Interpreted execution
gets to path tracking much sooner. This is a backend option for the research
driver, not a dependency patch or a change to production defaults.

All four runs complete within their 1,800-second operation budgets and attempt
all 1,864 paths. Times below exclude package loading and include first-use
code generation and compilation inside the solve:

| Dataset | HC backend | HC operation time | Returned endpoints | Validated recovery |
|---|---|---:|---:|---|
| Moderate | Compiled | 1,327.61 s | 9 | Yes: maximum relative η error 7.97×10⁻¹³ |
| Moderate | Interpreted | 655.79 s | 9 | Yes: maximum relative η error 7.97×10⁻¹³ |
| Nominal | Compiled | 1,342.94 s | 0 | No |
| Nominal | Interpreted | 630.36 s | 0 | No |

Both moderate runs recover the generating vector, approximately

```text
η = (2.11157894737, 99.12, 84, 60.1071428571, 686.071428571,
     113, 74, 17, 62, 28, 99, 65).
```

For the recovered candidate, the maximum relative residual over all 27
original rational jet equations is 4.64×10⁻¹⁴; over the selected rows it is
1.96×10⁻¹⁶. Validation is independent, at 100-digit precision. No extra Newton
refinement or data-dependent parameter elimination is applied to these HC
endpoints. The other eight returned endpoints comprise six where the original
rational map is undefined and two nonpositive candidates that fit the selected
rows but fail held-out rows. For the latter, maximum held-out relative errors
are about 1.07 and 7.84×10⁻⁴.

The complete return-code counts are retained in the worker JSON files:

| Dataset/backend | At infinity | Successful endpoints | Other terminations |
|---|---:|---:|---:|
| Moderate/compiled | 1,551 | 9 | 304 |
| Moderate/interpreted | 1,555 | 9 | 300 |
| Nominal/compiled | 1,373 | 0 | 491 |
| Nominal/interpreted | 1,369 | 0 | 495 |

Other terminations include accuracy limits, extended-step limits, and step-size
limits. Thus completing the path loop does **not** establish root completeness.
The nominal problem has a known generating solution; zero recovered endpoints
is a numerical failure of these runs, not evidence that no solution exists.
These are cold, separate-process timings on this machine, not a comparison of
amortized performance when a compiled template is reused many times.

The start-path count from affine polyhedral setup includes support augmentation
by constant terms. It is not the physical multiplicity M. Denominator
clearing can also introduce solutions where the original rational map is
undefined, so a small polynomial residual alone would not establish recovery.
For example, all 27 cleared polynomials vanish identically on `L₁ = ℓ₄ = 0`;
this is an extraneous positive-dimensional component where the original map
is undefined. Its existence is checked directly from the exported monomials.

A separate oracle-only sensitivity check keeps the other 11 combinations
fixed and doubles V₁. The first two derivatives do not depend on V₁. At the
nominal vector, the resulting relative changes in z‴ range from 1.68×10⁻¹⁸ to
1.32×10⁻¹⁴ across the nine conditions; two of the nine third derivatives even
round to exactly the same Float64 values. At the moderate vector, the range
is 5.34×10⁻⁴ to 1.55×10⁻². This illustrates why exact rank 12 is a different
question from recovery in finite precision. It does not by itself explain
individual homotopy path failures. The earlier manual study performed its
data elimination in exact rational arithmetic before rounding the smaller HC
system.

A 100-digit SVD measures the dimensionless local Jacobian
`diag(1/g) J diag(η)`, using the known vectors only for this diagnostic:

| Dataset | Full 27 rows: κ₂ | Selected 12 rows: κ₂ |
|---|---:|---:|
| Moderate | 1.10×10⁵ | 1.60×10⁵ |
| Nominal | 1.05×10²² | 2.49×10³¹ |

Thus the selected rows are algebraically independent yet especially ill
conditioned at the nominal vector. The full nominal system is already
extremely sensitive. This diagnostic changes neither the selection probes
nor the HC input, and is not a prescription to scale using unknown truth.

## Reproduction and scope

Scripts, exact input coefficients, selector output, and solver evidence live
in [`repro/sneyd_prepared_subset_2026_09_16`](../repro/sneyd_prepared_subset_2026_09_16/README.md).
The pinned Julia environment is activated without dependency resolution.
The ODEPE baseline is commit `aed76a2`; environment, dependency, worker, and
core-source hashes are saved alongside the evidence. Every supervised worker
exits successfully. The exact construction checks, finite-field rank checks,
and independent full-system recovery checks are rerun for the saved results.
These are research scripts and documentation; production estimation code and
default settings are unchanged. This does not test noisy interpolation or
the full PEtab likelihood.
