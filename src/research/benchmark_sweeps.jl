function _safe_parse_float(text::AbstractString)
    stripped = strip(text)
    isempty(stripped) && return NaN
    try
        return parse(Float64, stripped)
    catch
        return NaN
    end
end

function _safe_parse_bool(text::AbstractString)
    stripped = lowercase(strip(text))
    stripped == "true" && return true
    stripped == "false" && return false
    return false
end

function _read_bilby_comparison_rows(path::AbstractString)
    lines = readlines(path)
    isempty(lines) && return NamedTuple[]
    header = split(first(lines), ',')
    rows = NamedTuple[]
    for line in lines[2:end]
        isempty(strip(line)) && continue
        cols = split(line, ',')
        length(cols) == length(header) || continue
        row = Dict{String, String}(header[i] => cols[i] for i in eachindex(header))
        push!(rows, (
            id = row["id"],
            name = row["name"],
            noise = _safe_parse_float(row["noise"]),
            classification = row["classification"],
            is_successful_a = _safe_parse_bool(row["is_successful_a"]),
            is_successful_b = _safe_parse_bool(row["is_successful_b"]),
            mean_rel_error_a = _safe_parse_float(row["mean_rel_error_a"]),
            mean_rel_error_b = _safe_parse_float(row["mean_rel_error_b"]),
            max_rel_error_a = _safe_parse_float(row["max_rel_error_a"]),
            max_rel_error_b = _safe_parse_float(row["max_rel_error_b"]),
            time_a = _safe_parse_float(row["time_a"]),
            time_b = _safe_parse_float(row["time_b"]),
        ))
    end
    return rows
end

function _bilby_case_dir(
    benchmark_root::AbstractString,
    case_id::AbstractString;
    data_variant::AbstractString = "odepe_nopolish",
)
    return joinpath(benchmark_root, "filetree", data_variant, case_id)
end

function _slice_bilby_setup_script(script_text::AbstractString)
    kept = String[]
    for line in split(script_text, '\n'; keepempty = true)
        stripped = strip(line)
        if stripped == "# Run the analysis with the selected options" ||
           occursin("meta, results = analyze_parameter_estimation_problem", line)
            break
        end
        if startswith(stripped, "using Pkg; Pkg.activate") ||
           startswith(stripped, "using MKL") ||
           startswith(stripped, "using BenchmarkTools")
            continue
        end
        push!(kept, line)
    end
    push!(kept, "")
    push!(kept, "nothing")
    return join(kept, "\n")
end

function _load_bilby_case(case_dir::AbstractString)
    script_path = joinpath(case_dir, "script.jl")
    isfile(script_path) || throw(ArgumentError("Benchmark script not found at $script_path"))

    setup_code = _slice_bilby_setup_script(read(script_path, String))
    temp_module = Module(gensym(:BilbyCaseLoader))
    Base.include_string(temp_module, setup_code, script_path)

    pep = Core.eval(temp_module, :pep)
    benchmark_opts = isdefined(temp_module, :opts) ? Core.eval(temp_module, :opts) : nothing
    model_name = isdefined(temp_module, :name) ? String(Core.eval(temp_module, :name)) : pep.name
    datasize = isdefined(temp_module, :datasize) ? Int(Core.eval(temp_module, :datasize)) : (
        isnothing(pep.data_sample) || !haskey(pep.data_sample, "t") ? 0 : length(pep.data_sample["t"])
    )
    time_interval = isdefined(temp_module, :time_interval) ? collect(Float64, Core.eval(temp_module, :time_interval)) : collect(Float64, pep.recommended_time_interval)

    return (
        case_dir = String(case_dir),
        case_id = basename(String(case_dir)),
        model_name = model_name,
        pep = pep,
        benchmark_opts = benchmark_opts,
        datasize = datasize,
        time_interval = time_interval,
    )
end

function _default_sweep_estimation_options()
    return EstimationOptions(
        interpolator = InterpolatorAAADGPR,
        interpolators = InterpolatorMethod[],
        shooting_points = 3,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = false,
        polish_solver_solutions = false,
        polish_maxiters = 20,
        polish_maxtime = 5.0,
        use_parameter_homotopy = true,
        use_multipoint = true,
        multipoint_n_points = 2,
        multipoint_max_pairs = 4,
        system_solver = SolverHC,
        flow = FlowStandard,
        use_si_template = true,
    )
end

function _default_sweep_consensus_options()
    return ConsensusOptions(
        strategy = :family_consensus,
        support_point_count = 4,
        support_combo_count = 4,
        refine_top_families = 1,
        do_equation_refit = false,
    )
end

function _default_sweep_synthesized_options()
    return SynthesizedFinalizerOptions(
        base_consensus_opts = _default_sweep_consensus_options(),
        max_family_seeds = 4,
        max_cross_family_seeds = 4,
        allow_cross_family_synthesis = true,
        allow_parameter_stitching = true,
        cross_family_distance_limit = 0.5,
        seed_consistency_threshold = 100.0,
        max_refine_candidates = 4,
        refine_with_full_trajectory = true,
        refine_objective_mode = :trajectory_only,
    )
end

function _sweep_bucket_specs()
    return [
        (
            bucket = :both_success_room_to_improve,
            label = "both_success / room_to_improve",
            preferred_ids = [
                "seir_2_1em4",
                "brusselator_1_1em4",
                "fitzhugh_nagumo_3_1em4",
                "daisy_mamil3_4_1em4",
            ],
            filter = row -> row.classification == "both_success" && row.mean_rel_error_b > 0.005,
            sort_mode = :descending_error,
        ),
        (
            bucket = :both_success_controls,
            label = "both_success / controls",
            preferred_ids = [
                "dc_motor_1_1em4",
                "bicycle_model_7_1em4",
            ],
            filter = row -> row.classification == "both_success" && row.mean_rel_error_b <= 0.005,
            sort_mode = :ascending_error,
        ),
        (
            bucket = :amigo2_only_near_miss,
            label = "AMIGO2-only / ODEPE near-miss",
            preferred_ids = [
                "daisy_mamil3_7_1em4",
                "fitzhugh_nagumo_2_1em4",
                "sirt_treatment_7_1em4",
            ],
            filter = row -> row.classification == "a_only",
            sort_mode = :descending_error,
        ),
        (
            bucket = :odepe_only_contrast,
            label = "ODEPE-only / contrast",
            preferred_ids = [
                "aircraft_pitch_4_1em4",
            ],
            filter = row -> row.classification == "b_only",
            sort_mode = :ascending_error,
        ),
    ]
end

function _bucket_sort_key(row, sort_mode::Symbol)
    err = isfinite(row.mean_rel_error_b) ? row.mean_rel_error_b : Inf
    time_b = isfinite(row.time_b) ? row.time_b : Inf
    if sort_mode == :descending_error
        return (-err, time_b, row.id)
    end
    return (err, time_b, row.id)
end

function _select_bilby_sweep_cases(
    benchmark_root::AbstractString;
    comparison_csv_path::AbstractString = joinpath(benchmark_root, "analysis_results", "comparison_amigo2_run_vs_odepe_multipoint_full.csv"),
    data_variant::AbstractString = "odepe_nopolish",
    noise::Float64 = 1e-4,
    case_limit::Union{Nothing, Int} = nothing,
    requested_case_ids::Vector{String} = String[],
)
    rows = _read_bilby_comparison_rows(comparison_csv_path)
    noise_rows = filter(row -> isapprox(row.noise, noise; atol = 1e-12, rtol = 0.0), rows)
    row_by_id = Dict(row.id => row for row in noise_rows)
    selected = NamedTuple[]
    seen = Set{String}()

    function maybe_add(row, spec, mode::Symbol)
        row.id in seen && return false
        case_dir = _bilby_case_dir(benchmark_root, row.id; data_variant = data_variant)
        isdir(case_dir) || return false
        push!(selected, (
            bucket = spec.bucket,
            bucket_label = spec.label,
            selected_via = mode,
            case_id = row.id,
            case_dir = case_dir,
            row = row,
        ))
        push!(seen, row.id)
        return true
    end

    if !isempty(requested_case_ids)
        for case_id in requested_case_ids
            haskey(row_by_id, case_id) || continue
            row = row_by_id[case_id]
            matching_spec = findfirst(spec -> any(case_id == preferred for preferred in spec.preferred_ids) || spec.filter(row), _sweep_bucket_specs())
            spec = isnothing(matching_spec) ? (
                bucket = :ad_hoc,
                label = "ad hoc",
                preferred_ids = String[],
                filter = _ -> true,
                sort_mode = :ascending_error,
            ) : _sweep_bucket_specs()[matching_spec]
            maybe_add(row, spec, :requested)
        end
        return isnothing(case_limit) ? selected : selected[1:min(case_limit, length(selected))]
    end

    for spec in _sweep_bucket_specs()
        existing_preferred = [
            row_by_id[id] for id in spec.preferred_ids
            if haskey(row_by_id, id)
        ]
        for row in existing_preferred
            maybe_add(row, spec, :preferred)
        end

        needed = length(spec.preferred_ids) - count(item -> item.bucket == spec.bucket, selected)
        needed <= 0 && continue
        fallback_rows = sort(
            filter(spec.filter, noise_rows);
            by = row -> _bucket_sort_key(row, spec.sort_mode),
        )
        for row in fallback_rows
            maybe_add(row, spec, :fallback) || continue
            needed -= 1
            needed <= 0 && break
        end
    end

    return isnothing(case_limit) ? selected : selected[1:min(case_limit, length(selected))]
end

function _method_failure_summary(
    strategy::Symbol,
    err,
    shared_seconds::Float64,
    raw_candidate_count::Int,
    family_count::Int,
)
    return Dict{Symbol, Any}(
        :strategy => strategy,
        :status => :error,
        :error_message => sprint(showerror, err),
        :selection_seconds => NaN,
        :effective_total_seconds => shared_seconds,
        :incremental_seconds => NaN,
        :candidate_count => raw_candidate_count,
        :family_count => family_count,
        :winner_mode => :missing,
        :raw_winner_lineage => "none",
        :final_winner_lineage => "none",
        :raw_winner_fit_error => Inf,
        :final_winner_fit_error => Inf,
        :raw_winner_score => Inf,
        :final_winner_score => Inf,
        :support_points => Int[],
        :support_point_times => Float64[],
        :support_combos => Vector{Vector{Int}}(),
        :support_combo_times => Vector{Vector{Float64}}(),
        :parameter_rows => NamedTuple[],
        :state_rows => NamedTuple[],
        :truth_metrics => Dict{Symbol, Any}(
            :parameter_rel_rmse => Inf,
            :state_rel_rmse => Inf,
            :combined_rel_rmse => Inf,
            :all_rows => NamedTuple[],
        ),
        :raw_truth_metrics => Dict{Symbol, Any}(),
        :winner_evidence => nothing,
        :raw_winner_evidence => nothing,
        :top_families => NamedTuple[],
        :timing => TimingBreakdown(label = strategy),
    )
end

function _single_phase_timing(
    label::Symbol,
    phase_name::AbstractString,
    seconds::Real,
    bytes::Real = 0,
    gctime::Real = 0.0;
    details::OrderedDict{Symbol, Any} = OrderedDict{Symbol, Any}(),
)
    return TimingBreakdown(
        label = label,
        total_seconds = Float64(seconds),
        phases = TimingPhaseEntry[
            TimingPhaseEntry(String(phase_name), Float64(seconds), Int64(round(bytes)), Float64(gctime)),
        ],
        details = details,
    )
end

function _summary_worst_row(summary::AbstractDict{Symbol, <:Any})
    rows = get(get(summary, :truth_metrics, Dict{Symbol, Any}()), :all_rows, NamedTuple[])
    isempty(rows) && return nothing
    best_idx = nothing
    best_error = -Inf
    for (idx, row) in pairs(rows)
        rel_error = getproperty(row, :rel_error)
        if rel_error > best_error
            best_error = rel_error
            best_idx = idx
        end
    end
    return isnothing(best_idx) ? nothing : rows[best_idx]
end

function _summary_worst_error(summary::AbstractDict{Symbol, <:Any})
    row = _summary_worst_row(summary)
    return isnothing(row) ? Inf : row.rel_error
end

function _summary_worst_label(summary::AbstractDict{Symbol, <:Any})
    row = _summary_worst_row(summary)
    return isnothing(row) ? "none" : String(row.label)
end

function _synthesized_strategy_summary(
    pep::ParameterEstimationProblem,
    report::SynthesizedFinalizerReport,
    selection_seconds::Float64,
    shared_seconds::Float64,
    timing::Union{Nothing, TimingBreakdown} = nothing,
)
    raw_report = report.raw_consensus_report
    raw_truth = _candidate_truth_metrics(pep, raw_report.winner_candidate)
    final_truth = _candidate_truth_metrics(pep, report.winning_result)
    raw_idx = raw_report.winner_candidate_index
    raw_evidence = isnothing(raw_idx) ? nothing : _candidate_evidence_dict(raw_report.candidate_evidence[raw_idx])
    final_score = report.winning_origin == :raw ? get(report.selection_summary, :raw_winner_score, Inf) : get(report.selection_summary, :synthesized_best_score, Inf)

    return Dict{Symbol, Any}(
        :strategy => :synthesized_finalizer,
        :status => :ok,
        :selection_seconds => selection_seconds,
        :effective_total_seconds => shared_seconds + selection_seconds,
        :incremental_seconds => selection_seconds,
        :candidate_count => length(raw_report.raw_candidates),
        :family_count => length(raw_report.families),
        :winner_mode => Symbol(report.winning_origin),
        :raw_winner_lineage => isnothing(raw_report.winner_candidate) ? "none" : lineage_summary(raw_report.winner_candidate),
        :final_winner_lineage => isnothing(report.winning_result) ? "none" : lineage_summary(report.winning_result),
        :raw_winner_fit_error => isnothing(raw_report.winner_candidate) ? Inf : _result_err_key(raw_report.winner_candidate),
        :final_winner_fit_error => isnothing(report.winning_result) ? Inf : _result_err_key(report.winning_result),
        :raw_winner_score => get(report.selection_summary, :raw_winner_score, Inf),
        :final_winner_score => final_score,
        :support_points => copy(raw_report.support_points),
        :support_point_times => Float64[],
        :support_combos => deepcopy(raw_report.support_combos),
        :support_combo_times => Vector{Vector{Float64}}(),
        :parameter_rows => final_truth[:parameter_rows],
        :state_rows => final_truth[:state_rows],
        :truth_metrics => final_truth,
        :raw_truth_metrics => raw_truth,
        :winner_evidence => nothing,
        :raw_winner_evidence => raw_evidence,
        :top_families => _consensus_family_rows(raw_report),
        :winning_origin => report.winning_origin,
        :winner_seed_kind => get(report.selection_summary, :winner_seed_kind, nothing),
        :synthesized_seed_count => length(report.synthesized_seeds),
        :accepted_synthesized_seed_count => count(seed -> get(seed.pre_refine_checks, :accepted, false), report.synthesized_seeds),
        :refined_seed_result_count => length(report.refined_seed_results),
        :timing => isnothing(timing) ? TimingBreakdown(label = :synthesized_finalizer, total_seconds = selection_seconds) : timing,
    )
