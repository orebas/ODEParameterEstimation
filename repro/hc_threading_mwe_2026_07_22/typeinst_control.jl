# typeinst_control.jl — HC-free DISCRIMINATOR for the CompiledSystem segfault.
#
# The ts14 crash was:
#   jl_egal_/idset_eq/jl_smallintset_lookup/jl_idset_get
#   jl_as_global_root (staticdata.c) <- inst_datatype_inner <- ijl_apply_type
#   CompiledSystem{(h,k)}  (compiled_system_homotopy.jl:57)
# i.e. a segfault while instantiating a parametric type whose parameter is a
# fresh (UInt, Int) tuple, from 12 concurrent tasks. This script does EXACTLY
# that type-instantiation pattern with no HomotopyContinuation at all.
#   - If THIS segfaults: Julia-runtime bug (concurrent ijl_apply_type /
#     global-roots idset) -> report to JuliaLang with this 30-liner.
#   - If it survives far more instantiations than the HC crash needed: the HC
#     crash was memory corruption from HC's unlocked TSYSTEM_TABLE Dict.
#
# Usage: julia --startup-file=no -t <N> typeinst_control.jl [iters_per_worker]

using Random, Printf

struct Foo{T} end

const NW = max(2, Threads.nthreads() - 2)
const N  = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 300_000

@printf("typeinst control: threads=%d workers=%d iters=%d julia=%s\n",
        Threads.nthreads(), NW, N, string(VERSION))
flush(stdout)

function worker(w)
    rng = MersenneTwister(w)
    acc = 0
    for i in 1:N
        h = rand(rng, UInt)          # fresh random UInt, like hash(cleard_exprs)
        k = i % 8 + 1
        T = Foo{(h, k)}              # ijl_apply_type with fresh bits-tuple param
        acc += sizeof(typeof(T))
        if i % 50_000 == 0
            @printf("worker %d tick %d\n", w, i); flush(stdout)
        end
    end
    acc
end

@sync for w in 1:NW
    Threads.@spawn worker(w)
end

println("OK — $(NW * N) concurrent fresh-tuple type instantiations, no crash")
