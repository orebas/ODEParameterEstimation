using CSV
using Dates
using ODEParameterEstimation
using Printf
using Statistics

const ODEPE = ODEParameterEstimation
const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const CASE_ID = get(ENV, "ODEPE_DISCREPANCY_CASE_ID", get(ENV, "ODEPE_CRAUSTE_CASE_ID", "crauste_3_1em8"))
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "case_discrepancy_audit", CASE_ID)
const RESULT_ROOT = joinpath(BENCHMARK_ROOT, "result.csv")
const TOL = 1e-9

struct CaseSpec
    case_id::String
    system::String
    run_idx::Int
    noise_tag::String
end

function parse_case_spec(case_id::AbstractString)
    parts = split(String(case_id), "_")
    length(parts) < 3 && error("Invalid case id '$case_id'")
    system = join(parts[1:(end - 2)], "_")
    run_idx = parse(Int, parts[end - 1])
    noise_suffix = parts[end]
    noise_tag = if noise_suffix == "0"
        "0e+00"
    elseif noise_suffix == "1em8"
        "1e-08"
    elseif noise_suffix == "1em6"
        "1e-06"
    elseif noise_suffix == "1em4"
        "1e-04"
    elseif noise_suffix == "1em2"
        "1e-02"
    else
        error("Unsupported noise suffix '$noise_suffix'")
    end
    return CaseSpec(String(case_id), system, run_idx, noise_tag)
end

case_dir_for_variant(case_id::AbstractString, variant::AbstractString) =
    joinpath(BENCHMARK_ROOT, "filetree", variant, String(case_id))

comparison_path(spec::CaseSpec, method::AbstractString) =
    joinpath(BENCHMARK_ROOT, "analysis_results", "parameter_comparison_$(spec.system)_$(method)_noise_$(spec.noise_tag).csv")

function comparison_run_ordinal(spec::CaseSpec)
    isfile(RESULT_ROOT) || return spec.run_idx + 1
    rows = collect(CSV.File(RESULT_ROOT))
    filtered = filter(row ->
        String(row.name) == spec.system &&
        abs(Float64(row.noise) - parse(Float64, spec.noise_tag)) <= 0.0 &&
        String(row.run) == "odepe_nopolish",
        rows,
    )
    for (idx, row) in enumerate(filtered)
        String(row.id) == spec.case_id && return idx
    end
    return spec.run_idx + 1
end

result_csv_path(case_id::AbstractString, variant::AbstractString) =
    joinpath(case_dir_for_variant(case_id, variant), "result.csv")

stdout_path(case_id::AbstractString, variant::AbstractString) =
    joinpath(case_dir_for_variant(case_id, variant), "stdout.txt")

function load_selected_metrics(spec::CaseSpec, method::AbstractString; comparison_run::Int = comparison_run_ordinal(spec))
    path = comparison_path(spec, method)
    isfile(path) || return nothing
    for row in CSV.File(path)
        Int(row.Run) == comparison_run || continue
        return Dict{Symbol, Any}(
            :median_rel_err => Float64(row.MedianRelErr),
            :mean_rel_err => Float64(row.MeanRelErr),
            :max_rel_err => Float64(row.MaxRelErr),
            :rmse => Float64(row.RMSE),
            :success => Bool(row.Success),
        )
    end
    return nothing
end

function _safe_float(x)
    x isa Missing && return NaN
    return Float64(x)
end

function _fmt_pct(x)
    return ODEPE._fmt_percent(x)
end

function _format_float(x; digits::Int = 4)
    if x isa Nothing
        return "N/A"
    elseif !(x isa Real)
        return string(x)
    elseif !isfinite(x)
        return string(x)
    elseif abs(x) >= 1000 || (0 < abs(x) < 1e-3)
        return @sprintf("%.4e", x)
    else
        return @sprintf("%.*f", digits, x)
    end
end

function _normalize_name(name::AbstractString)
    return replace(replace(String(name), "(t)" => ""), "(0)" => "")
end

function _comparison_truth_est(row)
    truth = Dict{String, Float64}()
    est = Dict{String, Float64}()
    for field in propertynames(row)
        label = String(field)
        if startswith(label, "True_")
            truth[label[6:end]] = _safe_float(getproperty(row, field))
        elseif startswith(label, "Est_")
            est[label[5:end]] = _safe_float(getproperty(row, field))
        end
    end
    return truth, est
end

function _dict_abs_rmse(truth::Dict{String, Float64}, est::Dict{String, Float64})
    Set(keys(truth)) == Set(keys(est)) || error("Truth/estimate keys differ")
    vals = Float64[(truth[k] - est[k])^2 for k in keys(truth)]
    return isempty(vals) ? Inf : sqrt(sum(vals) / length(vals))
