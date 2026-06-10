# Split 2026-06-10 from the 5,443-line src/core/diagnostics.jl (Phase F2;
# pure content move, functions byte-identical). Part: variable classification, polynomial feasibility, sensitivity analysis.
# ─── Variable classification ───────────────────────────────────────────

"""
    _classify_polynomial_variables(var_names, pep)

Classify each variable name in the polynomial system into a role:
  :parameter, :state_ic, :state_derivative, :data_derivative, :transcendental

Uses `parse_derivative_variable_name` to decompose SIAN-style names (e.g. `x1_0`, `y1_2`).
"""
function _classify_polynomial_variables(var_names::Vector{String}, pep::ParameterEstimationProblem)
    roles = Dict{String, Symbol}()

    # Build lookup sets
    param_bases = Set{String}()
    for p in keys(pep.p_true)
        push!(param_bases, replace(string(p), "(t)" => ""))
    end
    state_bases = Set{String}()
    for s in keys(pep.ic)
        push!(state_bases, replace(string(s), "(t)" => ""))
    end
    obs_bases = Set{String}()
    for mq in pep.measured_quantities
        obs_name = replace(string(mq.lhs), "(t)" => "")
        # Strip _obs_trfn_ prefix for matching
        if !startswith(obs_name, "_obs_trfn_")
            push!(obs_bases, obs_name)
        end
    end

    for vn in var_names
        # Check transcendental first
        if contains(vn, "_trfn_")
            roles[vn] = :transcendental
            continue
        end

        parsed = parse_derivative_variable_name(vn)
        if !isnothing(parsed)
            base_name, deriv_order = parsed

            # Parameter (order 0 only in SI template)
            if base_name in param_bases && deriv_order == 0
                roles[vn] = :parameter
                continue
            end

            # State IC (order 0) or state derivative (order > 0)
            if base_name in state_bases
                roles[vn] = deriv_order == 0 ? :state_ic : :state_derivative
                continue
            end

            # Observable derivative (data variable)
            if base_name in obs_bases
                roles[vn] = :data_derivative
                continue
            end
        end

        # Direct parameter match (no _N suffix)
        if vn in param_bases
            roles[vn] = :parameter
            continue
        end

        # Direct state match
        if vn in state_bases
            roles[vn] = :state_ic
            continue
        end

        # Default to state_derivative (unknown role)
        roles[vn] = :state_derivative
    end

    return roles
end

"""
    _equations_to_strings(equations)

Convert symbolic equations to human-readable strings.
"""
function _equations_to_strings(equations)
    return [string(eq) * " = 0" for eq in equations]
end

# ─── Polynomial feasibility diagnosis ─────────────────────────────────

