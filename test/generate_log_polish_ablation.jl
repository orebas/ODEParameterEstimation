using CSV
using Dates
using ODEParameterEstimation
using Optimization
using Printf

const ODEPE = ODEParameterEstimation
const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const RESULT_ROOT = joinpath(BENCHMARK_ROOT, "result.csv")
const DEFAULT_CASE_IDS = ["crauste_3_1em8", "cstr_1_1em8", "seir_7_1em4"]
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "log_polish_ablation")
const SUCCESS_TOL = 0.1

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

function selected_case_ids()
    raw = split(get(ENV, "ODEPE_LOG_POLISH_CASE_IDS", join(DEFAULT_CASE_IDS, ",")), ",")
    return filter(!isempty, strip.(raw))
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

function _normalize_name(name::AbstractString)
    return replace(replace(String(name), "(t)" => ""), "(0)" => "")
end

function _truth_lookup(pep::ODEPE.ParameterEstimationProblem)
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

function _benchmark_metric_row(pep::ODEPE.ParameterEstimationProblem, candidate::Union{Nothing, ODEPE.ParameterEstimationResult})
    if isnothing(candidate)
        return Dict{Symbol, Any}(
            :rmse => Inf,
            :max_rel_err => Inf,
            :success => false,
            :n_coords => 0,
        )
    end
    truth = _truth_lookup(pep)
    est = _candidate_value_dict(candidate)
    Set(keys(truth)) == Set(keys(est)) || return Dict{Symbol, Any}(
        :rmse => Inf,
        :max_rel_err => Inf,
        :success => false,
        :n_coords => length(truth),
    )
    sqerrs = Float64[]
    relerrs = Float64[]
    for name in keys(truth)
        tv = truth[name]
        ev = est[name]
        push!(sqerrs, (tv - ev)^2)
        push!(relerrs, abs(ev - tv) / max(abs(tv), 1e-12))
    end
    rmse = isempty(sqerrs) ? Inf : sqrt(sum(sqerrs) / length(sqerrs))
    max_rel = isempty(relerrs) ? Inf : maximum(relerrs)
    return Dict{Symbol, Any}(
        :rmse => rmse,
        :max_rel_err => max_rel,
        :success => isfinite(max_rel) && max_rel <= SUCCESS_TOL,
        :n_coords => length(sqerrs),
    )
end

function _local_metric_row(pep::ODEPE.ParameterEstimationProblem, candidate::Union{Nothing, ODEPE.ParameterEstimationResult})
    metrics = ODEPE._candidate_truth_metrics(pep, candidate)
    return Dict{Symbol, Any}(
        :combined_rel_rmse => get(metrics, :combined_rel_rmse, Inf),
        :worst_row => get(metrics, :worst_row, nothing),
    )
end

function _best_candidate_by_metric(
    pep::ODEPE.ParameterEstimationProblem,
    candidates::Vector{ODEPE.ParameterEstimationResult},
    metric_fn,
)
    isempty(candidates) && return nothing, Dict{Symbol, Any}(), Inf
    best_idx = nothing
    best_metrics = Dict{Symbol, Any}()
    best_value = Inf
    for (idx, candidate) in enumerate(candidates)
        metrics = metric_fn(pep, candidate)
        value = get(metrics, :rmse, get(metrics, :combined_rel_rmse, Inf))
        if value < best_value
            best_idx = idx
            best_metrics = metrics
            best_value = value
        end
    end
    return best_idx, best_metrics, best_value
end

function _typed_candidate_vector(candidates)
    typed = ODEPE.ParameterEstimationResult[]
    for candidate in candidates
        candidate isa ODEPE.ParameterEstimationResult || continue
        push!(typed, candidate)
    end
    return typed
end

_coord_label_short(coordinate_transform::Symbol) =
    coordinate_transform == :linear ? "original-space" : "log-space"

