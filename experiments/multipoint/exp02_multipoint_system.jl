# Experiment 2: Build actual 2-point system with variable renaming and check rank
#
# For each model:
#   1. Instantiate template at two different time points
#   2. Rename per-point state variables (keep params shared)
#   3. Combine into one system
#   4. Try different equation-dropping strategies
#   5. Check Jacobian rank of the combined system at oracle values
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp02_multipoint_system.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using Symbolics
using LinearAlgebra
using ForwardDiff
using Printf

# ─── Core helper: build a 2-point system ────────────────────────────────

function build_two_point_system(pep, setup_data, t_idx_a, t_idx_b;
    drop_strategy=:highest_data)

    model = pep.model.system
    mq = pep.measured_quantities
    interp = ODEParameterEstimation.aaad_gpr_pivot

    # Instantiate template at point A
    eqs_a, vars_a = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=interp, time_index_set=[t_idx_a],
        precomputed_interpolants=setup_data.interpolants)

    # Instantiate template at point B
    eqs_b, vars_b = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=interp, time_index_set=[t_idx_b],
        precomputed_interpolants=setup_data.interpolants)

    # Classify variables into params (shared) vs state (per-point)
    var_names_a = string.(vars_a)
    roles_a = ODEParameterEstimation._classify_polynomial_variables(var_names_a, pep)

    param_var_names = Set(vn for (vn, role) in roles_a if role == :parameter)
    param_vars = [v for v in vars_a if string(v) in param_var_names]
    state_vars_a = [v for v in vars_a if !(string(v) in param_var_names)]
    # Point B: state vars are those whose name is NOT a parameter name
    state_vars_b = [v for v in vars_b if !(string(v) in param_var_names)]

    # Rename point B state variables: append _pt2
    # Use plain Symbolics variables (no (t) suffix) to match SIAN's naming convention
    t_var = ModelingToolkit.get_iv(model)
    rename_dict = Dict{Any, Any}()
    state_vars_b_renamed = Num[]

    for v in state_vars_b
        vname = string(v)
        base = replace(vname, r"\(.*\)$" => "")
        new_name = Symbol(base * "_pt2")
        new_var = Symbolics.variable(new_name)
        rename_dict[v] = new_var
        push!(state_vars_b_renamed, new_var)
    end

    # Substitute renamed variables into point B equations
    eqs_b_renamed = [Symbolics.substitute(eq, rename_dict) for eq in eqs_b]

    # Classify equations by type (data vs structural) and derivative order
    # Use perfect interpolants to detect which equations carry noise
    t_vec = pep.data_sample["t"]
    max_d = maximum(values(setup_data.good_deriv_level))

    eq_info_a = classify_equations(eqs_a, vars_a, pep, setup_data, t_idx_a, max_d)
    eq_info_b = classify_equations(eqs_b, vars_b, pep, setup_data, t_idx_b, max_d)

    # Determine which equations to drop based on strategy
    n_params = length(param_vars)
    n_to_drop = n_params  # Always need to drop n_params equations for squareness

    if drop_strategy == :highest_data
        # Drop the n_params DATA equations with highest derivative order
        # Split equally between points (drop n_params/2 from each if possible)
        n_drop_per_point = cld(n_to_drop, 2)  # ceiling division

        drop_a = select_drop_candidates(eq_info_a, min(n_drop_per_point, n_to_drop))
        remaining_to_drop = n_to_drop - length(drop_a)
        drop_b = select_drop_candidates(eq_info_b, remaining_to_drop)

        keep_a = setdiff(1:length(eqs_a), drop_a)
        keep_b = setdiff(1:length(eqs_b), drop_b)

    elseif drop_strategy == :highest_data_point_a_only
        # Drop all n_params highest data eqs from point A only
        drop_a = select_drop_candidates(eq_info_a, n_to_drop)
        keep_a = setdiff(1:length(eqs_a), drop_a)
        keep_b = 1:length(eqs_b)

    elseif drop_strategy == :highest_data_point_b_only
        keep_a = 1:length(eqs_a)
        drop_b = select_drop_candidates(eq_info_b, n_to_drop)
        keep_b = setdiff(1:length(eqs_b), drop_b)

    elseif drop_strategy == :none
        # Keep all equations (overdetermined)
        keep_a = 1:length(eqs_a)
        keep_b = 1:length(eqs_b)

    else
        error("Unknown drop strategy: $drop_strategy")
    end

    # Build combined system
    combined_eqs = vcat(eqs_a[collect(keep_a)], eqs_b_renamed[collect(keep_b)])

    # Collect all variables from the combined equations
    combined_vars_set = OrderedCollections.OrderedSet{Any}()
    for eq in combined_eqs
        union!(combined_vars_set, Symbolics.get_variables(eq))
    end
    combined_vars = collect(combined_vars_set)

    return (
        eqs = combined_eqs,
        vars = combined_vars,
        param_vars = param_vars,
        state_vars_a = state_vars_a,
        state_vars_b_renamed = state_vars_b_renamed,
        rename_dict = rename_dict,
        n_dropped_a = length(eqs_a) - length(keep_a),
        n_dropped_b = length(eqs_b) - length(keep_b),
        eq_info_a = eq_info_a,
        eq_info_b = eq_info_b,
    )
