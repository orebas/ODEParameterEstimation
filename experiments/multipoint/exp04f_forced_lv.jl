# Experiment 4F: Multi-point solve on forced_lv_sinusoidal — the key accuracy test
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp04f_forced_lv.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using LinearAlgebra
using Printf
using Symbolics
using SIAN
using SIAN.Nemo
using SIAN: QQMPolyRingElem, QQFieldElem, var_index

# Load core helpers (get_sian_ingredients, create_combined_ring, lift_poly)
# but suppress the main loop from exp04 by wrapping
let
    old_stdout = stdout
    redirect_stdout(devnull) do
        redirect_stderr(devnull) do
            include("exp04_multipoint_prolongation.jl")
        end
    end
end

# ═══════════════════════════════════════════════════════════════════════════

function run_multipoint_comparison(name, pep; n_data=31, t_interval=[0.0, 10.0], n_points=2)
    println("\n", "=" ^ 100)
    println("$name — Multi-point vs 1-point comparison (n=$n_data)")
    println("=" ^ 100)

    # Setup
    pep_data = ODEParameterEstimation.sample_problem_data(
        pep, EstimationOptions(datasize=n_data, time_interval=t_interval, nooutput=true))
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, tr_info = try
        ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
    catch; (pep_data, nothing); end

    ing = get_sian_ingredients(pep)  # uses pep's own time interval
    # But we need ingredients from pep_work (which has the right data_sample)
    # Re-extract with the correct pep
    ing2 = try
        pep_d2 = ODEParameterEstimation.sample_problem_data(
            pep, EstimationOptions(datasize=n_data, time_interval=t_interval, nooutput=true))
        t_v2 = ModelingToolkit.get_iv(pep_d2.model.system)
        pw2, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_d2, t_v2); catch; (pep_d2, nothing); end
        ordered = ODEParameterEstimation.OrderedODESystem(
            pw2.model.system, ModelingToolkit.unknowns(pw2.model.system), ModelingToolkit.parameters(pw2.model.system))
        si_ode, _, _ = ODEParameterEstimation.convert_to_si_ode(ordered, pw2.measured_quantities)
        eqs, Q, x_eqs, y_eqs, x_vars, y_vars, u_vars, mu, all_indets, gens_Rjet = SIAN.get_equations(si_ode)
        Rjet = gens_Rjet[1].parent; n = length(x_vars); m = length(y_vars); u = length(u_vars); s = length(mu) + n
        X, X_eq = SIAN.get_x_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)
        Y, Y_eq = SIAN.get_y_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)
        not_int_cond_params = gens_Rjet[(end-length(si_ode.parameters)+1):end]
        all_params = vcat(not_int_cond_params, gens_Rjet[1:n])
        x_variables = gens_Rjet[1:n]
        for i in 1:(s+1); x_variables = vcat(x_variables, gens_Rjet[(i*(n+m+u)+1):(i*(n+m+u)+n)]); end
        u_variables = gens_Rjet[(n+m+1):(n+m+u)]
        for i in 1:(s+1); u_variables = vcat(u_variables, gens_Rjet[((n+m+u)*i+n+m+1):((n+m+u)*(i+1))]); end
        (si_ode=si_ode, pep_work=pw2, eqs=eqs, Q=Q, x_eqs=x_eqs, y_eqs=y_eqs,
         x_vars=x_vars, y_vars=y_vars, u_vars=u_vars, mu=mu, all_indets=all_indets,
         gens_Rjet=gens_Rjet, Rjet=Rjet, n=n, m=m, u=u, s=s, X=X, X_eq=X_eq, Y=Y, Y_eq=Y_eq,
         all_params=all_params, x_variables=x_variables, u_variables=u_variables,
         not_int_cond_params=not_int_cond_params)
    catch e
        println("  Ingredients failed: ", sprint(showerror, e)[1:min(100,end)])
        return
    end

    pep_work = ing2.pep_work
    model = pep_work.model.system; mq = pep_work.measured_quantities
    setup = ODEParameterEstimation.setup_parameter_estimation(
        pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    t_vec = pep_work.data_sample["t"]; n_t = length(t_vec)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        startswith(sn, "_trfn_") || (real_params[sn] = v)
    end
    println("  True: ", real_params)
    println("  n=$n_t, t=[$(t_vec[1]), $(t_vec[end])], n_states=$(ing2.n), n_outputs=$(ing2.m)")

    # ─── 1-point baseline at several t ──────────────────────────────────
    println("\n  --- 1-point baseline ---")
    best_1pt_err = Inf; best_1pt_sol = nothing; best_1pt_t = 0.0
    for frac in [0.15, 0.25, 0.33, 0.5, 0.67, 0.8]
        t_idx = max(2, round(Int, n_t * frac))
        eqs, vars = ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample,
            setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot,
            time_index_set=[t_idx], precomputed_interpolants=setup.interpolants)
        solutions, _, _, _ = try
            ODEParameterEstimation.solve_with_hc(eqs, vars)
        catch; (Vector{Float64}[], nothing, nothing, nothing); end
        roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars), pep_work)
        pidxs = [i for (i, v) in enumerate(vars) if roles[string(v)] == :parameter]
        pnames = [replace(string(vars[i]), "_0" => "") for i in pidxs]
        for sol in solutions
            pvals = [sol[i] for i in pidxs]
            max_err = 0.0
            for (j, pn) in enumerate(pnames)
                haskey(real_params, pn) && (max_err = max(max_err, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
            end
            if max_err < best_1pt_err
                best_1pt_err = max_err; best_1pt_sol = Dict(zip(pnames, pvals)); best_1pt_t = t_vec[t_idx]
            end
        end
    end
    @printf("  Best 1-point: max_rel_err=%.3f at t=%.1f\n", best_1pt_err, best_1pt_t)
    if !isnothing(best_1pt_sol)
        for (pn, pv) in best_1pt_sol
            haskey(real_params, pn) && @printf("    %s: est=%.4f true=%.4f rel=%.3f\n", pn, pv, real_params[pn], abs(pv - real_params[pn])/abs(real_params[pn]))
        end
    end

    # ─── Multi-point prolongation + solve ───────────────────────────────
    println("\n  --- Multi-point ($n_points-point) ---")

    combined_ring = create_combined_ring(ing2, n_points)
    param_jet_names = Set(string(SIAN.var_to_symb(p)) for p in ing2.not_int_cond_params)

    # Lift
    X_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing2.X)] for _ in 1:n_points]
    Y_lifted = [[QQMPolyRingElem[] for _ in 1:length(ing2.Y)] for _ in 1:n_points]
    for pt in 1:n_points, i in 1:length(ing2.X)
        X_lifted[pt][i] = [lift_poly(p, ing2.not_int_cond_params, combined_ring, pt) for p in ing2.X[i]]
    end
    for pt in 1:n_points, i in 1:length(ing2.Y)
        Y_lifted[pt][i] = [lift_poly(p, ing2.not_int_cond_params, combined_ring, pt) for p in ing2.Y[i]]
    end

    x_variables_lifted = [QQMPolyRingElem[] for _ in 1:n_points]
    for pt in 1:n_points, v in ing2.x_variables
        tidx = findfirst(==(Symbol("$(SIAN.var_to_symb(v))_$(pt)")), Nemo.symbols(combined_ring))
        !isnothing(tidx) && push!(x_variables_lifted[pt], Nemo.gens(combined_ring)[tidx])
    end

    # Sample for rank testing
    d0 = BigInt(maximum(vcat([Nemo.total_degree(SIAN.unpack_fraction(ing2.Q * eq[2])[1]) for eq in ing2.eqs], Nemo.total_degree(ing2.Q))))
    D1 = floor(BigInt, (length(ing2.all_params) + 1) * 2 * d0 * ing2.s * (ing2.n + 1) * (1 + 2 * d0 * ing2.s) / 0.01)
    samples = [SIAN.sample_point(D1, ing2.x_vars, ing2.y_vars, ing2.u_variables, ing2.all_params, ing2.X_eq, ing2.Y_eq, ing2.Q) for _ in 1:n_points]

    orig_syms = [string(s) for s in Nemo.symbols(ing2.Rjet)]
    combined_vals = zeros(QQFieldElem, length(Nemo.gens(combined_ring)))
    for (idx, os) in enumerate(orig_syms)
        if os in param_jet_names || os == "z_aux"
            tidx = findfirst(==(Symbol(os)), Nemo.symbols(combined_ring))
            !isnothing(tidx) && (combined_vals[tidx] = SIAN.insert_zeros_to_vals(samples[1][4][1], samples[1][4][2])[idx])
        else
            for pt in 1:n_points
                tidx = findfirst(==(Symbol("$(os)_$(pt)")), Nemo.symbols(combined_ring))
                !isnothing(tidx) && (combined_vals[tidx] = SIAN.insert_zeros_to_vals(samples[pt][4][1], samples[pt][4][2])[idx])
            end
        end
    end

    param_vars_combined = QQMPolyRingElem[]
    for p in ing2.not_int_cond_params
        pidx = findfirst(==(SIAN.var_to_symb(p)), Nemo.symbols(combined_ring))
        !isnothing(pidx) && push!(param_vars_combined, Nemo.gens(combined_ring)[pidx])
    end
    state_ic_vars_combined = QQMPolyRingElem[]
    for pt in 1:n_points, i in 1:ing2.n
        tidx = findfirst(==(Symbol("$(Nemo.symbols(ing2.Rjet)[i])_$(pt)")), Nemo.symbols(combined_ring))
        !isnothing(tidx) && push!(state_ic_vars_combined, Nemo.gens(combined_ring)[tidx])
    end

    # Prolongation
    beta_mp = [[0 for _ in 1:ing2.m] for _ in 1:n_points]
    Et_mp = Array{QQMPolyRingElem}(undef, 0)
    x_theta_vars_mp = vcat(param_vars_combined, state_ic_vars_combined)
    prolongation_possible_mp = [[1 for _ in 1:ing2.m] for _ in 1:n_points]

    iter = 0
    while any(any(pp .> 0) for pp in prolongation_possible_mp)
        iter += 1; iter > 100 && break
        progress = false
        for pt in 1:n_points, i in 1:ing2.m
            if prolongation_possible_mp[pt][i] == 1
                beta_mp[pt][i] + 1 > length(Y_lifted[pt][i]) && (prolongation_possible_mp[pt][i] = 0; continue)
                candidate = Y_lifted[pt][i][beta_mp[pt][i]+1]
                eqs_test = vcat(Et_mp, candidate)
                JacX = SIAN.jacobi_matrix(eqs_test, x_theta_vars_mp, combined_vals)
                if LinearAlgebra.rank(JacX) == length(eqs_test)
                    Et_mp = vcat(Et_mp, candidate); beta_mp[pt][i] += 1; progress = true
                    polys_to_process = [candidate]
                    for pt2 in 1:n_points, k in 1:ing2.m
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
                            orig_idx = findfirst(==(Symbol(orig_vname)), Nemo.symbols(ing2.Rjet))
                            if !isnothing(orig_idx)
                                orig_var = Nemo.gens(ing2.Rjet)[orig_idx]
                                ord_var = SIAN.get_order_var2(orig_var, ing2.all_indets, ing2.n+ing2.m+ing2.u, ing2.s)
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
    println("  System: $(n_eqs)×$(n_vars), β=$beta_mp, square=$(n_eqs==n_vars)")
    n_eqs != n_vars && (println("  NOT SQUARE — aborting"); return)

    # Convert to Symbolics
    println("  Converting Nemo → Symbolics...")
    nemo2sym = Dict{QQMPolyRingElem, Any}()
    sym_vars_all = Dict{String, Num}()
    for gen in Nemo.gens(combined_ring)
        vname = string(Nemo.symbols(combined_ring)[SIAN.var_index(gen)])
        sv = Symbolics.variable(Symbol(vname))
        nemo2sym[gen] = sv; sym_vars_all[vname] = sv
    end
    sym_eqs = [Num(ODEParameterEstimation.nemo_to_symbolics(eq, nemo2sym)) for eq in Et_mp]
    sym_varlist = [sym_vars_all[string(Nemo.symbols(combined_ring)[SIAN.var_index(v)])] for v in x_theta_vars_mp]

    # Identify data vars
    eq_vars_set = Set{Num}()
    for eq in sym_eqs; union!(eq_vars_set, Set(Symbolics.get_variables(eq))); end
    data_sym_vars = setdiff(eq_vars_set, Set(sym_varlist))
    println("  Data variables: $(length(data_sym_vars))")

    # Build SIAN output → data source mapping
    # Match SIAN y_vars to measured quantities by name (not index!)
    # For _obs_trfn_ observables: use analytical evaluation
    # For real observables: use GP interpolants
    interps = setup.interpolants
    sian_obs_map = Dict{String, Any}()  # base_name → (:interp, interp) or (:trfn, func_type, freq)

    for (sian_idx, yvar) in enumerate(ing2.y_vars)
        sian_name = string(yvar)  # e.g., "y1", "y2", "_obs_trfn_cos_2_0_sin"

        # Try to match to a measured quantity
        matched = false
        for (mq_idx, mq_eq) in enumerate(mq)
            mq_lhs_name = replace(string(mq_eq.lhs), r"\(.*\)" => "")
            if mq_lhs_name == sian_name
                obs_rhs = ModelingToolkit.diff2term(mq_eq.rhs)
                if haskey(interps, obs_rhs)
                    sian_obs_map[sian_name] = (:interp, interps[obs_rhs])
                    matched = true
                    break
                end
            end
        end

        # If not matched via interpolant, try _obs_trfn_ analytical evaluation
        if !matched && startswith(sian_name, "_obs_trfn_")
            sian_obs_map[sian_name] = (:trfn, sian_name)
            matched = true
        end

        !matched && println("  WARNING: no data source for SIAN output '$sian_name'")
    end
    println("  Data source map: ", Dict(k => (v isa Tuple ? v[1] : v) for (k,v) in sian_obs_map))

    # Try several time point pairs
    println("\n  --- Solving at multiple point pairs ---")
    @printf("  %-20s  %-8s  %-8s  %s\n", "Points", "n_sols", "max_err", "params")
    println("  ", "-" ^ 80)

    for (frac_a, frac_b) in [(0.15, 0.5), (0.2, 0.67), (0.25, 0.75), (0.33, 0.67), (0.15, 0.85)]
        t_idx_a = max(2, round(Int, n_t * frac_a))
        t_idx_b = min(n_t - 1, round(Int, n_t * frac_b))
        t_points = [t_vec[t_idx_a], t_vec[t_idx_b]]

        # Substitute data — handle both interpolant and _trfn_ analytical sources
        data_subst = Dict{Num, Float64}()
        for dv in data_sym_vars
            dvname = string(dv)
            # Parse: "{sian_jet_name}_{point_idx}"
            # sian_jet_name itself may contain underscores (e.g., "_obs_trfn_cos_2_0_sin_1")
            # The point index is ALWAYS the last _N
            m_pt = match(r"^(.+)_(\d+)$", dvname); isnothing(m_pt) && continue
            sian_jet_name = m_pt.captures[1]; point_idx = parse(Int, m_pt.captures[2])

            # Parse SIAN jet name: "{base}_{order}" where base may contain underscores
            m_sian = match(r"^(.+)_(\d+)$", sian_jet_name); isnothing(m_sian) && continue
            obs_base = m_sian.captures[1]; deriv_order = parse(Int, m_sian.captures[2])

            t_pt = t_points[point_idx]

            if haskey(sian_obs_map, obs_base)
                source = sian_obs_map[obs_base]
                if source[1] == :interp
                    data_subst[dv] = Float64(ODEParameterEstimation.nth_deriv(x -> source[2](x), deriv_order, t_pt))
                elseif source[1] == :trfn
                    # Use analytical evaluation for _obs_trfn_ variables
                    # The SIAN jet name is like "_obs_trfn_cos_2_0_sin_1" → base "_obs_trfn_cos_2_0_sin", order 1
                    # evaluate_obs_trfn_template_variable expects the full base name + order
                    trfn_var_name = "$(obs_base)_$(deriv_order)"
                    val = ODEParameterEstimation.evaluate_obs_trfn_template_variable(trfn_var_name, t_pt)
                    if isnothing(val)
                        # Try evaluate_trfn_template_variable as fallback
                        val = ODEParameterEstimation.evaluate_trfn_template_variable(trfn_var_name, t_pt)
                    end
                    if !isnothing(val)
                        data_subst[dv] = Float64(val)
                    else
                        println("    WARNING: can't evaluate trfn $trfn_var_name at t=$t_pt")
                    end
                end
            end
        end

        if length(data_subst) < length(data_sym_vars)
            @printf("  t=(%.1f,%.1f)  missing %d data vars\n", t_points[1], t_points[2], length(data_sym_vars) - length(data_subst))
            continue
        end

        inst_eqs = [Num(Symbolics.substitute(eq, data_subst)) for eq in sym_eqs]

        solutions = try
            sols, _, _, _ = ODEParameterEstimation.solve_with_hc(inst_eqs, sym_varlist)
            sols
        catch e
            @printf("  t=(%.1f,%.1f)  HC FAIL: %s\n", t_points[1], t_points[2], sprint(showerror, e)[1:min(50,end)])
            continue
        end

        # Extract param values and compute errors
        param_comb_names = [replace(string(Nemo.symbols(combined_ring)[SIAN.var_index(v)]), "_0" => "") for v in param_vars_combined]
        best_err = Inf; best_sol_params = nothing
        for sol in solutions
            pvals = sol[1:length(param_vars_combined)]
            max_err = 0.0
            for (j, pn) in enumerate(param_comb_names)
                haskey(real_params, pn) && (max_err = max(max_err, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
            end
            if max_err < best_err
                best_err = max_err; best_sol_params = Dict(zip(param_comb_names, pvals))
            end
        end

        param_str = isnothing(best_sol_params) ? "" :
            join([@sprintf("%s=%.2f", pn, pv) for (pn, pv) in best_sol_params if haskey(real_params, pn)], " ")
        @printf("  t=(%.1f,%.1f)  %-8d  %-8.3f  %s\n", t_points[1], t_points[2], length(solutions), best_err, param_str)
    end

    @printf("\n  BEST 1-POINT: max_rel_err=%.3f\n", best_1pt_err)
end

# ═══════════════════════════════════════════════════════════════════════════

run_multipoint_comparison("forced_lv_sinusoidal",
    ODEParameterEstimation.forced_lv_sinusoidal();
    n_data=31, t_interval=[0.0, 10.0])
