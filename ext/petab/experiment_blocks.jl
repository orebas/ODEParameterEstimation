# Opt-in, bounded experiment construction. Each block is a single-point jet of
# one condition. State derivatives are eliminated using that condition's ODE;
# parameters keep their original PEtab identity across blocks. We assemble the
# unfixed pools before applying the same rank/basis selector as multipoint.

function _experiment_groups(problem::PEtabAlgebraicProblem, groups)
    available = Set(keys(problem.condition_states))
    result = [String.(collect(group)) for group in groups]
    isempty(result) && throw(ArgumentError("At least one experiment group is required"))
    for group in result
        1 <= length(group) <= 6 || throw(ArgumentError("Experiment groups must contain 1–6 conditions"))
        length(unique(group)) == length(group) || throw(ArgumentError("Repeated condition in experiment group"))
        all(in(available), group) || throw(ArgumentError("Unknown condition in experiment group: $group"))
    end
    return result
end

function _experiment_blocks(problem::PEtabAlgebraicProblem, pep::ParameterEstimationProblem, cids)
    rhs = Dict(Num(only(Symbolics.arguments(Symbolics.value(eq.lhs)))) => Num(eq.rhs)
        for eq in equations(pep.model.system))
    all_states = Set(pep.model.original_states)
    blocks = NamedTuple[]
    for cid in cids
        condition_states = problem.condition_states[cid]
        local_set = Set(condition_states)
        indices = findall(s -> s.experiment_id == cid, pep.data_sample.series)
        measured = pep.measured_quantities[indices]
        # Auxiliary input states need an explicit per-condition mapping before
        # this route can use them. The original combined route still handles them.
        for expr in vcat([rhs[s] for s in condition_states], [Num(eq.rhs) for eq in measured])
            any(v -> Num(v) in all_states && !(Num(v) in local_set),
                Symbolics.get_variables(expr)) && throw(ArgumentError(
                    "Cross-condition or auxiliary-state dependency in $cid is outside experiment blocks"))
        end
        # Remove only states with no path to a measured observable. This exact
        # dependency closure is not a representative choice: their values cannot
        # affect the block. The full PEtab score still simulates the whole model.
        required = Set(Num(v) for eq in measured for v in Symbolics.get_variables(eq.rhs)
            if Num(v) in local_set)
        while true
            before = length(required)
            union!(required, Set(Num(v) for s in collect(required)
                for v in Symbolics.get_variables(rhs[s]) if Num(v) in local_set))
            length(required) == before && break
        end
        states = filter(s -> s in required, condition_states)
        omitted_states = filter(s -> !(s in required), condition_states)
        flat = OrderedDict(s => Symbolics.variable(Symbol(_name(s) * "_0")) for s in states)
        dynamics = Num[Symbolics.substitute(rhs[s], flat) for s in states]
        jets = Num[Symbolics.substitute(eq.rhs, flat) for eq in measured]
        data = ObservationData(pep.data_sample.series[indices]; initial_time=0.0)
        push!(blocks, (; cid, states, omitted_states, flat, dynamics, jets, measured, data))
    end
    return blocks
end

