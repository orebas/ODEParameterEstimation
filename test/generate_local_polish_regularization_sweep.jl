using CSV
using Dates
using Statistics

include(joinpath(@__DIR__, "generate_local_polish_standardization_sweep.jl"))

const REGULARIZATION_OUTPUT_ROOT = get(
    ENV,
    "ODEPE_REGULARIZATION_OUTPUT_ROOT",
    joinpath(@__DIR__, "..", "artifacts", "diagnostics", "local_polish_regularization_1em4_hard"),
)
const REGULARIZATION_DEFAULT_LAMBDAS = [0.0, 1e-4, 1e-3, 1e-2, 1e-1]
const REGULARIZATION_MODE = :l2_log
const REGULARIZATION_SCALAR_POLISH_METHOD = ODEPE.PolishBFGS

function _env_override_float(name::AbstractString)
    raw = strip(get(ENV, name, ""))
    isempty(raw) && return nothing
    parsed = tryparse(Float64, raw)
    isnothing(parsed) && error("Invalid $(name) value '$raw'")
    return parsed
end

function _env_override_int(name::AbstractString)
    raw = strip(get(ENV, name, ""))
    isempty(raw) && return nothing
    parsed = tryparse(Int, raw)
    isnothing(parsed) && error("Invalid $(name) value '$raw'")
    return parsed
end

function selected_regularization_method_keys()
    raw = split(get(ENV, "ODEPE_REGULARIZATION_METHOD_KEYS", ""), ",")
    keys = Symbol.(filter(!isempty, strip.(raw)))
    isempty(keys) && return nothing
    return Set(keys)
end

function regularization_lambda_values()
    raw = split(get(ENV, "ODEPE_REGULARIZATION_LAMBDAS", join(string.(REGULARIZATION_DEFAULT_LAMBDAS), ",")), ",")
    values = Float64[]
    for entry in raw
        stripped = strip(entry)
        isempty(stripped) && continue
        parsed = tryparse(Float64, stripped)
        isnothing(parsed) && error("Invalid ODEPE_REGULARIZATION_LAMBDAS entry '$stripped'")
        parsed >= 0.0 || error("Regularization lambda must be nonnegative, got '$stripped'")
        push!(values, parsed)
    end
    isempty(values) && error("No regularization lambda values selected")
    return sort(unique(values))
end

function selected_regularization_case_ids(default_case_ids::Vector{String})
    raw = split(get(ENV, "ODEPE_REGULARIZATION_CASE_IDS", join(default_case_ids, ",")), ",")
    selected = Set(filter(!isempty, strip.(raw)))
    filtered = [case_id for case_id in default_case_ids if case_id in selected]
    isempty(filtered) && error("No regularization cases selected")
    return filtered
end

_lambda_label(λ::Real) = λ == 0.0 ? "0" : @sprintf("%.0e", λ)

function _regularization_method_specs()
    specs = [
        (key = :scalar_log, label = "Scalar log-space"),
        (key = :residual_lso_lm_bounded_log, label = "Bounded LeastSquaresOptim LM log-space"),
        (key = :residual_fastlm_bounded_log, label = "Bounded FastLevenbergMarquardt log-space"),
    ]
    selected = selected_regularization_method_keys()
    isnothing(selected) && return specs
    return filter(spec -> spec.key in selected, specs)
end

function _regularization_scalar_run_opts(run_opts::ODEPE.EstimationOptions)
    overrides = Pair{Symbol, Any}[
        :polish_method => REGULARIZATION_SCALAR_POLISH_METHOD,
        :opt_ad_backend => :forward,
        :nooutput => true,
        :diagnostics => false,
        :polish_solutions => true,
    ]

    maxtime_override = _env_override_float("ODEPE_REGULARIZATION_SCALAR_POLISH_MAXTIME")
    if !isnothing(maxtime_override)
        push!(overrides, :polish_maxtime => maxtime_override)
    end

    ode_maxiters_override = _env_override_int("ODEPE_REGULARIZATION_SCALAR_POLISH_ODE_MAXITERS")
    if !isnothing(ode_maxiters_override)
        push!(overrides, :polish_ode_maxiters => ode_maxiters_override)
    end

    return ODEPE.merge_options(run_opts; overrides...)
