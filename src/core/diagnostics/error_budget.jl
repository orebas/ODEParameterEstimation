# Split 2026-06-10 from the 5,443-line src/core/diagnostics.jl (Phase F2;
# pure content move, functions byte-identical). Part: single-point + multipoint error budgets.
# ─── Error Budget ─────────────────────────────────────────────────────

"""
    _build_signed_delta_d(sr, pf) → (delta_d, d_true_aligned, d_prod_aligned)

Build signed Δd = d_prod - d_true, aligned to the columns of sensitivity matrix S.
Matches S column labels to PolynomialFeasibilityReport's data_var_labels.
Returns zeros for unmatched or transcendental variables.
"""
function _build_signed_delta_d(sr::SensitivityReport, pf::PolynomialFeasibilityReport)
    n_data = length(sr.data_sensitivity_data_labels)
    delta_d = zeros(Float64, n_data)
    d_true_aligned = zeros(Float64, n_data)
    d_prod_aligned = zeros(Float64, n_data)

    has_dv = !isempty(pf.data_var_labels) && !isempty(pf.data_var_prod) && !isempty(pf.data_var_true)
    if !has_dv
        return delta_d, d_true_aligned, d_prod_aligned
    end

    # Build lookup from pf data var labels → index
    pf_dv_idx = Dict{String, Int}()
    for (i, lab) in enumerate(pf.data_var_labels)
        pf_dv_idx[lab] = i
    end

    for (j, dlabel) in enumerate(sr.data_sensitivity_data_labels)
        if contains(dlabel, "_trfn_") || contains(dlabel, "_obs_trfn_")
            continue  # transcendental — zero error
        end

        # Try exact match first
        if haskey(pf_dv_idx, dlabel)
            idx = pf_dv_idx[dlabel]
            d_true_aligned[j] = pf.data_var_true[idx]
            d_prod_aligned[j] = pf.data_var_prod[idx]
            delta_d[j] = d_prod_aligned[j] - d_true_aligned[j]
            continue
        end

        # Try matching by parsed (base, order) — S labels may use different notation
        base_s, order_s = _parse_data_label(dlabel)
        isempty(base_s) && continue

        for (i, pf_lab) in enumerate(pf.data_var_labels)
            base_p, order_p = _parse_data_label(pf_lab)
            if order_s == order_p && (base_s == base_p || startswith(base_s, base_p) || startswith(base_p, base_s))
                d_true_aligned[j] = pf.data_var_true[i]
                d_prod_aligned[j] = pf.data_var_prod[i]
                delta_d[j] = d_prod_aligned[j] - d_true_aligned[j]
                break
            end
        end
    end

    return delta_d, d_true_aligned, d_prod_aligned
end

