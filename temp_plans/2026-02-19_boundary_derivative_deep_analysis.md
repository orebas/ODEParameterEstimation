# Boundary Derivative Deep Analysis — 2026-02-19

## Context

When HC.jl finds parameter solutions at interior shooting points and backward ODE
integration to t=0 blows up (due to stiffness), we attempt an algebraic re-solve:
fix the PARAMETERS from the interior solution, re-run SIAN on the parameter-free model,
and solve for state initial conditions at t=0. This re-solve needs **observable derivative
data** from interpolants at t=0 — and those derivatives are catastrophically wrong.

This document records every detail of what goes wrong, why, and what the numbers look like.

---

## The SIAN Re-Solve System for ERK (Fixed Parameters)

### Model

ERK enzyme kinetics, 6 states, 6 parameters, 3 observables:

```
D(S0) = -kf1*E*S0 + kr1*C1
D(C1) = kf1*E*S0 - (kr1 + kc1)*C1
D(C2) = kc1*C1 - (kr2 + kc2)*C2 + kf2*E*S1
D(S1) = -kf2*E*S1 + kr2*C2
D(S2) = kc2*C2
D(E)  = -kf1*E*S0 + kr1*C1 - kf2*E*S1 + (kr2 + kc2)*C2

Observables: y0 ~ S0,  y1 ~ S1,  y2 ~ S2
```

Parameters: kf1=11.5, kr1=300, kc1=12.45, kf2=11.15, kr2=4.864, kc2=428.13
True ICs: S0=5.0, C1=0, C2=0, S1=0, S2=0, E=0.65

### What SIAN produces after fixing all 6 parameters

With all parameters baked into the model as constants, SIAN generates a
**15-equation, 15-unknown** polynomial system. The 15 unknowns are state
derivative variables at the evaluation time point:

```
Order 0 (ICs):        S0_0, S1_0, S2_0, C1_0, C2_0, E_0       (6 state values)
Order 1 (1st derivs): S0_1, S1_1, S2_1, C1_1, C2_1, E_1       (6 first derivatives)
Order 2 (2nd derivs): S0_2, S1_2, S2_2                          (3 second derivatives, observed only)
```

---

## Which Derivatives Are Read From Interpolants

The template has two kinds of equations:

### 6 Readoff Equations (data → variable)

These pin observable values and their first derivatives to interpolated data.
The right-hand side comes from `nth_deriv(interpolant, order, t_point)`:

| Eq# | Equation | Observable | Deriv Order | What it pins |
|-----|----------|-----------|-------------|-------------|
| Eq3 | S0_0 = y0(0) | y0 = S0 | 0 | S0 initial value |
| Eq1 | S1_0 = y1(0) | y1 = S1 | 0 | S1 initial value |
| Eq5 | S2_0 = y2(0) | y2 = S2 | 0 | S2 initial value |
| **Eq11** | **S0_1 = y0'(0)** | **y0 = S0** | **1** | **S0 first derivative** |
| **Eq7** | **S1_1 = y1'(0)** | **y1 = S1** | **1** | **S1 first derivative** |
| **Eq14** | **S2_1 = y2'(0)** | **y2 = S2** | **1** | **S2 first derivative** |

**Key**: Order 0 (function values) are accurate because interpolants pass through data
points. Order 1 (first derivatives) are catastrophically wrong at t=0 (boundary).
Order 2 derivatives are NOT read from data — they're unknowns solved algebraically.

### 9 Structural Equations (ODE relationships, params baked in)

These encode the ODE dynamics with parameter values as rational coefficients.
After readoff substitution (S0_0, S1_0, S2_0, S0_1, S1_1, S2_1 become known),
these determine the remaining 9 unknowns: C1_0, C2_0, E_0, C1_1, C2_1, E_1,
S0_2, S1_2, S2_2.

**Order 0 → 1 equations** (ODE evaluated at t=0):

```
Eq2:  S1_1 = 4.864·C2_0 - 11.15·E_0·S1_0         [D(S1) = kr2·C2 - kf2·E·S1]
Eq4:  S0_1 = 300·C1_0 - 11.5·E_0·S0_0              [D(S0) = kr1·C1 - kf1·E·S0]
Eq6:  S2_1 = 428.13·C2_0                             [D(S2) = kc2·C2]
Eq9:  E_1  = 300·C1_0 + 432.994·C2_0 - 11.5·E_0·S0_0 - 11.15·E_0·S1_0  [D(E)]
Eq10: C2_1 = 12.45·C1_0 - 432.994·C2_0 + 11.15·E_0·S1_0                  [D(C2)]
Eq13: C1_1 = -312.45·C1_0 + 11.5·E_0·S0_0                                 [D(C1)]
```

