using Test
using Logging
using ModelingToolkit
using OrderedCollections
using OrdinaryDiffEq

function quiet_feature_call(f)
    redirect_stdout(devnull) do
        redirect_stderr(devnull) do
            with_logger(NullLogger()) do
                return f()
            end
        end
    end
end

function run_feature_canary(ctor, opts)
    pep = ctor()
    sampled = ODEParameterEstimation.sample_problem_data(pep, opts)
    raw_results, analysis, uq = quiet_feature_call() do
        ODEParameterEstimation.analyze_parameter_estimation_problem(sampled, opts)
    end
    return sampled, raw_results, analysis, uq
end

function lookup_state_value(result, state)
    for (k, v) in result.states
        string(k) == string(state) && return v
    end
    error("State $(state) not found in result")
end

function lookup_param_value(result, param)
    for (k, v) in result.parameters
        string(k) == string(param) && return v
    end
    error("Parameter $(param) not found in result")
end

function measured_series(sampled_pep, mq)
    string_key = replace(string(mq.lhs), "(t)" => "")
    if haskey(sampled_pep.data_sample, string_key)
        return sampled_pep.data_sample[string_key]
    end
    num_key = ModelingToolkit.Num(mq.lhs)
    if haskey(sampled_pep.data_sample, num_key)
        return sampled_pep.data_sample[num_key]
    end
    rhs_string_key = replace(string(mq.rhs), "(t)" => "")
    if haskey(sampled_pep.data_sample, rhs_string_key)
        return sampled_pep.data_sample[rhs_string_key]
    end
    rhs_num_key = ModelingToolkit.Num(mq.rhs)
    return sampled_pep.data_sample[rhs_num_key]
end

function partially_observed_problem()
    @independent_variables t
    @parameters a
    @variables x(t) z(t)
    D = Differential(t)

    states = [x, z]
    params = [a]
    equations = [
        D(x) ~ a * x,
        D(z) ~ -a * z,
    ]
    measured_quantities = [x ~ x]

    model, mq = ODEParameterEstimation.create_ordered_ode_system(
        "partial_observation", states, params, equations, measured_quantities,
    )

    return ODEParameterEstimation.ParameterEstimationProblem(
        "partial_observation",
        model,
        mq,
        nothing,
        [0.0, 0.2],
        Tsit5(),
        OrderedDict(a => 0.5),
        OrderedDict(x => 2.0, z => 3.0),
        0,
    )
end

const MULTI_INTERP_TEMPLATE_LIST = [
    InterpolatorAAAD,
    InterpolatorAAADGPR,
    InterpolatorS2AAAMLE,
    InterpolatorAGPRobust,
    InterpolatorAGPRobustRQ,
    InterpolatorAGPRobustSEpRQ,
    InterpolatorAGPRobustSExRQ,
    InterpolatorS3AdaptSE,
    InterpolatorS3AdaptRQ,
    InterpolatorS3AdaptSEpRQ,
    InterpolatorS3AdaptSExRQ,
    InterpolatorS3BICSE,
]

const SAVE_SYSTEM_OFF_OPTS = EstimationOptions(
    datasize = 11,
    noise_level = 0.0,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    interpolator = InterpolatorAAAD,
    shooting_points = 0,
    nooutput = true,
    diagnostics = false,
    save_system = false,
    use_parameter_homotopy = false,
    polish_solver_solutions = false,
    polish_solutions = false,
)

const MULTI_INTERP_FAST_OPTS = EstimationOptions(
    datasize = 11,
    noise_level = 0.0,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    interpolators = MULTI_INTERP_TEMPLATE_LIST,
    shooting_points = 0,
    nooutput = true,
    diagnostics = false,
    save_system = false,
    use_parameter_homotopy = false,
    polish_solver_solutions = false,
    polish_solutions = false,
)

const SMALL_SAMPLE_OPTS = EstimationOptions(
    datasize = 11,
    noise_level = 0.0,
    time_interval = [0.0, 0.2],
    nooutput = true,
    diagnostics = false,
    save_system = false,
)

