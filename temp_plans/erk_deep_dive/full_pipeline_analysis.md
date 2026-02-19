# ERK Full Pipeline Analysis — 2026-02-19

## Executive Summary

A complete trace of the ERK parameter estimation pipeline, tracking exactly where
and how the estimation fails. Based on a run with 2001 data points, `try_more_methods=false`,
`InterpolatorAGPRobust`, parameter homotopy, HC.jl solver.

### Chain of Failures

```
AAAD poles at t≈0 (ε≈1e-7)
    ↓
S0'(0) = -2.469 instead of -37.375  (93.4% error)
S2'(0) = 0.968 instead of 0.0       (infinite relative error)
    ↓
Initial 33-eq system at t=0,2.86,5.71: 0 real solutions
    ↓
Only interior points (t=8.57-17.14) produce real solutions
    ↓
Interior solutions have wrong params (kf1≈0.8-2.9 vs true 11.5)
    ↓
Re-solve with wrong params at t=0 + wrong derivative data
    ↓
Wildly wrong C1, E ICs (3041 vs 0, 2028 vs 0.65)
    ↓
ODE forward solve diverges → err = 1e15
```

---

## 1. The ERK Model

Dual Michaelis-Menten enzyme kinetics: E catalyzes S0→S1→S2 via complexes C1, C2.

```
D(S0) = -kf1*E*S0 + kr1*C1
D(C1) = kf1*E*S0 - (kr1 + kc1)*C1
D(C2) = kc1*C1 - (kr2 + kc2)*C2 + kf2*E*S1
D(S1) = -kf2*E*S1 + kr2*C2
D(S2) = kc2*C2
D(E)  = -kf1*E*S0 + kr1*C1 - kf2*E*S1 + (kr2 + kc2)*C2
```

- **6 states**: S0, C1, C2, S1, S2, E (3 observed: S0, S1, S2)
- **6 parameters**: kf1=11.5, kr1=300.0, kc1=12.45, kf2=11.15, kr2=4.864, kc2=428.13
- **True ICs**: [5.0, 0, 0, 0, 0, 0.65]
- **Conservation laws**: S0+C1+C2+S1+S2 = 5.0, E+C1+C2 = 0.65
- **Stiffness**: Jacobian eigenvalues {-413, -397, -7.2, -0.25, 0, 0}
- **Boundary layer width**: ~0.0024 (vs grid h = 0.01)

---

## 2. Initial Solve: 33 Equations, 33 Variables

### System structure

SIAN produces 36 equations from the full model (6 params + 27 state derivative vars = 33 unknowns).
Algebraic independence selects 33 equations (drops Eq34-36: S2_4=y2_4, S0_4=y0_4, S1_4=y1_4).

**Data parameters**: 39 = 3 observables × 13 derivative orders (0 through 12).
Actually, the log shows orders up to 13 are referenced in the template, but order 13 and 14
are flagged with "Cannot map ... to DD" warnings — they use symbolic fallbacks.

### Shooting point results

| Point | t | HC.jl total | Real solutions | Note |
|-------|------|-------------|----------------|------|
| 1 | 0.00 | 2 | **0** | Boundary poles → catastrophic derivatives |
| 2 | 2.86 | 2 | **0** | Still in transient tail |
| 3 | 5.71 | 2 | **0** | Still in transient tail |
| 4 | 8.57 | 2 | **2** | Post-transient, residuals ~1e-17 |
| 5 | 11.43 | 2 | **2** | Post-transient, residuals ~1e-17 |
| 6 | 14.29 | 2 | **2** | Post-transient, residuals ~1e-17 |
| 7 | 17.14 | 2 | **2** | Post-transient, residuals ~1e-17 |
| 8 | 20.00 | 2 | **0** | Right boundary effects |

### Why HC.jl fails at t=0 and t=2.86

The 33-equation system needs derivatives up to order 12 from the AAAD interpolant. At t=0,
near-real poles at ε≈1e-7 cause first derivatives to be wrong by 13,500× and higher-order
derivatives to be astronomically worse. This makes the polynomial system inconsistent —
HC.jl finds 2 solutions algebraically but none have real parts close to real.

