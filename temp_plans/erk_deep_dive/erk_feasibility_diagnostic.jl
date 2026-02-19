#!/usr/bin/env julia
#
# ERK Polynomial System Feasibility Diagnostic
# =============================================
# Answers three questions:
# 1. Does the true solution satisfy the SIAN polynomial system?
# 2. Are interpolated derivatives accurate enough at interior points?
# 3. Can HC.jl find the true solution with best-available data?
#
# Run: julia temp_plans/erk_deep_dive/erk_feasibility_diagnostic.jl

using ODEParameterEstimation
using ModelingToolkit
using DifferentialEquations
using OrderedCollections
using LinearAlgebra
using Printf
using Symbolics

println("=" ^ 70)
println("  ERK POLYNOMIAL SYSTEM FEASIBILITY DIAGNOSTIC")
println("=" ^ 70)
println()

# ─────────────────────────────────────────────────────────────────────
# STEP 1: ERK Setup and High-Accuracy ODE Solution
# ─────────────────────────────────────────────────────────────────────
println("STEP 1: Setting up ERK model and solving ODE with high accuracy...")

@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t) y0(t) y1(t) y2(t)
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

@named erk_model = ODESystem(eqs, t, states, parameters)
measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]

# True parameter values and initial conditions
p_true_vals = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]
ic_vals = [5.0, 0.0, 0.0, 0.0, 0.0, 0.65]
time_interval = [0.0, 20.0]
datasize = 2001

p_true_dict = Dict(parameters .=> p_true_vals)
ic_dict = Dict(states .=> ic_vals)

println("  Parameters: kf1=$(p_true_vals[1]), kr1=$(p_true_vals[2]), kc1=$(p_true_vals[3]), " *
        "kf2=$(p_true_vals[4]), kr2=$(p_true_vals[5]), kc2=$(p_true_vals[6])")
println("  ICs: S0=$(ic_vals[1]), C1=$(ic_vals[2]), C2=$(ic_vals[3]), " *
        "S1=$(ic_vals[4]), S2=$(ic_vals[5]), E=$(ic_vals[6])")

# Generate data sample (2001 points, same as production)
data_sample = ODEParameterEstimation.sample_data(
    erk_model, measured_quantities, time_interval,
    p_true_dict, ic_dict, datasize;
    solver=AutoVern9(Rodas4P()),
)

# Also solve with high accuracy for ground truth state access at any t
sys_complete = complete(erk_model)
prob = ODEProblem(
    sys_complete,
    merge(Dict(ModelingToolkit.unknowns(sys_complete) .=> ic_vals),
          Dict(ModelingToolkit.parameters(sys_complete) .=> p_true_vals)),
    time_interval,
)
sol = solve(prob, AutoVern9(Rodas4P()); abstol=1e-14, reltol=1e-14, saveat=range(0, 20, length=datasize))

t_eval = 10.0  # Interior point — no AAAD pole issues
state_at_t = sol(t_eval)
println("  States at t=$t_eval: ", [@sprintf("%.6f", v) for v in state_at_t])
println("  STEP 1 DONE ✓")
println()

# ─────────────────────────────────────────────────────────────────────
# STEP 2: Compute Ground-Truth Derivatives via Symbolic Lie Derivatives
# ─────────────────────────────────────────────────────────────────────
println("STEP 2: Computing ground-truth Lie derivatives symbolically...")

# Define purely symbolic variables (no time dependence) for Lie derivative computation
@variables S0_v C1_v C2_v S1_v S2_v E_v
@variables kf1_v kr1_v kc1_v kf2_v kr2_v kc2_v

sym_states = [S0_v, C1_v, C2_v, S1_v, S2_v, E_v]
sym_params = [kf1_v, kr1_v, kc1_v, kf2_v, kr2_v, kc2_v]

