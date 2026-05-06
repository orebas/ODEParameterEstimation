using CSV
using Dates
using Statistics

const STANDARDIZATION_OUTPUT_ROOT = get(
    ENV,
    "ODEPE_STANDARDIZATION_OUTPUT_ROOT",
    joinpath(@__DIR__, "..", "artifacts", "diagnostics", "local_polish_standardization_1em4_hard"),
)

const STANDARDIZATION_NOISE_TAG = "1e-04"
const STANDARDIZATION_MIN_POLISH_RMSE = 0.1
const STANDARDIZATION_MIN_RATIO = 2.0
const STANDARDIZATION_EXCLUDED_SYSTEMS = Set(["cstr"])
const STANDARDIZATION_SOLVER_KEYS = [
    :residual_lso_lm_bounded,
    :residual_fastlm_bounded,
]

ENV["ODEPE_RESEARCH_ANALYSIS_MODE"] = get(ENV, "ODEPE_RESEARCH_ANALYSIS_MODE", "ungated")
ENV["ODEPE_RESIDUAL_SOLVER_KEYS"] = join(string.(STANDARDIZATION_SOLVER_KEYS), ",")

include(joinpath(@__DIR__, "generate_residual_polish_ablation.jl"))

const STANDARDIZATION_BEST_ARMS = [
    (:scalar_linear, "Scalar original-space"),
    (:scalar_log, "Scalar log-space"),
    (:residual_lso_lm_bounded_log, "Bounded LeastSquaresOptim LM log-space"),
    (:residual_fastlm_bounded_log, "Bounded FastLevenbergMarquardt log-space"),
]

function _fmt_ratio(x)
    if !isfinite(x)
        return "Inf"
    elseif abs(x) >= 1000 || (0 < abs(x) < 1e-3)
        return @sprintf("%.4e", x)
    else
        return @sprintf("%.2f", x)
    end
end

function _is_standard_positive_box(case_id::AbstractString)
    case_dir = case_dir_for_variant(case_id, "odepe_polish")
    return !isnothing(_benchmark_script_positive_box(case_dir, 1))
end

function _selected_rmse_for(spec::CaseSpec, method::AbstractString, comparison_run::Int)
    metrics = load_selected_metrics(spec, method; comparison_run = comparison_run)
    return isnothing(metrics) ? Inf : get(metrics, :rmse, Inf)
end

function select_standardization_suite()
    suite = NamedTuple[]
    comparison_ordinals = Dict{Tuple{String, String}, Int}()
    for row in CSV.File(RESULT_ROOT)
        String(row.run) == "odepe_nopolish" || continue
        spec = parse_case_spec(String(row.id))
        spec.noise_tag == STANDARDIZATION_NOISE_TAG || continue
        spec.system in STANDARDIZATION_EXCLUDED_SYSTEMS && continue
        _is_standard_positive_box(spec.case_id) || continue

        key = (spec.system, spec.noise_tag)
        ordinal = get(comparison_ordinals, key, 0) + 1
        comparison_ordinals[key] = ordinal

        amigo_rmse = _selected_rmse_for(spec, "amigo2_run", ordinal)
        polish_rmse = _selected_rmse_for(spec, "odepe_polish", ordinal)
        isfinite(amigo_rmse) && isfinite(polish_rmse) || continue
        amigo_rmse < polish_rmse || continue
        polish_rmse >= STANDARDIZATION_MIN_POLISH_RMSE || continue
        ratio = amigo_rmse == 0.0 ? Inf : polish_rmse / amigo_rmse
        ratio >= STANDARDIZATION_MIN_RATIO || continue

        push!(
            suite,
            (
                case_id = spec.case_id,
                system = spec.system,
                comparison_run = ordinal,
                amigo_rmse = amigo_rmse,
                polish_rmse = polish_rmse,
                ratio = ratio,
            ),
        )
    end

    sort!(
        suite;
        by = entry -> (
            -entry.ratio,
            -entry.polish_rmse,
            entry.system,
            entry.case_id,
        ),
    )
    return suite
end

function _suite_metadata_map(suite)
    return Dict(entry.case_id => entry for entry in suite)
end

function _write_suite_tsv(path::AbstractString, suite)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "case_id\tsystem\tcomparison_run\tsamigo_rmse\todepe_polish_rmse\tratio")
        for entry in suite
            println(
                io,
                join(
                    (
                        entry.case_id,
                        entry.system,
                        string(entry.comparison_run),
                        string(entry.amigo_rmse),
                        string(entry.polish_rmse),
                        string(entry.ratio),
                    ),
                    '\t',
                ),
            )
        end
    end
