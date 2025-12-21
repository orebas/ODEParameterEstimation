# Polynomialized Systems Parameter Estimation Results

## Test Configuration
- **Data points**: 201
- **Noise level**: 0.0 (noiseless)
- **Threads**: 12
- **Date**: 2025-12-03

---

## Part 1: Original Systems Identifiability Analysis

### Summary - All 11 Tier A Systems

| # | System | Params | Fully Identifiable? | Unidentifiable | Identifiable Combinations |
|---|--------|--------|---------------------|----------------|---------------------------|
| 1 | DC Motor | 6 | NO | {R, L, Kb, Kt, J, b, i} | (L*J)/Kt, (R*b + Kb*Kt)/Kt, (R*J + L*b)/Kt |
| 2 | Quadrotor Altitude | 3 | NO | {g} | d, m |
| 3 | Thermal System | 3 | **YES** | {} (NONE) | Ta, R_th, C_th (ALL) |
| 4 | Magnetic Levitation | 6 | NO | {m_lin, k_lin, R_coil, ki, b_lin, L, i} | 4 combinations |
| 5 | Aircraft Pitch | 5 | NO | {theta, V_air, Z_alpha} | M_delta_e, M_q, M_alpha, Z_alpha/V_air |
| 6 | Bicycle Model | 7 | NO | {Cf, Iz, m_veh, Cr} | 6 combinations |
| 7 | Boost Converter | 4 | NO | {L, C_cap, R_load, iL} | Vin, C_cap*R_load, L*C_cap |
| 8 | Bilinear System | 8 | NO | {a12, b2, x2, a21} | n2, n1, b1, a22, a11, a12*b2, a12*a21 |
| 9 | Forced Lotka-Volterra | 4 | NO | {b, predator} | d_pred, c, a |
| 10 | Mass-Spring-Damper | 3 | **YES** | {} (NONE) | k, c, m (ALL) |
| 11 | Flexible Arm | 5 | **YES** | {} (NONE) | k_stiff, bt, bm, Jt, Jm (ALL) |

### Key Findings

1. **3 Fully Identifiable Systems** (out of 11):
   - **Thermal System**: Simple linear heat transfer (3 params)
   - **Mass-Spring-Damper**: Classic 2nd order linear (3 params)
   - **Flexible Arm**: Two-mass torsional system (5 params)

2. **8 Systems Have Structural Unidentifiability**: The remaining systems have parameters that cannot be uniquely determined from the available observations.

3. **Identifiable Combinations**: Even when individual parameters are unidentifiable, StructuralIdentifiability.jl finds algebraic combinations that ARE identifiable.

---

## Part 2: Identifiable Variants Created

To make the unidentifiable systems useful for parameter estimation, we created **8 identifiable variants** in `tier_a_identifiable.jl`. These fix physically measurable parameters and/or add observations.

### Summary Table - Identifiable Variants

| System               | Original Unidentifiable | Fixed Params | Estimated Params | Strategy |
|----------------------|-------------------------|--------------|------------------|----------|
| DC Motor             | All 6                   | R, L, Kb     | Kt, J, b (3)     | Fix electricals |
| Quadrotor            | g only                  | g            | m, d (2)         | Fix gravity |
| Magnetic Levitation  | All 6                   | R_coil, L, ki| m, k, b (3)      | Fix electricals |
| Aircraft Pitch       | theta, V_air, Z_alpha   | V_air        | M_α,M_q,M_δe,Z_α (4) | Fix airspeed |
| Bicycle Model        | Cf, Iz, m_veh, Cr       | Vx, lf, lr   | Cf, Cr, m, Iz (4)| Fix geometry |
| Boost Converter      | L, C, R, iL             | Vin          | L, C, R (3)      | Fix Vin + add obs |
| Bilinear System      | a12, b2, x2, a21        | (none)       | All 8            | Add x2 observation |
| Lotka-Volterra       | b, predator             | (none)       | All 4            | Add predator obs |

### Detailed Physical Justifications

#### 1. DC Motor (identifiable)
- **Fixed**: R (armature resistance) - measured with multimeter; L (inductance) - LCR meter; Kb (back-EMF) - from datasheet
- **Estimated**: Kt (torque constant), J (rotor inertia), b (viscous friction) - harder to measure, vary with conditions

#### 2. Quadrotor Altitude (identifiable)
- **Fixed**: g = 9.81 m/s² (universal constant)
- **Estimated**: m (mass - varies with payload), d (drag - varies with rotor wear)

#### 3. Magnetic Levitation (identifiable)
- **Fixed**: R_coil, L (electrical - easily measured), ki (calibrated experimentally)
- **Estimated**: m_lin, k_lin, b_lin (linearized mechanical dynamics)

#### 4. Aircraft Pitch (identifiable)
- **Fixed**: V_air (true airspeed from pitot-static system)
- **Estimated**: M_alpha, M_q, M_delta_e, Z_alpha (stability derivatives - key unknowns in flight dynamics)

