### StructuralIdentifiability cross-check for ALL 23 wallaby benchmark systems.
### Supplements cluster Claude's results/wallaby_analysis/multiplicity/run_sian_polynomial_only.jl
### (which covered the 16 polynomial systems) by adding @ODEmodel blocks for the
### 7 sin(t)-using systems via the same polynomialization convention used in
### ODEPE's src/examples/models/polynomialized/ (u_sin/u_cos aux-state oscillator,
### u_sin/u_cos as OBSERVED outputs — equivalent to "sin(omega*t) is a known
### function of time" for identifiability purposes).
###
### The 16 polynomial blocks below are copied verbatim from cluster's script so
### we get an immediate sanity check (their verdicts must match).
###
### Empirical multiplicity claims being cross-checked (from cluster's MULTIPLICITY_FINDINGS.md):
###   daisy_mamil4: empirical 2  -> expect >= 1 :locally
###   seir:         empirical 2  -> expect >= 1 :locally
###   slow_fast:    empirical 2  -> expect >= 1 :locally
###   biohydrogenation: empirical 1 but SI says >=2 in identifiable subspace (x7 unident)
###   All other 19: empirical 1  -> expect all :globally (or nonidentifiable for known
###                                  cases like aircraft_pitch.theta, quadrotor.g)
###
### Run with:
###   julia --startup-file=no repro/multiplicity_complete_2026_05_19/run_sian_all_23.jl

using StructuralIdentifiability
using Logging

const SEP = "=" ^ 80
const SUMMARY = Dict{String, Dict{String, Symbol}}()
const ERRORS = Dict{String, String}()

function run_one(name::String, ode)
    println()
    println(SEP)
    println(name)
    println(SEP)
    try
        t0 = time()
        res = StructuralIdentifiability.assess_identifiability(ode; loglevel=Logging.Warn)
        dt = time() - t0
        sys_summary = Dict{String, Symbol}()
        keys_sorted = sort(collect(keys(res)); by = x -> string(x))
        for k in keys_sorted
            v = res[k]
            ks = string(k)
            println("  $ks => $v")
            sys_summary[ks] = v
        end
        println("[time: $(round(dt; digits=2)) s]")
        SUMMARY[name] = sys_summary
    catch e
        println("ERROR: $e")
        ERRORS[name] = string(e)
    end
end

###############################################################################
# === 16 systems from cluster's run_sian_polynomial_only.jl (verbatim) ===
###############################################################################

ode_biohydrogenation = StructuralIdentifiability.@ODEmodel(
    x5'(t) = ((-0.3*k7*x5(t)) / (2.0*k8 + 0.5*x6(t) + 0.5*x5(t)) + (8.0*k5*x4(t)) / (4.0*k6 + 8.0*x4(t))) / 0.5,
    x7'(t) = (0.2*(10.0*k10 - 0.5*x6(t))*k9*x6(t)) / (5.0*k10),
    x4'(t) = (-8.0*k5*x4(t)) / (8.0*(4.0*k6 + 8.0*x4(t))),
    x6'(t) = ((-0.2*(10.0*k10 - 0.5*x6(t))*k9*x6(t)) / (10.0*k10) + (0.3*k7*x5(t)) / (2.0*k8 + 0.5*x6(t) + 0.5*x5(t))) / 0.5,
    y1(t) = 8.0*x4(t),
    y2(t) = 0.5*x5(t)
)
run_one("biohydrogenation", ode_biohydrogenation)

ode_brusselator = StructuralIdentifiability.@ODEmodel(
    Yc'(t) = 6.0*b*X(t) - 16.0*a*Yc(t)*(X(t)^2),
    X'(t) = 0.5 - 0.5*X(t) - 3.0*b*X(t) + 16.0*a*Yc(t)*(X(t)^2),
    y1(t) = 2.0*X(t),
    y2(t) = 2.0*Yc(t)
)
run_one("brusselator", ode_brusselator)

ode_crauste = StructuralIdentifiability.@ODEmodel(
    M'(t) = 0.05*delta_LM*L(t),
    P'(t) = (-0.11*mu_P - 3.6e-6*mu_PE*E(t) - 0.00036*mu_PL*L(t) + 0.6*rho_P*P(t))*P(t),
    Npop'(t) = (-24270.0*mu_N*Npop(t) - 582.4799999999999*delta_NE*P(t)*Npop(t)) / 16180.0,
    L'(t) = (11.799999999999999*delta_EL*E(t) - 10.0*(0.05*delta_LM + 7.2e-7*mu_LE*E(t) + 0.00015000000000000001*mu_LL*L(t))*L(t)) / 10.0,
    E'(t) = (582.4799999999999*delta_NE*P(t)*Npop(t) + 10.0*(-1.18*delta_EL - 0.000432*mu_EE*E(t) + 2.56*rho_E*P(t))*E(t)) / 10.0,
    y1(t) = 16180.0*Npop(t),
    y2(t) = 10.0*E(t),
    y3(t) = 10.0*M(t) + 10.0*L(t),
    y4(t) = 2.0*P(t)
)
run_one("crauste", ode_crauste)

