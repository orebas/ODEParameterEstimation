# Debug script: Exactly mimic populate_derivatives to find the bug
#
# In populate_derivatives:
# - states_lhs[1] = [eq.lhs for eq in model_eq] = [D(x4)] (already a derivative)
# - obs_rhs[2] = D.(obs_rhs[1]) = [D(x4)] (derivative of observable)
#
# Both should contain D(x4), but from DIFFERENT deepcopies!

using ODEParameterEstimation
using ModelingToolkit: @variables, @parameters, Differential, ODESystem
using ModelingToolkit
using OrderedCollections

println("=" ^ 60)
println("DEBUG: Exact mimic of populate_derivatives")
println("=" ^ 60)

# Create model
t = ODEParameterEstimation.t
@variables x4(t)
@parameters k5 k6
D = Differential(t)

eqs = [D(x4) ~ -k5 * x4 / (k6 + x4)]
@variables y(t)
measured_quantities = [y ~ x4]

@named model = ODESystem(eqs, t)

println("\n1. Simulate unpack_ODE + deepcopies (as in populate_derivatives):")
# This mimics what happens in populate_derivatives
model_eq = deepcopy(ModelingToolkit.equations(model))
measured_quantities_dc = deepcopy(measured_quantities)

println("   model_eq: ", model_eq)
println("   measured_quantities_dc: ", measured_quantities_dc)

println("\n2. Build states_lhs and obs_rhs (as in populate_derivatives):")
# DD.states_lhs = [[eq.lhs for eq in model_eq], expand_derivatives.(D.([eq.lhs for eq in model_eq]))]
states_lhs_0 = [eq.lhs for eq in model_eq]  # This is [D(x4)] from eqs
states_lhs_1 = ModelingToolkit.expand_derivatives.(D.(states_lhs_0))  # This is [D(D(x4))]

# DD.obs_rhs = [[eq.rhs for eq in measured_quantities], expand_derivatives.(D.([eq.rhs for eq in measured_quantities]))]
obs_rhs_0 = [eq.rhs for eq in measured_quantities_dc]  # This is [x4] from mq
obs_rhs_1 = ModelingToolkit.expand_derivatives.(D.(obs_rhs_0))  # This is [D(x4)] from mq

println("   states_lhs[1] = ", states_lhs_0, " (from model_eq)")
println("   states_lhs[2] = ", states_lhs_1, " (D of states_lhs[1])")
println("   obs_rhs[1] = ", obs_rhs_0, " (from measured_quantities)")
println("   obs_rhs[2] = ", obs_rhs_1, " (D of obs_rhs[1])")

println("\n3. The KEY comparison:")
println("   states_lhs[1][1] = ", states_lhs_0[1])
println("      objectid: ", objectid(states_lhs_0[1]))
println("   obs_rhs[2][1] = ", obs_rhs_1[1])
println("      objectid: ", objectid(obs_rhs_1[1]))

println("\n   isequal(states_lhs[1][1], obs_rhs[2][1]): ", isequal(states_lhs_0[1], obs_rhs_1[1]))
println("   states_lhs[1][1] === obs_rhs[2][1]:       ", states_lhs_0[1] === obs_rhs_1[1])

println("\n4. Test substitution (as in multipoint_numerical_jacobian):")
# Build dictionary with states_lhs[1][1] as key (this comes from processing states_rhs)
# The value would be the numeric result of substituting into states_rhs[1][1]
dict_test = Dict{Any, Any}()
dict_test[states_lhs_0[1]] = -0.833  # Simulated numeric value

println("   Dictionary key: ", states_lhs_0[1], " (objectid: ", objectid(states_lhs_0[1]), ")")
println("   Dictionary value: ", dict_test[states_lhs_0[1]])

# Now try to substitute obs_rhs[2][1]
println("\n   Trying to substitute obs_rhs[2][1] = ", obs_rhs_1[1])
result = ModelingToolkit.Symbolics.substitute(obs_rhs_1[1], dict_test)
println("   Result: ", result)
println("   Substitution successful: ", result isa Number || result == -0.833)

println("\n" * "=" ^ 60)
println("DIAGNOSIS:")
if isequal(states_lhs_0[1], obs_rhs_1[1])
    println("  isequal returns true")
    if result isa Number || !ModelingToolkit.Symbolics.iscall(result)
        println("  Substitution WORKED - this variable mismatch is NOT the bug")
    else
        println("  BUG: isequal=true but substitution FAILED!")
        println("  Symbolics.substitute may require object identity (===)")
    end
else
    println("  BUG CONFIRMED: isequal returns false!")
    println("  Variables from different deepcopies don't match structurally")
    println("  states_lhs[1][1]: ", states_lhs_0[1])
    println("  obs_rhs[2][1]:    ", obs_rhs_1[1])
end
println("=" ^ 60)
