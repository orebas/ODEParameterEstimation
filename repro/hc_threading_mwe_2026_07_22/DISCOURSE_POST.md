# ⛔ SUPERSEDED — DO NOT POST (2026-07-23)

> This draft's central claims failed adversarial re-verification — see
> [`ADJUDICATION_2026-07-23.md`](ADJUDICATION_2026-07-23.md). Specifically: the solve
> path compiles per-**support** (coefficient changes reuse the compiled type; measured),
> `jl_as_global_root` writes are locked in 1.12.6 (the described race mechanism is wrong
> against the source), and the typeinst campaign was confounded (work scaled with thread
> count on a loaded box; retained dumps show progress-until-kill), and the deconfounded
> fixed-work re-run completed 10/10 with zero hangs/segfaults — healthy runtime of the
> `-t 14` workload is ≈260s on an idle box, above the original 180s kill threshold, so
> every "HANG" row was a timeout artifact. What survives and
> should be filed **separately, without any hang narrative**: the unlocked
> `TSYSTEM_TABLE`/`THOMOTOPY_TABLE` race (reproduced by two independent parties) — with
> the MWE's read-path probe fixed to `interpret(typeof(CS))` first. A rewrite will
> follow the deconfounded campaign.

# Multithreaded hang/segfault in `apply_type` (global-roots idset) on 1.12.6 & 1.11.5 — surfaced via HomotopyContinuation

*(Draft for Julia Discourse / a Julia issue. Environment-specific; please run the MWE on your own box and report `-t` + outcome.)*

## TL;DR

Instantiating parametric types with **fresh bit-pattern tuple parameters** (`Foo{(rand(UInt), k)}`) concurrently from many threads intermittently **hangs or segfaults** the Julia runtime, with a clean monotone thread-count gradient: fine at ≤4 threads, near-certain at 14. It reproduces in **30 lines, standard library only**, on **both 1.11.5 and 1.12.6**. The crash path is

```
ijl_apply_type → inst_datatype_inner → jl_as_global_root → jl_smallintset_lookup → idset_eq
```

