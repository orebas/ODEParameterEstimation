# ptrack.jl — parameter-homotopy TRACKING hunter (pure HomotopyContinuation.jl).
#
# The production biohydrogenation deadlock (2026-06-05, DigitalOcean box,
# JULIA_NUM_THREADS=8) froze in a gamma-straight tracking fan-out:
#   solve(F, starts; start_parameters, target_parameters, gamma)
# None of the fresh-solve arms exercise that path (tracker.jl + homotopies +
# endgame), so this script does: per ATTEMPT it
#   (1) builds a PARAMETERIZED dense system via the parse/eval path,
#   (2) fresh-solves it at a generic complex p0 (polyhedral start),
#   (3) issues NTRACK gamma-straight track calls to random real targets
#       (mirrors ODEPE's per-shooting-point parameterized solves + gamma retries).
# Heartbeats bracket each track call so the watchdog can localize a hang.
#
# Usage: julia --startup-file=no -t <N> ptrack.jl <mode> <hcthr> <nworkers> <nsolves> <seed_base> <shape>
#   mode  = seq | fanout      hcthr = on | off      shape = NxD (default 6x2)
#   nsolves = number of ATTEMPTS (each attempt = 1 fresh solve + NTRACK tracks)

using HomotopyContinuation
const HC = HomotopyContinuation
using Random, Printf, Dates

try
    ccall(:prctl, Cint, (Cint, Culong, Culong, Culong, Culong),
          0x59616d61, typemax(Culong), 0, 0, 0)
catch
end

HC.set_default_compile(:all)

const NTRACK = 25

mode      = length(ARGS) >= 1 ? ARGS[1] : "seq"
hcthr     = (length(ARGS) >= 2 ? ARGS[2] : "on") == "on"
nworkers  = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 4
nsolves   = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 10
seed_base = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 0
shapearg  = length(ARGS) >= 6 ? ARGS[6] : "6x2"

m = match(r"^(\d+)x(\d+)$", shapearg)
m === nothing && error("bad shape $shapearg (need NxD)")
const NV = parse(Int, m.captures[1])
const DG = parse(Int, m.captures[2])

@printf("HUNT2 start mode=%s PTRACK hcthr=%s nworkers=%d nthreads=%d ngcthreads=%d nsolves=%d ntrack=%d seed_base=%d shape=%s pid=%d julia=%s %s\n",
        mode, hcthr ? "on" : "off", nworkers, Threads.nthreads(),
        Threads.ngcthreads(), nsolves, NTRACK, seed_base, shapearg, getpid(),
        string(VERSION), now())
flush(stdout)

# Parameterized dense system as strings: every monomial coefficient is a parameter.
function param_strings(n::Int, d::Int)
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
    nm = length(monos)
    params = ["c$(i)_$(j)" for i in 1:n, j in 1:nm]
    polys = [join(["c$(i)_$(j)*$(monos[j])" for j in 1:nm], " + ") for i in 1:n]
    return vars, vec(params), polys
end

function build_param_system(vars, params_flat, polys)
    mm = Module()
    Core.eval(mm, :(using HomotopyContinuation))
    Core.eval(mm, Meta.parse("HomotopyContinuation.@var " * join(vars, " ")))
    Core.eval(mm, Meta.parse("HomotopyContinuation.@var " * join(params_flat, " ")))
    parsed = HC.ModelKit.Expression[Core.eval(mm, Meta.parse(p)) for p in polys]
    hv = [Core.eval(mm, Meta.parse(v)) for v in vars]
    hp = [Core.eval(mm, Meta.parse(p)) for p in params_flat]
    return HC.System(parsed, variables = hv, parameters = hp)
end

function one_attempt(i::Int, w::Int)
    seed = seed_base + i
    rng = MersenneTwister(seed)
    @printf("ATTEMPT %d W%d START ptrack%s seed=%d %s\n", i, w, shapearg, seed, now()); flush(stdout)
    vars, params_flat, polys = param_strings(NV, DG)
    F = build_param_system(vars, params_flat, polys)
    np = length(params_flat)
    p0 = randn(rng, ComplexF64, np)
    @printf("ATTEMPT %d W%d SOLVE ptrack fresh %s\n", i, w, now()); flush(stdout)
    t0 = time()
    r0 = HC.solve(F; target_parameters = p0, threading = hcthr, show_progress = false)
    S = HC.solutions(r0; only_nonsingular = true)
    @printf("ATTEMPT %d W%d FRESH-DONE nsol=%d %.2fs %s\n", i, w, length(S), time() - t0, now()); flush(stdout)
    isempty(S) && begin
        @printf("ATTEMPT %d W%d DONE ptrack seed=%d nsol=0 0.00s %s\n", i, w, seed, now()); flush(stdout)
        return
    end
    for k in 1:NTRACK
        pt = ComplexF64.(randn(rng, np))
        γ = cis(2π * rand(rng))
        @printf("ATTEMPT %d W%d TRACK %d %s\n", i, w, k, now()); flush(stdout)
        tk = time()
        rk = HC.solve(F, S; start_parameters = p0, target_parameters = pt,
                      gamma = γ, threading = hcthr, show_progress = false)
        @printf("ATTEMPT %d W%d TRACKED %d nsol=%d %.2fs %s\n",
                i, w, k, HC.nsolutions(rk), time() - tk, now()); flush(stdout)
    end
    @printf("ATTEMPT %d W%d DONE ptrack seed=%d nsol=%d %.2fs %s\n",
            i, w, seed, length(S), time() - t0, now())
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
else
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
end

@printf("HUNT2 complete %s\n", now())
flush(stdout)