(Note: 432.994 = kr2 + kc2 = 4.864 + 428.13)

**Order 1 → 2 equations** (differentiated ODE, product rule):

```
Eq8:  S1_2 = 4.864·C2_1 - 11.15·(E_0·S1_1 + E_1·S1_0)  [D²(S1)]
Eq12: S0_2 = 300·C1_1 - 11.5·(E_0·S0_1 + E_1·S0_0)      [D²(S0)]
Eq15: S2_2 = 428.13·C2_1                                    [D²(S2)]
```

---

## How Wrong Data Propagates: The Chain of Inference

After readoff substitution, S0_0=5, S1_0=0, S2_0=0 are accurate. The problems
start with S0_1, S1_1, S2_1 (the wrong order-1 data).

### Step 1: C2_0 — Two contradictory paths

With S1_0 = 0, two equations simplify to give C2_0 independently:

**From Eq2**: S1_1 = 4.864·C2_0 - 11.15·E_0·0 = 4.864·C2_0
  → **C2_0 = S1_1 / 4.864**

**From Eq6**: S2_1 = 428.13·C2_0
  → **C2_0 = S2_1 / 428.13**

These MUST agree for a solution to exist:

| Method | S1_1 (y1') | C2_0 via Eq2 | S2_1 (y2') | C2_0 via Eq6 | Ratio | Consistent? |
|--------|----------:|-------------:|----------:|-------------:|------:|:-----------|
| **True** | 0 | 0 | 0 | 0 | — | Yes |
| **AAAD** | 10.07 | 2.07 | -4858 | -11.35 | -5.5 | **NO** |
| **AAAD_GPR** | 0.012 | 0.00247 | -0.153 | -3.57e-4 | -6.9 | **NO** |
| **AGP_Robust** | 1.5e-5 | 3.08e-6 | 0.245 | 5.72e-4 | 185 | **NO** |

**Every single interpolator creates an algebraically inconsistent system.**
No point satisfies all 15 equations simultaneously. HC.jl correctly reports
0 solutions because none exist.

### Step 2: C1_0 and E_0 (from Eq4)

With S0_0 = 5:
```
S0_1 = 300·C1_0 - 11.5·E_0·5 = 300·C1_0 - 57.5·E_0
```

True: 300·0 - 57.5·0.65 = -37.375

| Method | S0_1 value | Equation becomes |
|--------|----------:|:----------------|
| True | -37.375 | 300·C1_0 - 57.5·E_0 = -37.375 |
| AAAD | -512,326 | 300·C1_0 - 57.5·E_0 = -512,326 |
| AAAD_GPR | -25.15 | 300·C1_0 - 57.5·E_0 = -25.15 |
| AGP_Robust | -22.13 | 300·C1_0 - 57.5·E_0 = -22.13 |

With AAAD: this forces C1_0 and E_0 into an enormous range (the constraint
line is 14,000× further from the origin than the true one).

### Step 3: Remaining variables cascade

From the already-wrong C2_0, C1_0, E_0:

- **Eq13**: C1_1 = -312.45·C1_0 + 57.5·E_0
- **Eq10**: C2_1 = 12.45·C1_0 - 432.994·C2_0
- **Eq9**: E_1 = 300·C1_0 + 432.994·C2_0 - 57.5·E_0
- **Eq12**: S0_2 = 300·C1_1 - 11.5·(E_0·S0_1 + E_1·5)
- **Eq8**: S1_2 = 4.864·C2_1 - 11.15·E_0·S1_1
- **Eq15**: S2_2 = 428.13·C2_1

Every downstream variable inherits and amplifies the errors from Steps 1-2.

### Cascading substitution fallback result

When HC.jl fails, the cascading substitution fallback in `resolve_states_with_fixed_params`
can only solve:

- **Pass 1**: S0_0, S1_0, S2_0, S0_1, S1_1, S2_1 (6 readoff values — just echoing data)
- **Pass 2**: C2_0 from Eq6 (single-unknown equation after substitution)
- **Pass 3**: No more single-unknown equations — done.

