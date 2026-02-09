# Debug script: Test if variables from different deepcopies match
#
# Hypothesis: The variables in DD.obs_rhs (from deepcopy(measured_quantities))
# don't match variables in DD.states_lhs (from deepcopy(model_eq))
# because they are separate deepcopy operations.

using ODEParameterEstimation
using ModelingToolkit: @variables, @parameters, Differential, ODESystem
using ModelingToolkit
using OrderedCollections

println("=" ^ 60)
println("DEBUG: Testing variable identity across different deepcopies")
println("=" ^ 60)

# Create a simple ODE model (similar to biohydrogenation structure)
t = ODEParameterEstimation.t  # Use the global t
@variables x4(t) x5(t)
@parameters k5 k6
D = Differential(t)

# ODE equations
eqs = [
    D(x4) ~ -k5 * x4 / (k6 + x4),
    D(x5) ~ k5 * x4 / (k6 + x4) - x5,
]

# Observable: y = x4 (direct observation of state)
@variables y(t)
measured_quantities = [
    y ~ x4
]

@named model = ODESystem(eqs, t)

println("\n1. Original variables from model:")
params = ModelingToolkit.parameters(model)
unknowns_orig = ModelingToolkit.unknowns(model)
println("   params: ", params)
println("   unknowns: ", unknowns_orig)

# Get x4 from original model unknowns
x4_from_model = unknowns_orig[1]
println("\n   x4 from model unknowns:")
println("   objectid: ", objectid(x4_from_model))

println("\n2. Simulate deepcopy of equations (as in unpack_ODE):")
eqs_deepcopy = deepcopy(ModelingToolkit.equations(model))
# Get x4 from the deepcopy'd equation RHS
expr_from_eqs = eqs_deepcopy[1].rhs  # -k5*x4 / (k6 + x4)
vars_from_eqs = ModelingToolkit.Symbolics.get_variables(expr_from_eqs)
println("   Expression: ", expr_from_eqs)
println("   Variables: ", vars_from_eqs)

x4_from_eqs_deepcopy = nothing
for v in vars_from_eqs
    if occursin("x4", string(v))
        global x4_from_eqs_deepcopy = v
        break
    end
end
if x4_from_eqs_deepcopy !== nothing
    println("   x4 from eqs deepcopy objectid: ", objectid(x4_from_eqs_deepcopy))
end

println("\n3. Simulate deepcopy of measured_quantities:")
measured_quantities_deepcopy = deepcopy(measured_quantities)
# Get x4 from the deepcopy'd measured quantity RHS
expr_from_mq = measured_quantities_deepcopy[1].rhs  # x4
println("   Expression: ", expr_from_mq)

x4_from_mq_deepcopy = nothing
if ModelingToolkit.Symbolics.iscall(expr_from_mq)
    x4_from_mq_deepcopy = expr_from_mq
else
    x4_from_mq_deepcopy = expr_from_mq
end
println("   x4 from mq deepcopy: ", x4_from_mq_deepcopy)
println("   x4 from mq deepcopy objectid: ", objectid(x4_from_mq_deepcopy))

println("\n4. Now differentiate the measured quantity (as done in populate_derivatives):")
diff_mq = ModelingToolkit.expand_derivatives(D(expr_from_mq))
println("   D(y_rhs) = D(x4) expanded: ", diff_mq)
println("   Type: ", typeof(diff_mq))

# Check if this derivative matches what would be in DD.states_lhs
# DD.states_lhs[2][1] should be D(x4) from the equations
D_x4_from_eqs = ModelingToolkit.expand_derivatives(D(eqs_deepcopy[1].lhs))
println("\n   D(eqs[1].lhs) from equations: ", D_x4_from_eqs)
println("   Type: ", typeof(D_x4_from_eqs))

println("\n5. Check if the derivatives match:")
println("   isequal(diff_mq, D_x4_from_eqs): ", isequal(diff_mq, D_x4_from_eqs))
println("   diff_mq === D_x4_from_eqs:       ", diff_mq === D_x4_from_eqs)

# Now try substitution
println("\n6. Test substitution:")
# Build a dictionary with D(x4) from equations as key
dict_from_eqs = Dict(D_x4_from_eqs => 42.0)
println("   Dict key (from equations): ", D_x4_from_eqs)
println("   Dict key objectid: ", objectid(D_x4_from_eqs))

# Try to substitute D(x4) from measured quantities
result = ModelingToolkit.Symbolics.substitute(diff_mq, dict_from_eqs)
println("\n   Substituting '$(diff_mq)' (from mq) with key '$(D_x4_from_eqs)' (from eqs):")
println("   Result: ", result)
println("   Result type: ", typeof(result))
println("   Substitution successful: ", !(ModelingToolkit.Symbolics.iscall(result) && result == diff_mq)
)

println("\n" * "=" ^ 60)
println("CONCLUSION:")
if D_x4_from_eqs === diff_mq
    println("  Variables are identical objects - substitution should work")
else
    println("  BUG: Variables are DIFFERENT objects!")
    println("  D(x4) from equations: objectid = ", objectid(D_x4_from_eqs))
    println("  D(x4) from mq:        objectid = ", objectid(diff_mq))
    println("  This causes Symbolics.substitute to fail!")
end
println("=" ^ 60)
