# Transcendental Function Investigation - Findings

## Test 1: SI.jl with transcendentals

| Scenario | Result |
|----------|--------|
| `D(x) = -k*x + A` (polynomial baseline) | SUCCESS - all globally identifiable |
| `D(x) = -k*x + A*sin(5.0*t)` | FAILED: "operator sin is not an arithmetic one" |
| `D(x) = -k*x + A*sin(omega*t)` (omega=param) | FAILED: MethodError in Nemo |
| `D(x) = -k*sin(x)` (state-dependent) | FAILED: "operator sin is not an arithmetic one" |
| `D(x) = -k*x + A*cos(3.0*t)` | FAILED: "operator cos is not an arithmetic one" |
| `D(x) = -k*x + A*p_sin` (placeholder PARAM) | SUCCESS but A,p_sin => :nonidentifiable |

**Key: SI.jl rejects ANY sin/cos. Placeholder parameters give WRONG identifiability.**

## Test 4 & 6: SI.jl "input variable" approach (state without ODE)

**Critical discovery**: When a variable is listed as a STATE but has NO ODE equation, SI.jl automatically treats it as a **known input**.

| Scenario | Result |
|----------|--------|
| `u_f(t)` as state, no ODE | k,A => :globally identifiable |
| `u_f(t)` as parameter (placeholder) | A,p_sin => :nonidentifiable |
| Two inputs `u_sin`, `u_cos` | k,A,B => :globally identifiable |
| DC motor with `u_sin` input (1 observable) | Most params nonidentifiable (correct! too few observables) |
| Two different frequency inputs | k,A,B => :globally identifiable |

**Winner: Input variable approach gives CORRECT identifiability. Parameters approach gives WRONG results.**

## Test 7: Symbolic differentiation

All work correctly:
- `d/dt sin(5t) = 5.0*cos(5.0*t)` ✓
- `d/dt cos(3t) = -3.0*sin(3.0*t)` ✓
- `d²/dt² sin(5t) = -25.0*sin(5.0*t)` ✓
- Chain rule with parameters: `d/dt(-k*x + A*sin(5t)) = 5A*cos(5t) - k*D(x)` ✓

## Test 7G & 8D: Numerical substitution of transcendentals

**IMPORTANT**: `Symbolics.substitute(expr, Dict(t => 0.5))` does NOT evaluate sin:
```
A*sin(5.0*t) → A*sin(2.5)   (sin(2.5) remains symbolic!)
```

But direct substitution of the transcendental subexpression DOES work:
```
Symbolics.substitute(expr, Dict(sin(5.0*t) => 0.5985)) → 0.5985*A   (polynomial in A!)
```

## Test 8C: Full pipeline with polynomial oscillator model

The manual polynomialization approach (u_sin/u_cos with oscillator ODEs) works end-to-end:
- k ≈ 0.5000 (true: 0.5), A ≈ 1.0000 (true: 1.0), omega_val ≈ 5.0000 (true: 5.0)
- Residuals: ~1e-23 (essentially exact)

## Summary of Approaches

### Approach 1: "Input variable" (state without ODE)
- **SI.jl**: Replace sin(c*t) with u_f(t) state. Works, gives correct identifiability.
- **Data gen**: Original ODE with sin(c*t) works natively in OrdinaryDiffEq.
- **Solving**: Template equations will have u_f_0, u_f_1, etc. Substitute analytically computed values.
- **Pro**: Simple, correct identifiability, no extra ODEs.
- **Con**: Can't estimate the frequency (it's baked into the analytical derivatives).

### Approach 2: Oscillator polynomialization (current manual pattern)
- **SI.jl**: Replace sin(ωt) with u_sin, u_cos + oscillator ODEs. Fully polynomial.
- **Data gen**: Integrates the oscillator states alongside the original system.
- **Solving**: omega becomes a solvable parameter.
- **Pro**: Can estimate unknown frequencies. Proven working (Test 8C).
- **Con**: Adds 2 states + 2 observables per frequency. More complex.

### Approach 3: User's simple idea (evaluate after differentiation)
- Works for solving phase but SI.jl blocks it before we get there.
- COMBINED with Approach 1: Use input variable for SI.jl, then user's idea for solving.
- This IS essentially Approach 1 with the insight that we compute derivatives of sin(c*t) analytically.
