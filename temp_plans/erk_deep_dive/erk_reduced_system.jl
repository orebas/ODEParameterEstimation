#!/usr/bin/env julia
# ERK Reduced System — cascade substitution to 8×8 core
# Run: julia /tmp/erk_reduced_system.jl > /tmp/erk_reduced_system.txt 2>&1

using ODEParameterEstimation
using ModelingToolkit
using DifferentialEquations
using OrderedCollections
using Printf
using LinearAlgebra
import ForwardDiff

# ═══════════════════════════════════════════════════════════════
# MODEL + DATA (same setup as dump script)
# ═══════════════════════════════════════════════════════════════
@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t) y0(t) y1(t) y2(t)
D = Differential(t)
states_list = [S0, C1, C2, S1, S2, E]
params_list = [kf1, kr1, kc1, kf2, kr2, kc2]
eqs = [
    D(S0) ~ -kf1 * E * S0 + kr1 * C1,
    D(C1) ~ kf1 * E * S0 - (kr1 + kc1) * C1,
    D(C2) ~ kc1 * C1 - (kr2 + kc2) * C2 + kf2 * E * S1,
    D(S1) ~ -kf2 * E * S1 + kr2 * C2,
    D(S2) ~ kc2 * C2,
    D(E) ~ -kf1 * E * S0 + kr1 * C1 - kf2 * E * S1 + (kr2 + kc2) * C2,
]
measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]
p_true = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]
ic_true = [5.0, 0.0, 0.0, 0.0, 0.0, 0.65]

@named erk_model = ODESystem(eqs, t, states_list, params_list)
ds = ODEParameterEstimation.sample_data(
    erk_model, measured_quantities, [0.0, 20.0],
    Dict(params_list .=> p_true), Dict(states_list .=> ic_true), 2001;
    solver = AutoVern9(Rodas4P()))

# High-accuracy ODE solution
sys_complete = complete(erk_model)
prob = ODEProblem(sys_complete,
    merge(Dict(ModelingToolkit.unknowns(sys_complete) .=> ic_true),
        Dict(ModelingToolkit.parameters(sys_complete) .=> p_true)),
    [0.0, 20.0])
sol = solve(prob, AutoVern9(Rodas4P()); abstol=1e-14, reltol=1e-14, dense=true)

# Taylor recursion for ground truth
function compute_truth(sol_obj, t_eval, pv; max_order=6)
    tc = zeros(6, max_order+1)
    s = sol_obj(t_eval)
    for i in 1:6; tc[i,1] = s[i]; end
    tp(a,b,k) = sum(a[j+1]*b[k-j+1] for j in 0:k)
    for k in 0:(max_order-1)
        S0c=tc[1,1:k+1]; C1c=tc[2,1:k+1]; C2c=tc[3,1:k+1]
        S1c=tc[4,1:k+1]; S2c=tc[5,1:k+1]; Ec=tc[6,1:k+1]
        ES0=tp(Ec,S0c,k); ES1=tp(Ec,S1c,k)
        f = zeros(6)
        f[1]=-pv[1]*ES0+pv[2]*C1c[k+1]
        f[2]=pv[1]*ES0-(pv[2]+pv[3])*C1c[k+1]
        f[3]=pv[3]*C1c[k+1]-(pv[5]+pv[6])*C2c[k+1]+pv[4]*ES1
        f[4]=-pv[4]*ES1+pv[5]*C2c[k+1]
        f[5]=pv[6]*C2c[k+1]
        f[6]=-pv[1]*ES0+pv[2]*C1c[k+1]-pv[4]*ES1+(pv[5]+pv[6])*C2c[k+1]
        for i in 1:6; tc[i,k+2]=f[i]/(k+1); end
    end
    obs_map = [1,4,5]  # S0, S1, S2
    obs = [[Float64(tc[s,k+1]*factorial(big(k))) for k in 0:max_order] for s in obs_map]
    states = Dict("C1_0"=>tc[2,1], "E_0"=>tc[6,1])
    return obs, states