At t=2.86, the evaluation point is past the boundary layer, but:
- 12th-order derivatives through AAAD still carry errors from the rational form's pole structure
- `n! * R / d^(n+1)` for n=12, even with d=2.86, amplifies tiny residues significantly
- The true observables are still in their transient decay at t=2.86 (S0 is not yet flat)
- These combined inaccuracies push all polynomial solution branches complex

Interior points (t≈8.57-17.14) work because observables are nearly flat post-transient,
so all derivatives order 1+ are near-zero and errors are small.

### Backsolve results from interior solutions

8 real solutions from points 4-7. After backsolving to t=0:

| Solution | Source | ODE err | Max |IC| | Notable blown states |
|----------|--------|---------|---------|----------------------|
| 1 | — | 1e15 | 103.2 | — |
| 2 | — | 1e15 | 4.9 | — |
| 3 | — | 1e15 | blown | S0 = 2.5e114, C1 = -2.5e114 |
| 4 | — | 1e15 | blown | C2 = -3.3e113, S1 = 3.2e113 |
| 5 | — | 1e15 | blown | S0 = -1.6e115, C1 = 1.6e115 |
| 6 | — | 3.0e12 | blown | C2 = -1.9e14, E = 1.9e14 |
| 7 | — | 1e15 | blown | C2 = 4.8e23, E = -1.9e24 |
| 8 | — | 1e15 | 36.3 | — |

Solutions 3-7 have **catastrophically blown** backsolves — eigenvalues -413, -397 flip to
+413, +397 in reverse time, amplifying errors by exp(413×8.57) ≈ 10^1537.

---

## 3. The SIAN Re-Solve: 15 Equations, 15 Variables

After detecting blown backsolves, the system deduplicates parameter sets and re-runs SIAN
with parameters fixed, producing a smaller system to solve for state ICs at t=0.

### 5 distinct parameter sets used for re-solve

| Set | kf1 | kr1 | kc1 | kf2 | kr2 | kc2 |
|-----|------|------|------|------|------|------|
| **True** | **11.50** | **300.0** | **12.45** | **11.15** | **4.864** | **428.13** |
| 1 | 0.831 | 2.747 | 3.209 | 0.396 | 0.000141 | -3.985 |
| 2 | -0.029 | 4.911 | -4.309 | 0.396 | -0.000120 | 3.387 |
| 3 | 1.009 | 3.045 | 2.762 | -3.055 | 0.0118 | -3.209 |
| 4 | -0.019 | 4.621 | -4.145 | -3.055 | -0.0122 | 3.303 |
| 5 | 2.889 | -7.889 | -6.583 | 11.997 | 0.017 | 4.512 |

**Every parameter set is wildly wrong.** The true values are 1-2 orders of magnitude larger.
This is because the HC.jl solutions at interior points find algebraically valid but physically
wrong solution branches.

### 15-equation system structure

**15 unknowns** (state derivatives at t=0):
- Order 0: S0_0, S1_0, S2_0, C1_0, C2_0, E_0
- Order 1: S0_1, S1_1, S2_1, C1_1, C2_1, E_1
- Order 2: S0_2, S1_2, S2_2

**6 data inputs** (from interpolation at t=0):
y0_0, y0_1, y1_0, y1_1, y2_0, y2_1

**Important**: SIAN internally references 24 derivative variables (y0_0 through y0_7,
y1_0 through y1_7, y2_0 through y2_7) during template construction. But after Gaussian
elimination, only 6 survive as explicit data inputs in the final equations. The dropped
equations (Eq16-18: S1_2=y1_2, S0_2=y0_2, S2_2=y2_2) would have pinned 2nd derivatives
to data, but are algebraically redundant and are dropped. Thus S0_2, S1_2, S2_2 become
unknowns solved algebraically.

### Complete 15×15 system (Parameter Set 1: kf1=0.831, kr1=2.747, kc1=3.209, kf2=0.396, kr2=0.000141, kc2=-3.985)

