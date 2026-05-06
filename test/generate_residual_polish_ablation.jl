using Dates
using FastLevenbergMarquardt
using ForwardDiff
using LeastSquaresOptim
using ModelingToolkit
using NonlinearSolve
using ODEParameterEstimation
using OrderedCollections
using LinearAlgebra
using SciMLBase
using Statistics

const ODEPE = ODEParameterEstimation

include(joinpath(@__DIR__, "generate_log_polish_ablation.jl"))

const RESIDUAL_DEFAULT_CASE_IDS = [
    "sirt_treatment_0_1em4",
    "crauste_7_1em4",
    "fitzhugh_nagumo_2_1em4",
    "seir_4_1em4",
    "flexible_arm_0_1em4",
    "daisy_mamil3_7_1em4",
    "daisy_mamil4_6_1em4",
    "brusselator_5_1em4",
    "forced_lotka_volterra_0_1em4",
]
const RESIDUAL_OUTPUT_ROOT = get(
    ENV,
    "ODEPE_RESIDUAL_OUTPUT_ROOT",
    joinpath(@__DIR__, "..", "artifacts", "diagnostics", "residual_polish_ablation"),
)
const RESIDUAL_TRANSFORMS = [
    (:linear, "linear"),
    (:log_positive, "log"),
]

const OPTIONAL_SOLVER_LOAD_STATUS = Dict{Symbol, Tuple{Bool, String}}()

function selected_residual_case_ids()
    raw = split(get(ENV, "ODEPE_RESIDUAL_POLISH_CASE_IDS", join(RESIDUAL_DEFAULT_CASE_IDS, ",")), ",")
    return filter(!isempty, strip.(raw))
end

function selected_residual_solver_keys()
    raw = get(ENV, "ODEPE_RESIDUAL_SOLVER_KEYS", "")
    isempty(strip(raw)) && return nothing
    keys = Symbol.(filter(!isempty, strip.(split(raw, ","))))
    return Set(keys)
end

function _residual_solver_specs()
    specs = [
        (
            key = :residual_lm,
            label = "residual LM",
            solver_label = "LevenbergMarquardt()",
            package = nothing,
            solver_kind = :nonlinearsolve,
            optimizer_factory = () -> NonlinearSolve.LevenbergMarquardt(autodiff = nothing),
            jacobian_mode = :forward,
        ),
        (
            key = :residual_fastshortcut,
            label = "residual FastShortcut",
            solver_label = "FastShortcutNLLSPolyalg()",
            package = nothing,
            solver_kind = :nonlinearsolve,
            optimizer_factory = () -> NonlinearSolve.FastShortcutNLLSPolyalg(
                concrete_jac = true,
                autodiff = nothing,
                jvp_autodiff = nothing,
                vjp_autodiff = nothing,
            ),
            jacobian_mode = :forward,
        ),
        (
            key = :residual_trustregion,
            label = "residual TrustRegion",
            solver_label = "TrustRegion()",
            package = nothing,
            solver_kind = :nonlinearsolve,
            optimizer_factory = () -> NonlinearSolve.TrustRegion(autodiff = nothing),
            jacobian_mode = :forward,
        ),
        (
            key = :residual_lso_lm,
            label = "residual LeastSquaresOptim LM",
            solver_label = "LeastSquaresOptimJL(:lm)",
            package = :LeastSquaresOptim,
            solver_kind = :nonlinearsolve,
            optimizer_factory = () -> LeastSquaresOptimJL(:lm; autodiff = nothing),
            jacobian_mode = :forward,
        ),
        (
            key = :residual_lso_lm_bounded,
            label = "residual LeastSquaresOptim LM bounded",
            solver_label = "LeastSquaresOptim.optimize!(LevenbergMarquardt(); lower/upper)",
            package = :LeastSquaresOptim,
            solver_kind = :lso_direct,
            optimizer_factory = () -> LeastSquaresOptim.LevenbergMarquardt(),
            jacobian_mode = :forward,
            bounds_mode = :bounded,
        ),
        (
            key = :residual_lso_dogleg,
            label = "residual LeastSquaresOptim Dogleg",
            solver_label = "LeastSquaresOptimJL(:dogleg)",
            package = :LeastSquaresOptim,
            solver_kind = :nonlinearsolve,
            optimizer_factory = () -> LeastSquaresOptimJL(:dogleg; autodiff = nothing),
            jacobian_mode = :forward,
        ),
        (
            key = :residual_lso_dogleg_bounded,
            label = "residual LeastSquaresOptim Dogleg bounded",
            solver_label = "LeastSquaresOptim.optimize!(Dogleg(); lower/upper)",
            package = :LeastSquaresOptim,
            solver_kind = :lso_direct,
            optimizer_factory = () -> LeastSquaresOptim.Dogleg(),
            jacobian_mode = :forward,
            bounds_mode = :bounded,
        ),
        (
            key = :residual_fastlm,
            label = "residual FastLevenbergMarquardt",
            solver_label = "FastLevenbergMarquardt.lmsolve!()",
            package = :FastLevenbergMarquardt,
            solver_kind = :fastlm_direct,
            optimizer_factory = () -> nothing,
            jacobian_mode = :forward,
        ),
        (
            key = :residual_fastlm_bounded,
            label = "residual FastLevenbergMarquardt bounded",
            solver_label = "FastLevenbergMarquardt.lmsolve!() with lb/ub",
            package = :FastLevenbergMarquardt,
            solver_kind = :fastlm_direct,
            optimizer_factory = () -> nothing,
            jacobian_mode = :forward,
            bounds_mode = :bounded,
        ),
    ]
    selected = selected_residual_solver_keys()
    isnothing(selected) && return specs
    return filter(spec -> spec.key in selected, specs)
