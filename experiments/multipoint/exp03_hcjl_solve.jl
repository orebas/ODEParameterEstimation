# Experiment 3: Solve 2-point systems with HC.jl — check zero-dimensionality
#
# For each model + drop strategy:
#   1. Build the 2-point system with ORACLE data (perfect interpolants)
#   2. Try to solve with HC.jl
#   3. Check: does it find finite solutions? How many? Is the true solution among them?
#   4. Compare solution count and degree to the 1-point baseline
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp03_hcjl_solve.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using Symbolics
using LinearAlgebra
using ForwardDiff
using Printf
using HomotopyContinuation

# Note: exp02 helper functions are defined inline below (not included to avoid running exp02's main loop)

# ─── Oracle interpolant builder ─────────────────────────────────────────

function build_oracle_interpolants(pep, t_idx, setup_data)
    t_vec = pep.data_sample["t"]
    t_eval = t_vec[t_idx]
    max_d = maximum(values(setup_data.good_deriv_level))
    st = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep, t_eval, max_d + 2)
    ot = ODEParameterEstimation.compute_observable_taylor_coefficients(pep, st, t_eval, max_d + 2)
    perfect = Dict{Num, ODEParameterEstimation.PerfectInterpolant}()
    for (key, tc) in ot
        perfect[key] = ODEParameterEstimation.PerfectInterpolant(t_eval, tc)
    end
    return perfect, st, ot
end

# ─── Build 2-point system with oracle or production data ────────────────

function build_two_point_oracle(pep, setup_data, t_idx_a, t_idx_b; drop_strategy=:highest_data)
    model = pep.model.system
    mq = pep.measured_quantities
    interp = ODEParameterEstimation.aaad_gpr_pivot

    # Oracle interpolants at each point
    oracle_a, st_a, ot_a = build_oracle_interpolants(pep, t_idx_a, setup_data)
    oracle_b, st_b, ot_b = build_oracle_interpolants(pep, t_idx_b, setup_data)

    # Instantiate template at point A with oracle data
    eqs_a, vars_a = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=interp, time_index_set=[t_idx_a],
        precomputed_interpolants=oracle_a)

    # Instantiate template at point B with oracle data
    eqs_b, vars_b = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=interp, time_index_set=[t_idx_b],
        precomputed_interpolants=oracle_b)

    # Classify and rename
    var_names_a = string.(vars_a)
    roles_a = ODEParameterEstimation._classify_polynomial_variables(var_names_a, pep)
    param_var_names = Set(vn for (vn, role) in roles_a if role == :parameter)
    param_vars = [v for v in vars_a if string(v) in param_var_names]
    state_vars_a = [v for v in vars_a if !(string(v) in param_var_names)]
    state_vars_b = [v for v in vars_b if !(string(v) in param_var_names)]

    t_var = ModelingToolkit.get_iv(model)
    rename_dict = Dict{Any, Any}()
    state_vars_b_renamed = Num[]
    for v in state_vars_b
        vname = string(v)
        # Strip (t) if present, append _pt2, create as plain Symbolics variable (no (t))
        # This matches the SIAN convention where template vars are plain symbols
        base = replace(vname, r"\(.*\)$" => "")
        new_name = Symbol(base * "_pt2")
        new_var = Symbolics.variable(new_name)
        rename_dict[v] = new_var
        push!(state_vars_b_renamed, new_var)
    end
    eqs_b_renamed = [Symbolics.substitute(eq, rename_dict) for eq in eqs_b]

    # Classify equations using PRODUCTION interpolants (to identify data vs structural)
    # We need the production system to detect which equations carry noise
    max_d = maximum(values(setup_data.good_deriv_level))
    var_orders = Dict{Any, Int}()
    for v in vars_a
        parsed = ODEParameterEstimation.parse_derivative_variable_name(string(v))
        var_orders[v] = isnothing(parsed) ? 0 : parsed[2]
    end

    # Build production systems for classification only
    eqs_a_prod, vars_a_prod = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=interp, time_index_set=[t_idx_a],
        precomputed_interpolants=setup_data.interpolants)
    eqs_b_prod, vars_b_prod = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=interp, time_index_set=[t_idx_b],
        precomputed_interpolants=setup_data.interpolants)

    eq_info_a = _classify_eqs_simple(eqs_a_prod, vars_a_prod, var_orders, pep, setup_data, t_idx_a)
    eq_info_b = _classify_eqs_simple(eqs_b_prod, vars_b_prod, var_orders, pep, setup_data, t_idx_b)

    n_params = length(param_vars)
    n_to_drop = n_params

    if drop_strategy == :highest_data
        n_per = cld(n_to_drop, 2)
        drop_a = _select_drops(eq_info_a, min(n_per, n_to_drop))
        drop_b = _select_drops(eq_info_b, n_to_drop - length(drop_a))
    elseif drop_strategy == :drop_from_a
        drop_a = _select_drops(eq_info_a, n_to_drop)
        drop_b = Int[]
    elseif drop_strategy == :drop_from_b
        drop_a = Int[]
        drop_b = _select_drops(eq_info_b, n_to_drop)
    elseif drop_strategy == :none
        drop_a = Int[]
        drop_b = Int[]
    else
        error("Unknown strategy: $drop_strategy")
    end

    keep_a = setdiff(1:length(eqs_a), drop_a)
    keep_b = setdiff(1:length(eqs_b), drop_b)

    combined_eqs = vcat(eqs_a[collect(keep_a)], eqs_b_renamed[collect(keep_b)])
    combined_vars_set = OrderedCollections.OrderedSet{Any}()
    for eq in combined_eqs
        union!(combined_vars_set, Symbolics.get_variables(eq))
    end
    combined_vars = collect(combined_vars_set)

    # Build true values
    reverse_rename = Dict(v => k for (k, v) in rename_dict)
    t_vec = pep.data_sample["t"]
    true_vals = Float64[]
    for v in combined_vars
        if haskey(reverse_rename, v)
            orig_v = reverse_rename[v]
            val = ODEParameterEstimation._lookup_true_value(pep, orig_v;
                state_taylor=st_b, obs_taylor=ot_b, t_eval=t_vec[t_idx_b])
        else
            val = ODEParameterEstimation._lookup_true_value(pep, v;
                state_taylor=st_a, obs_taylor=ot_a, t_eval=t_vec[t_idx_a])
        end
        push!(true_vals, val)
    end

    return (eqs=combined_eqs, vars=combined_vars, true_vals=true_vals,
            n_dropped_a=length(drop_a), n_dropped_b=length(drop_b),
            param_vars=param_vars, rename_dict=rename_dict)
