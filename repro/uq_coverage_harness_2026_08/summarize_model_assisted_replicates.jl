# Aggregate repeated-noise model-assisted correction records.
#
# Truth is used here only to evaluate the research estimator and its screen;
# no truth-derived quantity enters the correction or screening decision.

using Dates
using Printf
using Statistics
using TOML

isdefined(@__MODULE__, :_atomic_toml) ||
    include(joinpath(@__DIR__, "campaign_io.jl"))

function _mas_arg(name::String, default::String)
    prefix = "--$(name)="
    match = findfirst(arg -> startswith(arg, prefix), ARGS)
    isnothing(match) && return default
    return ARGS[match][(length(prefix) + 1):end]
end

_mas_list(name::String, default::String) =
    String.(filter(!isempty, strip.(split(_mas_arg(name, default), ','))))

_mas_available(record) = get(record, "available", false) === true

function _mas_raw_record(estimators)
    resolved = get(estimators, "model_assisted_resolved", Dict{String, Any}())
    _mas_available(resolved) && return resolved
    return get(estimators, "model_assisted_linear", Dict{String, Any}())
end

function _mas_policy_record(estimators)
    policy = get(
        estimators, "model_assisted_screened_policy", Dict{String, Any}(),
    )
    _mas_available(policy) && return policy
    screened = get(
        estimators, "model_assisted_screened", Dict{String, Any}(),
    )
    _mas_available(screened) && return screened
    return get(estimators, "pilot", Dict{String, Any}())
end

function _mas_coordinate_errors(record, role::String)
    _mas_available(record) || return Float64[]
    output = Float64[]
    for coordinate in get(record, "coordinates", Any[])
        role == "all" || get(coordinate, "role", "") == role || continue
        value = Float64(get(coordinate, "relative_error", NaN))
        isfinite(value) && push!(output, value)
    end
    return output
end

function _mas_rmse(values::Vector{Float64})
    isempty(values) && return NaN
    return sqrt(mean(abs2, values))
end

function _mas_ratio(numerator::Float64, denominator::Float64)
    isfinite(numerator) && isfinite(denominator) && denominator > 0 || return NaN
    return numerator / denominator
end

function _mas_group_summary(records::Vector{Dict{String, Any}})
    n = length(records)
    pilot_all = Float64[]
    raw_all = Float64[]
    policy_all = Float64[]
    pilot_params = Float64[]
    raw_params = Float64[]
    policy_params = Float64[]
    pilot_states = Float64[]
    raw_states = Float64[]
    policy_states = Float64[]
    raw_ratios = Float64[]
    policy_ratios = Float64[]
    correction_seconds = Float64[]
    raw_usable = 0
    screen_accepts = 0
    raw_improvements = 0
    accepted_improvements = 0
    false_accepts = 0
    false_rejects = 0
    route_counts = Dict{String, Int}()

    for record in records
        estimators = record["estimators"]
        pilot = estimators["pilot"]
        raw = _mas_raw_record(estimators)
        policy = _mas_policy_record(estimators)
        append!(pilot_all, _mas_coordinate_errors(pilot, "all"))
        append!(policy_all, _mas_coordinate_errors(policy, "all"))
        append!(pilot_params, _mas_coordinate_errors(pilot, "parameter"))
        append!(policy_params, _mas_coordinate_errors(policy, "parameter"))
        append!(pilot_states, _mas_coordinate_errors(pilot, "state"))
        append!(policy_states, _mas_coordinate_errors(policy, "state"))

        pilot_max = Float64(get(pilot, "max_relative_error", NaN))
        policy_max = Float64(get(policy, "max_relative_error", NaN))
        ratio = _mas_ratio(policy_max, pilot_max)
        isfinite(ratio) && push!(policy_ratios, ratio)

        accepted = get(record, "correction_screen_status", "") ==
            "trajectory_objective_improved"
        screen_accepts += accepted
        if _mas_available(raw)
            raw_usable += 1
            append!(raw_all, _mas_coordinate_errors(raw, "all"))
            append!(raw_params, _mas_coordinate_errors(raw, "parameter"))
            append!(raw_states, _mas_coordinate_errors(raw, "state"))
            raw_max = Float64(get(raw, "max_relative_error", NaN))
            raw_ratio = _mas_ratio(raw_max, pilot_max)
            isfinite(raw_ratio) && push!(raw_ratios, raw_ratio)
            improves = isfinite(raw_max) && isfinite(pilot_max) &&
                raw_max < pilot_max
            raw_improvements += improves
            accepted_improvements += accepted && improves
            false_accepts += accepted && !improves
            false_rejects += !accepted && improves
        else
            false_accepts += accepted
        end

        seconds = Float64(get(record, "correction_total_seconds", NaN))
        isfinite(seconds) && push!(correction_seconds, seconds)
        identity = record["selected_identity"]
        route = "$(identity["estimator_kind"])@$(identity["time_indices"])"
        route_counts[route] = get(route_counts, route, 0) + 1
    end

    pilot_rmse = _mas_rmse(pilot_all)
    raw_rmse = _mas_rmse(raw_all)
    policy_rmse = _mas_rmse(policy_all)
    mechanism_advances = raw_usable >= max(n - 1, 1) &&
        raw_improvements >= ceil(Int, 0.7 * n) &&
        _mas_ratio(raw_rmse, pilot_rmse) <= 0.8
    screened_advances = false_accepts <= 1 &&
        _mas_ratio(policy_rmse, pilot_rmse) <= 0.9

    return Dict{String, Any}(
        "replicates" => n,
        "raw_usable" => raw_usable,
        "screen_accepts" => screen_accepts,
        "raw_truth_improvements" => raw_improvements,
        "accepted_truth_improvements" => accepted_improvements,
        "false_accepts" => false_accepts,
        "false_rejects" => false_rejects,
        "pilot_relative_rmse_all" => pilot_rmse,
        "raw_relative_rmse_all" => raw_rmse,
        "screened_policy_relative_rmse_all" => policy_rmse,
        "raw_to_pilot_rmse_ratio_all" => _mas_ratio(raw_rmse, pilot_rmse),
        "screened_to_pilot_rmse_ratio_all" =>
            _mas_ratio(policy_rmse, pilot_rmse),
        "pilot_relative_rmse_parameters" => _mas_rmse(pilot_params),
        "raw_relative_rmse_parameters" => _mas_rmse(raw_params),
        "screened_policy_relative_rmse_parameters" => _mas_rmse(policy_params),
        "pilot_relative_rmse_states" => _mas_rmse(pilot_states),
        "raw_relative_rmse_states" => _mas_rmse(raw_states),
        "screened_policy_relative_rmse_states" => _mas_rmse(policy_states),
        "median_raw_max_error_ratio" =>
            isempty(raw_ratios) ? NaN : median(raw_ratios),
        "median_screened_max_error_ratio" =>
            isempty(policy_ratios) ? NaN : median(policy_ratios),
        "median_correction_seconds" => isempty(correction_seconds) ?
            NaN : median(correction_seconds),
        "selected_route_counts" => route_counts,
        "mechanism_advances" => mechanism_advances,
        "screened_estimator_advances" => screened_advances,
    )
