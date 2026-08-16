# Aggregate the preregistered model-assisted polish follow-up records.
#
# Truth is used only for offline estimator comparison. The correction and
# trajectory-SSE screen in each input record remain truth-free.

using Dates
using Printf
using Statistics
using TOML

isdefined(@__MODULE__, :_mas_group_summary) ||
    include(joinpath(@__DIR__, "summarize_model_assisted_replicates.jl"))

function _map_int_list(name::String, default::String)
    values = _mas_list(name, default)
    return isempty(values) ? Int[] : parse.(Int, values)
end

function _map_polished_coordinate_difference(pilot, corrected)
    pilot_coordinates = get(pilot, "coordinates", Any[])
    corrected_coordinates = get(corrected, "coordinates", Any[])
    length(pilot_coordinates) == length(corrected_coordinates) || return NaN
    differences = Float64[]
    for (pilot_coordinate, corrected_coordinate) in
        zip(pilot_coordinates, corrected_coordinates)
        get(pilot_coordinate, "label", "") ==
            get(corrected_coordinate, "label", "") || return NaN
        pilot_estimate = Float64(get(pilot_coordinate, "estimate", NaN))
        corrected_estimate =
            Float64(get(corrected_coordinate, "estimate", NaN))
        truth = Float64(get(pilot_coordinate, "truth", NaN))
        all(isfinite, (pilot_estimate, corrected_estimate, truth)) || return NaN
        scale = max(abs(truth), eps(Float64))
        push!(differences, abs(pilot_estimate - corrected_estimate) / scale)
    end
    return isempty(differences) ? NaN : maximum(differences)
end

function _map_group_summary(records::Vector{Dict{String, Any}})
    screen_accepts = 0
    raw_improvements = 0
    false_accepts = 0
    false_rejects = 0
    paired_records = 0
    pilot_polish_seconds = Float64[]
    corrected_polish_seconds = Float64[]
    paired_time_ratios = Float64[]
    raw_prepolish_ratios = Float64[]
    paired_seed_ratios = Float64[]
    polish_error_differences = Float64[]
    polish_estimate_differences = Float64[]
    pilot_polish_errors = Float64[]
    corrected_polish_errors = Float64[]
    order_counts = Dict{String, Int}()

    for record in records
        estimators = record["estimators"]
        pilot = estimators["pilot"]
        raw = _mas_raw_record(estimators)
        accepted = get(record, "correction_screen_status", "") ==
            "trajectory_objective_improved"
        screen_accepts += accepted

        pilot_max = Float64(get(pilot, "max_relative_error", NaN))
        raw_max = Float64(get(raw, "max_relative_error", NaN))
        improves = _mas_available(raw) && isfinite(pilot_max) &&
            isfinite(raw_max) && raw_max < pilot_max
        raw_improvements += improves
        false_accepts += accepted && !improves
        false_rejects += !accepted && improves
        raw_ratio = _mas_ratio(raw_max, pilot_max)
        isfinite(raw_ratio) && push!(raw_prepolish_ratios, raw_ratio)

        pilot_polish =
            get(estimators, "polish_from_pilot", Dict{String, Any}())
        corrected_polish =
            get(estimators, "polish_from_corrected", Dict{String, Any}())
        paired = _mas_available(pilot_polish) &&
            _mas_available(corrected_polish)
        paired || continue
        paired_records += 1

        screened =
            get(estimators, "model_assisted_screened", Dict{String, Any}())
        screened_max = Float64(get(screened, "max_relative_error", NaN))
        seed_ratio = _mas_ratio(screened_max, pilot_max)
        isfinite(seed_ratio) && push!(paired_seed_ratios, seed_ratio)

        pilot_seconds =
            Float64(get(pilot_polish, "elapsed_seconds", NaN))
        corrected_seconds =
            Float64(get(corrected_polish, "elapsed_seconds", NaN))
        isfinite(pilot_seconds) && push!(pilot_polish_seconds, pilot_seconds)
        isfinite(corrected_seconds) &&
            push!(corrected_polish_seconds, corrected_seconds)
        time_ratio = _mas_ratio(corrected_seconds, pilot_seconds)
        isfinite(time_ratio) && push!(paired_time_ratios, time_ratio)

        pilot_error =
            Float64(get(pilot_polish, "max_relative_error", NaN))
        corrected_error =
            Float64(get(corrected_polish, "max_relative_error", NaN))
        isfinite(pilot_error) && push!(pilot_polish_errors, pilot_error)
        isfinite(corrected_error) &&
            push!(corrected_polish_errors, corrected_error)
        all(isfinite, (pilot_error, corrected_error)) &&
            push!(polish_error_differences, abs(pilot_error - corrected_error))
        estimate_difference = _map_polished_coordinate_difference(
            pilot_polish, corrected_polish,
        )
        isfinite(estimate_difference) &&
            push!(polish_estimate_differences, estimate_difference)

        order = join(String.(get(record, "polish_order", String[])), "->")
        order_counts[order] = get(order_counts, order, 0) + 1
    end

    median_or_nan(values) = isempty(values) ? NaN : median(values)
    maximum_or_nan(values) = isempty(values) ? NaN : maximum(values)
    return Dict{String, Any}(
        "replicates" => length(records),
        "screen_accepts" => screen_accepts,
        "raw_truth_improvements" => raw_improvements,
        "false_accepts" => false_accepts,
        "false_rejects" => false_rejects,
        "paired_polish_records" => paired_records,
        "unpaired_records" => length(records) - paired_records,
        "median_raw_prepolish_max_error_ratio" =>
            median_or_nan(raw_prepolish_ratios),
        "median_paired_seed_max_error_ratio" =>
            median_or_nan(paired_seed_ratios),
        "median_pilot_polish_seconds" => median_or_nan(pilot_polish_seconds),
        "median_corrected_polish_seconds" =>
            median_or_nan(corrected_polish_seconds),
        "median_paired_polish_time_ratio" =>
            median_or_nan(paired_time_ratios),
        "median_pilot_polished_max_relative_error" =>
            median_or_nan(pilot_polish_errors),
        "median_corrected_polished_max_relative_error" =>
            median_or_nan(corrected_polish_errors),
        "max_paired_polished_error_difference" =>
            maximum_or_nan(polish_error_differences),
        "max_paired_polished_estimate_relative_difference" =>
            maximum_or_nan(polish_estimate_differences),
        "polish_order_counts" => order_counts,
    )
