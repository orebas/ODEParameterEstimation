#=============================================================================
Tier B: Polynomialized Control Systems - sqrt(state) Dynamics

These systems have sqrt(state) terms that need polynomialization.

POLYNOMIALIZATION STRATEGY:
For sqrt(h) terms:
  - Introduce z = sqrt(h), so h = z^2
  - From D(h) = f(h), derive D(z):
    D(h) = 2*z*D(z)  =>  D(z) = D(h) / (2*z) = f(z^2) / (2*z)
  - This gives RATIONAL dynamics in z (not purely polynomial)

ALGEBRAIC CONSTRAINT:
  z^2 = h (or equivalently z = sqrt(h))
  This constraint must hold for initial conditions.
  Framework currently doesn't support side constraints.

INITIAL CONDITIONS:
  z(0) = sqrt(h(0))  -- must be consistent with h IC

MEASURED QUANTITIES:
  If h is measured, and z = sqrt(h), then observing h gives us z indirectly.
  We observe z and note that h = z^2.
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#=============================================================================
                              1. TANK LEVEL
    Original: D(h) = (Qin - k_out*sqrt(h)) / A
    Polynomialized: introduce z = sqrt(h)
=============================================================================#

"""
    tank_level_poly()

Tank level with polynomialized sqrt dynamics.

Original system:
  D(h) = (Qin(t) - k_out*sqrt(h)) / A
  where Qin(t) = Q0 + Qa*sin(omega*t)

Polynomialization:
  Let z = sqrt(h), so h = z^2
  D(h) = 2*z*D(z)
  Therefore: 2*z*D(z) = (Qin - k_out*z) / A
  So: D(z) = (Qin - k_out*z) / (2*A*z)

This is RATIONAL in z (has z in denominator).

CONSTRAINT: z^2 = h (z > 0)
IC CONSTRAINT: z(0) = sqrt(h(0))

Plant parameters (UNKNOWN): A, k_out
Input parameters (FIXED): Q0=0.4, Qa=0.15, omega=0.5
"""
function tank_level_poly()
    @parameters A k_out

    # Input parameters - FIXED
    Q0_val = 0.4     # mean inlet flow
    Qa_val = 0.15    # flow oscillation amplitude
    omega_val = 0.5  # frequency

    # z = sqrt(h) is the transformed state
    @variables z(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        1.0,    # A: tank area
        0.3,    # k_out: outflow coefficient
    ]

    # Original h(0) = 1.0, so z(0) = sqrt(1.0) = 1.0
    ic_true = [1.0, 0.0, 1.0]  # [z, u_sin, u_cos]

    # Qin(t) = Q0 + Qa*u_sin
    Qin = Q0_val + Qa_val * u_sin

    # D(z) = (Qin - k_out*z) / (2*A*z)
    # Note: This is rational in z (z appears in denominator)
    equations = [
        D(z) ~ (Qin - k_out * z) / (2 * A * z),
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # We observe z (which represents sqrt(h))
    # NOTE: h = z^2 is the physical quantity
    measured_quantities = [y1 ~ z, y2 ~ u_sin, y3 ~ u_cos]

    states = [z, u_sin, u_cos]
    parameters = [A, k_out]

    model, mq = create_ordered_ode_system("tank_level_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "tank_level_poly",
        model,
        mq,
        nothing,
        [0.0, 30.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                              2. TWO-TANK
    Original has: sqrt(h1), sqrt(h2), sqrt(h1 - h2 + eps)
    This is much more complex due to the sqrt of a difference
=============================================================================#

"""
    two_tank_poly()

Two-tank system with polynomialized sqrt dynamics.

Original system:
  D(h1) = (Qin - k1*sqrt(h1) - k12*sqrt(h1 - h2 + eps)) / A1
  D(h2) = (k12*sqrt(h1 - h2 + eps) - k2*sqrt(h2)) / A2
  where eps = 0.01 (small constant to prevent sqrt of negative)

Polynomialization:
  Let z1 = sqrt(h1), z2 = sqrt(h2), z12 = sqrt(h1 - h2 + eps)
  So h1 = z1^2, h2 = z2^2

CHALLENGES:
  1. z12 depends on both h1 and h2: z12 = sqrt(z1^2 - z2^2 + eps)
  2. This creates a non-polynomial constraint: z12^2 = z1^2 - z2^2 + eps

APPROACH:
  - Treat z1, z2, z12 as separate states
  - Add ODEs for each
  - Document the algebraic constraint z12^2 = z1^2 - z2^2 + eps

For z1 = sqrt(h1):
  D(z1) = D(h1) / (2*z1) = (Qin - k1*z1 - k12*z12) / (2*A1*z1)

For z2 = sqrt(h2):
  D(z2) = D(h2) / (2*z2) = (k12*z12 - k2*z2) / (2*A2*z2)

For z12 = sqrt(h1 - h2 + eps):
  D(z12) = (D(h1) - D(h2)) / (2*z12)
  = [(Qin - k1*z1 - k12*z12)/A1 - (k12*z12 - k2*z2)/A2] / (2*z12)

Plant parameters (UNKNOWN): A1, A2, k1, k2, k12
Input parameters (FIXED): Q0=0.5, Qa=0.2, omega=0.3

CONSTRAINTS (not currently supported by framework):
  - z1^2 = h1 (z1 > 0)
  - z2^2 = h2 (z2 > 0)
  - z12^2 = z1^2 - z2^2 + eps (z12 > 0)
"""
function two_tank_poly()
    @parameters A1 A2 k1 k2 k12

    # Input parameters - FIXED
    Q0_val = 0.5     # mean flow
    Qa_val = 0.2     # oscillation
    omega_val = 0.3  # frequency
    eps_val = 0.01   # small constant for sqrt safety

    # Transformed states: z1 = sqrt(h1), z2 = sqrt(h2), z12 = sqrt(h1-h2+eps)
    @variables z1(t) z2(t) z12(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t)

    p_true = [
        1.0,     # A1
        1.0,     # A2
        0.3,     # k1
        0.3,     # k2
        0.2,     # k12
    ]

    # Original: h1(0) = 1.0, h2(0) = 0.5
    # So: z1(0) = 1.0, z2(0) = sqrt(0.5) ≈ 0.707
    # z12(0) = sqrt(1.0 - 0.5 + 0.01) = sqrt(0.51) ≈ 0.714
    ic_true = [1.0, sqrt(0.5), sqrt(0.51), 0.0, 1.0]

    # Qin = Q0 + Qa*u_sin
    Qin = Q0_val + Qa_val * u_sin

    # D(h1) = (Qin - k1*z1 - k12*z12) / A1
    Dh1 = (Qin - k1 * z1 - k12 * z12) / A1
    # D(h2) = (k12*z12 - k2*z2) / A2
    Dh2 = (k12 * z12 - k2 * z2) / A2

    equations = [
        # D(z1) = D(h1) / (2*z1)
        D(z1) ~ Dh1 / (2 * z1),
        # D(z2) = D(h2) / (2*z2)
        D(z2) ~ Dh2 / (2 * z2),
        # D(z12) = (D(h1) - D(h2)) / (2*z12)
        D(z12) ~ (Dh1 - Dh2) / (2 * z12),
        # Input oscillator
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # NOTE: We observe z1 and z2. Physical h1 = z1^2, h2 = z2^2
    measured_quantities = [y1 ~ z1, y2 ~ z2, y3 ~ u_sin, y4 ~ u_cos]

    states = [z1, z2, z12, u_sin, u_cos]
    parameters = [A1, A2, k1, k2, k12]

    model, mq = create_ordered_ode_system("two_tank_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "two_tank_poly",
        model,
        mq,
        nothing,
        [0.0, 50.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                    NOTES ON RATIONAL vs POLYNOMIAL

Both systems above are RATIONAL in the transformed variables (z appears in
denominators). This is acceptable for many polynomial system solvers that
actually handle rational functions, but it's worth noting.

The algebraic constraints are:
- Tank Level: z^2 = h (single constraint)
- Two-Tank: z1^2 = h1, z2^2 = h2, z12^2 = z1^2 - z2^2 + eps (three constraints)

These constraints are important for:
1. Setting consistent initial conditions
2. Verifying solutions make physical sense (z > 0)
3. Potentially adding to identifiability analysis
=============================================================================#