# ERK RHS as symbolic expressions (no time dependence)
f_rhs = [
    -kf1_v * E_v * S0_v + kr1_v * C1_v,                                     # dS0/dt
    kf1_v * E_v * S0_v - (kr1_v + kc1_v) * C1_v,                           # dC1/dt
    kc1_v * C1_v - (kr2_v + kc2_v) * C2_v + kf2_v * E_v * S1_v,          # dC2/dt
    -kf2_v * E_v * S1_v + kr2_v * C2_v,                                     # dS1/dt
    kc2_v * C2_v,                                                            # dS2/dt
    -kf1_v * E_v * S0_v + kr1_v * C1_v - kf2_v * E_v * S1_v + (kr2_v + kc2_v) * C2_v,  # dE/dt
]

# Observables: y0=S0, y1=S1, y2=S2  →  indices [1, 4, 5] into sym_states
obs_state_indices = [1, 4, 5]  # S0_v is states[1], S1_v is states[4], S2_v is states[5]

max_lie_order = 12

# Compute Lie derivatives: L^k(obs_i) = Lie derivative of order k
# L^0(obs_i) = obs_i
# L^k(obs_i) = sum_j (dL^{k-1}/dx_j) * f_j
println("  Computing Lie derivatives up to order $max_lie_order for 3 observables...")
lie_derivs = Vector{Vector{Any}}(undef, 3)  # lie_derivs[obs_idx][order+1]

for (oi, state_idx) in enumerate(obs_state_indices)
    lie_derivs[oi] = Any[sym_states[state_idx]]  # order 0
    for k in 1:max_lie_order
        prev = lie_derivs[oi][end]
        # Lie derivative: sum over all states of (d(prev)/d(state_j)) * f_j
        lie_k = sum(Symbolics.derivative(prev, sym_states[j]) * f_rhs[j] for j in 1:6)
        lie_k_expanded = Symbolics.expand(lie_k)
        push!(lie_derivs[oi], lie_k_expanded)
        nv = length(Symbolics.get_variables(lie_k_expanded))
        if k <= 4  # Only print first few
            println("    L^$k(obs_$oi): $nv unique variables")
        end
    end
    println("    ... (completed up to order $max_lie_order)")
end

# Evaluate at the true state values and parameters at t=t_eval
eval_dict = Dict{Any,Float64}()
for (i, v) in enumerate(sym_states)
    eval_dict[v] = state_at_t[i]
end
for (i, v) in enumerate(sym_params)
    eval_dict[v] = p_true_vals[i]
end

# Compute ground-truth derivative values
truth_derivs = Vector{Vector{Float64}}(undef, 3)
for oi in 1:3
    truth_derivs[oi] = Float64[]
    for k in 0:max_lie_order
        expr = lie_derivs[oi][k+1]
        val = Float64(Symbolics.value(Symbolics.substitute(expr, eval_dict)))
        push!(truth_derivs[oi], val)
    end
end

println("\n  Ground-truth derivatives at t=$t_eval:")
for oi in 1:3
    obs_name = ["y0(S0)", "y1(S1)", "y2(S2)"][oi]
    println("    $obs_name:")
    for k in 0:min(5, max_lie_order)
        @printf("      order %2d: %20.10e\n", k, truth_derivs[oi][k+1])
    end
    println("      ...")
end
println("  STEP 2 DONE ✓")
println()

# ─────────────────────────────────────────────────────────────────────
# STEP 3: Build Interpolants and Compare Derivatives
# ─────────────────────────────────────────────────────────────────────
println("STEP 3: Building interpolants and comparing derivatives at t=$t_eval...")

t_data = data_sample["t"]

# Build AAAD and AGPRobust interpolants for each observable
# Keys in data_sample are the Num(rhs) of measured quantities
obs_rhs_syms = [S0, S1, S2]  # RHS of measured_quantities
aaad_interps = []
agpr_interps = []

for (oi, obs_sym) in enumerate(obs_rhs_syms)
    y_data = data_sample[Num(obs_sym)]
    push!(aaad_interps, ODEParameterEstimation.aaad(collect(t_data), collect(y_data)))
    push!(agpr_interps, ODEParameterEstimation.agp_gpr_robust(collect(t_data), collect(y_data)))
end