_coord_label_long(coordinate_transform::Symbol) =
    coordinate_transform == :linear ?
    "original-space polish (no coordinate transform)" :
    "log-space polish (optimize in log(x), evaluate in x)"

function _research_analysis_mode()
    raw = lowercase(strip(get(ENV, "ODEPE_RESEARCH_ANALYSIS_MODE", "gated")))
    raw in ("gated", "ungated") || error("Unsupported ODEPE_RESEARCH_ANALYSIS_MODE='$raw'")
    return Symbol(raw)
end

function _analyze_candidates_for_research(
    pep::ODEPE.ParameterEstimationProblem,
    candidates::Vector{ODEPE.ParameterEstimationResult};
    mode::Symbol = _research_analysis_mode(),
)
    if mode == :gated
        analyzed = ODEPE.analyze_estimation_result(pep, candidates; nooutput = true)
        return _typed_candidate_vector(analyzed[1])
    elseif mode == :ungated
        scored = ODEPE._scored_results(candidates)
        isempty(scored) && return ODEPE.ParameterEstimationResult[]
        sorted = sort(scored, by = ODEPE._result_err_key)
        clusters = ODEPE.cluster_solutions(sorted)
        analyzed_candidates = ODEPE.ParameterEstimationResult[]
        for cluster in clusters
            isempty(cluster) && continue
            rep = first(cluster)
            rep isa ODEPE.ParameterEstimationResult || continue
            push!(analyzed_candidates, rep)
        end
        return analyzed_candidates
    end
    error("Unsupported research analysis mode $(mode)")
end

function _compare(lhs::Real, rhs::Real; atol::Float64 = 1e-6)
    if !isfinite(lhs) && !isfinite(rhs)
        return :tie
    elseif !isfinite(lhs)
        return :worse
    elseif !isfinite(rhs)
        return :better
    elseif lhs < rhs - atol
        return :better
    elseif lhs > rhs + atol
        return :worse
    end
    return :tie
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

function _benchmark_script_positive_box(case_dir::AbstractString, p_size::Int)
    script_path = joinpath(case_dir, "script.jl")
    isfile(script_path) || return nothing
    text = read(script_path, String)
    has_lb = occursin(r"opt_lb\s*=\s*1e-05\s*\*\s*ones\(length\(ic\)\s*\+\s*length\(p_true\)\)", text)
    has_ub = occursin(r"opt_ub\s*=\s*10\.0\s*\*\s*ones\(length\(ic\)\s*\+\s*length\(p_true\)\)", text)
    has_lb && has_ub || return nothing
    return (
        lb = fill(1e-5, p_size),
        ub = fill(10.0, p_size),
        source = :script_standard_positive_box,
    )
end

function _resolve_research_run_opts(
    pep::ODEPE.ParameterEstimationProblem,
    case_dir::AbstractString,
    benchmark_opts::Union{Nothing, ODEPE.EstimationOptions},
)
    datasize = isnothing(pep.data_sample) || !haskey(pep.data_sample, "t") ? 0 : length(pep.data_sample["t"])
    p_size = length(pep.ic) + length(pep.p_true)
    run_opts = ODEPE.merge_options(
        isnothing(benchmark_opts) ? ODEPE.EstimationOptions() : benchmark_opts;
        datasize = datasize,
        nooutput = true,
        diagnostics = false,
        polish_solutions = true,
    )
    needs_box = isnothing(run_opts.opt_lb) || isnothing(run_opts.opt_ub) ||
        length(run_opts.opt_lb) != p_size || length(run_opts.opt_ub) != p_size ||
        any(run_opts.opt_lb .<= 0.0) || any(run_opts.opt_ub .<= 0.0)
    box_meta = nothing
    if needs_box
        box_meta = _benchmark_script_positive_box(case_dir, p_size)
        if !isnothing(box_meta)
            run_opts = ODEPE.merge_options(run_opts; opt_lb = box_meta.lb, opt_ub = box_meta.ub)
        end
    end
    return run_opts, box_meta
