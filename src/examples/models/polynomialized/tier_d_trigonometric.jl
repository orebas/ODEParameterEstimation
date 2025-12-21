#=============================================================================
Tier D: Polynomialized Control Systems - Trigonometric Functions of States

These systems have sin(theta), cos(theta) where theta is a STATE VARIABLE
(not just time). This requires careful polynomialization.

POLYNOMIALIZATION STRATEGY:
For angle state theta with angular velocity omega = D(theta):
  - Introduce s = sin(theta), c = cos(theta)
  - D(s) = cos(theta) * D(theta) = c * omega
  - D(c) = -sin(theta) * D(theta) = -s * omega

This gives polynomial ODEs in (s, c, omega).

ALGEBRAIC CONSTRAINT:
  s^2 + c^2 = 1  (unit circle constraint)

INITIAL CONDITIONS:
  s(0) = sin(theta(0))
  c(0) = cos(theta(0))

IMPORTANT: After polynomialization, we no longer track theta directly.
We have (s, c) which represent (sin(theta), cos(theta)).
To recover theta, use theta = atan2(s, c).

NOTES ON CART-POLE:
The cart-pole equations have sin(theta)^2 in the denominator:
  D(v) = ... / (M + m*sin(theta)^2)
After substitution with s = sin(theta), this becomes:
  D(v) = ... / (M + m*s^2)
This is RATIONAL in s (s^2 in denominator), but polynomial in numerator.
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#=============================================================================
                              1. SWING EQUATION
    Simplest case: only has sin(delta), no cos(delta)
=============================================================================#