end

function _raw_fit_truth_gap(raw_pool::Dict{Symbol, Any})
    best_fit_rmse = get(get(raw_pool, :best_fit_truth_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)
    best_truth_rmse = get(get(raw_pool, :best_truth_truth_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)
    if !isfinite(best_fit_rmse) || !isfinite(best_truth_rmse)
        return Inf
    end
    return best_fit_rmse - best_truth_rmse
end

function _summary_combined_rmse(summary::Dict{Symbol, Any})
    return get(get(summary, :truth_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)
end

function _summary_parameter_rmse(summary::Dict{Symbol, Any})
    return get(get(summary, :truth_metrics, Dict{Symbol, Any}()), :parameter_rel_rmse, Inf)
end

function _summary_fit_error(summary::Dict{Symbol, Any})
    return get(summary, :final_winner_fit_error, Inf)
end

function _summary_biggest_shift(before::Dict{Symbol, Any}, after::Dict{Symbol, Any}; direction::Symbol)
    return _consensus_biggest_shift(before, after; direction = direction)
end

function _is_sparse_family_report(families::Vector{CandidateFamily})
    isempty(families) && return true
    return all(family -> length(family.member_indices) <= 1, families)
end

function _case_conclusion_labels(raw_pool, families, baseline_summary, consensus_summary, synth_summary; status::Symbol)
    status == :load_failed && return (:load_failed, nothing)
    raw_candidates = get(raw_pool, :raw_candidate_count, nothing)
    if raw_candidates === 0 || get(raw_pool, :best_fit_index, nothing) === nothing
        return (:hard_failure_no_candidates, nothing)
    end

    baseline_rmse = _summary_combined_rmse(baseline_summary)
    consensus_rmse = _summary_combined_rmse(consensus_summary)
    synth_rmse = _summary_combined_rmse(synth_summary)
    gap = _raw_fit_truth_gap(raw_pool)

    primary = if isfinite(synth_rmse) && synth_rmse + 1e-9 < min(baseline_rmse, consensus_rmse)
        :synthesis_helped
    elseif isfinite(consensus_rmse) && consensus_rmse + 1e-9 < baseline_rmse
        :consensus_helped
    elseif _is_sparse_family_report(families)
        :raw_pool_too_sparse
    elseif isfinite(gap) && gap > 1e-6
        :candidate_generation_bottleneck
    else
        :selector_not_needed
    end

    secondary = if primary != :candidate_generation_bottleneck && isfinite(gap) && gap > 1e-6
        :candidate_generation_bottleneck
    elseif primary != :raw_pool_too_sparse && _is_sparse_family_report(families)
        :raw_pool_too_sparse
    else
        nothing
    end

    return primary, secondary
end

function _shared_case_inputs(pep::ParameterEstimationProblem, est_opts::EstimationOptions)
    prep = @timed _prepare_consensus_inputs_with_timing(pep, est_opts)
    pep_with_data, run_opts, raw_candidates, raw_timing = prep.value
    reuse_bundle = _last_estimation_reuse()
    context_timed = isempty(raw_candidates) ? nothing : (@timed _build_consensus_context(pep_with_data, run_opts; reuse_bundle = reuse_bundle))
    context = isnothing(context_timed) ? nothing : context_timed.value
    context_seconds = isnothing(context_timed) ? 0.0 : context_timed.time
    context_timing = isnothing(context_timed) ? TimingBreakdown(label = :consensus_context) : _single_phase_timing(
        :consensus_context,
        "consensus_context",
        context_timed.time,
        context_timed.bytes,
        context_timed.gctime,
    )
    shared_timing = TimingBreakdown(
        label = :shared_case_setup,
        total_seconds = prep.time + context_seconds,
        phases = TimingPhaseEntry[
            TimingPhaseEntry("prepare_consensus_inputs", prep.time, Int64(prep.bytes), prep.gctime),
            TimingPhaseEntry("build_consensus_context", context_seconds, isnothing(context_timed) ? 0 : Int64(context_timed.bytes), isnothing(context_timed) ? 0.0 : context_timed.gctime),
        ],
        details = OrderedDict{Symbol, Any}(
            :raw_estimation => raw_timing,
            :context_timing => context_timing,
        ),
    )
    return (
        pep_with_data = pep_with_data,
        run_opts = run_opts,
        raw_candidates = raw_candidates,
        context = context,
        raw_timing = raw_timing,
        context_timing = context_timing,
        shared_timing = shared_timing,
        prep_seconds = prep.time,
        context_seconds = context_seconds,
        shared_seconds = prep.time + context_seconds,
        t_vector = isnothing(context) ? (
            isnothing(pep_with_data.data_sample) || !haskey(pep_with_data.data_sample, "t") ? Float64[] : Float64[pep_with_data.data_sample["t"]...]
        ) : context.t_vector,
    )
end

function _simple_candidate_strategy_summary(
    pep::ParameterEstimationProblem,
    strategy::Symbol,
    raw_candidate::Union{Nothing, ParameterEstimationResult},
    final_candidate::Union{Nothing, ParameterEstimationResult},
    selection_seconds::Float64,
    shared_seconds::Float64,
    timing::TimingBreakdown;
    raw_candidate_count::Int,
    family_count::Int = 0,
    winner_mode::Symbol = :raw,
    support_points::Vector{Int} = Int[],
    support_combos::Vector{Vector{Int}} = Vector{Vector{Int}}(),
    t_vector::Vector{Float64} = Float64[],
    extra::AbstractDict{Symbol, <:Any} = Dict{Symbol, Any}(),
)
    raw_truth = _candidate_truth_metrics(pep, raw_candidate)
    final_truth = _candidate_truth_metrics(pep, final_candidate)
    summary = Dict{Symbol, Any}(
        :strategy => strategy,
        :status => :ok,
        :selection_seconds => selection_seconds,
        :effective_total_seconds => shared_seconds + selection_seconds,
        :incremental_seconds => selection_seconds,
        :candidate_count => raw_candidate_count,
        :family_count => family_count,
        :winner_mode => winner_mode,
        :raw_winner_lineage => isnothing(raw_candidate) ? "none" : lineage_summary(raw_candidate),
        :final_winner_lineage => isnothing(final_candidate) ? "none" : lineage_summary(final_candidate),
        :raw_winner_fit_error => isnothing(raw_candidate) ? Inf : _result_err_key(raw_candidate),
        :final_winner_fit_error => isnothing(final_candidate) ? Inf : _result_err_key(final_candidate),
        :raw_winner_score => isnothing(raw_candidate) ? Inf : _result_err_key(raw_candidate),
        :final_winner_score => isnothing(final_candidate) ? Inf : _result_err_key(final_candidate),
        :support_points => copy(support_points),
        :support_point_times => _consensus_support_times(t_vector, support_points),
        :support_combos => deepcopy(support_combos),
        :support_combo_times => _consensus_support_combo_times(t_vector, support_combos),
        :parameter_rows => final_truth[:parameter_rows],
        :state_rows => final_truth[:state_rows],
        :truth_metrics => final_truth,
        :raw_truth_metrics => raw_truth,
        :winner_evidence => nothing,
        :raw_winner_evidence => nothing,
        :top_families => NamedTuple[],
        :timing => timing,
    )
    merge!(summary, extra)
    return summary
end

function _best_fit_raw_candidate(raw_candidates::Vector{ParameterEstimationResult})
    isempty(raw_candidates) && return nothing, nothing
    idx = _argmin_by(eachindex(raw_candidates), i -> begin
        err = _result_err_key(raw_candidates[i])
        isfinite(err) ? err : Inf
    end)
    isnothing(idx) && return 1, raw_candidates[1]
    return idx, raw_candidates[idx]
end

function _top_raw_fit_indices(raw_candidates::Vector{ParameterEstimationResult}, k::Int)
    isempty(raw_candidates) && return Int[]
    ranked = sort(collect(eachindex(raw_candidates)); by = i -> begin
        err = _result_err_key(raw_candidates[i])
        (isfinite(err) ? err : Inf, i)
    end)
    return ranked[1:min(k, length(ranked))]
end

function _candidate_seed_vector(
    candidate::ParameterEstimationResult,
    polish_ctx::PolishContext;
    clamp_to_bounds::Bool = true,
)
    ic_vec = [candidate.states[s] for s in polish_ctx.unknown_syms]
    param_vec = [candidate.parameters[p] for p in polish_ctx.param_syms]
    p0 = Float64.(vcat(ic_vec, param_vec))
    use_bounds = clamp_to_bounds && !isnothing(polish_ctx.lb) && !isnothing(polish_ctx.ub)
    return use_bounds ? clamp.(p0, polish_ctx.lb, polish_ctx.ub) : p0
end

function _polish_seed_vector(candidate::ParameterEstimationResult, polish_ctx::PolishContext)
    return _candidate_seed_vector(candidate, polish_ctx; clamp_to_bounds = true)
end

function _unclamped_polish_seed_vector(candidate::ParameterEstimationResult, polish_ctx::PolishContext)
    return _candidate_seed_vector(candidate, polish_ctx; clamp_to_bounds = false)
end

function _polish_seed_relative_distance(vec_a::AbstractVector, vec_b::AbstractVector)
    dist = 0.0
    for idx in eachindex(vec_a)
        a = vec_a[idx]
        b = vec_b[idx]
        scale = max(abs(a), abs(b), 1.0)
        dist = max(dist, abs(a - b) / scale)
    end
    return dist
end

function _tryhard_solution_state_vectors(sol, t_vector::Vector{Float64})
    isnothing(sol) && return nothing
    if length(sol.u) == length(t_vector)
        return [u isa AbstractArray ? Float64.(collect(u)) : Float64[u] for u in sol.u]
    end
    return [begin
        u = sol(t)
        u isa AbstractArray ? Float64.(collect(u)) : Float64[u]
    end for t in t_vector]
end

function _tryhard_observable_signature(
    candidate::ParameterEstimationResult,
    polish_ctx::PolishContext,
)
    sol = candidate.solution
    isnothing(sol) && return nothing
    state_vectors = try
        _tryhard_solution_state_vectors(sol, polish_ctx.t_vector)
    catch
        return nothing
    end
    isnothing(state_vectors) && return nothing

    param_vec = Float64[candidate.parameters[p] for p in polish_ctx.param_syms]
    signatures = Vector{Vector{Float64}}(undef, length(polish_ctx.obs_funcs))
    for (obs_idx, obs_fn) in enumerate(polish_ctx.obs_funcs)
        obs_vals = Vector{Float64}(undef, length(state_vectors))
        for i in eachindex(state_vectors)
            obs_vals[i] = obs_fn(state_vectors[i], param_vec)
        end
        signatures[obs_idx] = obs_vals
    end
    return signatures
end

function _tryhard_observable_scales(polish_ctx::PolishContext)
    scales = Float64[]
    for target in polish_ctx.data_targets
        rms = isempty(target) ? 0.0 : sqrt(sum(abs2, target) / length(target))
        amp = isempty(target) ? 0.0 : maximum(abs, target; init = 0.0)
        push!(scales, max(rms, amp, 1.0e-6))
    end
    return scales
end

function _tryhard_trajectory_distance(
    sig_a::Union{Nothing, Vector{Vector{Float64}}},
    sig_b::Union{Nothing, Vector{Vector{Float64}}},
    obs_scales::Vector{Float64},
)
    (isnothing(sig_a) || isnothing(sig_b)) && return Inf
    length(sig_a) == length(sig_b) == length(obs_scales) || return Inf
    dist = 0.0
    for obs_idx in eachindex(sig_a)
        vals_a = sig_a[obs_idx]
        vals_b = sig_b[obs_idx]
        length(vals_a) == length(vals_b) || return Inf
        n = length(vals_a)
        n == 0 && continue
        local_rmse = sqrt(sum(abs2, vals_a .- vals_b) / n)
        dist = max(dist, local_rmse / obs_scales[obs_idx])
    end
    return dist
end

function _tryhard_observable_loss(
    sig::Union{Nothing, Vector{Vector{Float64}}},
    polish_ctx::PolishContext,
)
    isnothing(sig) && return Inf
    length(sig) == length(polish_ctx.data_targets) || return Inf
    total = 0.0
    for obs_idx in eachindex(sig)
        vals = sig[obs_idx]
        target = polish_ctx.data_targets[obs_idx]
        length(vals) == length(target) || return Inf
        total += sum(abs2, vals .- target)
    end
    return total
end

function _tryhard_spread_scale_map(
    pep::ParameterEstimationProblem,
    candidates::Vector{ParameterEstimationResult},
)
    spread = try
        compute_cross_solution_spread(pep, candidates)
    catch
        nothing
    end
    scale_map = Dict{String, Float64}()
    isnothing(spread) && return scale_map

    function _assign!(entries)
        for entry in entries
            width = entry.iqr_high - entry.iqr_low
            baseline_scale = 0.05 * max(abs(entry.median), 1.0)
            spread_scale = max(width, entry.std, baseline_scale, 1.0e-6)
            scale_map[entry.name] = spread_scale
        end
    end

    _assign!(spread.param_spread)
    _assign!(spread.state_spread)
    return scale_map
end

function _tryhard_secondary_distance(
    candidate_a::ParameterEstimationResult,
    candidate_b::ParameterEstimationResult,
    polish_ctx::PolishContext,
    scale_map::Dict{String, Float64},
)
    vec_a = _polish_seed_vector(candidate_a, polish_ctx)
    vec_b = _polish_seed_vector(candidate_b, polish_ctx)
    labels = vcat(
        [replace(string(s), "(t)" => "") for s in polish_ctx.unknown_syms],
        [replace(string(p), "(t)" => "") for p in polish_ctx.param_syms],
    )
    dist = 0.0
    for idx in eachindex(vec_a)
        a = vec_a[idx]
        b = vec_b[idx]
        scale = get(scale_map, labels[idx], max(abs(a), abs(b), 1.0))
        dist = max(dist, abs(a - b) / max(scale, 1.0e-6))
    end
    return dist
end

function _tryhard_fit_order(new_fit::Float64, old_fit::Float64)
    if isfinite(new_fit) && isfinite(old_fit)
        tol = 1.0e-12 * max(abs(new_fit), abs(old_fit), 1.0)
        if new_fit < old_fit - tol
            return :better
        elseif new_fit > old_fit + tol
            return :worse
        end
        return :tie
    elseif isfinite(new_fit)
        return :better
    elseif isfinite(old_fit)
        return :worse
    end
    return :tie
end

function _tryhard_should_replace_representative(
    new_fit::Float64,
    old_fit::Float64,
    new_obs_loss::Float64,
    old_obs_loss::Float64,
    new_row_index::Int,
    old_row_index::Int,
)
    fit_order = _tryhard_fit_order(new_fit, old_fit)
    fit_order === :better && return true, :fit
    fit_order === :worse && return false, :fit

    if isfinite(new_obs_loss) && isfinite(old_obs_loss)
        tol = 1.0e-12 * max(abs(new_obs_loss), abs(old_obs_loss), 1.0)
        if new_obs_loss < old_obs_loss - tol
            return true, :observable_loss
        elseif new_obs_loss > old_obs_loss + tol
            return false, :observable_loss
        end
    elseif isfinite(new_obs_loss)
        return true, :observable_loss
    elseif isfinite(old_obs_loss)
        return false, :observable_loss
    end

    return new_row_index < old_row_index, :row_index
end

function _select_distinct_candidate_indices_by_order(
    candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
    ranked_indices::Vector{Int};
    top_k::Int,
    threshold::Float64 = 0.001,
)
    isempty(candidates) && return Int[]
    top_k <= 0 && return Int[]
    clamped_vectors = Dict{Int, Vector{Float64}}()
    selected = Int[]
    for idx in ranked_indices
        idx < 1 && continue
        idx > length(candidates) && continue
        vector = get!(clamped_vectors, idx) do
            _polish_seed_vector(candidates[idx], polish_ctx)
        end
        is_duplicate = false
        for chosen_idx in selected
            chosen_vector = get!(clamped_vectors, chosen_idx) do
                _polish_seed_vector(candidates[chosen_idx], polish_ctx)
            end
            if _polish_seed_relative_distance(vector, chosen_vector) <= threshold
                is_duplicate = true
                break
            end
        end
        is_duplicate && continue
        push!(selected, idx)
        length(selected) >= top_k && break
    end
    return selected
end

function _top_distinct_raw_fit_indices(
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext;
    top_k::Int = 5,
    threshold::Float64 = 0.001,
)
    ranked = sort(collect(eachindex(raw_candidates)); by = i -> begin
        err = _result_err_key(raw_candidates[i])
        (isfinite(err) ? err : Inf, i)
    end)
    return _select_distinct_candidate_indices_by_order(
        raw_candidates,
        polish_ctx,
        ranked;
        top_k = top_k,
        threshold = threshold,
    )
end

function _tryhard_origin_tag_text(tags::Set{Symbol})
    isempty(tags) && return "none"
    ordered = sort!(collect(String(tag) for tag in tags))
    return join(ordered, "+")
end

function _tryhard_source_mix(tags::Set{Symbol})
    isempty(tags) && return :none
    length(tags) == 1 && return first(tags)
    return :mixed
end

function _tryhard_origin_priority(origin::Symbol)
    return origin == :baseline ? 0 :
           origin == :block ? 1 :
           origin == :branch ? 2 :
           origin == :synthesized ? 3 : 10
end

function _copy_tryhard_seed_row(row::Dict{Symbol, Any})
    copied = copy(row)
    for key in (:origin_tags, :members)
        if haskey(copied, key)
            copied[key] = copy(copied[key])
        end
    end
    return copied
end

function _build_tryhard_seed_row(
    candidate::ParameterEstimationResult,
    origin::Symbol,
    origin_rank::Int,
    source_id::Int;
    generator_score::Real = NaN,
    generator_score_kind::Symbol = :none,
)
    origin_label = origin == :baseline ? "baseline" :
        origin == :block ? "block" :
        origin == :branch ? "branch" :
        origin == :synthesized ? "synthesized" : string(origin)
    return Dict{Symbol, Any}(
        :candidate => candidate,
        :origin_tags => Set([origin]),
        :origin_label => origin_label,
        :origin_rank => origin_rank,
        :best_origin_rank => origin_rank,
        :source_id => source_id,
        :generator_score => Float64(generator_score),
        :generator_score_kind => generator_score_kind,
        :block_score => generator_score_kind == :block_score ? Float64(generator_score) : NaN,
        :fit_error => _result_err_key(candidate),
        :lineage => lineage_summary(candidate),
        :members => String["$(origin_label)#$(source_id)"],
        :decision_reason => :unclassified,
    )
end

function _merge_tryhard_seed_rows(
    seed_rows::Vector{Dict{Symbol, Any}},
    polish_ctx::PolishContext;
    threshold::Float64 = 0.001,
)
    isempty(seed_rows) && return Dict{Symbol, Any}[]
    merged = Dict{Symbol, Any}[]
    cached_vectors = IdDict{Any, Vector{Float64}}()

    for row in seed_rows
        candidate = row[:candidate]
        row_origin_label = get(row, :origin_label, get(row, :representative_origin_label, "unknown"))
        row_source_id = get(row, :source_id, get(row, :representative_source_id, 0))
        vector = get!(cached_vectors, candidate) do
            _polish_seed_vector(candidate, polish_ctx)
        end
        matched = false
        for existing in merged
            existing_candidate = existing[:candidate]
            existing_vector = get!(cached_vectors, existing_candidate) do
                _polish_seed_vector(existing_candidate, polish_ctx)
            end
            if _polish_seed_relative_distance(vector, existing_vector) <= threshold
                union!(existing[:origin_tags], row[:origin_tags])
                append!(existing[:members], copy(row[:members]))
                existing[:best_origin_rank] = min(existing[:best_origin_rank], row[:best_origin_rank])
                if row[:fit_error] < existing[:fit_error]
                    existing[:candidate] = candidate
                    existing[:fit_error] = row[:fit_error]
                    existing[:lineage] = row[:lineage]
                    existing[:generator_score] = row[:generator_score]
                    existing[:generator_score_kind] = row[:generator_score_kind]
                    existing[:block_score] = row[:block_score]
                    existing[:origin_label] = row_origin_label
                    existing[:source_id] = row_source_id
                    existing[:representative_origin_label] = row_origin_label
                    existing[:representative_source_id] = row_source_id
                end
                matched = true
                break
            end
        end
        matched && continue
        push!(merged, Dict{Symbol, Any}(
            :candidate => candidate,
            :origin_tags => Set(row[:origin_tags]),
            :members => copy(row[:members]),
            :fit_error => row[:fit_error],
            :lineage => row[:lineage],
            :generator_score => row[:generator_score],
            :generator_score_kind => row[:generator_score_kind],
            :block_score => row[:block_score],
            :best_origin_rank => row[:best_origin_rank],
            :origin_label => row_origin_label,
            :source_id => row_source_id,
            :representative_origin_label => row_origin_label,
            :representative_source_id => row_source_id,
            :decision_reason => row[:decision_reason],
        ))
    end
    return merged
end

function _select_tryhard_baseline_seed_rows(
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext;
    opts::EstimationOptions = EstimationOptions(),
)
    cluster_meta = _polish_cluster_metadata(polish_ctx, raw_candidates; opts = opts)
    rows = Dict{Symbol, Any}[]
    for (rank, idx) in enumerate(cluster_meta.cluster_reps)
        row = _build_tryhard_seed_row(raw_candidates[idx], :baseline, rank, idx)
        row[:decision_reason] = :baseline_preserved
        push!(rows, row)
    end
    return rows
end

function _select_tryhard_raw_seed_rows(
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext;
    top_k::Int = 10,
    threshold::Float64 = 0.001,
)
    indices = _top_distinct_raw_fit_indices(raw_candidates, polish_ctx; top_k = top_k, threshold = threshold)
    rows = Dict{Symbol, Any}[]
    for (rank, idx) in enumerate(indices)
        push!(rows, _build_tryhard_seed_row(raw_candidates[idx], :baseline, rank, idx))
    end
    return rows
end

function _collect_tryhard_block_seed_rows(
    report::BlockConsensusReport,
    polish_ctx::PolishContext;
    threshold::Float64 = 0.001,
)
    hypotheses = report.assembled_hypotheses
    rows = Dict{Symbol, Any}[]
    ordered = sort(
        collect(eachindex(hypotheses));
        by = idx -> begin
            hypothesis = hypotheses[idx]
            (
                isfinite(hypothesis.final_combined_score) ? hypothesis.final_combined_score : Inf,
                isfinite(_result_err_key(hypothesis.final_candidate)) ? _result_err_key(hypothesis.final_candidate) : Inf,
                idx,
            )
        end,
    )
    for (rank, idx) in enumerate(ordered)
        hypothesis = hypotheses[idx]
        candidate = hypothesis.final_candidate
        push!(rows, _build_tryhard_seed_row(
            candidate,
            :block,
            rank,
            idx;
            generator_score = hypothesis.final_combined_score,
            generator_score_kind = :block_score,
        ))
    end
    return _merge_tryhard_seed_rows(rows, polish_ctx; threshold = threshold)
end

function _select_tryhard_block_seed_rows(
    report::BlockConsensusReport,
    polish_ctx::PolishContext;
    top_k::Int = 10,
    threshold::Float64 = 0.001,
)
    rows = _collect_tryhard_block_seed_rows(report, polish_ctx; threshold = threshold)
    return rows[1:min(top_k, length(rows))]
end

function _collect_tryhard_branch_seed_rows(
    report::BranchConsensusReport,
    polish_ctx::PolishContext;
    threshold::Float64 = 0.001,
)
    hypotheses = report.branch_hypotheses
    rows = Dict{Symbol, Any}[]
    ordered = sort(
        collect(eachindex(hypotheses));
        by = idx -> begin
            hypothesis = hypotheses[idx]
            candidate = _branch_selected_candidate(hypothesis)
            (
                -hypothesis.branch_score,
                isfinite(_result_err_key(candidate)) ? _result_err_key(candidate) : Inf,
                idx,
            )
        end,
    )
    for (rank, idx) in enumerate(ordered)
        hypothesis = hypotheses[idx]
        candidate = _branch_selected_candidate(hypothesis)
        push!(rows, _build_tryhard_seed_row(
            candidate,
            :branch,
            rank,
            idx;
            generator_score = hypothesis.branch_score,
            generator_score_kind = :branch_score,
        ))
    end
    return _merge_tryhard_seed_rows(rows, polish_ctx; threshold = threshold)
end

function _collect_tryhard_synthesized_seed_rows(
    report::SynthesizedFinalizerReport,
    polish_ctx::PolishContext;
    threshold::Float64 = 0.001,
)
    rows = Dict{Symbol, Any}[]
    for (rank, candidate) in enumerate(report.refined_seed_results)
        push!(rows, _build_tryhard_seed_row(
            candidate,
            :synthesized,
            rank,
            rank;
            generator_score = _result_err_key(candidate),
            generator_score_kind = :synthesized_fit,
        ))
    end
    return _merge_tryhard_seed_rows(rows, polish_ctx; threshold = threshold)
end

function _tryhard_reasonable_fit_limit(baseline_seed_rows::Vector{Dict{Symbol, Any}})
    fits = sort(Float64[row[:fit_error] for row in baseline_seed_rows if isfinite(row[:fit_error])])
    isempty(fits) && return 1.0e5
    p95 = length(fits) == 1 ? first(fits) : quantile(fits, 0.95)
    best = minimum(fits)
    return max(p95 * 1.0e3, best * 1.0e6, 1.0e5)
end

function _tryhard_bound_violation(candidate::ParameterEstimationResult, polish_ctx::PolishContext)
    if isnothing(polish_ctx.lb) || isnothing(polish_ctx.ub)
        return 0.0
    end
    vector = _unclamped_polish_seed_vector(candidate, polish_ctx)
    widths = max.(Float64.(polish_ctx.ub .- polish_ctx.lb), 1.0)
    lower = max.(polish_ctx.lb .- vector, 0.0) ./ widths
    upper = max.(vector .- polish_ctx.ub, 0.0) ./ widths
    return isempty(lower) ? 0.0 : maximum(max.(lower, upper))
end

function _tryhard_additive_order_key(row::Dict{Symbol, Any})
    priorities = [_tryhard_origin_priority(tag) for tag in row[:origin_tags]]
    best_priority = isempty(priorities) ? typemax(Int) : minimum(priorities)
    return (
        row[:best_origin_rank],
        -length(row[:origin_tags]),
        best_priority,
        isfinite(row[:fit_error]) ? row[:fit_error] : Inf,
        row[:representative_source_id],
    )
end

function _tryhard_generator_rank_value(row::Dict{Symbol, Any})
    score = row[:generator_score]
    kind = row[:generator_score_kind]
    !isfinite(score) && return Inf
    if kind == :branch_score
        return -score
    end
    return score
end

function _tryhard_min_distance_to_rows(
    candidate::ParameterEstimationResult,
    rows::Vector{Dict{Symbol, Any}},
    polish_ctx::PolishContext,
)
    isempty(rows) && return Inf
    vector = _polish_seed_vector(candidate, polish_ctx)
    nearest = Inf
    for row in rows
        dist = _polish_seed_relative_distance(vector, _polish_seed_vector(row[:candidate], polish_ctx))
        nearest = min(nearest, dist)
    end
    return nearest
end

function _tryhard_family_counts(rows::Vector{Dict{Symbol, Any}})
    counts = Dict{Symbol, Int}()
    for row in rows
        for tag in row[:origin_tags]
            counts[tag] = get(counts, tag, 0) + 1
        end
    end
    return counts
end

function _tryhard_reason_and_family_counts(rows::Vector{Dict{Symbol, Any}})
    counts = Dict{Tuple{Symbol, Symbol}, Int}()
    for row in rows
        reason = Symbol(get(row, :decision_reason, :unknown))
        tags = isempty(row[:origin_tags]) ? Set([:unknown]) : row[:origin_tags]
        for tag in tags
            key = (reason, tag)
            counts[key] = get(counts, key, 0) + 1
        end
    end
    return counts
end

function _assess_tryhard_additive_seed_row(
    row::Dict{Symbol, Any},
    admitted_rows::Vector{Dict{Symbol, Any}},
    polish_ctx::PolishContext;
    threshold::Float64 = 0.001,
    fit_limit::Float64 = Inf,
    bound_violation_limit::Float64 = 0.25,
)
    candidate = row[:candidate]
    unclamped = _unclamped_polish_seed_vector(candidate, polish_ctx)
    any(!isfinite, unclamped) && return (
        keep = false,
        reason = :nonfinite_seed,
        nearest_distance = Inf,
        new_family_tags = Symbol[],
        fit_outlier = false,
        duplicate = false,
    )
    _tryhard_bound_violation(candidate, polish_ctx) > bound_violation_limit && return (
        keep = false,
        reason = :bound_violation,
        nearest_distance = Inf,
        new_family_tags = Symbol[],
        fit_outlier = false,
        duplicate = false,
    )

    vector = _polish_seed_vector(candidate, polish_ctx)
    nearest_distance = Inf
    for existing in admitted_rows
        dist = _polish_seed_relative_distance(vector, _polish_seed_vector(existing[:candidate], polish_ctx))
        nearest_distance = min(nearest_distance, dist)
        if dist <= threshold
            new_family_tags = sort!(collect(setdiff(row[:origin_tags], existing[:origin_tags])); by = string)
            return (
                keep = !isempty(new_family_tags),
                reason = isempty(new_family_tags) ? :duplicate : :admitted_family_representative,
                nearest_distance = dist,
                new_family_tags = new_family_tags,
                fit_outlier = isfinite(row[:fit_error]) && row[:fit_error] > fit_limit,
                duplicate = true,
            )
        end
    end
    return (
        keep = true,
        reason = :admitted_additive,
        nearest_distance = nearest_distance,
        new_family_tags = sort!(collect(row[:origin_tags]); by = string),
        fit_outlier = isfinite(row[:fit_error]) && row[:fit_error] > fit_limit,
        duplicate = false,
    )
end

function _tryhard_additive_selection_score(
    row::Dict{Symbol, Any},
    assessment,
    admitted_family_tags::Set{Symbol},
    polish_ctx::PolishContext,
)
    new_family_count = length(setdiff(row[:origin_tags], admitted_family_tags))
    geometry_novelty = isfinite(assessment.nearest_distance) ?
        assessment.nearest_distance :
        _tryhard_min_distance_to_rows(row[:candidate], Dict{Symbol, Any}[], polish_ctx)
    generator_rank = _tryhard_generator_rank_value(row)
    source_id = get(row, :representative_source_id, get(row, :source_id, 0))
    return (
        new_family_count,
        geometry_novelty,
        length(row[:origin_tags]),
        assessment.fit_outlier ? 0 : 1,
        isfinite(generator_rank) ? 1 : 0,
        isfinite(generator_rank) ? -generator_rank : -Inf,
        isfinite(row[:fit_error]) ? -row[:fit_error] : -Inf,
        -row[:best_origin_rank],
        -source_id,
    )
end

function _build_reasonable_tryhard_frontier(
    baseline_seed_rows::Vector{Dict{Symbol, Any}},
    additive_seed_rows::Vector{Dict{Symbol, Any}},
    polish_ctx::PolishContext,
    finalists_opts::TryhardFinalistOptions;
    threshold::Float64 = finalists_opts.distinctness_threshold,
)
    admitted = [_copy_tryhard_seed_row(row) for row in baseline_seed_rows]
    rejected = Dict{Symbol, Any}[]
    growth_limit = max(length(baseline_seed_rows), ceil(Int, length(baseline_seed_rows) * finalists_opts.frontier_growth_factor))
    hard_limit = finalists_opts.max_admitted_merged_seeds
    frontier_limit = hard_limit > 0 ? min(growth_limit, max(length(baseline_seed_rows), hard_limit)) : growth_limit
    fit_limit = _tryhard_reasonable_fit_limit(baseline_seed_rows)
    remaining = [_copy_tryhard_seed_row(row) for row in additive_seed_rows]
    admitted_family_tags = Set{Symbol}()
    admitted_additive = Dict{Symbol, Any}[]

    while !isempty(remaining)
        if length(admitted) >= frontier_limit
            for row in remaining
                assessment = _assess_tryhard_additive_seed_row(
                    row,
                    admitted,
                    polish_ctx;
                    threshold = threshold,
                    fit_limit = fit_limit,
                )
                row[:nearest_admitted_distance] = assessment.nearest_distance
                row[:new_family_tags] = copy(assessment.new_family_tags)
                row[:introduces_new_family] = !isempty(assessment.new_family_tags)
                row[:decision_reason] = :soft_cap
                push!(rejected, row)
            end
            break
        end

        feasible = Any[]
        hard_reject_indices = Int[]
        for (idx, row) in enumerate(remaining)
            assessment = _assess_tryhard_additive_seed_row(
                row,
                admitted,
                polish_ctx;
                threshold = threshold,
                fit_limit = fit_limit,
            )
            row[:nearest_admitted_distance] = assessment.nearest_distance
            row[:new_family_tags] = copy(assessment.new_family_tags)
            row[:introduces_new_family] = !isempty(assessment.new_family_tags)
            if !assessment.keep && assessment.reason != :duplicate
                row[:decision_reason] = assessment.reason
                push!(rejected, row)
                push!(hard_reject_indices, idx)
                continue
            end
            if !assessment.keep
                row[:decision_reason] = assessment.reason
                push!(rejected, row)
                push!(hard_reject_indices, idx)
                continue
            end
            score = _tryhard_additive_selection_score(row, assessment, admitted_family_tags, polish_ctx)
            push!(feasible, (idx, assessment, score))
        end
        if isempty(feasible)
            for idx in reverse(sort!(hard_reject_indices))
                deleteat!(remaining, idx)
            end
            break
        end

        best = first(sort(feasible; by = item -> item[3], rev = true))
        idx, assessment, _ = best
        row = remaining[idx]
        row[:decision_reason] = assessment.reason
        push!(admitted, row)
        push!(admitted_additive, row)
        union!(admitted_family_tags, row[:origin_tags])
        for delete_idx in reverse(sort!(unique(vcat(hard_reject_indices, [idx]))))
            deleteat!(remaining, delete_idx)
        end
    end

    rejection_counts = Dict{Symbol, Int}()
    for row in rejected
        reason = row[:decision_reason]
        rejection_counts[reason] = get(rejection_counts, reason, 0) + 1
    end
    admitted_distances = Float64[
        row[:nearest_admitted_distance] for row in admitted_additive
        if haskey(row, :nearest_admitted_distance) && isfinite(row[:nearest_admitted_distance])
    ]
    basin_family_counts = _tryhard_family_counts(admitted_additive)

    return admitted, rejected, Dict{Symbol, Any}(
        :frontier_limit => frontier_limit,
        :growth_limit => growth_limit,
        :hard_limit => hard_limit,
        :fit_limit => fit_limit,
        :rejection_counts => rejection_counts,
        :admitted_additive_count => length(admitted_additive),
        :admitted_additive_family_counts => basin_family_counts,
        :rejected_additive_reason_family_counts => _tryhard_reason_and_family_counts(rejected),
        :admitted_distance_min => isempty(admitted_distances) ? Inf : minimum(admitted_distances),
        :admitted_distance_median => isempty(admitted_distances) ? Inf : median(admitted_distances),
        :admitted_distance_max => isempty(admitted_distances) ? Inf : maximum(admitted_distances),
    )
end

function _polish_tryhard_seed_rows(
    pep::ParameterEstimationProblem,
    run_opts::EstimationOptions,
    polish_ctx::PolishContext,
    merged_seed_rows::Vector{Dict{Symbol, Any}},
)
    polished_rows = Dict{Symbol, Any}[]
    polish_seconds = 0.0

    for (rank, row) in enumerate(merged_seed_rows)
        polished = nothing
        err_text = nothing
        elapsed = @elapsed begin
            try
                polished = _polish_research_seed(pep, row[:candidate], polish_ctx, run_opts)
            catch err
                err_text = sprint(showerror, err)
            end
        end
        polish_seconds += elapsed
        push!(polished_rows, Dict{Symbol, Any}(
            :rank => rank,
            :sources => _tryhard_origin_tag_text(row[:origin_tags]),
            :origin_tags => Set(row[:origin_tags]),
            :members => copy(row[:members]),
            :seed_fit_error => row[:fit_error],
            :seed_lineage => row[:lineage],
            :seed_candidate => row[:candidate],
            :polished_candidate => polished,
            :polish_seconds => elapsed,
            :error_message => err_text,
        ))
    end

    return polished_rows, polish_seconds
end

function _candidate_bound_diagnostics(
    candidate::ParameterEstimationResult,
    polish_ctx::PolishContext;
    near_bound_threshold::Float64 = 0.01,
)
    if isnothing(polish_ctx.lb) || isnothing(polish_ctx.ub)
        return (
            nearest_bound_margin = Inf,
            near_bound_count = 0,
            bound_pinned = false,
        )
    end
    vector = _polish_seed_vector(candidate, polish_ctx)
    widths = max.(Float64.(polish_ctx.ub .- polish_ctx.lb), 1.0)
    lower_margin = clamp.((vector .- polish_ctx.lb) ./ widths, 0.0, Inf)
    upper_margin = clamp.((polish_ctx.ub .- vector) ./ widths, 0.0, Inf)
    nearest = min.(lower_margin, upper_margin)
    return (
        nearest_bound_margin = isempty(nearest) ? Inf : minimum(nearest),
        near_bound_count = count(x -> isfinite(x) && x <= near_bound_threshold, nearest),
        bound_pinned = any(x -> isfinite(x) && x <= near_bound_threshold, nearest),
    )
end

function _cluster_tryhard_finalists(
    pep::ParameterEstimationProblem,
    polished_rows::Vector{Dict{Symbol, Any}},
    polish_ctx::PolishContext;
    metric::Symbol = :trajectory_hybrid,
    traj_threshold::Float64 = 0.02,
    secondary_threshold::Float64 = 1.0,
    threshold::Float64 = 0.003,
    near_bound_threshold::Float64 = 0.01,
)
    successful = [
        (row_index = idx, row = polished_rows[idx])
        for idx in eachindex(polished_rows)
        if !isnothing(polished_rows[idx][:polished_candidate])
    ]
    # Empty early return: must match the 4-tuple shape returned at the bottom of this function
    # (`finalists, basin_summary, all_polished_candidates, clustering_summary`); the caller at
    # `_assemble_tryhard_finalist_report` indexes `[4]`.
    isempty(successful) && return TryhardFinalist[], Dict{Symbol, Any}[], ParameterEstimationResult[], Dict{Symbol, Any}()

    ranked = sort(
        successful;
        by = item -> (_result_err_key(item.row[:polished_candidate]), item.row_index),
    )
    cached_vectors = IdDict{Any, Vector{Float64}}()
    trajectory_signatures = IdDict{Any, Union{Nothing, Vector{Vector{Float64}}}}()
    obs_scales = _tryhard_observable_scales(polish_ctx)
    spread_scale_map = _tryhard_spread_scale_map(
        pep,
        ParameterEstimationResult[item.row[:polished_candidate] for item in ranked],
    )
    basins = Dict{Symbol, Any}[]
    merge_mode_counts = Dict{Symbol, Int}()
    representative_update_counts = Dict{Symbol, Int}()

    for item in ranked
        row = item.row
        row_index = item.row_index
        candidate = row[:polished_candidate]
        vector = get!(cached_vectors, candidate) do
            _polish_seed_vector(candidate, polish_ctx)
        end
        candidate_sig = get!(trajectory_signatures, candidate) do
            _tryhard_observable_signature(candidate, polish_ctx)
        end
        candidate_obs_loss = _tryhard_observable_loss(candidate_sig, polish_ctx)

        matched_basin = nothing
        matched_mode = :none
        matched_traj_dist = Inf
        matched_secondary_dist = Inf
        for basin in basins
            rep_candidate = basin[:representative_candidate]
            rep_vector = get!(cached_vectors, rep_candidate) do
                _polish_seed_vector(rep_candidate, polish_ctx)
            end
            rep_sig = get!(trajectory_signatures, rep_candidate) do
                _tryhard_observable_signature(rep_candidate, polish_ctx)
            end
            geom_dist = _polish_seed_relative_distance(vector, rep_vector)
            traj_dist = _tryhard_trajectory_distance(candidate_sig, rep_sig, obs_scales)
            secondary_dist = _tryhard_secondary_distance(candidate, rep_candidate, polish_ctx, spread_scale_map)
            if metric == :trajectory_hybrid &&
               isfinite(traj_dist) &&
               traj_dist <= traj_threshold &&
               secondary_dist <= secondary_threshold
                matched_basin = basin
                matched_mode = :trajectory_hybrid
                matched_traj_dist = traj_dist
                matched_secondary_dist = secondary_dist
                break
            elseif geom_dist <= threshold
                matched_basin = basin
                matched_mode = :geometry_fallback
                matched_traj_dist = traj_dist
                matched_secondary_dist = secondary_dist
                break
            end
        end

        fit_error = _result_err_key(candidate)
        if isnothing(matched_basin)
            push!(basins, Dict{Symbol, Any}(
                :representative_candidate => candidate,
                :representative_lineage => lineage_summary(candidate),
                :member_indices => Int[row_index],
                :member_count => 1,
                :source_tags => Set(row[:origin_tags]),
                :best_fit_error => fit_error,
                :seed_members => copy(row[:members]),
                :traj_distances => Float64[],
                :secondary_distances => Float64[],
                :merge_modes => Dict{Symbol, Int}(),
                :representative_obs_loss => candidate_obs_loss,
                :representative_row_index => row_index,
            ))
            continue
        end

        push!(matched_basin[:member_indices], row_index)
        matched_basin[:member_count] += 1
        union!(matched_basin[:source_tags], row[:origin_tags])
        append!(matched_basin[:seed_members], row[:members])
        isfinite(matched_traj_dist) && push!(matched_basin[:traj_distances], matched_traj_dist)
        isfinite(matched_secondary_dist) && push!(matched_basin[:secondary_distances], matched_secondary_dist)
        matched_basin[:merge_modes][matched_mode] = get(matched_basin[:merge_modes], matched_mode, 0) + 1
        merge_mode_counts[matched_mode] = get(merge_mode_counts, matched_mode, 0) + 1
        replace_rep, replace_reason = _tryhard_should_replace_representative(
            fit_error,
            matched_basin[:best_fit_error],
            candidate_obs_loss,
            get(matched_basin, :representative_obs_loss, Inf),
            row_index,
            get(matched_basin, :representative_row_index, typemax(Int)),
        )
        if replace_rep
            matched_basin[:representative_candidate] = candidate
            matched_basin[:representative_lineage] = lineage_summary(candidate)
            matched_basin[:best_fit_error] = fit_error
            matched_basin[:representative_obs_loss] = candidate_obs_loss
            matched_basin[:representative_row_index] = row_index
            representative_update_counts[replace_reason] = get(representative_update_counts, replace_reason, 0) + 1
        end
    end

    basin_order = sort(
        collect(eachindex(basins));
        by = idx -> (
            -basins[idx][:member_count],
            -length(basins[idx][:source_tags]),
            basins[idx][:best_fit_error],
            idx,
        ),
    )

    finalists = TryhardFinalist[]
    basin_summary = Dict{Symbol, Any}[]
    for (finalist_rank, basin_idx) in enumerate(basin_order)
        basin = basins[basin_idx]
        diagnostics = _candidate_bound_diagnostics(
            basin[:representative_candidate],
            polish_ctx;
            near_bound_threshold = near_bound_threshold,
        )
        source_tags = sort!(collect(basin[:source_tags]); by = string)
        source_tag_set = Set(source_tags)
        finalist = TryhardFinalist(
            finalist_rank,
            basin[:representative_candidate],
            copy(basin[:member_indices]),
            basin[:member_count],
            source_tags,
            _tryhard_source_mix(source_tag_set),
            basin[:best_fit_error],
            basin[:representative_lineage],
            diagnostics.nearest_bound_margin,
            diagnostics.near_bound_count,
            diagnostics.bound_pinned,
        )
        push!(finalists, finalist)
        push!(basin_summary, Dict{Symbol, Any}(
            :finalist_index => finalist_rank,
            :member_indices => copy(basin[:member_indices]),
            :member_count => basin[:member_count],
            :source_tags => source_tags,
            :source_mix => finalist.source_mix,
            :best_fit_error => basin[:best_fit_error],
            :representative_observable_loss => get(basin, :representative_obs_loss, Inf),
            :representative_lineage => basin[:representative_lineage],
            :nearest_bound_margin => diagnostics.nearest_bound_margin,
            :near_bound_count => diagnostics.near_bound_count,
            :bound_pinned => diagnostics.bound_pinned,
            :seed_members => unique(copy(basin[:seed_members])),
            :trajectory_distance_max => isempty(basin[:traj_distances]) ? 0.0 : maximum(basin[:traj_distances]),
            :trajectory_distance_median => isempty(basin[:traj_distances]) ? 0.0 : median(basin[:traj_distances]),
            :secondary_distance_max => isempty(basin[:secondary_distances]) ? 0.0 : maximum(basin[:secondary_distances]),
            :secondary_distance_median => isempty(basin[:secondary_distances]) ? 0.0 : median(basin[:secondary_distances]),
            :merge_modes => copy(basin[:merge_modes]),
        ))
    end

    all_polished_candidates = ParameterEstimationResult[item.row[:polished_candidate] for item in ranked]
    clustering_summary = Dict{Symbol, Any}(
        :merge_mode_counts => merge_mode_counts,
        :representative_update_counts => representative_update_counts,
        :obs_scale_count => length(obs_scales),
        :spread_scale_count => length(spread_scale_map),
    )
    return finalists, basin_summary, all_polished_candidates, clustering_summary
end

function _assemble_tryhard_finalist_report(
    pep::ParameterEstimationProblem,
    run_opts::EstimationOptions,
    raw_candidates::Vector{ParameterEstimationResult},
    polish_ctx::PolishContext,
    raw_seed_rows::Vector{Dict{Symbol, Any}},
    merged_seed_rows::Vector{Dict{Symbol, Any}};
    block_report::Union{Nothing, BlockConsensusReport} = nothing,
    branch_report::Union{Nothing, BranchConsensusReport} = nothing,
    synth_report::Union{Nothing, SynthesizedFinalizerReport} = nothing,
    block_seed_rows::Vector{Dict{Symbol, Any}} = Dict{Symbol, Any}[],
    branch_seed_rows::Vector{Dict{Symbol, Any}} = Dict{Symbol, Any}[],
    synthesized_seed_rows::Vector{Dict{Symbol, Any}} = Dict{Symbol, Any}[],
    additive_seed_rows::Vector{Dict{Symbol, Any}} = Dict{Symbol, Any}[],
    rejected_additive_seed_rows::Vector{Dict{Symbol, Any}} = Dict{Symbol, Any}[],
    frontier_metadata::Dict{Symbol, Any} = Dict{Symbol, Any}(),
    policy_label::Symbol = :reasonable_frontier_finalists,
    finalists_opts::TryhardFinalistOptions = TryhardFinalistOptions(),
)
    timed = @timed begin
        polished_rows, polish_seconds = _polish_tryhard_seed_rows(pep, run_opts, polish_ctx, merged_seed_rows)
        basin_timed = @timed _cluster_tryhard_finalists(
            pep,
            polished_rows,
            polish_ctx;
            metric = finalists_opts.post_polish_metric,
            traj_threshold = finalists_opts.post_polish_traj_threshold,
            secondary_threshold = finalists_opts.post_polish_secondary_threshold,
            threshold = finalists_opts.post_polish_basin_threshold,
            near_bound_threshold = finalists_opts.near_bound_threshold,
        )
        (polished_rows = polished_rows, polish_seconds = polish_seconds, basin_timed = basin_timed)
    end
    basin_value = timed.value.basin_timed.value
    finalists = basin_value[1]
    basin_summary = basin_value[2]
    all_polished_candidates = basin_value[3]
    clustering_summary = basin_value[4]
    best_result = isempty(finalists) ? nothing : first(finalists).representative_candidate
    winner_sources = isempty(finalists) ? "none" : _tryhard_origin_tag_text(Set(first(finalists).source_tags))
    source_mix_counts = Dict{Symbol, Int}()
    for finalist in finalists
        source_mix_counts[finalist.source_mix] = get(source_mix_counts, finalist.source_mix, 0) + 1
    end
    basin_sizes = Int[row[:member_count] for row in basin_summary]
    basin_histogram = Dict{Symbol, Int}(
        :singleton => count(==(1), basin_sizes),
        :multi_member => count(>(1), basin_sizes),
        :largest => isempty(basin_sizes) ? 0 : maximum(basin_sizes),
    )
    polished_success_count = count(row -> !isnothing(row[:polished_candidate]), timed.value.polished_rows)
    polish_error_count = count(row -> !isnothing(row[:error_message]), timed.value.polished_rows)
    polish_nonfinite_fit_count = count(
        row -> !isnothing(row[:polished_candidate]) && !isfinite(_result_err_key(row[:polished_candidate])),
        timed.value.polished_rows,
    )
    polish_maxiters_count = count(
        row -> begin
            msg = get(row, :error_message, nothing)
            !isnothing(msg) && (
                occursin("maxiters", lowercase(msg)) ||
                occursin("max_iters", lowercase(msg))
            )
        end,
        timed.value.polished_rows,
    )
    rejection_counts = get(frontier_metadata, :rejection_counts, Dict{Symbol, Int}())
    timing = TimingBreakdown(
        label = policy_label,
        total_seconds = timed.value.polish_seconds + timed.value.basin_timed.time,
        phases = TimingPhaseEntry[
            TimingPhaseEntry("polish_seed_pool", timed.value.polish_seconds, Int64(timed.bytes), timed.gctime),
            TimingPhaseEntry("cluster_polished_basins", timed.value.basin_timed.time, 0, timed.value.basin_timed.gctime),
        ],
        details = OrderedDict{Symbol, Any}(
            :baseline_seed_count => length(raw_seed_rows),
            :block_seed_count => length(block_seed_rows),
            :branch_seed_count => length(branch_seed_rows),
            :synthesized_seed_count => length(synthesized_seed_rows),
            :additive_seed_count => length(additive_seed_rows),
            :merged_seed_count => length(merged_seed_rows),
            :rejected_additive_count => length(rejected_additive_seed_rows),
            :frontier_limit => get(frontier_metadata, :frontier_limit, length(merged_seed_rows)),
            :growth_limit => get(frontier_metadata, :growth_limit, length(merged_seed_rows)),
            :hard_limit => get(frontier_metadata, :hard_limit, 0),
            :polished_seed_count => polished_success_count,
            :polish_error_count => polish_error_count,
            :polish_nonfinite_fit_count => polish_nonfinite_fit_count,
            :polish_maxiters_count => polish_maxiters_count,
            :finalist_count => length(finalists),
            :winner_sources => winner_sources,
            :pre_polish_distinctness_threshold => finalists_opts.distinctness_threshold,
            :post_polish_metric => finalists_opts.post_polish_metric,
            :post_polish_traj_threshold => finalists_opts.post_polish_traj_threshold,
            :post_polish_secondary_threshold => finalists_opts.post_polish_secondary_threshold,
            :post_polish_basin_threshold => finalists_opts.post_polish_basin_threshold,
        ),
    )
    selection_summary = Dict{Symbol, Any}(
        :version_label => finalists_opts.version_label,
        :policy_label => policy_label,
        :winner_sources => winner_sources,
        :baseline_seed_count => length(raw_seed_rows),
        :block_seed_count => length(block_seed_rows),
        :branch_seed_count => length(branch_seed_rows),
        :synthesized_seed_count => length(synthesized_seed_rows),
        :additive_seed_count => length(additive_seed_rows),
        :merged_seed_count => length(merged_seed_rows),
        :rejected_additive_count => length(rejected_additive_seed_rows),
        :frontier_growth_factor => finalists_opts.frontier_growth_factor,
        :frontier_limit => get(frontier_metadata, :frontier_limit, length(merged_seed_rows)),
        :growth_limit => get(frontier_metadata, :growth_limit, length(merged_seed_rows)),
        :hard_limit => get(frontier_metadata, :hard_limit, 0),
        :pre_polish_distinctness_threshold => finalists_opts.distinctness_threshold,
        :post_polish_metric => finalists_opts.post_polish_metric,
        :post_polish_traj_threshold => finalists_opts.post_polish_traj_threshold,
        :post_polish_secondary_threshold => finalists_opts.post_polish_secondary_threshold,
        :post_polish_basin_threshold => finalists_opts.post_polish_basin_threshold,
        :rejection_counts => rejection_counts,
        :admitted_additive_count => get(frontier_metadata, :admitted_additive_count, 0),
        :admitted_additive_family_counts => get(frontier_metadata, :admitted_additive_family_counts, Dict{Symbol, Int}()),
        :rejected_additive_reason_family_counts => get(frontier_metadata, :rejected_additive_reason_family_counts, Dict{Tuple{Symbol, Symbol}, Int}()),
        :additive_fit_limit => get(frontier_metadata, :fit_limit, Inf),
        :admitted_distance_min => get(frontier_metadata, :admitted_distance_min, Inf),
        :admitted_distance_median => get(frontier_metadata, :admitted_distance_median, Inf),
        :admitted_distance_max => get(frontier_metadata, :admitted_distance_max, Inf),
        :polished_seed_count => polished_success_count,
        :polish_error_count => polish_error_count,
        :polish_nonfinite_fit_count => polish_nonfinite_fit_count,
        :polish_maxiters_count => polish_maxiters_count,
        :finalist_count => length(finalists),
        :basin_count => length(basin_summary),
        :basin_histogram => basin_histogram,
        :clustering_summary => clustering_summary,
        :source_mix_counts => source_mix_counts,
        :timing => timing,
        :selection_seconds => timing.total_seconds,
        :status => isnothing(best_result) ? :error : :ok,
    )
    seed_summary = Dict{Symbol, Any}(
        :baseline_seed_count => length(raw_seed_rows),
        :block_seed_count => length(block_seed_rows),
        :branch_seed_count => length(branch_seed_rows),
        :synthesized_seed_count => length(synthesized_seed_rows),
        :additive_seed_count => length(additive_seed_rows),
        :merged_seed_count => length(merged_seed_rows),
        :rejected_additive_count => length(rejected_additive_seed_rows),
        :frontier_limit => get(frontier_metadata, :frontier_limit, length(merged_seed_rows)),
        :growth_limit => get(frontier_metadata, :growth_limit, length(merged_seed_rows)),
        :hard_limit => get(frontier_metadata, :hard_limit, 0),
        :polished_seed_count => polished_success_count,
        :polish_error_count => polish_error_count,
        :polish_nonfinite_fit_count => polish_nonfinite_fit_count,
        :polish_maxiters_count => polish_maxiters_count,
    )
    return TryhardFinalistReport(
        finalists_opts.version_label,
        raw_candidates,
        block_report,
        branch_report,
        synth_report,
        raw_seed_rows,
        block_seed_rows,
        branch_seed_rows,
        synthesized_seed_rows,
        additive_seed_rows,
        merged_seed_rows,
        rejected_additive_seed_rows,
        timed.value.polished_rows,
        all_polished_candidates,
        finalists,
        best_result,
        seed_summary,
        basin_summary,
        selection_summary,
    )
end

function research_tryhard_finalists(
    pep::ParameterEstimationProblem;
    est_opts::EstimationOptions = EstimationOptions(),
    tryhard_opts::TryhardFinalistOptions = TryhardFinalistOptions(),
    raw_candidates::Union{Nothing, Vector{ParameterEstimationResult}} = nothing,
    block_report::Union{Nothing, BlockConsensusReport} = nothing,
    branch_report::Union{Nothing, BranchConsensusReport} = nothing,
    synth_report::Union{Nothing, SynthesizedFinalizerReport} = nothing,
    context = nothing,
)
    pep_with_data = pep
    run_opts = est_opts
    local_raw_candidates = raw_candidates
    if isnothing(local_raw_candidates)
        pep_with_data, run_opts, local_raw_candidates = _prepare_consensus_inputs(pep, est_opts)
    else
        run_opts = est_opts.flow == FlowStandard ? est_opts : merge_options(est_opts; flow = FlowStandard)
    end

    local_context = if isnothing(context)
        isempty(local_raw_candidates) ? nothing : _build_consensus_context(pep_with_data, run_opts; reuse_bundle = _last_estimation_reuse())
    else
        context
    end

    block_stage_seconds = 0.0
    branch_stage_seconds = 0.0
    synth_stage_seconds = 0.0

    local_block_report = if tryhard_opts.include_block_seeds
        if isnothing(block_report)
            block_opts = BlockConsensusOptions(
                support_point_count = tryhard_opts.block_support_point_count,
                support_combo_count = tryhard_opts.block_support_combo_count,
                enable_polish = false,
            )
            timed = @timed _assemble_block_consensus_report(
                pep_with_data,
                run_opts,
                local_raw_candidates,
                block_opts;
                context = local_context,
            )
            block_stage_seconds = timed.time
            timed.value
        else
            block_report
        end
    else
        nothing
    end

    local_branch_report = if tryhard_opts.include_branch_seeds
        if isnothing(branch_report)
            branch_opts = BranchConsensusOptions(
                support_point_count = tryhard_opts.block_support_point_count,
                support_combo_count = tryhard_opts.block_support_combo_count,
            )
            timed = @timed _assemble_branch_consensus_report(
                pep_with_data,
                run_opts,
                local_raw_candidates,
                branch_opts;
                context = local_context,
            )
            branch_stage_seconds = timed.time
            timed.value
        else
            branch_report
        end
    else
        nothing
    end

    local_synth_report = if tryhard_opts.include_synthesized_seeds
        if isnothing(synth_report)
            base_consensus_opts = ConsensusOptions(
                strategy = :family_consensus,
                support_point_count = tryhard_opts.block_support_point_count,
                support_combo_count = tryhard_opts.block_support_combo_count,
                refine_top_families = 1,
                do_equation_refit = false,
            )
            synth_defaults = _default_sweep_synthesized_options()
            synth_opts = SynthesizedFinalizerOptions(
                base_consensus_opts = base_consensus_opts,
                max_family_seeds = synth_defaults.max_family_seeds,
                max_cross_family_seeds = synth_defaults.max_cross_family_seeds,
                allow_cross_family_synthesis = synth_defaults.allow_cross_family_synthesis,
                allow_parameter_stitching = synth_defaults.allow_parameter_stitching,
                cross_family_distance_limit = synth_defaults.cross_family_distance_limit,
                seed_consistency_threshold = synth_defaults.seed_consistency_threshold,
                max_refine_candidates = synth_defaults.max_refine_candidates,
                refine_with_full_trajectory = synth_defaults.refine_with_full_trajectory,
                refine_objective_mode = synth_defaults.refine_objective_mode,
            )
            timed = @timed _research_synthesized_finalizer_from_shared(
                pep_with_data,
                run_opts,
                local_raw_candidates,
                local_context,
                synth_opts,
            )
            synth_stage_seconds = timed.time
            timed.value
        else
            synth_report
        end
    else
        nothing
    end

    seed_prep_timed = @timed begin
        polish_ctx = _build_polish_context(pep_with_data; opts = run_opts)
        raw_seed_rows = _select_tryhard_baseline_seed_rows(local_raw_candidates, polish_ctx; opts = run_opts)
        block_seed_rows = isnothing(local_block_report) ? Dict{Symbol, Any}[] : _collect_tryhard_block_seed_rows(
            local_block_report,
            polish_ctx;
            threshold = tryhard_opts.distinctness_threshold,
        )
        branch_seed_rows = isnothing(local_branch_report) ? Dict{Symbol, Any}[] : _collect_tryhard_branch_seed_rows(
            local_branch_report,
            polish_ctx;
            threshold = tryhard_opts.distinctness_threshold,
        )
        synthesized_seed_rows = isnothing(local_synth_report) ? Dict{Symbol, Any}[] : _collect_tryhard_synthesized_seed_rows(
            local_synth_report,
            polish_ctx;
            threshold = tryhard_opts.distinctness_threshold,
        )
        additive_seed_rows = _merge_tryhard_seed_rows(
            vcat(block_seed_rows, branch_seed_rows, synthesized_seed_rows),
            polish_ctx;
            threshold = tryhard_opts.distinctness_threshold,
        )
        merged_seed_rows, rejected_additive_seed_rows, frontier_metadata = _build_reasonable_tryhard_frontier(
            raw_seed_rows,
            additive_seed_rows,
            polish_ctx,
            tryhard_opts;
            threshold = tryhard_opts.distinctness_threshold,
        )
        (
            polish_ctx = polish_ctx,
            raw_seed_rows = raw_seed_rows,
            block_seed_rows = block_seed_rows,
            branch_seed_rows = branch_seed_rows,
            synthesized_seed_rows = synthesized_seed_rows,
            additive_seed_rows = additive_seed_rows,
            merged_seed_rows = merged_seed_rows,
            rejected_additive_seed_rows = rejected_additive_seed_rows,
            frontier_metadata = frontier_metadata,
        )
    end
    polish_ctx = seed_prep_timed.value.polish_ctx
    raw_seed_rows = seed_prep_timed.value.raw_seed_rows
    block_seed_rows = seed_prep_timed.value.block_seed_rows
    branch_seed_rows = seed_prep_timed.value.branch_seed_rows
    synthesized_seed_rows = seed_prep_timed.value.synthesized_seed_rows
    additive_seed_rows = seed_prep_timed.value.additive_seed_rows
    merged_seed_rows = seed_prep_timed.value.merged_seed_rows
    rejected_additive_seed_rows = seed_prep_timed.value.rejected_additive_seed_rows
    frontier_metadata = seed_prep_timed.value.frontier_metadata
    report = _assemble_tryhard_finalist_report(
        pep_with_data,
        run_opts,
        local_raw_candidates,
        polish_ctx,
        raw_seed_rows,
        merged_seed_rows;
        block_report = local_block_report,
        branch_report = local_branch_report,
        synth_report = local_synth_report,
        block_seed_rows = block_seed_rows,
        branch_seed_rows = branch_seed_rows,
        synthesized_seed_rows = synthesized_seed_rows,
        additive_seed_rows = additive_seed_rows,
        rejected_additive_seed_rows = rejected_additive_seed_rows,
        frontier_metadata = frontier_metadata,
        policy_label = :reasonable_frontier_finalists,
        finalists_opts = tryhard_opts,
    )
    generator_seconds_total = block_stage_seconds + branch_stage_seconds + synth_stage_seconds + seed_prep_timed.time
    timing = get(report.selection_summary, :timing, TimingBreakdown(label = :reasonable_frontier_finalists, total_seconds = 0.0))
    report.selection_summary[:block_report_seconds] = block_stage_seconds
    report.selection_summary[:branch_report_seconds] = branch_stage_seconds
    report.selection_summary[:synth_report_seconds] = synth_stage_seconds
    report.selection_summary[:seed_prep_seconds] = seed_prep_timed.time
    report.selection_summary[:generator_seconds_total] = generator_seconds_total
    report.selection_summary[:selection_seconds] = get(report.selection_summary, :selection_seconds, 0.0) + generator_seconds_total
    report.selection_summary[:timing] = TimingBreakdown(
        label = timing.label,
        total_seconds = timing.total_seconds + generator_seconds_total,
        phases = vcat(
            TimingPhaseEntry[
                TimingPhaseEntry("build_block_report", block_stage_seconds, 0, 0.0),
                TimingPhaseEntry("build_branch_report", branch_stage_seconds, 0, 0.0),
                TimingPhaseEntry("build_synth_report", synth_stage_seconds, 0, 0.0),
                TimingPhaseEntry("prepare_tryhard_seed_frontier", seed_prep_timed.time, Int64(seed_prep_timed.bytes), seed_prep_timed.gctime),
            ],
            timing.phases,
        ),
        details = OrderedDict{Symbol, Any}(pairs(timing.details)),
    )
    report.selection_summary[:timing].details[:block_report_seconds] = block_stage_seconds
    report.selection_summary[:timing].details[:branch_report_seconds] = branch_stage_seconds
    report.selection_summary[:timing].details[:synth_report_seconds] = synth_stage_seconds
    report.selection_summary[:timing].details[:seed_prep_seconds] = seed_prep_timed.time
    report.selection_summary[:timing].details[:generator_seconds_total] = generator_seconds_total
    support_source = !isnothing(local_block_report) ? local_block_report :
        (!isnothing(local_branch_report) ? local_branch_report : nothing)
    report.selection_summary[:support_points] = isnothing(support_source) ? Int[] : support_source.support_points
    report.selection_summary[:support_combos] = isnothing(support_source) ? Vector{Vector{Int}}() : support_source.support_combos
    return report
end

function _polish_raw_candidate_strategy(
    pep::ParameterEstimationProblem,
    run_opts::EstimationOptions,
    raw_candidates::Vector{ParameterEstimationResult},
    shared_seconds::Float64,
    t_vector::Vector{Float64};
    top_k::Int = 1,
)
    timed = @timed begin
        polish_ctx = nothing
        ctx_seconds = @elapsed polish_ctx = _build_polish_context(pep; opts = run_opts)
        candidate_indices = _top_raw_fit_indices(raw_candidates, top_k)
        polished = ParameterEstimationResult[]
        polish_seconds = 0.0
        for idx in candidate_indices
            polish_seconds += @elapsed push!(polished, _polish_research_seed(pep, raw_candidates[idx], polish_ctx, run_opts))
        end
        best_idx = isempty(polished) ? nothing : _argmin_by(eachindex(polished), i -> _result_err_key(polished[i]))
        (
            ctx_seconds = ctx_seconds,
            polish_seconds = polish_seconds,
            seed_indices = candidate_indices,
            raw_seed = isempty(candidate_indices) ? nothing : raw_candidates[first(candidate_indices)],
            final_candidate = isnothing(best_idx) ? nothing : polished[best_idx],
            polished = polished,
        )
    end
    strategy = top_k == 1 ? :polish_best_fit_raw : Symbol("polish_top_$(top_k)_raw_by_fit")
    selection_seconds = timed.value.ctx_seconds + timed.value.polish_seconds
    phases = TimingPhaseEntry[
        TimingPhaseEntry("build_polish_context", timed.value.ctx_seconds, 0, 0.0),
        TimingPhaseEntry("polish_raw_candidates", timed.value.polish_seconds, Int64(timed.bytes), timed.gctime),
    ]
    timing = TimingBreakdown(
        label = strategy,
        total_seconds = selection_seconds,
        phases = phases,
        details = OrderedDict{Symbol, Any}(
            :build_polish_context_seconds => timed.value.ctx_seconds,
            :polish_seconds => timed.value.polish_seconds,
            :seed_indices => timed.value.seed_indices,
            :polished_candidate_count => length(timed.value.polished),
        ),
    )
    return _simple_candidate_strategy_summary(
        pep,
        strategy,
        timed.value.raw_seed,
        timed.value.final_candidate,
        selection_seconds,
        shared_seconds,
        timing;
        raw_candidate_count = length(raw_candidates),
        winner_mode = isempty(timed.value.polished) ? :missing : :refined,
        t_vector = t_vector,
        extra = Dict{Symbol, Any}(
            :seed_indices => timed.value.seed_indices,
            :polished_candidate_count => length(timed.value.polished),
        ),
    )
end

function _block_no_polish_strategy(
    pep::ParameterEstimationProblem,
    run_opts::EstimationOptions,
    raw_candidates::Vector{ParameterEstimationResult},
    context,
    shared_seconds::Float64,
    t_vector::Vector{Float64},
    ;
    baseline_report::Union{Nothing, ConsensusEstimationReport} = nothing,
    force_reuse_baseline::Bool = false,
    block_opts::BlockConsensusOptions = BlockConsensusOptions(enable_polish = false),
)
    can_reuse_baseline = !isnothing(baseline_report) && (
        force_reuse_baseline ||
        get(baseline_report.scoring_summary, :support_point_count, nothing) == block_opts.support_point_count &&
        get(baseline_report.scoring_summary, :support_combo_count, nothing) == block_opts.support_combo_count
    )
    built = @timed _assemble_block_consensus_report(
        pep,
        run_opts,
        raw_candidates,
        block_opts;
        context = context,
        support_points = can_reuse_baseline ? baseline_report.support_points : nothing,
        support_combos = can_reuse_baseline ? baseline_report.support_combos : nothing,
        evidence = can_reuse_baseline ? baseline_report.candidate_evidence : nothing,
    )
    report = built.value
    report_timing = get(report.scoring_summary, :timing, TimingBreakdown(label = :block_v2_no_polish, total_seconds = built.time))
    timing = TimingBreakdown(
        label = :block_v2_no_polish,
        total_seconds = built.time,
        phases = report_timing.phases,
        details = OrderedDict{Symbol, Any}(
            pairs(report_timing.details)...,
            :block_count => length(report.block_decomposition.blocks),
            :hypothesis_count => length(report.assembled_hypotheses),
            :reused_baseline_report => can_reuse_baseline,
        ),
    )
    summary = _simple_candidate_strategy_summary(
        pep,
        :block_v2_no_polish,
        report.best_result,
        report.best_result,
        built.time,
        shared_seconds,
        timing;
        raw_candidate_count = length(raw_candidates),
        family_count = length(report.block_decomposition.blocks),
        winner_mode = isnothing(report.best_result) ? :missing : :raw,
        support_points = report.support_points,
        support_combos = report.support_combos,
        t_vector = t_vector,
        extra = Dict{Symbol, Any}(
            :block_count => length(report.block_decomposition.blocks),
            :hypothesis_count => length(report.assembled_hypotheses),
            :version_label => report.version_label,
        ),
    )
    return report, summary
end

function _polish_block_best_strategy(
    pep::ParameterEstimationProblem,
    run_opts::EstimationOptions,
    block_report::BlockConsensusReport,
    block_no_polish_summary::Dict{Symbol, Any},
    shared_seconds::Float64,
    t_vector::Vector{Float64},
)
    timed = @timed begin
        polish_ctx = nothing
        ctx_seconds = @elapsed polish_ctx = _build_polish_context(pep; opts = run_opts)
        polished = nothing
        polish_seconds = 0.0
        if !isnothing(block_report.best_result)
            polish_seconds = @elapsed polished = _polish_research_seed(pep, block_report.best_result, polish_ctx, run_opts)
        end
        (ctx_seconds = ctx_seconds, polish_seconds = polish_seconds, polished = polished)
    end
    selection_seconds = get(block_no_polish_summary, :selection_seconds, 0.0) + timed.value.ctx_seconds + timed.value.polish_seconds
    timing = TimingBreakdown(
        label = :polish_block_v2_best,
        total_seconds = selection_seconds,
        phases = vcat(
            get(block_no_polish_summary, :timing, TimingBreakdown()).phases,
            TimingPhaseEntry[
                TimingPhaseEntry("build_polish_context", timed.value.ctx_seconds, 0, 0.0),
                TimingPhaseEntry("polish_block_v2_best", timed.value.polish_seconds, Int64(timed.bytes), timed.gctime),
            ],
        ),
        details = OrderedDict{Symbol, Any}(
            :block_summary_timing => get(block_no_polish_summary, :timing, TimingBreakdown()),
            :build_polish_context_seconds => timed.value.ctx_seconds,
            :polish_seconds => timed.value.polish_seconds,
        ),
    )
    return _simple_candidate_strategy_summary(
        pep,
        :polish_block_v2_best,
        block_report.best_result,
        timed.value.polished,
        selection_seconds,
        shared_seconds,
        timing;
        raw_candidate_count = get(block_no_polish_summary, :candidate_count, 0),
        family_count = get(block_no_polish_summary, :family_count, 0),
        winner_mode = isnothing(timed.value.polished) ? :missing : :refined,
        support_points = block_report.support_points,
        support_combos = block_report.support_combos,
        t_vector = t_vector,
        extra = Dict{Symbol, Any}(
            :block_count => get(block_no_polish_summary, :block_count, 0),
            :hypothesis_count => get(block_no_polish_summary, :hypothesis_count, 0),
        ),
    )
end

function _build_bilby_case_study_artifact(
    case_spec;
    est_opts::EstimationOptions = _default_sweep_estimation_options(),
    consensus_opts::ConsensusOptions = _default_sweep_consensus_options(),
    synth_opts::SynthesizedFinalizerOptions = _default_sweep_synthesized_options(),
)
    generated_at = string(Dates.now())
    case_id = case_spec.case_id
    case_dir = case_spec.case_dir
    benchmark_row = case_spec.row

    base_artifact = Dict{Symbol, Any}(
        :case_id => case_id,
        :model_name => benchmark_row.name,
        :bucket => case_spec.bucket,
        :bucket_label => case_spec.bucket_label,
        :selected_via => case_spec.selected_via,
        :generated_at => generated_at,
        :case_dir => case_dir,
        :benchmark_reference => benchmark_row,
        :status => :ok,
        :error_message => nothing,
    )

    case_data = try
        _load_bilby_case(case_dir)
    catch err
        artifact = copy(base_artifact)
        artifact[:status] = :load_failed
        artifact[:error_message] = sprint(showerror, err)
        artifact[:raw_candidate_count] = 0
        artifact[:family_count] = 0
        artifact[:strategies] = OrderedDict{Symbol, Dict{Symbol, Any}}()
        artifact[:raw_pool] = Dict{Symbol, Any}()
        artifact[:primary_conclusion] = :load_failed
        artifact[:secondary_conclusion] = nothing
        artifact[:synthesized_seed_rows] = NamedTuple[]
        artifact[:synthesized_refined_rows] = NamedTuple[]
        artifact[:top_families] = NamedTuple[]
        return artifact
    end

    pep = case_data.pep
    run_est_opts = merge_options(est_opts; datasize = length(pep.data_sample["t"]))

    shared = try
        _shared_case_inputs(pep, run_est_opts)
    catch err
        artifact = copy(base_artifact)
        artifact[:status] = :case_failed
        artifact[:error_message] = sprint(showerror, err)
        artifact[:pep_name] = case_data.model_name
        artifact[:datasize] = case_data.datasize
        artifact[:time_interval] = case_data.time_interval
        artifact[:raw_candidate_count] = 0
        artifact[:family_count] = 0
        artifact[:raw_pool] = Dict{Symbol, Any}(
            :raw_candidate_count => 0,
            :best_fit_index => nothing,
            :best_truth_index => nothing,
            :best_fit_vs_truth_gap => Inf,
        )
        artifact[:strategies] = OrderedDict(
            :best_fit_baseline => _method_failure_summary(:best_fit_baseline, err, 0.0, 0, 0),
            :family_consensus => _method_failure_summary(:family_consensus, err, 0.0, 0, 0),
            :synthesized_finalizer => _method_failure_summary(:synthesized_finalizer, err, 0.0, 0, 0),
        )
        artifact[:synthesized_seed_rows] = NamedTuple[]
        artifact[:synthesized_refined_rows] = NamedTuple[]
        artifact[:top_families] = NamedTuple[]
        artifact[:run_config] = Dict{Symbol, Any}()
        artifact[:consensus_config] = Dict{Symbol, Any}()
        artifact[:synth_config] = Dict{Symbol, Any}()
        artifact[:primary_conclusion] = :hard_failure_no_candidates
        artifact[:secondary_conclusion] = nothing
        return artifact
    end
    raw_pool = _consensus_raw_pool_summary(shared.pep_with_data, shared.raw_candidates)
    raw_pool = merge(raw_pool, Dict{Symbol, Any}(
        :raw_candidate_count => length(shared.raw_candidates),
        :best_fit_vs_truth_gap => _raw_fit_truth_gap(raw_pool),
    ))

    strategies = OrderedDict{Symbol, Dict{Symbol, Any}}()
    families = CandidateFamily[]
    synth_seed_rows = NamedTuple[]
    synth_refined_rows = NamedTuple[]
    synth_report = nothing

    baseline_summary = try
        built = @timed _assemble_consensus_report(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            _consensus_options_with_strategy(consensus_opts, :best_fit_baseline);
            context = shared.context,
        )
        summary = _consensus_strategy_summary(shared.pep_with_data, built.value, built.time, shared.shared_seconds, shared.t_vector)
        summary[:status] = :ok
        families = built.value.families
        summary
    catch err
        _method_failure_summary(:best_fit_baseline, err, shared.shared_seconds, length(shared.raw_candidates), 0)
    end
    strategies[:best_fit_baseline] = baseline_summary

    consensus_summary = try
        built = @timed _assemble_consensus_report(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            _consensus_options_with_strategy(consensus_opts, :family_consensus);
            context = shared.context,
        )
        summary = _consensus_strategy_summary(shared.pep_with_data, built.value, built.time, shared.shared_seconds, shared.t_vector)
        summary[:status] = :ok
        families = built.value.families
        summary
    catch err
        _method_failure_summary(:family_consensus, err, shared.shared_seconds, length(shared.raw_candidates), length(families))
    end
    strategies[:family_consensus] = consensus_summary

    synth_summary = try
        built = @timed _research_synthesized_finalizer_from_shared(
            shared.pep_with_data,
            shared.run_opts,
            shared.raw_candidates,
            shared.context,
            synth_opts,
        )
        synth_report = built.value
        families = synth_report.raw_consensus_report.families
        synth_seed_rows = _synthesized_seed_rows(synth_report)
        synth_refined_rows = _synthesized_refined_rows(shared.pep_with_data, synth_report.refined_seed_results)
        _synthesized_strategy_summary(shared.pep_with_data, synth_report, built.time, shared.shared_seconds)
    catch err
        _method_failure_summary(:synthesized_finalizer, err, shared.shared_seconds, length(shared.raw_candidates), length(families))
    end
    synth_summary[:status] = get(synth_summary, :status, :ok)
    strategies[:synthesized_finalizer] = synth_summary

    primary_conclusion, secondary_conclusion = _case_conclusion_labels(
        raw_pool,
        families,
        baseline_summary,
        consensus_summary,
        synth_summary;
        status = :ok,
    )

    artifact = copy(base_artifact)
    artifact[:status] = isempty(shared.raw_candidates) ? :hard_failure_no_candidates : :ok
    artifact[:pep_name] = shared.pep_with_data.name
    artifact[:datasize] = length(shared.pep_with_data.data_sample["t"])
    artifact[:time_interval] = collect(Float64, shared.pep_with_data.recommended_time_interval)
    artifact[:shared_candidate_generation_seconds] = shared.prep_seconds
    artifact[:shared_context_seconds] = shared.context_seconds
    artifact[:shared_total_seconds] = shared.shared_seconds
    artifact[:raw_candidate_count] = length(shared.raw_candidates)
    artifact[:family_count] = length(families)
    artifact[:raw_pool] = raw_pool
    artifact[:strategies] = strategies
    artifact[:synthesized_seed_rows] = synth_seed_rows
    artifact[:synthesized_refined_rows] = synth_refined_rows
    artifact[:top_families] = _consensus_family_rows(isnothing(synth_report) ? _empty_consensus_report(shared.pep_with_data.name, :family_consensus) : synth_report.raw_consensus_report)
    artifact[:run_config] = Dict{Symbol, Any}(
        :interpolator => string(run_est_opts.interpolator),
        :interpolator_count => length(resolve_interpolator_list(run_est_opts)),
        :shooting_points => run_est_opts.shooting_points,
        :multipoint_n_points => run_est_opts.multipoint_n_points,
        :multipoint_max_pairs => run_est_opts.multipoint_max_pairs,
        :use_parameter_homotopy => run_est_opts.use_parameter_homotopy,
        :use_multipoint => run_est_opts.use_multipoint,
        :polish_solutions => run_est_opts.polish_solutions,
        :polish_solver_solutions => run_est_opts.polish_solver_solutions,
        :polish_maxiters => run_est_opts.polish_maxiters,
        :polish_maxtime => run_est_opts.polish_maxtime,
    )
    artifact[:consensus_config] = Dict{Symbol, Any}(
        :support_point_count => consensus_opts.support_point_count,
        :support_combo_count => consensus_opts.support_combo_count,
        :refine_top_families => consensus_opts.refine_top_families,
        :do_equation_refit => consensus_opts.do_equation_refit,
    )
    artifact[:synth_config] = Dict{Symbol, Any}(
        :max_family_seeds => synth_opts.max_family_seeds,
        :max_cross_family_seeds => synth_opts.max_cross_family_seeds,
        :allow_cross_family_synthesis => synth_opts.allow_cross_family_synthesis,
        :allow_parameter_stitching => synth_opts.allow_parameter_stitching,
        :cross_family_distance_limit => synth_opts.cross_family_distance_limit,
        :seed_consistency_threshold => synth_opts.seed_consistency_threshold,
        :max_refine_candidates => synth_opts.max_refine_candidates,
        :refine_with_full_trajectory => synth_opts.refine_with_full_trajectory,
        :refine_objective_mode => synth_opts.refine_objective_mode,
    )
    artifact[:primary_conclusion] = primary_conclusion
    artifact[:secondary_conclusion] = secondary_conclusion
    artifact[:error_message] = nothing
    return artifact
end

function _strategy_shift_rows(case_artifact::Dict{Symbol, Any})
    baseline = case_artifact[:strategies][:best_fit_baseline]
    rows = NamedTuple[]
    for strategy_key in (:family_consensus, :synthesized_finalizer)
        summary = case_artifact[:strategies][strategy_key]
        push!(rows, (
            strategy = strategy_key,
            fit_delta = _summary_fit_error(baseline) - _summary_fit_error(summary),
            parameter_rmse_delta = _summary_parameter_rmse(baseline) - _summary_parameter_rmse(summary),
            combined_rmse_delta = _summary_combined_rmse(baseline) - _summary_combined_rmse(summary),
            best_gain = _summary_biggest_shift(baseline, summary; direction = :improvement),
            worst_regression = _summary_biggest_shift(baseline, summary; direction = :worsening),
        ))
    end
    return rows
end

function _render_bilby_case_study_markdown(case_artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "# Bilby Sweep Case: $(case_artifact[:case_id])\n")
    println(io, "- Model: `$(case_artifact[:model_name])`")
    println(io, "- Bucket: `$(case_artifact[:bucket_label])`")
    println(io, "- Selected via: `$(case_artifact[:selected_via])`")
    println(io, "- Generated: `$(case_artifact[:generated_at])`")
    println(io, "- Status: `$(case_artifact[:status])`")
    println(io, "- Case dir: `$(case_artifact[:case_dir])`\n")

    if case_artifact[:status] == :load_failed
        println(io, "## Failure\n")
        println(io, "- Loader error: `$(case_artifact[:error_message])`")
        return String(take!(io))
    end

    if case_artifact[:status] != :ok
        println(io, "## Failure\n")
        println(io, "- Error: `$(case_artifact[:error_message])`")
        println(io, "- Primary conclusion: `$(case_artifact[:primary_conclusion])`")
        return String(take!(io))
    end

    ref = case_artifact[:benchmark_reference]
    println(io, "## Benchmark Reference\n")
    println(io, "| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |")
    println(io, "|------------|--------------|-------------|-----------|---------|")
    println(io, "| `amigo2_run` | $(_fmt_percent(ref.mean_rel_error_a)) | $(_fmt_percent(ref.max_rel_error_a)) | $(_fmt_float(ref.time_a; digits = 3)) | $(ref.is_successful_a) |")
    println(io, "| `odepe_multipoint` | $(_fmt_percent(ref.mean_rel_error_b)) | $(_fmt_percent(ref.max_rel_error_b)) | $(_fmt_float(ref.time_b; digits = 3)) | $(ref.is_successful_b) |")
    println(io, "- Benchmark classification: `$(ref.classification)`\n")

    config = case_artifact[:run_config]
    println(io, "## Sweep Run Configuration\n")
    println(io, "- Interpolator: `$(config[:interpolator])` (resolved count $(config[:interpolator_count]))")
    println(io, "- Shooting points: $(config[:shooting_points])")
    println(io, "- Multipoint: enabled=$(config[:use_multipoint]), points=$(config[:multipoint_n_points]), max pairs=$(config[:multipoint_max_pairs])")
    println(io, "- Parameter homotopy: $(config[:use_parameter_homotopy])")
    println(io, "- Raw candidate generation: $(_fmt_float(case_artifact[:shared_total_seconds]; digits = 3)) s shared\n")

    raw_pool = case_artifact[:raw_pool]
    println(io, "## Shared Raw Pool\n")
    println(io, "- Raw candidates: $(case_artifact[:raw_candidate_count])")
    println(io, "- Families: $(case_artifact[:family_count])")
    println(io, "- Best raw fit index: $(get(raw_pool, :best_fit_index, nothing))")
    println(io, "- Best raw oracle index: $(get(raw_pool, :best_truth_index, nothing))")
    println(io, "- Best-fit vs best-truth RMSE gap: $(_fmt_percent(get(raw_pool, :best_fit_vs_truth_gap, Inf)))\n")

    println(io, "## Strategy Comparison\n")
    println(io, "| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |")
    println(io, "|----------|--------|--------|-----------|------------|---------------|---------|")
    for strategy_key in (:best_fit_baseline, :family_consensus, :synthesized_finalizer)
        summary = case_artifact[:strategies][strategy_key]
        winner_label = strategy_key == :synthesized_finalizer ? string(get(summary, :winning_origin, get(summary, :winner_mode, :missing))) : _consensus_winner_label(summary)
        println(io, "| `$(strategy_key)` | `$(summary[:status])` | $(winner_label) | $(_fmt_sci(_summary_fit_error(summary))) | $(_fmt_percent(_summary_parameter_rmse(summary))) | $(_fmt_percent(_summary_combined_rmse(summary))) | $(summary[:final_winner_lineage]) |")
    end
    println(io)

    println(io, "## Baseline Deltas\n")
    println(io, "| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |")
    println(io, "|----------|-----------|------------------|---------------------|--------------|--------------------|")
    for row in _strategy_shift_rows(case_artifact)
        gain = isnothing(row.best_gain) ? "none" : "$(row.best_gain.label) ($(_fmt_percent(row.best_gain.before)) → $(_fmt_percent(row.best_gain.after)))"
        regression = isnothing(row.worst_regression) ? "none" : "$(row.worst_regression.label) ($(_fmt_percent(row.worst_regression.before)) → $(_fmt_percent(row.worst_regression.after)))"
        println(io, "| `$(row.strategy)` | $(_fmt_sci(row.fit_delta)) | $(_fmt_percent(row.parameter_rmse_delta)) | $(_fmt_percent(row.combined_rmse_delta)) | $(gain) | $(regression) |")
    end
    println(io)

    println(io, "## Synthesized Seeds\n")
    println(io, "| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |")
    println(io, "|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|")
    if isempty(case_artifact[:synthesized_seed_rows])
        println(io, "| 1 | - | none | none | none | false | Inf | Inf | Inf | Inf |")
    else
        for row in case_artifact[:synthesized_seed_rows]
            println(io, "| $(row.rank) | $(row.seed_index) | `$(row.kind)` | $(row.families) | $(row.source_candidates) | $(row.accepted) | $(_fmt_float(row.pre_refine_score; digits = 4)) | $(_fmt_sci(row.fit_loss)) | $(_fmt_sci(row.equation_penalty)) | $(_fmt_float(row.nearest_raw_distance; digits = 4)) |")
        end
    end
    println(io)

    println(io, "## Conclusion\n")
    println(io, "- Primary: `$(case_artifact[:primary_conclusion])`")
    !isnothing(case_artifact[:secondary_conclusion]) && println(io, "- Secondary: `$(case_artifact[:secondary_conclusion])`")
    println(io)

    return String(take!(io))
end

function _sweep_case_row(case_artifact::Dict{Symbol, Any})
    baseline = get(case_artifact[:strategies], :best_fit_baseline, Dict{Symbol, Any}())
    consensus = get(case_artifact[:strategies], :family_consensus, Dict{Symbol, Any}())
    synth = get(case_artifact[:strategies], :synthesized_finalizer, Dict{Symbol, Any}())
    return (
        case_id = case_artifact[:case_id],
        model_name = case_artifact[:model_name],
        bucket = String(case_artifact[:bucket_label]),
        classification = case_artifact[:benchmark_reference].classification,
        selected_via = String(case_artifact[:selected_via]),
        raw_candidate_count = case_artifact[:raw_candidate_count],
        family_count = case_artifact[:family_count],
        primary_conclusion = String(case_artifact[:primary_conclusion]),
        secondary_conclusion = isnothing(case_artifact[:secondary_conclusion]) ? "" : String(case_artifact[:secondary_conclusion]),
        baseline_combined_rmse = _summary_combined_rmse(baseline),
        consensus_combined_rmse = _summary_combined_rmse(consensus),
        synth_combined_rmse = _summary_combined_rmse(synth),
        consensus_delta_combined_rmse = _summary_combined_rmse(baseline) - _summary_combined_rmse(consensus),
        synth_delta_combined_rmse = _summary_combined_rmse(baseline) - _summary_combined_rmse(synth),
        best_fit_vs_truth_gap = get(case_artifact[:raw_pool], :best_fit_vs_truth_gap, Inf),
    )
end

function _render_bilby_sweep_summary_csv(sweep_artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "case_id,model_name,bucket,classification,selected_via,raw_candidate_count,family_count,primary_conclusion,secondary_conclusion,baseline_combined_rmse,consensus_combined_rmse,synth_combined_rmse,consensus_delta_combined_rmse,synth_delta_combined_rmse,best_fit_vs_truth_gap")
    for case_artifact in sweep_artifact[:cases]
        row = _sweep_case_row(case_artifact)
        println(io, join([
            row.case_id,
            row.model_name,
            row.bucket,
            row.classification,
            row.selected_via,
            string(row.raw_candidate_count),
            string(row.family_count),
            row.primary_conclusion,
            row.secondary_conclusion,
            string(row.baseline_combined_rmse),
            string(row.consensus_combined_rmse),
            string(row.synth_combined_rmse),
            string(row.consensus_delta_combined_rmse),
            string(row.synth_delta_combined_rmse),
            string(row.best_fit_vs_truth_gap),
        ], ","))
    end
    return String(take!(io))
end

function _best_case_by(cases, score_fn; positive::Bool)
    isempty(cases) && return nothing
    best = nothing
    best_score = positive ? -Inf : Inf
    for case_artifact in cases
        score = score_fn(case_artifact)
        isfinite(score) || continue
        if (positive && score > best_score) || (!positive && score < best_score)
            best = case_artifact
            best_score = score
        end
    end
    return best
end

function _render_bilby_sweep_summary_markdown(sweep_artifact::Dict{Symbol, Any})
    io = IOBuffer()
    println(io, "# Bilby Sweep Summary: $(sweep_artifact[:benchmark_name])\n")
    println(io, "- Generated: `$(sweep_artifact[:generated_at])`")
    println(io, "- Benchmark root: `$(sweep_artifact[:benchmark_root])`")
    println(io, "- Noise slice: `$(sweep_artifact[:noise_label])`")
    println(io, "- Total cases: $(length(sweep_artifact[:cases]))")
    println(io, "- Oracle note: $(sweep_artifact[:oracle_note])\n")

    println(io, "## Selected Cases\n")
    println(io, "| Case | Bucket | Classification | Selected Via | ODEPE Mean Rel Err | ODEPE Max Rel Err |")
    println(io, "|------|--------|----------------|--------------|--------------------|-------------------|")
    for case_artifact in sweep_artifact[:cases]
        ref = case_artifact[:benchmark_reference]
        println(io, "| `$(case_artifact[:case_id])` | $(case_artifact[:bucket_label]) | `$(ref.classification)` | `$(case_artifact[:selected_via])` | $(_fmt_percent(ref.mean_rel_error_b)) | $(_fmt_percent(ref.max_rel_error_b)) |")
    end
    println(io)

    counts = sweep_artifact[:aggregate_counts]
    println(io, "## Aggregate Counts\n")
    println(io, "- Consensus beat baseline: $(counts[:consensus_beats_baseline])")
    println(io, "- Synthesis beat baseline: $(counts[:synth_beats_baseline])")
    println(io, "- Synthesis beat consensus: $(counts[:synth_beats_consensus])")
    println(io, "- Raw baseline remained best: $(counts[:baseline_remained_best])\n")

    deltas = sweep_artifact[:aggregate_deltas]
    println(io, "## Aggregate Deltas\n")
    println(io, "| Metric | Mean | Median |")
    println(io, "|--------|------|--------|")
    println(io, "| Consensus minus baseline combined RMSE improvement | $(_fmt_percent(deltas[:consensus_combined_mean])) | $(_fmt_percent(deltas[:consensus_combined_median])) |")
    println(io, "| Synthesis minus baseline combined RMSE improvement | $(_fmt_percent(deltas[:synth_combined_mean])) | $(_fmt_percent(deltas[:synth_combined_median])) |")
    println(io, "| Consensus minus baseline parameter RMSE improvement | $(_fmt_percent(deltas[:consensus_parameter_mean])) | $(_fmt_percent(deltas[:consensus_parameter_median])) |")
    println(io, "| Synthesis minus baseline parameter RMSE improvement | $(_fmt_percent(deltas[:synth_parameter_mean])) | $(_fmt_percent(deltas[:synth_parameter_median])) |")
    println(io, "| Consensus minus baseline fit improvement | $(_fmt_sci(deltas[:consensus_fit_mean])) | $(_fmt_sci(deltas[:consensus_fit_median])) |")
    println(io, "| Synthesis minus baseline fit improvement | $(_fmt_sci(deltas[:synth_fit_mean])) | $(_fmt_sci(deltas[:synth_fit_median])) |")
    println(io)

    println(io, "## Conclusion Labels by Bucket\n")
    println(io, "| Bucket | Conclusion | Count |")
    println(io, "|--------|------------|-------|")
    for (bucket_label, label_counts) in sweep_artifact[:bucket_counts]
        for (label, count) in sort(collect(label_counts); by = x -> string(x[1]))
            println(io, "| $(bucket_label) | `$(label)` | $(count) |")
        end
    end
    println(io)

    println(io, "## Follow-up Shortlist\n")
    shortlist = sweep_artifact[:follow_up_shortlist]
    for (label, case_artifact, score) in shortlist
        if isnothing(case_artifact)
            println(io, "- $(label): none")
        else
            println(io, "- $(label): `$(case_artifact[:case_id])` ($(case_artifact[:bucket_label])) score=$(_fmt_percent(score))")
        end
    end
    println(io)

    println(io, "## Per-Case Outcomes\n")
    println(io, "| Case | Primary Conclusion | Baseline Combined RMSE | Consensus Combined RMSE | Synth Combined RMSE | Best-Fit vs Best-Truth Gap |")
    println(io, "|------|--------------------|------------------------|-------------------------|--------------------|----------------------------|")
    for case_artifact in sweep_artifact[:cases]
        row = _sweep_case_row(case_artifact)
        println(io, "| `$(row.case_id)` | `$(row.primary_conclusion)` | $(_fmt_percent(row.baseline_combined_rmse)) | $(_fmt_percent(row.consensus_combined_rmse)) | $(_fmt_percent(row.synth_combined_rmse)) | $(_fmt_percent(row.best_fit_vs_truth_gap)) |")
    end
    println(io)

    return String(take!(io))
end

function _mean_or_inf(values)
    finite_values = filter(isfinite, values)
    return isempty(finite_values) ? Inf : mean(finite_values)
end

function _median_or_inf(values)
    finite_values = filter(isfinite, values)
    return isempty(finite_values) ? Inf : median(finite_values)
end

function _build_bilby_sweep_artifact(
    benchmark_root::AbstractString;
    data_variant::AbstractString = "odepe_nopolish",
    noise::Float64 = 1e-4,
    noise_label::String = "1e-4",
    case_limit::Union{Nothing, Int} = nothing,
    requested_case_ids::Vector{String} = String[],
    est_opts::EstimationOptions = _default_sweep_estimation_options(),
    consensus_opts::ConsensusOptions = _default_sweep_consensus_options(),
    synth_opts::SynthesizedFinalizerOptions = _default_sweep_synthesized_options(),
)
    selected_cases = _select_bilby_sweep_cases(
        benchmark_root;
        data_variant = data_variant,
        noise = noise,
        case_limit = case_limit,
        requested_case_ids = requested_case_ids,
    )

    case_artifacts = Dict{Symbol, Any}[
        _build_bilby_case_study_artifact(
            case_spec;
            est_opts = est_opts,
            consensus_opts = consensus_opts,
            synth_opts = synth_opts,
        )
        for case_spec in selected_cases
    ]

    consensus_beats = count(case_artifact -> begin
        baseline = case_artifact[:strategies][:best_fit_baseline]
        consensus = case_artifact[:strategies][:family_consensus]
        _summary_combined_rmse(consensus) + 1e-9 < _summary_combined_rmse(baseline)
    end, case_artifacts)
    synth_beats = count(case_artifact -> begin
        baseline = case_artifact[:strategies][:best_fit_baseline]
        synth = case_artifact[:strategies][:synthesized_finalizer]
        _summary_combined_rmse(synth) + 1e-9 < _summary_combined_rmse(baseline)
    end, case_artifacts)
    synth_beats_consensus = count(case_artifact -> begin
        consensus = case_artifact[:strategies][:family_consensus]
        synth = case_artifact[:strategies][:synthesized_finalizer]
        _summary_combined_rmse(synth) + 1e-9 < _summary_combined_rmse(consensus)
    end, case_artifacts)
    baseline_best = count(case_artifact -> case_artifact[:primary_conclusion] in (:selector_not_needed, :raw_pool_too_sparse, :candidate_generation_bottleneck), case_artifacts)

    consensus_combined_deltas = [
        _summary_combined_rmse(case_artifact[:strategies][:best_fit_baseline]) - _summary_combined_rmse(case_artifact[:strategies][:family_consensus])
        for case_artifact in case_artifacts
    ]
    synth_combined_deltas = [
        _summary_combined_rmse(case_artifact[:strategies][:best_fit_baseline]) - _summary_combined_rmse(case_artifact[:strategies][:synthesized_finalizer])
        for case_artifact in case_artifacts
    ]
    consensus_parameter_deltas = [
        _summary_parameter_rmse(case_artifact[:strategies][:best_fit_baseline]) - _summary_parameter_rmse(case_artifact[:strategies][:family_consensus])
        for case_artifact in case_artifacts
    ]
    synth_parameter_deltas = [
        _summary_parameter_rmse(case_artifact[:strategies][:best_fit_baseline]) - _summary_parameter_rmse(case_artifact[:strategies][:synthesized_finalizer])
        for case_artifact in case_artifacts
    ]
    consensus_fit_deltas = [
        _summary_fit_error(case_artifact[:strategies][:best_fit_baseline]) - _summary_fit_error(case_artifact[:strategies][:family_consensus])
        for case_artifact in case_artifacts
    ]
    synth_fit_deltas = [
        _summary_fit_error(case_artifact[:strategies][:best_fit_baseline]) - _summary_fit_error(case_artifact[:strategies][:synthesized_finalizer])
        for case_artifact in case_artifacts
    ]

    bucket_counts = OrderedDict{String, Dict{Symbol, Int}}()
    for case_artifact in case_artifacts
        label_counts = get!(bucket_counts, String(case_artifact[:bucket_label]), Dict{Symbol, Int}())
        primary = case_artifact[:primary_conclusion]
        label_counts[primary] = get(label_counts, primary, 0) + 1
    end

    best_positive = _best_case_by(case_artifacts, case_artifact -> _summary_combined_rmse(case_artifact[:strategies][:best_fit_baseline]) - _summary_combined_rmse(case_artifact[:strategies][:synthesized_finalizer]); positive = true)
    best_negative = _best_case_by(case_artifacts, case_artifact -> _summary_combined_rmse(case_artifact[:strategies][:best_fit_baseline]) - _summary_combined_rmse(case_artifact[:strategies][:synthesized_finalizer]); positive = false)
    biggest_gap = _best_case_by(case_artifacts, case_artifact -> get(case_artifact[:raw_pool], :best_fit_vs_truth_gap, -Inf); positive = true)

    return Dict{Symbol, Any}(
        :benchmark_name => basename(String(benchmark_root)),
        :benchmark_root => String(benchmark_root),
        :generated_at => string(Dates.now()),
        :noise_label => noise_label,
        :oracle_note => "Truth-based metrics in these sweep artifacts are benchmark-only evaluation metrics and were not used by the selector/finalizer.",
        :cases => case_artifacts,
        :aggregate_counts => Dict{Symbol, Any}(
            :consensus_beats_baseline => consensus_beats,
            :synth_beats_baseline => synth_beats,
            :synth_beats_consensus => synth_beats_consensus,
            :baseline_remained_best => baseline_best,
        ),
        :aggregate_deltas => Dict{Symbol, Any}(
            :consensus_combined_mean => _mean_or_inf(consensus_combined_deltas),
            :consensus_combined_median => _median_or_inf(consensus_combined_deltas),
            :synth_combined_mean => _mean_or_inf(synth_combined_deltas),
            :synth_combined_median => _median_or_inf(synth_combined_deltas),
            :consensus_parameter_mean => _mean_or_inf(consensus_parameter_deltas),
            :consensus_parameter_median => _median_or_inf(consensus_parameter_deltas),
            :synth_parameter_mean => _mean_or_inf(synth_parameter_deltas),
            :synth_parameter_median => _median_or_inf(synth_parameter_deltas),
            :consensus_fit_mean => _mean_or_inf(consensus_fit_deltas),
            :consensus_fit_median => _median_or_inf(consensus_fit_deltas),
            :synth_fit_mean => _mean_or_inf(synth_fit_deltas),
            :synth_fit_median => _median_or_inf(synth_fit_deltas),
        ),
        :bucket_counts => bucket_counts,
        :follow_up_shortlist => [
            ("biggest positive synthesis delta", best_positive, isnothing(best_positive) ? Inf : _summary_combined_rmse(best_positive[:strategies][:best_fit_baseline]) - _summary_combined_rmse(best_positive[:strategies][:synthesized_finalizer])),
            ("biggest negative synthesis delta", best_negative, isnothing(best_negative) ? Inf : _summary_combined_rmse(best_negative[:strategies][:best_fit_baseline]) - _summary_combined_rmse(best_negative[:strategies][:synthesized_finalizer])),
            ("biggest best-fit vs best-truth divergence", biggest_gap, isnothing(biggest_gap) ? Inf : get(biggest_gap[:raw_pool], :best_fit_vs_truth_gap, Inf)),
        ],
    )
end
