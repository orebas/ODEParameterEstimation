# Multipoint UQ v1 step 3 (2026-08-14): estimate-conditioned IFT sensitivity
# over a MultiPointTemplate. The single-point sensitivity re-derives the
# system from the SI template; here the template already carries the
# solve/data partition, so this is a direct evaluation:
#
#   F = template.stripped_equations,  x = solve_vars,  d = data_vars
#   S = -(∂F/∂x)⁻¹ (∂F/∂d)   at   (x̂, d̂)
#
# where d̂ is exactly the data vector the solver consumes for this combo
# (evaluate_multipoint_template) and x̂ is the estimate conditioned per point:
# shared parameters θ̂, per-point state jets propagated from the estimate at
# each combo time (phase-1 machinery). Gates per the design consult: a
# root-residual check (‖F(x̂,d̂)‖ absolute + relative — IFT is only valid near
# an actual root) and the loud-degradation conditioning check in _ift_solve.

"""
    _multipoint_solve_var_point(name) → (point::Int, clean_name::String)

Point index and `_ptK`-stripped name for one multipoint solve/data variable
(point 1 = unsuffixed).
"""
function _multipoint_solve_var_point(name::AbstractString)
    m = match(r"_pt(\d+)$", name)
    isnothing(m) && return 1, String(name)
    return parse(Int, m.captures[1]), replace(String(name), r"_pt\d+$" => "")
end