ode_daisy_mamil3 = StructuralIdentifiability.@ODEmodel(
    x1'(t) = (0.5*(-1.666*a01 - a21 - 1.334*a31)*x1(t) + 0.334*a12*x2(t) + 0.9990000000000001*a13*x3(t)) / 0.5,
    x2'(t) = -0.334*a12*x2(t) + 0.5*a21*x1(t),
    x3'(t) = (-0.9990000000000001*a13*x3(t) + 0.667*a31*x1(t)) / 1.5,
    y1(t) = 0.5*x1(t),
    y2(t) = x2(t)
)
run_one("daisy_mamil3", ode_daisy_mamil3)

ode_daisy_mamil4 = StructuralIdentifiability.@ODEmodel(
    x1'(t) = (-0.1*k01*x1(t) + 0.4*k12*x2(t) + 0.8999999999999999*k13*x3(t) + 1.6*k14*x4(t) - 0.5*k21*x1(t) - 0.6000000000000001*k31*x1(t) - 0.7000000000000001*k41*x1(t)) / 0.4,
    x4'(t) = (-1.6*k14*x4(t) + 0.7000000000000001*k41*x1(t)) / 1.6,
    x2'(t) = (-0.4*k12*x2(t) + 0.5*k21*x1(t)) / 0.8,
    x3'(t) = (-0.8999999999999999*k13*x3(t) + 0.6000000000000001*k31*x1(t)) / 1.2,
    y1(t) = 0.4*x1(t),
    y2(t) = 0.8*x2(t),
    y3(t) = 1.2*x3(t) + 1.6*x4(t)
)
run_one("daisy_mamil4", ode_daisy_mamil4)

ode_fitzhugh_nagumo = StructuralIdentifiability.@ODEmodel(
    Vm'(t) = (-3.0)*g*(0.5*R(t) - 2.0*Vm(t) + (2.6666666666666665)*(Vm(t)^3)),
    R'(t) = (-0.4*a - 2.0*Vm(t) + 0.2*b*R(t)) / (3.0*g),
    y1(t) = -2.0*Vm(t)
)
run_one("fitzhugh_nagumo", ode_fitzhugh_nagumo)

ode_flexible_arm = StructuralIdentifiability.@ODEmodel(
    theta_t'(t) = omega_t(t),
    omega_m'(t) = (0.5 - 0.1*bm*omega_m(t) - 20.0*k*(-0.5*theta_t(t) + 0.5*theta_m(t))) / (0.1*Jm),
    omega_t'(t) = (-0.05*bt*omega_t(t) - 20.0*k*(0.5*theta_t(t) - 0.5*theta_m(t))) / (0.05*Jt),
    theta_m'(t) = omega_m(t),
    y1(t) = 0.5*theta_m(t),
    y2(t) = 0.5*theta_t(t)
)
run_one("flexible_arm", ode_flexible_arm)

ode_harmonic_oscillator = StructuralIdentifiability.@ODEmodel(
    x1'(t) = -a*x2(t),
    x2'(t) = x1(t) / b,
    y1(t) = 2.0*x1(t),
    y2(t) = x2(t)
)
run_one("harmonic_oscillator", ode_harmonic_oscillator)

ode_hiv = StructuralIdentifiability.@ODEmodel(
    vv'(t) = (200.0*k*yv(t) - 0.012*uu*vv(t)) / 0.002,
    w'(t) = (-0.008*b*w(t) - 0.08000000000000002*c*q*w(t)*yv(t) + 0.4*c*w(t)*z(t)*yv(t)) / 2.0,
    x'(t) = (2.0*lm - 40.0*d*x(t) - 0.00016*beta*x(t)*vv(t)) / 2000.0,
    z'(t) = -0.2*h*z(t) + 0.08000000000000002*c*q*w(t)*yv(t),
    yv'(t) = (-2.0*a*yv(t) + 0.00016*beta*x(t)*vv(t)) / 2.0,
    y1(t) = 2.0*w(t),
    y2(t) = z(t),
    y3(t) = 2000.0*x(t),
    y4(t) = 0.002*vv(t) + 2.0*yv(t)
)
run_one("hiv", ode_hiv)

