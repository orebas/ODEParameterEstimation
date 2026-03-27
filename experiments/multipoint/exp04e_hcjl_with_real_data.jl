# Experiment 4E: Solve multi-point prolongation system with REAL interpolated data
#
# Strategy:
# 1. Run multi-point prolongation to get Et_mp (the square equation set)
# 2. Convert Et_mp from Nemo → Symbolics
# 3. For each observable derivative variable in Et_mp, substitute the actual
#    interpolated value from GP at the corresponding time point
# 4. Solve with HC.jl
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp04e_hcjl_with_real_data.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using LinearAlgebra
using Printf
using Symbolics
using SIAN
using SIAN.Nemo
using SIAN: QQMPolyRingElem, QQFieldElem, var_index

# Load helpers
include("exp04_multipoint_prolongation.jl")

# ═══════════════════════════════════════════════════════════════════════════

function solve_multipoint_with_real_data(name, pep; n_points=2)
    println("\n━━━ $name — real data solve ━━━")

    ing = try; get_sian_ingredients(pep)
    catch e; println("  SKIP: $e"); return; end

    pep_work = ing.pep_work

    # Setup standard pipeline for interpolants
    setup = ODEParameterEstimation.setup_parameter_estimation(
        pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    t_vec = pep_work.data_sample["t"]

    # Pick two well-separated time points
    n_t = length(t_vec)
    t_idx_a = max(2, round(Int, n_t * 0.33))
    t_idx_b = min(n_t - 1, round(Int, n_t * 0.67))
    println("  Points: t_a=$(t_vec[t_idx_a]), t_b=$(t_vec[t_idx_b])")

    # --- Run multi-point prolongation (same as exp04) ---
    combined_ring = create_combined_ring(ing, n_points)
    param_jet_names = Set(string(SIAN.var_to_symb(p)) for p in ing.not_int_cond_params)

    X_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing.X)] for _ in 1:n_points]
    Y_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing.Y)] for _ in 1:n_points]
    for pt in 1:n_points, i in 1:length(ing.X)
        X_lifted[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.X[i]]
    end
    for pt in 1:n_points, i in 1:length(ing.Y)
        Y_lifted[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.Y[i]]
    end

    x_variables_lifted = [QQMPolyRingElem[] for _ in 1:n_points]
    for pt in 1:n_points, v in ing.x_variables
        tidx = findfirst(==(Symbol("$(SIAN.var_to_symb(v))_$(pt)")), Nemo.symbols(combined_ring))
        !isnothing(tidx) && push!(x_variables_lifted[pt], Nemo.gens(combined_ring)[tidx])
    end

    # Sample for rank testing
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

    # Prolongation
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
    n_eqs != n_vars && (println("  NOT SQUARE"); return)

    # --- Convert to Symbolics ---
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
        push!(sym_eqs, Num(ODEParameterEstimation.nemo_to_symbolics(eq, nemo2sym)))
    end
    sym_varlist = [sym_vars_all[string(Nemo.symbols(combined_ring)[SIAN.var_index(v)])] for v in x_theta_vars_mp]

    # --- Identify data variables (observables) that need interpolated values ---
    eq_vars_set = Set{Num}()
    for eq in sym_eqs; union!(eq_vars_set, Set(Symbolics.get_variables(eq))); end
    solve_set = Set(sym_varlist)
    data_sym_vars = setdiff(eq_vars_set, solve_set)

    println("  Data vars to substitute: $(length(data_sym_vars))")
    for dv in data_sym_vars
        println("    $(string(dv))")
    end

    # --- Substitute REAL interpolated values ---
    # Data vars have names like y2_0_1 (output y2, order 0, point 1)
    # or y1_1_2 (output y1, order 1, point 2)
    # We need to evaluate the corresponding interpolant at the time point
    #
    # The mapping: the original SIAN Y variable y_i_j at point pt
    # corresponds to the j-th derivative of the i-th measured quantity at t_vec[t_idx_pt]

    model = pep_work.model.system
    mq = pep_work.measured_quantities
    interps = setup.interpolants
    template_DD = setup.good_DD
    t_points = [t_vec[t_idx_a], t_vec[t_idx_b]]

    data_subst = Dict{Num, Float64}()

    # Build SIAN output BASE name → (obs_idx, interpolant) mapping
    # SIAN y_vars are named y1, y2, ... (original ring, no order suffix)
    # The jet ring names are y1_0, y2_0, etc. but we want the BASE name
    sian_obs_map = Dict{String, Tuple{Int, Any}}()
    for obs_idx in 1:ing.m
        # y_vars are in the original ring; their names are "y1", "y2", etc.
        obs_base_name = string(ing.y_vars[obs_idx])  # "y2", "y1", etc.

        if obs_idx <= length(mq)
            obs_rhs = ModelingToolkit.diff2term(mq[obs_idx].rhs)
            if haskey(interps, obs_rhs)
                sian_obs_map[obs_base_name] = (obs_idx, interps[obs_rhs])
            end
        end
    end
    println("  SIAN output base → interpolant: ", Dict(k => v[1] for (k,v) in sian_obs_map))

    for dv in data_sym_vars
        dvname = string(dv)

        # Parse: "y2_1_2" → SIAN base "y2", derivative order 1, point index 2
        # The combined ring naming is: {sian_var_name}_{point_idx}
        # where sian_var_name itself contains underscores like "y2_1" (output y2, order 1)
        # So we need to split off ONLY the last _N as the point index

        m_pt = match(r"^(.+)_(\d+)$", dvname)
        if isnothing(m_pt); println("    WARNING: can't parse $dvname"); continue; end
        sian_name = m_pt.captures[1]  # e.g., "y2_1"
        point_idx = parse(Int, m_pt.captures[2])
        t_point = t_points[point_idx]

        # Parse SIAN name: "y2_1" → base "y2", order 1
        m_sian = match(r"^(.+)_(\d+)$", sian_name)
        if isnothing(m_sian); println("    WARNING: can't parse SIAN name $sian_name"); continue; end
        obs_base = m_sian.captures[1]  # "y2"
        deriv_order = parse(Int, m_sian.captures[2])

        if haskey(sian_obs_map, obs_base)
            _, interp = sian_obs_map[obs_base]
            val = ODEParameterEstimation.nth_deriv(x -> interp(x), deriv_order, t_point)
            data_subst[dv] = Float64(val)
        else
            println("    WARNING: no interpolant for $dvname (base=$obs_base)")
        end
    end

    println("  Substituted $(length(data_subst)) / $(length(data_sym_vars)) data values")

    if length(data_subst) < length(data_sym_vars)
        println("  ✗ Missing data values — cannot solve")
        return
    end

    instantiated_eqs = [Num(Symbolics.substitute(eq, data_subst)) for eq in sym_eqs]

    # --- Solve with HC.jl ---
    println("  Solving multi-point $(n_eqs)×$(n_vars) with HC.jl...")
    mp_solutions = try
        sols, _, _, _ = ODEParameterEstimation.solve_with_hc(instantiated_eqs, sym_varlist)
        sols
    catch e
        println("  HC.jl FAILED: ", sprint(showerror, e)[1:min(100,end)])
        Vector{Float64}[]
    end
    println("  Multi-point: $(length(mp_solutions)) solution(s)")

    # --- 1-point baseline for comparison ---
    eqs_1pt, vars_1pt = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep_work.data_sample,
        setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[t_idx_a], precomputed_interpolants=setup.interpolants)

    sp_solutions = try
        sols, _, _, _ = ODEParameterEstimation.solve_with_hc(eqs_1pt, vars_1pt)
        sols
    catch e
        println("  1-pt HC.jl FAILED: ", sprint(showerror, e)[1:min(100,end)])
        Vector{Float64}[]
    end
    println("  1-point: $(length(sp_solutions)) solution(s)")

    # Compare against true values
    if !isempty(mp_solutions) || !isempty(sp_solutions)
        println("\n  Parameter comparison:")
        # Extract parameter names and true values
        param_names_list = [string(k) for k in keys(pep_work.p_true)]
        param_true = [v for v in values(pep_work.p_true)]
        println("  True params: ", Dict(zip(param_names_list, param_true)))

        if !isempty(mp_solutions)
            println("  Multi-point solution 1 (first $(length(param_vars_combined)) entries = params):")
            for (i, s) in enumerate(mp_solutions[1][1:min(length(param_vars_combined), end)])
                pname = string(Nemo.symbols(combined_ring)[SIAN.var_index(param_vars_combined[i])])
                @printf("    %s = %.6f\n", pname, s)
            end
        end
    end
end

# ═══════════════════════════════════════════════════════════════════════════

# The include of exp04 already ran — skip to Step 4E
println("\n\n", "=" ^ 100)
println("STEP 4E: Multi-Point HC.jl Solve with Real Data")
println("=" ^ 100)

for name in ["simple", "lotka_volterra"]
    solve_multipoint_with_real_data(name, getfield(ODEParameterEstimation, Symbol(name))())
end
