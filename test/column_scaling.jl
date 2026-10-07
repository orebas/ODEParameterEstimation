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

	@testset "only derivative unknowns can be scaled" begin
		solve_vars = ["k5_0", "x4_0", "x4_1", "x4_2", "x4_3_pt2"]
		@test OPE.column_scalable(solve_vars) == [false, false, true, true, true]
		# The scales agree: whatever the data, an unknown that cannot be scaled has a scale of one.
		data_vars = ["y1(t)", "Differential(t, 1)(y1(t))", "Differential(t, 2)(y1(t))", "Differential(t, 3)(y1(t))"]
		scales = OPE.compute_column_scales(solve_vars, data_vars, [[1e6, 50.0, 5000.0, 0.5]])
		@test scales == [1.0, 1.0, 50.0, 5000.0, 1.0]
		@test all(scales[.!OPE.column_scalable(solve_vars)] .== 1.0)
	end

	@testset "scale_hc_system takes the scales as parameters" begin
		HC.@var a b p
		F = HC.System([a^2 - p * b, a + b], variables = [a, b], parameters = [p])
		G = OPE.scale_hc_system(F, [a, b])
		@test HC.variables(G) == [a, b]
		@test length(HC.parameters(G)) == 3
		@test HC.parameters(G)[1] == p
		# The scales follow the system's own parameters: G(â, b̂; p, s) == F(s .* (â, b̂); p).
		@test G([1.0, 1.0], [0.5, 2.0, 3.0]) ≈ F([2.0, 3.0], [0.5])
		@test G([0.7, -1.3], [0.5, 2.0, 3.0]) ≈ F([1.4, -3.9], [0.5])
		# Scales of one give back the system itself.
		@test G([0.7, -1.3], [0.5, 1.0, 1.0]) ≈ F([0.7, -1.3], [0.5])

		# Only the variables named are scaled, and with none the system is returned as it is.
		H = OPE.scale_hc_system(F, [b])
		@test length(HC.parameters(H)) == 2
		@test H([0.7, -1.3], [0.5, 3.0]) ≈ F([0.7, -3.9], [0.5])
		@test OPE.scale_hc_system(F, typeof(a)[]) === F

		# The scaled system does not depend on the scale values, so HomotopyContinuation
		# compiles it once and reuses it for every data set.
		again = OPE.scale_hc_system(F, [a, b])
		@test again == G
		@test typeof(HC.fixed(again; compile = :all)) == typeof(HC.fixed(G; compile = :all))
	end

	@testset "scale parameters get names of their own" begin
		# The system already uses the first name a scale would get, and the next one tried.
		HC.@var colscale_1 colscale_1_ b
		F = HC.System([colscale_1^2 - colscale_1_ * b, colscale_1 + b], variables = [colscale_1, b], parameters = [colscale_1_])
		G = OPE.scale_hc_system(F, [colscale_1, b])
		@test allunique(string.(vcat(HC.variables(G), HC.parameters(G))))
		@test G([1.0, 1.0], [0.5, 2.0, 3.0]) ≈ F([2.0, 3.0], [0.5])
	end
end