end

function _run_regularized_method_report(
    method_key::Symbol,
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    run_opts::ODEPE.EstimationOptions,
    λ::Float64,
)
    if method_key == :scalar_log
        return safe_polish_mode_report(
            pep,
            raw_candidates,
            _regularization_scalar_run_opts(run_opts),
            :log_positive;
            regularization_lambda = λ,
            regularization_mode = REGULARIZATION_MODE,
        )
    elseif method_key == :residual_lso_lm_bounded_log
        return safe_residual_mode_report(
            pep,
            raw_candidates,
            run_opts,
            :log_positive;
            optimizer_factory = () -> LeastSquaresOptim.LevenbergMarquardt(),
            solver_kind = :lso_direct,
            jacobian_mode = :forward,
            bounds_mode = :bounded,
            regularization_lambda = λ,
            regularization_mode = REGULARIZATION_MODE,
            solver_label = "LeastSquaresOptim.optimize!(LevenbergMarquardt(); lower/upper)",
            required_package = :LeastSquaresOptim,
        )
    elseif method_key == :residual_fastlm_bounded_log
        return safe_residual_mode_report(
            pep,
            raw_candidates,
            run_opts,
            :log_positive;
            optimizer_factory = () -> nothing,
            solver_kind = :fastlm_direct,
            jacobian_mode = :forward,
            bounds_mode = :bounded,
            regularization_lambda = λ,
            regularization_mode = REGULARIZATION_MODE,
            solver_label = "FastLevenbergMarquardt.lmsolve!() with lb/ub",
            required_package = :FastLevenbergMarquardt,
        )
    end
    error("Unsupported regularization method key '$method_key'")
end

function _empty_regularization_report(reason::AbstractString, λ::Float64; status::Symbol = :error)
    return Dict{Symbol, Any}(
        :status => status,
        :reason => String(reason),
        :build_and_run_seconds => Inf,
        :regularization_lambda => λ,
        :regularization_mode => REGULARIZATION_MODE,
        :analyzed_candidate_count => 0,
        :polished_pool_count => 0,
        :selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
        :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
        :best_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
        :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
    )
end

function build_regularization_case_artifact(case_id::AbstractString, λ_values::Vector{Float64})
    spec = parse_case_spec(case_id)
    comparison_run = comparison_run_ordinal(spec)
    nopolish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_nopolish"))
    polish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_polish"))
    pep = polish_case.pep
    run_opts, box_meta = _resolve_research_run_opts(pep, polish_case.case_dir, polish_case.benchmark_opts)
    raw_candidates = ODEPE._load_benchmark_result_candidates(pep, run_opts, nopolish_case.case_dir)

    reports = Dict{Tuple{Symbol, Float64}, Dict{Symbol, Any}}()
    for method_spec in _regularization_method_specs()
        for λ in λ_values
            reports[(method_spec.key, λ)] = _run_regularized_method_report(
                method_spec.key,
                pep,
                raw_candidates,
                run_opts,
                λ,
            )
        end
    end

    return Dict{Symbol, Any}(
        :case_id => String(case_id),
        :spec => spec,
        :comparison_run => comparison_run,
        :raw_candidate_count => length(raw_candidates),
        :raw_stage_trace => _raw_stage_trace(pep, raw_candidates),
        :saved_amigo_metrics => load_selected_metrics(spec, "amigo2_run"; comparison_run = comparison_run),
        :saved_nopolish_metrics => load_selected_metrics(spec, "odepe_nopolish"; comparison_run = comparison_run),
        :saved_polish_metrics => load_selected_metrics(spec, "odepe_polish"; comparison_run = comparison_run),
        :box_meta => box_meta,
        :research_analysis_mode => _research_analysis_mode(),
        :regularization_mode => REGULARIZATION_MODE,
        :lambda_values => copy(λ_values),
        :reports => reports,
    )
end

