using CSV
using Dates
using Statistics

include(joinpath(@__DIR__, "generate_local_polish_regularization_sweep.jl"))

const LSO_TUNING_OUTPUT_ROOT = get(
    ENV,
    "ODEPE_LSO_TUNING_OUTPUT_ROOT",
    joinpath(@__DIR__, "..", "artifacts", "diagnostics", "lso_tuning_maxrel_1em4_hard"),
)
const LSO_TUNING_PHASE_A_LAMBDAS = [0.0, 1e-4, 1e-3, 1e-2, 1e-1]
const LSO_TUNING_PHASE_B_DELTAS = [3.0, 10.0, 30.0]
const LSO_TUNING_MIN_ITERATIONS = 4000
const LSO_TUNING_TOL_PROFILES = [:baseline, :strict]
const LSO_TUNING_THRESHOLDS = [0.01, 0.1, 0.5]

function selected_lso_tuning_case_ids(default_case_ids::Vector{String})
    raw = split(get(ENV, "ODEPE_LSO_TUNING_CASE_IDS", join(default_case_ids, ",")), ",")
    selected = Set(filter(!isempty, strip.(raw)))
    filtered = [case_id for case_id in default_case_ids if case_id in selected]
    isempty(filtered) && error("No LSO tuning cases selected")
    return filtered
end

_config_key_label(λ::Float64) = replace(_lambda_label(λ), "-" => "m")
_delta_key_label(Δ::Float64) = replace(string(round(Int, Δ)), "-" => "m")

function _control_specs()
    return [
        (
            key = :scalar_log_control,
            label = "Scalar log-space λ=0",
            phase = :control,
            method = :scalar_log,
            lambda = 0.0,
            delta = nothing,
            tol_profile = :baseline,
        ),
        (
            key = :fastlm_log_control,
            label = "Bounded FastLM log-space λ=0",
            phase = :control,
            method = :fastlm_log,
            lambda = 0.0,
            delta = nothing,
            tol_profile = :baseline,
        ),
    ]
end

function _phase_a_lso_specs()
    return [
        (
            key = Symbol("lso_phase_a_lambda_" * _config_key_label(λ)),
            label = "LSO LM log-space λ=$(_lambda_label(λ)), Δ=10, baseline tol",
            phase = :phase_a,
            method = :lso_log,
            lambda = λ,
            delta = 10.0,
            tol_profile = :baseline,
        ) for λ in LSO_TUNING_PHASE_A_LAMBDAS
    ]
end

function _phase_b_lso_specs(selected_lambdas::Vector{Float64})
    specs = NamedTuple[]
    for λ in selected_lambdas
        for Δ in LSO_TUNING_PHASE_B_DELTAS
            for tol_profile in LSO_TUNING_TOL_PROFILES
                push!(
                    specs,
                    (
                        key = Symbol(
                            "lso_phase_b_lambda_" * _config_key_label(λ) *
                            "_delta_" * _delta_key_label(Δ) *
                            "_tol_" * String(tol_profile),
                        ),
                        label = "LSO LM log-space λ=$(_lambda_label(λ)), Δ=$(Int(round(Δ))), $(tol_profile) tol",
                        phase = :phase_b,
                        method = :lso_log,
                        lambda = λ,
                        delta = Δ,
                        tol_profile = tol_profile,
                    ),
                )
            end
        end
    end
    return specs
end

function _lso_tol_values(run_opts::ODEPE.EstimationOptions, tol_profile::Symbol)
    scale = tol_profile == :strict ? 0.1 : 1.0
    tol_profile in LSO_TUNING_TOL_PROFILES || error("Unsupported LSO tol profile '$tol_profile'")
    return (
        x_tol = scale * run_opts.reltol,
        f_tol = scale * run_opts.reltol,
        g_tol = scale * run_opts.abstol,
    )
end