end

function _residual_arm_key(base_key::Symbol, coordinate_transform::Symbol)
    suffix = coordinate_transform == :linear ? :linear : :log
    return Symbol(base_key, "_", suffix)
end

function _residual_arm_label(base_label::AbstractString, coordinate_transform::Symbol)
    suffix = _coord_label_short(coordinate_transform)
    return "$(base_label) $(suffix)"
end

function _residual_optional_package_status(pkg::Symbol)
    return get!(OPTIONAL_SOLVER_LOAD_STATUS, pkg) do
        if pkg == :LeastSquaresOptim
            return true, "loaded"
        end
        path = Base.find_package(String(pkg))
        isnothing(path) && return false, "package $(pkg) not installed in current project"
        try
            if pkg == :FastLevenbergMarquardt
                @eval using FastLevenbergMarquardt
            else
                Core.eval(@__MODULE__, Expr(:using, pkg))
            end
            return true, "loaded"
        catch err
            return false, sprint(showerror, err)
        end
    end
end

function _large_residual_value(res)
    return convert(eltype(res), 1e6)
end

function _residual_polish_single_from_context(
    ctx::ODEPE.PolishContext,
    p0::AbstractVector{<:Real};
    optimizer = NonlinearSolve.LevenbergMarquardt(autodiff = nothing),
    solver_kind::Symbol = :nonlinearsolve,
    jacobian_mode::Symbol = :forward,
    bounds_mode::Symbol = :unbounded,
    regularization_lambda::Real = 0.0,
    regularization_mode::Symbol = :none,
    maxiters::Int = 200000,
    lso_delta::Union{Nothing, Float64} = nothing,
    lso_x_tol::Union{Nothing, Float64} = nothing,
    lso_f_tol::Union{Nothing, Float64} = nothing,
    lso_g_tol::Union{Nothing, Float64} = nothing,
)
    has_external_bounds = !isnothing(ctx.lb) && !isnothing(ctx.ub)
    p0_external = has_external_bounds ? clamp.(Float64.(p0), ctx.lb, ctx.ub) : Float64.(p0)
    p0_internal = ODEPE._polish_external_to_internal(p0_external, ctx.coordinate_transform)
    internal_lb = bounds_mode == :bounded ? ctx.internal_lb : nothing
    internal_ub = bounds_mode == :bounded ? ctx.internal_ub : nothing
    λ, reg_mode = _validate_research_regularization(ctx.coordinate_transform, regularization_mode, regularization_lambda)
    penalty_scale = reg_mode == :none ? 0.0 : sqrt(λ)

    residual_count = sum(length(target) for target in ctx.data_targets) + (reg_mode == :none ? 0 : length(p0_internal))
    residual_count == 0 && throw(ArgumentError("Residual polish requires at least one observed datum"))

    function residual!(res, p_internal, _)
        p_all = ODEPE._polish_internal_to_external(p_internal, ctx.coordinate_transform)
        ic_guess = @view p_all[1:ctx.n_ic]
        param_guess = @view p_all[(ctx.n_ic + 1):end]

        prob_opt = remake(
            ctx.base_ode_prob;
            u0 = Dict(ctx.unknown_syms .=> ic_guess),
            p = Dict(ctx.param_syms .=> param_guess),
            build_initializeprob = false,
        )

        sol_opt = try
            ModelingToolkit.solve(
                prob_opt,
                ctx.solver;
                saveat = ctx.t_vector,
                abstol = ctx.abstol,
                reltol = ctx.reltol,
                maxiters = ctx.polish_ode_maxiters,
            )
        catch
            fill!(res, _large_residual_value(res))
            return nothing
        end

        if sol_opt.retcode != SciMLBase.ReturnCode.Success
            fill!(res, _large_residual_value(res))
            return nothing
        end

        idx = 1
        @inbounds for (j, f) in enumerate(ctx.obs_funcs)
            data_true = ctx.data_targets[j]
            for i in eachindex(ctx.t_vector)
                res[idx] = f(sol_opt.u[i], param_guess) - data_true[i]
                idx += 1
            end
        end
        if reg_mode == :l2_log
            @inbounds for i in eachindex(p_internal)
                res[idx] = penalty_scale * p_internal[i]
                idx += 1
            end
        end
        return nothing
    end

    function residual_vec(p_internal)
        r = Vector{eltype(p_internal)}(undef, residual_count)
        residual!(r, p_internal, nothing)
        return r
    end

    jacobian! = if jacobian_mode == :forward
        function (J, u, p)
            ForwardDiff.jacobian!(J, residual_vec, u)
            return nothing
        end
    else
        nothing
    end
    resid_proto = zeros(eltype(p0_internal), residual_count)
    jac_proto = zeros(eltype(p0_internal), residual_count, length(p0_internal))
    nf = isnothing(jacobian!) ?
        NonlinearFunction(residual!; resid_prototype = resid_proto, jac_prototype = jac_proto) :
        NonlinearFunction(
            residual!;
            resid_prototype = resid_proto,
            jac_prototype = jac_proto,
            jac = jacobian!,
        )
    prob = NonlinearLeastSquaresProblem(nf, p0_internal)

    initial_residual = zeros(residual_count)
    residual!(initial_residual, p0_internal, nothing)
    initial_norm = norm(initial_residual)

    candidate_internal = p0_internal
    solver_result = nothing
    if solver_kind == :fastlm_direct
        J0 = zeros(eltype(p0_internal), residual_count, length(p0_internal))
        f0 = zeros(eltype(p0_internal), residual_count)
        workspace = FastLevenbergMarquardt.LMWorkspace(copy(p0_internal), f0, J0)
        linear_solver = length(p0_internal) <= residual_count ? :qr : :cholesky
        fastlm_residual! = (res, u, p) -> begin
            residual!(res, u, p)
            return res
        end
        fastlm_jacobian! = (J, u, p) -> begin
            jacobian!(J, u, p)
            return J
        end
        result = FastLevenbergMarquardt.lmsolve!(
            fastlm_residual!,
            fastlm_jacobian!,
            workspace,
            nothing,
            internal_lb,
            internal_ub;
            solver = linear_solver,
            xtol = ctx.reltol,
            ftol = ctx.reltol,
            gtol = ctx.abstol,
            maxit = maxiters,
        )
        solver_result = result
        candidate_internal = result[1]
    elseif solver_kind == :lso_direct
        problem = LeastSquaresOptim.LeastSquaresProblem(
            x = copy(p0_internal),
            f! = (out, x) -> residual!(out, x, nothing),
            g! = (J, x) -> jacobian!(J, x, nothing),
            output_length = residual_count,
        )
        result = LeastSquaresOptim.optimize!(
            problem,
            optimizer;
            x_tol = something(lso_x_tol, ctx.reltol),
            f_tol = something(lso_f_tol, ctx.reltol),
            g_tol = something(lso_g_tol, ctx.abstol),
            iterations = maxiters,
            Δ = something(lso_delta, 10.0),
            lower = isnothing(internal_lb) ? eltype(p0_internal)[] : internal_lb,
            upper = isnothing(internal_ub) ? eltype(p0_internal)[] : internal_ub,
        )
        solver_result = result
        candidate_internal = result.minimizer
    else
        nlls_sol = NonlinearSolve.solve(prob, optimizer; abstol = ctx.abstol, reltol = ctx.reltol, maxiters = maxiters)
        solver_result = nlls_sol
        candidate_internal = SciMLBase.successful_retcode(nlls_sol) ? nlls_sol.u : p0_internal
    end

    final_residual = similar(initial_residual)
    residual!(final_residual, candidate_internal, nothing)
    final_norm = norm(final_residual)

    p_opt_internal, objective_residual = if isfinite(final_norm) && final_norm <= initial_norm
        candidate_internal, final_residual
    else
        p0_internal, initial_residual
    end

    p_opt = ODEPE._polish_internal_to_external(p_opt_internal, ctx.coordinate_transform)
    ic_opt = p_opt[1:ctx.n_ic]
    param_opt = p_opt[(ctx.n_ic + 1):end]

    prob_final = remake(
        ctx.base_ode_prob;
        u0 = Dict(ctx.unknown_syms .=> ic_opt),
        p = Dict(ctx.param_syms .=> param_opt),
        build_initializeprob = false,
    )
    sol_final = ModelingToolkit.solve(prob_final, ctx.solver; saveat = ctx.t_vector, abstol = ctx.abstol, reltol = ctx.reltol)

    states_out = OrderedDict(s => ic_opt[ctx.state_index[s]] for s in ctx.state_syms_out if haskey(ctx.state_index, s))
    params_out = OrderedDict(p => param_opt[ctx.param_index[p]] for p in ctx.param_syms_out if haskey(ctx.param_index, p))
    final_obj = sum(abs2, objective_residual)

    final_result = ODEPE.ParameterEstimationResult(
        params_out,
        states_out,
        ctx.t_vector[1],
        final_obj,
        nothing,
        length(ctx.t_vector),
        ctx.t_vector[1],
        OrderedDict{Num, Float64}(),
        Set{Num}(),
        sol_final,
    )
    final_result.provenance = ODEPE.ResultProvenance(
        primary_method = :direct_opt,
        post_polish_error = final_obj,
    )
    ODEPE.sync_result_contract!(final_result)
    return final_result, solver_result
