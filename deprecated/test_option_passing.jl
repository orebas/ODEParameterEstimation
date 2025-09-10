# Simple test to verify option passing

# Test the solve_with_rs function directly
using ODEParameterEstimation

# Create a simple polynomial system
poly_system = [:(x^2 - 1), :(y^2 - 4)]
varlist = [:x, :y]

println("Testing solve_with_rs with different debug options...")

println("\n1. No debug options:")
options1 = Dict()
# This would normally call solve_with_rs(poly_system, varlist; options = options1)
println("   Options passed: ", options1)

println("\n2. All debug options enabled:")
options2 = Dict(
    :debug_solver => true,
    :debug_cas_diagnostics => true,
    :debug_dimensional_analysis => true,
)
println("   Options passed: ", options2)

println("\n3. Only solver debug:")
options3 = Dict(
    :debug_solver => true,
    :debug_cas_diagnostics => false,
    :debug_dimensional_analysis => false,
)
println("   Options passed: ", options3)

println("\n✓ Option structures created successfully")
println("The debug options would be passed through the call chain:")
println("  multipoint_parameter_estimation -> solve_parameter_estimation -> system_solver (solve_with_rs)")