end

function classify_equations(eqs, vars, pep, setup_data, t_idx, max_d)
    # Build perfect interpolants to distinguish data vs structural
    t_vec = pep.data_sample["t"]
    t_eval = t_vec[t_idx]
    model = pep.model.system
    mq = pep.measured_quantities

    state_taylor = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep, t_eval, max_d + 2)
    obs_taylor = ODEParameterEstimation.compute_observable_taylor_coefficients(pep, state_taylor, t_eval, max_d + 2)

    perfect_interps = Dict{Num, ODEParameterEstimation.PerfectInterpolant}()
    for (key, tc) in obs_taylor
        perfect_interps[key] = ODEParameterEstimation.PerfectInterpolant(t_eval, tc)
    end

    perf_eqs, _ = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[t_idx],
        precomputed_interpolants=perfect_interps)

    # Evaluate residuals
    true_vals = ODEParameterEstimation._build_true_value_vector(pep, vars;
        state_taylor=state_taylor, obs_taylor=obs_taylor, t_eval=t_eval)

    f_prod = ODEParameterEstimation._compile_system_function(eqs, vars)
    f_perf = ODEParameterEstimation._compile_system_function(perf_eqs, vars)
    r_prod = any(isnan, true_vals) ? fill(NaN, length(eqs)) : f_prod(true_vals)
    r_perf = any(isnan, true_vals) ? fill(NaN, length(eqs)) : f_perf(true_vals)

    # Classify each variable
    var_orders = Dict{Any, Int}()
    for v in vars
        parsed = ODEParameterEstimation.parse_derivative_variable_name(string(v))
        var_orders[v] = isnothing(parsed) ? 0 : parsed[2]
    end

    info = []
    for (i, eq) in enumerate(eqs)
        eq_vars = Symbolics.get_variables(eq)
        max_ord = maximum(get(var_orders, v, 0) for v in eq_vars; init=0)
        is_data = abs(r_prod[i] - r_perf[i]) > 1e-12
        push!(info, (idx=i, max_order=max_ord, is_data=is_data, residual=r_prod[i]))
    end
    return info
end

function select_drop_candidates(eq_info, n_drop)
    # Select the n_drop DATA equations with highest derivative order
    data_eqs = filter(e -> e.is_data, eq_info)
    sorted = sort(data_eqs, by=e -> (-e.max_order, -abs(e.residual)))
    return [e.idx for e in sorted[1:min(n_drop, length(sorted))]]
end

# ─── Build oracle true values for the combined system ───────────────────

function build_combined_true_values(pep, combined_vars, state_vars_a, state_vars_b_renamed,
    rename_dict, t_idx_a, t_idx_b, setup_data)

    t_vec = pep.data_sample["t"]
    max_d = maximum(values(setup_data.good_deriv_level))

    # Oracle at point A
    t_a = t_vec[t_idx_a]
    st_a = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep, t_a, max_d + 2)
    ot_a = ODEParameterEstimation.compute_observable_taylor_coefficients(pep, st_a, t_a, max_d + 2)

    # Oracle at point B
    t_b = t_vec[t_idx_b]
    st_b = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep, t_b, max_d + 2)
    ot_b = ODEParameterEstimation.compute_observable_taylor_coefficients(pep, st_b, t_b, max_d + 2)

    # Build reverse rename dict: renamed var → original var
    reverse_rename = Dict(v => k for (k, v) in rename_dict)

    # Get original vars_a for lookup
    model = pep.model.system
    mq = pep.measured_quantities
    _, vars_a_orig = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[t_idx_a],
        precomputed_interpolants=setup_data.interpolants)

    # Build true values for each combined variable
    true_vals = Float64[]
    for v in combined_vars
        if haskey(reverse_rename, v)
            # This is a renamed point-B variable — look up its original at point B
            orig_v = reverse_rename[v]
            val = ODEParameterEstimation._lookup_true_value(pep, orig_v;
                state_taylor=st_b, obs_taylor=ot_b, t_eval=t_b)
        else
            # This is a point-A variable or shared parameter — look up at point A
            val = ODEParameterEstimation._lookup_true_value(pep, v;
                state_taylor=st_a, obs_taylor=ot_a, t_eval=t_a)
        end
        push!(true_vals, val)
    end
    return true_vals
end

# ─── Main experiment ────────────────────────────────────────────────────

