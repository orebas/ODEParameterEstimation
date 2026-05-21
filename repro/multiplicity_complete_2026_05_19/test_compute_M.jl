### Test compute_algebraic_multiplicity on all 23 wallaby systems + synthetic
### test cases. The 23 wallaby cases follow run_sian_all_23.jl but use
### StructuralIdentifiability.@ODEmodel (not StructuralIdentifiability.@ODEmodel) so the resulting
### ODE objects match compute_M.jl's signature.
###
### Synthetic test cases verify the M=2/3/4 expectations on simple algebraic
### k-th power cases, plus swap-symmetric multi-state and continuous-unident
### edge cases.
###
### Run: julia --startup-file=no repro/multiplicity_complete_2026_05_19/test_compute_M.jl

using Pkg
include(joinpath(@__DIR__, "compute_M.jl"))

using Printf
using SIAN
using StructuralIdentifiability

const PASSES = Ref(0)
const FAILS  = Ref(0)
const RESULTS = Vector{NamedTuple}()

function check(name::String, ode, expected::Union{Int,Symbol}; tag::String="")
    println()
    println("─" ^ 70)
    println("Testing: $name  $(isempty(tag) ? "" : "[$tag]")  expected M=$expected")
    println("─" ^ 70)
    t0 = time()
    actual = try
        compute_algebraic_multiplicity(ode; p=0.99, infolevel=0)
    catch err
        @error "compute_algebraic_multiplicity threw" exception=(err, catch_backtrace())
        -1
    end
    elapsed = time() - t0
    pass = (expected isa Int && actual == expected)
    if expected === :any_positive
        pass = actual > 0
    end
    status = pass ? "PASS" : "FAIL"
    @printf("  %s  M = %d  (expected %s)  [%.2f s]\n", status, actual, string(expected), elapsed)
    push!(RESULTS, (; name, expected, actual, pass, elapsed, tag))
    if pass; PASSES[] += 1; else; FAILS[] += 1; end
    return actual
end

###############################################################################
# === 23 wallaby systems (transcribed from run_sian_all_23.jl, using SIAN's @ODEmodel) ===
###############################################################################

# --- 16 polynomial systems verbatim from cluster's run_sian_polynomial_only.jl ---

ode_biohydrogenation = StructuralIdentifiability.@ODEmodel(
    x5'(t) = ((-0.3*k7*x5(t)) / (2.0*k8 + 0.5*x6(t) + 0.5*x5(t)) + (8.0*k5*x4(t)) / (4.0*k6 + 8.0*x4(t))) / 0.5,
    x7'(t) = (0.2*(10.0*k10 - 0.5*x6(t))*k9*x6(t)) / (5.0*k10),
    x4'(t) = (-8.0*k5*x4(t)) / (8.0*(4.0*k6 + 8.0*x4(t))),
    x6'(t) = ((-0.2*(10.0*k10 - 0.5*x6(t))*k9*x6(t)) / (10.0*k10) + (0.3*k7*x5(t)) / (2.0*k8 + 0.5*x6(t) + 0.5*x5(t))) / 0.5,
    y1(t) = 8.0*x4(t),
    y2(t) = 0.5*x5(t)
)
check("biohydrogenation", ode_biohydrogenation, 2; tag="wallaby")

ode_brusselator = StructuralIdentifiability.@ODEmodel(
    Yc'(t) = 6.0*b*X(t) - 16.0*a*Yc(t)*(X(t)^2),
    X'(t) = 0.5 - 0.5*X(t) - 3.0*b*X(t) + 16.0*a*Yc(t)*(X(t)^2),
    y1(t) = 2.0*X(t),
    y2(t) = 2.0*Yc(t)
)
check("brusselator", ode_brusselator, 1; tag="wallaby")

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
check("crauste", ode_crauste, 1; tag="wallaby")

ode_daisy_mamil3 = StructuralIdentifiability.@ODEmodel(
    x1'(t) = (0.5*(-1.666*a01 - a21 - 1.334*a31)*x1(t) + 0.334*a12*x2(t) + 0.9990000000000001*a13*x3(t)) / 0.5,
    x2'(t) = -0.334*a12*x2(t) + 0.5*a21*x1(t),
    x3'(t) = (-0.9990000000000001*a13*x3(t) + 0.667*a31*x1(t)) / 1.5,
    y1(t) = 0.5*x1(t),
    y2(t) = x2(t)
)
check("daisy_mamil3", ode_daisy_mamil3, 1; tag="wallaby")