"""
    compute_error_budget(sr, da, pf; max_blame=5) → Union{Nothing, ErrorBudgetReport}

Signed IFT validation: compare Δx_actual = x_HC - x_true against Δx_predicted = S·Δd
where Δd = d_prod - d_true (signed). The nonlinearity metric is the normalized
prediction mismatch ‖Δx_predicted - Δx_actual‖ / ‖Δx_actual‖.

Returns `nothing` if the sensitivity matrix is empty.
"""
function compute_error_budget(
    sr::SensitivityReport,
    da::DerivativeAccuracyReport,
    pf::PolynomialFeasibilityReport;
    max_blame::Int = 5,
)
    S_true = sr.data_sensitivity_matrix
    if isempty(S_true)
        return nothing
    end

    n_unknowns, n_data = size(S_true)
    delta_d, d_true_aligned, d_prod_aligned = _build_signed_delta_d(sr, pf)

    unknown_labels = sr.data_sensitivity_unknown_labels
    unknown_roles = sr.data_sensitivity_unknown_roles
    data_labels = sr.data_sensitivity_data_labels

    has_actual = !isempty(pf.closest_solution_production) && !isempty(pf.true_values)

    # Map S row labels to pf variable indices
    pf_var_idx = Dict{String, Int}()
    if has_actual
        for (i, vn) in enumerate(pf.variable_names)
            pf_var_idx[vn] = i
        end
    end

    entries = ErrorBudgetEntry[]

    for i in 1:n_unknowns
        ulabel = i <= length(unknown_labels) ? unknown_labels[i] : "x_$i"
        urole = get(unknown_roles, ulabel, :unknown)

        # Signed IFT prediction: Δx_predicted = Σⱼ S[i,j] · Δd[j]
        signed_contributions = [S_true[i, j] * delta_d[j] for j in 1:n_data]
        dx_predicted = sum(signed_contributions)

        # Actual displacement: Δx_actual = x_HC[i] - x_true[i]
        dx_actual = NaN
        if has_actual && haskey(pf_var_idx, ulabel)
            idx = pf_var_idx[ulabel]
            if idx <= length(pf.closest_solution_production) && idx <= length(pf.true_values)
                dx_actual = pf.closest_solution_production[idx] - pf.true_values[idx]
            end
        end

        # Prediction ratio: |predicted| / |actual|
        ratio = if isnan(dx_actual) || abs(dx_actual) < 1e-300
            NaN
        else
            abs(dx_predicted) / abs(dx_actual)
        end

        # Blame: signed S[i,j]·Δd[j], sorted by |contribution| descending
        contrib_pairs = [(j, signed_contributions[j]) for j in 1:n_data]
        sort!(contrib_pairs; by = c -> -abs(c[2]))
        blame = @NamedTuple{data_label::String, s_times_dd::Float64, pct_of_predicted::Float64}[]
        abs_predicted = abs(dx_predicted)
        for k in 1:min(max_blame, length(contrib_pairs))
            j, s_dd = contrib_pairs[k]
            abs(s_dd) < 1e-300 && break
            pct = abs_predicted > 0 ? s_dd / dx_predicted : 0.0  # signed fraction
            dlabel = j <= length(data_labels) ? data_labels[j] : "d_$j"
            push!(blame, (data_label = dlabel, s_times_dd = s_dd, pct_of_predicted = pct))
        end

        push!(entries, ErrorBudgetEntry(ulabel, urole, dx_actual, dx_predicted, ratio, blame))
    end

    # Sort by |Δx_predicted| descending (largest predicted displacement first)
    sort!(entries; by = e -> -abs(e.delta_x_predicted))

    # Max derivative order
    max_order = 0
    for dlabel in data_labels
        _, order = _parse_data_label(dlabel)
        max_order = max(max_order, order)
    end

    # Sensitivity concentration
    s_col_norms = [norm(S_true[:, j]) for j in 1:n_data]
    s_fro = norm(S_true)
    sens_conc = s_fro > 0 ? maximum(s_col_norms) / s_fro : 0.0
    is_path = sens_conc > 0.5

    # Nonlinearity check: normalized mismatch between first-order prediction
    # and the observed displacement at the closest production root.
    sens_nonlin = NaN
    if has_actual && any(!iszero, d_prod_aligned)
        try
            dx_actual_vec = Float64[]
            dx_predicted_vec = Float64[]
            for e in entries
                if !isnan(e.delta_x_actual)
                    push!(dx_actual_vec, e.delta_x_actual)
                    push!(dx_predicted_vec, e.delta_x_predicted)
                end
            end
            if !isempty(dx_actual_vec)
                residual = dx_predicted_vec .- dx_actual_vec
                sens_nonlin = norm(residual) / max(norm(dx_actual_vec), 1e-300)
            end
        catch e
            _rethrow_if_interrupt(e)
            @warn "[ERROR_BUDGET] Nonlinearity check failed: $e"
        end
    end

    return ErrorBudgetReport(
        pf.model_name,
        :single_point,
        da.t_eval,
        da.interpolator_name,
        entries,
        data_labels,
        d_true_aligned,
        d_prod_aligned,
        delta_d,
        max_order,
        isnan(sens_nonlin) ? NaN : sens_nonlin,
        sens_conc,
        is_path,
    )
end

# ─── Multipoint Error Budget ─────────────────────────────────────────

"""
    _parse_multipoint_var_name(name) → (clean_name, point_index)

Strip `_ptK` suffix from a multipoint variable name. Returns the clean name
and the point index (1 if no suffix).
"""
function _parse_multipoint_var_name(name::AbstractString)
    m = match(r"^(.+)_pt(\d+)$", name)
    if !isnothing(m)
        return (String(m.captures[1]), parse(Int, m.captures[2]))
    end
    return (String(name), 1)
end

function _multipoint_var_order(name::AbstractString)
    clean_name, _ = _parse_multipoint_var_name(name)
    parsed = parse_derivative_variable_name(clean_name)
    return isnothing(parsed) ? 0 : parsed[2]
end

function _multipoint_template_max_order(mpt::MultiPointTemplate)
    max_order = 0
    for v in mpt.solve_vars
        max_order = max(max_order, _multipoint_var_order(string(v)))
    end
    for v in mpt.data_vars
        max_order = max(max_order, _multipoint_var_order(string(v)))
    end
    return max_order
end

function _multipoint_point_data_labels(mpt::MultiPointTemplate)
    groups = [String[] for _ in 1:mpt.n_points]
    for pt in 1:min(mpt.n_points, length(mpt.per_point_data_var_indices))
        for idx in mpt.per_point_data_var_indices[pt]
            idx > length(mpt.data_vars) && continue
            push!(groups[pt], string(mpt.data_vars[idx]))
        end
    end
    return groups
