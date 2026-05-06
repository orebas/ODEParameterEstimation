using Dates
using ODEParameterEstimation

const ODEPE = ODEParameterEstimation

include(joinpath(@__DIR__, "generate_residual_polish_ablation.jl"))

const CROSS_POLISH_DEFAULT_CASE_IDS = [
    "seir_3_1em4",
    "seir_7_1em4",
    "hiv_7_1em4",
    "hiv_4_1em4",
    "crauste_7_1em4",
    "hiv_2_1em4",
    "daisy_mamil4_1_1em4",
    "seir_6_1em4",
]

const CROSS_POLISH_OUTPUT_ROOT = get(
    ENV,
    "ODEPE_CROSS_POLISH_OUTPUT_ROOT",
    joinpath(@__DIR__, "..", "artifacts", "diagnostics", "cross_polish_basin_diagnostic"),
)

const CROSS_POLISH_DISTANCE_THRESHOLD = 1e-3
const CROSS_POLISH_TOP_FIT_K = 3
const CROSS_POLISH_SOURCE_MODE = Symbol(get(ENV, "ODEPE_CROSS_POLISH_SOURCE_MODE", "topk"))

function _cross_polish_source_mode_label()
    return CROSS_POLISH_SOURCE_MODE == :full_pool ? "full analyzed representative pool" : "oracle/fit/top-k subset"
end

function selected_cross_polish_case_ids()
    raw = split(get(ENV, "ODEPE_CROSS_POLISH_CASE_IDS", join(CROSS_POLISH_DEFAULT_CASE_IDS, ",")), ",")
    return filter(!isempty, strip.(raw))
end

function _cross_polish_method_specs()
    residual_specs = withenv("ODEPE_RESIDUAL_SOLVER_KEYS" => "") do
        Dict(spec.key => spec for spec in _residual_solver_specs())
    end
    return [
        (
            key = :scalar_log,
            label = "Scalar log-space",
            kind = :scalar,
            coordinate_transform = :log_positive,
        ),
        (
            key = :residual_lso_lm_bounded_log,
            label = "Bounded LeastSquaresOptim LM log-space",
            kind = :residual,
            coordinate_transform = :log_positive,
            residual_spec = residual_specs[:residual_lso_lm_bounded],
        ),
        (
            key = :residual_fastlm_bounded_log,
            label = "Bounded FastLevenbergMarquardt log-space",
            kind = :residual,
            coordinate_transform = :log_positive,
            residual_spec = residual_specs[:residual_fastlm_bounded],
        ),
    ]
end

_cross_method_label(method_key::Symbol) = begin
    for spec in _cross_polish_method_specs()
        spec.key == method_key && return spec.label
    end
    return string(method_key)
end

function _candidate_err_value(candidate)
    if isnothing(candidate) || !(candidate isa ODEPE.ParameterEstimationResult)
        return Inf
    end
    err = candidate.err
    return isnothing(err) ? Inf : Float64(err)
end

function _candidate_distance(candidate_a, candidate_b)
    if isnothing(candidate_a) || isnothing(candidate_b)
        return Inf
    end
    try
        return ODEPE.solution_distance(candidate_a, candidate_b)
    catch
        return Inf
    end
end

function _report_oracle_candidate(report)
    get(report, :status, :missing) == :ok || return nothing
    analyzed_candidates = get(report, :analyzed_candidates, ODEPE.ParameterEstimationResult[])
    idx = get(report, :best_benchmark_index, nothing)
    idx isa Integer || return nothing
    1 <= idx <= length(analyzed_candidates) || return nothing
    candidate = analyzed_candidates[idx]
    return candidate isa ODEPE.ParameterEstimationResult ? candidate : nothing
end

function _report_selected_candidate(report)
    get(report, :status, :missing) == :ok || return nothing
    candidate = get(report, :selected_candidate, nothing)
    return candidate isa ODEPE.ParameterEstimationResult ? candidate : nothing
end

