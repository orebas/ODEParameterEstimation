# EstimationOptions surface contracts (2026-08-12 dead-options cleanup):
# deleted fields error LOUDLY at construction (the rtol-vs-reltol typo class),
# and the newly wired fields actually reach their consumers.

using ODEParameterEstimation
using Test
using OrderedCollections

@testset "EstimationOptions surface contracts" begin
	# Deleted fields: setting one is a construction error, not a silent no-op.
	@test_throws MethodError EstimationOptions(rtol = 1e-8)
	@test_throws MethodError EstimationOptions(max_deriv_level = 12)
	@test_throws MethodError EstimationOptions(use_monodromy = true)

	# Wired fields exist with their behavior-neutral defaults.
	o = EstimationOptions()
	@test o.clustering_threshold == 1.0e-5   # == the old CLUSTERING_THRESHOLD constant
	@test o.si_probability == 0.99           # == SIAN's old hardcoded p
	@test o.point_hint == 0.5                # == pick_points' old kwarg default
	@test o.save_filepath == ""              # empty = legacy "saved_systems/" base
	@test o.hc_threading === true
	@test o.hc_compile_mode === :all

	# clustering_threshold genuinely controls full-space clustering: with a huge
	# threshold everything merges into one cluster; with a tiny one nothing does.
	fake(v) = (states = OrderedDict(:x => v), parameters = OrderedDict(:a => v))
	rows = [fake(1.0), fake(1.5), fake(2.0)]
	@test length(ODEParameterEstimation.cluster_solutions(rows; threshold = 10.0)) == 1
	@test length(ODEParameterEstimation.cluster_solutions(rows; threshold = 1e-12)) == 3

	# gp_s3_refinement shim survives (deprecation warning path, not deleted).
	@test EstimationOptions(gp_s3_refinement = false).gp_s3_refinement === false
end
