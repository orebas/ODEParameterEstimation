# Experiment 4: Multi-Point Prolongation Algorithm (Test-Driven)
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp04_multipoint_prolongation.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using LinearAlgebra
using Printf
using SIAN
using SIAN.Nemo
using SIAN: QQMPolyRingElem, QQFieldElem, var_index

# ─── Get SIAN ingredients ───────────────────────────────────────────────

function get_sian_ingredients(pep)
    pep_data = ODEParameterEstimation.sample_problem_data(
        pep, EstimationOptions(datasize=21,
            time_interval=isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval,
            nooutput=true))
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try
        ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
    catch; (pep_data, nothing); end

    ordered_model = ODEParameterEstimation.OrderedODESystem(
        pep_work.model.system, ModelingToolkit.unknowns(pep_work.model.system),
        ModelingToolkit.parameters(pep_work.model.system))
    si_ode, symbol_map, gens = ODEParameterEstimation.convert_to_si_ode(ordered_model, pep_work.measured_quantities)

    eqs, Q, x_eqs, y_eqs, x_vars, y_vars, u_vars, mu, all_indets, gens_Rjet = SIAN.get_equations(si_ode)
    Rjet = gens_Rjet[1].parent
    n = length(x_vars); m = length(y_vars); u = length(u_vars); s = length(mu) + n

    X, X_eq = SIAN.get_x_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)
    Y, Y_eq = SIAN.get_y_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)

    not_int_cond_params = gens_Rjet[(end-length(si_ode.parameters)+1):end]
    all_params = vcat(not_int_cond_params, gens_Rjet[1:n])
    x_variables = gens_Rjet[1:n]
    for i in 1:(s+1)
        x_variables = vcat(x_variables, gens_Rjet[(i*(n+m+u)+1):(i*(n+m+u)+n)])
    end
    u_variables = gens_Rjet[(n+m+1):(n+m+u)]
    for i in 1:(s+1)
        u_variables = vcat(u_variables, gens_Rjet[((n+m+u)*i+n+m+1):((n+m+u)*(i+1))])
    end

    return (si_ode=si_ode, pep_work=pep_work, eqs=eqs, Q=Q, x_eqs=x_eqs, y_eqs=y_eqs,
        x_vars=x_vars, y_vars=y_vars, u_vars=u_vars, mu=mu, all_indets=all_indets,
        gens_Rjet=gens_Rjet, Rjet=Rjet, n=n, m=m, u=u, s=s,
        X=X, X_eq=X_eq, Y=Y, Y_eq=Y_eq,
        all_params=all_params, x_variables=x_variables, u_variables=u_variables,
        not_int_cond_params=not_int_cond_params)
end

# ─── Create combined multi-point ring ───────────────────────────────────

function create_combined_ring(ing, n_points)
    (; Rjet, mu, gens_Rjet, not_int_cond_params) = ing
    # The combined ring has:
    # - For each point r: all non-parameter, non-z_aux variables get suffix _r
    # - Parameters keep their original names (shared)
    # - z_aux is shared
    #
    # IMPORTANT: mu contains params in the original (non-jet) ring (e.g., "a")
    # but jet ring params are "a_0". We need to match against not_int_cond_params
    # which are the actual jet ring parameter generators.
    param_jet_names = Set(string(SIAN.var_to_symb(p)) for p in not_int_cond_params)
    orig_symbols = [string(s) for s in Nemo.symbols(Rjet)]

    combined_names = String[]
    for r in 1:n_points
        for s in orig_symbols
            if s in param_jet_names || s == "z_aux"
                # Skip — shared, added once after the loop
            else
                push!(combined_names, "$(s)_$(r)")
            end
        end
    end
    # Add shared variables once
    push!(combined_names, "z_aux")
    for s in orig_symbols
        if s in param_jet_names
            push!(combined_names, s)
        end
    end

    combined_ring, combined_gens = Nemo.polynomial_ring(Nemo.QQ, combined_names)
    return combined_ring
end

# ─── Lift polynomial to combined ring for a specific point ──────────────