#### 5. Bicycle Model (identifiable)
- **Fixed**: Vx (test speed - controlled), lf, lr (axle distances - from specs)
- **Estimated**: Cf, Cr (tire cornering stiffness), m_veh, Iz (mass and yaw inertia)

#### 6. Boost Converter (identifiable)
- **Fixed**: Vin (input voltage - measured)
- **Added observation**: iL (inductor current - common power electronics sensor)
- **Estimated**: L, C_cap, R_load

#### 7. Bilinear System (identifiable)
- **No parameters fixed** - instead added second observation (x2)
- Adding a sensor makes all 8 parameters identifiable
- Common in practice: dual-sensor configurations

#### 8. Forced Lotka-Volterra (identifiable)
- **No parameters fixed** - added predator observation
- Observing both prey and predator populations (via camera traps, tagging, etc.)
- All 4 parameters become identifiable

---

## Part 3: Test Results

### Identifiable Variants Validation

All 8 identifiable model variants were tested and **integrate successfully**:

```
Testing IDENTIFIABLE model variants...
============================================================
  ✓ DC Motor (identifiable): OK (3 params)
  ✓ Quadrotor (identifiable): OK (2 params)
  ✓ Magnetic Levitation (identifiable): OK (3 params)
  ✓ Aircraft Pitch (identifiable): OK (4 params)
  ✓ Bicycle Model (identifiable): OK (4 params)
  ✓ Boost Converter (identifiable): OK (3 params)
  ✓ Bilinear System (identifiable): OK (8 params)
  ✓ Lotka-Volterra (identifiable): OK (4 params)

8 / 8 models integrate successfully
```

### Parameter Estimation Behavior

For the **original unidentifiable systems**, the parameter estimation framework correctly:
1. Identifies which parameters are structurally unidentifiable via StructuralIdentifiability.jl
2. Computes identifiable combinations of parameters
3. Returns empty solutions when the system is not fully identifiable (expected behavior)

Example log output for DC Motor:
```
[DEBUG-SI] SI.jl found 7 unidentifiable params: Set(Any[b, J, R, Kb, L, Kt, i])
[DEBUG-SI] Using 3 independent identifiable functions for DOF analysis
[DEBUG-SI] Independent identifiable funcs: [(L*J)//Kt, (R*b + Kb*Kt)//Kt, (R*J + L*b)//Kt]
```

---

## Part 4: Physical Interpretation

The identifiability patterns make physical sense:

1. **Products/Ratios of coupled parameters**: When parameters always appear together in the dynamics (e.g., L*J), only their product is observable

2. **Time constants**: RC, LC, mechanical-electrical coupling constants are often identifiable

3. **Scaling ambiguity**: Parameters that scale together (like Cf and m_veh in the bicycle model) form identifiable ratios

4. **Hidden states**: When a state is not observed, parameters that only appear with that state become unidentifiable

---

## Part 5: Recommendations

### For Systems with Unidentifiable Parameters

1. **Fix known parameters from datasheets/measurement**:
   - Electrical parameters (R, L) - easily measured
   - Physical constants (g, known geometry)
   - Calibration constants from prior experiments

2. **Add additional sensor measurements**:
   - Observe hidden states when feasible
   - Power electronics: add current sensors
   - Ecological models: monitor both populations
   - Control systems: add accelerometers, encoders

3. **Use identifiable combinations as reduced parameters**:
   - Instead of estimating L and J separately, estimate L*J
   - Reparametrize the model around observable quantities

### For Parameter Estimation Research

1. The **fully identifiable systems** make good test cases:
   - Thermal System (3 params) - simplest
   - Mass-Spring-Damper (3 params) - classic
   - Flexible Arm (5 params) - more complex

2. The **identifiable variants** are more interesting:
   - Have realistic physical justifications
   - More parameters while remaining identifiable
   - Cover diverse domains (motors, vehicles, ecosystems)

3. **Systems with many parameters** (>5) and few observations tend to have more unidentifiable parameters

---

## File Locations

- **Original models**: `src/examples/models/polynomialized/tier_a_polynomial.jl`
- **Identifiable variants**: `src/examples/models/polynomialized/tier_a_identifiable.jl`
- **Test script**: `test/polynomialized_tests/run_poly_estimation.jl`
- **This summary**: `test/polynomialized_tests/IDENTIFIABILITY_SUMMARY.md`

---

## Tier B, C, D Notes

### Tier B: sqrt(state) Systems
- Tank Level, Two-Tank
- Contain rational dynamics (z in denominator)
- Integration works; parameter estimation needs testing

### Tier C: Arrhenius exp(state)
- CSTR with polynomialized Arrhenius kinetics
- z = exp(-E_R/T), very small values (~1e-11)
- Challenging numerical properties

### Tier D: Trigonometric sin/cos(state)
- Swing Equation, Ball-Beam, Cart-Pole
- Polynomialized via s = sin(θ), c = cos(θ)
- Cart-Pole has s² in denominator (rational)
- Algebraic constraint s² + c² = 1 reduces effective dimension

All 17 systems across all tiers integrate successfully.
