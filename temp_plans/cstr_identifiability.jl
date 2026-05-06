"""
What does StructuralIdentifiability + SIAN actually say about cstr_1_0?
- find_identifiable_functions: which combinations of params+ICs are identifiable
- assess_local_identifiability: per-variable local identifiability
- run_numerical_identifiability_advisory (the package's own): what does ODEPE think?
"""

using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using StructuralIdentifiability
const ODEPE = ODEParameterEstimation

parameters = @parameters tau Tin dH_rhoCP UA_VrhoCP
states = @variables C(t) Temp(t) r_eff(t)
observables = @variables y1(t)
eqs = [
    D(C) ~ (1.0 - C) / (2.0*tau) - 1.999863916554819*r_eff*C,
    D(Temp) ~ (Tin - Temp) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff*C - 2.0*UA_VrhoCP*Temp + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*sin(0.5*t),
    D(r_eff) ~ 12.5*r_eff/(Temp^2)*((Tin - Temp) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff*C - 2.0*UA_VrhoCP*Temp + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*sin(0.5*t)),
]
mq_orig = [y1 ~ 700.0*Temp]
ic = [0.843, 0.18, 0.856]
p_true = [0.385, 0.113, 0.248, 0.421]

println("="^72)
println("STRUCTURAL IDENTIFIABILITY OF CSTR (sin-forced, polished, exact)")
println("="^72)

# Build SI ODE
si_ode = StructuralIdentifiability.@ODEmodel(
    C'(t) = (1.0 - C(t)) / (2.0*tau) - 1.999863916554819*r_eff(t)*C(t),
    Temp'(t) = (Tin - Temp(t)) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff(t)*C(t) - 2.0*UA_VrhoCP*Temp(t) + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*sin_term(t),
    r_eff'(t) = 12.5*r_eff(t)/(Temp(t)^2)*((Tin - Temp(t)) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff(t)*C(t) - 2.0*UA_VrhoCP*Temp(t) + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*sin_term(t)),
    sin_term'(t) = 0.5*cos_term(t),
    cos_term'(t) = -0.5*sin_term(t),
    y1(t) = 700.0*Temp(t)
)

println("\n--- assess_local_identifiability ---")
local_id = StructuralIdentifiability.assess_local_identifiability(si_ode)
println(local_id)

println("\n--- assess_identifiability ---")
global_id = StructuralIdentifiability.assess_identifiability(si_ode)
println(global_id)

println("\n--- find_identifiable_functions (with_states=true) ---")
ident_fns = StructuralIdentifiability.find_identifiable_functions(si_ode; with_states = true)
for f in ident_fns
    println("  ", f)
end

println("\nCSTR_IDENTIFIABILITY_DONE")