"""
    _experiment_frontier(problem, pep, cids; max_derivative_order=4, progress=identity)

Build local observation jets one order at a time and reduce their joint pool.
No single-experiment representative is fixed. Rank is a numerical test of this
finite relaxed design, not a structural-identifiability certificate. A deficient
pool at the explicit order limit is returned without attempting a polynomial solve.

# Returns
A named tuple with the selected frontier, block mappings, and construction trace.
"""
function _experiment_frontier(problem::PEtabAlgebraicProblem, pep::ParameterEstimationProblem,
        cids; max_derivative_order::Int=4, progress::Function=identity)
    0 <= max_derivative_order <= 10 || throw(ArgumentError("Experiment derivative limit must be in 0:10"))
    blocks = _experiment_blocks(problem, pep, cids)
    used = Set(Num(v) for b in blocks for expr in vcat(b.dynamics, b.jets)
        for v in Symbolics.get_variables(expr))
    params = [p for p in pep.model.original_parameters if p in used]
    # Keep even an as-yet absent unknown as a zero Jacobian column. Otherwise a
    # low-order pool could look full rank by silently dropping an unseen state.
    variables = vcat(Num.(params), reduce(vcat, [collect(values(b.flat)) for b in blocks]))
    symbolic_equations, jets = Num[], Num[]
    metadata = ODEPE.NoiseEqMeta[]
    data_map = OrderedDict{Num, Tuple{Int, Int, Int}}()
    trace = NamedTuple[]
    frontier = nothing
    for order in 0:max_derivative_order
        for (bi, block) in enumerate(blocks), (oi, jet) in enumerate(block.jets)
            dv = Symbolics.variable(Symbol(_name(block.measured[oi].lhs) * "_$order"))
            equation = ODEPE.clear_denoms(jet ~ dv)
            polynomial = Num(equation.lhs - equation.rhs)
            push!(symbolic_equations, polynomial)
            push!(jets, jet)
            push!(metadata, (point=bi, source_index=length(metadata)+1,
                max_observed_order=order,
                support_score=Float64(length(Symbolics.get_variables(polynomial))) +
                    1e-3 * length(string(polynomial))))
            data_map[dv] = (bi, oi, order)
        end
        pool = (; symbolic_equations, instantiated_equations=jets,
            instantiated_vars=variables, metadata, template_DD=nothing,
            full_equation_count=length(symbolic_equations), n_points=length(blocks))
        # Rank the rational observation map, not cleared polynomials with random
        # data: off the solution set, denominator derivatives can add false rank.
        frontier = ODEPE._noise_select_pool(pep, pool; compute_mixed_volume=false,
            candidate_limit=8, beam_width=4)
        last_row = last(frontier.frontier)
        row = (; derivative_order=order, equation_count=length(jets),
            variable_count=length(variables), rank=last_row.allowed_rank,
            selected_equation_count=isnothing(frontier.selected) ? 0 : length(frontier.selected.equations))
        push!(trace, row)
        progress((; stage=:experiment_rank, conditions=cids, trace=copy(trace)))
        !isnothing(frontier.selected) && break
        order == max_derivative_order && break
        for block in blocks
            xs = collect(values(block.flat))
            next = Num[sum((Symbolics.derivative(jet, x) * f for (x, f) in zip(xs, block.dynamics)); init=Num(0))
                for jet in block.jets]
            block.jets .= next
        end
    end
    return (; frontier, blocks, data_map, params, trace, jets)
end

function _experiment_root_error(built, selected, solved, data_values)
    try
        observed = Dict(Num(v)=>value for (v, value) in zip(selected.data_vars, data_values))
        all_data = collect(keys(built.data_map))
        for i in selected.selected_equation_indices
            predicted = Float64(Symbolics.value(Symbolics.substitute(built.jets[i], solved)))
            actual = observed[all_data[i]]
            isfinite(predicted) && abs(predicted-actual) <= 1e-5*(1+abs(actual)) ||
                return "Root fails the selected rational observation equations"
        end
        for block in built.blocks, f in block.dynamics
            isfinite(Float64(Symbolics.value(Symbolics.substitute(f, solved)))) ||
                return "Root lies at a pole of the original ODE"
        end
    catch err
        ODEPE._rethrow_if_interrupt(err)
        return "Original rational equations cannot be evaluated: " * sprint(showerror, err)
    end
    return nothing
end