end

function _oracle_winner(artifact)
    best_key = nothing
    best_rmse = Inf
    for (key, _) in STANDARDIZATION_BEST_ARMS
        rmse = _arm_best_rmse(artifact, key)
        if rmse < best_rmse
            best_rmse = rmse
            best_key = key
        end
    end
    return best_key, best_rmse
end

function _selected_winner(artifact)
    best_key = nothing
    best_rmse = Inf
    for (key, _) in STANDARDIZATION_BEST_ARMS
        rmse = _arm_selected_rmse(artifact, key)
        if rmse < best_rmse
            best_rmse = rmse
            best_key = key
        end
    end
    return best_key, best_rmse
end

function _clear_winner_case_ids(case_artifacts, winner_key::Symbol; margin::Float64 = 0.8)
    result = String[]
    for artifact in case_artifacts
        pairs = [(key, _arm_best_rmse(artifact, key)) for (key, _) in STANDARDIZATION_BEST_ARMS]
        finite_pairs = filter(x -> isfinite(x[2]), pairs)
        length(finite_pairs) >= 2 || continue
        sort!(finite_pairs; by = last)
        finite_pairs[1][1] == winner_key || continue
        finite_pairs[1][2] <= margin * finite_pairs[2][2] || continue
        push!(result, artifact[:case_id])
    end
    return result
end

function _selection_gap_case_ids(case_artifacts; ratio_threshold::Float64 = 2.0)
    result = String[]
    for artifact in case_artifacts
        winner_key, best_rmse = _oracle_winner(artifact)
        isnothing(winner_key) && continue
        selected_rmse = _arm_selected_rmse(artifact, winner_key)
        isfinite(best_rmse) && isfinite(selected_rmse) || continue
        selected_rmse >= ratio_threshold * best_rmse || continue
        push!(result, artifact[:case_id])
    end
    return result
end

function _winner_label(key::Symbol)
    for (arm_key, label) in STANDARDIZATION_BEST_ARMS
        arm_key == key && return label
    end
    return string(key)
end

_winner_label(::Nothing) = "N/A"

function _parse_pct_string(x)
    s = strip(String(x))
    isempty(s) && return Inf
    s == "Inf" && return Inf
    endswith(s, "%") || return tryparse(Float64, s) === nothing ? Inf : something(tryparse(Float64, s), Inf)
    num = strip(chop(s; tail = 1))
    num == "Inf" && return Inf
    parsed = tryparse(Float64, num)
    return isnothing(parsed) ? Inf : parsed / 100
end

function _parse_runtime_seconds(x)
    s = replace(strip(String(x)), '`' => "")
    s = replace(s, " s" => "")
    parsed = tryparse(Float64, s)
    return isnothing(parsed) ? Inf : parsed
end

function _parse_float_like(x)
    if x isa Real
        return Float64(x)
    end
    parsed = tryparse(Float64, String(x))
    return isnothing(parsed) ? Inf : parsed
end

