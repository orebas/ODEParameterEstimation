using ODEParameterEstimation
using Test
using ModelingToolkit
using Symbolics

@testset "Derivative Utilities" begin
    @testset "calculate_higher_derivatives" begin
        # Create a simple test ODE model
        @parameters a b
        @variables t x(t) y(t)
        D = Differential(t)
        
        eqs = [
            D(x) ~ a * x + b * y,
            D(y) ~ -b * x + a * y
        ]
        
        # Calculate derivatives up to level 2
        derivatives = ODEParameterEstimation.calculate_higher_derivatives(eqs, 2)
        
        # Check that we have the right number of derivative levels
        @test length(derivatives) == 3  # original + 2 derivative levels
        
        # Check that each level has the right number of equations
        @test length(derivatives[1]) == 2
        @test length(derivatives[2]) == 2
        @test length(derivatives[3]) == 2
        
        # Check that the first level contains the original equations
        @test isequal(derivatives[1][1].lhs, D(x))
        @test isequal(derivatives[1][2].lhs, D(y))
        
        # Check that the second level contains first derivatives
        # Second derivatives of x and y should appear in the LHS
        @test occursin("D(D(x))", string(derivatives[2][1].lhs)) || 
              occursin("D²(x)", string(derivatives[2][1].lhs))
        @test occursin("D(D(y))", string(derivatives[2][2].lhs)) || 
              occursin("D²(y)", string(derivatives[2][2].lhs))
    end
    
    @testset "calculate_higher_derivative_terms" begin
        # Create simple LHS and RHS terms
        @parameters a b
        @variables t x(t) y(t)
        
        lhs_terms = [x, y]
        rhs_terms = [a * x + b * y, -b * x + a * y]
        
        # Calculate derivatives up to level 2
        lhs_derivatives, rhs_derivatives = 
            ODEParameterEstimation.calculate_higher_derivative_terms(lhs_terms, rhs_terms, 2)
        
        # Check that we have the right number of derivative levels
        @test length(lhs_derivatives) == 3  # original + 2 derivative levels
        @test length(rhs_derivatives) == 3
        
        # Check that each level has the right number of terms
        @test length(lhs_derivatives[1]) == 2
        @test length(lhs_derivatives[2]) == 2
        @test length(lhs_derivatives[3]) == 2
        
        @test length(rhs_derivatives[1]) == 2
        @test length(rhs_derivatives[2]) == 2
        @test length(rhs_derivatives[3]) == 2
        
        # Check that the first level contains the original terms
        @test isequal(lhs_derivatives[1][1], x)
        @test isequal(lhs_derivatives[1][2], y)
        
        # First derivatives should contain D(x) and D(y)
        @test occursin("D(x)", string(lhs_derivatives[2][1])) || 
              occursin("ẋ", string(lhs_derivatives[2][1]))
        @test occursin("D(y)", string(lhs_derivatives[2][2])) || 
              occursin("ẏ", string(lhs_derivatives[2][2]))
    end
end