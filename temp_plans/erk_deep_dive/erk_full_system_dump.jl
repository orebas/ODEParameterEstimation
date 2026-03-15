#!/usr/bin/env julia
# ERK Full System Dump — all 33 equations, all 33 unknowns, Jacobian, solutions
# Run: julia /tmp/erk_full_system_dump.jl > /tmp/erk_full_system_dump.txt 2>&1

using ODEParameterEstimation
using ModelingToolkit
using DifferentialEquations
using OrderedCollections
using Printf
using LinearAlgebra
import HomotopyContinuation
const HC = HomotopyContinuation
import ForwardDiff

# ═══════════════════════════════════════════════════════════════
# MODEL SETUP
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
p_true_vals = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]
ic_vals = [5.0, 0.0, 0.0, 0.0, 0.0, 0.65]

@named erk_model = ODESystem(eqs, t, states_list, params_list)
ds = ODEParameterEstimation.sample_data(
    erk_model, measured_quantities, [0.0, 20.0],
    Dict(params_list .=> p_true_vals), Dict(states_list .=> ic_vals), 2001;
    solver = AutoVern9(Rodas4P()))

om, mqo = ODEParameterEstimation.create_ordered_ode_system(
    "erk", states_list, params_list, eqs, measured_quantities)
pep = ParameterEstimationProblem("erk", om, mqo, ds, [0.0, 20.0],
    nothing, OrderedDict(params_list .=> p_true_vals),
    OrderedDict(states_list .=> ic_vals), 0)

# ═══════════════════════════════════════════════════════════════
# SIAN TEMPLATE + INTERPOLANTS
# ═══════════════════════════════════════════════════════════════
interpolator_func = ODEParameterEstimation.get_interpolator_function(InterpolatorAAAD, nothing)
setup_data = ODEParameterEstimation.setup_parameter_estimation(
    pep; max_num_points=1, point_hint=0.5, nooutput=true, interpolator=interpolator_func)

ordered_model = ODEParameterEstimation.OrderedODESystem(
    pep.model.system, setup_data.states, setup_data.params)

template_equations, _, _, _ =
    ODEParameterEstimation.get_si_equation_system(
        ordered_model, pep.measured_quantities, pep.data_sample;
        DD=setup_data.good_DD, infolevel=0)

# Identify data variables
obs_data_vars = Set{Any}()
for level in setup_data.good_DD.obs_lhs
    for v in level; push!(obs_data_vars, v); end
end

vars_in_template = Set{Any}()
for eq in template_equations
    for v in Symbolics.get_variables(eq); push!(vars_in_template, v); end
end

data_vars_in_eqs = sort(collect(intersect(vars_in_template, obs_data_vars)), by=string)
data_var_info = []
for v in data_vars_in_eqs
    for order in 0:15
        for obs_idx in 1:3
            if order + 1 <= length(setup_data.good_DD.obs_lhs) &&
               obs_idx <= length(setup_data.good_DD.obs_lhs[order+1]) &&
               v === setup_data.good_DD.obs_lhs[order+1][obs_idx]
                push!(data_var_info, (v, obs_idx, order, string(v)))
                @goto found
            end
        end
    end
    @label found
end
sort!(data_var_info, by=x->(x[2], x[3]))

# ═══════════════════════════════════════════════════════════════
# HIGH-ACCURACY ODE SOLUTION FOR GROUND TRUTH
# ═══════════════════════════════════════════════════════════════
TRUTH_MAX_ORDER = 8
sys_complete = complete(erk_model)
prob = ODEProblem(sys_complete,
    merge(Dict(ModelingToolkit.unknowns(sys_complete) .=> ic_vals),
        Dict(ModelingToolkit.parameters(sys_complete) .=> p_true_vals)),
    [0.0, 20.0])
sol = solve(prob, AutoVern9(Rodas4P()); abstol=1e-14, reltol=1e-14, dense=true)

