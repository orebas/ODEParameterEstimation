# Paired research panel for model-assisted algebraic correction (2026-08-16).
#
# Each audited model/noise cell compares the exact same selected seed as an
# unpolished pilot, an IFT one-step update, a same-branch polynomial re-solve,
# and a trajectory-polish seed before/after correction.  It does not rerun the
# full candidate pool for each polish arm, so this isolates seed quality.

include(joinpath(@__DIR__, "run_estimator_aware_peb_canaries.jl"))

using Random

function _mac_bool_arg(name::String, default::Bool)
    fallback = default ? "true" : "false"
    return lowercase(_campaign_arg(name, fallback)) in ("true", "yes", "1")
end

function _mac_synthetic_problem(
    case_id::String,
    case,
    paths,
    noise::Float64,
    seed::Int,
    max_observations::Int,
)
    base, rows, original_rows = _peb_problem(
        case, paths.data, max_observations,
    )
    sample_times = Float64.(base.data_sample["t"])
    clean = ODEParameterEstimation.sample_data(
        base.model.system,
        base.measured_quantities,
        Float64[first(sample_times), last(sample_times)],
        base.p_true,
        base.ic,
        length(sample_times);
        uneven_sampling = true,
        uneven_sampling_times = sample_times,
        solver = package_wide_default_ode_solver,
        abstol = 1e-14,
        reltol = 1e-14,
    )
    Random.seed!(seed)
    noisy = add_additive_noise(clean, noise)
    problem = ParameterEstimationProblem(
        "$(case_id)_mac_noise_$noise",
        base.model,
        base.measured_quantities,
        noisy,
        Float64[first(sample_times), last(sample_times)],
        package_wide_default_ode_solver,
        base.p_true,
        base.ic,
        base.unident_count,
    )
    return problem, clean, rows, original_rows
end

function _mac_working_problem(
    problem::ParameterEstimationProblem,
    opts::EstimationOptions,
)
    working = deepcopy(problem)
    if opts.auto_handle_transcendentals
        t_var = ModelingToolkit.get_iv(working.model.system)
        working, _ = ODEParameterEstimation.transform_pep_for_estimation(
            working, t_var,
        )
    end
    scale_info = nothing
    working_opts = opts
    if opts.auto_rescale
        working, scale_info = rescale_pep(working)
        if !isnothing(scale_info)
            working_opts = ODEParameterEstimation.rescale_option_bounds(
                opts, scale_info, working,
            )
        end
    end
    return working, working_opts, scale_info
end

function _mac_physical_result(result, scale_info)
    isnothing(result) && return nothing
    output = deepcopy(result)
    !isnothing(scale_info) && unrescale_results([output], scale_info)
    return output
end

function _mac_result_record(
    problem::ParameterEstimationProblem,
    result::Union{Nothing, ParameterEstimationResult};
    elapsed_seconds::Float64 = NaN,
)
    isnothing(result) && return Dict{String, Any}(
        "available" => false,
        "elapsed_seconds" => elapsed_seconds,
    )
    coordinates = Dict{String, Any}[]
    relative_errors = Float64[]
    absolute_errors = Float64[]
    for coordinate in _model_coordinates(problem)
        estimate = Float64(_center_for_label(result, coordinate.label))
        absolute_error = abs(estimate - coordinate.truth)
        relative_error = absolute_error / max(abs(coordinate.truth), 1e-12)
        push!(absolute_errors, absolute_error)
        push!(relative_errors, relative_error)
        push!(coordinates, Dict{String, Any}(
            "label" => coordinate.label,
            "role" => string(coordinate.role),
            "truth" => coordinate.truth,
            "estimate" => estimate,
            "absolute_error" => absolute_error,
            "relative_error" => relative_error,
        ))
    end
    identity = result.provenance.estimator_identity
    return Dict{String, Any}(
        "available" => true,
        "elapsed_seconds" => elapsed_seconds,
        "fit_sse" => isnothing(result.err) ? Inf : Float64(result.err),
        "max_absolute_error" => isempty(absolute_errors) ? NaN : maximum(absolute_errors),
        "max_relative_error" => isempty(relative_errors) ? NaN : maximum(relative_errors),
        "median_relative_error" => isempty(relative_errors) ? NaN : median(relative_errors),
        "identity" => _identity_dict(identity),
        "source_type" => string(result.provenance.source_type),
        "polish_applied" => result.provenance.polish_applied,
        "notes" => string.(result.provenance.notes),
        "coordinates" => coordinates,
    )