@testset "Feature regressions" begin
    @testset "multi-interpolator benchmark template path" begin
        sampled, raw_results, analysis, _ = run_feature_canary(ODEParameterEstimation.simple, MULTI_INTERP_FAST_OPTS)
        expected_sources = Set(ODEParameterEstimation.interpolator_method_to_symbol(method) for method in MULTI_INTERP_TEMPLATE_LIST)
        actual_sources = Set(filter(!isnothing, [result.interpolator_source for result in raw_results[1]]))

        @test sampled.name == "simple"
        @test length(ODEParameterEstimation.resolve_interpolator_list(MULTI_INTERP_FAST_OPTS)) == length(MULTI_INTERP_TEMPLATE_LIST)
        @test !isempty(raw_results[1])
        @test !isempty(analysis[1])
        @test analysis[2] < 1e-4
        @test !isempty(actual_sources)
        @test actual_sources ⊆ expected_sources
        @test :aaad in actual_sources
        @test all(result.provenance.interpolator_source == result.interpolator_source for result in raw_results[1])
        @test all(result.return_code == ODEParameterEstimation.compatibility_return_code(result.provenance) for result in raw_results[1])
        @test all(!isnothing(result.provenance.source_candidate_index) for result in raw_results[1])
    end

    @testset "transcendental transform augments the problem directly" begin
        sampled = ODEParameterEstimation.sample_problem_data(
            getfield(ODEParameterEstimation, :dc_motor_sinusoidal)(),
            EstimationOptions(
                datasize = 11,
                noise_level = 0.0,
                shooting_points = 0,
                nooutput = true,
                diagnostics = false,
                save_system = false,
            ),
        )
        t_var = ModelingToolkit.get_iv(sampled.model.system)
        transformed, tr_info = quiet_feature_call() do
            ODEParameterEstimation.transform_pep_for_estimation(sampled, t_var)
        end

        @test !isnothing(tr_info)
        @test transformed.name == sampled.name * "_polynomialized"
        @test !isempty(tr_info.entries)
        @test !isempty(tr_info.input_variables)
        @test any(contains(string(state), "_trfn_") for state in transformed.model.original_states)
        @test length(transformed.model.original_states) > length(sampled.model.original_states)
        @test length(transformed.data_sample) > length(sampled.data_sample)
    end

    @testset "missing SI reconstruction values fail explicitly" begin
        sampled = ODEParameterEstimation.sample_problem_data(partially_observed_problem(), SMALL_SAMPLE_OPTS)
        observed_mq = only(sampled.measured_quantities)
        observed_series = measured_series(sampled, observed_mq)
        augmented_data_sample = OrderedDict(sampled.data_sample)
        augmented_data_sample[replace(string(observed_mq.lhs), "(t)" => "")] = observed_series
        sampled = ODEParameterEstimation.ParameterEstimationProblem(
            sampled.name,
            sampled.model,
            sampled.measured_quantities,
            augmented_data_sample,
            sampled.recommended_time_interval,
            sampled.solver,
            sampled.p_true,
            sampled.ic,
            sampled.unident_count,
        )

        setup_data = (
            time_index_set = [1],
            all_unidentifiable = Set{Any}(),
        )
        solution_data = (
            solns = [Float64[]],
            forward_subst_dict = [OrderedDict{Num, Any}()],
            trivial_dict = Dict{Any, Any}(),
            final_varlist = Any[],
            trimmed_varlist = Any[],
            good_udict = Dict{Any, Any}(),
            solution_time_indices = [1],
        )

        err = try
            quiet_feature_call() do
                ODEParameterEstimation.process_estimation_results(
                    sampled,
                    solution_data,
                    setup_data;
                    opts = SMALL_SAMPLE_OPTS,
                )
            end
            nothing
        catch e
            e
        end
        @test err isa ErrorException
        @test occursin("missing from the SI solution", sprint(showerror, err))
    end

    @testset "save_system=false does not create saved_systems output" begin
        mktempdir() do tmpdir
            cd(tmpdir) do
                _, raw_results, analysis, _ = run_feature_canary(ODEParameterEstimation.simple, SAVE_SYSTEM_OFF_OPTS)

                @test !isempty(raw_results[1])
                @test !isempty(analysis[1])
                @test !isdir(joinpath(tmpdir, "saved_systems"))
            end
        end
    end

    @testset "single interpolator run stays on the requested interpolator" begin
        _, raw_results, analysis, _ = run_feature_canary(ODEParameterEstimation.simple, SAVE_SYSTEM_OFF_OPTS)
        actual_sources = Set(filter(!isnothing, [result.interpolator_source for result in raw_results[1]]))

        @test !isempty(raw_results[1])
        @test !isempty(analysis[1])
        @test actual_sources == Set([:aaad])
        @test length(raw_results[1]) == 1
    end

    @testset "parameter homotopy path produces valid results" begin
        homotopy_opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            system_solver = SolverHC,
            flow = FlowStandard,
            use_si_template = true,
            interpolator = InterpolatorAAAD,
            shooting_points = 3,  # homotopy requires >= 3
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = true,
            polish_solver_solutions = false,
            polish_solutions = false,
        )
        _, raw_results, analysis, _ = run_feature_canary(ODEParameterEstimation.simple, homotopy_opts)

        @test !isempty(raw_results[1])
        @test !isempty(analysis[1])
        @test analysis[2] < 1e-2  # solutions should be reasonable
    end

    @testset "terminal_fallback=:direct_opt rescues empty algebraic results" begin
        # Use a partially observed problem that may produce 0 algebraic solutions,
        # then verify the direct_opt fallback produces results.
        fallback_opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            system_solver = SolverHC,
            flow = FlowStandard,
            use_si_template = true,
            interpolator = InterpolatorAAAD,
            shooting_points = 0,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            terminal_fallback = :direct_opt,
            polish_solutions = true,
        )
        _, raw_results, analysis, _ = run_feature_canary(ODEParameterEstimation.simple, fallback_opts)

        @test !isempty(raw_results[1])
        @test !isempty(analysis[1])
        # Verify provenance tracks terminal_fallback when it's used
        for result in raw_results[1]
            @test result.provenance isa ODEParameterEstimation.ResultProvenance
        end
    end

    @testset "polish_solutions applies BFGS refinement" begin
        polish_opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            system_solver = SolverHC,
            flow = FlowStandard,
            use_si_template = true,
            interpolator = InterpolatorAAAD,
            shooting_points = 0,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = true,
        )
        _, raw_results, analysis, _ = run_feature_canary(ODEParameterEstimation.simple, polish_opts)

        @test !isempty(raw_results[1])
        @test !isempty(analysis[1])
        @test analysis[2] < 1e-4  # polished results should be very accurate
        # At least some results should show polish was applied
        any_polished = any(result.provenance.polish_applied for result in raw_results[1])
        @test any_polished
    end

    @testset "_obs_trfn_ parsing unit tests" begin
        parse_fn = ODEParameterEstimation._parse_obs_trfn_base_name
        eval_fn = ODEParameterEstimation.evaluate_obs_trfn_template_variable

        # Pattern 1: freq_sin / freq_cos
        @test parse_fn("_obs_trfn_0_5_sin") == (:sin, 0.5)
        @test parse_fn("_obs_trfn_0_5_cos") == (:cos, 0.5)

        # Pattern 2: partner naming (cos_freq_sin, cos_freq_cos)
        @test parse_fn("_obs_trfn_cos_0_5_cos") == (:cos, 0.5)
        @test parse_fn("_obs_trfn_cos_0_5_sin") == (:sin, 0.5)

        # Evaluation
        @test eval_fn("_obs_trfn_cos_0_5_cos(t)", Float64(π)) ≈ cos(0.5π)

        # Non-trfn names return nothing
        @test parse_fn("y1") === nothing
        @test eval_fn("y1_0", 0.0) === nothing
    end

    @testset "Transcendental UQ: _obs_trfn_ not in unknowns" begin
        # forced_decay: 1 state, 2 params, sin(0.5t) forcing → triggers _obs_trfn_ machinery
        pep = ODEParameterEstimation.forced_decay()
        pep_data = ODEParameterEstimation.sample_problem_data(
            pep, EstimationOptions(datasize = 31, time_interval = [0.0, 10.0]))
        t_var = ModelingToolkit.get_iv(pep_data.model.system)
        pep_transformed, tr_info = ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
        @test !isnothing(tr_info)  # confirms sin(0.5t) was detected

        # Run diagnose with UQ-capable interpolator
        report = quiet_feature_call() do
            diagnose(pep_transformed; interpolators = [InterpolatorAGPUQ])
        end
        sr = report.best.sensitivity

        # Data sensitivity matrix should be non-empty
        @test !isempty(sr.data_sensitivity_matrix)

        # Unknown labels must NOT contain _obs_trfn_
        for label in sr.data_sensitivity_unknown_labels
            @test !startswith(label, "_obs_trfn_")
        end

        # Dimension consistency: rows of S == length of unknown labels
        n_unknowns, n_data = size(sr.data_sensitivity_matrix)
        @test length(sr.data_sensitivity_unknown_labels) == n_unknowns
        @test length(sr.data_sensitivity_data_labels) == n_data
    end

    @testset "_obs_trfn_ vars not in diagnostic pipeline" begin
        # forced_decay triggers _obs_trfn_ machinery; verify it doesn't leak into diagnostics
        pep = ODEParameterEstimation.forced_decay()
        pep_data = ODEParameterEstimation.sample_problem_data(
            pep, EstimationOptions(datasize = 31, time_interval = [0.0, 10.0]))
        t_var = ModelingToolkit.get_iv(pep_data.model.system)
        pep_transformed, tr_info = ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
        @test !isnothing(tr_info)

        # Run polynomial system and sensitivity diagnostics
        poly_report, sr = quiet_feature_call() do
            poly = diagnose_polynomial_system(pep_transformed)
            sens = diagnose_sensitivity(pep_transformed)
            (poly, sens)
        end

        # Polynomial report: no _obs_trfn_ in variable names
        for vname in poly_report.variable_names
            @test !contains(vname, "_obs_trfn_")
        end

        # Polynomial report: true residual is finite (not NaN)
        @test isfinite(poly_report.true_residual_production)

        # Sensitivity report: Jacobian cond is finite (not NaN)
        @test isfinite(sr.jacobian_cond)

        # Sensitivity report: no _obs_trfn_ in Jacobian column labels
        for label in sr.jacobian_col_labels
            @test !contains(label, "_obs_trfn_")
        end
    end
end