function compute_truth_at_t(sol_obj, t_eval, pvals; max_order=TRUTH_MAX_ORDER)
    n_st = 6
    tc = zeros(Float64, n_st, max_order + 1)
    s = sol_obj(t_eval)
    for i in 1:6; tc[i,1] = s[i]; end
    tp(a,b,k) = sum(a[j+1]*b[k-j+1] for j in 0:k)
    for k in 0:(max_order-1)
        S0c=tc[1,1:k+1]; C1c=tc[2,1:k+1]; C2c=tc[3,1:k+1]
        S1c=tc[4,1:k+1]; S2c=tc[5,1:k+1]; Ec=tc[6,1:k+1]
        kf1v,kr1v,kc1v,kf2v,kr2v,kc2v = pvals
        ES0=tp(Ec,S0c,k); ES1=tp(Ec,S1c,k)
        f = zeros(6)
        f[1]=-kf1v*ES0+kr1v*C1c[k+1]
        f[2]=kf1v*ES0-(kr1v+kc1v)*C1c[k+1]
        f[3]=kc1v*C1c[k+1]-(kr2v+kc2v)*C2c[k+1]+kf2v*ES1
        f[4]=-kf2v*ES1+kr2v*C2c[k+1]
        f[5]=kc2v*C2c[k+1]
        f[6]=-kf1v*ES0+kr1v*C1c[k+1]-kf2v*ES1+(kr2v+kc2v)*C2c[k+1]
        for i in 1:6; tc[i,k+2]=f[i]/(k+1); end
    end
    obs_idx_map = [1, 4, 5]  # S0, S1, S2
    obs_derivs = Vector{Vector{Float64}}(undef, 3)
    for (oi, si) in enumerate(obs_idx_map)
        obs_derivs[oi] = [Float64(tc[si,k+1]*factorial(big(k))) for k in 0:max_order]
    end
    all_state_derivs = Dict{String,Float64}()
    state_names = ["S0", "C1", "C2", "S1", "S2", "E"]
    for (si, sn) in enumerate(state_names)
        for k in 0:max_order
            all_state_derivs["$(sn)_$(k)"] = Float64(tc[si,k+1]*factorial(big(k)))
        end
    end
    return obs_derivs, all_state_derivs
end

# ═══════════════════════════════════════════════════════════════
# BUILD INTERPOLANTS
# ═══════════════════════════════════════════════════════════════
t_vec = collect(Float64, ds["t"])
obs_keys = [S0, states_list[4], states_list[5]]
obs_names = ["y0(S0)", "y1(S1)", "y2(S2)"]

aaad_interps = Any[]
agp_interps = Any[]
for okey in obs_keys
    y_data = collect(Float64, ds[okey])
    push!(aaad_interps, ODEParameterEstimation.aaad(t_vec, y_data))
    push!(agp_interps, ODEParameterEstimation.agp_gpr_robust(t_vec, y_data))
end

# ═══════════════════════════════════════════════════════════════
# CHOOSE EVALUATION POINT
# ═══════════════════════════════════════════════════════════════
# Point 3 (t=5.71) — best AAAD accuracy, representative interior point
t_eval = t_vec[572]
@printf("EVALUATION POINT: t = %.6f (index 572)\n\n", t_eval)

truth_obs, truth_states = compute_truth_at_t(sol, t_eval, p_true_vals)
param_truth = Dict(
    "kf1_0" => 11.5, "kr1_0" => 300.0, "kc1_0" => 12.45,
    "kf2_0" => 11.15, "kr2_0" => 4.864, "kc2_0" => 428.13)

# ═══════════════════════════════════════════════════════════════
# SECTION A: THE 33 SYMBOLIC EQUATIONS (before data substitution)
# ═══════════════════════════════════════════════════════════════
println("=" ^ 120)
println("SECTION A: SYMBOLIC TEMPLATE EQUATIONS (before data substitution)")
println("=" ^ 120)
println("Total: $(length(template_equations)) equations\n")

all_template_vars = Set{Any}()
for eq in template_equations
    union!(all_template_vars, Symbolics.get_variables(eq))
end

