# Aggregate schema-v2 audited repeated-noise UQ records without silently
# conditioning coverage on successful/finite rows.

using LinearAlgebra
using Dates
using Printf
using Statistics
using TOML

isdefined(@__MODULE__, :_atomic_toml) ||
	include(joinpath(@__DIR__, "campaign_io.jl"))

function _asru_arg(name::String, default::String)
	prefix = "--$(name)="
	index = findfirst(arg -> startswith(arg, prefix), ARGS)
	isnothing(index) && return default
	return ARGS[index][(length(prefix) + 1):end]
end

_asru_list(name::String, default::String) =
	String.(filter(!isempty, strip.(split(_asru_arg(name, default), ','))))

function _asru_group_key(record)
	config = record["config"]
	recipe = config["selection_recipe"]
	return (
		manifest_id = String(config["manifest_id"]),
		odepe_commit = String(config["odepe_commit"]),
		odepe_repository_state_sha256 = String(config["odepe_repository_state_sha256"]),
		peb_frozen_sha = String(config["peb_frozen_sha"]),
		case_id = String(record["case_id"]),
		arm = String(record["arm"]),
		interpolator_pool = String(record["interpolator_pool"]),
		data_source = String(get(record, "data_source", get(config, "data_source", "unknown"))),
		noise = Float64(record["noise"]),
		shooting_points = Int(config["shooting_points"]),
		multipoint_max_pairs = Int(config["multipoint_max_pairs"]),
		multipoint_pair_strategy = String(config["multipoint_pair_strategy"]),
		observations = Int(config["observations"]),
		lengthscale_factor = Float64(config["gp_derivative_lengthscale_factor"]),
		recipe_kind = String(recipe["kind"]),
		recipe_rows = Tuple(Int.(get(recipe, "rows", Int[]))),
		recipe_interpolator = String(get(recipe, "interpolator_source", "")),
	)
end

function _asru_coordinate_map(record)
	return Dict(
		String(row["label"]) => row for row in get(record, "coordinates", Any[])
	)
end

function _asru_mean_matrix(matrices::Vector{Matrix{Float64}})
	result = zeros(size(first(matrices)))
	for matrix in matrices
		result .+= matrix
	end
	return result ./ length(matrices)
end

function _asru_empirical_covariance(errors::Vector{Vector{Float64}})
	length(errors) >= 2 || return fill(NaN, length(first(errors)), length(first(errors)))
	values = reduce(hcat, errors)
	centered = values .- mean(values; dims = 2)
	return centered * centered' / (size(values, 2) - 1)
end

function _asru_chisq95(dimension::Int)
	dimension > 0 || return NaN
	z95 = 1.6448536269514722
	return dimension * (1 - 2 / (9dimension) + z95 * sqrt(2 / (9dimension)))^3
end