end

function main_summarize_model_assisted_replicates()
    dirs = _mas_list("dirs", "")
    isempty(dirs) && throw(ArgumentError("provide one or more --dirs paths"))
    paths = String[]
    for dir in dirs
        isdir(dir) || throw(ArgumentError("result directory does not exist: $dir"))
        append!(paths, filter(path -> endswith(path, ".toml"), readdir(dir; join = true)))
    end
    records = Dict{String, Any}[]
    for path in sort(unique(paths))
        record = TOML.parsefile(path)
        get(record, "outcome", "") == "ok" || continue
        haskey(record, "estimators") || continue
        push!(records, record)
    end
    isempty(records) && throw(ArgumentError("no successful model-assisted records found"))

    grouped = Dict{Tuple{String, Float64}, Vector{Dict{String, Any}}}()
    for record in records
        key = (String(record["case_id"]), Float64(record["noise"]))
        push!(get!(grouped, key, Dict{String, Any}[]), record)
    end
    summaries = Dict{String, Any}()
    println("\n", "="^154)
    println("MODEL-ASSISTED REPEATED-NOISE SUMMARY")
    println("="^154)
    @printf("%-28s %-9s %3s %5s %5s %5s %4s %4s %10s %10s %9s %7s %7s\n",
        "case", "noise", "N", "use", "acc", "wins", "FA", "FR",
        "raw/RMSE", "policy/RMSE", "med ratio", "mech", "screen")
    for key in sort(collect(keys(grouped)))
        case_id, noise = key
        group = sort(grouped[key]; by = record -> Int(record["noise_seed"]))
        summary = _mas_group_summary(group)
        summary["case_id"] = case_id
        summary["noise"] = noise
        summary["seeds"] = Int[record["noise_seed"] for record in group]
        summaries["$(case_id)__noise_$(noise)"] = summary
        @printf("%-28s %-9.1e %3d %5d %5d %5d %4d %4d %10.3g %10.3g %9.3g %7s %7s\n",
            case_id, noise, summary["replicates"], summary["raw_usable"],
            summary["screen_accepts"], summary["raw_truth_improvements"],
            summary["false_accepts"], summary["false_rejects"],
            summary["raw_to_pilot_rmse_ratio_all"],
            summary["screened_to_pilot_rmse_ratio_all"],
            summary["median_raw_max_error_ratio"],
            summary["mechanism_advances"],
            summary["screened_estimator_advances"])
    end
    println("="^154)

    output = Dict{String, Any}(
        "schema_version" => 1,
        "generated_at" => string(now()),
        "source_directories" => dirs,
        "truth_usage" => "evaluation_only",
        "mechanism_advancement_rule" =>
            "raw usable >= N-1, truth improvement in >=70% of pairs, and all-coordinate relative RMSE <=80% of pilot",
        "screened_advancement_rule" =>
            "false accepts <=1 and all-coordinate relative RMSE <=90% of pilot",
        "groups" => summaries,
    )
    out_path = _mas_arg("out", "")
    !isempty(out_path) && _atomic_toml(out_path, output)
    return output
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_summarize_model_assisted_replicates()
end