end

function _lookup_production_data_value(
    label::AbstractString,
    pep::ParameterEstimationProblem,
    setup_data,
    t_eval::Float64,
)
    clean_name, _ = _parse_multipoint_var_name(label)

    trfn_val = evaluate_trfn_template_variable(clean_name, t_eval)
    if isnothing(trfn_val)
        trfn_val = evaluate_obs_trfn_template_variable(clean_name, t_eval)
    end
    if !isnothing(trfn_val)
        return Float64(trfn_val)
    end

    parsed = parse_derivative_variable_name(clean_name)
    isnothing(parsed) && return NaN
    base_name, deriv_order = parsed

    for mq in pep.measured_quantities
        obs_name = replace(string(mq.lhs), r"\(.*\)$" => "")
        obs_name == string(base_name) || continue
        obs_rhs = ModelingToolkit.diff2term(mq.rhs)
        if haskey(setup_data.interpolants, obs_rhs)
            interp = setup_data.interpolants[obs_rhs]
            return try
                Float64(nth_deriv(x -> interp(x), deriv_order, t_eval))
            catch err
                _rethrow_if_interrupt(err)
                NaN
            end
        end
    end

    return NaN
end

function _diagnose_derivative_accuracy_for_labels(
    pep::ParameterEstimationProblem;
    setup_data,
    t_eval::Float64,
    labels::Vector{String},
    interpolator_name::String,
)
    entry_type = @NamedTuple{obs::String, order::Int, true_val::Float64, interp_val::Float64, rel_error::Float64}
    entries = entry_type[]
    isempty(labels) && return DerivativeAccuracyReport(pep.name, t_eval, 0, entries, "", 0, 0.0, interpolator_name)

    max_order = maximum(_multipoint_var_order(label) for label in labels)
    state_taylor = compute_oracle_taylor_coefficients(pep, t_eval, max_order + 2)
    obs_taylor = compute_observable_taylor_coefficients(pep, state_taylor, t_eval, max_order + 2)

    worst_obs = ""
    worst_order = 0
    worst_rel_error = -Inf

    for label in labels
        clean_name, _ = _parse_multipoint_var_name(label)
        order = _multipoint_var_order(label)
        true_val = Float64(_lookup_true_value(pep, clean_name;
            state_taylor = state_taylor, obs_taylor = obs_taylor, t_eval = t_eval))
        interp_val = _lookup_production_data_value(clean_name, pep, setup_data, t_eval)
        rel_err = if isfinite(true_val) && isfinite(interp_val)
            # See _diagnose_derivative_accuracy_for_labels' sibling computation:
            # avoid inflating numerical noise into bogus relative error when the
            # true value is effectively zero (e.g. conserved-quantity derivatives).
            abs_err = abs(true_val - interp_val)
            abs(true_val) < 1e-10 ? abs_err : abs_err / abs(true_val)
        else
            Inf
        end

        push!(entries, (obs = label, order = order, true_val = true_val, interp_val = interp_val, rel_error = rel_err))
        if rel_err > worst_rel_error
            worst_rel_error = rel_err
            worst_obs = label
            worst_order = order
        end
    end

    if !isfinite(worst_rel_error)
        worst_rel_error = Inf
    end

    return DerivativeAccuracyReport(
        pep.name,
        t_eval,
        max_order,
        entries,
        worst_obs,
        worst_order,
        worst_rel_error,
        interpolator_name,
    )
end

function _index_combinations(indices::Vector{Int}, k::Int)
    results = Vector{Vector{Int}}()
    if k <= 0
        push!(results, Int[])
        return results
    end
    if length(indices) < k
        return results
    end

    function _rec(start_idx::Int, acc::Vector{Int})
        if length(acc) == k
            push!(results, copy(acc))
            return
        end
        remaining = k - length(acc)
        last_start = length(indices) - remaining + 1
        for i in start_idx:last_start
            push!(acc, indices[i])
            _rec(i + 1, acc)
            pop!(acc)
        end
    end

    _rec(1, Int[])
    return results
end