function _load_existing_standardization_artifacts(root::AbstractString)
    tsv_path = joinpath(root, "summary.tsv")
    md_path = joinpath(root, "summary.md")
    if !isfile(tsv_path) || !isfile(md_path)
        return Dict{String, Dict{Symbol, Any}}()
    end

    row_map = Dict{String, Dict{Symbol, Any}}()
    for row in CSV.File(tsv_path; delim = '\t')
        case_id = String(row.case_id)
        row_map[case_id] = Dict{Symbol, Any}(Symbol(name) => row[name] for name in propertynames(row))
    end

    artifacts = Dict{String, Dict{Symbol, Any}}()
    current_case = nothing
    current_arm = nothing
    current_artifact = nothing
    current_report = nothing
    for line in eachline(md_path)
        if (m = match(r"^### `(.+)`$", line)) !== nothing
            current_case = m.captures[1]
            row = row_map[current_case]
            current_artifact = Dict{Symbol, Any}(
                :case_id => current_case,
                :raw_candidate_count => 0,
                :research_analysis_mode => :ungated,
                :residual_solver_specs => _residual_solver_specs(),
                :box_meta => (source = :script_standard_positive_box,),
                :raw_stage_trace => Dict{Symbol, Any}(
                    :imported_best_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row[:imported_best_benchmark_rmse])),
                    :analyzed_best_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row[:analyzed_input_best_benchmark_rmse])),
                    :analyzed_selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row[:analyzed_input_selected_benchmark_rmse])),
                ),
                :saved_amigo_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row[:saved_amigo_rmse])),
                :saved_nopolish_metrics => Dict{Symbol, Any}(),
                :saved_polish_metrics => Dict{Symbol, Any}(:rmse => _parse_float_like(row[:saved_polish_rmse])),
            )
            artifacts[current_case] = current_artifact
            current_arm = nothing
            current_report = nothing
        elseif !isnothing(current_case) && startswith(line, "- Imported raw candidate count:")
            m = match(r"`(\d+)`", line)
            if !isnothing(m)
                current_artifact[:raw_candidate_count] = parse(Int, m.captures[1])
            end
        elseif !isnothing(current_case) && startswith(line, "  - `odepe_nopolish` RMSE:")
            current_artifact[:saved_nopolish_metrics] = Dict{Symbol, Any}(:rmse => _parse_pct_string(split(line, ": ", limit = 2)[2]))
        elseif !isnothing(current_case) && startswith(line, "- Research box override:")
            if (m = match(r"`([^`]+)`", line)) !== nothing
                current_artifact[:box_meta] = (source = Symbol(m.captures[1]),)
            end
        elseif !isnothing(current_case) && (m = match(r"^- (.+):$", line)) !== nothing
            label = m.captures[1]
            key = if label == "scalar original-space"
                :scalar_linear
            elseif label == "scalar log-space"
                :scalar_log
            elseif label == "residual LeastSquaresOptim LM bounded original-space"
                :residual_lso_lm_bounded_linear
            elseif label == "residual LeastSquaresOptim LM bounded log-space"
                :residual_lso_lm_bounded_log
            elseif label == "residual FastLevenbergMarquardt bounded original-space"
                :residual_fastlm_bounded_linear
            elseif label == "residual FastLevenbergMarquardt bounded log-space"
                :residual_fastlm_bounded_log
            else
                nothing
            end
            current_arm = key
            if !isnothing(key)
                current_report = Dict{Symbol, Any}()
                current_artifact[key] = current_report
            else
                current_report = nothing
            end
        elseif !isnothing(current_report) && startswith(line, "  - status:")
            current_report[:status] = Symbol(replace(split(line, '`')[2], "-" => "_"))
        elseif !isnothing(current_report) && startswith(line, "  - selected benchmark RMSE:")
            current_report[:selected_benchmark_metrics] = Dict{Symbol, Any}(:rmse => _parse_pct_string(split(line, ": ", limit = 2)[2]))
        elseif !isnothing(current_report) && startswith(line, "  - best-in-set benchmark RMSE:")
            current_report[:best_benchmark_metrics] = Dict{Symbol, Any}(:rmse => _parse_pct_string(split(line, ": ", limit = 2)[2]))
        elseif !isnothing(current_report) && startswith(line, "  - selected local relative RMSE:")
            current_report[:selected_local_metrics] = Dict{Symbol, Any}(:combined_rel_rmse => _parse_pct_string(split(line, ": ", limit = 2)[2]))
        elseif !isnothing(current_report) && startswith(line, "  - best-in-set local relative RMSE:")
            current_report[:best_local_metrics] = Dict{Symbol, Any}(:combined_rel_rmse => _parse_pct_string(split(line, ": ", limit = 2)[2]))
        elseif !isnothing(current_report) && startswith(line, "  - runtime:")
            current_report[:build_and_run_seconds] = _parse_runtime_seconds(split(line, ": ", limit = 2)[2])
        elseif !isnothing(current_report) && startswith(line, "  - polished representative count:")
            m = match(r"`(\d+)`", line)
            current_report[:cluster_rep_count] = isnothing(m) ? 0 : parse(Int, m.captures[1])
        elseif !isnothing(current_report) && startswith(line, "  - reason:")
            current_report[:reason] = split(line, ": ", limit = 2)[2]
        end
    end

    return artifacts
end