end

function _rebuild_polish_context_with_optf(
    ctx::ODEPE.PolishContext,
    optf::Optimization.OptimizationFunction,
)
    return ODEPE.PolishContext(
        ctx.unknown_syms,
        ctx.param_syms,
        ctx.n_ic,
        ctx.n_param,
        ctx.new_model,
        ctx.obs_funcs,
        ctx.data_targets,
        ctx.t_vector,
        ctx.tspan,
        ctx.solver,
        ctx.abstol,
        ctx.reltol,
        ctx.adtype,
        optf,
        ctx.base_ode_prob,
        ctx.state_syms_out,
        ctx.param_syms_out,
        ctx.state_index,
        ctx.param_index,
        ctx.lb,
        ctx.ub,
        ctx.internal_lb,
        ctx.internal_ub,
        ctx.coordinate_transform,
        ctx.polish_ode_maxiters,
    )
end

function _validate_research_regularization(
    coordinate_transform::Symbol,
    regularization_mode::Symbol,
    regularization_lambda::Real,
)
    λ = Float64(regularization_lambda)
    λ >= 0.0 || throw(ArgumentError("research regularization lambda must be nonnegative"))
    if regularization_mode == :none || λ == 0.0
        return 0.0, :none
    end
    regularization_mode == :l2_log || throw(ArgumentError("unsupported research regularization mode '$regularization_mode'"))
    coordinate_transform == :log_positive || throw(ArgumentError("research log-space regularization requires log-space polish"))
    return λ, regularization_mode
end

function _regularized_scalar_polish_context(
    ctx::ODEPE.PolishContext;
    regularization_lambda::Real = 0.0,
    regularization_mode::Symbol = :none,
)
    λ, mode = _validate_research_regularization(ctx.coordinate_transform, regularization_mode, regularization_lambda)
    mode == :none && return ctx

    base_optf = ctx.optf
    reg_optf = Optimization.OptimizationFunction(
        (x, p) -> begin
            base_value = base_optf.f(x, p)
            !isfinite(base_value) && return base_value
            return base_value + λ * sum(abs2, x)
        end,
        ctx.adtype,
    )
    return _rebuild_polish_context_with_optf(ctx, reg_optf)
end

function build_polish_mode_report(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    run_opts::ODEPE.EstimationOptions,
    coordinate_transform::Symbol;
    regularization_lambda::Real = 0.0,
    regularization_mode::Symbol = :none,
)
    timed = @timed begin
        polish_ctx = ODEPE._build_polish_context(pep; opts = run_opts, coordinate_transform = coordinate_transform)
        polish_ctx = _regularized_scalar_polish_context(
            polish_ctx;
            regularization_lambda = regularization_lambda,
            regularization_mode = regularization_mode,
        )
        polished_pool = ODEPE._polish_batch_from_context(polish_ctx, raw_candidates; opts = run_opts)
        analyzed_candidates = _analyze_candidates_for_research(pep, polished_pool)
        selected_idx, selected_candidate = ODEPE._best_fit_raw_candidate(analyzed_candidates)
        selected_benchmark = _benchmark_metric_row(pep, selected_candidate)
        selected_local = _local_metric_row(pep, selected_candidate)
        best_bench_idx, best_bench_metrics, _ = _best_candidate_by_metric(pep, analyzed_candidates, _benchmark_metric_row)
        best_local_idx, best_local_metrics, _ = _best_candidate_by_metric(pep, analyzed_candidates, _local_metric_row)
        Dict{Symbol, Any}(
            :status => :ok,
            :polished_pool_count => length(polished_pool),
            :analyzed_candidates => analyzed_candidates,
            :analyzed_candidate_count => length(analyzed_candidates),
            :selected_index => selected_idx,
            :selected_candidate => selected_candidate,
            :selected_benchmark_metrics => selected_benchmark,
            :selected_local_metrics => selected_local,
            :best_benchmark_index => best_bench_idx,
            :best_benchmark_metrics => best_bench_metrics,
            :best_local_index => best_local_idx,
            :best_local_metrics => best_local_metrics,
            :regularization_lambda => Float64(regularization_lambda),
            :regularization_mode => regularization_mode,
        )
    end
    payload = timed.value
    payload[:build_and_run_seconds] = timed.time
    return payload