end

function main_summarize_model_assisted_polish()
    dirs = _mas_list("dirs", "")
    isempty(dirs) && throw(ArgumentError("provide one or more --dirs paths"))
    warmup_seeds = Set(_map_int_list("warmup-seeds", "8163200"))
    paths = String[]
    for dir in dirs
        isdir(dir) || throw(ArgumentError("result directory does not exist: $dir"))
        append!(paths, filter(path -> endswith(path, ".toml"),
            readdir(dir; join = true)))
    end

    records = Dict{String, Any}[]
    excluded_warmups = Dict{String, Any}[]
    for path in sort(unique(paths))
        record = TOML.parsefile(path)
        get(record, "outcome", "") == "ok" || continue
        haskey(record, "estimators") || continue
        get(record, "run_polish", false) === true || continue
        if Int(record["noise_seed"]) in warmup_seeds
            push!(excluded_warmups, record)
        else
            push!(records, record)
        end
    end
    isempty(records) && throw(ArgumentError("no evaluation polish records found"))

    grouped = Dict{Tuple{String, Float64}, Vector{Dict{String, Any}}}()
    for record in records
        key = (String(record["case_id"]), Float64(record["noise"]))
        push!(get!(grouped, key, Dict{String, Any}[]), record)
    end

    summaries = Dict{String, Any}()
    println("\n", "="^151)
    println("MODEL-ASSISTED REPEATED-POLISH SUMMARY")
    println("="^151)
    @printf("%-28s %-9s %3s %5s %5s %4s %4s %10s %10s %10s %10s\n",
        "case", "noise", "N", "acc", "pairs", "FA", "FR",
        "seed ratio", "pilot sec", "corr sec", "time ratio")
    for key in sort(collect(keys(grouped)))
        case_id, noise = key
        group = sort(grouped[key]; by = record -> Int(record["noise_seed"]))
        summary = _map_group_summary(group)
        summary["case_id"] = case_id
        summary["noise"] = noise
        summary["seeds"] = Int[record["noise_seed"] for record in group]
        summaries["$(case_id)__noise_$(noise)"] = summary
        @printf("%-28s %-9.1e %3d %5d %5d %4d %4d %10.3g %10.3g %10.3g %10.3g\n",
            case_id, noise, summary["replicates"],
            summary["screen_accepts"], summary["paired_polish_records"],
            summary["false_accepts"], summary["false_rejects"],
            summary["median_paired_seed_max_error_ratio"],
            summary["median_pilot_polish_seconds"],
            summary["median_corrected_polish_seconds"],
            summary["median_paired_polish_time_ratio"])
    end
    println("="^151)

    output = Dict{String, Any}(
        "schema_version" => 1,
        "generated_at" => string(now()),
        "source_directories" => dirs,
        "truth_usage" => "evaluation_only",
        "warmup_seeds" => sort(collect(warmup_seeds)),
        "excluded_warmup_records" => length(excluded_warmups),
        "groups" => summaries,
    )
    out_path = _mas_arg("out", "")
    !isempty(out_path) && _atomic_toml(out_path, output)
    return output
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_summarize_model_assisted_polish()
end