The rational coefficients encode the fixed parameter values.

```
Eq1  (pins S1_0):     y1_0 - S1_0 = 0
                      → -1.53e-5 - S1_0 = 0

Eq2  (S1 ODE):        -(kr2)*C2_0 + S1_1 + kf2*E_0*S1_0 = 0
                      → -(251932/1789481415)*C2_0 + S1_1 + (70919708/178909121)*E_0*S1_0 = 0

Eq3  (pins S0_0):     y0_0 - S0_0 = 0
                      → 4.961 - S0_0 = 0

Eq4  (S0 ODE):        -kr1*C1_0 + S0_1 + kf1*E_0*S0_0 = 0
                      → -(85942927/31282926)*C1_0 + S0_1 + (92747971/111640866)*E_0*S0_0 = 0

Eq5  (pins S2_0):     y2_0 - S2_0 = 0
                      → -0.000790 - S2_0 = 0

Eq6  (S2 ODE):        kc2*C2_0 + S2_1 = 0
                      → (249841115/62695078)*C2_0 + S2_1 = 0

Eq7  (pins S1_1):     y1_1 - S1_1 = 0
                      → 0.01226 - S1_1 = 0

Eq8  (S1 ODE diff):   -(kr2)*C2_1 + S1_2 + kf2*E_0*S1_1 + kf2*E_1*S1_0 = 0
                      → -(251932/1789481415)*C2_1 + S1_2 + (70919708/178909121)*E_0*S1_1
                        + (70919708/178909121)*E_1*S1_0 = 0

Eq9  (E ODE):         -kr1*C1_0 + (kr2+kc2)*C2_0 + E_1 + kf1*E_0*S0_0 + kf2*E_0*S1_0 = 0
                      → -(85942927/31282926)*C1_0 + (237487369/59597137)*C2_0 + E_1
                        + (92747971/111640866)*E_0*S0_0 + (70919708/178909121)*E_0*S1_0 = 0

Eq10 (C2 ODE):        -kc1*C1_0 - (kr2+kc2)*C2_0 + C2_1 - kf2*E_0*S1_0 = 0
                      → -(57564061/17940503)*C1_0 - (237487369/59597137)*C2_0 + C2_1
                        - (70919708/178909121)*E_0*S1_0 = 0

Eq11 (pins S0_1):     y0_1 - S0_1 = 0
                      → -2.469 - S0_1 = 0

Eq12 (S0 ODE diff):   -kr1*C1_1 + S0_2 + kf1*E_0*S0_1 + kf1*E_1*S0_0 = 0
                      → -(85942927/31282926)*C1_1 + S0_2 + (92747971/111640866)*E_0*S0_1
                        + (92747971/111640866)*E_1*S0_0 = 0

Eq13 (C1 ODE):        (kf1+kc1)*C1_0 + C1_1 - kf1*E_0*S0_0 = 0
                      → (562056228/94369843)*C1_0 + C1_1 - (92747971/111640866)*E_0*S0_0 = 0

Eq14 (pins S2_1):     y2_1 - S2_1 = 0
                      → 0.9684 - S2_1 = 0

Eq15 (S2 ODE diff):   kc2*C2_1 + S2_2 = 0
                      → (249841115/62695078)*C2_1 + S2_2 = 0
```

**Key rational coefficient ↔ parameter mapping for Set 1:**
- `92747971/111640866 ≈ 0.831` = kf1
- `85942927/31282926 ≈ 2.747` = kr1
- `57564061/17940503 ≈ 3.209` = kc1
- `70919708/178909121 ≈ 0.396` = kf2
- `251932/1789481415 ≈ 0.000141` = kr2
- `249841115/62695078 ≈ 3.985` = |kc2|
- `237487369/59597137 ≈ 3.985` = kr2 + kc2
- `562056228/94369843 ≈ 5.956` = kf1 + kc1 (= 0.831 + 3.209 ≈ 4.04... hmm, actually kr1 + kc1)