end

function _mac_polish_candidate(
    context,
    candidate::ParameterEstimationResult,
    opts::EstimationOptions,
)
    measurement = @timed ODEParameterEstimation._polish_batch_from_context(
        context, ParameterEstimationResult[candidate]; opts,
    )
    outputs = measurement.value
    polished = length(outputs) >= 2 ? last(outputs) : nothing
    return polished, Float64(measurement.time), Int64(measurement.bytes)
end

function _mac_output_path(
    out_dir::String,
    case_id::String,
    noise::Float64,
    seed::Int,
    max_observations::Int,
)
    rows = max_observations <= 0 ? "full" : "n$max_observations"
    return joinpath(
        out_dir,
        "$(case_id)__noise_$(_safe_token(noise))__seed_$(seed)__$(rows).toml",
    )
end

function _run_model_assisted_cell(
    case_id::String,
    case,
    noise::Float64,
    seed::Int,
    cell_index::Int;
    peb_root::String,
    out_dir::String,
    max_observations::Int,
    shooting_points::Int,
    max_pairs::Int,
    run_polish::Bool,
    polish_maxtime::Float64,
    force::Bool,
)
    output_path = _mac_output_path(
        out_dir, case_id, noise, seed, max_observations,
    )
    if isfile(output_path) && !force
        println("SKIP completed: ", basename(output_path))
        return TOML.parsefile(output_path)
    end

    paths = _peb_paths(peb_root, case_id, case)
    problem, _, rows, original_rows = _mac_synthetic_problem(
        case_id, case, paths, noise, seed, max_observations,
    )
    algebraic_arm = case.historical_kind == :single_point_algebraic ? "sp" : "mp"
    extra = _peb_arm_options(
        case, algebraic_arm, shooting_points, max_pairs, "uq_only",
    )
    n_unknowns = length(case.p_true) + length(case.ic)
    opts = EstimationOptions(;
        datasize = length(rows),
        time_interval = Float64[first(problem.data_sample["t"]), last(problem.data_sample["t"])],
        noise_level = noise,
        noise_model = :additive,
        nooutput = true,
        diagnostics = false,
        shooting_warp = true,
        shooting_warp_beta = 3.0,
        use_parameter_homotopy = true,
        opt_lb = fill(1e-5, n_unknowns),
        opt_ub = fill(10.0, n_unknowns),
        extra...,
    )
    working_problem, working_opts, scale_info = _mac_working_problem(problem, opts)
    polish_opts = merge_options(
        working_opts;
        compute_uncertainty = false,
        polish_solutions = true,
        polish_solver_solutions = true,
        polish_maxtime = polish_maxtime,
        polish_max_concurrency = 1,
    )

    payload = Dict{String, Any}(
        "schema_version" => 1,
        "scope" => "model_assisted_fixed_selected_seed_panel",
        "case_id" => case_id,
        "model" => string(case.model),
        "noise" => noise,
        "noise_model" => "additive_homoskedastic",
        "noise_seed" => seed,
        "algebraic_arm" => algebraic_arm,
        "interpolator_pool" => "uq_only",
        "peb_frozen_sha" => PEB_FROZEN_SHA,
        "data_sha256" => case.data_sha256,
        "generator_sha256" => case.generator_sha256,
        "metadata_sha256" => case.metadata_sha256,
        "historical_interpolator" => string(case.historical_interpolator),
        "historical_kind" => string(case.historical_kind),
        "historical_max_error" => case.historical_max_error,
        "used_observations" => length(rows),
        "original_observations" => original_rows,
        "shooting_points" => shooting_points,
        "multipoint_max_pairs" => max_pairs,
        "run_polish" => run_polish,
        "polish_method" => string(polish_opts.polish_method),
        "polish_maxtime" => polish_maxtime,
        "started_at" => string(now()),
    )

    println("RUN case=$case_id noise=$noise seed=$seed arm=$algebraic_arm")
    flush(stdout)
    wall_start = time()
    try
        cell_value, _ = ODEParameterEstimation._with_run_context(
                capture_timing = true) do
            analysis_measurement = @timed ODEParameterEstimation._analyze_parameter_estimation_problem_impl(
                deepcopy(problem), opts,
            )
            analysis_tuple = analysis_measurement.value
            timing = ODEParameterEstimation._run_ctx().timing
            raw, analysis, uq = analysis_tuple
            isempty(analysis.returned_results) && return (
                outcome = :no_estimate,
                analysis_seconds = Float64(analysis_measurement.time),
                analysis_bytes = Int64(analysis_measurement.bytes),
                timing,
                raw_count = isempty(raw) ? 0 : length(raw[1]),
                selected = nothing,
                correction = nothing,
                correction_seconds = NaN,
                correction_bytes = Int64(0),
                polish_context_seconds = NaN,
                polish_context_bytes = Int64(0),
                pilot_polished = nothing,
                corrected_polished = nothing,
                pilot_polish_seconds = NaN,
                corrected_polish_seconds = NaN,
                pilot_polish_bytes = Int64(0),
                corrected_polish_bytes = Int64(0),
                polish_order = String[],
                uq,
            )

            selected = first(analysis.returned_results)
            identity = selected.provenance.estimator_identity
            artifact = get(
                ODEParameterEstimation._run_ctx().estimator_artifacts,
                identity.candidate_id,
                nothing,
            )
            artifact isa Union{
                ODEParameterEstimation.SinglePointUQArtifact,
                ODEParameterEstimation.MultipointUQArtifact,
            } || throw(ArgumentError(
                "selected estimator did not retain an algebraic artifact; got $(typeof(artifact))",
            ))

            correction_measurement = @timed research_model_assisted_one_step(
                working_problem, selected, artifact;
                abstol = working_opts.abstol,
                reltol = working_opts.reltol,
            )
            correction = correction_measurement.value
            corrected_seed = correction.screened_result

            polish_context_seconds = NaN
            polish_context_bytes = Int64(0)
            pilot_polished = nothing
            corrected_polished = nothing
            pilot_polish_seconds = NaN
            corrected_polish_seconds = NaN
            pilot_polish_bytes = Int64(0)
            corrected_polish_bytes = Int64(0)
            polish_order = String[]
            if run_polish && !isnothing(corrected_seed)
                context_measurement = @timed ODEParameterEstimation._build_polish_context(
                    working_problem; opts = polish_opts,
                )
                polish_context = context_measurement.value
                polish_context_seconds = Float64(context_measurement.time)
                polish_context_bytes = Int64(context_measurement.bytes)
                arm_order = isodd(cell_index) ?
                    ("pilot", "corrected") : ("corrected", "pilot")
                append!(polish_order, arm_order)
                for polish_arm in arm_order
                    if polish_arm == "pilot"
                        pilot_polished, pilot_polish_seconds, pilot_polish_bytes =
                            _mac_polish_candidate(
                                polish_context, correction.pilot_result, polish_opts,
                            )
                    else
                        corrected_polished, corrected_polish_seconds,
                            corrected_polish_bytes = _mac_polish_candidate(
                                polish_context, corrected_seed, polish_opts,
                            )
                    end
                end
            end
            return (
                outcome = :ok,
                analysis_seconds = Float64(analysis_measurement.time),
                analysis_bytes = Int64(analysis_measurement.bytes),
                timing,
                raw_count = isempty(raw) ? 0 : length(raw[1]),
                selected,
                correction,
                correction_seconds = Float64(correction_measurement.time),
                correction_bytes = Int64(correction_measurement.bytes),
                polish_context_seconds,
                polish_context_bytes,
                pilot_polished,
                corrected_polished,
                pilot_polish_seconds,
                corrected_polish_seconds,
                pilot_polish_bytes,
                corrected_polish_bytes,
                polish_order,
                uq,
            )
        end

        payload["outcome"] = string(cell_value.outcome)
        payload["analysis_seconds"] = cell_value.analysis_seconds
        payload["analysis_allocated_bytes"] = cell_value.analysis_bytes
        payload["structured_timing"] = timing_breakdown_to_dict(cell_value.timing)
        payload["raw_candidate_count"] = cell_value.raw_count
        if cell_value.outcome == :ok
            correction = cell_value.correction
            pilot = _mac_physical_result(correction.pilot_result, scale_info)
            linear = _mac_physical_result(correction.linear_result, scale_info)
            resolved = _mac_physical_result(correction.resolved_result, scale_info)
            pilot_polished = _mac_physical_result(
                cell_value.pilot_polished, scale_info,
            )
            corrected_polished = _mac_physical_result(
                cell_value.corrected_polished, scale_info,
            )
            payload["selected_identity"] = _identity_dict(
                cell_value.selected.provenance.estimator_identity,
            )
            payload["correction_status"] = string(correction.status)
            payload["correction_message"] = correction.message
            payload["correction_screen_status"] = string(correction.screen_status)
            payload["correction_screen_message"] = correction.screen_message
            payload["correction_relative_data_norm"] = correction.correction_norm
            payload["pilot_root_residual"] = correction.pilot_residual
            payload["linear_root_residual"] = correction.linear_residual
            payload["resolved_root_residual"] = correction.resolved_residual
            payload["newton_iterations"] = correction.newton_iterations
            payload["correction_data_coordinates"] = [
                Dict{String, Any}(
                    "label" => correction.data_labels[i],
                    "observed" => correction.observed_data_values[i],
                    "pilot_model_smoothed" => correction.model_smoothed_values[i],
                    "pilot_model_exact" => correction.model_exact_values[i],
                    "estimated_bias" => correction.estimated_bias[i],
                    "corrected" => correction.corrected_data_values[i],
                )
                for i in eachindex(correction.data_labels)
            ]
            payload["pilot_root"] = correction.pilot_root
            payload["linear_root"] = correction.linear_root
            payload["resolved_root"] = correction.resolved_root
            payload["correction_stage_seconds"] = Dict(
                string(key) => value for (key, value) in correction.timings
            )
            payload["correction_total_seconds"] = cell_value.correction_seconds
            payload["correction_allocated_bytes"] = cell_value.correction_bytes
            payload["polish_context_seconds"] = cell_value.polish_context_seconds
            payload["polish_context_allocated_bytes"] = cell_value.polish_context_bytes
            payload["polish_order"] = cell_value.polish_order
            payload["estimators"] = Dict{String, Any}(
                "pilot" => _mac_result_record(problem, pilot),
                "model_assisted_linear" => _mac_result_record(problem, linear;
                    elapsed_seconds = cell_value.correction_seconds),
                "model_assisted_resolved" => _mac_result_record(problem, resolved;
                    elapsed_seconds = cell_value.correction_seconds),
                "model_assisted_screened" => _mac_result_record(
                    problem,
                    _mac_physical_result(correction.screened_result, scale_info);
                    elapsed_seconds = cell_value.correction_seconds,
                ),
                "polish_from_pilot" => _mac_result_record(problem, pilot_polished;
                    elapsed_seconds = cell_value.pilot_polish_seconds),
                "polish_from_corrected" => _mac_result_record(problem, corrected_polished;
                    elapsed_seconds = cell_value.corrected_polish_seconds),
            )
            payload["polish_allocated_bytes"] = Dict{String, Any}(
                "pilot" => cell_value.pilot_polish_bytes,
                "corrected" => cell_value.corrected_polish_bytes,
            )
            payload["corrected_uq_policy"] =
                "unavailable_pending_pilot_through_correction_influence"
        end
    catch err
        err isa InterruptException && rethrow()
        payload["outcome"] = "error"
        payload["message"] = sprint(showerror, err, catch_backtrace())
    end
    payload["elapsed_seconds"] = time() - wall_start
    payload["max_rss_bytes"] = Sys.maxrss()
    payload["completed_at"] = string(now())
    _atomic_toml(output_path, payload)
    println("DONE ", basename(output_path), " outcome=", payload["outcome"],
        " elapsed=", round(payload["elapsed_seconds"]; digits = 1), "s")
    flush(stdout)
    return payload
