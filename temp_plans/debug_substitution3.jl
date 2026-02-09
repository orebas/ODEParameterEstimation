# Debug script: Test if x4 from different deepcopies match for substitution
#
# Focus on the actual issue: can we substitute x4 from equations deepcopy
# into an expression containing x4 from measured_quantities deepcopy?

using ODEParameterEstimation
using ModelingToolkit: @variables, @parameters, Differential, ODESystem
using ModelingToolkit
using OrderedCollections

println("=" ^ 60)
println("DEBUG: Can variables from different deepcopies substitute?")
println("=" ^ 60)

# Create a simple ODE model (similar to biohydrogenation structure)
t = ODEParameterEstimation.t  # Use the global t
@variables x4(t)
@parameters k5 k6
D = Differential(t)

# ODE equation
eqs = [D(x4) ~ -k5 * x4 / (k6 + x4)]

# Observable: y = x4 (direct observation of state)
@variables y(t)
measured_quantities = [y ~ x4]

@named model = ODESystem(eqs, t)

println("\n1. Create two separate deepcopies (as done in populate_derivatives):")
eqs_deepcopy = deepcopy(ModelingToolkit.equations(model))
measured_quantities_deepcopy = deepcopy(measured_quantities)

# Get x4 from both deepcopies
x4_from_eqs = nothing
for v in ModelingToolkit.Symbolics.get_variables(eqs_deepcopy[1].rhs)
    if occursin("x4", string(v))
        global x4_from_eqs = v
        break
    end
end

x4_from_mq = measured_quantities_deepcopy[1].rhs  # This is x4 directly

println("   x4 from equations deepcopy:")
println("      Value: ", x4_from_eqs)
println("      objectid: ", objectid(x4_from_eqs))
println("   x4 from measured_quantities deepcopy:")
println("      Value: ", x4_from_mq)
println("      objectid: ", objectid(x4_from_mq))

println("\n2. Check equality:")
println("   isequal(x4_from_eqs, x4_from_mq): ", isequal(x4_from_eqs, x4_from_mq))
println("   x4_from_eqs === x4_from_mq:       ", x4_from_eqs === x4_from_mq)
println("   hash(x4_from_eqs) == hash(x4_from_mq): ", hash(x4_from_eqs) == hash(x4_from_mq))

println("\n3. Test substitution:")
# Create a substitution dict with x4 from equations
dict_eqs = Dict(x4_from_eqs => 10.0, k5 => 1.0, k6 => 2.0)

# Get k5, k6 from eqs for completeness
all_vars_eqs = ModelingToolkit.Symbolics.get_variables(eqs_deepcopy[1].rhs)
for v in all_vars_eqs
    vstr = string(v)
    if occursin("k5", vstr)
        dict_eqs[v] = 1.0
    elseif occursin("k6", vstr)
        dict_eqs[v] = 2.0
    end
end

println("   Dictionary keys from equations deepcopy:")
for (k, v) in dict_eqs
    println("      ", k, " => ", v, " (objectid: ", objectid(k), ")")
end

# Expression from measured_quantities (differentiated)
# This is what obs_rhs would contain after differentiation
obs_diff = ModelingToolkit.expand_derivatives(D(x4_from_mq))
println("\n   Expression from mq (differentiated): ", obs_diff)

# Build the ODE RHS substitution (what states_rhs contains)
states_rhs = eqs_deepcopy[1].rhs  # -k5*x4 / (k6 + x4)
states_lhs = ModelingToolkit.expand_derivatives(D(eqs_deepcopy[1].lhs))  # D(x4)
println("   ODE RHS (states_rhs): ", states_rhs)
println("   ODE LHS derivative (states_lhs): ", states_lhs)

# First substitution: substitute params/states into ODE RHS
result1 = ModelingToolkit.Symbolics.substitute(states_rhs, dict_eqs)
println("\n   Step 1: Substitute into ODE RHS")
println("   Result: ", result1)
println("   Is numeric: ", !ModelingToolkit.Symbolics.iscall(result1))

# Add the derivative to the dictionary
dict_with_deriv = copy(dict_eqs)
dict_with_deriv[states_lhs] = ModelingToolkit.Symbolics.value(result1)
println("\n   Added to dict: ", states_lhs, " => ", ModelingToolkit.Symbolics.value(result1))
println("   Key objectid: ", objectid(states_lhs))

# Now try to substitute obs_diff (which uses x4 from mq deepcopy)
println("\n4. Critical test: substitute obs_diff using dict with states_lhs key")
println("   obs_diff: ", obs_diff, " (objectid: ", objectid(obs_diff), ")")
println("   dict key: ", states_lhs, " (objectid: ", objectid(states_lhs), ")")
println("   isequal: ", isequal(obs_diff, states_lhs))

result2 = ModelingToolkit.Symbolics.substitute(obs_diff, dict_with_deriv)
println("\n   Substitution result: ", result2)
println("   Is numeric: ", result2 isa Number || !ModelingToolkit.Symbolics.iscall(result2))

println("\n" * "=" ^ 60)
println("DIAGNOSIS:")
if isequal(obs_diff, states_lhs)
    println("  isequal works - Symbolics.substitute should find the key")
    if result2 isa Number || !ModelingToolkit.Symbolics.iscall(result2)
        println("  Substitution SUCCEEDED - this is not the bug")
    else
        println("  BUG: Substitution FAILED despite isequal match!")
        println("  This suggests Symbolics.substitute uses === not isequal")
    end
else
    println("  BUG: isequal fails for variables from different deepcopies!")
    println("  obs_diff and states_lhs are structurally different")
end
println("=" ^ 60)