function render_standardization_summary(path::AbstractString, suite, case_artifacts)
    mkpath(dirname(path))
    suite_meta = _suite_metadata_map(suite)
    best_counts_lso = _comparison_counts(case_artifacts, :residual_lso_lm_bounded_log, :scalar_log; metric_fn = _arm_best_rmse)
    best_counts_fastlm = _comparison_counts(case_artifacts, :residual_fastlm_bounded_log, :scalar_log; metric_fn = _arm_best_rmse)
    best_counts_scalar_original = _comparison_counts(case_artifacts, :scalar_linear, :scalar_log; metric_fn = _arm_best_rmse)
    selected_counts_lso = _comparison_counts(case_artifacts, :residual_lso_lm_bounded_log, :scalar_log; metric_fn = _arm_selected_rmse)
    selected_counts_fastlm = _comparison_counts(case_artifacts, :residual_fastlm_bounded_log, :scalar_log; metric_fn = _arm_selected_rmse)
    selected_counts_scalar_original = _comparison_counts(case_artifacts, :scalar_linear, :scalar_log; metric_fn = _arm_selected_rmse)

    open(path, "w") do io
        println(io, "# Local Polish Standardization Sweep\n")
        println(io, "- Generated: `$(Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"))`")
        println(io, "- Basis: imported bilby `odepe_nopolish` pools")
        println(io, "- Research analysis mode: `ungated`")
        println(io, "- Decision metric: `best-in-set / oracle view`")
        println(io, "- Suite filter: positive-box `1e-4` cases, `amigo2 < odepe_polish`, saved `odepe_polish >= 10%`, ratio `>= 2x`, excluding `cstr`")
        println(io, "- Shortlist: `Scalar original-space`, `Scalar log-space`, `Bounded LeastSquaresOptim LM log-space`, `Bounded FastLevenbergMarquardt log-space`\n")

        println(io, "## Suite\n")
        println(io, "| Case | Saved `amigo2` | Saved `odepe_polish` | Gap Ratio |")
        println(io, "| --- | ---: | ---: | ---: |")
        for entry in suite
            println(io, "| `$(entry.case_id)` | $(_fmt_pct(entry.amigo_rmse)) | $(_fmt_pct(entry.polish_rmse)) | $(_fmt_ratio(entry.ratio))x |")
        end

        println(io, "\n## Best-In-Set / Oracle View\n")
        println(io, "| Case | Imported best | Saved `amigo2` | Saved `odepe_polish` | Scalar original-space | Scalar log-space | Bounded LeastSquaresOptim LM log-space | Bounded FastLevenbergMarquardt log-space |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for artifact in case_artifacts
            println(
                io,
                "| `$(artifact[:case_id])` | $(_fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :imported_best_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | $(_fmt_pct(suite_meta[artifact[:case_id]].amigo_rmse)) | $(_fmt_pct(suite_meta[artifact[:case_id]].polish_rmse)) | $(_fmt_pct(_arm_best_rmse(artifact, :scalar_linear))) | $(_fmt_pct(_arm_best_rmse(artifact, :scalar_log))) | $(_fmt_pct(_arm_best_rmse(artifact, :residual_lso_lm_bounded_log))) | $(_fmt_pct(_arm_best_rmse(artifact, :residual_fastlm_bounded_log))) |",
            )
        end

        println(io, "\n## Fit-Selected / Operational View\n")
        println(io, "| Case | Scalar original-space | Scalar log-space | Bounded LeastSquaresOptim LM log-space | Bounded FastLevenbergMarquardt log-space |")
        println(io, "| --- | ---: | ---: | ---: | ---: |")
        for artifact in case_artifacts
            println(
                io,
                "| `$(artifact[:case_id])` | $(_fmt_pct(_arm_selected_rmse(artifact, :scalar_linear))) | $(_fmt_pct(_arm_selected_rmse(artifact, :scalar_log))) | $(_fmt_pct(_arm_selected_rmse(artifact, :residual_lso_lm_bounded_log))) | $(_fmt_pct(_arm_selected_rmse(artifact, :residual_fastlm_bounded_log))) |",
            )
        end

        println(io, "\n## Aggregate Comparison vs `Scalar log-space`\n")
        println(io, "| Arm | Oracle best-in-set | Fit-selected | Median runtime ratio |")
        println(io, "| --- | --- | --- | ---: |")
        println(io, "| `Scalar original-space` | $(best_counts_scalar_original[:better]) better / $(best_counts_scalar_original[:tie]) tie / $(best_counts_scalar_original[:worse]) worse / $(best_counts_scalar_original[:unsupported]) unsupported | $(selected_counts_scalar_original[:better]) better / $(selected_counts_scalar_original[:tie]) tie / $(selected_counts_scalar_original[:worse]) worse / $(selected_counts_scalar_original[:unsupported]) unsupported | $(_format_float(best_counts_scalar_original[:median_runtime_ratio]; digits = 3))x |")
        println(io, "| `Bounded LeastSquaresOptim LM log-space` | $(best_counts_lso[:better]) better / $(best_counts_lso[:tie]) tie / $(best_counts_lso[:worse]) worse / $(best_counts_lso[:unsupported]) unsupported | $(selected_counts_lso[:better]) better / $(selected_counts_lso[:tie]) tie / $(selected_counts_lso[:worse]) worse / $(selected_counts_lso[:unsupported]) unsupported | $(_format_float(best_counts_lso[:median_runtime_ratio]; digits = 3))x |")
        println(io, "| `Bounded FastLevenbergMarquardt log-space` | $(best_counts_fastlm[:better]) better / $(best_counts_fastlm[:tie]) tie / $(best_counts_fastlm[:worse]) worse / $(best_counts_fastlm[:unsupported]) unsupported | $(selected_counts_fastlm[:better]) better / $(selected_counts_fastlm[:tie]) tie / $(selected_counts_fastlm[:worse]) worse / $(selected_counts_fastlm[:unsupported]) unsupported | $(_format_float(best_counts_fastlm[:median_runtime_ratio]; digits = 3))x |")

        println(io, "\n## Surprise Cases\n")
        println(io, "- Clear `Bounded LeastSquaresOptim LM log-space` wins: `$(join(_clear_winner_case_ids(case_artifacts, :residual_lso_lm_bounded_log), "`, `"))`")
        println(io, "- Clear `Bounded FastLevenbergMarquardt log-space` wins: `$(join(_clear_winner_case_ids(case_artifacts, :residual_fastlm_bounded_log), "`, `"))`")
        println(io, "- Clear `Scalar log-space` wins: `$(join(_clear_winner_case_ids(case_artifacts, :scalar_log), "`, `"))`")
        println(io, "- Large oracle-vs-selected gaps on the oracle-winning arm: `$(join(_selection_gap_case_ids(case_artifacts), "`, `"))`")

        println(io, "\n## Per-Case Oracle Winners\n")
        println(io, "| Case | Oracle winner | Oracle RMSE | Fit-selected RMSE on winner |")
        println(io, "| --- | --- | ---: | ---: |")
        for artifact in case_artifacts
            winner_key, winner_rmse = _oracle_winner(artifact)
            selected_rmse = isnothing(winner_key) ? Inf : _arm_selected_rmse(artifact, winner_key)
            println(io, "| `$(artifact[:case_id])` | `$(_winner_label(winner_key))` | $(_fmt_pct(winner_rmse)) | $(_fmt_pct(selected_rmse)) |")
        end
    end
end

function main()
    suite = select_standardization_suite()
    isempty(suite) && error("No cases matched the standardization-suite criteria")
    existing = _load_existing_standardization_artifacts(STANDARDIZATION_OUTPUT_ROOT)
    case_ids = [entry.case_id for entry in suite]
    artifacts = Dict{Symbol, Any}[existing[case_id] for case_id in case_ids if haskey(existing, case_id)]
    completed = Set(getindex.(artifacts, :case_id))
    remaining_case_ids = [case_id for case_id in case_ids if !(case_id in completed)]

    mkpath(STANDARDIZATION_OUTPUT_ROOT)
    _write_suite_tsv(joinpath(STANDARDIZATION_OUTPUT_ROOT, "suite.tsv"), suite)

    summary_tsv = joinpath(STANDARDIZATION_OUTPUT_ROOT, "summary.tsv")
    summary_md = joinpath(STANDARDIZATION_OUTPUT_ROOT, "summary.md")
    progress_path = joinpath(STANDARDIZATION_OUTPUT_ROOT, "progress.txt")
    clarified_path = joinpath(STANDARDIZATION_OUTPUT_ROOT, "summary_clarified.md")

    for (idx, case_id) in enumerate(remaining_case_ids)
        println("[$(length(artifacts) + 1)/$(length(case_ids))] Running $(case_id)")
        artifact = build_residual_case_artifact_safe(case_id)
        push!(artifacts, artifact)
        render_residual_summary_tsv(summary_tsv, artifacts)
        render_residual_summary_md(summary_md, artifacts)
        render_residual_progress(progress_path, case_ids, artifacts)
        render_standardization_summary(clarified_path, suite, artifacts)
        println("[$(length(artifacts))/$(length(case_ids))] Flushed $(case_id)")
    end

    println("Wrote standardization sweep to $(STANDARDIZATION_OUTPUT_ROOT)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
