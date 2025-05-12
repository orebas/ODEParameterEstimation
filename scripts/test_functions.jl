### A simple script to test core functionality of ODEParameterEstimation.jl
### Run this script with: julia --project scripts/test_functions.jl

using ODEParameterEstimation
using ModelingToolkit
using OrdinaryDiffEq

function test_model_utils()
    println("Testing model_utils.jl functions...")
    
    # Create a simple test ODE model
    @parameters a b
    @variables t x1(t) x2(t)
    D = Differential(t)
    
    eqs = [
        D(x1) ~ -a * x2,
        D(x2) ~ b * x1
    ]
    states = [x1, x2]
    params = [a, b]
    
    @named test_model = ODESystem(eqs, t, states, params)
    
    # Test unpack_ODE
    time_var, equations, state_vars, parameters = ODEParameterEstimation.unpack_ODE(test_model)
    println("  unpack_ODE: ", time_var === t ? "✓" : "✗")
    
    # Test tag_symbol
    tagged_x = ODEParameterEstimation.tag_symbol(x1, "pre_", "_post")
    println("  tag_symbol: ", occursin("pre_x1_t_post", string(tagged_x)) ? "✓" : "✗")
    
    # Test create_ordered_ode_system
    measured_quantities = [x1 ~ x1]
    ordered_system, mq = ODEParameterEstimation.create_ordered_ode_system(
        "TestSystem", states, params, eqs, measured_quantities)
    println("  create_ordered_ode_system: ", typeof(ordered_system) == ODEParameterEstimation.OrderedODESystem ? "✓" : "✗")
    
    println("Model utils tests complete.\n")
end

function test_math_utils()
    println("Testing math_utils.jl functions...")
    
    # Test clear_denoms
    @variables x y z
    eq = x/y ~ z
    cleared_eq = ODEParameterEstimation.clear_denoms(eq)
    println("  clear_denoms: ", cleared_eq.rhs == y*z ? "✓" : "✗")
    
    # Test count_turns
    series = [1, 2, 3, 2, 1]
    turns = ODEParameterEstimation.count_turns(series)
    println("  count_turns: ", turns == 1 ? "✓" : "✗")
    
    # Test calculate_timeseries_stats
    stats = ODEParameterEstimation.calculate_timeseries_stats([1.0, 2.0, 3.0, 4.0, 5.0])
    println("  calculate_timeseries_stats: ", stats.mean == 3.0 ? "✓" : "✗")
    
    println("Math utils tests complete.\n")
end

function test_core_types()
    println("Testing core_types.jl types...")
    
    # Test OrderedODESystem
    @parameters a b
    @variables t x1(t) x2(t)
    D = Differential(t)
    
    eqs = [
        D(x1) ~ -a * x2,
        D(x2) ~ b * x1
    ]
    states = [x1, x2]
    params = [a, b]
    
    @named model = ODESystem(eqs, t, states, params)
    ordered_sys = ODEParameterEstimation.OrderedODESystem(model, params, states)
    println("  OrderedODESystem: ", ordered_sys.original_parameters == params ? "✓" : "✗")
    
    println("Core types tests complete.\n")
end

function run_tests()
    println("Starting ODEParameterEstimation tests...\n")
    
    test_model_utils()
    test_math_utils()
    test_core_types()
    
    println("All tests complete!")
end

run_tests()