ode_daisy_mamil4 = StructuralIdentifiability.@ODEmodel(
    x1'(t) = (-0.1*k01*x1(t) + 0.4*k12*x2(t) + 0.8999999999999999*k13*x3(t) + 1.6*k14*x4(t) - 0.5*k21*x1(t) - 0.6000000000000001*k31*x1(t) - 0.7000000000000001*k41*x1(t)) / 0.4,
    x4'(t) = (-1.6*k14*x4(t) + 0.7000000000000001*k41*x1(t)) / 1.6,
    x2'(t) = (-0.4*k12*x2(t) + 0.5*k21*x1(t)) / 0.8,
    x3'(t) = (-0.8999999999999999*k13*x3(t) + 0.6000000000000001*k31*x1(t)) / 1.2,
    y1(t) = 0.4*x1(t),
    y2(t) = 0.8*x2(t),
    y3(t) = 1.2*x3(t) + 1.6*x4(t)
)
check("daisy_mamil4", ode_daisy_mamil4, 2; tag="wallaby")

ode_fitzhugh_nagumo = StructuralIdentifiability.@ODEmodel(
    Vm'(t) = (-3.0)*g*(0.5*R(t) - 2.0*Vm(t) + (2.6666666666666665)*(Vm(t)^3)),
    R'(t) = (-0.4*a - 2.0*Vm(t) + 0.2*b*R(t)) / (3.0*g),
    y1(t) = -2.0*Vm(t)
)
check("fitzhugh_nagumo", ode_fitzhugh_nagumo, 1; tag="wallaby")

ode_flexible_arm = StructuralIdentifiability.@ODEmodel(
    theta_t'(t) = omega_t(t),
    omega_m'(t) = (0.5 - 0.1*bm*omega_m(t) - 20.0*k*(-0.5*theta_t(t) + 0.5*theta_m(t))) / (0.1*Jm),
    omega_t'(t) = (-0.05*bt*omega_t(t) - 20.0*k*(0.5*theta_t(t) - 0.5*theta_m(t))) / (0.05*Jt),
    theta_m'(t) = omega_m(t),
    y1(t) = 0.5*theta_m(t),
    y2(t) = 0.5*theta_t(t)
)
check("flexible_arm", ode_flexible_arm, 1; tag="wallaby")

ode_harmonic_oscillator = StructuralIdentifiability.@ODEmodel(
    x1'(t) = -a*x2(t),
    x2'(t) = x1(t) / b,
    y1(t) = 2.0*x1(t),
    y2(t) = x2(t)
)
check("harmonic_oscillator", ode_harmonic_oscillator, 1; tag="wallaby")

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
check("hiv", ode_hiv, 1; tag="wallaby")

ode_lotka_volterra = StructuralIdentifiability.@ODEmodel(
    w'(t) = -0.6*k3*w(t) + 4.0*k2*w(t)*r(t),
    r'(t) = 2.0*k1*r(t) - 2.0*k2*w(t)*r(t),
    y1(t) = 4.0*r(t)
)
check("lotka_volterra", ode_lotka_volterra, 1; tag="wallaby")

ode_mass_spring_damper = StructuralIdentifiability.@ODEmodel(
    vel'(t) = (1.0 - 0.5*c*vel(t) - 8.0*k*x(t)) / m,
    x'(t) = 0.5*vel(t),
    y1(t) = x(t)
)
check("mass_spring_damper", ode_mass_spring_damper, 1; tag="wallaby")

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
check("repressilator", ode_repressilator, 1; tag="wallaby")

ode_seir = StructuralIdentifiability.@ODEmodel(
    S'(t) = (-15840.0*b*In(t)*S(t)) / (3960000.0*Npop(t)),
    E'(t) = ((15840.0*b*In(t)*S(t)) / (2000.0*Npop(t)) - 6.0*nu*E(t)) / 20.0,
    In'(t) = (-4.0*a*In(t) + 6.0*nu*E(t)) / 10.0,
    Npop'(t) = 0,
    y1(t) = 10.0*In(t),
    y2(t) = 2000.0*Npop(t)
)
check("seir", ode_seir, 2; tag="wallaby")

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
check("slow_fast", ode_slow_fast, 2; tag="wallaby")

