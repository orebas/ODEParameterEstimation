# MWE — data race in HomotopyContinuation.jl's global compiled-system cache.
#
# HomotopyContinuation 2.20.0, src/model_kit/compiled_system_homotopy.jl:
#     const TSYSTEM_TABLE   = Dict{UInt,Vector{System}}()     # line 1
#     const THOMOTOPY_TABLE = Dict{UInt,Vector{Homotopy}}()   # line 86
# Every CompiledSystem / CompiledHomotopy construction mutates these plain
# Dicts with NO lock (haskey / push! / setindex!, lines 41-56 & 128-142), and
# `interpret` reads them during evaluation (lines 67, 159). Every
# `solve(...; compile = :all)` — and the first solve of any new system under
# the default :mixed — goes through this code. Base.Dict is not thread-safe:
# concurrent insert (which can trigger rehash) vs. probe corrupts the table.
#
# Consequences observed with this MWE on Julia 1.12.6:
#   * LOST ENTRIES: constructions whose table entry vanishes. Their
#     CompiledSystem{(h,k)} is a delayed bomb — `interpret` later throws
#     KeyError, or silently uses a wrong system after the slot is reused.
#   * SPURIOUS BUCKET MERGES: nbuckets < nentries even though all hashes are
#     distinct single-worker (control shows 0 natural collisions).
#   * With more workers/iterations: KeyError from inside CompiledSystem, and
#     (rarely) a corrupted-Dict probe loop -> a spin with no GC safepoint ->
#     the next stop-the-world freezes the whole process. This matches
#     nondeterministic multi-thread solve() freezes reported in #594/#668/#702
#     (last painted line is whatever progress meter was active, e.g.
#     "Computing mixed cells...").
#
# Run:  julia --startup-file=no -t 8 mwe_tsystem_race.jl
# PASS = "OK": nentries == N total constructions (this is what -t 1 gives).
# FAIL = "RACE DETECTED": entries lost / spurious collisions / KeyError.

using HomotopyContinuation
const MK = HomotopyContinuation.ModelKit
using Random, Printf

const NW = max(2, Threads.nthreads() - 2)   # worker tasks
const N  = 30_000                            # constructions per worker

MK.@var x y z

function worker(w, errs)
    rng = MersenneTwister(w)
    for i in 1:N
        a, b = randn(rng), randn(rng)
        F = MK.System([a * x^2 + b * y - 1, b * x * y + a * z^2 + 2, z * y - a],
                      variables = [x, y, z])
        try
            CS = MK.CompiledSystem(F)
            MK.interpret(CS)                 # read path
        catch err
            Threads.atomic_add!(errs, 1)
            @printf("worker %d iter %d: %s\n", w, i, sprint(showerror, err))
        end
    end
end

errs = Threads.Atomic{Int}(0)
@sync for w in 1:NW
    Threads.@spawn worker(w, errs)
end

total    = NW * N
nbuckets = length(MK.TSYSTEM_TABLE)
nentries = sum(length(v) for v in values(MK.TSYSTEM_TABLE); init = 0)
lost     = total - nentries
spurious = nentries - nbuckets

@printf("threads=%d workers=%d constructions=%d\n", Threads.nthreads(), NW, total)
@printf("table buckets=%d entries=%d lost=%d spurious_collisions=%d errors=%d\n",
        nbuckets, nentries, lost, spurious, errs[])
if lost == 0 && spurious == 0 && errs[] == 0
    println("OK — no race observed this run (try more threads / rerun; single-threaded control is always exact)")
else
    println("RACE DETECTED — unlocked global TSYSTEM_TABLE was corrupted by concurrent CompiledSystem construction")
end