"""
    diagnose_polynomial_system(pep; kwargs...) → PolynomialFeasibilityReport

Build the SI polynomial system with both perfect (oracle) and production
interpolant data, solve both with HC.jl, and compare solution counts,
residuals, and distances to the true parameter values.
"""
function diagnose_polynomial_system(
    pep::ParameterEstimationProblem;
    interpolator = agp_gpr_robust,
    setup_data = nothing,
    t_eval::Union{Nothing, Float64} = nothing,
    max_order::Union{Nothing, Int} = nothing,
    kwargs...,
)
    if isnothing(setup_data)
        t_var_for_trfn = ModelingToolkit.get_iv(pep.model.system)
        pep, _ = try
            transform_pep_for_estimation(pep, t_var_for_trfn)
        catch e
            @warn "[DIAGNOSE_POLY] Transcendental transform failed (may not be needed): $e"
            (pep, nothing)
        end
        setup_data = setup_parameter_estimation(pep; interpolator = interpolator, nooutput = true)
    end

    t_vec = pep.data_sample["t"]
    if isnothing(t_eval)
        idx = setup_data.time_index_set[1]
        t_eval = t_vec[idx]
    end
    time_idx = argmin(abs.(t_vec .- t_eval))

    if isnothing(max_order)
        max_order = isempty(setup_data.good_deriv_level) ? 2 : maximum(values(setup_data.good_deriv_level))
    end

    model = pep.model.system
    mq = pep.measured_quantities

    # Compute oracle Taylor coefficients for true-value lookup
    state_taylor = compute_oracle_taylor_coefficients(pep, t_eval, max_order + 2; kwargs...)
    obs_taylor = compute_observable_taylor_coefficients(pep, state_taylor, t_eval, max_order + 2)

    # Build perfect interpolants from oracle data
    perfect_interps = Dict{Num, PerfectInterpolant}()
    for (key, tc) in obs_taylor
        perfect_interps[key] = PerfectInterpolant(t_eval, tc)
    end

    # Build polynomial system with PRODUCTION interpolants
    prod_eqs, prod_vars = construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator = interpolator,
        time_index_set = [time_idx],
        precomputed_interpolants = setup_data.interpolants,
    )

    # Build polynomial system with PERFECT interpolants
    perf_eqs, perf_vars = construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator = interpolator,
        time_index_set = [time_idx],
        precomputed_interpolants = perfect_interps,
    )

    n_eqs = length(prod_eqs)
    n_vars = length(prod_vars)
    is_square = n_eqs == n_vars
    var_names = string.(prod_vars)

    # Solve both systems
    prod_solutions = Vector{Float64}[]
    perf_solutions = Vector{Float64}[]

    if is_square && n_vars > 0
        try
            prod_solutions, _, _, _ = solve_with_hc(prod_eqs, prod_vars)
        catch e
            @warn "[DIAG] HC.jl failed on production system: $e"
        end
        try
            perf_solutions, _, _, _ = solve_with_hc(perf_eqs, perf_vars)
        catch e
            @warn "[DIAG] HC.jl failed on perfect system: $e"
        end
    end

    # Map variable names to true values (using oracle Taylor for derivative vars)
    true_vals = _build_true_value_vector(pep, prod_vars;
        state_taylor = state_taylor, obs_taylor = obs_taylor, t_eval = t_eval)

    # Compute residuals at true values
    true_res_prod = _compute_residual(prod_eqs, prod_vars, true_vals)
    true_res_perf = _compute_residual(perf_eqs, perf_vars, true_vals)

    # Closest solution distance (with per-variable values for error budget)
    dist_prod, closest_sol_prod = _closest_solution_with_values(prod_solutions, true_vals)
    dist_perf = _closest_solution_distance(perf_solutions, true_vals)

    # Classify variables and store equation strings
    eq_strings = _equations_to_strings(prod_eqs)
    var_roles = _classify_polynomial_variables(var_names, pep)

    # Capture d_prod and d_true for signed IFT validation
    dv_labels, dv_prod, dv_true = _capture_data_variable_values(
        setup_data, pep, t_eval, state_taylor, obs_taylor, max_order)

    return PolynomialFeasibilityReport(
        pep.name, n_eqs, n_vars, is_square,
        length(perf_solutions), length(prod_solutions),
        true_res_perf, true_res_prod,
        dist_perf, dist_prod,
        var_names, eq_strings, var_roles,
        closest_sol_prod, Float64.(true_vals),
        dv_labels, dv_prod, dv_true,
    )
end

"""
Capture data variable values (d_prod from interpolants, d_true from oracle Taylor)
for a given evaluation point. Returns `(labels, d_prod, d_true)`.
"""
function _capture_data_variable_values(
    setup_data, pep, t_eval, state_taylor, obs_taylor, max_order,
)
    mq = pep.measured_quantities
    DD = setup_data.good_DD

    t_vec = pep.data_sample["t"]
    time_idx = argmin(abs.(t_vec .- t_eval))
    t_point = t_vec[time_idx]

    labels = String[]
    d_prod_vals = Float64[]
    d_true_vals = Float64[]

    # DD.obs_lhs[level][obs_idx] is the symbolic variable for observable obs_idx at derivative level (level-1)
    !hasproperty(DD, :obs_lhs) && return labels, d_prod_vals, d_true_vals

    for (level_idx, level_vars) in enumerate(DD.obs_lhs)
        deriv_level = level_idx - 1
        for (obs_idx, lhs_var) in enumerate(level_vars)
            obs_idx > length(mq) && continue
            label = string(lhs_var)

            # d_true from oracle Taylor
            d_true_val = NaN
            if !isnothing(obs_taylor)
                obs_rhs_key = ModelingToolkit.diff2term(mq[obs_idx].rhs)
                if haskey(obs_taylor, obs_rhs_key)
                    tc = obs_taylor[obs_rhs_key]
                    if deriv_level + 1 <= length(tc)
                        d_true_val = tc[deriv_level + 1] * factorial(deriv_level)
                    end
                end
            end

            # d_prod from production interpolants
            d_prod_val = NaN
            if haskey(setup_data.interpolants, ModelingToolkit.diff2term(mq[obs_idx].rhs))
                interp = setup_data.interpolants[ModelingToolkit.diff2term(mq[obs_idx].rhs)]
                try
                    d_prod_val = Float64(nth_deriv(x -> interp(x), deriv_level, t_point))
                catch
                end
            end

            push!(labels, label)
            push!(d_prod_vals, d_prod_val)
            push!(d_true_vals, d_true_val)
        end
    end

    return labels, d_prod_vals, d_true_vals
