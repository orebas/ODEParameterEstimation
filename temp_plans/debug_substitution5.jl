# Debug script: Test OrderedDict vs Dict for Symbolics.substitute
#
# The actual code uses OrderedDict. Maybe there's a difference in key matching?

using ODEParameterEstimation
using ModelingToolkit: @variables, @parameters, Differential, ODESystem
using ModelingToolkit
using OrderedCollections

println("=" ^ 60)
println("DEBUG: OrderedDict vs Dict for Symbolics.substitute")
println("=" ^ 60)

# Create model
t = ODEParameterEstimation.t
@variables x4(t)
@parameters k5 k6
D = Differential(t)

eqs = [D(x4) ~ -k5 * x4 / (k6 + x4)]
@named model = ODESystem(eqs, t)

# Get variables from model (as in multipoint_local_identifiability_analysis)
params_from_model = ModelingToolkit.parameters(model)
unknowns_from_model = ModelingToolkit.unknowns(model)

# Get expression from deepcopy'd equations (as in populate_derivatives)
eqs_deepcopy = deepcopy(ModelingToolkit.equations(model))
expr_from_deepcopy = eqs_deepcopy[1].rhs  # -k5*x4/(k6+x4)

println("\n1. Variables from model (used for dictionary keys):")
println("   params: ", params_from_model)
println("   unknowns: ", unknowns_from_model)

println("\n2. Expression from deepcopy (contains different variable objects):")
println("   expr: ", expr_from_deepcopy)
vars_in_expr = ModelingToolkit.Symbolics.get_variables(expr_from_deepcopy)
println("   vars: ", collect(vars_in_expr))

println("\n3. Test with regular Dict:")
dict_regular = Dict{Any, Any}()
dict_regular[params_from_model[1]] = 1.0  # k5
dict_regular[params_from_model[2]] = 2.0  # k6
dict_regular[unknowns_from_model[1]] = 10.0  # x4
println("   Dict keys: ", collect(keys(dict_regular)))
result_dict = ModelingToolkit.Symbolics.substitute(expr_from_deepcopy, dict_regular)
println("   Substitution result: ", result_dict)
println("   Success: ", !ModelingToolkit.Symbolics.iscall(result_dict))

println("\n4. Test with OrderedDict:")
dict_ordered = OrderedDict{Any, Any}()
dict_ordered[params_from_model[1]] = 1.0  # k5
dict_ordered[params_from_model[2]] = 2.0  # k6
dict_ordered[unknowns_from_model[1]] = 10.0  # x4
println("   OrderedDict keys: ", collect(keys(dict_ordered)))
result_ordered = ModelingToolkit.Symbolics.substitute(expr_from_deepcopy, dict_ordered)
println("   Substitution result: ", result_ordered)
println("   Success: ", !ModelingToolkit.Symbolics.iscall(result_ordered))

println("\n5. Test exact pattern from multipoint_numerical_jacobian:")
# Build values_dict as in the actual code
values_dict = OrderedDict{Any, Float64}()
for p in params_from_model
    values_dict[p] = rand()
end
for s in unknowns_from_model
    values_dict[s] = rand()
end

# Create evaluated_subst_dict as in the actual code
evaluated_subst_dict = OrderedDict{Any, Any}(values_dict)
thekeys = collect(keys(evaluated_subst_dict))
println("   values_dict keys: ", thekeys)

# Try substitution
result_actual = ModelingToolkit.Symbolics.substitute(expr_from_deepcopy, evaluated_subst_dict)
println("   Substitution result: ", result_actual)
println("   Success: ", !ModelingToolkit.Symbolics.iscall(result_actual))

println("\n" * "=" ^ 60)
println("DIAGNOSIS:")
if !ModelingToolkit.Symbolics.iscall(result_actual)
    println("  OrderedDict substitution WORKS in isolation")
    println("  The bug must be in HOW the dictionary is modified in the loop")
else
    println("  BUG FOUND: OrderedDict substitution FAILS even in isolation")
end
println("=" ^ 60)