for (i, eq) in enumerate(template_equations)
    vars = sort(collect(Symbolics.get_variables(eq)), by=string)
    n_v = length(vars)
    # Classify vars
    data_v = [v for v in vars if v in obs_data_vars]
    unknown_v = [v for v in vars if !(v in obs_data_vars)]
    println("Eq$i ($n_v vars, $(length(unknown_v)) unknowns, $(length(data_v)) data):")
    println("  $eq = 0")
    println("  unknowns: $(join(string.(unknown_v), ", "))")
    println("  data:     $(join(string.(data_v), ", "))")
    println()
end

# ═══════════════════════════════════════════════════════════════
# SECTION B: VARIABLE CATALOG
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 120)
println("SECTION B: VARIABLE CATALOG")
println("=" ^ 120)

println("\n--- DATA VARIABLES (12 total, substituted from interpolation) ---")
for (i, (v, oi, ord, vn)) in enumerate(data_var_info)
    @printf("  [D%02d] %-20s  obs=%d (%s)  order=%d\n", i, vn, oi, obs_names[oi], ord)
end

# Get the unknowns (what HC.jl solves for)
# Substitute data and find remaining variables
perfect_values = Dict{Any,Float64}()
for (v, oi, ord, vn) in data_var_info
    perfect_values[v] = truth_obs[oi][ord+1]
end

substituted = Symbolics.substitute.(template_equations, Ref(perfect_values))
kept_eqs = Any[]
kept_vars = Set{Any}()
for eq in substituted
    vars = Symbolics.get_variables(eq)
    if !isempty(vars)
        push!(kept_eqs, eq)
        union!(kept_vars, vars)
    end
end
varlist = sort(collect(kept_vars), by=string)
var_names = [string(v) for v in varlist]
n = length(varlist)

println("\n--- UNKNOWNS ($n total, solved by HC.jl) ---")
for (i, vn) in enumerate(var_names)
    category = if startswith(vn, "k")
        "parameter"
    elseif endswith(vn, "_0")
        "state IC"
    else
        "state deriv"
    end
    @printf("  [U%02d] %-20s  (%s)\n", i, vn, category)
end

# ═══════════════════════════════════════════════════════════════
# SECTION C: TRUE VALUES OF ALL VARIABLES AT t_eval
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 120)
@printf("SECTION C: TRUE VALUES AT t = %.6f\n", t_eval)
println("=" ^ 120)

# Build true solution vector
true_x = Float64[]
for vn in var_names
    if haskey(truth_states, vn)
        push!(true_x, truth_states[vn])
    elseif haskey(param_truth, vn)
        push!(true_x, param_truth[vn])
    else
        push!(true_x, NaN)
        @warn "Missing truth for $vn"
    end
end

println("\n--- DATA VARIABLE TRUE VALUES ---")
for (i, (v, oi, ord, vn)) in enumerate(data_var_info)
    @printf("  [D%02d] %-20s = %+22.15e\n", i, vn, truth_obs[oi][ord+1])
end

println("\n--- UNKNOWN TRUE VALUES ---")
for (i, vn) in enumerate(var_names)
    @printf("  [U%02d] %-20s = %+22.15e\n", i, vn, true_x[i])
end

# ═══════════════════════════════════════════════════════════════
# SECTION D: DATA VALUES (AAAD vs AGPRobust vs Truth)
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 120)
println("SECTION D: INTERPOLATED DATA VALUES (Truth vs AAAD vs AGPRobust)")
println("=" ^ 120)

aaad_values = Dict{Any,Float64}()
agp_values = Dict{Any,Float64}()

@printf("\n  %-20s %22s %22s %22s %12s %12s\n",
    "Variable", "Truth", "AAAD", "AGPRobust", "AAAD err%", "AGP err%")
println("  " * "─" ^ 108)