ode_sirt_treatment = StructuralIdentifiability.@ODEmodel(
    S'(t) = -0.08*b*S(t)*In(t)/Npop(t) - 0.032*d*b*S(t)*Tr(t)/Npop(t),
    Npop'(t) = 0,
    Tr'(t) = 6.0*g*In(t) - 0.2*nu*Tr(t),
    In'(t) = 1.52*b*S(t)*In(t)/Npop(t) + 0.608*d*b*S(t)*Tr(t)/Npop(t) - (0.2*a + 0.6*g)*In(t),
    y1(t) = 10.0*Tr(t),
    y2(t) = 2000.0*Npop(t),
    y3(t) = 10.0*In(t)
)
check("sirt_treatment", ode_sirt_treatment, 1; tag="wallaby")

ode_vanderpol = StructuralIdentifiability.@ODEmodel(
    x1'(t) = 0.5*a*x2(t),
    x2'(t) = -4.0*x1(t) + 2.0*b*x2(t) - 32.0*b*x2(t)*(x1(t)^2),
    y1(t) = 4.0*x1(t),
    y2(t) = x2(t)
)
check("vanderpol", ode_vanderpol, 1; tag="wallaby")

# --- 7 sin(t) systems with u_sin as a free input ---

ode_aircraft_pitch = StructuralIdentifiability.@ODEmodel(
    theta'(t) = q(t),
    q'(t) = (-M_alpha*alpha(t) - M_delta_e*u_sin(t) - 0.2*M_q*q(t)) / 0.05,
    alpha'(t) = (0.05*q(t) - 0.002*Z_alpha*alpha(t)) / 0.1,
    y1(t) = 0.05*q(t)
)
check("aircraft_pitch", ode_aircraft_pitch, 1; tag="wallaby")

ode_bicycle_model = StructuralIdentifiability.@ODEmodel(
    vy'(t) = ((160000.0*Cf*(0.05*u_sin(t) + (-0.12*r(t) - 0.5*vy(t)) / 20.0) + 8000.0*Cr*(0.13999999999999999*r(t) - 0.5*vy(t))) / (3000.0*m_veh) - 2.0*r(t)) / 0.5,
    r'(t) = (192000.0*Cf*(0.05*u_sin(t) + (-0.12*r(t) - 0.5*vy(t)) / 20.0) - 11200.0*Cr*(0.13999999999999999*r(t) - 0.5*vy(t))) / 250.0,
    y1(t) = 0.1*r(t),
    y2(t) = 0.5*vy(t)
)
check("bicycle_model", ode_bicycle_model, 1; tag="wallaby")

ode_boost_converter = StructuralIdentifiability.@ODEmodel(
    iL'(t) = (12.0 - 48.0*(0.5 - 0.1*u_sin(t))*vC(t)) / (0.08*L),
    vC'(t) = ((-48.0*vC(t)) / (20.0*R_load) + 2.0*(0.5 - 0.1*u_sin(t))*iL(t)) / (1.92*C_cap),
    y1(t) = 48.0*vC(t),
    y2(t) = 2.0*iL(t)
)
check("boost_converter", ode_boost_converter, 1; tag="wallaby")

ode_cstr = StructuralIdentifiability.@ODEmodel(
    C'(t) = (1.0 - C(t)) / (2.0*tau) - 1.999863916554819*r_eff(t)*C(t),
    Temp'(t) = (Tin - Temp(t)) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff(t)*C(t) - 2.0*UA_VrhoCP*Temp(t) + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*u_sin(t),
    r_eff'(t) = 12.5*r_eff(t)/(Temp(t)^2)*((Tin - Temp(t)) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff(t)*C(t) - 2.0*UA_VrhoCP*Temp(t) + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*u_sin(t)),
    y1(t) = 700.0*Temp(t)
)
check("cstr", ode_cstr, 1; tag="wallaby")

ode_dc_motor = StructuralIdentifiability.@ODEmodel(
    omega_m'(t) = (0.2*Kt*i(t) - 0.1*omega_m(t)) / (0.02*Jm),
    i'(t) = (12.0 - 0.1*omega_m(t) - 2.0*i(t) + 2.0*u_sin(t)) / 0.5,
    y1(t) = omega_m(t)
)
check("dc_motor", ode_dc_motor, 1; tag="wallaby")

ode_forced_lotka_volterra = StructuralIdentifiability.@ODEmodel(
    x'(t) = (-0.3*u_sin(t) + 6.0*alpha*x(t) - 8.0*beta*x(t)*yv(t)) / 2.0,
    yv'(t) = (-12.0*gamma*yv(t) + 4.0*delta*x(t)*yv(t)) / 2.0,
    y1(t) = 2.0*x(t),
    y2(t) = 2.0*yv(t)
)
check("forced_lotka_volterra", ode_forced_lotka_volterra, 1; tag="wallaby")