Result: 7 of 15 variables solved. The remaining 8 (C1_0, E_0, C1_1, E_1, C2_1,
S0_2, S1_2, S2_2) are in 7 equations (one became redundant) — **underdetermined**.
HC.jl is skipped. C1 and E fall back to 0.0.

---

## Exact Numerical Values: Ground Truth vs All Interpolators

### Benchmark Setup

- 2000 data points on [0, 20], grid spacing h ≈ 0.01
- High-accuracy ODE solution (abstol=1e-14, reltol=1e-14) for ground truth
- Ground truth derivatives computed via Richardson extrapolation from dense ODE output
- Three interpolator methods: AAAD (BaryRational.aaa), AAAD_GPR (AAA + GP pivot),
  AGP_Robust (GP regression)

### Observable S0 (y0 ~ S0)

#### At t = 0 (left boundary)

| Method | Order 0 (value) | RelErr | Order 1 (deriv) | RelErr | Order 2 | RelErr |
|--------|----------------:|-------:|----------------:|-------:|--------:|-------:|
| **GROUND TRUTH** | **5.00000** | | **-37.375** | | **13640.96** | |
| AAAD | 5.00000 | 0 | -512,326 | 13,700× | 5.48e12 | 4.0e8× |
| AAAD_GPR | 5.00000 | 2.5e-7 | -25.15 | 0.327 | 4818.67 | 0.647 |
| AGP_Robust | 5.00000 | 7.3e-6 | -22.13 | 0.408 | 3419.76 | 0.749 |
| FD_30pt | 5.00000 | 0 | -33.73 | 0.098 | 10356.7 | 0.241 |
| FD_50pt | 5.00000 | 0 | -36.08 | 0.035 | 12968.1 | 0.049 |

#### At t = 1e-12 (sub-grid epsilon — essentially identical to t=0)

| Method | Order 0 | Order 1 | Order 2 |
|--------|--------:|--------:|--------:|
| **GROUND TRUTH** | 5.00000 | -37.375 | 13640.84 |
| AAAD | 5.00000 | -512,320 | 5.48e12 |
| AAAD_GPR | 5.00000 | -25.15 | 4818.67 |
| AGP_Robust | 5.00000 | -22.13 | 3419.76 |

Values are **unchanged** — a sub-grid epsilon does nothing because the interpolant
is smooth at that scale. The wrong derivative behavior extends uniformly through
the entire sub-grid region.

#### At t = 0.01 (= 1h, one grid spacing)

| Method | Order 0 | RelErr | Order 1 (true: -2.031) | RelErr |
|--------|--------:|-------:|-----------------------:|-------:|
| AAAD | 4.8937 | 1.1e-4 | **80.13** | **40×** |
| AAAD_GPR | 4.8943 | 2.6e-6 | -2.798 | 0.377 |
| AGP_Robust | 4.8945 | 4.7e-5 | -3.392 | 0.670 |

Even one grid spacing away, AAAD derivatives are still wildly wrong.

#### At t = 0.1 (= 10h, ten grid spacings in)

| Method | Order 0 | RelErr | Order 1 (true: -1.1867) | RelErr |
|--------|--------:|-------:|------------------------:|-------:|
| AAAD | 4.78431 | 1.1e-14 | -1.18675 | **5.2e-10** |
| AAAD_GPR | 4.78431 | - | -1.18804 | 0.0011 |
| AGP_Robust | 4.78445 | 4.2e-5 | -1.18976 | 0.0025 |

At 10h, AAAD derivatives become machine-precision accurate. The crossover from
catastrophic to excellent happens somewhere between 1h and 10h.

### Observable S1 (y1 ~ S1)

#### At t = 0

| Method | Order 0 | Order 1 (true: ~0) | Order 2 (true: ~0) |
|--------|--------:|-------------------:|-------------------:|
| **GROUND TRUTH** | 0.0 | 1.53e-19 | -6.72e-13 |
| AAAD | 0.0 | **10.07** | 2.88e6 |
| AAAD_GPR | -2.4e-5 | **0.0120** | -0.0200 |
| AGP_Robust | -1.7e-8 | **1.46e-5** | 2.113 |

