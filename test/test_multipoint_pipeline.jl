# Regression test: multipoint through the full estimation pipeline
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("test/test_multipoint_pipeline.jl")'

using ODEParameterEstimation
using Test

function flatten_r(x)
    out = ParameterEstimationResult[]
    x isa ParameterEstimationResult && (push!(out, x); return out)
    x isa Tuple && (for i in x; append!(out, flatten_r(i)); end; return out)
    x isa Vector && (for i in x; append!(out, flatten_r(i)); end; return out)
    out
end

@testset "Multipoint Pipeline" begin
    pep = ODEParameterEstimation.lotka_volterra()
    pep_data = ODEParameterEstimation.sample_problem_data(pep,
        EstimationOptions(datasize = 201, noise_level = 0.0, nooutput = true))

    # Single-point baseline
    raw_sp = analyze_parameter_estimation_problem(pep_data,
        EstimationOptions(datasize = 201, noise_level = 0.0, nooutput = true))
    results_sp = flatten_r(raw_sp)

    # With multipoint (N=2, both paths run)
    raw_mp = analyze_parameter_estimation_problem(pep_data,
        EstimationOptions(use_multipoint = true, multipoint_n_points = 2,
            multipoint_max_pairs = 10, datasize = 201, noise_level = 0.0, nooutput = true))
    results_mp = flatten_r(raw_mp)

    # Multipoint should produce MORE results (SP solutions + MP solutions merged)
    @test length(results_mp) > length(results_sp)

    # Both should produce valid results with finite errors
    errs_sp = [r.err for r in results_sp if !isnothing(r.err) && isfinite(r.err)]
    errs_mp = [r.err for r in results_mp if !isnothing(r.err) && isfinite(r.err)]
    @test !isempty(errs_sp)
    @test !isempty(errs_mp)

    # Multipoint best error should be no worse than 10x single-point
    # (in practice it's equal or better)
    @test minimum(errs_mp) <= minimum(errs_sp) * 10
end