ode_lotka_volterra = StructuralIdentifiability.@ODEmodel(
    w'(t) = -0.6*k3*w(t) + 4.0*k2*w(t)*r(t),
    r'(t) = 2.0*k1*r(t) - 2.0*k2*w(t)*r(t),
    y1(t) = 4.0*r(t)
)
run_one("lotka_volterra", ode_lotka_volterra)

ode_mass_spring_damper = StructuralIdentifiability.@ODEmodel(
    vel'(t) = (1.0 - 0.5*c*vel(t) - 8.0*k*x(t)) / m,
    x'(t) = 0.5*vel(t),
    y1(t) = x(t)
)
run_one("mass_spring_damper", ode_mass_spring_damper)

ode_repressilator = StructuralIdentifiability.@ODEmodel(
    m3'(t) = -m3(t) + (4.0*beta) / (0.5*(1 + 8.0*n*p2(t))),
    m2'(t) = -m2(t) + (4.0*beta) / (0.5*(1 + 16.0*n*p1(t))),
    p3'(t) = -2.0*alpha*(p3(t) - 0.08333333333333333*m3(t)),
    p2'(t) = -2.0*alpha*(-0.25*m2(t) + p2(t)),
    m1'(t) = -m1(t) + (4.0*beta) / (0.5*(1 + 24.0*n*p3(t))),
    p1'(t) = -2.0*alpha*(-0.125*m1(t) + p1(t)),
    y1(t) = 4.0*p1(t),
    y2(t) = 2.0*p2(t),
    y3(t) = 6.0*p3(t)
)
run_one("repressilator", ode_repressilator)

ode_seir = StructuralIdentifiability.@ODEmodel(
    S'(t) = (-15840.0*b*In(t)*S(t)) / (3960000.0*Npop(t)),
    E'(t) = ((15840.0*b*In(t)*S(t)) / (2000.0*Npop(t)) - 6.0*nu*E(t)) / 20.0,
    In'(t) = (-4.0*a*In(t) + 6.0*nu*E(t)) / 10.0,
    Npop'(t) = 0,
    y1(t) = 10.0*In(t),
    y2(t) = 2000.0*Npop(t)
)
run_one("seir", ode_seir)

ode_slow_fast = StructuralIdentifiability.@ODEmodel(
    eA'(t) = 0,
    xC'(t) = 0.666*k2*xB(t),
    eC'(t) = 0,
    xB'(t) = (0.166*k1*xA(t) - 0.666*k2*xB(t)) / 0.666,
    eB'(t) = 0,
    xA'(t) = -0.5*k1*xA(t),
    y1(t) = xC(t),
    y2(t) = 0.44222400000000006*xA(t)*eA(t) + 0.9990000000000001*eB(t)*xB(t) + 1.666*xC(t)*eC(t),
    y3(t) = 1.332*eA(t),
    y4(t) = 1.666*eC(t)
)
run_one("slow_fast", ode_slow_fast)

ode_sirt_treatment = StructuralIdentifiability.@ODEmodel(
    S'(t) = -0.08*b*S(t)*In(t)/Npop(t) - 0.032*d*b*S(t)*Tr(t)/Npop(t),
    Npop'(t) = 0,
    Tr'(t) = 6.0*g*In(t) - 0.2*nu*Tr(t),
    In'(t) = 1.52*b*S(t)*In(t)/Npop(t) + 0.608*d*b*S(t)*Tr(t)/Npop(t) - (0.2*a + 0.6*g)*In(t),
    y1(t) = 10.0*Tr(t),
    y2(t) = 2000.0*Npop(t),
    y3(t) = 10.0*In(t)
)
run_one("sirt_treatment", ode_sirt_treatment)

ode_vanderpol = StructuralIdentifiability.@ODEmodel(
    x1'(t) = 0.5*a*x2(t),
    x2'(t) = -4.0*x1(t) + 2.0*b*x2(t) - 32.0*b*x2(t)*(x1(t)^2),
    y1(t) = 4.0*x1(t),
    y2(t) = x2(t)
)
run_one("vanderpol", ode_vanderpol)

###############################################################################
# === 7 @ODEmodel blocks for sin(t) systems, transcribed verbatim from
#     wallaby script.jl bodies (NOT from src/examples/models/polynomialized/).
#
# Why not the *_poly() examples: wallaby cells declare a smaller, specific
# subset of parameters as symbolic and inline the rest as numeric constants.
# My earlier translation used the full *_poly() parameter set, which made the
# polynomial system much larger and (for bicycle_model) hit a Groebner.jl
# internal BoundsError. These blocks now match wallaby exactly.
#
# Convention: sin(omega*t) becomes a free input variable u_sin(t) (no state
# ODE for it). This mirrors ODEPE's runtime `transform_pep_for_estimation()`,
# which feeds _trfn_sin_X_Y to SI as an INPUT (see si_equation_builder.jl:172,
# `ODE{...}(state_eqn_dict, out_eqn_dict, inputs_)`).
###############################################################################