S1 starts at 0 and its true first derivative is essentially 0 (it's ~1.5e-19
because of floating-point accumulation, analytically it's exactly 0 since
S1(0)=0, C2(0)=0 → S1'(0) = -kf2·E·S1 + kr2·C2 = 0).

All interpolators produce nonzero S1'(0), which directly creates a wrong C2_0:
- AAAD: C2_0 = 10.07/4.864 = 2.07 (true: 0)
- AAAD_GPR: C2_0 = 0.012/4.864 = 0.00247
- AGP_Robust: C2_0 = 1.46e-5/4.864 = 3.0e-6

### Observable S2 (y2 ~ S2)

#### At t = 0

| Method | Order 0 | Order 1 (true: ~0) | Order 2 (true: ~0) |
|--------|--------:|-------------------:|-------------------:|
| **GROUND TRUTH** | 0.0 | 1.33e-18 | 4.07e-12 |
| AAAD | 0.0 | **-4858** | 7.83e9 |
| AAAD_GPR | -7.6e-8 | **-0.153** | 259.04 |
| AGP_Robust | -5.9e-5 | **0.245** | 114.35 |

S2 also starts at 0 with true derivative ~0. The interpolators produce wildly
wrong derivatives that create a SECOND contradictory value for C2_0:
- AAAD: C2_0 = -4858/428.13 = -11.35 (vs 2.07 from S1 — opposite sign!)
- AAAD_GPR: C2_0 = -0.153/428.13 = -3.57e-4 (vs 0.00247 — factor 7 off)
- AGP_Robust: C2_0 = 0.245/428.13 = 5.72e-4 (vs 3.0e-6 — factor 185 off)

---

## Shifted Interpolant Results (t = 0 + Nh)

Evaluating the interpolant's derivatives not at t=0 but at a shifted point
t = N·h (where h ≈ 0.01) for S0:

| Shift | AAAD Order 1 | RelErr | AAAD_GPR Order 1 | AGP_Robust Order 1 |
|-------|-------------:|-------:|-----------------:|-------------------:|
| t=0 (no shift) | -512,326 | 13,700 | -25.15 (0.33) | -22.13 (0.41) |
| t=1h (0.01) | 80.13 | 40× | -2.80 (0.38) | -3.39 (0.67) |
| t=2h (0.02) | -1.336 | 0.091 | -1.075 (0.12) | -0.842 (0.31) |
| t=5h (0.05) | **-1.1993** | **6.3e-9** | -1.194 (4.6e-3) | -1.119 (0.067) |
| t=10h (0.10) | **-1.1867** | **3.7e-11** | -1.188 (1.1e-3) | -1.190 (2.5e-3) |
| t=25h (0.25) | -1.1495 | 2.8e-11 | -1.150 (3.4e-4) | -1.145 (3.5e-3) |
| t=50h (0.50) | -1.0892 | 2.1e-10 | -1.089 (9.2e-5) | -1.089 (1.1e-4) |

**AAAD at 5h**: machine-precision accurate for Order 1.
**GP methods at 10h**: sub-percent accuracy.

Note: the ground truth ORDER 1 value changes with t (the true derivative at t=0.05
is -1.1993, not -37.375). The shifted approach evaluates at a different point, so the
SIAN equations would need to be instantiated at the shifted time point, not t=0.

---

## Why AAAD Is So Catastrophically Worse Than GP Methods

### The barycentric rational form

AAAD uses the AAA algorithm (BaryRational.jl) which produces:

```
r(z) = N(z) / D(z)

where  N(z) = Σⱼ wⱼfⱼ / (z - xⱼ)
       D(z) = Σⱼ wⱼ / (z - xⱼ)
```

xⱼ are "support points" (a subset of data nodes selected greedily by AAA),
wⱼ are barycentric weights, fⱼ = f(xⱼ) are function values.

The function value at any z is computed by `baryEval` in `src/core/derivatives.jl:66-96`.
The derivative is computed by `TaylorDiff.derivative(f, z, Val(n))` propagating
Taylor coefficients through the baryEval arithmetic.

### Root cause: Near-real POLES placed by AAA extremely close to t=0

**The initial hypothesis that boundary derivatives blow up due to 1/h² scaling from
nearby support points was WRONG.** Detailed investigation (diagnostic script at
`/tmp/aaad_deep_diagnostic.jl`, output at `/tmp/aaad_diagnostic_output.txt`)
revealed the true mechanism: **AAA places near-real poles of the rational
approximant extremely close to t=0**, and these poles dominate the derivative.

A rational function r(z) = p(z)/q(z) has poles where q(z)=0. Near a pole z_p
with residue R, the function behaves as r(z) ≈ R/(z - z_p) + smooth terms.
The derivative is r'(z) ≈ -R/(z - z_p)² + smooth terms. At z=0, if a pole
sits at z_p = -ε (just outside [0,20]), the derivative contribution is
**-R/ε²**, which can be enormous when ε is tiny.

### Poles found by `BaryRational.prz()` analysis

Using `BaryRational.prz(aaa_approx)` to extract poles, residues, and zeros:

#### S0 (y0 ~ S0): 18 support points, 17 poles

| Pole location | Distance from 0 | Residue | R/ε² (predicted d1) | Actual d1 |
|--------------|----------------:|--------:|--------------------:|----------:|
| **-1.896e-7** | **1.896e-7** | **1.815e-8** | **~505,000** | **-505,028** |
| +0.01001 | 0.01001 | -3.221e-8 | -0.321 | (included) |
| +0.01962 | 0.01962 | 1.869e-8 | 0.049 | (included) |
| -0.712 ± 0.424i | 0.829 | ~-6e-5 | ~-8.7e-5 | (negligible) |

**The pole at -1.896e-7 (189 nanometers from the origin!) dominates completely.**
R/ε² = 1.815e-8 / (1.896e-7)² = 505,000 — matching the observed derivative
of -505,028 to within 0.005%.

#### S1 (y1 ~ S1): 23 support points, 22 poles

| Pole location | Distance from 0 | Residue | R/ε² (predicted d1) | Actual d1 |
|--------------|----------------:|--------:|--------------------:|----------:|
| **-4.521e-5** | **4.521e-5** | **3.182e-9** | **~1.56** | **-1.542** |
| -0.005708 | 0.005708 | -2.020e-9 | -0.062 | (included) |
| +0.01053 | 0.01053 | -1.916e-9 | -0.017 | (included) |

S1's closest pole is further away (45 micrometers vs 190 nanometers for S0),
so its derivative error is much smaller (1.54 vs 505,028) — but still wrong by
a factor of ~1e19 vs the true value of ~1.5e-19.

#### S2 (y2 ~ S2): 21 support points, 20 poles

| Pole location | Distance from 0 | Residue | R/ε² (predicted d1) | Actual d1 |
|--------------|----------------:|--------:|--------------------:|----------:|
| **-1.293e-6** | **1.293e-6** | **7.799e-9** | **~4,667** | **-4,665** |
| +0.01004 | 0.01004 | -1.320e-8 | -0.131 | (included) |
| +0.01932 | 0.01932 | 7.065e-9 | 0.019 | (included) |

**Summary of pole-dominated derivatives:**

| Observable | Nearest pole | Distance ε | Residue R | R/ε² | Observed d1 | Match |
|-----------|-------------|----------:|--------:|------:|----------:|------:|
| S0 | -1.896e-7 | 1.90e-7 | 1.82e-8 | 505,000 | -505,028 | 99.99% |
| S1 | -4.521e-5 | 4.52e-5 | 3.18e-9 | 1.56 | -1.54 | ~99% |
| S2 | -1.293e-6 | 1.29e-6 | 7.80e-9 | 4,667 | -4,665 | 99.96% |

### Why AAA creates these poles (Froissart doublets at stiff boundaries)

The AAA algorithm greedily selects support points to minimize interpolation error.
For stiff functions with a fast boundary layer (eigenvalues -413, -397), the
function changes dramatically in the first ~0.005 time units. AAA must capture
this rapid variation using a rational form. The barycentric weights it assigns
to boundary support points are **extremely small**:

| Observable | Weight at t=0 | Weight at t=0.01 | Typical interior weight |
|-----------|-------------:|----------------:|-----------------------:|
| S0 | 1.65e-8 | -1.64e-6 | ~0.1 |
| S1 | 5.47e-9 | -1.90e-7 | ~0.1 |
| S2 | 4.59e-7 | -2.06e-5 | ~0.1 |

These tiny weights are symptoms of near-cancellation: AAA is trying to represent
a function with a fast boundary layer using a low-degree rational approximant.
The near-cancellation between numerator and denominator creates **Froissart doublets**
— spurious pole-zero pairs very close together. The AAA cleanup step
(`BaryRational.cleanup!`) removes some, but the ones just outside [0,20] survive
because they don't cause visible interpolation error (the residues are tiny).

The poles at ~1e-7 to ~5e-5 from the origin have residues of ~1e-8 to ~1e-9.
For function evaluation, a residue of 1e-8 at distance 1e-7 contributes
R/ε = 1e-8/1e-7 = 0.1 — negligible compared to the function value of 5.0.
But for the derivative, R/ε² = 1e-8/1e-14 = 1e6 — catastrophic.

### The breakflag: correctly triggered, but doesn't help derivatives

Our `baryEval` (derivatives.jl:66-96) has a breakflag branch for when z ≈ xⱼ:

```julia
if (z - x[j])^2 < sqrt(tol)  # breakflag triggered
    # Modified formula: (w_b*f_b + m*num)/(w_b + m*den)
    # where m = z - x[breakindex]
end
```

**Diagnostic confirmed**: The breakflag IS triggered at t=0 (which is support point
index 1 for all three observables). The comparison `<` works correctly with
TaylorScalar types (TaylorDiff defines `isless` for TaylorScalar vs Float64).

However, the breakflag branch computes a DIFFERENT formula that avoids 0/0 at the
exact support point, but the derivatives of this formula are STILL dominated by
the nearby poles. The breakflag fixes function evaluation (order 0), not derivative
computation. The pole at -1.896e-7 is a property of the rational function r(z)
itself, not an artifact of how we evaluate it.

### Right boundary is fine: no nearby poles at t=20

The diagnostic confirmed that there are NO near-real poles within |z-20| < 1 for
any observable. The poles are clustered near t=0, not t=20, because the stiff
boundary layer is at the left boundary.

Derivative sweep at t=20 for S0:
```
t=20.0:         d1 = -0.00504  (reasonable)
t=19.999:       d1 = -0.00504  (stable)
t=19.99:        d1 = -0.00505  (stable)
t=19.9:         d1 = -0.00519  (stable)
```

Versus sweep at t=0:
```
t=0.0:          d1 = -505,028  (CATASTROPHIC — 13,500× error)
t=1e-8:         d1 = -455,690  (still catastrophic)
t=1e-6:         d1 = -12,829   (still catastrophic — we've passed the nearest pole)
t=1e-5:         d1 = -176      (still 4.7× error)
t=1e-4:         d1 = -3.02     (12× error — only now entering reasonable range)
t=1e-3:         d1 = -1.23     (close to interior values)
```

The derivative improves as t moves away from 0 because the 1/(t - z_p)² contribution
from the nearest pole shrinks. The crossover to "reasonable" happens around t ≈ 1e-4
to 1e-3, consistent with the nearest pole being at ε ≈ 1.9e-7.

### BaryRational.bary vs our baryEval

Diagnostic Part 4 confirmed that `BaryRational.bary` and our `baryEval` give the
**same derivative values** when both work. `BaryRational.bary` actually fails with
TaylorDiff types because its `nearby()` function requires `T <: AbstractVector{T}`
matching, which doesn't work for TaylorScalar. Our `baryEval`'s breakflag approach
is what makes TaylorDiff differentiation possible at all for support points.

The key insight: **it's the rational function itself that has the wrong derivative,
not a bug in how we evaluate it.** Both implementations agree on the wrong values.

### Why GP methods don't have this problem

The GP interpolant uses a kernel basis:

```
f̂(z) = Σⱼ αⱼ · k(z, xⱼ)

where k is typically RBF: k(z,x) = exp(-|z-x|²/2ℓ²)
```

The derivative:

```
f̂'(z) = Σⱼ αⱼ · [-(z-xⱼ)/ℓ²] · exp(-|z-xⱼ|²/2ℓ²)
```

**No poles. No 1/(z-xⱼ) singularities.** Each term is bounded:

```
|αⱼ · (z-xⱼ)/ℓ² · exp(-|z-xⱼ|²/2ℓ²)| ≤ |αⱼ| / (ℓ·√e)
```

The maximum contribution from any single data point is bounded by αⱼ/(ℓ√e),
regardless of the evaluation point z. At the boundary z=0, the GP derivative
is a weighted sum of bounded terms — it can't blow up by factors of 14,000.

The GP derivative IS still wrong at t=0 (by ~30-40%) because the GP prior
(RBF kernel with fitted length scale) assumes the function varies smoothly at
a single characteristic scale ℓ, which is wrong for a stiff system with a fast
boundary layer. But the error is bounded by the kernel's smoothness guarantee.

### Summary: Rational vs Kernel basis

| Property | AAAD (rational) | GP (kernel) |
|----------|:---------------|:-----------|
| Basis functions | 1/(z - xⱼ) | exp(-\|z-x\|²/2ℓ²) |
| Derivative basis | -1/(z - xⱼ)² | bounded Gaussian |
| At boundary (z=0) | **dominated by nearby poles: R/ε²** | bounded by 1/(ℓ√e) |
| Pole behavior | near-real poles at ε~1e-7 from boundary | **no poles** |
| Function accuracy | exact at nodes | near-exact |
| Derivative accuracy at boundary | **catastrophic (13,500× error)** | wrong by 30-40% |
| Derivative accuracy at interior | machine precision | sub-percent |
| Optimized for | function interpolation | smoothness prior |

---

## Stiffness: Why the Boundary Layer Exists

### Jacobian eigenvalues at t=0

The ERK system Jacobian at the true initial conditions has eigenvalues:

| Eigenvalue | Value | Timescale (1/|λ|) | Physical source |
|-----------|------:|------------------:|:---------------|
| λ₁ | -413.19 | 0.00242 | kc2=428.13 (catalysis) |
| λ₂ | -397.07 | 0.00252 | kr1=300 (back-reaction) |
| λ₃ | -7.165 | 0.1396 | moderate dynamics |
| λ₄ | -0.246 | 4.065 | slow dynamics |
| λ₅ | 0 | ∞ | conservation law |
| λ₆ | 0 | ∞ | conservation law |

### Boundary layer analysis

The fastest timescale is τ_fast ≈ 0.00242 (from the two large eigenvalues).
The data grid spacing is h ≈ 0.01. The ratio:

```
h / τ_fast = 0.01 / 0.00242 ≈ 4.1
```

The grid has only ~4 points inside the fast boundary layer. This means:
- The solution changes dramatically in the first ~0.005 time units
- The grid barely resolves this transient
- Derivatives in this region are enormous: S0''(0) = 13,641 vs S0''(1) = 0.22

### Dynamic range of derivatives

| Observable | f'(0) | f'(0.1) | f'(1) | f'(10) | Range (0 to 1) |
|-----------|------:|--------:|------:|-------:|---------------:|
| S0 | -37.38 | -1.187 | -1.089 | -0.233 | 34× |
| S1 | ~0 | 0.00757 | -4.4e-4 | -7.4e-5 | — |
| S2 | ~0 | 1.200 | 0.994 | 0.226 | — |

S0's derivative changes by 34× in the first unit of time. The second
derivative S0''(0) = 13,641 represents the stiff transient.

---

## What the Code Does (implementation references)

### Data substitution: `construct_equation_system_from_si_template`

File: `src/core/si_template_integration.jl`, lines 117-144

```julia
max_required_deriv = isempty(derivative_dict) ? 0 : maximum(values(derivative_dict))

for (obs_idx, obs_eqn) in enumerate(measured_quantities_in)
    obs_interp = precomputed_interpolants[obs_rhs]
    for i in 0:max_required_deriv
        lhs_var = DD.obs_lhs[i+1][obs_idx]
        val = nth_deriv(x -> obs_interp(x), i, t_point)  # ← THIS IS THE PROBLEM
        interpolated_values_dict[lhs_var] = val
    end
end
```

For the fixed-parameter ERK template, `max_required_deriv` = 1 (only orders 0 and 1
are in the derivative_dict). So 6 values are substituted (3 observables × 2 orders).

### nth_deriv: TaylorDiff differentiation

File: `src/core/derivatives.jl`, lines 222-229

```julia
function nth_deriv(f::Function, n::Int, t::Real)::Real
    if n == 0
        return f(t)
    end
    return TaylorDiff.derivative(f, t, Val(n))
end
```

### AAAD interpolant evaluation: baryEval

File: `src/core/derivatives.jl`, lines 66-96

```julia
function baryEval(z, f, x, w, tol = 1e-13)
    num = zero(T)
    den = zero(T)
    for j in eachindex(f)
        t = w[j] / (z - x[j])    # ← 1/(z - xⱼ) terms
        num += t * f[j]
        den += t
    end
    return num / den
end
```

TaylorDiff propagates through these 1/(z-xⱼ) operations, producing the
catastrophic derivative values at z=0 where nearby xⱼ create huge 1/xⱼ² terms.

### SIAN re-solve: resolve_states_with_fixed_params

File: `src/core/si_template_integration.jl`, lines 263-537 (new code)

1. `apply_prefixed_params_to_model()` — bakes parameter values into ODE
2. `get_si_equation_system()` — re-runs SIAN on parameter-free model
3. `construct_equation_system_from_si_template()` — instantiates at t=0
4. `solve_with_hc()` — attempts HC.jl on the square system
5. Cascading substitution fallback if HC.jl fails

### Blown backsolve detection

File: `src/core/optimized_multishot_estimation.jl`, lines 1532-1744

Detects solutions where `|IC| > bound_threshold` or `err > 1e15`, deduplicates
by parameter values, routes to `resolve_states_with_fixed_params`.

---

## Possible Fixes (Not Yet Implemented)

### Fix 1: Shifted evaluation point

Instead of evaluating derivatives at t=0, evaluate at t=5h or t=10h where
AAAD is accurate. The SIAN template would be instantiated at the shifted time
point. This changes what "initial conditions" means — we'd get state values
at t=0.05 rather than t=0, and would need to integrate backward by 0.05 to
get t=0 ICs. But 0.05 is much shorter than the full domain, so backward
integration is less likely to blow up.

**Pro**: Trivial code change (just change time_index).
**Con**: Still requires a short backward integration; stiffness might still cause issues.

### Fix 2: Fornberg finite differences for boundary derivatives

Replace `nth_deriv(interpolant, order, t=0)` with Fornberg FD weights applied
directly to the raw data at boundary shooting points. The FD_50pt stencil gives
S0'(0) = -36.08 (3.5% error) vs AAAD's -512,326 (13,700× error).

**Pro**: Uses raw data directly, no interpolant poles.
**Con**: FD accuracy degrades with derivative order; still 3.5% error for order 1.

### Fix 3: Only attempt re-solve at interior shooting points

Skip the t=0 re-solve entirely. If the backsolve from an interior point fails
at t=0, try re-solving at the interior shooting point instead (where interpolant
derivatives are accurate). Then use the state values at t=shooting_point as the
"initial conditions" for a fresh ODE integration.

**Pro**: Avoids the boundary problem entirely.
**Con**: More complex; may not always have an interior point available.

### Fix 4: Use GP interpolant for boundary shooting points

AAAD gives errors of 13,700× at boundary. AGP_Robust gives 41% error. For
the boundary re-solve, switch to a GP interpolant which at least gives a
sensible (if not precise) derivative. This would make the SIAN system "nearly
consistent" rather than wildly inconsistent — HC.jl might find approximate
solutions, or the cascading substitution would produce reasonable values.

**Pro**: Simple interpolator swap at boundary.
**Con**: 30-40% derivative error might still make the algebraic system inconsistent.

---

## Files

| File | Purpose |
|------|---------|
| `/tmp/boundary_deriv_benchmark.jl` | Standalone benchmark script (2000 pts, ERK model) |
| `/tmp/boundary_deriv_logscale.txt` | Full benchmark output (1191 lines, all 3 observables) |
| `src/core/derivatives.jl` | `nth_deriv`, `baryEval`, `aaad`, interpolator implementations |
| `src/core/si_template_integration.jl` | `construct_equation_system_from_si_template`, `resolve_states_with_fixed_params` |
| `src/core/optimized_multishot_estimation.jl` | Blown backsolve detection + re-solve routing |
| `src/core/si_equation_builder.jl` | `apply_prefixed_params_to_model`, `get_si_equation_system` |
| `/tmp/aaad_deep_diagnostic.jl` | 7-part AAAD diagnostic script (support points, poles, breakflag, boundaries) |
| `/tmp/aaad_diagnostic_output.txt` | Full output from the diagnostic (326 lines) |
| `temp_plans/2026-02-18_backsolve_fallback_analysis.md` | Previous analysis (implementation details) |

---

## Key Takeaways

1. **The SIAN re-solve needs exactly 6 data values**: 3 order-0 (fine) + 3 order-1 (broken)
2. **Order-1 derivatives at t=0 are wrong for ALL interpolators** — AAAD by 13,700×, GP by 30-40%
3. **The C2_0 overdetermination** (Eq2 and Eq6 both give C2_0) makes even small errors create algebraic inconsistency
4. **AAAD's near-real poles at ε~1e-7 from the boundary** cause derivatives to scale as R/ε² ≈ 505,000, while GP's kernel basis has no poles and is inherently bounded
5. **The stiff boundary layer** (timescale 0.0024 vs grid h=0.01) means derivatives change by factors of 34-62,000 across the domain, making global interpolation fundamentally difficult near t=0
6. **Shifting by 5-10h** fixes AAAD completely (machine precision at t=5h)
7. **Sub-grid epsilon (t=1e-8, 1e-12) does nothing** — the interpolant is smooth at that scale
