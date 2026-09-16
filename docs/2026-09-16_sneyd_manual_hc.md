# Sneyd: manual joint estimation from true prepared derivatives

The known-preparation, fully coupled problem is tractable after exploiting its
coefficient structure. All 12 independent kinetic combinations are recovered
from exact oracle derivatives at both a moderate parameter vector and the
SBML nominal values. Eight combinations follow from rational interpolation
and linear solves. The remaining HC problem has four unknowns and six distinct
quadratic equations, with seven terms per equation. Exact constant row
operations reduce it further and produce a unique solution.

No original kinetic parameter value or starting root is supplied to HC. No
production code, dependency, or default estimator setting changes in this study.

## Exact problem used

This follows the [prepared derivative-rank study](2026-09-16_sneyd_prepared_jets.md).
Use all nine PEtab condition records (eight distinct Ca/IP3 pairs), the shared
14 kinetic parameters, and the prescribed state

```text
(A, I₁, I₂, O, R, S)(0) = (0, 0, 0, 0, 1, 0).
z = (9A + O)/10,    y = z⁴.
```

For each condition, the oracle obtains z′(0), z″(0), z‴(0) by multiplying
the independently validated SBML generator Q into the initial vector. All
arithmetic in oracle generation and algebraic preprocessing is rational.
The nominal vector uses the SBML decimal values, which differ from the PEtab
parameter-table decimals in the last few digits. The moderate vector is the
same seeded positive integer vector used in the rank study.

The fully stacked problem consists of 27 rooted moment equations in the
shared kinetic parameters. The two continuous redundancies are removed by
using the 12-combination parameterization from the preceding report. Initial
states are fixed, inputs retain their actual condition values, and rates in
different conditions remain linked through the original kinetic formulas.
There is no separate free-rate model per experiment.

The target is recovery of these 12 combinations, and hence the generators in
every condition. The 14 individual kinetic constants remain nonunique.

## Data-dependent elimination

Write c = Ca and p = IP3, and define the combinations from the rank report:

```text
δ = L₁ L₃/(L₁ + L₃)
α = L₁ ℓ₄/(L₁ + L₃),  β = δ k₂,  γ = L₃ U₁/(L₁ + L₃)
b₁ = 8U₅ − L₅ ℓ₋₄,   b₀ = −L₅(k₋₂ + k₃),   s = L₅.
```

First derivatives determine α, β, δ by the linear equations

```text
rₑ = 10 zₑ′ / pₑ
α cₑ + β − rₑ δ = rₑ cₑ.
```

For the second derivatives let φ₂ₑ = 10zₑ′ and

```text
qₑ = 10zₑ″/φ₂ₑ + φ₂ₑ
q(c) = (b₁c + b₀)/(c+s) − γc/(c+δ).
```

The function q(c)(c+δ) has a quadratic numerator and a monic linear
denominator c+s. Fitting its four coefficients is another linear solve using
all condition rows. It gives s, b₀, γ, b₁, provided δ ≠ s; this holds for both
parameter vectors. The exact overdetermined equations are checked for
consistency, not fitted approximately.

Finally, at the repeated Ca = 0.4 with different IP3 inputs, remove the known
terms from the third derivative equation. The remainder is affine in φ₂,
with slope φ₁. Its differences determine r = k₋₂. This uses the actual
IP3-condition variation; all matching-input differences agree exactly.

Thus α, β, δ, γ, b₁, b₀, s, r are determined from the derivative data. The
remaining unknowns are

```text
w = L₁,    v₁ = V₁,    v₅ = V₅,    v₉ = k₋₃.
```

The full 12-combination vector is reconstructed by

```text
L₁ = w                   U₁ = γw/δ          V₁ = v₁
L₅ = s                   U₅ = (b₁+sαr/β)/8 V₅ = v₅
k₂ = β/δ                 k₋₂ = r
ℓ₄ = αw/(w−δ)            ℓ₋₄ = αr/β
k₃ = −b₀/s − r           k₋₃ = v₉.
```

All denominators are checked, and the recovered combinations are positive.
This preprocessing uses measured oracle derivatives, not generating parameter
values. The exact target vector is stored separately for validation.

## The actual HC equations

At this point φ₁, φ₂, φ₃, φ₅, φ₈ are known in every condition. Define

```text
uₑ = φ₂ₑ + φ₃ₑ
vₑ = φ₁ₑ + φ₅ₑ + φ₈ₑ
Tₑ = 10zₑ‴/φ₂ₑ − uₑ² − φ₁ₑφ₂ₑ − (vₑ−9φ₅ₑ)(uₑ+vₑ).
```

The remaining third-derivative equations, after multiplying by cₑ+w, are

```text
Fₑ = (cₑ+w)(φ₃ₑv₁ + φ₈ₑv₉ − Tₑ)
       − φ₅ₑw(8v₅ + 9γcₑ/δ) = 0.
```

Each has exactly seven monomials:

```text
w v₁,  w v₅,  w v₉,  w,  v₁,  v₉,  1.
```

There are nine retained rows and six distinct equations, one per distinct Ca.
The IP3 variation has already supplied the equation determining r. A square
subset is selected by an exact Jacobian-rank check at an unrelated rational
point; its four quadratics contain 28 terms in total. HC's affine polyhedral
start count is 3; the total-degree bound is 16. These counts are solver start
counts, not a claim about physical multiplicity.

The full coefficient matrix in the seven monomials has rank 5. Exact constant
row operations give an equivalent five-equation basis. For the nominal data,
rounded here solely for display, that basis is

