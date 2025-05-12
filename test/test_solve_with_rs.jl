using ODEParameterEstimation
using ModelingToolkit
using Test
using LinearAlgebra

@testset "Testing solve_with_rs function" begin
    @variables x y z
    
    # System 1: Simple system with real solutions
    poly_system1 = [(x^2 + y^2 - 5.0), (x - 2*y)]
    solutions1, varlist1, _, _ = solve_with_rs(poly_system1, [x, y], polish_solutions=false)
    
    # Check if solutions were found
    @test !isempty(solutions1)
    
    # Check if solutions are correct (within tolerance)
    for sol in solutions1
        # Extract x and y values
        x_val = sol[1]
        y_val = sol[2]
        
        # Check if they satisfy the equations (with tolerance)
        @test abs(x_val^2 + y_val^2 - 5.0) < 1e-10
        @test abs(x_val - 2*y_val) < 1e-10
    end
    
    # System 2: This is the problematic system from the REPL - has complex solutions only
    poly_system2 = [(x^2 + y^2 - 4.0), (x + 2*y - 6.0)]
    solutions2, varlist2, _, _ = solve_with_rs(poly_system2, [x, y], polish_solutions=false)
    
    # For a system with only complex solutions, we expect empty results for real-only solutions
    @test isempty(solutions2)
    
    # No need to check further since we expect no solutions
    
    # Debug output
    @info "System 2 - solutions:" solutions2
    
    # System 3: Another test case with integer coefficients
    poly_system3 = [(x^2 + y^2 - 1), (x + y - 1)]
    solutions3, varlist3, _, _ = solve_with_rs(poly_system3, [x, y], polish_solutions=false)
    
    # Check if solutions were found
    @test !isempty(solutions3)
    
    # Check if solutions are correct (within tolerance)
    for sol in solutions3
        # Extract x and y values
        x_val = sol[1]
        y_val = sol[2]
        
        # Debug output
        @info "Solution:" x_val y_val
        @info "Residuals:" (x_val^2 + y_val^2 - 1) (x_val + y_val - 1)
        
        # Check if they satisfy the equations (with tolerance)
        @test abs(x_val^2 + y_val^2 - 1) < 1e-10
        @test abs(x_val + y_val - 1) < 1e-10
    end
end