end

function _print_model_assisted_summary(payloads)
    println("\n", "="^142)
    println("MODEL-ASSISTED FIXED-SEED PANEL")
    println("="^142)
    @printf("%-28s %-9s %-10s %-12s %-12s %-12s %-12s %-9s\n",
        "case", "noise", "outcome", "pilot", "screened", "polish p",
        "polish c", "corr sec")
    for payload in payloads
        estimators = get(payload, "estimators", Dict{String, Any}())
        error_for(name) = get(get(estimators, name, Dict{String, Any}()),
            "max_relative_error", NaN)
        @printf("%-28s %-9.1e %-10s %-12.3g %-12.3g %-12.3g %-12.3g %-9.2f\n",
            payload["case_id"], payload["noise"], payload["outcome"],
            error_for("pilot"), error_for("model_assisted_screened"),
            error_for("polish_from_pilot"), error_for("polish_from_corrected"),
            get(payload, "correction_total_seconds", NaN))
    end
    println("="^142)
    return nothing
end

function main_model_assisted_panel()
    case_ids = _campaign_list(
        "cases",
        "lotka_volterra_5_1em6,fitzhugh_nagumo_9_1em6,slow_fast_5_1em6,receptor_binding_5_1em6",
    )
    unknown = setdiff(case_ids, collect(keys(PEB_AUDITED_CASES)))
    isempty(unknown) || throw(ArgumentError(
        "unknown audited cases: $(join(unknown, ", "))",
    ))
    noises = parse.(Float64, _campaign_list("noises", "1e-6,1e-4,1e-2"))
    all(noise -> isfinite(noise) && noise >= 0, noises) || throw(ArgumentError(
        "all noise levels must be finite and non-negative",
    ))
    base_seed = parse(Int, _campaign_arg("seed", "8162026"))
    max_observations = parse(Int, _campaign_arg("max-observations", "0"))
    shooting_points = parse(Int, _campaign_arg("shooting-points", "20"))
    max_pairs = parse(Int, _campaign_arg("max-pairs", "15"))
    run_polish = _mac_bool_arg("polish", true)
    polish_maxtime = parse(Float64, _campaign_arg("polish-maxtime", "120.0"))
    cell_index_offset = parse(Int, _campaign_arg("cell-index-offset", "0"))
    force = _mac_bool_arg("force", false)
    peb_root = normpath(_campaign_arg("peb-root", _default_peb_root()))
    out_name = _campaign_arg(
        "out", "model_assisted_panel_$(Dates.format(now(), "yyyymmdd_HHMMSS"))",
    )
    out_dir = isabspath(out_name) ? out_name : joinpath(@__DIR__, "results", out_name)
    mkpath(out_dir)

    println("PEB root: ", peb_root)
    println("Output: ", out_dir)
    println("Cases: ", join(case_ids, ", "), " | noises: ", noises,
        " | polish: ", run_polish)
    payloads = Dict{String, Any}[]
    cell_index = cell_index_offset
    for (case_position, case_id) in enumerate(case_ids),
            (_, noise) in enumerate(noises)
        cell_index += 1
        # Reuse the same standardized draw across a model's noise levels.
        seed = base_seed + 1000 * case_position
        push!(payloads, _run_model_assisted_cell(
            case_id, PEB_AUDITED_CASES[case_id], noise, seed, cell_index;
            peb_root, out_dir, max_observations, shooting_points, max_pairs,
            run_polish, polish_maxtime, force,
        ))
    end
    _print_model_assisted_summary(payloads)
    println("Results saved under ", out_dir)
    return payloads
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_model_assisted_panel()
end