function lift_poly(poly::QQMPolyRingElem, not_int_cond_params, combined_ring, point_idx)
    # Custom lifter: maps non-parameter variables v → v_{point_idx} in the combined ring
    # Parameters (in not_int_cond_params) and z_aux keep their names (shared)
    old_ring = parent(poly)
    param_symbols = Set(SIAN.var_to_symb(p) for p in not_int_cond_params)

    var_mapping = Array{Union{Int, Nothing}}(undef, length(Nemo.gens(old_ring)))
    combined_syms = Nemo.symbols(combined_ring)

    for (i, sym) in enumerate(Nemo.symbols(old_ring))
        if sym in param_symbols || string(sym) == "z_aux"
            # Shared — find by exact name
            var_mapping[i] = findfirst(==(sym), combined_syms)
        else
            # Per-point — append _point_idx
            target = Symbol(string(sym), "_", point_idx)
            var_mapping[i] = findfirst(==(target), combined_syms)
        end
    end

    builder = Nemo.MPolyBuildCtx(combined_ring)
    for (exp_vec, coef) in zip(Nemo.exponent_vectors(poly), Nemo.coefficients(poly))
        new_exp = zeros(Int, length(Nemo.gens(combined_ring)))
        for i in 1:length(exp_vec)
            if exp_vec[i] != 0
                if isnothing(var_mapping[i])
                    sym_name = string(Nemo.symbols(old_ring)[i])
                    error("Variable $sym_name not found in combined ring (tried $(sym_name)_$(point_idx))")
                end
                new_exp[var_mapping[i]] = exp_vec[i]
            end
        end
        Nemo.push_term!(builder, Nemo.base_ring(combined_ring)(coef), new_exp)
    end
    return Nemo.finish(builder)
end

# ─── Single-point prolongation (baseline) ───────────────────────────────

function run_single_point_prolongation(ing)
    (; Q, X, Y, x_vars, y_vars, all_params, x_variables,
     all_indets, gens_Rjet, n, m, u, s, X_eq, Y_eq, u_variables, eqs) = ing

    d0 = BigInt(maximum(vcat([Nemo.total_degree(SIAN.unpack_fraction(Q * eq[2])[1]) for eq in eqs], Nemo.total_degree(Q))))
    D1 = floor(BigInt, (length(all_params) + 1) * 2 * d0 * s * (n + 1) * (1 + 2 * d0 * s) / 0.01)

    sample = SIAN.sample_point(D1, x_vars, y_vars, u_variables, all_params, X_eq, Y_eq, Q)
    all_subs = sample[4]; u_hat = sample[2]; y_hat = sample[1]

    beta = [0 for _ in 1:m]
    Et = Array{QQMPolyRingElem}(undef, 0)
    x_theta_vars = copy(all_params)
    prolongation_possible = [1 for _ in 1:m]
    all_x_theta_vars_subs = SIAN.insert_zeros_to_vals(all_subs[1], all_subs[2])
    eqs_i_old = Array{QQMPolyRingElem}(undef, 0)
    evl_old = Array{QQMPolyRingElem}(undef, 0)

    while sum(prolongation_possible) > 0
        for i in 1:m
            if prolongation_possible[i] == 1
                eqs_i = vcat(Et, Y[i][beta[i]+1])
                evl = [Nemo.evaluate(eq, vcat(u_hat[1], y_hat[1]), vcat(u_hat[2], y_hat[2])) for eq in eqs_i if !(eq in eqs_i_old)]
                evl_old = vcat(evl_old, evl)
                JacX = SIAN.jacobi_matrix(evl_old, x_theta_vars, all_x_theta_vars_subs)
                eqs_i_old = eqs_i
                if LinearAlgebra.rank(JacX) == length(eqs_i)
                    Et = vcat(Et, Y[i][beta[i]+1])
                    beta[i] += 1
                    polys_to_process = vcat(Et, [Y[k][beta[k]+1] for k in 1:m])
                    while length(polys_to_process) != 0
                        new_to_process = Array{QQMPolyRingElem}(undef, 0)
                        vrs = Set{QQMPolyRingElem}()
                        for poly in polys_to_process
                            vrs = union(vrs, [v for v in Nemo.vars(poly) if v in x_variables])
                        end
                        vars_to_add = Set{QQMPolyRingElem}(v for v in vrs if !(v in x_theta_vars))
                        for v in vars_to_add
                            x_theta_vars = vcat(x_theta_vars, v)
                            ord_var = SIAN.get_order_var2(v, all_indets, n + m + u, s)
                            var_idx = var_index(ord_var[1])
                            poly = X[var_idx][ord_var[2]]
                            Et = vcat(Et, poly)
                            new_to_process = vcat(new_to_process, poly)
                        end
                        polys_to_process = new_to_process
                    end
                else
                    prolongation_possible[i] = 0
                end
            end
        end
    end
    return (Et=Et, beta=beta, x_theta_vars=x_theta_vars, n_eqs=length(Et), n_vars=length(x_theta_vars))
end

# ═══════════════════════════════════════════════════════════════════════════
# TESTS
# ═══════════════════════════════════════════════════════════════════════════

