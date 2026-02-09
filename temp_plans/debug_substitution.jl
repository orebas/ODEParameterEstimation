# Debug script: Verify that deepcopy in unpack_ODE causes variable mismatch
#
# Hypothesis: The deepcopy of equations creates new symbolic variable objects,
# which don't match the keys in the substitution dictionary (which uses original variables).

using ODEParameterEstimation
using ModelingToolkit: @variables, @parameters, Differential, ODESystem
using ModelingToolkit
using OrderedCollections

println("=" ^ 60)
println("DEBUG: Testing variable identity between deepcopy and original")
println("=" ^ 60)

# Create a simple ODE model
t = ODEParameterEstimation.t  # Use the global t
@variables x(t) y(t)
@parameters k1 k2
D = Differential(t)

eqs = [
    D(x) ~ -k1 * x,
    D(y) ~ k1 * x - k2 * y,
]

@named model = ODESystem(eqs, t)

println("\n1. Get variables from the model:")
params = ModelingToolkit.parameters(model)
unknowns = ModelingToolkit.unknowns(model)
println("   parameters(model): ", params)
println("   unknowns(model):   ", unknowns)

# Get the original parameter
k1_original = params[1]
x_original = unknowns[1]
println("\n2. Original k1:")
println("   Value: ", k1_original)
println("   objectid: ", objectid(k1_original))
println("   Original x:")
println("   Value: ", x_original)
println("   objectid: ", objectid(x_original))

# Get the deepcopy'd equation (simulating unpack_ODE)
eqs_deepcopy = deepcopy(ModelingToolkit.equations(model))
println("\n3. Deep-copied equations:")
for eq in eqs_deepcopy
    println("   ", eq)
end

# Extract k1 from the deepcopy'd equation
# The first equation should be D(x) ~ -k1 * x
expr = eqs_deepcopy[1].rhs  # -k1 * x
println("\n4. Expression from deepcopy'd equation: ", expr)

# Get variables from the expression
vars_in_expr = ModelingToolkit.Symbolics.get_variables(expr)
println("   Variables in expression:")
for v in vars_in_expr
    println("      ", v, " (objectid: ", objectid(v), ")")
end

# Check if any variable from deepcopy matches the original
println("\n5. Comparing original vs deepcopy'd variables:")
for v in vars_in_expr
    println("   Variable: ", v)
    println("   isequal(k1_original, v): ", isequal(k1_original, v))
    println("   isequal(x_original, v):  ", isequal(x_original, v))
    println("   k1_original === v:       ", k1_original === v)
    println("   x_original === v:        ", x_original === v)
    println()
end

println("\n6. Test substitution with original variables as keys:")
dict_original = Dict(k1_original => 1.0, x_original => 2.0)
println("   Dictionary keys: ", collect(keys(dict_original)))
result1 = ModelingToolkit.Symbolics.substitute(expr, dict_original)
println("   Substituting expression '$(expr)' with original keys:")
println("   Result: ", result1, " (type: ", typeof(result1), ")")
println("   Is numeric: ", result1 isa Number)

# Now extract variable from deepcopy and use as key
println("\n7. Test substitution with deepcopy'd variables as keys:")
k1_deepcopy = nothing
x_deepcopy = nothing
for v in vars_in_expr
    if !ModelingToolkit.Symbolics.iscall(v)
        k1_deepcopy = v  # parameters don't have (t)
    else
        x_deepcopy = v   # unknowns have (t)
    end
end

if k1_deepcopy !== nothing && x_deepcopy !== nothing
    dict_deepcopy = Dict(k1_deepcopy => 1.0, x_deepcopy => 2.0)
    println("   Dictionary keys: ", collect(keys(dict_deepcopy)))
    result2 = ModelingToolkit.Symbolics.substitute(expr, dict_deepcopy)
    println("   Substituting expression '$(expr)' with deepcopy keys:")
    println("   Result: ", result2, " (type: ", typeof(result2), ")")
    println("   Is numeric: ", result2 isa Number)
else
    println("   ERROR: Could not identify k1_deepcopy or x_deepcopy")
end

println("\n" * "=" ^ 60)
println("CONCLUSION:")
if k1_deepcopy !== nothing && k1_original !== k1_deepcopy
    println("  BUG CONFIRMED: deepcopy creates NEW variable objects!")
    println("  Original k1 objectid: ", objectid(k1_original))
    println("  Deepcopy k1 objectid: ", objectid(k1_deepcopy))
    println("  Symbolics.substitute uses object identity, so substitution fails!")
else
    println("  Variables appear to be identical (isequal may work)")
    println("  BUT object identity (===) may differ")
end
println("=" ^ 60)