function _asru_group_summary(records::Vector{Dict{String, Any}})
	sort!(records; by = record -> Int(record["master_seed"]))
	seeds = Int[Int(record["master_seed"]) for record in records]
	length(unique(seeds)) == length(seeds) ||
		throw(ArgumentError("duplicate seeds in one audited UQ group: $seeds"))
	n = length(records)
	reports = filter(record -> get(record, "outcome", "") == "report", records)
	reason_counts = Dict{String, Int}()
	selection_counts = Dict{String, Int}()
	for record in records
		reason = String(get(record, "outcome", "missing_outcome"))
		if reason == "uq_unavailable"
			reason *= ":" * String(get(record, "uq_reason", "unknown"))
		end
		reason_counts[reason] = get(reason_counts, reason, 0) + 1
		identity = get(record, "selected_identity", Dict{String, Any}())
		if !isempty(identity)
			route = "$(get(identity, "estimator_kind", "unknown"))@$(get(identity, "time_indices", Any[]))#$(get(identity, "interpolator_source", ""))"
			selection_counts[route] = get(selection_counts, route, 0) + 1
		end
	end

	coordinate_accumulator = Dict{String, Vector{Dict{String, Any}}}()
	for record in records, row in get(record, "coordinates", Any[])
		get(row, "identifiable", true) === true || continue
		push!(get!(coordinate_accumulator, String(row["label"]), Dict{String, Any}[]), row)
	end
	coordinate_summary = Dict{String, Any}[]
	calibration_pass = !isempty(coordinate_accumulator)
	for label in sort(collect(keys(coordinate_accumulator)))
		rows = coordinate_accumulator[label]
		zs = Float64[Float64(row["z"]) for row in rows if isfinite(Float64(row["z"]))]
		errors = Float64[
			Float64(row["estimate"]) - Float64(row["truth"]) for row in rows
			if isfinite(Float64(row["estimate"])) && isfinite(Float64(row["truth"]))
		]
		relative_errors = Float64[
			Float64(get(row, "relative_error", Inf)) for row in rows
			if isfinite(Float64(get(row, "relative_error", Inf)))
		]
		covered = count(row -> get(row, "covered_95", false) === true, rows)
		conditional_coverage = isempty(zs) ? NaN : covered / length(zs)
		unconditional_coverage = covered / n
		mean_z = isempty(zs) ? NaN : mean(zs)
		std_z = length(zs) < 2 ? NaN : std(zs)
		push!(coordinate_summary, Dict{String, Any}(
			"label" => label,
			"usable_z" => length(zs),
			"mean_z" => mean_z,
			"std_z" => std_z,
			"median_absolute_z" => isempty(zs) ? NaN : median(abs.(zs)),
			"estimator_bias" => isempty(errors) ? NaN : mean(errors),
			"estimator_rmse" => isempty(errors) ? NaN : sqrt(mean(abs2, errors)),
			"median_absolute_error" => isempty(errors) ? NaN : median(abs.(errors)),
			"median_relative_error" => isempty(relative_errors) ? NaN :
				median(relative_errors),
			"maximum_relative_error" => isempty(relative_errors) ? NaN :
				maximum(relative_errors),
			"conditional_coverage_95" => conditional_coverage,
			"unconditional_coverage_95" => unconditional_coverage,
		))
		if n >= 60
			calibration_pass &= length(zs) >= ceil(Int, 0.9n)
			calibration_pass &= isfinite(mean_z) && abs(mean_z) < 0.5
			calibration_pass &= isfinite(conditional_coverage) && conditional_coverage >= 0.85
		end
	end

	errors = Vector{Float64}[]
	reported_covariances = Matrix{Float64}[]
	covariance_label_sets = Vector{Vector{String}}()
	mahalanobis = Float64[]
	joint_covered = 0
	for record in reports
		labels = String.(get(record, "uq_param_labels", String[]))
		coordinate_map = _asru_coordinate_map(record)
		keep = [i for (i, label) in enumerate(labels)
			if haskey(coordinate_map, label) &&
				get(coordinate_map[label], "identifiable", true) === true]
		isempty(keep) && continue
		error = Float64[
			Float64(coordinate_map[labels[i]]["estimate"]) -
			Float64(coordinate_map[labels[i]]["truth"])
			for i in keep
		]
		covariance = Matrix{Float64}(reduce(vcat,
			[permutedims(Float64.(row)) for row in record["uq_param_covariance"]]))
		covariance = covariance[keep, keep]
		all(isfinite, error) && all(isfinite, covariance) || continue
		push!(errors, error)
		push!(reported_covariances, covariance)
		push!(covariance_label_sets, labels[keep])
		if isposdef(Symmetric(covariance))
			q = dot(error, cholesky(Symmetric(covariance)) \ error)
			push!(mahalanobis, q)
			joint_covered += q <= _asru_chisq95(length(error))
		end
	end

	covariance_summary = Dict{String, Any}()
	if !isempty(covariance_label_sets) && any(labels != first(covariance_label_sets)
			for labels in covariance_label_sets)
		throw(ArgumentError(
			"UQ coordinate labels/order changed within one audited repeated-noise group",
		))
	end
	if !isempty(reported_covariances) && all(size(matrix) == size(first(reported_covariances))
			for matrix in reported_covariances) &&
		all(length(error) == length(first(errors)) for error in errors)
		mean_reported = _asru_mean_matrix(reported_covariances)
		empirical = _asru_empirical_covariance(errors)
		covariance_summary = Dict{String, Any}(
			"labels" => copy(first(covariance_label_sets)),
			"labels_dimension" => size(mean_reported, 1),
			"mean_reported" => [collect(row) for row in eachrow(mean_reported)],
			"empirical" => [collect(row) for row in eachrow(empirical)],
			"empirical_to_reported_variance_ratio" =>
				collect(diag(empirical) ./ diag(mean_reported)),
		)
	end

	linearizations = [get(record, "linearization", Dict{String, Any}()) for record in reports]
	jitter_ratios = Float64[
		Float64(get(item, "gp_jitter_to_noise", NaN)) for item in linearizations
		if isfinite(Float64(get(item, "gp_jitter_to_noise", NaN)))
	]
	elapsed = Float64[Float64(get(record, "elapsed_seconds", NaN)) for record in records]
	rss = Float64[Float64(get(record, "max_rss_bytes", NaN)) for record in records]
	finite_elapsed = filter(isfinite, elapsed)
	finite_rss = filter(isfinite, rss)
	estimate_records = filter(record -> !isempty(get(record, "coordinates", Any[])), records)
	accurate_estimates = count(record -> begin
		identified = filter(
			row -> get(row, "identifiable", true) === true,
			get(record, "coordinates", Any[]),
		)
		!isempty(identified) && all(row -> begin
			error = Float64(get(row, "relative_error", Inf))
			isfinite(error) && error <= 1e-3
		end, identified)
	end, estimate_records)
	stable_reports = count(record -> begin
		reliability = get(record, "uq_reliability", Dict{String, Any}())
		get(reliability, "numerical_linearization", "unknown") == "accepted" &&
			get(record, "artifact_match", "") == "exact"
	end, reports)
	availability_pass = n < 10 || length(reports) >= ceil(Int, 0.9n)
	calibration_pass &= n < 60 || stable_reports >= ceil(Int, 0.9n)
	return Dict{String, Any}(
		"replicates" => n,
		"seeds" => seeds,
		"estimate_available" => length(estimate_records),
		"estimate_available_rate" => length(estimate_records) / n,
		"accurate_estimates_at_1e-3" => accurate_estimates,
		"accurate_estimate_rate_at_1e-3" => accurate_estimates / n,
		"usable_reports" => length(reports),
		"usable_rate" => length(reports) / n,
		"numerically_stable_exact_reports" => stable_reports,
		"outcome_reason_counts" => reason_counts,
		"selection_counts" => selection_counts,
		"coordinates" => coordinate_summary,
		"covariance_comparison" => covariance_summary,
		"joint_mahalanobis_usable" => length(mahalanobis),
		"joint_mahalanobis_coverage_95" => isempty(mahalanobis) ? NaN :
			joint_covered / length(mahalanobis),
		"joint_mahalanobis_unconditional_coverage_95" => joint_covered / n,
		"mean_mahalanobis" => isempty(mahalanobis) ? NaN : mean(mahalanobis),
		"median_gp_jitter_to_noise" => isempty(jitter_ratios) ? NaN : median(jitter_ratios),
		"median_elapsed_seconds" => isempty(finite_elapsed) ? NaN : median(finite_elapsed),
		"peak_rss_bytes" => isempty(finite_rss) ? NaN : maximum(finite_rss),
		"availability_gate_pass" => availability_pass,
		"n60_calibration_gate_pass" => n >= 60 ?
			(availability_pass && calibration_pass) : false,
		"calibration_claim_permitted" => n >= 60,
	)
