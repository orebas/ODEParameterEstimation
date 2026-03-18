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

        invalid_placeholder_policy = EstimationOptions(si_placeholder_fail_categories = [:not_a_real_category])
        @test !ODEParameterEstimation.validate_options(invalid_placeholder_policy)

        @test_throws ErrorException ODEParameterEstimation.merge_options(base; definitely_not_an_option = true)
    end

    @testset "Unsupported model-class validation" begin
        @independent_variables t
        @parameters a
        @variables x(t) y(t)
        D = Differential(t)

        trig_model, trig_mq = ODEParameterEstimation.create_ordered_ode_system(
            "unsupported_trig",
            [x],
            [a],
            [D(x) ~ -a * sin(x)],
            [y ~ x],
        )
        trig_pep = ODEParameterEstimation.ParameterEstimationProblem(
            "unsupported_trig",
            trig_model,
            trig_mq,
            nothing,
            [0.0, 1.0],
            nothing,
            OrderedDict(a => 1.0),
            OrderedDict(x => 0.1),
            0,
        )
        trig_err = try
            ODEParameterEstimation.validate_supported_model_class(trig_pep)
            nothing
        catch err
            err
        end
        @test trig_err isa ODEParameterEstimation.UnsupportedModelClassError
        @test trig_err.category == :state_trigonometric

        sqrt_model, sqrt_mq = ODEParameterEstimation.create_ordered_ode_system(
            "unsupported_sqrt",
            [x],
            [a],
            [D(x) ~ a - sqrt(x)],
            [y ~ x],
        )
        sqrt_pep = ODEParameterEstimation.ParameterEstimationProblem(
            "unsupported_sqrt",
            sqrt_model,
            sqrt_mq,
            nothing,
            [0.0, 1.0],
            nothing,
            OrderedDict(a => 1.0),
            OrderedDict(x => 1.0),
            0,
        )
        sqrt_err = try
            ODEParameterEstimation.validate_supported_model_class(sqrt_pep)
            nothing
        catch err
            err
        end
        @test sqrt_err isa ODEParameterEstimation.UnsupportedModelClassError
        @test sqrt_err.category == :sqrt_nonlinearity

        supported_time_trig_model, supported_time_trig_mq = ODEParameterEstimation.create_ordered_ode_system(
            "supported_time_trig",
            [x],
            [a],
            [D(x) ~ -a * x + sin(2.0 * t)],
            [y ~ x],
        )
        supported_time_trig_pep = ODEParameterEstimation.ParameterEstimationProblem(
            "supported_time_trig",
            supported_time_trig_model,
            supported_time_trig_mq,
            nothing,
            [0.0, 1.0],
            nothing,
            OrderedDict(a => 1.0),
            OrderedDict(x => 0.1),
            0,
        )
        @test isnothing(ODEParameterEstimation.validate_supported_model_class(supported_time_trig_pep))
    end

    @testset "Sampling validation" begin
        @independent_variables t
        @parameters a
        @variables x(t) y(t)
        D = Differential(t)

        unstable_model, unstable_mq = ODEParameterEstimation.create_ordered_ode_system(
            "unstable_sampling_case",
            [x],
            [a],
            [D(x) ~ x^2],
            [y ~ x],
        )

        unstable_err = try
            ODEParameterEstimation.sample_data(
                unstable_model.system,
                unstable_mq,
                [0.0, 2.0],
                OrderedDict(a => 1.0),
                OrderedDict(x => 1.0),
                41,
            )
            nothing
        catch err
            err
        end
        @test unstable_err isa ODEParameterEstimation.SamplingFailureError

        maglev = ODEParameterEstimation.magnetic_levitation()
        maglev_opts = EstimationOptions(
            datasize = 41,
            noise_level = 0.0,
            time_interval = maglev.recommended_time_interval,
            nooutput = true,
        )
        sampled_maglev = ODEParameterEstimation.sample_problem_data(maglev, maglev_opts)
        @test length(sampled_maglev.data_sample["t"]) == 41
        @test all(length(values) == 41 for (key, values) in sampled_maglev.data_sample if key != "t")
    end

    @testset "Derivative order guard" begin
        err = try
            ODEParameterEstimation.nth_deriv(sin, ODEParameterEstimation.TAYLORDIFF_MAX_DERIVATIVE_ORDER + 1, 0.0)
            nothing
        catch caught
            caught
        end
        @test err isa ODEParameterEstimation.UnsupportedDerivativeOrderError
        @test err.requested_order == ODEParameterEstimation.TAYLORDIFF_MAX_DERIVATIVE_ORDER + 1
        @test err.supported_order == ODEParameterEstimation.TAYLORDIFF_MAX_DERIVATIVE_ORDER
        @test err.backend == :taylordiff
        @test isnothing(err.context)
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

    @testset "SI placeholder policy helpers" begin
        @test !ODEParameterEstimation.should_fail_si_placeholder(:dd_observable_index_oob, Symbol[])
        @test ODEParameterEstimation.should_fail_si_placeholder(:dd_observable_index_oob, [:dd_observable_index_oob])
        @test ODEParameterEstimation.should_fail_si_placeholder(:observable_derivative_overflow, [:dd_derivative_unmapped])
        @test ODEParameterEstimation.should_fail_si_placeholder(:support_jet, [:state_or_input_jet])
        @test ODEParameterEstimation.should_fail_si_placeholder(:true_unknown_variable, [:unknown_variable])

        z_aux_classification = ODEParameterEstimation.classify_si_ring_variable("z_aux", Dict{String, Int}(), nothing)
        @test z_aux_classification.category == :sian_auxiliary

        role_context = (
            state_names = Set(["x1"]),
            param_names = Set(["b"]),
            measured_rhs_names = Set(["z2"]),
        )
        state_jet_classification = ODEParameterEstimation.classify_si_ring_variable("x1_0", Dict{String, Int}(), (obs_lhs = [[1]],), role_context)
        @test state_jet_classification.category == :state_jet
        param_support_classification = ODEParameterEstimation.classify_si_ring_variable("b_0", Dict{String, Int}(), (obs_lhs = [[1]],), role_context)
        @test param_support_classification.category == :parameter_or_ic_symbol
        measured_rhs_classification = ODEParameterEstimation.classify_si_ring_variable("z2_0", Dict{String, Int}(), (obs_lhs = [[1]],), role_context)
        @test measured_rhs_classification.category == :measured_rhs_jet
        trfn_support_classification = ODEParameterEstimation.classify_si_ring_variable("_trfn_u_0", Dict{String, Int}(), (obs_lhs = [[1]],), role_context)
        @test trfn_support_classification.category == :transformed_analytic_support

        unknown_classification = ODEParameterEstimation.classify_si_ring_variable("mystery_symbol", Dict{String, Int}(), nothing)
        @test unknown_classification.category == :true_unknown_variable

        R_used, gens_used = ODEParameterEstimation.Nemo.polynomial_ring(ODEParameterEstimation.Nemo.QQ, ["x", "y1_0", "y1_1"])
        used_vars = ODEParameterEstimation.collect_used_nemo_variables([gens_used[1] + gens_used[2]])
        @test Set(string.(used_vars)) == Set(["x", "y1_0"])

        pep_dd = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), EstimationOptions(datasize = 11, noise_level = 0.0, nooutput = true))
        shallow_dd = ODEParameterEstimation.populate_derivatives(pep_dd.model.system, pep_dd.measured_quantities, 1, OrderedCollections.OrderedDict())
        extended_dd = ODEParameterEstimation.ensure_si_template_dd_support(
            pep_dd.model,
            pep_dd.measured_quantities,
            shallow_dd,
            Dict(:fake_y => 3),
        )
        @test length(extended_dd.obs_lhs) >= 4

        placeholder_stats = Dict{Symbol, Vector{String}}()
        placeholder_map = Dict{Any, Any}()
        @test_throws ErrorException ODEParameterEstimation._create_si_symbolic_placeholder!(
            placeholder_map,
            :fake_var,
            "fake_var",
            placeholder_stats,
            :dd_observable_index_oob;
            fail_categories = [:dd_observable_index_oob],
        )

        R, gens = ODEParameterEstimation.Nemo.polynomial_ring(ODEParameterEstimation.Nemo.QQ, ["late_x"])
        late_poly = gens[1]
        @test_throws ErrorException ODEParameterEstimation.nemo_to_symbolics(
            late_poly,
            Dict();
            fail_categories = [:late_map_miss],
        )

        R_aux, gens_aux = ODEParameterEstimation.Nemo.polynomial_ring(ODEParameterEstimation.Nemo.QQ, ["z_aux"])
        aux_poly = gens_aux[1]
        aux_sym = ODEParameterEstimation.nemo_to_symbolics(aux_poly, Dict())
        @test string(aux_sym) == "z_aux"
    end

    @testset "SEIR algebraic rescue can retry at shooting time" begin
        base_pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), EstimationOptions(datasize = 11, noise_level = 0.0, nooutput = true))
        failing_runner(args...) = error("synthetic advisory failure")

        fallback_ident = ODEParameterEstimation.setup_identifiability(
            base_pep;
            max_num_points = 1,
            nooutput = true,
            advisory_runner = failing_runner,
        )
        @test fallback_ident.numerical_advisory.status == :failed
        @test fallback_ident.numerical_advisory.failure_reason == "synthetic advisory failure"
        @test :heuristic_fallback in fallback_ident.numerical_advisory.notes
        @test fallback_ident.good_num_points == 1
        @test isempty(fallback_ident.good_udict)
        @test isempty(fallback_ident.all_unidentifiable)
        @test isempty(fallback_ident.good_DD.all_unidentifiable)

        opts = EstimationOptions(
            datasize = 21,
            noise_level = 1e-8,
            nooutput = true,
            diagnostics = false,
            flow = FlowStandard,
            use_si_template = true,
            use_parameter_homotopy = true,
            interpolators = [InterpolatorAAAD, InterpolatorAGPRobust],
            save_system = false,
            polish_solver_solutions = true,
            polish_solutions = false,
        )
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.seir(), opts)
        ident = ODEParameterEstimation.setup_identifiability(pep; max_num_points = 1, nooutput = true)
        ordered_model = isa(pep.model.system, ODEParameterEstimation.OrderedODESystem) ?
            pep.model.system :
            ODEParameterEstimation.OrderedODESystem(pep.model.system, ident.states, ident.params)
        si_template, _ = ODEParameterEstimation.prepare_si_template_with_structural_fix(
            ordered_model,
            pep.measured_quantities,
            pep.data_sample,
            ident.good_DD,
            false;
            states = ident.states,
            params = ident.params,
            infolevel = 0,
            placeholder_fail_categories = opts.si_placeholder_fail_categories,
        )
        interp_spec = first(ODEParameterEstimation.resolve_interpolator_list(opts))
        interp_func = ODEParameterEstimation.get_interpolator_function(interp_spec[1], interp_spec[2])
        interpolants = ODEParameterEstimation.create_interpolants(
            pep.measured_quantities,
            pep.data_sample,
            ident.t_vector,
            interp_func,
        )
        known_param_dict = OrderedDict{Any, Float64}(k => Float64(v) for (k, v) in pep.p_true)
        resolve_t0 = ODEParameterEstimation.resolve_states_with_fixed_params(
            pep.model.system,
            pep.measured_quantities,
            pep.data_sample,
            ident.good_deriv_level,
            ident.good_udict,
            ident.good_varlist,
            ident.good_DD,
            known_param_dict,
            interpolants;
            si_template = si_template,
            time_index = 1,
            diagnostics = false,
            placeholder_fail_categories = opts.si_placeholder_fail_categories,
        )
        resolve_shoot = ODEParameterEstimation.resolve_states_with_fixed_params(
            pep.model.system,
            pep.measured_quantities,
            pep.data_sample,
            ident.good_deriv_level,
            ident.good_udict,
            ident.good_varlist,
            ident.good_DD,
            known_param_dict,
            interpolants;
            si_template = si_template,
            time_index = 2,
            diagnostics = false,
            placeholder_fail_categories = opts.si_placeholder_fail_categories,
        )

        @test ODEParameterEstimation._resolve_missing_state_count(resolve_t0) > 0
        @test ODEParameterEstimation._resolve_missing_state_count(resolve_shoot) == 0

        candidate = ODEParameterEstimation._build_algebraic_resolve_candidate(
            pep,
            known_param_dict,
            ident.good_udict,
            ident.all_unidentifiable,
            resolve_shoot,
            resolve_shoot.state_vars,
            first(resolve_shoot.solutions),
            2,
            2,
            :aaad,
            1,
            1.0,
            opts;
            rescue_path = :algebraic_resolve_shoot,
        )
        candidate.provenance = ODEParameterEstimation.copy_provenance(
            candidate.provenance;
            ODEParameterEstimation.si_template_lineage_kwargs(si_template)...,
        )
        ODEParameterEstimation.sync_result_contract!(candidate)

        @test candidate.return_code == :algebraic_resolve_shoot
        @test :resolved_at_shooting_time in candidate.provenance.notes
        @test candidate.provenance.practical_identifiability_status == :not_assessed
        @test all(isfinite, values(candidate.states))
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

    @testset "SI template shape guard" begin
        @parameters a

        fake_structure = (
            status = :residual_underdetermined,
            n_equations = 10,
            n_variables = 12,
            n_data_vars = 3,
            n_effective_eqs = 8,
            n_effective_vars = 10,
            dropped_equation_indices = [2, 5],
        )
        fake_roles = (
            suspicious_categories = Dict(:true_unknown_variable => 1),
        )

        err = try
            ODEParameterEstimation.throw_on_nonsquare_si_template(
                fake_structure,
                OrderedDict(a => 1.0),
                fake_roles,
            )
            nothing
        catch e
            e
        end

        @test err isa ODEParameterEstimation.SITemplateShapeError
        @test occursin("residual_underdetermined", sprint(showerror, err))
        @test occursin("effective system has 8 equations and 10 unknowns", sprint(showerror, err))
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
            structural_fix_set = OrderedDict(a => 1.0),
            template_status_after_residual_fix = :determined,
            practical_identifiability_status = :advisory_available,
            numerical_advisory = ODEParameterEstimation.NumericalIdentifiabilityAdvisory(
                status = :available,
                recommended_num_points = 1,
                recommended_deriv_level = Dict(1 => 3),
            ),
        )

        ODEParameterEstimation.sync_result_contract!(result)

        @test result.return_code == :direct_opt_fallback
        @test result.interpolator_source == :aaad
        @test ODEParameterEstimation.compatibility_return_code(result.provenance) == :direct_opt_fallback
        @test occursin("method=direct_opt", ODEParameterEstimation.lineage_summary(result))
        @test occursin("rescue=direct_opt_fallback", ODEParameterEstimation.lineage_summary(result))
        @test occursin("structural_fix=1", ODEParameterEstimation.lineage_summary(result))
        @test occursin("template=determined", ODEParameterEstimation.lineage_summary(result))
        @test occursin("practical=advisory_available", ODEParameterEstimation.lineage_summary(result))
        @test occursin("advisory=available", ODEParameterEstimation.lineage_summary(result))
    end

    @testset "Algebraic resolve failure stays candidate-local" begin
        candidates = [
            ODEParameterEstimation.ParameterEstimationResult(
                OrderedDict{Num, Float64}(),
                OrderedDict{Num, Float64}(),
                0.0,
                1.0,
                nothing,
                0,
                0.0,
                OrderedDict{Num, Float64}(),
                Set{Num}(),
                nothing,
                nothing,
                ODEParameterEstimation.ResultProvenance(),
            ),
            ODEParameterEstimation.ParameterEstimationResult(
                OrderedDict{Num, Float64}(),
                OrderedDict{Num, Float64}(),
                0.0,
                1.0,
                nothing,
                0,
                0.0,
                OrderedDict{Num, Float64}(),
                Set{Num}(),
                nothing,
                nothing,
                ODEParameterEstimation.ResultProvenance(),
            ),
        ]

        upstream_err = TaskFailedException(Task(() -> nothing))
        ODEParameterEstimation._note_algebraic_resolve_failure!(candidates, [1], upstream_err)
        @test :algebraic_resolve_failed in candidates[1].provenance.notes
        @test :algebraic_resolve_upstream_failure in candidates[1].provenance.notes
        @test isempty(candidates[2].provenance.notes)
        @test ODEParameterEstimation._algebraic_resolve_failure_notes(ErrorException("boom")) == [:algebraic_resolve_failed, :algebraic_resolve_exception]
    end
end
