using Dates
using ODEParameterEstimation
using Printf

const PROJECT_ROOT = normpath(joinpath(@__DIR__, ".."))
const AUDIT_TIMESTAMP = get(ENV, "ODEPE_ITERFIX_TIMESTAMP", Dates.format(now(), "yyyy-mm-dd_HHMMSS"))
const AUDIT_ROOT = get(ENV, "ODEPE_ITERFIX_ROOT", joinpath(PROJECT_ROOT, "artifacts", "iterfix_audit", AUDIT_TIMESTAMP))
const RAW_DIR = joinpath(AUDIT_ROOT, "raw")
const KEY_DIR = joinpath(AUDIT_ROOT, "key")
const SUMMARY_TSV = get(ENV, "ODEPE_ITERFIX_TSV", joinpath(AUDIT_ROOT, "summary.tsv"))
const TIMEOUT_SECS = something(tryparse(Float64, get(ENV, "ODEPE_ITERFIX_TIMEOUT_SECS", "1200")), 1200.0)
const PARALLELISM = max(1, something(tryparse(Int, get(ENV, "ODEPE_ITERFIX_WORKERS", "4")), 4))
const CASE_RUNNER = joinpath(@__DIR__, "iterfix_case_runner.jl")

struct ModelSpec
    name::Symbol
    category::Symbol
end

mutable struct ActiveJob
    spec::ModelSpec
    proc::Base.Process
    io::IOStream
    start_time::Float64
    raw_log_path::String
    key_log_path::String
end

function available_model_specs()
    registries = ODEParameterEstimation.available_model_categories()
    ordered_categories = [:green, :structural_unidentifiability, :hard, :limitations]
    specs = ModelSpec[]
    for category in ordered_categories
        for model_name in sort!(collect(keys(registries[category])); by = string)
            push!(specs, ModelSpec(model_name, category))
        end
    end
    return specs
end

function selected_specs(args::Vector{String})
    all_specs = available_model_specs()
    if isempty(args) || (length(args) == 1 && only(args) == "--all")
        return all_specs
    end

    spec_by_name = Dict(spec.name => spec for spec in all_specs)
    requested = ModelSpec[]
    for arg in args
        name = Symbol(replace(arg, "model:" => ""))
        haskey(spec_by_name, name) || error("Unknown model $(name). Use --all or explicit names from available_models().")
        push!(requested, spec_by_name[name])
    end
    return requested
end

sanitize_filename(name::Symbol) = replace(string(name), r"[^A-Za-z0-9_.-]" => "_")

function tsv_escape(value)
    return replace(replace(string(value), '\t' => ' '), '\n' => "\\n")
end

function write_summary_header(path::String)
    mkpath(dirname(path))
    open(path, "w") do io
        write(io, join([
            "model_name",
            "category",
            "status",
            "runtime_seconds",
            "iterfix_entered",
            "iterfix_iteration_count",
            "iterfix_fix_count",
            "fixed_parameters",
            "iterfix_convergence_reason",
            "saw_template_dd_extension",
            "saw_true_unknown_or_late_miss",
            "posdef_count",
            "final_exception_summary",
            "raw_log_path",
            "key_log_path",
        ], '\t') * "\n")
    end
end

function append_summary_row(path::String, row)
    open(path, "a") do io
        values = [
            string(row.model_name),
            string(row.category),
            row.status,
            @sprintf("%.3f", row.runtime_seconds),
            string(row.iterfix_entered),
            string(row.iterfix_iteration_count),
            string(row.iterfix_fix_count),
            join(row.fixed_parameters, ","),
            row.iterfix_convergence_reason,
            string(row.saw_template_dd_extension),
            string(row.saw_true_unknown_or_late_miss),
            string(row.posdef_count),
            tsv_escape(row.final_exception_summary),
            row.raw_log_path,
            row.key_log_path,
        ]
        write(io, join(values, '\t') * "\n")
    end
end

function load_log_text(path::String)
    return isfile(path) ? read(path, String) : ""
end

function extract_key_lines(text::String)
    key_lines = String[]
    for line in split(text, '\n')
        isempty(line) && continue
        if occursin("[ITERATIVE-FIX]", line) ||
           occursin("[SI-MAP]", line) ||
           occursin("[TRFN-SOLVE]", line) ||
           occursin("[DEBUG-EQ-COUNT]", line) ||
           occursin("AUDIT_CASE_", line) ||
           occursin("AUDIT_EXCEPTION_SUMMARY", line) ||
           occursin("ERROR:", line) ||
           occursin("Exception", line)
            push!(key_lines, line)
        end
    end
    return key_lines
end

function write_key_log(raw_log_path::String, key_log_path::String)
    text = load_log_text(raw_log_path)
    key_lines = extract_key_lines(text)
    open(key_log_path, "w") do io
        for line in key_lines
            println(io, line)
        end
    end
end

function parse_iterfix_convergence_reason(text::String, status::String)
    if occursin("CONVERGED: Nearly-determined system", text)
        return "nearly_determined"
    elseif occursin("CONVERGED: Determined system achieved", text)
        return "determined"
    elseif occursin("No parameter available to fix", text)
        return "no_param_available"
    elseif occursin("Overdetermined system", text) && occursin("[ITERATIVE-FIX]", text)
        return "overdetermined_stop"
    elseif occursin("Did not converge after", text)
        return "max_iter_stop"
    elseif status == "timeout"
        return "timeout"
    elseif status != "completed"
        return "exception_before_result"
    elseif occursin("[ITERATIVE-FIX] Iteration", text)
        return "no_terminal_marker"
    else
        return "did_not_reach_iterfix_result"
    end
end

