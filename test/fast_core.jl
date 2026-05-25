using Test
using Logging
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
            interpolators = [InterpolatorAGPRobust, InterpolatorS3AdaptSE],
            terminal_fallback = :direct_opt,
            backsolve_recovery = :algebraic_resolve,
            t0_state_completion = :strict,
        )

        @test merged.flow == FlowStandard
        @test merged.shooting_points == 2
        @test ODEParameterEstimation.validate_options(merged)

        resolved = ODEParameterEstimation.resolve_interpolator_list(merged)
        @test length(resolved) == 2
        @test first.(resolved) == [InterpolatorAGPRobust, InterpolatorS3AdaptSE]

        custom_interp = (xs, ys) -> ODEParameterEstimation.aaad(xs, ys)
        custom_opts = EstimationOptions(
            interpolators = InterpolatorMethod[],
            interpolator = InterpolatorCustom,
            custom_interpolator = custom_interp,
        )
        resolved_custom = ODEParameterEstimation.resolve_interpolator_list(custom_opts)
        @test length(resolved_custom) == 1
        @test first(resolved_custom)[1] == InterpolatorCustom
        @test first(resolved_custom)[2] === custom_interp

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
        @test_throws MethodError ODEParameterEstimation.run_parameter_estimation_examples(models = Symbol[]; datasize = 10)
        @test isnothing(ODEParameterEstimation.run_parameter_estimation_examples(
            models = Symbol[],
            opts = EstimationOptions(save_system = false, nooutput = true),
            log_dir = mktempdir(),
            doskip = false,
        ))

        # terminal_fallback + FlowDirectOpt is redundant but not invalid (just warns)
        redundant_terminal_fallback = EstimationOptions(
            flow = FlowDirectOpt,
            terminal_fallback = :direct_opt,
        )
        @test ODEParameterEstimation.validate_options(redundant_terminal_fallback)

        invalid_seed_policy = EstimationOptions(t0_state_completion = :maybe)
        @test !ODEParameterEstimation.validate_options(invalid_seed_policy)

        invalid_uq_policy = EstimationOptions(uq_failure_policy = :maybe)
        @test !ODEParameterEstimation.validate_options(invalid_uq_policy)

        invalid_placeholder_policy = EstimationOptions(si_placeholder_fail_categories = [:not_a_real_category])
        @test !ODEParameterEstimation.validate_options(invalid_placeholder_policy)

        @test_throws ErrorException ODEParameterEstimation.merge_options(base; definitely_not_an_option = true)

        public_names = names(ODEParameterEstimation; all = false, imported = false)
        @test :estimate ∉ public_names
        @test :solve_with_monodromy ∉ public_names
        @test :aaad_in_testing ∉ public_names
    end

    @testset "Branch-stress example registry" begin
        categories = ODEParameterEstimation.available_model_categories()
        branch_stress = categories[:branch_stress]

        expected = Set([
            :latent_subpopulation_branch,
            :latent_subpopulation_observed_control,
            :receptor_subtype_binding_branch,
            :receptor_subtype_binding_observed_control,
        ])

        @test Set(keys(branch_stress)) == expected
        @test expected ⊆ Set(ODEParameterEstimation.available_models())

        for model_name in expected
            pep = branch_stress[model_name]()
            @test pep isa ODEParameterEstimation.ParameterEstimationProblem
            @test pep.name == string(model_name)
            @test all(value -> 0.0 < value < 10.0, values(pep.p_true))
            @test all(value -> 0.0 < value < 10.0, values(pep.ic))
        end

        latent = ODEParameterEstimation.latent_subpopulation_branch()
        latent_params = collect(values(latent.p_true))
        latent_ics = collect(values(latent.ic))
        latent_branch_reps = Set{Tuple{NTuple{6, Float64}, NTuple{5, Float64}}}()
        for perm in ((1, 2, 3), (1, 3, 2), (2, 1, 3), (2, 3, 1), (3, 1, 2), (3, 2, 1))
            permuted_params = (
                latent_params[perm[1]],
                latent_params[perm[2]],
                latent_params[perm[3]],
                latent_params[3 + perm[1]],
                latent_params[3 + perm[2]],
                latent_params[3 + perm[3]],
            )
            permuted_ics = (
                latent_ics[1],
                latent_ics[1 + perm[1]],
                latent_ics[1 + perm[2]],
                latent_ics[1 + perm[3]],
                latent_ics[5],
            )
            @test sum(permuted_ics[2:4]) ≈ sum(latent_ics[2:4]) atol = 1e-12 rtol = 1e-12
            @test all(value -> 0.0 < value < 10.0, permuted_params)
            @test all(value -> 0.0 < value < 10.0, permuted_ics)
            push!(latent_branch_reps, (permuted_params, permuted_ics))
        end
        @test length(latent_branch_reps) == 6

        receptor = ODEParameterEstimation.receptor_subtype_binding_branch()
        receptor_params = collect(values(receptor.p_true))
        receptor_ics = collect(values(receptor.ic))
        swapped_receptor_params = (
            receptor_params[2],
            receptor_params[1],
            receptor_params[4],
            receptor_params[3],
            receptor_params[6],
            receptor_params[5],
        )
        swapped_receptor_ics = (receptor_ics[1], receptor_ics[3], receptor_ics[2])
        @test receptor_ics[2] + receptor_ics[3] ≈ swapped_receptor_ics[2] + swapped_receptor_ics[3] atol = 1e-12 rtol = 1e-12
        @test Tuple(receptor_params) != swapped_receptor_params
        @test Tuple(receptor_ics) != swapped_receptor_ics
        @test all(value -> 0.0 < value < 10.0, swapped_receptor_params)
        @test all(value -> 0.0 < value < 10.0, swapped_receptor_ics)
    end

    @testset "Polish coordinate transforms" begin
        # Per-variable transform selection: positive bounds → :log,
        # finite signed bounds → :shifted_log, unbounded → :linear
        lb = Float64[1e-3, -1.0, -Inf, 0.0]
        ub = Float64[100.0, 1.0, Inf, 10.0]
        transforms, shifts = ODEParameterEstimation._choose_polish_transforms(lb, ub; policy = :auto)
        @test transforms == [:log, :shifted_log, :linear, :shifted_log]
        @test shifts[1] == 0.0
        @test shifts[2] > 1.0           # shift covers the negative lower bound
        @test shifts[3] == 0.0
        @test shifts[4] > 0.0

        # Forward / inverse round-trip in original scale
        x = Float64[2.5, 0.3, -7.4, 4.7]
        y = ODEParameterEstimation._polish_external_to_internal(x, transforms, shifts)
        x_back = ODEParameterEstimation._polish_internal_to_external(y, transforms, shifts)
        @test x_back ≈ x rtol = 1e-12

        # `:shifted_log` keeps the internal lower bound finite even when external lb is just
        # barely negative — the formula `s = max(εM, -lb + εM)` prevents a near-zero log argument
        lb_marginal = Float64[-1e-10]
        ub_marginal = Float64[10.0]
        t_marg, s_marg = ODEParameterEstimation._choose_polish_transforms(lb_marginal, ub_marginal; policy = :auto)
        @test t_marg == [:shifted_log]
        ilb_marg, _ = ODEParameterEstimation._polish_coordinate_bounds(t_marg, s_marg, lb_marginal, ub_marginal)
        @test isfinite(ilb_marg[1]) && ilb_marg[1] > -100  # not absurdly negative

        # Policy overrides
        t_lin, _ = ODEParameterEstimation._choose_polish_transforms(lb, ub; policy = :linear)
        @test all(t_lin .== :linear)

        # `:log_only` is strict — errors when any variable has non-positive or non-finite bounds
        @test_throws ArgumentError ODEParameterEstimation._choose_polish_transforms(lb, ub; policy = :log_only)
        # but works fine when every bound permits `:log`
        lb_pos = Float64[1e-3, 0.5]
        ub_pos = Float64[100.0, 10.0]
        t_logpos, _ = ODEParameterEstimation._choose_polish_transforms(lb_pos, ub_pos; policy = :log_only)
        @test all(t_logpos .== :log)
    end

    @testset "Polish method dispatch" begin
        # New residual-mode methods are recognized
        @test ODEParameterEstimation.is_residual_polish_method(PolishLSOBoundedLog)
        @test ODEParameterEstimation.is_residual_polish_method(PolishFastLMBoundedLog)
        @test !ODEParameterEstimation.is_residual_polish_method(PolishNewtonTrust)
        @test !ODEParameterEstimation.is_residual_polish_method(PolishBFGS)

        # `get_polish_optimizer` returns a tagged tuple for residual methods, a plain
        # constructor for scalar methods
        token_lso = ODEParameterEstimation.get_polish_optimizer(PolishLSOBoundedLog)
        @test token_lso isa Tuple
        @test token_lso[1] === :lso_direct
        # Don't pull `LeastSquaresOptim` into Main scope; check the type name instead.
        instance_name = string(typeof(token_lso[2]()).name.module, ".", typeof(token_lso[2]()).name.name)
        @test instance_name == "LeastSquaresOptim.LevenbergMarquardt"

        token_fastlm = ODEParameterEstimation.get_polish_optimizer(PolishFastLMBoundedLog)
        @test token_fastlm isa Tuple
        @test token_fastlm[1] === :fastlm_direct

        # Scalar path still works (`NewtonTrustRegion` is exported from `Optim` by `using ODEParameterEstimation`)
        @test ODEParameterEstimation.get_polish_optimizer(PolishNewtonTrust) === ODEParameterEstimation.NewtonTrustRegion
    end

    @testset "Consensus estimation smoke" begin
        opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            shooting_points = 0,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = false,
        )
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), opts)
        report = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                with_logger(NullLogger()) do
                    ODEParameterEstimation.research_consensus_estimation(
                        pep;
                        est_opts = opts,
                        consensus_opts = ODEParameterEstimation.ConsensusOptions(
                            strategy = :family_consensus,
                            support_point_count = 2,
                            support_combo_count = 1,
                            refine_top_families = 1,
                            do_equation_refit = false,
                        ),
                    )
                end
            end
        end

        @test report isa ODEParameterEstimation.ConsensusEstimationReport
        @test !isempty(report.raw_candidates)
        @test length(report.raw_candidates) == length(report.candidate_evidence)
        @test !isempty(report.families)
        @test !isnothing(report.winner_candidate)
        @test report.scoring_summary[:strategy] == :family_consensus
    end

    @testset "Synthesized finalizer smoke" begin
        opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            shooting_points = 0,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = false,
        )
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), opts)
        report = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                with_logger(NullLogger()) do
                    ODEParameterEstimation.research_synthesized_finalizer(
                        pep;
                        est_opts = opts,
                        synth_opts = ODEParameterEstimation.SynthesizedFinalizerOptions(
                            base_consensus_opts = ODEParameterEstimation.ConsensusOptions(
                                strategy = :family_consensus,
                                support_point_count = 2,
                                support_combo_count = 1,
                                refine_top_families = 1,
                                do_equation_refit = false,
                            ),
                            max_family_seeds = 2,
                            max_cross_family_seeds = 2,
                            cross_family_distance_limit = 10.0,
                            max_refine_candidates = 2,
                        ),
                    )
                end
            end
        end

        @test report isa ODEParameterEstimation.SynthesizedFinalizerReport
        @test report.raw_consensus_report isa ODEParameterEstimation.ConsensusEstimationReport
        @test !isempty(report.raw_consensus_report.raw_candidates)
        @test !isnothing(report.winning_result)
        @test report.winning_origin in (:raw, :synthesized)
        @test report.selection_summary[:n_raw_candidates] == length(report.raw_consensus_report.raw_candidates)
        @test report.selection_summary[:n_synthesized_seeds] == length(report.synthesized_seeds)
        @test report.selection_summary[:n_refined_seed_results] == length(report.refined_seed_results)
    end

    @testset "Branch consensus v1 smoke" begin
        opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            shooting_points = 3,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = false,
            multipoint_max_pairs = 2,
        )
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), opts)
        report = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                with_logger(NullLogger()) do
                    ODEParameterEstimation.research_branch_consensus_v1(
                        pep;
                        est_opts = opts,
                        branch_opts = ODEParameterEstimation.BranchConsensusOptions(
                            support_point_count = 2,
                            support_combo_count = 1,
                            top_branch_neighbor_count = 2,
                            max_refined_seeds = 2,
                            max_returned_branches = 3,
                        ),
                    )
                end
            end
        end

        @test report isa ODEParameterEstimation.BranchConsensusReport
        @test report.version_label == :branch_consensus_v1
        @test !isempty(report.raw_candidates)
        @test !isempty(report.branch_hypotheses)
        @test !isnothing(report.best_result)
        @test 1 <= report.adaptive_k <= 3
        @test report.scoring_summary[:version_label] == :branch_consensus_v1
        @test report.scoring_summary[:n_raw_candidates] == length(report.raw_candidates)
        @test report.scoring_summary[:n_branches] == length(report.branch_hypotheses)
        @test any(branch.branch_index == report.best_branch_index for branch in report.top_branches)
        @test all(!isempty(branch.variable_support) for branch in report.top_branches)
        @test all(!isempty(branch.block_support) for branch in report.top_branches)
    end

    @testset "Block consensus v2 smoke" begin
        opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            shooting_points = 3,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = false,
            multipoint_max_pairs = 2,
        )
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), opts)
        report = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                with_logger(NullLogger()) do
                    ODEParameterEstimation.research_block_consensus_v2(
                        pep;
                        est_opts = opts,
                        block_opts = ODEParameterEstimation.BlockConsensusOptions(
                            support_point_count = 2,
                            support_combo_count = 1,
                            max_clusters_per_block = 3,
                            max_recombined_clusters_per_block = 2,
                            max_hypotheses = 4,
                            polish_top_hypotheses = 1,
                        ),
                    )
                end
            end
        end

        @test report isa ODEParameterEstimation.BlockConsensusReport
        @test report.version_label == :block_consensus_v2
        @test !isempty(report.raw_candidates)
        @test !isempty(report.block_decomposition.blocks)
        @test !isempty(report.assembled_hypotheses)
        @test !isnothing(report.best_result)
        @test !isempty(report.top_hypotheses)
        @test !isempty(report.variable_confidence)
        @test report.scoring_summary[:version_label] == :block_consensus_v2
        @test report.scoring_summary[:n_raw_candidates] == length(report.raw_candidates)
        @test report.scoring_summary[:n_blocks] == length(report.block_decomposition.blocks)
    end

    @testset "Block consensus v2 reuse path" begin
        opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            shooting_points = 3,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = false,
            multipoint_max_pairs = 2,
        )
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), opts)
        pep_with_data, run_opts, raw_candidates = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                with_logger(NullLogger()) do
                    ODEParameterEstimation._prepare_consensus_inputs(pep, opts)
                end
            end
        end
        context = ODEParameterEstimation._build_consensus_context(pep_with_data, run_opts)
        consensus_opts = ODEParameterEstimation.ConsensusOptions(
            strategy = :best_fit_baseline,
            support_point_count = 2,
            support_combo_count = 1,
            refine_top_families = 1,
            do_equation_refit = false,
        )
        baseline_report = ODEParameterEstimation._assemble_consensus_report(
            pep_with_data,
            run_opts,
            raw_candidates,
            consensus_opts;
            context = context,
        )
        block_opts = ODEParameterEstimation.BlockConsensusOptions(
            support_point_count = 2,
            support_combo_count = 1,
            max_clusters_per_block = 3,
            max_recombined_clusters_per_block = 2,
            max_hypotheses = 4,
            enable_polish = false,
        )
        direct_report = ODEParameterEstimation._assemble_block_consensus_report(
            pep_with_data,
            run_opts,
            raw_candidates,
            block_opts;
            context = context,
        )
        reused_report = ODEParameterEstimation._assemble_block_consensus_report(
            pep_with_data,
            run_opts,
            raw_candidates,
            block_opts;
            context = context,
            support_points = baseline_report.support_points,
            support_combos = baseline_report.support_combos,
            evidence = baseline_report.candidate_evidence,
        )

        @test direct_report.support_points == reused_report.support_points == baseline_report.support_points
        @test direct_report.support_combos == reused_report.support_combos == baseline_report.support_combos
        @test direct_report.block_decomposition.blocks == reused_report.block_decomposition.blocks
        @test length(direct_report.assembled_hypotheses) == length(reused_report.assembled_hypotheses)
        @test direct_report.scoring_summary[:best_score] ≈ reused_report.scoring_summary[:best_score]
        @test direct_report.best_result.err ≈ reused_report.best_result.err
        @test [item.composite_score for item in direct_report.candidate_evidence] ≈ [item.composite_score for item in reused_report.candidate_evidence]

        timing = reused_report.scoring_summary[:timing]
        @test timing isa ODEParameterEstimation.TimingBreakdown
        @test any(phase.name == "reuse_or_build_evidence" for phase in timing.phases)
        @test any(phase.name == "hypothesis_rescore" && phase.seconds == 0.0 for phase in timing.phases)
        @test timing.details[:reused_support_points] == true
        @test timing.details[:reused_support_combos] == true
        @test timing.details[:reused_candidate_evidence] == true
    end

    @testset "Tryhard finalists smoke" begin
        opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            shooting_points = 3,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = false,
            multipoint_max_pairs = 2,
        )
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), opts)
        report = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                with_logger(NullLogger()) do
                    ODEParameterEstimation.research_tryhard_finalists(
                        pep;
                        est_opts = opts,
                        tryhard_opts = ODEParameterEstimation.TryhardFinalistOptions(
                            block_support_point_count = 2,
                            block_support_combo_count = 1,
                            post_polish_metric = :trajectory_hybrid,
                            post_polish_traj_threshold = 0.05,
                            post_polish_secondary_threshold = 1.5,
                            post_polish_basin_threshold = 0.005,
                        ),
                    )
                end
            end
        end

        @test report isa ODEParameterEstimation.TryhardFinalistReport
        @test report.version_label == :reasonable_frontier_v1
        @test !isempty(report.raw_seed_rows)
        @test !isempty(report.merged_seed_rows)
        @test !isempty(report.finalists)
        @test !isnothing(report.best_result)
        @test report.selection_summary[:policy_label] == :reasonable_frontier_finalists
        @test report.selection_summary[:finalist_count] == length(report.finalists)
        @test report.selection_summary[:post_polish_metric] == :trajectory_hybrid
        @test report.selection_summary[:post_polish_traj_threshold] == 0.05
        @test report.selection_summary[:post_polish_secondary_threshold] == 1.5
        @test report.selection_summary[:post_polish_basin_threshold] == 0.005
    end

    @testset "Tryhard additive merge compatibility" begin
        opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            shooting_points = 3,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = false,
            multipoint_max_pairs = 2,
        )
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), opts)
        shared = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                with_logger(NullLogger()) do
                    ODEParameterEstimation._prepare_consensus_inputs(pep, opts)
                end
            end
        end
        pep_with_data, run_opts, raw_candidates = shared
        polish_ctx = ODEParameterEstimation._build_polish_context(pep_with_data; opts = run_opts)
        block_report = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                with_logger(NullLogger()) do
                    ODEParameterEstimation._assemble_block_consensus_report(
                        pep_with_data,
                        run_opts,
                        raw_candidates,
                        ODEParameterEstimation.BlockConsensusOptions(
                            support_point_count = 2,
                            support_combo_count = 1,
                            enable_polish = false,
                        ),
                    )
                end
            end
        end
        block_rows = ODEParameterEstimation._collect_tryhard_block_seed_rows(block_report, polish_ctx; threshold = 0.001)
        merged_rows = ODEParameterEstimation._merge_tryhard_seed_rows(block_rows, polish_ctx; threshold = 0.001)

        @test !isempty(block_rows)
        @test !isempty(merged_rows)
        @test all(haskey(row, :origin_label) for row in merged_rows)
        @test all(haskey(row, :source_id) for row in merged_rows)
    end

    @testset "Tryhard frontier admits additive Inf-fit family reps" begin
        opts = EstimationOptions(
            datasize = 11,
            noise_level = 0.0,
            shooting_points = 3,
            nooutput = true,
            diagnostics = false,
            save_system = false,
            use_parameter_homotopy = false,
            polish_solver_solutions = false,
            polish_solutions = false,
            multipoint_max_pairs = 2,
        )
        pep = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), opts)
        shared = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                with_logger(NullLogger()) do
                    ODEParameterEstimation._prepare_consensus_inputs(pep, opts)
                end
            end
        end
        pep_with_data, run_opts, raw_candidates = shared
        polish_ctx = ODEParameterEstimation._build_polish_context(pep_with_data; opts = run_opts)
        baseline_rows = ODEParameterEstimation._select_tryhard_baseline_seed_rows(raw_candidates[1:1], polish_ctx; opts = run_opts)
        additive_row = ODEParameterEstimation._build_tryhard_seed_row(
            raw_candidates[1],
            :branch,
            1,
            1;
            generator_score = 0.5,
            generator_score_kind = :branch_score,
        )
        additive_row[:fit_error] = Inf

        admitted, rejected, metadata = ODEParameterEstimation._build_reasonable_tryhard_frontier(
            baseline_rows,
            Dict{Symbol, Any}[additive_row],
            polish_ctx,
            ODEParameterEstimation.TryhardFinalistOptions(frontier_growth_factor = 2.0);
            threshold = 0.001,
        )

        @test length(admitted) == 2
        @test isempty(rejected)
        @test metadata[:admitted_additive_count] == 1
        @test metadata[:admitted_additive_family_counts][:branch] == 1
    end

    @testset "Consensus benchmark rendering" begin
        raw_rows = [
            (kind = :parameter, label = "a31", estimate = 0.84, truth = 0.80, abs_error = 0.04, rel_error = 0.05),
            (kind = :state_ic, label = "x3(0)", estimate = 0.44, truth = 0.46, abs_error = 0.02, rel_error = 0.043478260869565216),
        ]
        better_rows = [
            (kind = :parameter, label = "a31", estimate = 0.81, truth = 0.80, abs_error = 0.01, rel_error = 0.0125),
            (kind = :state_ic, label = "x3(0)", estimate = 0.455, truth = 0.46, abs_error = 0.005, rel_error = 0.010869565217391304),
        ]
        consensus_rows = [
            (kind = :parameter, label = "a31", estimate = 0.83, truth = 0.80, abs_error = 0.03, rel_error = 0.0375),
            (kind = :state_ic, label = "x3(0)", estimate = 0.45, truth = 0.46, abs_error = 0.01, rel_error = 0.021739130434782608),
        ]
        family_rows = [(rank = 1, member_count = 2, family_score = 0.2, medoid_index = 1, best_member_index = 2, interpolators = "aaad_gpr", source_types = "single_point,multipoint", shooting_support = "4, 9")]
        evidence = Dict{Symbol, Any}(
            :base_fit_error => 1.0e-4,
            :sp_equation_residual_kept => 1.0e-6,
            :sp_equation_residual_dropped => 2.0e-6,
            :mp_equation_residual_kept => 3.0e-6,
            :mp_equation_residual_dropped => 4.0e-6,
            :conditioning_score => 10.0,
            :uq_volume_proxy => NaN,
            :source_diversity_tags => Symbol[:aaad_gpr, :multipoint],
            :composite_score => 0.2,
            :score_breakdown => (fit = 0.1, equation = 0.2, support = 0.3, trust = 0.4),
        )
        artifact = Dict{Symbol, Any}(
            :model_name => "demo",
            :dataset_label => "demo-set",
            :generated_at => "2026-04-05T12:00:00",
            :shared_candidate_generation_seconds => 1.0,
            :shared_context_seconds => 0.5,
            :shared_total_seconds => 1.5,
            :raw_candidate_count => 3,
            :oracle_note => "benchmark-only",
            :run_config => Dict{Symbol, Any}(
                :interpolator => "InterpolatorAAADGPR",
                :interpolator_count => 1,
                :shooting_points => 6,
                :multipoint_n_points => 2,
                :multipoint_max_pairs => 8,
                :use_parameter_homotopy => true,
                :use_multipoint => true,
                :polish_solutions => false,
                :polish_solver_solutions => false,
                :polish_maxiters => 40,
                :polish_maxtime => 20.0,
            ),
            :consensus_config => Dict{Symbol, Any}(
                :support_point_count => 8,
                :support_combo_count => 8,
                :refine_top_families => 2,
                :do_equation_refit => true,
            ),
            :raw_pool => Dict{Symbol, Any}(
                :best_fit_index => 1,
                :best_truth_index => 2,
                :best_fit_lineage => "fit lineage",
                :best_truth_lineage => "truth lineage",
                :best_fit_fit_error => 1.0e-4,
                :best_truth_fit_error => 1.1e-4,
                :best_fit_truth_metrics => Dict(:combined_rel_rmse => 0.08),
                :best_truth_truth_metrics => Dict(:combined_rel_rmse => 0.03),
            ),
            :strategies => Dict{Symbol, Any}[
                Dict{Symbol, Any}(
                    :strategy => :best_fit_baseline,
                    :selection_seconds => 0.1,
                    :effective_total_seconds => 1.6,
                    :candidate_count => 3,
                    :family_count => 2,
                    :winner_mode => :raw,
                    :raw_winner_lineage => "fit lineage",
                    :final_winner_lineage => "fit lineage",
                    :raw_winner_fit_error => 1.0e-4,
                    :final_winner_fit_error => 1.0e-4,
                    :raw_winner_score => 0.4,
                    :final_winner_score => 0.4,
                    :support_points => [4, 9],
                    :support_point_times => [0.8, 1.5],
                    :support_combos => [[4, 9]],
                    :support_combo_times => [[0.8, 1.5]],
                    :parameter_rows => raw_rows[1:1],
                    :state_rows => raw_rows[2:2],
                    :truth_metrics => Dict(:all_rows => raw_rows, :parameter_rel_rmse => 0.05, :combined_rel_rmse => 0.047),
                    :raw_truth_metrics => Dict(:all_rows => raw_rows, :parameter_rel_rmse => 0.05, :combined_rel_rmse => 0.047),
                    :winner_evidence => evidence,
                    :raw_winner_evidence => evidence,
                    :top_families => family_rows,
                ),
                Dict{Symbol, Any}(
                    :strategy => :family_consensus,
                    :selection_seconds => 0.2,
                    :effective_total_seconds => 1.7,
                    :candidate_count => 3,
                    :family_count => 2,
                    :winner_mode => :raw,
                    :raw_winner_lineage => "consensus lineage",
                    :final_winner_lineage => "consensus lineage",
                    :raw_winner_fit_error => 1.2e-4,
                    :final_winner_fit_error => 1.2e-4,
                    :raw_winner_score => 0.2,
                    :final_winner_score => 0.2,
                    :support_points => [4, 9],
                    :support_point_times => [0.8, 1.5],
                    :support_combos => [[4, 9]],
                    :support_combo_times => [[0.8, 1.5]],
                    :parameter_rows => consensus_rows[1:1],
                    :state_rows => consensus_rows[2:2],
                    :truth_metrics => Dict(:all_rows => consensus_rows, :parameter_rel_rmse => 0.0375, :combined_rel_rmse => 0.031),
                    :raw_truth_metrics => Dict(:all_rows => consensus_rows, :parameter_rel_rmse => 0.0375, :combined_rel_rmse => 0.031),
                    :winner_evidence => evidence,
                    :raw_winner_evidence => evidence,
                    :top_families => family_rows,
                ),
                Dict{Symbol, Any}(
                    :strategy => :family_consensus_refit,
                    :selection_seconds => 0.3,
                    :effective_total_seconds => 1.8,
                    :candidate_count => 3,
                    :family_count => 2,
                    :winner_mode => :refined,
                    :raw_winner_lineage => "consensus lineage",
                    :final_winner_lineage => "refined lineage",
                    :raw_winner_fit_error => 1.2e-4,
                    :final_winner_fit_error => 0.9e-4,
                    :raw_winner_score => 0.2,
                    :final_winner_score => 0.1,
                    :support_points => [4, 9],
                    :support_point_times => [0.8, 1.5],
                    :support_combos => [[4, 9]],
                    :support_combo_times => [[0.8, 1.5]],
                    :parameter_rows => better_rows[1:1],
                    :state_rows => better_rows[2:2],
                    :truth_metrics => Dict(:all_rows => better_rows, :parameter_rel_rmse => 0.0125, :combined_rel_rmse => 0.012),
                    :raw_truth_metrics => Dict(:all_rows => consensus_rows, :parameter_rel_rmse => 0.0375, :combined_rel_rmse => 0.031),
                    :winner_evidence => evidence,
                    :raw_winner_evidence => evidence,
                    :top_families => family_rows,
                ),
            ],
        )

        @test ODEParameterEstimation._consensus_winner_label(Dict(:strategy => :best_fit_baseline, :winner_mode => :raw)) == "raw winner"
        @test ODEParameterEstimation._consensus_winner_label(Dict(:strategy => :family_consensus_refit, :winner_mode => :raw)) == "refit kept raw winner"
        @test ODEParameterEstimation._consensus_winner_label(Dict(:strategy => :family_consensus_refit, :winner_mode => :refined)) == "refined winner"
        @test ODEParameterEstimation._consensus_winner_label(Dict(:strategy => :family_consensus, :winner_mode => :missing)) == "no winner"

        md = ODEParameterEstimation._render_consensus_benchmark_markdown(artifact)
        @test occursin("## What's New", md)
        @test occursin("## Strategy Comparison", md)
        @test occursin("best_fit_baseline", md)
        @test occursin("family_consensus_refit", md)
        @test occursin("## Impact Summary", md)
        @test occursin("refined winner", md)
    end

    @testset "Synthesized benchmark rendering" begin
        artifact = Dict{Symbol, Any}(
            :model_name => "demo",
            :dataset_label => "demo-set",
            :generated_at => "2026-04-06T10:00:00",
            :total_seconds => 12.5,
            :raw_candidate_count => 4,
            :family_count => 3,
            :synthesized_seed_count => 5,
            :accepted_synthesized_seed_count => 3,
            :refined_seed_result_count => 2,
            :winning_origin => :synthesized,
            :selection_summary => Dict{Symbol, Any}(:winner_seed_kind => :parameter_stitch),
            :oracle_note => "benchmark-only",
            :run_config => Dict{Symbol, Any}(
                :interpolator => "InterpolatorAAADGPR",
                :interpolator_count => 1,
                :shooting_points => 6,
                :multipoint_n_points => 2,
                :multipoint_max_pairs => 8,
                :use_parameter_homotopy => true,
                :use_multipoint => true,
                :polish_solutions => false,
                :polish_solver_solutions => false,
                :polish_maxiters => 40,
                :polish_maxtime => 20.0,
            ),
            :consensus_config => Dict{Symbol, Any}(
                :strategy => :family_consensus,
                :support_point_count => 4,
                :support_combo_count => 4,
                :refine_top_families => 1,
                :do_equation_refit => false,
            ),
            :synth_config => Dict{Symbol, Any}(
                :max_family_seeds => 4,
                :max_cross_family_seeds => 4,
                :allow_cross_family_synthesis => true,
                :allow_parameter_stitching => true,
                :cross_family_distance_limit => 0.5,
                :seed_consistency_threshold => 100.0,
                :max_refine_candidates => 4,
                :refine_with_full_trajectory => true,
                :refine_objective_mode => :trajectory_only,
            ),
            :raw_summary => Dict{Symbol, Any}(
                :label => "raw consensus winner",
                :lineage => "raw lineage",
                :fit_error => 1.0e-4,
                :truth_metrics => Dict(
                    :parameter_rel_rmse => 0.08,
                    :combined_rel_rmse => 0.07,
                    :all_rows => [
                        (label = "a12", rel_error = 0.10),
                        (label = "a31", rel_error = 0.02),
                    ],
                ),
            ),
            :best_refined_summary => Dict{Symbol, Any}(
                :label => "best synthesized refined result",
                :lineage => "synth lineage",
                :fit_error => 8.0e-5,
                :truth_metrics => Dict(
                    :parameter_rel_rmse => 0.05,
                    :combined_rel_rmse => 0.04,
                    :all_rows => [
                        (label = "a12", rel_error = 0.03),
                        (label = "a31", rel_error = 0.015),
                    ],
                ),
            ),
            :final_summary => Dict{Symbol, Any}(
                :label => "final selected winner",
                :lineage => "stitch lineage",
                :fit_error => 8.0e-5,
                :truth_metrics => Dict(
                    :parameter_rel_rmse => 0.05,
                    :combined_rel_rmse => 0.04,
                    :all_rows => [
                        (label = "a12", rel_error = 0.03),
                        (label = "a31", rel_error = 0.015),
                    ],
                ),
            ),
            :seed_rows => [
                (rank = 1, seed_index = 3, kind = :parameter_stitch, families = "1, 2", source_candidates = "1, 4", accepted = true, pre_refine_score = 1.2, fit_loss = 1.5e-4, equation_penalty = 2.0e-5, nearest_raw_distance = 0.12),
            ],
            :refined_rows => [
                (rank = 1, lineage = "stitch lineage", fit_error = 8.0e-5, parameter_rel_rmse = 0.05, combined_rel_rmse = 0.04),
            ],
            :top_families => [
                (rank = 1, member_count = 2, family_score = 0.2, medoid_index = 1, best_member_index = 2, interpolators = "aaad_gpr", source_types = "single_point,multipoint", shooting_support = "4, 9"),
            ],
        )

        md = ODEParameterEstimation._render_synthesized_benchmark_markdown(artifact)
        @test occursin("## What's New", md)
        @test occursin("## Outcome Comparison", md)
        @test occursin("parameter_stitch", md)
        @test occursin("## Synthesized Seeds", md)
        @test occursin("## Refined Synthesized Results", md)
        @test occursin("Winning origin: `synthesized`", md)
    end

    @testset "Bilby loader fixture" begin
        fixture_dir = mktempdir()
        script_path = joinpath(fixture_dir, "script.jl")
        data_path = joinpath(fixture_dir, "data.csv")

        write(data_path, join([
            "0.0,0.5",
            "0.25,0.475",
            "0.5,0.45",
            "0.75,0.425",
            "1.0,0.4",
        ], "\n"))

        fixture_script = join([
            "using Pkg; Pkg.activate(raw\"/tmp/ignore\")",
            "using ODEParameterEstimation",
            "using ModelingToolkit, OrdinaryDiffEq",
            "using OrderedCollections",
            "using ModelingToolkit: t_nounits as t, D_nounits as D",
            "using CSV",
            "using Symbolics: Num",
            "",
            "name = \"simple_fixture\"",
            "parameters = @parameters k1",
            "states = @variables x(t)",
            "observables = @variables y1(t)",
            "state_equations = [",
            "    D(x) ~ -k1 * x,",
            "]",
            "measured_quantities = [",
            "    y1 ~ x,",
            "]",
            "ic = [0.5]",
            "p_true = [0.2]",
            "",
            "time_interval = [0.0, 1.0]",
            "datasize = 5",
            "",
            "model, mq = create_ordered_ode_system(",
            "    name,",
            "    states,",
            "    parameters,",
            "    state_equations,",
            "    measured_quantities",
            ")",
            "",
            "csv_data = CSV.read(joinpath(@__DIR__, \"data.csv\"), Tuple, header=false)",
            "data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()",
            "data_sample[\"t\"] = collect(Float64, csv_data[1])",
            "for (i, eq) in enumerate(mq)",
            "    data_sample[Num(eq.rhs)] = collect(Float64, csv_data[i + 1])",
            "end",
            "",
            "pep = ParameterEstimationProblem(",
            "    name,",
            "    model,",
            "    mq,",
            "    data_sample,",
            "    time_interval,",
            "    nothing,",
            "    OrderedDict(parameters .=> p_true),",
            "    OrderedDict(states .=> ic),",
            "    0,",
            ")",
            "",
            "opts = EstimationOptions(",
            "    datasize = length(data_sample[\"t\"]),",
            "    noise_level = 0.0,",
            ")",
            "",
            "# Run the analysis with the selected options",
            "meta, results = analyze_parameter_estimation_problem(pep, opts)",
        ], "\n")
        write(script_path, fixture_script)

        loaded = ODEParameterEstimation._load_bilby_case(fixture_dir)
        @test loaded.case_id == basename(fixture_dir)
        @test loaded.model_name == "simple_fixture"
        @test loaded.datasize == 5
        @test loaded.pep isa ODEParameterEstimation.ParameterEstimationProblem
        @test length(loaded.pep.data_sample["t"]) == 5
    end

    @testset "Benchmark result candidate import fixture" begin
        fixture_dir = mktempdir()
        script_path = joinpath(fixture_dir, "script.jl")
        data_path = joinpath(fixture_dir, "data.csv")
        result_path = joinpath(fixture_dir, "result.csv")

        write(data_path, join([
            "0.0,0.5",
            "0.25,0.475",
            "0.5,0.45",
            "0.75,0.425",
            "1.0,0.4",
        ], "\n"))
        write(result_path, join([
            "x(t),k1",
            "0.50,0.20",
            "0.55,0.18",
        ], "\n"))

        fixture_script = join([
            "using ODEParameterEstimation",
            "using ModelingToolkit",
            "using OrderedCollections",
            "using ModelingToolkit: t_nounits as t, D_nounits as D",
            "using CSV",
            "using Symbolics: Num",
            "",
            "name = \"simple_fixture\"",
            "parameters = @parameters k1",
            "states = @variables x(t)",
            "observables = @variables y1(t)",
            "state_equations = [D(x) ~ -k1 * x]",
            "measured_quantities = [y1 ~ x]",
            "ic = [0.5]",
            "p_true = [0.2]",
            "time_interval = [0.0, 1.0]",
            "datasize = 5",
            "model, mq = create_ordered_ode_system(name, states, parameters, state_equations, measured_quantities)",
            "csv_data = CSV.read(joinpath(@__DIR__, \"data.csv\"), Tuple, header=false)",
            "data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()",
            "data_sample[\"t\"] = collect(Float64, csv_data[1])",
            "for (i, eq) in enumerate(mq)",
            "    data_sample[Num(eq.rhs)] = collect(Float64, csv_data[i + 1])",
            "end",
            "pep = ParameterEstimationProblem(",
            "    name,",
            "    model,",
            "    mq,",
            "    data_sample,",
            "    time_interval,",
            "    nothing,",
            "    OrderedDict(parameters .=> p_true),",
            "    OrderedDict(states .=> ic),",
            "    0,",
            ")",
            "opts = EstimationOptions(datasize = length(data_sample[\"t\"]), noise_level = 0.0, nooutput = true, diagnostics = false, polish_solver_solutions = false, polish_solutions = false)",
            "# Run the analysis with the selected options",
            "meta, results = analyze_parameter_estimation_problem(pep, opts)",
        ], "\n")
        write(script_path, fixture_script)

        loaded = ODEParameterEstimation._load_bilby_case(fixture_dir)
        imported = ODEParameterEstimation._load_benchmark_result_candidates(loaded.pep, loaded.benchmark_opts, fixture_dir)

        @test length(imported) == 2
        @test all(result.provenance.source_type == :imported for result in imported)
        @test all(:benchmark_result_csv in result.provenance.notes for result in imported)
        # err must be a well-defined number (NaN would indicate a bug); Inf is the
        # documented sentinel for diverged integration (matches err_blown pattern in
        # optimized_multishot_estimation.jl). See _seed_loss in synthesized_finalizer.jl
        # for the try/catch -> Inf convention.
        @test all(!isnan(result.err) for result in imported)
        @test all((isfinite(result.err) || isinf(result.err)) for result in imported)
    end

    @testset "Bilby selector fallback" begin
        root = mktempdir()
        mkpath(joinpath(root, "analysis_results"))
        mkpath(joinpath(root, "filetree", "odepe_nopolish"))

        csv_path = joinpath(root, "analysis_results", "comparison_amigo2_run_vs_odepe_multipoint_full.csv")
        write(csv_path, join([
            "id,name,noise,classification,is_successful_a,is_successful_b,mean_rel_error_a,mean_rel_error_b,max_rel_error_a,max_rel_error_b,time_a,time_b",
            "seir_2_1em4,seir,0.0001,both_success,True,True,0.001,0.030,0.002,0.050,10.0,20.0",
            "alt_room_a_1em4,seir,0.0001,both_success,True,True,0.001,0.040,0.002,0.060,10.0,15.0",
            "alt_room_b_1em4,seir,0.0001,both_success,True,True,0.001,0.020,0.002,0.040,10.0,25.0",
        ], "\n"))

        mkpath(joinpath(root, "filetree", "odepe_nopolish", "alt_room_a_1em4"))
        mkpath(joinpath(root, "filetree", "odepe_nopolish", "alt_room_b_1em4"))

        selected = ODEParameterEstimation._select_bilby_sweep_cases(
            root;
            noise = 1e-4,
            case_limit = 1,
        )

        @test length(selected) == 1
        @test selected[1].case_id == "alt_room_a_1em4"
        @test selected[1].selected_via == :fallback
        @test selected[1].bucket == :both_success_room_to_improve
    end

    @testset "Bilby sweep rendering" begin
        strategy_template = Dict{Symbol, Any}(
            :status => :ok,
            :final_winner_lineage => "demo lineage",
            :winner_mode => :raw,
            :winning_origin => :raw,
            :final_winner_fit_error => 1.0e-4,
            :truth_metrics => Dict(
                :parameter_rel_rmse => 0.03,
                :combined_rel_rmse => 0.02,
                :all_rows => [
                    (label = "a31", rel_error = 0.01),
                    (label = "x3(0)", rel_error = 0.03),
                ],
            ),
        )
        case_artifact = Dict{Symbol, Any}(
            :case_id => "demo_case_1em4",
            :model_name => "demo_model",
            :bucket => :both_success_room_to_improve,
            :bucket_label => "both_success / room_to_improve",
            :selected_via => :preferred,
            :generated_at => "2026-04-06T12:00:00",
            :case_dir => "/tmp/demo_case_1em4",
            :benchmark_reference => (
                id = "demo_case_1em4",
                name = "demo_model",
                noise = 1e-4,
                classification = "both_success",
                is_successful_a = true,
                is_successful_b = true,
                mean_rel_error_a = 0.01,
                mean_rel_error_b = 0.02,
                max_rel_error_a = 0.03,
                max_rel_error_b = 0.04,
                time_a = 10.0,
                time_b = 20.0,
            ),
            :status => :ok,
            :shared_total_seconds => 2.5,
            :raw_candidate_count => 4,
            :family_count => 2,
            :raw_pool => Dict{Symbol, Any}(
                :best_fit_index => 1,
                :best_truth_index => 2,
                :best_fit_vs_truth_gap => 0.01,
            ),
            :strategies => OrderedDict(
                :best_fit_baseline => copy(strategy_template),
                :family_consensus => merge(copy(strategy_template), Dict{Symbol, Any}(
                    :final_winner_fit_error => 8.0e-5,
                    :truth_metrics => Dict(
                        :parameter_rel_rmse => 0.02,
                        :combined_rel_rmse => 0.015,
                        :all_rows => [
                            (label = "a31", rel_error = 0.008),
                            (label = "x3(0)", rel_error = 0.02),
                        ],
                    ),
                )),
                :synthesized_finalizer => merge(copy(strategy_template), Dict{Symbol, Any}(
                    :winning_origin => :synthesized,
                    :winner_mode => :synthesized,
                    :final_winner_fit_error => 7.0e-5,
                    :truth_metrics => Dict(
                        :parameter_rel_rmse => 0.015,
                        :combined_rel_rmse => 0.012,
                        :all_rows => [
                            (label = "a31", rel_error = 0.007),
                            (label = "x3(0)", rel_error = 0.015),
                        ],
                    ),
                )),
            ),
            :synthesized_seed_rows => [
                (rank = 1, seed_index = 1, kind = :parameter_stitch, families = "1, 2", source_candidates = "1, 3", accepted = true, pre_refine_score = 1.2, fit_loss = 1.0e-4, equation_penalty = 2.0e-5, nearest_raw_distance = 0.12),
            ],
            :synthesized_refined_rows => NamedTuple[],
            :run_config => Dict{Symbol, Any}(
                :interpolator => "InterpolatorAAADGPR",
                :interpolator_count => 1,
                :shooting_points => 3,
                :multipoint_n_points => 2,
                :multipoint_max_pairs => 4,
                :use_parameter_homotopy => true,
                :use_multipoint => true,
                :polish_solutions => false,
                :polish_solver_solutions => false,
                :polish_maxiters => 20,
                :polish_maxtime => 5.0,
            ),
            :primary_conclusion => :synthesis_helped,
            :secondary_conclusion => :candidate_generation_bottleneck,
        )
        sweep_artifact = Dict{Symbol, Any}(
            :benchmark_name => "benchmark_bilby_2026_03_09",
            :benchmark_root => "/tmp/benchmark",
            :generated_at => "2026-04-06T12:00:00",
            :noise_label => "1e-4",
            :oracle_note => "benchmark-only",
            :cases => [case_artifact],
            :aggregate_counts => Dict(
                :consensus_beats_baseline => 1,
                :synth_beats_baseline => 1,
                :synth_beats_consensus => 1,
                :baseline_remained_best => 0,
            ),
            :aggregate_deltas => Dict(
                :consensus_combined_mean => 0.005,
                :consensus_combined_median => 0.005,
                :synth_combined_mean => 0.008,
                :synth_combined_median => 0.008,
                :consensus_parameter_mean => 0.01,
                :consensus_parameter_median => 0.01,
                :synth_parameter_mean => 0.015,
                :synth_parameter_median => 0.015,
                :consensus_fit_mean => 2.0e-5,
                :consensus_fit_median => 2.0e-5,
                :synth_fit_mean => 3.0e-5,
                :synth_fit_median => 3.0e-5,
            ),
            :bucket_counts => OrderedDict(
                "both_success / room_to_improve" => Dict(:synthesis_helped => 1),
            ),
            :follow_up_shortlist => [
                ("biggest positive synthesis delta", case_artifact, 0.008),
                ("biggest negative synthesis delta", nothing, Inf),
                ("biggest best-fit vs best-truth divergence", case_artifact, 0.01),
            ],
        )

        case_md = ODEParameterEstimation._render_bilby_case_study_markdown(case_artifact)
        @test occursin("## Strategy Comparison", case_md)
        @test occursin("synthesized_finalizer", case_md)
        @test occursin("Primary: `synthesis_helped`", case_md)

        sweep_md = ODEParameterEstimation._render_bilby_sweep_summary_markdown(sweep_artifact)
        @test occursin("## Selected Cases", sweep_md)
        @test occursin("biggest positive synthesis delta", sweep_md)
        @test occursin("demo_case_1em4", sweep_md)

        sweep_csv = ODEParameterEstimation._render_bilby_sweep_summary_csv(sweep_artifact)
        @test occursin("case_id,model_name,bucket", sweep_csv)
        @test occursin("demo_case_1em4", sweep_csv)
    end

    @testset "Block study rendering" begin
        artifact = Dict{Symbol, Any}(
            :case_dir => "/tmp/demo_case",
            :case_id => "demo_case_1em4",
            :model_name => "demo_model",
            :generated_at => "2026-04-07T12:00:00",
            :candidate_source => :benchmark_result_csv,
            :shared_candidate_seconds => 1.0,
            :shared_context_seconds => 0.5,
            :shared_total_seconds => 1.5,
            :raw_candidate_count => 6,
            :raw_pool => Dict{Symbol, Any}(
                :best_fit_index => 1,
                :best_truth_index => 2,
                :best_fit_truth_metrics => Dict(:combined_rel_rmse => 0.20),
                :best_truth_truth_metrics => Dict(:combined_rel_rmse => 0.10),
            ),
            :baseline => Dict{Symbol, Any}(
                :strategy => :best_fit_baseline,
                :selection_seconds => 0.0,
                :effective_total_seconds => 1.5,
                :final_winner_lineage => "baseline lineage",
                :final_winner_fit_error => 1.0e-3,
                :truth_metrics => Dict(:parameter_rel_rmse => 0.30, :combined_rel_rmse => 0.20),
            ),
            :branch_v1 => Dict{Symbol, Any}(
                :strategy => :branch_consensus_v1,
                :selection_seconds => 0.2,
                :effective_total_seconds => 1.7,
                :final_winner_lineage => "branch lineage",
                :final_winner_fit_error => 8.0e-4,
                :truth_metrics => Dict(:parameter_rel_rmse => 0.25, :combined_rel_rmse => 0.18),
            ),
            :block_v2 => Dict{Symbol, Any}(
                :strategy => :block_consensus_v2,
                :selection_seconds => 0.4,
                :effective_total_seconds => 1.9,
                :final_winner_lineage => "block lineage",
                :final_winner_fit_error => 5.0e-4,
                :truth_metrics => Dict(:parameter_rel_rmse => 0.10, :combined_rel_rmse => 0.08),
            ),
            :high_correlations => [
                (lhs = "a", rhs = "d", corr = 0.91),
                (lhs = "g", rhs = "nu", corr = 0.84),
            ],
            :block_clusters => [
                (block_index = 1, variable_names = "a, b, d", cluster_index = 1, medoid_candidate_index = 4, total_weight = 0.52, dominance = 0.70, spread = 0.11, silhouette = 0.48),
                (block_index = 2, variable_names = "g, nu", cluster_index = 1, medoid_candidate_index = 2, total_weight = 0.33, dominance = 0.88, spread = 0.03, silhouette = 0.61),
            ],
            :top_hypotheses => [
                (source_clusters = "1, 1", source_candidates = "4, 2", fit_error = 5.0e-4, equation_penalty = 2.0e-4, combined_score = 0.10, polished = true, lineage = "block assembled"),
            ],
            :system_summary => Dict{Symbol, Any}(
                :states => ["In(t)", "Npop(t)", "S(t)", "Tr(t)"],
                :parameters => ["a", "b", "d", "g", "nu"],
                :observables => ["y1", "y2", "y3"],
                :datasize => 1501,
                :time_interval => [0.0, 10.0],
            ),
            :block_report => (
                variable_confidence = [
                    ODEParameterEstimation.BlockVariableConfidence("a", 1, 0.70, 0.10, 0.70, 0.80, :high),
                    ODEParameterEstimation.BlockVariableConfidence("d", 1, 0.15, 0.35, 0.70, 0.55, :low),
                ],
            ),
        )

        md = ODEParameterEstimation._render_block_consensus_study_markdown(artifact)
        @test occursin("## Strategy Comparison", md)
        @test occursin("## Inferred Blocks", md)
        @test occursin("block_consensus_v2", md)
        @test occursin("Variable Confidence", md)
    end

    @testset "Tryhard representative tie-break" begin
        replace, reason = ODEParameterEstimation._tryhard_should_replace_representative(
            Inf, Inf, 0.1, 0.2, 2, 1,
        )
        @test replace
        @test reason == :observable_loss

        replace, reason = ODEParameterEstimation._tryhard_should_replace_representative(
            1.0, 2.0, 10.0, 0.1, 2, 1,
        )
        @test replace
        @test reason == :fit

        replace, reason = ODEParameterEstimation._tryhard_should_replace_representative(
            Inf, Inf, Inf, Inf, 2, 1,
        )
        @test !replace
        @test reason == :row_index
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

    @testset "Analysis and UQ helpers handle unscored candidates" begin
        @independent_variables t
        @parameters a
        @variables x(t) y(t)
        D = Differential(t)

        model, measured_quantities = ODEParameterEstimation.create_ordered_ode_system(
            "analysis_no_scores",
            [x],
            [a],
            [D(x) ~ a * x],
            [y ~ x],
        )
        pep = ODEParameterEstimation.ParameterEstimationProblem(
            "analysis_no_scores",
            model,
            measured_quantities,
            OrderedDict{Union{String, Num}, Vector{Float64}}(
                y => [1.0, 1.1],
                "t" => [0.0, 1.0],
            ),
            [0.0, 1.0],
            nothing,
            OrderedDict(a => 1.0),
            OrderedDict(x => 1.0),
            0,
        )

        unscored_results = [
            ODEParameterEstimation.ParameterEstimationResult(
                OrderedDict(a => 1.0),
                OrderedDict(x => 1.0),
                0.0,
                nothing,
                nothing,
                2,
                nothing,
                OrderedDict{Num, Float64}(),
                Set{Num}(),
                nothing,
            ),
            ODEParameterEstimation.ParameterEstimationResult(
                OrderedDict(a => 1.5),
                OrderedDict(x => 0.9),
                0.0,
                nothing,
                nothing,
                2,
                nothing,
                OrderedDict{Num, Float64}(),
                Set{Num}(),
                nothing,
            ),
        ]

        analysis = ODEParameterEstimation.analyze_estimation_result(pep, unscored_results; nooutput = true)
        @test analysis.returned_results == Any[]
        @test all(isinf, (analysis.besterror, analysis.best_min_error, analysis.best_mean_error,
                          analysis.best_median_error, analysis.best_max_error,
                          analysis.best_approximation_error, analysis.best_rms_error))
        @test analysis.algebraic_multiplicity === nothing  # opts default = nothing → unchanged

        uq_result = ODEParameterEstimation._compute_uq_result(
            pep,
            unscored_results,
            EstimationOptions(compute_uncertainty = true, nooutput = true),
        )
        @test isnothing(uq_result)

        matern_result = first(unscored_results)
        matern_result.provenance = ODEParameterEstimation.ResultProvenance(
            interpolator_source = :s3_bic_matern52,
        )
        @test ODEParameterEstimation._uq_kernel_for_result(matern_result, EstimationOptions()) == :matern52

        default_result = last(unscored_results)
        @test ODEParameterEstimation._uq_kernel_for_result(default_result, EstimationOptions()) == :se

        @test_throws ArgumentError ODEParameterEstimation.solve_parameter_estimation(pep, (;))
    end

    @testset "Branch-diverse M selection" begin
        @independent_variables tt
        @parameters a
        @variables x(tt)

        function branch_result(a_value, x_value, err)
            return ODEParameterEstimation.ParameterEstimationResult(
                OrderedDict(a => Float64(a_value)),
                OrderedDict(x => Float64(x_value)),
                0.0,
                Float64(err),
                nothing,
                2,
                nothing,
                OrderedDict{Num, Float64}(),
                Set{Num}(),
                nothing,
            )
        end

        best = branch_result(1.0, 1.0, 1.0)
        near_duplicate = branch_result(1.001, 1.001, 1.1)
        distinct = branch_result(2.0, 2.0, 10.0)

        opts = EstimationOptions(
            algebraic_multiplicity = 2,
            branch_diversity_selection = true,
            branch_diversity_eps = 0.01,
        )
        selected = ODEParameterEstimation.select_branch_diverse_reps(
            [best, near_duplicate, distinct],
            2,
            opts,
        )
        @test selected[1] === best
        @test selected[2] === distinct

        fallback = ODEParameterEstimation.select_branch_diverse_reps(
            [best, near_duplicate],
            2,
            opts,
        )
        @test fallback[1] === best
        @test fallback[2] === near_duplicate

        disabled = ODEParameterEstimation.select_branch_diverse_reps(
            [best, near_duplicate, distinct],
            2,
            EstimationOptions(algebraic_multiplicity = 2, branch_diversity_selection = false),
        )
        @test disabled[1] === best
        @test disabled[2] === near_duplicate

        multiplicity_one = ODEParameterEstimation.select_branch_diverse_reps(
            [best, near_duplicate, distinct],
            1,
            EstimationOptions(algebraic_multiplicity = 1),
        )
        @test length(multiplicity_one) == 1
        @test multiplicity_one[1] === best
    end

    @testset "Multipoint Diagnostic Rendering" begin
        @test ODEParameterEstimation._multipoint_var_order("y1_4_pt2") == 4
        @test ODEParameterEstimation._multipoint_var_order("_obs_trfn_0_5_sin_3_pt2") == 3

        empty_blame = NamedTuple{(:data_label, :s_times_dd, :pct_of_predicted), Tuple{String, Float64, Float64}}[]
        sp_entry = ODEParameterEstimation.ErrorBudgetEntry("a12", :parameter, 1.0, 1.0, 1.0, empty_blame)
        mp_entry = ODEParameterEstimation.ErrorBudgetEntry("a12", :parameter, 1.0, 0.5, 0.5, empty_blame)
        sp_eb = ODEParameterEstimation.ErrorBudgetReport(
            "demo",
            :single_point,
            0.75,
            "aaad_gpr",
            [sp_entry],
            ["y1_3"],
            [1.0],
            [1.1],
            [0.1],
            3,
            0.01,
            0.2,
            false,
        )
        mp_eb = ODEParameterEstimation.ErrorBudgetReport(
            "demo",
            :multipoint,
            [0.75, 1.50],
            "aaad_gpr",
            [mp_entry],
            ["y1_2", "y1_2_pt2"],
            [1.0, 1.0],
            [1.1, 1.2],
            [0.1, 0.2],
            2,
            3.5,
            0.3,
            false,
        )
        eq_meta = @NamedTuple{point::Int, is_data::Bool, order::Int}[(point = 1, is_data = false, order = 3)]
        invalid_analysis = ODEParameterEstimation.MultipointDiagnosticAnalysis(
            :best_solved_combo,
            :gate_invalid,
            "selected fallback combo",
            [3, 7],
            [0.75, 1.50],
            10,
            4,
            true,
            1,
            0.1,
            1.0,
            2.0,
            false,
            "the multipoint system is too nonlinear at the selected combination for a trustworthy first-order comparison",
            ["a12"],
            ["y1_2", "y1_2_pt2"],
            2,
            12,
            8,
            5,
            2,
            [1, 2, 3, 4, 5, 6, 7, 8],
            [9, 10, 11, 12],
            eq_meta,
        )

        io = IOBuffer()
        ODEParameterEstimation._write_html_multipoint_comparison_section(io, sp_eb, mp_eb, invalid_analysis)
        html = String(take!(io))
        @test occursin("Comparison withheld", html)
        @test !occursin("<th>Improvement</th>", html)

        warned_analysis = ODEParameterEstimation.MultipointDiagnosticAnalysis(
            :best_solved_combo,
            :warn_only,
            invalid_analysis.selection_reason,
            invalid_analysis.selected_time_indices,
            invalid_analysis.selected_t_values,
            invalid_analysis.candidate_combo_count,
            invalid_analysis.solved_combo_count,
            invalid_analysis.selected_combo_solved,
            invalid_analysis.selected_combo_solution_count,
            invalid_analysis.selected_combo_worst_derivative_error,
            invalid_analysis.selected_combo_true_residual,
            invalid_analysis.selected_combo_closest_distance,
            false,
            invalid_analysis.compare_invalid_reason,
            invalid_analysis.comparable_unknown_labels,
            invalid_analysis.actual_data_labels,
            invalid_analysis.actual_max_deriv_order,
            invalid_analysis.total_equation_count,
            invalid_analysis.stripped_equation_count,
            invalid_analysis.solve_var_count,
            invalid_analysis.data_var_count,
            invalid_analysis.kept_equation_indices,
            invalid_analysis.dropped_equation_indices,
            invalid_analysis.eq_metadata,
        )
        io = IOBuffer()
        ODEParameterEstimation._write_html_multipoint_comparison_section(io, sp_eb, mp_eb, warned_analysis)
        html = String(take!(io))
        @test occursin("Comparison warning", html)
        @test occursin("<th>Improvement</th>", html)

        io = IOBuffer()
        ODEParameterEstimation._write_html_multipoint_selection_section(io, invalid_analysis)
        html = String(take!(io))
        @test occursin("Actual Multipoint Data Labels", html)
        @test occursin("Template Strip Details", html)
        @test occursin("comparison withheld", lowercase(html))
    end
end