"""
    _compute_multipoint_data_sensitivity(mpt, combo_time_indices, estimate, pep, setup_data;
                                         root_residual_rtol = 1e-3)
      → (S, data_labels, data_roles, unknown_labels, unknown_roles, info)

Estimate-conditioned parameter–data sensitivity for a multipoint template at
one time-point combo. The first five returns match the single-point sibling
`_compute_data_sensitivity` so Σ_d assembly can consume either. `info` is a
NamedTuple: `(reason, root_residual_abs, root_residual_rel, jx_cond,
ift_degraded, residual_degraded, degraded, x_hat, d_hat)` — `degraded = true`
means downstream UQ must be reported as unreliable, never silently trusted;
`x_hat`/`d_hat` record the linearization point.

On unusable inputs (non-finite data or estimate values) returns an empty S
with `info.reason` set.
"""
function _compute_multipoint_data_sensitivity(
    mpt::MultiPointTemplate,
    combo_time_indices::Vector{Int},
    estimate::ParameterEstimationResult,
    pep::ParameterEstimationProblem,
    setup_data;
    root_residual_rtol::Float64 = 1e-3,
)
    _empty(reason) = (
        Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(),
        String[], Dict{String, Symbol}(),
        (; reason, root_residual_abs = NaN, root_residual_rel = NaN,
            jx_cond = NaN, ift_degraded = true, residual_degraded = true,
            degraded = true, x_hat = Float64[], d_hat = Float64[]),
    )

    length(combo_time_indices) == mpt.n_points ||
        throw(ArgumentError("combo has $(length(combo_time_indices)) indices for an n_points=$(mpt.n_points) template"))
    t_vec = pep.data_sample["t"]
    t_values = Float64[t_vec[i] for i in combo_time_indices]

    # d̂ — exactly the data vector the solver consumes for this combo
    ev = evaluate_multipoint_template(mpt, combo_time_indices, setup_data.interpolants, pep.data_sample)
    d_hat = ev.data_values
    if !all(isfinite, d_hat)
        @warn "[MP-UQ] Non-finite multipoint data values — skipping sensitivity" combo = combo_time_indices
        return _empty(:nonfinite_data)
    end

    # Per-point estimate conditioning: Taylor jets of the estimate at each combo time
    max_solve_order = 0
    for v in mpt.solve_vars
        _, clean = _multipoint_solve_var_point(string(v))
        parsed = parse_derivative_variable_name(clean)
        isnothing(parsed) || (max_solve_order = max(max_solve_order, parsed[2]))
    end

    point_ctx = Vector{Tuple{Dict{Num, Vector{Float64}}, ParameterEstimationProblem}}(undef, mpt.n_points)
    for pt in 1:mpt.n_points
        st = try
            compute_estimate_taylor_coefficients(pep, estimate, t_values[pt], max_solve_order + 2)
        catch err
            _rethrow_if_interrupt(err)
            # An unusable estimate (missing/non-finite values, failed forward
            # solve) must degrade the UQ report, not throw at the caller.
            @warn "[MP-UQ] Estimate jet propagation failed at t = $(t_values[pt]) — skipping sensitivity" exception = err
            return _empty(:estimate_taylor_failed)
        end
        point_ctx[pt] = (st, _pep_with_estimate_values(pep, estimate, st))
    end

    x_hat = Float64[]
    for v in mpt.solve_vars
        pt, clean = _multipoint_solve_var_point(string(v))
        # Suffixed vars need a clean-named symbolic handle for the shared
        # name-parsing lookup ("w_2_pt2" would parse wrong); unsuffixed pass through.
        handle = pt == 1 ? v : Symbolics.variable(Symbol(clean))
        st, value_pep = point_ctx[pt]
        push!(x_hat, _lookup_true_value(value_pep, handle;
            state_taylor = st, obs_taylor = nothing, t_eval = t_values[pt]))
    end
    if !all(isfinite, x_hat)
        bad = [string(v) for (v, x) in zip(mpt.solve_vars, x_hat) if !isfinite(x)]
        @warn "[MP-UQ] Could not resolve estimate values for solve variables — skipping sensitivity" bad
        return _empty(:nonfinite_solve_values)
    end

    combined_vars = vcat(mpt.solve_vars, mpt.data_vars)
    combined_vals = vcat(x_hat, d_hat)
    fn = _compile_system_function(mpt.stripped_equations, combined_vars)

    # Root-residual gate: IFT linearizes a root branch — far from a root the
    # derivative is meaningless. The reported estimate is polished against the
    # whole trajectory, so it sits near-but-not-on this algebraic root; degrade
    # loudly when the gap is material rather than reporting a covariance for a
    # branch the estimate isn't on.
    # NB the compiled template function returns BigFloat: multipoint template
    # equations carry BigFloat coefficients from the SIAN/rational pipeline, so
    # AD here runs in extended precision. Results are narrowed to Float64 at
    # this boundary (SensitivityReport stores Matrix{Float64}) — narrowing the
    # AD input instead would strip the Dual partials.
    r_vec = Float64.(fn(combined_vals))
    r_abs = norm(r_vec, Inf)
    J_full = Float64.(ForwardDiff.jacobian(fn, combined_vals))
    # Per-equation first-order term magnitude Σ_j |J_ij · v_j| — an
    # order-of-magnitude proxy for the size of the terms each equation cancels
    # (a degree factor loose on high-degree monomials, fine for a gate).
    term_scale = maximum(abs.(J_full) * abs.(combined_vals); init = 0.0)
    r_rel = r_abs / max(term_scale, 1e-300)
    residual_degraded = !(r_rel <= root_residual_rtol)
    if residual_degraded
        @warn "[MP-UQ] Estimate point is far from a template root (rel residual $(r_rel) > $(root_residual_rtol)) — sensitivity S is unreliable" r_abs
    end

    n_x = length(mpt.solve_vars)
    J_x = J_full[:, 1:n_x]
    J_d = J_full[:, (n_x + 1):end]
    S, cond_Jx, ift_degraded = _ift_solve(J_x, J_d)

    d_labels = String[string(v) for v in mpt.data_vars]
    x_labels = String[string(v) for v in mpt.solve_vars]
    d_clean = [last(_multipoint_solve_var_point(l)) for l in d_labels]
    x_clean = [last(_multipoint_solve_var_point(l)) for l in x_labels]
    d_clean_roles = _classify_polynomial_variables(d_clean, pep)
    x_clean_roles = _classify_polynomial_variables(x_clean, pep)
    d_roles = Dict{String, Symbol}(l => get(d_clean_roles, c, :unknown) for (l, c) in zip(d_labels, d_clean))
    x_roles = Dict{String, Symbol}(l => get(x_clean_roles, c, :unknown) for (l, c) in zip(x_labels, x_clean))

    info = (; reason = :ok, root_residual_abs = r_abs, root_residual_rel = r_rel,
        jx_cond = cond_Jx, ift_degraded, residual_degraded,
        degraded = ift_degraded || residual_degraded || isempty(S),
        x_hat = x_hat, d_hat = d_hat)

    return S, d_labels, d_roles, x_labels, x_roles, info
end