ode_quadrotor = StructuralIdentifiability.@ODEmodel(
    z'(t) = 0.1*w(t),
    w'(t) = (2.0*u_sin(t) - 0.2*d*w(t)) / (2.0*m),
    y1(t) = 10.0*z(t)
)
check("quadrotor", ode_quadrotor, 1; tag="wallaby")

###############################################################################
# === Synthetic stress tests ===
###############################################################################

# x' = a^2 * x ; y = x → a^2 globally identifiable, a satisfies a^2 = const → M = 2
ode_a2 = StructuralIdentifiability.@ODEmodel(
    x'(t) = a^2 * x(t),
    y1(t) = x(t)
)
check("synthetic_a_squared", ode_a2, 2; tag="synthetic")

# x' = a^3 * x ; y = x → a^3 globally identifiable, a satisfies a^3 = const → M = 3
ode_a3 = StructuralIdentifiability.@ODEmodel(
    x'(t) = a^3 * x(t),
    y1(t) = x(t)
)
check("synthetic_a_cubed", ode_a3, 3; tag="synthetic")

# x' = a^4 * x ; y = x → a^4 globally identifiable, a satisfies a^4 = const → M = 4
ode_a4 = StructuralIdentifiability.@ODEmodel(
    x'(t) = a^4 * x(t),
    y1(t) = x(t)
)
check("synthetic_a_fourth_power", ode_a4, 4; tag="synthetic")

# x' = a^5 * x ; y = x → M = 5
ode_a5 = StructuralIdentifiability.@ODEmodel(
    x'(t) = a^5 * x(t),
    y1(t) = x(t)
)
check("synthetic_a_fifth_power", ode_a5, 5; tag="synthetic")

# Two-variable swap: x1' = a*x1, x2' = b*x2 ; y = x1 + x2
# The system is symmetric under (a,x1) ↔ (b,x2) since y is symmetric.
# → 2 algebraic branches → M = 2
ode_swap2 = StructuralIdentifiability.@ODEmodel(
    x1'(t) = a*x1(t),
    x2'(t) = b*x2(t),
    y1(t) = x1(t) + x2(t)
)
check("synthetic_swap_2var", ode_swap2, 2; tag="synthetic")

# Three-variable swap with double-counting: x1' = a*x1, x2' = b*x2, x3' = c*x3 ; y = x1+x2+x3
# The 3 channels are interchangeable → M = 3! = 6 algebraic branches.
ode_swap3 = StructuralIdentifiability.@ODEmodel(
    x1'(t) = a*x1(t),
    x2'(t) = b*x2(t),
    x3'(t) = c*x3(t),
    y1(t) = x1(t) + x2(t) + x3(t)
)
check("synthetic_swap_3var", ode_swap3, 6; tag="synthetic")

# Combined: x' = a^2 * x ; y = x^2 (observable is itself squared).
# y'/y = 2*a^2 → a^2 globally id'd, a has 2 algebraic roots (±sqrt(a^2)).
# y(0) = x0^2 → x0 has 2 algebraic roots (±sqrt(y(0))).
# Total: 2 × 2 = 4 algebraic branches.
ode_combined = StructuralIdentifiability.@ODEmodel(
    x'(t) = a^2 * x(t),
    y1(t) = x(t)^2
)
check("synthetic_a2_y_squared", ode_combined, 4; tag="synthetic")

###############################################################################
# === Summary ===
###############################################################################
println()
println("=" ^ 70)
println("SUMMARY")
println("=" ^ 70)
println("$(PASSES[]) pass, $(FAILS[]) fail, $(PASSES[] + FAILS[]) total")
println()

# Compact table
@printf("  %-32s %-10s %6s %6s %5s %s\n", "system", "tag", "actual", "expect", "pass", "wall")
println("  " * "─" ^ 76)
for r in RESULTS
    status = r.pass ? "  ✓" : "✗ "
    @printf("  %-32s %-10s %6d %6s   %s   %5.2fs\n",
        r.name, r.tag, r.actual, string(r.expected), status, r.elapsed)
end
println()

# Categorize failures
fails = [r for r in RESULTS if !r.pass]
if !isempty(fails)
    println("=" ^ 70)
    println("FAILURES")
    println("=" ^ 70)
    for r in fails
        println("  $(r.name) [$(r.tag)]: got $(r.actual), expected $(r.expected)")
    end
end

exit(FAILS[] > 0 ? 1 : 0)
