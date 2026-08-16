# Summarize checkpointed estimator-aware nonlinear campaign cells.
#
# Example:
#
#   julia --startup-file=no repro/uq_coverage_harness_2026_08/summarize_estimator_aware_nonlinear.jl \
#       repro/uq_coverage_harness_2026_08/results/lv_vdp_estimator_routes_n5_20260814 \
#       --out=repro/uq_coverage_harness_2026_08/results/lv_vdp_estimator_routes_n5_20260814/summary.md

using Printf
using Statistics
using TOML

function _summary_arg(name::String, default::String)
	prefix = "--$(name)="
	match = findfirst(arg -> startswith(arg, prefix), ARGS)
	isnothing(match) && return default
	return ARGS[match][(length(prefix) + 1):end]
end

function _campaign_files()
	paths = filter(arg -> !startswith(arg, "--"), ARGS)
	isempty(paths) && error("provide at least one campaign directory or TOML file")
	files = String[]
	for path in paths
		if isdir(path)
			append!(files, filter(file -> endswith(file, ".toml"),
				joinpath.(path, readdir(path))))
		elseif isfile(path) && endswith(path, ".toml")
			push!(files, path)
		else
			@warn "ignoring missing or non-TOML campaign input" path
		end
	end
	return sort!(unique(files))
end

function _finite_values(values)
	return Float64[x for x in values if x isa Real && isfinite(x)]
end

function _worst_error(cell)
	errors = _finite_values(get(row, "relative_error", Inf)
		for row in get(cell, "coordinates", []))
	return isempty(errors) ? Inf : maximum(errors)
end

function _count_summary(values)
	counts = Dict{String, Int}()
	for value in values
		key = string(value)
		counts[key] = get(counts, key, 0) + 1
	end
	return join(["$key=$(counts[key])" for key in sort!(collect(keys(counts)))], ", ")
end

function _parent_kind(cell)
	lineage = get(cell, "lineage", [])
	length(lineage) >= 2 || return "—"
	return string(get(lineage[2], "estimator_kind", "unknown"))
end

function _group_key(cell)
	interval = Float64.(get(cell, "time_interval", Float64[]))
	window = isempty(interval) ? "?" : "$(first(interval))–$(last(interval))"
	return (
		string(get(cell, "model", "unknown")),
		window,
		Float64(get(cell, "noise", NaN)),
		string(get(cell, "arm", "unknown")),
		string(get(cell, "multipoint_pair_strategy", "spread")),
		Float64(get(cell, "gp_derivative_lengthscale_factor", 1.0)),
	)
end

function _outcome_key(cell)
	outcome = string(get(cell, "outcome", "unknown"))
	if outcome == "report"
		return "report:" * string(get(cell, "uq_status", "unknown"))
	elseif outcome == "uq_unavailable"
		return outcome * ":" * string(get(cell, "uq_reason", "unknown"))
	elseif outcome == "error"
		return "error"
	else
		return outcome
	end
end

function _reliability_axis(cell, axis::String)
	reliability = get(cell, "uq_reliability", Dict{String, Any}())
	haskey(reliability, axis) && return string(reliability[axis])
	# Schema-v1 checkpoints predate independent reliability axes. Preserve them
	# in summaries without pretending their legacy status certified calibration.
	outcome = string(get(cell, "outcome", "unknown"))
	if axis == "availability"
		return outcome == "report" ? "available" :
			outcome == "uq_unavailable" ? "unavailable" : "not_available"
	elseif axis == "numerical_linearization"
		return outcome == "report" ? "legacy_not_recorded" : "not_computed"
	elseif axis == "empirical_calibration"
		return "not_assessed"
	end
	return "not_recorded"
end

function _median_or_nan(values)
	finite = _finite_values(values)
	return isempty(finite) ? NaN : median(finite)
end

function _maximum_or_nan(values)
	finite = _finite_values(values)
	return isempty(finite) ? NaN : maximum(finite)
end