function _experiment_candidates(problem::PEtabAlgebraicProblem, options::EstimationOptions,
        groups; max_derivative_order::Int=4, started::Float64=time(), max_seconds::Real=900.0,
        progress::Function=identity)
    groups = _experiment_groups(problem, groups)
    pep, scaling = options.auto_rescale ? rescale_pep(problem.algebraic) : (problem.algebraic, nothing)
    raw = NamedTuple[]
    reports = NamedTuple[]
    for (gi, cids) in enumerate(groups)
        time() - started < max_seconds || break
        group_started = time()
        progress((; stage=:experiment_construction, conditions=cids))
        built = _experiment_frontier(problem, pep, cids; max_derivative_order, progress)
        omitted_states = Dict(b.cid=>string.(b.omitted_states) for b in built.blocks)
        selected = built.frontier.selected
        if isnothing(selected)
            push!(reports, (; conditions=cids, status=:rank_deficient_at_limit,
                trace=built.trace, omitted_states, seconds=time()-group_started))
            continue
        end
        progress((; stage=:experiment_interpolation, conditions=cids, trace=built.trace))
        count_before = length(raw)
        for (method, custom) in resolve_interpolator_list(options)
            time() - started < max_seconds || break
            interp_func = ODEPE.get_interpolator_function(method, custom; s3_adapt_k=options.s3_adapt_k)
            interps = [ODEPE.create_interpolants(b.measured, b.data, b.data["t"], interp_func)
                for b in built.blocks]
            # One anchor per condition per system. Multiple small systems explore
            # the time window; they do not multiply the experiment block count.
            fractions = options.shooting_points == 1 ? [0.5] :
                collect(range(0.2, 0.8; length=options.shooting_points))
            values_list, times_list = Vector{Float64}[], Vector{Float64}[]
            for fraction in fractions
                times = [first(b.data["t"]) + fraction * (last(b.data["t"]) - first(b.data["t"]))
                    for b in built.blocks]
                values = Float64[]
                for dv in selected.data_vars
                    bi, oi, order = built.data_map[Num(dv)]
                    expr = built.blocks[bi].measured[oi].rhs
                    push!(values, ODEPE._estimation_derivative(interps[bi][expr], order, times[bi]))
                end
                all(isfinite, values) || continue
                push!(values_list, values)
                push!(times_list, times)
            end
            time() - started < max_seconds || break
            progress((; stage=:experiment_solve, conditions=cids, trace=built.trace,
                interpolator=string(interpolator_method_to_symbol(method)),
                variable_count=length(selected.solve_vars), anchor_count=length(values_list)))
            solutions = ODEPE.solve_with_hc_parameterized(selected.equations,
                selected.solve_vars, selected.data_vars, values_list;
                options=Dict(:use_column_scaling=>options.use_column_scaling,
                    :real_tol=>options.hc_real_tol, :gamma_seed=>20260910))
            for (ai, roots) in enumerate(solutions), root in roots
                solved = Dict(Num(v)=>Float64(value) for (v, value) in zip(selected.solve_vars, root))
                algebraic_validation_error = _experiment_root_error(built, selected, solved, values_list[ai])
                parameters = OrderedDict{Num, Float64}(p=>solved[p] for p in built.params)
                states = OrderedDict{Num, Float64}(s=>solved[v] for b in built.blocks for (s, v) in b.flat)
                if !isnothing(scaling)
                    for p in keys(parameters)
                        parameters[p] *= get(scaling.param_scales, p, 1.0)
                    end
                    for s in keys(states)
                        states[s] *= get(scaling.state_scales, s, 1.0)
                    end
                end
                state_times = OrderedDict(cid=>problem.condition_time_offsets[cid] + ti
                    for (cid, ti) in zip(cids, times_list[ai]))
                provenance = ODEPE.ResultProvenance(source_type=:multi_experiment,
                    interpolator_source=interpolator_method_to_symbol(method),
                    multipoint_combo_index=gi, source_shooting_index=ai,
                    equations_dropped_by_rank_trimming=selected.dropped_equation_indices,
                    notes=[:bounded_experiment_jets, :joint_rank_selection, :no_structural_certificate])
                push!(raw, (; parameters, states, state_times, provenance, algebraic_validation_error))
            end
        end
        push!(reports, (; conditions=cids, status=:algebraic_complete, trace=built.trace, omitted_states,
            raw_candidate_count=length(raw)-count_before, seconds=time()-group_started))
    end
    return raw, reports
end
