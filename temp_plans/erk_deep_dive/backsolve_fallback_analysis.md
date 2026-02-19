# Backsolve Fallback Analysis — 2026-02-18

## Overview

When HC.jl finds parameter solutions at interior shooting points, backward ODE integration
to t=0 can blow up for stiff systems (e.g., ERK). The "backsolve fallback" detects blown
solutions and attempts algebraic re-solve at t=0 with parameters fixed.

This document records what we implemented, what works, what doesn't, and why.

---

## What We Implemented (SIAN Re-run Approach)

### Previous approach (broken)
- Take the original 33-equation SIAN template (designed for 33 unknowns: 6 params + 27 state derivs)
- Post-hoc substitute 6 known param values → 33 equations in 27 unknowns (overdetermined)
- Overdetermined system has numerically inconsistent redundant equations

### New approach (implemented in this session)
- **Bake parameter values into the ODE model** using `apply_prefixed_params_to_model()`
- **Re-run SIAN** on the parameter-free model via `get_si_equation_system()`
- SIAN generates a fresh template with **only state derivative unknowns** → square system
- For ERK: **15 equations, 15 unknowns** (was 33 eqs, 33 vars before param fixing)

### Code changes made
1. `src/core/si_template_integration.jl` — Complete rewrite of `resolve_states_with_fixed_params`
2. `src/core/parameter_estimation.jl` — Fminbox/Newton compatibility fix + restored default bounds
3. `src/core/optimized_multishot_estimation.jl` — Added diagnostic logging for blown backsolves

---

## The 15-Equation System for ERK (Fixed Parameters)

### 15 unknowns

State derivative variables evaluated at the resolve time point:

```
Order 0 (ICs):      S0_0, S1_0, S2_0, C1_0, C2_0, E_0     (6 state values)
Order 1 (1st derivs): S0_1, S1_1, S2_1, C1_1, C2_1, E_1     (6 first derivatives)
Order 2 (2nd derivs): S0_2, S1_2, S2_2                        (3 second derivatives, observed states only)
```

### 15 equations (at t=0, after data substitution)

**6 "readoff" equations** — observable data directly pins state values:
```
Eq1:   S1_0  = y1(0)     = 0           (true: 0)      ✓ accurate
Eq3:   S0_0  = y0(0)     = 5.0         (true: 5.0)    ✓ accurate
Eq5:   S2_0  = y2(0)     ≈ -2.67e-6   (true: 0)      ✓ ~accurate
Eq7:   S1_1  = y1'(0)    = -21,114     (true: 0)      ✗ CATASTROPHICALLY WRONG
Eq11:  S0_1  = y0'(0)    = -8.647e7    (true: -37.4)  ✗ WRONG by factor 2,300,000
Eq14:  S2_1  = y2'(0)    = 4.636e6     (true: 0)      ✗ WRONG by factor 4,600,000
```

**9 structural equations** — pure ODE relationships with parameter values baked in as
rational coefficients. These have NO data variables and NO constant terms:
```
Eq2:   S1_1 = 4.864·C2_0 - 11.15·E_0·S1_0              [from D(S1) = kr2·C2 - kf2·E·S1]
Eq4:   S0_1 = 300·C1_0 - 11.5·E_0·S0_0                  [from D(S0) = kr1·C1 - kf1·E·S0]
Eq6:   S2_1 = 428.13·C2_0                                 [from D(S2) = kc2·C2]
Eq8:   S1_2 = 4.864·C2_1 - 11.15·(E_0·S1_1 + E_1·S1_0)  [from D²(S1)]
Eq9:   E_1 = 300·C1_0 + 433·C2_0 - 11.5·E_0·S0_0 - 11.15·E_0·S1_0  [from D(E)]
Eq10:  C2_1 = 12.45·C1_0 - 433·C2_0 + 11.15·E_0·S1_0    [from D(C2)]
Eq12:  S0_2 = 300·C1_1 - 11.5·(E_0·S0_1 + E_1·S0_0)     [from D²(S0)]
Eq13:  C1_1 = -312.45·C1_0 + 11.5·E_0·S0_0               [from D(C1)]
Eq15:  S2_2 = 428.13·C2_1                                  [from D²(S2)]
```

(Coefficients shown approximately; actual code uses exact rationals like `1024383633//3414610`)

### How the inconsistency works