# Compute interpolated derivatives at t_eval
# Only compute up to order that the SIAN system actually needs (will determine in Step 4)
# For now, compute what we can — AAAD can handle high orders, AGP may struggle
max_interp_order = min(max_lie_order, 12)

aaad_derivs = Vector{Vector{Float64}}(undef, 3)
agpr_derivs = Vector{Vector{Float64}}(undef, 3)

for oi in 1:3
    aaad_derivs[oi] = Float64[]
    agpr_derivs[oi] = Float64[]
    for k in 0:max_interp_order
        aaad_val = try
            ODEParameterEstimation.nth_deriv(x -> aaad_interps[oi](x), k, t_eval)
        catch e
            NaN
        end
        agpr_val = try
            ODEParameterEstimation.nth_deriv(x -> agpr_interps[oi](x), k, t_eval)
        catch e
            NaN
        end
        push!(aaad_derivs[oi], aaad_val)
        push!(agpr_derivs[oi], agpr_val)
    end
end

# Print comparison table
println("\n  DERIVATIVE COMPARISON AT t=$t_eval:")
println("  " * "-" ^ 115)
@printf("  %-5s %-5s %20s %20s %20s %12s %12s\n",
    "Obs", "Order", "Truth", "AAAD", "AGPRobust", "AAAD err%", "AGPR err%")
println("  " * "-" ^ 115)

for oi in 1:3
    obs_name = ["y0", "y1", "y2"][oi]
    for k in 0:max_interp_order
        truth = truth_derivs[oi][k+1]
        aaad_val = aaad_derivs[oi][k+1]
        agpr_val = agpr_derivs[oi][k+1]
        aaad_err = abs(truth) > 1e-15 ? abs((aaad_val - truth) / truth) * 100 : abs(aaad_val - truth)
        agpr_err = abs(truth) > 1e-15 ? abs((agpr_val - truth) / truth) * 100 : abs(agpr_val - truth)
        @printf("  %-5s %5d %20.8e %20.8e %20.8e %11.4f%% %11.4f%%\n",
            obs_name, k, truth, aaad_val, agpr_val, aaad_err, agpr_err)
    end
end
println("  STEP 3 DONE ✓")
println()

# ─────────────────────────────────────────────────────────────────────
# STEP 4: Build the SIAN Template System
# ─────────────────────────────────────────────────────────────────────
println("STEP 4: Building SIAN polynomial template system...")

# Create the ordered ODE system
ordered_model, mq = create_ordered_ode_system(
    "ERK_diag", states, parameters, eqs, measured_quantities
)

# Build the DerivativeData structure
# First we need the deriv_level from SIAN — use the internal API
# populate_derivatives needs a max_deriv_level; SIAN determines this.
# We'll let get_si_equation_system handle it, then extract max_deriv from the result.

# Build DD with a generous derivative level (SIAN typically needs ≤12 for 6-state systems)
DD = ODEParameterEstimation.populate_derivatives(
    ordered_model.system, measured_quantities, 14, Dict()
)

println("  DD.obs_lhs levels: $(length(DD.obs_lhs)), obs per level: $(length(DD.obs_lhs[1]))")

# Get the SI.jl polynomial template
template_equations, y_derivative_dict, unidentifiable, identifiable_funcs =
    ODEParameterEstimation.get_si_equation_system(
        ordered_model, measured_quantities, data_sample;
        DD=DD, infolevel=1,
    )

println("  Template equations: $(length(template_equations))")
println("  Derivative dict: $y_derivative_dict")
println("  Max derivative order needed: $(isempty(y_derivative_dict) ? 0 : maximum(values(y_derivative_dict)))")
println("  Unidentifiable: $unidentifiable")

# Extract all variables in the template
all_template_vars = Set()
for eq in template_equations
    union!(all_template_vars, Set(Symbolics.get_variables(eq)))
end
println("  Total unique variables in template: $(length(all_template_vars))")

# Classify variables: data vars (from DD.obs_lhs) vs solve vars
max_deriv_needed = isempty(y_derivative_dict) ? 0 : maximum(values(y_derivative_dict))