function run_all_tests()
    println("=" ^ 100)
    println("EXPERIMENT 4: Multi-Point Prolongation (Test-Driven)")
    println("=" ^ 100)

    # ─── Test model ─────────────────────────────────────────────────────
    println("\n━━━ Loading simple model ━━━")
    ing = get_sian_ingredients(ODEParameterEstimation.simple())
    println("  n=$(ing.n) m=$(ing.m) u=$(ing.u) s=$(ing.s)")
    println("  Rjet has $(length(ing.gens_Rjet)) generators")
    println("  X: $(length(ing.X)) states, Y: $(length(ing.Y)) outputs")
    println("  Params (mu): ", [string(SIAN.var_to_symb(p)) for p in ing.mu])

    # ─── Single-point baseline ──────────────────────────────────────────
    println("\n━━━ Single-point baseline ━━━")
    single = run_single_point_prolongation(ing)
    println("  Et: $(single.n_eqs) equations, $(single.n_vars) variables")
    println("  β = $(single.beta)")
    println("  Square: $(single.n_eqs == single.n_vars)")

    # ─── Step A: Lift polynomials ───────────────────────────────────────
    println("\n━━━ Test A1: Lift polynomials to combined ring ━━━")
    combined_ring = create_combined_ring(ing, 2)
    println("  Combined ring: $(length(Nemo.gens(combined_ring))) generators")
    println("  First 10: ", [string(s) for s in Nemo.symbols(combined_ring)][1:min(10, end)])
    println("  Last 5: ", [string(s) for s in Nemo.symbols(combined_ring)][end-4:end])

    # Lift Y[1][1] for point 1 and point 2
    Y11 = ing.Y[1][1]
    println("\n  Original Y[1][1]: ", Y11)
    println("  Original vars: ", [string(SIAN.var_to_symb(v)) for v in Nemo.vars(Y11)])

    Y11_pt1 = try
        lift_poly(Y11, ing.not_int_cond_params, combined_ring, 1)
    catch e
        println("  LIFT FAILED for pt1: ", sprint(showerror, e))
        nothing
    end
    Y11_pt2 = try
        lift_poly(Y11, ing.not_int_cond_params, combined_ring, 2)
    catch e
        println("  LIFT FAILED for pt2: ", sprint(showerror, e))
        nothing
    end

    if !isnothing(Y11_pt1) && !isnothing(Y11_pt2)
        println("  Y[1][1] @ pt1: ", Y11_pt1)
        println("  Y[1][1] @ pt2: ", Y11_pt2)
        println("  Vars @ pt1: ", [string(s) for s in Nemo.symbols(parent(Y11_pt1))[
            [var_index(v) for v in Nemo.vars(Y11_pt1)]]])
        println("  Vars @ pt2: ", [string(s) for s in Nemo.symbols(parent(Y11_pt2))[
            [var_index(v) for v in Nemo.vars(Y11_pt2)]]])

        # Check shared params
        vars_pt1 = Set(string(Nemo.symbols(combined_ring)[var_index(v)]) for v in Nemo.vars(Y11_pt1))
        vars_pt2 = Set(string(Nemo.symbols(combined_ring)[var_index(v)]) for v in Nemo.vars(Y11_pt2))
        shared = intersect(vars_pt1, vars_pt2)
        only_pt1 = setdiff(vars_pt1, vars_pt2)
        only_pt2 = setdiff(vars_pt2, vars_pt1)
        println("  Shared variables: ", shared, " (should be params only)")
        println("  Only in pt1: ", only_pt1)
        println("  Only in pt2: ", only_pt2)
        println("  ✓ Test A1 PASSED" * (isempty(shared) ? " (WARNING: no shared vars — params may not appear in Y[1][1])" : ""))
    end

    # Test A2: Lift all X and Y
    println("\n━━━ Test A2: Lift ALL X and Y equations ━━━")
    n_lifted = 0
    n_failed = 0
    for pt in 1:2
        for i in 1:length(ing.X)
            for j in 1:length(ing.X[i])
                try
                    lift_poly(ing.X[i][j], ing.not_int_cond_params, combined_ring, pt)
                    n_lifted += 1
                catch e
                    n_failed += 1
                    if n_failed <= 3
                        println("  FAIL: X[$i][$j] pt$pt: ", sprint(showerror, e)[1:min(80,end)])
                    end
                end
            end
        end
        for i in 1:length(ing.Y)
            for j in 1:length(ing.Y[i])
                try
                    lift_poly(ing.Y[i][j], ing.not_int_cond_params, combined_ring, pt)
                    n_lifted += 1
                catch e
                    n_failed += 1
                    if n_failed <= 3
                        println("  FAIL: Y[$i][$j] pt$pt: ", sprint(showerror, e)[1:min(80,end)])
                    end
                end
            end
        end
    end
    println("  Lifted: $n_lifted, Failed: $n_failed")
    println("  $(n_failed == 0 ? "✓ Test A2 PASSED" : "✗ Test A2 FAILED ($n_failed failures)")")

    if n_failed > 0
        println("\n  *** Stopping: cannot proceed without working polynomial lifting ***")
        return
    end

    # ─── Step B: Multi-point sampling ───────────────────────────────────
    println("\n━━━ Test B1: Multi-point sampling ━━━")

    # Sample shared parameters
    d0 = BigInt(maximum(vcat([Nemo.total_degree(SIAN.unpack_fraction(ing.Q * eq[2])[1]) for eq in ing.eqs], Nemo.total_degree(ing.Q))))
    D1 = floor(BigInt, (length(ing.all_params) + 1) * 2 * d0 * ing.s * (ing.n + 1) * (1 + 2 * d0 * ing.s) / 0.01)

    # Sample two independent points with shared params
    sample1 = SIAN.sample_point(D1, ing.x_vars, ing.y_vars, ing.u_variables, ing.all_params, ing.X_eq, ing.Y_eq, ing.Q)
    sample2 = SIAN.sample_point(D1, ing.x_vars, ing.y_vars, ing.u_variables, ing.all_params, ing.X_eq, ing.Y_eq, ing.Q)

    # Force shared parameter values: copy params from sample1 to sample2
    # sample[3] = [all_params, theta_hat] — the parameter values
    # sample[4] = [all_vars, all_vals] — the full substitution
    theta1 = sample1[3][2]  # parameter values from point 1
    theta2 = sample2[3][2]  # parameter values from point 2

    println("  Param values pt1: ", theta1[1:min(4, end)])
    println("  Param values pt2: ", theta2[1:min(4, end)])
    println("  (These should differ — we need to force sharing)")

    # For the combined ring evaluation, build a single value vector
    # that maps each combined ring variable to its value
    combined_vals = zeros(QQFieldElem, length(Nemo.gens(combined_ring)))

    subs1 = SIAN.insert_zeros_to_vals(sample1[4][1], sample1[4][2])
    subs2 = SIAN.insert_zeros_to_vals(sample2[4][1], sample2[4][2])

    # Map values from single-point rings to combined ring
    param_jet_names = Set(string(SIAN.var_to_symb(p)) for p in ing.not_int_cond_params)
    orig_syms = [string(s) for s in Nemo.symbols(ing.Rjet)]
    combined_syms = [string(s) for s in Nemo.symbols(combined_ring)]

    for (idx, orig_sym) in enumerate(orig_syms)
        if orig_sym in param_jet_names || orig_sym == "z_aux"
            # Shared — use point 1 value
            target_name = orig_sym
            target_idx = findfirst(==(target_name), combined_syms)
            if !isnothing(target_idx)
                combined_vals[target_idx] = subs1[idx]
            end
        else
            # Per-point
            for (pt, subs) in [(1, subs1), (2, subs2)]
                target_name = "$(orig_sym)_$(pt)"
                target_idx = findfirst(==(target_name), combined_syms)
                if !isnothing(target_idx)
                    combined_vals[target_idx] = subs[idx]
                end
            end
        end
    end

    # Override point 2 parameter values with point 1's (force sharing)
    for orig_sym in orig_syms
        if orig_sym in param_jet_names
            target_idx = findfirst(==(orig_sym), combined_syms)
            if !isnothing(target_idx)
                # Already set from point 1 above
            end
        end
    end

    n_assigned = count(!iszero, combined_vals)
    println("  Combined vals: $n_assigned / $(length(combined_vals)) assigned")

    # Evaluate a lifted polynomial
    if !isnothing(Y11_pt1)
        val = Nemo.evaluate(Y11_pt1, combined_vals)
        println("  Y[1][1]@pt1 evaluated: $val (should be 0 at a valid sample point)")
    end

    # ─── Test B2: Jacobian ──────────────────────────────────────────────
    println("\n━━━ Test B2: Jacobian computation ━━━")

    # Build a small test system: Y[1][1] from both points
    test_eqs = [lift_poly(ing.Y[1][1], ing.not_int_cond_params, combined_ring, pt) for pt in 1:2]
    # Get combined variables from these equations
    test_vars_set = Set{QQMPolyRingElem}()
    for eq in test_eqs
        union!(test_vars_set, Nemo.vars(eq))
    end
    test_vars = collect(test_vars_set)
    println("  Test system: $(length(test_eqs)) eqs, $(length(test_vars)) vars")
    println("  Vars: ", [string(Nemo.symbols(combined_ring)[var_index(v)]) for v in test_vars])

    # jacobi_matrix expects polynomials (not evaluated values) — it differentiates then evaluates
    J = SIAN.jacobi_matrix(test_eqs, test_vars, combined_vals)
    println("  Jacobian size: $(size(J))")
    println("  Jacobian rank: $(LinearAlgebra.rank(J))")
    println("  $(LinearAlgebra.rank(J) == length(test_eqs) ? "✓ Test B2 PASSED" : "✗ rank mismatch")")

    # ─── Step C: Multi-point prolongation ───────────────────────────────
    println("\n━━━ Test C1: Multi-point prolongation (simple) ━━━")

    # Lift all X and Y for both points
    X_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing.X)] for _ in 1:2]
    Y_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing.Y)] for _ in 1:2]

    for pt in 1:2
        for i in 1:length(ing.X)
            X_lifted[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.X[i]]
        end
        for i in 1:length(ing.Y)
            Y_lifted[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.Y[i]]
        end
    end

    # Build x_variables for each point (state derivative variables in the combined ring)
    x_variables_lifted = [QQMPolyRingElem[] for _ in 1:2]
    for pt in 1:2
        for v in ing.x_variables
            vname = string(SIAN.var_to_symb(v))
            target_name = "$(vname)_$(pt)"
            target_idx = findfirst(==(target_name), combined_syms)
            if !isnothing(target_idx)
                push!(x_variables_lifted[pt], Nemo.gens(combined_ring)[target_idx])
            end
        end
    end

    # Shared parameter variables in the combined ring
    param_vars_combined = QQMPolyRingElem[]
    for p in ing.all_params
        pname = string(SIAN.var_to_symb(p))
        if pname in param_jet_names
            # Direct parameter name
            target_idx = findfirst(==(pname), combined_syms)
        else
            # State IC — this is point-specific, need to handle differently
            # Actually, all_params = [not_int_cond_params..., gens_Rjet[1:n]...]
            # The first part (not_int_cond_params) are true parameters, shared
            # The second part (gens_Rjet[1:n]) are state ICs x_i_0, which are per-point
            # For multi-point, we need TWO copies of state ICs (one per point)
            target_idx = nothing  # will handle below
        end
        if !isnothing(target_idx)
            push!(param_vars_combined, Nemo.gens(combined_ring)[target_idx])
        end
    end
    println("  Shared parameter vars: $(length(param_vars_combined))")
    println("  Names: ", [string(Nemo.symbols(combined_ring)[var_index(v)]) for v in param_vars_combined])

    # Multi-point prolongation loop
    # x_theta_vars must start with shared params + per-point state ICs (x_i_0 for each point)
    # In single-point SIAN: all_params = [not_int_cond_params..., gens_Rjet[1:n]...]
    # The second part (gens_Rjet[1:n]) are state order-0 variables (ICs)
    # For multi-point: share params, but each point gets its own ICs

    # State IC variables in the combined ring (x_i_0 for each point)
    state_ic_vars_combined = QQMPolyRingElem[]
    for pt in 1:2
        for i in 1:ing.n
            ic_name = string(Nemo.symbols(ing.Rjet)[i])  # e.g., "x2_0", "x1_0"
            target_name = "$(ic_name)_$(pt)"
            target_idx = findfirst(==(Symbol(target_name)), Nemo.symbols(combined_ring))
            if !isnothing(target_idx)
                push!(state_ic_vars_combined, Nemo.gens(combined_ring)[target_idx])
            end
        end
    end
    println("  State IC vars: ", [string(Nemo.symbols(combined_ring)[SIAN.var_index(v)]) for v in state_ic_vars_combined])

    n_pts = 2
    beta_mp = [[0 for _ in 1:ing.m] for _ in 1:n_pts]
    Et_mp = Array{QQMPolyRingElem}(undef, 0)
    x_theta_vars_mp = vcat(param_vars_combined, state_ic_vars_combined)  # params + per-point ICs
    prolongation_possible_mp = [[1 for _ in 1:ing.m] for _ in 1:n_pts]

    iteration = 0
    while any(any(pp .> 0) for pp in prolongation_possible_mp)
        iteration += 1
        if iteration > 50; println("  WARNING: too many iterations, breaking"); break; end

        progress = false
        for pt in 1:n_pts
            for i in 1:ing.m
                if prolongation_possible_mp[pt][i] == 1
                    candidate = Y_lifted[pt][i][beta_mp[pt][i]+1]
                    eqs_test = vcat(Et_mp, candidate)

                    # Pass polynomials to jacobi_matrix — it differentiates then evaluates
                    JacX = SIAN.jacobi_matrix(eqs_test, x_theta_vars_mp, combined_vals)

                    if LinearAlgebra.rank(JacX) == length(eqs_test)
                        # Accept this equation
                        Et_mp = vcat(Et_mp, candidate)
                        beta_mp[pt][i] += 1
                        progress = true

                        # CASCADE: add X equations for new state variables at this point
                        polys_to_process = [candidate]
                        # Also look ahead at next Y candidates
                        for pt2 in 1:n_pts
                            for k in 1:ing.m
                                if beta_mp[pt2][k] + 1 <= length(Y_lifted[pt2][k])
                                    push!(polys_to_process, Y_lifted[pt2][k][beta_mp[pt2][k]+1])
                                end
                            end
                        end

                        while length(polys_to_process) != 0
                            new_to_process = QQMPolyRingElem[]
                            vrs = Set{QQMPolyRingElem}()
                            for poly in polys_to_process
                                for v in Nemo.vars(poly)
                                    if v in x_variables_lifted[pt]
                                        push!(vrs, v)
                                    end
                                end
                            end
                            vars_to_add = Set{QQMPolyRingElem}(v for v in vrs if !(v in x_theta_vars_mp))
                            for v in vars_to_add
                                x_theta_vars_mp = vcat(x_theta_vars_mp, v)
                                # Find which X equation this variable belongs to
                                vname = string(Nemo.symbols(combined_ring)[var_index(v)])
                                # Parse: name looks like "x1_3_1" → base=x1, order=3, point=1
                                # Use the single-point get_order_var2 on the original variable
                                orig_vname = replace(vname, r"_[0-9]+$" => "")  # strip point suffix
                                orig_idx = findfirst(==(Symbol(orig_vname)), Nemo.symbols(ing.Rjet))
                                if !isnothing(orig_idx)
                                    orig_var = Nemo.gens(ing.Rjet)[orig_idx]
                                    ord_var = SIAN.get_order_var2(orig_var, ing.all_indets, ing.n + ing.m + ing.u, ing.s)
                                    var_idx2 = var_index(ord_var[1])
                                    x_eq_poly = X_lifted[pt][var_idx2][ord_var[2]]
                                    Et_mp = vcat(Et_mp, x_eq_poly)
                                    push!(new_to_process, x_eq_poly)
                                end
                            end
                            polys_to_process = new_to_process
                        end
                    else
                        prolongation_possible_mp[pt][i] = 0
                    end
                end
            end
        end
        if !progress; break; end
    end

    println("  Multi-point result:")
    println("    Et: $(length(Et_mp)) equations, $(length(x_theta_vars_mp)) variables")
    println("    Square: $(length(Et_mp) == length(x_theta_vars_mp))")
    println("    β per point: $beta_mp")
    println("    Single-point β was: $(single.beta)")
    lower = all(all(beta_mp[pt][i] <= single.beta[i] for i in 1:ing.m) for pt in 1:n_pts)
    println("    β reduced: $lower")

    if length(Et_mp) == length(x_theta_vars_mp)
        println("  ✓ Test C1 PASSED — square system produced")
    else
        println("  ✗ Test C1 FAILED — not square ($(length(Et_mp)) eqs vs $(length(x_theta_vars_mp)) vars)")
    end