end

function _dict_rel_rmse(truth::Dict{String, Float64}, est::Dict{String, Float64})
    Set(keys(truth)) == Set(keys(est)) || error("Truth/estimate keys differ")
    vals = Float64[((est[k] - truth[k]) / max(abs(truth[k]), 1e-12))^2 for k in keys(truth)]
    return isempty(vals) ? Inf : sqrt(sum(vals) / length(vals))
end

function _result_truth_dict(pep::ODEPE.ParameterEstimationProblem)
    truth = Dict{String, Float64}()
    for (sym, value) in pep.p_true
        truth[_normalize_name(string(sym))] = Float64(value)
    end
    for (sym, value) in pep.ic
        truth[_normalize_name(string(sym))] = Float64(value)
    end
    return truth
end

function _candidate_value_dict(candidate::ODEPE.ParameterEstimationResult)
    values = Dict{String, Float64}()
    for (sym, value) in candidate.parameters
        values[_normalize_name(string(sym))] = Float64(value)
    end
    for (sym, value) in candidate.states
        values[_normalize_name(string(sym))] = Float64(value)
    end
    return values
end

function _candidate_benchmark_rmse(pep::ODEPE.ParameterEstimationProblem, candidate::ODEPE.ParameterEstimationResult)
    truth = _result_truth_dict(pep)
    est = _candidate_value_dict(candidate)
    return _dict_abs_rmse(truth, est)
end

function _candidate_local_rel_rmse(pep::ODEPE.ParameterEstimationProblem, candidate::ODEPE.ParameterEstimationResult)
    return get(ODEPE._candidate_truth_metrics(pep, candidate), :combined_rel_rmse, Inf)
end

function _typed_candidate_vector(candidates)
    typed = ODEPE.ParameterEstimationResult[]
    for candidate in candidates
        candidate isa ODEPE.ParameterEstimationResult || continue
        push!(typed, candidate)
    end
    return typed
end

function _best_candidate_by_metric(
    pep::ODEPE.ParameterEstimationProblem,
    candidates::Vector{ODEPE.ParameterEstimationResult},
    metric_fn,
)
    isempty(candidates) && return nothing, Inf
    best_idx = nothing
    best_value = Inf
    for (idx, candidate) in enumerate(candidates)
        value = metric_fn(pep, candidate)
        if value < best_value
            best_idx = idx
            best_value = value
        end
    end
    return best_idx, best_value
end

function _matching_candidate_index(
    candidates::Vector{ODEPE.ParameterEstimationResult},
    target::Dict{String, Float64};
    atol::Float64 = 1e-10,
    rtol::Float64 = 1e-9,
)
    for (idx, candidate) in enumerate(candidates)
        values = _candidate_value_dict(candidate)
        Set(keys(values)) == Set(keys(target)) || continue
        ok = true
        for (name, value) in target
            observed = values[name]
            if !(abs(observed - value) <= atol + rtol * max(abs(observed), abs(value), 1.0))
                ok = false
                break
            end
        end
        ok && return idx
    end
    return nothing
end

function _matching_csv_row_index(path::AbstractString, target::Dict{String, Float64})
    isfile(path) || return nothing
    for (idx, row) in enumerate(CSV.File(path))
        values = Dict{String, Float64}()
        for field in propertynames(row)
            name = String(field)
            haskey(target, name) || continue
            values[name] = _safe_float(getproperty(row, field))
        end
        Set(keys(values)) == Set(keys(target)) || continue
        ok = true
        for (name, value) in target
            observed = values[name]
            if !(abs(observed - value) <= 1e-10 + 1e-9 * max(abs(observed), abs(value), 1.0))
                ok = false
                break
            end
        end
        ok && return idx
    end
    return nothing
end

function _parse_stdout_counts(path::AbstractString)
    isfile(path) || return Dict{Symbol, Any}()
    text = read(path, String)
    raw_total_matches = collect(eachmatch(r"Found\s+(\d+)\s+solutions total across", text))
    saved_matches = collect(eachmatch(r"Number of solutions found:\s+(\d+)", text))
    return Dict{Symbol, Any}(
        :raw_total_solutions => isempty(raw_total_matches) ? missing : parse(Int, raw_total_matches[end].captures[1]),
        :saved_solution_count => isempty(saved_matches) ? missing : parse(Int, saved_matches[end].captures[1]),
    )
end

function _result_csv_row_count(path::AbstractString)
    isfile(path) || return 0
    return length(collect(CSV.File(path)))
end

