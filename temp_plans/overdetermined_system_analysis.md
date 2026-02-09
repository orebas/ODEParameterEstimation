# Overdetermined System Analysis: Transcendental Function Handling

## Date: 2026-02-08
## Status: Phase 1 complete, needs empirical validation

---

## 1. Overview

The transcendental function support (`_trfn_`) introduces a transformation that converts ODE systems containing `sin(c*t)`, `cos(c*t)`, or `exp(c*t)` into polynomial systems suitable for SIAN/SI.jl identifiability analysis and HomotopyContinuation.jl solving. This document explains why **overdetermined polynomial systems** arise as a side effect of this transformation, the heuristic used to handle them, and the associated risks.

---

## 2. The Transformation Pipeline

### 2.1 Detection (`transcendental_utils.jl:166`)
`detect_transcendentals()` walks the expression trees of ODE equations and measured quantities, finding subexpressions of the form `sin(c*t)`, `cos(c*t)`, `exp(c*t)` where `c` is a known numeric constant.

### 2.2 Model Augmentation (`transcendental_utils.jl:278`)
`create_transformed_model()` replaces each transcendental subexpression with a new state variable (`_trfn_sin_5_0(t)`, `_trfn_cos_5_0(t)`, etc.) and adds:

- **Oscillator ODEs**: For sin/cos at frequency `c`:
  ```
  D(_trfn_sin_c) = c * _trfn_cos_c
  D(_trfn_cos_c) = -c * _trfn_sin_c
  ```
  For exp at rate `c`:
  ```
  D(_trfn_exp_c) = c * _trfn_exp_c
  ```

- **New observables**: Each oscillator state gets its own measurement equation:
  ```
  _obs_trfn_sin ~ _trfn_sin_c
  _obs_trfn_cos ~ _trfn_cos_c
  ```

- **Known initial conditions**: `sin(0)=0`, `cos(0)=1`, `exp(0)=1`

- **Synthetic data**: Generated analytically via `generate_input_data()` at all time points.

### 2.3 Top-Level Call (`analysis_utils.jl:343-352`)
The transformation is invoked at the top of `analyze_parameter_estimation_problem()`:
```julia
if opts.auto_handle_transcendentals
    t_var = ModelingToolkit.get_iv(PEP.model.system)
    PEP, _tr_info = transform_pep_for_estimation(PEP, t_var)
end
```
This ensures the transformed PEP is used for **both** identifiability analysis and parameter estimation.

The same call also happens in `optimized_multishot_estimation.jl:986` for the parameter homotopy path.

---

## 3. Why SI.jl's Template is Correct and Square (Symbolically)

SI.jl (StructuralIdentifiability.jl) receives the augmented polynomial system. From its perspective:
- The oscillator states are ordinary state variables
- The oscillator observables are ordinary measurement equations
- The system is polynomial and the template it produces is **square** (same number of equations as unknowns)

The template contains variables in the SIAN naming convention:
- `y1_0, y1_1, ...` — observable derivatives (data)
- `x_0, alpha_0, ...` — states and parameters (unknowns)
- `_trfn_sin_5_0_0, _trfn_sin_5_0_1, ...` — oscillator state derivatives (treated as unknowns by SI.jl)
- `_obs_trfn_..._0, _obs_trfn_..._1, ...` — oscillator observable derivatives (data)

At the symbolic level, everything balances. The template is a valid square polynomial system.

---

## 4. What Happens at Numerical Instantiation

### 4.1 Standard Path (`si_template_integration.jl:23-261`)

`construct_equation_system_from_si_template()` instantiates the symbolic template at a specific time point:

1. **Data substitution** (lines 107-144): Observable derivative values (`y1_0`, `y1_1`, ...) are computed from interpolated data and substituted.

2. **_trfn_ substitution** (lines 147-163): The `_trfn_` template variables are **also** substituted with their known analytical values:
   ```julia
   for v in vars_in_template
       var_name = string(v)
       trfn_val = evaluate_trfn_template_variable(var_name, t_point)
       if !isnothing(trfn_val)
           interpolated_values_dict[v] = trfn_val
       end
   end
   ```
   This is correct because `_trfn_` variables represent known functions of time, not free unknowns.

3. **Trivial equation removal** (lines 187-209): After substitution, equations whose **every variable** has been substituted become `0 ≈ 0`. These are safely removed (zero variables remaining).

4. **The problem**: After removing trivially-satisfied equations, there may still be more non-trivial equations than remaining variables. This is the **overdetermined system**.

### 4.2 Parameter Homotopy Path (`optimized_multishot_estimation.jl:1090-1324`)

The parameter homotopy path handles this differently:

1. `classify_trfn_in_template()` (line 1093) identifies `_trfn_` variables among the solve vars
2. Equations containing only data + `_trfn_` vars are removed (lines 1257-1267)
3. `_trfn_` vars are moved to `data_vars` and evaluated at each shooting point (lines 1269-1315)