function _render_summary(cells)
	groups = Dict{Tuple{String, String, Float64, String, String, Float64}, Vector{Dict{String, Any}}}()
	for cell in cells
		push!(get!(groups, _group_key(cell), Dict{String, Any}[]), cell)
	end

	io = IOBuffer()
	println(io, "# Estimator-aware nonlinear campaign summary\n")
	println(io, "Generated from $(length(cells)) completed checkpoint cells. Small-N results are routing and accuracy pilots, not calibration claims.\n")
	println(io, "| model | window | noise | arm | pair strategy | ℓ factor | N | selected estimator | seed lineage | outcome/reason | availability | numerical | median worst error | max worst error | median seconds |")
	println(io, "|---|---:|---:|---|---|---:|---:|---|---|---|---|---|---:|---:|---:|")
	for key in sort!(collect(keys(groups)))
		model, window, noise, arm, pair_strategy, lengthscale_factor = key
		rows = groups[key]
		routes = _count_summary(get(get(row, "selected_identity", Dict()),
			"estimator_kind", "none") for row in rows)
		parents = _count_summary(_parent_kind(row) for row in rows)
		outcomes = _count_summary(_outcome_key(row) for row in rows)
		availability = _count_summary(
			_reliability_axis(row, "availability") for row in rows)
		numerical = _count_summary(
			_reliability_axis(row, "numerical_linearization") for row in rows)
		errors = [_worst_error(row) for row in rows]
		seconds = [get(row, "elapsed_seconds", NaN) for row in rows]
		@printf(io, "| %s | %s | %.1e | %s | %s | %.3g | %d | %s | %s | %s | %s | %s | %.3g | %.3g | %.1f |\n",
			model, window, noise, arm, pair_strategy, lengthscale_factor,
			length(rows), routes, parents, outcomes, availability, numerical,
			_median_or_nan(errors), _maximum_or_nan(errors), _median_or_nan(seconds))
	end

	println(io, "\n## Coordinate diagnostics\n")
	println(io, "Conditional coverage uses finite reported standard errors. Usable rate and unconditional coverage retain every attempted cell in the denominator; unavailable or nonfinite UQ therefore cannot disappear from the headline result.\n")
	println(io, "| model | window | noise | arm | pair strategy | ℓ factor | coordinate | N attempted | N estimate | median error | N usable UQ | usable rate | median abs(z) | conditional 95% coverage | unconditional 95% coverage |")
	println(io, "|---|---:|---:|---|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|")
	for key in sort!(collect(keys(groups)))
		model, window, noise, arm, pair_strategy, lengthscale_factor = key
		rows = groups[key]
		labels = sort!(unique(string(get(coord, "label", "unknown"))
			for row in rows for coord in get(row, "coordinates", [])))
		for label in labels
			coordinates = [coord for row in rows for coord in get(row, "coordinates", [])
				if string(get(coord, "label", "unknown")) == label]
			errors = _finite_values(get(coord, "relative_error", Inf) for coord in coordinates)
			zs = _finite_values(get(coord, "z", NaN) for coord in coordinates)
			n_attempted = length(rows)
			n_covered = count(z -> abs(z) <= 1.959963984540054, zs)
			conditional_coverage = isempty(zs) ? NaN : n_covered / length(zs)
			usable_rate = n_attempted == 0 ? NaN : length(zs) / n_attempted
			unconditional_coverage = n_attempted == 0 ? NaN : n_covered / n_attempted
			@printf(io, "| %s | %s | %.1e | %s | %s | %.3g | %s | %d | %d | %.3g | %d | %.1f%% | %.3g | %.1f%% | %.1f%% |\n",
				model, window, noise, arm, pair_strategy, lengthscale_factor,
				label, n_attempted, length(errors),
				isempty(errors) ? NaN : median(errors), length(zs), 100 * usable_rate,
				isempty(zs) ? NaN : median(abs.(zs)), 100 * conditional_coverage,
				100 * unconditional_coverage)
		end
	end
	return String(take!(io))
end

files = _campaign_files()
cells = Dict{String, Any}[TOML.parsefile(file) for file in files]
rendered = _render_summary(cells)
print(rendered)
out_path = _summary_arg("out", "")
if !isempty(out_path)
	mkpath(dirname(abspath(out_path)))
	open(out_path, "w") do io
		write(io, rendered)
	end
	println("\nSaved summary to ", abspath(out_path))
end