The wrong readoff values (Eq7, Eq11, Eq14) propagate into the structural equations
via substitution. Example:

1. From Eq6 + Eq14: `C2_0 = S2_1 / 428.13 = 4.636e6 / 428.13 = 10,829`
2. From Eq2 + Eq1 + Eq7: `C2_0 = (S1_1) / 4.864 = -21114 / 4.864 = -4,341`

Two contradictory values for C2_0! (True value: 0)

This is why HC.jl fails: **no point satisfies all 15 equations simultaneously**.

### Why only t=0 fails

At interior time points (e.g., t=10), the interpolated derivatives are accurate because
data exists on both sides. HC.jl succeeds 5/5 at interior points.

At t=0 (first data point = boundary), the interpolant's derivative reflects global curve
behavior, not local boundary behavior. The one-sided nature of boundary extrapolation
causes catastrophic errors, especially for stiff systems where dynamics change dramatically.

---

## Current Results

### ERK with polish_solver_solutions=false
- 10 HC.jl solutions from 2 shooting points
- **4/8 blown** backsolves detected
- 4 unique parameter sets resolved via SIAN re-run
- **All 4 resolve successfully** via HC.jl (these are at interior shooting points)
- Best approx error: ~0.001
- E estimates still terrible (E=-13758 to E=1575 vs true 0.65) — this is from the
  original HC.jl algebraic solution quality, not the backsolve fallback

### ERK with polish_solver_solutions=true
- 12 HC.jl solutions (more solutions found with polishing)
- **5/11 blown** in first round, **10/10 blown** in second round
- 15 total SIAN re-runs:
  - **5 succeed via HC.jl** (interior shooting point)
  - **10 fail** (exact-IC shooting point at t=0) → cascade fallback
- Cascade solves 7 of 15 variables (data readoffs + C2_0)
- Remaining 8 unknowns (C1_0, E_0, C1_1, E_1, C2_1, S0_2, S1_2, S2_2) in 7 equations
  → **underdetermined** (8 vars, 7 eqs — one equation became redundant)
- Previously crashed with FiniteException; fixed by guarding HC.jl against underdetermined systems
- Cascade-solved vars returned as partial solution; C1 and E fall back to 0.0

---

## "Cascading Substitution" — What It Actually Is

Despite the fancy name, it's trivially simple:

1. Look at the equations. Find any with **exactly 1 unknown variable**.
2. Solve it (linear solve: `Symbolics.symbolic_linear_solve`).
3. Substitute the answer into all remaining equations.
4. Repeat until no more single-unknown equations exist.

It's just back-substitution on the trivially solvable equations. For ERK at t=0:

- **Pass 1**: Solves S1_0=0, S0_0=5, S2_0≈0, S1_1=-21114, S0_1=-8.6e7, S2_1=4.6e6
  (all from readoff equations — just reading data values)
- **Pass 2**: Solves C2_0 from Eq6 (after substituting S2_1)
- **Pass 3**: No more single-unknown equations. Done.

Result: 7 variables solved (6 data readoffs + C2_0), 8 remaining unsolved.
The unsolved variables are the unobserved states (C1, E) and their derivatives.

---

## The Data Fallback Problem

When `resolve_states_with_fixed_params` returns a partial solution (missing C1, E),
the caller at `optimized_multishot_estimation.jl:1620-1647` fills in missing states:

```julia
sname = replace(string(s), "(t)" => "")
if haskey(sian_name_to_val, sname)
    push!(raw_ic, sian_name_to_val[sname])       # Found in SIAN solution
elseif haskey(known_param_dict, s)
    push!(raw_ic, known_param_dict[s])            # It's a parameter
else
    # Fallback: check measured quantities or default to 0.0
    fallback_val = 0.0
    for mq in PEP.measured_quantities
        if isequal(mq.rhs, s)
            fallback_val = data_sample[mq_key][1]  # Observed → use data
        end
    end
    push!(raw_ic, fallback_val)                    # Unobserved → 0.0
end
```

For ERK:
- C1: not observed → **0.0** (accidentally correct, true=0)
- E: not observed → **0.0** (WRONG, true=0.65)

We added `@warn` logging to flag every time this fallback executes.

---

## Root Cause: Boundary Interpolation

