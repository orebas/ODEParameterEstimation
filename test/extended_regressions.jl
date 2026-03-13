using Test

function extended_value_by_name(dict_like, name::AbstractString)
    for (k, v) in dict_like
        string(k) == name && return v
    end
    error("Entry $(name) not found")
end

function extended_name_set(values_iter)
    return Set(string.(collect(values_iter)))
end

@testset "Extended regressions" begin
    @testset "treatment keeps structurally unidentifiable variables explicit" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.treatment, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test isfinite(analysis[2])
        @test analysis[2] < 1e-3
        @test extended_name_set(best.all_unidentifiable) == Set(["a", "b", "d", "g", "In(t)", "S(t)"])
        @test extended_value_by_name(best.parameters, "nu") ≈ extended_value_by_name(pep.p_true, "nu") atol = 1e-4 rtol = 1e-4
    end

    @testset "biohydrogenation keeps the hidden product state marked unidentifiable" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.biohydrogenation, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test isfinite(analysis[2])
        @test analysis[2] < 1e-3
        @test extended_name_set(best.all_unidentifiable) == Set(["x7(t)"])
        @test all(
            assigned_var -> string(assigned_var) in extended_name_set(best.all_unidentifiable),
            keys(best.provenance.representative_assignments),
        )
        for param_name in ("k5", "k6")
            @test extended_value_by_name(best.parameters, param_name) ≈ extended_value_by_name(pep.p_true, param_name) atol = 5e-4 rtol = 5e-4
        end
    end
end
