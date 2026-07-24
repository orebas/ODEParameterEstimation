#!/usr/bin/env julia

# Bounded microbenchmark for HomotopyContinuation's per-call `compile` policy.
#
# Run each mode in a fresh Julia process so compiled evaluator state from one
# mode cannot warm another:
#
#   julia --startup-file=no -t 1 investigation/benchmark_hc_compile_modes.jl \
#       captured_systems/sum_test_000_neq18_nvar18.jl all 3

using HomotopyContinuation
using Printf

length(ARGS) >= 2 || error(
    "usage: benchmark_hc_compile_modes.jl CAPTURED_SYSTEM (all|mixed|none) [REPEATS]",
)

capture_path = abspath(ARGS[1])
compile_mode = Symbol(ARGS[2])
repeats = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 3

compile_mode in (:all, :mixed, :none) || error("unsupported compile mode: $compile_mode")
repeats > 0 || error("REPEATS must be positive")
isfile(capture_path) || error("captured system does not exist: $capture_path")

module_started = time_ns()
capture_module = Module(:ODEPECompileModeProbe)
Core.eval(capture_module, :(using HomotopyContinuation))
Base.include(capture_module, capture_path)
system = Core.eval(capture_module, :system)
setup_seconds = (time_ns() - module_started) / 1.0e9

println(
    "schema\tjulia\thc\tthreads\tcompile\tcapture\tsetup_seconds\trepeat\twall_seconds\tmaxrss_bytes\tnsolutions",
)
flush(stdout)

for repeat_index in 1:repeats
    GC.gc()
    started = time_ns()
    result = HomotopyContinuation.solve(
        system;
        compile = compile_mode,
        threading = false,
        show_progress = false,
    )
    wall_seconds = (time_ns() - started) / 1.0e9
    nsolutions = length(
        HomotopyContinuation.solutions(result; only_nonsingular = false),
    )
    @printf(
        "odepe-hc-compile-v1\t%s\t%s\t%d\t%s\t%s\t%.9f\t%d\t%.9f\t%d\t%d\n",
        VERSION,
        pkgversion(HomotopyContinuation),
        Threads.nthreads(),
        compile_mode,
        basename(capture_path),
        setup_seconds,
        repeat_index,
        wall_seconds,
        Sys.maxrss(),
        nsolutions,
    )
    flush(stdout)
end
