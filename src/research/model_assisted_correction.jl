# Research-only model-assisted correction for derivative-based algebraic roots.
#
# This is deliberately not an EstimationOptions arm.  It consumes the exact
# selected SP/MP artifact retained for estimator-aware UQ, simulates the pilot
# ODE once, estimates the retained smoother's deterministic jet distortion, and
# updates the same polynomial branch.  Promotion into the production candidate
# pool requires the staged benchmark and influence-calculus gates documented in
# docs/2026-08-15_estimation_uq_research_program.md.

function _mac_recipe(
    pep::ParameterEstimationProblem,
    artifact::SinglePointUQArtifact,
)
    metadata = _uq_single_point_meta(artifact, pep)
    return (
        equations = artifact.equations,
        solve_vars = artifact.solve_vars,
        data_vars = artifact.data_vars,
        data_values = copy(artifact.data_values),
        root = Float64.(real.(artifact.root)),
        interpolants = artifact.interpolants,
        time_indices = Int[artifact.time_index],
        times = Float64[artifact.time_value],
        metadata,
    )
end

function _mac_recipe(
    ::ParameterEstimationProblem,
    artifact::MultipointUQArtifact,
)
    evaluation = artifact.evaluation
    template = evaluation.template
    return (
        equations = template.stripped_equations,
        solve_vars = template.solve_vars,
        data_vars = template.data_vars,
        data_values = copy(evaluation.data_values),
        root = Float64.(real.(artifact.root)),
        interpolants = artifact.interpolants,
        time_indices = copy(evaluation.time_indices),
        times = copy(evaluation.t_values),
        metadata = copy(template.data_var_meta),
    )
end

function _mac_recipe(::ParameterEstimationProblem, artifact::AbstractEstimatorArtifact)
    throw(ArgumentError(
        "model-assisted correction supports retained single- or multipoint algebraic artifacts; got $(typeof(artifact))",
    ))
end

"""Stable evaluation of a retained fixed GP smoother on alternative raw data."""
function _mac_fixed_smoother_jet(
    interp::AGPInterpolatorUQ,
    raw_values::AbstractVector{<:Real},
    time_value::Real,
    max_order::Int,
)
    length(raw_values) == length(interp.xs_train) || throw(ArgumentError(
        "model trajectory length does not match the retained GP training grid",
    ))
    values = Float64.(raw_values)
    values_mean = mean(values)
    values_std = max(std(values), 1e-8)
    normalized = (values .- values_mean) ./ values_std
    alpha = interp.chol \ normalized
    kstar = _build_K_star_n(interp, time_value, max_order)
    jet = values_std .* (kstar * alpha)
    jet[1] += values_mean
    return Vector{Float64}(jet)
end

function _mac_observable_series(
    pep::ParameterEstimationProblem,
    result::ParameterEstimationResult,
    mq,
    sample_times::AbstractVector{<:Real},
)
    isnothing(result.solution) && throw(ArgumentError(
        "the reconstructed pilot has no successful ODE trajectory",
    ))
    completed = ModelingToolkit.complete(pep.model.system)
    states = ModelingToolkit.unknowns(completed)
    params = ModelingToolkit.parameters(completed)
    t_var = ModelingToolkit.get_iv(completed)
    param_values = _uq_ordered_result_values(result.parameters, params)
    any(!isfinite, param_values) && throw(ArgumentError(
        "the reconstructed pilot is missing model parameters",
    ))
    built = ModelingToolkit.build_function(
        mq.rhs, states, params, t_var; expression = Val(false),
    )
    observable = built isa Tuple ? built[1] : built
    output = Vector{Float64}(undef, length(sample_times))
    for (i, time_value) in enumerate(sample_times)
        state_values = Float64.(real.(result.solution(Float64(time_value))))
        value = observable(state_values, param_values, Float64(time_value))
        output[i] = Float64(real(value isa AbstractArray ? only(value) : value))
    end
    return output
end