# --- aircraft_pitch (wallaby cell aircraft_pitch_0_0/script.jl)
# Free params: M_alpha, M_q, M_delta_e, Z_alpha; states: theta, q, alpha;
# Input: u_sin replaces sin(2.0*t); Observation: y1 = 0.05*q
ode_aircraft_pitch = StructuralIdentifiability.@ODEmodel(
    theta'(t) = q(t),
    q'(t) = (-M_alpha*alpha(t) - M_delta_e*u_sin(t) - 0.2*M_q*q(t)) / 0.05,
    alpha'(t) = (0.05*q(t) - 0.002*Z_alpha*alpha(t)) / 0.1,
    y1(t) = 0.05*q(t)
)
run_one("aircraft_pitch", ode_aircraft_pitch)

# --- bicycle_model (wallaby cell bicycle_model_0_0/script.jl)
# Free params: Cf, Cr, m_veh; states: vy, r; Input: u_sin (sin(0.5*t))
# Observations: y1=0.1*r, y2=0.5*vy
ode_bicycle_model = StructuralIdentifiability.@ODEmodel(
    vy'(t) = ((160000.0*Cf*(0.05*u_sin(t) + (-0.12*r(t) - 0.5*vy(t)) / 20.0) + 8000.0*Cr*(0.13999999999999999*r(t) - 0.5*vy(t))) / (3000.0*m_veh) - 2.0*r(t)) / 0.5,
    r'(t) = (192000.0*Cf*(0.05*u_sin(t) + (-0.12*r(t) - 0.5*vy(t)) / 20.0) - 11200.0*Cr*(0.13999999999999999*r(t) - 0.5*vy(t))) / 250.0,
    y1(t) = 0.1*r(t),
    y2(t) = 0.5*vy(t)
)
run_one("bicycle_model", ode_bicycle_model)

# --- boost_converter (wallaby cell boost_converter_0_0/script.jl)
# Free params: L, C_cap, R_load; states: iL, vC; Input: u_sin (sin(5.0*t))
ode_boost_converter = StructuralIdentifiability.@ODEmodel(
    iL'(t) = (12.0 - 48.0*(0.5 - 0.1*u_sin(t))*vC(t)) / (0.08*L),
    vC'(t) = ((-48.0*vC(t)) / (20.0*R_load) + 2.0*(0.5 - 0.1*u_sin(t))*iL(t)) / (1.92*C_cap),
    y1(t) = 48.0*vC(t),
    y2(t) = 2.0*iL(t)
)
run_one("boost_converter", ode_boost_converter)

# --- cstr (wallaby cell cstr_0_0/script.jl)
# Free params: tau, Tin, dH_rhoCP, UA_VrhoCP; states: C, Temp, r_eff; Input: u_sin (sin(0.5*t))
# Observation: y1 = 700.0*Temp
ode_cstr = StructuralIdentifiability.@ODEmodel(
    C'(t) = (1.0 - C(t)) / (2.0*tau) - 1.999863916554819*r_eff(t)*C(t),
    Temp'(t) = (Tin - Temp(t)) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff(t)*C(t) - 2.0*UA_VrhoCP*Temp(t) + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*u_sin(t),
    r_eff'(t) = 12.5*r_eff(t)/(Temp(t)^2)*((Tin - Temp(t)) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff(t)*C(t) - 2.0*UA_VrhoCP*Temp(t) + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*u_sin(t)),
    y1(t) = 700.0*Temp(t)
)
run_one("cstr", ode_cstr)

# --- dc_motor (wallaby cell dc_motor_0_0/script.jl)
# Free params: Kt, Jm; states: omega_m, i; Input: u_sin (sin(5.0*t))
ode_dc_motor = StructuralIdentifiability.@ODEmodel(
    omega_m'(t) = (0.2*Kt*i(t) - 0.1*omega_m(t)) / (0.02*Jm),
    i'(t) = (12.0 - 0.1*omega_m(t) - 2.0*i(t) + 2.0*u_sin(t)) / 0.5,
    y1(t) = omega_m(t)
)
run_one("dc_motor", ode_dc_motor)