end

function _classify_eqs_simple(eqs, vars, var_orders, pep, setup_data, t_idx)
    # Use production vs oracle residual difference to identify data equations
    t_vec = pep.data_sample["t"]
    t_eval = t_vec[t_idx]
    max_d = maximum(values(setup_data.good_deriv_level))
    st = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep, t_eval, max_d + 2)
    ot = ODEParameterEstimation.compute_observable_taylor_coefficients(pep, st, t_eval, max_d + 2)
    true_vals = ODEParameterEstimation._build_true_value_vector(pep, vars;
        state_taylor=st, obs_taylor=ot, t_eval=t_eval)

    model = pep.model.system; mq = pep.measured_quantities

    # Production system
    f_prod = ODEParameterEstimation._compile_system_function(eqs, vars)
    r_prod = any(isnan, true_vals) ? fill(NaN, length(eqs)) : f_prod(true_vals)

    # Perfect system
    perfect = Dict{Num, ODEParameterEstimation.PerfectInterpolant}()
    for (key, tc) in ot
        perfect[key] = ODEParameterEstimation.PerfectInterpolant(t_eval, tc)
    end
    perf_eqs, _ = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[t_idx], precomputed_interpolants=perfect)
    f_perf = ODEParameterEstimation._compile_system_function(perf_eqs, vars)
    r_perf = any(isnan, true_vals) ? fill(NaN, length(eqs)) : f_perf(true_vals)

    info = []
    for (i, eq) in enumerate(eqs)
        eq_vars = Symbolics.get_variables(eq)
        max_ord = maximum(get(var_orders, v, 0) for v in eq_vars; init=0)
        is_data = abs(r_prod[i] - r_perf[i]) > 1e-12
        push!(info, (idx=i, max_order=max_ord, is_data=is_data, residual=abs(r_prod[i])))
    end
    return info
end

function _select_drops(eq_info, n)
    data_eqs = filter(e -> e.is_data, eq_info)
    sorted = sort(data_eqs, by=e -> (-e.max_order, -e.residual))
    return [e.idx for e in sorted[1:min(n, length(sorted))]]
end

# ─── Main ───────────────────────────────────────────────────────────────

models = OrderedDict{String, Any}(
    "simple" => (ODEParameterEstimation.simple, [0.0, 1.0]),
    "lotka_volterra" => (ODEParameterEstimation.lotka_volterra, nothing),
    "forced_lv_sinusoidal" => (ODEParameterEstimation.forced_lv_sinusoidal, nothing),
)

strategies = [:highest_data, :drop_from_a, :drop_from_b]