data_var_set = Set()
data_var_list = []  # ordered
for order in 0:max_deriv_needed
    if order + 1 <= length(DD.obs_lhs)
        for obs_idx in 1:length(DD.obs_lhs[order+1])
            v = DD.obs_lhs[order+1][obs_idx]
            if v in all_template_vars
                push!(data_var_set, v)
                push!(data_var_list, (v, obs_idx, order))
            end
        end
    end
end

solve_vars = [v for v in all_template_vars if !(v in data_var_set)]

println("  Data variables (from DD.obs_lhs): $(length(data_var_set))")
for (v, obs_idx, order) in data_var_list
    @printf("    %s  (obs=%d, order=%d)\n", string(v), obs_idx, order)
end
println("  Solve variables (params + state ICs): $(length(solve_vars))")
for v in solve_vars
    println("    ", string(v))
end
println("  STEP 4 DONE ✓")
println()

# ─────────────────────────────────────────────────────────────────────
# STEP 5: Residual Check — Does the True Solution Satisfy the System?
# ─────────────────────────────────────────────────────────────────────
println("STEP 5: Checking if the TRUE solution satisfies the polynomial system...")

# Build substitution dict for ALL variables
sub_dict = Dict()

# Substitute data variables with ground-truth derivatives
for (v, obs_idx, order) in data_var_list
    sub_dict[v] = truth_derivs[obs_idx][order+1]
end

# Substitute solve variables with true parameter/state values
# Solve vars are Symbolics variables created by SIAN → DD mapping.
# Their names follow patterns like:
#   kf1_0 → parameter kf1 (order 0)
#   S0_0  → state S0 at evaluation time (order 0)
# We need to parse each name and map to the true value.

param_name_to_val = Dict(
    "kf1" => p_true_vals[1], "kr1" => p_true_vals[2], "kc1" => p_true_vals[3],
    "kf2" => p_true_vals[4], "kr2" => p_true_vals[5], "kc2" => p_true_vals[6],
)
state_name_to_val = Dict(
    "S0" => state_at_t[1], "C1" => state_at_t[2], "C2" => state_at_t[3],
    "S1" => state_at_t[4], "S2" => state_at_t[5], "E" => state_at_t[6],
)

println("  Mapping solve variables to true values:")
unmapped_vars = []
for v in solve_vars
    vname = string(v)
    parsed = ODEParameterEstimation.parse_derivative_variable_name(vname)

    if !isnothing(parsed)
        base_name, deriv_order = parsed
        if deriv_order == 0
            # Order-0 "jet variable" = the value itself
            if haskey(param_name_to_val, base_name)
                sub_dict[v] = param_name_to_val[base_name]
                @printf("    %s → param %s = %.6f\n", vname, base_name, sub_dict[v])
            elseif haskey(state_name_to_val, base_name)
                sub_dict[v] = state_name_to_val[base_name]
                @printf("    %s → state %s(t=%.1f) = %.6f\n", vname, base_name, t_eval, sub_dict[v])
            else
                push!(unmapped_vars, (v, vname, base_name, deriv_order))
            end
        else
            # Higher-order jet variable = derivative of state/param at t_eval
            # For states, these are the RHS evaluated at the true point
            # We can compute these from the Lie derivatives of the state
            if haskey(state_name_to_val, base_name)
                # Find which state index this is
                state_idx = findfirst(n -> n == base_name, ["S0", "C1", "C2", "S1", "S2", "E"])
                if !isnothing(state_idx)
                    # Compute the k-th time derivative of state state_idx at the true point
                    # This is the k-th Lie derivative of x_i evaluated at the true state
                    # Build it symbolically: the k-th time derivative of state i is obtained
                    # by differentiating the ODE RHS (k-1) times
                    # For simplicity, compute numerically from the ODE solution
                    state_deriv_val = try
                        ODEParameterEstimation.nth_deriv(tt -> sol(tt)[state_idx], deriv_order, t_eval)
                    catch
                        NaN
                    end
                    sub_dict[v] = state_deriv_val
                    @printf("    %s → d^%d %s/dt^%d(t=%.1f) = %.6e\n",
                        vname, deriv_order, base_name, deriv_order, t_eval, state_deriv_val)
                else
                    push!(unmapped_vars, (v, vname, base_name, deriv_order))
                end
            elseif haskey(param_name_to_val, base_name)
                # Parameters are constant → all time derivatives are 0
                sub_dict[v] = 0.0
                @printf("    %s → d^%d %s/dt^%d = 0 (constant param)\n",
                    vname, deriv_order, base_name, deriv_order)
            else
                push!(unmapped_vars, (v, vname, base_name, deriv_order))
            end
        end
    else
        push!(unmapped_vars, (v, vname, "", -1))
    end
