_unscale(value, scale::Symbol) = scale == :lin ? value : scale == :log ? exp(value) :
    scale == :log10 ? 10.0^value : throw(ArgumentError("Unsupported PEtab parameter scale: $scale"))
_scale(value, scale::Symbol) = scale == :lin ? value : scale == :log ? log(value) :
    scale == :log10 ? log10(value) : throw(ArgumentError("Unsupported PEtab parameter scale: $scale"))

function _physical_parameters(problem::PEtabAlgebraicProblem, x::AbstractVector)
    length(x) == length(problem.parameter_ids) || throw(DimensionMismatch("Wrong PEtab parameter vector length"))
    return OrderedDict(p => _unscale(v, s) for (p, v, s) in
        zip(problem.parameter_symbols, x, problem.parameter_scales))
end

function _adapter_solution(problem::PEtabAlgebraicProblem, x::AbstractVector;
        abstol::Real=1e-10, reltol::Real=1e-10)
    pep = problem.algebraic
    ps = _physical_parameters(problem, x)
    ic = OrderedDict(s => Float64(Symbolics.value(Symbolics.substitute(expr, ps)))
        for (s, expr) in problem.initial_maps)
    param_map = OrderedDict(p => ps[p] for p in pep.model.original_parameters)
    times = sort!(unique(Float64.(problem.petab.model_info.model.petab_tables[:measurements].time)))
    ode = ODEProblem(complete(pep.model.system), merge(ic, param_map),
        (pep.data_sample.initial_time, last(times)))
    return solve(ode, pep.solver; saveat=times, abstol=abstol, reltol=reltol)
end

function _adapter_predictions(problem::PEtabAlgebraicProblem, x::AbstractVector)
    sol = _adapter_solution(problem, x)
    rows = problem.petab.model_info.model.petab_tables[:measurements]
    return Float64[sol(row.time; idxs=expr) for (row, expr) in
        zip(eachrow(rows), problem.row_observables)]
end

# Invert only the initial-only parameters. Kinetic and observable parameters
# retain their algebraic values. The preparation may be overdetermined because
# the algebraic states were relaxed; the projection residual is reported.
function _candidate_vector(problem::PEtabAlgebraicProblem, candidate, x0)
    physical = _physical_parameters(problem, x0)
    merge!(physical, candidate.parameters)
    preparation_states = copy(candidate.states)
    for (cid, offset) in problem.condition_time_offsets
        iszero(offset) && continue
        states = problem.condition_states[cid]
        selected = Set(states)
        eqs = [eq for eq in equations(problem.algebraic.model.system)
            if Num(only(Symbolics.arguments(Symbolics.value(eq.lhs)))) in selected]
        params = problem.algebraic.model.original_parameters
        local_model, _ = create_ordered_ode_system("preparation_" * cid, states, params, eqs, Equation[])
        state_values = Dict(s => candidate.states[s] for s in states)
        param_values = Dict(p => physical[p] for p in params)
        ode = ODEProblem(local_model.system, merge(state_values, param_values), (offset, 0.0))
        sol = solve(ode, problem.algebraic.solver; abstol=1e-10, reltol=1e-10)
        ODEPE.SciMLBase.successful_retcode(sol) || throw(ArgumentError("Initial preparation backsolve failed for $cid"))
        for s in states
            preparation_states[s] = Float64(sol(0.0; idxs=s))
        end
    end
    dynamic = Set(problem.algebraic.model.original_parameters)
    initial_variables = Set(Num(v) for expr in values(problem.initial_maps) for v in Symbolics.get_variables(expr))
    initial_only = [p for p in problem.parameter_symbols if !(p in dynamic) && p in initial_variables]
    if !isempty(initial_only)
        expressions = collect(values(problem.initial_maps))
        jac = Symbolics.jacobian(expressions, initial_only)
        for entry in jac, v in Symbolics.get_variables(entry)
            Num(v) in initial_only && throw(ArgumentError("Nonlinear initial-only parameter map is outside the pilot"))
        end
        zero_map = merge(physical, Dict(p => 0.0 for p in initial_only))
        A = Float64[Symbolics.value(Symbolics.substitute(jac[i, j], physical))
            for i in axes(jac, 1), j in axes(jac, 2)]
        b = Float64[preparation_states[s] - Symbolics.value(Symbolics.substitute(expr, zero_map))
            for (s, expr) in problem.initial_maps]
        rank(A) == length(initial_only) || throw(ArgumentError("Initial parameter map is rank deficient"))
        estimates = A \ b
        merge!(physical, Dict(zip(initial_only, estimates)))
    end
    preparation_residual = norm(Float64[preparation_states[s] -
        Symbolics.value(Symbolics.substitute(expr, physical)) for (s, expr) in problem.initial_maps])
    x = Float64[_scale(physical[p], scale) for (p, scale) in
        zip(problem.parameter_symbols, problem.parameter_scales)]
    return x, preparation_residual
end

function _rejected_candidate(problem::PEtabAlgebraicProblem, candidate, index, reason, x)
    ids = Dict(zip(problem.parameter_symbols, problem.parameter_ids))
    return (; index, reason, x,
        algebraic_parameters=Dict(get(ids, p, string(p)) => value for (p, value) in candidate.parameters),
        algebraic_states=Dict(string(s) => value for (s, value) in candidate.states),
        provenance=provenance_metadata_dict(candidate.provenance))
end