function _run_cross_polish_method(
    method_spec,
    pep::ODEPE.ParameterEstimationProblem,
    candidates::Vector{ODEPE.ParameterEstimationResult},
    run_opts::ODEPE.EstimationOptions,
)
    if method_spec.kind == :scalar
        return safe_polish_mode_report(pep, candidates, run_opts, method_spec.coordinate_transform)
    elseif method_spec.kind == :residual
        residual_spec = method_spec.residual_spec
        return safe_residual_mode_report(
            pep,
            candidates,
            run_opts,
            method_spec.coordinate_transform;
            optimizer_factory = residual_spec.optimizer_factory,
            solver_kind = residual_spec.solver_kind,
            jacobian_mode = residual_spec.jacobian_mode,
            bounds_mode = haskey(residual_spec, :bounds_mode) ? residual_spec.bounds_mode : :unbounded,
            solver_label = residual_spec.solver_label,
            required_package = residual_spec.package,
        )
    end
    error("Unsupported cross-polish method kind $(method_spec.kind)")
end

function _collect_source_seed_entries(
    pep::ODEPE.ParameterEstimationProblem,
    report::Dict{Symbol, Any};
    top_fit_k::Int = CROSS_POLISH_TOP_FIT_K,
)
    get(report, :status, :missing) == :ok || return Dict{Symbol, Any}[]
    analyzed_candidates = _typed_candidate_vector(get(report, :analyzed_candidates, ODEPE.ParameterEstimationResult[]))
    isempty(analyzed_candidates) && return Dict{Symbol, Any}[]

    fit_ranked = sort(analyzed_candidates; by = _candidate_err_value)
    requested = Tuple{String, ODEPE.ParameterEstimationResult}[]
    if CROSS_POLISH_SOURCE_MODE == :full_pool
        for (idx, candidate) in enumerate(fit_ranked)
            push!(requested, ("fit_rank_$(idx)", candidate))
        end
    else
        oracle_candidate = _report_oracle_candidate(report)
        !isnothing(oracle_candidate) && push!(requested, ("oracle_best", oracle_candidate))
        selected_candidate = _report_selected_candidate(report)
        !isnothing(selected_candidate) && push!(requested, ("fit_selected", selected_candidate))
        for (idx, candidate) in enumerate(fit_ranked[1:min(top_fit_k, length(fit_ranked))])
            push!(requested, ("top_fit_$(idx)", candidate))
        end
    end

    entries = Dict{Symbol, Any}[]
    for (role, candidate) in requested
        existing_idx = findfirst(entry ->
            _candidate_distance(candidate, entry[:candidate]) <= CROSS_POLISH_DISTANCE_THRESHOLD,
            entries,
        )
        if isnothing(existing_idx)
            push!(
                entries,
                Dict{Symbol, Any}(
                    :primary_role => role,
                    :roles => String[role],
                    :candidate => candidate,
                    :benchmark_metrics => _benchmark_metric_row(pep, candidate),
                    :local_metrics => _local_metric_row(pep, candidate),
                    :fit_objective => _candidate_err_value(candidate),
                ),
            )
        else
            push!(entries[existing_idx][:roles], role)
        end
    end

    return entries
end