function _lso_tuning_case_context(case_id::AbstractString)
    spec = parse_case_spec(case_id)
    comparison_run = comparison_run_ordinal(spec)
    nopolish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_nopolish"))
    polish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_polish"))
    pep = polish_case.pep
    run_opts, box_meta = _resolve_research_run_opts(pep, polish_case.case_dir, polish_case.benchmark_opts)
    raw_candidates = ODEPE._load_benchmark_result_candidates(pep, run_opts, nopolish_case.case_dir)
    return (
        spec = spec,
        comparison_run = comparison_run,
        pep = pep,
        run_opts = run_opts,
        box_meta = box_meta,
        raw_candidates = raw_candidates,
    )
end

function _run_lso_tuning_report(config, pep, raw_candidates, run_opts)
    if config.method == :scalar_log
        return safe_polish_mode_report(
            pep,
            raw_candidates,
            _regularization_scalar_run_opts(run_opts),
            :log_positive;
            regularization_lambda = config.lambda,
            regularization_mode = REGULARIZATION_MODE,
        )
    elseif config.method == :fastlm_log
        return safe_residual_mode_report(
            pep,
            raw_candidates,
            run_opts,
            :log_positive;
            optimizer_factory = () -> nothing,
            solver_kind = :fastlm_direct,
            jacobian_mode = :forward,
            bounds_mode = :bounded,
            regularization_lambda = config.lambda,
            regularization_mode = REGULARIZATION_MODE,
            solver_label = "FastLevenbergMarquardt.lmsolve!() with lb/ub",
            required_package = :FastLevenbergMarquardt,
        )
    elseif config.method == :lso_log
        tol = _lso_tol_values(run_opts, config.tol_profile)
        return safe_residual_mode_report(
            pep,
            raw_candidates,
            run_opts,
            :log_positive;
            optimizer_factory = () -> LeastSquaresOptim.LevenbergMarquardt(),
            solver_kind = :lso_direct,
            jacobian_mode = :forward,
            bounds_mode = :bounded,
            regularization_lambda = config.lambda,
            regularization_mode = REGULARIZATION_MODE,
            solver_label = "LeastSquaresOptim.optimize!(LevenbergMarquardt(); lower/upper)",
            required_package = :LeastSquaresOptim,
            maxiters_override = max(run_opts.polish_maxiters, LSO_TUNING_MIN_ITERATIONS),
            lso_delta = config.delta,
            lso_x_tol = tol.x_tol,
            lso_f_tol = tol.f_tol,
            lso_g_tol = tol.g_tol,
        )
    end
    error("Unsupported tuning config method '$(config.method)'")
end

function _empty_lso_tuning_report(reason::AbstractString)
    return Dict{Symbol, Any}(
        :status => :error,
        :reason => String(reason),
        :build_and_run_seconds => Inf,
        :selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
        :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
        :best_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
        :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
    )
end

function _ensure_case_artifact(case_id::AbstractString, existing_artifact::Union{Nothing, Dict{Symbol, Any}} = nothing)
    if !isnothing(existing_artifact)
        artifact = deepcopy(existing_artifact)
        artifact[:reports] = deepcopy(get(existing_artifact, :reports, Dict{Symbol, Dict{Symbol, Any}}()))
        return artifact
    end
    return Dict{Symbol, Any}(
        :case_id => String(case_id),
        :reports => Dict{Symbol, Dict{Symbol, Any}}(),
    )
end