function _mac_model_data_values(
    pep::ParameterEstimationProblem,
    pilot_result::ParameterEstimationResult,
    interpolants::AbstractDict,
    times::Vector{Float64},
    metadata::Vector{DataVarMeta},
    observed_data_values::Vector{Float64},
)
    length(observed_data_values) == length(metadata) || throw(ArgumentError(
        "observed data and data-variable metadata lengths differ",
    ))
    unresolved = findall(meta -> meta.kind == :unresolved, metadata)
    isempty(unresolved) || throw(ArgumentError(
        "model-assisted correction cannot resolve data-variable rows $unresolved",
    ))
    max_order = maximum((meta.order for meta in metadata
                         if meta.kind == :observable_jet); init = 0)

    state_taylors = Vector{Dict{Num, Vector{Float64}}}(undef, length(times))
    observable_taylors = Vector{Dict{Num, Vector{Float64}}}(undef, length(times))
    for point in eachindex(times)
        state_taylors[point] = compute_estimate_taylor_coefficients(
            pep, pilot_result, times[point], max_order + 1,
        )
        estimate_pep = _pep_with_estimate_values(
            pep, pilot_result, state_taylors[point],
        )
        observable_taylors[point] = compute_observable_taylor_coefficients(
            estimate_pep, state_taylors[point], times[point], max_order + 1,
        )
    end

    used_observables = sort(unique(Int[
        meta.obs_idx for meta in metadata
        if meta.kind == :observable_jet && !isnothing(meta.obs_idx)
    ]))
    smoother_jets = Dict{Tuple{Int, Int}, Vector{Float64}}()
    for obs_idx in used_observables
        mq = pep.measured_quantities[obs_idx]
        interp = _uq_exact_interpolant(interpolants, mq)
        interp isa AGPInterpolatorUQ || throw(ArgumentError(
            "observable '$(_uq_observation_name(mq))' does not retain an AGPInterpolatorUQ; exact fixed-smoother correction is unavailable",
        ))
        model_series = _mac_observable_series(
            pep, pilot_result, mq, interp.xs_train,
        )
        obs_max_order = maximum((meta.order for meta in metadata
                                 if meta.kind == :observable_jet &&
                                    meta.obs_idx == obs_idx); init = 0)
        for point in eachindex(times)
            smoother_jets[(obs_idx, point)] = _mac_fixed_smoother_jet(
                interp, model_series, times[point], obs_max_order,
            )
        end
    end

    smoothed = zeros(length(metadata))
    exact = zeros(length(metadata))
    for (row, meta) in enumerate(metadata)
        if meta.kind == :observable_jet
            obs_idx = something(meta.obs_idx)
            mq = pep.measured_quantities[obs_idx]
            obs_key = ModelingToolkit.diff2term(mq.rhs)
            coefficients = get(observable_taylors[meta.point], obs_key, nothing)
            isnothing(coefficients) && throw(ArgumentError(
                "model-exact Taylor coefficients are unavailable for '$(_uq_observation_name(mq))'",
            ))
            exact[row] = coefficients[meta.order + 1] * factorial(meta.order)
            smoothed[row] = smoother_jets[(obs_idx, meta.point)][meta.order + 1]
        elseif meta.kind == :transcendental
            # Known analytic inputs are not produced by a data smoother, so their
            # model-assisted bias is exactly zero. Retain the actual value in the
            # report rather than displaying a fictitious zero-valued input.
            exact[row] = observed_data_values[row]
            smoothed[row] = observed_data_values[row]
        else
            throw(ArgumentError(
                "unsupported model-assisted data-variable kind $(meta.kind)",
            ))
        end
    end
    return smoothed, exact
end

function _mac_trfn_state_value(state, time_value::Float64)
    base_name = replace(string(state), "(t)" => "")
    info = _parse_trfn_base_name(base_name)
    isnothing(info) && return nothing
    kind, frequency = info
    kind == :sin && return sin(frequency * time_value)
    kind == :cos && return cos(frequency * time_value)
    kind == :exp && return exp(frequency * time_value)
    return nothing
end