"""
    swing_equation_poly()

Generator swing equation with polynomialized sin(delta).

Original system:
  D(delta) = Delta_omega
  D(Delta_omega) = (omega_s/(2H)) * (Pm(t) - Pmax*sin(delta) - D_damp*Delta_omega)
  Pm(t) = Pm0 + Pma*sin(omega*t)

Polynomialization for sin(delta):
  Let s = sin(delta), c = cos(delta)
  D(s) = c * D(delta) = c * Delta_omega
  D(c) = -s * D(delta) = -s * Delta_omega

The original D(Delta_omega) becomes:
  D(Delta_omega) = (omega_s/(2H)) * (Pm(t) - Pmax*s - D_damp*Delta_omega)

This is POLYNOMIAL in (s, c, Delta_omega).

Plant parameters (UNKNOWN): H, D_damp, Pmax, omega_s
Input parameters (FIXED): Pm0=0.8, Pma=0.1, omega=0.5

CONSTRAINT: s^2 + c^2 = 1
IC: s(0) = sin(delta(0)), c(0) = cos(delta(0))
"""
function swing_equation_poly()
    @parameters H D_damp Pmax omega_s

    # Input parameters - FIXED
    Pm0_val = 0.8    # mean mechanical power
    Pma_val = 0.1    # power oscillation amplitude
    omega_val = 0.5  # disturbance frequency

    # States: s = sin(delta), c = cos(delta), Delta_omega, plus input oscillator
    @variables s_delta(t) c_delta(t) Delta_omega(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        5.0,      # H: inertia constant
        1.0,      # D_damp: damping
        1.0,      # Pmax: max sync power
        377.0,    # omega_s: sync speed (60 Hz)
    ]

    # Original: delta(0) = 0.927 rad
    delta0 = 0.927
    ic_true = [sin(delta0), cos(delta0), 0.0, 0.0, 1.0]  # [s, c, Delta_omega, u_sin, u_cos]

    # Pm(t) = Pm0 + Pma*u_sin
    Pm = Pm0_val + Pma_val * u_sin

    equations = [
        # D(s) = c * omega (where omega = D(delta) = Delta_omega in this notation)
        # Note: Delta_omega here is the deviation from synchronous speed, which equals D(delta)
        D(s_delta) ~ c_delta * Delta_omega,
        # D(c) = -s * omega
        D(c_delta) ~ -s_delta * Delta_omega,
        # D(Delta_omega) = (omega_s/(2H)) * (Pm - Pmax*s - D_damp*Delta_omega)
        D(Delta_omega) ~ (omega_s / (2 * H)) * (Pm - Pmax * s_delta - D_damp * Delta_omega),
        # Input oscillator
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # Observe Delta_omega and input
    measured_quantities = [y1 ~ Delta_omega, y2 ~ u_sin, y3 ~ u_cos]

    states = [s_delta, c_delta, Delta_omega, u_sin, u_cos]
    parameters = [H, D_damp, Pmax, omega_s]

    model, mq = create_ordered_ode_system("swing_equation_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "swing_equation_poly",
        model,
        mq,
        nothing,
        [0.0, 20.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                              2. BALL-BEAM
    Has both sin(theta) and cos(theta)
=============================================================================#

"""
    ball_beam_poly()

Ball-beam system with polynomialized trig of beam angle.

Original system:
  D(r) = rdot
  D(rdot) = (5/7)*g*sin(theta) - r*omega_b^2
  D(theta) = omega_b
  D(omega_b) = (tau(t) - m_ball*g*r*cos(theta)) / J_beam
  tau(t) = tau_a*sin(omega*t)

Polynomialization for theta:
  Let s = sin(theta), c = cos(theta)
  D(s) = c * D(theta) = c * omega_b
  D(c) = -s * D(theta) = -s * omega_b

Substituting:
  D(r) = rdot
  D(rdot) = (5/7)*g*s - r*omega_b^2
  D(s) = c * omega_b
  D(c) = -s * omega_b
  D(omega_b) = (tau(t) - m_ball*g*r*c) / J_beam

This is POLYNOMIAL in (r, rdot, s, c, omega_b).

Plant parameters (UNKNOWN): m_ball, R_ball, J_beam, g
Input parameters (FIXED): tau_a=0.1, omega=2.0

CONSTRAINT: s^2 + c^2 = 1
IC: s(0) = sin(theta(0)), c(0) = cos(theta(0))
"""
function ball_beam_poly()
    @parameters m_ball R_ball J_beam g

    # Input parameters - FIXED
    tau_a_val = 0.1   # torque amplitude
    omega_val = 2.0   # frequency

    # States: r, rdot, s = sin(theta), c = cos(theta), omega_b, plus input
    @variables r(t) rdot(t) s_theta(t) c_theta(t) omega_b(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t)

    p_true = [
        0.1,     # m_ball
        0.02,    # R_ball
        0.5,     # J_beam
        9.81,    # g
    ]

    # Original: r(0) = 0.1, rdot(0) = 0, theta(0) = 0, omega_b(0) = 0
    theta0 = 0.0
    ic_true = [0.1, 0.0, sin(theta0), cos(theta0), 0.0, 0.0, 1.0]

    # tau(t) = tau_a * u_sin
    tau_input = tau_a_val * u_sin

    equations = [
        D(r) ~ rdot,
        D(rdot) ~ (5.0 / 7.0) * g * s_theta - r * omega_b^2,
        D(s_theta) ~ c_theta * omega_b,
        D(c_theta) ~ -s_theta * omega_b,
        D(omega_b) ~ (tau_input - m_ball * g * r * c_theta) / J_beam,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # Observe r and s_theta (or equivalently, r and theta via atan2)
    measured_quantities = [y1 ~ r, y2 ~ s_theta, y3 ~ u_sin, y4 ~ u_cos]

    states = [r, rdot, s_theta, c_theta, omega_b, u_sin, u_cos]
    parameters = [m_ball, R_ball, J_beam, g]

    model, mq = create_ordered_ode_system("ball_beam_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "ball_beam_poly",
        model,
        mq,
        nothing,
        [0.0, 10.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                              3. CART-POLE
    Most complex: has sin(theta), cos(theta), and sin(theta)^2 in denominator
=============================================================================#

"""
    cart_pole_poly()

Cart-pole with polynomialized trigonometric dynamics.

Original system:
  D(x) = v
  D(v) = (F(t) + m*s*(l*omega_p^2 + g*c)) / (M + m*s^2)
  D(theta) = omega_p
  D(omega_p) = (-F(t)*c - m*l*omega_p^2*c*s - (M+m)*g*s) / (l*(M + m*s^2))

where s = sin(theta), c = cos(theta), F(t) = Fa*sin(omega*t)

This system has sin(theta)^2 in the denominator, making it RATIONAL after
substitution (not purely polynomial).

Polynomialization:
  Let s = sin(theta), c = cos(theta)
  D(s) = c * omega_p
  D(c) = -s * omega_p

The cart and pole equations become:
  D(v) = (F + m*s*(l*omega_p^2 + g*c)) / (M + m*s^2)
  D(omega_p) = (-F*c - m*l*omega_p^2*c*s - (M+m)*g*s) / (l*(M + m*s^2))

Plant parameters (UNKNOWN): M, m, l, g
Input parameters (FIXED): Fa=2.0, omega=1.5

CONSTRAINTS:
  - s^2 + c^2 = 1
  - The denominator (M + m*s^2) must be positive (always true for physical params)

IC: s(0) = sin(theta(0)), c(0) = cos(theta(0))

NOTE: After polynomialization, theta is no longer a state. We track (s, c) instead.
The position x is still tracked and could be used to verify the cart position.
"""
function cart_pole_poly()
    @parameters M m l g

    # Input parameters - FIXED
    Fa_val = 2.0    # force amplitude
    omega_val = 1.5 # forcing frequency

    # States: x, v, s = sin(theta), c = cos(theta), omega_p, plus input
    @variables x(t) v(t) s_theta(t) c_theta(t) omega_p(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t)

    p_true = [
        1.0,    # M: cart mass
        0.1,    # m: pendulum mass
        0.5,    # l: pendulum length
        9.81,   # g: gravity
    ]

    # Original: x(0)=0, v(0)=0, theta(0)=0.1, omega_p(0)=0
    theta0 = 0.1
    ic_true = [0.0, 0.0, sin(theta0), cos(theta0), 0.0, 0.0, 1.0]

    # F(t) = Fa * u_sin
    F_input = Fa_val * u_sin

    # Denominator term (appears in both v and omega_p equations)
    denom = M + m * s_theta^2

    equations = [
        D(x) ~ v,
        # D(v) = (F + m*s*(l*omega_p^2 + g*c)) / (M + m*s^2)
        D(v) ~ (F_input + m * s_theta * (l * omega_p^2 + g * c_theta)) / denom,
        # D(s) = c * omega_p
        D(s_theta) ~ c_theta * omega_p,
        # D(c) = -s * omega_p
        D(c_theta) ~ -s_theta * omega_p,
        # D(omega_p) = (-F*c - m*l*omega_p^2*c*s - (M+m)*g*s) / (l*(M + m*s^2))
        D(omega_p) ~ (-F_input * c_theta - m * l * omega_p^2 * c_theta * s_theta - (M + m) * g * s_theta) / (l * denom),
        # Input oscillator
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # Observe x and s_theta (cart position and sin of pole angle)
    measured_quantities = [y1 ~ x, y2 ~ s_theta, y3 ~ u_sin, y4 ~ u_cos]

    states = [x, v, s_theta, c_theta, omega_p, u_sin, u_cos]
    parameters = [M, m, l, g]

    model, mq = create_ordered_ode_system("cart_pole_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "cart_pole_poly",
        model,
        mq,
        nothing,
        [0.0, 10.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                    NOTES ON TRIGONOMETRIC POLYNOMIALIZATION

1. STATE SPACE CHANGE:
   - Original: theta is a state
   - Polynomialized: (s, c) = (sin(theta), cos(theta)) are states
   - theta is no longer directly available; recover via theta = atan2(s, c)

2. CONSTRAINT s^2 + c^2 = 1:
   - This is an ALGEBRAIC constraint (DAE structure)
   - Current framework doesn't support explicit constraints
   - The constraint is automatically satisfied if:
     a) ICs are consistent: s(0)^2 + c(0)^2 = 1
     b) ODEs preserve the constraint (they do, by construction)
   - Numerical drift may cause small violations over long integrations

3. RATIONAL vs POLYNOMIAL:
   - Swing equation: purely polynomial
   - Ball-beam: purely polynomial
   - Cart-pole: RATIONAL (s^2 in denominator)

4. IDENTIFIABILITY IMPLICATIONS:
   - The constraint s^2 + c^2 = 1 reduces the effective state dimension
   - This affects identifiability analysis
   - Standard polynomial identifiability tools may need modification

5. OBSERVABILITY:
   - If we observe s (or equivalently theta), we know sin(theta)
   - cos(theta) can be inferred from constraint: c = sqrt(1 - s^2) (with sign ambiguity)
   - The sign ambiguity for c matters: c could be +sqrt(...) or -sqrt(...)
   - Observing both s and c, or observing s continuously, resolves this
=============================================================================#
