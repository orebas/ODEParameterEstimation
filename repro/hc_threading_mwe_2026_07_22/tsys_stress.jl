# tsys_stress.jl — targeted stress of HC ModelKit's UNLOCKED global caches.
#
# HomotopyContinuation 2.20.0, src/model_kit/compiled_system_homotopy.jl:
#   line 1 : const TSYSTEM_TABLE   = Dict{UInt,Vector{System}}()    (no lock!)
#   line 86: const THOMOTOPY_TABLE = Dict{UInt,Vector{Homotopy}}()  (no lock!)
# Both are MUTATED (haskey / push! / setindex!) by every CompiledSystem /
# CompiledHomotopy construction — i.e. by every `solve` that compiles — and READ
# by `interpret` during evaluation. Base.Dict is not thread-safe: concurrent
# insert (rehash!) vs probe corrupts the table -> wrong results, KeyError,
# segfault, or an unbounded probe loop. A probe loop performs no allocation, so
# it never reaches a GC safepoint: the next stop-the-world then freezes EVERY
# thread permanently — a whole-process deadlock whose last painted output is
# whatever progress meter was on screen (e.g. "Computing mixed cells...").
#
# This script constructs CompiledSystem objects from many workers concurrently
# (distinct random coefficients -> distinct hashes -> continuous inserts and
# periodic rehashes). Any thrown Dict/KeyError/BoundsError, a hang (watchdog),
# or a table-size mismatch at the end = caught it.
#
# Usage: julia --startup-file=no -t <N> tsys_stress.jl <mode> <hcthr> <nworkers> <nsolves> <seed_base> <shape>
#   (driver3-compatible: nsolves = iterations PER WORKER; mode/hcthr/shape ignored
#    except mode=seq forces 1 worker)

using HomotopyContinuation
const HC = HomotopyContinuation
const MK = HC.ModelKit
using Random, Printf, Dates

try
    ccall(:prctl, Cint, (Cint, Culong, Culong, Culong, Culong),
          0x59616d61, typemax(Culong), 0, 0, 0)
catch
end

mode      = length(ARGS) >= 1 ? ARGS[1] : "fanout"
nworkers  = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 8
iters     = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 20000
seed_base = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 0
mode == "seq" && (nworkers = 1)

@printf("HUNT2 start mode=%s TSYS-STRESS nworkers=%d nthreads=%d ngcthreads=%d iters_per_worker=%d seed_base=%d pid=%d julia=%s %s\n",
        mode, nworkers, Threads.nthreads(), Threads.ngcthreads(),
        iters, seed_base, getpid(), string(VERSION), now())
flush(stdout)

MK.@var x y z

# Tiny system, random coefficients -> distinct hash -> insert into TSYSTEM_TABLE.
# Every ~5th iteration reuses a shared coefficient (cache-hit path: probes the
# shared Vector while others push! to it).
function make_system(rng, i)
    a = i % 5 == 0 ? 1.0 : randn(rng)
    b = randn(rng)
    MK.System([a * x^2 + b * y - 1, b * x * y + a * z^2 + 2, z * y - a], variables = [x, y, z])
end

const errs = Threads.Atomic{Int}(0)

function worker(w::Int)
    rng = MersenneTwister(seed_base + w)
    @printf("ATTEMPT %d W%d START tsys %s\n", w, w, now()); flush(stdout)
    @printf("ATTEMPT %d W%d SOLVE tsys %s\n", w, w, now()); flush(stdout)
    t0 = time()
    for i in 1:iters
        try
            F = make_system(rng, i)
            CS = MK.CompiledSystem(F)
            # exercise the read path `interpret` too
            MK.interpret(CS)
        catch err
            Threads.atomic_add!(errs, 1)
            @printf("ATTEMPT %d W%d ERROR iter=%d %s %s\n", w, w, i,
                    sprint(showerror, err)[1:min(end, 300)], now())
            flush(stdout)
        end
        if i % 2000 == 0
            @printf("ATTEMPT %d W%d TICK %d table=%d %.1fs %s\n",
                    w, w, i, length(MK.TSYSTEM_TABLE), time() - t0, now())
            flush(stdout)
        end
    end
    @printf("ATTEMPT %d W%d DONE tsys nsol=%d %.2fs %s\n",
            w, w, iters, time() - t0, now())
    flush(stdout)
end

if nworkers == 1
    worker(1)
else
    @sync for w in 1:nworkers
        Threads.@spawn worker(w)
    end
end

# sanity: total table entries should equal total distinct systems inserted
nentries = sum(length(v) for v in values(MK.TSYSTEM_TABLE); init = 0)
@printf("TABLE nbuckets=%d nentries=%d errors=%d\n",
        length(MK.TSYSTEM_TABLE), nentries, errs[])
@printf("HUNT2 complete %s\n", now())
flush(stdout)