function _mac_result_from_root(
    pep::ParameterEstimationProblem,
    parent::ParameterEstimationResult,
    recipe,
    root::Vector{Float64},
    data_values::Vector{Float64};
    estimator_kind::Union{Nothing, Symbol},
    abstol::Float64,
    reltol::Float64,
)
    data_labels = string.(recipe.data_vars)
    augmented_values, augmented_metadata, _ = _uq_augment_direct_observation_rows(
        pep, recipe.solve_vars, data_values, recipe.metadata, data_labels,
        recipe.time_indices, recipe.times,
    )
    _, local_labels, _, local_values = _uq_local_output_map(
        pep, recipe.solve_vars, augmented_values, root, augmented_metadata,
        zeros(length(root), length(augmented_values)),
    )
    local_by_name = Dict(local_labels .=> local_values)

    completed = ModelingToolkit.complete(pep.model.system)
    completed_states = ModelingToolkit.unknowns(completed)
    completed_params = ModelingToolkit.parameters(completed)
    t_shoot = first(recipe.times)
    t0 = Float64(first(pep.data_sample["t"]))
    parameter_values = Float64[
        get(local_by_name, _uq_clean_name(param), NaN) for param in completed_params
    ]
    state_values = Float64[]
    for state in completed_states
        name = _uq_clean_name(state)
        value = get(local_by_name, name, NaN)
        if !isfinite(value)
            trfn_value = _mac_trfn_state_value(state, t_shoot)
            !isnothing(trfn_value) && (value = Float64(trfn_value))
        end
        push!(state_values, value)
    end
    any(!isfinite, parameter_values) && throw(ArgumentError(
        "corrected algebraic root is missing a model parameter",
    ))
    any(!isfinite, state_values) && throw(ArgumentError(
        "corrected algebraic root is missing a shooting-point state",
    ))

    solver = isnothing(pep.solver) ? package_wide_default_ode_solver : pep.solver
    state_values_t0 = if abs(t_shoot - t0) <= 1e-12
        state_values
    else
        backward_problem = ODEProblem(
            completed,
            merge(
                Dict(completed_states .=> state_values),
                Dict(completed_params .=> parameter_values),
            ),
            (t_shoot, t0),
        )
        backward_solution = ModelingToolkit.solve(
            backward_problem, solver; abstol, reltol,
        )
        SciMLBase.successful_retcode(backward_solution) || throw(ErrorException(
            "corrected-root backsolve failed with $(backward_solution.retcode)",
        ))
        Float64.(real.(backward_solution(t0)))
    end

    state_t0_by_name = Dict(
        _uq_clean_name(state) => state_values_t0[i]
        for (i, state) in enumerate(completed_states)
    )
    param_by_name = Dict(
        _uq_clean_name(param) => parameter_values[i]
        for (i, param) in enumerate(completed_params)
    )
    current_states = ModelingToolkit.unknowns(pep.model.system)
    current_params = ModelingToolkit.parameters(pep.model.system)
    raw = vcat(
        Float64[state_t0_by_name[_uq_clean_name(state)] for state in current_states],
        Float64[param_by_name[_uq_clean_name(param)] for param in current_params],
    )
    ordered_states, ordered_params, solution, fit_error = process_raw_solution(
        raw, pep.model, pep.data_sample, solver; abstol, reltol,
    )

    notes = Symbol[note for note in parent.provenance.notes if note != :rescaled]
    if !isnothing(estimator_kind)
        push!(notes, :model_assisted_one_step)
        push!(notes, :uq_unavailable_pending_model_assisted_influence)
    end
    identity = if isnothing(estimator_kind)
        copy_estimator_identity(parent.provenance.estimator_identity)
    else
        parent_identity = ensure_result_estimator_identity!(parent)
        _run_ctx_new_identity!(
            estimator_kind = estimator_kind,
            data_scope = :model_assisted_point_set,
            time_indices = recipe.time_indices,
            time_values = recipe.times,
            interpolator_source = parent.provenance.interpolator_source,
            parent_candidate_ids = Int[parent_identity.candidate_id],
        )
    end
    provenance = copy_provenance(
        parent.provenance;
        pre_polish_error = isnothing(estimator_kind) ?
            parent.provenance.pre_polish_error : parent.err,
        post_polish_error = fit_error,
        polish_applied = false,
        notes,
        source_type = isnothing(estimator_kind) ?
            parent.provenance.source_type : :model_assisted_correction,
        estimator_identity = identity,
    )
    result = ParameterEstimationResult(
        ordered_params, ordered_states, t_shoot, Float64(fit_error),
        nothing, length(pep.data_sample["t"]), t0,
        isnothing(parent.unident_dict) ? nothing : deepcopy(parent.unident_dict),
        copy(parent.all_unidentifiable), solution,
        parent.provenance.interpolator_source, provenance, parent.branch_size,
    )
    sync_result_contract!(result)
    return result
end

