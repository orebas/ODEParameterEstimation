# Experiment 4D: Solve multi-point prolongation systems with HC.jl
#
# Takes the multi-point system from exp04, converts Nemo → Symbolics → HC.jl, solves
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp04d_hcjl_solve.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using LinearAlgebra
using Printf
using Symbolics
using SIAN
using SIAN.Nemo
using SIAN: QQMPolyRingElem, QQFieldElem, var_index

# Load shared helpers from exp04 (only functions, not the main loop)
# We need: get_sian_ingredients, create_combined_ring, lift_poly

include("exp04_multipoint_prolongation.jl")

# ─── Build multi-point system and solve with HC.jl ──────────────────────

function build_and_solve_multipoint(name, pep; n_points=2)
    println("\n━━━ $name — HC.jl solve ━━━")

    ing = try; get_sian_ingredients(pep)
    catch e; println("  SKIP: $e"); return; end

    # --- Build combined ring + lift equations ---
    combined_ring = create_combined_ring(ing, n_points)
    param_jet_names = Set(string(SIAN.var_to_symb(p)) for p in ing.not_int_cond_params)

    X_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing.X)] for _ in 1:n_points]
    Y_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing.Y)] for _ in 1:n_points]
    for pt in 1:n_points
        for i in 1:length(ing.X)
            X_lifted[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.X[i]]
        end
        for i in 1:length(ing.Y)
            Y_lifted[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.Y[i]]
        end
    end

    x_variables_lifted = [QQMPolyRingElem[] for _ in 1:n_points]
    for pt in 1:n_points
        for v in ing.x_variables
            vname = string(SIAN.var_to_symb(v))
            tidx = findfirst(==(Symbol("$(vname)_$(pt)")), Nemo.symbols(combined_ring))
            !isnothing(tidx) && push!(x_variables_lifted[pt], Nemo.gens(combined_ring)[tidx])
        end
    end

    # --- Sample + prolongation ---
    d0 = BigInt(maximum(vcat([Nemo.total_degree(SIAN.unpack_fraction(ing.Q * eq[2])[1]) for eq in ing.eqs], Nemo.total_degree(ing.Q))))
    D1 = floor(BigInt, (length(ing.all_params) + 1) * 2 * d0 * ing.s * (ing.n + 1) * (1 + 2 * d0 * ing.s) / 0.01)
    samples = [SIAN.sample_point(D1, ing.x_vars, ing.y_vars, ing.u_variables, ing.all_params, ing.X_eq, ing.Y_eq, ing.Q) for _ in 1:n_points]

    orig_syms = [string(s) for s in Nemo.symbols(ing.Rjet)]
    combined_vals = zeros(QQFieldElem, length(Nemo.gens(combined_ring)))
    for (idx, orig_sym) in enumerate(orig_syms)
        if orig_sym in param_jet_names || orig_sym == "z_aux"
            tidx = findfirst(==(Symbol(orig_sym)), Nemo.symbols(combined_ring))
            !isnothing(tidx) && (combined_vals[tidx] = SIAN.insert_zeros_to_vals(samples[1][4][1], samples[1][4][2])[idx])
        else
            for pt in 1:n_points
                tidx = findfirst(==(Symbol("$(orig_sym)_$(pt)")), Nemo.symbols(combined_ring))
                !isnothing(tidx) && (combined_vals[tidx] = SIAN.insert_zeros_to_vals(samples[pt][4][1], samples[pt][4][2])[idx])
            end
        end
    end

    param_vars_combined = QQMPolyRingElem[]
    for p in ing.not_int_cond_params
        pidx = findfirst(==(SIAN.var_to_symb(p)), Nemo.symbols(combined_ring))
        !isnothing(pidx) && push!(param_vars_combined, Nemo.gens(combined_ring)[pidx])
    end
    state_ic_vars_combined = QQMPolyRingElem[]
    for pt in 1:n_points, i in 1:ing.n
        tidx = findfirst(==(Symbol("$(Nemo.symbols(ing.Rjet)[i])_$(pt)")), Nemo.symbols(combined_ring))
        !isnothing(tidx) && push!(state_ic_vars_combined, Nemo.gens(combined_ring)[tidx])
    end

    beta_mp = [[0 for _ in 1:ing.m] for _ in 1:n_points]
    Et_mp = Array{QQMPolyRingElem}(undef, 0)
    x_theta_vars_mp = vcat(param_vars_combined, state_ic_vars_combined)
    prolongation_possible_mp = [[1 for _ in 1:ing.m] for _ in 1:n_points]

    iteration = 0
    while any(any(pp .> 0) for pp in prolongation_possible_mp)
        iteration += 1; iteration > 100 && break
        progress = false
        for pt in 1:n_points, i in 1:ing.m
            if prolongation_possible_mp[pt][i] == 1
                beta_mp[pt][i] + 1 > length(Y_lifted[pt][i]) && (prolongation_possible_mp[pt][i] = 0; continue)
                candidate = Y_lifted[pt][i][beta_mp[pt][i]+1]
                eqs_test = vcat(Et_mp, candidate)
                JacX = SIAN.jacobi_matrix(eqs_test, x_theta_vars_mp, combined_vals)
                if LinearAlgebra.rank(JacX) == length(eqs_test)
                    Et_mp = vcat(Et_mp, candidate); beta_mp[pt][i] += 1; progress = true
                    polys_to_process = [candidate]
                    for pt2 in 1:n_points, k in 1:ing.m
                        beta_mp[pt2][k] + 1 <= length(Y_lifted[pt2][k]) && push!(polys_to_process, Y_lifted[pt2][k][beta_mp[pt2][k]+1])
                    end
                    while !isempty(polys_to_process)
                        new_to_process = QQMPolyRingElem[]
                        vrs = Set{QQMPolyRingElem}()
                        for poly in polys_to_process, v in Nemo.vars(poly)
                            v in x_variables_lifted[pt] && push!(vrs, v)
                        end
                        for v in vrs
                            v in x_theta_vars_mp && continue
                            x_theta_vars_mp = vcat(x_theta_vars_mp, v)
                            vname = string(Nemo.symbols(combined_ring)[SIAN.var_index(v)])
                            orig_vname = replace(vname, r"_[0-9]+$" => "")
                            orig_idx = findfirst(==(Symbol(orig_vname)), Nemo.symbols(ing.Rjet))
                            if !isnothing(orig_idx)
                                orig_var = Nemo.gens(ing.Rjet)[orig_idx]
                                ord_var = SIAN.get_order_var2(orig_var, ing.all_indets, ing.n+ing.m+ing.u, ing.s)
                                vi2 = var_index(ord_var[1])
                                if vi2 <= length(X_lifted[pt]) && ord_var[2] <= length(X_lifted[pt][vi2])
                                    Et_mp = vcat(Et_mp, X_lifted[pt][vi2][ord_var[2]])
                                    push!(new_to_process, X_lifted[pt][vi2][ord_var[2]])
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
        !progress && break
    end

    n_eqs = length(Et_mp); n_vars = length(x_theta_vars_mp)
    println("  Prolongation: $(n_eqs)×$(n_vars), β=$beta_mp, square=$(n_eqs==n_vars)")
    n_eqs != n_vars && (println("  ✗ NOT SQUARE"); return)

    # --- Convert Nemo → Symbolics ---
    println("  Converting to Symbolics...")
    nemo2sym = Dict{QQMPolyRingElem, Any}()
    sym_vars_all = Dict{String, Num}()
    for gen in Nemo.gens(combined_ring)
        vname = string(Nemo.symbols(combined_ring)[SIAN.var_index(gen)])
        sv = Symbolics.variable(Symbol(vname))
        nemo2sym[gen] = sv
        sym_vars_all[vname] = sv
    end

    sym_eqs = Num[]
    for eq in Et_mp
        try
            push!(sym_eqs, Num(ODEParameterEstimation.nemo_to_symbolics(eq, nemo2sym)))
        catch e
            println("  FAIL converting: ", sprint(showerror, e)[1:min(80,end)])
            return
        end
    end

    sym_varlist = [sym_vars_all[string(Nemo.symbols(combined_ring)[SIAN.var_index(v)])] for v in x_theta_vars_mp]
    println("  Converted: $(length(sym_eqs)) eqs, $(length(sym_varlist)) vars")

    # --- Find data variables (in equations but not in solve vars) ---
    eq_vars_set = Set{Num}()
    for eq in sym_eqs; union!(eq_vars_set, Set(Symbolics.get_variables(eq))); end
    solve_set = Set(sym_varlist)
    data_vars = setdiff(eq_vars_set, solve_set)
    println("  Data variables to substitute: $(length(data_vars))")

    # Substitute data values from the sample
    if !isempty(data_vars)
        data_subst = Dict{Num, Float64}()
        for dv in data_vars
            dvname = string(dv)
            cidx = findfirst(==(Symbol(dvname)), Nemo.symbols(combined_ring))
            if !isnothing(cidx)
                data_subst[dv] = Float64(combined_vals[cidx])
            else
                println("  WARNING: $dvname not in combined ring")
            end
        end
        sym_eqs = [Num(Symbolics.substitute(eq, data_subst)) for eq in sym_eqs]
    end

    # --- Solve with HC.jl ---
    println("  Solving with HC.jl ($(n_eqs)×$(n_vars))...")
    try
        solutions, _, _, _ = ODEParameterEstimation.solve_with_hc(sym_eqs, sym_varlist)
        println("  ★ HC.jl found $(length(solutions)) real solution(s)")

        if !isempty(solutions)
            true_vals = [Float64(combined_vals[SIAN.var_index(v)]) for v in x_theta_vars_mp]
            for (si, sol) in enumerate(solutions[1:min(5, end)])
                dist = norm(sol .- true_vals)
                @printf("    Sol %d: dist=%.2e %s\n", si, dist, dist < 1e-6 ? "✓ MATCHES" : "")
            end
        end
    catch e
        println("  HC.jl FAILED: ", sprint(showerror, e)[1:min(120,end)])
    end

    # --- Also solve 1-point baseline for comparison ---
    println("\n  --- 1-point baseline ---")
    single = run_single_point_prolongation(ing)
    println("  Single-point: $(single.n_eqs)×$(single.n_vars), β=$(single.beta)")

    # Convert single-point to Symbolics (using original ring)
    nemo2sym_1pt = Dict{QQMPolyRingElem, Any}()
    for gen in Nemo.gens(ing.Rjet)
        vname = string(Nemo.symbols(ing.Rjet)[SIAN.var_index(gen)])
        nemo2sym_1pt[gen] = Symbolics.variable(Symbol(vname))
    end
    sym_eqs_1pt = [Num(ODEParameterEstimation.nemo_to_symbolics(eq, nemo2sym_1pt)) for eq in single.Et]
    sym_vars_1pt = [nemo2sym_1pt[v] for v in single.x_theta_vars]

    # Find and substitute data vars for 1-point
    eq_vars_1pt = Set{Num}()
    for eq in sym_eqs_1pt; union!(eq_vars_1pt, Set(Symbolics.get_variables(eq))); end
    data_1pt = setdiff(eq_vars_1pt, Set(sym_vars_1pt))
    subs1 = SIAN.insert_zeros_to_vals(samples[1][4][1], samples[1][4][2])
    if !isempty(data_1pt)
        data_subst_1pt = Dict{Num, Float64}()
        for dv in data_1pt
            dvname = string(dv)
            ridx = findfirst(==(Symbol(dvname)), Nemo.symbols(ing.Rjet))
            !isnothing(ridx) && (data_subst_1pt[dv] = Float64(subs1[ridx]))
        end
        sym_eqs_1pt = [Num(Symbolics.substitute(eq, data_subst_1pt)) for eq in sym_eqs_1pt]
    end

    try
        solutions_1pt, _, _, _ = ODEParameterEstimation.solve_with_hc(sym_eqs_1pt, sym_vars_1pt)
        true_vals_1pt = [Float64(subs1[SIAN.var_index(v)]) for v in single.x_theta_vars]
        println("  1-point HC.jl: $(length(solutions_1pt)) solution(s)")
        if !isempty(solutions_1pt)
            dists = [norm(s .- true_vals_1pt) for s in solutions_1pt]
            @printf("    Closest to truth: %.2e\n", minimum(dists))
        end
    catch e
        println("  1-point HC.jl FAILED: ", sprint(showerror, e)[1:min(100,end)])
    end
end

# ─── Main ───────────────────────────────────────────────────────────────

# (The include of exp04 already runs its main loop — we add HC.jl tests after)

println("\n\n", "=" ^ 100)
println("STEP D: HC.jl Verification")
println("=" ^ 100)

for name in ["simple", "lotka_volterra", "forced_lv_sinusoidal"]
    build_and_solve_multipoint(name, getfield(ODEParameterEstimation, Symbol(name))())
end