### Data values at t=0: Interpolated vs True

| Variable | Meaning | Interpolated Value | True Value | Abs Error | Rel Error |
|----------|---------|-------------------|------------|-----------|-----------|
| y0_0 → S0_0 | S0(0) | 4.961 | 5.000 | 0.039 | **0.78%** |
| **y0_1 → S0_1** | **S0'(0)** | **-2.469** | **-37.375** | **34.91** | **93.4%** |
| y1_0 → S1_0 | S1(0) | -1.53e-5 | 0.000 | 1.5e-5 | ~0 |
| y1_1 → S1_1 | S1'(0) | 0.01226 | 0.000 | 0.012 | ~0 (true=0) |
| y2_0 → S2_0 | S2(0) | -7.90e-4 | 0.000 | 7.9e-4 | ~0 |
| **y2_1 → S2_1** | **S2'(0)** | **0.9684** | **0.000** | **0.968** | **∞** |

The two catastrophically wrong values:
1. **S0'(0) = -2.469 instead of -37.375** — AAAD pole problem (13,500× in raw AAAD; here
   using AGPRobust which gives 93.4% error, much better but still destructive)
2. **S2'(0) = 0.9684 instead of 0.0** — S2 starts at 0, derivative is kc2*C2(0) = 428.13*0 = 0,
   but interpolant picks up phantom slope

### How bad data propagates through the system

**C2_0 is overdetermined** — two equations give it independently:
- From Eq2 (with S1_0≈0): C2_0 ≈ S1_1 / kr2 = 0.01226 / 0.000141 ≈ 86.9
- From Eq6: C2_0 = -S2_1 / kc2 = -0.9684 / (-3.985) ≈ 0.243

These MUST agree for a consistent solution. With the wrong S1_1 and S2_1, they disagree
by a factor of ~357. HC.jl must find a complex compromise — which it does (1 real solution
with C2_0 ≈ -0.243).

### Re-solve results

| Set | C1(0) | E(0) | ODE err | Max |IC| |
|-----|-------|------|---------|---------|
| **True** | **0.0** | **0.65** | — | — |
| 1 | 3041 | 2028 | 1e15 | 3041 |
| 2 | -60.6 | 2028 | 1e15 | 2028 |
| 3 | -557.7 | -338.8 | 515 | 558 |
| 4 | 6.37 | -338.8 | 2.4e32 | 339 |
| 5 | -84.95 | 46.93 | 1e15 | 84.9 |

Observable ICs (S0, S1, S2) are consistently correct (~4.961, ~-1.5e-5, ~-7.9e-4) because
pinning equations force them to match interpolated data. But unobserved states (C1, E) are
completely wrong, and the (wrong) parameters combined with wrong ICs make forward ODE
integration diverge.

---

## 4. Pole Deflation Results

Prototype at `pole_deflation_test.jl` tested 3 strategies for removing AAAD pole contributions.

### S0'(0) results

| Strategy | Value | Abs Error | Improvement vs Raw |
|----------|------:|----------:|-------------------:|
| Ground truth | -37.375 | — | — |
| AAAD raw | -504,988 | 504,951 | 1× (baseline) |
| Deflate nearest (r=1.0) | -1.577 | 35.8 | **14,100×** |
| Deflate all dangerous (r=1.0) | -1.577 | 35.8 | 14,100× |
| Analytic correction (r=1.0) | -1.577 | 35.8 | 14,100× |
| FHD5 | -23.23 | 14.1 | **35,800×** |
| Fornberg 50pt | -36.32 | 1.06 | **476,000×** |
| AGPRobust (used in log) | -2.469* | 34.9 | 14,500× |

(*AGPRobust value is from the log run, not the pole deflation test)

**Key findings:**
- Deflation removes ~99.99% of the error magnitude (from 505K to ~36)
- But the remaining error (35.8 absolute, 95.8% relative) is still too large for the algebraic system
- FHD5 (pole-free) does better than deflation
- Fornberg 50pt FD is the best — 2.8% error
- Strategies (b-all) and (c-analytic) are mathematically equivalent
- Deflation introduces ~1.9% error in d0 (function values)
- d2 (2nd derivatives) remain terrible after deflation