This path uses HomotopyContinuation's parameter homotopy, which naturally handles the `_trfn_` values as varying parameters across shooting points.

---

## 5. Why the Forced LV Specifically Goes Overdetermined

### 5.1 The Model

```julia
D(x) = alpha*x - beta*x*y - h*sin(omega*t)
D(y) = delta*x*y - gamma*y
y1 ~ x, y2 ~ y    # Both states directly observed
```

### 5.2 After Transformation

```julia
D(x) = alpha*x - beta*x*y - h*_trfn_sin_2_0
D(y) = delta*x*y - gamma*y
D(_trfn_sin_2_0) = 2*_trfn_cos_2_0
D(_trfn_cos_2_0) = -2*_trfn_sin_2_0

y1 ~ x                          # original
y2 ~ y                          # original
_obs_sin ~ _trfn_sin_2_0        # added
_obs_cos ~ _trfn_cos_2_0        # added
```

### 5.3 Why It Becomes Overdetermined

The key factors that combine to create excess equations:

1. **Both original states are directly observed** (`y1~x`, `y2~y`). This means the SI.jl template already includes equations from observable derivatives that effectively encode the state dynamics. The states themselves are "data" — their values at any time point are known from interpolation.

2. **The oscillator states are also fully observed** (`_obs_sin~_trfn_sin`, `_obs_cos~_trfn_cos`). After substituting both the original observable data AND the `_trfn_` analytical values, many equations become redundant.

3. **The coupling between the sin/cos oscillator creates constraints** that, once the oscillator values are substituted, provide no new information about the real unknowns (parameters `alpha, beta, delta, gamma`).

The result: after substituting all data variables and all `_trfn_` variables, we have more equations than remaining unknowns (the 4 parameters + possibly some state derivatives).

### 5.4 Why Other Models Don't Have This Problem (as severely)

Models like `dc_motor_sinusoidal` or `aircraft_pitch_sinusoidal` observe only **one** output (e.g., `y1 ~ omega_m`). The other states are hidden, so they remain as unknowns in the template. The `_trfn_` substitution removes some variables and equations, but the ratio stays balanced because there are enough real unknowns to "absorb" the remaining equations.

---

## 6. The Heuristic: Redundant Equation Removal

### 6.1 Location

`si_template_integration.jl:221-257`

### 6.2 Algorithm

```julia
while length(kept_equations) > length(final_vars)
    # Build per-variable occurrence count
    var_eq_count = Dict{Any, Int}()
    for eq in kept_equations
        for v in Symbolics.get_variables(eq)
            var_eq_count[v] = get(var_eq_count, v, 0) + 1
        end
    end

    # Try removing from the end (highest derivative order = most numerically sensitive)
    removed = false
    for idx in length(kept_equations):-1:1
        eq_vars = Symbolics.get_variables(kept_equations[idx])
        # Safe if every variable appears in at least 2 equations (this one + another)
        if all(v -> get(var_eq_count, v, 0) >= 2, eq_vars)
            deleteat!(kept_equations, idx)
            removed = true
            break
        end
    end

    if !removed
        @warn "Cannot safely remove any equation without losing a variable."
        break
    end

    # Recompute final_vars
    final_vars = OrderedSet()
    for eq in kept_equations
        union!(final_vars, Symbolics.get_variables(eq))
    end
end
```

### 6.3 Design Rationale

1. **"Safe to remove" criterion**: An equation is removable only if every variable in it also appears in at least one other remaining equation. This guarantees no variable is "lost" (becomes unconstrained).

2. **Remove from the end**: Higher-indexed equations correspond to higher derivative orders in the SI.jl template. These are typically more numerically sensitive (higher-order derivatives of interpolated data are noisier). Preferring to remove these preserves the most numerically stable constraints.

3. **Iterative**: The loop removes one equation at a time and recomputes, because removing one equation changes the occurrence counts and may make previously non-removable equations removable.

4. **Graceful degradation**: If no equation can be safely removed, the system remains overdetermined and is passed to HC.jl as-is (with a warning). HC.jl can sometimes handle mildly overdetermined systems via randomization.

---

## 7. Risk Assessment

### 7.1 Known Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Heuristic removes a "wrong" equation** — one that, while redundant in exact arithmetic, provides crucial numerical information | **Medium** | The criterion is conservative (requires all vars to appear elsewhere), but numerical conditioning can still suffer |
| **HC.jl fails on non-square systems** | **High** | HC.jl's `solve()` requires square systems. The heuristic MUST succeed in reducing to square, or HC fails. The `@warn` fallback does NOT help HC. |
| **Heuristic doesn't generalize** | **Medium** | Only tested on 8 sinusoidal models. Models with complex coupling, multiple frequencies, or mixed sin/cos/exp may behave differently |
| **Order of equation removal matters** | **Low** | Different removal orders give algebraically equivalent but numerically different systems. The "remove from end" policy is reasonable but not optimal |
| **Interaction with reconstruction loop** | **Low** | If the base system (before _trfn_) needed derivative level increments, the overdetermined handling might interact poorly with the reconstruction loop in `solve_parameter_estimation` |