function _load_non_identifiable(case_id::AbstractString, variant::AbstractString)
    isfile(RESULT_ROOT) || return String[]
    for row in CSV.File(RESULT_ROOT)
        String(row.id) == String(case_id) || continue
        String(row.run) == String(variant) || continue
        raw = strip(String(row.non_identifiable))
        raw in ("", "[]", "nan", "NaN") && return String[]
        stripped = strip(raw, ['[', ']'])
        isempty(strip(stripped)) && return String[]
        return [strip(replace(part, "'" => "", "\"" => "")) for part in split(stripped, ",") if !isempty(strip(part))]
    end
    return String[]
end

function _load_comparison_rows(spec::CaseSpec, method::AbstractString)
    path = comparison_path(spec, method)
    rows = NamedTuple[]
    for row in CSV.File(path)
        truth, est = _comparison_truth_est(row)
        push!(rows, (
            run = Int(row.Run),
            truth = truth,
            est = est,
            saved_rmse = Float64(row.RMSE),
            saved_mean_rel_err = Float64(row.MeanRelErr),
            saved_max_rel_err = Float64(row.MaxRelErr),
        ))
    end
    return rows
end

function _metric_probe_rows(spec::CaseSpec, method::AbstractString; comparison_run::Int = comparison_run_ordinal(spec))
    rows = _load_comparison_rows(spec, method)
    isempty(rows) && return NamedTuple[]
    selected = filter(row -> row.run == comparison_run, rows)
    other = filter(row -> row.run != comparison_run, rows)
    chosen = NamedTuple[]
    !isempty(selected) && push!(chosen, selected[1])
    if !isempty(other)
        best_other = sort(other, by = row -> row.saved_rmse)[1]
        push!(chosen, best_other)
    end
    return chosen
end

function _build_analyzed_trace(
    pep::ODEPE.ParameterEstimationProblem,
    candidates::Vector{ODEPE.ParameterEstimationResult},
)
    analyzed = ODEPE.analyze_estimation_result(pep, candidates; nooutput = true)
    analyzed_candidates = _typed_candidate_vector(analyzed[1])
    selected_idx, selected_candidate = ODEPE._best_fit_raw_candidate(analyzed_candidates)
    best_abs_idx, best_abs_rmse = _best_candidate_by_metric(pep, analyzed_candidates, _candidate_benchmark_rmse)
    best_rel_idx, best_rel_rmse = _best_candidate_by_metric(pep, analyzed_candidates, _candidate_local_rel_rmse)
    return Dict{Symbol, Any}(
        :input_count => length(candidates),
        :analyzed_count => length(analyzed_candidates),
        :selected_index => selected_idx,
        :selected_abs_rmse => isnothing(selected_candidate) ? Inf : _candidate_benchmark_rmse(pep, selected_candidate),
        :selected_rel_rmse => isnothing(selected_candidate) ? Inf : _candidate_local_rel_rmse(pep, selected_candidate),
        :best_abs_index => best_abs_idx,
        :best_abs_rmse => best_abs_rmse,
        :best_rel_index => best_rel_idx,
        :best_rel_rmse => best_rel_rmse,
        :analyzed_candidates => analyzed_candidates,
    )
end

function _best_exported_pool_rmse(
    pep::ODEPE.ParameterEstimationProblem,
    path::AbstractString,
)
    isfile(path) || return nothing, Inf
    truth = _result_truth_dict(pep)
    best_idx = nothing
    best_rmse = Inf
    for (idx, row) in enumerate(CSV.File(path))
        est = Dict{String, Float64}()
        valid = true
        for name in keys(truth)
            if !hasproperty(row, Symbol(name))
                valid = false
                break
            end
            value = _safe_float(getproperty(row, Symbol(name)))
            if !isfinite(value)
                valid = false
                break
            end
            est[name] = value
        end
        valid || continue
        rmse = _dict_abs_rmse(truth, est)
        if rmse < best_rmse
            best_idx = idx
            best_rmse = rmse
        end
    end
    return best_idx, best_rmse
end

