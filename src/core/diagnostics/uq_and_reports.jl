# Split 2026-06-10 from the 5,443-line src/core/diagnostics.jl (Phase F2;
# pure content move, functions byte-identical). Part: diagnose_uncertainty, UQ HTML, diagnose_model, estimation/backsolve reports.
# ─── Uncertainty Quantification ────────────────────────────────────────

"""
    _parse_data_label(label) → (base_name, deriv_order)

Parse a data variable label that may be in SIAN style ("y1_0", "y1_2") or
Symbolics style ("y1(t)", "Differential(t, 1)(y1(t))").

Returns `("", 0)` if parsing fails.
"""
function _parse_data_label(label::String)
    # Thin adapter over the single shared parser (Phase D1); this caller's
    # failure contract is ("", 0).
    parsed = parse_jet_label(label)
    return isnothing(parsed) ? ("", 0) : parsed
end

"""
    _match_obs_name(base_name, obs_name_to_idx) → Union{Int, Nothing}

Find the observable index matching a base name. Tries exact match then prefix match.
"""
function _match_obs_name(base_name::AbstractString, obs_name_to_idx::Dict{String, Int})
    # Exact match
    haskey(obs_name_to_idx, base_name) && return obs_name_to_idx[base_name]

    # Prefix match (e.g. "y1" matching "y1_extra")
    for (oname, oidx) in obs_name_to_idx
        if oname == base_name || startswith(oname, base_name)
            return oidx
        end
    end

    return nothing
end

