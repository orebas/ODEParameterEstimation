# Handling Transcendental Functions in Parameter Estimation

## Date: December 2024

## Problem Statement

ODEParameterEstimation.jl relies on polynomial/rational differential algebra:
- Symbolic differentiation to form polynomial systems
- Groebner bases for identifiability analysis
- Polynomial system solvers (HomotopyContinuation, etc.)

Many real systems have transcendental terms that don't fit this framework:
- **Arrhenius kinetics**: `exp(-E/(R*T))` in CSTR and chemical systems
- **Trigonometric**: `sin(θ), cos(θ)` in mechanical/robotics systems
- **Time-varying inputs**: `A*sin(ω*t)` in control systems
- **Logarithmic**: `log(x)` in various models

---

## Initial Analysis (Claude)

### The Core Tension
The framework relies on polynomial/rational differential algebra, but inputs like `sin(ωt)` and `exp(-t/τ)` are transcendental functions.

### Proposed Approach: Auxiliary Variable Polynomialization

Replace transcendental functions with ODEs that generate them:

1. **Sinusoid**: `sin(ωt)` is the solution to a harmonic oscillator
   ```
   ds/dt = ω·c
   dc/dt = -ω·s
   ```
   with `s(0)=0, c(0)=1` → then `s(t) = sin(ωt)`
   Plus algebraic constraint: `s² + c² = 1`

2. **Exponential**: `exp(-t/τ)` is the solution to
   ```
   de/dt = -e/τ
   ```
   with `e(0)=1`

3. **For exp(f(x))** (e.g., Arrhenius):
   ```
   z = exp(f(x))
   dz/dt = z · (df/dx) · (dx/dt)
   ```

4. **For log(x)**:
   ```
   z = log(x)
   x · dz/dt = dx/dt
   ```
   (This is rational, not purely polynomial)

### Related Framework Extensions Discussed

1. **Fixed vs Unknown Parameters**: Some parameters are known a priori (physical constants, measured quantities)
2. **Fixed vs Unknown Initial Conditions**: Some ICs are measured at t=0, others unknown
3. **Known Differentiable Input Functions**: User provides `u(t)` analytically, we compute/use derivatives

---

## Multi-Model Consensus Analysis

Consulted three models with different stances:
- **Gemini 2.5 Pro** (FOR stance) - 9/10 confidence
- **GPT-5** (NEUTRAL stance) - 8/10 confidence
- **O3** (AGAINST stance) - 8/10 confidence

### Universal Agreement (All Three Models)

1. **Mathematically Sound**: Auxiliary-variable polynomialization is the canonical, industry-standard approach

2. **Industry Adoption**: Used by major tools:
   - DAISY (Bellu et al.)
   - SIAN
   - GenSSI
   - STRIKE-GOLDD
   - StructuralIdentifiability.jl
   - Maple diffalg
   - Mathematica

3. **Functions That Can Be Polynomialized** ("Differentially Algebraic"):
   | Function | Auxiliary Equation | Notes |
   |----------|-------------------|-------|
   | `exp(f)` | `dz/dt = z · df/dt` | Pure ODE |
   | `sin(θ), cos(θ)` | `ds/dt = c·dθ/dt`, `dc/dt = -s·dθ/dt` | Plus constraint `s²+c²=1` |
   | `log(x)` | `x · dz/dt = dx/dt` | Rational (need x>0) |
   | `tan(θ)` | Similar pattern | Involves sec² |
   | `tanh(x)` | Similar pattern | |

4. **Functions That CANNOT Be Polynomialized** ("Differentially Transcendental"):
   - `exp(x²)` - no finite auxiliary set
   - `erf(x)` - error function
   - `Gamma(x)` - gamma function
   - `zeta(x)` - zeta function
   - Bessel functions (unless using higher-order auxiliary vars)
   - Piecewise / absolute value
   - Delays

### Practical Challenges Identified

1. **DAE Index**: Algebraic constraints like `s² + c² = 1` create index-1 DAEs
   - Most differential algebra tools handle index-1 fine
   - Need robust error messages for index issues