```text
w v₁ − 0.8523198105517544                                      = 0
w v₅ − 0.000019693828910711008 v₉ − 2063.9293211789927          = 0
w v₉ − 1.2833367459390381                                      = 0
w    − 0.6702792215159699                                      = 0
v₁   − 1.271589187300277                                       = 0.
```

All these constants were obtained from the oracle derivatives by row
operations. In particular, the last two were not supplied as known parameters.
Once w is determined, the rest can be solved linearly. The validation script
does exactly that without reading the oracle vector, and proves a unique
solution of the full reduced equations for each tested data set. A selected
four-equation subset of this basis has three quadratics and one linear
equation; its polyhedral start count is 1 and total-degree bound is 8.

## HC results and conditioning

The moderate case succeeds on both polyhedral and total-degree starts.
Solving the unreduced square subsystem produces two finite real roots; one
has negative rate combinations and fails the remaining condition equations.
HC's overdetermined solve rejects that extra root and retains the generating
model. The row-reduced system also returns the correct model.

For the nominal case, the recovered remaining parameters are

| Quantity | Generating / recovered value |
|---|---:|
| L₁ | 0.6702792215159699 |
| V₁ = k₋₁ + ℓ₋₂ | 1.271589187300277 |
| V₅ = k₋₄ + ℓ₋₆ | 3079.208324879 |
| k₋₃ | 1.91463005974811 |

The full row-reduced polyhedral solve uses two starts because HC internally
randomizes the overdetermined equations: one candidate succeeds, and one is
rejected as an excess solution. The successful returned candidate has maximum
relative error approximately 5.3 × 10⁻¹⁶ in the remaining parameters. The
selected row-reduced total-degree solve uses eight starts, seven end at
infinity, and the correct root is certified against the exact square system.
The latter has relative error approximately 2.1 × 10⁻¹⁶.

The unreduced nominal equations demonstrate a numerical trap. One polyhedral
run returns a candidate with V₁ ≈ 1996 + 2683i, while its normalized residual
is only 7.95 × 10⁻¹⁶. Its Jacobian condition estimate is about 2.93 × 10¹⁹.
This candidate does not recover the parameters and is not physically real.
The corresponding row-reduced full system has condition estimate about
1.22 × 10⁴ and recovers the nominal parameters. Total-degree solving of the
unreduced equations also reaches the correct nominal solution. All failed
calls and incorrect candidates are retained in the evidence.

Two exact-rational square-system polyhedral calls encounter an HC 2.22.4
entry-point `MethodError`: random start coefficient scaling promotes the
vectors to BigFloat or mixed element types, while `ToricHomotopy` expects
`Vector{Vector{ComplexF64}}`. This is separate from mixed-volume complexity.
The overdetermined entry path and total-degree path complete. An additional
control makes the Float64 coefficient boundary explicit and validates its
returned roots against the saved exact equations. The selected row-reduced
polyhedral control tracks one path, recovers the nominal solution to machine
precision (maximum relative error 1.30 × 10⁻¹⁶ across all 12 combinations),
and certifies it against the exact rational square system. Casting
alone does not fix the unreduced problem: its returned candidate has negative
V₁ ≈ −183. Results are retained in `hc_float.json` and
`validation_float.json`. No HC dependency is patched.

Measured setup plus tracking for the nominal full row-reduced polyhedral
solve is 0.535 s, of which approximately 0.534 s is reported as compilation.
The first moderate square solve costs 15.09 s of setup and 23.53 s of
tracking, almost entirely compilation. These measurements exclude package
loading and separate root certification. There is no long mixed-volume or
large path-count barrier for the reduced systems. The explicit Float64
single-path control takes 4.731 s for setup plus tracking, with about 0.00125 s
outside the reported compilation time. These are measurements of the saved
small systems, not timings for the whole manual derivation or package loading.

## Validation, quartic data, and limits

Independent exact elimination recovers all 12 kinetic combinations with zero
rational error. Unrefined HC errors are reported separately from 100-digit
Newton refinement on the full-data row-reduced equations. The latter recovers
the combinations, every condition's generator, and all 27 original rooted
derivative constraints to high precision. An incorrect subsystem candidate
moving to the full solution during this refinement does not retroactively
count as correct HC recovery.

The original quartic derivatives are also generated exactly:

```text
y⁽⁴⁾ = 24a⁴,   y⁽⁵⁾ = 240a³b,   y⁽⁶⁾ = 480a³d + 1080a²b²,
a = z′,        b = z″,            d = z‴.
```

Taking the positive fourth root of y⁽⁴⁾/24, then solving for b and d, produces
exactly the same rooted derivatives and reduced HC input. Positivity selects
the physical branch because φ₂ = 10a > 0. This establishes equivalence for
these exact physical oracle jets; a direct HC enumeration of the unreduced
quartic complex branches was not performed.

The result is a manual estimation using oracle derivatives and substantial
data-dependent algebraic elimination. It does not establish that a direct
uneliminated 27-equation/12-variable HC call is fast. Exact rational
preprocessing matters at the nominal values: the original equations are
badly conditioned. No derivatives were estimated from samples, no noisy fit
was attempted, and exact row reduction of inconsistent noisy equations would
not provide the same procedure. These remain separate estimation questions.

Scripts, exact inputs, all HC outcomes, and validation are in the
[research harness](../repro/sneyd_manual_hc_2026_09_16/README.md).