end

# Build interpolants
t_vec = collect(Float64, ds["t"])
obs_keys = [S0, states_list[4], states_list[5]]
aaad_interps = [ODEParameterEstimation.aaad(t_vec, collect(Float64, ds[k])) for k in obs_keys]
agp_interps = [ODEParameterEstimation.agp_gpr_robust(t_vec, collect(Float64, ds[k])) for k in obs_keys]

# ═══════════════════════════════════════════════════════════════
# THE REDUCTION
# ═══════════════════════════════════════════════════════════════
println("=" ^ 100)
println("ERK REDUCED SYSTEM — FROM 33×33 TO 8×8")
println("=" ^ 100)

println("""
STEP 1: Trivial pinning (12 equations eliminate 12 observed-state derivatives)
  S0_k = y0^(k)  for k = 0,1,2,3    (from Eq1,3,5,7,10,14,16,19,23,25,28,32)
  S1_k = y1^(k)  for k = 0,1,2,3
  S2_k = y2^(k)  for k = 0,1,2,3

STEP 2: S2-chain (4 equations eliminate C2_0, C2_1, C2_2, S2_4)
  From D(S2) = kc2·C2:
    C2_k = y2^(k+1) / kc2    for k = 0,1,2    (from Eq2,8,17)
    S2_4 = kc2 · C2_3                           (from Eq26)

STEP 3: Cascade — E and C1 higher derivatives (9 eqs eliminate 9 vars)
  From D(E)  equation:  E_k+1  = f(C1_k, E_0..E_k, params, data)
  From D(C1) equation:  C1_k+1 = g(C1_k, E_0..E_k, params, data)
  From D(C2) at order 2: C2_3  = h(C1_2, E_0..E_2, params, data)
  From S0 ODE at order 3: S0_4  = j(C1_3, E_0..E_3, params, data)
  From S1 ODE at order 3: S1_4  = l(C2_3, E_0..E_3, params, data)

  Cascade order:
    E_1  from Eq12,  C1_1 from Eq13
    E_2  from Eq21,  C1_2 from Eq22
    E_3  from Eq30,  C1_3 from Eq31
    C2_3 from Eq27,  S0_4 from Eq29,  S1_4 from Eq33

  All higher derivs determined by (C1_0, E_0, params, data).

RESULT: 8 equations in 8 unknowns
  Unknowns: x = [C1_0, E_0, kf1, kr1, kc1, kf2, kr2, kc2]
  Data: d = [y0, y0', y0'', y0''', y1, y1', y1'', y1''', y2', y2'', y2''']
  (11 data values — y2 itself drops out, only y2 derivatives appear)
""")

