# Experiment 4G: Multi-point on HARD benchmark models
#
# Focus on models that are challenging for ODEPE in the Bilby benchmark
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp04g_hard_models.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using LinearAlgebra
using Printf
using Symbolics
using SIAN
using SIAN.Nemo
using SIAN: QQMPolyRingElem, QQFieldElem, var_index

# Suppress exp04 main loop output
let; redirect_stdout(devnull) do; redirect_stderr(devnull) do
    include("exp04_multipoint_prolongation.jl")
end; end; end

# ═══════════════════════════════════════════════════════════════════════════

function run_hard_model_test(name, pep; n_data=21, t_interval=nothing)
    println("\n", "━" ^ 90)
    println("MODEL: $name (n=$n_data)")
    println("━" ^ 90)

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]

    pep_data = try
        ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=n_data, time_interval=ti, nooutput=true))
    catch e; println("  SKIP (sample): ", sprint(showerror, e)[1:min(80,end)]); return nothing; end

    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, tr_info = try
        ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
    catch; (pep_data, nothing); end

    model = pep_work.model.system; mq = pep_work.measured_quantities
    states = ModelingToolkit.unknowns(model); params = ModelingToolkit.parameters(model)

    # Get SIAN ingredients
    ing = try
        ordered = ODEParameterEstimation.OrderedODESystem(model, states, params)
        si_ode, _, _ = ODEParameterEstimation.convert_to_si_ode(ordered, mq)
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
        (si_ode=si_ode, pep_work=pep_work, eqs=eqs, Q=Q, x_eqs=x_eqs, y_eqs=y_eqs,
         x_vars=x_vars, y_vars=y_vars, u_vars=u_vars, mu=mu, all_indets=all_indets,
         gens_Rjet=gens_Rjet, Rjet=Rjet, n=n, m=m, u=u, s=s, X=X, X_eq=X_eq, Y=Y, Y_eq=Y_eq,
         all_params=all_params, x_variables=x_variables, u_variables=u_variables,
         not_int_cond_params=not_int_cond_params)
    catch e; println("  SKIP (SIAN): ", sprint(showerror, e)[1:min(100,end)]); return nothing; end

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end
    println("  States=$(ing.n) Params=$(length(real_params)) Obs=$(ing.m) s=$(ing.s)")
    println("  True: ", real_params)

    # ─── Single-point prolongation baseline ─────────────────────────────
    single = try; run_single_point_prolongation(ing)
    catch e; println("  SKIP (single prolong): ", sprint(showerror, e)[1:min(80,end)]); return nothing; end
    println("  1-point: $(single.n_eqs)×$(single.n_vars), β=$(single.beta)")

    # ─── Multi-point prolongation ───────────────────────────────────────
    n_points = 2
    combined_ring = try; create_combined_ring(ing, n_points)
    catch e; println("  SKIP (ring): $e"); return nothing; end
    param_jet_names = Set(string(SIAN.var_to_symb(p)) for p in ing.not_int_cond_params)

    # Lift
    X_lifted = try
        xl = [[QQMPolyRingElem[] for _ in 1:length(ing.X)] for _ in 1:n_points]
        yl = [[QQMPolyRingElem[] for _ in 1:length(ing.Y)] for _ in 1:n_points]
        for pt in 1:n_points, i in 1:length(ing.X)
            xl[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.X[i]]
        end
        for pt in 1:n_points, i in 1:length(ing.Y)
            yl[pt][i] = [lift_poly(p, ing.not_int_cond_params, combined_ring, pt) for p in ing.Y[i]]
        end
        (xl, yl)
    catch e; println("  SKIP (lift): ", sprint(showerror, e)[1:min(80,end)]); return nothing; end
    X_l, Y_l = X_lifted

    x_variables_lifted = [QQMPolyRingElem[] for _ in 1:n_points]
    for pt in 1:n_points, v in ing.x_variables
        tidx = findfirst(==(Symbol("$(SIAN.var_to_symb(v))_$(pt)")), Nemo.symbols(combined_ring))
        !isnothing(tidx) && push!(x_variables_lifted[pt], Nemo.gens(combined_ring)[tidx])
    end

    # Sample
    d0 = BigInt(maximum(vcat([Nemo.total_degree(SIAN.unpack_fraction(ing.Q * eq[2])[1]) for eq in ing.eqs], Nemo.total_degree(ing.Q))))
    D1 = floor(BigInt, (length(ing.all_params) + 1) * 2 * d0 * ing.s * (ing.n + 1) * (1 + 2 * d0 * ing.s) / 0.01)
    samples = try
        [SIAN.sample_point(D1, ing.x_vars, ing.y_vars, ing.u_variables, ing.all_params, ing.X_eq, ing.Y_eq, ing.Q) for _ in 1:n_points]
    catch e; println("  SKIP (sample_point): ", sprint(showerror, e)[1:min(80,end)]); return nothing; end

    orig_syms = [string(s) for s in Nemo.symbols(ing.Rjet)]
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
    pp_mp = [[1 for _ in 1:ing.m] for _ in 1:n_points]

    itr = 0
    while any(any(pp .> 0) for pp in pp_mp)
        itr += 1; itr > 100 && (println("  WARNING: >100 iterations"); break)
        progress = false
        for pt in 1:n_points, i in 1:ing.m
            if pp_mp[pt][i] == 1
                beta_mp[pt][i] + 1 > length(Y_l[pt][i]) && (pp_mp[pt][i] = 0; continue)
                candidate = Y_l[pt][i][beta_mp[pt][i]+1]
                eqs_test = vcat(Et_mp, candidate)
                JacX = SIAN.jacobi_matrix(eqs_test, x_theta_vars_mp, combined_vals)
                if LinearAlgebra.rank(JacX) == length(eqs_test)
                    Et_mp = vcat(Et_mp, candidate); beta_mp[pt][i] += 1; progress = true
                    polys_to_process = [candidate]
                    for pt2 in 1:n_points, k in 1:ing.m
                        beta_mp[pt2][k] + 1 <= length(Y_l[pt2][k]) && push!(polys_to_process, Y_l[pt2][k][beta_mp[pt2][k]+1])
                    end
                    while !isempty(polys_to_process)
                        new_tp = QQMPolyRingElem[]
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
                                if vi2 <= length(X_l[pt]) && ord_var[2] <= length(X_l[pt][vi2])
                                    Et_mp = vcat(Et_mp, X_l[pt][vi2][ord_var[2]])
                                    push!(new_tp, X_l[pt][vi2][ord_var[2]])
                                end
                            end
                        end
                        polys_to_process = new_tp
                    end
                else
                    pp_mp[pt][i] = 0
                end
            end
        end
        !progress && break
    end

    ne = length(Et_mp); nv = length(x_theta_vars_mp)
    is_square = ne == nv
    max_beta_single = maximum(single.beta)
    max_beta_mp = maximum(maximum(beta_mp[pt][i] for i in 1:ing.m) for pt in 1:n_points)

    println("  2-point: $(ne)×$(nv), β=$beta_mp, square=$is_square")
    println("  Max order: single=$max_beta_single → multi=$max_beta_mp",
        max_beta_mp < max_beta_single ? " ★ REDUCED" : "")

    return (name=name, n_s=ing.n, n_p=length(real_params), n_o=ing.m,
        single_size="$(single.n_eqs)×$(single.n_vars)", single_beta=single.beta, max_single=max_beta_single,
        multi_size="$(ne)×$(nv)", multi_beta=beta_mp, max_multi=max_beta_mp,
        is_square=is_square, reduced=max_beta_mp < max_beta_single)
