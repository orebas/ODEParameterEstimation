# _ift_solve contract (2026-08-13, "degrade loudly" decision): factorized IFT
# sensitivity, no silent pinv. The old cond>1e6 pinv fallback returned the
# minimum-norm derivative — suppressing weak-direction sensitivity and making
# downstream covariance overconfident exactly when conditioning is worst.
# Pure numerics; fast_unit tier.

using Test
using Logging
using LinearAlgebra

@testset "_ift_solve (factorized IFT, loud degradation)" begin
	@testset "well-conditioned: plain factorized solve" begin
		J_x = [2.0 0.0; 0.0 3.0]
		J_d = Matrix{Float64}(I, 2, 2)
		S, c, degraded = ODEParameterEstimation._ift_solve(J_x, J_d)
		@test S ≈ [-0.5 0.0; 0.0 -1/3] rtol = 1e-12
		@test c ≈ 1.5 rtol = 1e-12
		@test !degraded
	end

	@testset "ill-conditioned: degraded flag, amplification kept visible" begin
		J_x = [1.0 0.0; 0.0 1e-9]
		J_d = Matrix{Float64}(I, 2, 2)
		S, c, degraded = with_logger(NullLogger()) do
			ODEParameterEstimation._ift_solve(J_x, J_d)
		end
		@test degraded
		@test c ≈ 1e9 rtol = 1e-6
		# The weak-direction amplification stays VISIBLE (wide, honest), never
		# quietly suppressed toward a minimum-norm answer.
		@test abs(S[2, 2]) ≈ 1e9 rtol = 1e-6
	end

	@testset "exactly singular: empty S + degraded (no minimum-norm fiction)" begin
		J_x = [1.0 0.0; 0.0 0.0]
		J_d = Matrix{Float64}(I, 2, 2)
		S, c, degraded = with_logger(NullLogger()) do
			ODEParameterEstimation._ift_solve(J_x, J_d)
		end
		@test degraded
		@test isempty(S)   # no local IFT derivative exists — say so, don't invent one
	end
end