end

function build_residual_mode_report(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    run_opts::ODEPE.EstimationOptions,
    coordinate_transform::Symbol;
    optimizer = NonlinearSolve.LevenbergMarquardt(autodiff = nothing),
    solver_kind::Symbol = :nonlinearsolve,
    jacobian_mode::Symbol = :forward,
    bounds_mode::Symbol = :unbounded,
    regularization_lambda::Real = 0.0,
    regularization_mode::Symbol = :none,
    maxiters_override::Union{Nothing, Int} = nothing,
    lso_delta::Union{Nothing, Float64} = nothing,
    lso_x_tol::Union{Nothing, Float64} = nothing,
    lso_f_tol::Union{Nothing, Float64} = nothing,
    lso_g_tol::Union{Nothing, Float64} = nothing,
)
    timed = @timed begin
        ctx = ODEPE._build_polish_context(pep; opts = run_opts, coordinate_transform = coordinate_transform)
        cluster_meta = ODEPE._polish_cluster_metadata(ctx, raw_candidates; opts = run_opts)
        cluster_reps = cluster_meta.cluster_reps
        clamped_p0s = cluster_meta.clamped_p0s
        polish_maxiters = something(maxiters_override, run_opts.polish_maxiters)

        polished_pool = ODEPE.ParameterEstimationResult[]
        append!(polished_pool, raw_candidates)

        for rep_idx in cluster_reps
            candidate = raw_candidates[rep_idx]
            polished_result, _ = _residual_polish_single_from_context(
                ctx,
                clamped_p0s[rep_idx];
                optimizer = optimizer,
                solver_kind = solver_kind,
                jacobian_mode = jacobian_mode,
                bounds_mode = bounds_mode,
                regularization_lambda = regularization_lambda,
                regularization_mode = regularization_mode,
                maxiters = polish_maxiters,
                lso_delta = lso_delta,
                lso_x_tol = lso_x_tol,
                lso_f_tol = lso_f_tol,
                lso_g_tol = lso_g_tol,
            )
            polished_result.unident_dict = deepcopy(candidate.unident_dict)
            polished_result.all_unidentifiable = copy(candidate.all_unidentifiable)
            polished_result.provenance = ODEPE.copy_provenance(
                candidate.provenance;
                pre_polish_error = candidate.err,
                post_polish_error = polished_result.err,
                polish_applied = true,
            )
            push!(polished_pool, polished_result)
        end

        analyzed_candidates = _analyze_candidates_for_research(pep, polished_pool)
        selected_idx, selected_candidate = ODEPE._best_fit_raw_candidate(analyzed_candidates)
        selected_benchmark = _benchmark_metric_row(pep, selected_candidate)
        selected_local = _local_metric_row(pep, selected_candidate)
        best_bench_idx, best_bench_metrics, _ = _best_candidate_by_metric(pep, analyzed_candidates, _benchmark_metric_row)
        best_local_idx, best_local_metrics, _ = _best_candidate_by_metric(pep, analyzed_candidates, _local_metric_row)

        Dict{Symbol, Any}(
            :status => :ok,
            :polished_pool_count => length(polished_pool),
            :cluster_rep_count => length(cluster_reps),
            :analyzed_candidates => analyzed_candidates,
            :analyzed_candidate_count => length(analyzed_candidates),
            :selected_index => selected_idx,
            :selected_candidate => selected_candidate,
            :selected_benchmark_metrics => selected_benchmark,
            :selected_local_metrics => selected_local,
            :best_benchmark_index => best_bench_idx,
            :best_benchmark_metrics => best_bench_metrics,
            :best_local_index => best_local_idx,
            :best_local_metrics => best_local_metrics,
            :regularization_lambda => Float64(regularization_lambda),
            :regularization_mode => regularization_mode,
            :maxiters => polish_maxiters,
            :lso_delta => lso_delta,
            :lso_x_tol => lso_x_tol,
            :lso_f_tol => lso_f_tol,
            :lso_g_tol => lso_g_tol,
        )
    end
    payload = timed.value
    payload[:build_and_run_seconds] = timed.time
    return payload