function run_lso_tuning_case_configs(case_id::AbstractString, configs, existing_artifact::Union{Nothing, Dict{Symbol, Any}} = nothing)
    artifact = _ensure_case_artifact(case_id, existing_artifact)
    missing = [config for config in configs if !haskey(artifact[:reports], config.key)]
    isempty(missing) && return artifact

    ctx = _lso_tuning_case_context(case_id)
    artifact[:spec] = ctx.spec
    artifact[:comparison_run] = ctx.comparison_run
    artifact[:raw_candidate_count] = length(ctx.raw_candidates)
    artifact[:raw_stage_trace] = _raw_stage_trace(ctx.pep, ctx.raw_candidates)
    artifact[:saved_amigo_metrics] = load_selected_metrics(ctx.spec, "amigo2_run"; comparison_run = ctx.comparison_run)
    artifact[:saved_nopolish_metrics] = load_selected_metrics(ctx.spec, "odepe_nopolish"; comparison_run = ctx.comparison_run)
    artifact[:saved_polish_metrics] = load_selected_metrics(ctx.spec, "odepe_polish"; comparison_run = ctx.comparison_run)
    artifact[:box_meta] = ctx.box_meta
    artifact[:research_analysis_mode] = _research_analysis_mode()

    for config in missing
        report = try
            _run_lso_tuning_report(config, ctx.pep, ctx.raw_candidates, ctx.run_opts)
        catch err
            _empty_lso_tuning_report(sprint(showerror, err))
        end
        report[:config_key] = config.key
        report[:config_label] = config.label
        report[:phase] = config.phase
        report[:method] = config.method
        report[:lambda] = config.lambda
        report[:delta] = config.delta
        report[:tol_profile] = config.tol_profile
        artifact[:reports][config.key] = report
    end

    return artifact
end

function _report_for_config(artifact, config_key::Symbol)
    reports = get(artifact, :reports, Dict{Symbol, Dict{Symbol, Any}}())
    return get(reports, config_key, _empty_lso_tuning_report("missing"))
end

function _config_success_counts(case_artifacts, config_key::Symbol)
    values = Float64[]
    runtimes = Float64[]
    ok = 0
    for artifact in case_artifacts
        report = _report_for_config(artifact, config_key)
        _report_status(report) == :ok || continue
        value = _report_best_max_rel_err(report)
        isfinite(value) || continue
        push!(values, value)
        ok += 1
        runtime = _report_runtime(report)
        isfinite(runtime) && push!(runtimes, runtime)
    end
    return Dict(
        :ok => ok,
        :at_1pct => count(<=(0.01), values),
        :at_10pct => count(<=(0.1), values),
        :at_50pct => count(<=(0.5), values),
        :median_max_rel_err => isempty(values) ? Inf : median(values),
        :median_runtime_seconds => isempty(runtimes) ? Inf : median(runtimes),
    )
end

function _config_rank_tuple(case_artifacts, config_key::Symbol)
    counts = _config_success_counts(case_artifacts, config_key)
    return (
        -counts[:at_1pct],
        -counts[:at_10pct],
        -counts[:at_50pct],
        counts[:median_max_rel_err],
        counts[:median_runtime_seconds],
    )
end

function _select_phase_b_lambdas(case_artifacts)
    phase_a_specs = _phase_a_lso_specs()
    ranked = sort(phase_a_specs; by = spec -> _config_rank_tuple(case_artifacts, spec.key))
    return [spec.lambda for spec in ranked[1:min(2, length(ranked))]]
end

function _pairwise_counts(case_artifacts, lhs_key::Symbol, rhs_key::Symbol)
    better = 0
    tie = 0
    worse = 0
    unsupported = 0
    for artifact in case_artifacts
        lhs = _report_for_config(artifact, lhs_key)
        rhs = _report_for_config(artifact, rhs_key)
        if _report_status(lhs) != :ok || _report_status(rhs) != :ok
            unsupported += 1
            continue
        end
        cmp = _compare(_report_best_max_rel_err(lhs), _report_best_max_rel_err(rhs))
        cmp == :better && (better += 1)
        cmp == :tie && (tie += 1)
        cmp == :worse && (worse += 1)
    end
    return Dict(:better => better, :tie => tie, :worse => worse, :unsupported => unsupported)
end

