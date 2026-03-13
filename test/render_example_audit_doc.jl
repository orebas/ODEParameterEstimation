using Dates
using Printf

function parse_tsv(path)
	lines = filter(!isempty, readlines(path))
	isempty(lines) && return NamedTuple[]
	headers = split(first(lines), '\t')
	rows = NamedTuple[]
	for line in Iterators.drop(lines, 1)
		fields = split(line, '\t'; keepempty = true)
		length(fields) < length(headers) && resize!(fields, length(headers))
		push!(rows, NamedTuple{Tuple(Symbol.(headers))}(Tuple(fields[1:length(headers)])))
	end
	return rows
end

parse_float(s) = isempty(s) ? NaN : tryparse(Float64, s) |> x -> isnothing(x) ? NaN : x
parse_int(s) = isempty(s) ? -1 : tryparse(Int, s) |> x -> isnothing(x) ? -1 : x

function quality_hint(row)
	row.status != "ok" && return row.status
	max_rel = parse_float(row.max_rel_param_err)
	if isnan(max_rel)
		return "ok"
	elseif max_rel <= 1e-3
		return "strong"
	elseif max_rel <= 1e-1
		return "mixed"
	else
		return "poor"
	end
end

function summarize_status(rows)
	counts = Dict{String, Int}()
	for row in rows
		counts[row.status] = get(counts, row.status, 0) + 1
	end
	return counts
end

function format_float(s; digits = 3)
	x = parse_float(s)
	return isnan(x) ? "" : @sprintf("%.*g", digits, x)
end

function format_secs(s)
	x = parse_float(s)
	return isnan(x) ? "timeout" : @sprintf("%.1fs", x)
end

function code_text(s)
	return isempty(s) ? "" : "`" * replace(s, "`" => "'") * "`"
end

function write_section(io, title, rows; include_param_stats = true)
	println(io, "## ", title)
	println(io)
	counts = summarize_status(rows)
	for status in sort(collect(keys(counts)))
		println(io, "- `", status, "`: ", counts[status])
	end
	println(io)
	if include_param_stats
		println(io, "| Case | Status | Quality | Time | Best Err | Median Rel Param Err | Max Rel Param Err | Best Count | Raw Count | Note |")
		println(io, "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
		for row in sort(rows; by = r -> r.case_id)
			println(io,
				"| ", code_text(row.case_id),
				" | ", code_text(row.status),
				" | ", code_text(quality_hint(row)),
				" | ", format_secs(row.secs),
				" | ", code_text(format_float(row.best_err; digits = 6)),
				" | ", code_text(format_float(row.median_rel_param_err; digits = 6)),
				" | ", code_text(format_float(row.max_rel_param_err; digits = 6)),
				" | ", parse_int(row.best_count),
				" | ", parse_int(row.raw_count),
				" | ", replace(row.note, "|" => "\\|"),
				" |",
			)
		end
	else
		println(io, "| Case | Status | Time | Best Err | Best Count | Raw Count | Note |")
		println(io, "| --- | --- | --- | --- | --- | --- | --- |")
		for row in sort(rows; by = r -> r.case_id)
			println(io,
				"| ", code_text(row.case_id),
				" | ", code_text(row.status),
				" | ", format_secs(row.secs),
				" | ", code_text(format_float(row.best_err; digits = 6)),
				" | ", parse_int(row.best_count),
				" | ", parse_int(row.raw_count),
				" | ", replace(row.note, "|" => "\\|"),
				" |",
			)
		end
	end
	println(io)
end

model_path = get(ENV, "ODEPE_MODEL_AUDIT_TSV", "/tmp/all_model_audit.tsv")
script_path = get(ENV, "ODEPE_SCRIPT_AUDIT_TSV", "/tmp/all_script_audit.tsv")
output_path = get(ENV, "ODEPE_AUDIT_DOC", joinpath(@__DIR__, "..", "docs", "2026-03-12_example_audit.md"))

model_rows = isfile(model_path) ? parse_tsv(model_path) : NamedTuple[]
script_rows = isfile(script_path) ? parse_tsv(script_path) : NamedTuple[]

open(output_path, "w") do io
	println(io, "# Example Audit Status")
	println(io)
	println(io, "Generated on ", Dates.format(now(), dateformat"yyyy-mm-dd HH:MM"))
	println(io)
	println(io, "This document records the first-stage baseline audit for the example/model catalog using smoke-sized settings and per-case timeouts.")
	println(io)
	if !isempty(model_rows)
		write_section(io, "Model Status", model_rows; include_param_stats = true)
	end
	if !isempty(script_rows)
		write_section(io, "Script Status", script_rows; include_param_stats = false)
	end
end

println(output_path)