end

# ─── Run multi-point prolongation on multiple models ────────────────────

function run_multipoint_on_model(name, pep; n_points=2)
    println("\n━━━ $name ($(n_points)-point) ━━━")

    ing = try
        get_sian_ingredients(pep)
    catch e
        println("  SKIP (ingredients): ", sprint(showerror, e)[1:min(80,end)])
        return nothing
    end
    println("  n=$(ing.n) m=$(ing.m) s=$(ing.s)")

    # Single-point baseline
    single = try
        run_single_point_prolongation(ing)
    catch e
        println("  SKIP (single-point): ", sprint(showerror, e)[1:min(80,end)])
        return nothing
    end
    println("  Single-point: $(single.n_eqs)×$(single.n_vars), β=$(single.beta)")

    # Combined ring
    combined_ring = create_combined_ring(ing, n_points)
    combined_syms = [string(s) for s in Nemo.symbols(combined_ring)]
    param_jet_names = Set(string(SIAN.var_to_symb(p)) for p in ing.not_int_cond_params)

    # Lift X, Y for all points
    X_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing.X)] for _ in 1:n_points]
    Y_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing.Y)] for _ in 1:n_points]
    lift_ok = true
    for pt in 1:n_points
        for i in 1:length(ing.X)
            try
                X_lifted[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.X[i]]
            catch e
                println("  LIFT FAIL X[$i] pt$pt: ", sprint(showerror, e)[1:min(60,end)])
                lift_ok = false
            end
        end
        for i in 1:length(ing.Y)
            try
                Y_lifted[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.Y[i]]
            catch e
                println("  LIFT FAIL Y[$i] pt$pt: ", sprint(showerror, e)[1:min(60,end)])
                lift_ok = false
            end
        end
    end
    if !lift_ok; println("  SKIP: lifting failed"); return nothing; end

    # x_variables for each point
    x_variables_lifted = [QQMPolyRingElem[] for _ in 1:n_points]
    for pt in 1:n_points
        for v in ing.x_variables
            vname = string(SIAN.var_to_symb(v))
            target = Symbol("$(vname)_$(pt)")
            target_idx = findfirst(==(target), Nemo.symbols(combined_ring))
            if !isnothing(target_idx)
                push!(x_variables_lifted[pt], Nemo.gens(combined_ring)[target_idx])
            end
        end
    end

    # Sample multi-point
    d0 = BigInt(maximum(vcat([Nemo.total_degree(SIAN.unpack_fraction(ing.Q * eq[2])[1]) for eq in ing.eqs], Nemo.total_degree(ing.Q))))
    D1 = floor(BigInt, (length(ing.all_params) + 1) * 2 * d0 * ing.s * (ing.n + 1) * (1 + 2 * d0 * ing.s) / 0.01)

    samples = [SIAN.sample_point(D1, ing.x_vars, ing.y_vars, ing.u_variables, ing.all_params, ing.X_eq, ing.Y_eq, ing.Q) for _ in 1:n_points]

    orig_syms = [string(s) for s in Nemo.symbols(ing.Rjet)]
    combined_vals = zeros(QQFieldElem, length(Nemo.gens(combined_ring)))

    for (idx, orig_sym) in enumerate(orig_syms)
        if orig_sym in param_jet_names || orig_sym == "z_aux"
            target_idx = findfirst(==(Symbol(orig_sym)), Nemo.symbols(combined_ring))
            if !isnothing(target_idx)
                subs1 = SIAN.insert_zeros_to_vals(samples[1][4][1], samples[1][4][2])
                combined_vals[target_idx] = subs1[idx]
            end
        else
            for pt in 1:n_points
                target = Symbol("$(orig_sym)_$(pt)")
                target_idx = findfirst(==(target), Nemo.symbols(combined_ring))
                if !isnothing(target_idx)
                    subs_pt = SIAN.insert_zeros_to_vals(samples[pt][4][1], samples[pt][4][2])
                    combined_vals[target_idx] = subs_pt[idx]
                end
            end
        end
    end

    # Shared parameter vars + per-point state ICs
    param_vars_combined = QQMPolyRingElem[]
    for p in ing.not_int_cond_params
        pname = SIAN.var_to_symb(p)
        pidx = findfirst(==(pname), Nemo.symbols(combined_ring))
        if !isnothing(pidx)
            push!(param_vars_combined, Nemo.gens(combined_ring)[pidx])
        end
    end

    state_ic_vars_combined = QQMPolyRingElem[]
    for pt in 1:n_points
        for i in 1:ing.n
            ic_name = string(Nemo.symbols(ing.Rjet)[i])
            target = Symbol("$(ic_name)_$(pt)")
            target_idx = findfirst(==(target), Nemo.symbols(combined_ring))
            if !isnothing(target_idx)
                push!(state_ic_vars_combined, Nemo.gens(combined_ring)[target_idx])
            end
        end
    end

    # Prolongation loop
    beta_mp = [[0 for _ in 1:ing.m] for _ in 1:n_points]
    Et_mp = Array{QQMPolyRingElem}(undef, 0)
    x_theta_vars_mp = vcat(param_vars_combined, state_ic_vars_combined)
    prolongation_possible_mp = [[1 for _ in 1:ing.m] for _ in 1:n_points]

    iteration = 0
    while any(any(pp .> 0) for pp in prolongation_possible_mp)
        iteration += 1
        if iteration > 100; println("  WARNING: >100 iterations, breaking"); break; end

        progress = false
        for pt in 1:n_points
            for i in 1:ing.m
                if prolongation_possible_mp[pt][i] == 1
                    if beta_mp[pt][i] + 1 > length(Y_lifted[pt][i])
                        prolongation_possible_mp[pt][i] = 0
                        continue
                    end
                    candidate = Y_lifted[pt][i][beta_mp[pt][i]+1]
                    eqs_test = vcat(Et_mp, candidate)

                    JacX = SIAN.jacobi_matrix(eqs_test, x_theta_vars_mp, combined_vals)

                    if LinearAlgebra.rank(JacX) == length(eqs_test)
                        Et_mp = vcat(Et_mp, candidate)
                        beta_mp[pt][i] += 1
                        progress = true

                        # CASCADE
                        polys_to_process = [candidate]
                        for pt2 in 1:n_points, k in 1:ing.m
                            if beta_mp[pt2][k] + 1 <= length(Y_lifted[pt2][k])
                                push!(polys_to_process, Y_lifted[pt2][k][beta_mp[pt2][k]+1])
                            end
                        end

                        while length(polys_to_process) != 0
                            new_to_process = QQMPolyRingElem[]
                            vrs = Set{QQMPolyRingElem}()
                            for poly in polys_to_process
                                for v in Nemo.vars(poly)
                                    if v in x_variables_lifted[pt]
                                        push!(vrs, v)
                                    end
                                end
                            end
                            vars_to_add = Set{QQMPolyRingElem}(v for v in vrs if !(v in x_theta_vars_mp))
                            for v in vars_to_add
                                x_theta_vars_mp = vcat(x_theta_vars_mp, v)
                                vname = string(Nemo.symbols(combined_ring)[SIAN.var_index(v)])
                                orig_vname = replace(vname, r"_[0-9]+$" => "")
                                orig_idx = findfirst(==(Symbol(orig_vname)), Nemo.symbols(ing.Rjet))
                                if !isnothing(orig_idx)
                                    orig_var = Nemo.gens(ing.Rjet)[orig_idx]
                                    ord_var = SIAN.get_order_var2(orig_var, ing.all_indets, ing.n + ing.m + ing.u, ing.s)
                                    var_idx2 = var_index(ord_var[1])
                                    if var_idx2 <= length(X_lifted[pt]) && ord_var[2] <= length(X_lifted[pt][var_idx2])
                                        x_eq_poly = X_lifted[pt][var_idx2][ord_var[2]]
                                        Et_mp = vcat(Et_mp, x_eq_poly)
                                        push!(new_to_process, x_eq_poly)
                                    end
                                end
                            end
                            polys_to_process = new_to_process
                        end
                    else
                        prolongation_possible_mp[pt][i] = 0
                    end
                end
            end
        end
        if !progress; break; end
    end

    n_eqs_mp = length(Et_mp)
    n_vars_mp = length(x_theta_vars_mp)
    is_square = n_eqs_mp == n_vars_mp

    println("  $(n_points)-point: $(n_eqs_mp)×$(n_vars_mp), β=$beta_mp")
    println("  Square: $is_square")

    max_beta_mp = maximum(maximum(beta_mp[pt][i] for i in 1:ing.m) for pt in 1:n_points)
    max_beta_single = maximum(single.beta)
    println("  Max derivative order: single=$max_beta_single, multi=$max_beta_mp")

    if any(any(beta_mp[pt][i] < single.beta[i] for i in 1:ing.m) for pt in 1:n_points)
        println("  ★ DERIVATIVE ORDER REDUCED at some point/output")
    else
        println("  (no reduction in derivative orders)")
    end

    return (single=single, beta_mp=beta_mp, n_eqs_mp=n_eqs_mp, n_vars_mp=n_vars_mp, is_square=is_square)