### How nth_deriv works
- `src/core/derivatives.jl:222-229`
- Uses `TaylorDiff.derivative(f, t, Val(n))` to compute n-th derivative
- `f` is a closure over the interpolant: `x -> obs_interp(x)`
- The interpolant is created by `agp_gpr_robust` (GP-based) or `aaad` (AAA rational)

### Why boundary derivatives are catastrophically wrong
1. **GP/AAA interpolants are global fits** — optimized for function-value accuracy, not derivatives
2. **At boundary (first/last data point)**, data only exists on one side
3. **For stiff systems like ERK**: dynamics change dramatically over [0,20]; the interpolant
   at t=0 "sees" the steep changes at later times and assigns a wildly wrong slope
4. **States starting at 0** (S1, S2, C1, C2) compound this: the true derivative is 0, but the
   interpolant overshoots

### The 0th derivatives are fine
Function values at data points are exact (the interpolant passes through data points).
Only 1st+ derivatives at boundaries are affected.

### Interior points are fine
At the regular shooting points (t=10, etc.), interpolation is accurate on both sides.
HC.jl succeeds 100% at interior points.

---

## Reproducing the Results

### Test script (ERK, no polish)
```julia
# Save as /tmp/erk_test.jl, run with: julia /tmp/erk_test.jl
using ModelingToolkit, DifferentialEquations, ODEParameterEstimation, OrderedCollections

solver = AutoVern9(Rodas4P())
@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t) y0(t) y1(t) y2(t)
D = Differential(t)
states = [S0, C1, C2, S1, S2, E]
parameters = [kf1, kr1, kc1, kf2, kr2, kc2]
eqs = [
    D(S0) ~ -kf1*E*S0 + kr1*C1,
    D(C1) ~ kf1*E*S0 - (kr1 + kc1)*C1,
    D(C2) ~ kc1*C1 - (kr2 + kc2)*C2 + kf2*E*S1,
    D(S1) ~ -kf2*E*S1 + kr2*C2,
    D(S2) ~ kc2*C2,
    D(E) ~ -kf1*E*S0 + kr1*C1 - kf2*E*S1 + (kr2 + kc2)*C2,
]
@named model = ODESystem(eqs, t, states, parameters)
measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]
ic = [5.0, 0, 0, 0, 0, 0.65]
p_true = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]

data_sample = ODEParameterEstimation.sample_data(model,
    measured_quantities, [0., 20.],
    Dict(parameters .=> p_true), Dict(states .=> ic),
    1000; solver = solver)

model, mq = create_ordered_ode_system("test", states, parameters, eqs, measured_quantities)
pep = ParameterEstimationProblem("test", model, mq, data_sample, [0., 20.], nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)

opts = EstimationOptions(
    use_parameter_homotopy = true, datasize = 1001, noise_level = 0,
    system_solver = SolverHC, flow = FlowStandard, use_si_template = true,
    polish_solver_solutions = true, polish_solutions = false,
    interpolator = InterpolatorAGPRobust, diagnostics = true)

meta, results = analyze_parameter_estimation_problem(pep, opts)
```

### Key log lines to look for
```
[RESOLVE] Re-running SIAN with 6 fixed parameters    # SIAN re-run triggered
[RESOLVE] Instantiated system: 15 eqs, 15 state vars (square)   # Square system ✓
[RESOLVE] HC.jl found 1 solution(s)    # Success (interior point)
[RESOLVE] HC.jl found no solutions     # Failure (boundary point)
[RESOLVE] Remaining system is underdetermined (7 eqs, 8 vars)   # Cascade leaves underdetermined
[RESOLVE-MAP] State E NOT in SIAN solution — using fallback=0.0 (ZERO)   # Missing state
[BACKSOLVE] Solution N BLOWN: err=1.0e15, blown_states=...   # Blown detection
```

---

## Next Steps

### Immediate: Fix boundary derivative estimation
The interpolated 1st derivatives at t=0 are wrong by factors of millions.
This is the single point of failure. **This is its own project** — boundary derivative
estimation is harder than it sounds and needs its own plan. See separate plan document.

### Deferred
- Pre-polish clustering (avoid redundant BFGS runs)
- Pareto fallback (random-start BFGS when 0 algebraic solutions found)
- Investigate why even HC.jl-successful ERK resolves give terrible E estimates
  (E=-13758 vs true 0.65) — may indicate the polynomial system has many spurious roots
