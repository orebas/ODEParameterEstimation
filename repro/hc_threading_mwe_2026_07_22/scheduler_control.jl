# scheduler_control.jl — pure-Julia DISCRIMINATOR (no HomotopyContinuation).
#
# Reproduces the concurrency SHAPE of HC solves without any HC code:
# per "attempt": a fresh Module + toplevel eval (world-age churn), then a
# @sync burst of nthreads @spawn tasks doing allocation-heavy work (GC churn),
# like threaded_solve's per-solve task burst. Same heartbeat protocol as
# attempt.jl so driver3.sh can watchdog it.
#
# If THIS hangs on the box, the deadlock is below HC (Julia runtime /
# scheduler / GC / WSL2) — the key discriminator for the upstream report.
#
# Usage: julia --startup-file=no -t <N> scheduler_control.jl <mode> <hcthr> <nworkers> <nsolves> <seed_base> <shape>
#   (interface matches attempt.jl; mode/hcthr/shape accepted but only
#    nworkers/nsolves/seed_base matter: mode=seq -> 1 outer task)

using Random, Printf, Dates

try
    ccall(:prctl, Cint, (Cint, Culong, Culong, Culong, Culong),
          0x59616d61, typemax(Culong), 0, 0, 0)
catch
end

mode      = length(ARGS) >= 1 ? ARGS[1] : "seq"
nworkers  = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 1
nsolves   = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 200
seed_base = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 0

@printf("HUNT2 start mode=%s SCHEDCTL nworkers=%d nthreads=%d ngcthreads=%d nsolves=%d seed_base=%d pid=%d julia=%s %s\n",
        mode, nworkers, Threads.nthreads(), Threads.ngcthreads(),
        nsolves, seed_base, getpid(), string(VERSION), now())
flush(stdout)

function one_attempt(i::Int, w::Int)
    seed = seed_base + i
    rng = MersenneTwister(seed)
    @printf("ATTEMPT %d W%d START sched seed=%d %s\n", i, w, seed, now()); flush(stdout)
    # world-age churn: fresh module + toplevel eval (like per-attempt `using`/parse/eval)
    m = Module()
    Core.eval(m, :(f(x) = x + $i))
    Core.eval(m, :(f(1.5)))
    @printf("ATTEMPT %d W%d SOLVE sched %s\n", i, w, now()); flush(stdout)
    t0 = time()
    # task burst + GC churn, ~0.1-1 s of work
    nt = Threads.nthreads()
    results = Vector{Float64}(undef, nt)
    @sync for t in 1:nt
        Threads.@spawn begin
            acc = 0.0
            for r in 1:60
                A = randn(rng isa MersenneTwister ? MersenneTwister(seed * 1000 + t * 100 + r) : rng, 40, 40)
                acc += sum(abs2, A * A')
                r % 7 == 0 && yield()
            end
            results[t] = acc
        end
    end
    el = time() - t0
    @printf("ATTEMPT %d W%d DONE sched seed=%d nsol=%d %.2fs %s\n",
            i, w, seed, length(results), el, now())
    flush(stdout)
end

if mode == "seq"
    for i in 1:nsolves
        one_attempt(i, 0)
    end
else
    next = Threads.Atomic{Int}(1)
    @sync for w in 1:nworkers
        Threads.@spawn begin
            while true
                i = Threads.atomic_add!(next, 1)
                i > nsolves && break
                one_attempt(i, w)
            end
        end
    end
end

@printf("HUNT2 complete %s\n", now())
flush(stdout)