function _load_existing_lso_tuning_artifacts(root::AbstractString)
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
                :reports => Dict{Symbol, Dict{Symbol, Any}}(),
            )
        end
        config_key = Symbol(String(row.config_key))
        artifact[:reports][config_key] = Dict{Symbol, Any}(
            :status => Symbol(String(row.status)),
            :reason => ismissing(row.reason) ? "" : String(row.reason),
            :build_and_run_seconds => _parse_float_like(row.runtime_seconds),
            :selected_benchmark_metrics => Dict{Symbol, Any}(
                :rmse => _parse_float_like(row.selected_benchmark_rmse),
                :max_rel_err => _parse_float_like(row.selected_benchmark_max_rel_err),
            ),
            :best_benchmark_metrics => Dict{Symbol, Any}(
                :rmse => _parse_float_like(row.best_benchmark_rmse),
                :max_rel_err => _parse_float_like(row.best_benchmark_max_rel_err),
            ),
            :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => _parse_float_like(row.selected_local_rel_rmse)),
            :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => _parse_float_like(row.best_local_rel_rmse)),
            :config_key => config_key,
            :config_label => String(row.config_label),
            :phase => Symbol(String(row.phase)),
            :method => Symbol(String(row.method)),
            :lambda => _parse_float_like(row.lambda),
            :delta => strip(String(row.delta)) == "" ? nothing : _parse_float_like(row.delta),
            :tol_profile => Symbol(String(row.tol_profile)),
        )
    end

    return artifacts
end

function render_lso_tuning_summary_tsv(path::AbstractString, suite, case_artifacts, configs)
    mkpath(dirname(path))
    suite_meta = _suite_metadata_map(suite)
    headers = [
        "case_id",
        "system",
        "comparison_run",
        "config_key",
        "config_label",
        "phase",
        "method",
        "lambda",
        "delta",
        "tol_profile",
        "status",
        "reason",
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
        "runtime_seconds",
    ]

    open(path, "w") do io
        println(io, join(headers, '\t'))
        for artifact in case_artifacts
            entry = suite_meta[artifact[:case_id]]
            for config in configs
                report = _report_for_config(artifact, config.key)
                row = [
                    artifact[:case_id],
                    entry.system,
                    string(entry.comparison_run),
                    string(config.key),
                    config.label,
                    string(config.phase),
                    string(config.method),
                    string(config.lambda),
                    isnothing(config.delta) ? "" : string(config.delta),
                    string(config.tol_profile),
                    string(_report_status(report)),
                    replace(String(get(report, :reason, "")), '\n' => ' '),
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
                    string(_report_runtime(report)),
                ]
                println(io, join(row, '\t'))
            end
        end
    end
end

