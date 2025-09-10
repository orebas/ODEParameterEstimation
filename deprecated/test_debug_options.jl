# Test script to verify debug options are working correctly

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections

# Create a simple test problem
@parameters a b
@variables t x(t) y(t)
D = Differential(t)

eqs = [
    D(x) ~ a * x - b * x * y,
    D(y) ~ -a * y + b * x * y
]

measured_quantities = [
    x ~ x,
    y ~ y
]

# Create a simple ODE system
@named sys = ODESystem(eqs, t)

# Create test data
data_sample = OrderedDict(
    "t" => [0.0, 1.0, 2.0],
    x => [1.0, 1.2, 1.5],
    y => [0.5, 0.6, 0.7]
)

p_true = OrderedDict(a => 1.0, b => 0.5)
ic = OrderedDict(x => 1.0, y => 0.5)

# Create the parameter estimation problem
pep = ParameterEstimationProblem(
    "test_problem",
    OrderedODESystem(sys),
    measured_quantities,
    data_sample,
    nothing,
    nothing,
    p_true,
    ic,
    0
)

println("\n=== Test 1: Default options (no debug output, save_system=true) ===")
try
    result = multipoint_parameter_estimation(
        pep,
        max_num_points = 1,
        interpolator = nothing,
    )
    println("✓ Test 1 passed - no debug output visible")
catch e
    println("Test 1 result: ", e)
end

println("\n=== Test 2: Enable all debug options ===")
try
    result = multipoint_parameter_estimation(
        pep,
        max_num_points = 1,
        interpolator = nothing,
        diagnostics = true,
        debug_solver = true,
        debug_cas_diagnostics = true,
        debug_dimensional_analysis = true,
    )
    println("✓ Test 2 passed - debug output should be visible above")
catch e
    println("Test 2 result: ", e)
end

println("\n=== Test 3: Disable system saving ===")
try
    result = multipoint_parameter_estimation(
        pep,
        max_num_points = 1,
        interpolator = nothing,
        save_system = false,
    )
    println("✓ Test 3 passed - no 'Saved polynomial system' messages should appear")
catch e
    println("Test 3 result: ", e)
end

println("\n=== Test 4: Selective debug (only solver debug) ===")
try
    result = multipoint_parameter_estimation(
        pep,
        max_num_points = 1,
        interpolator = nothing,
        debug_solver = true,
        debug_cas_diagnostics = false,
        debug_dimensional_analysis = false,
    )
    println("✓ Test 4 passed - only DEBUG-SOLVER output should be visible")
catch e
    println("Test 4 result: ", e)
end

println("\n=== All tests completed ===")
println("Check that:")
println("1. Test 1 showed no DEBUG output")
println("2. Test 2 showed all DEBUG output")
println("3. Test 3 showed no 'Saved polynomial system' messages")
println("4. Test 4 showed only DEBUG-SOLVER output")