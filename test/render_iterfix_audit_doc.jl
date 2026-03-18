using Dates

const SUMMARY_TSV = length(ARGS) >= 1 ? ARGS[1] : get(ENV, "ODEPE_ITERFIX_TSV", error("Set ODEPE_ITERFIX_TSV or pass summary TSV as ARGS[1]"))
const AUDIT_ROOT = length(ARGS) >= 2 ? ARGS[2] : get(ENV, "ODEPE_ITERFIX_ROOT", dirname(SUMMARY_TSV))
const DOC_PATH = length(ARGS) >= 3 ? ARGS[3] : get(ENV, "ODEPE_ITERFIX_DOC", joinpath(dirname(dirname(SUMMARY_TSV)), "..", "docs", string(Dates.today(), "_iterfix_audit.md")))

function parse_tsv(path::String)
    lines = readlines(path)
    isempty(lines) && return NamedTuple[]
    header = split(first(lines), '\t')
    rows = NamedTuple[]
    for line in Iterators.drop(lines, 1)
        isempty(line) && continue
        parts = split(line, '\t')
        data = Dict{Symbol, String}()
        for (key, value) in zip(header, parts)
            data[Symbol(key)] = replace(value, "\\n" => "\n")
        end
        push!(rows, (;
            model_name = data[:model_name],
            category = data[:category],
            status = data[:status],
            runtime_seconds = tryparse(Float64, get(data, :runtime_seconds, "")) |> x -> isnothing(x) ? NaN : x,
            iterfix_entered = get(data, :iterfix_entered, "false") == "true",
            iterfix_iteration_count = something(tryparse(Int, get(data, :iterfix_iteration_count, "")), 0),
            iterfix_fix_count = something(tryparse(Int, get(data, :iterfix_fix_count, "")), 0),
            fixed_parameters = isempty(get(data, :fixed_parameters, "")) ? String[] : split(data[:fixed_parameters], ','),
            iterfix_convergence_reason = get(data, :iterfix_convergence_reason, ""),
            saw_template_dd_extension = get(data, :saw_template_dd_extension, "false") == "true",
            saw_true_unknown_or_late_miss = get(data, :saw_true_unknown_or_late_miss, "false") == "true",
            posdef_count = something(tryparse(Int, get(data, :posdef_count, "")), 0),
            final_exception_summary = get(data, :final_exception_summary, ""),
            raw_log_path = get(data, :raw_log_path, ""),
            key_log_path = get(data, :key_log_path, ""),
        ))
    end
    return rows
end

function grouped_counts(rows, field::Symbol)
    counts = Dict{String, Int}()
    for row in rows
        key = String(getproperty(row, field))
        counts[key] = get(counts, key, 0) + 1
    end
    return sort!(collect(counts); by = first)
end

function markdown_code_safe(text::AbstractString)
    return replace(text, '`' => "'")
end

function write_doc(rows)
    entered = filter(r -> r.iterfix_entered, rows)
    fixed = filter(r -> r.iterfix_fix_count > 0, rows)
    multistep = filter(r -> r.iterfix_iteration_count > 1, rows)
    failures = filter(r -> r.status != "completed", rows)

    open(DOC_PATH, "w") do io
        println(io, "# Iterative-Fixing Audit")
        println(io)
        println(io, "- Generated: $(Dates.now())")
        println(io, "- Audit root: `$(AUDIT_ROOT)`")
        println(io, "- Summary TSV: `$(SUMMARY_TSV)`")
        println(io)
        println(io, "## Totals")
        println(io)
        println(io, "- Models audited: $(length(rows))")
        println(io, "- Entered iterative-fix loop: $(length(entered))")
        println(io, "- Fixed at least one parameter: $(length(fixed))")
        println(io, "- Used more than one iteration: $(length(multistep))")
        println(io, "- Non-completed runs: $(length(failures))")
        println(io)
        println(io, "## Status Counts")
        println(io)
        for (status, count) in grouped_counts(rows, :status)
            println(io, "- `$(status)`: $(count)")
        end
        println(io)
        println(io, "## Convergence Reasons")
        println(io)
        for (reason, count) in grouped_counts(rows, :iterfix_convergence_reason)
            println(io, "- `$(reason)`: $(count)")
        end
        println(io)
        println(io, "## Models That Actually Fixed Parameters")
        println(io)
        if isempty(fixed)
            println(io, "None.")
        else
            for row in sort!(copy(fixed); by = r -> r.model_name)
                fixed_names = join(row.fixed_parameters, ", ")
                println(io, "- `$(row.model_name)` (`$(row.category)`): iterations=$(row.iterfix_iteration_count), fixed=$(fixed_names)")
                println(io, "  raw log: `$(row.raw_log_path)`")
                println(io, "  key log: `$(row.key_log_path)`")
            end
        end
        println(io)
        println(io, "## Models With Multiple Iterations But No Recorded Fix")
        println(io)
        multi_no_fix = filter(r -> r.iterfix_iteration_count > 1 && r.iterfix_fix_count == 0, rows)
        if isempty(multi_no_fix)
            println(io, "None.")
        else
            for row in sort!(copy(multi_no_fix); by = r -> r.model_name)
                println(io, "- `$(row.model_name)` (`$(row.category)`): reason=`$(row.iterfix_convergence_reason)`")
            end
        end
        println(io)
        println(io, "## Non-Completed Models")
        println(io)
        if isempty(failures)
            println(io, "None.")
        else
            for row in sort!(copy(failures); by = r -> r.model_name)
                println(io, "- `$(row.model_name)` (`$(row.category)`): status=`$(row.status)`, reason=`$(row.iterfix_convergence_reason)`")
                if !isempty(row.final_exception_summary)
                    println(io, "  exception: `$(markdown_code_safe(row.final_exception_summary))`")
                end
            end
        end
    end
end

rows = parse_tsv(SUMMARY_TSV)
write_doc(rows)