end

if !isempty(unmapped_vars)
    println("\n  ⚠ UNMAPPED solve variables:")
    for (v, vname, base, order) in unmapped_vars
        println("    $vname (base=$base, order=$order)")
    end
end

# Evaluate residuals
residuals = Float64[]
println("\n  Residuals (equation by equation):")
for (i, eq) in enumerate(template_equations)
    val = try
        Float64(Symbolics.value(Symbolics.substitute(eq, sub_dict)))
    catch e
        @printf("    Eq%2d: SUBSTITUTION FAILED: %s\n", i, string(e))
        NaN
    end
    push!(residuals, val)
    flag = abs(val) > 1e-6 ? " ← LARGE" : ""
    @printf("    Eq%2d: residual = %20.10e%s\n", i, val, flag)
end

max_resid = maximum(abs.(filter(!isnan, residuals)))
println("\n  MAX |residual| with true solution: ", @sprintf("%.10e", max_resid))
if max_resid < 1e-6
    println("  ✓ TRUE SOLUTION SATISFIES THE SYSTEM (residuals ≈ 0)")
else
    println("  ✗ TRUE SOLUTION DOES NOT SATISFY THE SYSTEM!")
    println("    This means the polynomial system is structurally wrong or")
    println("    the variable mapping is incorrect.")
end
println("  STEP 5 DONE ✓")
println()

# ─────────────────────────────────────────────────────────────────────
# STEP 6: Solve with HC.jl Using Ground-Truth Data
# ─────────────────────────────────────────────────────────────────────
println("STEP 6: Solving with HC.jl using GROUND-TRUTH derivative data...")

# Substitute only the data variables with ground-truth values
data_sub_dict_truth = Dict()
for (v, obs_idx, order) in data_var_list
    data_sub_dict_truth[v] = truth_derivs[obs_idx][order+1]
end

subst_eqs_truth = Symbolics.substitute.(template_equations, Ref(data_sub_dict_truth))

# Filter trivial equations and extract remaining variables
kept_eqs_truth = []
final_vars_truth = Set()
for eq in subst_eqs_truth
    vars_in_eq = Symbolics.get_variables(eq)
    if !isempty(vars_in_eq)
        push!(kept_eqs_truth, eq)
        union!(final_vars_truth, vars_in_eq)
    end
end

final_vars_truth_vec = collect(final_vars_truth)
println("  After data substitution: $(length(kept_eqs_truth)) equations, $(length(final_vars_truth_vec)) variables")

# Solve with HC.jl
hc_solutions_truth = []
try
    hc_solutions_truth, _, _, _ = ODEParameterEstimation.solve_with_hc(
        kept_eqs_truth, final_vars_truth_vec;
        display_system=true,
    )
    println("  HC.jl found $(length(hc_solutions_truth)) solutions (including complex projections)")
catch e
    println("  HC.jl FAILED: ", string(e))
end