"""
Generate candidates using the combined algebraic model, then evaluate the
original PEtab objective at each complete parameter vector. `polish`, if
provided, is a function `(petab_problem, x, remaining_seconds) -> result` whose
result has `xmin` and `fmin` fields (for example PEtab.calibrate with Fides).
The original PEtab problem is passed unchanged, including every estimate=1
parameter. An external worker is required for a hard wall-clock timeout during
noninterruptible algebraic setup; `max_seconds` bounds admission of later stages.
"""
function estimate_petab_problem(problem::PEtabAlgebraicProblem;
        options::EstimationOptions=EstimationOptions(), x0=nothing, seed::Integer=20260910,
        polish::Union{Nothing, Function}=nothing, checkpoint::Union{Nothing, Function}=nothing,
        max_seconds::Real=900.0)
    max_seconds > 0 || throw(ArgumentError("max_seconds must be positive"))
    options.compute_uncertainty && throw(ArgumentError("PEtab uncertainty quantification is outside the pilot"))
    options.flow == FlowStandard || throw(ArgumentError("The PEtab adapter generates algebraic candidates; pass a polish callback for PEtab numerical refinement"))
    if isnothing(x0)
        for row in eachrow(problem.petab.model_info.model.petab_tables[:parameters])
            _missing(_column(row, :initializationPriorType)) || throw(ArgumentError(
                "PEtab initialization distributions require an explicit starting vector in this pilot"))
        end
    end
    started = time()
    start = isnothing(x0) ? collect(PEtab.get_startguesses(MersenneTwister(seed),
        problem.petab, 1; allow_inf=true, sample_prior=false)) : Float64.(x0)
    length(start) == length(problem.parameter_ids) || throw(DimensionMismatch("Wrong starting vector length"))
    all(isfinite, start) && all(problem.petab.lower_bounds .<= start .<= problem.petab.upper_bounds) ||
        throw(ArgumentError("Starting vector must be finite and inside PEtab bounds"))
    # Raw SSE trajectory optimization would change the statistical problem.
    # Keep all returned algebraic candidates before the ordinary analysis layer's
    # multiplicity-based truncation, and score them using PEtab below.
    opts = merge_options(options; polish_solutions=false, terminal_fallback=:none,
        compute_uncertainty=false, synthesize_aggregate_candidates=false, save_system=false)
    pep, scaling = options.auto_rescale ? rescale_pep(problem.algebraic) : (problem.algebraic, nothing)
    !isnothing(scaling) && (opts = ODEPE.rescale_option_bounds(opts, scaling, problem.algebraic))
    stage = time()
    raw, _, _, _ = optimized_multishot_parameter_estimation(pep, opts)
    !isnothing(scaling) && unrescale_results(raw, scaling)
    algebraic_seconds = time() - stage
    scored = NamedTuple[]
    rejected = NamedTuple[]
    stage = time()
    for (index, candidate) in enumerate(raw)
        time() - started < max_seconds || break
        try
            x, prep_residual = _candidate_vector(problem, candidate, start)
            if !all(isfinite, x) || !all(problem.petab.lower_bounds .<= x .<= problem.petab.upper_bounds)
                push!(rejected, _rejected_candidate(problem, candidate, index, "Algebraic vector outside PEtab bounds", x))
                continue
            end
            value = problem.petab.nllh(x)
            if !isfinite(value)
                push!(rejected, _rejected_candidate(problem, candidate, index, "Nonfinite original PEtab objective", x))
                continue
            end
            push!(scored, (; index, x, nllh=Float64(value), preparation_residual=prep_residual,
                provenance=provenance_metadata_dict(candidate.provenance)))
        catch err
            ODEPE._rethrow_if_interrupt(err)
            push!(rejected, _rejected_candidate(problem, candidate, index, sprint(showerror, err), Float64[]))
        end
    end
    scoring_seconds = time() - stage
    unscored_candidate_count = length(raw) - length(scored) - length(rejected)
    sort!(scored; by=c -> c.nllh)
    if !isnothing(checkpoint)
        checkpoint((; parameter_ids=problem.parameter_ids, x0=start, candidates=scored,
            rejected, raw_candidate_count=length(raw), unscored_candidate_count, algebraic_seconds, scoring_seconds))
    end
    refined = nothing
    polish_seconds = 0.0
    polish_error = nothing
    if !isnothing(polish) && !isempty(scored) && time() - started < max_seconds
        stage = time()
        best = first(scored)
        try
            result = polish(problem.petab, copy(best.x), max_seconds - (time() - started))
            if all(isfinite, result.xmin) && all(problem.petab.lower_bounds .<= result.xmin .<= problem.petab.upper_bounds)
                value = problem.petab.nllh(result.xmin)
                if isfinite(value) && value <= best.nllh
                    refined = (; x=collect(result.xmin), nllh=Float64(value), parent_index=best.index,
                        status=string(result.converged))
                end
            end
        catch err
            ODEPE._rethrow_if_interrupt(err)
            polish_error = first(sprint(showerror, err), 2000)
        end
        polish_seconds = time() - stage
    end
    status = isempty(scored) ? (time() - started >= max_seconds ? :budget_exhausted : :no_valid_candidates) : :success
    return (; status,
        parameter_ids=problem.parameter_ids, x0=start, candidates=scored, rejected,
        raw_candidate_count=length(raw), unscored_candidate_count, refined, polish_error, algebraic_seconds, scoring_seconds,
        polish_seconds, total_seconds=time() - started, notes=copy(problem.notes))
end
