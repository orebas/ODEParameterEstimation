using Test
using Logging

function quiet_call(f)
    redirect_stdout(devnull) do
        redirect_stderr(devnull) do
            with_logger(NullLogger()) do
                return f()
            end
        end
    end
end

function run_canary(ctor, opts)
    pep = ctor()
    sampled = ODEParameterEstimation.sample_problem_data(pep, opts)
    raw_results, analysis, uq = quiet_call() do
        ODEParameterEstimation.analyze_parameter_estimation_problem(sampled, opts)
    end
    return pep, raw_results, analysis, uq
end

function best_cluster_solution(analysis)
    isempty(analysis[1]) && return nothing
    return first(analysis[1])
end

function state_has_transformed_input(result)
    any(contains(string(state), "_trfn_") for state in keys(result.states))
end

const FAST_STANDARD_OPTS = EstimationOptions(
    datasize = 21,
    noise_level = 0.0,
    shooting_points = 0,
    nooutput = true,
    diagnostics = false,
    flow = FlowStandard,
    use_si_template = true,
    use_parameter_homotopy = false,
    interpolator = InterpolatorAAAD,
    save_system = false,
    polish_solver_solutions = false,
    polish_solutions = false,
)

const FAST_DIRECT_OPTS = EstimationOptions(
    datasize = 21,
    noise_level = 0.0,
    nooutput = true,
    diagnostics = false,
    flow = FlowDirectOpt,
    opt_maxiters = 5000,
    save_system = false,
)

@testset "Example canaries" begin
    @testset "simple recovers parameters" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.simple, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test analysis[2] < 1e-6

        for (param, true_value) in pep.p_true
            @test best.parameters[param] ≈ true_value atol = 1e-6 rtol = 1e-6
        end
    end

    @testset "lotka-volterra has an accurate solution cluster" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.lotka_volterra, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test analysis[2] < 1e-5

        for (param, true_value) in pep.p_true
            @test best.parameters[param] ≈ true_value atol = 1e-5 rtol = 1e-5
        end
    end

    @testset "trivial unidentifiability is surfaced" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.trivial_unident, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test analysis[2] < 1e-6
        @test !isempty(best.all_unidentifiable)
        @test Set(best.all_unidentifiable) == Set(keys(pep.p_true))
        @test !isempty(best.provenance.representative_assignments)
    end

    @testset "measured-quantity linear combinations stay identifiable" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.simple_linear_combination, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test analysis[2] < 1e-8

        for (param, true_value) in pep.p_true
            @test best.parameters[param] ≈ true_value atol = 1e-8 rtol = 1e-8
        end
    end

    @testset "nonlinear observable stays estimable" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.onesp_cubed, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test analysis[2] < 1e-10

        for (param, true_value) in pep.p_true
            @test best.parameters[param] ≈ true_value atol = 1e-10 rtol = 1e-10
        end
    end

    @testset "multiple nonlinear observables stay estimable" begin
        pep, raw_results, analysis, _ = run_canary(ODEParameterEstimation.threesp_cubed, FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test analysis[2] < 1e-10

        for (param, true_value) in pep.p_true
            @test best.parameters[param] ≈ true_value atol = 1e-10 rtol = 1e-10
        end
    end

    @testset "transcendental input path stays alive" begin
        pep, raw_results, analysis, _ = run_canary(getfield(ODEParameterEstimation, :dc_motor_sinusoidal), FAST_STANDARD_OPTS)
        best = best_cluster_solution(analysis)

        @test pep.name == "dc_motor_sinusoidal"
        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test isfinite(analysis[2])
        @test state_has_transformed_input(best)
        @test !isempty(best.all_unidentifiable)
    end

    @testset "direct optimization smoke test" begin
        _, raw_results, analysis, _ = run_canary(ODEParameterEstimation.simple_linear_combination, FAST_DIRECT_OPTS)
        best = best_cluster_solution(analysis)

        @test !isempty(raw_results[1])
        @test !isnothing(best)
        @test isfinite(analysis[2])
        @test best.provenance.primary_method == :direct_opt
        @test best.provenance.polish_applied
        @test best.return_code == :direct_opt
    end
end
