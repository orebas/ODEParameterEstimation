using ODEParameterEstimation
using LinearAlgebra
using Symbolics
using Test

@testset "Noise-frontier Jacobian and rank" begin
    @variables x[1:17]
    variables = collect(x)

    # More variables than a typical AD chunk, with an independent, exact
    # Jacobian. Redundant equations must not change the column-rank decision.
    A = zeros(19, 17)
    A[1:17, :] = diagm(Float64.(1:17))
    A[18, :] = A[1, :] + A[3, :]
    A[19, :] = 2 * A[17, :]
    J, observed_rank = ODEParameterEstimation._noise_rank_matrix(A * variables, variables)
    @test J == A
    @test observed_rank == 17

    A[:, 17] = 2 * A[:, 16]
    J, observed_rank = ODEParameterEstimation._noise_rank_matrix(A * variables, variables)
    @test J == A
    @test observed_rank == 16

    # Nonlinear equations with an exact row dependence at every probe point.
    equations = [x[1]^2 + x[2], 2 * x[1]^2 + 2 * x[2], x[3]]
    J, observed_rank = ODEParameterEstimation._noise_rank_matrix(equations, variables[1:3])
    @test observed_rank == 2
    @test J[2, :] == 2 * J[1, :]
    @test J[1, 2:3] == [1, 0]
    @test J[3, :] == [0, 0, 1]
end
