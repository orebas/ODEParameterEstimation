### Test the SIAN-Julia patch: does identifiability_ode now expose
### `algebraic_multiplicity` in its result Dict, and does it work on
### biohydrogenation (the system that crashed in our standalone Path C
### test)?
###
### Three checks:
###   1. Simple system (lotka_volterra) → M=1 + Dict has key
###   2. Multiplicity-2 system (daisy_mamil4) → M=2
###   3. The known-problem system (biohydrogenation) → either M=2 or
###      crash, in which case we capture the failure for upstream repro.
###
### Run: julia --startup-file=no repro/multiplicity_complete_2026_05_19/test_patched_sian.jl

using SIAN
using Logging

println("=" ^ 60)
println("SIAN version: ", pkgversion(SIAN))
println("Loaded from:  ", pathof(SIAN))
println("=" ^ 60)

# --- check 1: lotka_volterra, should be M=1 ---
println("\n### Test 1: lotka_volterra (expected M=1) ###")
ode_lv = SIAN.@ODEmodel(
    w'(t) = -3//5 * k3 * w(t) + 4 * k2 * w(t) * r(t),
    r'(t) = 2 * k1 * r(t) - 2 * k2 * w(t) * r(t),
    y1(t) = 4 * r(t),
)
res_lv = SIAN.identifiability_ode(ode_lv, SIAN.get_parameters(ode_lv); infolevel=0)
println("  Result keys: ", sort(collect(keys(res_lv))))
println("  algebraic_multiplicity = ", get(res_lv, "algebraic_multiplicity", "MISSING"))

# --- check 2: daisy_mamil4, should be M=2 ---
println("\n### Test 2: daisy_mamil4 (expected M=2) ###")
ode_dm4 = SIAN.@ODEmodel(
    x1'(t) = (-1//10 * k01 * x1(t) + 4//10 * k12 * x2(t) + 9//10 * k13 * x3(t) + 16//10 * k14 * x4(t) - 5//10 * k21 * x1(t) - 6//10 * k31 * x1(t) - 7//10 * k41 * x1(t)) // (4//10),
    x4'(t) = (-16//10 * k14 * x4(t) + 7//10 * k41 * x1(t)) // (16//10),
    x2'(t) = (-4//10 * k12 * x2(t) + 5//10 * k21 * x1(t)) // (8//10),
    x3'(t) = (-9//10 * k13 * x3(t) + 6//10 * k31 * x1(t)) // (12//10),
    y1(t) = 4//10 * x1(t),
    y2(t) = 8//10 * x2(t),
    y3(t) = 12//10 * x3(t) + 16//10 * x4(t),
)
res_dm4 = SIAN.identifiability_ode(ode_dm4, SIAN.get_parameters(ode_dm4); infolevel=0)
println("  Result keys: ", sort(collect(keys(res_dm4))))
println("  algebraic_multiplicity = ", get(res_dm4, "algebraic_multiplicity", "MISSING"))

# --- check 3: biohydrogenation, expected M=2; key question is whether it crashes ---
println("\n### Test 3: biohydrogenation (expected M=2 IF Groebner survives) ###")
# Capture the polynomial system to a file before Groebner blows up.
ENV["SIAN_DUMP_GB_INPUT"] = joinpath(@__DIR__, "bioh_gb_input.jl")
# Floats from wallaby script converted to rationals.
# -0.3 → -3//10, 2.0 → 2, 0.5 → 1//2, 8.0 → 8, 4.0 → 4, 0.2 → 1//5, 10.0 → 10, 5.0 → 5
ode_bioh = SIAN.@ODEmodel(
    x5'(t) = ((-3//10 * k7 * x5(t)) // (2 * k8 + 1//2 * x6(t) + 1//2 * x5(t)) + (8 * k5 * x4(t)) // (4 * k6 + 8 * x4(t))) // (1//2),
    x7'(t) = (1//5 * (10 * k10 - 1//2 * x6(t)) * k9 * x6(t)) // (5 * k10),
    x4'(t) = (-8 * k5 * x4(t)) // (8 * (4 * k6 + 8 * x4(t))),
    x6'(t) = ((-1//5 * (10 * k10 - 1//2 * x6(t)) * k9 * x6(t)) // (10 * k10) + (3//10 * k7 * x5(t)) // (2 * k8 + 1//2 * x6(t) + 1//2 * x5(t))) // (1//2),
    y1(t) = 8 * x4(t),
    y2(t) = 1//2 * x5(t),
)
try
    res_bioh = SIAN.identifiability_ode(ode_bioh, SIAN.get_parameters(ode_bioh); infolevel=0)
    println("  Result keys: ", sort(collect(keys(res_bioh))))
    println("  algebraic_multiplicity = ", get(res_bioh, "algebraic_multiplicity", "MISSING"))
catch err
    println("\n  *** CRASH on biohydrogenation ***")
    println("  Error type: ", typeof(err))
    if err isa TaskFailedException && hasfield(typeof(err), :task) && hasfield(typeof(err.task), :exception)
        println("  Inner exception: ", typeof(err.task.exception))
        println("  Inner message:   ", err.task.exception)
    else
        showerror(stdout, err)
        println()
    end
    println()
    println("  → Capture for upstream Groebner.jl bug report.")
end

println()
println("=" ^ 60)
println("DONE")