end

"""
Build a vector of true values in the order of `varlist` by matching
variable names to parameters, states, and their derivatives.
Uses oracle Taylor coefficients to resolve derivative variables (e.g., x1_1, x2_2).
"""
function _build_true_value_vector(pep::ParameterEstimationProblem, varlist;
    state_taylor::Union{Nothing, Dict{Num, Vector{Float64}}} = nothing,
    obs_taylor::Union{Nothing, Dict{Num, Vector{Float64}}} = nothing,
    t_eval::Float64 = 0.0,
)
    true_vals = Float64[]
    for v in varlist
        val = _lookup_true_value(pep, v; state_taylor = state_taylor, obs_taylor = obs_taylor, t_eval = t_eval)
        push!(true_vals, val)
    end
    return true_vals
end

function _lookup_true_value(pep::ParameterEstimationProblem, var;
    state_taylor::Union{Nothing, Dict{Num, Vector{Float64}}} = nothing,
    obs_taylor::Union{Nothing, Dict{Num, Vector{Float64}}} = nothing,
    t_eval::Float64 = 0.0,
)
    # Direct parameter match
    for (p, v) in pep.p_true
        if isequal(var, p)
            return v
        end
    end
    # Direct state match
    for (s, v) in pep.ic
        if isequal(var, s)
            return v
        end
    end

    var_name = string(var)

    # Check bare _obs_trfn_ names (Symbolics form, no _N suffix) before parsing
    clean_name = replace(var_name, r"\(.*\)" => "")
    obs_trfn_val = evaluate_obs_trfn_template_variable(clean_name, t_eval)
    if !isnothing(obs_trfn_val)
        return obs_trfn_val
    end

    # Try parse as derivative variable (e.g., y1_0, x1_0, x2_2)
    parsed = parse_derivative_variable_name(var_name)
    if !isnothing(parsed)
        base_name, deriv_order = parsed

        # Check if it's a _trfn_ or _obs_trfn_ variable
        trfn_val = evaluate_trfn_template_variable(var_name, t_eval)
        if isnothing(trfn_val)
            trfn_val = evaluate_obs_trfn_template_variable(var_name, t_eval)
        end
        if !isnothing(trfn_val)
            return trfn_val
        end

        # Match against parameters by base name (order 0 only)
        for (p, v) in pep.p_true
            p_str = string(p)
            p_base = replace(p_str, "(t)" => "")
            if p_base == base_name && deriv_order == 0
                return v
            end
        end

        # Match against states by base name — use Taylor coefficients for all orders
        # SIAN variables store actual derivatives f^(k)(t_eval), not Taylor coeffs f^(k)(t0)/k!
        # Taylor coeffs are at t_eval, so tc[k+1] * k! = f^(k)(t_eval)
        for (s, v) in pep.ic
            s_str = string(s)
            s_base = replace(s_str, "(t)" => "")
            if s_base == base_name
                if !isnothing(state_taylor) && haskey(state_taylor, s)
                    tc = state_taylor[s]
                    if deriv_order + 1 <= length(tc)
                        return tc[deriv_order + 1] * factorial(deriv_order)
                    end
                end
                # Fallback: IC only valid for order 0 at t=0
                if deriv_order == 0
                    return v
                end
            end
        end

        # Match against observable names — use observable Taylor coefficients
        if !isnothing(obs_taylor)
            for mq in pep.measured_quantities
                obs_lhs_name = replace(string(mq.lhs), "(t)" => "")
                if obs_lhs_name == base_name
                    key = ModelingToolkit.diff2term(mq.rhs)
                    if haskey(obs_taylor, key)
                        tc = obs_taylor[key]
                        if deriv_order + 1 <= length(tc)
                            return tc[deriv_order + 1] * factorial(deriv_order)
                        end
                    end
                end
            end
        end
    end

    # Unknown variable — return NaN
    @warn "[DIAG] Could not find true value for variable: $var"
    return NaN
end