function build_local_stock_trace(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    run_opts::ODEPE.EstimationOptions,
)
    ctx = ODEPE._build_polish_context(pep; opts = run_opts)
    cluster_meta = ODEPE._polish_cluster_metadata(ctx, raw_candidates; opts = run_opts)
    polished_pool = ODEPE._polish_batch_from_context(ctx, raw_candidates; opts = run_opts)
    analyzed = ODEPE.analyze_estimation_result(pep, polished_pool; nooutput = true)
    analyzed_candidates = _typed_candidate_vector(analyzed[1])
    selected_idx, selected_candidate = ODEPE._best_fit_raw_candidate(analyzed_candidates)
    best_abs_idx, best_abs_rmse = _best_candidate_by_metric(pep, analyzed_candidates, _candidate_benchmark_rmse)
    best_rel_idx, best_rel_rmse = _best_candidate_by_metric(pep, analyzed_candidates, _candidate_local_rel_rmse)

    return Dict{Symbol, Any}(
        :input_count => length(raw_candidates),
        :cluster_rep_count => length(cluster_meta.cluster_reps),
        :polished_pool_count => length(polished_pool),
        :analyzed_count => length(analyzed_candidates),
        :selected_index => selected_idx,
        :selected_abs_rmse => isnothing(selected_candidate) ? Inf : _candidate_benchmark_rmse(pep, selected_candidate),
        :selected_rel_rmse => isnothing(selected_candidate) ? Inf : _candidate_local_rel_rmse(pep, selected_candidate),
        :best_abs_index => best_abs_idx,
        :best_abs_rmse => best_abs_rmse,
        :best_rel_index => best_rel_idx,
        :best_rel_rmse => best_rel_rmse,
    )
end