end

function safe_residual_mode_report(
    pep::ODEPE.ParameterEstimationProblem,
    raw_candidates::Vector{ODEPE.ParameterEstimationResult},
    run_opts::ODEPE.EstimationOptions,
    coordinate_transform::Symbol;
    optimizer_factory = () -> NonlinearSolve.LevenbergMarquardt(autodiff = nothing),
    solver_kind::Symbol = :nonlinearsolve,
    jacobian_mode::Symbol = :forward,
    bounds_mode::Symbol = :unbounded,
    regularization_lambda::Real = 0.0,
    regularization_mode::Symbol = :none,
    solver_label::AbstractString = "LevenbergMarquardt()",
    required_package::Union{Nothing, Symbol} = nothing,
    maxiters_override::Union{Nothing, Int} = nothing,
    lso_delta::Union{Nothing, Float64} = nothing,
    lso_x_tol::Union{Nothing, Float64} = nothing,
    lso_f_tol::Union{Nothing, Float64} = nothing,
    lso_g_tol::Union{Nothing, Float64} = nothing,
)
    if !isnothing(required_package)
        available, reason = _residual_optional_package_status(required_package)
        if !available
            return Dict{Symbol, Any}(
                :status => :unsupported,
                :reason => reason,
                :solver_label => solver_label,
                :build_and_run_seconds => Inf,
                :analyzed_candidate_count => 0,
                :polished_pool_count => 0,
                :cluster_rep_count => 0,
                :regularization_lambda => Float64(regularization_lambda),
                :regularization_mode => regularization_mode,
                :maxiters => maxiters_override,
                :lso_delta => lso_delta,
                :lso_x_tol => lso_x_tol,
                :lso_f_tol => lso_f_tol,
                :lso_g_tol => lso_g_tol,
                :selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
                :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
                :best_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
                :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
            )
        end
    end

    try
        optimizer = optimizer_factory()
        report = build_residual_mode_report(
            pep,
            raw_candidates,
            run_opts,
            coordinate_transform;
            optimizer = optimizer,
            solver_kind = solver_kind,
            jacobian_mode = jacobian_mode,
            bounds_mode = bounds_mode,
            regularization_lambda = regularization_lambda,
            regularization_mode = regularization_mode,
            maxiters_override = maxiters_override,
            lso_delta = lso_delta,
            lso_x_tol = lso_x_tol,
            lso_f_tol = lso_f_tol,
            lso_g_tol = lso_g_tol,
        )
        report[:solver_label] = solver_label
        return report
    catch err
        status = (coordinate_transform == :log_positive && err isa ArgumentError) ? :unsupported : :error
        return Dict{Symbol, Any}(
            :status => status,
            :reason => sprint(showerror, err),
            :solver_label => solver_label,
            :build_and_run_seconds => Inf,
            :analyzed_candidate_count => 0,
            :polished_pool_count => 0,
            :cluster_rep_count => 0,
            :regularization_lambda => Float64(regularization_lambda),
            :regularization_mode => regularization_mode,
            :maxiters => maxiters_override,
            :lso_delta => lso_delta,
            :lso_x_tol => lso_x_tol,
            :lso_f_tol => lso_f_tol,
            :lso_g_tol => lso_g_tol,
            :selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
            :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
            :best_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
            :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
        )
    end