function _mac_local_newton(
    fn,
    start::Vector{Float64},
    data_values::Vector{Float64};
    max_iterations::Int,
    tolerance::Float64,
)
    root = copy(start)
    last_residual = Inf
    for iteration in 0:max_iterations
        residual = Float64.(fn(vcat(root, data_values)))
        last_residual = norm(residual, Inf)
        last_residual <= tolerance &&
            return root, true, iteration, last_residual
        iteration == max_iterations && break
        jacobian = try
            Float64.(ForwardDiff.jacobian(
                candidate -> fn(vcat(candidate, data_values)), root,
            ))
        catch err
            _rethrow_if_interrupt(err)
            return root, false, iteration, last_residual
        end
        step = try
            jacobian \ residual
        catch err
            _rethrow_if_interrupt(err)
            return root, false, iteration, last_residual
        end
        all(isfinite, step) || return root, false, iteration, last_residual

        accepted = false
        step_scale = 1.0
        for _ in 1:18
            trial = root .- step_scale .* step
            trial_residual = norm(Float64.(fn(vcat(trial, data_values))), Inf)
            if isfinite(trial_residual) && trial_residual < last_residual
                root = trial
                accepted = true
                break
            end
            step_scale *= 0.5
        end
        accepted || return root, false, iteration, last_residual
    end
    return root, false, max_iterations, last_residual
end

function _mac_fit_error(result::Union{Nothing, ParameterEstimationResult})
    isnothing(result) && return Inf
    isnothing(result.err) && return Inf
    value = Float64(result.err)
    return isfinite(value) ? value : Inf
end

function _mac_screen_corrected_result(
    pilot::ParameterEstimationResult,
    linear::Union{Nothing, ParameterEstimationResult},
    resolved::Union{Nothing, ParameterEstimationResult},
)
    candidates = ParameterEstimationResult[
        candidate for candidate in (linear, resolved) if !isnothing(candidate)
    ]
    isempty(candidates) && return (
        nothing,
        :no_usable_candidate,
        "no corrected candidate produced a finite trajectory objective",
    )
    corrected = candidates[argmin(_mac_fit_error.(candidates))]
    corrected_error = _mac_fit_error(corrected)
    isfinite(corrected_error) || return (
        nothing,
        :no_usable_candidate,
        "no corrected candidate produced a finite trajectory objective",
    )
    pilot_error = _mac_fit_error(pilot)
    if !isfinite(pilot_error) || corrected_error < pilot_error
        return (
            corrected,
            :trajectory_objective_improved,
            "corrected candidate lowered the observed-data trajectory objective",
        )
    end
    return (
        nothing,
        :trajectory_objective_not_improved,
        "corrected candidates did not lower the observed-data trajectory objective",
    )
end