which matches the *closed* issue [#58171](https://github.com/JuliaLang/julia/issues/58171) — suggesting PR #57392 did **not** fully close the concurrent global-roots path. It reached me as the long-standing intermittent `HomotopyContinuation.solve` freeze ([HC #702](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/702), [#594](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/594)), because HomotopyContinuation mints a fresh `CompiledSystem{(h,k)}` type on **every** solve.

## Environment

| | |
|---|---|
| Julia | 1.12.6 (also reproduced on 1.11.5) |
| CPU / OS | 14-core AMD Ryzen, Linux (WSL2) |
| HomotopyContinuation | 2.20.0 |
| MixedSubdivisions | 1.2.0 |

## Minimal reproducer — no dependencies

```julia
# typeinst_control.jl
# Concurrent instantiation of parametric types with fresh (UInt,Int) tuple params.
using Random, Printf

struct Foo{T} end

const NW = max(2, Threads.nthreads() - 2)
const N  = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 150_000

@printf("threads=%d workers=%d iters=%d julia=%s\n",
        Threads.nthreads(), NW, N, string(VERSION)); flush(stdout)

function worker(w)
    rng = MersenneTwister(w)
    acc = 0
    for i in 1:N
        h = rand(rng, UInt)      # fresh random bits, like hash(exprs)
        k = i % 8 + 1
        T = Foo{(h, k)}          # ijl_apply_type with a fresh bits-tuple parameter
        acc += sizeof(typeof(T))
        i % 50_000 == 0 && (@printf("worker %d tick %d\n", w, i); flush(stdout))
    end
    acc
end

@sync for w in 1:NW
    Threads.@spawn worker(w)
end
println("OK — $(NW * N) concurrent fresh-tuple type instantiations, no crash")
```

Run it (a few seconds of work when healthy):

```
julia --startup-file=no -t 14 typeinst_control.jl
```

### Outcomes (each cell = one run; HANG = not finished at a 180 s kill)

| Julia  | `-t` | run 1 | run 2 | run 3 |
|--------|------|-------|-------|-------|
| 1.12.6 | 14   | HANG  | HANG  | **SEGFAULT** |
| 1.12.6 | 14   | HANG  | HANG  | HANG  *(independent re-run)* |
| 1.12.6 | 8    | HANG  | OK    | HANG  |
| 1.12.6 | 4    | OK    | OK    | OK    |
| 1.12.6 | 2    | OK    | OK    | —     |
| 1.11.5 | 14   | HANG  | HANG  | HANG  |

A live hang sampled with gdb showed 11 threads in state R (spinning), 1 D, 24 S — i.e. active spin with no forward progress on a seconds-long workload.

### Segfault backtrace

```
ijl_apply_type            jltypes.c:1469
inst_datatype_inner       jltypes.c:2275
jl_as_global_root         staticdata.c:2975
jl_idset_get              idset.c:40
jl_smallintset_lookup     smallintset.c:137
idset_eq                  idset.c:15        # <-- crash while probing a corrupted chain
```

When it hangs instead of crashing, the same probe loop appears to spin forever — and because a spinning thread never reaches a GC safepoint, the next stop-the-world collection freezes every other thread too.

## Where it comes from in practice (HomotopyContinuation)

HC compiles each polynomial system to native code and encodes the system’s identity in the **type parameter**:

```julia
# HomotopyContinuation 2.20.0, src/model_kit/compiled_system_homotopy.jl
return CompiledSystem{(h, k)}(n, nvars, nparams, F)   # h = hash(cleared exprs), k = table index
```

With `set_default_compile(:all)` and `threading=true` (both the norm for our workload), and because the fitted **coefficients remain in the hashed expressions**, every solve produces a new `(h,k)` → a type Julia has never seen → all N tracker tasks demand its compilation at once. That produces a **compilation convoy** (gdb of a real frozen, *sequential* solve: 12 threads waiting on `jl_typeinf_lock`, one inside `llvm::slpvectorizer::BoUpSLP::getSpillCost`), and the same storm of fresh-type creation is what trips the `apply_type`/idset race above.

## Two HomotopyContinuation-side issues found alongside (for the HC maintainers)

1. **Unlocked global caches.** `TSYSTEM_TABLE` and `THOMOTOPY_TABLE` (`compiled_system_homotopy.jl:1` and `:86`) are plain `Dict`s mutated (`haskey`/`push!`/`setindex!`) with no lock, and read by `interpret`. Under concurrent construction (12 workers × 60 000, `-t 14`) this silently drops **0.6–2.8 % of entries** and occasionally segfaults. A `ReentrantLock` around the tables is a ~5-line fix.
2. **Cache never hits for coefficient-varying systems**, so the per-system compile is paid on every solve. Compiling the `CompiledSystem` evaluator once on the setup task *before* spawning tracker tasks would serialise the unavoidable compile onto one thread instead of an N-way `jl_typeinf_lock` pile-up.

## Ruled out (so nobody re-chases these)

- **MixedSubdivisions** — grep of 1.1.5 and 1.2.0 shows *zero* threading primitives. The “Computing mixed cells…” line is just an always-on progress meter that happens to be last-painted when the process freezes elsewhere. Not the cause.
- **#59538** (1.12 startup scheduler deadlock) — real, but fixed by PR #59583 and shipped in 1.12.1+; we’re on 1.12.6.
- **HC `threadid()` (#668)** — fixed by HC PR #669; absent from the 2.20 solve path.

## Questions for the community / core

1. Is the concurrent `apply_type` → global-roots idset race tracked anywhere beyond the closed #58171? Should #58171 be reopened given a clean stdlib-only 1.12.6 reproducer?
2. Is there a supported way to make concurrent parametric-type instantiation safe (a lock we should be hitting, or a runtime flag), or is per-thread type-cache interning simply expected to be race-free and this is a genuine regression surface?
3. For the HC maintainers: would you accept (a) a lock around the compiled-system tables and (b) a pre-spawn warm-compile, and is the fresh-`{(h,k)}`-type-per-system design open to revisiting?

Happy to share the full harness (≈18,600 solves across threading/shape/thread-count arms), gdb/`/proc` captures, and the HC-level reproducer.