println("=" ^ 110)
println("EXPERIMENT 3: HC.jl Solve on 2-Point Oracle Systems")
println("=" ^ 110)

for (name, (ctor, oti)) in models
    println("\n", "━" ^ 100)
    println("MODEL: $name")
    println("━" ^ 100)

    pep = try; ctor(); catch e; println("  SKIP: $e"); continue; end
    ti = !isnothing(oti) ? oti : !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]
    pep_data = try
        ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=21, time_interval=ti, nooutput=true))
    catch e; println("  SKIP: $e"); continue; end
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var); catch; (pep_data, nothing); end

    setup = try
        ODEParameterEstimation.setup_parameter_estimation(
            pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    catch e; println("  Setup failed: $e"); continue; end

    t_vec = pep_work.data_sample["t"]
    n_t = length(t_vec)
    t_idx_a = max(2, round(Int, n_t * 0.33))
    t_idx_b = min(n_t - 1, round(Int, n_t * 0.67))

    println("  Points: t_a=$(t_vec[t_idx_a]), t_b=$(t_vec[t_idx_b])")

    # 1-point baseline with oracle
    println("\n  --- 1-point baseline (oracle) ---")
    try
        oracle_mid, st_mid, ot_mid = build_oracle_interpolants(pep_work, setup.time_index_set[1], setup)
        eqs_1pt, vars_1pt = ODEParameterEstimation.construct_equation_system_from_si_template(
            pep_work.model.system, pep_work.measured_quantities, pep_work.data_sample,
            setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot,
            time_index_set=[setup.time_index_set[1]],
            precomputed_interpolants=oracle_mid)

        solutions_1pt, _, _, _ = ODEParameterEstimation.solve_with_hc(eqs_1pt, vars_1pt)
        true_1pt = ODEParameterEstimation._build_true_value_vector(pep_work, vars_1pt;
            state_taylor=st_mid, obs_taylor=ot_mid, t_eval=t_vec[setup.time_index_set[1]])

        n_real = length(solutions_1pt)
        if n_real > 0
            dists = [norm(s .- true_1pt) for s in solutions_1pt]
            best_dist = minimum(dists)
            println("  1-point: $(length(eqs_1pt))×$(length(vars_1pt)), $n_real real solutions, closest to truth: $(@sprintf("%.2e", best_dist))")
        else
            println("  1-point: $(length(eqs_1pt))×$(length(vars_1pt)), 0 solutions!")
        end
    catch e
        println("  1-point baseline failed: ", sprint(showerror, e)[1:min(100,end)])
    end

    # 2-point with each strategy
    println("\n  --- 2-point systems (oracle) ---")
    @printf("  %-25s  %-10s  %-8s  %-10s  %-12s  %s\n",
        "Strategy", "Size", "Sols", "Dist→true", "Degree", "Notes")
    println("  ", "-" ^ 85)

    for strat in strategies
        try
            result = build_two_point_oracle(pep_work, setup, t_idx_a, t_idx_b; drop_strategy=strat)
            ne = length(result.eqs)
            nv = length(result.vars)

            if ne != nv
                @printf("  %-25s  %d×%d     NOT SQUARE\n", "$strat ($(result.n_dropped_a)+$(result.n_dropped_b))", ne, nv)
                continue
            end

            # Try HC.jl solve
            solutions, _, _, _ = try
                ODEParameterEstimation.solve_with_hc(result.eqs, result.vars)
            catch e
                @printf("  %-25s  %d×%d     HC FAILED: %s\n",
                    "$strat ($(result.n_dropped_a)+$(result.n_dropped_b))", ne, nv,
                    sprint(showerror, e)[1:min(50,end)])
                continue
            end

            n_real = length(solutions)
            dist_str = "—"
            if n_real > 0 && !any(isnan, result.true_vals)
                dists = [norm(s .- result.true_vals) for s in solutions]
                best_dist = minimum(dists)
                dist_str = @sprintf("%.2e", best_dist)
            end

            @printf("  %-25s  %d×%d     %-8d  %-12s  %s\n",
                "$strat ($(result.n_dropped_a)+$(result.n_dropped_b))",
                ne, nv, n_real, dist_str,
                n_real == 0 ? "⚠ NO SOLUTIONS (positive-dimensional?)" :
                n_real == 1 ? "unique" : "$n_real branches")

        catch e
            @printf("  %-25s  FAILED: %s\n", string(strat), sprint(showerror, e)[1:min(70,end)])
        end
    end
end

println("\n", "=" ^ 110)
println("EXPERIMENT 3 COMPLETE")
println("=" ^ 110)
