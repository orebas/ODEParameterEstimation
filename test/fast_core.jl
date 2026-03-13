using Test
using ModelingToolkit
using OrderedCollections

@testset "Fast Core Contracts" begin
    @testset "Ordered ODE construction" begin
        @independent_variables t
        @parameters a b
        @variables x1(t) x2(t) y1(t) y2(t)
        D = Differential(t)

        eqs = [
            D(x1) ~ -a * x2,
            D(x2) ~ b * x1,
        ]
        states = [x1, x2]
        params = [a, b]
        measured_quantities = [y1 ~ x1, y2 ~ x2]

        ordered_system, mq = ODEParameterEstimation.create_ordered_ode_system(
            "TestSystem", states, params, eqs, measured_quantities,
        )
        time_var, equations, state_vars, parameters = ODEParameterEstimation.unpack_ODE(ordered_system.system)

        @test ordered_system isa ODEParameterEstimation.OrderedODESystem
        @test mq == measured_quantities
        @test isequal(time_var, t)
        @test length(equations) == 2
        @test string.(state_vars) == string.(states)
        @test string.(parameters) == string.(params)
        @test string.(ordered_system.original_parameters) == string.(params)
        @test string.(ordered_system.original_states) == string.(states)
    end

    @testset "Option helpers" begin
        base = EstimationOptions(
            flow = FlowStandard,
            interpolator = InterpolatorAAAD,
            shooting_points = 3,
            save_system = false,
        )
        merged = ODEParameterEstimation.merge_options(
            base;
            shooting_points = 2,
            interpolators = [InterpolatorAGPRobust, InterpolatorS3SE],
            terminal_fallback = :direct_opt,
            backsolve_recovery = :algebraic_resolve,
            t0_state_completion = :strict,
        )

        @test merged.flow == FlowStandard
        @test merged.shooting_points == 2
        @test ODEParameterEstimation.validate_options(merged)

        resolved = ODEParameterEstimation.resolve_interpolator_list(merged)
        @test length(resolved) == 2
        @test first.(resolved) == [InterpolatorAGPRobust, InterpolatorS3SE]

        @test ODEParameterEstimation.compute_shooting_indices(0, 21) == [10]
        @test ODEParameterEstimation.compute_shooting_indices(3, 21; warp = false) == [1, 11, 21]
        @test merged.terminal_fallback == :direct_opt
        @test merged.backsolve_recovery == :algebraic_resolve
        @test merged.t0_state_completion == :strict

        @test instances(EstimationFlow) == (FlowStandard, FlowDirectOpt)
        @test !isdefined(ODEParameterEstimation, :FlowDeprecated)
        @test !isdefined(ODEParameterEstimation, :multipoint_parameter_estimation)
        @test !isdefined(ODEParameterEstimation, :multishot_parameter_estimation)

        @test_throws MethodError EstimationOptions(try_more_methods = true)
        @test_throws ErrorException ODEParameterEstimation.merge_options(base; try_more_methods = true)

        invalid_terminal_fallback = EstimationOptions(
            flow = FlowDirectOpt,
            terminal_fallback = :direct_opt,
        )
        @test !ODEParameterEstimation.validate_options(invalid_terminal_fallback)

        invalid_seed_policy = EstimationOptions(t0_state_completion = :maybe)
        @test !ODEParameterEstimation.validate_options(invalid_seed_policy)

        invalid_uq_policy = EstimationOptions(uq_failure_policy = :maybe)
        @test !ODEParameterEstimation.validate_options(invalid_uq_policy)

        @test_throws ErrorException ODEParameterEstimation.merge_options(base; definitely_not_an_option = true)
    end

    @testset "UQ policy helper" begin
        failed_uq = (
            success = false,
            message = "synthetic failure",
        )

        passthrough_opts = EstimationOptions(uq_failure_policy = :return_failed)
        throw_opts = EstimationOptions(uq_failure_policy = :throw)

        @test ODEParameterEstimation.apply_uq_failure_policy(failed_uq, passthrough_opts) === failed_uq
        @test_throws ErrorException ODEParameterEstimation.apply_uq_failure_policy(failed_uq, throw_opts)
    end

    @testset "Math helpers" begin
        @test ODEParameterEstimation.count_turns([1, 2, 3, 4, 5]) == 0
        @test ODEParameterEstimation.count_turns([1, 3, 2, 1]) == 1

        stats = ODEParameterEstimation.calculate_timeseries_stats([1.0, 3.0, 2.0, 4.0, 2.0])
        @test stats.mean ≈ 2.4
        @test stats.turns == 3

        valid_points, valid_params, dropped = ODEParameterEstimation.filter_finite_shooting_point_params(
            [1, 5, 9],
            [
                [1.0, 2.0],
                [NaN, 3.0],
                [4.0, Inf],
            ],
        )
        @test valid_points == [1]
        @test valid_params == [[1.0, 2.0]]
        @test dropped == [(5, 1), (9, 1)]
    end

    @testset "Result compatibility helpers" begin
        @parameters a
        @variables t x(t)

        result = ODEParameterEstimation.ParameterEstimationResult(
            OrderedDict(a => 1.0),
            OrderedDict(x => 2.0),
            0.0,
            1e-6,
            nothing,
            10,
            nothing,
            OrderedDict{Num, Float64}(),
            Set{Num}(),
            nothing,
        )
        result.provenance = ODEParameterEstimation.ResultProvenance(
            primary_method = :direct_opt,
            rescue_path = :direct_opt_fallback,
            interpolator_source = :aaad,
            source_shooting_index = 3,
            source_candidate_index = 7,
            polish_applied = true,
        )

        ODEParameterEstimation.sync_result_contract!(result)

        @test result.return_code == :direct_opt_fallback
        @test result.interpolator_source == :aaad
        @test ODEParameterEstimation.compatibility_return_code(result.provenance) == :direct_opt_fallback
        @test occursin("method=direct_opt", ODEParameterEstimation.lineage_summary(result))
        @test occursin("rescue=direct_opt_fallback", ODEParameterEstimation.lineage_summary(result))
    end
end
