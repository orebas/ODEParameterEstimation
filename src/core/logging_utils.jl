
"""
    configure_logging(level=Logging.Info)

Configure the logging level for ODEParameterEstimation.
Default level is Info, but can be set to Debug for more verbose output.

# Arguments
- `level`: Logging level (Logging.Debug, Logging.Info, Logging.Warn, or Logging.Error)

# Example
```julia
configure_logging(Logging.Debug) # Enable detailed debug messages
```
"""
function configure_logging(level=Logging.Info)
    logger = ConsoleLogger(stderr, level)
    global_logger(logger)
end

"""
    log_matrix(matrix, title; level=Logging.Debug)

Log a matrix with an informative title at the specified logging level.

# Arguments
- `matrix`: Matrix to be logged
- `title`: Title for the matrix log
- `level`: Logging level (default: Debug)
"""
function log_matrix(matrix, title; level=Logging.Debug)
    Logging.with_logger(ConsoleLogger(stderr, level)) do
        @logmsg level "$title:\n$(summary(matrix))"
        rows, cols = size(matrix)
        if rows <= 20 && cols <= 20
            for i in 1:rows
                row_str = join(["$(round(matrix[i,j], digits=5))" for j in 1:cols], "\t")
                @logmsg level "Row $i:\t$row_str"
            end
        else
            @logmsg level "Matrix too large to display completely"
            @logmsg level "First few elements: $(matrix[1:min(5,rows), 1:min(5,cols)])"
        end
    end
end

"""
    log_equations(equations, title; level=Logging.Debug)

Log a set of equations with an informative title at the specified logging level.

# Arguments
- `equations`: Collection of equations to be logged
- `title`: Title for the equations log
- `level`: Logging level (default: Debug)
"""
function log_equations(equations, title; level=Logging.Debug)
    Logging.with_logger(ConsoleLogger(stderr, level)) do
        @logmsg level "$title:"
        for (i, eq) in enumerate(equations)
            @logmsg level "Equation $i: $eq"
        end
    end
end

"""
    log_dict(dict, title; level=Logging.Debug)

Log a dictionary with an informative title at the specified logging level.

# Arguments
- `dict`: Dictionary to be logged
- `title`: Title for the dictionary log
- `level`: Logging level (default: Debug)
"""
function log_dict(dict, title; level=Logging.Debug)
    Logging.with_logger(ConsoleLogger(stderr, level)) do
        @logmsg level "$title:"
        for (key, value) in dict
            @logmsg level "  $key => $value"
        end
    end
end

# ── Phase heartbeats ──────────────────────────────────────────────────────────
# Live, flushed, timestamped phase markers so a silent log still localizes the
# running phase (2026-07 hang post-mortem: buffered output made a stalled run
# unlocatable — see repro/hc_threading_mwe_2026_07_22/PROVENANCE_*.md). Coarse
# by design: once-per-run phases plus one line per interpolator — never inside
# per-point/per-combo inner loops.

"""
    _heartbeat(opts, phase; kind=:start, extra="")

Emit a flushed, timestamped `[HB HH:MM:SS] ▶/✓ phase` marker. No-op unless
`opts.heartbeat` is true and `opts.nooutput` is false. `kind` is `:start`,
`:done`, or `:note`; `extra` is appended verbatim.
"""
function _heartbeat(opts, phase::AbstractString; kind::Symbol = :start, extra::AbstractString = "")
    (opts.heartbeat && !opts.nooutput) || return nothing
    mark = kind === :start ? "▶" : kind === :done ? "✓" : "•"
    stamp = Dates.format(Dates.now(), "HH:MM:SS")
    if isempty(extra)
        println("[HB ", stamp, "] ", mark, " ", phase)
    else
        println("[HB ", stamp, "] ", mark, " ", phase, " ", extra)
    end
    flush(stdout)
    flush(stderr)
    return nothing
end

"""
    _heartbeat_run_header(opts, model_name)

One-line self-identifying run header (model, pid, julia/ODEPE/HC versions,
thread counts) so any log fragment is attributable without external context.
"""
function _heartbeat_run_header(opts, model_name::AbstractString)
    (opts.heartbeat && !opts.nooutput) || return nothing
    hc_ver = try
        string(pkgversion(HomotopyContinuation))
    catch
        "?"
    end
    odepe_ver = try
        string(pkgversion(@__MODULE__))
    catch
        "?"
    end
    _heartbeat(opts, "run";
        extra = string("model=", model_name, " pid=", Base.Libc.getpid(),
            " julia=", VERSION, " odepe=", odepe_ver, " hc=", hc_ver,
            " threads=", Threads.nthreads(), " gcthreads=", Threads.ngcthreads()))
end

# Enable debug logging if environment variable is set
if haskey(ENV, "ODEPE_DEBUG") && ENV["ODEPE_DEBUG"] == "true"
    configure_logging(Logging.Debug)
else
    configure_logging(Logging.Info)
end