println("THE 8 EQUATIONS (after all substitutions):")
println("─" ^ 100)
println("""
  Notation: a = [y0, y0', y0'', y0''']  b = [y1, y1', y1'', y1''']  c = [y2', y2'', y2''']

  Cascade definitions (computed from unknowns, NOT separate equations):
    C1_1 = kf1·E_0·a[1] − (kc1+kr1)·C1_0
    E_1  = kr1·C1_0 + (kc2+kr2)·c[1]/kc2 − kf1·E_0·a[1] − kf2·E_0·b[1]
    C1_2 = kf1·E_0·a[2] + kf1·E_1·a[1] − (kc1+kr1)·C1_1
    E_2  = kr1·C1_1 + (kc2+kr2)·c[2]/kc2 − kf1·(E_0·a[2]+E_1·a[1]) − kf2·(E_0·b[2]+E_1·b[1])

  Constraint equations (these must all = 0):
    R1 = a[2] + kf1·E_0·a[1] − kr1·C1_0                          [S0 ODE, order 0; uses a[1..2]]
    R2 = b[2] + kf2·E_0·b[1] − kr2·c[1]/kc2                      [S1 ODE, order 0; uses b[1..2], c[1]]
    R3 = c[2]/kc2 − kc1·C1_0 + (kc2+kr2)·c[1]/kc2 − kf2·E_0·b[1] [C2 ODE, order 0; uses b[1], c[1..2]]
    R4 = a[3] + kf1·E_0·a[2] + kf1·E_1·a[1] − kr1·C1_1           [S0 ODE, order 1; uses a[1..3]]
    R5 = b[3] + kf2·E_0·b[2] + kf2·E_1·b[1] − kr2·c[2]/kc2       [S1 ODE, order 1; uses b[1..3], c[1..2]]
    R6 = c[3]/kc2 − kc1·C1_1 + (kc2+kr2)·c[2]/kc2                 [C2 ODE, order 1; uses b[1..2], c[1..3]]
         − kf2·E_0·b[2] − kf2·E_1·b[1]
    R7 = a[4] + kf1·E_0·a[3] + 2·kf1·E_1·a[2] + kf1·E_2·a[1]     [S0 ODE, order 2; uses a[1..4], c[1..2]]
         − kr1·C1_2
    R8 = b[4] + kf2·E_0·b[3] + 2·kf2·E_1·b[2] + kf2·E_2·b[1]     [S1 ODE, order 2; uses b[1..4], c[1..2]]
         − kr2·c[3]/kc2

  Data usage per equation:
    R1, R2: order 0-1 only (y0, y0', y1, y1', y2')
    R3:     order 0-1 only (y1, y2', y2'')
    R4, R5: order 0-2     (through E_1, C1_1 cascade)
    R6:     order 0-2     (y2''' enters directly!)
    R7, R8: order 0-3     (through E_2, C1_2 cascade + y0''', y1''')
""")

# ═══════════════════════════════════════════════════════════════
# NUMERICAL IMPLEMENTATION
# ═══════════════════════════════════════════════════════════════

# Unknowns: x = [C1_0, E_0, kf1, kr1, kc1, kf2, kr2, kc2]
const NAMES_8 = ["C1_0", "E_0", "kf1", "kr1", "kc1", "kf2", "kr2", "kc2"]
const EQ_NAMES = ["R1(S0,ord0)", "R2(S1,ord0)", "R3(C2,ord0)",
                   "R4(S0,ord1)", "R5(S1,ord1)", "R6(C2,ord1)",
                   "R7(S0,ord2)", "R8(S1,ord2)"]

# Data: d = [y0, y0', y0'', y0''', y1, y1', y1'', y1''', y2', y2'', y2''']
const DATA_NAMES = ["y0", "y0'", "y0''", "y0'''",
                     "y1", "y1'", "y1''", "y1'''",
                     "y2'", "y2''", "y2'''"]

function reduced_residual(x, d)
    C1_0, E_0, kf1, kr1, kc1, kf2, kr2, kc2 = x
    a1, a2, a3, a4 = d[1], d[2], d[3], d[4]     # y0, y0', y0'', y0'''
    b1, b2, b3, b4 = d[5], d[6], d[7], d[8]     # y1, y1', y1'', y1'''
    c1, c2, c3     = d[9], d[10], d[11]          # y2', y2'', y2'''

    # Cascade: compute intermediates
    C1_1 = kf1*E_0*a1 - (kc1+kr1)*C1_0
    E_1  = kr1*C1_0 + (kc2+kr2)*c1/kc2 - kf1*E_0*a1 - kf2*E_0*b1
    C1_2 = kf1*E_0*a2 + kf1*E_1*a1 - (kc1+kr1)*C1_1
    E_2  = kr1*C1_1 + (kc2+kr2)*c2/kc2 - kf1*(E_0*a2 + E_1*a1) - kf2*(E_0*b2 + E_1*b1)

    # 8 constraint equations
    R1 = a2 + kf1*E_0*a1 - kr1*C1_0
    R2 = b2 + kf2*E_0*b1 - kr2*c1/kc2
    R3 = c2/kc2 - kc1*C1_0 + (kc2+kr2)*c1/kc2 - kf2*E_0*b1
    R4 = a3 + kf1*E_0*a2 + kf1*E_1*a1 - kr1*C1_1
    R5 = b3 + kf2*E_0*b2 + kf2*E_1*b1 - kr2*c2/kc2
    R6 = c3/kc2 - kc1*C1_1 + (kc2+kr2)*c2/kc2 - kf2*E_0*b2 - kf2*E_1*b1
    R7 = a4 + kf1*E_0*a3 + 2*kf1*E_1*a2 + kf1*E_2*a1 - kr1*C1_2
    R8 = b4 + kf2*E_0*b3 + 2*kf2*E_1*b2 + kf2*E_2*b1 - kr2*c3/kc2

    return [R1, R2, R3, R4, R5, R6, R7, R8]
