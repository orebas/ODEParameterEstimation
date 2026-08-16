using Test
using TOML

include(joinpath(
	@__DIR__, "..", "repro", "uq_coverage_harness_2026_08", "campaign_io.jl",
))

@testset "research campaign TOML serialization" begin
	mktempdir() do directory
		path = joinpath(directory, "nested_payload.toml")
		payload = Dict{String, Any}(
			"native" => Dict{String, Any}("value" => 2.5),
			"optional" => Dict{String, Any}("value" => nothing),
			"array" => Any[1, nothing],
		)
		@test _atomic_toml(path, payload) == path
		parsed = TOML.parsefile(path)
		@test parsed["native"]["value"] == 2.5
		@test parsed["optional"]["value"] == CAMPAIGN_TOML_MISSING
		@test parsed["array"] == Any[1, CAMPAIGN_TOML_MISSING]
	end
end