function build_artifact(case_id::AbstractString)
    spec = parse_case_spec(case_id)
    comparison_run = comparison_run_ordinal(spec)
    nopolish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_nopolish"))
    polish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_polish"))
    pep = polish_case.pep
    datasize = isnothing(pep.data_sample) || !haskey(pep.data_sample, "t") ? 0 : length(pep.data_sample["t"])

    run_opts = ODEPE.merge_options(
        isnothing(polish_case.benchmark_opts) ? ODEPE.EstimationOptions() : polish_case.benchmark_opts;
        datasize = datasize,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = true,
    )

    imported_nopolish = ODEPE._load_benchmark_result_candidates(pep, run_opts, nopolish_case.case_dir)
    imported_polish = ODEPE._load_benchmark_result_candidates(pep, run_opts, polish_case.case_dir)
    analyzed_nopolish_trace = _build_analyzed_trace(pep, imported_nopolish)
    analyzed_polish_trace = _build_analyzed_trace(pep, imported_polish)

    nopolish_stdout = _parse_stdout_counts(stdout_path(case_id, "odepe_nopolish"))
    polish_stdout = _parse_stdout_counts(stdout_path(case_id, "odepe_polish"))
    nopolish_rows = _result_csv_row_count(result_csv_path(case_id, "odepe_nopolish"))
    polish_rows = _result_csv_row_count(result_csv_path(case_id, "odepe_polish"))
    non_identifiable = _load_non_identifiable(case_id, "odepe_polish")

    metric_probe_rows = _metric_probe_rows(spec, "odepe_polish"; comparison_run = comparison_run)
    metric_records = NamedTuple[]
    for row in metric_probe_rows
        push!(metric_records, (
            run = row.run,
            saved_rmse = row.saved_rmse,
            recomputed_abs_rmse = _dict_abs_rmse(row.truth, row.est),
            recomputed_rel_rmse = _dict_rel_rmse(row.truth, row.est),
            saved_mean_rel_err = row.saved_mean_rel_err,
            saved_max_rel_err = row.saved_max_rel_err,
        ))
    end

    saved_nopolish_selected = load_selected_metrics(spec, "odepe_nopolish"; comparison_run = comparison_run)
    saved_polish_selected = load_selected_metrics(spec, "odepe_polish"; comparison_run = comparison_run)

    raw_best_abs_idx, raw_best_abs_rmse = _best_candidate_by_metric(pep, imported_nopolish, _candidate_benchmark_rmse)
    raw_best_rel_idx, raw_best_rel_rmse = _best_candidate_by_metric(pep, imported_nopolish, _candidate_local_rel_rmse)
    polish_best_abs_idx, polish_best_abs_rmse = _best_candidate_by_metric(pep, imported_polish, _candidate_benchmark_rmse)
    polish_best_rel_idx, polish_best_rel_rmse = _best_candidate_by_metric(pep, imported_polish, _candidate_local_rel_rmse)
    exported_nopolish_best_idx, exported_nopolish_best_rmse = _best_exported_pool_rmse(pep, result_csv_path(case_id, "odepe_nopolish"))
    exported_polish_best_idx, exported_polish_best_rmse = _best_exported_pool_rmse(pep, result_csv_path(case_id, "odepe_polish"))

    selected_polish_row = isempty(metric_probe_rows) ? nothing : metric_probe_rows[1]
    selected_polish_match_index = isnothing(selected_polish_row) ? nothing : _matching_candidate_index(imported_polish, selected_polish_row.est)
    selected_polish_export_match_index = isnothing(selected_polish_row) ? nothing : _matching_csv_row_index(result_csv_path(case_id, "odepe_polish"), selected_polish_row.est)
    selected_nopolish_rows = _metric_probe_rows(spec, "odepe_nopolish"; comparison_run = comparison_run)
    selected_nopolish_row = isempty(selected_nopolish_rows) ? nothing : selected_nopolish_rows[1]
    selected_nopolish_match_index = isnothing(selected_nopolish_row) ? nothing : _matching_candidate_index(imported_nopolish, selected_nopolish_row.est)
    selected_nopolish_export_match_index = isnothing(selected_nopolish_row) ? nothing : _matching_csv_row_index(result_csv_path(case_id, "odepe_nopolish"), selected_nopolish_row.est)
    selected_nopolish_analyzed_match_index = isnothing(selected_nopolish_row) ? nothing : _matching_candidate_index(analyzed_nopolish_trace[:analyzed_candidates], selected_nopolish_row.est)
    selected_polish_analyzed_match_index = isnothing(selected_polish_row) ? nothing : _matching_candidate_index(analyzed_polish_trace[:analyzed_candidates], selected_polish_row.est)
    nopolish_in_polish_count = count(candidate -> !isnothing(_matching_candidate_index(imported_polish, _candidate_value_dict(candidate))), imported_nopolish)

    stock_trace = build_local_stock_trace(pep, imported_nopolish, run_opts)

    pool_semantics_mismatch = (
        get(nopolish_stdout, :raw_total_solutions, missing) !== missing &&
        Int(get(nopolish_stdout, :raw_total_solutions, 0)) > nopolish_rows
    )
    metric_definition_mismatch = !isempty(metric_records) &&
        abs(metric_records[1].recomputed_abs_rmse - metric_records[1].saved_rmse) <= 1e-9 &&
        abs(metric_records[1].recomputed_rel_rmse - metric_records[1].saved_rmse) > 1e-6
    local_polish_bucket = "unresolved"

    return Dict{Symbol, Any}(
        :case_id => String(case_id),
        :spec => spec,
        :comparison_run => comparison_run,
        :saved_nopolish_selected => saved_nopolish_selected,
        :saved_polish_selected => saved_polish_selected,
        :non_identifiable => non_identifiable,
        :nopolish_stdout => nopolish_stdout,
        :polish_stdout => polish_stdout,
        :nopolish_rows => nopolish_rows,
        :polish_rows => polish_rows,
        :imported_nopolish_count => length(imported_nopolish),
        :imported_polish_count => length(imported_polish),
        :metric_records => metric_records,
        :raw_best_abs_idx => raw_best_abs_idx,
        :raw_best_abs_rmse => raw_best_abs_rmse,
        :raw_best_rel_idx => raw_best_rel_idx,
        :raw_best_rel_rmse => raw_best_rel_rmse,
        :analyzed_nopolish_trace => analyzed_nopolish_trace,
        :polish_best_abs_idx => polish_best_abs_idx,
        :polish_best_abs_rmse => polish_best_abs_rmse,
        :polish_best_rel_idx => polish_best_rel_idx,
        :polish_best_rel_rmse => polish_best_rel_rmse,
        :analyzed_polish_trace => analyzed_polish_trace,
        :exported_nopolish_best_idx => exported_nopolish_best_idx,
        :exported_nopolish_best_rmse => exported_nopolish_best_rmse,
        :exported_polish_best_idx => exported_polish_best_idx,
        :exported_polish_best_rmse => exported_polish_best_rmse,
        :selected_nopolish_match_index => selected_nopolish_match_index,
        :selected_nopolish_export_match_index => selected_nopolish_export_match_index,
        :selected_nopolish_analyzed_match_index => selected_nopolish_analyzed_match_index,
        :selected_polish_match_index => selected_polish_match_index,
        :selected_polish_export_match_index => selected_polish_export_match_index,
        :selected_polish_analyzed_match_index => selected_polish_analyzed_match_index,
        :nopolish_in_polish_count => nopolish_in_polish_count,
        :stock_trace => stock_trace,
        :pool_semantics_mismatch => pool_semantics_mismatch,
        :metric_definition_mismatch => metric_definition_mismatch,
        :local_polish_bucket => local_polish_bucket,
    )
end

function render_pool_summary_tsv(path::String, artifact::Dict{Symbol, Any})
    open(path, "w") do io
        println(io, join([
            "variant",
            "stdout_raw_total_solutions",
            "stdout_saved_solution_count",
            "result_csv_rows",
            "imported_candidate_count",
        ], '\t'))
        for variant in ("odepe_nopolish", "odepe_polish")
            counts = artifact[Symbol(replace(variant, "odepe_" => "") * "_stdout")]
            rows = artifact[Symbol(replace(variant, "odepe_" => "") * "_rows")]
            imported = artifact[Symbol("imported_" * replace(variant, "odepe_" => "") * "_count")]
            println(io, join([
                variant,
                string(get(counts, :raw_total_solutions, missing)),
                string(get(counts, :saved_solution_count, missing)),
                string(rows),
                string(imported),
            ], '\t'))
        end
    end
