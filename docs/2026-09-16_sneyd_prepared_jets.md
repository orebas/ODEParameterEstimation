# Sneyd: known preparation, joint conditions, and fully observed states

With the PEtab preparation imposed exactly, the nine-condition model reaches
its maximum local kinetic-parameter rank using rooted-output derivatives
through order **3**, or original quartic-output derivatives through order **6**.
That maximum is **12**, not 14: two continuous parameter redundancies are
present in the input-to-rate map itself. For the hypothetical fully observed
case, first derivatives at a later point suffice jointly across conditions.

These are derivative-information calculations, not an estimation run. No
production source, Julia dependency, interpolator, or solver setting changed.

## Model and scope

Source: `Benchmark-Models-PEtab`, revision
`ddaa86d13f708926c57ec8918ce75a6b50e2e562`,
`Benchmark-Models/Sneyd_PNAS2002`. Source file hashes and the exact condition
table are saved with the results. The probe checks its generator symbolically
against all SBML reactions after resolving assignment rules, checks the
initial concentrations and PEtab observable, and verifies column sums of zero.

There are nine condition records, eight distinct (Ca, IP3) input pairs, and
14 shared kinetic parameters. The Gaussian noise parameter is not included
in this deterministic ODE information calculation. Inputs are known constants
within each experiment. All conditions prescribe

```text
x = (A, I₁, I₂, O, R, S)ᵀ
x(0) = (0, 0, 0, 0, 1, 0)ᵀ
z = (9A + O)/10
y = z⁴                          original PEtab observable
x′ = Q(φ₁,…,φ₉) x
φ = φ(θ; Ca, IP3)               known rational formulas, shared θ
```

Here θ remains unknown; only the initial state and inputs are supplied.
Parameter evaluation points are used to inspect equation rank, not supplied
as known parameters to an estimator.

The generator corresponds to

```text
A′  = φ₄ I₂ + φ₅ O − (φ₆ + φ₇) A
I₁′ = φ₃ R − φ₄ I₁
I₂′ = φ₇ A − φ₄ I₂
O′  = φ₂ R + φ₆ A + φ₉ S − (φ₁ + φ₅ + φ₈) O
R′  = φ₁ O − (φ₂ + φ₃) R + φ₄ I₁
S′  = φ₈ O − φ₉ S.
```

## Algebra after plugging in the preparation

For condition e, let Qₑ = Q(φ(θ; Caₑ, IP3ₑ)) and
h = (9, 0, 0, 1, 0, 0)ᵀ/10. All states and state derivatives can be eliminated:

```text
xₑ⁽ᵏ⁾(0) = Qₑᵏ x(0)
zₑ⁽ᵏ⁾(0) = hᵀ Qₑᵏ x(0).
```

Equate the right sides to measured/estimated derivatives. With known
preparation there are no free anchor-state variables. These expressions are
polynomial in each condition's nine rates, and rational in the original
shared kinetic parameters. No Gröbner basis or mixed-volume calculation is
needed to construct these equations or inspect their Jacobian rank.

Suppress the condition index and set u = φ₂ + φ₃, v = φ₁ + φ₅ + φ₈. The first
three informative rooted-output equations are

```text
z′(0)   = φ₂ / 10
z″(0)   = φ₂ (9φ₅ − u − v) / 10
z‴(0)   = φ₂ [u² + φ₁φ₂ + φ₄φ₃ + (v − 9φ₅)(u + v)
               − 8φ₅φ₆ − 9φ₅φ₇ + φ₈φ₉] / 10.
```

For example, the first equation in original kinetic parameters is

```text
10 zₑ′(0) = IP3ₑ (Caₑ ℓ₄ + L₃ k₂)
                     / [Caₑ (1 + L₃/L₁) + L₃].
```

The nine conditions yield 27 equations through rooted order 3, or 24 after
removing the duplicate input pair. Their independent parameter information
has dimension 12. This count does not assert that all 24 equations are
independent, nor that the resulting polynomial solve is easy.

## Zero initial states and the quartic output

At preparation, O′ = φ₂ and I₁′ = φ₃ are the initially active receiving
states. A′, I₂′, and S′ vanish. In particular z(0) = 0 but z′(0) > 0 for the
positive parameters and inputs used here. Consequently

```text
y(0) = y′(0) = y″(0) = y‴(0) = 0.

a = z′(0),  b = z″(0),  d = z‴(0)
y⁽⁴⁾(0) = 24 a⁴
y⁽⁵⁾(0) = 240 a³ b
y⁽⁶⁾(0) = 480 a³ d + 1080 a² b².
```

Thus the original quartic loses three derivative orders at this zero.
The transformation between the three displayed rooted derivatives and the
three quartic derivatives has nonsingular Jacobian when a ≠ 0; a > 0 picks
the physical fourth-root branch. At a positive z anchor, the map z ↦ z⁴
instead has nonzero first derivative and introduces no such order delay.
This is a statement about exact clean trajectories, not a prescription to
fourth-root noisy measurements near zero.

The prepared joint ranks are:

| Maximum derivative order | Rooted output z | Original output y | All six states, hypothetical |
|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 |
| 1 | 3 | 0 | 4 |
| 2 | 7 | 0 | 9 |
| 3 | 12 | 0 | 12 |
| 4 | 12 | 3 | 12 |
| 5 | 12 | 7 | 12 |
| 6 | 12 | 12 | 12 |

These are ranks with respect to the 14 kinetic parameters, with known state
values held fixed. The probe also checks higher orders through 12.

## Why 14 kinetic constants provide only 12 independent directions

The group (k₁, ℓ₂, k₋₁, ℓ₋₂) enters every rate through only

