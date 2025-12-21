#=============================================================================
Tier A: Polynomialized Control Systems - Polynomial Dynamics

These systems have polynomial/rational dynamics after input polynomialization.
The time-varying inputs are converted to autonomous ODE form:

For sin(omega*t) inputs:
  - u_sin, u_cos auxiliary states
  - D(u_sin) = omega * u_cos
  - D(u_cos) = -omega * u_sin
  - ICs: u_sin(0) = 0, u_cos(0) = 1
  - Both are MEASURED (observable)

For exp(-t/tau) ramp inputs:
  - u_exp auxiliary state
  - D(u_exp) = -u_exp / tau
  - IC: u_exp(0) = 1
  - u_exp is MEASURED (observable)

KEY DESIGN DECISIONS:
- Input parameters (omega, amplitudes, offsets) are FIXED (hardcoded as known values)
- Plant parameters are UNKNOWN (to be estimated)
- Auxiliary state ICs are FIXED (known from input definition)
- Plant state ICs may be unknown (problem-dependent)

FRAMEWORK LIMITATIONS:
- Currently no distinction between fixed/unknown parameters
- Currently no distinction between fixed/unknown ICs
- For now: include all as parameters, document which should be fixed
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#=============================================================================
                              1. DC MOTOR
    Linear dynamics, sinusoidal voltage input
=============================================================================#