function _build_cross_transfer_row(
    case_id::AbstractString,
    pep::ODEPE.ParameterEstimationProblem,
    source_method,
    target_method,
    seed_entry::Dict{Symbol, Any},
    run_opts::ODEPE.EstimationOptions,
    target_cold_report::Dict{Symbol, Any},
)
    source_candidate = seed_entry[:candidate]
    source_benchmark = seed_entry[:benchmark_metrics]
    source_fit_objective = seed_entry[:fit_objective]

    transfer_report = _run_cross_polish_method(
        target_method,
        pep,
        ODEPE.ParameterEstimationResult[source_candidate],
        run_opts,
    )

    transfer_oracle_candidate = _report_oracle_candidate(transfer_report)
    transfer_selected_candidate = _report_selected_candidate(transfer_report)
    target_cold_oracle_candidate = _report_oracle_candidate(target_cold_report)
    target_cold_selected_candidate = _report_selected_candidate(target_cold_report)

    transfer_best_benchmark = _benchmark_metric_row(pep, transfer_oracle_candidate)
    transfer_selected_benchmark = get(
        transfer_report,
        :selected_benchmark_metrics,
        Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
    )

    transfer_best_fit_objective = _candidate_err_value(transfer_oracle_candidate)
    transfer_selected_fit_objective = _candidate_err_value(transfer_selected_candidate)

    dist_to_target_oracle = _candidate_distance(transfer_oracle_candidate, target_cold_oracle_candidate)
    dist_to_target_selected = _candidate_distance(transfer_oracle_candidate, target_cold_selected_candidate)
    same_target_oracle = isfinite(dist_to_target_oracle) && dist_to_target_oracle <= CROSS_POLISH_DISTANCE_THRESHOLD
    same_target_selected = isfinite(dist_to_target_selected) && dist_to_target_selected <= CROSS_POLISH_DISTANCE_THRESHOLD

    return Dict{Symbol, Any}(
        :case_id => String(case_id),
        :source_method_key => source_method.key,
        :source_method_label => source_method.label,
        :target_method_key => target_method.key,
        :target_method_label => target_method.label,
        :seed_primary_role => seed_entry[:primary_role],
        :seed_roles => join(seed_entry[:roles], ","),
        :source_seed_benchmark_rmse => get(source_benchmark, :rmse, Inf),
        :source_seed_max_rel_err => get(source_benchmark, :max_rel_err, Inf),
        :source_seed_fit_objective => source_fit_objective,
        :target_cold_oracle_rmse => get(get(target_cold_report, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf),
        :target_cold_selected_rmse => get(get(target_cold_report, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf),
        :transfer_best_rmse => get(transfer_best_benchmark, :rmse, Inf),
        :transfer_selected_rmse => get(transfer_selected_benchmark, :rmse, Inf),
        :transfer_best_fit_objective => transfer_best_fit_objective,
        :transfer_selected_fit_objective => transfer_selected_fit_objective,
        :distance_to_target_oracle => dist_to_target_oracle,
        :distance_to_target_selected => dist_to_target_selected,
        :same_target_oracle => same_target_oracle,
        :same_target_selected => same_target_selected,
        :same_target_any => same_target_oracle || same_target_selected,
        :benchmark_improved_vs_seed => get(transfer_best_benchmark, :rmse, Inf) < get(source_benchmark, :rmse, Inf),
        :fit_improved_vs_seed => transfer_selected_fit_objective < source_fit_objective,
        :status => get(transfer_report, :status, :missing),
        :reason => get(transfer_report, :reason, ""),
        :transfer_runtime_seconds => get(transfer_report, :build_and_run_seconds, Inf),
    )
end

function _diagnose_case_transfer_rows(transfer_rows::Vector{Dict{Symbol, Any}})
    successful = filter(row ->
        row[:status] == :ok && isfinite(row[:transfer_best_rmse]),
        transfer_rows,
    )
    isempty(successful) && return Dict{Symbol, Any}(
        :diagnosis => :mixed,
        :successful_transfer_count => 0,
        :same_target_any_count => 0,
        :same_target_any_rate => 0.0,
    )

    same_any_count = count(row -> row[:same_target_any], successful)
    same_any_rate = same_any_count / length(successful)
    diagnosis = if same_any_rate >= 0.75
        :same_basin_likely
    elseif same_any_rate <= 0.25
        :different_basin_likely
    else
        :mixed
    end

    return Dict{Symbol, Any}(
        :diagnosis => diagnosis,
        :successful_transfer_count => length(successful),
        :same_target_any_count => same_any_count,
        :same_target_any_rate => same_any_rate,
    )
end

function build_cross_polish_case_artifact(case_id::AbstractString)
    case_spec = parse_case_spec(case_id)
    comparison_run = comparison_run_ordinal(case_spec)
    nopolish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_nopolish"))
    polish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_polish"))
    pep = polish_case.pep
    run_opts, box_meta = _resolve_research_run_opts(pep, polish_case.case_dir, polish_case.benchmark_opts)
    raw_candidates = ODEPE._load_benchmark_result_candidates(pep, run_opts, nopolish_case.case_dir)

    method_specs = _cross_polish_method_specs()
    cold_reports = Dict{Symbol, Any}()
    seed_entries = Dict{Symbol, Vector{Dict{Symbol, Any}}}()
    for method_spec in method_specs
        report = _run_cross_polish_method(method_spec, pep, raw_candidates, run_opts)
        cold_reports[method_spec.key] = report
        seed_entries[method_spec.key] = _collect_source_seed_entries(pep, report)
    end

    transfer_rows = Dict{Symbol, Any}[]
    for source_method in method_specs
        for target_method in method_specs
            source_method.key == target_method.key && continue
            target_cold_report = cold_reports[target_method.key]
            for seed_entry in seed_entries[source_method.key]
                push!(
                    transfer_rows,
                    _build_cross_transfer_row(
                        case_id,
                        pep,
                        source_method,
                        target_method,
                        seed_entry,
                        run_opts,
                        target_cold_report,
                    ),
                )
            end
        end
    end

    return Dict{Symbol, Any}(
        :case_id => String(case_id),
        :comparison_run => comparison_run,
        :raw_candidate_count => length(raw_candidates),
        :saved_amigo_metrics => load_selected_metrics(case_spec, "amigo2_run"; comparison_run = comparison_run),
        :saved_nopolish_metrics => load_selected_metrics(case_spec, "odepe_nopolish"; comparison_run = comparison_run),
        :saved_polish_metrics => load_selected_metrics(case_spec, "odepe_polish"; comparison_run = comparison_run),
        :box_meta => box_meta,
        :method_specs => method_specs,
        :cold_reports => cold_reports,
        :seed_entries => seed_entries,
        :transfer_rows => transfer_rows,
        :case_diagnosis => _diagnose_case_transfer_rows(transfer_rows),
    )
end

function build_cross_polish_case_artifact_safe(case_id::AbstractString)
    try
        return build_cross_polish_case_artifact(case_id)
    catch err
        return Dict{Symbol, Any}(
            :case_id => String(case_id),
            :artifact_error => sprint(showerror, err),
            :raw_candidate_count => 0,
            :saved_amigo_metrics => nothing,
            :saved_nopolish_metrics => nothing,
            :saved_polish_metrics => nothing,
            :box_meta => nothing,
            :method_specs => _cross_polish_method_specs(),
            :cold_reports => Dict{Symbol, Any}(),
            :seed_entries => Dict{Symbol, Vector{Dict{Symbol, Any}}}(),
            :transfer_rows => Dict{Symbol, Any}[],
            :case_diagnosis => Dict{Symbol, Any}(
                :diagnosis => :mixed,
                :successful_transfer_count => 0,
                :same_target_any_count => 0,
                :same_target_any_rate => 0.0,
            ),
        )
    end
end

function _flatten_transfer_rows(case_artifacts)
    rows = Dict{Symbol, Any}[]
    for artifact in case_artifacts
        append!(rows, get(artifact, :transfer_rows, Dict{Symbol, Any}[]))
    end
    return rows
end

function _pairwise_transfer_summary(transfer_rows::Vector{Dict{Symbol, Any}})
    grouped = Dict{Tuple{Symbol, Symbol}, Vector{Dict{Symbol, Any}}}()
    for row in transfer_rows
        key = (row[:source_method_key], row[:target_method_key])
        push!(get!(grouped, key, Dict{Symbol, Any}[]), row)
    end

    summaries = NamedTuple[]
    for (key, rows) in sort(collect(grouped); by = first)
        successful = filter(row -> row[:status] == :ok && isfinite(row[:transfer_best_rmse]), rows)
        same_oracle = count(row -> row[:same_target_oracle], successful)
        same_selected = count(row -> row[:same_target_selected], successful)
        same_any = count(row -> row[:same_target_any], successful)
        improved_benchmark = count(row -> row[:benchmark_improved_vs_seed], successful)
        improved_fit = count(row -> row[:fit_improved_vs_seed], successful)
        push!(
            summaries,
            (
                source_method_key = key[1],
                target_method_key = key[2],
                source_method_label = _cross_method_label(key[1]),
                target_method_label = _cross_method_label(key[2]),
                attempted = length(rows),
                successful = length(successful),
                same_oracle = same_oracle,
                same_selected = same_selected,
                same_any = same_any,
                improved_benchmark = improved_benchmark,
                improved_fit = improved_fit,
            ),
        )
    end
    return summaries
end

function render_cross_polish_summary_tsv(path::AbstractString, case_artifacts)
    mkpath(dirname(path))
    rows = _flatten_transfer_rows(case_artifacts)
    open(path, "w") do io
        println(
            io,
            join(
                [
                    "case_id",
                    "source_method_key",
                    "source_method_label",
                    "target_method_key",
                    "target_method_label",
                    "seed_primary_role",
                    "seed_roles",
                    "source_seed_benchmark_rmse",
                    "source_seed_max_rel_err",
                    "source_seed_fit_objective",
                    "target_cold_oracle_rmse",
                    "target_cold_selected_rmse",
                    "transfer_best_rmse",
                    "transfer_selected_rmse",
                    "transfer_best_fit_objective",
                    "transfer_selected_fit_objective",
                    "distance_to_target_oracle",
                    "distance_to_target_selected",
                    "same_target_oracle",
                    "same_target_selected",
                    "same_target_any",
                    "benchmark_improved_vs_seed",
                    "fit_improved_vs_seed",
                    "status",
                    "reason",
                    "transfer_runtime_seconds",
                ],
                '\t',
            ),
        )
        for row in rows
            println(
                io,
                join(
                    [
                        String(row[:case_id]),
                        string(row[:source_method_key]),
                        String(row[:source_method_label]),
                        string(row[:target_method_key]),
                        String(row[:target_method_label]),
                        String(row[:seed_primary_role]),
                        String(row[:seed_roles]),
                        string(row[:source_seed_benchmark_rmse]),
                        string(row[:source_seed_max_rel_err]),
                        string(row[:source_seed_fit_objective]),
                        string(row[:target_cold_oracle_rmse]),
                        string(row[:target_cold_selected_rmse]),
                        string(row[:transfer_best_rmse]),
                        string(row[:transfer_selected_rmse]),
                        string(row[:transfer_best_fit_objective]),
                        string(row[:transfer_selected_fit_objective]),
                        string(row[:distance_to_target_oracle]),
                        string(row[:distance_to_target_selected]),
                        string(row[:same_target_oracle]),
                        string(row[:same_target_selected]),
                        string(row[:same_target_any]),
                        string(row[:benchmark_improved_vs_seed]),
                        string(row[:fit_improved_vs_seed]),
                        string(row[:status]),
                        replace(String(get(row, :reason, "")), '\t' => ' '),
                        string(row[:transfer_runtime_seconds]),
                    ],
                    '\t',
                ),
            )
        end
    end
end

function render_cross_polish_summary_md(path::AbstractString, case_artifacts)
    mkpath(dirname(path))
    transfer_rows = _flatten_transfer_rows(case_artifacts)
    pairwise = _pairwise_transfer_summary(transfer_rows)
    generated_at = Dates.format(now(), Dates.DateFormat("yyyy-mm-dd HH:MM:SS"))
    open(path, "w") do io
        println(io, "# Cross-Polish Basin Diagnostic\n")
        println(io, "- Generated: `$(generated_at)`")
        println(io, "- Basis: imported bilby `odepe_nopolish` pools")
        println(io, "- Methods: `Scalar log-space`, `Bounded LeastSquaresOptim LM log-space`, `Bounded FastLevenbergMarquardt log-space`")
        println(io, "- Source seed mode: `$(_cross_polish_source_mode_label())`")
        println(io, "- Same-attractor threshold: `$(CROSS_POLISH_DISTANCE_THRESHOLD)` under `solution_distance(...)`\n")

        println(io, "## Pairwise Transfer Summary\n")
        println(io, "| Source → Target | Attempted | Successful | Same target oracle | Same target selected | Same either | Benchmark improved vs seed | Fit improved vs seed |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for row in pairwise
            println(
                io,
                "| `$(row.source_method_label)` → `$(row.target_method_label)` | $(row.attempted) | $(row.successful) | $(row.same_oracle) | $(row.same_selected) | $(row.same_any) | $(row.improved_benchmark) | $(row.improved_fit) |",
            )
        end

        println(io, "\n## Per-Case Diagnosis\n")
        println(io, "| Case | Diagnosis | Successful transfers | Same-attractor transfers | Same-attractor rate |")
        println(io, "| --- | --- | ---: | ---: | ---: |")
        for artifact in case_artifacts
            diagnosis = get(artifact[:case_diagnosis], :diagnosis, :mixed)
            successful_count = get(artifact[:case_diagnosis], :successful_transfer_count, 0)
            same_count = get(artifact[:case_diagnosis], :same_target_any_count, 0)
            same_rate = get(artifact[:case_diagnosis], :same_target_any_rate, 0.0)
            println(
                io,
                "| `$(artifact[:case_id])` | `$(diagnosis)` | $(successful_count) | $(same_count) | $(_format_float(same_rate; digits = 3)) |",
            )
        end

        strange_rows = filter(row ->
            row[:status] == :ok &&
            row[:fit_improved_vs_seed] &&
            !(row[:benchmark_improved_vs_seed]),
            transfer_rows,
        )
        println(io, "\n## Fit Improves But Benchmark Worsens\n")
        if isempty(strange_rows)
            println(io, "None observed.\n")
        else
            println(io, "| Case | Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Source fit | Transfer selected fit |")
            println(io, "| --- | --- | --- | ---: | ---: | ---: | ---: |")
            for row in strange_rows
                println(
                    io,
                    "| `$(row[:case_id])` | `$(row[:source_method_label])` → `$(row[:target_method_label])` | `$(row[:seed_roles])` | $(_fmt_pct(row[:source_seed_benchmark_rmse])) | $(_fmt_pct(row[:transfer_best_rmse])) | $(_format_float(row[:source_seed_fit_objective]; digits = 4)) | $(_format_float(row[:transfer_selected_fit_objective]; digits = 4)) |",
                )
            end
            println(io)
        end

        println(io, "## Notes\n")
        println(io, "- `summary.tsv` contains one row per transferred seed.")
        println(io, "- `case_notes.md` contains from-cold winners and detailed transfer tables per case.")
    end
end

function render_cross_polish_case_notes(path::AbstractString, case_artifacts)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Cross-Polish Case Notes\n")
        for artifact in case_artifacts
            println(io, "## `$(artifact[:case_id])`\n")
            if haskey(artifact, :artifact_error)
                println(io, "- Artifact build error: `$(artifact[:artifact_error])`\n")
                continue
            end
            println(io, "- Imported raw candidate count: `$(artifact[:raw_candidate_count])`")
            if !isnothing(get(artifact, :box_meta, nothing))
                println(io, "- Research box override: `$(artifact[:box_meta].source)`")
            end
            println(io, "- Saved references:")
            println(io, "  - `amigo2_run` RMSE: $(_fmt_pct(_maybe_get(_maybe_get(artifact, :saved_amigo_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - `odepe_nopolish` RMSE: $(_fmt_pct(_maybe_get(_maybe_get(artifact, :saved_nopolish_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - `odepe_polish` RMSE: $(_fmt_pct(_maybe_get(_maybe_get(artifact, :saved_polish_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "- Case diagnosis: `$(artifact[:case_diagnosis][:diagnosis])`\n")

            println(io, "### From-Cold Winners\n")
            println(io, "| Method | Oracle best RMSE | Fit-selected RMSE | Status |")
            println(io, "| --- | ---: | ---: | --- |")
            for method_spec in artifact[:method_specs]
                report = artifact[:cold_reports][method_spec.key]
                println(
                    io,
                    "| `$(method_spec.label)` | $(_fmt_pct(get(get(report, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | $(_fmt_pct(get(get(report, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | `$(get(report, :status, :missing))` |",
                )
            end

            println(io, "\n### Source Seeds\n")
            println(io, "| Method | Roles | Seed RMSE | Seed fit objective |")
            println(io, "| --- | --- | ---: | ---: |")
            for method_spec in artifact[:method_specs]
                for seed_entry in get(artifact[:seed_entries], method_spec.key, Dict{Symbol, Any}[])
                    seed_roles = join(seed_entry[:roles], ",")
                    println(
                        io,
                        "| `$(method_spec.label)` | `$(seed_roles)` | $(_fmt_pct(get(seed_entry[:benchmark_metrics], :rmse, Inf))) | $(_format_float(seed_entry[:fit_objective]; digits = 4)) |",
                    )
                end
            end

            println(io, "\n### Transfer Rows\n")
            println(io, "| Source → Target | Seed roles | Source RMSE | Transfer best RMSE | Transfer selected RMSE | Dist to target oracle | Dist to target selected | Same any | Benchmark improved | Fit improved | Status |")
            println(io, "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |")
            for row in get(artifact, :transfer_rows, Dict{Symbol, Any}[])
                println(
                    io,
                    "| `$(row[:source_method_label])` → `$(row[:target_method_label])` | `$(row[:seed_roles])` | $(_fmt_pct(row[:source_seed_benchmark_rmse])) | $(_fmt_pct(row[:transfer_best_rmse])) | $(_fmt_pct(row[:transfer_selected_rmse])) | $(_format_float(row[:distance_to_target_oracle]; digits = 4)) | $(_format_float(row[:distance_to_target_selected]; digits = 4)) | `$(row[:same_target_any])` | `$(row[:benchmark_improved_vs_seed])` | `$(row[:fit_improved_vs_seed])` | `$(row[:status])` |",
                )
            end
            println(io)
        end
    end
end

function render_cross_polish_progress(path::AbstractString, case_ids::AbstractVector{<:AbstractString}, artifacts)
    mkpath(dirname(path))
    updated_at = Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS")
    normalized_case_ids = String.(case_ids)
    completed_ids = String[artifact[:case_id] for artifact in artifacts]
    remaining = setdiff(normalized_case_ids, completed_ids)
    open(path, "w") do io
        println(io, "completed_cases=$(length(artifacts))")
        println(io, "requested_cases=$(length(normalized_case_ids))")
        println(io, "completed_case_ids=$(join(completed_ids, ','))")
        println(io, "remaining_case_ids=$(join(remaining, ','))")
        println(io, "updated_at=$(updated_at)")
    end
end

function main()
    mkpath(CROSS_POLISH_OUTPUT_ROOT)
    case_ids = selected_cross_polish_case_ids()
    artifacts = Dict{Symbol, Any}[]
    summary_tsv = joinpath(CROSS_POLISH_OUTPUT_ROOT, "summary.tsv")
    summary_md = joinpath(CROSS_POLISH_OUTPUT_ROOT, "summary.md")
    case_notes = joinpath(CROSS_POLISH_OUTPUT_ROOT, "case_notes.md")
    progress_path = joinpath(CROSS_POLISH_OUTPUT_ROOT, "progress.txt")

    for (idx, case_id) in enumerate(case_ids)
        println("[$idx/$(length(case_ids))] Running $(case_id)")
        artifact = build_cross_polish_case_artifact_safe(case_id)
        push!(artifacts, artifact)
        render_cross_polish_summary_tsv(summary_tsv, artifacts)
        render_cross_polish_summary_md(summary_md, artifacts)
        render_cross_polish_case_notes(case_notes, artifacts)
        render_cross_polish_progress(progress_path, case_ids, artifacts)
        println("[$idx/$(length(case_ids))] Flushed $(case_id)")
    end

    println("Wrote cross-polish basin diagnostic to $(CROSS_POLISH_OUTPUT_ROOT)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