end

function build_residual_case_artifact(case_id::AbstractString)
    spec = parse_case_spec(case_id)
    comparison_run = comparison_run_ordinal(spec)
    nopolish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_nopolish"))
    polish_case = ODEPE._load_bilby_case(case_dir_for_variant(case_id, "odepe_polish"))
    pep = polish_case.pep
    run_opts, box_meta = _resolve_research_run_opts(pep, polish_case.case_dir, polish_case.benchmark_opts)
    raw_candidates = ODEPE._load_benchmark_result_candidates(pep, run_opts, nopolish_case.case_dir)

    artifact = Dict{Symbol, Any}(
        :case_id => case_id,
        :spec => spec,
        :comparison_run => comparison_run,
        :research_analysis_mode => _research_analysis_mode(),
        :raw_candidate_count => length(raw_candidates),
        :raw_stage_trace => _raw_stage_trace(pep, raw_candidates),
        :saved_amigo_metrics => load_selected_metrics(spec, "amigo2_run"; comparison_run = comparison_run),
        :saved_nopolish_metrics => load_selected_metrics(spec, "odepe_nopolish"; comparison_run = comparison_run),
        :saved_polish_metrics => load_selected_metrics(spec, "odepe_polish"; comparison_run = comparison_run),
        :box_meta => box_meta,
        :residual_solver_specs => _residual_solver_specs(),
    )
    artifact[:scalar_linear] = safe_polish_mode_report(pep, raw_candidates, run_opts, :linear)
    artifact[:scalar_log] = safe_polish_mode_report(pep, raw_candidates, run_opts, :log_positive)
    for spec in artifact[:residual_solver_specs]
        for (coordinate_transform, _) in RESIDUAL_TRANSFORMS
            arm_key = _residual_arm_key(spec.key, coordinate_transform)
            artifact[arm_key] = safe_residual_mode_report(
                pep,
                raw_candidates,
                run_opts,
                coordinate_transform;
                optimizer_factory = spec.optimizer_factory,
                solver_kind = spec.solver_kind,
                jacobian_mode = spec.jacobian_mode,
                bounds_mode = get(spec, :bounds_mode, :unbounded),
                solver_label = spec.solver_label,
                required_package = spec.package,
            )
        end
    end
    return artifact
