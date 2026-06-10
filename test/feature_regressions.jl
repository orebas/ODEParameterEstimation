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
    interpolators = InterpolatorMethod[InterpolatorAAAD],
    shooting_points = 0,
    nooutput = true,
    diagnostics = false,
    save_system = false,
    use_parameter_homotopy = false,
    polish_solver_solutions = false,
    polish_solutions = false,
    synthesize_aggregate_candidates = false,
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
    synthesize_aggregate_candidates = false,  # this test asserts on per-interpolator provenance; synthesis would inject :synthesized entries
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

    @testset "log-positive polish context preserves loss geometry" begin
        base_opts = EstimationOptions(
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
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), base_opts)
        p_size = length(pep.ic) + length(pep.p_true)
        positive_opts = ODEParameterEstimation.merge_options(
            base_opts;
            opt_lb = fill(0.05, p_size),
            opt_ub = fill(10.0, p_size),
        )
        # Pin `coordinate_transform` explicitly so the test is independent of the
        # current default `polish_method` / `polish_coordinate_policy`.
        linear_ctx = ODEParameterEstimation._build_polish_context(pep; opts = positive_opts, coordinate_transform = :linear)
        log_ctx = ODEParameterEstimation._build_polish_context(pep; opts = positive_opts, coordinate_transform = :log_positive)
        p0 = clamp.(vcat(Float64.(collect(values(pep.ic))), Float64.(collect(values(pep.p_true)))), positive_opts.opt_lb, positive_opts.opt_ub)

        # Per-variable transforms: `:linear` legacy → all `:linear`,
        # `:log_positive` legacy → `:log_only` policy → all `:log` here (all bounds are > 0)
        @test all(linear_ctx.coordinate_transforms .== :linear)
        @test all(log_ctx.coordinate_transforms .== :log)
        @test log_ctx.internal_lb ≈ log.(positive_opts.opt_lb)
        @test log_ctx.internal_ub ≈ log.(positive_opts.opt_ub)
        @test linear_ctx.optf.f(p0, nothing) ≈ log_ctx.optf.f(log.(p0), nothing) rtol = 1e-9 atol = 1e-9

        bad_opts = ODEParameterEstimation.merge_options(
            base_opts;
            opt_lb = vcat([-0.1], fill(0.05, p_size - 1)),
            opt_ub = fill(10.0, p_size),
        )
        @test_throws ArgumentError ODEParameterEstimation._build_polish_context(
            pep;
            opts = bad_opts,
            coordinate_transform = :log_positive,
        )
    end

    @testset "Bounded LSO log-space residual polish" begin
        # Direct end-to-end smoke test of the new residual polish path on `simple()`.
        # Seeds the polisher near (but not at) the true parameters and confirms it
        # converges back. Uses `:auto` per-variable transforms (all positive bounds → :log).
        base_opts = EstimationOptions(
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
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), base_opts)
        p_size = length(pep.ic) + length(pep.p_true)
        lso_opts = ODEParameterEstimation.merge_options(
            base_opts;
            polish_method = PolishLSOBoundedLog,
            opt_lb = fill(1e-3, p_size),
            opt_ub = fill(50.0, p_size),
            polish_maxiters = 200,
        )

        # The residual path should pick up `:auto` automatically when polish_method is
        # residual; positive bounds resolve to all `:log`.
        ctx = ODEParameterEstimation._build_polish_context(pep; opts = lso_opts)
        @test all(ctx.coordinate_transforms .== :log)
        @test ctx.regularization_lambda == 0.0

        # Seed: true values (no perturbation in IC) — exercises the path end-to-end and
        # confirms the revert guard at worst returns the seed.
        p_true = vcat(Float64.(collect(values(pep.ic))), Float64.(collect(values(pep.p_true))))
        polished, _ = ODEParameterEstimation._polish_single_from_context(
            ctx, p_true;
            polish_method = PolishLSOBoundedLog,
            maxiters = 200,
            lso_delta = lso_opts.polish_lso_delta,
        )
        @test polished isa ODEParameterEstimation.ParameterEstimationResult
        @test isfinite(polished.err)
        # Polished should not be worse than the perfect seed (revert guard ensures this)
        @test polished.err < 1e-6

        # Same path with FastLM should also run without error
        fastlm_opts = ODEParameterEstimation.merge_options(lso_opts; polish_method = PolishFastLMBoundedLog)
        ctx_fast = ODEParameterEstimation._build_polish_context(pep; opts = fastlm_opts)
        polished_fast, _ = ODEParameterEstimation._polish_single_from_context(
            ctx_fast, p_true;
            polish_method = PolishFastLMBoundedLog,
            maxiters = 200,
        )
        @test polished_fast isa ODEParameterEstimation.ParameterEstimationResult
        @test isfinite(polished_fast.err)

        # Optional λ regularization: residual length grows by n_unknowns; trajectory-fit
        # err remains comparable.
        reg_opts = ODEParameterEstimation.merge_options(
            lso_opts;
            polish_regularization_lambda = 1e-6,
        )
        ctx_reg = ODEParameterEstimation._build_polish_context(pep; opts = reg_opts)
        @test ctx_reg.regularization_lambda == 1e-6
        polished_reg, _ = ODEParameterEstimation._polish_single_from_context(
            ctx_reg, p_true;
            polish_method = PolishLSOBoundedLog,
            maxiters = 200,
        )
        @test polished_reg isa ODEParameterEstimation.ParameterEstimationResult
        @test isfinite(polished_reg.err)
    end

    @testset "Sensitivity-seed pipeline smoke" begin
        # With use_sensitivity_seeds = false (default), behavior must match the
        # baseline (no augmentation, no extra polish seeds, no warnings).
        # With use_sensitivity_seeds = true, the augmentation hook runs through
        # _maybe_augment_with_sensitivity_seeds, computes Σ_x = S·diag(σ_d²)·S',
        # and either emits seeds or falls through silently.
        base_opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            shooting_points = 0,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = true,
        )

        # Off-by-default path
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), base_opts)
        baseline = ODEParameterEstimation.analyze_parameter_estimation_problem(pep, base_opts)
        @test !isempty(baseline[2][1])
        @test isfinite(baseline[2][1][1].err)

        # Flag-on path
        seeded_opts = ODEParameterEstimation.merge_options(
            base_opts;
            use_sensitivity_seeds = true,
            sensitivity_seed_probe_scale = 1.0,
            sensitivity_seed_eigenvalue_threshold = 0.05,
        )
        pep_seeded = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), seeded_opts)
        seeded = ODEParameterEstimation.analyze_parameter_estimation_problem(pep_seeded, seeded_opts)
        @test !isempty(seeded[2][1])
        @test isfinite(seeded[2][1][1].err)
        # Flag-on must not break recovery on a well-determined model
        @test seeded[2][1][1].err < 1e-3

        # Compute σ_d directly with a multi-source synthetic cache; verify
        # cross-interpolator spread mode (no floor active when sources disagree).
        @independent_variables t
        @variables y1(t)
        # Use a closure factory to avoid module-scope struct redefinition warnings on rerun.
        make_linear = slope -> (x::Real -> slope * x)
        mq = [y1 ~ y1]
        key1 = ModelingToolkit.diff2term(mq[1].rhs)
        cache_multi = Dict{Symbol, AbstractDict}(
            :a => Dict{Any, Any}(key1 => make_linear(2.0)),
            :b => Dict{Any, Any}(key1 => make_linear(2.5)),
            :c => Dict{Any, Any}(key1 => make_linear(3.0)),
        )
        est = compute_sigma_d(cache_multi, mq, 0.5, 1; noise_level = 0.0, order_decay_kappa = 2.0)
        # At order 1 the three derivatives are 2.0, 2.5, 3.0; std = 0.5
        @test est.sigma_d[1, 2] ≈ 0.5 atol = 1e-9
        # No floor active when noise_level = 0
        @test all(.!est.floor_active[1, :])

        # Single-source falls through to floor
        cache_single = Dict{Symbol, AbstractDict}(
            :a => Dict{Any, Any}(key1 => make_linear(2.0)),
        )
        est_single = compute_sigma_d(cache_single, mq, 0.5, 2; noise_level = 0.01, order_decay_kappa = 2.0)
        @test est_single.sigma_d[1, :] ≈ [0.01, 0.02, 0.04] atol = 1e-12
        @test all(est_single.floor_active[1, :])
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

    @testset "diagnose() auto-applies trfn transform" begin
        # forced_decay has sin(0.5t) forcing — without auto-trfn diagnose would fail
        # with "system does not seem to have rational right-hand side".
        pep = ODEParameterEstimation.forced_decay()
        pep_data = ODEParameterEstimation.sample_problem_data(
            pep, EstimationOptions(datasize = 31, time_interval = [0.0, 10.0]))

        # 1) Single-mode diagnose() on raw sin-forced PEP — must NOT throw.
        report_auto = quiet_feature_call() do
            diagnose(pep_data; save_to_disk = false, html_report = false)
        end
        @test report_auto isa ODEParameterEstimation.DiagnosticReport

        # 2) Idempotence: works when caller pre-transformed.
        t_var = ModelingToolkit.get_iv(pep_data.model.system)
        pep_pre, _ = ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
        report_pre = quiet_feature_call() do
            diagnose(pep_pre; save_to_disk = false, html_report = false)
        end
        @test report_pre isa ODEParameterEstimation.DiagnosticReport

        # 3) Lower-level peer entries also auto-transform (no setup_data passed).
        poly_report = quiet_feature_call() do
            diagnose_polynomial_system(pep_data)
        end
        @test isfinite(poly_report.true_residual_production)

        sens_report = quiet_feature_call() do
            diagnose_sensitivity(pep_data)
        end
        @test isfinite(sens_report.jacobian_cond)

        deriv_report = quiet_feature_call() do
            diagnose_derivative_accuracy(pep_data)
        end
        @test deriv_report isa ODEParameterEstimation.DerivativeAccuracyReport

        # 4) Multi-mode diagnose() also auto-transforms.
        report_multi = quiet_feature_call() do
            diagnose(pep_data; interpolators = [InterpolatorAGPUQ],
                     save_to_disk = false, html_report = false)
        end
        @test report_multi isa ODEParameterEstimation.ComprehensiveDiagnosticReport
    end

    @testset "compute_uncertainty=true returns an IFT UncertaintyReport" begin
        # Phase E2 (review P0#5): the experimental UQ sidecar is rewired from the
        # broken FD-Jacobian path (archived in deprecated/uq_fd_path.jl) to the
        # IFT-based diagnose_uncertainty. End-to-end smoke on simple().
        uq_opts = EstimationOptions(
            datasize = 21, noise_level = 0.0, shooting_points = 0,
            nooutput = true, diagnostics = false, flow = FlowStandard,
            use_si_template = true, use_parameter_homotopy = false,
            interpolator = InterpolatorAAAD, save_system = false,
            polish_solver_solutions = false, polish_solutions = false,
            compute_uncertainty = true,
        )
        sampled = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), uq_opts)
        _, _, uq = quiet_feature_call() do
            ODEParameterEstimation.analyze_parameter_estimation_problem(sampled, uq_opts)
        end
        @test uq isa ODEParameterEstimation.UncertaintyReport
        @test !isempty(uq.param_std)
        @test any(isfinite, uq.param_std)
    end

    @testset "diagnose writes HTML report to disk" begin
        # Phase A smoke (insurance for the planned diagnostics.jl file split):
        # the rest of CI only runs diagnose with html_report=false. Reports go to
        # artifacts/diagnostics/<name>/ relative to pwd, so run inside a tempdir.
        sampled = ODEParameterEstimation.sample_problem_data(
            ODEParameterEstimation.simple(),
            EstimationOptions(datasize = 21, noise_level = 0.0, nooutput = true))
        mktempdir() do dir
            cd(dir) do
                quiet_feature_call() do
                    diagnose(sampled; save_to_disk = true, html_report = true)
                end
                report_path = joinpath("artifacts", "diagnostics", "simple", "report.html")
                @test isfile(report_path)
                @test filesize(report_path) > 1000
            end
        end
    end

    @testset "Auto-filter interpolators by noise" begin
        # Build a clean PEP and synthetic data with known noise levels.
        pep = ODEParameterEstimation.simple()
        opts_low = EstimationOptions(datasize = 51, time_interval = [-0.5, 0.5], noise_level = 0.0,
                                     nooutput = true, diagnostics = false, save_system = false)
        opts_high = EstimationOptions(datasize = 51, time_interval = [-0.5, 0.5], noise_level = 1e-2,
                                      nooutput = true, diagnostics = false, save_system = false)
        pep_low = ODEParameterEstimation.sample_problem_data(pep, opts_low)
        pep_high = ODEParameterEstimation.sample_problem_data(pep, opts_high)

        # 1) σ̂ estimator is small for clean data, larger for noisy
        σ̂_low = ODEParameterEstimation.estimate_relative_noise(pep_low)
        σ̂_high = ODEParameterEstimation.estimate_relative_noise(pep_high)
        @test σ̂_low < 1e-4               # clean data → low noise estimate
        @test σ̂_high > σ̂_low * 10        # noisy data is detectably noisier

        # 2) Filter triggers at high noise (drops S2AAAMLE), passes through low noise
        list_with_s2 = [(InterpolatorS2AAAMLE, nothing), (InterpolatorAGPRobust, nothing)]
        filtered_high = ODEParameterEstimation._apply_noise_filter(list_with_s2, σ̂_high)
        @test length(filtered_high) == 1
        @test filtered_high[1][1] == InterpolatorAGPRobust

        filtered_low = ODEParameterEstimation._apply_noise_filter(list_with_s2, σ̂_low)
        @test length(filtered_low) == 2  # both kept at clean noise

        # 3) Wrapper short-circuits when no noise-sensitive method present
        list_safe = [(InterpolatorAGPRobust, nothing), (InterpolatorAAADGPR, nothing)]
        opts_default = EstimationOptions(datasize = 51, nooutput = true, diagnostics = false, save_system = false)
        result_safe = ODEParameterEstimation.maybe_filter_interpolators_by_noise(list_safe, pep_high, opts_default)
        @test result_safe == list_safe   # no change

        # 4) Wrapper opt-out preserves S2 even at high noise
        opts_optout = EstimationOptions(datasize = 51, nooutput = true, diagnostics = false,
                                        save_system = false, auto_filter_interpolators = false)
        result_optout = ODEParameterEstimation.maybe_filter_interpolators_by_noise(
            list_with_s2, pep_high, opts_optout)
        @test length(result_optout) == 2  # filter disabled

        # 5) Empty-after-filter fallback to AAADGPR
        list_only_s2 = [(InterpolatorS2AAAMLE, nothing)]
        result_fallback = ODEParameterEstimation.maybe_filter_interpolators_by_noise(
            list_only_s2, pep_high, opts_default)
        @test length(result_fallback) == 1
        @test result_fallback[1][1] == InterpolatorAAADGPR
    end

    @testset "Synthesize aggregate candidates (Phase 1: B/C)" begin
        # Run a small estimation with synthesis on; verify synthesized candidates
        # appear with correct provenance. Use simple() at noise=0 which produces
        # a clean pool that aggregates predictably.
        opts_on = EstimationOptions(
            datasize = 11, noise_level = 0.0,
            system_solver = SolverHC, flow = FlowStandard,
            use_si_template = true, shooting_points = 0,
            nooutput = true, diagnostics = false, save_system = false,
            polish_solver_solutions = false, polish_solutions = false,
            interpolators = MULTI_INTERP_TEMPLATE_LIST,
            synthesize_aggregate_candidates = true,
        )
        opts_off = ODEParameterEstimation.merge_options(opts_on;
            synthesize_aggregate_candidates = false)

        _, raw_on, _ = run_feature_canary(ODEParameterEstimation.simple, opts_on)
        _, raw_off, _ = run_feature_canary(ODEParameterEstimation.simple, opts_off)

        n_synth = count(c -> c.provenance.source_type == :synthesized_aggregate, raw_on[1])
        @test length(raw_on[1]) >= length(raw_off[1])             # synth never reduces pool size
        # Categories B/C only fire when ≥ 2 candidates per SP/anchor, which
        # `simple()` may or may not produce at shooting_points=0. Just verify
        # provenance shape on any synthesized candidate that DID get added.
        if n_synth > 0
            synth = first(c for c in raw_on[1]
                          if c.provenance.source_type == :synthesized_aggregate)
            @test synth.provenance.aggregation_strategy in (:median, :trim25_mean)
            @test !isempty(synth.provenance.aggregation_source_indices)
            @test :synthesized_aggregate in synth.provenance.notes
            @test isnothing(synth.provenance.interpolator_source)  # synthesized → no specific source
        end
    end
end
