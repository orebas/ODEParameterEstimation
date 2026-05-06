# Structural identifiability of forced_lv at the SI.jl level.
# We model sin(2t) as an extra state with its own ODE.

using ODEParameterEstimation
using StructuralIdentifiability

println("="^72)
println("SI of forced_lotka_volterra (sin-forced, 2-state)")
println("="^72)

si_ode = StructuralIdentifiability.@ODEmodel(
    x'(t)         = (-0.3*sin_term(t) + 6.0*alpha*x(t) - 8.0*beta*x(t)*yv(t)) / 2.0,
    yv'(t)        = (-12.0*gamma*yv(t) + 4.0*delta*x(t)*yv(t)) / 2.0,
    sin_term'(t)  = 2.0*cos_term(t),
    cos_term'(t)  = -2.0*sin_term(t),
    y1(t)         = 2.0*x(t),
    y2(t)         = 2.0*yv(t)
)

println("\n--- assess_local_identifiability ---")
local_id = StructuralIdentifiability.assess_local_identifiability(si_ode)
println(local_id)

println("\n--- assess_identifiability (global) — may be slow ---")
try
    global_id = StructuralIdentifiability.assess_identifiability(si_ode)
    println(global_id)
catch e
    println("Global identifiability check failed: $e")
end

println("\n--- find_identifiable_functions(with_states=true) ---")
try
    ident_fns = StructuralIdentifiability.find_identifiable_functions(si_ode; with_states = true)
    for f in ident_fns
        println("  ", f)
    end
catch e
    println("find_identifiable_functions failed: $e")
end

println("\nFORCED_LV_SI_DONE")
