# Split 2026-06-10 from the 5,443-line src/core/diagnostics.jl (Phase F2;
# pure content move, functions byte-identical). Part: HTML report generation, building blocks, error-budget HTML, SVG embedding.
# ─── HTML report generation ────────────────────────────────────────────

const _HTML_CSS = """
<style>
  :root { --bg: #fafbfc; --card: #fff; --border: #d0d7de; --accent: #0969da;
          --easy: #1a7f37; --moderate: #bf8700; --hard: #cf222e; --infeasible: #8250df;
          --teal: #0d7d6b; --gray-mid: #6e7781; }
  * { box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
         background: var(--bg); color: #1f2328; max-width: 1080px; margin: 2rem auto; padding: 0 1rem; }
  h1 { font-size: 1.5rem; border-bottom: 1px solid var(--border); padding-bottom: .5rem; }
  h2 { font-size: 1.2rem; margin-top: 1.5rem; }
  h3 { font-size: 1rem; margin: .75rem 0 .35rem; }
  h4 { font-size: .9rem; margin: .5rem 0 .25rem; }
  .math { font-family: "Cambria Math", "STIX Two Math", "Times New Roman", serif; font-style: italic; }
  .section-kicker { font-size: .7rem; font-weight: 700; letter-spacing: .08em;
                    text-transform: uppercase; color: var(--gray-mid); margin-bottom: .15rem; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-weight: 600;
           font-size: .85rem; color: #fff; }
  .badge-easy { background: var(--easy); }
  .badge-moderate { background: var(--moderate); }
  .badge-hard { background: var(--hard); }
  .badge-infeasible { background: var(--infeasible); }
  .badge-obs { background: var(--teal); font-size: .7rem; padding: 1px 6px; vertical-align: middle; }
  .badge-latent { background: var(--gray-mid); font-size: .7rem; padding: 1px 6px; vertical-align: middle; }
  /* Summary grid */
  .summary-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
                  gap: .75rem; margin: 1rem 0 1.5rem; }
  .metric-card { background: var(--card); border: 1px solid var(--border); border-radius: 8px;
                 padding: .75rem 1rem;
                 box-shadow: 0 1px 2px rgba(15,23,42,0.04), 0 8px 24px rgba(15,23,42,0.06); }
  .metric-card .mc-label { font-size: .72rem; font-weight: 700; letter-spacing: .06em;
                            text-transform: uppercase; color: var(--gray-mid); margin-bottom: .25rem; }
  .metric-card .mc-value { font-size: 1.3rem; font-weight: 700; line-height: 1.1; }
  .metric-card .mc-sub { font-size: .75rem; color: var(--gray-mid); margin-top: .15rem; }
  /* Collapsible sections */
  details { background: var(--card); border: 1px solid var(--border); border-radius: 8px;
            margin: .75rem 0;
            box-shadow: 0 1px 2px rgba(15,23,42,0.04), 0 8px 24px rgba(15,23,42,0.06); }
  details > summary { cursor: pointer; padding: .65rem 1rem; font-weight: 600;
                       list-style: none; user-select: none; display: flex; align-items: center; gap: .5rem; }
  details > summary::before { content: '\\25B6'; font-size: .65rem; color: var(--gray-mid);
                               transition: transform .15s; display: inline-block; }
  details[open] > summary::before { transform: rotate(90deg); }
  details > summary:hover { background: #f6f8fa; border-radius: 8px; }
  .detail-body { padding: .5rem 1rem 1rem; }
  /* Tables */
  table { border-collapse: collapse; width: 100%; font-size: .85rem; margin: .5rem 0;
          font-variant-numeric: tabular-nums lining-nums; }
  th, td { text-align: right; padding: 4px 10px; border-bottom: 1px solid var(--border); }
  th { background: #f6f8fa; font-weight: 600; text-align: right; }
  th:first-child, td:first-child { text-align: left; }
  /* Error severity */
  .err-ok { color: var(--easy); }
  .err-warn { color: var(--moderate); }
  .err-bad { color: var(--hard); font-weight: 600; }
  .best-cell { background: #dafbe1; font-weight: 600; }
  /* Misc utility */
  .meta { color: #656d76; font-size: .8rem; }
  .kv { display: grid; grid-template-columns: 200px 1fr; gap: 2px 12px; font-size: .9rem; margin: .5rem 0; }
  .kv dt { font-weight: 600; }
  /* Jacobian / heatmap */
  .jac-wrap { overflow-x: auto; margin: .5rem 0; }
  .jac-table { border-collapse: collapse; font-size: .7rem; width: auto; }
  .jac-table th { font-size: .7rem; padding: 2px 4px; white-space: nowrap; }
  .jac-table td { font-size: .7rem; padding: 2px 4px; text-align: right; font-family: monospace;
                  font-variant-numeric: tabular-nums; }
  .jac-table .jac-zero { color: #ccc; }
  .jac-table .jac-col-header { writing-mode: vertical-rl; text-orientation: mixed; transform: rotate(180deg);
                                 font-weight: 600; text-align: left; padding: 4px 2px; height: 6em; }
  /* Overview grid */
  .overview-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin: .5rem 0; }
  .overview-grid table { font-size: .85rem; }
  /* Provenance box */
  .provenance { color: #656d76; font-size: .8rem; margin: .25rem 0 .5rem; padding: .4rem .6rem;
                 background: #f6f8fa; border-radius: 4px; border-left: 3px solid var(--accent); }
  /* Trajectory plot cards */
  .plot-card { margin: .5rem 0; border-radius: 6px; border: 1px solid var(--border);
               overflow: hidden; }
  .plot-card.observable { border-left: 4px solid var(--teal); }
  .plot-card.latent { border-left: 4px solid var(--gray-mid); }
  .plot-card-title { padding: .4rem .75rem; font-size: .85rem; font-weight: 600;
                     background: #f6f8fa; display: flex; align-items: center; gap: .5rem; }
  .plot-card-body { padding: .5rem; }
  /* Print */
  @media print {
    body { max-width: 100%; margin: 0; padding: 0; }
    details { box-shadow: none; break-inside: avoid; }
    details[open] > summary::before { content: '\\25BC'; }
    .metric-card { box-shadow: none; }
  }
</style>
"""

function _err_class(e::Float64)
    e < 0.01 ? "err-ok" : e < 0.10 ? "err-warn" : "err-bad"
end

function _difficulty_badge(d::Symbol)
    """<span class="badge badge-$(d)">$(d)</span>"""
end

function _fmt(x::Float64; sigdigits = 3)
    isnan(x) && return "NaN"
    isinf(x) && return x > 0 ? "∞" : "-∞"
    x == 0.0 && return "0"
    ax = abs(x)
    if ax >= 1e-3 && ax < 1e4
        s = string(round(x; sigdigits = sigdigits))
        if contains(s, '.')
            s = rstrip(s, '0')
            s = rstrip(s, '.')
        end
        return s
    else
        exp = floor(Int, log10(ax))
        mantissa = x / 10.0^exp
        m_str = string(round(mantissa; sigdigits = sigdigits))
        if contains(m_str, '.')
            m_str = rstrip(m_str, '0')
            m_str = rstrip(m_str, '.')
        end
        return "$(m_str)×10<sup>$(exp)</sup>"
    end
end

function _fmt_pct(x::Float64)
    isnan(x) && return "NaN"
    pct = x * 100
    if pct >= 0.01 && pct < 1000
        return string(round(pct; sigdigits = 3)) * "%"
    else
        return _fmt(x)
    end
end

"""
    _save_diagnostic_html(report::DiagnosticReport; pep=nothing)

Generate a self-contained HTML report with collapsible sections for a single
DiagnosticReport.  When `pep` is provided, includes SVG trajectory plots.
"""
function _save_diagnostic_html(report::DiagnosticReport; pep = nothing)
    dir = joinpath("artifacts", "diagnostics", report.model_name)
    mkpath(dir)
    path = joinpath(dir, "report.html")

    # Compute local-coordinate UQ if sensitivity matrix is available. A single
    # DiagnosticReport does not carry a best estimation result, so it cannot
    # backsolve to physical initial-condition coordinates here.
    uq_report = nothing
    uq_interps = nothing
    if !isnothing(pep) && !isempty(report.sensitivity.data_sensitivity_matrix)
        try
            setup_data = setup_parameter_estimation(pep; interpolator = agp_gpr_uq, nooutput = true)
            result = diagnose_uncertainty(pep, setup_data, report.derivative_accuracy.t_eval, report.sensitivity)
            if !isnothing(result)
                uq_report, uq_interps = result
            end
        catch e
            @warn "[DIAGNOSE] UQ computation failed (non-fatal): $e"
        end
    end

    open(path, "w") do io
        _write_html_header(io, report.model_name, report.difficulty, report.bottleneck, report.timestamp)
        _write_html_executive_summary(io, report; pep = pep, uq = uq_report)
        if !isnothing(pep)
            _write_html_model_overview_section(io, pep)
            _write_html_trajectory_section(io, pep; uq_interpolants = uq_interps)
        end
        _write_html_deriv_section(io, report.derivative_accuracy)
        _write_html_poly_section(io, report.polynomial_feasibility;
            t_eval = report.derivative_accuracy.t_eval,
            interpolator_name = report.derivative_accuracy.interpolator_name)
        _write_html_sens_section(io, report.sensitivity)
        if !isnothing(report.error_budget)
            _write_html_error_budget_section(io, report.error_budget)
        end
        if !isnothing(uq_report)
            _write_html_uq_section(io, uq_report; uq_interpolants = uq_interps)
        end
        _write_html_footer(io)
    end
    @info "[DIAGNOSE] HTML report: $path"
end