# --- forced_lotka_volterra (wallaby cell forced_lotka_volterra_0_0/script.jl)
# Free params: alpha, beta, delta, gamma; states: x, yv; Input: u_sin (sin(2.0*t))
ode_forced_lotka_volterra = StructuralIdentifiability.@ODEmodel(
    x'(t) = (-0.3*u_sin(t) + 6.0*alpha*x(t) - 8.0*beta*x(t)*yv(t)) / 2.0,
    yv'(t) = (-12.0*gamma*yv(t) + 4.0*delta*x(t)*yv(t)) / 2.0,
    y1(t) = 2.0*x(t),
    y2(t) = 2.0*yv(t)
)
run_one("forced_lotka_volterra", ode_forced_lotka_volterra)

# --- quadrotor (wallaby cell quadrotor_0_0/script.jl)
# Free params: m, d; states: z, w; Input: u_sin (sin(t))
ode_quadrotor = StructuralIdentifiability.@ODEmodel(
    z'(t) = 0.1*w(t),
    w'(t) = (2.0*u_sin(t) - 0.2*d*w(t)) / (2.0*m),
    y1(t) = 10.0*z(t)
)
run_one("quadrotor", ode_quadrotor)

###############################################################################
# Summary
###############################################################################
println()
println(SEP)
println("SUMMARY (all 23 wallaby systems)")
println(SEP)

# Empirical multiplicity from cluster's MULTIPLICITY_FINDINGS.md table.
# Cluster's table read biohydrogenation as 1 (unprojected); SI revises to >=2 in
# identifiable subspace. We keep "1" here so the verdict column flags the mismatch.
empirical = Dict(
    "aircraft_pitch" => 1, "bicycle_model" => 1,
    "biohydrogenation" => 1, "boost_converter" => 1,
    "brusselator" => 1, "crauste" => 1, "cstr" => 1,
    "daisy_mamil3" => 1, "daisy_mamil4" => 2, "dc_motor" => 1,
    "fitzhugh_nagumo" => 1, "flexible_arm" => 1,
    "forced_lotka_volterra" => 1, "harmonic_oscillator" => 1,
    "hiv" => 1, "lotka_volterra" => 1, "mass_spring_damper" => 1,
    "quadrotor" => 1, "repressilator" => 1, "seir" => 2,
    "slow_fast" => 2, "sirt_treatment" => 1, "vanderpol" => 1,
)
all_sys = sort(collect(keys(empirical)))
println(rpad("system", 30) * rpad("emp_mult", 10) * rpad("SI_global", 10) * rpad("SI_local", 9) * rpad("SI_nonid", 10) * "verdict")
println("-" ^ 100)
for s in all_sys
    info = get(SUMMARY, s, nothing)
    em = empirical[s]
    if info === nothing
        err = get(ERRORS, s, "missing")
        verdict = "ERROR: $(first(err, 40))"
        println(rpad(s, 30) * rpad("$em", 10) * rpad("-", 10) * rpad("-", 9) * rpad("-", 10) * verdict)
        continue
    end
    n_glob = count(==(:globally), values(info))
    n_loc  = count(==(:locally),  values(info))
    n_non  = count(==(:nonidentifiable), values(info))
    verdict = if em == 1 && n_loc == 0
        "CONFIRMED (mult=1)"
    elseif em >= 2 && n_loc >= 1
        "CONFIRMED (mult>=2 plausible)"
    elseif em == 1 && n_loc >= 1
        "MISMATCH: empirical=1 but SI finds locally"
    elseif em >= 2 && n_loc == 0
        "MISMATCH: empirical>=2 but SI says fully globally"
    else
        "?"
    end
    println(rpad(s, 30) * rpad("$em", 10) * rpad("$n_glob", 10) * rpad("$n_loc", 9) * rpad("$n_non", 10) * verdict)
end

println()
println(SEP)
println("DETAILED PER-VAR STATUS")
println(SEP)
for s in all_sys
    info = get(SUMMARY, s, nothing)
    info === nothing && continue
    glob = sort([k for (k, v) in info if v == :globally])
    loc  = sort([k for (k, v) in info if v == :locally])
    non  = sort([k for (k, v) in info if v == :nonidentifiable])
    println("$s:")
    if !isempty(glob); println("  globally:  " * join(glob, ", ")); end
    if !isempty(loc);  println("  locally:   " * join(loc,  ", ")); end
    if !isempty(non);  println("  nonident:  " * join(non,  ", ")); end
end

if !isempty(ERRORS)
    println()
    println(SEP)
    println("ERRORS")
    println(SEP)
    for (s, e) in ERRORS
        println("$s: $e")
    end
end

println()
println("DONE_ALL_23_SYSTEMS")