---

## 5. Code Paths and Key Files

### Data substitution
`src/core/si_template_integration.jl:117-144` — `construct_equation_system_from_si_template`
computes `nth_deriv(x -> obs_interp(x), i, t_point)` for each observable × derivative order.

### Interpolant construction
`src/core/derivatives.jl` — `aaad()`, `fhd()`, `agp_gpr_robust()` constructors.
`nth_deriv()` at line 222 calls `TaylorDiff.derivative(f, t, Val(n))`.

### Blown backsolve detection
`src/core/optimized_multishot_estimation.jl:1532-1744` — detects `|IC| > bound_threshold`
or `err > 1e15`, deduplicates parameter sets, routes to `resolve_states_with_fixed_params`.

### SIAN re-solve
`src/core/si_template_integration.jl:263-537` — `resolve_states_with_fixed_params`:
1. `apply_prefixed_params_to_model()` — bakes parameter values into ODE
2. `get_si_equation_system()` — re-runs SIAN on parameter-free model
3. `construct_equation_system_from_si_template()` — instantiates at t=0
4. `solve_with_hc()` — attempts HC.jl on the square system
5. Cascading substitution fallback if HC.jl fails

### Interpolator selection
`src/types/estimation_options.jl:23-31` — `InterpolatorMethod` enum.
`get_interpolator_function():302-323` — maps enum to function.
One interpolator per run, no automatic retry, same interpolant reused for re-solve.

---

## 6. Potential Fixes (Ranked by Promise)

### Fix 1: Fornberg FD for boundary shooting points (BEST RESULTS)
Replace `nth_deriv(interpolant, order, t=0)` with Fornberg FD weights at boundary points.
50-point stencil gives 2.8% error for S0'(0). Code change: ~20 lines in
`si_template_integration.jl`, only triggered when `t_point` is at first/last data point.

### Fix 2: Shifted evaluation point
Evaluate derivatives at t=5h instead of t=0 where AAAD is machine-precision accurate.
SIAN template instantiated at shifted point, then short backward integration to get t=0 ICs.
Pro: trivial code change. Con: still requires short backward integration.

### Fix 3: GP interpolant for boundary points
Switch from AAAD to AGPRobust specifically at boundary shooting points. 30-40% error
vs 13,500×. May make the algebraic system "nearly consistent" enough for HC.jl.

### Fix 4: FHD5 interpolant (pole-free)
Floater-Hormann degree 5 has no poles by construction. Gave 38% error for S0'(0) in
prototype. Better than GP but worse than Fornberg FD.

### Fix 5: Only re-solve at interior points
Skip t=0 re-solve entirely. Use state values at the interior shooting point as "ICs"
for forward integration. Avoids the boundary problem completely.

### Fix 6: Pre-polish clustering
Cluster backsolved solutions BEFORE the expensive BFGS polish step to avoid redundant
optimization runs. Not directly related to the boundary derivative problem but saves
significant computation. See `pre_polish_clustering.md`.

---

## 7. Key Numbers to Remember

- Jacobian eigenvalues at t=0: {-413, -397, -7.2, -0.25, 0, 0}
- Boundary layer width: 0.0024 (from 1/413)
- Grid spacing h: 0.01 (2001 points on [0,20])
- Points inside boundary layer: ~4
- AAAD nearest pole to t=0 (S0): -1.896e-7 with residue 1.815e-8
- Resulting d1 error: R/ε² ≈ 505,000 (observed: 505,028)
- True S0'(0): -37.375
- Initial system: 33 equations, 33 variables, 39 data parameters (orders 0-12)
- Re-solve system: 15 equations, 15 variables, 6 data parameters (orders 0-1)
- Number of distinct parameter sets for re-solve: 5
- All 5 parameter sets are wildly wrong (kf1 true=11.5, estimated 0.8-2.9)
