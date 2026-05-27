# Unit tests for data-driven column scaling helpers (no ODE solve required).
# Run standalone:
#   julia --startup-file=no -e 'using ODEParameterEstimation, Test; include("test/column_scaling.jl")'
using ODEParameterEstimation, HomotopyContinuation, Test
const OPE = ODEParameterEstimation
const HC = HomotopyContinuation

@testset "column scaling helpers" begin
	@testset "compute_column_scales rule" begin
		# solve_vars: a param (order 0), and state x4 derivatives of order 0,1,2.
		# Strings stand in for symbolic vars (the helper only uses string(·)).
		solve_vars = ["k5_0", "x4_0", "x4_1", "x4_2"]
		data_vars = ["y1(t)", "Differential(t, 1)(y1(t))", "Differential(t, 2)(y1(t))"]
		# order-0 mag 2, order-1 mag 50, order-2 mag 5000
		param_values_list = [[2.0, 50.0, 5000.0]]
		s = OPE.compute_column_scales(solve_vars, data_vars, param_values_list)
		@test s[1] == 1.0            # param (order 0) untouched
		@test s[2] == 1.0            # state order 0 untouched
		@test s[3] == 50.0           # order 1 -> max(50,1)
		@test s[4] == 5000.0         # order 2 -> max(5000,1)
	end

	@testset "order_mag aggregates max over points; floor at 1.0" begin
		solve_vars = ["x_1", "x_2"]
		data_vars = ["Differential(t, 1)(y1(t))", "Differential(t, 2)(y1(t))"]
		# two points; order-1 max(0.3, 7.0)=7.0 (then floor) ; order-2 max(0.1,0.2)=0.2 -> floor to 1.0
		param_values_list = [[0.3, 0.1], [7.0, 0.2]]
		s = OPE.compute_column_scales(solve_vars, data_vars, param_values_list)
		@test s[1] == 7.0            # order 1 -> max(7.0, 1.0)
		@test s[2] == 1.0            # order 2 mag 0.2 -> floored to 1.0
	end

	@testset "non-finite skipped, empty -> ones, missing order -> 1.0" begin
		solve_vars = ["x_1", "x_5"]   # x_5 has no order-5 data
		data_vars = ["Differential(t, 1)(y1(t))"]
		# NaN/Inf in some points are ignored; finite max is 40.0
		param_values_list = [[NaN], [Inf], [40.0]]
		s = OPE.compute_column_scales(solve_vars, data_vars, param_values_list)
		@test s[1] == 40.0           # order 1 from the only finite value
		@test s[2] == 1.0            # no order-5 data -> fallback 1.0

		# empty param list -> identity
		@test OPE.compute_column_scales(solve_vars, data_vars, Vector{Vector{Float64}}()) == ones(2)
	end

	@testset "scale_hc_system round-trip" begin
		HC.@var a b
		F = HC.System([a^2 - b, a + b], variables = [a, b])
		# all-ones -> returns same object (fast path)
		@test OPE.scale_hc_system(F, [a, b], [1.0, 1.0]) === F
		# scale a by 2, b by 3: G(â,b̂) = F(2â,3b̂); G(1,1) must equal F(2,3)
		G = OPE.scale_hc_system(F, [a, b], [2.0, 3.0])
		@test G([1.0, 1.0]) ≈ F([2.0, 3.0])
		# and a generic point: G(â,b̂) == F(2â,3b̂)
		@test G([0.7, -1.3]) ≈ F([1.4, -3.9])
	end
end
