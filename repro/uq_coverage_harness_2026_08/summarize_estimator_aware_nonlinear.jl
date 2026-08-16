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
	)
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
	groups = Dict{Tuple{String, String, Float64, String}, Vector{Dict{String, Any}}}()
	for cell in cells
		push!(get!(groups, _group_key(cell), Dict{String, Any}[]), cell)
	end

	io = IOBuffer()
	println(io, "# Estimator-aware nonlinear campaign summary\n")
	println(io, "Generated from $(length(cells)) completed checkpoint cells. Small-N results are routing and accuracy pilots, not calibration claims.\n")
	println(io, "| model | window | noise | arm | N | selected estimator | seed lineage | UQ outcome | median worst error | max worst error | median seconds |")
	println(io, "|---|---:|---:|---|---:|---|---|---|---:|---:|---:|")
	for key in sort!(collect(keys(groups)))
		model, window, noise, arm = key
		rows = groups[key]
		routes = _count_summary(get(get(row, "selected_identity", Dict()),
			"estimator_kind", "none") for row in rows)
		parents = _count_summary(_parent_kind(row) for row in rows)
		outcomes = _count_summary(get(row, "outcome", "unknown") == "report" ?
			"report:" * string(get(row, "uq_status", "unknown")) :
			string(get(row, "outcome", "unknown")) * ":" *
			string(get(row, "uq_reason", "")) for row in rows)
		errors = [_worst_error(row) for row in rows]
		seconds = [get(row, "elapsed_seconds", NaN) for row in rows]
		@printf(io, "| %s | %s | %.1e | %s | %d | %s | %s | %s | %.3g | %.3g | %.1f |\n",
			model, window, noise, arm, length(rows), routes, parents, outcomes,
			_median_or_nan(errors), _maximum_or_nan(errors), _median_or_nan(seconds))
	end

	println(io, "\n## Coordinate diagnostics\n")
	println(io, "Coverage and z summaries include only cells with finite reported standard errors.\n")
	println(io, "| model | window | noise | arm | coordinate | N estimate | median error | N UQ | median abs(z) | 95% coverage |")
	println(io, "|---|---:|---:|---|---|---:|---:|---:|---:|---:|")
	for key in sort!(collect(keys(groups)))
		model, window, noise, arm = key
		rows = groups[key]
		labels = sort!(unique(string(get(coord, "label", "unknown"))
			for row in rows for coord in get(row, "coordinates", [])))
		for label in labels
			coordinates = [coord for row in rows for coord in get(row, "coordinates", [])
				if string(get(coord, "label", "unknown")) == label]
			errors = _finite_values(get(coord, "relative_error", Inf) for coord in coordinates)
			zs = _finite_values(get(coord, "z", NaN) for coord in coordinates)
			coverage = isempty(zs) ? NaN : mean(abs.(zs) .<= 1.959963984540054)
			@printf(io, "| %s | %s | %.1e | %s | %s | %d | %.3g | %d | %.3g | %.1f%% |\n",
				model, window, noise, arm, label, length(errors),
				isempty(errors) ? NaN : median(errors), length(zs),
				isempty(zs) ? NaN : median(abs.(zs)), 100 * coverage)
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
