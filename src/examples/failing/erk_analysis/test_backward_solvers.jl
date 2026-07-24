#=
Test: Can stiff solvers or extreme tolerances fix backward integration?
=========================================================================
SAFETY: Low maxiters, stiff solvers only, GC between tests.
Previous version caused BSOD by letting explicit Vern9 run wild on a stiff
backward problem with maxiters=10M.
=#

using ModelingToolkit, DifferentialEquations
using OrderedCollections
using LinearAlgebra
using Printf

println("=" ^ 80)
println("TEST: Backward ODE Integration with Stiff Solvers")
println("=" ^ 80)

# Define ERK model
@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t)
D = Differential(t)
states = [S0, C1, C2, S1, S2, E]
parameters = [kf1, kr1, kc1, kf2, kr2, kc2]
eqs = [
    D(S0) ~ -kf1 * E * S0 + kr1 * C1,
    D(C1) ~ kf1 * E * S0 - (kr1 + kc1) * C1,
    D(C2) ~ kc1 * C1 - (kr2 + kc2) * C2 + kf2 * E * S1,
    D(S1) ~ -kf2 * E * S1 + kr2 * C2,
    D(S2) ~ kc2 * C2,
    D(E) ~ -kf1 * E * S0 + kr1 * C1 - kf2 * E * S1 + (kr2 + kc2) * C2,
]
@named model = ODESystem(eqs, t, states, parameters)
model = complete(model)

p_true = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]
ic_true = [5.0, 0.0, 0.0, 0.0, 0.0, 0.65]

# Step 1: Forward solve (safe, fast)
println("\n### Step 1: Generate ground truth ###")
p_map = Dict(parameters .=> p_true)
ic_map = Dict(states .=> ic_true)
prob_fwd = ODEProblem(model, merge(ic_map, p_map), (0.0, 20.0))
sol_fwd = solve(prob_fwd, Vern9(), abstol=1e-14, reltol=1e-14)
println("Forward solve: SUCCESS ($(length(sol_fwd.t)) timesteps)")

# Step 2: Eigenvalues (already computed in prior run, but fast to redo)
println("\n### Step 2: Jacobian Eigenvalues (recap) ###")
for ts in [0.0, 5.0]
    s_vals = [sol_fwd(ts, idxs=s) for s in states]
    S0v, C1v, C2v, S1v, S2v, Ev = s_vals
    kf1v, kr1v, kc1v, kf2v, kr2v, kc2v = p_true
    J = [
        -kf1v*Ev       kr1v          0                0            0    -kf1v*S0v;
         kf1v*Ev  -(kr1v+kc1v)       0                0            0     kf1v*S0v;
              0        kc1v     -(kr2v+kc2v)     kf2v*Ev           0     kf2v*S1v;
              0          0          kr2v        -kf2v*Ev           0    -kf2v*S1v;
              0          0          kc2v              0            0          0;
        -kf1v*Ev       kr1v     (kr2v+kc2v)    -kf2v*Ev          0  -(kf1v*S0v+kf2v*S1v);
    ]
    eigs = eigvals(J)
    real_parts = real.(eigs)
    @printf("  t=%.0f: eigenvalues = [%s]\n", ts,
            join([@sprintf("%.1f", r) for r in sort(real_parts)], ", "))
end

# Step 3: Backward integration — STIFF SOLVERS ONLY, low maxiters
println("\n### Step 3: Backward Integration (stiff solvers, safe maxiters) ###")

SAFE_MAXITERS = 100_000  # not 10M!

# Only test implicit stiff solvers — explicit solvers on stiff backward = OOM
solver_configs = [
    ("Rodas4P  (atol=1e-8)",  Rodas4P(),  1e-8,  1e-8),
    ("Rodas4P  (atol=1e-14)", Rodas4P(),  1e-14, 1e-14),
    ("Rodas5P  (atol=1e-14)", Rodas5P(),  1e-14, 1e-14),
    ("RadauIIA5(atol=1e-14)", RadauIIA5(), 1e-14, 1e-14),
]

shooting_times = [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0]

for ts in shooting_times
    println("\n--- Backward from t=$ts → t=0 ---")

    exact_ic = [sol_fwd(ts, idxs=s) for s in states]

    for (name, solver, atol, rtol) in solver_configs
        for (label, ic_test) in [
            ("exact IC",      copy(exact_ic)),
            ("perturb 1e-10", exact_ic .* (1 .+ 1e-10 .* [0.1, -0.3, 0.2, -0.1, 0.05, 0.15])),
            ("perturb 1e-6",  exact_ic .* (1 .+ 1e-6  .* [0.1, -0.3, 0.2, -0.1, 0.05, 0.15])),
        ]
            prob_bwd = ODEProblem(model, merge(Dict(states .=> ic_test), p_map), (ts, 0.0))
            backsolved = try
                sol_bwd = solve(prob_bwd, solver; abstol=atol, reltol=rtol,
                                maxiters=SAFE_MAXITERS)
                if sol_bwd.retcode == ReturnCode.Success
                    [sol_bwd(0.0, idxs=s) for s in states]
                else
                    nothing
                end
            catch e
                nothing
            end

            if backsolved !== nothing
                error_vec = abs.(backsolved .- ic_true)
                max_err = maximum(error_vec)
                tag = max_err < 0.01 ? "OK" : (max_err < 1.0 ? "DEGRADED" : "BLOWN")
                @printf("  %-25s %-15s err=%.2e [%s]\n", name, label, max_err, tag)
            else
                @printf("  %-25s %-15s FAILED\n", name, label)
            end
            GC.gc(false)  # light GC between tests
        end
    end
    GC.gc()  # full GC between shooting times
end

# Step 4: Find the safe backward interval
println("\n### Step 4: Maximum Safe Backward Interval ###")
println("(Rodas5P, atol=1e-14, with 1e-6 deterministic perturbation)")

max_safe_dt = 0.0
for dt in [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0]
    exact_ic = [sol_fwd(dt, idxs=s) for s in states]
    perturbed = exact_ic .* (1 .+ 1e-6 .* [0.1, -0.3, 0.2, -0.1, 0.05, 0.15])

    prob = ODEProblem(model, merge(Dict(states .=> perturbed), p_map), (dt, 0.0))
    result = try
        sol = solve(prob, Rodas5P(); abstol=1e-14, reltol=1e-14, maxiters=SAFE_MAXITERS)
        sol.retcode == ReturnCode.Success ? [sol(0.0, idxs=s) for s in states] : nothing
    catch; nothing; end

    if result !== nothing
        err = maximum(abs.(result .- ic_true))
        tag = err < 0.01 ? "SAFE" : (err < 1.0 ? "MARGINAL" : "BLOWN")
        if err < 0.1
            max_safe_dt = dt
        end
        @printf("  Δt=%.3f: max_err = %.2e  [%s]\n", dt, err, tag)
    else
        @printf("  Δt=%.3f: FAILED\n", dt)
    end
    GC.gc(false)
end

println("\n  → Max safe backward Δt ≈ $max_safe_dt (with 1e-6 perturbation)")
println("  → Current shooting Δt ≈ 2.8 seconds")

println("\n" * "=" ^ 80)
println("DONE")
println("=" ^ 80)