"""
    research_model_assisted_one_step(pep, selected, artifact; kwargs...)

Apply one model-assisted bias correction to the exact retained algebraic
estimator selected by production.  `pep` must be the same transformed/rescaled
problem that produced `artifact`; the returned results therefore use those
working coordinates and should be unscaled only after all optional polishing.

The function produces two candidate estimators:

1. `linear_result`: the literal IFT update `x₁ = x₀ - S*b̂`;
2. `resolved_result`: a cheap local Newton re-solve of the same polynomial
   branch at corrected data `d - b̂`.

No trajectory optimizer is run.  The only trajectory work is reconstructing
and simulating the pilot plus final candidate scoring.

`screened_result` is the lower-trajectory-SSE corrected candidate only when it
beats the reconstructed pilot on that same observed-data objective.  This is a
truth-free catastrophe screen, not evidence that the parameter estimate or a
subsequent polish must improve.

# Arguments
- `pep`: transformed/rescaled estimation problem matching the retained artifact.
- `selected`: selected public pilot result (used for lineage and metadata).
- `artifact`: retained `SinglePointUQArtifact` or `MultipointUQArtifact`.
- `abstol`, `reltol`: ODE reconstruction tolerances.
- `newton_max_iterations`: local polynomial re-solve iteration cap.
- `newton_tolerance`: infinity-norm polynomial residual target.

# Returns
- [`ModelAssistedCorrectionReport`](@ref). Corrected UQ is deliberately
  unavailable pending pilot-through-correction influence derivation.
"""
function research_model_assisted_one_step(
    pep::ParameterEstimationProblem,
    selected::ParameterEstimationResult,
    artifact::AbstractEstimatorArtifact;
    abstol::Float64 = 1e-12,
    reltol::Float64 = 1e-12,
    newton_max_iterations::Int = 30,
    newton_tolerance::Float64 = 1e-10,
)
    newton_max_iterations >= 0 || throw(ArgumentError(
        "newton_max_iterations must be non-negative",
    ))
    newton_tolerance > 0 || throw(ArgumentError(
        "newton_tolerance must be positive",
    ))
    timings = OrderedDict{Symbol, Float64}()
    recipe = _mac_recipe(pep, artifact)
    all(isfinite, recipe.root) || throw(ArgumentError(
        "retained pilot root contains non-finite values",
    ))
    all(isfinite, recipe.data_values) || throw(ArgumentError(
        "retained pilot data contains non-finite values",
    ))
    fn = _compile_system_function(
        recipe.equations, vcat(recipe.solve_vars, recipe.data_vars),
    )
    pilot_residual = norm(fn(vcat(recipe.root, recipe.data_values)), Inf)

    t0 = time()
    pilot_result = _mac_result_from_root(
        pep, selected, recipe, recipe.root, recipe.data_values;
        estimator_kind = nothing, abstol, reltol,
    )
    timings[:pilot_reconstruction] = time() - t0

    t0 = time()
    model_smoothed, model_exact = _mac_model_data_values(
        pep, pilot_result, recipe.interpolants, recipe.times, recipe.metadata,
        recipe.data_values,
    )
    timings[:model_bias_estimation] = time() - t0
    estimated_bias = model_smoothed - model_exact
    corrected_data = recipe.data_values - estimated_bias

    t0 = time()
    sensitivity, _ = _uq_exact_ift(
        recipe.equations, recipe.solve_vars, recipe.data_vars,
        recipe.root, recipe.data_values,
    )
    linear_root = recipe.root - sensitivity * estimated_bias
    linear_residual = norm(fn(vcat(linear_root, corrected_data)), Inf)
    timings[:linear_update] = time() - t0

    linear_result = try
        _mac_result_from_root(
            pep, selected, recipe, linear_root, corrected_data;
            estimator_kind = :model_assisted_linear,
            abstol, reltol,
        )
    catch err
        _rethrow_if_interrupt(err)
        @warn "Model-assisted linear candidate could not be reconstructed" exception = (err, catch_backtrace())
        nothing
    end

    t0 = time()
    resolved_root, resolved_ok, newton_iterations, resolved_residual =
        _mac_local_newton(
            fn, linear_root, corrected_data;
            max_iterations = newton_max_iterations,
            tolerance = newton_tolerance,
        )
    timings[:local_polynomial_resolve] = time() - t0
    resolved_result = if resolved_ok
        try
            _mac_result_from_root(
                pep, selected, recipe, resolved_root, corrected_data;
                estimator_kind = :model_assisted_local_resolve,
                abstol, reltol,
            )
        catch err
            _rethrow_if_interrupt(err)
            @warn "Model-assisted resolved candidate could not be reconstructed" exception = (err, catch_backtrace())
            nothing
        end
    else
        nothing
    end

    status = if !isnothing(resolved_result)
        :resolved
    elseif !isnothing(linear_result)
        :linear_only
    else
        :failed
    end
    message = if status == :resolved
        "model-assisted local branch re-solve converged"
    elseif status == :linear_only
        "local branch re-solve did not converge; linear IFT candidate retained"
    else
        "neither corrected candidate produced a usable trajectory"
    end
    screened_result, screen_status, screen_message =
        _mac_screen_corrected_result(
            pilot_result, linear_result, resolved_result,
        )
    correction_norm = norm(estimated_bias) / max(norm(recipe.data_values), 1e-300)
    return ModelAssistedCorrectionReport(
        status, message, screen_status, screen_message,
        pilot_result, linear_result, resolved_result, screened_result,
        string.(recipe.data_vars), copy(recipe.data_values), model_smoothed,
        model_exact, estimated_bias, corrected_data, copy(recipe.root),
        linear_root, resolved_root, Float64(pilot_residual),
        Float64(linear_residual), Float64(resolved_residual),
        newton_iterations, Float64(correction_norm), timings,
    )
end
