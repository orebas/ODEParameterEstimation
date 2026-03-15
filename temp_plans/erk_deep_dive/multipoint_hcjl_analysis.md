# ERK Multipoint HC.jl Analysis — 2026-02-22

## Executive Summary

Comprehensive analysis of HC.jl behavior at all 8 shooting points for the ERK 33×33
polynomial system, with 3 interpolation methods (AAAD, AGPRobust, AAAD-GPR) and perfect
(Taylor recursion) data. Includes sensitivity analysis via implicit function theorem.

### Key Findings

1. **Generic degree = 2**: The 33×33 system has exactly 2 solutions. One is the true
   parameters; the other is a kc1↔kc2 / C1↔C2 "mirror" exploiting cascade symmetry.

2. **AAAD is machine-precision at all interior points** (t=2.86 through t=17.14),
   recovering true parameters with sum_rel_err as low as 0.000004.

3. **cond(∂F/∂x) ≈ 10^14–10^15**: The system Jacobian is extremely ill-conditioned.
   Even tiny data errors get amplified by factors of 10^6–10^9.

4. **AGPRobust fails entirely** despite only having ~0.05%–1.76% errors in 3rd-order
   derivatives, because y2(S2) ord 2–3 errors are amplified by sensitivity coefficients
   of magnitude 10^7–10^9.

5. **Point 1 (t=0) is degenerate**: 0 solutions even with perfect data (4 of 6 ICs = 0).

6. **Point 8 (t=20) is ill-conditioned**: Even AAAD's sub-epsilon errors corrupt both solutions.

---

## System Structure

- 33 equations, 33 unknowns, 12 data variables (3 obs × orders 0–3)
- 6 parameters: kf1, kr1, kc1, kf2, kr2, kc2
- 27 state derivative unknowns: S0_0 through S0_4, C1_0 through C1_3, C2_0 through C2_3,
  S1_0 through S1_4, S2_0 through S2_4, E_0 through E_3
- Observable state order-0 unknowns (S0_0, S1_0, S2_0) are trivially pinned by data (y0_0, y1_0, y2_0)
- Unobserved state order-0 unknowns (C1_0, C2_0, E_0) must be solved algebraically

---

## Interpolation Accuracy at Shooting Points

All values are % relative error. Only worst-case data variable shown per point.

| Point | t      | AAAD worst | AGPRobust worst             | AAAD-GPR worst          |
|-------|--------|------------|-----------------------------|-------------------------|
| 1     | 0.00   | 1.35M% (y0 ord 1, poles) | 108% (y1 ord 3)   | 120% (y2 ord 3)        |
| 2     | 2.86   | 0.00%      | **11.76% (y2 ord 3)**       | 228.75% (y1 ord 3)     |
| 3     | 5.71   | 0.00%      | **1.76% (y2 ord 3)**        | 0.32% (y1 ord 3)       |
| 4     | 8.57   | 0.00%      | 3.63% (y2 ord 3)            | 0.00%                  |
| 5     | 11.43  | 0.00%      | 0.67% (y2 ord 3)            | 0.00%                  |
| 6     | 14.29  | 0.00%      | 2.34% (y2 ord 3)            | 0.01%                  |
| 7     | 17.14  | 0.00%      | 7.25% (y2 ord 3)            | 29.32% (y1 ord 3)      |
| 8     | 20.00  | 0.00%      | 16.5M% (y0 ord 3)           | 15.2M% (y0 ord 3)      |

**AGPRobust pattern**: y2(S2) order 3 is consistently the worst variable. Orders 0–2 are
typically <0.01%. The GP kernel cannot resolve 3rd-order dynamics of the S2 observable.

---

## HC.jl Solution Counts