end

function main_summarize_audited_repeated_uq()
	dirs = _asru_list("dirs", "")
	isempty(dirs) && throw(ArgumentError("provide --dirs=<result-dir>[,<result-dir>]"))
	paths = String[]
	for dir in dirs
		isdir(dir) || throw(ArgumentError("result directory does not exist: $dir"))
		append!(paths, filter(path -> endswith(path, ".toml"), readdir(dir; join = true)))
	end
	records = Dict{String, Any}[]
	for path in sort(paths)
		record = TOML.parsefile(path)
		get(record, "schema_version", 0) == 2 || continue
		haskey(record, "config") && haskey(record, "case_id") || continue
		push!(records, record)
	end
	isempty(records) && throw(ArgumentError("no schema-v2 records found"))
	paired_hashes = Dict{Any, String}()
	for record in records
		key = (
			String(record["case_id"]),
			String(get(record, "data_source", "unknown")),
			Float64(record["noise"]),
			Int(record["master_seed"]),
		)
		hash = String(get(record, "generated_data_sha256", ""))
		isempty(hash) && continue
		if haskey(paired_hashes, key) && paired_hashes[key] != hash
			throw(ArgumentError(
				"paired-data hash mismatch for case/source/noise/seed $key",
			))
		end
		paired_hashes[key] = hash
	end
	groups = Dict{Any, Vector{Dict{String, Any}}}()
	for record in records
		push!(get!(groups, _asru_group_key(record), Dict{String, Any}[]), record)
	end
	summaries = Dict{String, Any}[]
	for (key, group) in sort(collect(groups); by = item -> string(first(item)))
		summary = _asru_group_summary(group)
		for field in propertynames(key)
			value = getproperty(key, field)
			summary[string(field)] = field == :recipe_rows ? collect(value) : value
		end
		push!(summaries, summary)
		@printf("%-30s %-20s N=%-3d usable=%-3d median_s=%8.1f\n",
			key.case_id, key.arm, summary["replicates"], summary["usable_reports"],
			summary["median_elapsed_seconds"])
	end
	output = _asru_arg("out", joinpath(first(dirs), "summary_v2.toml"))
	payload = Dict{String, Any}(
		"schema_version" => 2,
		"generated_at" => string(Dates.now()),
		"groups" => summaries,
	)
	_atomic_toml(output, payload)
	println("Summary written to ", output)
	return payload
end

if abspath(PROGRAM_FILE) == @__FILE__
	main_summarize_audited_repeated_uq()
end