function parse_exception_summary(text::String)
    m = match(r"AUDIT_EXCEPTION_SUMMARY\tstatus=error\tsummary=(.*)", text)
    if !isnothing(m)
        captured = m.captures[1]
        try
            return Meta.parse(captured) |> eval |> string
        catch
            return captured
        end
    end
    err_line = findlast(line -> startswith(line, "ERROR:"), split(text, '\n'))
    isnothing(err_line) && return ""
    return split(text, '\n')[err_line]
end

function parse_log_summary(spec::ModelSpec, status::String, runtime_seconds::Float64, raw_log_path::String, key_log_path::String)
    text = load_log_text(raw_log_path)
    iteration_matches = collect(eachmatch(r"\[ITERATIVE-FIX\] Iteration (\d+)", text))
    fix_matches = collect(eachmatch(r"\[ITERATIVE-FIX\] Fixing parameter: ([^=\n]+?)\s*=", text))
    fixed_parameters = [strip(m.captures[1]) for m in fix_matches]
    iter_count = isempty(iteration_matches) ? 0 : maximum(parse(Int, m.captures[1]) for m in iteration_matches)
    return (
        model_name = spec.name,
        category = spec.category,
        status = status,
        runtime_seconds = runtime_seconds,
        iterfix_entered = !isempty(iteration_matches),
        iterfix_iteration_count = iter_count,
        iterfix_fix_count = length(fixed_parameters),
        fixed_parameters = fixed_parameters,
        iterfix_convergence_reason = parse_iterfix_convergence_reason(text, status),
        saw_template_dd_extension = occursin("[SI-MAP] Extending DerivativeData support for SI template", text),
        saw_true_unknown_or_late_miss = occursin(":true_unknown_variable", text) || occursin(":late_map_miss", text) || occursin("true_unknown_variable", text) || occursin("late_map_miss", text),
        posdef_count = length(collect(eachmatch(r"PosDefException", text))),
        final_exception_summary = parse_exception_summary(text),
        raw_log_path = raw_log_path,
        key_log_path = key_log_path,
    )
end

function spawn_job(spec::ModelSpec)
    raw_log_path = joinpath(RAW_DIR, string(sanitize_filename(spec.name), ".log"))
    key_log_path = joinpath(KEY_DIR, string(sanitize_filename(spec.name), ".log"))
    io = open(raw_log_path, "w")
    julia_bin = joinpath(Sys.BINDIR, Base.julia_exename())
    cmd = `$julia_bin --project=$(PROJECT_ROOT) $(CASE_RUNNER) $(String(spec.name)) $(String(spec.category))`
    proc = run(pipeline(ignorestatus(cmd), stdout = io, stderr = io); wait = false)
    return ActiveJob(spec, proc, io, time(), raw_log_path, key_log_path)
end

function close_job_io!(job::ActiveJob)
    try
        close(job.io)
    catch
    end
    return nothing
end

function finalize_job!(job::ActiveJob, status::String)
    runtime_seconds = time() - job.start_time
    close_job_io!(job)
    write_key_log(job.raw_log_path, job.key_log_path)
    return parse_log_summary(job.spec, status, runtime_seconds, job.raw_log_path, job.key_log_path)
end

function process_status(job::ActiveJob)
    if process_running(job.proc)
        return nothing
    end
    status = if success(job.proc)
        "completed"
    elseif job.proc.exitcode < 0
        "worker_crash"
    else
        "error"
    end
    return finalize_job!(job, status)
end

function timeout_job!(job::ActiveJob)
    try
        kill(job.proc)
    catch
    end
    try
        wait(job.proc)
    catch
    end
    return finalize_job!(job, "timeout")
end

function print_row(row)
    println(join([
        string(row.model_name),
        string(row.category),
        row.status,
        @sprintf("%.3f", row.runtime_seconds),
        string(row.iterfix_entered),
        string(row.iterfix_iteration_count),
        string(row.iterfix_fix_count),
        join(row.fixed_parameters, ","),
        row.iterfix_convergence_reason,
        string(row.saw_template_dd_extension),
        string(row.saw_true_unknown_or_late_miss),
        string(row.posdef_count),
        tsv_escape(row.final_exception_summary),
        row.raw_log_path,
        row.key_log_path,
    ], '\t'))
end

function run_audit(specs::Vector{ModelSpec})
    mkpath(RAW_DIR)
    mkpath(KEY_DIR)
    write_summary_header(SUMMARY_TSV)

    pending = collect(specs)
    active = ActiveJob[]

    println(join([
        "model_name",
        "category",
        "status",
        "runtime_seconds",
        "iterfix_entered",
        "iterfix_iteration_count",
        "iterfix_fix_count",
        "fixed_parameters",
        "iterfix_convergence_reason",
        "saw_template_dd_extension",
        "saw_true_unknown_or_late_miss",
        "posdef_count",
        "final_exception_summary",
        "raw_log_path",
        "key_log_path",
    ], '\t'))

    while !isempty(pending) || !isempty(active)
        while length(active) < PARALLELISM && !isempty(pending)
            spec = popfirst!(pending)
            push!(active, spawn_job(spec))
        end

        completed_rows = Any[]
        remaining_jobs = ActiveJob[]
        for job in active
            elapsed = time() - job.start_time
            if elapsed > TIMEOUT_SECS
                push!(completed_rows, timeout_job!(job))
                continue
            end

            row = process_status(job)
            if isnothing(row)
                push!(remaining_jobs, job)
            else
                push!(completed_rows, row)
            end
        end
        active = remaining_jobs

        for row in completed_rows
            print_row(row)
            append_summary_row(SUMMARY_TSV, row)
        end

        isempty(active) || sleep(1.0)
    end
end

specs = selected_specs(ARGS)
run_audit(specs)