2. **Initial Conditions**: Auxiliary variable ICs must be consistent
   - If `z = exp(f(x))`, then `z(0) = exp(f(x(0)))`
   - If `θ(0)` is unknown, then `s(0), c(0)` become unknowns constrained to unit circle

3. **Scalability**: Each transcendental adds 1-2 states
   - Groebner basis complexity grows with variable count
   - Empirically manageable: <10 extra vars for large biological models

4. **Denominators**: Must clear denominators and saturate ideals
   - Avoids spurious solutions on singular sets (e.g., T=0 in Arrhenius)

### Key Insight from O3

If a transcendental term has **known parameters** (e.g., `A·sin(ωt)` with known A, ω), treat it as a **known external input** rather than polynomializing. This keeps the core system smaller and connects to the "fixed vs unknown parameters" extension.

### Alternative Approaches Mentioned

1. **Taylor Series Approximation**: Simpler but introduces approximation error, only valid locally
2. **Holonomic/D-finite Lifting**: Generalizes to Bessel, Airy functions
3. **Power Series (Pohjanpalo) Identifiability**: Fallback for unsupported functions
4. **Reparametrization**: Log-transform to absorb exponentials where possible

---

## Recommended Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User-Provided Model                       │
│  dx/dt = f(x, p) with transcendentals and inputs            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Classification / Preprocessing                  │
│  - Parameters: fixed vs unknown                             │
│  - ICs: fixed vs unknown                                    │
│  - Transcendentals: polynomialize OR treat as known input   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Augmented Polynomial DAE System                 │
│  - Original states + auxiliary states                       │
│  - Polynomial/rational differential equations               │
│  - Algebraic constraints (s² + c² = 1, etc.)               │
│  - Consistent initial conditions                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│           Existing Identifiability / Estimation              │
│  - Groebner basis / differential elimination                │
│  - Polynomial system solvers                                │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Options (To Be Decided)

Given user priority of "mathematical correctness over UX":

### Option 1: Minimal (Manual Polynomialization)
- User transforms the model themselves
- Framework handles the augmented polynomial DAE
- Lowest implementation effort

### Option 2: Moderate (Helper Functions)
- Provide helper functions that generate auxiliary equations for common cases
- User assembles them into the model
- Medium implementation effort

### Option 3: Full Automation
- Automatic AST transformation with whitelist of supported functions
- Domain/inequation tracking
- Highest implementation effort

---

## Data Structures Sketch

```julia
struct ExtendedPEP
    # ... existing fields ...

    # Parameter classification
    parameters_unknown::OrderedDict{Num, Any}  # Variables in polynomial system
    parameters_fixed::OrderedDict{Num, Float64}  # Substituted as numbers

    # IC classification
    ic_unknown::OrderedDict{Num, Any}
    ic_fixed::OrderedDict{Num, Float64}

    # Input functions (optional)
    inputs::Vector{InputFunction}  # Known functional forms

    # Auxiliary variables from polynomialization
    auxiliary_states::Vector{AuxiliaryState}
    algebraic_constraints::Vector{Num}  # e.g., s² + c² - 1 = 0
end

struct AuxiliaryState
    symbol::Num           # e.g., z
    original_expr::Num    # e.g., exp(-E/(R*T))
    derivative_eq::Num    # e.g., dz/dt = z * (E/(R*T²)) * dT/dt
    ic_expr::Num          # e.g., z(0) = exp(-E/(R*T(0)))
end
```

---

## References

- DAISY: Bellu et al., "DAISY: A new software tool to test global identifiability"
- SIAN: Hong et al., "SIAN: software for structural identifiability analysis"
- GenSSI: Ligon et al., "GenSSI 2.0"
- STRIKE-GOLDD: Villaverde et al., "Structural identifiability of dynamic systems biology models"
- Pohjanpalo: "System identifiability based on the power series expansion of the solution"

---

## Status

**PAUSED** - Design discussion complete, to be revisited for implementation decisions.