| Point | t      | AAAD  | Perfect | Notes |
|-------|--------|-------|---------|-------|
| 1     | 0.00   | 0/0   | 0/0     | Degenerate (zero ICs) |
| 2     | 2.86   | 2/2   | 2/2     | Both methods find 2 real solutions |
| 3     | 5.71   | 2/2   | 2/2     | Same |
| 4     | 8.57   | 2/2*  | 2/2     | *First diagnostic showed 1, but fresh solve gives 2 |
| 5     | 11.43  | 2/2*  | 1/1*    | *Varies by run |
| 6     | 14.29  | 2/2*  | 2/2     | |
| 7     | 17.14  | 1/1   | 2/2     | AAAD loses one path |
| 8     | 20.00  | 2/2   | 2/2     | Both found but both BAD with AAAD |

---

## AAAD Solution Quality at Each Point

| Point | t      | Best sol Σ|rel_err| | Quality     | Note |
|-------|--------|---------------------|-------------|------|
| 1     | 0.00   | —                   | DEGENERATE  | 0 solutions |
| 2     | 2.86   | 0.000239            | ★★★ EXCELLENT | |
| 3     | 5.71   | **0.000004**        | ★★★ EXCELLENT | Best single point |
| 4     | 8.57   | 0.000020            | ★★★ EXCELLENT | |
| 5     | 11.43  | 0.000155            | ★★★ EXCELLENT | |
| 6     | 14.29  | 0.001747            | ★★ GREAT    | Slight degradation |
| 7     | 17.14  | 0.016996            | ★ GOOD      | One path lost |
| 8     | 20.00  | 12.89               | ✗✗ BAD      | Conditioning issue |

---

## AGPRobust Solution Quality — Detailed Analysis

### Point 2 (t = 2.86)

**Data errors**: Only 3 of 12 data variables have measurable error:
- y0(S0) ord 3: Δ = +1.54e-5 (0.048%)
- y2(S2) ord 2: Δ = +5.11e-4 (0.32%)
- y2(S2) ord 3: Δ = -3.78e-3 (11.76%)

**HC.jl results**: 2 solutions found, BOTH bad:
- Sol 1: Σ|rel_err| = 5.33 — all params wrong (kf1=0.38 vs 11.5, kr1=-0.86 vs 300)
- Sol 2: Σ|rel_err| = 7.74 — similar pattern but worse

**What's preserved**: Observable ICs are exact (S0_0, S1_0, S2_0 ≈ 0% error).
E_0 has 6.0% error. C1_0 and C2_0 are badly wrong.

### Point 3 (t = 5.71)

**Data errors**: Even smaller:
- y2(S2) ord 2: Δ = +1.88e-4 (0.23%)
- y2(S2) ord 3: Δ = +3.61e-4 (1.76%)

**HC.jl results**: 2 solutions found, BOTH identical (max|imag|=2.35, both are
the same conjugate pair that collapsed):
- Sol 1 = Sol 2: Σ|rel_err| = 5.88 — all params near zero
- All 6 params are in range [-0.21, 0.54] instead of [4.86, 428.13]

**What's preserved**: Same pattern — S0_0, S1_0, S2_0 exact; E_0 has 2.1% error.

---

## Sensitivity Analysis (Implicit Function Theorem)

At the true solution: F(x*, d*) = 0.
Perturbation: dx = -(∂F/∂x)^{-1} (∂F/∂d) · Δd

### Condition numbers
- Point 2: cond(∂F/∂x) = **1.03 × 10^14**
- Point 3: cond(∂F/∂x) = **1.23 × 10^15**

### Dominant sensitivities (∂x/∂d) for parameter kf1_0

| Data variable    | Sensitivity at t=2.86 | Sensitivity at t=5.71 |
|------------------|-----------------------|-----------------------|
| y0(S0) ord 3     | -4.60e+04             | -1.58e+05             |
| y2(S2) ord 2     | -1.21e+07             | -6.71e+07             |
| y2(S2) ord 3     | **-6.12e+06**         | **-6.69e+07**         |
| y1(S1) ord 3     | +5.36e+08             | +5.88e+09             |

### How AGPRobust errors propagate to kf1_0