function _build_multipoint_combo_metrics(
    pep::ParameterEstimationProblem,
    mpt::MultiPointTemplate,
    setup_data,
    time_indices::Vector{Int},
    interp_name::String,
    point_data_labels::Vector{Vector{String}},
    oracle_order::Int,
)
    t_vec = pep.data_sample["t"]
    t_values = Float64[t_vec[idx] for idx in time_indices]

    da_per_point = DerivativeAccuracyReport[]
    for pt in 1:mpt.n_points
        labels = pt <= length(point_data_labels) ? point_data_labels[pt] : String[]
        push!(da_per_point, _diagnose_derivative_accuracy_for_labels(
            pep;
            setup_data = setup_data,
            t_eval = t_values[pt],
            labels = labels,
            interpolator_name = interp_name,
        ))
    end
    worst_err = isempty(da_per_point) ? Inf : maximum(dr.worst_rel_error for dr in da_per_point)

    state_taylors = Vector{Dict{Num, Vector{Float64}}}()
    obs_taylors = Vector{Dict{Num, Vector{Float64}}}()
    for te in t_values
        st = compute_oracle_taylor_coefficients(pep, te, oracle_order + 2)
        ot = compute_observable_taylor_coefficients(pep, st, te, oracle_order + 2)
        push!(state_taylors, st)
        push!(obs_taylors, ot)
    end

    eval_result = evaluate_multipoint_template(mpt, time_indices, setup_data.interpolants, pep.data_sample)
    data_subst = Dict{Any, Float64}()
    for (j, dv) in enumerate(mpt.data_vars)
        j <= length(eval_result.data_values) || continue
        data_subst[dv] = eval_result.data_values[j]
    end
    inst_eqs = [Symbolics.substitute(eq, data_subst) for eq in mpt.stripped_equations]

    x_true = Float64[]
    for v in mpt.solve_vars
        push!(x_true, _lookup_multipoint_true_value(string(v), pep, t_values, state_taylors, obs_taylors))
    end

    true_residual = _compute_residual(inst_eqs, mpt.solve_vars, x_true)

    hc_solutions = try
        solve_multipoint_direct(eval_result)
    catch e
        _rethrow_if_interrupt(e)
        @warn "[MP_BUDGET] HC solve failed for combo $(time_indices): $e"
        Vector{Float64}[]
    end
    closest_distance, _ = _closest_solution_with_values(hc_solutions, x_true)

    return (
        time_indices = Int[time_indices...],
        t_values = Float64[t_values...],
        derivative_reports = da_per_point,
        worst_derivative_error = worst_err,
        true_residual = true_residual,
        closest_distance = closest_distance,
        solution_count = length(hc_solutions),
        solved = !isempty(hc_solutions),
    )
end

function _candidate_sort_tuple(candidate)
    return (
        isfinite(candidate.worst_derivative_error) ? candidate.worst_derivative_error : Inf,
        isfinite(candidate.true_residual) ? candidate.true_residual : Inf,
        isfinite(candidate.closest_distance) ? candidate.closest_distance : Inf,
    )
end

function _select_multipoint_candidate(candidates, selection_policy::Symbol)
    isempty(candidates) && return nothing, "no candidate multipoint combinations were available"

    if selection_policy == :fixed_quartiles
        return candidates[1], "selected the legacy fixed-quartiles multipoint combination"
    end

    if selection_policy == :best_derivative_combo
        idx = argmin([_candidate_sort_tuple(c) for c in candidates])
        return candidates[idx], "selected the lowest derivative-error multipoint combination"
    end

    solved = [c for c in candidates if c.solved]
    if !isempty(solved)
        idx = argmin([_candidate_sort_tuple(c) for c in solved])
        return solved[idx], "selected the best solved multipoint combination by derivative error, residual, and distance to truth"
    end

    idx = argmin([_candidate_sort_tuple(c) for c in candidates])
    return candidates[idx], "no solved multipoint combination was found, so the lowest derivative-error combination was selected as a fallback"
end

function _default_multipoint_time_indices(t_vec::Vector{Float64}, n_points::Int)
    n_t = length(t_vec)
    if n_points == 2
        t1_idx = max(2, round(Int, n_t * 0.25))
        t2_idx = min(n_t - 1, round(Int, n_t * 0.75))
        if t1_idx == t2_idx
            t2_idx = min(n_t, t1_idx + 1)
        end
        return unique(Int[t1_idx, t2_idx])
    end

    fracs = collect(range(0.15, 0.85; length = n_points))
    return unique(Int[max(2, min(n_t - 1, round(Int, n_t * frac))) for frac in fracs])
end