models = OrderedDict{String, Any}(
    "simple" => (ODEParameterEstimation.simple, [0.0, 1.0]),
    "lotka_volterra" => (ODEParameterEstimation.lotka_volterra, nothing),
    "forced_lv_sinusoidal" => (ODEParameterEstimation.forced_lv_sinusoidal, nothing),
    "seir" => (ODEParameterEstimation.seir, nothing),
)

println("=" ^ 110)
println("EXPERIMENT 2: Multi-Point System Construction + Rank Check")
println("=" ^ 110)

strategies = [:highest_data, :highest_data_point_a_only, :highest_data_point_b_only]

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

    # Pick two well-separated points (33% and 67% of interval)
    t_idx_a = max(2, round(Int, n_t * 0.33))
    t_idx_b = min(n_t - 1, round(Int, n_t * 0.67))
    println("  Points: t_a=$(t_vec[t_idx_a]) (idx=$t_idx_a), t_b=$(t_vec[t_idx_b]) (idx=$t_idx_b)")

    # For reference: 1-point system
    eqs_1pt, vars_1pt = ODEParameterEstimation.construct_equation_system_from_si_template(
        pep_work.model.system, pep_work.measured_quantities, pep_work.data_sample,
        setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[setup.time_index_set[1]],
        precomputed_interpolants=setup.interpolants)
    roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars_1pt), pep_work)
    n_params = count(v -> v == :parameter, values(roles))
    println("  1-point baseline: $(length(eqs_1pt))×$(length(vars_1pt)) ($n_params params)")

    # Test each drop strategy
    @printf("\n  %-30s  %-12s  %-12s  %-12s  %-8s  %s\n",
        "Strategy", "Eqs", "Vars", "Square?", "J_rank", "Status")
    println("  ", "-" ^ 90)

    for strat in strategies
        try
            result = build_two_point_system(pep_work, setup, t_idx_a, t_idx_b; drop_strategy=strat)
            ne = length(result.eqs)
            nv = length(result.vars)
            is_square = ne == nv

            # Build combined oracle true values
            true_vals = build_combined_true_values(pep_work, result.vars,
                result.state_vars_a, result.state_vars_b_renamed,
                result.rename_dict, t_idx_a, t_idx_b, setup)

            jrank = 0
            status = ""
            if !any(isnan, true_vals) && ne > 0 && nv > 0
                try
                    f = ODEParameterEstimation._compile_system_function(result.eqs, result.vars)
                    J = ForwardDiff.jacobian(f, true_vals)
                    jrank = rank(J; atol=1e-8)

                    if is_square && jrank == nv
                        # Also check residual at true values
                        r = f(true_vals)
                        res_norm = norm(r)
                        status = res_norm < 1e-8 ? "✓ FULL RANK, res=$(Printf.@sprintf("%.1e", res_norm))" :
                                 "✓ FULL RANK, res=$(Printf.@sprintf("%.1e", res_norm)) (production noise)"
                    elseif jrank == nv
                        status = "full rank but not square"
                    else
                        status = "✗ RANK DEFICIENT ($(jrank)/$(nv))"
                    end
                catch e
                    status = "compile error: $(sprint(showerror, e)[1:min(60,end)])"
                end
            else
                status = "NaN in true values"
            end

            dropped_str = "drop $(result.n_dropped_a)+$(result.n_dropped_b)"
            @printf("  %-30s  %-12s  %-12s  %-12s  %-8s  %s\n",
                "$strat ($dropped_str)", "$(ne)", "$(nv)", is_square, jrank, status)

        catch e
            @printf("  %-30s  FAILED: %s\n", string(strat), sprint(showerror, e)[1:min(70,end)])
        end
    end

    # Also test: full overdetermined system (no drops)
    try
        result = build_two_point_system(pep_work, setup, t_idx_a, t_idx_b; drop_strategy=:none)
        ne = length(result.eqs)
        nv = length(result.vars)
        true_vals = build_combined_true_values(pep_work, result.vars,
            result.state_vars_a, result.state_vars_b_renamed,
            result.rename_dict, t_idx_a, t_idx_b, setup)

        if !any(isnan, true_vals)
            f = ODEParameterEstimation._compile_system_function(result.eqs, result.vars)
            J = ForwardDiff.jacobian(f, true_vals)
            jrank = rank(J; atol=1e-8)
            r = f(true_vals)

            @printf("  %-30s  %-12s  %-12s  %-12s  %-8s  %s\n",
                "none (overdetermined)", "$(ne)", "$(nv)", "no", jrank,
                "res=$(Printf.@sprintf("%.1e", norm(r))), rank $jrank/$nv")
        end
    catch e
        println("  overdetermined: FAILED — $e")
    end
end

println("\n", "=" ^ 110)
println("EXPERIMENT 2 COMPLETE")
println("=" ^ 110)