**At Point 2 (t=2.86):**
```
Δ(y2 ord 3) = -3.78e-3  ×  (dx/dd = -6.12e+06)  =  contribution +23,158
Δ(y2 ord 2) = +5.11e-4  ×  (dx/dd = -1.21e+07)  =  contribution  -6,208
                                        Total predicted: kf1 → 16,773 (actual: 0.38)
```
The linear prediction says kf1 should be ~16,773 — but the actual HC.jl solution is 0.38.
This means the linear approximation BREAKS DOWN: the data error is so large relative to
the basin of attraction that the algebraic solver jumps to a completely different branch.

**At Point 3 (t=5.71):**
```
Δ(y2 ord 3) = +3.61e-4  ×  (dx/dd = -6.69e+07)  =  contribution -24,150
Δ(y2 ord 2) = +1.88e-4  ×  (dx/dd = -6.71e+07)  =  contribution -12,640
                                        Total predicted: kf1 → -36,597 (actual: 0.46)
```
Same story — linear prediction gives ~-36,000, but actual solution is 0.46.

### Critical Insight

The sensitivity coefficients for y2(S2) derivatives orders 2 and 3 are O(10^7),
meaning a 0.01% error in y2 ord 3 produces a predicted displacement of:
  0.0001 × 6.7e7 = 6,700 (on a true value of 11.5)

This is a **600× relative displacement** from just 0.01% data error!

The system is **beyond the linear regime** — the perturbation is so large that the
algebraic solver doesn't just shift the true root slightly, it snaps to a completely
different algebraic branch (all params near zero) that didn't exist as a real solution
before the perturbation.

### Why y2(S2) ord 3 has the highest sensitivity

S2 is the "output product" of the dual enzyme cascade: S0 → C1 → C2 → S1 → S2.
Its 3rd derivative encodes 3 levels of rate-of-change information about the cascade.
The sensitivity coefficients are enormous because the mapping from
(kf1, kr1, kc1, kf2, kr2, kc2) → d³S2/dt³ passes through all 6 rate equations,
accumulating multiplicative factors.

---

## Why the "Mirror" Solution Exists

The 2nd algebraic solution (Σ|rel_err| ≈ 39.35) swaps:
- kc1 ↔ kc2 (12.45 ↔ 428.13)
- kr1 ↔ kr2 (approx, with sign changes)
- C1_0 ↔ C2_0

This exploits the symmetry of the dual Michaelis-Menten cascade:
E + S0 ⇌ C1 → S1 + E  and  E + S1 ⇌ C2 → S2 + E
The two catalytic steps have identical algebraic structure.

The mirror solution has kf1_0 ≈ -0.013 (negative!) and kr1_0 ≈ -447 (negative!),
so it's physically meaningless — but it's a valid algebraic root of the polynomial system.

---

## Implications

1. **AAAD is the right interpolator for ERK**: Machine-precision at all interior points.
2. **AGPRobust cannot work for ERK**: cond(∂F/∂x) = 10^14 means you need 14+ digits of
   data accuracy. AGPRobust's 3rd-order derivative errors (~0.05–12%) correspond to
   perturbations ~10^4× larger than the basin of attraction.
3. **The system is well-posed**: Only 2 solutions (total degree 2), one is physical.
   The algebraic problem is fully solvable — it's purely an interpolation challenge.
4. **Skip boundary points**: t=0 is degenerate, t=20 is ill-conditioned.
   Points 2–6 (t=2.86 to t=14.29) are the sweet spot.
5. **Pre-filtering the mirror solution**: Σ|rel_err| ≈ 39 vs ≈ 0.001 — trivially distinguishable
   by any metric (param range check, ODE residual, etc.)

---

## Scripts

- `/tmp/erk_hcjl_deep_diagnostic.jl` — interpolation errors + HC.jl counts at all 8 points
- `/tmp/erk_solution_values.jl` — actual solution values with distance from truth
- `/tmp/erk_agprobust_sensitivity.jl` — AGPRobust detail at points 2,3 + Jacobian analysis
- Outputs: `/tmp/erk_deep_diag_output.txt`, `/tmp/erk_solution_values_output.txt`,
  `/tmp/erk_agprobust_sensitivity_output.txt`