end

# ═══════════════════════════════════════════════════════════════════════════

println("=" ^ 100)
println("EXPERIMENT 4G: Hard Benchmark Models — Multi-Point Prolongation")
println("=" ^ 100)

hard_models = [
    ("treatment", ODEParameterEstimation.treatment(), 21, nothing),
    ("biohydrogenation", ODEParameterEstimation.biohydrogenation(), 21, [0.0, 1.0]),
    ("crauste", ODEParameterEstimation.crauste(), 21, nothing),
    ("hiv", ODEParameterEstimation.hiv(), 21, nothing),
    ("fitzhugh_nagumo", ODEParameterEstimation.fitzhugh_nagumo(), 21, nothing),
    ("daisy_ex3", ODEParameterEstimation.daisy_ex3(), 21, nothing),
    ("daisy_mamil3", ODEParameterEstimation.daisy_mamil3(), 21, nothing),
    ("slowfast", ODEParameterEstimation.slowfast(), 21, nothing),
    ("seir", ODEParameterEstimation.seir(), 21, nothing),
]

results = []
for (name, pep, nd, ti) in hard_models
    r = run_hard_model_test(name, pep; n_data=nd, t_interval=ti)
    !isnothing(r) && push!(results, r)
end

println("\n\n", "=" ^ 100)
println("SUMMARY — Hard Models")
println("=" ^ 100)
@printf("%-20s  %3s %3s %3s  %-10s  %-6s  %-10s  %-6s  %-8s  %s\n",
    "Model", "n_s", "n_p", "n_o", "1pt_sys", "1pt_β", "2pt_sys", "2pt_β", "Reduced?", "Max order change")
println("-" ^ 110)
for r in results
    @printf("%-20s  %3d %3d %3d  %-10s  %-6d  %-10s  %-6d  %-8s  %d → %d\n",
        r.name, r.n_s, r.n_p, r.n_o, r.single_size, r.max_single,
        r.multi_size, r.max_multi,
        r.is_square ? (r.reduced ? "★ YES" : "no") : "NOT SQ",
        r.max_single, r.max_multi)
end
println("=" ^ 100)