"""
    _save_comprehensive_html(comp::ComprehensiveDiagnosticReport; pep=nothing)

Generate a self-contained HTML report with the interpolator×point grid
and collapsible detail sections for a ComprehensiveDiagnosticReport.
When `pep` is provided, includes SVG trajectory plots.
"""
function _save_comprehensive_html(comp::ComprehensiveDiagnosticReport; pep = nothing,
    estimation_report::Union{Nothing, EstimationResultsReport} = nothing,
    data_config::Union{Nothing, NamedTuple} = nothing)
    dir = joinpath("artifacts", "diagnostics", comp.model_name)
    mkpath(dir)
    path = joinpath(dir, "report.html")
    r = comp.best

    # Compute UQ if sensitivity matrix is available
    uq_report = nothing
    local_uq_report = nothing
    uq_interps = nothing
    if !isnothing(pep) && !isempty(r.sensitivity.data_sensitivity_matrix)
        try
            # Use agp_gpr_uq so the SAME GP provides derivatives to UQ as to estimation
            setup_data = setup_parameter_estimation(pep; interpolator = agp_gpr_uq, nooutput = true)
            result = diagnose_uncertainty(pep, setup_data, comp.best_eval_point, r.sensitivity)
            if !isnothing(result)
                local_uq_report, uq_interps = result
                uq_report = local_uq_report
                uq_interp_name = "agp_gpr_uq"
                if comp.best_interpolator != uq_interp_name
                    push!(uq_report.warnings,
                        "UQ covariance was computed with $(uq_interp_name), while the best diagnostic interpolator was $(comp.best_interpolator). The covariance section therefore uses a different interpolator family than the best-fit derivative audit.")
                end
                @info "[DIAGNOSE] UQ computed: max CV = $(_fmt_pct(uq_report.max_cv)), status = $(uq_report.status)"
            end
        catch e
            @warn "[DIAGNOSE] UQ computation failed (non-fatal): $e"
        end
    end

    # Compute physical-coordinate UQ and the legacy IC-only backsolve report if
    # we have both estimation results and local UQ.
    backsolve_uq = nothing
    if !isnothing(estimation_report) && !isnothing(local_uq_report) && !isnothing(pep)
        try
            backsolve_uq = propagate_backsolve_uncertainty(pep, estimation_report.best_result, local_uq_report)
            if !isnothing(backsolve_uq) && backsolve_uq.success
                @info "[DIAGNOSE] Backsolve UQ: amplification = $(round(backsolve_uq.amplification; sigdigits=3))"
            end
            uq_report = physicalize_uncertainty_report(pep, estimation_report.best_result, local_uq_report)
            if !isnothing(uq_report.backsolve_transform)
                @info "[DIAGNOSE] Physical UQ: coordinate_system=$(uq_report.coordinate_system), transform=$(uq_report.backsolve_transform.status), amplification=$(round(uq_report.backsolve_transform.amplification; sigdigits=3))"
            end
        catch e
            @warn "[DIAGNOSE] Physical/backsolve UQ failed (non-fatal): $e"
        end
    end

    open(path, "w") do io
        _write_html_header(io, comp.model_name, r.difficulty, r.bottleneck, r.timestamp;
            best_interp = comp.best_interpolator, best_point = comp.best_eval_point)

        _write_html_executive_summary(io, comp; pep = pep, uq = uq_report,
            estimation_report = estimation_report, data_config = data_config)

        # Model overview + trajectories (visual context before numerics)
        if !isnothing(pep)
            _write_html_model_overview_section(io, pep)
            _write_html_trajectory_section(io, pep; uq_interpolants = uq_interps,
                estimated_result = !isnothing(estimation_report) ? estimation_report.best_result : nothing)
        end

        # Grid section
        _write_html_grid_section(io, comp)

        if !isnothing(comp.multipoint_analysis)
            _write_html_multipoint_selection_section(io, comp.multipoint_analysis)
        end

        # Best-combination detail sections
        _write_html_deriv_section(io, r.derivative_accuracy; label = "Best Combination")
        _write_html_poly_section(io, r.polynomial_feasibility;
            t_eval = comp.best_eval_point, interpolator_name = comp.best_interpolator)
        _write_html_sens_section(io, r.sensitivity)
        if !isnothing(r.error_budget)
            _write_html_error_budget_section(io, r.error_budget)
        end

        # Multipoint derivative accuracy (per evaluation point)
        if !isempty(comp.multipoint_derivative_accuracy)
            for (i, mp_da) in enumerate(comp.multipoint_derivative_accuracy)
                t_str = @sprintf("%.3f", mp_da.t_eval)
                _write_html_deriv_section(io, mp_da;
                    label = "Multipoint Point $i (t = $t_str)", collapsed = true)
            end
        end

        # Multipoint error budget (standalone section)
        if !isnothing(comp.multipoint_error_budget)
            _write_html_error_budget_section(io, comp.multipoint_error_budget)
        end

        # Multipoint vs single-point comparison (if available)
        if !isnothing(comp.multipoint_error_budget) && !isnothing(r.error_budget)
            _write_html_multipoint_comparison_section(io, r.error_budget, comp.multipoint_error_budget, comp.multipoint_analysis)
        end

        # UQ section
        if !isnothing(uq_report)
            _write_html_uq_section(io, uq_report; uq_interpolants = uq_interps)
        end

        # Estimation results section
        if !isnothing(estimation_report)
            _write_html_estimation_section(io, estimation_report; uq = uq_report)
        end

        # Backsolve UQ section
        if !isnothing(backsolve_uq) && backsolve_uq.success
            _write_html_backsolve_uq_section(io, backsolve_uq)
        end

        # Per-interpolator expandable detail
        _write_html_all_deriv_details(io, comp)

        _write_html_footer(io)
    end
    @info "[DIAGNOSE] HTML report: $path"
end

# ─── HTML building blocks ──────────────────────────────────────────────

function _write_html_header(io, model_name, difficulty, bottleneck, timestamp;
    best_interp = nothing, best_point = nothing)
    println(io, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\">")
    println(io, "<title>Diagnostic: $model_name</title>")
    println(io, _HTML_CSS)
    println(io, "</head><body>")
    println(io, "<h1>Diagnostic Report: <code>$model_name</code></h1>")
    println(io, "<p>$(_difficulty_badge(difficulty)) &nbsp; $bottleneck</p>")
    meta = "<p class=\"meta\">$(Dates.format(timestamp, "yyyy-mm-dd HH:MM:SS"))"
    if !isnothing(best_interp)
        meta *= " &middot; Best: <b>$best_interp</b> at t=$(@sprintf("%.4f", best_point))"
    end
    meta *= "</p>"
    println(io, meta)
end

function _write_html_footer(io)
    println(io, "<p class=\"meta\" style=\"margin-top:2rem;\">Generated by ODEParameterEstimation.jl diagnostic framework</p>")
    println(io, "</body></html>")
end

"""
    _write_html_executive_summary(io, report_or_comp; pep=nothing)

Write a grid of metric cards immediately after the page header.  Accepts either
a `DiagnosticReport` or a `ComprehensiveDiagnosticReport` (uses `.best` in that case).
"""
function _write_html_executive_summary(io, report; pep = nothing, uq = nothing,
    estimation_report::Union{Nothing, EstimationResultsReport} = nothing,
    data_config::Union{Nothing, NamedTuple} = nothing)
    # Normalise to a DiagnosticReport
    r = report isa ComprehensiveDiagnosticReport ? report.best : report

    da = r.derivative_accuracy
    pf = r.polynomial_feasibility
    sr = r.sensitivity

    println(io, "<div class=\"summary-grid\">")

    # ── Card: States / Params / Obs ───────────────────────────────────
    if !isnothing(pep)
        n_states = length(pep.ic)
        n_params = length(pep.p_true)
        n_obs = count(mq -> !startswith(replace(string(mq.lhs), r"\(.*\)" => ""), "_obs_trfn_"),
            pep.measured_quantities)
        println(io, """<div class="metric-card">
  <div class="mc-label">Model Size</div>
  <div class="mc-value">$(n_states)s / $(n_params)p</div>
  <div class="mc-sub">$(n_obs) observable(s)</div>
</div>""")
    end

    # ── Card: Data Configuration ──────────────────────────────────────
    if !isnothing(data_config)
        noise_str = data_config.noise_level > 0 ? "$(_fmt(data_config.noise_level))" : "none"
        t_str = "[$(round(data_config.time_interval[1]; digits=2)), $(round(data_config.time_interval[2]; digits=2))]"
        println(io, """<div class="metric-card">
  <div class="mc-label">Data</div>
  <div class="mc-value" style="font-size:.95rem;">$(data_config.datasize) pts</div>
  <div class="mc-sub">noise: $noise_str &middot; $t_str</div>
</div>""")
    elseif !isnothing(pep) && !isnothing(pep.data_sample)
        n_pts = length(pep.data_sample["t"])
        t_data = pep.data_sample["t"]
        t_str = "[$(round(t_data[1]; digits=2)), $(round(t_data[end]; digits=2))]"
        println(io, """<div class="metric-card">
  <div class="mc-label">Data</div>
  <div class="mc-value" style="font-size:.95rem;">$n_pts pts</div>
  <div class="mc-sub">$t_str</div>
</div>""")
    end

    # ── Card: Identifiability ──────────────────────────────────────────
    if !isnothing(pep)
        if pep.unident_count == 0
            println(io, """<div class="metric-card">
  <div class="mc-label">Identifiability</div>
  <div class="mc-value" style="color:var(--easy);">All ✓</div>
  <div class="mc-sub">structurally identifiable</div>
</div>""")
        else
            println(io, """<div class="metric-card">
  <div class="mc-label">Identifiability</div>
  <div class="mc-value" style="color:var(--moderate);">$(pep.unident_count)</div>
  <div class="mc-sub">unidentifiable</div>
</div>""")
        end
    end

    # ── Card: Best interpolator ────────────────────────────────────────
    interp_display = da.interpolator_name == "unknown" ? "—" : da.interpolator_name
    println(io, """<div class="metric-card">
  <div class="mc-label">Best Interpolator</div>
  <div class="mc-value" style="font-size:.95rem;">$(interp_display)</div>
  <div class="mc-sub">t = $(@sprintf("%.4f", da.t_eval))</div>
</div>""")

    # ── Card: Worst derivative error ───────────────────────────────────
    worst_cls = da.worst_rel_error < 0.01 ? "var(--easy)" : da.worst_rel_error < 0.10 ? "var(--moderate)" : "var(--hard)"
    println(io, """<div class="metric-card">
  <div class="mc-label">Worst Deriv Error</div>
  <div class="mc-value" style="color:$worst_cls;">$(_fmt_pct(da.worst_rel_error))</div>
  <div class="mc-sub">$(isempty(da.worst_obs) ? "" : replace(da.worst_obs, r"\(.*\)" => "") * " ord $(da.worst_order)")</div>
</div>""")

    # ── Card: Jacobian condition number ────────────────────────────────
    cond_color = isnan(sr.jacobian_cond) ? "#333" :
        sr.jacobian_cond < 1e6 ? "var(--easy)" :
        sr.jacobian_cond < 1e12 ? "var(--moderate)" : "var(--hard)"
    println(io, """<div class="metric-card">
  <div class="mc-label">Jacobian κ</div>
  <div class="mc-value" style="color:$cond_color;">$(_fmt(sr.jacobian_cond))</div>
  <div class="mc-sub">rank $(sr.effective_rank) / $(length(sr.singular_values))</div>
</div>""")

    # ── Card: Difficulty badge (large) ─────────────────────────────────
    diff_color = r.difficulty == :easy ? "var(--easy)" :
        r.difficulty == :moderate ? "var(--moderate)" :
        r.difficulty == :hard ? "var(--hard)" : "var(--infeasible)"
    println(io, """<div class="metric-card">
  <div class="mc-label">Difficulty</div>
  <div class="mc-value" style="color:$diff_color;font-size:1.5rem;">$(r.difficulty)</div>
  <div class="mc-sub" style="font-size:.7rem;">$(replace(r.bottleneck[1:min(60,length(r.bottleneck))], "&" => "&amp;", "<" => "&lt;", ">" => "&gt;"))$(length(r.bottleneck) > 60 ? "…" : "")</div>
</div>""")

    # ── Estimation cards (if available) ──────────────────────────────
    if !isnothing(estimation_report)
        err_color = estimation_report.best_error < 0.01 ? "var(--easy)" :
            estimation_report.best_error < 0.10 ? "var(--moderate)" : "var(--hard)"
        println(io, """<div class="metric-card">
  <div class="mc-label">Best Error</div>
  <div class="mc-value" style="color:$err_color;">$(_fmt(estimation_report.best_error))</div>
  <div class="mc-sub">$(estimation_report.n_results) solution(s)</div>
</div>""")
        println(io, """<div class="metric-card">
  <div class="mc-label">Estimation Time</div>
  <div class="mc-value" style="font-size:.95rem;">$(round(estimation_report.estimation_time_seconds; digits=1))s</div>
  <div class="mc-sub">full pipeline</div>
</div>""")
    end

    # ── UQ card (if available) ────────────────────────────────────────
    if !isnothing(uq)
        _write_html_uq_summary_cards(io, uq)
    end

    println(io, "</div>")  # close summary-grid