end

# ═══════════════════════════════════════════════════════════════
# EVALUATE AT t = 5.71
# ═══════════════════════════════════════════════════════════════
t_eval = t_vec[572]
truth_obs, truth_ic = compute_truth(sol, t_eval, p_true)

# True data vector
d_true = [truth_obs[1][1], truth_obs[1][2], truth_obs[1][3], truth_obs[1][4],  # y0..y0'''
          truth_obs[2][1], truth_obs[2][2], truth_obs[2][3], truth_obs[2][4],  # y1..y1'''
          truth_obs[3][2], truth_obs[3][3], truth_obs[3][4]]                    # y2'..y2'''

# True unknown vector
x_true = [truth_ic["C1_0"], truth_ic["E_0"],
          p_true[1], p_true[2], p_true[3], p_true[4], p_true[5], p_true[6]]

println("\n" * "=" ^ 100)
@printf("NUMERICAL EVALUATION AT t = %.4f\n", t_eval)
println("=" ^ 100)

println("\n--- TRUE VALUES ---")
println("  Unknowns:")
for (i, n) in enumerate(NAMES_8)
    @printf("    %-6s = %+20.12e\n", n, x_true[i])
end
println("  Data:")
for (i, n) in enumerate(DATA_NAMES)
    @printf("    %-6s = %+20.12e\n", n, d_true[i])
end

# Verify residual
r_true = reduced_residual(x_true, d_true)
@printf("\n  Residual at true solution: max|R| = %.4e\n", maximum(abs, r_true))

# ═══════════════════════════════════════════════════════════════
# JACOBIAN OF REDUCED SYSTEM
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 100)
println("JACOBIAN ∂R/∂x (8 × 8) AT TRUE SOLUTION")
println("=" ^ 100)

J8 = ForwardDiff.jacobian(x -> reduced_residual(x, d_true), x_true)
cond8 = cond(J8)
@printf("\ncond(∂R/∂x) = %.6e\n", cond8)

svd8 = svd(J8)
println("\nSingular values:")
for (i, s) in enumerate(svd8.S)
    @printf("  σ_%d = %.6e\n", i, s)
end
@printf("Condition = σ₁/σ₈ = %.6e\n", svd8.S[1]/svd8.S[end])

println("\nFull 8×8 Jacobian:")
@printf("%-14s", "")
for n in NAMES_8; @printf(" %12s", n); end
println()
println("─" ^ (14 + 13*8))
for i in 1:8
    @printf("%-14s", EQ_NAMES[i])
    for j in 1:8
        @printf(" %+12.4e", J8[i,j])
    end
    println()
end

# ═══════════════════════════════════════════════════════════════
# SENSITIVITY ∂x/∂d (8 × 11)
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 100)
println("SENSITIVITY ∂x/∂d (8 × 11) — HOW DATA ERRORS PROPAGATE TO UNKNOWNS")
println("=" ^ 100)

