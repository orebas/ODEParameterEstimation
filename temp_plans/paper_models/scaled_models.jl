# =============================================================================
# Scaled Model Definitions — 25 Models for IEEE TAC Paper
# All parameters and ICs have true value 0.5
# =============================================================================
#
# Scaling methodology:
#   For param p with original value v:  p_orig = s_p * p_scaled, s_p = 2*v
#   For state x with original IC v:     x_orig = s_x * x_scaled, s_x = 2*v
#   For zero ICs: perturbed to small nonzero, then scaled
#   For negative values: negative scale factor (s = 2*v, preserving sign)
#
# Each function returns a ParameterEstimationProblem with:
#   p_true = [0.5, 0.5, ...], ic_true = [0.5, 0.5, ...]
#
# Usage:
#   include("scaled_models.jl")
#   pep = lotka_volterra_scaled()
# =============================================================================

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

# =============================================================================
#                    SECTION A: BASELINE / VALIDATION (3)
# =============================================================================

# Model 1: Harmonic Oscillator (scaled)
# Original: a=1.0, b=1.0, x1(0)=1.0, x2(0)=0.0→perturbed to 0.5
# Scale factors: s_a=2.0, s_b=2.0, s_x1=2.0, s_x2=1.0
# Original eqs:
#   D(x1) = -a*x2           → s_x1*D(x1s) = -(s_a*as)*(s_x2*x2s)
#   D(x2) = x1/b            → s_x2*D(x2s) = (s_x1*x1s)/(s_b*bs)
# Scaled:
#   D(x1s) = -(s_a*s_x2/s_x1)*as*x2s = -(2.0*1.0/2.0)*as*x2s = -1.0*as*x2s
#   D(x2s) = (s_x1/(s_x2*s_b))*x1s/bs = (2.0/(1.0*2.0))*x1s/bs = 1.0*x1s/bs
# Measured: y1 ~ x1_orig = s_x1*x1s = 2.0*x1s, y2 ~ x2_orig = s_x2*x2s = 1.0*x2s
function harmonic_scaled()
    parameters = @parameters a b
    states = @variables x1(t) x2(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 0.5]
    ic_true = [0.5, 0.5]  # x2 perturbed from 0→0.5, s_x2=1.0

    equations = [
        D(x1) ~ -1.0 * a * x2,
        D(x2) ~ 1.0 * x1 / b,
    ]
    measured_quantities = [y1 ~ 2.0 * x1, y2 ~ 1.0 * x2]

    model, mq = create_ordered_ode_system("harmonic_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "harmonic_scaled", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 2: Lotka-Volterra (scaled)
# Original: k1=1.0, k2=0.5, k3=0.3, r(0)=2.0, w(0)=1.0
# Scale factors: s_k1=2.0, s_k2=1.0, s_k3=0.6, s_r=4.0, s_w=2.0
# Original eqs:
#   D(r) = k1*r - k2*r*w     → s_r*D(rs) = (s_k1*k1s)*(s_r*rs) - (s_k2*k2s)*(s_r*rs)*(s_w*ws)
#   D(w) = k2*r*w - k3*w     → s_w*D(ws) = (s_k2*k2s)*(s_r*rs)*(s_w*ws) - (s_k3*k3s)*(s_w*ws)
# Scaled:
#   D(rs) = (s_k1)*k1s*rs - (s_k2*s_w)*k2s*rs*ws = 2.0*k1s*rs - 2.0*k2s*rs*ws
#   D(ws) = (s_k2*s_r)*k2s*rs*ws - (s_k3)*k3s*ws = 4.0*k2s*rs*ws - 0.6*k3s*ws
# Measured: y1 ~ r_orig = 4.0*rs
function lotka_volterra_scaled()
    parameters = @parameters k1 k2 k3
    states = @variables r(t) w(t)
    observables = @variables y1(t)
    p_true = [0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5]

    equations = [
        D(r) ~ 2.0 * k1 * r - 2.0 * k2 * r * w,
        D(w) ~ 4.0 * k2 * r * w - 0.6 * k3 * w,
    ]
    measured_quantities = [y1 ~ 4.0 * r]

    model, mq = create_ordered_ode_system("lotka_volterra_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "lotka_volterra_scaled", model, mq, nothing,
        [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 3: Van der Pol Oscillator (scaled)
# Original: a=1.0, b=1.0, x1(0)=2.0, x2(0)=0.0→perturbed to 0.5
# Scale factors: s_a=2.0, s_b=2.0, s_x1=4.0, s_x2=1.0
# Original eqs:
#   D(x1) = a*x2             → s_x1*D(x1s) = (s_a*as)*(s_x2*x2s)
#   D(x2) = -x1 - b*(x1^2-1)*x2  → s_x2*D(x2s) = -(s_x1*x1s) - (s_b*bs)*((s_x1*x1s)^2 - 1)*(s_x2*x2s)
# Scaled:
#   D(x1s) = (s_a*s_x2/s_x1)*as*x2s = (2.0*1.0/4.0)*as*x2s = 0.5*as*x2s
#   D(x2s) = -(s_x1/s_x2)*x1s - (s_b*s_x1^2*s_x2/s_x2)*bs*x1s^2*x2s + (s_b*s_x2/s_x2)*bs*x2s
#           = -4.0*x1s - (2.0*16.0)*bs*x1s^2*x2s + 2.0*bs*x2s
#           = -4.0*x1s - 32.0*bs*x1s^2*x2s + 2.0*bs*x2s
# Measured: y1 ~ 4.0*x1s, y2 ~ 1.0*x2s
function vanderpol_scaled()
    parameters = @parameters a b
    states = @variables x1(t) x2(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 0.5]
    ic_true = [0.5, 0.5]  # x2 perturbed from 0→0.5, s_x2=1.0

    equations = [
        D(x1) ~ 0.5 * a * x2,
        D(x2) ~ -4.0 * x1 - 32.0 * b * x1^2 * x2 + 2.0 * b * x2,
    ]
    measured_quantities = [y1 ~ 4.0 * x1, y2 ~ 1.0 * x2]

    model, mq = create_ordered_ode_system("vanderpol_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "vanderpol_scaled", model, mq, nothing,
        nothing, nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#                SECTION B: CHEMICAL / PROCESS ENGINEERING (3)
# =============================================================================

# Model 4: Brusselator (scaled)
# Original: a=1.0, b=3.0, X(0)=1.0, Y(0)=1.0
# Scale factors: s_a=2.0, s_b=6.0, s_X=2.0, s_Y=2.0
# Original eqs:
#   D(X) = 1.0 - (b+1)*X + a*X^2*Y
#     → s_X*D(Xs) = 1.0 - (s_b*bs+1)*(s_X*Xs) + (s_a*as)*(s_X*Xs)^2*(s_Y*Ys)
#   D(Y) = b*X - a*X^2*Y
#     → s_Y*D(Ys) = (s_b*bs)*(s_X*Xs) - (s_a*as)*(s_X*Xs)^2*(s_Y*Ys)
# Scaled:
#   D(Xs) = 1.0/s_X - (s_b/s_X)*bs*Xs - (1/s_X)*Xs + (s_a*s_X^2*s_Y/s_X)*as*Xs^2*Ys
#         = 0.5 - 3.0*bs*Xs - 0.5*Xs + 16.0*as*Xs^2*Ys
#   D(Ys) = (s_b*s_X/s_Y)*bs*Xs - (s_a*s_X^2*s_Y/s_Y)*as*Xs^2*Ys
#         = 6.0*bs*Xs - 16.0*as*Xs^2*Ys
# Measured: y1 ~ 2.0*Xs, y2 ~ 2.0*Ys
function brusselator_scaled()
    parameters = @parameters a b
    states = @variables X(t) Y(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 0.5]
    ic_true = [0.5, 0.5]

    equations = [
        D(X) ~ 0.5 - 3.0 * b * X - 0.5 * X + 16.0 * a * X^2 * Y,
        D(Y) ~ 6.0 * b * X - 16.0 * a * X^2 * Y,
    ]
    measured_quantities = [y1 ~ 2.0 * X, y2 ~ 2.0 * Y]

    model, mq = create_ordered_ode_system("brusselator_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "brusselator_scaled", model, mq, nothing,
        [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 5: CSTR with Fixed Activation Energy (scaled)
# Original: tau=1.0, Tin=350.0, Cin=1.0, dH_rhoCP=5.0, UA_VrhoCP=1.0
#           C(0)=0.5, T(0)=350.0, r_eff(0)≈1.0, u_sin(0)=0.0→perturbed, u_cos(0)=1.0
# Scale factors: s_tau=2.0, s_Tin=700.0, s_Cin=2.0, s_dH=10.0, s_UA=2.0
#                s_C=1.0, s_T=700.0, s_reff=2.0, s_usin=1.0(perturbed), s_ucos=2.0
# NOTE: This model has complex interactions. Since the external harness uses
# sin/cos states as oscillator inputs, and the CSTR has large absolute values
# (T≈350), we need careful handling. The r_eff IC is computed numerically.
# For this model, we scale so p_true=0.5, ic_true=0.5 as closely as possible.
#
# Given the extreme range of T (≈350), direct scaling would produce very large
# coefficients. We proceed with the mathematical transformation.
function cstr_fixed_activation_scaled()
    @parameters tau Tin Cin dH_rhoCP UA_VrhoCP

    E_R_val = 8750.0
    Tc0_val = 300.0
    Tca_val = 10.0
    omega_val = 0.5

    @variables C(t) T(t) r_eff(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    # Original values: tau=1, Tin=350, Cin=1, dH=5, UA=1
    # Original ICs: C=0.5, T=350, r_eff=k0*exp(-E_R/350), u_sin=0→0.5, u_cos=1
    # Scale factors
    s_tau = 2.0; s_Tin = 700.0; s_Cin = 2.0; s_dH = 10.0; s_UA = 2.0
    s_C = 1.0; s_T = 700.0
    k0_original = 7.2e10
    r_eff0 = k0_original * exp(-E_R_val / 350.0)
    s_reff = 2.0 * r_eff0
    s_usin = 1.0  # perturbed from 0
    s_ucos = 2.0

    p_true = [0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5, 0.5]

    # Tc = Tc0_val + Tca_val * u_sin_orig = 300 + 10 * s_usin * u_sin_s
    # Original equations after substitution:
    # D(C_orig) = (Cin_orig - C_orig)/tau_orig - r_eff_orig*C_orig
    # s_C*D(Cs) = (s_Cin*Cins - s_C*Cs)/(s_tau*taus) - (s_reff*reffs)*(s_C*Cs)
    # D(Cs) = (s_Cin/(s_C*s_tau))*Cins/taus - (1/s_tau)*Cs/taus - (s_reff)*reffs*Cs
    #       = (2.0/2.0)*Cins/taus - (1/2.0)*Cs/taus - s_reff*reffs*Cs
    #       = 1.0*Cins/taus - 0.5*Cs/taus - s_reff*reffs*Cs

    # D(T_orig) = (Tin_orig - T_orig)/tau_orig + dH_orig*r_orig*C_orig - UA_orig*(T_orig - Tc)
    # s_T*D(Ts) = (s_Tin*Tins - s_T*Ts)/(s_tau*taus) + (s_dH*dHs)*(s_reff*reffs)*(s_C*Cs)
    #             - (s_UA*UAs)*(s_T*Ts - Tc0_val - Tca_val*s_usin*usins)
    # D(Ts) = (s_Tin/(s_T*s_tau))*Tins/taus - (1/s_tau)*Ts/taus
    #         + (s_dH*s_reff*s_C/s_T)*dHs*reffs*Cs
    #         - (s_UA)*UAs*Ts + (s_UA*Tc0_val/s_T)*UAs + (s_UA*Tca_val*s_usin/s_T)*UAs*usins

    # The D(r_eff) equation is similarly complex. Let's compute coefficients.
    # For brevity, we define the RHS terms symbolically.

    # Let's define helper expressions for readability
    Tc_orig = Tc0_val + Tca_val * s_usin * u_sin  # Tc in original units
    T_orig = s_T * T  # T in original units

    # D(T_orig)/dt (the RHS in original units, expressed in scaled vars)
    dT_orig = (s_Tin * Tin - s_T * T) / (s_tau * tau) + (s_dH * dH_rhoCP) * (s_reff * r_eff) * (s_C * C) - (s_UA * UA_VrhoCP) * (s_T * T - Tc_orig)

    equations = [
        # D(C_s) = D(C_orig) / s_C
        D(C) ~ ((s_Cin * Cin - s_C * C) / (s_tau * tau) - (s_reff * r_eff) * (s_C * C)) / s_C,
        # D(T_s) = D(T_orig) / s_T
        D(T) ~ dT_orig / s_T,
        # D(r_eff_s) = D(r_eff_orig) / s_reff
        # D(r_eff_orig) = r_eff_orig * (E_R / T_orig^2) * D(T_orig)
        D(r_eff) ~ (s_reff * r_eff) * (E_R_val / (T_orig)^2) * dT_orig / s_reff,
        # Oscillator
        D(u_sin) ~ omega_val * (s_ucos / s_usin) * u_cos,
        D(u_cos) ~ -omega_val * (s_usin / s_ucos) * u_sin,
    ]

    # y1 ~ T_orig = s_T * T_s = 700*T_s
    # y2 ~ u_sin_orig = s_usin * u_sin_s = 1.0*u_sin_s
    # y3 ~ u_cos_orig = s_ucos * u_cos_s = 2.0*u_cos_s
    measured_quantities = [y1 ~ s_T * T, y2 ~ s_usin * u_sin, y3 ~ s_ucos * u_cos]

    states = [C, T, r_eff, u_sin, u_cos]
    parameters = [tau, Tin, Cin, dH_rhoCP, UA_VrhoCP]

    model, mq = create_ordered_ode_system("cstr_fixed_activation_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "cstr_fixed_activation_scaled", model, mq, nothing,
        [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 6: Biohydrogenation (scaled)
# Original: k5=0.5, k6=2.0, k7=0.3, k8=1.0, k9=0.2, k10=5.0
#           x4(0)=4.0, x5(0)=0→0.25, x6(0)=0→0.25, x7(0)=0→0.25
# Scale factors: s_k5=1.0, s_k6=4.0, s_k7=0.6, s_k8=2.0, s_k9=0.4, s_k10=10.0
#                s_x4=8.0, s_x5=0.5, s_x6=0.5, s_x7=0.5
# Original eqs:
#   D(x4) = -k5*x4/(k6+x4)
#   D(x5) = k5*x4/(k6+x4) - k7*x5/(k8+x5+x6)
#   D(x6) = k7*x5/(k8+x5+x6) - k9*x6*(k10-x6)/k10
#   D(x7) = k9*x6*(k10-x6)/k10
function biohydrogenation_scaled()
    parameters = @parameters k5 k6 k7 k8 k9 k10
    states = @variables x4(t) x5(t) x6(t) x7(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5]  # x5,x6,x7 perturbed from 0→0.25

    # Scale factors
    s_k5 = 1.0; s_k6 = 4.0; s_k7 = 0.6; s_k8 = 2.0; s_k9 = 0.4; s_k10 = 10.0
    s_x4 = 8.0; s_x5 = 0.5; s_x6 = 0.5; s_x7 = 0.5

    # Common subexpressions in original units (in terms of scaled vars)
    # k6_orig + x4_orig = s_k6*k6s + s_x4*x4s
    # k8_orig + x5_orig + x6_orig = s_k8*k8s + s_x5*x5s + s_x6*x6s

    equations = [
        # D(x4_s) = -(s_k5*k5s)*(s_x4*x4s)/((s_k6*k6s + s_x4*x4s)*s_x4)
        D(x4) ~ -(s_k5 * k5) * (s_x4 * x4) / ((s_k6 * k6 + s_x4 * x4) * s_x4),
        # D(x5_s) = [(s_k5*k5s)*(s_x4*x4s)/(s_k6*k6s+s_x4*x4s) - (s_k7*k7s)*(s_x5*x5s)/(s_k8*k8s+s_x5*x5s+s_x6*x6s)] / s_x5
        D(x5) ~ ((s_k5 * k5) * (s_x4 * x4) / (s_k6 * k6 + s_x4 * x4) - (s_k7 * k7) * (s_x5 * x5) / (s_k8 * k8 + s_x5 * x5 + s_x6 * x6)) / s_x5,
        # D(x6_s) = [(s_k7*k7s)*(s_x5*x5s)/(s_k8*k8s+s_x5*x5s+s_x6*x6s) - (s_k9*k9s)*(s_x6*x6s)*(s_k10*k10s-s_x6*x6s)/(s_k10*k10s)] / s_x6
        D(x6) ~ ((s_k7 * k7) * (s_x5 * x5) / (s_k8 * k8 + s_x5 * x5 + s_x6 * x6) - (s_k9 * k9) * (s_x6 * x6) * (s_k10 * k10 - s_x6 * x6) / (s_k10 * k10)) / s_x6,
        # D(x7_s) = [(s_k9*k9s)*(s_x6*x6s)*(s_k10*k10s-s_x6*x6s)/(s_k10*k10s)] / s_x7
        D(x7) ~ ((s_k9 * k9) * (s_x6 * x6) * (s_k10 * k10 - s_x6 * x6) / (s_k10 * k10)) / s_x7,
    ]

    # y1 ~ x4_orig = 8.0*x4s, y2 ~ x5_orig = 0.5*x5s
    measured_quantities = [y1 ~ s_x4 * x4, y2 ~ s_x5 * x5]

    model, mq = create_ordered_ode_system("biohydrogenation_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "biohydrogenation_scaled", model, mq, nothing, nothing,
        [0.0, 36.0],
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 1,
    )
end

# =============================================================================
#            SECTION C: MECHANICAL / AEROSPACE / VEHICLE (4)
# =============================================================================

# Model 7: Mass-Spring-Damper (scaled)
# Original: m=1.0, c=0.5, k=4.0, F=1.0, x(0)=0.5, v(0)=0→0.25
# Scale factors: s_m=2.0, s_c=1.0, s_k=8.0, s_F=2.0, s_x=1.0, s_v=0.5
# Original eqs:
#   D(x) = v                 → s_x*D(xs) = s_v*vs
#   D(v) = (F-c*v-k*x)/m    → s_v*D(vs) = (s_F*Fs - s_c*cs*s_v*vs - s_k*ks*s_x*xs)/(s_m*ms)
# Scaled:
#   D(xs) = (s_v/s_x)*vs = 0.5*vs
#   D(vs) = (s_F*Fs - s_c*s_v*cs*vs - s_k*s_x*ks*xs)/(s_m*s_v*ms)
#         = (2.0*Fs - 0.5*cs*vs - 8.0*ks*xs)/(2.0*0.5*ms)
#         = (2.0*Fs - 0.5*cs*vs - 8.0*ks*xs)/(1.0*ms)
function mass_spring_damper_scaled()
    parameters = @parameters m c k F
    states = @variables x(t) v(t)
    observables = @variables y1(t)
    p_true = [0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5]  # v perturbed from 0→0.25, s_v=0.5

    s_m = 2.0; s_c = 1.0; s_k = 8.0; s_F = 2.0; s_x = 1.0; s_v = 0.5
    equations = [
        D(x) ~ (s_v / s_x) * v,
        D(v) ~ (s_F * F - s_c * s_v * c * v - s_k * s_x * k * x) / (s_m * s_v * m),
    ]
    measured_quantities = [y1 ~ s_x * x]

    model, mq = create_ordered_ode_system("mass_spring_damper_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "mass_spring_damper_scaled", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 8: DC Motor with Sinusoidal Voltage (scaled)
# Original: Kt=0.1, J=0.01, b=0.1, omega_m(0)=0→0.5, i(0)=0→0.5
# Scale factors: s_Kt=0.2, s_J=0.02, s_b=0.2, s_om=1.0, s_i=1.0
# Fixed constants: R_val=2.0, L_val=0.5, Kb_val=0.1, V0_val=12.0, Va_val=2.0, omega_val=5.0
# V_input = 12.0 + 2.0*sin(5.0*t) (unchanged - external forcing)
# Original eqs:
#   D(omega_m) = (Kt*i - b*omega_m)/J
#   D(i) = (V_input - R*i - Kb*omega_m)/L
# Scaled:
#   D(oms) = [(s_Kt*Kts)*(s_i*is) - (s_b*bs)*(s_om*oms)] / (s_J*s_om*Js)
#          = [0.2*Kts*1.0*is - 0.2*bs*1.0*oms] / (0.02*1.0*Js)
#          = [0.2*Kts*is - 0.2*bs*oms] / (0.02*Js)
#          = (10.0*Kts*is - 10.0*bs*oms) / Js
#   D(is) = (V_input - R_val*s_i*is - Kb_val*s_om*oms) / (L_val*s_i)
#         = (12.0+2.0*sin(5t) - 2.0*is - 0.1*oms) / 0.5
#         = 2.0*(12.0+2.0*sin(5t) - 2.0*is - 0.1*oms)
function dc_motor_sinusoidal_scaled()
    @parameters Kt J b
    R_val = 2.0; L_val = 0.5; Kb_val = 0.1
    V0_val = 12.0; Va_val = 2.0; omega_val = 5.0

    @variables omega_m(t) i(t)
    @variables y1(t)
    p_true = [0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5]  # Both perturbed from 0

    s_Kt = 0.2; s_J = 0.02; s_b = 0.2; s_om = 1.0; s_i = 1.0
    V_input = V0_val + Va_val * sin(omega_val * t)

    equations = [
        D(omega_m) ~ (s_Kt * Kt * s_i * i - s_b * b * s_om * omega_m) / (s_J * s_om * J),
        D(i) ~ (V_input - R_val * s_i * i - Kb_val * s_om * omega_m) / (L_val * s_i),
    ]
    measured_quantities = [y1 ~ s_om * omega_m]

    states = [omega_m, i]
    parameters = [Kt, J, b]
    model, mq = create_ordered_ode_system("dc_motor_sinusoidal_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "dc_motor_sinusoidal_scaled", model, mq, nothing,
        [0.0, 5.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 9: Flexible Arm (scaled)
# Original: Jm=0.1, Jt=0.05, bm=0.1, bt=0.05, k=10.0, tau=0.5
#           ALL ICs = 0 → perturbed to 0.25
# Scale factors: s_Jm=0.2, s_Jt=0.1, s_bm=0.2, s_bt=0.1, s_k=20.0, s_tau=1.0
#                s_thm=0.5, s_omm=0.5, s_tht=0.5, s_omt=0.5
function flexible_arm_scaled()
    parameters = @parameters Jm Jt bm bt k tau
    states = @variables theta_m(t) omega_m(t) theta_t(t) omega_t(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5]  # All perturbed from 0→0.25

    s_Jm = 0.2; s_Jt = 0.1; s_bm = 0.2; s_bt = 0.1; s_k = 20.0; s_tau = 1.0
    s_thm = 0.5; s_omm = 0.5; s_tht = 0.5; s_omt = 0.5

    equations = [
        # D(theta_m_s) = (s_omm/s_thm)*omega_m_s
        D(theta_m) ~ (s_omm / s_thm) * omega_m,
        # D(omega_m_s) = [s_tau*tau_s - s_bm*bm_s*s_omm*omm_s - s_k*k_s*(s_thm*thm_s - s_tht*tht_s)] / (s_Jm*Jm_s*s_omm)
        D(omega_m) ~ (s_tau * tau - s_bm * bm * s_omm * omega_m - s_k * k * (s_thm * theta_m - s_tht * theta_t)) / (s_Jm * Jm * s_omm),
        # D(theta_t_s) = (s_omt/s_tht)*omega_t_s
        D(theta_t) ~ (s_omt / s_tht) * omega_t,
        # D(omega_t_s) = [-s_bt*bt_s*s_omt*omt_s - s_k*k_s*(s_tht*tht_s - s_thm*thm_s)] / (s_Jt*Jt_s*s_omt)
        D(omega_t) ~ (-s_bt * bt * s_omt * omega_t - s_k * k * (s_tht * theta_t - s_thm * theta_m)) / (s_Jt * Jt * s_omt),
    ]

    measured_quantities = [y1 ~ s_thm * theta_m, y2 ~ s_tht * theta_t]

    model, mq = create_ordered_ode_system("flexible_arm_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "flexible_arm_scaled", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 10: Aircraft Pitch with Sinusoidal Elevator (scaled)
# Original: M_alpha=-5.0, M_q=-2.0, M_delta_e=-10.0, Z_alpha=-0.5
#           theta(0)=0→0.025, q(0)=0→0.025, alpha(0)=0.05
# Negative params: flip sign into equation. Let M_alpha_pos = |M_alpha| = 5.0
# Scale factors: s_Ma=10.0, s_Mq=4.0, s_Mde=20.0, s_Za=1.0
#                s_th=0.05, s_q=0.05, s_al=0.1
# In equations, params appear with negative sign: -s_Ma*Ma_s, etc.
function aircraft_pitch_sinusoidal_scaled()
    @parameters M_alpha M_q M_delta_e Z_alpha
    V_air_val = 50.0
    delta_e0_val = 0.0; delta_ea_val = 0.05; omega_val = 2.0

    @variables theta(t) q(t) alpha(t)
    @variables y1(t)
    p_true = [0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5]

    # Negative params: original values are negative, so s = 2*v (v<0)
    # M_alpha_orig = -5.0 → s_Ma = -10.0, param_scaled = 0.5 → orig = -10*0.5 = -5 ✓
    # M_q_orig = -2.0 → s_Mq = -4.0
    # M_delta_e_orig = -10.0 → s_Mde = -20.0
    # Z_alpha_orig = -0.5 → s_Za = -1.0
    s_Ma = -10.0; s_Mq = -4.0; s_Mde = -20.0; s_Za = -1.0
    s_th = 0.05; s_q = 0.05; s_al = 0.1

    delta_e_input = delta_e0_val + delta_ea_val * sin(omega_val * t)

    equations = [
        # D(theta_s) = (s_q/s_th)*q_s
        D(theta) ~ (s_q / s_th) * q,
        # D(q_s) = [s_Ma*Ma_s*s_al*al_s + s_Mq*Mq_s*s_q*q_s + s_Mde*Mde_s*delta_e] / s_q
        D(q) ~ (s_Ma * M_alpha * s_al * alpha + s_Mq * M_q * s_q * q + s_Mde * M_delta_e * delta_e_input) / s_q,
        # D(alpha_s) = [s_Za*Za_s*s_al*al_s/V_air + s_q*q_s] / s_al
        D(alpha) ~ (s_Za * Z_alpha * s_al * alpha / V_air_val + s_q * q) / s_al,
    ]

    measured_quantities = [y1 ~ s_q * q]

    states = [theta, q, alpha]
    parameters = [M_alpha, M_q, M_delta_e, Z_alpha]
    model, mq = create_ordered_ode_system("aircraft_pitch_sinusoidal_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "aircraft_pitch_sinusoidal_scaled", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#              SECTION D: MODERN CONTROL APPLICATIONS (3)
# =============================================================================

# Model 11: Bicycle Model with Sinusoidal Steering (scaled)
# Original: Cf=80000, Cr=80000, m_veh=1500, Iz=2500
#           vy(0)=0→0.25, r(0)=0→0.05
# Scale factors: s_Cf=160000, s_Cr=160000, s_m=3000, s_Iz=5000
#                s_vy=0.5, s_r=0.1
# Fixed: lf=1.2, lr=1.4, Vx=20.0, delta_a=0.05, omega=0.5
function bicycle_model_sinusoidal_scaled()
    @parameters Cf Cr m_veh Iz
    lf_val = 1.2; lr_val = 1.4; Vx_val = 20.0
    delta_a_val = 0.05; omega_val = 0.5

    @variables vy(t) r(t)
    @variables y1(t) y2(t)
    p_true = [0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5]

    s_Cf = 160000.0; s_Cr = 160000.0; s_m = 3000.0; s_Iz = 5000.0
    s_vy = 0.5; s_r = 0.1

    delta_input = delta_a_val * sin(omega_val * t)

    # Original first eq:
    # D(vy) = [Cf*(delta - (vy+lf*r)/Vx) + Cr*(-(vy-lr*r)/Vx)] / m_veh - Vx*r
    # Substituting scaled vars:
    # s_vy*D(vys) = [s_Cf*Cfs*(delta - (s_vy*vys+lf*s_r*rs)/Vx) + s_Cr*Crs*(-(s_vy*vys-lr*s_r*rs)/Vx)] / (s_m*ms) - Vx*s_r*rs

    equations = [
        D(vy) ~ ((s_Cf * Cf * (delta_input - (s_vy * vy + lf_val * s_r * r) / Vx_val) + s_Cr * Cr * (-(s_vy * vy - lr_val * s_r * r) / Vx_val)) / (s_m * m_veh) - Vx_val * s_r * r) / s_vy,
        D(r) ~ (lf_val * s_Cf * Cf * (delta_input - (s_vy * vy + lf_val * s_r * r) / Vx_val) - lr_val * s_Cr * Cr * (-(s_vy * vy - lr_val * s_r * r) / Vx_val)) / (s_Iz * Iz * s_r),
    ]

    measured_quantities = [y1 ~ s_r * r, y2 ~ s_vy * vy]

    states = [vy, r]
    parameters = [Cf, Cr, m_veh, Iz]
    model, mq = create_ordered_ode_system("bicycle_model_sinusoidal_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "bicycle_model_sinusoidal_scaled", model, mq, nothing,
        [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 12: Quadrotor Altitude with Sinusoidal Thrust (scaled)
# Original: m=1.0, d=0.1, z(0)=5.0, w(0)=0→0.5
# Scale factors: s_m=2.0, s_d=0.2, s_z=10.0, s_w=1.0
# D(z) = w → D(zs) = (s_w/s_z)*ws = 0.1*ws
# D(w) = (Ta*sin(t) - d*w)/m → D(ws) = (Ta*sin(t) - s_d*ds*s_w*ws)/(s_m*ms*s_w)
function quadrotor_sinusoidal_scaled()
    @parameters m d
    Ta_val = 2.0; omega_val = 1.0

    @variables z(t) w(t)
    @variables y1(t)
    p_true = [0.5, 0.5]
    ic_true = [0.5, 0.5]

    s_m = 2.0; s_d = 0.2; s_z = 10.0; s_w = 1.0

    equations = [
        D(z) ~ (s_w / s_z) * w,
        D(w) ~ (Ta_val * sin(omega_val * t) - s_d * d * s_w * w) / (s_m * m * s_w),
    ]
    measured_quantities = [y1 ~ s_z * z]

    states = [z, w]
    parameters = [m, d]
    model, mq = create_ordered_ode_system("quadrotor_sinusoidal_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "quadrotor_sinusoidal_scaled", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 13: Boost Converter with Sinusoidal Duty Cycle (scaled)
# Original: L=0.001, C_cap=0.001, R_load=10.0
#           iL(0)=1.0, vC(0)=24.0
# Scale factors: s_L=0.002, s_C=0.002, s_R=20.0, s_iL=2.0, s_vC=48.0
# d_complement = 0.5 - 0.1*sin(100t) (unchanged - external forcing)
function boost_converter_sinusoidal_scaled()
    @parameters L C_cap R_load
    Vin_val = 12.0
    d0_val = 0.5; da_val = 0.1; omega_val = 100.0

    @variables iL(t) vC(t)
    @variables y1(t) y2(t)
    p_true = [0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5]

    s_L = 0.002; s_C = 0.002; s_R = 20.0; s_iL = 2.0; s_vC = 48.0
    d_complement = (1.0 - d0_val) - da_val * sin(omega_val * t)

    equations = [
        # D(iL_s) = (Vin - d_comp*s_vC*vCs) / (s_L*Ls*s_iL)
        D(iL) ~ (Vin_val - d_complement * s_vC * vC) / (s_L * L * s_iL),
        # D(vC_s) = (d_comp*s_iL*iLs - s_vC*vCs/(s_R*Rs)) / (s_C*Cs*s_vC)
        D(vC) ~ (d_complement * s_iL * iL - s_vC * vC / (s_R * R_load)) / (s_C * C_cap * s_vC),
    ]

    measured_quantities = [y1 ~ s_vC * vC, y2 ~ s_iL * iL]

    states = [iL, vC]
    parameters = [L, C_cap, R_load]
    model, mq = create_ordered_ode_system("boost_converter_sinusoidal_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "boost_converter_sinusoidal_scaled", model, mq, nothing,
        [0.0, 0.5], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#           SECTION E: BIOLOGICAL / EPIDEMIOLOGICAL (4)
# =============================================================================

# Model 14: SEIR Epidemiological Model (scaled)
# Original: a=0.2, b=0.4, nu=0.15
#           S(0)=990, E(0)=10, In(0)=0→5, N(0)=1000
# Scale factors: s_a=0.4, s_b=0.8, s_nu=0.3
#                s_S=1980, s_E=20, s_In=10, s_N=2000
# Note: S+E+In = N is a conservation law, but after scaling with different
# scale factors the conservation is broken. This is intentional — the randomized
# harness doesn't preserve conservation laws anyway.
function seir_scaled()
    parameters = @parameters a b nu
    states = @variables S(t) E(t) In(t) N(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5]

    s_a = 0.4; s_b = 0.8; s_nu = 0.3
    s_S = 1980.0; s_E = 20.0; s_In = 10.0; s_N = 2000.0

    equations = [
        # D(S_s) = -b_orig*S_orig*In_orig/N_orig / s_S
        D(S) ~ -(s_b * b) * (s_S * S) * (s_In * In) / ((s_N * N) * s_S),
        # D(E_s) = [b_orig*S_orig*In_orig/N_orig - nu_orig*E_orig] / s_E
        D(E) ~ ((s_b * b) * (s_S * S) * (s_In * In) / (s_N * N) - (s_nu * nu) * (s_E * E)) / s_E,
        # D(In_s) = [nu_orig*E_orig - a_orig*In_orig] / s_In
        D(In) ~ ((s_nu * nu) * (s_E * E) - (s_a * a) * (s_In * In)) / s_In,
        D(N) ~ 0,
    ]

    measured_quantities = [y1 ~ s_In * In, y2 ~ s_N * N]

    model, mq = create_ordered_ode_system("SEIR_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "seir_scaled", model, mq, nothing,
        [0.0, 60.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 15: FitzHugh-Nagumo (scaled)
# Original: g=3.0, a=0.2, b=0.2, V(0)=-1.0, R(0)=0→0.25
# Negative IC: V(0)=-1.0, so s_V = 2*(-1.0) = -2.0
# Scale factors: s_g=6.0, s_a=0.4, s_b=0.4, s_V=-2.0, s_R=0.5
# V_orig = s_V*Vs = -2.0*Vs → Vs=0.5 maps to V=-1.0 ✓
function fitzhugh_nagumo_scaled()
    parameters = @parameters g a b
    states = @variables V(t) R(t)
    observables = @variables y1(t)
    p_true = [0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5]

    s_g = 6.0; s_a = 0.4; s_b = 0.4; s_V = -2.0; s_R = 0.5

    # Original: D(V) = g*(V - V^3/3 + R)
    # s_V*D(Vs) = s_g*gs*(s_V*Vs - (s_V*Vs)^3/3 + s_R*Rs)
    # D(Vs) = s_g*gs*(s_V*Vs - s_V^3*Vs^3/3 + s_R*Rs) / s_V
    # D(Vs) = s_g*gs*Vs - s_g*gs*s_V^2*Vs^3/3 + s_g*gs*s_R*Rs/s_V

    # Original: D(R) = (1/g)*(V - a + b*R)
    # s_R*D(Rs) = (1/(s_g*gs))*(s_V*Vs - s_a*as + s_b*bs*s_R*Rs)
    # D(Rs) = (s_V*Vs - s_a*as + s_b*bs*s_R*Rs) / (s_g*gs*s_R)

    equations = [
        D(V) ~ (s_g * g * (s_V * V - (s_V)^3 * V^3 / 3 + s_R * R)) / s_V,
        D(R) ~ (s_V * V - s_a * a + s_b * b * s_R * R) / (s_g * g * s_R),
    ]
    measured_quantities = [y1 ~ s_V * V]

    model, mq = create_ordered_ode_system("fitzhugh_nagumo_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "fitzhugh_nagumo_scaled", model, mq, nothing,
        [0.0, 0.03], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 16: Repressilator (scaled)
# Original: beta=2.0, n=2.0, alpha=1.0
#           m1(0)=0→0.25, m2(0)=0→0.25, m3(0)=0→0.25
#           p1(0)=2.0, p2(0)=1.0, p3(0)=3.0
# Scale factors: s_beta=4.0, s_n=4.0, s_alpha=2.0
#   s_m1=0.5, s_m2=0.5, s_m3=0.5, s_p1=4.0, s_p2=2.0, s_p3=6.0
function repressilator_scaled()
    parameters = @parameters beta n alpha
    states = @variables m1(t) m2(t) m3(t) p1(t) p2(t) p3(t)
    observables = @variables y1(t) y2(t) y3(t)
    p_true = [0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]

    s_beta = 4.0; s_n = 4.0; s_alpha = 2.0
    s_m1 = 0.5; s_m2 = 0.5; s_m3 = 0.5
    s_p1 = 4.0; s_p2 = 2.0; s_p3 = 6.0

    # Original: D(m1) = -m1 + beta/(1 + p3*n)
    # s_m1*D(m1s) = -(s_m1*m1s) + (s_beta*betas)/(1 + (s_p3*p3s)*(s_n*ns))
    # D(m1s) = -m1s + (s_beta*betas)/((1 + s_p3*s_n*p3s*ns)*s_m1)
    #
    # Original: D(p1) = -alpha*(p1 - m1)
    # s_p1*D(p1s) = -(s_alpha*alphas)*(s_p1*p1s - s_m1*m1s)
    # D(p1s) = -(s_alpha*alphas)*(p1s - (s_m1/s_p1)*m1s)

    equations = [
        D(m1) ~ -m1 + (s_beta * beta) / ((1 + s_p3 * s_n * p3 * n) * s_m1),
        D(m2) ~ -m2 + (s_beta * beta) / ((1 + s_p1 * s_n * p1 * n) * s_m2),
        D(m3) ~ -m3 + (s_beta * beta) / ((1 + s_p2 * s_n * p2 * n) * s_m3),
        D(p1) ~ -(s_alpha * alpha) * (p1 - (s_m1 / s_p1) * m1),
        D(p2) ~ -(s_alpha * alpha) * (p2 - (s_m2 / s_p2) * m2),
        D(p3) ~ -(s_alpha * alpha) * (p3 - (s_m3 / s_p3) * m3),
    ]

    measured_quantities = [y1 ~ s_p1 * p1, y2 ~ s_p2 * p2, y3 ~ s_p3 * p3]

    model, mq = create_ordered_ode_system("repressilator_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "repressilator_scaled", model, mq, nothing,
        [0.0, 24.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 17: HIV Immune Dynamics (scaled)
# Original: lm=1.0, d=0.01, beta=2e-5, a=0.5, k=50.0, u=3.0, c=0.05, q=0.1, b=0.002, h=0.1
#           x(0)=1000, y(0)=1.0, v(0)=1e-3, w(0)=1.0, z(0)=0→0.5
# Scale factors: s_lm=2.0, s_d=0.02, s_beta=4e-5, s_a=1.0, s_k=100.0
#                s_u=6.0, s_c=0.1, s_q=0.2, s_b=0.004, s_h=0.2
#                s_x=2000, s_y=2.0, s_v=0.002, s_w=2.0, s_z=1.0
function hiv_scaled()
    parameters = @parameters lm d beta a k u c q b h
    states = @variables x(t) y(t) v(t) w(t) z(t)
    observables = @variables y1(t) y2(t) y3(t) y4(t)
    p_true = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5, 0.5]

    s_lm = 2.0; s_d = 0.02; s_beta = 4e-5; s_a = 1.0; s_k = 100.0
    s_u = 6.0; s_c = 0.1; s_q = 0.2; s_b = 0.004; s_h = 0.2
    s_x = 2000.0; s_y = 2.0; s_v = 0.002; s_w = 2.0; s_z = 1.0

    equations = [
        # D(x_s) = [lm_orig - d_orig*x_orig - beta_orig*x_orig*v_orig] / s_x
        D(x) ~ (s_lm * lm - s_d * d * s_x * x - s_beta * beta * s_x * x * s_v * v) / s_x,
        # D(y_s) = [beta_orig*x_orig*v_orig - a_orig*y_orig] / s_y
        D(y) ~ (s_beta * beta * s_x * x * s_v * v - s_a * a * s_y * y) / s_y,
        # D(v_s) = [k_orig*y_orig - u_orig*v_orig] / s_v
        D(v) ~ (s_k * k * s_y * y - s_u * u * s_v * v) / s_v,
        # D(w_s) = [c_orig*z_orig*y_orig*w_orig - c_orig*q_orig*y_orig*w_orig - b_orig*w_orig] / s_w
        D(w) ~ (s_c * c * s_z * z * s_y * y * s_w * w - s_c * c * s_q * q * s_y * y * s_w * w - s_b * b * s_w * w) / s_w,
        # D(z_s) = [c_orig*q_orig*y_orig*w_orig - h_orig*z_orig] / s_z
        D(z) ~ (s_c * c * s_q * q * s_y * y * s_w * w - s_h * h * s_z * z) / s_z,
    ]

    # y1~w_orig, y2~z_orig, y3~x_orig, y4~y_orig+v_orig
    measured_quantities = [
        y1 ~ s_w * w,
        y2 ~ s_z * z,
        y3 ~ s_x * x,
        y4 ~ s_y * y + s_v * v,
    ]

    model, mq = create_ordered_ode_system("hiv_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "hiv_scaled", model, mq, nothing,
        [0.0, 25.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#          SECTION F: PHARMACOKINETICS / COMPARTMENTAL (2)
# =============================================================================

# Model 18: DAISY Mamillary 4-Compartment (scaled)
# Original: k01=0.125, k12=0.25, k13=0.375, k14=0.5, k21=0.625, k31=0.75, k41=0.875
#           x1(0)=0.2, x2(0)=0.4, x3(0)=0.6, x4(0)=0.8
# Scale factors: s_k01=0.25, s_k12=0.5, s_k13=0.75, s_k14=1.0, s_k21=1.25, s_k31=1.5, s_k41=1.75
#                s_x1=0.4, s_x2=0.8, s_x3=1.2, s_x4=1.6
function daisy_mamil4_scaled()
    parameters = @parameters k01 k12 k13 k14 k21 k31 k41
    states = @variables x1(t) x2(t) x3(t) x4(t)
    observables = @variables y1(t) y2(t) y3(t)
    p_true = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5]

    s_k01 = 0.25; s_k12 = 0.5; s_k13 = 0.75; s_k14 = 1.0
    s_k21 = 1.25; s_k31 = 1.5; s_k41 = 1.75
    s_x1 = 0.4; s_x2 = 0.8; s_x3 = 1.2; s_x4 = 1.6

    equations = [
        # D(x1_s) = [-k01_o*x1_o + k12_o*x2_o + k13_o*x3_o + k14_o*x4_o - k21_o*x1_o - k31_o*x1_o - k41_o*x1_o] / s_x1
        D(x1) ~ (-s_k01 * k01 * s_x1 * x1 + s_k12 * k12 * s_x2 * x2 + s_k13 * k13 * s_x3 * x3 + s_k14 * k14 * s_x4 * x4 - s_k21 * k21 * s_x1 * x1 - s_k31 * k31 * s_x1 * x1 - s_k41 * k41 * s_x1 * x1) / s_x1,
        # D(x2_s) = [-k12_o*x2_o + k21_o*x1_o] / s_x2
        D(x2) ~ (-s_k12 * k12 * s_x2 * x2 + s_k21 * k21 * s_x1 * x1) / s_x2,
        # D(x3_s) = [-k13_o*x3_o + k31_o*x1_o] / s_x3
        D(x3) ~ (-s_k13 * k13 * s_x3 * x3 + s_k31 * k31 * s_x1 * x1) / s_x3,
        # D(x4_s) = [-k14_o*x4_o + k41_o*x1_o] / s_x4
        D(x4) ~ (-s_k14 * k14 * s_x4 * x4 + s_k41 * k41 * s_x1 * x1) / s_x4,
    ]

    # y1 ~ x1_orig, y2 ~ x2_orig, y3 ~ x3_orig + x4_orig
    measured_quantities = [y1 ~ s_x1 * x1, y2 ~ s_x2 * x2, y3 ~ s_x3 * x3 + s_x4 * x4]

    model, mq = create_ordered_ode_system("DAISY_mamil4_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "daisy_mamil4_scaled", model, mq, nothing,
        nothing, nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 19: Two-Compartment Pharmacokinetics (scaled)
# Original: k12=0.5, k21=0.25, ke=0.15, V1=1.0, V2=2.0
#           C1(0)=10.0, C2(0)=0→0.5
# Scale factors: s_k12=1.0, s_k21=0.5, s_ke=0.3, s_V1=2.0, s_V2=4.0
#                s_C1=20.0, s_C2=1.0
function two_compartment_pk_scaled()
    parameters = @parameters k12 k21 ke V1 V2
    states = @variables C1(t) C2(t)
    observables = @variables y1(t)
    p_true = [0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5]

    s_k12 = 1.0; s_k21 = 0.5; s_ke = 0.3; s_V1 = 2.0; s_V2 = 4.0
    s_C1 = 20.0; s_C2 = 1.0

    equations = [
        # D(C1_s) = [-k12_o*C1_o + k21_o*C2_o*V2_o/V1_o - ke_o*C1_o] / s_C1
        D(C1) ~ (-s_k12 * k12 * s_C1 * C1 + s_k21 * k21 * s_C2 * C2 * s_V2 * V2 / (s_V1 * V1) - s_ke * ke * s_C1 * C1) / s_C1,
        # D(C2_s) = [k12_o*C1_o*V1_o/V2_o - k21_o*C2_o] / s_C2
        D(C2) ~ (s_k12 * k12 * s_C1 * C1 * s_V1 * V1 / (s_V2 * V2) - s_k21 * k21 * s_C2 * C2) / s_C2,
    ]
    measured_quantities = [y1 ~ s_C1 * C1]

    model, mq = create_ordered_ode_system("two_compartment_pk_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "two_compartment_pk_scaled", model, mq, nothing,
        [0.0, 48.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#             SECTION G: CHALLENGING LARGE-SCALE (1)
# =============================================================================

# Model 20: Crauste Corrected (scaled)
# Original params: mu_N=0.75, mu_EE=2.16e-5, mu_LE=3.6e-8, mu_LL=7.5e-6,
#   mu_M=0 (DROPPED), mu_P=0.055, mu_PE=1.8e-7, mu_PL=1.8e-5,
#   delta_NE=0.009, delta_EL=0.59, delta_LM=0.025, rho_E=0.64, rho_P=0.15
# Original ICs: N=8090, E=0→5, L=0→5, M=0→5, P=1.0
# mu_M=0: hardcoded as 0 in equation (dropped from parameter set)
# Scale factors computed as 2*original_value for each
function crauste_corrected_scaled()
    # mu_M hardcoded to 0 — removed from parameter list (12 estimated params)
    parameters = @parameters mu_N mu_EE mu_LE mu_LL mu_P mu_PE mu_PL delta_NE delta_EL delta_LM rho_E rho_P
    states = @variables N(t) E(t) L(t) M(t) P(t)
    observables = @variables y1(t) y2(t) y3(t) y4(t)
    p_true = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5, 0.5]

    # Scale factors
    s_muN = 1.5; s_muEE = 4.32e-5; s_muLE = 7.2e-8; s_muLL = 1.5e-5
    s_muP = 0.11; s_muPE = 3.6e-7; s_muPL = 3.6e-5
    s_dNE = 0.018; s_dEL = 1.18; s_dLM = 0.05; s_rhoE = 1.28; s_rhoP = 0.3
    s_N = 16180.0; s_E = 10.0; s_L = 10.0; s_M = 10.0; s_P = 2.0

    equations = [
        # D(N_s) = [-N_o*mu_N_o - N_o*P_o*delta_NE_o] / s_N
        D(N) ~ (-(s_N * N) * (s_muN * mu_N) - (s_N * N) * (s_P * P) * (s_dNE * delta_NE)) / s_N,
        # D(E_s) = [N_o*P_o*delta_NE_o + E_o*(rho_E_o*P_o - mu_EE_o*E_o - delta_EL_o)] / s_E
        D(E) ~ ((s_N * N) * (s_P * P) * (s_dNE * delta_NE) + (s_E * E) * ((s_rhoE * rho_E) * (s_P * P) - (s_muEE * mu_EE) * (s_E * E) - (s_dEL * delta_EL))) / s_E,
        # D(L_s) = [delta_EL_o*E_o - L_o*(mu_LL_o*L_o + mu_LE_o*E_o + delta_LM_o)] / s_L
        D(L) ~ ((s_dEL * delta_EL) * (s_E * E) - (s_L * L) * ((s_muLL * mu_LL) * (s_L * L) + (s_muLE * mu_LE) * (s_E * E) + (s_dLM * delta_LM))) / s_L,
        # D(M_s) = [L_o*delta_LM_o] / s_M  (mu_M=0, term removed entirely)
        D(M) ~ ((s_L * L) * (s_dLM * delta_LM)) / s_M,
        # D(P_s) = [P_o*(rho_P_o*P_o - mu_PE_o*E_o - mu_PL_o*L_o - mu_P_o)] / s_P
        D(P) ~ ((s_P * P) * ((s_rhoP * rho_P) * (s_P * P) - (s_muPE * mu_PE) * (s_E * E) - (s_muPL * mu_PL) * (s_L * L) - (s_muP * mu_P))) / s_P,
    ]

    measured_quantities = [y1 ~ s_N * N, y2 ~ s_E * E, y3 ~ s_L * L + s_M * M, y4 ~ s_P * P]

    model, mq = create_ordered_ode_system("crauste_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "crauste_corrected_scaled", model, mq, nothing,
        [0.0, 25.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
#                   SECTION H: EXTENDED SET (5)
# =============================================================================

# Model 21: Forced Lotka-Volterra with Sinusoidal Harvesting (scaled)
# Original: alpha=1.5, beta=1.0, delta=0.5, gamma=3.0
#           x(0)=1.0, y(0)=1.0
# Scale factors: s_al=3.0, s_be=2.0, s_de=1.0, s_ga=6.0, s_x=2.0, s_y=2.0
function forced_lv_sinusoidal_scaled()
    @parameters alpha beta delta gamma
    h_val = 0.3; omega_val = 2.0

    @variables x(t) y(t)
    @variables y1(t) y2(t)
    p_true = [0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5]

    s_al = 3.0; s_be = 2.0; s_de = 1.0; s_ga = 6.0; s_x = 2.0; s_y = 2.0

    equations = [
        # D(x_s) = [alpha_o*x_o - beta_o*x_o*y_o - h*sin(omega*t)] / s_x
        D(x) ~ (s_al * alpha * s_x * x - s_be * beta * s_x * x * s_y * y - h_val * sin(omega_val * t)) / s_x,
        # D(y_s) = [delta_o*x_o*y_o - gamma_o*y_o] / s_y
        D(y) ~ (s_de * delta * s_x * x * s_y * y - s_ga * gamma * s_y * y) / s_y,
    ]
    measured_quantities = [y1 ~ s_x * x, y2 ~ s_y * y]

    states = [x, y]
    parameters = [alpha, beta, delta, gamma]
    model, mq = create_ordered_ode_system("forced_lv_sinusoidal_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "forced_lv_sinusoidal_scaled", model, mq, nothing,
        [0.0, 5.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 22: Treatment (SEIR + Intervention) (scaled)
# Original: a=0.1, b=0.8, d=2.0, g=0.3, nu=0.1
#           In(0)=50, N(0)=1000, S(0)=950, Tr(0)=0→5
# Scale factors: s_a=0.2, s_b=1.6, s_d=4.0, s_g=0.6, s_nu=0.2
#                s_In=100, s_N=2000, s_S=1900, s_Tr=10
function treatment_scaled()
    parameters = @parameters a b d g nu
    states = @variables In(t) N(t) S(t) Tr(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5]

    s_a = 0.2; s_b = 1.6; s_d = 4.0; s_g = 0.6; s_nu = 0.2
    s_In = 100.0; s_N = 2000.0; s_S = 1900.0; s_Tr = 10.0

    equations = [
        # D(In_s) = [b_o*S_o*In_o/N_o + d_o*b_o*S_o*Tr_o/N_o - (a_o+g_o)*In_o] / s_In
        D(In) ~ ((s_b * b) * (s_S * S) * (s_In * In) / (s_N * N) + (s_d * d) * (s_b * b) * (s_S * S) * (s_Tr * Tr) / (s_N * N) - ((s_a * a) + (s_g * g)) * (s_In * In)) / s_In,
        D(N) ~ 0,
        # D(S_s) = [-b_o*S_o*In_o/N_o - d_o*b_o*S_o*Tr_o/N_o] / s_S
        D(S) ~ (-(s_b * b) * (s_S * S) * (s_In * In) / (s_N * N) - (s_d * d) * (s_b * b) * (s_S * S) * (s_Tr * Tr) / (s_N * N)) / s_S,
        # D(Tr_s) = [g_o*In_o - nu_o*Tr_o] / s_Tr
        D(Tr) ~ ((s_g * g) * (s_In * In) - (s_nu * nu) * (s_Tr * Tr)) / s_Tr,
    ]
    measured_quantities = [y1 ~ s_Tr * Tr, y2 ~ s_N * N]

    model, mq = create_ordered_ode_system("treatment_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "treatment_scaled", model, mq, nothing, nothing,
        [0.0, 40.0],
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 6,
    )
end

# Model 23: SIRS with Periodic Forcing (scaled)
# Original: b0=0.143, b1=0.286, g=0.429, M=0.571, mu=0.714, nu=0.857
#           i(0)=0.167, r(0)=0.333, s(0)=0.5, x1(0)=0.667, x2(0)=0.833
# Already near 0.5! Scale factors close to 1.
# Scale factors: s_b0=0.286, s_b1=0.572, s_g=0.858, s_M=1.142, s_mu=1.428, s_nu=1.714
#                s_i=0.334, s_r=0.666, s_s=1.0, s_x1=1.334, s_x2=1.666
function sirsforced_scaled()
    parameters = @parameters b0 b1 g M mu nu
    states = @variables i(t) r(t) s(t) x1(t) x2(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5, 0.5]

    s_b0 = 0.286; s_b1 = 0.572; s_g = 0.858; s_M = 1.142; s_mu = 1.428; s_nu = 1.714
    s_i = 0.334; s_r = 0.666; s_s = 1.0; s_x1 = 1.334; s_x2 = 1.666

    equations = [
        # D(i_s) = [b0_o*(1+b1_o*x1_o)*i_o*s_o - (nu_o+mu_o)*i_o] / s_i
        D(i) ~ ((s_b0 * b0) * (1.0 + (s_b1 * b1) * (s_x1 * x1)) * (s_i * i) * (s_s * s) - ((s_nu * nu) + (s_mu * mu)) * (s_i * i)) / s_i,
        # D(r_s) = [nu_o*i_o - (mu_o+g_o)*r_o] / s_r
        D(r) ~ ((s_nu * nu) * (s_i * i) - ((s_mu * mu) + (s_g * g)) * (s_r * r)) / s_r,
        # D(s_s) = [mu_o - mu_o*s_o - b0_o*(1+b1_o*x1_o)*i_o*s_o + g_o*r_o] / s_s
        D(s) ~ ((s_mu * mu) - (s_mu * mu) * (s_s * s) - (s_b0 * b0) * (1.0 + (s_b1 * b1) * (s_x1 * x1)) * (s_i * i) * (s_s * s) + (s_g * g) * (s_r * r)) / s_s,
        # D(x1_s) = [-M_o*x2_o] / s_x1
        D(x1) ~ (-(s_M * M) * (s_x2 * x2)) / s_x1,
        # D(x2_s) = [M_o*x1_o] / s_x2
        D(x2) ~ ((s_M * M) * (s_x1 * x1)) / s_x2,
    ]
    measured_quantities = [y1 ~ s_i * i, y2 ~ s_r * r]

    model, mq = create_ordered_ode_system("sirsforced_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "sirsforced_scaled", model, mq, nothing,
        [0.0, 30.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 3,
    )
end

# Model 24: Slow-Fast Chemical Cascade (scaled)
# Original: k1=0.25, k2=0.5
#           xA(0)=0.166, xB(0)=0.333, xC(0)=0.5, eA(0)=0.666, eC(0)=0.833, eB(0)=0.75
# Already near 0.5! Minimal scaling needed.
# Scale factors: s_k1=0.5, s_k2=1.0
#   s_xA=0.332, s_xB=0.666, s_xC=1.0, s_eA=1.332, s_eC=1.666, s_eB=1.5
function slowfast_scaled()
    parameters = @parameters k1 k2
    states = @variables xA(t) xB(t) xC(t) eA(t) eC(t) eB(t)
    observables = @variables y1(t) y2(t) y3(t) y4(t)
    p_true = [0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]

    s_k1 = 0.5; s_k2 = 1.0
    s_xA = 0.332; s_xB = 0.666; s_xC = 1.0
    s_eA = 1.332; s_eC = 1.666; s_eB = 1.5

    equations = [
        # D(xA_s) = [-k1_o*xA_o] / s_xA
        D(xA) ~ (-(s_k1 * k1) * (s_xA * xA)) / s_xA,
        # D(xB_s) = [k1_o*xA_o - k2_o*xB_o] / s_xB
        D(xB) ~ ((s_k1 * k1) * (s_xA * xA) - (s_k2 * k2) * (s_xB * xB)) / s_xB,
        # D(xC_s) = [k2_o*xB_o] / s_xC
        D(xC) ~ ((s_k2 * k2) * (s_xB * xB)) / s_xC,
        D(eA) ~ 0,
        D(eC) ~ 0,
        D(eB) ~ 0,
    ]

    # y1 ~ xC_orig, y2 ~ eA_orig*xA_orig + eB_orig*xB_orig + eC_orig*xC_orig
    # y3 ~ eA_orig, y4 ~ eC_orig
    measured_quantities = [
        y1 ~ s_xC * xC,
        y2 ~ (s_eA * eA) * (s_xA * xA) + (s_eB * eB) * (s_xB * xB) + (s_eC * eC) * (s_xC * xC),
        y3 ~ s_eA * eA,
        y4 ~ s_eC * eC,
    ]

    model, mq = create_ordered_ode_system("slowfast_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "slowfast_scaled", model, mq, nothing,
        [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 25: Magnetic Levitation with Sinusoidal Voltage (scaled)
# Original: m_lin=0.1, k_lin=50.0, b_lin=2.0
#           x(0)=0→0.005, v(0)=0→0.025, i(0)=2.5 (=V0/R_coil)
# Scale factors: s_mlin=0.2, s_klin=100.0, s_blin=4.0
#                s_x=0.01, s_v=0.05, s_i=5.0
# Fixed: R_coil=2.0, L=0.05, ki=10.0, V0=5.0, Va=1.0, omega=5.0
function magnetic_levitation_sinusoidal_scaled()
    @parameters m_lin k_lin b_lin
    R_coil_val = 2.0; L_val = 0.05; ki_val = 10.0
    V0_val = 5.0; Va_val = 1.0; omega_val = 5.0

    @variables x(t) v(t) i(t)
    @variables y1(t)
    p_true = [0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5]

    s_mlin = 0.2; s_klin = 100.0; s_blin = 4.0
    s_x = 0.01; s_v = 0.05; s_i = 5.0

    i_eq = V0_val / R_coil_val  # = 2.5
    V_input = V0_val + Va_val * sin(omega_val * t)

    equations = [
        # D(x_s) = (s_v/s_x)*v_s
        D(x) ~ (s_v / s_x) * v,
        # D(v_s) = [ki*(i_orig - i_eq) - k_lin_o*x_orig - b_lin_o*v_orig] / (m_lin_o * s_v)
        D(v) ~ (ki_val * (s_i * i - i_eq) - s_klin * k_lin * s_x * x - s_blin * b_lin * s_v * v) / (s_mlin * m_lin * s_v),
        # D(i_s) = (V_input - R_coil*i_orig) / (L*s_i)
        D(i) ~ (V_input - R_coil_val * s_i * i) / (L_val * s_i),
    ]
    measured_quantities = [y1 ~ s_x * x]

    states = [x, v, i]
    parameters = [m_lin, k_lin, b_lin]
    model, mq = create_ordered_ode_system("magnetic_levitation_sinusoidal_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "magnetic_levitation_sinusoidal_scaled", model, mq, nothing,
        [0.0, 5.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# Model 26: DAISY mamil3 (scaled)
# Original: a12=0.167, a13=0.333, a21=0.5, a31=0.667, a01=0.833
#           x1(0)=0.25, x2(0)=0.5, x3(0)=0.75
# Scale factors: s_a12=0.334, s_a13=0.666, s_a21=1.0, s_a31=1.334, s_a01=1.666
#                s_x1=0.5, s_x2=1.0, s_x3=1.5
# Original eqs (linear compartmental):
#   D(x1) = -(a21+a31+a01)*x1 + a12*x2 + a13*x3
#   D(x2) = a21*x1 - a12*x2
#   D(x3) = a31*x1 - a13*x3
# Scaling: substitute p_orig=s_p*p_s, x_orig=s_x*x_s, divide by s_xi for eq i
# D(x1s): [-(s_a21*a21s + s_a31*a31s + s_a01*a01s)*(s_x1*x1s) + s_a12*a12s*(s_x2*x2s) + s_a13*a13s*(s_x3*x3s)] / s_x1
#        = -(1.0*a21 + 1.334*a31 + 1.666*a01)*x1 + (0.334*1.0/0.5)*a12*x2 + (0.666*1.5/0.5)*a13*x3
#        = -(1.0*a21 + 1.334*a31 + 1.666*a01)*x1 + 0.668*a12*x2 + 1.998*a13*x3
# D(x2s): [s_a21*a21s*(s_x1*x1s) - s_a12*a12s*(s_x2*x2s)] / s_x2
#        = (1.0*0.5/1.0)*a21*x1 - 0.334*a12*x2
#        = 0.5*a21*x1 - 0.334*a12*x2
# D(x3s): [s_a31*a31s*(s_x1*x1s) - s_a13*a13s*(s_x3*x3s)] / s_x3
#        = (1.334*0.5/1.5)*a31*x1 - (0.666*1.5/1.5)*a13*x3
#        = 0.4446666...*a31*x1 - 0.666*a13*x3
# Measurements: y1 ~ x1_orig = 0.5*x1s, y2 ~ x2_orig = 1.0*x2s
function daisy_mamil3_scaled()
    parameters = @parameters a12 a13 a21 a31 a01
    states = @variables x1(t) x2(t) x3(t)
    observables = @variables y1(t) y2(t)
    p_true = [0.5, 0.5, 0.5, 0.5, 0.5]
    ic_true = [0.5, 0.5, 0.5]

    # Scale factors
    s_a12 = 2.0 * 0.167; s_a13 = 2.0 * 0.333; s_a21 = 2.0 * 0.5; s_a31 = 2.0 * 0.667; s_a01 = 2.0 * 0.833
    s_x1 = 2.0 * 0.25; s_x2 = 2.0 * 0.5; s_x3 = 2.0 * 0.75

    equations = [
        D(x1) ~ (-(s_a21 * a21 + s_a31 * a31 + s_a01 * a01) * (s_x1 * x1) + s_a12 * a12 * (s_x2 * x2) + s_a13 * a13 * (s_x3 * x3)) / s_x1,
        D(x2) ~ (s_a21 * a21 * (s_x1 * x1) - s_a12 * a12 * (s_x2 * x2)) / s_x2,
        D(x3) ~ (s_a31 * a31 * (s_x1 * x1) - s_a13 * a13 * (s_x3 * x3)) / s_x3,
    ]
    measured_quantities = [y1 ~ s_x1 * x1, y2 ~ s_x2 * x2]

    model, mq = create_ordered_ode_system("daisy_mamil3_scaled", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem(
        "daisy_mamil3_scaled", model, mq, nothing,
        [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true), 0,
    )
end

# =============================================================================
# Model registry for easy access
# =============================================================================
const SCALED_MODELS = Dict(
    :harmonic => harmonic_scaled,
    :lotka_volterra => lotka_volterra_scaled,
    :vanderpol => vanderpol_scaled,
    :brusselator => brusselator_scaled,
    :cstr_fixed_activation => cstr_fixed_activation_scaled,
    :biohydrogenation => biohydrogenation_scaled,
    :mass_spring_damper => mass_spring_damper_scaled,
    :dc_motor_sinusoidal => dc_motor_sinusoidal_scaled,
    :flexible_arm => flexible_arm_scaled,
    :aircraft_pitch_sinusoidal => aircraft_pitch_sinusoidal_scaled,
    :bicycle_model_sinusoidal => bicycle_model_sinusoidal_scaled,
    :quadrotor_sinusoidal => quadrotor_sinusoidal_scaled,
    :boost_converter_sinusoidal => boost_converter_sinusoidal_scaled,
    :seir => seir_scaled,
    :fitzhugh_nagumo => fitzhugh_nagumo_scaled,
    :repressilator => repressilator_scaled,
    :hiv => hiv_scaled,
    :daisy_mamil4 => daisy_mamil4_scaled,
    :two_compartment_pk => two_compartment_pk_scaled,
    :crauste_corrected => crauste_corrected_scaled,
    :forced_lv_sinusoidal => forced_lv_sinusoidal_scaled,
    :treatment => treatment_scaled,
    :sirsforced => sirsforced_scaled,
    :slowfast => slowfast_scaled,
    :magnetic_levitation_sinusoidal => magnetic_levitation_sinusoidal_scaled,
    :daisy_mamil3 => daisy_mamil3_scaled,
)
