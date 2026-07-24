# attempt.jl — pure HomotopyContinuation.jl threading-deadlock hunter (v2).
#
# Loads ONLY HomotopyContinuation. Runs many independent "attempts"; each attempt
#   (1) generates a random polynomial system as STRINGS (seeded),
#   (2) rebuilds the expressions via Meta.parse + Core.eval in a fresh Module
#       (mirrors ODEPE's convert_to_hc_format, which evals parsed strings),
#   (3) constructs HC.System and
#   (4) calls HC.solve — a fresh polyhedral solve, which always runs
#       MixedSubdivisions.fine_mixed_cells (the "Computing mixed cells..."
#       ProgressUnknown meter is ON by default inside HC; solve(show_progress=false)
#       does NOT disable it — HC's polyhedral.jl:22 passes no kwargs).
#
# Heartbeats (flushed) bracket every phase so an external watchdog can localize
# a hang: "ATTEMPT <id> START" -> "ATTEMPT <id> SOLVE" -> "ATTEMPT <id> DONE".
# A stalled log with a START/SOLVE lacking its DONE = caught hang.
#
# Modes:
#   seq    — one task, sequential attempts (production ODEPE shape: HC is called
#            from a single task; concurrency comes from HC's internal
#            threaded_solve and from the Julia runtime's GC/compile threads).
#   fanout — NW worker tasks via Threads.@spawn pulling attempts off an atomic
#            counter; each worker builds & solves its own systems concurrently
#            (max race surface: concurrent toplevel eval, concurrent compile of
#            fresh CompiledSystems, concurrent MixedSubdivisions meters).
#
# HC-internal threading per solve: on|off (solve(; threading = ...)).
# NOTE set_default_compile(:all) matches ODEPE (homotopy_continuation.jl:415).
#
# Usage:
#   julia --startup-file=no -t <N> attempt.jl <mode> <hcthr> <nworkers> <nsolves> <seed_base> <shape>
#     mode     = seq | fanout
#     hcthr    = on | off
#     nworkers = worker task count (ignored for seq)
#     shape    = mix | NxD (e.g. 10x2) | sN (sparse, e.g. s12) | capdir:<dir>
#
# In-process looping is deliberate: it amortizes HC's ~35 s first-call JIT and
# mirrors production (one long-lived process, many solves, hangs on one). The
# external driver enforces a hard `timeout` + a log-mtime watchdog, so a hung
# attempt cannot wedge the session.

using HomotopyContinuation
const HC = HomotopyContinuation
using Random, Printf, Dates

# Let the watchdog's gdb ptrace-attach us (kernel.yama.ptrace_scope=1):
try
    ccall(:prctl, Cint, (Cint, Culong, Culong, Culong, Culong),
          0x59616d61, typemax(Culong), 0, 0, 0)  # PR_SET_PTRACER, PR_SET_PTRACER_ANY
catch
end

HC.set_default_compile(:all)   # match ODEPE production

# ---------------------------------------------------------------- system gen --
# Emit variable names + polynomial strings (everything downstream goes through
# the parse/eval path, like ODEPE's convert_to_hc_format).

function dense_strings(n::Int, d::Int, rng)
    vars = ["x$i" for i in 1:n]
    monos = String[]
    expo = zeros(Int, n)
    function rec(k, remaining)
        if k > n
            s = join(["$(vars[i])^$(expo[i])" for i in 1:n if expo[i] > 0], "*")
            push!(monos, isempty(s) ? "1" : s)
            return
        end
        for e in 0:remaining
            expo[k] = e
            rec(k + 1, remaining - e)
        end
        expo[k] = 0
    end
    rec(1, d)
    polys = [join(["($(@sprintf("%.17g", randn(rng))))*$m" for m in monos], " + ") for _ in 1:n]
    return vars, polys
end

# Sparse: n vars, each poly = constant + all linear terms + `extra` random
# monomials of total degree in 2:dmax. Long mixed-cells enumeration relative to
# path count — stresses the fine_mixed_cells phase.
function sparse_strings(n::Int, rng; extra::Int = 6, dmax::Int = 3)
    vars = ["x$i" for i in 1:n]
    polys = String[]
    for _ in 1:n
        terms = String["($(@sprintf("%.17g", randn(rng))))"]
        for v in vars
            push!(terms, "($(@sprintf("%.17g", randn(rng))))*$v")
        end
        for _ in 1:extra
            d = rand(rng, 2:dmax)
            idx = rand(rng, 1:n, d)
            push!(terms, "($(@sprintf("%.17g", randn(rng))))*" *
                         join(["$(vars[i])" for i in idx], "*"))
        end
        push!(polys, join(terms, " + "))
    end
    return vars, polys
end