end

function safe_polish_mode_report(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    run_opts::ODEPE.EstimationOptions,
    coordinate_transform::Symbol;
    regularization_lambda::Real = 0.0,
    regularization_mode::Symbol = :none,
)
    try
        return build_polish_mode_report(
            pep,
            raw_candidates,
            run_opts,
            coordinate_transform;
            regularization_lambda = regularization_lambda,
            regularization_mode = regularization_mode,
        )
    catch err
        status = (coordinate_transform == :log_positive && err isa ArgumentError) ? :unsupported : :error
        return Dict{Symbol, Any}(
            :status => status,
            :reason => sprint(showerror, err),
            :build_and_run_seconds => Inf,
            :analyzed_candidate_count => 0,
            :polished_pool_count => 0,
            :regularization_lambda => Float64(regularization_lambda),
            :regularization_mode => regularization_mode,
            :selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
            :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
            :best_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
            :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
        )
    end
end

function _raw_stage_trace(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
)
    imported_best_idx, imported_best_metrics, _ = _best_candidate_by_metric(pep, raw_candidates, _benchmark_metric_row)
    imported_best_local_idx, imported_best_local_metrics, _ = _best_candidate_by_metric(pep, raw_candidates, _local_metric_row)
    analyzed_candidates = _analyze_candidates_for_research(pep, raw_candidates)
    analyzed_selected_idx, analyzed_selected_candidate = ODEPE._best_fit_raw_candidate(analyzed_candidates)
    analyzed_selected_benchmark = _benchmark_metric_row(pep, analyzed_selected_candidate)
    analyzed_selected_local = _local_metric_row(pep, analyzed_selected_candidate)
    analyzed_best_idx, analyzed_best_metrics, _ = _best_candidate_by_metric(pep, analyzed_candidates, _benchmark_metric_row)
    analyzed_best_local_idx, analyzed_best_local_metrics, _ = _best_candidate_by_metric(pep, analyzed_candidates, _local_metric_row)
    return Dict{Symbol, Any}(
        :imported_count => length(raw_candidates),
        :imported_best_index => imported_best_idx,
        :imported_best_metrics => imported_best_metrics,
        :imported_best_local_index => imported_best_local_idx,
        :imported_best_local_metrics => imported_best_local_metrics,
        :analyzed_count => length(analyzed_candidates),
        :analyzed_selected_index => analyzed_selected_idx,
        :analyzed_selected_benchmark_metrics => analyzed_selected_benchmark,
        :analyzed_selected_local_metrics => analyzed_selected_local,
        :analyzed_best_index => analyzed_best_idx,
        :analyzed_best_metrics => analyzed_best_metrics,
        :analyzed_best_local_index => analyzed_best_local_idx,
        :analyzed_best_local_metrics => analyzed_best_local_metrics,
    )
end

