# hunt.jl — pure HomotopyContinuation.jl threading-deadlock hunter.
#
# Loads ONLY HomotopyContinuation, then solves many random dense polynomial
# systems with threading=true, flushing a START/DONE heartbeat around EACH
# solve. A hang leaves a trailing "START" with no matching "DONE"; an external
# watchdog (drive.sh) detects the stalled log and dumps backtraces before kill.
#
# Usage: julia --startup-file=no -t <threads> hunt.jl <nsolves> <seed_base> [shape]
#   shape (optional): "mix" (default), or "NxD" e.g. "10x2" to pin one shape.
#
# NOTE: looping in-process is deliberate here — it (a) amortizes HC's ~35 s
# first-call JIT across many solves and (b) mirrors production, where ODEPE
# issues many solve() calls in one long-lived process and hangs on one. The
# per-solve flush means a watchdog kill loses no information.

using HomotopyContinuation
const HC = HomotopyContinuation
using Random, Printf, Dates

# Let the watchdog's gdb ptrace-attach us for backtrace capture even under
# kernel.yama.ptrace_scope=1 (PR_SET_PTRACER=0x59616d61, PR_SET_PTRACER_ANY=-1).
try
    ccall(:prctl, Cint, (Cint, Culong, Culong, Culong, Culong),
          0x59616d61, typemax(Culong), 0, 0, 0)
catch
end

# Dense square system: n polys in n vars, each a dense combo of all monomials
# of total degree <= d with random real coefficients. Forces a non-trivial
# polyhedral ("Computing mixed cells") start — the reported hang location.
function dense_system(n::Int, d::Int, seed::Int)
    rng = MersenneTwister(seed)
    HC.@var x[1:n]
    monos = HC.Expression[]
    function rec(prefix, remaining, k)
        if k == n
            push!(monos, prod(x[i]^prefix[i] for i in 1:n))
            return
        end
        for e in 0:remaining
            rec(vcat(prefix, e), remaining - e, k + 1)
        end
    end
    rec(Int[], d, 0)
    polys = [sum(randn(rng) * m for m in monos) for _ in 1:n]
    return HC.System(polys, variables = collect(x))
end

nsolves   = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 40
seed_base = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 0
shapearg  = length(ARGS) >= 3 ? ARGS[3] : "mix"

# Shape rotation: small-to-moderate so a healthy solve stays well under the
# watchdog's stall threshold, but with hundreds-to-thousands of paths so the
# threaded tracker/mixed-cells stages get a real workout.
shapes = if shapearg == "mix"
    [(8, 2), (10, 2), (9, 2), (7, 3), (11, 2), (6, 3)]
else
    m = match(r"^(\d+)x(\d+)$", shapearg)
    m === nothing && error("bad shape $shapearg")
    [(parse(Int, m.captures[1]), parse(Int, m.captures[2]))]
end

@printf("HUNT start  nthreads=%d  nsolves=%d  seed_base=%d  shape=%s  pid=%d  %s\n",
        Threads.nthreads(), nsolves, seed_base, shapearg, getpid(), now())
flush(stdout)

for i in 1:nsolves
    (n, d) = shapes[(i - 1) % length(shapes) + 1]
    seed = seed_base + i
    F = dense_system(n, d, seed)
    @printf("ATTEMPT %d START n=%d d=%d seed=%d neq=%d %s\n",
            i, n, d, seed, length(F.expressions), now())
    flush(stdout)
    t0 = time()
    r = HC.solve(F; threading = true, show_progress = false)
    el = time() - t0
    @printf("ATTEMPT %d DONE  n=%d d=%d seed=%d nsol=%d  %.2fs  %s\n",
            i, n, d, seed, HC.nsolutions(r), el, now())
    flush(stdout)
end

@printf("HUNT complete  %s\n", now())
flush(stdout)