for (v, oi, ord, vn) in data_var_info
    tv = truth_obs[oi][ord+1]
    aaad_val = try
        ODEParameterEstimation.nth_deriv(x -> aaad_interps[oi](x), ord, t_eval)
    catch; NaN; end
    agp_val = try
        ODEParameterEstimation.nth_deriv(x -> agp_interps[oi](x), ord, t_eval)
    catch; NaN; end

    aaad_err = abs(tv) > 1e-15 ? abs((aaad_val - tv) / tv) * 100 : abs(aaad_val) * 100
    agp_err = abs(tv) > 1e-15 ? abs((agp_val - tv) / tv) * 100 : abs(agp_val) * 100

    @printf("  %-20s %+22.15e %+22.15e %+22.15e %11.6f%% %11.6f%%\n",
        vn, tv, aaad_val, agp_val, aaad_err, agp_err)

    aaad_values[v] = aaad_val
    agp_values[v] = agp_val
end

# ═══════════════════════════════════════════════════════════════
# SECTION E: HC.jl SOLUTIONS (all 33 values)
# ═══════════════════════════════════════════════════════════════
function solve_and_dump(label, data_vals)
    println("\n" * "─" ^ 80)
    println("  HC.jl with $label data")
    println("─" ^ 80)

    sub = Symbolics.substitute.(template_equations, Ref(data_vals))
    keqs = Any[]
    kvars = Set{Any}()
    for eq in sub
        vs = Symbolics.get_variables(eq)
        if !isempty(vs)
            push!(keqs, eq)
            union!(kvars, vs)
        end
    end
    vl = sort(collect(kvars), by=string)
    vn_local = [string(v) for v in vl]

    if length(keqs) != length(vl)
        println("  System: $(length(keqs)) eqs, $(length(vl)) vars — NOT SQUARE, skipping")
        return nothing
    end

    hc_system, hc_variables = ODEParameterEstimation.convert_to_hc_format(keqs, vl)
    result = HC.solve(hc_system; show_progress=false)
    all_sols = HC.solutions(result)

    println("  $(length(all_sols)) solutions found")

    solutions_data = []
    for (si, s) in enumerate(all_sols)
        sv = Float64[real(s[j]) for j in 1:length(s)]
        max_imag = maximum(abs.(imag.(s)))

        # Compute distance from truth
        # Need to match variable ordering
        truth_vec = Float64[]
        for vn in vn_local
            if haskey(truth_states, vn)
                push!(truth_vec, truth_states[vn])
            elseif haskey(param_truth, vn)
                push!(truth_vec, param_truth[vn])
            else
                push!(truth_vec, NaN)
            end
        end

        param_sum_rel = 0.0
        for (j, vn) in enumerate(vn_local)
            if haskey(param_truth, vn)
                tv = param_truth[vn]
                param_sum_rel += abs((sv[j] - tv) / tv)
            end
        end

        println()
        @printf("  SOLUTION %d (max|imag|=%.2e, Σ|param_rel_err|=%.6f):\n", si, max_imag, param_sum_rel)
        @printf("  %-20s %22s %22s %14s\n", "Variable", "HC.jl value", "True value", "rel_err%")
        println("  " * "─" ^ 78)
        for (j, vn) in enumerate(vn_local)
            tv = truth_vec[j]
            ev = sv[j]
            err = if isnan(tv)
                NaN
            elseif abs(tv) > 1e-15
                (ev - tv) / tv * 100
            else
                ev * 100
            end
            @printf("  %-20s %+22.15e %+22.15e %+13.6f%%\n", vn, ev, tv, err)
        end

        push!(solutions_data, (vn_local, sv, truth_vec, param_sum_rel))
    end
    return solutions_data
end

println("\n" * "=" ^ 120)
println("SECTION E: HC.jl SOLUTIONS — ALL 33 UNKNOWNS")
println("=" ^ 120)

perfect_sols = solve_and_dump("PERFECT", perfect_values)
aaad_sols = solve_and_dump("AAAD", aaad_values)
agp_sols = solve_and_dump("AGPRobust", agp_values)

# ═══════════════════════════════════════════════════════════════
# SECTION F: INSTANTIATED EQUATIONS (after data substitution)
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 120)
println("SECTION F: INSTANTIATED EQUATIONS (after substituting perfect data)")
println("=" ^ 120)
println("$(length(kept_eqs)) equations in $n unknowns\n")