"""
    dc_motor_poly()

DC motor with polynomialized sinusoidal voltage input.
Original: V(t) = V0 + Va*sin(omega*t)
Polynomialized: V(t) = V0 + Va*u_sin, where u_sin satisfies harmonic oscillator ODE.

Plant parameters (UNKNOWN): R, L, Kb, Kt, J, b
Input parameters (FIXED): V0=12.0, Va=2.0, omega=5.0
"""
function dc_motor_poly()
    # Plant parameters - TO BE ESTIMATED
    @parameters R L Kb Kt J b

    # Input parameters - FIXED (known values hardcoded)
    V0_val = 12.0   # DC voltage offset
    Va_val = 2.0    # AC voltage amplitude
    omega_val = 5.0 # Input frequency (rad/s)

    # Plant states
    @variables omega_m(t) i(t)
    # Auxiliary states for input (sin/cos oscillator)
    @variables u_sin(t) u_cos(t)

    # Observables (using y1, y2, y3 naming for SIAN compatibility)
    @variables y1(t) y2(t) y3(t)

    # True plant parameter values (for testing)
    p_true = [
        2.0,    # R: armature resistance (Ohms)
        0.5,    # L: armature inductance (H)
        0.1,    # Kb: back-EMF constant
        0.1,    # Kt: torque constant
        0.01,   # J: rotor inertia
        0.1,    # b: viscous friction
    ]

    # Initial conditions
    # Plant ICs - could be unknown in practice
    # Auxiliary ICs - FIXED by input definition: sin(0)=0, cos(0)=1
    ic_true = [0.0, 0.0, 0.0, 1.0]  # [omega_m, i, u_sin, u_cos]

    # Input signal: V(t) = V0 + Va * u_sin
    V_input = V0_val + Va_val * u_sin

    equations = [
        # Plant dynamics (polynomial/linear in states)
        D(omega_m) ~ (Kt * i - b * omega_m) / J,
        D(i) ~ (V_input - R * i - Kb * omega_m) / L,
        # Input oscillator (autonomous ODE for sin/cos)
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # Measured quantities: plant output + input signal (known/observable)
    measured_quantities = [
        y1 ~ omega_m,
        y2 ~ u_sin,
        y3 ~ u_cos,
    ]

    states = [omega_m, i, u_sin, u_cos]
    parameters = [R, L, Kb, Kt, J, b]

    model, mq = create_ordered_ode_system("dc_motor_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "dc_motor_poly",
        model,
        mq,
        nothing,
        [0.0, 5.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                           2. QUADROTOR ALTITUDE
    Linear dynamics, sinusoidal thrust input
=============================================================================#

"""
    quadrotor_altitude_poly()

Quadrotor altitude with polynomialized thrust oscillation.
Original: T(t) = m*g + Ta*sin(omega*t)
Polynomialized: T(t) = m*g + Ta*u_sin

Plant parameters (UNKNOWN): m, g, d
Input parameters (FIXED): Ta=2.0, omega=1.0
"""
function quadrotor_altitude_poly()
    @parameters m g d

    # Input parameters - FIXED
    Ta_val = 2.0    # thrust oscillation amplitude
    omega_val = 1.0 # frequency

    @variables z(t) w(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        1.0,     # m: mass
        9.81,    # g: gravity
        0.1,     # d: drag
    ]

    ic_true = [5.0, 0.0, 0.0, 1.0]  # [z, w, u_sin, u_cos]

    # Thrust: T = m*g + Ta*u_sin (hover + oscillation)
    # Net force = T - m*g - d*w = Ta*u_sin - d*w
    equations = [
        D(z) ~ w,
        D(w) ~ (Ta_val * u_sin - d * w) / m,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ z, y2 ~ u_sin, y3 ~ u_cos]

    states = [z, w, u_sin, u_cos]
    parameters = [m, g, d]

    model, mq = create_ordered_ode_system("quadrotor_altitude_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "quadrotor_altitude_poly",
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
                           3. THERMAL SYSTEM
    Linear dynamics, sinusoidal heating input
=============================================================================#

"""
    thermal_system_poly()

Room temperature with polynomialized day/night heating cycle.
Original: Q(t) = Q0*(1 + Qa_rel*sin(omega*t))
Polynomialized: Q(t) = Q0 + Q0*Qa_rel*u_sin

Plant parameters (UNKNOWN): C_th, R_th, Ta
Input parameters (FIXED): Q0=500.0, Qa_rel=0.5, omega=0.001
"""
function thermal_system_poly()
    @parameters C_th R_th Ta

    # Input parameters - FIXED
    Q0_val = 500.0     # mean heater power
    Qa_rel_val = 0.5   # 50% modulation
    omega_val = 0.001  # slow cycle

    @variables T(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        1000.0,   # C_th: thermal capacitance
        0.01,     # R_th: thermal resistance
        293.0,    # Ta: ambient (20C)
    ]

    ic_true = [288.0, 0.0, 1.0]  # [T, u_sin, u_cos]

    # Q(t) = Q0*(1 + Qa_rel*u_sin) = Q0 + Q0*Qa_rel*u_sin
    Q_input = Q0_val + Q0_val * Qa_rel_val * u_sin

    equations = [
        D(T) ~ (Q_input - (T - Ta) / R_th) / C_th,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ T, y2 ~ u_sin, y3 ~ u_cos]

    states = [T, u_sin, u_cos]
    parameters = [C_th, R_th, Ta]

    model, mq = create_ordered_ode_system("thermal_system_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "thermal_system_poly",
        model,
        mq,
        nothing,
        [0.0, 5000.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                        4. MAGNETIC LEVITATION (LINEARIZED)
    Linear dynamics, sinusoidal voltage input
=============================================================================#

"""
    magnetic_levitation_poly()

Linearized maglev with polynomialized AC voltage ripple.
Original: V(t) = V0 + Va*sin(omega*t)
Polynomialized: V(t) = V0 + Va*u_sin

Plant parameters (UNKNOWN): m_lin, k_lin, b_lin, R_coil, L, ki
Input parameters (FIXED): V0=5.0, Va=1.0, omega=5.0
"""
function magnetic_levitation_poly()
    @parameters m_lin k_lin b_lin R_coil L ki

    # Input parameters - FIXED
    V0_val = 5.0    # DC voltage
    Va_val = 1.0    # AC amplitude
    omega_val = 5.0 # frequency

    @variables x(t) v(t) i(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        0.1,    # m_lin: effective mass
        50.0,   # k_lin: linearized stiffness
        2.0,    # b_lin: damping
        2.0,    # R_coil: coil resistance
        0.05,   # L: inductance
        10.0,   # ki: current-to-force gain
    ]

    # i_eq = V0/R = 2.5A at equilibrium
    i_eq = V0_val / p_true[4]
    ic_true = [0.0, 0.0, i_eq, 0.0, 1.0]  # [x, v, i, u_sin, u_cos]

    # V(t) = V0 + Va*u_sin
    V_input = V0_val + Va_val * u_sin

    equations = [
        D(x) ~ v,
        D(v) ~ (ki * (i - V0_val / R_coil) - k_lin * x - b_lin * v) / m_lin,
        D(i) ~ (V_input - R_coil * i) / L,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ x, y2 ~ u_sin, y3 ~ u_cos]

    states = [x, v, i, u_sin, u_cos]
    parameters = [m_lin, k_lin, b_lin, R_coil, L, ki]

    model, mq = create_ordered_ode_system("magnetic_levitation_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "magnetic_levitation_poly",
        model,
        mq,
        nothing,
        [0.0, 5.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                           5. AIRCRAFT PITCH
    Linear dynamics, sinusoidal elevator input
=============================================================================#

"""
    aircraft_pitch_poly()

Aircraft pitch with polynomialized elevator input.
Original: delta_e(t) = delta_e0 + delta_ea*sin(omega*t)
Polynomialized: delta_e(t) = delta_e0 + delta_ea*u_sin

Plant parameters (UNKNOWN): M_alpha, M_q, M_delta_e, Z_alpha, V_air
Input parameters (FIXED): delta_e0=0.0, delta_ea=0.05, omega=2.0
"""
function aircraft_pitch_poly()
    @parameters M_alpha M_q M_delta_e Z_alpha V_air

    # Input parameters - FIXED
    delta_e0_val = 0.0   # trim
    delta_ea_val = 0.05  # elevator amplitude
    omega_val = 2.0      # frequency

    @variables theta(t) q(t) alpha(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        -5.0,     # M_alpha
        -2.0,     # M_q
        -10.0,    # M_delta_e
        -0.5,     # Z_alpha
        50.0,     # V_air
    ]

    ic_true = [0.0, 0.0, 0.05, 0.0, 1.0]  # [theta, q, alpha, u_sin, u_cos]

    # delta_e(t) = delta_e0 + delta_ea*u_sin
    delta_e_input = delta_e0_val + delta_ea_val * u_sin

    equations = [
        D(theta) ~ q,
        D(q) ~ M_alpha * alpha + M_q * q + M_delta_e * delta_e_input,
        D(alpha) ~ Z_alpha * alpha / V_air + q,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ q, y2 ~ u_sin, y3 ~ u_cos]

    states = [theta, q, alpha, u_sin, u_cos]
    parameters = [M_alpha, M_q, M_delta_e, Z_alpha, V_air]

    model, mq = create_ordered_ode_system("aircraft_pitch_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "aircraft_pitch_poly",
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
                           6. BICYCLE MODEL
    Linear dynamics, sinusoidal steering input
=============================================================================#

"""
    bicycle_model_poly()

Vehicle lateral dynamics with polynomialized sinusoidal steering.
Original: delta(t) = delta_a*sin(omega*t)
Polynomialized: delta(t) = delta_a*u_sin

Plant parameters (UNKNOWN): Cf, Cr, m_veh, Iz, lf, lr, Vx
Input parameters (FIXED): delta_a=0.05, omega=0.5
"""
function bicycle_model_poly()
    @parameters Cf Cr m_veh Iz lf lr Vx

    # Input parameters - FIXED
    delta_a_val = 0.05  # steering amplitude
    omega_val = 0.5     # frequency

    @variables vy(t) r(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t)

    p_true = [
        80000.0,   # Cf
        80000.0,   # Cr
        1500.0,    # m_veh
        2500.0,    # Iz
        1.2,       # lf
        1.4,       # lr
        20.0,      # Vx
    ]

    ic_true = [0.0, 0.0, 0.0, 1.0]  # [vy, r, u_sin, u_cos]

    # delta(t) = delta_a*u_sin
    delta_input = delta_a_val * u_sin

    equations = [
        D(vy) ~ (Cf * (delta_input - (vy + lf * r) / Vx) + Cr * (-(vy - lr * r) / Vx)) / m_veh - Vx * r,
        D(r) ~ (lf * Cf * (delta_input - (vy + lf * r) / Vx) - lr * Cr * (-(vy - lr * r) / Vx)) / Iz,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ r, y2 ~ vy, y3 ~ u_sin, y4 ~ u_cos]

    states = [vy, r, u_sin, u_cos]
    parameters = [Cf, Cr, m_veh, Iz, lf, lr, Vx]

    model, mq = create_ordered_ode_system("bicycle_model_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "bicycle_model_poly",
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
                           7. BOOST CONVERTER
    Polynomial dynamics (bilinear), sinusoidal duty cycle input
=============================================================================#

"""
    boost_converter_poly()

Boost converter with polynomialized duty cycle modulation.
Original: d(t) = d0 + da*sin(omega*t)
Polynomialized: d(t) = d0 + da*u_sin

Note: d' = 1 - d appears as coefficient, so (1-d)*state is polynomial in (state, u_sin).

Plant parameters (UNKNOWN): L, C_cap, R_load, Vin
Input parameters (FIXED): d0=0.5, da=0.1, omega=100.0
"""
function boost_converter_poly()
    @parameters L C_cap R_load Vin

    # Input parameters - FIXED
    d0_val = 0.5      # mean duty
    da_val = 0.1      # modulation amplitude
    omega_val = 100.0 # frequency

    @variables iL(t) vC(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        0.001,   # L
        0.001,   # C_cap
        10.0,    # R_load
        12.0,    # Vin
    ]

    ic_true = [1.0, 24.0, 0.0, 1.0]  # [iL, vC, u_sin, u_cos]

    # d(t) = d0 + da*u_sin, d' = 1 - d = (1 - d0) - da*u_sin
    d_complement = (1.0 - d0_val) - da_val * u_sin

    equations = [
        D(iL) ~ (Vin - d_complement * vC) / L,
        D(vC) ~ (d_complement * iL - vC / R_load) / C_cap,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ vC, y2 ~ u_sin, y3 ~ u_cos]

    states = [iL, vC, u_sin, u_cos]
    parameters = [L, C_cap, R_load, Vin]

    model, mq = create_ordered_ode_system("boost_converter_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "boost_converter_poly",
        model,
        mq,
        nothing,
        [0.0, 0.5],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                           8. BILINEAR SYSTEM
    Polynomial dynamics (bilinear), sinusoidal input
=============================================================================#

"""
    bilinear_system_poly()

Generic bilinear system with polynomialized sinusoidal input.
Original: u(t) = u0 + ua*sin(omega*t)
Polynomialized: u(t) = u0 + ua*u_sin

Bilinear term n1*x1*u becomes polynomial in (x1, u_sin).

Plant parameters (UNKNOWN): a11, a12, a21, a22, b1, b2, n1, n2
Input parameters (FIXED): u0=1.0, ua=0.5, omega=2.0
"""
function bilinear_system_poly()
    @parameters a11 a12 a21 a22 b1 b2 n1 n2

    # Input parameters - FIXED
    u0_val = 1.0    # mean input
    ua_val = 0.5    # oscillation
    omega_val = 2.0 # frequency

    @variables x1(t) x2(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        -0.5,    # a11
        0.2,     # a12
        0.1,     # a21
        -0.3,    # a22
        1.0,     # b1
        0.5,     # b2
        0.2,     # n1
        0.1,     # n2
    ]

    ic_true = [1.0, 0.5, 0.0, 1.0]  # [x1, x2, u_sin, u_cos]

    # u(t) = u0 + ua*u_sin
    u_input = u0_val + ua_val * u_sin

    equations = [
        D(x1) ~ a11 * x1 + a12 * x2 + b1 * u_input + n1 * x1 * u_input,
        D(x2) ~ a21 * x1 + a22 * x2 + b2 * u_input + n2 * x2 * u_input,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ x1, y2 ~ u_sin, y3 ~ u_cos]

    states = [x1, x2, u_sin, u_cos]
    parameters = [a11, a12, a21, a22, b1, b2, n1, n2]

    model, mq = create_ordered_ode_system("bilinear_system_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "bilinear_system_poly",
        model,
        mq,
        nothing,
        [0.0, 15.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                        9. FORCED LOTKA-VOLTERRA
    Polynomial dynamics, sinusoidal harvesting/stocking input
=============================================================================#

"""
    forced_lotka_volterra_poly()

Lotka-Volterra with polynomialized seasonal harvesting.
Original: u(t) = u0*(1 + ua_rel*sin(omega*t))
Polynomialized: u(t) = u0 + u0*ua_rel*u_sin

Plant parameters (UNKNOWN): a, b, c, d_pred
Input parameters (FIXED): u0=0.2, ua_rel=0.5, omega=0.5
"""
function forced_lotka_volterra_poly()
    @parameters a b c d_pred

    # Input parameters - FIXED
    u0_val = 0.2      # mean stocking
    ua_rel_val = 0.5  # 50% seasonal variation
    omega_val = 0.5   # seasonal frequency

    @variables prey(t) predator(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        1.0,     # a: prey growth
        0.5,     # b: predation
        0.5,     # c: predator death
        0.25,    # d_pred: predator efficiency
    ]

    ic_true = [2.0, 1.0, 0.0, 1.0]  # [prey, predator, u_sin, u_cos]

    # u(t) = u0*(1 + ua_rel*u_sin) = u0 + u0*ua_rel*u_sin
    u_input = u0_val + u0_val * ua_rel_val * u_sin

    equations = [
        D(prey) ~ a * prey - b * prey * predator + u_input,
        D(predator) ~ -c * predator + d_pred * prey * predator,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ prey, y2 ~ u_sin, y3 ~ u_cos]

    states = [prey, predator, u_sin, u_cos]
    parameters = [a, b, c, d_pred]

    model, mq = create_ordered_ode_system("forced_lotka_volterra_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "forced_lotka_volterra_poly",
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
                        10. MASS-SPRING-DAMPER
    Linear dynamics, ramp + sinusoidal force input
    Input: F(t) = F0*(1 - exp(-t/tau_r)) + Fa*sin(omega*t)
=============================================================================#

"""
    mass_spring_damper_poly()

Mass-spring-damper with polynomialized ramp + sinusoidal force.
Original: F(t) = F0*(1 - exp(-t/tau_r)) + Fa*sin(omega*t)
Polynomialized:
  - u_exp for exp(-t/tau_r) with D(u_exp) = -u_exp/tau_r
  - u_sin, u_cos for sin(omega*t)
  - F(t) = F0*(1 - u_exp) + Fa*u_sin = F0 - F0*u_exp + Fa*u_sin

Plant parameters (UNKNOWN): m, c, k
Input parameters (FIXED): F0=2.0, Fa=1.0, omega=3.0, tau_r=0.5
"""
function mass_spring_damper_poly()
    @parameters m c k

    # Input parameters - FIXED
    F0_val = 2.0      # steady-state force
    Fa_val = 1.0      # oscillation amplitude
    omega_val = 3.0   # frequency
    tau_r_val = 0.5   # ramp time constant

    @variables x(t) v(t) u_exp(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t)

    p_true = [
        1.0,    # m: mass
        0.5,    # c: damping
        4.0,    # k: spring constant
    ]

    # ICs: u_exp(0)=1 (exp(0)=1), u_sin(0)=0, u_cos(0)=1
    ic_true = [0.0, 0.0, 1.0, 0.0, 1.0]  # [x, v, u_exp, u_sin, u_cos]

    # F(t) = F0*(1 - u_exp) + Fa*u_sin = F0 - F0*u_exp + Fa*u_sin
    F_input = F0_val - F0_val * u_exp + Fa_val * u_sin

    equations = [
        D(x) ~ v,
        D(v) ~ (F_input - c * v - k * x) / m,
        D(u_exp) ~ -u_exp / tau_r_val,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ x, y2 ~ u_exp, y3 ~ u_sin, y4 ~ u_cos]

    states = [x, v, u_exp, u_sin, u_cos]
    parameters = [m, c, k]

    model, mq = create_ordered_ode_system("mass_spring_damper_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "mass_spring_damper_poly",
        model,
        mq,
        nothing,
        [0.0, 15.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                           11. FLEXIBLE ARM
    Linear dynamics, ramp + sinusoidal torque input
    Input: tau(t) = tau0*(1 - exp(-t/tau_r)) + tau_a*sin(omega*t)
=============================================================================#

"""
    flexible_arm_poly()

Flexible arm with polynomialized ramp + sinusoidal torque.
Original: tau(t) = tau0*(1 - exp(-t/tau_r)) + tau_a*sin(omega*t)
Polynomialized: tau(t) = tau0 - tau0*u_exp + tau_a*u_sin

Plant parameters (UNKNOWN): Jm, Jt, bm, bt, k_stiff
Input parameters (FIXED): tau0=0.5, tau_a=0.1, tau_r=0.5, omega=5.0
"""
function flexible_arm_poly()
    @parameters Jm Jt bm bt k_stiff

    # Input parameters - FIXED
    tau0_val = 0.5    # steady torque
    tau_a_val = 0.1   # oscillation amplitude
    tau_r_val = 0.5   # ramp time constant
    omega_val = 5.0   # vibration frequency

    @variables theta_m(t) omega_m(t) theta_t(t) omega_t(t) u_exp(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t) y5(t)

    p_true = [
        0.1,     # Jm
        0.05,    # Jt
        0.1,     # bm
        0.05,    # bt
        10.0,    # k_stiff
    ]

    ic_true = [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0]  # [theta_m, omega_m, theta_t, omega_t, u_exp, u_sin, u_cos]

    # tau(t) = tau0*(1 - u_exp) + tau_a*u_sin = tau0 - tau0*u_exp + tau_a*u_sin
    tau_input = tau0_val - tau0_val * u_exp + tau_a_val * u_sin

    equations = [
        D(theta_m) ~ omega_m,
        D(omega_m) ~ (tau_input - bm * omega_m - k_stiff * (theta_m - theta_t)) / Jm,
        D(theta_t) ~ omega_t,
        D(omega_t) ~ (-bt * omega_t - k_stiff * (theta_t - theta_m)) / Jt,
        D(u_exp) ~ -u_exp / tau_r_val,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ theta_m, y2 ~ theta_t, y3 ~ u_exp, y4 ~ u_sin, y5 ~ u_cos]

    states = [theta_m, omega_m, theta_t, omega_t, u_exp, u_sin, u_cos]
    parameters = [Jm, Jt, bm, bt, k_stiff]

    model, mq = create_ordered_ode_system("flexible_arm_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "flexible_arm_poly",
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
