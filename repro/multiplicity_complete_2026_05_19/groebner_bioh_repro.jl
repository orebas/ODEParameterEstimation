### Minimal reproducer for a Groebner.jl crash on the biohydrogenation
### benchmark ODE system (4-state Michaelis-Menten chain).
###
### The polynomial system is the output of SIAN-Julia's
### identifiability_ode pipeline at SIAN.jl:267 — i.e., the Et_hat
### polynomial system with the Rabinowitsch saturation z_aux*Q_hat - 1.
### Other systems we tested (lotka_volterra, daisy_mamil4, seir, etc.)
### all return correctly; biohydrogenation specifically hits an internal
### BoundsError in Groebner.jl's parallel-worker multimodular path.
###
### Versions:
###   Julia 1.12.x
###   Groebner.jl 0.10.3 (latest as of 2026-05-20)
###   Nemo.jl (latest)
###
### Inner exception (paraphrased from full stacktrace):
###   nested task error: BoundsError: attempt to access 4-element Vector{Int32} at index [5]
###   in `_process_chunk` at Groebner/groebner.jl:210
###   called from `_groebner_learn_and_apply##8#9` at line 286
###
### Run: julia --startup-file=no groebner_bioh_repro.jl

using Nemo
using Groebner
using Serialization

println("Versions:")
println("  Julia    ", VERSION)
println("  Nemo     ", pkgversion(Nemo))
println("  Groebner ", pkgversion(Groebner))
println()

# Load the polynomial system from the dump.
dump_path = joinpath(@__DIR__, "bioh_gb_input.bin")
isfile(dump_path) || error("Missing dump at $dump_path; run test_patched_sian.jl first")

(polys, var_names) = open(deserialize, dump_path)

println("Loaded polynomial system:")
println("  $(length(polys)) polynomials")
println("  $(length(var_names)) variables")
println("  ring vars: ", join(var_names, ", "))
println()

# Default Groebner path — this is what crashes:
println("Calling Groebner.groebner(polys)... (default path, multi-task multimodular)")
gb = try
    Groebner.groebner(polys)
catch err
    println("\n*** CRASHED ***")
    println("Error type: ", typeof(err))
    if err isa TaskFailedException
        println("Inner exception type: ", typeof(err.task.exception))
        println("Inner exception:      ", err.task.exception)
    else
        println("Message: ", sprint(showerror, err))
    end
    println()
    nothing
end

if gb === nothing
    println("Default Groebner.groebner failed. Trying single-task fallback...")
    try
        gb = Groebner.groebner(polys; tasks=1)
        println("  tasks=1 succeeded — $(length(gb)) basis polys.")
        println("  quotient_basis dim = $(length(Groebner.quotient_basis(gb)))")
    catch err2
        println("  tasks=1 also failed: ", typeof(err2))
    end
end

println()
println("DONE")