end

function build_residual_case_artifact_safe(case_id::AbstractString)
    try
        return build_residual_case_artifact(case_id)
    catch err
        reason = sprint(showerror, err)
        specs = _residual_solver_specs()
        empty_report = Dict{Symbol, Any}(
            :status => :error,
            :reason => reason,
            :build_and_run_seconds => Inf,
            :selected_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
            :selected_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
            :best_benchmark_metrics => Dict{Symbol, Any}(:rmse => Inf, :max_rel_err => Inf, :success => false),
            :best_local_metrics => Dict{Symbol, Any}(:combined_rel_rmse => Inf),
        )
        artifact = Dict{Symbol, Any}(
            :case_id => String(case_id),
            :raw_candidate_count => 0,
            :raw_stage_trace => Dict{Symbol, Any}(),
            :saved_amigo_metrics => nothing,
            :saved_nopolish_metrics => nothing,
            :saved_polish_metrics => nothing,
            :box_meta => nothing,
            :artifact_error => reason,
            :scalar_linear => deepcopy(empty_report),
            :scalar_log => deepcopy(empty_report),
            :residual_solver_specs => specs,
        )
        for spec in specs
            artifact[_residual_arm_key(spec.key, :linear)] = deepcopy(empty_report)
            artifact[_residual_arm_key(spec.key, :log_positive)] = deepcopy(empty_report)
        end
        return artifact
    end
end

_maybe_get(x, key, default) = x === nothing ? default : get(x, key, default)

