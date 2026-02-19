# =============================================================================
# Original Model Definitions — 25 Models for IEEE TAC Paper
# Collected from ODEParameterEstimation.jl repository
# =============================================================================
#
# These are verbatim copies of the 25 models selected for benchmarking.
# See scaled_models.jl for the rescaled versions (p_true=0.5, ic_true=0.5).
#
# Usage:
#   include("original_models.jl")
#   pep = lotka_volterra()
#
# Organization follows paper sections:
#   A. Baseline / Validation (3)
#   B. Chemical / Process Engineering (3)
#   C. Mechanical / Aerospace / Vehicle (4)
#   D. Modern Control Applications (3)
#   E. Biological / Epidemiological (4)
#   F. Pharmacokinetics / Compartmental (2)
#   G. Challenging Large-Scale (1)
#   H. Extended Set (5)
# =============================================================================

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

# Helper (from load_examples.jl)
# create_ordered_ode_system is provided by ODEParameterEstimation

# =============================================================================
#                    SECTION A: BASELINE / VALIDATION (3)
# =============================================================================

# Model 1: Harmonic Oscillator
function harmonic()
    parameters = @parameters a b
    states = @variables x1(t) x2(t)
    observables = @variables y1(t) y2(t)
    p_true = [1.0, 1.0]
    ic_true = [1.0, 0.0]
    equations = [
        D(x1) ~ -a * x2,
        D(x2) ~ x1 / b,
    ]
    measured_quantities = [y1 ~ x1, y2 ~ x2]
    model, mq = create_ordered_ode_system("harmonic", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "harmonic", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 2: Lotka-Volterra
function lotka_volterra()
    parameters = @parameters k1 k2 k3
    states = @variables r(t) w(t)
    observables = @variables y1(t)
    p_true = [1.0, 0.5, 0.3]
    ic_true = [2.0, 1.0]
    equations = [
        D(r) ~ k1 * r - k2 * r * w,
        D(w) ~ k2 * r * w - k3 * w,
    ]
    measured_quantities = [y1 ~ r]
    model, mq = create_ordered_ode_system("Lotka_Volterra", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "lotka_volterra", model, mq, nothing,
        [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 3: Van der Pol Oscillator
function vanderpol()
    parameters = @parameters a b
    states = @variables x1(t) x2(t)
    observables = @variables y1(t) y2(t)
    p_true = [1.0, 1.0]
    ic_true = [2.0, 0.0]
    equations = [
        D(x1) ~ a * x2,
        D(x2) ~ -(x1) - b * (x1^2 - 1) * (x2),
    ]
    measured_quantities = [y1 ~ x1, y2 ~ x2]
    model, mq = create_ordered_ode_system("vanderpol", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "vanderpol", model, mq, nothing, nothing, nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#                SECTION B: CHEMICAL / PROCESS ENGINEERING (3)
# =============================================================================

# Model 4: Brusselator
function brusselator()
    parameters = @parameters a b
    states = @variables X(t) Y(t)
    observables = @variables y1(t) y2(t)
    p_true = [1.0, 3.0]
    ic_true = [1.0, 1.0]
    equations = [
        D(X) ~ 1.0 - (b + 1) * X + a * X^2 * Y,
        D(Y) ~ b * X - a * X^2 * Y,
    ]
    measured_quantities = [y1 ~ X, y2 ~ Y]
    model, mq = create_ordered_ode_system("brusselator", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "brusselator", model, mq, nothing,
        [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 5: CSTR with Fixed Activation Energy
function cstr_fixed_activation()
    @parameters tau Tin Cin dH_rhoCP UA_VrhoCP
    E_R_val = 8750.0
    Tc0_val = 300.0
    Tca_val = 10.0
    omega_val = 0.5
    @variables C(t) T(t) r_eff(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)
    p_true = [1.0, 350.0, 1.0, 5.0, 1.0]
    C0 = 0.5
    T0 = 350.0
    k0_original = 7.2e10
    r_eff0 = k0_original * exp(-E_R_val / T0)
    ic_true = [C0, T0, r_eff0, 0.0, 1.0]
    Tc = Tc0_val + Tca_val * u_sin
    reaction_rate = r_eff * C
    equations = [
        D(C) ~ (Cin - C) / tau - reaction_rate,
        D(T) ~ (Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc),
        D(r_eff) ~ r_eff * (E_R_val / T^2) * ((Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc)),
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]
    measured_quantities = [y1 ~ T, y2 ~ u_sin, y3 ~ u_cos]
    states = [C, T, r_eff, u_sin, u_cos]
    parameters = [tau, Tin, Cin, dH_rhoCP, UA_VrhoCP]
    model, mq = create_ordered_ode_system("cstr_fixed_activation", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "cstr_fixed_activation", model, mq, nothing,
        [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 6: Biohydrogenation
function biohydrogenation()
    parameters = @parameters k5 k6 k7 k8 k9 k10
    states = @variables x4(t) x5(t) x6(t) x7(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 2.0, 0.3, 1.0, 0.2, 5.0]
    ic_true = [4.0, 0.0, 0.0, 0.0]
    equations = [
        D(x4) ~ -k5 * x4 / (k6 + x4),
        D(x5) ~ k5 * x4 / (k6 + x4) - k7 * x5 / (k8 + x5 + x6),
        D(x6) ~ k7 * x5 / (k8 + x5 + x6) - k9 * x6 * (k10 - x6) / k10,
        D(x7) ~ k9 * x6 * (k10 - x6) / k10,
    ]
    measured_quantities = [y1 ~ x4, y2 ~ x5]
    model, mq = create_ordered_ode_system("BioHydrogenation", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "biohydrogenation", model, mq, nothing, nothing,
        [0.0, 36.0],
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 1,
    )
end

# =============================================================================
#            SECTION C: MECHANICAL / AEROSPACE / VEHICLE (4)
# =============================================================================

# Model 7: Mass-Spring-Damper
function mass_spring_damper()
    parameters = @parameters m c k F
    states = @variables x(t) v(t)
    observables = @variables y1(t)
    p_true = [1.0, 0.5, 4.0, 1.0]
    ic_true = [0.5, 0.0]
    equations = [
        D(x) ~ v,
        D(v) ~ (F - c * v - k * x) / m,
    ]
    measured_quantities = [y1 ~ x]
    model, mq = create_ordered_ode_system("mass_spring_damper", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "mass_spring_damper", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 8: DC Motor with Sinusoidal Voltage
function dc_motor_sinusoidal()
    @parameters Kt J b
    R_val = 2.0
    L_val = 0.5
    Kb_val = 0.1
    V0_val = 12.0
    Va_val = 2.0
    omega_val = 5.0
    @variables omega_m(t) i(t)
    @variables y1(t)
    p_true = [0.1, 0.01, 0.1]
    ic_true = [0.0, 0.0]
    V_input = V0_val + Va_val * sin(omega_val * t)
    equations = [
        D(omega_m) ~ (Kt * i - b * omega_m) / J,
        D(i) ~ (V_input - R_val * i - Kb_val * omega_m) / L_val,
    ]
    measured_quantities = [y1 ~ omega_m]
    states = [omega_m, i]
    parameters = [Kt, J, b]
    model, mq = create_ordered_ode_system("dc_motor_sinusoidal", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "dc_motor_sinusoidal", model, mq, nothing,
        [0.0, 5.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 9: Flexible Arm
function flexible_arm()
    parameters = @parameters Jm Jt bm bt k tau
    states = @variables theta_m(t) omega_m(t) theta_t(t) omega_t(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.1, 0.05, 0.1, 0.05, 10.0, 0.5]
    ic_true = [0.0, 0.0, 0.0, 0.0]
    equations = [
        D(theta_m) ~ omega_m,
        D(omega_m) ~ (tau - bm * omega_m - k * (theta_m - theta_t)) / Jm,
        D(theta_t) ~ omega_t,
        D(omega_t) ~ (-bt * omega_t - k * (theta_t - theta_m)) / Jt,
    ]
    measured_quantities = [y1 ~ theta_m, y2 ~ theta_t]
    model, mq = create_ordered_ode_system("flexible_arm", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "flexible_arm", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 10: Aircraft Pitch with Sinusoidal Elevator
function aircraft_pitch_sinusoidal()
    @parameters M_alpha M_q M_delta_e Z_alpha
    V_air_val = 50.0
    delta_e0_val = 0.0
    delta_ea_val = 0.05
    omega_val = 2.0
    @variables theta(t) q(t) alpha(t)
    @variables y1(t)
    p_true = [-5.0, -2.0, -10.0, -0.5]
    ic_true = [0.0, 0.0, 0.05]
    delta_e_input = delta_e0_val + delta_ea_val * sin(omega_val * t)
    equations = [
        D(theta) ~ q,
        D(q) ~ M_alpha * alpha + M_q * q + M_delta_e * delta_e_input,
        D(alpha) ~ Z_alpha * alpha / V_air_val + q,
    ]
    measured_quantities = [y1 ~ q]
    states = [theta, q, alpha]
    parameters = [M_alpha, M_q, M_delta_e, Z_alpha]
    model, mq = create_ordered_ode_system("aircraft_pitch_sinusoidal", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "aircraft_pitch_sinusoidal", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#              SECTION D: MODERN CONTROL APPLICATIONS (3)
# =============================================================================

# Model 11: Bicycle Model with Sinusoidal Steering
function bicycle_model_sinusoidal()
    @parameters Cf Cr m_veh Iz
    lf_val = 1.2
    lr_val = 1.4
    Vx_val = 20.0
    delta_a_val = 0.05
    omega_val = 0.5
    @variables vy(t) r(t)
    @variables y1(t) y2(t)
    p_true = [80000.0, 80000.0, 1500.0, 2500.0]
    ic_true = [0.0, 0.0]
    delta_input = delta_a_val * sin(omega_val * t)
    equations = [
        D(vy) ~ (Cf * (delta_input - (vy + lf_val * r) / Vx_val) + Cr * (-(vy - lr_val * r) / Vx_val)) / m_veh - Vx_val * r,
        D(r) ~ (lf_val * Cf * (delta_input - (vy + lf_val * r) / Vx_val) - lr_val * Cr * (-(vy - lr_val * r) / Vx_val)) / Iz,
    ]
    measured_quantities = [y1 ~ r, y2 ~ vy]
    states = [vy, r]
    parameters = [Cf, Cr, m_veh, Iz]
    model, mq = create_ordered_ode_system("bicycle_model_sinusoidal", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "bicycle_model_sinusoidal", model, mq, nothing,
        [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 12: Quadrotor Altitude with Sinusoidal Thrust
function quadrotor_sinusoidal()
    @parameters m d
    g_val = 9.81
    Ta_val = 2.0
    omega_val = 1.0
    @variables z(t) w(t)
    @variables y1(t)
    p_true = [1.0, 0.1]
    ic_true = [5.0, 0.0]
    equations = [
        D(z) ~ w,
        D(w) ~ (Ta_val * sin(omega_val * t) - d * w) / m,
    ]
    measured_quantities = [y1 ~ z]
    states = [z, w]
    parameters = [m, d]
    model, mq = create_ordered_ode_system("quadrotor_sinusoidal", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "quadrotor_sinusoidal", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 13: Boost Converter with Sinusoidal Duty Cycle
function boost_converter_sinusoidal()
    @parameters L C_cap R_load
    Vin_val = 12.0
    d0_val = 0.5
    da_val = 0.1
    omega_val = 100.0
    @variables iL(t) vC(t)
    @variables y1(t) y2(t)
    p_true = [0.001, 0.001, 10.0]
    ic_true = [1.0, 24.0]
    d_complement = (1.0 - d0_val) - da_val * sin(omega_val * t)
    equations = [
        D(iL) ~ (Vin_val - d_complement * vC) / L,
        D(vC) ~ (d_complement * iL - vC / R_load) / C_cap,
    ]
    measured_quantities = [y1 ~ vC, y2 ~ iL]
    states = [iL, vC]
    parameters = [L, C_cap, R_load]
    model, mq = create_ordered_ode_system("boost_converter_sinusoidal", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "boost_converter_sinusoidal", model, mq, nothing,
        [0.0, 0.5], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#           SECTION E: BIOLOGICAL / EPIDEMIOLOGICAL (4)
# =============================================================================

# Model 14: SEIR Epidemiological Model
function seir()
    parameters = @parameters a b nu
    states = @variables S(t) E(t) In(t) N(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.2, 0.4, 0.15]
    ic_true = [990.0, 10.0, 0.0, 1000.0]
    equations = [
        D(S) ~ -b * S * In / N,
        D(E) ~ b * S * In / N - nu * E,
        D(In) ~ nu * E - a * In,
        D(N) ~ 0,
    ]
    measured_quantities = [y1 ~ In, y2 ~ N]
    model, mq = create_ordered_ode_system("SEIR", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "seir", model, mq, nothing,
        [0.0, 60.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 15: FitzHugh-Nagumo
function fitzhugh_nagumo()
    parameters = @parameters g a b
    states = @variables V(t) R(t)
    observables = @variables y1(t)
    p_true = [3.0, 0.2, 0.2]
    ic_true = [-1.0, 0.0]
    equations = [
        D(V) ~ g * (V - V^3 / 3 + R),
        D(R) ~ 1 / g * (V - a + b * R),
    ]
    measured_quantities = [y1 ~ V]
    model, mq = create_ordered_ode_system("fitzhugh-nagumo", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "fitzhugh_nagumo", model, mq, nothing,
        [0.0, 0.03], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 16: Repressilator
function repressilator()
    parameters = @parameters beta n alpha
    states = @variables m1(t) m2(t) m3(t) p1(t) p2(t) p3(t)
    observables = @variables y1(t) y2(t) y3(t)
    p_true = [2.0, 2.0, 1.0]
    ic_true = [0.0, 0.0, 0.0, 2.0, 1.0, 3.0]
    equations = [
        D(m1) ~ -m1 + beta * (1 / (1 + p3 * n)),
        D(m2) ~ -m2 + beta * (1 / (1 + p1 * n)),
        D(m3) ~ -m3 + beta * (1 / (1 + p2 * n)),
        D(p1) ~ -alpha * (p1 - m1),
        D(p2) ~ -alpha * (p2 - m2),
        D(p3) ~ -alpha * (p3 - m3),
    ]
    measured_quantities = [y1 ~ p1, y2 ~ p2, y3 ~ p3]
    model, mq = create_ordered_ode_system("repressilator", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "repressilator", model, mq, nothing,
        [0.0, 24.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 17: HIV Immune Dynamics
function hiv()
    parameters = @parameters lm d beta a k u c q b h
    states = @variables x(t) y(t) v(t) w(t) z(t)
    observables = @variables y1(t) y2(t) y3(t) y4(t)
    p_true = [1.0, 0.01, 2e-5, 0.5, 50.0, 3.0, 0.05, 0.1, 0.002, 0.1]
    ic_true = [1000.0, 1.0, 1e-3, 1.0, 0.0]
    equations = [
        D(x) ~ lm - d * x - beta * x * v,
        D(y) ~ beta * x * v - a * y,
        D(v) ~ k * y - u * v,
        D(w) ~ c * z * y * w - c * q * y * w - b * w,
        D(z) ~ c * q * y * w - h * z,
    ]
    measured_quantities = [y1 ~ w, y2 ~ z, y3 ~ x, y4 ~ y + v]
    model, mq = create_ordered_ode_system("hiv", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "hiv", model, mq, nothing,
        [0.0, 25.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#          SECTION F: PHARMACOKINETICS / COMPARTMENTAL (2)
# =============================================================================

# Model 18: DAISY Mamillary 4-Compartment
function daisy_mamil4()
    parameters = @parameters k01 k12 k13 k14 k21 k31 k41
    states = @variables x1(t) x2(t) x3(t) x4(t)
    observables = @variables y1(t) y2(t) y3(t)
    p_true = [0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875]
    ic_true = [0.2, 0.4, 0.6, 0.8]
    equations = [
        D(x1) ~ -k01 * x1 + k12 * x2 + k13 * x3 + k14 * x4 - k21 * x1 - k31 * x1 - k41 * x1,
        D(x2) ~ -k12 * x2 + k21 * x1,
        D(x3) ~ -k13 * x3 + k31 * x1,
        D(x4) ~ -k14 * x4 + k41 * x1,
    ]
    measured_quantities = [y1 ~ x1, y2 ~ x2, y3 ~ x3 + x4]
    model, mq = create_ordered_ode_system("DAISY_mamil4", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "daisy_mamil4", model, mq, nothing,
        nothing, nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 19: Two-Compartment Pharmacokinetics
function two_compartment_pk()
    parameters = @parameters k12 k21 ke V1 V2
    states = @variables C1(t) C2(t)
    observables = @variables y1(t)
    p_true = [0.5, 0.25, 0.15, 1.0, 2.0]
    ic_true = [10.0, 0.0]
    equations = [
        D(C1) ~ -k12 * C1 + k21 * C2 * V2 / V1 - ke * C1,
        D(C2) ~ k12 * C1 * V1 / V2 - k21 * C2,
    ]
    measured_quantities = [y1 ~ C1]
    model, mq = create_ordered_ode_system("two_compartment_pk", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "two_compartment_pk", model, mq, nothing,
        [0.0, 48.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#             SECTION G: CHALLENGING LARGE-SCALE (1)
# =============================================================================

# Model 20: Crauste Corrected (Microbial Ecosystem)
function crauste_corrected()
    parameters = @parameters mu_N mu_EE mu_LE mu_LL mu_M mu_P mu_PE mu_PL delta_NE delta_EL delta_LM rho_E rho_P
    states = @variables N(t) E(t) L(t) M(t) P(t)
    observables = @variables y1(t) y2(t) y3(t) y4(t)
    p_true = [0.75, 0.0000216, 0.000000036, 0.0000075, 0.0, 0.055, 0.00000018, 0.000018, 0.009, 0.59, 0.025, 0.64, 0.15]
    ic_true = [8090.0, 0.0, 0.0, 0.0, 1.0]
    equations = [
        D(N) ~ -N * mu_N - N * P * delta_NE,
        D(E) ~ N * P * delta_NE + E * (rho_E * P - mu_EE * E - delta_EL),
        D(L) ~ delta_EL * E - L * (mu_LL * L + mu_LE * E + delta_LM),
        D(M) ~ L * delta_LM - mu_M * M,
        D(P) ~ P * (rho_P * P - mu_PE * E - mu_PL * L - mu_P),
    ]
    measured_quantities = [y1 ~ N, y2 ~ E, y3 ~ L + M, y4 ~ P]
    model, mq = create_ordered_ode_system("crauste", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "crauste_corrected", model, mq, nothing,
        [0.0, 25.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#                   SECTION H: EXTENDED SET (5)
# =============================================================================

# Model 21: Forced Lotka-Volterra with Sinusoidal Harvesting
function forced_lv_sinusoidal()
    @parameters alpha beta delta gamma
    h_val = 0.3
    omega_val = 2.0
    @variables x(t) y(t)
    @variables y1(t) y2(t)
    p_true = [1.5, 1.0, 0.5, 3.0]
    ic_true = [1.0, 1.0]
    equations = [
        D(x) ~ alpha * x - beta * x * y - h_val * sin(omega_val * t),
        D(y) ~ delta * x * y - gamma * y,
    ]
    measured_quantities = [y1 ~ x, y2 ~ y]
    states = [x, y]
    parameters = [alpha, beta, delta, gamma]
    model, mq = create_ordered_ode_system("forced_lv_sinusoidal", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "forced_lv_sinusoidal", model, mq, nothing,
        [0.0, 5.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 22: Treatment (SEIR + Intervention)
function treatment()
    parameters = @parameters a b d g nu
    states = @variables In(t) N(t) S(t) Tr(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.1, 0.8, 2.0, 0.3, 0.1]
    ic_true = [50.0, 1000.0, 950.0, 0.0]
    equations = [
        D(In) ~ b * S * In / N + d * b * S * Tr / N - (a + g) * In,
        D(N) ~ 0,
        D(S) ~ -b * S * In / N - d * b * S * Tr / N,
        D(Tr) ~ g * In - nu * Tr,
    ]
    measured_quantities = [y1 ~ Tr, y2 ~ N]
    model, mq = create_ordered_ode_system("treatment", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "treatment", model, mq, nothing, nothing,
        [0.0, 40.0],
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 6,
    )
end

# Model 23: SIRS with Periodic Forcing
function sirsforced()
    parameters = @parameters b0 b1 g M mu nu
    states = @variables i(t) r(t) s(t) x1(t) x2(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.143, 0.286, 0.429, 0.571, 0.714, 0.857]
    ic_true = [0.167, 0.333, 0.5, 0.667, 0.833]
    equations = [
        D(i) ~ b0 * (1.0 + b1 * x1) * i * s - (nu + mu) * i,
        D(r) ~ nu * i - (mu + g) * r,
        D(s) ~ mu - mu * s - b0 * (1.0 + b1 * x1) * i * s + g * r,
        D(x1) ~ -M * x2,
        D(x2) ~ M * x1,
    ]
    measured_quantities = [y1 ~ i, y2 ~ r]
    model, mq = create_ordered_ode_system("sirsforced", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "sirsforced", model, mq, nothing,
        [0.0, 30.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 3,
    )
end

# Model 24: Slow-Fast Chemical Cascade
function slowfast()
    parameters = @parameters k1 k2
    states = @variables xA(t) xB(t) xC(t) eA(t) eC(t) eB(t)
    observables = @variables y1(t) y2(t) y3(t) y4(t)
    p_true = [0.25, 0.5]
    ic_true = [0.166, 0.333, 0.5, 0.666, 0.833, 0.75]
    equations = [
        D(xA) ~ -k1 * xA,
        D(xB) ~ k1 * xA - k2 * xB,
        D(xC) ~ k2 * xB,
        D(eA) ~ 0,
        D(eC) ~ 0,
        D(eB) ~ 0,
    ]
    measured_quantities = [y1 ~ xC, y2 ~ eA * xA + eB * xB + eC * xC, y3 ~ eA, y4 ~ eC]
    model, mq = create_ordered_ode_system("slowfast", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "slowfast", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 25: Magnetic Levitation with Sinusoidal Voltage
function magnetic_levitation_sinusoidal()
    @parameters m_lin k_lin b_lin
    R_coil_val = 2.0
    L_val = 0.05
    ki_val = 10.0
    V0_val = 5.0
    Va_val = 1.0
    omega_val = 5.0
    @variables x(t) v(t) i(t)
    @variables y1(t)
    p_true = [0.1, 50.0, 2.0]
    i_eq = V0_val / R_coil_val
    ic_true = [0.0, 0.0, i_eq]
    V_input = V0_val + Va_val * sin(omega_val * t)
    equations = [
        D(x) ~ v,
        D(v) ~ (ki_val * (i - V0_val / R_coil_val) - k_lin * x - b_lin * v) / m_lin,
        D(i) ~ (V_input - R_coil_val * i) / L_val,
    ]
    measured_quantities = [y1 ~ x]
    states = [x, v, i]
    parameters = [m_lin, k_lin, b_lin]
    model, mq = create_ordered_ode_system("magnetic_levitation_sinusoidal", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "magnetic_levitation_sinusoidal", model, mq, nothing,
        [0.0, 5.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end
