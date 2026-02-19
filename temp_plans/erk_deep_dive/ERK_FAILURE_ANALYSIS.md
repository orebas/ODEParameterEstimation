# ERK Model: Why Parameter Estimation Fails

## Executive Summary

The ERK model fails to produce accurate parameter estimates due to **three compounding issues**, ranked by severity:

1. **Catastrophic backward ODE instability** (FATAL): Backsolving from shooting points to t=0 amplifies roundoff errors by factors of 10^100+ due to fast decay modes becoming fast growth modes in reverse time.
2. **Degenerate initial conditions**: Four of six states start at exactly zero (C1=C2=S1=S2=0), creating a degenerate point for the polynomial solver.
3. **Large parameter scale mismatch**: Parameters span a 100x range (kr2=4.864 to kc2=428.13), degrading numerical conditioning.

## The ERK Model

```
D(S0) = -kf1*E*S0 + kr1*C1
D(C1) = kf1*E*S0 - (kr1 + kc1)*C1
D(C2) = kc1*C1 - (kr2 + kc2)*C2 + kf2*E*S1
D(S1) = -kf2*E*S1 + kr2*C2
D(S2) = kc2*C2
D(E)  = -kf1*E*S0 + kr1*C1 - kf2*E*S1 + (kr2 + kc2)*C2
```

- **6 states**, 3 observed (y0~S0, y1~S1, y2~S2)
- **6 parameters**: kf1=11.5, kr1=300.0, kc1=12.45, kf2=11.15, kr2=4.864, kc2=428.13
- **ICs**: [5.0, 0, 0, 0, 0, 0.65]

This is a dual Michaelis-Menten enzyme kinetics system: E catalyzes S0→S1→S2 through two sequential reactions via intermediate complexes C1 and C2.

## Conservation Laws

The system has **two conservation laws** (verified algebraically):

1. **Total substrate**: S0 + C1 + C2 + S1 + S2 = 5.0 (constant)
2. **Total enzyme**: E + C1 + C2 = 0.65 (constant)

This means:
- Only **4 of 6 states** are dynamically independent
- **E(t) = y0(t) + y1(t) + y2(t) - 4.35** — directly computable from observables!
- C1 and C2 can be inferred from first derivatives of observables
- The system is **fully observable and globally identifiable** (confirmed by SI.jl)

## Diagnostic Results

### What Works

| Stage | Result | Details |
|-------|--------|---------|
| Data generation | SUCCESS | Clean noiseless data, observables span full dynamic range |
| Identifiability analysis | SUCCESS | All 12 variables globally identifiable, derivative levels needed: {1→2, 2→1, 3→2} |
| SIAN polynomial system | SUCCESS | 33 equations in 33 unknowns, Jacobian rank 33, converges in 1 iteration |
| HC solving | SUCCESS | Finds 6 solutions per shooting point (12 after C1↔C2 symmetry) |

### Where It Fails

#### Issue 1: Catastrophic Backward ODE Integration (THE KILLER)

The HC solver finds accurate parameter values at interior shooting points:
```
At shooting time ~5.7:
  Parameters found: kf1=11.50, kr1=300.0, kc1=12.45, kf2=11.15, kr2=4.864, kc2=428.13  ← EXACT!
  States at t=5.7:  S0=1.085, C1=0.025, C2=0.001, S1=0.001, S2=3.889, E=0.624          ← REASONABLE

But backsolved to t=0:
  S0 = 4.04×10¹¹¹    ← CATASTROPHIC!
  C1 = -4.04×10¹¹¹   ← CATASTROPHIC!
  E  = 4.12×10¹¹¹    ← CATASTROPHIC!
```

**Root cause**: The linearized system around the solution trajectory has eigenvalues approximately {-kr1-kc1, -kr2-kc2, ...} ≈ {-312, -433, ...}. When integrating **backward** in time from t=5.7 to t=0:
- These eigenvalues flip sign to +312 and +433
- Errors amplify by exp(433 × 5.7) ≈ 10^1072
- Even machine-epsilon errors (10^-16) become 10^1056

This is **mathematically unavoidable** for stiff systems integrated backward. The shooting-point approach fundamentally cannot work for systems with fast timescales unless the shooting point is very close to t=0.

#### Issue 2: The C1↔C2 Symmetry

The polynomial system admits a symmetry where C1 and C2 swap roles, producing two classes of solutions:
```
Solution A: C1=0.025, C2=0.001  (correct)
Solution B: C1=0.001, C2=0.025  (swapped)
```
This doubles the solution count (6 → 12) and the swapped solutions have completely wrong parameter values (kf1 ≈ -0.013, kr1 ≈ -447, etc.).

#### Issue 3: Degenerate Zero ICs

At t=0, the true solution has C1(0)=C2(0)=S1(0)=S2(0)=0. This is a boundary of the solution manifold. The HC solver at t=0 finds solutions like:
```
S0=4.99, C1=-0.41, C2=0.63, S1~0, S2~0, E=-0.63  ← WRONG (negative C1, E)
```
These are spurious solutions that satisfy the polynomial equations but violate physical constraints (non-negativity).

### Derivative Expression Growth (Not the Bottleneck)

While derivative expressions grow ~5× per level:
```
y0 derivatives: 26 → 159 → 804 → 3,950 → 19,287 → 94,042 → 458,370 chars
```
The code correctly handles this via:
- Symbolic differentiation keeps expressions compact (DD structure uses Differential notation)
- Numerical evaluation via substitution dict avoids symbolic blowup
- The identifiability analysis only needs derivative levels {1→2, 2→1, 3→2}, far below the worst case

## Potential Fixes

### Fix 1: Forward-only shooting (HIGH IMPACT)

Instead of backsolving to t=0, evaluate the solution quality **at the shooting point** and forward:
- Solve the ODE **forward** from the shooting point
- Compare against data in the **forward** direction only
- Report states at the shooting time, not at t=0

This completely avoids backward integration instability.

### Fix 2: Use conservation laws as constraints

Since E = y0 + y1 + y2 - 4.35 and C1 + C2 = 5 - y0 - y1 - y2:
- Reduce the system to 4 independent states before estimation
- Eliminate E and one of {C1, C2} using conservation laws
- This cuts the polynomial system from 33 unknowns to ~23

This requires knowing (or estimating) the conservation constants, which depend on ICs.

### Fix 3: Enforce non-negativity constraints

Filter HC solutions to reject those with:
- Negative state values (concentrations must be non-negative)
- Negative rate constants (kf1, kr1, etc. must be positive)

This would immediately discard the spurious C1↔C2-swapped solutions.

### Fix 4: Multi-shooting with short intervals

Instead of backsolving over [0, 20], use very short shooting intervals (< 0.01 for this system):
- The backward instability grows as exp(433 × Δt)
- For Δt=0.01: amplification factor ≈ exp(4.33) ≈ 76 (manageable)
- For Δt=5.0: amplification factor ≈ 10^940 (impossible)

### Fix 5: Stiff-aware backsolving

If backward integration is needed, use the adjoint method or BVP formulation instead of naive backward ODE solving. The adjoint integrates the **transpose** system forward, avoiding instability.

## Reproduction

```julia
julia src/examples/failing/erk_analysis/diagnose_erk.jl
```

See `diagnostic_output.log` for full output.