function _build_multipoint_analysis(
    mpt::MultiPointTemplate,
    selected_candidate,
    candidate_combo_count::Int,
    solved_combo_count::Int,
    selection_policy::Symbol,
    compare_policy::Symbol,
    selection_reason::String,
    compare_is_valid::Bool,
    compare_invalid_reason::String,
    comparable_unknown_labels::Vector{String},
)
    actual_labels = string.(mpt.data_vars)
    actual_max_order = isempty(actual_labels) ? 0 : maximum(_multipoint_var_order(label) for label in actual_labels)

    return MultipointDiagnosticAnalysis(
        selection_policy,
        compare_policy,
        selection_reason,
        isnothing(selected_candidate) ? Int[] : selected_candidate.time_indices,
        isnothing(selected_candidate) ? Float64[] : selected_candidate.t_values,
        candidate_combo_count,
        solved_combo_count,
        !isnothing(selected_candidate) && selected_candidate.solved,
        isnothing(selected_candidate) ? 0 : selected_candidate.solution_count,
        isnothing(selected_candidate) ? Inf : selected_candidate.worst_derivative_error,
        isnothing(selected_candidate) ? Inf : selected_candidate.true_residual,
        isnothing(selected_candidate) ? Inf : selected_candidate.closest_distance,
        compare_is_valid,
        compare_invalid_reason,
        comparable_unknown_labels,
        actual_labels,
        actual_max_order,
        mpt.total_equation_count,
        length(mpt.stripped_equations),
        length(mpt.solve_vars),
        length(mpt.data_vars),
        copy(mpt.kept_equation_indices),
        copy(mpt.dropped_equation_indices),
        copy(mpt.eq_metadata),
    )
end

"""
    _lookup_multipoint_true_value(var_name, pep, t_values, state_taylors, obs_taylors)

Look up the oracle true value of a multipoint variable. Handles `_ptK` suffixes
by using the appropriate point's Taylor coefficients.
"""
function _lookup_multipoint_true_value(
    var_name::String,
    pep::ParameterEstimationProblem,
    t_values::Vector{Float64},
    state_taylors::Vector,
    obs_taylors::Vector,
)
    clean_name, pt_idx = _parse_multipoint_var_name(var_name)

    # Try parameter match first (shared across points)
    for (p, v) in pep.p_true
        pname = replace(string(p), "(t)" => "")
        if pname == clean_name || pname * "_0" == clean_name
            return Float64(v)
        end
    end

    # Parse derivative info from clean name
    parsed = parse_derivative_variable_name(clean_name)
    if isnothing(parsed)
        # Try as bare state IC (e.g., "x1" → "x1_0" with order 0)
        for (s, v) in pep.ic
            sname = replace(string(s), "(t)" => "")
            if sname == clean_name
                return Float64(v)
            end
        end
        @warn "[MP_BUDGET] Cannot parse variable name: $var_name (clean: $clean_name)"
        return NaN
    end

    base_name, deriv_order = parsed

    # Check bounds on point index
    if pt_idx < 1 || pt_idx > length(state_taylors)
        @warn "[MP_BUDGET] Point index $pt_idx out of range for variable $var_name"
        return NaN
    end

    st = state_taylors[pt_idx]
    ot = obs_taylors[pt_idx]
    t_eval = t_values[pt_idx]

    # Try state match
    for (s, _) in pep.ic
        sname = replace(string(s), "(t)" => "")
        if sname == base_name
            obs_rhs_key = s  # the state Symbolics variable
            if haskey(st, obs_rhs_key) || haskey(st, ModelingToolkit.diff2term(s))
                key = haskey(st, obs_rhs_key) ? obs_rhs_key : ModelingToolkit.diff2term(s)
                tc = st[key]
                if deriv_order + 1 <= length(tc)
                    return tc[deriv_order + 1] * factorial(deriv_order)
                end
            end
        end
    end

    # Try observable match
    for (obs_idx, mq) in enumerate(pep.measured_quantities)
        obs_name = replace(string(mq.lhs), r"\(.*\)" => "")
        if obs_name == base_name
            obs_rhs_key = ModelingToolkit.diff2term(mq.rhs)
            if haskey(ot, obs_rhs_key)
                tc = ot[obs_rhs_key]
                if deriv_order + 1 <= length(tc)
                    return tc[deriv_order + 1] * factorial(deriv_order)
                end
            end
        end
    end

    @warn "[MP_BUDGET] No true value match for $var_name (base=$base_name, order=$deriv_order, pt=$pt_idx)"
    return NaN
end