### 7.2 Models at Risk

Models most likely to trigger overdetermined behavior:
- **All states directly observed** + **sinusoidal input**: `forced_lv_sinusoidal`, `bicycle_model_sinusoidal`, `boost_converter_sinusoidal`, `bilinear_system_sinusoidal` (all have 2 states, 2 outputs)
- Models with `exp(c*t)`: Not yet tested

Models less likely to have issues:
- **Single output**: `dc_motor_sinusoidal`, `quadrotor_sinusoidal`, `magnetic_levitation_sinusoidal`, `aircraft_pitch_sinusoidal` (more hidden states → more real unknowns to balance)

### 7.3 What Could Go Wrong

1. **HC.jl `ArgumentError: not a square system`**: If the heuristic can't reduce the system to square (all removable equations are gone but system is still overdetermined), HC will throw. The parameter homotopy path would need similar handling.

2. **Silent wrong answers**: If a numerically important equation is removed, the solver might find solutions that satisfy the reduced system but not the original — giving incorrect parameter estimates. This would show up as high reconstruction error.

3. **Model-specific failures**: A model where the coupling structure prevents ANY equation from being removable (every equation has a unique variable) would fail even though the system is algebraically overdetermined.

---

## 8. Code Locations Summary

| File | Lines | What |
|------|-------|------|
| `transcendental_utils.jl` | 1-808 | All _trfn_ detection, transformation, evaluation |
| `transcendental_utils.jl` | 600-673 | `transform_pep_for_estimation` — main entry point |
| `transcendental_utils.jl` | 278-425 | `create_transformed_model` — oscillator ODE augmentation |
| `transcendental_utils.jl` | 776-807 | `classify_trfn_in_template` — used by parameter homotopy path |
| `si_template_integration.jl` | 147-163 | _trfn_ value substitution at shooting points |
| `si_template_integration.jl` | 187-209 | Trivially-satisfied (0-variable) equation removal |
| `si_template_integration.jl` | 221-257 | **Overdetermined equation removal heuristic** |
| `optimized_multishot_estimation.jl` | 1090-1096 | _trfn_ classification in parameter homotopy |
| `optimized_multishot_estimation.jl` | 1246-1324 | _trfn_ evaluation at shooting points |
| `parameter_estimation_helpers.jl` | 530-547 | _trfn_ state IC computation (analytical) |
| `parameter_estimation_helpers.jl` | 566-585 | Directly-observed state fallback (data sample) |
| `analysis_utils.jl` | 343-352 | Top-level transform call |
| `estimation_options.jl` | (field) | `auto_handle_transcendentals::Bool` option |
| `control_systems.jl` | 2040-2457 | 8 sinusoidal model definitions |
| `load_examples.jl` | 99-107 | 8 sinusoidal model registrations |

---

## 9. Recommended Next Steps

1. **Run all 8 sinusoidal models** via `julia src/examples/run_examples.jl` and examine:
   - Whether any model fails with "not a square system" errors
   - Whether the `[TEMPLATE] Overdetermined` log messages appear
   - Whether reconstruction error is acceptable

2. **Compare sinusoidal vs. identifiable versions**: The 8 sinusoidal models have hand-polynomialized counterparts (e.g., `dc_motor_identifiable`). Run both and compare parameter estimates.

3. **Add a fallback for the standard path**: If the heuristic fails (cannot reduce to square), consider:
   - Using least-squares / NLopt solver instead of HC.jl
   - Switching to the parameter homotopy path (which handles _trfn_ differently)
   - Random equation selection (pick n equations from n+k, try multiple subsets)

4. **Consider a formal redundancy test**: Instead of the "all vars appear elsewhere" heuristic, compute the symbolic Jacobian rank to determine which equations are algebraically redundant.

5. **Verify `swing_equation` D→D_damp rename**: The parameter `D` in `swing_equation()` was renamed to `D_damp` to avoid conflict with the `Differential` operator `D`. This is a breaking change if anyone depends on the old parameter name.

---

## 10. Appendix: Concrete Example (forced_lv_sinusoidal)

### Before transformation:
- 2 ODEs, 4 parameters, 2 observed states
- Contains `sin(2*t)` — not polynomial

### After transformation:
- 4 ODEs (original 2 + oscillator pair), 4 parameters, 4 states
- 4 observables (y1~x, y2~y, obs_sin~_trfn_sin, obs_cos~_trfn_cos)
- System is polynomial — SI.jl produces a square template

### At template instantiation:
- SI.jl template has, say, 8 equations and 8 variables
- After substituting y1/y2 derivatives (data) + _trfn_ derivatives (analytical): ~4 variables remain
- But only ~2-3 equations become truly trivial (0 vars)
- Result: 5 equations, 4 variables → overdetermined by 1

### After heuristic:
- Find equation where all vars appear in other equations → remove it
- Result: 4 equations, 4 variables → square → HC.jl can solve