"""
    diagnose_uncertainty(pep, setup_data, t_eval, sensitivity_report; kwargs...) → UncertaintyReport

Propagate GP posterior covariance through the parameter-data sensitivity matrix
to compute parameter uncertainty: Σ_x = S · Σ_d · S'.

Returns `nothing` if the sensitivity matrix is empty or UQ computation fails.
"""
function diagnose_uncertainty(
    pep::ParameterEstimationProblem,
    setup_data,
    t_eval::Float64,
    sensitivity_report::SensitivityReport;
    kwargs...,
)
    S = sensitivity_report.data_sensitivity_matrix
    data_labels = sensitivity_report.data_sensitivity_data_labels

    if isempty(S) || isempty(data_labels)
        return nothing
    end

    n_unknowns, n_data = size(S)

    # Validate dimension consistency between S and unknown labels
    expected_labels = length(sensitivity_report.data_sensitivity_unknown_labels)
    if expected_labels > 0 && expected_labels != n_unknowns
        @warn "[UQ] Label count mismatch: S has $n_unknowns rows but $expected_labels unknown labels — aborting UQ"
        return nothing
    end

    # Step 1: Fit UQ GPs for each non-trfn observable
    t_data = pep.data_sample["t"]
    uq_interps = Dict{String, AGPInterpolatorUQ}()
    obs_names = String[]
    obs_posterior_mean = Vector{Float64}[]
    obs_posterior_std = Vector{Float64}[]

    # Determine max derivative order needed from data labels
    # Data labels may use SIAN style ("y1_0", "y1_1") or Symbolics style
    # ("y1(t)", "Differential(t, 1)(y1(t))")
    max_deriv_needed = 0
    for dl in data_labels
        _, order = _parse_data_label(dl)
        max_deriv_needed = max(max_deriv_needed, order)
    end
    # SE kernel now supports arbitrary order via Hermite recurrence.
    # Cap at a reasonable maximum to prevent runaway computation.
    max_deriv_needed = min(max_deriv_needed, 8)

    for mq in pep.measured_quantities
        obs_name = replace(string(mq.lhs), r"\(.*\)" => "")
        startswith(obs_name, "_obs_trfn_") && continue

        obs_rhs = ModelingToolkit.diff2term(mq.rhs)
        y_data = _get_observable_data(pep, obs_rhs)
        isnothing(y_data) && continue

        try
            # Reuse estimation interpolant if it's already an AGPInterpolatorUQ
            if haskey(setup_data.interpolants, obs_rhs) &&
               setup_data.interpolants[obs_rhs] isa AGPInterpolatorUQ
                interp_uq = setup_data.interpolants[obs_rhs]
            else
                interp_uq = agp_gpr_uq(Float64.(t_data), Float64.(y_data))
            end
            uq_interps[obs_name] = interp_uq

            μ, Σ = joint_derivative_covariance(interp_uq, t_eval, max_deriv_needed)
            # Warn on negative variance before clipping
            neg_diag = findall(d -> d < -1e-10, diag(Σ))
            if !isempty(neg_diag)
                @warn "[UQ] Negative GP posterior variance for '$obs_name' at indices $neg_diag (values: $(diag(Σ)[neg_diag])) — clipping to zero"
            end
            σ = sqrt.(max.(diag(Σ), 0.0))

            push!(obs_names, obs_name)
            push!(obs_posterior_mean, μ)
            push!(obs_posterior_std, σ)
        catch e
            @warn "[UQ] GP fitting failed for observable $obs_name: $e"
        end
    end

    if isempty(obs_names)
        return nothing
    end

    # Step 2: Build Σ_d by mapping data_labels to GP posterior covariance entries
    # Build obs_name → index in obs_names
    obs_name_to_idx = Dict(obs_names[i] => i for i in eachindex(obs_names))

    # For each observable, get the full posterior covariance at t_eval
    obs_cov_blocks = Dict{String, Matrix{Float64}}()
    for (i, name) in enumerate(obs_names)
        if haskey(uq_interps, name)
            _, Σ_obs = joint_derivative_covariance(uq_interps[name], t_eval, max_deriv_needed)
            obs_cov_blocks[name] = Σ_obs
        end
    end

    warnings = String[]

    Σ_d = zeros(n_data, n_data)
    for i in 1:n_data
        base_i, order_i = _parse_data_label(data_labels[i])
        if isempty(base_i)
            msg = "Unparseable data label '$(data_labels[i])' — skipped in Σ_d"
            push!(warnings, msg)
            @warn "[UQ] $msg"
            continue
        end

        # Find which observable this corresponds to
        obs_idx_i = _match_obs_name(base_i, obs_name_to_idx)
        if isnothing(obs_idx_i)
            msg = "Data label '$(data_labels[i])' (base='$base_i') has no matching observable — skipped in Σ_d"
            push!(warnings, msg)
            @warn "[UQ] $msg"
            continue
        end
        obs_name_i = obs_names[obs_idx_i]

        for j in 1:n_data
            base_j, order_j = _parse_data_label(data_labels[j])
            if isempty(base_j)
                continue  # already warned on the outer loop
            end

            # Must be same observable (block-diagonal assumption)
            obs_idx_j = _match_obs_name(base_j, obs_name_to_idx)
            isnothing(obs_idx_j) && continue
            obs_idx_i != obs_idx_j && continue

            # Look up covariance from the GP posterior block
            if haskey(obs_cov_blocks, obs_name_i)
                Σ_block = obs_cov_blocks[obs_name_i]
                if order_i + 1 <= size(Σ_block, 1) && order_j + 1 <= size(Σ_block, 2)
                    Σ_d[i, j] = Σ_block[order_i + 1, order_j + 1]
                end
            end
        end
    end

    # Enforce PSD on Σ_d
    Σ_d = Symmetric(Σ_d)
    evals = eigvals(Σ_d)
    if minimum(evals) < 0
        Σ_d = Σ_d + Matrix{Float64}(I, n_data, n_data) * (abs(minimum(evals)) + 1e-15)
    end

    # Check: zero-variance data variables with nonzero sensitivity
    xlabels = if !isempty(sensitivity_report.data_sensitivity_unknown_labels)
        sensitivity_report.data_sensitivity_unknown_labels
    else
        sensitivity_report.jacobian_col_labels  # fallback for legacy reports
    end
    zero_diag = findall(d -> d == 0.0, diag(Σ_d))
    if !isempty(zero_diag)
        for idx in zero_diag
            sensitive_params = findall(s -> abs(s) > 1e-10, S[:, idx])
            if !isempty(sensitive_params)
                pnames = [xlabels[k] for k in sensitive_params]
                msg = "Zero GP covariance for '$(data_labels[idx])' but parameters [$(join(pnames, ", "))] depend on it — their uncertainty is UNDERESTIMATED"
                push!(warnings, msg)
                @warn "[UQ] $msg"
            end
        end
    end

    # Step 3: Compute Σ_x = S · Σ_d · S'
    Σ_x = S * Matrix(Σ_d) * S'
    Σ_x = Symmetric(Σ_x)

    # Enforce PSD
    evals_x = eigvals(Σ_x)
    if minimum(evals_x) < 0
        Σ_x = Σ_x + Matrix{Float64}(I, n_unknowns, n_unknowns) * (abs(minimum(evals_x)) + 1e-15)
    end

    # Warn on negative variance before clipping
    neg_diag_x = findall(d -> d < -1e-10, diag(Σ_x))
    if !isempty(neg_diag_x)
        neg_labels = [xlabels[k] for k in neg_diag_x if k <= length(xlabels)]
        msg = "Negative variance for parameters [$(join(neg_labels, ", "))] (values: $(diag(Σ_x)[neg_diag_x])) — numerical breakdown, clipping to zero"
        push!(warnings, msg)
        @warn "[UQ] $msg"
    end

    param_std = sqrt.(max.(diag(Σ_x), 0.0))

    # Step 4: Build param labels and true values (from data sensitivity unknown labels)
    param_labels = if !isempty(sensitivity_report.data_sensitivity_unknown_labels)
        sensitivity_report.data_sensitivity_unknown_labels
    else
        sensitivity_report.jacobian_col_labels  # fallback for legacy reports
    end
    param_roles = if !isempty(sensitivity_report.data_sensitivity_unknown_roles)
        sensitivity_report.data_sensitivity_unknown_roles
    else
        sensitivity_report.jacobian_col_roles  # fallback for legacy reports
    end

    # Look up true values for each unknown
    param_true_values = Float64[]
    for label in param_labels
        val = NaN
        # Try matching against p_true
        for (p, v) in pep.p_true
            if replace(string(p), "(t)" => "") == label
                val = v
                break
            end
        end
        # Try matching against ic
        if isnan(val)
            for (s, v) in pep.ic
                if replace(string(s), "(t)" => "") == label
                    val = v
                    break
                end
            end
        end
        # Try parsed name for derivative variables
        if isnan(val)
            parsed = parse_derivative_variable_name(label)
            if !isnothing(parsed)
                base, order = parsed
                if order == 0
                    for (p, v) in pep.p_true
                        if replace(string(p), "(t)" => "") == base
                            val = v
                            break
                        end
                    end
                    if isnan(val)
                        for (s, v) in pep.ic
                            if replace(string(s), "(t)" => "") == base
                                val = v
                                break
                            end
                        end
                    end
                end
            end
        end
        push!(param_true_values, val)
    end

    # Step 5: Correlation matrix
    corr = zeros(n_unknowns, n_unknowns)
    for i in 1:n_unknowns
        for j in 1:n_unknowns
            si = param_std[i]
            sj = param_std[j]
            if si > 0 && sj > 0
                corr[i, j] = clamp(Matrix(Σ_x)[i, j] / (si * sj), -1.0, 1.0)
            elseif i == j
                corr[i, j] = 1.0
            end
        end
    end

    # Step 6: Quality classification
    max_cv = 0.0
    for i in 1:n_unknowns
        tv = param_true_values[i]
        if isfinite(tv) && abs(tv) > 1e-15
            cv = param_std[i] / abs(tv)
            max_cv = max(max_cv, cv)
        end
    end

    status = if max_cv < 0.5
        :ok
    elseif max_cv < 2.0
        :wide_ci
    else
        :degenerate
    end

    return UncertaintyReport(
        pep.name, t_eval,
        obs_names, obs_posterior_mean, obs_posterior_std,
        Matrix(Σ_d), data_labels,
        Matrix(Σ_x), param_std, param_labels, param_roles, param_true_values,
        corr,
        max_cv, status, warnings,
    ), uq_interps
end

# ─── UQ HTML rendering ───────────────────────────────────────────────

