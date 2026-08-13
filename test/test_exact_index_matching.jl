# Two silent-mismatch fixes (2026-08-13, multipoint-UQ pre-fixes):
# 1. _per_point_data_indices returns EXACT per-point index lists — the old
#    first:last range collapse mis-assigned data when indices interleave.
# 2. _match_obs_name is exact-only — the old startswith prefix fallback let
#    "y1" match "y10" depending on dict iteration order.
# Pure functions; fast_unit tier.

using Test
using Symbolics

@testset "exact index & name matching (silent-mismatch fixes)" begin
	@testset "_per_point_data_indices handles interleaved ordering" begin
		v(s) = Symbolics.variable(Symbol(s))
		# Deliberately interleaved: pt2, pt1, pt2, pt1
		data_vars = Any[v("y1_0_pt2"), v("y1_0"), v("y1_1_pt2"), v("y1_1")]
		idx = ODEParameterEstimation._per_point_data_indices(data_vars, 2)
		@test idx[1] == [2, 4]   # unsuffixed → point 1
		@test idx[2] == [1, 3]
		# The old first(indices):last(indices) collapse would have produced
		# 2:4 and 1:3 — overlapping, both wrong.
		@test sort(vcat(idx...)) == [1, 2, 3, 4]

		# Point-major contiguous input still works
		data_vars2 = Any[v("y1_0"), v("y1_1"), v("y1_0_pt2"), v("y1_1_pt2")]
		idx2 = ODEParameterEstimation._per_point_data_indices(data_vars2, 2)
		@test idx2[1] == [1, 2]
		@test idx2[2] == [3, 4]

		# Empty point list stays empty
		idx3 = ODEParameterEstimation._per_point_data_indices(Any[v("y1_0")], 2)
		@test idx3[1] == [1]
		@test isempty(idx3[2])
	end

	@testset "_match_obs_name is exact-only (y1 vs y10)" begin
		d = Dict("y1" => 1, "y10" => 2)
		@test ODEParameterEstimation._match_obs_name("y1", d) == 1
		@test ODEParameterEstimation._match_obs_name("y10", d) == 2
		@test ODEParameterEstimation._match_obs_name("y", d) === nothing
		@test ODEParameterEstimation._match_obs_name("y9", d) === nothing
		@test ODEParameterEstimation._match_obs_name("y100", d) === nothing
	end
end
