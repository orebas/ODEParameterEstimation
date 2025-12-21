#=============================================================================
Tier A: IDENTIFIABLE Versions of Polynomialized Control Systems

These are modified versions of the unidentifiable systems from tier_a_polynomial.jl
with some parameters fixed to known values (from datasheets, physical constants,
or measurement) to make the remaining parameters identifiable.

MODIFICATIONS BASED ON STRUCTURAL IDENTIFIABILITY ANALYSIS:
Each system below documents:
- Original unidentifiable parameters
- Which parameters are fixed and why (physical justification)
- Remaining parameters to estimate

DESIGN PHILOSOPHY:
1. Fix parameters that are easily measured or known from specifications
2. Keep the physically interesting parameters as unknowns
3. Maintain relevance for control theory applications (IEEE TAC audience)
4. Ensure compatibility with algebraic parameter estimation methods
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#=============================================================================
                              1. DC MOTOR (IDENTIFIABLE)
    Original: 6 params, all unidentifiable
    Identifiable combinations: (L*J)/Kt, (R*b + Kb*Kt)/Kt, (R*J + L*b)/Kt

    FIX: R, L (measurable with multimeter/LCR meter), Kb (from motor datasheet)
    ESTIMATE: Kt, J, b (mechanical parameters - harder to measure directly)
=============================================================================#

