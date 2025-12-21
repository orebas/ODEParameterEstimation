# Debug script to trace SI template generation
using Logging

# Enable all debug logging
global_logger(ConsoleLogger(stderr, Logging.Debug))

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections

# Include example models
include("src/examples/load_examples.jl")

println("=" ^ 80)
println("DEBUGGING SI TEMPLATE GENERATION")
println("=" ^ 80)

# Create the problem
pep = cstr_fixed_activation()

println("Creating minimal data sample...")
# Create a minimal data sample
t_vec = collect(range(0.0, 10.0, length=101))
data_sample = OrderedDict(
    "t" => t_vec,
    "y1" => 350.0 .* ones(length(t_vec)),  # Dummy data for T
    "y2" => sin.(0.5 .* t_vec),              # Dummy data for u_sin
    "y3" => cos.(0.5 .* t_vec),              # Dummy data for u_cos
)

println("Getting model components...")
model = pep.model
measured_quantities = pep.measured_quantities

println("Creating OrderedODESystem...")
t = ModelingToolkit.get_iv(model)
model_states = ModelingToolkit.unknowns(model)
model_ps = ModelingToolkit.parameters(model)
ordered_model = ODEParameterEstimation.OrderedODESystem(model, model_states, model_ps)

println("Calling get_si_equation_system...")
template_equations, derivative_dict, unidentifiable, identifiable_funcs = ODEParameterEstimation.get_si_equation_system(
    ordered_model,
    measured_quantities,
    data_sample;
    DD = nothing,
    infolevel = 1,  # Enable verbose output
)

println("\n" * "=" ^ 80)
println("RESULTS:")
println("=" ^ 80)
println("Number of template equations: ", length(template_equations))
println("Derivative dict: ", derivative_dict)
println("Unidentifiable: ", unidentifiable)
println("Identifiable funcs: ", identifiable_funcs)

# Count variables in the equations
using Symbolics
all_vars = Set()
for eq in template_equations
    union!(all_vars, Symbolics.get_variables(eq))
end
println("Number of unique variables in equations: ", length(all_vars))
println("Variables: ", collect(all_vars))

# Print each equation
println("\n" * "=" ^ 80)
println("EQUATIONS:")
println("=" ^ 80)
for (i, eq) in enumerate(template_equations)
    println("Eq$i: ", eq)
end