# Compare each solution to the true values
if !isempty(hc_solutions_truth)
    # Build true-value vector in the same variable order
    true_vec = Float64[]
    var_names_ordered = String[]
    for v in final_vars_truth_vec
        vname = string(v)
        push!(var_names_ordered, vname)
        if haskey(sub_dict, v)
            push!(true_vec, sub_dict[v])
        else
            push!(true_vec, NaN)
        end
    end

    println("\n  Variable order: ", var_names_ordered)
    println("  True values:    ", [@sprintf("%.4e", v) for v in true_vec])

    # Find closest solution
    best_dist = Inf
    best_idx = 0
    for (i, s) in enumerate(hc_solutions_truth)
        dist = norm(s .- true_vec)
        rel_err = norm((s .- true_vec) ./ max.(abs.(true_vec), 1e-10))
        @printf("  Solution %2d: dist=%.4e, rel_err=%.4e\n", i, dist, rel_err)
        if i <= 3  # Print first 3 in detail
            for (j, vn) in enumerate(var_names_ordered)
                err_pct = abs(true_vec[j]) > 1e-10 ?
                    abs((s[j] - true_vec[j]) / true_vec[j]) * 100 : abs(s[j])
                @printf("    %-15s: sol=%.6e, true=%.6e, err=%.2f%%\n",
                    vn, s[j], true_vec[j], err_pct)
            end
        end
        if dist < best_dist
            best_dist = dist
            best_idx = i
        end
    end
    println("\n  CLOSEST solution: #$best_idx, distance=$(@sprintf("%.4e", best_dist))")
else
    println("  NO SOLUTIONS from HC.jl")
end

println("  STEP 6 DONE ✓")
println()

# ─────────────────────────────────────────────────────────────────────
# STEP 7: Solve with Interpolated Data (AAAD and AGPRobust)
# ─────────────────────────────────────────────────────────────────────
function solve_with_interp_data(interp_derivs, interp_name, template_equations, data_var_list, sub_dict, final_vars_truth_vec)
    println("  Solving with $interp_name interpolated data...")

    data_sub = Dict()
    for (v, obs_idx, order) in data_var_list
        if order + 1 <= length(interp_derivs[obs_idx])
            data_sub[v] = interp_derivs[obs_idx][order+1]
        else
            data_sub[v] = NaN
            println("    ⚠ Missing derivative: obs=$obs_idx, order=$order")
        end
    end

    subst_eqs = Symbolics.substitute.(template_equations, Ref(data_sub))

    kept_eqs = []
    final_vars = Set()
    for eq in subst_eqs
        vars_in_eq = Symbolics.get_variables(eq)
        if !isempty(vars_in_eq)
            push!(kept_eqs, eq)
            union!(final_vars, vars_in_eq)
        end
    end

    println("    After substitution: $(length(kept_eqs)) equations, $(length(final_vars)) variables")

    solutions = []
    try
        solutions, _, _, _ = ODEParameterEstimation.solve_with_hc(kept_eqs, collect(final_vars))
        println("    HC.jl found $(length(solutions)) solutions")
    catch e
        println("    HC.jl FAILED: ", string(e))
    end

    # Compare to true
    if !isempty(solutions) && !isempty(final_vars_truth_vec)
        # Build true-value vector for this variable ordering
        fv_vec = collect(final_vars)
        true_vec = Float64[]
        for v in fv_vec
            if haskey(sub_dict, v)
                push!(true_vec, sub_dict[v])
            else
                push!(true_vec, NaN)
            end
        end

        best_dist = Inf
        best_idx = 0
        for (i, s) in enumerate(solutions)
            dist = norm(s .- true_vec)
            if dist < best_dist
                best_dist = dist
                best_idx = i
            end
        end
        rel_err = norm((solutions[best_idx] .- true_vec) ./ max.(abs.(true_vec), 1e-10))
        @printf("    CLOSEST solution: #%d, dist=%.4e, rel_err=%.4e\n", best_idx, best_dist, rel_err)

        # Print the closest solution details
        for (j, v) in enumerate(fv_vec)
            vname = string(v)
            s_val = solutions[best_idx][j]
            t_val = haskey(sub_dict, v) ? sub_dict[v] : NaN
            err_pct = abs(t_val) > 1e-10 ? abs((s_val - t_val) / t_val) * 100 : abs(s_val)
            @printf("      %-15s: sol=%.6e, true=%.6e, err=%.2f%%\n", vname, s_val, t_val, err_pct)
        end
    end

    return solutions
end

println("STEP 7: Solving with interpolated data...")
println()