function render_lso_tuning_summary_md(path::AbstractString, suite, case_artifacts, selected_phase_b_lambdas::Vector{Float64})
    mkpath(dirname(path))
    phase_a_specs = _phase_a_lso_specs()
    phase_b_specs = _phase_b_lso_specs(selected_phase_b_lambdas)
    control_specs = _control_specs()
    lso_specs = vcat(phase_a_specs, phase_b_specs)
    winner = isempty(lso_specs) ? nothing : first(sort(lso_specs; by = spec -> _config_rank_tuple(case_artifacts, spec.key)))

    open(path, "w") do io
        println(io, "# LSO Max-Rel Tuning Sweep\n")
        println(io, "- Generated: `$(Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"))`")
        println(io, "- Suite size: `$(length(case_artifacts)) / $(length(suite))` cases flushed")
        println(io, "- Primary metric: oracle best-in-set `max_rel_err`")
        println(io, "- Thresholds: `1%`, `10%`, `50%`")
        println(io, "- Phase A λ grid: `$(join(_lambda_label.(LSO_TUNING_PHASE_A_LAMBDAS), "`, `"))`")
        println(io, "- Phase B Δ grid: `$(join(string.(Int.(round.(LSO_TUNING_PHASE_B_DELTAS))), "`, `"))`")
        println(io, "- Phase B tolerance profiles: `baseline`, `strict`\n")

        println(io, "## Frozen Controls\n")
        println(io, "| Control | <=1% | <=10% | <=50% | Median max-rel | Median runtime (s) |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: |")
        for config in control_specs
            counts = _config_success_counts(case_artifacts, config.key)
            println(
                io,
                "| `$(config.label)` | $(counts[:at_1pct]) | $(counts[:at_10pct]) | $(counts[:at_50pct]) | $(_format_float(counts[:median_max_rel_err]; digits = 4)) | $(_format_float(counts[:median_runtime_seconds]; digits = 2)) |",
            )
        end

        println(io, "\n## Phase A: λ Scan\n")
        println(io, "| λ | <=1% | <=10% | <=50% | Median max-rel | Median runtime (s) |")
        println(io, "| ---: | ---: | ---: | ---: | ---: | ---: |")
        for config in phase_a_specs
            counts = _config_success_counts(case_artifacts, config.key)
            println(
                io,
                "| `$( _lambda_label(config.lambda) )` | $(counts[:at_1pct]) | $(counts[:at_10pct]) | $(counts[:at_50pct]) | $(_format_float(counts[:median_max_rel_err]; digits = 4)) | $(_format_float(counts[:median_runtime_seconds]; digits = 2)) |",
            )
        end

        println(io, "\n## Selected λ For Phase B\n")
        println(io, "- `$(join(_lambda_label.(selected_phase_b_lambdas), "`, `"))`\n")

        println(io, "## Phase B: Δ / Tolerance Scan\n")
        println(io, "| λ | Δ | tol | <=1% | <=10% | <=50% | Median max-rel | Median runtime (s) |")
        println(io, "| ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |")
        for config in phase_b_specs
            counts = _config_success_counts(case_artifacts, config.key)
            println(
                io,
                "| `$( _lambda_label(config.lambda) )` | `$(Int(round(something(config.delta, 0.0))))` | `$(config.tol_profile)` | $(counts[:at_1pct]) | $(counts[:at_10pct]) | $(counts[:at_50pct]) | $(_format_float(counts[:median_max_rel_err]; digits = 4)) | $(_format_float(counts[:median_runtime_seconds]; digits = 2)) |",
            )
        end

        println(io, "\n## Winning LSO Config\n")
        if isnothing(winner)
            println(io, "- No finite LSO winner yet.")
        else
            counts = _config_success_counts(case_artifacts, winner.key)
            println(io, "- Winner: `$(winner.label)`")
            println(io, "- Threshold counts: `$(counts[:at_1pct])` at `1%`, `$(counts[:at_10pct])` at `10%`, `$(counts[:at_50pct])` at `50%`")
            println(io, "- Median finite max-rel: `$(_format_float(counts[:median_max_rel_err]; digits = 4))`")
            println(io, "- Median runtime: `$(_format_float(counts[:median_runtime_seconds]; digits = 2)) s`")

            println(io, "\n## Winner vs Controls\n")
            println(io, "| Baseline | Better | Tie | Worse | Unsupported |")
            println(io, "| --- | ---: | ---: | ---: | ---: |")
            for config in control_specs
                counts_vs = _pairwise_counts(case_artifacts, winner.key, config.key)
                println(io, "| `$(config.label)` | $(counts_vs[:better]) | $(counts_vs[:tie]) | $(counts_vs[:worse]) | $(counts_vs[:unsupported]) |")
            end
        end
    end
end

function render_lso_tuning_progress(path::AbstractString, case_ids::Vector{String}, artifacts, selected_phase_b_lambdas::Vector{Float64})
    phase_a_specs = vcat(_control_specs(), _phase_a_lso_specs())
    phase_b_specs = _phase_b_lso_specs(selected_phase_b_lambdas)
    phase_a_complete = count(artifact -> all(haskey(get(artifact, :reports, Dict{Symbol, Any}()), config.key) for config in phase_a_specs), artifacts)
    phase_b_complete = count(artifact -> all(haskey(get(artifact, :reports, Dict{Symbol, Any}()), config.key) for config in phase_b_specs), artifacts)
    completed_ids = [artifact[:case_id] for artifact in artifacts]
    open(path, "w") do io
        println(io, "completed_cases=$(length(completed_ids))")
        println(io, "requested_cases=$(length(case_ids))")
        println(io, "phase_a_complete_cases=$(phase_a_complete)")
        println(io, "phase_b_complete_cases=$(phase_b_complete)")
        println(io, "selected_phase_b_lambdas=$(join(_lambda_label.(selected_phase_b_lambdas), ','))")
        println(io, "completed_case_ids=$(join(completed_ids, ','))")
        println(io, "remaining_case_ids=$(join([case_id for case_id in case_ids if !(case_id in Set(completed_ids))], ','))")
        println(io, "updated_at=$(Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"))")
    end
end

function main()
    suite = select_standardization_suite()
    case_ids = selected_lso_tuning_case_ids([entry.case_id for entry in suite])
    selected_case_set = Set(case_ids)
    suite = [entry for entry in suite if entry.case_id in selected_case_set]

    mkpath(LSO_TUNING_OUTPUT_ROOT)
    _write_suite_tsv(joinpath(LSO_TUNING_OUTPUT_ROOT, "suite.tsv"), suite)

    existing = _load_existing_lso_tuning_artifacts(LSO_TUNING_OUTPUT_ROOT)
    artifacts_by_case = Dict{String, Dict{Symbol, Any}}(case_id => existing[case_id] for case_id in keys(existing))

    phase_a_configs = vcat(_control_specs(), _phase_a_lso_specs())
    summary_tsv = joinpath(LSO_TUNING_OUTPUT_ROOT, "summary.tsv")
    summary_md = joinpath(LSO_TUNING_OUTPUT_ROOT, "summary.md")
    progress_path = joinpath(LSO_TUNING_OUTPUT_ROOT, "progress.txt")

    for case_id in case_ids
        artifact = get(artifacts_by_case, case_id, nothing)
        missing = [config for config in phase_a_configs if isnothing(artifact) || !haskey(get(artifact, :reports, Dict{Symbol, Any}()), config.key)]
        isempty(missing) && continue
        println("[phase-a] $(case_id): $(length(missing)) configs")
        artifacts_by_case[case_id] = run_lso_tuning_case_configs(case_id, missing, artifact)
        ordered_artifacts = [artifacts_by_case[id] for id in case_ids if haskey(artifacts_by_case, id)]
        render_lso_tuning_summary_tsv(summary_tsv, suite, ordered_artifacts, phase_a_configs)
        render_lso_tuning_summary_md(summary_md, suite, ordered_artifacts, Float64[])
        render_lso_tuning_progress(progress_path, case_ids, ordered_artifacts, Float64[])
    end

    ordered_artifacts = [artifacts_by_case[id] for id in case_ids if haskey(artifacts_by_case, id)]
    selected_phase_b_lambdas = _select_phase_b_lambdas(ordered_artifacts)
    phase_b_configs = _phase_b_lso_specs(selected_phase_b_lambdas)

    for case_id in case_ids
        artifact = artifacts_by_case[case_id]
        missing = [config for config in phase_b_configs if !haskey(get(artifact, :reports, Dict{Symbol, Any}()), config.key)]
        isempty(missing) && continue
        println("[phase-b] $(case_id): $(length(missing)) configs")
        artifacts_by_case[case_id] = run_lso_tuning_case_configs(case_id, missing, artifact)
        ordered_artifacts = [artifacts_by_case[id] for id in case_ids if haskey(artifacts_by_case, id)]
        render_lso_tuning_summary_tsv(summary_tsv, suite, ordered_artifacts, vcat(phase_a_configs, phase_b_configs))
        render_lso_tuning_summary_md(summary_md, suite, ordered_artifacts, selected_phase_b_lambdas)
        render_lso_tuning_progress(progress_path, case_ids, ordered_artifacts, selected_phase_b_lambdas)
    end

    ordered_artifacts = [artifacts_by_case[id] for id in case_ids if haskey(artifacts_by_case, id)]
    render_lso_tuning_summary_tsv(summary_tsv, suite, ordered_artifacts, vcat(phase_a_configs, phase_b_configs))
    render_lso_tuning_summary_md(summary_md, suite, ordered_artifacts, selected_phase_b_lambdas)
    render_lso_tuning_progress(progress_path, case_ids, ordered_artifacts, selected_phase_b_lambdas)

    println("Wrote LSO tuning sweep to $(LSO_TUNING_OUTPUT_ROOT)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