"""
Write the UQ section to the HTML report: CI table, correlation matrix,
observation uncertainty, and executive summary cards.
"""
function _write_html_uq_section(io, uq::UncertaintyReport;
    uq_interpolants::Union{Nothing, Dict{String, AGPInterpolatorUQ}} = nothing)
    println(io, "<details open><summary>Parameter Uncertainty (GP → IFT)</summary><div class=\"detail-body\">")

    # Provenance
    status_badge = if uq.status == :ok
        """<span class="badge badge-easy">OK</span>"""
    elseif uq.status == :wide_ci
        """<span class="badge badge-moderate">Wide CI</span>"""
    else
        """<span class="badge badge-hard">Degenerate</span>"""
    end
    println(io, """<div class="provenance">Σ<sub>x</sub> = S·Σ<sub>d</sub>·S<sup>T</sup> where S = parameter–data sensitivity, Σ<sub>d</sub> = GP posterior covariance at t = $(@sprintf("%.4f", uq.t_eval)). $status_badge</div>""")

    # Warning box (if any)
    if !isempty(uq.warnings)
        println(io, """<div style="background:#fff3cd;border:1px solid #ffc107;border-radius:6px;padding:10px 14px;margin:8px 0;">""")
        println(io, """<strong style="color:#856404;">UQ Warnings</strong><ul style="margin:4px 0 0 0;padding-left:20px;">""")
        for w in uq.warnings
            w_esc = replace(w, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            println(io, "<li style=\"color:#856404;\">$w_esc</li>")
        end
        println(io, "</ul></div>")
    end

    # CI table
    println(io, "<h4>Parameter Confidence Intervals</h4>")
    println(io, "<table><tr><th>Parameter</th><th>Role</th><th>True Value</th><th>±1σ (68%)</th><th>95% CI (±1.96σ)</th><th>CV</th><th>Status</th></tr>")

    n_params = min(length(uq.param_labels), length(uq.param_true_values), length(uq.param_std))
    for i in 1:n_params
        label = uq.param_labels[i]
        raw_esc = replace(label, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        pretty = _pretty_name(label)
        role = get(uq.param_roles, label, :unknown)
        role_label = get(_ROLE_LABELS, role, string(role))
        role_color = get(_HTML_ROLE_COLORS, role, "#333")

        tv = uq.param_true_values[i]
        σ = uq.param_std[i]

        tv_str = isfinite(tv) ? _fmt(tv) : "—"
        σ1_str = _fmt(σ)
        σ2_str = _fmt(UQ_CI_Z * σ)

        # CV
        cv = (isfinite(tv) && abs(tv) > 1e-15) ? σ / abs(tv) : NaN
        cv_str = isfinite(cv) ? _fmt_pct(cv) : "—"
        cv_cls = !isfinite(cv) ? "" : cv < 0.10 ? "err-ok" : cv < 0.50 ? "err-warn" : "err-bad"

        status_mark = !isfinite(cv) ? "—" : cv < 0.10 ? "✓" : cv < 0.50 ? "~" : "✗"

        println(io, """<tr><td><span title="$raw_esc" style="color:$role_color;font-weight:600;" class="math">$pretty</span></td><td>$role_label</td><td>$tv_str</td><td>±$σ1_str</td><td>±$σ2_str</td><td class="$cv_cls">$cv_str</td><td>$status_mark</td></tr>""")
    end
    println(io, "</table>")

    # Observation Uncertainty at Shooting Point
    if !isempty(uq.obs_names)
        println(io, "<details><summary>Observation GP Posterior at t = $(@sprintf("%.4f", uq.t_eval))</summary><div class=\"detail-body\">")
        println(io, "<table><tr><th>Observable</th><th>Order</th><th>μ (mean)</th><th>σ (std)</th></tr>")
        for (oi, obs_name) in enumerate(uq.obs_names)
            for k in eachindex(uq.obs_posterior_mean[oi])
                order = k - 1
                μ_val = uq.obs_posterior_mean[oi][k]
                σ_val = uq.obs_posterior_std[oi][k]
                obs_pretty = _pretty_name(obs_name)
                println(io, "<tr><td class=\"math\">$obs_pretty</td><td>$order</td><td>$(_fmt(μ_val))</td><td>$(_fmt(σ_val))</td></tr>")
            end
        end
        println(io, "</table></div></details>")
    end

    # GP Noise Estimates
    if !isnothing(uq_interpolants) && !isempty(uq_interpolants)
        println(io, "<details><summary>GP Noise Estimates</summary><div class=\"detail-body\">")
        println(io, """<div class="provenance">Estimated observation noise σ<sub>n</sub> from GP hyperparameter optimization (kernel jitter on diagonal of K).</div>""")
        println(io, "<table><tr><th>Observable</th><th>σ<sub>n</sub> (noise std)</th><th>σ<sub>n</sub>² (noise var)</th></tr>")
        for (obs_name, interp) in sort(collect(uq_interpolants); by = first)
            σ_n = sqrt(max(interp.noise_var, 0.0))
            println(io, "<tr><td class=\"math\">$(_pretty_name(obs_name))</td><td>$(_fmt(σ_n))</td><td>$(_fmt(interp.noise_var))</td></tr>")
        end
        println(io, "</table></div></details>")
    end

    # Correlation matrix (use actual matrix size to avoid bounds errors with _trfn_ vars)
    n = min(length(uq.param_labels), size(uq.correlation_matrix, 1))
    if n > 0
        default_open = n <= 12
        open_attr = default_open ? " open" : ""
        println(io, "<details$open_attr><summary>Parameter Correlation Matrix ($n × $n)</summary><div class=\"detail-body\">")
        println(io, """<div class="provenance">ρ[i,j] = Σ<sub>x</sub>[i,j] / (σ<sub>i</sub>·σ<sub>j</sub>). Blue = positive correlation, red = negative, white = independent.</div>""")
        println(io, "<div class=\"jac-wrap\"><table class=\"jac-table\">")

        # Column headers
        print(io, "<tr><th></th>")
        for label in uq.param_labels
            raw_esc = replace(label, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            pretty = _pretty_name(label)
            role = get(uq.param_roles, label, :unknown)
            color = get(_HTML_ROLE_COLORS, role, "#333")
            print(io, """<th class="jac-col-header" style="color:$color;" title="$raw_esc">$pretty</th>""")
        end
        println(io, "</tr>")

        # Rows
        for i in 1:n
            label_i = uq.param_labels[i]
            raw_esc = replace(label_i, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            pretty = _pretty_name(label_i)
            role = get(uq.param_roles, label_i, :unknown)
            color = get(_HTML_ROLE_COLORS, role, "#333")
            print(io, """<tr><th style="color:$color;font-weight:600;" title="$raw_esc" class="math">$pretty</th>""")
            for j in 1:n
                ρ = uq.correlation_matrix[i, j]
                _write_correlation_cell(io, ρ)
            end
            println(io, "</tr>")
        end
        println(io, "</table></div></div></details>")
    end

    println(io, "</div></details>")
end

"""Write a single correlation cell with blue/red coloring."""
function _write_correlation_cell(io, ρ::Float64)
    if abs(ρ) < 1e-10
        print(io, "<td class=\"jac-zero\">0</td>")
    else
        alpha = @sprintf("%.2f", 0.1 + 0.3 * abs(ρ))
        bg = ρ > 0 ? "rgba(9,105,218,$alpha)" : "rgba(207,34,46,$alpha)"
        fmt_val = @sprintf("%.2f", ρ)
        print(io, """<td style="background:$bg;">$fmt_val</td>""")
    end
end

"""Write UQ metric cards for the executive summary grid."""
function _write_html_uq_summary_cards(io, uq::UncertaintyReport)
    # Max σ card
    max_σ = maximum(uq.param_std; init = 0.0)
    σ_color = uq.status == :ok ? "var(--easy)" : uq.status == :wide_ci ? "var(--moderate)" : "var(--hard)"
    println(io, """<div class="metric-card">
  <div class="mc-label">Max Param σ</div>
  <div class="mc-value" style="color:$σ_color;">$(_fmt(max_σ))</div>
  <div class="mc-sub">$(_fmt_pct(uq.max_cv)) worst CV</div>
</div>""")
end

# ─── diagnose_model: one-line convenience API ──────────────────────────

"""
    diagnose_model(pep; opts=EstimationOptions(), full_analysis=:best, kwargs...)

Convenience wrapper that automates the full diagnostic pipeline:
1. Sample data from the PEP (if not already sampled)
2. Transform for transcendental functions (sin/cos/exp)
3. Compute production shooting points
4. Call `diagnose()` with comprehensive multi-point analysis

Returns a `ComprehensiveDiagnosticReport`.

# Keyword arguments
- `opts::EstimationOptions`: Controls datasize, time_interval, noise, etc.
- `full_analysis`: Controls depth — see `diagnose()` docs.
- `interpolators`: Vector of `InterpolatorMethod` enums (default: production set).
- All other kwargs are forwarded to `diagnose()`.
"""
function diagnose_model(
    pep::ParameterEstimationProblem;
    opts::EstimationOptions = EstimationOptions(),
    full_analysis::Union{Symbol, Int, Vector{Float64}} = :best,
    interpolators::Vector{InterpolatorMethod} = InterpolatorMethod[],
    run_estimation::Bool = false,
    kwargs...,
)
    # Step 1: Sample data if not already present
    pep_data = if isnothing(pep.data_sample)
        @info "[DIAGNOSE_MODEL] Sampling data (datasize=$(opts.datasize))..."
        sample_problem_data(pep, opts)
    else
        pep
    end

    # Step 2: Transform for transcendentals
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_transformed, tr_info = try
        transform_pep_for_estimation(pep_data, t_var)
    catch e
        @warn "[DIAGNOSE_MODEL] Transcendental transform failed (may not be needed): $e"
        (pep_data, nothing)
    end

    if !isnothing(tr_info)
        @info "[DIAGNOSE_MODEL] Transformed $(length(tr_info.entries)) transcendental(s)"
    end

    # Step 3: Optionally run estimation pipeline
    est_report = nothing
    if run_estimation
        @info "[DIAGNOSE_MODEL] Running estimation pipeline..."
        est_start = time()
        try
            est_opts = EstimationOptions(;
                nooutput = true,
                datasize = opts.datasize,
                time_interval = opts.time_interval,
                noise_level = opts.noise_level,
                ode_solver = opts.ode_solver,
                interpolator = InterpolatorAGPUQ,
                polish_solutions = false,
                polish_solver_solutions = false,
            )
            raw_tuple, analyzed_tuple, uq_est = analyze_parameter_estimation_problem(pep_transformed, est_opts)
            elapsed = time() - est_start
            @info "[DIAGNOSE_MODEL] Estimation completed in $(round(elapsed; digits=1))s"
            # analyzed_tuple[1] is the sorted vector of best ParameterEstimationResults
            est_results = analyzed_tuple[1]
            est_report = _build_estimation_report(pep_transformed, est_results, nothing, elapsed)
        catch e
            @warn "[DIAGNOSE_MODEL] Estimation failed (non-fatal): $e"
        end
    end

    # Step 4: Compute production shooting points
    t_vec = pep_transformed.data_sample["t"]
    n_total = length(t_vec)
    shoot_indices = compute_shooting_indices(12, n_total; warp = true, beta = 3.0)
    # Avoid exact boundary
    if !isempty(shoot_indices) && shoot_indices[1] == 1 && n_total > 2
        shoot_indices[1] = 2
    end
    t_eval_points = unique(sort([t_vec[i] for i in shoot_indices if i >= 1 && i <= n_total]))

    # Step 5: Call diagnose with comprehensive mode
    return diagnose(pep_transformed;
        interpolators = isempty(interpolators) ? _DIAGNOSTIC_DEFAULT_INTERPOLATORS : interpolators,
        t_eval_points = t_eval_points,
        full_analysis = full_analysis,
        estimation_report = est_report,
        data_config = (datasize = opts.datasize, noise_level = opts.noise_level,
                       time_interval = opts.time_interval),
        kwargs...,
    )
end

# ─── Estimation Results Report Builder ──────────────────────────────────

"""
    compute_cross_solution_spread(pep, results) → CrossSolutionSpread

Compute per-parameter statistics across all HC solutions to measure
practical identifiability. Small CV → tight. Large CV → loose.
"""
function compute_cross_solution_spread(
    pep::ParameterEstimationProblem,
    results::AbstractVector,
)
    valid = filter(r -> !isnothing(r.err) && isfinite(r.err), results)
    n_sol = length(valid)

    unident_names = Set{String}()
    if n_sol > 0
        for u in first(valid).all_unidentifiable
            push!(unident_names, replace(string(u), "(t)" => ""))
        end
    end

    function _spread_entry(name::String, true_val::Float64, values::Vector{Float64}, is_unident::Bool)
        n = length(values)
        if n == 0
            return ParameterSpreadEntry(name, true_val, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, is_unident, :unknown)
        end
        sorted = sort(values)
        med = n % 2 == 1 ? sorted[div(n + 1, 2)] : 0.5 * (sorted[div(n, 2)] + sorted[div(n, 2) + 1])
        mn = sum(values) / n
        sd = n > 1 ? sqrt(sum((v - mn)^2 for v in values) / (n - 1)) : 0.0
        cv = abs(med) > 1e-15 ? sd / abs(med) : (sd > 1e-15 ? Inf : 0.0)
        q25 = sorted[max(1, round(Int, 0.25 * n))]
        q75 = sorted[max(1, min(n, round(Int, 0.75 * n)))]
        cls = is_unident ? :unidentifiable : cv < 0.05 ? :tight : cv < 0.5 ? :moderate : :loose
        return ParameterSpreadEntry(name, true_val, med, mn, sd, cv, q25, q75, minimum(values), maximum(values), n, is_unident, cls)
    end

    # Parameter spread
    param_spread = ParameterSpreadEntry[]
    for (p, true_val) in pep.p_true
        p_name = replace(string(p), "(t)" => "")
        values = Float64[]
        for r in valid
            for (ep, ev) in r.parameters
                if replace(string(ep), "(t)" => "") == p_name
                    isfinite(ev) && push!(values, ev)
                    break
                end
            end
        end
        is_unident = p_name in unident_names
        push!(param_spread, _spread_entry(p_name, Float64(true_val), values, is_unident))
    end

    # State spread
    state_spread = ParameterSpreadEntry[]
    for (s, true_val) in pep.ic
        s_name = replace(string(s), "(t)" => "")
        startswith(s_name, "_trfn_") && continue
        values = Float64[]
        for r in valid
            for (es, ev) in r.states
                if replace(string(es), "(t)" => "") == s_name
                    isfinite(ev) && push!(values, ev)
                    break
                end
            end
        end
        push!(state_spread, _spread_entry(s_name, Float64(true_val), values, false))
    end

    return CrossSolutionSpread(pep.name, n_sol, param_spread, state_spread)
end

function _build_estimation_report(pep::ParameterEstimationProblem,
    analyzed_results, uq_report, elapsed::Float64)

    # analyzed_results is already oracle-sorted (by max relative error against truth,
    # excluding unidentifiable params). Use that ordering — do NOT re-sort by backsolve
    # error, which can select a wrong algebraic branch that happens to have low
    # approximation error but wildly wrong parameter values.
    valid = filter(r -> !isnothing(r.err) && isfinite(r.err), analyzed_results)
    if isempty(valid)
        valid = analyzed_results
    end
    isempty(valid) && error("No estimation results to build report from")

    # Take the first (best oracle-sorted) result
    best = first(valid)
    best_error = isnothing(best.err) ? NaN : best.err

    # Build set of unidentifiable parameter names for flagging
    unident_names = Set{String}()
    for u in best.all_unidentifiable
        push!(unident_names, replace(string(u), "(t)" => ""))
    end

    # Build parameter comparison
    param_comparison = @NamedTuple{name::String, true_val::Float64, est_val::Float64,
        rel_error::Float64, within_ci::Bool, is_unidentifiable::Bool}[]
    for (p, true_val) in pep.p_true
        p_name = replace(string(p), "(t)" => "")
        est_val = NaN
        for (ep, ev) in best.parameters
            if replace(string(ep), "(t)" => "") == p_name
                est_val = ev
                break
            end
        end
        rel_err = abs(true_val) > 1e-15 ? abs(est_val - true_val) / abs(true_val) : abs(est_val - true_val)
        within = true  # default if no UQ
        is_unident = p_name in unident_names
        push!(param_comparison, (name = p_name, true_val = true_val, est_val = est_val,
            rel_error = rel_err, within_ci = within, is_unidentifiable = is_unident))
    end

    # Build state (IC) comparison
    state_comparison = @NamedTuple{name::String, true_val::Float64, est_val::Float64,
        rel_error::Float64, within_ci::Bool}[]
    for (s, true_val) in pep.ic
        s_name = replace(string(s), "(t)" => "")
        # Skip _trfn_ states
        startswith(s_name, "_trfn_") && continue
        est_val = NaN
        for (es, ev) in best.states
            if replace(string(es), "(t)" => "") == s_name
                est_val = ev
                break
            end
        end
        rel_err = abs(true_val) > 1e-15 ? abs(est_val - true_val) / abs(true_val) : abs(est_val - true_val)
        within = true  # default if no UQ
        push!(state_comparison, (name = s_name, true_val = true_val, est_val = est_val,
            rel_error = rel_err, within_ci = within))
    end

    # Update CI coverage if UQ is available (use _find_uq_sigma for SIAN name matching)
    if !isnothing(uq_report) && !isempty(uq_report.param_std)
        for i in eachindex(param_comparison)
            pc = param_comparison[i]
            σ = _find_uq_sigma(pc.name, uq_report)
            if isfinite(σ)
                within = abs(pc.true_val - pc.est_val) < UQ_CI_Z * σ
                param_comparison[i] = (name = pc.name, true_val = pc.true_val,
                    est_val = pc.est_val, rel_error = pc.rel_error, within_ci = within,
                    is_unidentifiable = pc.is_unidentifiable)
            end
        end
    end

    # Cross-solution spread (practical identifiability)
    spread = try
        compute_cross_solution_spread(pep, valid)
    catch e
        @warn "[DIAG] Cross-solution spread failed: $e"
        nothing
    end

    return EstimationResultsReport(
        pep.name, length(valid), best_error, elapsed,
        param_comparison, state_comparison, best, spread,
    )
end

# ─── Backsolve Uncertainty Propagation ─────────────────────────────────

"""
    propagate_backsolve_uncertainty(pep, best_result, uq_report) → BacksolveUQReport

Propagate parameter uncertainty from the shooting point through the backward
ODE integration to initial conditions at t₀ using the delta method:

    Σ_{s(t₀)} = J_g · Σ_{p, s(t_eval)} · J_g'

where J_g = ∂g/∂(p, s(t_eval)) is computed via ForwardDiff.
"""
function propagate_backsolve_uncertainty(pep::ParameterEstimationProblem,
    best_result::ParameterEstimationResult,
    uq_report::UncertaintyReport)

    t_data = pep.data_sample["t"]
    t0 = t_data[1]
    t_shoot = best_result.at_time

    # If estimation was at t0, no backsolve needed — return actual values
    if abs(t_shoot - t0) < 1e-10
        real_states = [s for s in pep.model.original_states
                        if !startswith(replace(string(s), "(t)" => ""), "_trfn_")]
        ic_names = [replace(string(s), "(t)" => "") for s in real_states]
        n_ic = length(ic_names)

        # Get actual estimated ICs
        ic_est = Float64[]
        for s in real_states
            s_name = replace(string(s), "(t)" => "")
            found = false
            for (es, ev) in best_result.states
                if replace(string(es), "(t)" => "") == s_name
                    push!(ic_est, ev); found = true; break
                end
            end
            found || push!(ic_est, NaN)
        end

        # Get true ICs
        ic_true = [get(pep.ic, s, NaN) for s in real_states]

        # At t0, uncertainty comes directly from UQ (no backsolve propagation)
        ic_std = Float64[]
        for s_name in ic_names
            push!(ic_std, _find_uq_sigma(s_name, uq_report))
        end
        # Replace NaN with 0 for missing entries
        ic_std = [isnan(s) ? 0.0 : s for s in ic_std]

        ic_covers = [ic_std[i] > 0 ? abs(ic_true[i] - ic_est[i]) < UQ_CI_Z * ic_std[i] : true
                     for i in 1:n_ic]

        return BacksolveUQReport(
            t_shoot, t0, ic_names, ic_est, ic_true, ic_std,
            ic_covers, Matrix{Float64}(undef, 0, 0), 1.0, true,
        )
    end

    sys = pep.model.system
    params = pep.model.original_parameters
    states = pep.model.original_states

    # Filter out _trfn_ states
    real_states = [s for s in states if !startswith(replace(string(s), "(t)" => ""), "_trfn_")]
    ic_names = [replace(string(s), "(t)" => "") for s in real_states]
    n_params = length(params)
    n_states = length(real_states)

    # Extract estimated parameter values and state ICs
    est_params = Float64[]
    for p in params
        p_name = replace(string(p), "(t)" => "")
        found = false
        for (ep, ev) in best_result.parameters
            if replace(string(ep), "(t)" => "") == p_name
                push!(est_params, ev)
                found = true
                break
            end
        end
        found || push!(est_params, NaN)
    end

    est_ics = Float64[]
    for s in real_states
        s_name = replace(string(s), "(t)" => "")
        found = false
        for (es, ev) in best_result.states
            if replace(string(es), "(t)" => "") == s_name
                push!(est_ics, ev)
                found = true
                break
            end
        end
        found || push!(est_ics, NaN)
    end

    # True ICs for coverage check
    ic_true = Float64[]
    for s in real_states
        push!(ic_true, get(pep.ic, s, NaN))
    end

    # Build the backsolve closure: θ = [params..., states_at_t_shoot...] → states_at_t0
    # We need to forward-solve from t0 to t_shoot with estimated params, get states at t_shoot,
    # then build a closure that takes those values and back-solves
    completed_sys = ModelingToolkit.complete(sys)
    completed_states = ModelingToolkit.unknowns(completed_sys)
    completed_params = ModelingToolkit.parameters(completed_sys)

    function backsolve_closure(θ)
        p_vals = θ[1:n_params]
        s_vals_at_shoot = θ[n_params+1:n_params+length(states)]

        u0_dict = Dict(completed_states .=> s_vals_at_shoot)
        p_dict = Dict(completed_params .=> p_vals)

        prob = ODEProblem(completed_sys, merge(u0_dict, p_dict), (t_shoot, t0))
        sol = OrdinaryDiffEq.solve(prob, AutoVern9(Rodas5P());
            abstol = 1e-12, reltol = 1e-12, saveat = Float64[])

        # Extract states at t0
        result = zeros(eltype(θ), length(states))
        for i in eachindex(states)
            result[i] = sol(t0)[i]
        end
        return result
    end

    # Get states at t_shoot by forward-solving from estimated ICs
    states_at_shoot = try
        # Use the estimated solution if available
        if !isnothing(best_result.solution)
            [best_result.solution(t_shoot)[i] for i in eachindex(states)]
        else
            # Forward solve
            all_ics = Float64[]
            for s in states
                s_name = replace(string(s), "(t)" => "")
                found = false
                for (es, ev) in best_result.states
                    if replace(string(es), "(t)" => "") == s_name
                        push!(all_ics, ev)
                        found = true
                        break
                    end
                end
                found || push!(all_ics, 0.0)
            end

            u0_dict = Dict(completed_states .=> all_ics)
            p_dict = Dict(completed_params .=> est_params)
            prob = ODEProblem(completed_sys, merge(u0_dict, p_dict), (t0, t_shoot))
            sol = OrdinaryDiffEq.solve(prob, AutoVern9(Rodas5P()); abstol = 1e-12, reltol = 1e-12)
            [sol(t_shoot)[i] for i in eachindex(states)]
        end
    catch e
        @warn "[BACKSOLVE_UQ] Failed to get states at shooting point: $e"
        return BacksolveUQReport(t_shoot, t0, ic_names, est_ics, ic_true,
            fill(NaN, n_states), fill(false, n_states),
            Matrix{Float64}(undef, 0, 0), NaN, false)
    end

    # Build θ point
    θ_point = vcat(est_params, states_at_shoot)

    # Compute Jacobian via ForwardDiff
    J_g = try
        ForwardDiff.jacobian(backsolve_closure, θ_point)
    catch e
        @warn "[BACKSOLVE_UQ] ForwardDiff Jacobian failed: $e"
        return BacksolveUQReport(t_shoot, t0, ic_names, est_ics, ic_true,
            fill(NaN, n_states), fill(false, n_states),
            Matrix{Float64}(undef, 0, 0), NaN, false)
    end

    # Extract the sub-block of Σ_x corresponding to [params, order-0 states]
    # from the UQ report. UQ param_labels include derivative variables — we only
    # want params and order-0 state ICs.
    n_theta = n_params + length(states)
    Σ_sub = zeros(n_theta, n_theta)

    # Build mapping: θ index → UQ param index
    theta_labels = String[]
    for p in params
        push!(theta_labels, replace(string(p), "(t)" => ""))
    end
    for s in states
        push!(theta_labels, replace(string(s), "(t)" => ""))
    end

    for i in 1:n_theta
        for j in 1:n_theta
            # Find matching indices in UQ param_labels
            ui = _find_uq_param_index(theta_labels[i], uq_report)
            uj = _find_uq_param_index(theta_labels[j], uq_report)
            if !isnothing(ui) && !isnothing(uj)
                Σ_sub[i, j] = uq_report.param_covariance[ui, uj]
            end
        end
    end

    # Propagate: Σ_ic = J_g · Σ_sub · J_g'
    Σ_ic = J_g * Σ_sub * J_g'

    # Extract only the real (non-trfn) state rows from J_g result
    # J_g returns all states, but we only want real ones
    real_indices = [i for (i, s) in enumerate(states)
                    if !startswith(replace(string(s), "(t)" => ""), "_trfn_")]

    ic_std = [sqrt(max(Σ_ic[i, i], 0.0)) for i in real_indices]
    ic_estimated = est_ics

    # Extract the backsolve result at t0 for estimated values
    try
        result_at_t0 = backsolve_closure(θ_point)
        ic_estimated = [result_at_t0[i] for i in real_indices]
    catch
        # Fall back to the estimation ICs
    end

    ic_ci_covers = [abs(ic_true[i] - ic_estimated[i]) < UQ_CI_Z * ic_std[i] for i in 1:n_states]

    # Amplification = max singular value of J_g
    svs = try
        svdvals(J_g[real_indices, :])
    catch
        [NaN]
    end
    amplification = maximum(svs; init = NaN)

    return BacksolveUQReport(
        t_shoot, t0, ic_names, ic_estimated, ic_true,
        ic_std, ic_ci_covers,
        J_g[real_indices, :], amplification, true,
    )
end

"""Find the index of a variable name in the UQ report's param_labels."""
function _find_uq_param_index(name::String, uq::UncertaintyReport)
    for (i, label) in enumerate(uq.param_labels)
        if label == name
            return i
        end
        # Also try parsed base name for derivative vars like "x1_0"
        parsed = parse_derivative_variable_name(label)
        if !isnothing(parsed)
            base, order = parsed
            if order == 0 && String(base) == name
                return i
            end
        end
    end
    return nothing
end

# ─── UQ Name-Matching Helper ─────────────────────────────────────────

"""
    _find_uq_sigma(name, uq) → Float64

Look up the standard deviation for variable `name` in the UQ report,
trying exact match first, then SIAN-style `_0` suffix match (e.g. `a_0` → `a`).
Returns `NaN` if no match found.
"""
function _find_uq_sigma(name::String, uq::UncertaintyReport)
    # Exact match
    for j in eachindex(uq.param_labels)
        if uq.param_labels[j] == name
            return uq.param_std[j]
        end
    end
    # SIAN-style match: "a_0" matches "a"
    for j in eachindex(uq.param_labels)
        parsed = parse_derivative_variable_name(uq.param_labels[j])
        if !isnothing(parsed)
            base, order = parsed
            if order == 0 && String(base) == name
                return uq.param_std[j]
            end
        end
    end
    return NaN
end

# ─── Estimation Results HTML Section ──────────────────────────────────

"""
Write the estimation results section to the HTML report.
Shows a comparison table of true vs estimated values with CI coverage.
"""
function _write_html_estimation_section(io, est::EstimationResultsReport;
    uq::Union{Nothing, UncertaintyReport} = nothing)

    println(io, "<details open><summary>Estimation Results</summary><div class=\"detail-body\">")

    # Summary line
    err_badge = est.best_error < 0.01 ? """<span class="badge badge-easy">Low Error</span>""" :
        est.best_error < 0.10 ? """<span class="badge badge-moderate">Moderate Error</span>""" :
        """<span class="badge badge-hard">High Error</span>"""
    println(io, """<div class="provenance">Best error: $(_fmt(est.best_error)) &middot; $(est.n_results) solution(s) &middot; $(round(est.estimation_time_seconds; digits=1))s $err_badge</div>""")

    has_uq = !isnothing(uq) && !isempty(uq.param_std)

    # Parameters table
    if !isempty(est.param_comparison)
        println(io, "<h4>Parameters</h4>")
        println(io, "<table><tr><th>Parameter</th><th>True</th><th>Estimated</th><th>Rel Error</th>")
        if has_uq
            println(io, "<th>95% CI</th><th>Coverage</th>")
        end
        println(io, "</tr>")

        for pc in est.param_comparison
            is_unident = pc.is_unidentifiable
            err_cls = is_unident ? "" : pc.rel_error < 0.01 ? "err-ok" : pc.rel_error < 0.10 ? "err-warn" : "err-bad"
            pretty = _pretty_name(pc.name)
            raw_esc = replace(pc.name, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")

            unident_badge = is_unident ? """ <span class="badge badge-moderate">unident.</span>""" : ""
            row_style = is_unident ? " style=\"opacity:0.6;\"" : ""
            print(io, """<tr$row_style><td><span title="$raw_esc" class="math" style="font-weight:600;">$pretty</span>$unident_badge</td>""")
            print(io, "<td>$(_fmt(pc.true_val))</td>")
            print(io, "<td>$(_fmt(pc.est_val))</td>")
            print(io, """<td class="$err_cls">$(_fmt_pct(pc.rel_error))</td>""")

            if has_uq
                if is_unident
                    # Skip CI for unidentifiable parameters
                    print(io, "<td>—</td><td>—</td>")
                else
                    σ = _find_uq_sigma(pc.name, uq)
                    if isfinite(σ)
                        ci_lo = pc.est_val - UQ_CI_Z * σ
                        ci_hi = pc.est_val + UQ_CI_Z * σ
                        within = abs(pc.true_val - pc.est_val) < UQ_CI_Z * σ
                        cov_mark = within ? """<span style="color:var(--easy);">✓</span>""" :
                            """<span style="color:var(--hard);">✗</span>"""
                        print(io, "<td>[$(_fmt(ci_lo)), $(_fmt(ci_hi))]</td><td>$cov_mark</td>")
                    else
                        print(io, "<td>—</td><td>—</td>")
                    end
                end
            end
            println(io, "</tr>")
        end
        println(io, "</table>")
    end

    # States (ICs) table — with CI columns when UQ is available
    if !isempty(est.state_comparison)
        println(io, "<h4>Initial Conditions</h4>")
        println(io, "<table><tr><th>State</th><th>True</th><th>Estimated</th><th>Rel Error</th>")
        if has_uq
            println(io, "<th>95% CI</th><th>Coverage</th>")
        end
        println(io, "</tr>")

        for sc in est.state_comparison
            err_cls = sc.rel_error < 0.01 ? "err-ok" : sc.rel_error < 0.10 ? "err-warn" : "err-bad"
            pretty = _pretty_name(sc.name)
            raw_esc = replace(sc.name, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")

            print(io, """<tr><td><span title="$raw_esc" class="math" style="font-weight:600;">$pretty</span>(0)</td>""")
            print(io, "<td>$(_fmt(sc.true_val))</td>")
            print(io, "<td>$(_fmt(sc.est_val))</td>")
            print(io, """<td class="$err_cls">$(_fmt_pct(sc.rel_error))</td>""")

            if has_uq
                σ = _find_uq_sigma(sc.name, uq)
                if isfinite(σ)
                    ci_lo = sc.est_val - UQ_CI_Z * σ
                    ci_hi = sc.est_val + UQ_CI_Z * σ
                    within = abs(sc.true_val - sc.est_val) < UQ_CI_Z * σ
                    cov_mark = within ? """<span style="color:var(--easy);">✓</span>""" :
                        """<span style="color:var(--hard);">✗</span>"""
                    print(io, "<td>[$(_fmt(ci_lo)), $(_fmt(ci_hi))]</td><td>$cov_mark</td>")
                else
                    print(io, "<td>—</td><td>—</td>")
                end
            end
            println(io, "</tr>")
        end
        println(io, "</table>")
    end

    # Cross-solution spread (practical identifiability)
    if !isnothing(est.spread) && est.spread.n_solutions > 1
        _write_html_spread_section(io, est.spread)
    end

    println(io, "</div></details>")
end

"""
Write the cross-solution spread table showing practical identifiability.
"""
function _write_html_spread_section(io, spread::CrossSolutionSpread)
    println(io, "<details open><summary>Practical Identifiability (Cross-Solution Spread, N=$(spread.n_solutions))</summary><div class=\"detail-body\">")
    println(io, """<div class="provenance"><b>What this shows:</b> How much each parameter/state varies across all $(spread.n_solutions) HC solutions from different interpolators and shooting points. Small CV (coefficient of variation) = practically identifiable at this noise level. Large CV = practically non-identifiable — multiple parameter values fit the data equally well.<br><b>Classification:</b> <span class="err-ok">tight</span> (CV &lt; 5%), <span class="err-warn">moderate</span> (5–50%), <span class="err-bad">loose</span> (CV &gt; 50%).</div>""")

    for (label, entries) in [("Parameters", spread.param_spread), ("Initial Conditions", spread.state_spread)]
        isempty(entries) && continue
        println(io, "<h4>$label</h4>")
        println(io, "<table><tr><th>Name</th><th>True</th><th>Median</th><th>CV</th><th>IQR</th><th>Range</th><th>N</th><th>Class</th></tr>")
        for e in entries
            cls_str = e.classification == :tight ? "tight" :
                      e.classification == :moderate ? "moderate" :
                      e.classification == :loose ? "LOOSE" :
                      e.classification == :unidentifiable ? "unident." : "?"
            cls_css = e.classification == :tight ? "err-ok" :
                      e.classification == :moderate ? "err-warn" : "err-bad"
            cv_str = isinf(e.cv) ? "∞" : isnan(e.cv) ? "—" : @sprintf("%.1f%%", e.cv * 100)
            row_style = e.is_unidentifiable ? " style=\"opacity:0.6;\"" : ""
            pretty = _pretty_name(e.name)

            println(io, """<tr$row_style><td class="math" style="font-weight:600;">$pretty</td>""" *
                "<td>$(_fmt(e.true_val))</td>" *
                "<td>$(_fmt(e.median))</td>" *
                """<td class="$cls_css">$cv_str</td>""" *
                "<td>[$(_fmt(e.iqr_low)), $(_fmt(e.iqr_high))]</td>" *
                "<td>[$(_fmt(e.min_val)), $(_fmt(e.max_val))]</td>" *
                "<td>$(e.n_solutions)</td>" *
                """<td class="$cls_css" style="font-weight:600;">$cls_str</td></tr>""")
        end
        println(io, "</table>")
    end
    println(io, "</div></details>")
end

# ─── Backsolve UQ HTML Section ──────────────────────────────────────────

"""
Write the backsolve UQ section to the HTML report.
Shows uncertainty propagation from shooting point through backward ODE to t₀.
"""
function _write_html_backsolve_uq_section(io, bq::BacksolveUQReport)
    println(io, "<details><summary>Backsolve Uncertainty (t=$(round(bq.t_shoot; digits=4)) → t₀=$(round(bq.t0; digits=4)))</summary><div class=\"detail-body\">")

    amp_color = bq.amplification < 10 ? "var(--easy)" : bq.amplification < 100 ? "var(--moderate)" : "var(--hard)"
    println(io, """<div class="provenance">Uncertainty propagated from shooting point t = $(round(bq.t_shoot; digits=4)) to t₀ = $(round(bq.t0; digits=4)) via backward ODE Jacobian (ForwardDiff). Amplification factor: <span style="color:$amp_color;font-weight:600;">$(_fmt(bq.amplification))×</span> (max singular value of J<sub>g</sub>).</div>""")

    # IC table
    println(io, "<table><tr><th>State IC</th><th>True</th><th>Estimated</th><th>σ (propagated)</th><th>95% CI</th><th>Coverage</th></tr>")

    for i in eachindex(bq.ic_names)
        pretty = _pretty_name(bq.ic_names[i])
        raw_esc = replace(bq.ic_names[i], "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")

        ci_lo = bq.ic_estimated[i] - UQ_CI_Z * bq.ic_std[i]
        ci_hi = bq.ic_estimated[i] + UQ_CI_Z * bq.ic_std[i]
        cov_mark = bq.ic_ci_covers[i] ? """<span style="color:var(--easy);">✓</span>""" :
            """<span style="color:var(--hard);">✗</span>"""

        print(io, """<tr><td><span title="$raw_esc" class="math" style="font-weight:600;">$pretty</span>(0)</td>""")
        print(io, "<td>$(_fmt(bq.ic_true[i]))</td>")
        print(io, "<td>$(_fmt(bq.ic_estimated[i]))</td>")
        print(io, "<td>$(_fmt(bq.ic_std[i]))</td>")
        print(io, "<td>[$(_fmt(ci_lo)), $(_fmt(ci_hi))]</td>")
        println(io, "<td>$cov_mark</td></tr>")
    end
    println(io, "</table>")

    println(io, "</div></details>")
end