end

function render_metric_audit_tsv(path::String, artifact::Dict{Symbol, Any})
    open(path, "w") do io
        println(io, join([
            "source",
            "run",
            "saved_rmse",
            "recomputed_abs_rmse",
            "recomputed_rel_rmse",
            "saved_mean_rel_err",
            "saved_max_rel_err",
        ], '\t'))
        for record in artifact[:metric_records]
            println(io, join([
                "parameter_comparison_odepe_polish",
                string(record.run),
                string(record.saved_rmse),
                string(record.recomputed_abs_rmse),
                string(record.recomputed_rel_rmse),
                string(record.saved_mean_rel_err),
                string(record.saved_max_rel_err),
            ], '\t'))
        end
        println(io, join([
            "exported_odepe_nopolish_best",
            "",
            "",
            string(artifact[:exported_nopolish_best_rmse]),
            "",
            "",
            "",
        ], '\t'))
        println(io, join([
            "imported_odepe_nopolish_best",
            "",
            "",
            string(artifact[:raw_best_abs_rmse]),
            string(artifact[:raw_best_rel_rmse]),
            "",
            "",
        ], '\t'))
        println(io, join([
            "analyzed_odepe_nopolish_best",
            "",
            "",
            string(artifact[:analyzed_nopolish_trace][:best_abs_rmse]),
            string(artifact[:analyzed_nopolish_trace][:best_rel_rmse]),
            "",
            "",
        ], '\t'))
        println(io, join([
            "exported_odepe_polish_best",
            "",
            string(get(artifact[:saved_polish_selected], :rmse, Inf)),
            string(artifact[:exported_polish_best_rmse]),
            "",
            string(get(artifact[:saved_polish_selected], :mean_rel_err, Inf)),
            string(get(artifact[:saved_polish_selected], :max_rel_err, Inf)),
        ], '\t'))
        println(io, join([
            "imported_odepe_polish_best",
            "",
            string(get(artifact[:saved_polish_selected], :rmse, Inf)),
            string(artifact[:polish_best_abs_rmse]),
            string(artifact[:polish_best_rel_rmse]),
            string(get(artifact[:saved_polish_selected], :mean_rel_err, Inf)),
            string(get(artifact[:saved_polish_selected], :max_rel_err, Inf)),
        ], '\t'))
        println(io, join([
            "analyzed_odepe_polish_best",
            "",
            string(get(artifact[:saved_polish_selected], :rmse, Inf)),
            string(artifact[:analyzed_polish_trace][:best_abs_rmse]),
            string(artifact[:analyzed_polish_trace][:best_rel_rmse]),
            string(get(artifact[:saved_polish_selected], :mean_rel_err, Inf)),
            string(get(artifact[:saved_polish_selected], :max_rel_err, Inf)),
        ], '\t'))
        println(io, join([
            "local_stock_on_imported_nopolish",
            "",
            "",
            string(artifact[:stock_trace][:best_abs_rmse]),
            string(artifact[:stock_trace][:best_rel_rmse]),
            "",
            "",
        ], '\t'))
    end
end

function render_stock_trace_tsv(path::String, artifact::Dict{Symbol, Any})
    trace = artifact[:stock_trace]
    open(path, "w") do io
        println(io, join([
            "input_count",
            "cluster_rep_count",
            "polished_pool_count",
            "analyzed_count",
            "selected_index",
            "selected_abs_rmse",
            "selected_rel_rmse",
            "best_abs_index",
            "best_abs_rmse",
            "best_rel_index",
            "best_rel_rmse",
        ], '\t'))
        println(io, join([
            string(trace[:input_count]),
            string(trace[:cluster_rep_count]),
            string(trace[:polished_pool_count]),
            string(trace[:analyzed_count]),
            string(trace[:selected_index]),
            string(trace[:selected_abs_rmse]),
            string(trace[:selected_rel_rmse]),
            string(trace[:best_abs_index]),
            string(trace[:best_abs_rmse]),
            string(trace[:best_rel_index]),
            string(trace[:best_rel_rmse]),
        ], '\t'))
    end
end