function build_case_artifact(case_id::AbstractString)
    spec = parse_case_spec(case_id)
    comparison_run = comparison_run_ordinal(spec)
    nopolish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_nopolish"))
    polish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_polish"))
    pep = polish_case.pep
    run_opts, box_meta = _resolve_research_run_opts(pep, polish_case.case_dir, polish_case.benchmark_opts)
    raw_candidates = ODEPE._load_benchmark_result_candidates(pep, run_opts, nopolish_case.case_dir)
    raw_stage_trace = _raw_stage_trace(pep, raw_candidates)

    linear_report = safe_polish_mode_report(pep, raw_candidates, run_opts, :linear)
    log_report = safe_polish_mode_report(pep, raw_candidates, run_opts, :log_positive)

    return Dict{Symbol, Any}(
        :case_id => case_id,
        :spec => spec,
        :comparison_run => comparison_run,
        :research_analysis_mode => _research_analysis_mode(),
        :raw_candidate_count => length(raw_candidates),
        :raw_stage_trace => raw_stage_trace,
        :saved_amigo_metrics => load_selected_metrics(spec, "amigo2_run"; comparison_run = comparison_run),
        :saved_nopolish_metrics => load_selected_metrics(spec, "odepe_nopolish"; comparison_run = comparison_run),
        :saved_polish_metrics => load_selected_metrics(spec, "odepe_polish"; comparison_run = comparison_run),
        :box_meta => box_meta,
        :linear_report => linear_report,
        :log_report => log_report,
    )
end

function build_case_artifact_safe(case_id::AbstractString)
    try
        return build_case_artifact(case_id)
    catch err
        reason = sprint(showerror, err)
        return Dict{Symbol, Any}(
            :case_id => String(case_id),
            :raw_candidate_count => 0,
            :saved_amigo_metrics => nothing,
            :saved_nopolish_metrics => nothing,
            :saved_polish_metrics => nothing,
            :box_meta => nothing,
            :artifact_error => reason,
            :linear_report => Dict{Symbol, Any}(
                :status => :error,
                :reason => reason,
                :build_and_run_seconds => Inf,
                :selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
                :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
                :best_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
                :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
            ),
            :log_report => Dict{Symbol, Any}(
                :status => :error,
                :reason => reason,
                :build_and_run_seconds => Inf,
                :selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
                :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
                :best_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
                :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
            ),
        )
    end
end