for (i, eq) in enumerate(kept_eqs)
    vars = sort(collect(Symbolics.get_variables(eq)), by=string)
    println("Eq$i ($(length(vars)) vars):")
    println("  $eq = 0")
    println("  vars: $(join(string.(vars), ", "))")
    println()
end

# ═══════════════════════════════════════════════════════════════
# SECTION G: JACOBIAN ∂F/∂x AND SENSITIVITY dx/dd
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 120)
println("SECTION G: JACOBIAN ∂F/∂x AT TRUE SOLUTION")
println("=" ^ 120)

# Build compiled function
expr_fn = try
    Symbolics.build_function(kept_eqs, varlist; expression=Val(false))[1]
catch
    expr_code = Symbolics.build_function(kept_eqs, varlist; expression=Val(true))[1]
    eval(expr_code)
end

residual = expr_fn(true_x)
@printf("\nResidual at true solution: max|r| = %.4e\n", maximum(abs, residual))

# ∂F/∂x
J_x = ForwardDiff.jacobian(expr_fn, true_x)
cond_Jx = cond(J_x)
@printf("cond(∂F/∂x) = %.4e\n", cond_Jx)
@printf("rank(∂F/∂x) = %d (of %d)\n", rank(J_x), n)

# Print full Jacobian
println("\n--- FULL JACOBIAN ∂F/∂x ($n × $n) ---")
println("Rows = equations, Columns = unknowns")
@printf("%-6s", "")
for vn in var_names
    @printf(" %12s", vn[1:min(end,12)])
end
println()
println("─" ^ (6 + 13 * n))
for i in 1:n
    @printf("Eq%-3d ", i)
    for j in 1:n
        @printf(" %+12.4e", J_x[i,j])
    end
    println()
end

# SVD
svd_result = svd(J_x)
println("\n--- SINGULAR VALUES ---")
for (i, s) in enumerate(svd_result.S)
    @printf("  σ_%02d = %.6e\n", i, s)
end
@printf("\ncond = σ_max / σ_min = %.6e / %.6e = %.6e\n",
    svd_result.S[1], svd_result.S[end], svd_result.S[1] / svd_result.S[end])

# ═══════════════════════════════════════════════════════════════
# SECTION H: SENSITIVITY MATRIX dx/dd
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 120)
println("SECTION H: SENSITIVITY MATRIX dx/dd = -(∂F/∂x)^{-1} (∂F/∂d)")
println("=" ^ 120)

n_data = length(data_var_info)
J_d = zeros(n, n_data)
data_labels = String[]

for (di, (v, oi, ord, vn)) in enumerate(data_var_info)
    push!(data_labels, "$(obs_names[oi]) ord $ord")
    ε = 1e-7 * max(abs(perfect_values[v]), 1e-10)
    perturbed_plus = copy(perfect_values)
    perturbed_plus[v] += ε
    sub_plus = Symbolics.substitute.(template_equations, Ref(perturbed_plus))
    kept_plus = Any[]
    for eq in sub_plus
        vs = Symbolics.get_variables(eq)
        if !isempty(vs); push!(kept_plus, eq); end
    end
    expr_fn_plus = try
        Symbolics.build_function(kept_plus, varlist; expression=Val(false))[1]
    catch
        expr_code = Symbolics.build_function(kept_plus, varlist; expression=Val(true))[1]
        eval(expr_code)
    end
    res_plus = expr_fn_plus(true_x)
    J_d[:, di] = (res_plus - residual) / ε
end

sensitivity = -J_x \ J_d

println("\n--- FULL SENSITIVITY dx/dd ($n × $n_data) ---")
println("How a unit perturbation in data variable j shifts unknown i")
@printf("%-20s", "")
for dl in data_labels
    @printf(" %14s", dl[1:min(end,14)])
end
println()
println("─" ^ (20 + 15 * n_data))
for i in 1:n
    @printf("%-20s", var_names[i])
    for di in 1:n_data
        @printf(" %+14.6e", sensitivity[i, di])
    end
    println()
end

