using Test

function result_value_by_name(dict_like, name::AbstractString)
    for (k, v) in dict_like
        string(k) == name && return v
    end
    error("Entry $(name) not found")
end

function result_name_set(values_iter)
    return Set(string.(collect(values_iter)))
end

function oracle_max_param_error(pep, result)
    unident = Set(string.(collect(result.all_unidentifiable)))
    rel_errors = Float64[]
    for (param, true_value) in pep.p_true
        string(param) in unident && continue
        haskey(result.parameters, param) || continue
        denom = max(abs(Float64(true_value)), 1e-6)
        push!(rel_errors, abs(Float64(result.parameters[param]) - Float64(true_value)) / denom)
    end
    return isempty(rel_errors) ? Inf : maximum(rel_errors)
end

@testset "Identifiability regressions" begin
    @testset "substring-heavy parameter names still recover accurately" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.substr_test, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test analysis[2] < 1e-8
        @test isempty(best.all_unidentifiable)
        @test result_value_by_name(best.parameters, "a") ≈ pep.p_true[first(keys(pep.p_true))] atol = 1e-8 rtol = 1e-8
        @test result_value_by_name(best.parameters, "b") ≈ pep.p_true[collect(keys(pep.p_true))[2]] atol = 1e-8 rtol = 1e-8
        @test result_value_by_name(best.parameters, "beta") ≈ pep.p_true[collect(keys(pep.p_true))[3]] atol = 1e-6 rtol = 1e-6
    end

    @testset "global unidentifiable states and parameters are surfaced together" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.global_unident_test, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test isfinite(analysis[2])
        @test analysis[2] < 0.35
        @test result_name_set(best.all_unidentifiable) == Set(["b", "c", "d", "x3(t)"])
        @test result_value_by_name(best.parameters, "a") ≈ pep.p_true[first(keys(pep.p_true))] atol = 1e-8 rtol = 1e-8
    end

    @testset "summed-observation unidentifiability stays explicit" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.sum_test, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test isfinite(analysis[2])
        @test analysis[2] < 0.2
        @test result_name_set(best.all_unidentifiable) == Set(["c", "x1(t)", "x2(t)"])
        @test result_name_set(keys(best.provenance.structural_fix_set)) == Set(["c"])
        @test isempty(best.provenance.residual_fix_set)
        @test best.provenance.template_status_before_residual_fix == :determined
        @test best.provenance.template_status_after_residual_fix == :determined
        @test best.provenance.practical_identifiability_status == :not_assessed
        @test any(
            isapprox(result_value_by_name(result.parameters, "a"), pep.p_true[first(keys(pep.p_true))]; atol = 1e-6, rtol = 1e-6) &&
            isapprox(result_value_by_name(result.parameters, "b"), pep.p_true[collect(keys(pep.p_true))[2]]; atol = 1e-6, rtol = 1e-6)
            for result in analysis[1]
        )
        @test oracle_max_param_error(pep, best) ≈ minimum(oracle_max_param_error(pep, result) for result in analysis[1]) atol = 1e-10 rtol = 1e-10
    end
end
