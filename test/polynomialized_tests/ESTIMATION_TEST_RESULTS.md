# Polynomialized Systems: Parameter Estimation Test Results

## Test Configuration
- **Data points**: 201-501
- **Noise level**: 0.0 (noiseless)
- **Julia**: Multi-threaded execution now supported

## Package Versions (Updated 2025-12-03)
- **Groebner.jl**: v0.10.0 (upgraded from v0.9.5)
- **StructuralIdentifiability.jl**: v0.5.17 (upgraded from v0.5.16)
- **SIAN.jl**: v1.7.1

## Groebner.jl Threading Bug: RESOLVED

**Previous issue (Groebner v0.9.5)**: All tests failed with multithreaded Julia due to a BoundsError in `Groebner._groebner_learn_and_apply_threaded`:
```
BoundsError: attempt to access 7-element Vector{...} at index [8]
```

**Resolution**: Upgraded to Groebner v0.10.0 which fixes this bug. Multi-threaded execution now works correctly.

**Tested**: Successfully ran with 12 threads on simple model (2 params, 2 states)

## Test Results Summary

| System | Params | States | Status | Notes |
|--------|--------|--------|--------|-------|
| Simple (baseline) | 2 | 2 | SUCCESS | ~0% error |
| DC Motor | 6 | 4 | UNIDENTIFIABLE | 3 identifiable combinations |
| Bilinear System | 2 | 4 | NO SOLUTIONS | HomotopyContinuation.FiniteException |
| Forced Lotka-Volterra | 4 | 6 | NO SOLUTIONS | HomotopyContinuation.FiniteException |
| Mass-Spring-Damper | 3 | 6 | NO SOLUTIONS | HomotopyContinuation.FiniteException |

## Detailed Results

### Simple Model (Baseline)
- **Status**: SUCCESS
- **Parameters**: 2 (a, b)
- **States**: 2 (x1, x2)
- **Recovery error**: ~0% for all parameters
- **Runtime**: ~30s

### Tier A: Polynomial Dynamics

#### DC Motor
- **States**: 4 (omega_m, i, u_sin, u_cos)
- **Parameters**: 6 (R, L, Kb, Kt, J, b)
- **Status**: STRUCTURALLY UNIDENTIFIABLE
- **Runtime**: ~100s
- **Unidentifiable params**: All 6 (R, L, Kb, Kt, J, b) plus state i
- **Identifiable combinations**:
  1. `(L*J)/Kt`
  2. `(R*b + Kb*Kt)/Kt`
  3. `(R*J + L*b)/Kt`
- **Interpretation**: The 6 individual parameters cannot be uniquely determined from observations. This is a fundamental structural limitation - the parameters are entangled.

#### Bilinear System
- **States**: 4 (x1, x2, u_sin, u_cos)
- **Parameters**: 2 (a, b)
- **Status**: NO SOLUTIONS
- **Runtime**: ~425s
- **Error**: HomotopyContinuation.FiniteException at all shooting points
- **Note**: Despite having only 2 parameters, solver fails

#### Forced Lotka-Volterra
- **States**: 6 (x, y, u_sin, u_cos, u_exp)
- **Parameters**: 4 (alpha, beta, gamma, delta)
- **Status**: NO SOLUTIONS
- **Runtime**: ~50s
- **Error**: HomotopyContinuation.FiniteException at all shooting points

#### Mass-Spring-Damper
- **States**: 6 (x, v, u_sin, u_cos, u_exp)
- **Parameters**: 3 (m, c, k)
- **Status**: NO SOLUTIONS
- **Runtime**: ~53s
- **Error**: HomotopyContinuation.FiniteException at all shooting points

### Remaining Systems (Not Yet Tested)

**Tier A (Polynomial)**:
- Quadrotor Altitude
- Thermal System
- Magnetic Levitation
- Aircraft Pitch
- Bicycle Model
- Boost Converter
- Flexible Arm

**Tier B (sqrt dynamics)**:
- Tank Level
- Two-Tank

## Key Insights

### 1. Structural Identifiability
Many control systems are **structurally unidentifiable** from typical observations. The framework correctly detects this and reports:
- Which parameters are individually unidentifiable
- What combinations of parameters ARE identifiable

### 2. HomotopyContinuation.FiniteException
Most polynomialized systems fail with `HomotopyContinuation.FiniteException` at all shooting points. This indicates:
- The polynomial system may have no finite solutions
- The system may be over/under-determined
- Numerical conditioning issues

### 3. Computational Complexity
The parameter estimation pipeline is computationally intensive for systems with:
- Many parameters (>4)
- High derivative orders (>5)
- Multiple observations

Single system analysis takes 50-425 seconds.

### 4. Known Issues
- **NaN at boundaries**: AAA interpolator returns NaN at domain boundaries (t=-0.5, t=0.5)
- **PosDefException**: AGP interpolator has numerical issues but continues
- **FiniteException**: HomotopyContinuation fails for most control systems

### 5. Framework Capabilities
The ODEParameterEstimation framework:
- Works correctly on simple identifiable systems
- Correctly identifies structural unidentifiability
- Reports identifiable parameter combinations
- Has solver issues with polynomialized control systems

## Recommendations

1. **For testing**: Multi-threading is now safe with Groebner v0.10.0. Use `julia --threads=auto` for best performance.

2. **For control systems**: Consider:
   - Reducing parameters by using known physical relationships
   - Adding more observations to improve identifiability
   - Fixing some parameters to known values
   - Investigating why HomotopyContinuation.FiniteException occurs

3. **For practical use**: Start with simpler models (2-4 parameters) to verify the pipeline works before scaling up

4. **Future work**:
   - Investigate FiniteException root cause
   - Add boundary handling for interpolators
   - Test with different polynomial system solvers

## Files
- Test script: `test/polynomialized_tests/run_poly_estimation.jl`
- Model definitions: `src/examples/models/polynomialized/tier_*.jl`