function render_summary_tsv(path::AbstractString, case_artifacts)
    mkpath(dirname(path))
    headers = [
        "case_id",
        "raw_candidate_count",
        "imported_best_benchmark_rmse",
        "analyzed_input_best_benchmark_rmse",
        "analyzed_input_selected_benchmark_rmse",
        "saved_amigo_rmse",
        "saved_nopolish_rmse",
        "saved_polish_rmse",
        "linear_status",
        "linear_selected_benchmark_rmse",
        "linear_selected_max_rel",
        "linear_selected_success",
        "linear_selected_local_rel_rmse",
        "linear_best_benchmark_rmse",
        "linear_best_local_rel_rmse",
        "linear_seconds",
        "log_status",
        "log_selected_benchmark_rmse",
        "log_selected_max_rel",
        "log_selected_success",
        "log_selected_local_rel_rmse",
        "log_best_benchmark_rmse",
        "log_best_local_rel_rmse",
        "log_seconds",
        "log_vs_linear_selected_benchmark",
        "log_vs_linear_best_benchmark",
        "log_vs_linear_selected_local",
        "log_vs_linear_best_local",
    ]
    open(path, "w") do io
        println(io, join(headers, '\t'))
        for artifact in case_artifacts
            linear = artifact[:linear_report]
            logr = artifact[:log_report]
            println(io, join([
                artifact[:case_id],
                string(artifact[:raw_candidate_count]),
                string(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :imported_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(artifact, :saved_amigo_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(artifact, :saved_nopolish_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(artifact, :saved_polish_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(linear, :status, :missing)),
                string(get(get(linear, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(linear, :selected_benchmark_metrics, Dict{Symbol, Any}()), :max_rel_err, Inf)),
                string(get(get(linear, :selected_benchmark_metrics, Dict{Symbol, Any}()), :success, false)),
                string(get(get(linear, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)),
                string(get(get(linear, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(linear, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)),
                string(get(linear, :build_and_run_seconds, Inf)),
                string(get(logr, :status, :missing)),
                string(get(get(logr, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(logr, :selected_benchmark_metrics, Dict{Symbol, Any}()), :max_rel_err, Inf)),
                string(get(get(logr, :selected_benchmark_metrics, Dict{Symbol, Any}()), :success, false)),
                string(get(get(logr, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)),
                string(get(get(logr, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(logr, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)),
                string(get(logr, :build_and_run_seconds, Inf)),
                string(_compare(get(get(logr, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf), get(get(linear, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))),
                string(_compare(get(get(logr, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf), get(get(linear, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))),
                string(_compare(get(get(logr, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf), get(get(linear, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf))),
                string(_compare(get(get(logr, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf), get(get(linear, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf))),
            ], '\t'))
        end
    end
end

function render_summary_md(path::AbstractString, case_artifacts)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Log-Space Polish Ablation\n")
        println(io, "- Generated: `$(Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"))`")
        println(io, "- Basis: imported bilby `odepe_nopolish` pools")
        println(io, "- Comparison: same pool, same simulation loss, `:linear` vs `:log_positive` polish")
        analysis_mode = isempty(case_artifacts) ? :unknown : get(first(case_artifacts), :research_analysis_mode, :unknown)
        println(io, "- Research analysis mode: `$(analysis_mode)`")
        println(io, "- Benchmark success tolerance: `10%` max relative error\n")

        println(io, "| Case | Imported best RMSE | Analyzed imported best RMSE | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Linear selected RMSE | Log selected RMSE | Linear best-in-set RMSE | Log best-in-set RMSE | Log status |")
        println(io, "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
        for artifact in case_artifacts
            linear = artifact[:linear_report]
            logr = artifact[:log_report]
            println(io, "| `$(artifact[:case_id])` | $(_fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :imported_best_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | $(_fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_best_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | $(_fmt_pct(get(get(artifact, :saved_amigo_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | $(_fmt_pct(get(get(artifact, :saved_polish_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | $(_fmt_pct(get(get(linear, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | $(_fmt_pct(get(get(logr, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | $(_fmt_pct(get(get(linear, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | $(_fmt_pct(get(get(logr, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))) | `$(get(logr, :status, :missing))` |")
        end

        println(io, "\n## Case Notes\n")
        for artifact in case_artifacts
            linear = artifact[:linear_report]
            logr = artifact[:log_report]
            println(io, "### `$(artifact[:case_id])`\n")
            if haskey(artifact, :artifact_error)
                println(io, "- Artifact build error: `$(artifact[:artifact_error])`")
            end
            println(io, "- Imported raw candidate count: `$(artifact[:raw_candidate_count])`")
            println(io, "- Imported pool stage metrics:")
            println(io, "  - imported best benchmark RMSE: $(_fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :imported_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - analyzed imported selected benchmark RMSE: $(_fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - analyzed imported best benchmark RMSE: $(_fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            if !isnothing(get(artifact, :box_meta, nothing))
                println(io, "- Research box override: `$(artifact[:box_meta].source)` (`[1e-5, 10]` on all polished coordinates)")
            end
            println(io, "- Saved references:")
            println(io, "  - `amigo2_run` RMSE: $(_fmt_pct(get(get(artifact, :saved_amigo_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - `odepe_nopolish` RMSE: $(_fmt_pct(get(get(artifact, :saved_nopolish_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - `odepe_polish` RMSE: $(_fmt_pct(get(get(artifact, :saved_polish_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "- $(_coord_label_long(:linear)):")
            println(io, "  - status: `$(get(linear, :status, :missing))`")
            println(io, "  - selected benchmark RMSE: $(_fmt_pct(get(get(linear, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - selected max relative error: $(_fmt_pct(get(get(linear, :selected_benchmark_metrics, Dict{Symbol, Any}()), :max_rel_err, Inf)))")
            println(io, "  - selected success: `$(get(get(linear, :selected_benchmark_metrics, Dict{Symbol, Any}()), :success, false))`")
            println(io, "  - selected local relative RMSE: $(_fmt_pct(get(get(linear, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)))")
            println(io, "  - best-in-set benchmark RMSE: $(_fmt_pct(get(get(linear, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - best-in-set local relative RMSE: $(_fmt_pct(get(get(linear, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)))")
            println(io, "  - runtime: `$(_format_float(get(linear, :build_and_run_seconds, Inf); digits = 3)) s`")
            println(io, "- $(_coord_label_long(:log_positive)):")
            println(io, "  - status: `$(get(logr, :status, :missing))`")
            if get(logr, :status, :missing) == :ok
                println(io, "  - selected benchmark RMSE: $(_fmt_pct(get(get(logr, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
                println(io, "  - selected max relative error: $(_fmt_pct(get(get(logr, :selected_benchmark_metrics, Dict{Symbol, Any}()), :max_rel_err, Inf)))")
                println(io, "  - selected success: `$(get(get(logr, :selected_benchmark_metrics, Dict{Symbol, Any}()), :success, false))`")
                println(io, "  - selected local relative RMSE: $(_fmt_pct(get(get(logr, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)))")
                println(io, "  - best-in-set benchmark RMSE: $(_fmt_pct(get(get(logr, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
                println(io, "  - best-in-set local relative RMSE: $(_fmt_pct(get(get(logr, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)))")
                println(io, "  - runtime: `$(_format_float(get(logr, :build_and_run_seconds, Inf); digits = 3)) s`")
                println(io, "  - vs $(_coord_label_short(:linear)) selected benchmark RMSE: `$(string(_compare(get(get(logr, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf), get(get(linear, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))))`")
                println(io, "  - vs $(_coord_label_short(:linear)) best-in-set benchmark RMSE: `$(string(_compare(get(get(logr, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf), get(get(linear, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf))))`")
                println(io, "  - vs $(_coord_label_short(:linear)) selected local relative RMSE: `$(string(_compare(get(get(logr, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf), get(get(linear, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf))))`")
                println(io, "  - vs $(_coord_label_short(:linear)) best-in-set local relative RMSE: `$(string(_compare(get(get(logr, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf), get(get(linear, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf))))`")
            else
                println(io, "  - reason: `$(get(logr, :reason, "missing"))`")
            end
            println(io)
        end
    end
end

function render_progress(path::AbstractString, case_ids::Vector{String}, artifacts)
    mkpath(dirname(path))
    updated_at = Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS")
    open(path, "w") do io
        println(io, "completed_cases=$(length(artifacts))")
        println(io, "requested_cases=$(length(case_ids))")
        println(io, "completed_case_ids=$(join([artifact[:case_id] for artifact in artifacts], ','))")
        remaining = setdiff(case_ids, [artifact[:case_id] for artifact in artifacts])
        println(io, "remaining_case_ids=$(join(remaining, ','))")
        println(io, "updated_at=$(updated_at)")
    end
end

function main()
    mkpath(OUTPUT_ROOT)
    case_ids = selected_case_ids()
    artifacts = Dict{Symbol, Any}[]
    summary_tsv = joinpath(OUTPUT_ROOT, "summary.tsv")
    summary_md = joinpath(OUTPUT_ROOT, "summary.md")
    progress_path = joinpath(OUTPUT_ROOT, "progress.txt")
    for (idx, case_id) in enumerate(case_ids)
        println("[$idx/$(length(case_ids))] Running $(case_id)")
        artifact = build_case_artifact_safe(case_id)
        push!(artifacts, artifact)
        render_summary_tsv(summary_tsv, artifacts)
        render_summary_md(summary_md, artifacts)
        render_progress(progress_path, case_ids, artifacts)
        println("[$idx/$(length(case_ids))] Flushed $(case_id)")
    end
    println("Wrote log-space polish ablation to $(OUTPUT_ROOT)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