end

"""
    _pretty_name(s::String) → String

Convert a raw symbolic variable name into a readable HTML snippet.

Rules applied (in order):
1. Strip `(t)` suffix (e.g. `x1(t)` → `x1`)
2. Detect `Differential(t, N)(var(t))` patterns and render as prime notation
   - N=1 → `var&prime;`   (′)
   - N=2 → `var&Prime;`   (″)
   - N=3 → `var&#8243;`   (‴)
   - N≥4 → `d<sup>N</sup>var/dt<sup>N</sup>`
3. Convert trailing digit sequence to subscript: `x12` → `x<sub>12</sub>`
4. Keeps the raw name available as a `title` attribute for tooltips when wrapped
   in `<span title="...">`.

For Jacobian/sensitivity matrix headers, callers should wrap with:
  `<span title="RAW_NAME">PRETTY_NAME</span>`
"""
function _pretty_name(s::AbstractString)::String
    # Strip outer whitespace
    raw = strip(s)

    # ── Detect multipoint _ptK suffix: "y1_2_pt2" → pretty(y1_2) + "(pt 2)" ─
    m_mp = match(r"^(.+)_pt(\d+)$", raw)
    if !isnothing(m_mp)
        base_part = _pretty_name(String(m_mp.captures[1]))
        pt_num = m_mp.captures[2]
        return """$base_part <span style="font-size:.75em;color:#656d76;font-style:normal;">(pt $pt_num)</span>"""
    end

    # ── Detect Differential(t, N)(var(t)) pattern ─────────────────────
    m = match(r"^Differential\(t,\s*(\d+)\)\((\w+)\(t\)\)$", raw)
    if !isnothing(m)
        n = parse(Int, m.captures[1])
        var = m.captures[2]
        base = _pretty_name_base(var)
        return if n == 1
            "$(base)&prime;"
        elseif n == 2
            "$(base)&Prime;"
        elseif n == 3
            "$(base)&#8243;"
        else
            "d<sup>$n</sup>$(base)/dt<sup>$n</sup>"
        end
    end

    # ── Strip (t) suffix ──────────────────────────────────────────────
    core = replace(raw, r"\(t\)$" => "")

    # ── Apply base formatting (subscript trailing digits) ─────────────
    return _pretty_name_base(core)
end

"""Apply subscript formatting to trailing digit sequence in a bare name."""
function _pretty_name_base(s::AbstractString)::String
    m = match(r"^(.*?)(\d+)$", s)
    if !isnothing(m)
        base = m.captures[1]
        digits = m.captures[2]
        return "$(base)<sub>$(digits)</sub>"
    end
    return s
end