"""
    _compute_multipoint_sensitivity(pep, mpt, t_values; state_taylors, obs_taylors)

Compute the IFT sensitivity matrix for a multipoint polynomial system.
Returns `(S, data_labels, data_roles, unknown_labels, unknown_roles)`.
"""
function _compute_multipoint_sensitivity(
    pep::ParameterEstimationProblem,
    mpt::MultiPointTemplate,
    t_values::Vector{Float64};
    state_taylors::Vector,
    obs_taylors::Vector,
)
    solve_vars = mpt.solve_vars
    data_vars = mpt.data_vars
    equations = mpt.stripped_equations
    n_x = length(solve_vars)
    n_d = length(data_vars)

    if n_x == 0 || n_d == 0 || isempty(equations)
        return Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}()
    end

    # Build true values for solve_vars and data_vars
    x_true = Float64[]
    for v in solve_vars
        val = _lookup_multipoint_true_value(string(v), pep, t_values, state_taylors, obs_taylors)
        push!(x_true, val)
    end

    d_true = Float64[]
    for v in data_vars
        val = _lookup_multipoint_true_value(string(v), pep, t_values, state_taylors, obs_taylors)
        push!(d_true, val)
    end

    combined_vars = [solve_vars..., data_vars...]
    combined_true = [x_true..., d_true...]

    if any(isnan, combined_true)
        nan_vars = [string(combined_vars[i]) for i in eachindex(combined_true) if isnan(combined_true[i])]
        @warn "[MP_BUDGET] NaN in true values" nan_count = length(nan_vars) vars = nan_vars[1:min(5, length(nan_vars))]
        return Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}()
    end

    # Compile and compute Jacobian
    combined_fn = _compile_system_function(equations, combined_vars)
    J_full = ForwardDiff.jacobian(combined_fn, combined_true)

    J_x = J_full[:, 1:n_x]
    J_d = J_full[:, (n_x + 1):end]

    # IFT: S = -(J_x \ J_d) or pinv for ill-conditioned
    cond_Jx = try
        svs_x = svd(J_x).S
        length(svs_x) > 0 ? svs_x[1] / max(svs_x[end], 1e-300) : Inf
    catch err
        _rethrow_if_interrupt(err)
        Inf
    end

    S = if cond_Jx > 1e6
        -(pinv(J_x) * J_d)
    else
        -(J_x \ J_d)
    end

    # Labels and roles
    d_labels = [string(v) for v in data_vars]
    d_roles = Dict{String, Symbol}()
    for dl in d_labels
        if contains(dl, "_trfn_")
            d_roles[dl] = :transcendental
        else
            d_roles[dl] = :data_derivative
        end
    end

    x_labels = [string(v) for v in solve_vars]
    x_roles = _classify_polynomial_variables(x_labels, pep)

    return S, d_labels, d_roles, x_labels, x_roles
end