# ∂R/∂d via finite differences
J_d8 = zeros(8, 11)
for di in 1:11
    ε = 1e-7 * max(abs(d_true[di]), 1e-10)
    d_plus = copy(d_true); d_plus[di] += ε
    J_d8[:, di] = (reduced_residual(x_true, d_plus) - r_true) / ε
end

sensitivity8 = -J8 \ J_d8

println("\nFull sensitivity matrix (unit perturbation in data → shift in unknown):")
@printf("%-8s", "")
for n in DATA_NAMES; @printf(" %12s", n[1:min(end,12)]); end
println()
println("─" ^ (8 + 13*11))
for i in 1:8
    @printf("%-8s", NAMES_8[i])
    for di in 1:11
        @printf(" %+12.4e", sensitivity8[i, di])
    end
    println()
end

# ═══════════════════════════════════════════════════════════════
# COMPARE: AAAD vs AGPRobust DATA
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 100)
println("DATA COMPARISON: Truth vs AAAD vs AGPRobust")
println("=" ^ 100)

function get_data_vector(interps, t_pt)
    d = zeros(11)
    for ord in 0:3
        d[ord+1] = ODEParameterEstimation.nth_deriv(x -> interps[1](x), ord, t_pt)  # y0^(ord)
        d[ord+5] = ODEParameterEstimation.nth_deriv(x -> interps[2](x), ord, t_pt)  # y1^(ord)
    end
    for ord in 1:3
        d[ord+8] = ODEParameterEstimation.nth_deriv(x -> interps[3](x), ord, t_pt)  # y2^(ord)
    end
    return d
end

d_aaad = get_data_vector(aaad_interps, t_eval)
d_agp  = get_data_vector(agp_interps, t_eval)

@printf("\n%-8s %20s %20s %20s %12s %12s\n",
    "Data", "Truth", "AAAD", "AGPRobust", "AAAD err%", "AGP err%")
println("─" ^ 96)
for i in 1:11
    ae = abs(d_true[i]) > 1e-15 ? abs((d_aaad[i]-d_true[i])/d_true[i])*100 : 0.0
    ge = abs(d_true[i]) > 1e-15 ? abs((d_agp[i]-d_true[i])/d_true[i])*100 : 0.0
    @printf("%-8s %+20.12e %+20.12e %+20.12e %11.6f%% %11.6f%%\n",
        DATA_NAMES[i], d_true[i], d_aaad[i], d_agp[i], ae, ge)
end

# ═══════════════════════════════════════════════════════════════
# ERROR PROPAGATION
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 100)
println("ERROR PROPAGATION — PREDICTED DISPLACEMENT OF EACH UNKNOWN")
println("=" ^ 100)

for (label, d_interp) in [("AAAD", d_aaad), ("AGPRobust", d_agp)]
    Δd = d_interp - d_true
    Δx_pred = sensitivity8 * Δd

    println("\n--- $label ---")
    @printf("%-8s %14s %14s %14s %14s\n", "Unknown", "True", "Pred shift", "Pred value", "Pred err%")
    println("─" ^ 68)
    for i in 1:8
        pred_val = x_true[i] + Δx_pred[i]
        pred_err = abs(x_true[i]) > 1e-15 ? Δx_pred[i]/x_true[i]*100 : Δx_pred[i]
        @printf("%-8s %+14.6e %+14.6e %+14.6e %+13.4f%%\n",
            NAMES_8[i], x_true[i], Δx_pred[i], pred_val, pred_err)
    end

    # Top contributors per parameter
    println("\n  Top error contributors:")
    for i in 1:8
        if !startswith(NAMES_8[i], "k") && NAMES_8[i] != "E_0"; continue; end
        contribs = [(sensitivity8[i,di]*Δd[di], DATA_NAMES[di], Δd[di], sensitivity8[i,di]) for di in 1:11]
        sort!(contribs, by=x->abs(x[1]), rev=true)
        @printf("  %s (true=%.4f):\n", NAMES_8[i], x_true[i])
        for k in 1:min(3, length(contribs))
            c, dl, de, s = contribs[k]
            if abs(c) > 1e-12
                @printf("    %-8s Δd=%+11.3e  ∂x/∂d=%+11.3e  contrib=%+11.3e\n", dl, de, s, c)
            end
        end
    end