function build_regularization_case_artifact_safe(case_id::AbstractString, λ_values::Vector{Float64})
    try
        return build_regularization_case_artifact(case_id, λ_values)
    catch err
        reason = sprint(showerror, err)
        reports = Dict{Tuple{Symbol, Float64}, Dict{Symbol, Any}}()
        for method_spec in _regularization_method_specs()
            for λ in λ_values
                reports[(method_spec.key, λ)] = _empty_regularization_report(reason, λ)
            end
        end
        return Dict{Symbol, Any}(
            :case_id => String(case_id),
            :raw_candidate_count => 0,
            :raw_stage_trace => Dict{Symbol, Any}(),
            :saved_amigo_metrics => nothing,
            :saved_nopolish_metrics => nothing,
            :saved_polish_metrics => nothing,
            :box_meta => nothing,
            :research_analysis_mode => _research_analysis_mode(),
            :regularization_mode => REGULARIZATION_MODE,
            :lambda_values => copy(λ_values),
            :reports => reports,
            :artifact_error => reason,
        )
    end
end

function _regularization_report(artifact, method_key::Symbol, λ::Float64)
    reports = get(artifact, :reports, Dict{Tuple{Symbol, Float64}, Dict{Symbol, Any}}())
    return get(reports, (method_key, λ), _empty_regularization_report("missing", λ; status = :missing))
end

function _report_selected_rmse(report)
    return _maybe_get(_maybe_get(report, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)
end

function _report_best_rmse(report)
    return _maybe_get(_maybe_get(report, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)
end

function _report_selected_max_rel_err(report)
    return _maybe_get(_maybe_get(report, :selected_benchmark_metrics, Dict{Symbol, Any}()), :max_rel_err, Inf)
end

function _report_best_max_rel_err(report)
    return _maybe_get(_maybe_get(report, :best_benchmark_metrics, Dict{Symbol, Any}()), :max_rel_err, Inf)
end

function _report_selected_local_rmse(report)
    return _maybe_get(_maybe_get(report, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)
end

function _report_best_local_rmse(report)
    return _maybe_get(_maybe_get(report, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)
end

function _report_runtime(report)
    return _maybe_get(report, :build_and_run_seconds, Inf)
end

function _report_status(report)
    return _maybe_get(report, :status, :missing)
end

function _report_selected_fit_objective(report)
    candidate = get(report, :selected_candidate, nothing)
    return isnothing(candidate) ? Inf : Float64(candidate.err)
end

function _report_best_benchmark_fit_objective(report)
    analyzed = get(report, :analyzed_candidates, ODEPE.ParameterEstimationResult[])
    best_idx = get(report, :best_benchmark_index, nothing)
    if isnothing(best_idx) || !(best_idx isa Integer) || best_idx < 1 || best_idx > length(analyzed)
        return Inf
    end
    return Float64(analyzed[best_idx].err)
end

function _regularization_counts(
    case_artifacts,
    method_key::Symbol,
    λ::Float64,
    baseline_method_key::Symbol,
    baseline_lambda::Float64;
    metric_fn = _report_best_rmse,
)
    better = 0
    tie = 0
    worse = 0
    unsupported = 0
    ratios = Float64[]
    for artifact in case_artifacts
        report = _regularization_report(artifact, method_key, λ)
        baseline = _regularization_report(artifact, baseline_method_key, baseline_lambda)
        if _report_status(report) != :ok || _report_status(baseline) != :ok
            unsupported += 1
            continue
        end
        cmp = _compare(metric_fn(report), metric_fn(baseline))
        cmp == :better && (better += 1)
        cmp == :tie && (tie += 1)
        cmp == :worse && (worse += 1)
        base_runtime = _report_runtime(baseline)
        report_runtime = _report_runtime(report)
        if isfinite(base_runtime) && base_runtime > 0.0 && isfinite(report_runtime)
            push!(ratios, report_runtime / base_runtime)
        end
    end
    return Dict(
        :better => better,
        :tie => tie,
        :worse => worse,
        :unsupported => unsupported,
        :median_runtime_ratio => isempty(ratios) ? Inf : median(ratios),
    )
end

function _best_lambda_for_method(artifact, method_key::Symbol; metric_fn = _report_best_rmse)
    best_lambda = nothing
    best_value = Inf
    for λ in get(artifact, :lambda_values, Float64[])
        report = _regularization_report(artifact, method_key, λ)
        _report_status(report) == :ok || continue
        value = metric_fn(report)
        if value < best_value
            best_value = value
            best_lambda = λ
        end
    end
    return best_lambda, best_value
end

function _load_existing_regularization_artifacts(root::AbstractString)
    tsv_path = joinpath(root, "summary.tsv")
    isfile(tsv_path) || return Dict{String, Dict{Symbol, Any}}()

    artifacts = Dict{String, Dict{Symbol, Any}}()
    for row in CSV.File(tsv_path; delim = '\t')
        case_id = String(row.case_id)
        artifact = get!(artifacts, case_id) do
            Dict{Symbol, Any}(
                :case_id => case_id,
                :raw_candidate_count => Int(row.raw_candidate_count),
                :raw_stage_trace => Dict{Symbol, Any}(
                    :imported_best_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row.imported_best_benchmark_rmse)),
                    :analyzed_best_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row.analyzed_input_best_benchmark_rmse)),
                    :analyzed_selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row.analyzed_input_selected_benchmark_rmse)),
                ),
                :saved_amigo_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row.saved_amigo_rmse)),
                :saved_nopolish_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row.saved_nopolish_rmse)),
                :saved_polish_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row.saved_polish_rmse)),
                :research_analysis_mode => Symbol(String(row.research_analysis_mode)),
                :regularization_mode => Symbol(String(row.regularization_mode)),
                :lambda_values => Float64[],
                :reports => Dict{Tuple{Symbol, Float64}, Dict{Symbol, Any}}(),
            )
        end

        λ = Float64(row.lambda)
        if !(λ in artifact[:lambda_values])
            push!(artifact[:lambda_values], λ)
            sort!(artifact[:lambda_values])
        end

        artifact[:reports][(Symbol(String(row.method_key)), λ)] = Dict{Symbol, Any}(
            :status => Symbol(String(row.status)),
            :reason => ismissing(row.reason) ? "" : String(row.reason),
            :build_and_run_seconds => _parse_float_like(row.runtime_seconds),
            :regularization_lambda => λ,
            :regularization_mode => Symbol(String(row.regularization_mode)),
            :selected_benchmark_metrics => Dict{Symbol, Any}(
                :rmse => _parse_float_like(row.selected_benchmark_rmse),
                :max_rel_err => hasproperty(row, :selected_benchmark_max_rel_err) ? _parse_float_like(row.selected_benchmark_max_rel_err) : Inf,
            ),
            :best_benchmark_metrics => Dict{Symbol, Any}(
                :rmse => _parse_float_like(row.best_benchmark_rmse),
                :max_rel_err => hasproperty(row, :best_benchmark_max_rel_err) ? _parse_float_like(row.best_benchmark_max_rel_err) : Inf,
            ),
            :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => _parse_float_like(row.selected_local_rel_rmse)),
            :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => _parse_float_like(row.best_local_rel_rmse)),
        )
    end

    return artifacts