"""
    compute_multipoint_error_budget(pep, mpt, t_values, setup_data, da_per_point; max_blame=5)

Signed IFT validation for multipoint: solves the system with HC.jl, computes
Δx_actual = x_HC - x_true and Δx_predicted = S·Δd, and checks nonlinearity.
"""
function compute_multipoint_error_budget(
    pep::ParameterEstimationProblem,
    mpt::MultiPointTemplate,
    t_values::Vector{Float64},
    setup_data,
    da_per_point::Vector{DerivativeAccuracyReport};
    max_blame::Int = 5,
)
    n_points = length(t_values)
    max_order = _multipoint_template_max_order(mpt)

    # Oracle Taylor at each point
    state_taylors = Vector{Dict{Num, Vector{Float64}}}()
    obs_taylors = Vector{Dict{Num, Vector{Float64}}}()
    for te in t_values
        st = compute_oracle_taylor_coefficients(pep, te, max_order + 2)
        ot = compute_observable_taylor_coefficients(pep, st, te, max_order + 2)
        push!(state_taylors, st)
        push!(obs_taylors, ot)
    end

    # Sensitivity matrix S at oracle point
    S, d_labels, d_roles, x_labels, x_roles = _compute_multipoint_sensitivity(
        pep, mpt, t_values;
        state_taylors = state_taylors, obs_taylors = obs_taylors)

    if isempty(S)
        @warn "[MP_BUDGET] Failed to compute multipoint sensitivity matrix"
        return nothing
    end

    n_unknowns, n_data = size(S)

    # Build d_true: oracle values for each data variable
    d_true = Float64[]
    for v in mpt.data_vars
        val = _lookup_multipoint_true_value(string(v), pep, t_values, state_taylors, obs_taylors)
        push!(d_true, val)
    end

    # Evaluate multipoint template at the specified time points to get d_prod
    t_vec = pep.data_sample["t"]
    time_indices = [argmin(abs.(t_vec .- te)) for te in t_values]
    eval_result = evaluate_multipoint_template(mpt, time_indices, setup_data.interpolants, pep.data_sample)
    d_prod = Float64.(eval_result.data_values)

    # Signed Δd = d_prod - d_true
    delta_d = d_prod .- d_true

    # Solve the multipoint system with HC.jl to get x_HC
    x_true = Float64[]
    for v in mpt.solve_vars
        val = _lookup_multipoint_true_value(string(v), pep, t_values, state_taylors, obs_taylors)
        push!(x_true, val)
    end

    hc_solutions = try
        solve_multipoint_direct(eval_result)
    catch e
        _rethrow_if_interrupt(e)
        @warn "[MP_BUDGET] HC solve failed: $e"
        Vector{Float64}[]
    end

    # Find closest solution to truth
    x_hc = Float64[]
    if !isempty(hc_solutions) && !any(isnan, x_true)
        best_dist = Inf
        for sol in hc_solutions
            d = norm(sol .- x_true)
            if d < best_dist
                best_dist = d
                x_hc = Float64.(sol)
            end
        end
    end

    has_actual = !isempty(x_hc) && length(x_hc) == length(x_true)

    # Build entries with signed IFT prediction
    entries = ErrorBudgetEntry[]
    for i in 1:n_unknowns
        ulabel = i <= length(x_labels) ? x_labels[i] : "x_$i"
        urole = get(x_roles, ulabel, :unknown)

        # Signed prediction: Σⱼ S[i,j]·Δd[j]
        signed_contributions = [S[i, j] * delta_d[j] for j in 1:n_data]
        dx_predicted = sum(signed_contributions)

        # Actual displacement
        dx_actual = has_actual ? x_hc[i] - x_true[i] : NaN

        ratio = if isnan(dx_actual) || abs(dx_actual) < 1e-300
            NaN
        else
            abs(dx_predicted) / abs(dx_actual)
        end

        # Blame: signed contributions sorted by |contribution|
        contrib_pairs = [(j, signed_contributions[j]) for j in 1:n_data]
        sort!(contrib_pairs; by = c -> -abs(c[2]))
        blame = @NamedTuple{data_label::String, s_times_dd::Float64, pct_of_predicted::Float64}[]
        abs_predicted = abs(dx_predicted)
        for k in 1:min(max_blame, length(contrib_pairs))
            j, s_dd = contrib_pairs[k]
            abs(s_dd) < 1e-300 && break
            pct = abs_predicted > 0 ? s_dd / dx_predicted : 0.0
            dl = j <= length(d_labels) ? d_labels[j] : "d_$j"
            push!(blame, (data_label = dl, s_times_dd = s_dd, pct_of_predicted = pct))
        end

        push!(entries, ErrorBudgetEntry(ulabel, urole, dx_actual, dx_predicted, ratio, blame))
    end

    sort!(entries; by = e -> -abs(e.delta_x_predicted))

    # Max derivative order
    max_order_used = 0
    for dlabel in d_labels
        clean, _ = _parse_multipoint_var_name(dlabel)
        _, order = _parse_data_label(clean)
        max_order_used = max(max_order_used, order)
    end

    interp_name = !isempty(da_per_point) ? da_per_point[1].interpolator_name : "unknown"

    # Sensitivity concentration
    s_col_norms = [norm(S[:, j]) for j in 1:n_data]
    s_fro = norm(S)
    sens_conc = s_fro > 0 ? maximum(s_col_norms) / s_fro : 0.0
    is_path = sens_conc > 0.5

    # Nonlinearity: ‖S·Δd - Δx_actual‖ / ‖Δx_actual‖
    sens_nonlin = NaN
    if has_actual
        dx_actual_vec = [x_hc[i] - x_true[i] for i in 1:n_unknowns]
        dx_predicted_vec = [sum(S[i, j] * delta_d[j] for j in 1:n_data) for i in 1:n_unknowns]
        residual = dx_predicted_vec .- dx_actual_vec
        norm_actual = norm(dx_actual_vec)
        sens_nonlin = norm_actual > 1e-300 ? norm(residual) / norm_actual : NaN
    end

    return ErrorBudgetReport(
        pep.name,
        :multipoint,
        t_values,
        interp_name,
        entries,
        d_labels,
        d_true,
        d_prod,
        delta_d,
        max_order_used,
        isnan(sens_nonlin) ? NaN : sens_nonlin,
        sens_conc,
        is_path,
    )
end