end

# ═══════════════════════════════════════════════════════════════
# WHAT IF WE ONLY USE R1..R5 (order 0-1 data)?
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 100)
println("SUB-SYSTEM ANALYSIS: CONDITION NUMBERS BY EQUATION SUBSET")
println("=" ^ 100)

# R1..R3 only (order 0 data, 3 eqs, 8 unknowns)
println("\nR1-R3 (S0/S1/C2 ODEs at order 0, uses data orders 0-1):")
J_sub3 = J8[1:3, :]
sv3 = svd(J_sub3).S
@printf("  Singular values: %s\n", join([@sprintf("%.3e", s) for s in sv3], ", "))
@printf("  Rank = %d (of 3)\n", count(s -> s > 1e-10, sv3))

# R1..R5 (order 0-1, 5 eqs, 8 unknowns)
println("\nR1-R5 (order 0-1 equations, uses data orders 0-2):")
J_sub5 = J8[1:5, :]
sv5 = svd(J_sub5).S
@printf("  Singular values: %s\n", join([@sprintf("%.3e", s) for s in sv5], ", "))
@printf("  Rank = %d (of 5)\n", count(s -> s > 1e-10, sv5))

# R1..R6 (order 0-1 + C2 ord 1, 6 eqs, 8 unknowns)
println("\nR1-R6 (adds C2 ODE order 1, uses data orders 0-2+y2'''):")
J_sub6 = J8[1:6, :]
sv6 = svd(J_sub6).S
@printf("  Singular values: %s\n", join([@sprintf("%.3e", s) for s in sv6], ", "))
@printf("  Rank = %d (of 6)\n", count(s -> s > 1e-10, sv6))

# Full R1..R8 (8 eqs, 8 unknowns)
println("\nR1-R8 (full system, uses data orders 0-3):")
@printf("  Singular values: %s\n", join([@sprintf("%.3e", s) for s in svd8.S], ", "))
@printf("  cond = %.6e\n", cond8)

# ═══════════════════════════════════════════════════════════════
# MACHINE-READABLE
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 100)
println("MACHINE-READABLE DATA")
println("=" ^ 100)

println("\n--- UNKNOWN_IDX,NAME,TRUE_VALUE ---")
for (i,n) in enumerate(NAMES_8)
    @printf("%d,%s,%.15e\n", i, n, x_true[i])
end

println("\n--- DATA_IDX,NAME,TRUE,AAAD,AGP ---")
for (i,n) in enumerate(DATA_NAMES)
    @printf("%d,%s,%.15e,%.15e,%.15e\n", i, n, d_true[i], d_aaad[i], d_agp[i])
end

println("\n--- JACOBIAN_8x8 (row,col,value) ---")
for i in 1:8, j in 1:8
    if abs(J8[i,j]) > 1e-20
        @printf("%d,%d,%.15e\n", i, j, J8[i,j])
    end
end

println("\n--- SENSITIVITY_8x11 (unknown_idx,data_idx,value) ---")
for i in 1:8, di in 1:11
    if abs(sensitivity8[i,di]) > 1e-20
        @printf("%d,%d,%.15e\n", i, di, sensitivity8[i,di])
    end
end

println("\n--- SINGULAR_VALUES_8 ---")
for (i,s) in enumerate(svd8.S)
    @printf("%d,%.15e\n", i, s)
end

println("\n" * "=" ^ 100)
println("DONE")
println("=" ^ 100)
flush(stdout)