function _compute_residual(equations, varlist, vals)
    if isempty(equations) || isempty(vals) || any(isnan, vals)
        return NaN
    end
    try
        f = _compile_system_function(equations, varlist)
        r = f(vals)
        return norm(r)
    catch
        # Fallback to substitution
        subst_dict = Dict(varlist[i] => vals[i] for i in eachindex(varlist))
        total = 0.0
        for eq in equations
            r = try
                Float64(Symbolics.value(Symbolics.substitute(eq, subst_dict)))
            catch
                NaN
            end
            total += r^2
        end
        return sqrt(total)
    end
end

function _closest_solution_distance(solutions, true_vals)
    if isempty(solutions) || any(isnan, true_vals)
        return Inf
    end
    min_dist = Inf
    for sol in solutions
        d = norm(sol .- true_vals)
        min_dist = min(min_dist, d)
    end
    return min_dist
end

"""
Return `(distance, solution_vector)` for the closest solution to `true_vals`.
Returns `(Inf, Float64[])` when no solutions exist.
"""
function _closest_solution_with_values(solutions, true_vals)
    if isempty(solutions) || any(isnan, true_vals)
        return (Inf, Float64[])
    end
    min_dist = Inf
    best_sol = Float64[]
    for sol in solutions
        d = norm(sol .- true_vals)
        if d < min_dist
            min_dist = d
            best_sol = sol
        end
    end
    return (min_dist, best_sol)
end

# ─── Sensitivity analysis ─────────────────────────────────────────────

"""
    diagnose_sensitivity(pep; kwargs...) → SensitivityReport

Compute Jacobian conditioning at the true solution and root displacement
between perfect and production polynomial systems.
"""
function diagnose_sensitivity(
    pep::ParameterEstimationProblem;
    interpolator = agp_gpr_robust,
    setup_data = nothing,
    poly_report::Union{Nothing, PolynomialFeasibilityReport} = nothing,
    t_eval::Union{Nothing, Float64} = nothing,
    max_order::Union{Nothing, Int} = nothing,
    kwargs...,
)
    if isnothing(setup_data)
        t_var_for_trfn = ModelingToolkit.get_iv(pep.model.system)
        pep, _ = try
            transform_pep_for_estimation(pep, t_var_for_trfn)
        catch e
            @warn "[DIAGNOSE_SENS] Transcendental transform failed (may not be needed): $e"
            (pep, nothing)
        end
        setup_data = setup_parameter_estimation(pep; interpolator = interpolator, nooutput = true)
    end

    t_vec = pep.data_sample["t"]
    if isnothing(t_eval)
        idx = setup_data.time_index_set[1]
        t_eval = t_vec[idx]
    end
    time_idx = argmin(abs.(t_vec .- t_eval))

    if isnothing(max_order)
        max_order = isempty(setup_data.good_deriv_level) ? 2 : maximum(values(setup_data.good_deriv_level))
    end

    model = pep.model.system
    mq = pep.measured_quantities

    # Compute oracle Taylor for true-value lookup
    state_taylor = compute_oracle_taylor_coefficients(pep, t_eval, max_order + 2; kwargs...)
    obs_taylor = compute_observable_taylor_coefficients(pep, state_taylor, t_eval, max_order + 2)

    # Build production system to get equations + varlist
    prod_eqs, prod_vars = construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator = interpolator,
        time_index_set = [time_idx],
        precomputed_interpolants = setup_data.interpolants,
    )

    true_vals = _build_true_value_vector(pep, prod_vars;
        state_taylor = state_taylor, obs_taylor = obs_taylor, t_eval = t_eval)
    n_vars = length(prod_vars)

    # Compute Jacobian via ForwardDiff on a compiled system function
    jac_cond = NaN
    eff_rank = 0
    svs = Float64[]
    J_matrix = Matrix{Float64}(undef, 0, 0)

    if n_vars > 0 && !any(isnan, true_vals)
        try
            sys_fn = _compile_system_function(prod_eqs, prod_vars)
            J = ForwardDiff.jacobian(sys_fn, true_vals)
            J_matrix = J

            sv = svd(J)
            svs = sv.S
            jac_cond = length(svs) > 0 ? svs[1] / max(svs[end], 1e-300) : NaN
            eff_rank = count(s -> s > 1e-10 * svs[1], svs)
        catch e
            @warn "[DIAG] Jacobian computation failed: $e"
        end
    end

    # Root displacement: ||sol_prod - sol_perf|| / ||data_prod - data_perf||
    root_sens = NaN
    if !isnothing(poly_report) && isfinite(poly_report.closest_distance_production) && isfinite(poly_report.closest_distance_perfect)
        data_diff = abs(poly_report.true_residual_production - poly_report.true_residual_perfect)
        if data_diff > 1e-300
            root_sens = abs(poly_report.closest_distance_production - poly_report.closest_distance_perfect) / data_diff
        end
    end

    # Build Jacobian labels and variable roles
    eq_labels = ["Eq $i" for i in 1:length(prod_eqs)]
    var_names = [string(v) for v in prod_vars]
    var_roles = _classify_polynomial_variables(var_names, pep)

    # ── Parameter-data sensitivity: dx*/dd via implicit function theorem ──
    S_matrix = Matrix{Float64}(undef, 0, 0)
    data_labels = String[]
    data_roles = Dict{String, Symbol}()
    unknown_labels = String[]
    unknown_roles = Dict{String, Symbol}()

    try
        S_matrix, data_labels, data_roles, unknown_labels, unknown_roles = _compute_data_sensitivity(
            pep, setup_data, t_eval, prod_vars, true_vals;
            state_taylor = state_taylor, obs_taylor = obs_taylor, kwargs...)
    catch e
        @warn "[DIAG] Data sensitivity computation failed: $e"
    end

    return SensitivityReport(pep.name, jac_cond, eff_rank, svs, root_sens,
        J_matrix, eq_labels, var_names, var_roles,
        S_matrix, data_labels, data_roles, unknown_labels, unknown_roles)