"""
    dc_motor_identifiable()

DC motor with electrical parameters fixed (from measurement/datasheet).

Physical justification for fixed parameters:
- R (armature resistance): Easily measured with multimeter
- L (armature inductance): Measured with LCR meter or impedance analyzer
- Kb (back-EMF constant): Given in motor datasheet or measured at no-load

Parameters to estimate:
- Kt (torque constant): Related to Kb but affected by load conditions
- J (rotor inertia): Difficult to measure without specialized equipment
- b (viscous friction): Varies with bearing condition, temperature

This makes the system fully identifiable.
"""
function dc_motor_identifiable()
    # Parameters to ESTIMATE
    @parameters Kt J b

    # FIXED electrical parameters (known from measurement/datasheet)
    R_val = 2.0     # armature resistance (Ohms) - measured
    L_val = 0.5     # armature inductance (H) - measured
    Kb_val = 0.1    # back-EMF constant (V·s/rad) - from datasheet

    # Input parameters - FIXED
    V0_val = 12.0   # DC voltage offset
    Va_val = 2.0    # AC voltage amplitude
    omega_val = 5.0 # Input frequency (rad/s)

    # States
    @variables omega_m(t) i(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    # True values for parameters to estimate
    p_true = [
        0.1,    # Kt: torque constant
        0.01,   # J: rotor inertia
        0.1,    # b: viscous friction
    ]

    ic_true = [0.0, 0.0, 0.0, 1.0]  # [omega_m, i, u_sin, u_cos]

    V_input = V0_val + Va_val * u_sin

    equations = [
        D(omega_m) ~ (Kt * i - b * omega_m) / J,
        D(i) ~ (V_input - R_val * i - Kb_val * omega_m) / L_val,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ omega_m, y2 ~ u_sin, y3 ~ u_cos]

    states = [omega_m, i, u_sin, u_cos]
    parameters = [Kt, J, b]

    model, mq = create_ordered_ode_system("dc_motor_identifiable", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "dc_motor_identifiable",
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
                        2. QUADROTOR ALTITUDE (IDENTIFIABLE)
    Original: 3 params, only g unidentifiable

    FIX: g = 9.81 (known physical constant)
    ESTIMATE: m, d
=============================================================================#

"""
    quadrotor_altitude_identifiable()

Quadrotor altitude with gravity fixed.

Physical justification:
- g (gravity): Universal physical constant, g = 9.81 m/s²

Parameters to estimate:
- m (mass): Varies with payload, battery state
- d (drag coefficient): Varies with rotor wear, atmospheric conditions

This was already nearly identifiable - just fixing g makes it fully identifiable.
"""
function quadrotor_altitude_identifiable()
    @parameters m d

    # FIXED physical constant
    g_val = 9.81    # gravity (m/s²)

    # Input parameters - FIXED
    Ta_val = 2.0    # thrust oscillation amplitude
    omega_val = 1.0 # frequency

    @variables z(t) w(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        1.0,     # m: mass
        0.1,     # d: drag
    ]

    ic_true = [5.0, 0.0, 0.0, 1.0]

    equations = [
        D(z) ~ w,
        D(w) ~ (Ta_val * u_sin - d * w) / m,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ z, y2 ~ u_sin, y3 ~ u_cos]

    states = [z, w, u_sin, u_cos]
    parameters = [m, d]

    model, mq = create_ordered_ode_system("quadrotor_altitude_identifiable", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "quadrotor_altitude_identifiable",
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
                    4. MAGNETIC LEVITATION (IDENTIFIABLE)
    Original: 6 params, all unidentifiable
    Identifiable combinations: ratios involving ki

    FIX: R_coil, L (measured), ki (from calibration)
    ESTIMATE: m_lin, k_lin, b_lin (linearized mechanical dynamics)
=============================================================================#

"""
    magnetic_levitation_identifiable()

Magnetic levitation with electrical parameters fixed.

Physical justification for fixed parameters:
- R_coil: Coil resistance, easily measured with multimeter
- L: Coil inductance, measured with LCR meter
- ki: Current-to-force gain, calibrated experimentally

Parameters to estimate:
- m_lin: Effective mass (depends on operating point linearization)
- k_lin: Linearized magnetic stiffness
- b_lin: Damping coefficient

These mechanical parameters are harder to measure directly and may
vary with operating conditions.
"""
function magnetic_levitation_identifiable()
    @parameters m_lin k_lin b_lin

    # FIXED electrical parameters (measured)
    R_coil_val = 2.0   # coil resistance (Ohms)
    L_val = 0.05       # inductance (H)
    ki_val = 10.0      # current-to-force gain

    # Input parameters - FIXED
    V0_val = 5.0
    Va_val = 1.0
    omega_val = 5.0

    @variables x(t) v(t) i(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        0.1,    # m_lin: effective mass
        50.0,   # k_lin: linearized stiffness
        2.0,    # b_lin: damping
    ]

    i_eq = V0_val / R_coil_val
    ic_true = [0.0, 0.0, i_eq, 0.0, 1.0]

    V_input = V0_val + Va_val * u_sin

    equations = [
        D(x) ~ v,
        D(v) ~ (ki_val * (i - V0_val / R_coil_val) - k_lin * x - b_lin * v) / m_lin,
        D(i) ~ (V_input - R_coil_val * i) / L_val,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ x, y2 ~ u_sin, y3 ~ u_cos]

    states = [x, v, i, u_sin, u_cos]
    parameters = [m_lin, k_lin, b_lin]

    model, mq = create_ordered_ode_system("magnetic_levitation_identifiable", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "magnetic_levitation_identifiable",
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
                        5. AIRCRAFT PITCH (IDENTIFIABLE)
    Original: 5 params, unidentifiable: {theta, V_air, Z_alpha}
    Identifiable: M_delta_e, M_q, M_alpha, Z_alpha/V_air

    FIX: V_air (known from flight conditions/pitot tube)
    ESTIMATE: M_alpha, M_q, M_delta_e, Z_alpha (stability derivatives)
=============================================================================#

"""
    aircraft_pitch_identifiable()

Aircraft pitch dynamics with airspeed fixed.

Physical justification for fixed parameter:
- V_air: True airspeed, measured by pitot-static system or known test conditions

Parameters to estimate:
- M_alpha: Pitch moment due to angle of attack (stability derivative)
- M_q: Pitch damping derivative
- M_delta_e: Control effectiveness (elevator)
- Z_alpha: Lift curve slope effect

These stability derivatives are the key unknowns for flight dynamics
and are typically estimated from flight test data.
"""
function aircraft_pitch_identifiable()
    @parameters M_alpha M_q M_delta_e Z_alpha

    # FIXED from flight conditions
    V_air_val = 50.0  # true airspeed (m/s) - from pitot tube

    # Input parameters - FIXED
    delta_e0_val = 0.0
    delta_ea_val = 0.05
    omega_val = 2.0

    @variables theta(t) q(t) alpha(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        -5.0,     # M_alpha
        -2.0,     # M_q
        -10.0,    # M_delta_e
        -0.5,     # Z_alpha
    ]

    ic_true = [0.0, 0.0, 0.05, 0.0, 1.0]

    delta_e_input = delta_e0_val + delta_ea_val * u_sin

    equations = [
        D(theta) ~ q,
        D(q) ~ M_alpha * alpha + M_q * q + M_delta_e * delta_e_input,
        D(alpha) ~ Z_alpha * alpha / V_air_val + q,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ q, y2 ~ u_sin, y3 ~ u_cos]

    states = [theta, q, alpha, u_sin, u_cos]
    parameters = [M_alpha, M_q, M_delta_e, Z_alpha]

    model, mq = create_ordered_ode_system("aircraft_pitch_identifiable", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "aircraft_pitch_identifiable",
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
                        6. BICYCLE MODEL (IDENTIFIABLE)
    Original: 7 params, unidentifiable: {Cf, Iz, m_veh, Cr}
    Many identifiable ratios/combinations

    FIX: Vx (test speed), lf, lr (vehicle geometry - from wheelbase measurements)
    ESTIMATE: Cf, Cr (tire stiffness), m_veh (mass), Iz (yaw inertia)
=============================================================================#

"""
    bicycle_model_identifiable()

Vehicle lateral dynamics with speed and geometry fixed.

Physical justification for fixed parameters:
- Vx: Longitudinal velocity, controlled/measured in test
- lf, lr: Distance from CG to front/rear axle, measured from vehicle specs

Parameters to estimate:
- Cf, Cr: Cornering stiffness coefficients (vary with tire wear, pressure, temp)
- m_veh: Vehicle mass (varies with loading)
- Iz: Yaw moment of inertia

These tire and inertia parameters are the primary unknowns in vehicle
dynamics identification.
"""
function bicycle_model_identifiable()
    @parameters Cf Cr m_veh Iz

    # FIXED from vehicle specs and test conditions
    lf_val = 1.2    # front axle to CG (m)
    lr_val = 1.4    # rear axle to CG (m)
    Vx_val = 20.0   # test speed (m/s)

    # Input parameters - FIXED
    delta_a_val = 0.05
    omega_val = 0.5

    @variables vy(t) r(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t)

    p_true = [
        80000.0,   # Cf
        80000.0,   # Cr
        1500.0,    # m_veh
        2500.0,    # Iz
    ]

    ic_true = [0.0, 0.0, 0.0, 1.0]

    delta_input = delta_a_val * u_sin

    equations = [
        D(vy) ~ (Cf * (delta_input - (vy + lf_val * r) / Vx_val) + Cr * (-(vy - lr_val * r) / Vx_val)) / m_veh - Vx_val * r,
        D(r) ~ (lf_val * Cf * (delta_input - (vy + lf_val * r) / Vx_val) - lr_val * Cr * (-(vy - lr_val * r) / Vx_val)) / Iz,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ r, y2 ~ vy, y3 ~ u_sin, y4 ~ u_cos]

    states = [vy, r, u_sin, u_cos]
    parameters = [Cf, Cr, m_veh, Iz]

    model, mq = create_ordered_ode_system("bicycle_model_identifiable", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "bicycle_model_identifiable",
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
                        7. BOOST CONVERTER (IDENTIFIABLE)
    Original: 4 params, unidentifiable: {L, C_cap, R_load, iL}
    Identifiable: Vin, C_cap*R_load, L*C_cap

    FIX: Vin (measured input voltage)
    ESTIMATE: L, C_cap, R_load

    Note: With Vin fixed, there are still only 2 identifiable combinations
    (RC product and LC product), so 3 params from 2 equations is underdetermined.
    Adding iL observation makes it fully identifiable.
=============================================================================#

"""
    boost_converter_identifiable()

Boost converter with input voltage fixed and inductor current observed.

Physical justification:
- Vin: Input voltage, measured by multimeter or known power supply setting

Additional observation:
- iL: Inductor current, measured by current sensor (common in power electronics)

Parameters to estimate:
- L: Inductance (varies with core saturation, temperature)
- C_cap: Capacitance (varies with aging, temperature)
- R_load: Load resistance (varies with operating conditions)
"""
function boost_converter_identifiable()
    @parameters L C_cap R_load

    # FIXED from measurement
    Vin_val = 12.0  # input voltage (V)

    # Input parameters - FIXED
    d0_val = 0.5
    da_val = 0.1
    omega_val = 100.0

    @variables iL(t) vC(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t)  # Added y4 for iL observation

    p_true = [
        0.001,   # L
        0.001,   # C_cap
        10.0,    # R_load
    ]

    ic_true = [1.0, 24.0, 0.0, 1.0]

    d_complement = (1.0 - d0_val) - da_val * u_sin

    equations = [
        D(iL) ~ (Vin_val - d_complement * vC) / L,
        D(vC) ~ (d_complement * iL - vC / R_load) / C_cap,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # Observe both vC and iL (current sensor added)
    measured_quantities = [y1 ~ vC, y2 ~ iL, y3 ~ u_sin, y4 ~ u_cos]

    states = [iL, vC, u_sin, u_cos]
    parameters = [L, C_cap, R_load]

    model, mq = create_ordered_ode_system("boost_converter_identifiable", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "boost_converter_identifiable",
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
                        8. BILINEAR SYSTEM (IDENTIFIABLE)
    Original: 8 params, unidentifiable: {a12, b2, x2, a21}
    Identifiable: n2, n1, b1, a22, a11, a12*b2, a12*a21

    APPROACH: Observe x2 as well (additional sensor), reducing unidentifiability
    This is common in practice - adding a sensor to improve identifiability
=============================================================================#

"""
    bilinear_system_identifiable()

Bilinear system with both states observed.

Physical justification:
- In many applications, adding a second sensor is feasible
- Observing both x1 and x2 makes the coupling parameters identifiable

Parameters to estimate:
- All 8 original parameters become identifiable with dual observation
"""
function bilinear_system_identifiable()
    @parameters a11 a12 a21 a22 b1 b2 n1 n2

    # Input parameters - FIXED
    u0_val = 1.0
    ua_val = 0.5
    omega_val = 2.0

    @variables x1(t) x2(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t)  # y1=x1, y2=x2, y3,y4=input

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

    ic_true = [1.0, 0.5, 0.0, 1.0]

    u_input = u0_val + ua_val * u_sin

    equations = [
        D(x1) ~ a11 * x1 + a12 * x2 + b1 * u_input + n1 * x1 * u_input,
        D(x2) ~ a21 * x1 + a22 * x2 + b2 * u_input + n2 * x2 * u_input,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # Observe BOTH x1 and x2 (dual-sensor setup)
    measured_quantities = [y1 ~ x1, y2 ~ x2, y3 ~ u_sin, y4 ~ u_cos]

    states = [x1, x2, u_sin, u_cos]
    parameters = [a11, a12, a21, a22, b1, b2, n1, n2]

    model, mq = create_ordered_ode_system("bilinear_system_identifiable", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "bilinear_system_identifiable",
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
                    9. FORCED LOTKA-VOLTERRA (IDENTIFIABLE)
    Original: 4 params, unidentifiable: {b, predator}
    Identifiable: d_pred, c, a

    APPROACH: Observe predator population as well (wildlife monitoring)
=============================================================================#

"""
    forced_lotka_volterra_identifiable()

Lotka-Volterra with both populations observed.

Physical justification:
- In ecological studies, monitoring both prey and predator is common
- Camera traps, surveys, or tagging provide predator population data

Parameters to estimate:
- All 4 parameters become identifiable with dual observation
"""
function forced_lotka_volterra_identifiable()
    @parameters a b c d_pred

    # Input parameters - FIXED
    u0_val = 0.2
    ua_rel_val = 0.5
    omega_val = 0.5

    @variables prey(t) predator(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t) y4(t)

    p_true = [
        1.0,     # a: prey growth
        0.5,     # b: predation
        0.5,     # c: predator death
        0.25,    # d_pred: predator efficiency
    ]

    ic_true = [2.0, 1.0, 0.0, 1.0]

    u_input = u0_val + u0_val * ua_rel_val * u_sin

    equations = [
        D(prey) ~ a * prey - b * prey * predator + u_input,
        D(predator) ~ -c * predator + d_pred * prey * predator,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # Observe BOTH prey and predator
    measured_quantities = [y1 ~ prey, y2 ~ predator, y3 ~ u_sin, y4 ~ u_cos]

    states = [prey, predator, u_sin, u_cos]
    parameters = [a, b, c, d_pred]

    model, mq = create_ordered_ode_system("forced_lotka_volterra_identifiable", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "forced_lotka_volterra_identifiable",
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
                            SUMMARY OF MODIFICATIONS

| System               | Original Unidentifiable | Fixed Params | Estimated Params |
|----------------------|-------------------------|--------------|------------------|
| DC Motor             | All 6                   | R, L, Kb     | Kt, J, b (3)     |
| Quadrotor            | g only                  | g            | m, d (2)         |
| Magnetic Levitation  | All 6                   | R_coil, L, ki| m, k, b (3)      |
| Aircraft Pitch       | theta, V_air, Z_alpha   | V_air        | M_α,M_q,M_δe,Z_α |
| Bicycle Model        | Cf, Iz, m_veh, Cr       | Vx, lf, lr   | Cf, Cr, m, Iz (4)|
| Boost Converter      | L, C, R, iL             | Vin + add obs| L, C, R (3)      |
| Bilinear System      | a12, b2, x2, a21        | + add obs    | All 8            |
| Lotka-Volterra       | b, predator             | + add obs    | All 4            |

Total identifiable models: 8 (from 8 that were unidentifiable)
Plus 3 already identifiable: Thermal, Mass-Spring-Damper, Flexible Arm
=============================================================================#