end

function render_regularization_summary_tsv(path::AbstractString, suite, case_artifacts)
    mkpath(dirname(path))
    suite_meta = _suite_metadata_map(suite)
    headers = [
        "case_id",
        "system",
        "comparison_run",
        "lambda",
        "lambda_label",
        "method_key",
        "method_label",
        "status",
        "reason",
        "regularization_mode",
        "research_analysis_mode",
        "raw_candidate_count",
        "imported_best_benchmark_rmse",
        "analyzed_input_best_benchmark_rmse",
        "analyzed_input_selected_benchmark_rmse",
        "saved_amigo_rmse",
        "saved_nopolish_rmse",
        "saved_polish_rmse",
        "selected_benchmark_rmse",
        "selected_benchmark_max_rel_err",
        "best_benchmark_rmse",
        "best_benchmark_max_rel_err",
        "selected_local_rel_rmse",
        "best_local_rel_rmse",
        "selected_fit_objective",
        "best_benchmark_fit_objective",
        "runtime_seconds",
    ]

    open(path, "w") do io
        println(io, join(headers, '\t'))
        for artifact in case_artifacts
            case_id = artifact[:case_id]
            entry = suite_meta[case_id]
            for method_spec in _regularization_method_specs()
                for λ in artifact[:lambda_values]
                    report = _regularization_report(artifact, method_spec.key, λ)
                    row = [
                        case_id,
                        entry.system,
                        string(entry.comparison_run),
                        string(λ),
                        _lambda_label(λ),
                        string(method_spec.key),
                        method_spec.label,
                        string(_report_status(report)),
                        replace(String(get(report, :reason, "")), '\n' => ' '),
                        string(get(report, :regularization_mode, REGULARIZATION_MODE)),
                        string(get(artifact, :research_analysis_mode, :unknown)),
                        string(get(artifact, :raw_candidate_count, 0)),
                        string(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :imported_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                        string(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                        string(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                        string(_maybe_get(_maybe_get(artifact, :saved_amigo_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                        string(_maybe_get(_maybe_get(artifact, :saved_nopolish_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                        string(_maybe_get(_maybe_get(artifact, :saved_polish_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                        string(_report_selected_rmse(report)),
                        string(_report_selected_max_rel_err(report)),
                        string(_report_best_rmse(report)),
                        string(_report_best_max_rel_err(report)),
                        string(_report_selected_local_rmse(report)),
                        string(_report_best_local_rmse(report)),
                        string(_report_selected_fit_objective(report)),
                        string(_report_best_benchmark_fit_objective(report)),
                        string(_report_runtime(report)),
                    ]
                    println(io, join(row, '\t'))
                end
            end
        end
    end
end

function render_regularization_summary_md(path::AbstractString, suite, case_artifacts)
    mkpath(dirname(path))
    λ_values = isempty(case_artifacts) ? regularization_lambda_values() : first(case_artifacts)[:lambda_values]
    open(path, "w") do io
        println(io, "# Log-Space L2 Regularization Sweep\n")
        println(io, "- Generated: `$(Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"))`")
        println(io, "- Basis: imported bilby `odepe_nopolish` pools")
        println(io, "- Research analysis mode: `ungated`")
        println(io, "- Penalty: `RSS(x) + λ * ||log(x)||²` for scalar, equivalent augmented least-squares residual for residual methods")
        println(io, "- Lambda grid: `$(join(_lambda_label.(λ_values), "`, `"))`")
        println(io, "- Suite filter: positive-box `1e-4` cases, `amigo2 < odepe_polish`, saved `odepe_polish >= 10%`, ratio `>= 2x`, excluding `cstr`\n")

        println(io, "## Oracle Aggregate vs Each Method's `λ = 0`\n")
        println(io, "| Method | λ | Oracle vs same-method `λ=0` | Median runtime ratio |")
        println(io, "| --- | ---: | --- | ---: |")
        for method_spec in _regularization_method_specs()
            for λ in λ_values
                counts = _regularization_counts(case_artifacts, method_spec.key, λ, method_spec.key, 0.0; metric_fn = _report_best_rmse)
                summary = "$(counts[:better]) better / $(counts[:tie]) tie / $(counts[:worse]) worse / $(counts[:unsupported]) unsupported"
                println(io, "| `$(method_spec.label)` | `$( _lambda_label(λ) )` | $(summary) | $(_format_float(counts[:median_runtime_ratio]; digits = 3))x |")
            end
        end

        println(io, "\n## Oracle Aggregate vs Unregularized Bounded LeastSquaresOptim LM\n")
        println(io, "| Arm | λ | Oracle vs `Bounded LeastSquaresOptim LM log-space, λ=0` |")
        println(io, "| --- | ---: | --- |")
        for method_spec in _regularization_method_specs()
            for λ in λ_values
                counts = _regularization_counts(
                    case_artifacts,
                    method_spec.key,
                    λ,
                    :residual_lso_lm_bounded_log,
                    0.0;
                    metric_fn = _report_best_rmse,
                )
                summary = "$(counts[:better]) better / $(counts[:tie]) tie / $(counts[:worse]) worse / $(counts[:unsupported]) unsupported"
                println(io, "| `$(method_spec.label)` | `$( _lambda_label(λ) )` | $(summary) |")
            end
        end

        println(io, "\n## Per-Case Best λ / Oracle View\n")
        println(io, "| Case | Scalar best λ | Scalar best RMSE | LSO best λ | LSO best RMSE | FastLM best λ | FastLM best RMSE |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: | ---: |")
        for artifact in case_artifacts
            scalar_best_λ, scalar_best_rmse = _best_lambda_for_method(artifact, :scalar_log; metric_fn = _report_best_rmse)
            lso_best_λ, lso_best_rmse = _best_lambda_for_method(artifact, :residual_lso_lm_bounded_log; metric_fn = _report_best_rmse)
            fastlm_best_λ, fastlm_best_rmse = _best_lambda_for_method(artifact, :residual_fastlm_bounded_log; metric_fn = _report_best_rmse)
            println(io, "| `$(artifact[:case_id])` | `$(isnothing(scalar_best_λ) ? "N/A" : _lambda_label(scalar_best_λ))` | $(_fmt_pct(scalar_best_rmse)) | `$(isnothing(lso_best_λ) ? "N/A" : _lambda_label(lso_best_λ))` | $(_fmt_pct(lso_best_rmse)) | `$(isnothing(fastlm_best_λ) ? "N/A" : _lambda_label(fastlm_best_λ))` | $(_fmt_pct(fastlm_best_rmse)) |")
        end

        println(io, "\n## Cases Improved vs `λ = 0`\n")
        for method_spec in _regularization_method_specs()
            improved = String[]
            for artifact in case_artifacts
                base_report = _regularization_report(artifact, method_spec.key, 0.0)
                best_λ, best_value = _best_lambda_for_method(artifact, method_spec.key; metric_fn = _report_best_rmse)
                _report_status(base_report) == :ok || continue
                isfinite(best_value) || continue
                _compare(best_value, _report_best_rmse(base_report)) == :better || continue
                push!(improved, "$(artifact[:case_id]) (`$(_lambda_label(something(best_λ, 0.0)))`)")
            end
            println(io, "- `$(method_spec.label)`: $(isempty(improved) ? "none" : join(improved, ", "))")
        end
    end
end

function render_regularization_summary_clarified(path::AbstractString, suite, case_artifacts)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Log-Space L2 Regularization Sweep: Clarified Views\n")
        println(io, "## Best-In-Set / Oracle View\n")
        println(io, "| Case | Scalar `λ=0` | Scalar best over λ | LSO `λ=0` | LSO best over λ | FastLM `λ=0` | FastLM best over λ |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: | ---: |")
        for artifact in case_artifacts
            scalar_best_λ, scalar_best_rmse = _best_lambda_for_method(artifact, :scalar_log; metric_fn = _report_best_rmse)
            lso_best_λ, lso_best_rmse = _best_lambda_for_method(artifact, :residual_lso_lm_bounded_log; metric_fn = _report_best_rmse)
            fastlm_best_λ, fastlm_best_rmse = _best_lambda_for_method(artifact, :residual_fastlm_bounded_log; metric_fn = _report_best_rmse)
            println(
                io,
                "| `$(artifact[:case_id])` | $(_fmt_pct(_report_best_rmse(_regularization_report(artifact, :scalar_log, 0.0)))) | $(_fmt_pct(scalar_best_rmse)) @ `$(isnothing(scalar_best_λ) ? "N/A" : _lambda_label(scalar_best_λ))` | $(_fmt_pct(_report_best_rmse(_regularization_report(artifact, :residual_lso_lm_bounded_log, 0.0)))) | $(_fmt_pct(lso_best_rmse)) @ `$(isnothing(lso_best_λ) ? "N/A" : _lambda_label(lso_best_λ))` | $(_fmt_pct(_report_best_rmse(_regularization_report(artifact, :residual_fastlm_bounded_log, 0.0)))) | $(_fmt_pct(fastlm_best_rmse)) @ `$(isnothing(fastlm_best_λ) ? "N/A" : _lambda_label(fastlm_best_λ))` |",
            )
        end

        println(io, "\n## Fit-Selected / Operational View\n")
        println(io, "| Case | Scalar `λ=0` | Scalar best over λ | LSO `λ=0` | LSO best over λ | FastLM `λ=0` | FastLM best over λ |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: | ---: |")
        for artifact in case_artifacts
            scalar_best_λ, scalar_best_selected = _best_lambda_for_method(artifact, :scalar_log; metric_fn = _report_selected_rmse)
            lso_best_λ, lso_best_selected = _best_lambda_for_method(artifact, :residual_lso_lm_bounded_log; metric_fn = _report_selected_rmse)
            fastlm_best_λ, fastlm_best_selected = _best_lambda_for_method(artifact, :residual_fastlm_bounded_log; metric_fn = _report_selected_rmse)
            println(
                io,
                "| `$(artifact[:case_id])` | $(_fmt_pct(_report_selected_rmse(_regularization_report(artifact, :scalar_log, 0.0)))) | $(_fmt_pct(scalar_best_selected)) @ `$(isnothing(scalar_best_λ) ? "N/A" : _lambda_label(scalar_best_λ))` | $(_fmt_pct(_report_selected_rmse(_regularization_report(artifact, :residual_lso_lm_bounded_log, 0.0)))) | $(_fmt_pct(lso_best_selected)) @ `$(isnothing(lso_best_λ) ? "N/A" : _lambda_label(lso_best_λ))` | $(_fmt_pct(_report_selected_rmse(_regularization_report(artifact, :residual_fastlm_bounded_log, 0.0)))) | $(_fmt_pct(fastlm_best_selected)) @ `$(isnothing(fastlm_best_λ) ? "N/A" : _lambda_label(fastlm_best_λ))` |",
            )
        end
    end
end

function render_regularization_progress(path::AbstractString, case_ids::Vector{String}, artifacts)
    mkpath(dirname(path))
    completed_ids = [artifact[:case_id] for artifact in artifacts]
    remaining_ids = [case_id for case_id in case_ids if !(case_id in Set(completed_ids))]
    open(path, "w") do io
        println(io, "completed_cases=$(length(artifacts))")
        println(io, "requested_cases=$(length(case_ids))")
        println(io, "completed_case_ids=$(join(completed_ids, ','))")
        println(io, "remaining_case_ids=$(join(remaining_ids, ','))")
        println(io, "updated_at=$(Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"))")
    end
end

function main()
    suite = select_standardization_suite()
    case_ids = selected_regularization_case_ids([entry.case_id for entry in suite])
    selected_case_set = Set(case_ids)
    suite = [entry for entry in suite if entry.case_id in selected_case_set]
    λ_values = regularization_lambda_values()

    mkpath(REGULARIZATION_OUTPUT_ROOT)
    _write_suite_tsv(joinpath(REGULARIZATION_OUTPUT_ROOT, "suite.tsv"), suite)

    existing = _load_existing_regularization_artifacts(REGULARIZATION_OUTPUT_ROOT)
    artifacts = Dict{Symbol, Any}[existing[case_id] for case_id in case_ids if haskey(existing, case_id)]
    completed = Set(getindex.(artifacts, :case_id))
    remaining_case_ids = [case_id for case_id in case_ids if !(case_id in completed)]

    summary_tsv = joinpath(REGULARIZATION_OUTPUT_ROOT, "summary.tsv")
    summary_md = joinpath(REGULARIZATION_OUTPUT_ROOT, "summary.md")
    clarified_md = joinpath(REGULARIZATION_OUTPUT_ROOT, "summary_clarified.md")
    progress_path = joinpath(REGULARIZATION_OUTPUT_ROOT, "progress.txt")

    for case_id in remaining_case_ids
        println("[$(length(artifacts) + 1)/$(length(case_ids))] Running $(case_id)")
        artifact = build_regularization_case_artifact_safe(case_id, λ_values)
        push!(artifacts, artifact)
        render_regularization_summary_tsv(summary_tsv, suite, artifacts)
        render_regularization_summary_md(summary_md, suite, artifacts)
        render_regularization_summary_clarified(clarified_md, suite, artifacts)
        render_regularization_progress(progress_path, case_ids, artifacts)
        println("[$(length(artifacts))/$(length(case_ids))] Flushed $(case_id)")
    end

    println("Wrote regularization sweep to $(REGULARIZATION_OUTPUT_ROOT)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