println("  --- AAAD ---")
aaad_solutions = solve_with_interp_data(
    aaad_derivs, "AAAD", template_equations, data_var_list, sub_dict, final_vars_truth_vec)
println()

println("  --- AGPRobust ---")
agpr_solutions = solve_with_interp_data(
    agpr_derivs, "AGPRobust", template_equations, data_var_list, sub_dict, final_vars_truth_vec)

println("  STEP 7 DONE ✓")
println()

# ─────────────────────────────────────────────────────────────────────
# STEP 8: Summary Report
# ─────────────────────────────────────────────────────────────────────
println("=" ^ 70)
println("  DIAGNOSTIC SUMMARY")
println("=" ^ 70)
println()

println("1. RESIDUAL CHECK (true solution + true derivatives):")
@printf("   Max |residual|: %.4e\n", max_resid)
if max_resid < 1e-6
    println("   → System IS correct — true solution is a root")
else
    println("   → System may be WRONG or variable mapping is incorrect")
end
println()

println("2. DERIVATIVE ACCURACY at t=$t_eval (selected orders):")
for oi in 1:3
    obs_name = ["y0", "y1", "y2"][oi]
    for k in [0, 1, 2, 4, 8, max_interp_order]
        if k + 1 <= length(truth_derivs[oi])
            truth = truth_derivs[oi][k+1]
            aaad_err = abs(truth) > 1e-15 ?
                abs((aaad_derivs[oi][k+1] - truth) / truth) * 100 : abs(aaad_derivs[oi][k+1])
            agpr_err = abs(truth) > 1e-15 ?
                abs((agpr_derivs[oi][k+1] - truth) / truth) * 100 : abs(agpr_derivs[oi][k+1])
            @printf("   %s order %2d: AAAD err=%8.3f%%, AGPR err=%8.3f%%\n",
                obs_name, k, aaad_err, agpr_err)
        end
    end
end
println()

println("3. HC.jl WITH GROUND-TRUTH DATA:")
@printf("   # solutions: %d\n", length(hc_solutions_truth))
if !isempty(hc_solutions_truth)
    true_vec_for_summary = Float64[]
    for v in final_vars_truth_vec
        push!(true_vec_for_summary, get(sub_dict, v, NaN))
    end
    dists = [norm(s .- true_vec_for_summary) for s in hc_solutions_truth]
    @printf("   Closest solution distance: %.4e\n", minimum(dists))
end
println()

println("4. HC.jl WITH AAAD DATA:")
@printf("   # solutions: %d\n", length(aaad_solutions))
println()

println("5. HC.jl WITH AGPRobust DATA:")
@printf("   # solutions: %d\n", length(agpr_solutions))
println()

# Final conclusion
println("-" ^ 70)
if max_resid < 1e-6 && !isempty(hc_solutions_truth)
    best_true_dist = minimum([norm(s .- [get(sub_dict, v, NaN) for v in final_vars_truth_vec])
                              for s in hc_solutions_truth])
    if best_true_dist < 1e-3
        println("CONCLUSION: System is FEASIBLE — HC.jl finds the true solution with perfect data.")
        if isempty(aaad_solutions) && isempty(agpr_solutions)
            println("  → Interpolation derivatives are the bottleneck.")
        elseif !isempty(aaad_solutions) || !isempty(agpr_solutions)
            println("  → Check if interpolation-based solutions are close to truth.")
        end
    else
        println("CONCLUSION: System is correct but HC.jl MISSES the true root even with perfect data.")
        println("  → This is a path-tracking/monodromy coverage problem in HC.jl.")
    end
elseif max_resid < 1e-6 && isempty(hc_solutions_truth)
    println("CONCLUSION: System is correct (true solution satisfies it) but HC.jl finds 0 solutions.")
    println("  → Polynomial structure or degree may prevent total-degree homotopy from working.")
elseif max_resid >= 1e-6
    println("CONCLUSION: SYSTEM IS STRUCTURALLY WRONG — true solution doesn't satisfy it!")
    println("  → There is a fundamental issue with the SIAN template or variable mapping.")
end
println("-" ^ 70)
println()
println("Done!")