function render_summary_markdown(path::String, artifact::Dict{Symbol, Any})
    open(path, "w") do io
        println(io, "# Case Discrepancy Audit\n")
        println(io, "- Case: `$(artifact[:case_id])`")
        println(io, "- Comparison-table run ordinal: `$(artifact[:comparison_run])`")
        println(io, "- Generated: `$(Dates.now())`")
        println(io, "- Benchmark root: `$(BENCHMARK_ROOT)`")
        println(io, "- Goal: bucket the mismatch into benchmark/export, import/analyze, or local polish-path differences\n")

        println(io, "## Pool Semantics\n")
        println(io, "| Variant | Stdout Raw Total | Stdout Saved Count | `result.csv` Rows | Imported Candidate Count |")
        println(io, "| --- | ---: | ---: | ---: | ---: |")
        println(io, "| `odepe_nopolish` | $(get(artifact[:nopolish_stdout], :raw_total_solutions, missing)) | $(get(artifact[:nopolish_stdout], :saved_solution_count, missing)) | $(artifact[:nopolish_rows]) | $(artifact[:imported_nopolish_count]) |")
        println(io, "| `odepe_polish` | $(get(artifact[:polish_stdout], :raw_total_solutions, missing)) | $(get(artifact[:polish_stdout], :saved_solution_count, missing)) | $(artifact[:polish_rows]) | $(artifact[:imported_polish_count]) |\n")
        println(io, "- `odepe_nopolish` saved/exported pool is far smaller than the raw total found during search.")
        println(io, "- `odepe_polish` exported pool contains `$(artifact[:nopolish_in_polish_count]) / $(artifact[:imported_nopolish_count])` exact `odepe_nopolish` candidates, plus many additional rows.")
        println(io, "- Benchmark-selected `odepe_nopolish` estimate found in exported `odepe_nopolish/result.csv`: `$(isnothing(artifact[:selected_nopolish_export_match_index]) ? "no" : "yes, row $(artifact[:selected_nopolish_export_match_index])")`")
        println(io, "- Benchmark-selected `odepe_polish` estimate found in exported `odepe_polish/result.csv`: `$(isnothing(artifact[:selected_polish_export_match_index]) ? "no" : "yes, row $(artifact[:selected_polish_export_match_index])")`")
        println(io, "- Pool-semantics bucket: `$(artifact[:pool_semantics_mismatch] ? "YES" : "NO")`\n")

        println(io, "## Metric Reconciliation\n")
        println(io, "- Benchmark `RMSE` in `summarize_results.py` is plain absolute RMSE over merged states + parameters, optionally filtering `non_identifiable` names.")
        println(io, "- Local `combined_rel_rmse` is relative RMSE over merged states + parameters.")
        println(io, "- Non-identifiable list for this case: `$(isempty(artifact[:non_identifiable]) ? "[]" : string(artifact[:non_identifiable]))`\n")
        println(io, "| Probe Row | Saved RMSE | Recomputed Benchmark RMSE | Recomputed Local Relative RMSE | Saved Mean Rel Err | Saved Max Rel Err |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: |")
        for record in artifact[:metric_records]
            println(io, "| `run $(record.run)` | $(_format_float(record.saved_rmse; digits = 6)) | $(_format_float(record.recomputed_abs_rmse; digits = 6)) | $(_fmt_pct(record.recomputed_rel_rmse)) | $(_fmt_pct(record.saved_mean_rel_err)) | $(_fmt_pct(record.saved_max_rel_err)) |")
        end
        println(io)
        println(io, "| Stage | Best Benchmark RMSE | Best Local Relative RMSE |")
        println(io, "| --- | ---: | ---: |")
        println(io, "| Exported `odepe_nopolish/result.csv` | $(_format_float(artifact[:exported_nopolish_best_rmse]; digits = 6)) | N/A |")
        println(io, "| Imported `odepe_nopolish` | $(_format_float(artifact[:raw_best_abs_rmse]; digits = 6)) | $(_fmt_pct(artifact[:raw_best_rel_rmse])) |")
        println(io, "| Analyzed imported `odepe_nopolish` | $(_format_float(artifact[:analyzed_nopolish_trace][:best_abs_rmse]; digits = 6)) | $(_fmt_pct(artifact[:analyzed_nopolish_trace][:best_rel_rmse])) |")
        println(io, "| Local stock polish on imported `odepe_nopolish` | $(_format_float(artifact[:stock_trace][:best_abs_rmse]; digits = 6)) | $(_fmt_pct(artifact[:stock_trace][:best_rel_rmse])) |")
        println(io, "| Exported `odepe_polish/result.csv` | $(_format_float(artifact[:exported_polish_best_rmse]; digits = 6)) | N/A |")
        println(io, "| Imported `odepe_polish` | $(_format_float(artifact[:polish_best_abs_rmse]; digits = 6)) | $(_fmt_pct(artifact[:polish_best_rel_rmse])) |")
        println(io, "| Analyzed imported `odepe_polish` | $(_format_float(artifact[:analyzed_polish_trace][:best_abs_rmse]; digits = 6)) | $(_fmt_pct(artifact[:analyzed_polish_trace][:best_rel_rmse])) |\n")
        println(io, "- Benchmark-selected `odepe_nopolish` RMSE from analysis CSV: $(_format_float(get(artifact[:saved_nopolish_selected], :rmse, Inf); digits = 6))")
        println(io, "- Benchmark-selected `odepe_polish` RMSE from analysis CSV: $(_format_float(get(artifact[:saved_polish_selected], :rmse, Inf); digits = 6))")
        println(io, "- Benchmark-selected `odepe_nopolish` estimate survives import: `$(isnothing(artifact[:selected_nopolish_match_index]) ? "no" : "yes, row $(artifact[:selected_nopolish_match_index])")`")
        println(io, "- Benchmark-selected `odepe_nopolish` estimate survives analysis-before-polish: `$(isnothing(artifact[:selected_nopolish_analyzed_match_index]) ? "no" : "yes, row $(artifact[:selected_nopolish_analyzed_match_index])")`")
        println(io, "- Benchmark-selected `odepe_polish` estimate survives import: `$(isnothing(artifact[:selected_polish_match_index]) ? "no" : "yes, row $(artifact[:selected_polish_match_index])")`")
        println(io, "- Benchmark-selected `odepe_polish` estimate survives analysis-before-polish: `$(isnothing(artifact[:selected_polish_analyzed_match_index]) ? "no" : "yes, row $(artifact[:selected_polish_analyzed_match_index])")`")
        println(io, "- Metric-definition bucket: `$(artifact[:metric_definition_mismatch] ? "YES" : "NO")`\n")

        println(io, "## Local Stock Polish Trace\n")
        println(io, "| Input Rows | Unique Polish Starts | Polished Pool Rows | Analyzed Rows | Selected Benchmark RMSE | Selected Local Relative RMSE | Best Benchmark RMSE | Best Local Relative RMSE |")
        println(io, "| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        println(io, "| $(artifact[:stock_trace][:input_count]) | $(artifact[:stock_trace][:cluster_rep_count]) | $(artifact[:stock_trace][:polished_pool_count]) | $(artifact[:stock_trace][:analyzed_count]) | $(_format_float(artifact[:stock_trace][:selected_abs_rmse]; digits = 6)) | $(_fmt_pct(artifact[:stock_trace][:selected_rel_rmse])) | $(_format_float(artifact[:stock_trace][:best_abs_rmse]; digits = 6)) | $(_fmt_pct(artifact[:stock_trace][:best_rel_rmse])) |\n")
        println(io, "- Saved `odepe_nopolish` selected benchmark RMSE: $(_format_float(get(artifact[:saved_nopolish_selected], :rmse, Inf); digits = 6))")
        println(io, "- Saved `odepe_polish` selected benchmark RMSE: $(_format_float(get(artifact[:saved_polish_selected], :rmse, Inf); digits = 6))")
        println(io, "- Local stock-polish bucket: `$(artifact[:local_polish_bucket])`\n")

        println(io, "## Bucket Verdict\n")
        println(io, "- `Pool semantics mismatch`: `$(artifact[:pool_semantics_mismatch] ? "YES" : "NO")`")
        println(io, "- `Metric-definition mismatch`: `$(artifact[:metric_definition_mismatch] ? "YES" : "NO")`")
        println(io, "- `Local polish-path mismatch`: `$(artifact[:local_polish_bucket])`")
        println(io)
        println(io, "Current best reading:")
        println(io, "- The saved `odepe_nopolish/result.csv` file is not a proxy for the full raw search population.")
        println(io, "- Prior comparisons mixed absolute benchmark RMSE with local relative RMSE, which inflated apparent disagreement.")
        println(io, "- This artifact identifies whether the discrepancy is already present in the exported pool, introduced on import/analysis, or introduced during local stock polish.")
    end
end

function main()
    mkpath(OUTPUT_ROOT)
    artifact = build_artifact(CASE_ID)
    render_pool_summary_tsv(joinpath(OUTPUT_ROOT, "pool_summary.tsv"), artifact)
    render_metric_audit_tsv(joinpath(OUTPUT_ROOT, "metric_audit.tsv"), artifact)
    render_stock_trace_tsv(joinpath(OUTPUT_ROOT, "stock_polish_trace.tsv"), artifact)
    render_summary_markdown(joinpath(OUTPUT_ROOT, "summary.md"), artifact)
    println("Wrote case discrepancy audit artifact to:")
    println("  " * joinpath(OUTPUT_ROOT, "summary.md"))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