"""Format a Symbolics expression for HTML display — clean up Differential notation and add spacing."""
function _format_expression(expr)::String
    s = string(expr)
    # Replace Differential(t, N)(var(t)) with dⁿvar/dtⁿ notation
    s = replace(s, r"Differential\(t, 1\)\((\w+)\(t\)\)" => s"d\1/dt")
    s = replace(s, r"Differential\(t, (\d+)\)\((\w+)\(t\)\)" => s"d^\1\2/dt^\1")
    s = replace(s, r"Differential\(t\)\((\w+)\(t\)\)" => s"d\1/dt")
    # Strip (t) from state variables for cleaner display
    s = replace(s, r"(\w+)\(t\)" => s"\1")
    # Add · between coefficient and variable where missing: "582.48delta" → "582.48·delta"
    # But NOT in scientific notation: "7.2e-7" should stay as-is
    s = replace(s, r"(\d)([a-zA-Z_])" => s"\1·\2")
    # Fix scientific notation broken by the above: "7.2·e-7" → "7.2e-7"
    s = replace(s, r"(\d)·e([+-]\d)" => s"\1e\2")
    # Handle number·( patterns: "10.0(" → "10.0·("
    s = replace(s, r"(\d)\(" => s"\1·(")
    # Handle ")variable" patterns: ")E" → ")·E"
    s = replace(s, r"\)(\w)" => s")·\1")
    # But not ")·/" which would be wrong
    s = replace(s, r"\)·/" => s")/")
    # HTML-escape
    s = replace(s, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
    return s
end

"""Format an ODE equation (lhs ~ rhs) for HTML display."""
function _format_ode_equation(eq)::String
    lhs = _format_expression(eq.lhs)
    rhs = _format_expression(eq.rhs)
    return "$lhs = $rhs"
end

"""
Write a collapsible Model Overview section with ODE equations, parameters, states, observables,
identifiability status, and data summary. Placed first in the report.
"""
function _write_html_model_overview_section(io, pep::ParameterEstimationProblem)
    println(io, "<details open><summary>Model Overview</summary><div class=\"detail-body\">")

    # ODE Equations
    println(io, "<h3 style=\"margin-top:0\">ODE Equations</h3>")
    eqs = try
        ModelingToolkit.equations(pep.model.system)
    catch
        []
    end
    if !isempty(eqs)
        println(io, "<ol style=\"font-family:monospace;font-size:.85rem;line-height:1.6;\">")
        for eq in eqs
            eq_str = _format_ode_equation(eq)
            println(io, "<li>$eq_str</li>")
        end
        println(io, "</ol>")
    else
        println(io, "<p class=\"meta\">No equations available</p>")
    end

    # Two-column grid: States & ICs | Parameters & True Values
    println(io, "<div class=\"overview-grid\">")

    # States & ICs
    println(io, "<div>")
    println(io, "<h3>States &amp; Initial Conditions</h3>")
    println(io, "<table><tr><th>State</th><th>IC Value</th></tr>")
    for (s, v) in pep.ic
        raw = string(s)
        raw_esc = replace(raw, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        pretty = _pretty_name(raw)
        println(io, "<tr><td><span title=\"$raw_esc\" class=\"math\">$pretty</span></td><td>$(_fmt(v))</td></tr>")
    end
    println(io, "</table></div>")

    # Parameters & True Values
    println(io, "<div>")
    println(io, "<h3>Parameters &amp; True Values</h3>")
    println(io, "<table><tr><th>Parameter</th><th>True Value</th></tr>")
    for (p, v) in pep.p_true
        raw = string(p)
        raw_esc = replace(raw, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        pretty = _pretty_name(raw)
        println(io, "<tr><td><span title=\"$raw_esc\" class=\"math\">$pretty</span></td><td>$(_fmt(v))</td></tr>")
    end
    println(io, "</table></div>")

    println(io, "</div>")  # close overview-grid

    # Observables
    println(io, "<h3>Observables</h3>")
    println(io, "<ul style=\"font-family:monospace;font-size:.85rem;\">")
    for mq in pep.measured_quantities
        lhs_raw = string(mq.lhs)
        lhs_pretty = _pretty_name(lhs_raw)
        rhs_str = _format_expression(mq.rhs)
        println(io, "<li><span class=\"math\">$lhs_pretty</span> = $rhs_str</li>")
    end
    println(io, "</ul>")

    # Identifiability badge
    if pep.unident_count == 0
        println(io, "<p><span class=\"badge badge-easy\">All identifiable</span></p>")
    else
        println(io, "<p><span class=\"badge badge-moderate\">$(pep.unident_count) unidentifiable</span></p>")
    end

    # Data summary
    if !isnothing(pep.data_sample) && haskey(pep.data_sample, "t")
        t_vec = pep.data_sample["t"]
        n_pts = length(t_vec)
        t_min = @sprintf("%.4f", first(t_vec))
        t_max = @sprintf("%.4f", last(t_vec))
        println(io, "<p class=\"meta\">Data: $n_pts points over [$t_min, $t_max]</p>")
    end

    println(io, "</div></details>")
end

function _write_html_deriv_section(io, da::DerivativeAccuracyReport; label = "", collapsed = false)
    title = isempty(label) ? "Derivative Accuracy (t = $(@sprintf("%.4f", da.t_eval)))" :
        "Derivative Accuracy — $label (t = $(@sprintf("%.4f", da.t_eval)))"
    open_attr = collapsed ? "" : " open"
    println(io, "<details$open_attr><summary>$title</summary><div class=\"detail-body\">")
    # Provenance annotation
    interp_label = da.interpolator_name == "unknown" ? "" : "Interpolator: <b>$(da.interpolator_name)</b><br>"
    println(io, """<div class="provenance">$(interp_label)"True Value" = oracle Taylor coefficients at the exact ODE solution (machine precision).<br>"Interpolant" = value from the production interpolation method.</div>""")
    println(io, "<table><tr><th>Observable</th><th>Order</th><th>True Value</th><th>Interpolant</th><th>Rel Error</th></tr>")
    for e in da.entries
        cls = _err_class(e.rel_error)
        obs_raw_esc = replace(e.obs, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        obs_pretty = _pretty_name(e.obs)
        println(io, "<tr><td><span title=\"$obs_raw_esc\" class=\"math\">$obs_pretty</span></td><td>$(e.order)</td><td>$(_fmt(e.true_val))</td><td>$(_fmt(e.interp_val))</td><td class=\"$cls\">$(_fmt_pct(e.rel_error))</td></tr>")
    end
    println(io, "</table>")
    worst_pretty = _pretty_name(da.worst_obs)
    worst_raw_esc = replace(da.worst_obs, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
    println(io, "<p class=\"meta\">Worst: <b><span title=\"$worst_raw_esc\">$worst_pretty</span></b> order $(da.worst_order) — $(_fmt_pct(da.worst_rel_error))</p>")
    println(io, "</div></details>")
end

function _derivative_grid_lookup(comp::ComprehensiveDiagnosticReport)
    lookup = Dict{Tuple{String, Float64}, DerivativeAccuracyReport}()
    for dr in comp.derivative_grid
        lookup[(dr.interpolator_name, dr.t_eval)] = dr
    end
    return lookup
end

function _write_html_poly_section(io, pf::PolynomialFeasibilityReport;
    pep = nothing, t_eval::Float64 = NaN, interpolator_name::String = "")
    println(io, "<details><summary>Polynomial Feasibility ($(pf.n_equations) eqs × $(pf.n_variables) vars)</summary><div class=\"detail-body\">")
    # Provenance annotation
    prov_parts = String[]
    if !isnan(t_eval)
        push!(prov_parts, "SI template polynomial system instantiated at shooting point t = $(@sprintf("%.4f", t_eval)).")
    end
    if !isempty(interpolator_name)
        push!(prov_parts, "\"Perfect\" = oracle Taylor interpolants (exact data); \"Production\" = <b>$interpolator_name</b>.")
    else
        push!(prov_parts, "\"Perfect\" = oracle Taylor interpolants (exact data); \"Production\" = production interpolation method.")
    end
    println(io, """<div class="provenance">$(join(prov_parts, "<br>"))</div>""")
    println(io, "<dl class=\"kv\">")
    println(io, "<dt>Square</dt><dd>$(pf.is_square)</dd>")
    println(io, "<dt>Solutions (perfect)</dt><dd>$(pf.n_solutions_perfect)</dd>")
    println(io, "<dt>Solutions (production)</dt><dd>$(pf.n_solutions_production)</dd>")
    println(io, "<dt>True residual (perfect)</dt><dd>$(_fmt(pf.true_residual_perfect))</dd>")
    println(io, "<dt>True residual (production)</dt><dd>$(_fmt(pf.true_residual_production))</dd>")
    println(io, "<dt>Closest distance (perfect)</dt><dd>$(_fmt(pf.closest_distance_perfect))</dd>")
    println(io, "<dt>Closest distance (production)</dt><dd>$(_fmt(pf.closest_distance_production))</dd>")
    println(io, "</dl>")
    if !isempty(pf.variable_names)
        pretty_vars = ["""<span title="$(replace(v, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;"))" class="math">$(_pretty_name(v))</span>""" for v in pf.variable_names]
        println(io, "<details><summary>Variable names ($(length(pf.variable_names)))</summary><div class=\"detail-body\">$(join(pretty_vars, ", "))</div></details>")
    end
    # Color-coded equations
    if !isempty(pf.equation_strings)
        _write_html_equation_section(io, pf)
    end
    println(io, "</div></details>")
end

# ─── HTML color-coded equation helpers ────────────────────────────────

const _HTML_ROLE_COLORS = Dict{Symbol, String}(
    :parameter => "#0969da",       # blue
    :state_ic => "#1a7f37",        # green
    :state_at_eval => "#6f42c1",    # violet
    :state_derivative => "#bf8700", # amber
    :data_derivative => "#0550ae",  # teal/cyan
    :transcendental => "#8250df",   # purple
)

"""Write a collapsible section with all equations, color-coded by variable role."""
function _write_html_equation_section(io, pf::PolynomialFeasibilityReport)
    println(io, "<details><summary>Polynomial Equations ($(length(pf.equation_strings)))</summary><div class=\"detail-body\">")

    # Legend
    println(io, "<p style=\"font-size:.8rem;margin-bottom:.5rem;\">")
    for (role, label) in sort(collect(_ROLE_LABELS); by = first)
        color = get(_HTML_ROLE_COLORS, role, "#333")
        print(io, """<span style="color:$color;font-weight:600;">&#9632; $label</span> &nbsp; """)
    end
    println(io, "</p>")

    # Equations
    println(io, "<ol style=\"font-family:monospace;font-size:.82rem;line-height:1.6;\">")
    for eq_str in pf.equation_strings
        print(io, "<li>")
        _write_html_color_coded_equation(io, eq_str, pf.variable_roles)
        println(io, "</li>")
    end
    println(io, "</ol>")
    println(io, "</div></details>")
end

"""Write a single equation with colored <span> tags per variable."""
function _write_html_color_coded_equation(io, eq_str::String, var_roles::Dict{String, Symbol})
    tokens = _tokenize_equation(eq_str)
    for (token, is_var) in tokens
        esc_token = replace(token, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        if is_var && haskey(var_roles, token)
            color = get(_HTML_ROLE_COLORS, var_roles[token], "#333")
            print(io, """<span style="color:$color;font-weight:600;">$esc_token</span>""")
        else
            print(io, esc_token)
        end
    end
end

function _write_html_sens_section(io, sr::SensitivityReport)
    println(io, "<details><summary>Sensitivity Analysis</summary><div class=\"detail-body\">")
    # Provenance annotation
    eval_point = sr.value_source === :estimate ?
        "the ESTIMATE (θ̂, x̂ jets, GP interpolant data jets)" : "true values"
    println(io, """<div class="provenance">J = ∂F/∂x evaluated at $(eval_point), where F = SI polynomial system, x = unknowns (params, ICs, state derivatives).<br>Condition number κ = σ_max / σ_min bounds worst-case error amplification: ‖δx‖/‖x‖ ≤ κ · ‖δd‖/‖d‖.<br>The <b>Parameter–Data Sensitivity</b> matrix below gives the actual per-variable amplification via the implicit function theorem.</div>""")
    println(io, "<dl class=\"kv\">")
    println(io, "<dt>Evaluation point</dt><dd>$(sr.value_source)</dd>")
    cond_cls = isnan(sr.jacobian_cond) ? "" : sr.jacobian_cond < 1e6 ? "err-ok" : sr.jacobian_cond < 1e12 ? "err-warn" : "err-bad"
    println(io, "<dt>Jacobian condition</dt><dd class=\"$cond_cls\">$(_fmt(sr.jacobian_cond))</dd>")
    println(io, "<dt>Effective rank</dt><dd>$(sr.effective_rank) / $(length(sr.singular_values))</dd>")
    if !isnan(sr.root_sensitivity)
        println(io, "<dt>Root sensitivity</dt><dd>$(_fmt(sr.root_sensitivity))</dd>")
    end
    println(io, "</dl>")
    if !isempty(sr.singular_values)
        println(io, "<details><summary>Singular value spectrum ($(length(sr.singular_values)))</summary><div class=\"detail-body\">")
        println(io, "<table><tr><th>#</th><th>σ</th><th>σ / σ_max</th></tr>")
        smax = sr.singular_values[1]
        for (i, sv) in enumerate(sr.singular_values)
            ratio = smax > 0 ? sv / smax : NaN
            cls = ratio < 1e-10 ? "err-bad" : ratio < 1e-6 ? "err-warn" : ""
            println(io, "<tr><td>$i</td><td>$(_fmt(sv))</td><td class=\"$cls\">$(_fmt(ratio))</td></tr>")
        end
        println(io, "</table></div></details>")
    end
    # Full Jacobian matrix (if captured)
    if length(sr.jacobian_matrix) > 0 && !isempty(sr.jacobian_col_labels)
        n_rows, n_cols = size(sr.jacobian_matrix)
        default_open = n_rows <= 16 && n_cols <= 16
        open_attr = default_open ? " open" : ""
        println(io, "<details$open_attr><summary>Full Jacobian Matrix ∂F/∂x ($(n_rows) × $(n_cols))</summary><div class=\"detail-body\">")
        _write_html_jacobian_table(io, sr)
        println(io, "</div></details>")
    end
    # Data sensitivity matrix: dx*/dd via implicit function theorem
    if length(sr.data_sensitivity_matrix) > 0 && !isempty(sr.data_sensitivity_data_labels)
        _write_html_data_sensitivity_section(io, sr)
    end
    println(io, "</div></details>")
end

"""
Write the parameter-data sensitivity matrix S = -(∂F/∂x)⁻¹·(∂F/∂d) as a labeled
HTML table with heatmap coloring. S[i,j] = how much unknown i shifts per unit
perturbation of data variable j.
"""
function _write_html_data_sensitivity_section(io, sr::SensitivityReport)
    S = sr.data_sensitivity_matrix
    n_unknowns, n_data = size(S)
    max_abs = maximum(abs, S; init = 1e-300)

    # Summary statistics
    max_amp = @sprintf("%.2e", max_abs)
    println(io, "<details open><summary>Parameter–Data Sensitivity dx*/dd ($(n_unknowns) × $(n_data))</summary><div class=\"detail-body\">")
    println(io, """<div class="provenance">S = -(∂F/∂x)<sup>-1</sup>·(∂F/∂d) via implicit function theorem.<br>S[i,j] = displacement in unknown i per unit error in data variable j.<br>Max amplification: <b>$max_amp</b></div>""")

    # Per-unknown sensitivity summary (which unknown is most affected?)
    row_max = [maximum(abs, S[i, :]; init = 0.0) for i in 1:n_unknowns]
    # Use data_sensitivity_unknown_labels (correct for the S matrix) with fallback to jacobian_col_labels
    unknown_labels = if !isempty(sr.data_sensitivity_unknown_labels)
        sr.data_sensitivity_unknown_labels
    else
        sr.jacobian_col_labels
    end
    unknown_roles_dict = if !isempty(sr.data_sensitivity_unknown_roles)
        sr.data_sensitivity_unknown_roles
    else
        sr.jacobian_col_roles
    end
    col_labels = sr.data_sensitivity_data_labels

    if length(unknown_labels) != n_unknowns
        @warn "[HTML] Data sensitivity row label count ($(length(unknown_labels))) != matrix rows ($n_unknowns)"
    end

    # Sort unknowns by sensitivity (most sensitive first) for the summary
    sorted_idx = sortperm(row_max; rev = true)
    println(io, "<h4 style=\"margin-top:.5rem;\">Most sensitive unknowns</h4>")
    println(io, "<table><tr><th>Unknown</th><th>Role</th><th>Max |S|</th><th>Most sensitive to</th></tr>")
    n_show = min(8, n_unknowns)
    for k in 1:n_show
        i = sorted_idx[k]
        uname = i <= length(unknown_labels) ? unknown_labels[i] : "x_$i"
        role = get(unknown_roles_dict, uname, :unknown)
        role_label = get(_ROLE_LABELS, role, string(role))
        role_color = get(_HTML_ROLE_COLORS, role, "#333")
        max_s = row_max[i]
        # Find which data var this unknown is most sensitive to
        j_max = argmax(abs.(S[i, :]))
        dname = j_max <= length(col_labels) ? col_labels[j_max] : "d_$j_max"
        cls = max_s > 100.0 ? "err-bad" : max_s > 10.0 ? "err-warn" : "err-ok"
        uname_esc = replace(uname, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        upretty = _pretty_name(uname)
        dname_esc = replace(dname, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        dpretty = _pretty_name(dname)
        println(io, """<tr><td><span title="$uname_esc" style="color:$role_color;font-weight:600;" class="math">$upretty</span></td><td>$role_label</td><td class="$cls">$(_fmt(max_s))</td><td><span title="$dname_esc" class="math">$dpretty</span></td></tr>""")
    end
    println(io, "</table>")

    # Full matrix (collapsible for large systems)
    default_open = n_unknowns <= 12 && n_data <= 12
    open_attr = default_open ? " open" : ""
    println(io, "<details$open_attr><summary>Full Sensitivity Matrix ($(n_unknowns) × $(n_data))</summary><div class=\"detail-body\">")

    # Role legend
    println(io, "<p style=\"font-size:.8rem;margin-bottom:.5rem;\">Columns = data variables (interpolated observable derivatives). Rows = unknowns.</p>")

    println(io, "<div class=\"jac-wrap\"><table class=\"jac-table\">")

    # Column headers (data variable names, rotated)
    print(io, "<tr><th></th>")
    for dname in col_labels
        drole = get(sr.data_sensitivity_data_roles, dname, :data_derivative)
        color = get(_HTML_ROLE_COLORS, drole, "#0550ae")
        esc_name = replace(dname, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        dpretty = _pretty_name(dname)
        print(io, """<th class="jac-col-header" style="color:$color;" title="$esc_name"><span title="$esc_name">$dpretty</span></th>""")
    end
    println(io, "</tr>")

    # Data rows (one per unknown)
    for i in 1:n_unknowns
        uname = i <= length(unknown_labels) ? unknown_labels[i] : "x_$i"
        role = get(unknown_roles_dict, uname, :unknown)
        color = get(_HTML_ROLE_COLORS, role, "#333")
        esc_name = replace(uname, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        upretty = _pretty_name(uname)
        print(io, """<tr><th style="color:$color;font-weight:600;" title="$esc_name" class="math">$upretty</th>""")
        for j in 1:n_data
            _write_jacobian_cell(io, S[i, j], max_abs)
        end
        println(io, "</tr>")
    end

    println(io, "</table></div>")
    println(io, "</div></details>")
    println(io, "</div></details>")
end

# ─── Error Budget HTML ────────────────────────────────────────────────

"""
    _err_class_ratio(r::Float64) → String

CSS class for a prediction ratio value. Green if within 0.1–10×, yellow 10–100×, red otherwise.
"""
function _err_class_ratio(r::Float64)
    (isnan(r) || isinf(r)) && return "err-bad"
    ra = abs(r)
    return ra >= 0.1 && ra <= 10.0 ? "err-ok" : ra <= 100.0 ? "err-warn" : "err-bad"
end

"""
    _write_html_error_budget_section(io, eb::ErrorBudgetReport)

Render the error budget as an HTML section with a summary table and collapsible
per-unknown blame breakdowns.
"""
function _write_html_error_budget_section(io, eb::ErrorBudgetReport)
    mode_str = eb.mode == :multipoint ? "Multipoint" : "Single-Point"
    t_str = eb.t_eval isa Vector ? join([@sprintf("%.4f", t) for t in eb.t_eval], ", ") : @sprintf("%.4f", eb.t_eval)

    println(io, "<details open><summary>IFT Error Budget ($mode_str)</summary><div class=\"detail-body\">")

    # Build rich provenance text
    prov = """<div class="provenance">
<b>What this shows:</b> The Implicit Function Theorem (IFT) predicts how errors in interpolated data (Δd = d<sub>prod</sub> − d<sub>true</sub>) propagate to errors in estimated parameters/states (Δx = x<sub>HC</sub> − x<sub>true</sub>) via the sensitivity matrix S.<br>
<b>Formula:</b> Δx<sub>predicted</sub> = S · Δd. If |predicted|/|actual| ≈ 1, the linearization is accurate. The nonlinearity metric below is ‖Δx<sub>predicted</sub> − Δx<sub>actual</sub>‖ / ‖Δx<sub>actual</sub>‖.<br>
<b>Max derivative order in data:</b> $(eb.max_deriv_order_used). <b>Interpolator:</b> $(eb.interpolator_name)."""

    if eb.mode == :multipoint && eb.t_eval isa Vector && length(eb.t_eval) >= 2
        prov *= """<br><b>Evaluation points:</b> Point 1: t = $(@sprintf("%.3f", eb.t_eval[1])) (variables without suffix). Point 2: t = $(@sprintf("%.3f", eb.t_eval[2])) (variables marked <span style="color:#656d76;">(pt 2)</span>)."""
    else
        prov *= """<br><b>Evaluation point:</b> t = $t_str."""
    end
    prov *= "</div>"
    println(io, prov)

    # Nonlinearity badge
    if !isnan(eb.sensitivity_nonlinearity)
        nl = eb.sensitivity_nonlinearity
        nl_cls = nl < 0.1 ? "err-ok" : nl < 1.0 ? "err-warn" : "err-bad"
        nl_desc = nl < 0.1 ? "Linear regime — IFT predictions reliable" :
                  nl < 1.0 ? "Mildly nonlinear — predictions approximate" :
                  "Highly nonlinear — predictions unreliable"
        println(io, """<dl class="kv"><dt>Nonlinearity</dt><dd class="$nl_cls">$(@sprintf("%.2f", nl)) — $nl_desc</dd>""")
        println(io, """<dt>Sensitivity concentration</dt><dd>$(@sprintf("%.1f%%", eb.sensitivity_concentration * 100))</dd></dl>""")
    end

    if eb.is_pathological
        println(io, """<div style="background:#fff3cd;border:1px solid #bf8700;border-radius:6px;padding:.5rem .75rem;margin:.5rem 0;font-size:.85rem;"><b style="color:#cf222e;">⚠ Pathological sensitivity concentration</b> — one data variable dominates >50% of the sensitivity matrix.</div>""")
    end

    # Multipoint polynomial system summary
    if eb.mode == :multipoint
        n_solve = length(eb.entries)
        n_data = length(eb.data_labels)
        println(io, """<dl class="kv"><dt>Polynomial system</dt><dd>$(n_solve) unknowns × $(n_data) data vars (max order $(eb.max_deriv_order_used))</dd></dl>""")
    end

    if isempty(eb.entries)
        println(io, "<p>No error budget entries.</p></div></details>")
        return
    end

    # Summary stats
    n_well = count(e -> !isnan(e.prediction_ratio) && 0.5 <= e.prediction_ratio <= 2.0, eb.entries)
    n_with_actual = count(e -> !isnan(e.delta_x_actual), eb.entries)
    if n_with_actual > 0
        println(io, """<p style="font-size:.85rem;margin:.25rem 0;">IFT accuracy: <b>$n_well / $n_with_actual</b> unknowns have |predicted|/|actual| within 0.5–2×.</p>""")
    end

    # Main table: signed Δx
    println(io, "<table>")
    println(io, "<tr><th>Unknown</th><th>Role</th><th>Δx<sub>actual</sub></th><th>Δx<sub>predicted</sub></th><th>|pred|/|actual|</th></tr>")

    for entry in eb.entries
        role_label = get(_ROLE_LABELS, entry.unknown_role, string(entry.unknown_role))
        role_color = get(_HTML_ROLE_COLORS, entry.unknown_role, "#333")
        upretty = _pretty_name(entry.unknown_label)
        uesc = replace(entry.unknown_label, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")

        abs_pred = abs(entry.delta_x_predicted)
        abs_act = abs(entry.delta_x_actual)
        pred_cls = abs_pred < 1e-3 ? "err-ok" : abs_pred < 1e-1 ? "err-warn" : "err-bad"
        actual_cls = isnan(entry.delta_x_actual) ? "" : abs_act < 1e-3 ? "err-ok" : abs_act < 1e-1 ? "err-warn" : "err-bad"
        ratio_cls = _err_class_ratio(entry.prediction_ratio)
        actual_str = isnan(entry.delta_x_actual) ? "—" : _fmt(entry.delta_x_actual)
        pred_str = _fmt(entry.delta_x_predicted)
        ratio_str = isnan(entry.prediction_ratio) ? "—" : @sprintf("%.2f×", entry.prediction_ratio)

        # Collapsible row with blame detail
        println(io, "<tr><td colspan=\"5\" style=\"padding:0;\">")
        println(io, "<details><summary style=\"display:grid;grid-template-columns:1fr .6fr 1fr 1fr .8fr;padding:4px 10px;cursor:pointer;\">")
        println(io, """<span title="$uesc" style="color:$role_color;font-weight:600;text-align:left;" class="math">$upretty</span>""")
        println(io, """<span style="text-align:right;">$role_label</span>""")
        println(io, """<span class="$actual_cls" style="text-align:right;">$actual_str</span>""")
        println(io, """<span class="$pred_cls" style="text-align:right;">$pred_str</span>""")
        println(io, """<span class="$ratio_cls" style="text-align:right;">$ratio_str</span>""")
        println(io, "</summary>")

        # Signed blame breakdown
        if !isempty(entry.blame)
            println(io, "<div style=\"padding:4px 20px 8px;\">")
            println(io, "<table style=\"width:auto;margin:0;\"><tr><th>Data Variable</th><th>S·Δd (signed)</th><th>% of Δx<sub>pred</sub></th></tr>")
            for b in entry.blame
                dpretty = _pretty_name(b.data_label)
                desc = replace(b.data_label, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
                pct_str = @sprintf("%+.1f%%", b.pct_of_predicted * 100)
                sign_color = b.s_times_dd >= 0 ? "#1a7f37" : "#cf222e"
                bar_w = max(1, round(Int, abs(b.pct_of_predicted) * 200))
                println(io, """<tr><td><span title="$desc" class="math">$dpretty</span></td><td style="color:$sign_color;">$(_fmt(b.s_times_dd))</td><td>$pct_str <span style="display:inline-block;height:8px;width:$(bar_w)px;background:$sign_color;border-radius:2px;vertical-align:middle;"></span></td></tr>""")
            end
            println(io, "</table></div>")
        end
        println(io, "</details></td></tr>")
    end
    println(io, "</table>")

    # Data variable table: d_true, d_prod, Δd
    if !isempty(eb.delta_d) && !isempty(eb.data_labels)
        println(io, "<details><summary>Data Variables: d<sub>true</sub> vs d<sub>prod</sub></summary><div class=\"detail-body\">")
        println(io, """<div class="provenance">d<sub>true</sub> = exact (oracle) derivative value from high-precision ODE solve. d<sub>prod</sub> = production interpolant value. Δd = d<sub>prod</sub> − d<sub>true</sub> (signed interpolation error).<br>Sorted by |Δd| descending. Higher derivative orders typically have larger errors because interpolation accuracy degrades with order.</div>""")
        println(io, "<table><tr><th>Data Variable</th><th>Order</th><th>d<sub>true</sub></th><th>d<sub>prod</sub></th><th>Δd (signed)</th></tr>")
        sorted_idx = sortperm(abs.(eb.delta_d); rev = true)
        for j in sorted_idx
            j > length(eb.data_labels) && continue
            dlabel = eb.data_labels[j]
            dpretty = _pretty_name(dlabel)
            desc = replace(dlabel, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            order = _multipoint_var_order(dlabel)
            dd = eb.delta_d[j]
            dt = j <= length(eb.data_true) ? eb.data_true[j] : NaN
            dp = j <= length(eb.data_prod) ? eb.data_prod[j] : NaN
            abs_dd = abs(dd)
            cls = abs_dd < 1e-10 ? "err-ok" : abs_dd < 1e-6 ? "err-warn" : "err-bad"
            sign_color = dd >= 0 ? "#1a7f37" : "#cf222e"
            println(io, """<tr><td><span title="$desc" class="math">$dpretty</span></td><td>$order</td><td>$(_fmt(dt))</td><td>$(_fmt(dp))</td><td class="$cls" style="color:$sign_color;">$(_fmt(dd))</td></tr>""")
        end
        println(io, "</table></div></details>")
    end

    println(io, "</div></details>")
end

"""
    _write_html_multipoint_comparison_section(io, sp_eb, mp_eb, mpa)

Side-by-side comparison of single-point vs multipoint error budgets.
Shows shared parameters with improvement ratios.
"""
function _write_html_multipoint_comparison_section(
    io,
    sp_eb::ErrorBudgetReport,
    mp_eb::ErrorBudgetReport,
    mpa::Union{Nothing, MultipointDiagnosticAnalysis} = nothing,
)
    sp_t_str = sp_eb.t_eval isa Vector ? join([@sprintf("%.3f", t) for t in sp_eb.t_eval], ", ") : @sprintf("%.3f", sp_eb.t_eval)
    mp_t_str = mp_eb.t_eval isa Vector ? join([@sprintf("%.3f", t) for t in mp_eb.t_eval], ", ") : @sprintf("%.3f", mp_eb.t_eval)
    compare_policy = isnothing(mpa) ? :always_show : mpa.compare_policy
    compare_is_valid = isnothing(mpa) ? true : mpa.compare_is_valid
    compare_reason = isnothing(mpa) ? "" : mpa.compare_invalid_reason

    println(io, "<details open><summary>Single-Point vs Multipoint Error Budget</summary><div class=\"detail-body\">")
    println(io, """<div class="provenance"><b>What this shows:</b> Side-by-side comparison of the IFT-predicted errors (|Δx<sub>predicted</sub>|) from the single-point and multipoint polynomial systems.<br>
<b>Single-point</b> (max order <b>$(sp_eb.max_deriv_order_used)</b>, t = $sp_t_str): uses one time point, requires higher-order derivatives.<br>
<b>Multipoint</b> (max order <b>$(mp_eb.max_deriv_order_used)</b>, t = $mp_t_str): uses 2 time points with shared parameters, reducing the max derivative order needed. Lower order = more accurate interpolation = smaller data errors.<br>
<b>Improvement</b> = |SP predicted| / |MP predicted|. Values >1 mean multipoint predicts smaller errors for that parameter.</div>""")

    if !compare_is_valid
        reason = replace(compare_reason, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        if compare_policy == :gate_invalid
            println(io, """<div style="background:#fff3cd;border:1px solid #bf8700;border-radius:6px;padding:.5rem .75rem;margin:.5rem 0;font-size:.85rem;"><b>Comparison withheld:</b> $reason</div>""")
            println(io, "</div></details>")
            return
        else
            prefix = compare_policy == :warn_only ? "Comparison warning" : "Comparison note"
            println(io, """<div style="background:#fff3cd;border:1px solid #bf8700;border-radius:6px;padding:.5rem .75rem;margin:.5rem 0;font-size:.85rem;"><b>$prefix:</b> $reason</div>""")
        end
    end

    # Build lookup from multipoint entries by clean name
    mp_lookup = Dict{String, ErrorBudgetEntry}()
    for entry in mp_eb.entries
        clean, _ = _parse_multipoint_var_name(entry.unknown_label)
        mp_lookup[clean] = entry
    end

    println(io, "<table>")
    println(io, "<tr><th>Unknown</th><th>Role</th><th>SP Predicted</th><th>MP Predicted</th><th>Improvement</th><th>SP Top Blame</th><th>MP Top Blame</th></tr>")

    # Show shared parameters and state ICs (variables that appear in both)
    n_rows = 0
    for sp_entry in sp_eb.entries
        mp_entry = get(mp_lookup, sp_entry.unknown_label, nothing)
        isnothing(mp_entry) && continue  # per-point state derivs won't match

        role_label = get(_ROLE_LABELS, sp_entry.unknown_role, string(sp_entry.unknown_role))
        role_color = get(_HTML_ROLE_COLORS, sp_entry.unknown_role, "#333")
        upretty = _pretty_name(sp_entry.unknown_label)
        uesc = replace(sp_entry.unknown_label, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")

        sp_abs = abs(sp_entry.delta_x_predicted)
        mp_abs = abs(mp_entry.delta_x_predicted)
        improvement = mp_abs > 1e-300 ? sp_abs / mp_abs : Inf
        imp_str = isinf(improvement) ? "∞" : @sprintf("%.1f×", improvement)
        imp_cls = improvement > 2.0 ? "err-ok" : improvement > 0.5 ? "err-warn" : "err-bad"

        sp_blame_str = isempty(sp_entry.blame) ? "—" : begin
            b = sp_entry.blame[1]
            "$(_pretty_name(b.data_label)) ($(@sprintf("%+.0f%%", b.pct_of_predicted * 100)))"
        end
        mp_blame_str = isempty(mp_entry.blame) ? "—" : begin
            b = mp_entry.blame[1]
            "$(_pretty_name(b.data_label)) ($(@sprintf("%+.0f%%", b.pct_of_predicted * 100)))"
        end

        println(io, """<tr><td><span title="$uesc" style="color:$role_color;font-weight:600;" class="math">$upretty</span></td><td>$role_label</td><td>$(_fmt(sp_abs))</td><td>$(_fmt(mp_abs))</td><td class="$imp_cls" style="font-weight:600;">$imp_str</td><td style="font-size:.8rem;">$sp_blame_str</td><td style="font-size:.8rem;">$mp_blame_str</td></tr>""")
        n_rows += 1
    end

    println(io, "</table>")
    if n_rows == 0
        println(io, """<p class="meta">No overlapping unknown labels were available for a direct single-point vs multipoint comparison.</p>""")
    end

    # Summary
    order_reduction = sp_eb.max_deriv_order_used - mp_eb.max_deriv_order_used
    if order_reduction > 0
        println(io, """<p style="margin-top:.5rem;font-size:.85rem;">Multipoint reduces max derivative order by <b>$order_reduction</b> ($(sp_eb.max_deriv_order_used) → $(mp_eb.max_deriv_order_used)).</p>""")
    elseif order_reduction == 0
        println(io, """<p style="margin-top:.5rem;font-size:.85rem;color:var(--moderate);">⚠ Multipoint did NOT reduce max derivative order (both use order $(sp_eb.max_deriv_order_used)). Rank stripping may have kept the highest-order equations.</p>""")
    end

    println(io, "</div></details>")
end

"""
Write the full labelled Jacobian matrix as an HTML table with color-coded column headers
and heatmap cell backgrounds.
"""
function _write_html_jacobian_table(io, sr::SensitivityReport)
    J = sr.jacobian_matrix
    n_rows, n_cols = size(J)
    max_abs = maximum(abs, J; init = 1e-300)

    # Role legend
    println(io, "<p style=\"font-size:.8rem;margin-bottom:.5rem;\">")
    for (role, label) in sort(collect(_ROLE_LABELS); by = first)
        color = get(_HTML_ROLE_COLORS, role, "#333")
        print(io, """<span style="color:$color;font-weight:600;">&#9632; $label</span> &nbsp; """)
    end
    println(io, "</p>")

    println(io, "<div class=\"jac-wrap\"><table class=\"jac-table\">")

    # Column headers (rotated variable names, color-coded by role)
    print(io, "<tr><th></th>")
    for (ci, col_name) in enumerate(sr.jacobian_col_labels)
        role = get(sr.jacobian_col_roles, col_name, :state_derivative)
        color = get(_HTML_ROLE_COLORS, role, "#333")
        esc_name = replace(col_name, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        pretty = _pretty_name(col_name)
        print(io, """<th class="jac-col-header" style="color:$color;" title="$esc_name"><span title="$esc_name">$pretty</span></th>""")
    end
    println(io, "</tr>")

    # Data rows
    for ri in 1:n_rows
        row_label = ri <= length(sr.jacobian_row_labels) ? sr.jacobian_row_labels[ri] : "Eq $ri"
        print(io, "<tr><th title=\"$row_label\">$row_label</th>")
        for ci in 1:n_cols
            _write_jacobian_cell(io, J[ri, ci], max_abs)
        end
        println(io, "</tr>")
    end

    println(io, "</table></div>")
end

"""Write a single Jacobian cell with heatmap coloring."""
function _write_jacobian_cell(io, val::Float64, max_abs::Float64)
    if abs(val) < 1e-14 * max_abs
        print(io, "<td class=\"jac-zero\">0</td>")
    else
        # Compute log-intensity for background color (0..1 range), based on absolute value
        intensity = clamp(log10(abs(val) / max_abs + 1e-300) / log10(max_abs + 1e-300) + 1.0, 0.0, 1.0)
        alpha = @sprintf("%.2f", 0.08 + 0.22 * intensity)
        # Single color (blue) by magnitude — sign shown in the number, not the color
        bg = "rgba(9,105,218,$alpha)"
        fmt_val = @sprintf("%.1e", val)
        print(io, """<td style="background:$bg;">$fmt_val</td>""")
    end
end

function _write_html_grid_section(io, comp::ComprehensiveDiagnosticReport)
    lookup = _derivative_grid_lookup(comp)
    println(io, "<details open><summary>Interpolator × Evaluation Point Grid</summary><div class=\"detail-body\">")
    println(io, """<div class="provenance">Each cell = max<sub>obs,order</sub> |true − interp| / max(|true|, ε). Green highlight = best combination.</div>""")
    println(io, "<table><tr><th>Interpolator</th>")
    for te in comp.eval_points
        println(io, "<th>t=$(@sprintf("%.2f", te))</th>")
    end
    println(io, "</tr>")

    n_points = length(comp.eval_points)
    for (ii, iname) in enumerate(comp.interpolator_names)
        println(io, "<tr><td>$iname</td>")
        for pi in 1:n_points
            te = comp.eval_points[pi]
            key = (iname, te)
            if haskey(lookup, key)
                dr = lookup[key]
                err = dr.worst_rel_error
                is_best = (iname == comp.best_interpolator && te ≈ comp.best_eval_point)
                cls = _err_class(err) * (is_best ? " best-cell" : "")
                println(io, "<td class=\"$cls\">$(_fmt(err))</td>")
            else
                println(io, "<td>—</td>")
            end
        end
        println(io, "</tr>")
    end
    println(io, "</table></div></details>")
end

function _write_html_all_deriv_details(io, comp::ComprehensiveDiagnosticReport)
    lookup = _derivative_grid_lookup(comp)
    println(io, "<details><summary>All Derivative Accuracy Tables</summary><div class=\"detail-body\">")
    for (ii, iname) in enumerate(comp.interpolator_names)
        for (pi, te) in enumerate(comp.eval_points)
            key = (iname, te)
            if haskey(lookup, key)
                dr = lookup[key]
                _write_html_deriv_section(io, dr;
                    label = "$iname")
            end
        end
    end
    println(io, "</div></details>")
end

function _write_html_multipoint_selection_section(io, mpa::MultipointDiagnosticAnalysis)
    println(io, "<details open><summary>Multipoint Selection & Template Summary</summary><div class=\"detail-body\">")

    times_str = isempty(mpa.selected_t_values) ? "—" : join((@sprintf("%.3f", t) for t in mpa.selected_t_values), ", ")
    cmp_status = mpa.compare_is_valid ? """<span class="badge badge-easy">comparison valid</span>""" :
        """<span class="badge badge-moderate">comparison withheld</span>"""
    println(io, """<div class="provenance"><b>Selection policy:</b> $(mpa.selection_policy). <b>Comparison policy:</b> $(mpa.compare_policy). <b>Selected times:</b> [$times_str]. $cmp_status</div>""")
    println(io, "<dl class=\"kv\">")
    println(io, "<dt>Selection reason</dt><dd>$(replace(mpa.selection_reason, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;"))</dd>")
    println(io, "<dt>Combos examined</dt><dd>$(mpa.candidate_combo_count) total, $(mpa.solved_combo_count) solved</dd>")
    println(io, "<dt>Selected combo</dt><dd>$(mpa.selected_combo_solved ? "solved" : "unsolved") with $(mpa.selected_combo_solution_count) HC solution(s)</dd>")
    println(io, "<dt>Worst derivative error</dt><dd>$(_fmt(mpa.selected_combo_worst_derivative_error))</dd>")
    println(io, "<dt>True residual</dt><dd>$(_fmt(mpa.selected_combo_true_residual))</dd>")
    println(io, "<dt>Closest distance to truth</dt><dd>$(_fmt(mpa.selected_combo_closest_distance))</dd>")
    println(io, "<dt>Actual max derivative order</dt><dd>$(mpa.actual_max_deriv_order)</dd>")
    println(io, "<dt>Template strip summary</dt><dd>$(mpa.total_equation_count) total eqs → $(mpa.stripped_equation_count) kept; $(mpa.solve_var_count) solve vars, $(mpa.data_var_count) data vars</dd>")
    println(io, "</dl>")

    if !mpa.compare_is_valid && !isempty(mpa.compare_invalid_reason)
        reason = replace(mpa.compare_invalid_reason, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        println(io, """<div style="background:#fff3cd;border:1px solid #bf8700;border-radius:6px;padding:.5rem .75rem;margin:.5rem 0;font-size:.85rem;"><b>Comparison withheld:</b> $reason</div>""")
    end

    if !isempty(mpa.actual_data_labels)
        println(io, "<details><summary>Actual Multipoint Data Labels</summary><div class=\"detail-body\">")
        println(io, "<table><tr><th>#</th><th>Label</th><th>Order</th></tr>")
        for (i, label) in enumerate(mpa.actual_data_labels)
            raw = replace(label, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            println(io, "<tr><td>$i</td><td><span title=\"$raw\" class=\"math\">$(_pretty_name(label))</span></td><td>$(_multipoint_var_order(label))</td></tr>")
        end
        println(io, "</table></div></details>")
    end

    println(io, "<details><summary>Template Strip Details</summary><div class=\"detail-body\">")
    println(io, "<p class=\"meta\">Kept equation indices: $(join(mpa.kept_equation_indices, ", "))</p>")
    println(io, "<p class=\"meta\">Dropped equation indices: $(join(mpa.dropped_equation_indices, ", "))</p>")
    if !isempty(mpa.eq_metadata)
        println(io, "<table><tr><th>Kept Row</th><th>Point</th><th>Data-only</th><th>Max Order</th></tr>")
        for (i, meta) in enumerate(mpa.eq_metadata)
            println(io, "<tr><td>$i</td><td>$(meta.point)</td><td>$(meta.is_data)</td><td>$(meta.order)</td></tr>")
        end
        println(io, "</table>")
    end
    println(io, "</div></details>")

    println(io, "</div></details>")
end

# ─── SVG trajectory plots in HTML ─────────────────────────────────────

"""
Write a collapsible "Trajectories" section with SVG plots of observables
(data + ODE curve) and state variables (ODE curve only).
Observable states appear first with a teal left-border accent;
latent states appear after with a gray left-border accent.
"""
function _write_html_trajectory_section(io, pep; uq_interpolants = nothing,
    estimated_result::Union{Nothing, ParameterEstimationResult} = nothing)
    plots = try
        _generate_trajectory_plots(pep; uq_interpolants = uq_interpolants,
            estimated_result = estimated_result)
    catch e
        @warn "[DIAGNOSE] Trajectory plot generation failed: $e"
        Tuple{String, String, Bool}[]
    end
    isempty(plots) && return

    # Separate observable and latent plots
    obs_plots = [(t, s) for (t, s, is_obs) in plots if is_obs]
    lat_plots = [(t, s) for (t, s, is_obs) in plots if !is_obs]

    println(io, "<details open><summary>Trajectories ($(length(plots)) plots)</summary><div class=\"detail-body\">")

    # Observable plots first
    if !isempty(obs_plots)
        println(io, "<p class=\"section-kicker\">Observables</p>")
        for (title, svg) in obs_plots
            println(io, """<div class="plot-card observable">""")
            println(io, """<div class="plot-card-title">$title <span class="badge badge-obs">Observable</span></div>""")
            println(io, """<div class="plot-card-body">$svg</div>""")
            println(io, "</div>")
        end
    end

    # Latent state plots
    if !isempty(lat_plots)
        println(io, "<p class=\"section-kicker\" style=\"margin-top:1rem;\">Latent States</p>")
        for (title, svg) in lat_plots
            println(io, """<div class="plot-card latent">""")
            println(io, """<div class="plot-card-title">$title <span class="badge badge-latent">Latent</span></div>""")
            println(io, """<div class="plot-card-body">$svg</div>""")
            println(io, "</div>")
        end
    end

    println(io, "</div></details>")
end


# ─── UQ HTML rendering (moved from uq_and_reports.jl 2026-06-10: defined where used) ───

"""
Write the UQ section to the HTML report: CI table, correlation matrix,
observation uncertainty, and executive summary cards.
"""
function _write_html_uq_section(io, uq::UncertaintyReport;
    uq_interpolants::Union{Nothing, Dict{String, AGPInterpolatorUQ}} = nothing)
    title = uq.coordinate_system == :physical_initial_conditions ?
        "Physical Parameter/IC Uncertainty" :
        "Local Parameter Uncertainty"
    println(io, "<details open><summary>$title (Estimator Covariance → IFT)</summary><div class=\"detail-body\">")

    # Provenance
    status_badge = if uq.status == :ok
        """<span class="badge badge-easy">OK</span>"""
    elseif uq.status == :wide_ci
        """<span class="badge badge-moderate">Wide CI</span>"""
    else
        """<span class="badge badge-hard">Degenerate</span>"""
    end
    coord_desc = uq.coordinate_system == :physical_initial_conditions ?
        "public coordinates <code>[parameters, initial conditions at t0]</code>" :
        "local algebraic coordinates at <code>t_eval</code>"
    println(io, """<div class="provenance">Σ<sub>x</sub> = S·Σ<sub>d</sub>·S<sup>T</sup> where S = parameter–data sensitivity, Σ<sub>d</sub> = W·Σ<sub>y</sub>·W<sup>T</sup> at t = $(@sprintf("%.4f", uq.t_eval)). Displaying $coord_desc. Covariance: <code>$(uq.covariance_kind)</code>; noise source: <code>$(uq.noise_source)</code>. $status_badge</div>""")

    if !isnothing(uq.backsolve_transform)
        bt = uq.backsolve_transform
        println(io, """<div class="provenance"><b>Backsolve transform:</b> <code>$(bt.status)</code>, t<sub>0</sub> = $(@sprintf("%.4f", bt.t0)), amplification = $(_fmt(bt.amplification)). Source: <code>$(join(bt.source_labels, ", "))</code>. Target: <code>$(join(bt.target_labels, ", "))</code>.</div>""")
    end

    if !isnothing(uq.practical_identifiability_index)
        ia = uq.practical_identifiability_index
        ia_str = isfinite(ia.i_a) ? _fmt(ia.i_a) : "NaN"
        lambda_str = isfinite(ia.lambda_max) ? _fmt(ia.lambda_max) : "NaN"
        labels_str = isempty(ia.labels) ? "none" : join([_pretty_name(x) for x in ia.labels], ", ")
        println(io, """<div class="provenance"><b>I<sub>A</sub></b> = $ia_str (λ<sub>max</sub> = $lambda_str, status = <code>$(ia.status)</code>). Projection labels: <span class="math">$labels_str</span>.</div>""")
    end

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
    println(io, "<h4>Confidence Intervals</h4>")
    println(io, "<table><tr><th>Quantity</th><th>Role</th><th>True Value</th><th>±1σ (68%)</th><th>95% CI (±1.96σ)</th><th>CV</th><th>Status</th></tr>")

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

    if !isnothing(uq.local_coordinate_report)
        local_snapshot = uq.local_coordinate_report
        println(io, "<details><summary>Local IFT Coordinate Audit ($(length(local_snapshot.param_labels)) coordinates at t = $(@sprintf("%.4f", local_snapshot.t_eval)))</summary><div class=\"detail-body\">")
        println(io, """<div class="provenance">These are the direct IFT coordinates before projection/backsolve. Order-0 state labels here are values at t_eval, not initial conditions.</div>""")
        println(io, "<table><tr><th>Local coordinate</th><th>Role</th><th>Coordinate value</th><th>±1σ</th><th>95% CI half-width</th></tr>")
        for i in eachindex(local_snapshot.param_labels)
            label = local_snapshot.param_labels[i]
            raw_esc = replace(label, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            role = get(local_snapshot.param_roles, label, :unknown)
            role_label = get(_ROLE_LABELS, role, string(role))
            role_color = get(_HTML_ROLE_COLORS, role, "#333")
            value = i <= length(local_snapshot.coordinate_values) ? local_snapshot.coordinate_values[i] : NaN
            value_str = isfinite(value) ? _fmt(value) : "—"
            σ = local_snapshot.param_std[i]
            println(io, """<tr><td><span title="$raw_esc" style="color:$role_color;font-weight:600;" class="math">$(_pretty_name(label))</span></td><td>$role_label</td><td>$value_str</td><td>±$(_fmt(σ))</td><td>±$(_fmt(UQ_CI_Z * σ))</td></tr>""")
        end
        println(io, "</table></div></details>")
    end

    if !isnothing(uq.backsolve_transform)
        bt = uq.backsolve_transform
        println(io, "<details><summary>Backsolve Transform Audit</summary><div class=\"detail-body\">")
        println(io, "<table><tr><th>Target \\ Source</th>")
        for label in bt.source_labels
            print(io, "<th class=\"math\">$(_pretty_name(label))</th>")
        end
        println(io, "</tr>")
        for i in eachindex(bt.target_labels)
            println(io, "<tr><th class=\"math\">$(_pretty_name(bt.target_labels[i]))</th>")
            for j in eachindex(bt.source_labels)
                print(io, "<td>$(_fmt(bt.transform_matrix[i, j]))</td>")
            end
            println(io, "</tr>")
        end
        println(io, "</table></div></details>")
    end

    # Observation Uncertainty at Shooting Point
    if !isempty(uq.obs_names)
        println(io, "<details><summary>Observation Jet Estimator at t = $(@sprintf("%.4f", uq.t_eval))</summary><div class=\"detail-body\">")
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
        println(io, """<div class="provenance">Estimated observation noise from GP hyperparameter optimization. The normalized variance is learned on z-scored data; the raw-unit variance multiplies by the observable sample standard deviation squared.</div>""")
        println(io, "<table><tr><th>Observable</th><th>normalized σ<sub>n</sub></th><th>normalized σ<sub>n</sub>²</th><th>raw σ<sub>y</sub></th><th>raw σ<sub>y</sub>²</th></tr>")
        for (obs_name, interp) in sort(collect(uq_interpolants); by = first)
            σ_n = sqrt(max(interp.noise_var, 0.0))
            raw_var = learned_observation_noise_variance(interp)
            raw_σ = sqrt(max(raw_var, 0.0))
            println(io, "<tr><td class=\"math\">$(_pretty_name(obs_name))</td><td>$(_fmt(σ_n))</td><td>$(_fmt(interp.noise_var))</td><td>$(_fmt(raw_σ))</td><td>$(_fmt(raw_var))</td></tr>")
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
    label = uq.coordinate_system == :physical_initial_conditions ? "Max Physical σ" : "Max Local σ"
    println(io, """<div class="metric-card">
  <div class="mc-label">$label</div>
  <div class="mc-value" style="color:$σ_color;">$(_fmt(max_σ))</div>
  <div class="mc-sub">$(_fmt_pct(uq.max_cv)) worst CV</div>
</div>""")
    if !isnothing(uq.practical_identifiability_index)
        ia = uq.practical_identifiability_index
        ia_color = ia.status == :ok ? "var(--easy)" : ia.status == :wide_ci ? "var(--moderate)" : "var(--hard)"
        ia_str = isfinite(ia.i_a) ? _fmt(ia.i_a) : "NaN"
        println(io, """<div class="metric-card">
  <div class="mc-label">I<sub>A</sub></div>
  <div class="mc-value" style="color:$ia_color;">$ia_str</div>
  <div class="mc-sub">normalized estimator covariance</div>
</div>""")
    end
end