function _arm_selected_rmse(artifact, key::Symbol)
    return _maybe_get(_maybe_get(_maybe_get(artifact, key, Dict{Symbol, Any}()), :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)
end

function _arm_best_rmse(artifact, key::Symbol)
    return _maybe_get(_maybe_get(_maybe_get(artifact, key, Dict{Symbol, Any}()), :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)
end

function _arm_selected_status(artifact, key::Symbol)
    return _maybe_get(_maybe_get(artifact, key, Dict{Symbol, Any}()), :status, :missing)
end

function _arm_runtime(artifact, key::Symbol)
    return _maybe_get(_maybe_get(artifact, key, Dict{Symbol, Any}()), :build_and_run_seconds, Inf)
end

function _comparison_counts(case_artifacts, arm_key::Symbol, baseline_key::Symbol; metric_fn = _arm_best_rmse)
    better = 0
    tie = 0
    worse = 0
    unsupported = 0
    ratios = Float64[]
    for artifact in case_artifacts
        arm_status = _arm_selected_status(artifact, arm_key)
        base_status = _arm_selected_status(artifact, baseline_key)
        if arm_status != :ok || base_status != :ok
            unsupported += 1
            continue
        end
        cmp = _compare(metric_fn(artifact, arm_key), metric_fn(artifact, baseline_key))
        cmp == :better && (better += 1)
        cmp == :tie && (tie += 1)
        cmp == :worse && (worse += 1)
        base_runtime = _arm_runtime(artifact, baseline_key)
        arm_runtime = _arm_runtime(artifact, arm_key)
        if isfinite(base_runtime) && base_runtime > 0 && isfinite(arm_runtime)
            push!(ratios, arm_runtime / base_runtime)
        end
    end
    return Dict(
        :better => better,
        :tie => tie,
        :worse => worse,
        :unsupported => unsupported,
        :median_runtime_ratio => isempty(ratios) ? Inf : median(ratios),
    )
end

function render_residual_summary_tsv(path::AbstractString, case_artifacts)
    mkpath(dirname(path))
    specs = isempty(case_artifacts) ? _residual_solver_specs() : case_artifacts[1][:residual_solver_specs]
    headers = [
        "case_id",
        "raw_candidate_count",
        "imported_best_benchmark_rmse",
        "analyzed_input_best_benchmark_rmse",
        "analyzed_input_selected_benchmark_rmse",
        "saved_amigo_rmse",
        "saved_polish_rmse",
        "scalar_linear_best_rmse",
        "scalar_log_best_rmse",
    ]
    for spec in specs
        push!(headers, string(spec.key, "_linear_best_rmse"))
        push!(headers, string(spec.key, "_log_best_rmse"))
        push!(headers, string(spec.key, "_linear_vs_scalar_linear"))
        push!(headers, string(spec.key, "_log_vs_scalar_log"))
    end
    open(path, "w") do io
        println(io, join(headers, '\t'))
        for artifact in case_artifacts
            row = String[
                artifact[:case_id],
                string(artifact[:raw_candidate_count]),
                string(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :imported_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(_maybe_get(_maybe_get(artifact, :saved_amigo_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(_maybe_get(_maybe_get(artifact, :saved_polish_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                string(_arm_best_rmse(artifact, :scalar_linear)),
                string(_arm_best_rmse(artifact, :scalar_log)),
            ]
            for spec in specs
                linear_key = _residual_arm_key(spec.key, :linear)
                log_key = _residual_arm_key(spec.key, :log_positive)
                push!(row, string(_arm_best_rmse(artifact, linear_key)))
                push!(row, string(_arm_best_rmse(artifact, log_key)))
                push!(row, string(_compare(_arm_best_rmse(artifact, linear_key), _arm_best_rmse(artifact, :scalar_linear))))
                push!(row, string(_compare(_arm_best_rmse(artifact, log_key), _arm_best_rmse(artifact, :scalar_log))))
            end
            println(io, join(row, '\t'))
        end
    end
end

function _render_arm(io, label::AbstractString, report::AbstractDict)
    println(io, "- $(label):")
    println(io, "  - status: `$(get(report, :status, :missing))`")
    if get(report, :status, :missing) == :ok
        println(io, "  - selected benchmark RMSE: $(_fmt_pct(_maybe_get(_maybe_get(report, :selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
        println(io, "  - best-in-set benchmark RMSE: $(_fmt_pct(_maybe_get(_maybe_get(report, :best_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
        println(io, "  - selected local relative RMSE: $(_fmt_pct(_maybe_get(_maybe_get(report, :selected_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)))")
        println(io, "  - best-in-set local relative RMSE: $(_fmt_pct(_maybe_get(_maybe_get(report, :best_local_metrics, Dict{Symbol, Any}()), :combined_rel_rmse, Inf)))")
        println(io, "  - runtime: `$(_format_float(get(report, :build_and_run_seconds, Inf); digits = 3)) s`")
        if haskey(report, :cluster_rep_count)
            println(io, "  - polished representative count: `$(get(report, :cluster_rep_count, 0))`")
        end
    else
        println(io, "  - reason: `$(get(report, :reason, "missing"))`")
    end
end

function render_residual_summary_md(path::AbstractString, case_artifacts)
    mkpath(dirname(path))
    specs = isempty(case_artifacts) ? _residual_solver_specs() : case_artifacts[1][:residual_solver_specs]
    open(path, "w") do io
        println(io, "# Residual-Vector Polish Ablation\n")
        println(io, "- Generated: `$(Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"))`")
        println(io, "- Basis: imported bilby `odepe_nopolish` pools")
        println(io, "- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool")
        analysis_mode = isempty(case_artifacts) ? :unknown : get(first(case_artifacts), :research_analysis_mode, :unknown)
        println(io, "- Research analysis mode: `$(analysis_mode)`")
        println(io, "- Residual solver roster: `$(join([spec.solver_label for spec in specs], "`, `"))`")
        println(io, "- Benchmark success tolerance: `10%` max relative error\n")

        header = ["Case", "Imported best RMSE", "Analyzed imported best RMSE", "Saved `amigo2` RMSE", "Saved `odepe_polish` RMSE", "Scalar log best"]
        align = ["---", "---:", "---:", "---:", "---:", "---:"]
        for spec in specs
            push!(header, "$(spec.label) log best")
            push!(align, "---:")
        end
        println(io, "| $(join(header, " | ")) |")
        println(io, "| $(join(align, " | ")) |")
        for artifact in case_artifacts
            row = [
                "`$(artifact[:case_id])`",
                _fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :imported_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                _fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                _fmt_pct(_maybe_get(_maybe_get(artifact, :saved_amigo_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                _fmt_pct(_maybe_get(_maybe_get(artifact, :saved_polish_metrics, Dict{Symbol, Any}()), :rmse, Inf)),
                _fmt_pct(_arm_best_rmse(artifact, :scalar_log)),
            ]
            for spec in specs
                push!(row, _fmt_pct(_arm_best_rmse(artifact, _residual_arm_key(spec.key, :log_positive))))
            end
            println(io, "| $(join(row, " | ")) |")
        end

        println(io, "\n## Solver Summary vs `scalar + log`\n")
        println(io, "| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |")
        println(io, "| --- | --- | --- | ---: |")
        for spec in specs
            log_key = _residual_arm_key(spec.key, :log_positive)
            best_counts = _comparison_counts(case_artifacts, log_key, :scalar_log; metric_fn = _arm_best_rmse)
            selected_counts = _comparison_counts(case_artifacts, log_key, :scalar_log; metric_fn = _arm_selected_rmse)
            best_summary = "$(best_counts[:better]) better / $(best_counts[:tie]) tie / $(best_counts[:worse]) worse / $(best_counts[:unsupported]) unsupported"
            selected_summary = "$(selected_counts[:better]) better / $(selected_counts[:tie]) tie / $(selected_counts[:worse]) worse / $(selected_counts[:unsupported]) unsupported"
            println(io, "| `$(spec.solver_label)` | $(best_summary) | $(selected_summary) | $(_format_float(best_counts[:median_runtime_ratio]; digits = 3))x |")
        end

        println(io, "\n## Case Notes\n")
        for artifact in case_artifacts
            println(io, "### `$(artifact[:case_id])`\n")
            if haskey(artifact, :artifact_error)
                println(io, "- Artifact build error: `$(artifact[:artifact_error])`")
            end
            println(io, "- Imported raw candidate count: `$(artifact[:raw_candidate_count])`")
            println(io, "- Imported pool stage metrics:")
            println(io, "  - imported best benchmark RMSE: $(_fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :imported_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - analyzed imported selected benchmark RMSE: $(_fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_selected_benchmark_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - analyzed imported best benchmark RMSE: $(_fmt_pct(get(get(get(artifact, :raw_stage_trace, Dict{Symbol, Any}()), :analyzed_best_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            if !isnothing(get(artifact, :box_meta, nothing))
                println(io, "- Research box override: `$(artifact[:box_meta].source)` (`[1e-5, 10]` on all polished coordinates)")
            end
            println(io, "- Saved references:")
            println(io, "  - `amigo2_run` RMSE: $(_fmt_pct(_maybe_get(_maybe_get(artifact, :saved_amigo_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - `odepe_nopolish` RMSE: $(_fmt_pct(_maybe_get(_maybe_get(artifact, :saved_nopolish_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            println(io, "  - `odepe_polish` RMSE: $(_fmt_pct(_maybe_get(_maybe_get(artifact, :saved_polish_metrics, Dict{Symbol, Any}()), :rmse, Inf)))")
            _render_arm(io, "scalar $(_coord_label_short(:linear))", get(artifact, :scalar_linear, Dict{Symbol, Any}()))
            _render_arm(io, "scalar $(_coord_label_short(:log_positive))", get(artifact, :scalar_log, Dict{Symbol, Any}()))
            for spec in specs
                linear_key = _residual_arm_key(spec.key, :linear)
                log_key = _residual_arm_key(spec.key, :log_positive)
                _render_arm(io, _residual_arm_label(spec.label, :linear), get(artifact, linear_key, Dict{Symbol, Any}()))
                _render_arm(io, _residual_arm_label(spec.label, :log_positive), get(artifact, log_key, Dict{Symbol, Any}()))
                println(io, "- $(spec.label) $(_coord_label_short(:linear)) vs scalar $(_coord_label_short(:linear)) best-in-set benchmark RMSE: `$(string(_compare(_arm_best_rmse(artifact, linear_key), _arm_best_rmse(artifact, :scalar_linear))))`")
                println(io, "- $(spec.label) $(_coord_label_short(:log_positive)) vs scalar $(_coord_label_short(:log_positive)) best-in-set benchmark RMSE: `$(string(_compare(_arm_best_rmse(artifact, log_key), _arm_best_rmse(artifact, :scalar_log))))`")
            end
            println(io)
        end
    end
end

function render_residual_progress(path::AbstractString, case_ids::AbstractVector{<:AbstractString}, artifacts)
    mkpath(dirname(path))
    updated_at = Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS")
    completed_ids = [artifact[:case_id] for artifact in artifacts]
    remaining = setdiff(case_ids, completed_ids)
    open(path, "w") do io
        println(io, "completed_cases=$(length(artifacts))")
        println(io, "requested_cases=$(length(case_ids))")
        println(io, "completed_case_ids=$(join(completed_ids, ','))")
        println(io, "remaining_case_ids=$(join(remaining, ','))")
        println(io, "updated_at=$(updated_at)")
    end
end

function main()
    mkpath(RESIDUAL_OUTPUT_ROOT)
    case_ids = selected_residual_case_ids()
    artifacts = Dict{Symbol, Any}[]
    summary_tsv = joinpath(RESIDUAL_OUTPUT_ROOT, "summary.tsv")
    summary_md = joinpath(RESIDUAL_OUTPUT_ROOT, "summary.md")
    progress_path = joinpath(RESIDUAL_OUTPUT_ROOT, "progress.txt")
    for (idx, case_id) in enumerate(case_ids)
        println("[$idx/$(length(case_ids))] Running $(case_id)")
        artifact = build_residual_case_artifact_safe(case_id)
        push!(artifacts, artifact)
        render_residual_summary_tsv(summary_tsv, artifacts)
        render_residual_summary_md(summary_md, artifacts)
        render_residual_progress(progress_path, case_ids, artifacts)
        println("[$idx/$(length(case_ids))] Flushed $(case_id)")
    end
    println("Wrote residual polish ablation to $(RESIDUAL_OUTPUT_ROOT)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