```text
L₁ = k₋₁ ℓ₂ / (k₁ ℓ₋₂)
U₁ = L₁ k₁ + ℓ₂
V₁ = k₋₁ + ℓ₋₂.
```

Likewise (k₄, ℓ₆, k₋₄, ℓ₋₆) enters only through

```text
L₅ = k₋₄ ℓ₆ / (k₄ ℓ₋₆)
U₅ = L₅ k₄ + ℓ₆
V₅ = k₋₄ + ℓ₋₆.
```

Together with k₂, k₋₂, ℓ₄, ℓ₋₄, k₃, k₋₃, these are 12 combinations.
The probe verifies symbolically that they reconstruct every rate for arbitrary
Ca and IP3. The rank cannot exceed 12 regardless of the number of conditions,
derivatives, or observed states. This is an exact upper bound.

For either four-parameter group, fix its L, U, V and choose any a satisfying
0 < a < U/L. The following continuously varying positive parameters preserve
all three combinations:

```text
forward_a     = a
forward_other = U − L a
reverse_a     = L a V / U
reverse_other = (1 − L a/U) V.
```

Use a = k₁ or k₄ for the two respective groups. Thus each supplies a genuine
continuous ambiguity, even with perfect observation of all trajectories.
Parameter bounds may restrict the allowed families; they do not supply extra
ODE information. A rank of 12 does not settle discrete/global ambiguities
among the 12 combinations.

There is also a simple exact upper bound of 7 through rooted order 2. Define

```text
δ = L₁ L₃/(L₁ + L₃)
α = L₁ ℓ₄/(L₁ + L₃),  β = δ k₂,  γ = L₃ U₁/(L₁ + L₃)
b₁ = 8U₅ − L₅ ℓ₋₄,   b₀ = −L₅(k₋₂ + k₃).

φ₂ = IP3 (α Ca + β)/(Ca + δ)
10 z″ = φ₂ [(b₁ Ca + b₀)/(Ca + L₅) − φ₂ − γ Ca/(Ca + δ)].
```

The first two rooted derivatives therefore depend on at most seven quantities
(α, β, δ, γ, b₁, b₀, L₅). The first derivative alone depends on at most three.
Nonzero modular minors attain these upper bounds and the rank-12 bound at
order 3. This establishes generic derivative-order sufficiency and necessity
for this prepared scalar-output setup, at the level of local information.

## Later point with all states observed

If xₑ(t*) and xₑ′(t*) are observed, each condition supplies

```text
xₑ′(t*) = Q(φₑ) xₑ(t*) = H(xₑ(t*)) φₑ.
```

This is linear in the nine rates φₑ; the entries of H are observed states.
For example, S′ = O φ₈ − S φ₉. It remains rational in the shared original
kinetic parameters after substituting φₑ = φ(θ; Caₑ, IP3ₑ).

- **One condition, nine independent rates:** one first-derivative vector has
  at most five independent equations, because the six states sum to one.
  Generic nonzero observed states attain rank 5. Adding second derivatives
  reaches rank 9. Equivalently, stack the linear equations
  x′ = H(x)φ and x″ = H(x′)φ. First derivatives at multiple suitably distinct
  observed state vectors can also supply the additional linear equations.
- **All conditions, shared kinetic parameters:** first derivatives alone
  reach rank 12. This is verified both at arbitrary positive normalized
  anchors and at states on actual trajectories from the PEtab preparation.
- **Nonzero is not itself a rank guarantee.** An equilibrium or an otherwise
  uninformative state/condition design can still be deficient.

For a check on reachable states, the probe evaluates exp(Qₑ t*)x(0) at
t* = 0.01 for all nine conditions. The Jacobian of Qₑ(θ)xₑ(t*) is then taken
holding the observed state fixed. It is evaluated in the 12-combination
coordinates, with 70- and 100-digit arithmetic. Both a moderate positive
parameter vector and the SBML nominal vector have positive states and rank
12; all 20 displayed singular-value digits agree across precisions. At the
nominal vector the smallest state is about 8.31 × 10⁻⁸. The smallest and
largest singular values after the documented row/relative-column scaling are
about 4.28 × 10⁻⁷ and 7.97. Full rank alone does not imply good conditioning.

## One-condition comparison and limits

Keeping the nine rates independent in one condition gives:

| Observation and known anchor | Order reaching rank 9 |
|---|---:|
| Rooted output, prescribed preparation | 9 |
| Quartic output, prescribed preparation | 12 |
| All states, prescribed preparation | 3 |
| All states, generic known positive anchor | 2 |

The zeros delay some individual flows but do not permanently hide a rate if
all states are observed: first derivatives determine φ₂ and φ₃; second
derivatives add φ₁, φ₄, φ₅, φ₈; third derivatives add φ₆, φ₇, φ₉.

The order-3 scalar-output joint result therefore relies on **both** known
preparation and the cross-condition rate formulas. It should not be applied
to the earlier single-condition, independent-rate, unknown-state experiment.

The finite-field calculations use two primes (2147483647 and 1000000007),
three positive integer parameter samples, and the exact decimal SBML nominal
parameters. All resulting rank sequences agree. The rate gradients are
independently checked against symbolic differentiation. Nonzero modular
minors certify lower bounds over the rational model; symbolic factorizations
supply the upper bounds described above. The fully observed reachable-anchor
calculation is a separate high-precision numerical check.

No noisy derivatives were estimated, no polynomial system was solved, no
global root count was computed, and no recovery result is claimed. The fast
transient and endpoint derivative accuracy remain practical questions even
after lowering the required derivative order. The next bounded estimation
experiment can use the known preparation and joint rooted derivatives through
order 3, first with exact ODE derivatives and only then with interpolated data.

Reproduction instructions and machine-readable evidence:
[research harness](../repro/sneyd_prepared_jets_2026_09_16/README.md).
