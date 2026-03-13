using Test

const EXAMPLES_ROOT_EXTENDED = joinpath(@__DIR__, "..", "src", "examples")

function include_example_extended(parts...)
    return Base.include(Main, joinpath(EXAMPLES_ROOT_EXTENDED, parts...))
end

@testset "Extended example smoke tests" begin
    include_example_extended("first_example.jl")
    include_example_extended("control_investigations", "03_tank_constant_vs_driven.jl")
    include_example_extended("control_investigations", "04_oscillator_input_polynomialized.jl")
    include_example_extended("control_investigations", "05_comparing_approaches.jl")
    include_example_extended("biohydrogenation", "biohydrogenation_example.jl")
    include_example_extended("biohydrogenation", "biohydrogenation_example_with_options.jl")

    @testset "first example smoke" begin
        result = quiet_call() do
            run_first_example(smoke = true)
        end
        @test !isempty(result[1][1])
        @test !isempty(result[2][1])
        @test result[2][2] <= 1e-6
    end

    @testset "tank comparison remains a loaded limitation demo" begin
        @test isdefined(Main, :run_tank_comparison)
    end

    @testset "polynomialization demo smoke" begin
        results = quiet_call() do
            run_polynomialization_demo(smoke = true)
        end
        @test isfinite(results.driven[2][2])
        @test isfinite(results.poly[2][2])
        @test isfinite(results.poly_known[2][2])
    end

    @testset "comprehensive comparison smoke" begin
        results = quiet_call() do
            run_comprehensive_comparison(smoke = true)
        end
        for key in ("constant", "driven", "poly", "poly_known")
            @test isfinite(results[key][2][2])
        end
    end

    @testset "biohydrogenation options smoke" begin
        @test isdefined(Main, :run_biohydrogenation_example)
        @test isdefined(Main, :run_biohydrogenation_example_with_options)
    end
end