end

"""
    _compute_data_sensitivity(pep, setup_data, t_eval, prod_vars, true_vals; kwargs...)

Compute the parameter-data sensitivity matrix S = -(∂F/∂x)⁻¹ · (∂F/∂d) via the
implicit function theorem.  Here F(x, d) = 0 is the SI polynomial system, x are
the unknowns (params, ICs, state derivatives), and d are the data variables
(interpolated observable derivatives).

S[i,j] tells you: a unit perturbation in data variable j causes S[i,j] displacement
in unknown i.  This directly quantifies how interpolation errors propagate to
recovered parameter values.

Returns `(S_matrix, data_labels, data_roles)`.
"""
function _compute_data_sensitivity(
    pep::ParameterEstimationProblem,
    setup_data,
    t_eval::Float64,
    prod_vars,
    true_vals;
    state_taylor = nothing,
    obs_taylor = nothing,
    kwargs...,
)
    model = pep.model.system
    mq = pep.measured_quantities
    DD = setup_data.good_DD

    # Step 1: Get SI template equations (pre-substitution)
    ordered_model = if isa(model, OrderedODESystem)
        model
    else
        (_, _, model_states, model_ps) = unpack_ODE(model)
        OrderedODESystem(model, model_states, model_ps)
    end

    template_equations, derivative_dict, _, _, _, _ = get_si_equation_system(
        ordered_model, mq, pep.data_sample;
        DD = DD, infolevel = 0,
        compute_multiplicity = false,  # M metadata is discarded here — skip the Groebner step
    )
    template_DD = ensure_si_template_dd_support(ordered_model, mq, DD, derivative_dict)

    # Step 2: Collect all variables from template equations
    all_template_vars = OrderedCollections.OrderedSet{Any}()
    for eq in template_equations
        union!(all_template_vars, Symbolics.get_variables(eq))
    end

    # Step 3: Identify data variables from DD.obs_lhs
    data_var_set = Set{Any}()
    for (level_idx, level_vars) in enumerate(template_DD.obs_lhs)
        for v in level_vars
            if v in all_template_vars
                push!(data_var_set, v)
            end
        end
    end

    # Step 4: Substitute _trfn_ vars only (known functions of time, not data)
    t_vec = pep.data_sample["t"]
    time_idx = argmin(abs.(t_vec .- t_eval))
    t_point = t_vec[time_idx]

    trfn_subst = Dict{Any, Any}()
    trfn_substituted_vars = Set{Any}()
    for v in all_template_vars
        vname = string(v)
        trfn_val = evaluate_trfn_template_variable(vname, t_point)
        if isnothing(trfn_val)
            # Also try _obs_trfn_ pattern (observable wrappers for transcendental inputs)
            trfn_val = evaluate_obs_trfn_template_variable(vname, t_point)
        end
        if !isnothing(trfn_val)
            trfn_subst[v] = trfn_val
            push!(trfn_substituted_vars, v)
        end
    end

    working_equations = if !isempty(trfn_subst)
        Symbolics.substitute.(template_equations, Ref(trfn_subst))
    else
        template_equations
    end

    # Remove trivial equations (0 variables after _trfn_ substitution)
    kept_equations = eltype(working_equations)[]
    for eq in working_equations
        if !isempty(Symbolics.get_variables(eq))
            push!(kept_equations, eq)
        end
    end

    if isempty(kept_equations)
        return Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}()
    end

    # Re-collect variables after substitution
    remaining_vars = OrderedCollections.OrderedSet{Any}()
    for eq in kept_equations
        union!(remaining_vars, Symbolics.get_variables(eq))
    end

    # Step 5: Separate unknowns (solved-for) and data (interpolated) variables
    # Remove _trfn_/_obs_trfn_ vars from data set (they're known functions, not data)
    for v in trfn_substituted_vars
        delete!(data_var_set, v)
    end
    # Template vars and prod_vars may be different Symbolics objects with the same name,
    # so use isequal for matching (structural comparison, not reference equality).
    data_var_names = Set(string(v) for v in data_var_set)
    unknown_vars = [v for v in remaining_vars if !(string(v) in data_var_names)]
    data_vars = [v for v in remaining_vars if string(v) in data_var_names]

    n_x = length(unknown_vars)
    n_d = length(data_vars)

    if n_x == 0 || n_d == 0
        return Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}()
    end

    # Step 6: Build true values for all variables
    # Unknowns use _build_true_value_vector (SIAN naming).
    # Data vars use oracle Taylor coefficients directly via DD.obs_lhs mapping.
    unknown_true = _build_true_value_vector(pep, unknown_vars;
        state_taylor = state_taylor, obs_taylor = obs_taylor, t_eval = t_eval)

    # Build oracle values for data variables from obs_taylor
    data_true = Float64[]
    for v in data_vars
        val = NaN
        # Match data variable against DD.obs_lhs to find (obs_idx, deriv_level)
        for (level_idx, level_vars) in enumerate(template_DD.obs_lhs)
            deriv_level = level_idx - 1
            for (obs_idx, lhs_var) in enumerate(level_vars)
                if isequal(v, lhs_var)
                    # Get oracle value: obs_taylor gives Taylor coefficients
                    # Taylor coeff[k+1] * k! = f^(k)(t_eval)
                    if !isnothing(obs_taylor) && obs_idx <= length(mq)
                        obs_rhs_key = ModelingToolkit.diff2term(mq[obs_idx].rhs)
                        if haskey(obs_taylor, obs_rhs_key)
                            tc = obs_taylor[obs_rhs_key]
                            if deriv_level + 1 <= length(tc)
                                val = tc[deriv_level + 1] * factorial(deriv_level)
                            end
                        end
                    end
                    @goto found_data_val
                end
            end
        end
        @label found_data_val
        push!(data_true, val)
    end

    combined_vars = [unknown_vars..., data_vars...]
    combined_true = [unknown_true..., data_true...]

    if any(isnan, combined_true)
        @warn "[DIAG] NaN in combined true values for data sensitivity" nan_count = count(isnan, combined_true)
        return Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}()
    end

    # Step 7: Build combined function and compute full Jacobian
    combined_fn = _compile_system_function(kept_equations, combined_vars)
    J_full = ForwardDiff.jacobian(combined_fn, combined_true)

    # Partition: J_x = J_full[:, 1:n_x], J_d = J_full[:, n_x+1:end]
    J_x = J_full[:, 1:n_x]
    J_d = J_full[:, (n_x + 1):end]

    # Step 8: IFT: S = -(J_x \ J_d)  or pinv for ill-conditioned systems
    cond_Jx = try
        svs_x = svd(J_x).S
        length(svs_x) > 0 ? svs_x[1] / max(svs_x[end], 1e-300) : Inf
    catch
        Inf
    end

    S = if cond_Jx > 1e6
        -(pinv(J_x) * J_d)
    else
        -(J_x \ J_d)
    end

    # Build labels and roles
    d_labels = [string(v) for v in data_vars]
    d_roles = _classify_polynomial_variables(d_labels, pep)
    x_labels = [string(v) for v in unknown_vars]
    x_roles = _classify_polynomial_variables(x_labels, pep)

    return S, d_labels, d_roles, x_labels, x_roles
end