"""
    _try_multipoint_error_budget(pep, setup_data, interp_func, interp_name; kwargs...)

Build the multipoint diagnostic payload: choose a multipoint combination,
compute per-point derivative accuracy for the actual template inputs, compute
the selected error budget, and return structured selection metadata.
"""
function _try_multipoint_error_budget(
    pep::ParameterEstimationProblem,
    setup_data,
    interp_func,
    interp_name::String;
    t_eval_points::Vector{Float64} = Float64[],
    sp_error_budget::Union{Nothing, ErrorBudgetReport} = nothing,
    selection_policy::Symbol = :best_solved_combo,
    compare_policy::Symbol = :gate_invalid,
    kwargs...,
)
    try
        model = pep.model.system
        mq = pep.measured_quantities
        t_vec = pep.data_sample["t"]

        # Build SI template (needed by build_multipoint_template)
        ordered_model = isa(model, OrderedODESystem) ? model : begin
            (_, _, s, p) = unpack_ODE(model)
            OrderedODESystem(model, s, p)
        end

        si_template, _ = prepare_si_template_with_structural_fix(
            ordered_model, mq, pep.data_sample,
            setup_data.good_DD, false;
            states = setup_data.states,
            params = setup_data.params,
        )

        # Build setup tuple for multipoint
        mpt_setup = (
            good_deriv_level = setup_data.good_deriv_level,
            good_udict = setup_data.good_udict,
            good_varlist = setup_data.good_varlist,
            good_DD = setup_data.good_DD,
            interpolants = setup_data.interpolants,
        )

        mpt = build_multipoint_template(pep, mpt_setup, si_template; n_points = 2, diagnostics = false)

        if length(mpt.stripped_equations) != length(mpt.solve_vars)
            @warn "[MP_BUDGET] Multipoint template is not square — skipping"
            return nothing
        end

        point_data_labels = _multipoint_point_data_labels(mpt)
        oracle_order = _multipoint_template_max_order(mpt)

        candidates = NamedTuple[]
        if selection_policy == :fixed_quartiles
            time_indices = _default_multipoint_time_indices(t_vec, mpt.n_points)
            if length(time_indices) == mpt.n_points
                push!(candidates, _build_multipoint_combo_metrics(
                    pep, mpt, setup_data, time_indices, interp_name, point_data_labels, oracle_order))
            end
        else
            candidate_times = isempty(t_eval_points) ? collect(t_vec) : t_eval_points
            resolved_indices = unique(sort(Int[argmin(abs.(t_vec .- te)) for te in candidate_times]))
            for combo in _index_combinations(resolved_indices, mpt.n_points)
                push!(candidates, _build_multipoint_combo_metrics(
                    pep, mpt, setup_data, combo, interp_name, point_data_labels, oracle_order))
            end
        end

        selected_candidate, selection_reason = _select_multipoint_candidate(candidates, selection_policy)

        mp_eb = nothing
        da_per_point = DerivativeAccuracyReport[]
        if !isnothing(selected_candidate)
            da_per_point = selected_candidate.derivative_reports
            mp_eb = compute_multipoint_error_budget(
                pep, mpt, selected_candidate.t_values, setup_data, da_per_point)
        end

        comparable_unknowns = String[]
        compare_is_valid = true
        compare_invalid_reason = ""
        if isnothing(mp_eb)
            compare_is_valid = false
            compare_invalid_reason = "multipoint error budget could not be computed for the selected combination"
        elseif isnothing(sp_error_budget)
            compare_is_valid = false
            compare_invalid_reason = "single-point error budget is unavailable, so no direct comparison can be made"
        else
            mp_clean = Set(String[])
            for entry in mp_eb.entries
                clean, _ = _parse_multipoint_var_name(entry.unknown_label)
                push!(mp_clean, clean)
            end
            comparable_unknowns = [entry.unknown_label for entry in sp_error_budget.entries if entry.unknown_label in mp_clean]

            if isnothing(selected_candidate) || !selected_candidate.solved
                compare_is_valid = false
                compare_invalid_reason = "the selected multipoint combination has no HC solution, so the comparison is not apples-to-apples"
            elseif isempty(comparable_unknowns)
                compare_is_valid = false
                compare_invalid_reason = "no overlapping unknowns exist between the single-point and multipoint error budgets"
            elseif !isfinite(mp_eb.sensitivity_nonlinearity)
                compare_is_valid = false
                compare_invalid_reason = "the multipoint nonlinearity metric is unavailable"
            elseif mp_eb.sensitivity_nonlinearity > 1.0
                compare_is_valid = false
                compare_invalid_reason = "the multipoint system is too nonlinear at the selected combination for a trustworthy first-order comparison"
            end
        end

        analysis = _build_multipoint_analysis(
            mpt,
            selected_candidate,
            length(candidates),
            count(c -> c.solved, candidates),
            selection_policy,
            compare_policy,
            selection_reason,
            compare_is_valid,
            compare_invalid_reason,
            comparable_unknowns,
        )

        return (error_budget = mp_eb, derivative_reports = da_per_point, analysis = analysis)
    catch e
        _rethrow_if_interrupt(e)
        @warn "[MP_BUDGET] Multipoint error budget failed" exception = (e, catch_backtrace())
        return nothing
    end
end