# ═══════════════════════════════════════════════════════════════
# SECTION I: ERROR CONTRIBUTION BREAKDOWN (AGPRobust)
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 120)
println("SECTION I: ERROR CONTRIBUTION BY DATA VARIABLE (AGPRobust)")
println("=" ^ 120)
println("For each unknown: contribution_j = (dx_i/dd_j) * Δd_j")
println("Δd = AGPRobust_value - truth\n")

data_errors = Float64[]
for (v, oi, ord, vn) in data_var_info
    push!(data_errors, agp_values[v] - perfect_values[v])
end

predicted_errors = sensitivity * data_errors

println("--- DATA ERRORS (AGPRobust - Truth) ---")
for (di, (v, oi, ord, vn)) in enumerate(data_var_info)
    @printf("  %-20s Δd = %+14.6e  (%.6f%%)\n", data_labels[di], data_errors[di],
        abs(perfect_values[v]) > 1e-15 ? abs(data_errors[di] / perfect_values[v]) * 100 : 0.0)
end

println("\n--- PREDICTED vs ACTUAL ERROR ---")
@printf("%-20s %14s %14s %14s\n", "Variable", "True", "Predicted", "Predicted err%")
println("─" ^ 65)
for i in 1:n
    tv = true_x[i]
    pred = tv + predicted_errors[i]
    pred_err = abs(tv) > 1e-15 ? (predicted_errors[i] / tv) * 100 : predicted_errors[i]
    @printf("%-20s %+14.6e %+14.6e %+13.4f%%\n", var_names[i], tv, pred, pred_err)
end

# Per-unknown breakdown: top 3 contributors for each parameter
println("\n--- TOP 3 DATA ERROR CONTRIBUTORS PER PARAMETER ---")
for i in 1:n
    vn = var_names[i]
    if !startswith(vn, "k"); continue; end
    contributions = [(sensitivity[i, di] * data_errors[di], data_labels[di],
                      data_errors[di], sensitivity[i, di]) for di in 1:n_data]
    sort!(contributions, by=x->abs(x[1]), rev=true)
    @printf("\n  %s (true = %.6f):\n", vn, true_x[i])
    for k in 1:min(3, length(contributions))
        c, dl, de, s = contributions[k]
        @printf("    %-25s Δd=%+12.4e  dx/dd=%+12.4e  contrib=%+12.4e\n", dl, de, s, c)
    end
end

# ═══════════════════════════════════════════════════════════════
# SECTION J: MACHINE-READABLE CSV-STYLE DUMP
# ═══════════════════════════════════════════════════════════════
println("\n" * "=" ^ 120)
println("SECTION J: MACHINE-READABLE DATA")
println("=" ^ 120)

println("\n--- VARIABLE_INDEX,NAME,TRUE_VALUE ---")
for (i, vn) in enumerate(var_names)
    @printf("%d,%s,%.15e\n", i, vn, true_x[i])
end

println("\n--- DATA_INDEX,NAME,OBS,ORDER,TRUE_VALUE,AAAD_VALUE,AGP_VALUE ---")
for (di, (v, oi, ord, vn)) in enumerate(data_var_info)
    tv = perfect_values[v]
    av = aaad_values[v]
    gv = agp_values[v]
    @printf("%d,%s,%d,%d,%.15e,%.15e,%.15e\n", di, vn, oi, ord, tv, av, gv)
end

println("\n--- JACOBIAN (row,col,value) ---")
for i in 1:n
    for j in 1:n
        if abs(J_x[i,j]) > 1e-20
            @printf("%d,%d,%.15e\n", i, j, J_x[i,j])
        end
    end
end

println("\n--- SENSITIVITY (unknown_idx,data_idx,value) ---")
for i in 1:n
    for di in 1:n_data
        if abs(sensitivity[i,di]) > 1e-20
            @printf("%d,%d,%.15e\n", i, di, sensitivity[i,di])
        end
    end
end

println("\n--- SINGULAR_VALUES ---")
for (i, s) in enumerate(svd_result.S)
    @printf("%d,%.15e\n", i, s)
end

println("\n" * "=" ^ 120)
println("DONE")
println("=" ^ 120)
flush(stdout)