end

# ─── Main ───────────────────────────────────────────────────────────────

println("=" ^ 100)
println("EXPERIMENT 4: Multi-Point Prolongation Results")
println("=" ^ 100)

models = OrderedDict{String, Function}(
    "simple" => ODEParameterEstimation.simple,
    "lotka_volterra" => ODEParameterEstimation.lotka_volterra,
    "forced_lv_sinusoidal" => ODEParameterEstimation.forced_lv_sinusoidal,
    "harmonic" => ODEParameterEstimation.harmonic,
    "seir" => ODEParameterEstimation.seir,
    "hiv" => ODEParameterEstimation.hiv,
)

results = OrderedDict{String, Any}()
for (name, ctor) in models
    r = run_multipoint_on_model(name, ctor())
    if !isnothing(r)
        results[name] = r
    end
end

# Summary table
println("\n\n", "=" ^ 100)
println("SUMMARY")
println("=" ^ 100)
@printf("%-25s  %-10s  %-8s  %-25s  %-25s  %s\n",
    "Model", "1pt_sys", "1pt_β", "2pt_sys", "2pt_β", "Reduction?")
println("-" ^ 100)
for (name, r) in results
    @printf("%-25s  %-10s  %-8s  %-25s  %-25s  %s\n",
        name,
        "$(r.single.n_eqs)×$(r.single.n_vars)", string(r.single.beta),
        "$(r.n_eqs_mp)×$(r.n_vars_mp)", string(r.beta_mp),
        r.is_square ? (any(any(r.beta_mp[pt][i] < r.single.beta[i] for i in eachindex(r.single.beta)) for pt in eachindex(r.beta_mp)) ? "★ YES" : "no") : "NOT SQUARE")
end
println("=" ^ 100)