# Rebuild an HC.System from strings in a fresh Module (per attempt), mirroring
# ODEPE's `eval.(Meta.parse.(string_target))` + System(parsed; variables=...).
function build_system(vars::Vector{String}, polys::Vector{String})
    m = Module()
    Core.eval(m, :(using HomotopyContinuation))
    Core.eval(m, Meta.parse("HomotopyContinuation.@var " * join(vars, " ")))
    parsed = HC.ModelKit.Expression[Core.eval(m, Meta.parse(p)) for p in polys]
    hc_vars = [Core.eval(m, Meta.parse(v)) for v in vars]
    return HC.System(parsed, variables = hc_vars)
end

# Captured-system mode: each .jl file in the dir defines `system` (pure HC).
function load_captured(dir::String)
    files = sort(filter(f -> endswith(f, ".jl"), readdir(dir; join = true)))
    isempty(files) && error("no captured .jl systems in $dir")
    return files
end

# ------------------------------------------------------------------- driver --
mode      = length(ARGS) >= 1 ? ARGS[1] : "seq"
hcthr     = (length(ARGS) >= 2 ? ARGS[2] : "on") == "on"
nworkers  = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 4
nsolves   = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 40
seed_base = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 0
shapearg  = length(ARGS) >= 6 ? ARGS[6] : "mix"

const SHAPES_MIX = [(8, 2), (10, 2), (9, 2), (7, 3), (11, 2), (6, 3)]

capfiles = String[]
shapes = SHAPES_MIX
sparse_n = 0
if shapearg == "mix"
    # default
elseif (m = match(r"^(\d+)x(\d+)$", shapearg)) !== nothing
    shapes = [(parse(Int, m.captures[1]), parse(Int, m.captures[2]))]
elseif (m = match(r"^s(\d+)$", shapearg)) !== nothing
    sparse_n = parse(Int, m.captures[1])
elseif startswith(shapearg, "capdir:")
    capfiles = load_captured(String(split(shapearg, ":"; limit = 2)[2]))
else
    error("bad shape $shapearg")
end

@printf("HUNT2 start mode=%s hcthr=%s nworkers=%d nthreads=%d ngcthreads=%d nsolves=%d seed_base=%d shape=%s pid=%d julia=%s HC=2.20.0 %s\n",
        mode, hcthr ? "on" : "off", nworkers, Threads.nthreads(),
        Threads.ngcthreads(), nsolves, seed_base, shapearg, getpid(),
        string(VERSION), now())
flush(stdout)

function one_attempt(i::Int, w::Int)
    seed = seed_base + i
    rng = MersenneTwister(seed)
    local desc, F
    if !isempty(capfiles)
        f = capfiles[(i - 1) % length(capfiles) + 1]
        desc = basename(f)
        @printf("ATTEMPT %d W%d START cap=%s %s\n", i, w, desc, now()); flush(stdout)
        mm = Module()
        Core.eval(mm, :(Base.include($mm, $f)))
        F = Core.eval(mm, :system)
    elseif sparse_n > 0
        desc = "s$(sparse_n)"
        @printf("ATTEMPT %d W%d START %s seed=%d %s\n", i, w, desc, seed, now()); flush(stdout)
        vars, polys = sparse_strings(sparse_n, rng)
        F = build_system(vars, polys)
    else
        (n, d) = shapes[(i - 1) % length(shapes) + 1]
        desc = "$(n)x$(d)"
        @printf("ATTEMPT %d W%d START %s seed=%d %s\n", i, w, desc, seed, now()); flush(stdout)
        vars, polys = dense_strings(n, d, rng)
        F = build_system(vars, polys)
    end
    @printf("ATTEMPT %d W%d SOLVE %s %s\n", i, w, desc, now()); flush(stdout)
    t0 = time()
    r = HC.solve(F; threading = hcthr, show_progress = false)
    el = time() - t0
    @printf("ATTEMPT %d W%d DONE %s seed=%d nsol=%d %.2fs %s\n",
            i, w, desc, seed, HC.nsolutions(r), el, now())
    flush(stdout)
end

if mode == "seq"
    for i in 1:nsolves
        try
            one_attempt(i, 0)
        catch err
            @printf("ATTEMPT %d W0 ERROR %s %s\n", i, sprint(showerror, err)[1:min(end, 200)], now())
            flush(stdout)
        end
    end
elseif mode == "fanout"
    next = Threads.Atomic{Int}(1)
    @sync for w in 1:nworkers
        Threads.@spawn begin
            while true
                i = Threads.atomic_add!(next, 1)
                i > nsolves && break
                try
                    one_attempt(i, w)
                catch err
                    @printf("ATTEMPT %d W%d ERROR %s %s\n", i, w,
                            sprint(showerror, err)[1:min(end, 200)], now())
                    flush(stdout)
                end
            end
        end
    end
else
    error("bad mode $mode")
end

@printf("HUNT2 complete %s\n", now())
flush(stdout)
