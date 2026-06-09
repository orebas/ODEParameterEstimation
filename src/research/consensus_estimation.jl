function _consensus_source_symbol(candidate, default_source::Symbol)
    source = hasproperty(candidate, :provenance) ? candidate.provenance.interpolator_source : candidate.interpolator_source
    return isnothing(source) ? default_source : source
end

# _consensus_candidate_pep relocated to core/parameter_estimation_helpers.jl (2026-06-09)
# so production (branch_completion, sensitivity_seeds) no longer calls into this
# research file. It remains available in the module namespace for use here.

function _consensus_support_labels(si_template, pep::ParameterEstimationProblem)
    obs_names = Set(replace(string(mq.lhs), "(t)" => "") for mq in pep.measured_quantities)
    labels = String[]
    seen = Set{String}()
    all_eqs = hasproperty(si_template, :all_equations) ? si_template.all_equations : si_template.equations
    for eq in all_eqs
        for v in Symbolics.get_variables(eq)
            vname = replace(string(v), r"_pt\d+$" => "")
            parsed = parse_derivative_variable_name(vname)
            if !isnothing(parsed)
                base_name, _ = parsed
                if base_name in obs_names && !(vname in seen)
                    push!(labels, vname)
                    push!(seen, vname)
                end
            end
        end
    end
    return labels
end

function _consensus_observable_rhs(pep::ParameterEstimationProblem, base_name::String)
    for mq in pep.measured_quantities
        lhs_name = replace(string(mq.lhs), "(t)" => "")
        lhs_name == base_name && return ModelingToolkit.diff2term(mq.rhs)
    end
    return nothing
end

function _consensus_interpolated_value(
    interpolants::Dict,
    pep::ParameterEstimationProblem,
    label::AbstractString,
    t_eval::Float64,
)
    clean_name = replace(String(label), r"_pt\d+$" => "")
    trfn_val = evaluate_trfn_template_variable(clean_name, t_eval)
    if isnothing(trfn_val)
        trfn_val = evaluate_obs_trfn_template_variable(clean_name, t_eval)
    end
    !isnothing(trfn_val) && return Float64(trfn_val)

    parsed = parse_derivative_variable_name(clean_name)
    isnothing(parsed) && return NaN
    base_name, deriv_order = parsed
    rhs = _consensus_observable_rhs(pep, String(base_name))
    isnothing(rhs) && return NaN
    haskey(interpolants, rhs) || return NaN
    interp = interpolants[rhs]
    return try
        Float64(nth_deriv(x -> interp(x), deriv_order, t_eval))
    catch
        NaN
    end
end

function _consensus_point_agreement_score(
    pep::ParameterEstimationProblem,
    label_set::Vector{String},
    interpolant_cache::Dict{Symbol, Dict},
    point_idx::Int,
    t_vector::Vector{Float64},
)
    length(interpolant_cache) <= 1 && return 0.0
    t_eval = t_vector[point_idx]
    disagreements = Float64[]
    for label in label_set
        vals = Float64[
            _consensus_interpolated_value(interpolants, pep, label, t_eval)
            for interpolants in values(interpolant_cache)
        ]
        vals = filter(isfinite, vals)
        length(vals) <= 1 && continue
        scale = max(abs(mean(vals)), 1e-12)
        push!(disagreements, std(vals) / scale)
    end
    isempty(disagreements) && return 0.0
    return median(disagreements)
end

function _consensus_support_point_candidates(candidates, point_indices)
    support = Int[]
    append!(support, point_indices)
    for candidate in candidates
        prov = candidate.provenance
        !isnothing(prov.source_shooting_index) && push!(support, prov.source_shooting_index)
        if !isnothing(prov.multipoint_time_indices)
            append!(support, prov.multipoint_time_indices)
        end
    end
    sort!(support)
    unique!(support)
    return filter(idx -> idx >= 1, support)
end

function _select_consensus_support_points(
    pep::ParameterEstimationProblem,
    candidates,
    point_indices::Vector{Int},
    label_set::Vector{String},
    interpolant_cache::Dict{Symbol, Dict},
    consensus_opts::ConsensusOptions,
    t_vector::Vector{Float64},
)
    support = _consensus_support_point_candidates(candidates, point_indices)
    support = filter(idx -> idx <= length(t_vector), support)
    isempty(support) && return Int[]

    if length(interpolant_cache) > 1
        ranked = sort(support; by = idx -> (
            _consensus_point_agreement_score(pep, label_set, interpolant_cache, idx, t_vector),
            idx,
        ))
        return ranked[1:min(consensus_opts.support_point_count, length(ranked))]
    end

    earliest_first = sort(support)
    return earliest_first[1:min(consensus_opts.support_point_count, length(earliest_first))]
end

function _support_combo_sort_key(combo::Vector{Int})
    spread = sum(abs(combo[j] - combo[i]) for i in 1:length(combo) for j in (i+1):length(combo))
    return (-spread, combo)
end

function _select_consensus_support_combos(
    candidates,
    support_points::Vector{Int},
    n_points::Int,
    consensus_opts::ConsensusOptions,
)
    n_points <= 1 && return Vector{Vector{Int}}()

    combo_counts = Dict{Tuple{Vararg{Int}}, Int}()
    for candidate in candidates
        mp = candidate.provenance.multipoint_time_indices
        if !isnothing(mp) && length(mp) == n_points
            key = Tuple(sort(mp))
            combo_counts[key] = get(combo_counts, key, 0) + 1
        end
    end

    combos = [collect(key) for key in keys(combo_counts)]
    sort!(combos; by = combo -> (-get(combo_counts, Tuple(combo), 0), _support_combo_sort_key(combo)))

    if length(combos) < consensus_opts.support_combo_count && length(support_points) >= n_points
        generated = _index_combinations(sort(support_points), n_points)
        sort!(generated; by = _support_combo_sort_key)
        for combo in generated
            key = Tuple(combo)
            key in keys(combo_counts) && continue
            push!(combos, combo)
            length(combos) >= consensus_opts.support_combo_count && break
        end
    end

    return [Int[combo...] for combo in combos[1:min(consensus_opts.support_combo_count, length(combos))]]
end

function _reuse_bundle_compatible(
    reuse_bundle,
    pep::ParameterEstimationProblem,
    opts::EstimationOptions,
    interpolator_sources::Vector{Symbol},
)
    isnothing(reuse_bundle) && return false
    hasproperty(reuse_bundle, :model_system) || return false
    reuse_bundle.model_system === pep.model.system || return false
    data_length = isnothing(pep.data_sample) || !haskey(pep.data_sample, "t") ? 0 : length(pep.data_sample["t"])
    reuse_bundle.data_length == data_length || return false
    reuse_bundle.use_multipoint == (opts.use_multipoint && opts.system_solver == SolverHC) || return false
    reuse_bundle.multipoint_n_points == opts.multipoint_n_points || return false
    return Set(reuse_bundle.interpolator_sources) == Set(interpolator_sources)
end

function _build_consensus_context(
    pep::ParameterEstimationProblem,
    opts::EstimationOptions;
    reuse_bundle = nothing,
)
    ident_data = setup_identifiability(pep; max_num_points = 1, nooutput = true)
    t_vector = ident_data.t_vector
    ordered_model = pep.model
    si_template, _ = prepare_si_template_with_structural_fix(
        ordered_model,
        pep.measured_quantities,
        pep.data_sample,
        ident_data.good_DD,
        false;
        states = ident_data.states,
        params = ident_data.params,
        infolevel = 0,
        placeholder_fail_categories = opts.si_placeholder_fail_categories,
    )

    interpolator_list = resolve_interpolator_list(opts)
    # Auto-filter AAA-family interpolators that are catastrophic at the data's noise level.
    interpolator_list = maybe_filter_interpolators_by_noise(interpolator_list, pep, opts)
    isempty(interpolator_list) && error("Consensus estimation requires at least one configured interpolator.")

    interpolant_cache = Dict{Symbol, Dict}()
    interpolator_function_cache = Dict{Symbol, Function}()
    for (method, custom) in interpolator_list
        source = interpolator_method_to_symbol(method)
        interp_func = get_interpolator_function(method, custom; s3_adapt_k = opts.s3_adapt_k)
        interpolator_function_cache[source] = interp_func
        interpolant_cache[source] = create_interpolants(pep.measured_quantities, pep.data_sample, t_vector, interp_func)
    end
    interpolator_sources = Symbol[interpolator_method_to_symbol(method) for (method, _) in interpolator_list]
    compatible_reuse_bundle = _reuse_bundle_compatible(reuse_bundle, pep, opts, interpolator_sources) ? reuse_bundle : nothing
    default_source = first(keys(interpolant_cache))

    point_indices = if opts.shooting_points == 0
        [max(1, min(length(t_vector), round(Int, 0.499 * length(t_vector))))]
    else
        compute_shooting_indices(min(opts.shooting_points, length(t_vector)), length(t_vector);
            warp = opts.shooting_warp, beta = opts.shooting_warp_beta)
    end

    mpt_setup = (
        good_deriv_level = ident_data.good_deriv_level,
        good_udict = ident_data.good_udict,
        good_varlist = ident_data.good_varlist,
        good_DD = ident_data.good_DD,
        interpolants = interpolant_cache[default_source],
    )
    mpt = if opts.use_multipoint && opts.system_solver == SolverHC
        try
            build_multipoint_template(pep, mpt_setup, si_template;
                n_points = opts.multipoint_n_points,
                diagnostics = false)
        catch
            nothing
        end
    else
        nothing
    end

    return (
        pep = pep,
        opts = opts,
        ident_data = ident_data,
        si_template = si_template,
        mpt = mpt,
        t_vector = t_vector,
        point_indices = point_indices,
        interpolant_cache = interpolant_cache,
        interpolator_function_cache = interpolator_function_cache,
        default_source = default_source,
        support_labels = _consensus_support_labels(si_template, pep),
        reusable_system_cache = isnothing(compatible_reuse_bundle) ? Dict{Any, Any}() : copy(compatible_reuse_bundle.system_cache),
        reusable_order_cache = isnothing(compatible_reuse_bundle) ? Dict{Any, Any}() : copy(compatible_reuse_bundle.order_cache),
    )
end

function _instantiate_template_equations_at_point(
    equations,
    pep::ParameterEstimationProblem,
    interpolants::Dict,
    t_eval::Float64,
)
    subst = Dict{Any, Float64}()
    vars = OrderedSet{Any}()
    for eq in equations
        union!(vars, Symbolics.get_variables(eq))
    end

    for v in vars
        value = _consensus_interpolated_value(interpolants, pep, string(v), t_eval)
        isfinite(value) && (subst[v] = value)
    end

    instantiated = Symbolics.substitute.(equations, Ref(subst))
    remaining_vars = OrderedSet{Any}()
    for eq in instantiated
        union!(remaining_vars, Symbolics.get_variables(eq))
    end
    return instantiated, collect(remaining_vars)
end

function _instantiate_multipoint_equations(
    mpt::MultiPointTemplate,
    equations,
    evaluation::MultiPointEvaluation,
)
    subst = Dict{Any, Float64}()
    for (i, dv) in enumerate(mpt.data_vars)
        i <= length(evaluation.data_values) || continue
        subst[dv] = evaluation.data_values[i]
    end

    instantiated = Symbolics.substitute.(equations, Ref(subst))
    remaining_vars = OrderedSet{Any}()
    for eq in instantiated
        union!(remaining_vars, Symbolics.get_variables(eq))
    end
    return instantiated, collect(remaining_vars)
end

function _consensus_tspan(pep::ParameterEstimationProblem)
    if isnothing(pep.recommended_time_interval) || isnothing(pep.data_sample)
        return [-0.5, 0.5]
    end
    t_vec = pep.data_sample["t"]
    return [first(t_vec), last(t_vec)]
end

function _consensus_ode_setup!(coeff_cache::Dict, pep::ParameterEstimationProblem)
    return get!(coeff_cache, (:base_ode_problem, objectid(pep.model.system))) do
        sys = pep.model.system
        completed_sys = ModelingToolkit.complete(sys)
        states = ModelingToolkit.unknowns(sys)
        params = ModelingToolkit.parameters(sys)
        ordered_params = [pep.p_true[p] for p in params]
        ordered_ic = [pep.ic[s] for s in states]
        u0_map = Dict(ModelingToolkit.unknowns(completed_sys) .=> ordered_ic)
        p_map = Dict(ModelingToolkit.parameters(completed_sys) .=> ordered_params)
        (
            completed_sys = completed_sys,
            base_ode_problem = ODEProblem(completed_sys, merge(u0_map, p_map), _consensus_tspan(pep)),
        )
    end
end

function _consensus_time_coefficients!(
    coeff_cache::Dict,
    candidate_index::Int,
    candidate::ParameterEstimationResult,
    pep::ParameterEstimationProblem,
    point_idx::Int,
    max_order::Int,
    opts::EstimationOptions,
)
    time_key = (:time_atom, candidate_index, point_idx)
    if haskey(coeff_cache, time_key)
        cached = coeff_cache[time_key]
        cached.max_order >= max_order && return cached
    end

    candidate_pep = get!(coeff_cache, (:candidate_pep, candidate_index)) do
        _consensus_candidate_pep(pep, candidate)
    end
    ode_setup = _consensus_ode_setup!(coeff_cache, pep)
    t_eval = pep.data_sample["t"][point_idx]
    state_taylor = compute_oracle_taylor_coefficients(candidate_pep, t_eval, max_order + 2;
        solver = pep.solver,
        abstol = opts.abstol,
        reltol = opts.reltol,
        completed_sys = ode_setup.completed_sys,
        base_ode_problem = ode_setup.base_ode_problem,
    )
    obs_taylor = compute_observable_taylor_coefficients(candidate_pep, state_taylor, t_eval, max_order + 2)
    atom = (
        candidate_pep = candidate_pep,
        point_idx = point_idx,
        t_value = Float64(t_eval),
        state_taylor = state_taylor,
        obs_taylor = obs_taylor,
        max_order = max_order,
    )
    coeff_cache[time_key] = atom
    return atom
end

function _consensus_coefficients!(
    coeff_cache::Dict,
    candidate_index::Int,
    candidate::ParameterEstimationResult,
    pep::ParameterEstimationProblem,
    time_indices::Vector{Int},
    max_order::Int,
    opts::EstimationOptions,
)
    key = (candidate_index, Tuple(time_indices), max_order)
    haskey(coeff_cache, key) && return coeff_cache[key]

    atoms = [_consensus_time_coefficients!(coeff_cache, candidate_index, candidate, pep, idx, max_order, opts) for idx in time_indices]
    candidate_pep = first(atoms).candidate_pep
    t_values = Float64[atom.t_value for atom in atoms]
    state_taylors = [atom.state_taylor for atom in atoms]
    obs_taylors = [atom.obs_taylor for atom in atoms]

    coeff_cache[key] = (
        candidate_pep = candidate_pep,
        t_values = t_values,
        state_taylors = state_taylors,
        obs_taylors = obs_taylors,
    )
    return coeff_cache[key]
end

function _compiled_system_function!(
    system_cache::Dict,
    cache_key,
    equations,
    varlist,
)
    compiled_key = (:compiled_function, cache_key)
    return get!(system_cache, compiled_key) do
        _compile_system_function(equations, varlist)
    end
end

function _system_max_order!(
    order_cache::Dict,
    cache_key,
    varlist,
)
    return get!(order_cache, cache_key) do
        isempty(varlist) ? 0 : maximum(_multipoint_var_order(string(v)) for v in varlist)
    end
end

function _lookup_candidate_system_value(
    var_name::AbstractString,
    candidate_pep::ParameterEstimationProblem,
    t_values::Vector{Float64},
    state_taylors::Vector,
    obs_taylors::Vector,
)
    clean_name, pt_idx = _parse_multipoint_var_name(var_name)
    if pt_idx < 1 || pt_idx > length(t_values)
        return NaN
    end

    t_eval = t_values[pt_idx]
    trfn_val = evaluate_trfn_template_variable(clean_name, t_eval)
    if isnothing(trfn_val)
        trfn_val = evaluate_obs_trfn_template_variable(clean_name, t_eval)
    end
    !isnothing(trfn_val) && return Float64(trfn_val)

    parsed = parse_derivative_variable_name(clean_name)
    if !isnothing(parsed)
        base_name, deriv_order = parsed
        for (p, v) in candidate_pep.p_true
            pname = replace(string(p), "(t)" => "")
            if pname == base_name || pname * "_0" == clean_name
                return deriv_order == 0 ? Float64(v) : NaN
            end
        end
        for (s, _) in candidate_pep.ic
            sname = replace(string(s), "(t)" => "")
            if sname == base_name
                st = state_taylors[pt_idx]
                if haskey(st, s) && deriv_order + 1 <= length(st[s])
                    return Float64(st[s][deriv_order + 1] * factorial(deriv_order))
                end
            end
        end
        for mq in candidate_pep.measured_quantities
            obs_name = replace(string(mq.lhs), "(t)" => "")
            if obs_name == base_name
                key = ModelingToolkit.diff2term(mq.rhs)
                ot = obs_taylors[pt_idx]
                if haskey(ot, key) && deriv_order + 1 <= length(ot[key])
                    return Float64(ot[key][deriv_order + 1] * factorial(deriv_order))
                end
            end
        end
    end

    for (p, v) in candidate_pep.p_true
        replace(string(p), "(t)" => "") == clean_name && return Float64(v)
    end
    for (s, _) in candidate_pep.ic
        sname = replace(string(s), "(t)" => "")
        if sname == clean_name
            st = state_taylors[pt_idx]
            haskey(st, s) && return Float64(st[s][1])
        end
    end
    for mq in candidate_pep.measured_quantities
        obs_name = replace(string(mq.lhs), "(t)" => "")
        if obs_name == clean_name
            key = ModelingToolkit.diff2term(mq.rhs)
            ot = obs_taylors[pt_idx]
            haskey(ot, key) && return Float64(ot[key][1])
        end
    end

    return NaN
end

function _candidate_value_vector(
    varlist,
    coeff_data,
)
    vals = Float64[]
    for v in varlist
        push!(vals, _lookup_candidate_system_value(string(v), coeff_data.candidate_pep, coeff_data.t_values, coeff_data.state_taylors, coeff_data.obs_taylors))
    end
    return vals
end

function _equation_residual_norm(equations, varlist, vals; system_cache::Union{Nothing, Dict} = nothing, cache_key = nothing)
    isempty(equations) && return NaN
    if isempty(varlist)
        total = 0.0
        for eq in equations
            value = try
                Float64(Symbolics.value(eq))
            catch
                NaN
            end
            isfinite(value) || return NaN
            total += value^2
        end
        return sqrt(total)
    end
    any(!isfinite, vals) && return NaN
    try
        f = isnothing(system_cache) || isnothing(cache_key) ?
            _compile_system_function(equations, varlist) :
            _compiled_system_function!(system_cache, cache_key, equations, varlist)
        residual = f(vals)
        return norm(residual)
    catch
        return _compute_residual(equations, varlist, vals)
    end
end

function _equation_condition_number(equations, varlist, vals; system_cache::Union{Nothing, Dict} = nothing, cache_key = nothing)
    if isempty(equations) || isempty(varlist)
        return NaN
    end
    any(!isfinite, vals) && return NaN
    try
        f = isnothing(system_cache) || isnothing(cache_key) ?
            _compile_system_function(equations, varlist) :
            _compiled_system_function!(system_cache, cache_key, equations, varlist)
        J = ForwardDiff.jacobian(f, vals)
        svs = svdvals(J)
        isempty(svs) && return NaN
        return svs[1] / max(svs[end], 1e-300)
    catch
        return NaN
    end
end

function _aggregate_metric(values::Vector{Float64})
    finite_vals = filter(isfinite, values)
    isempty(finite_vals) && return NaN
    return median(finite_vals)
end

function _score_candidate_raw(
    candidate_index::Int,
    candidate::ParameterEstimationResult,
    context,
    support_points::Vector{Int},
    support_combos::AbstractVector{<:AbstractVector},
    coeff_cache::Dict,
    system_cache::Dict,
    order_cache::Dict,
)
    pep = context.pep
    opts = context.opts
    source = _consensus_source_symbol(candidate, context.default_source)
    interpolants = get(context.interpolant_cache, source, context.interpolant_cache[context.default_source])

    sp_kept = Float64[]
    sp_dropped = Float64[]
    sp_cond = Float64[]

    all_sp_eqs = hasproperty(context.si_template, :all_equations) ? context.si_template.all_equations : context.si_template.equations
    dropped_sp_indices = hasproperty(context.si_template, :rank_trimming_metadata) ? context.si_template.rank_trimming_metadata.dropped_equation_indices : Int[]
    dropped_sp_eqs = isempty(dropped_sp_indices) ? Num[] : all_sp_eqs[filter(i -> 1 <= i <= length(all_sp_eqs), dropped_sp_indices)]

    for point_idx in support_points
        t_eval = pep.data_sample["t"][point_idx]
        sp_key = (:sp_kept, source, point_idx)
        eqs, varlist = get!(system_cache, sp_key) do
            construct_equation_system_from_si_template(
                pep.model.system,
                pep.measured_quantities,
                pep.data_sample,
                context.ident_data.good_deriv_level,
                context.ident_data.good_udict,
                context.ident_data.good_varlist,
                context.ident_data.good_DD;
                interpolator = context.interpolator_function_cache[source],
                time_index_set = [point_idx],
                precomputed_interpolants = interpolants,
                diagnostics = false,
                si_template = context.si_template,
            )
        end
        kept_order = _system_max_order!(order_cache, (:sp_kept_order, source, point_idx), varlist)

        inst_dropped_eqs = nothing
        dropped_vars = Any[]
        dropped_order = 0
        if !isempty(dropped_sp_eqs)
            dropped_key = (:sp_dropped, source, point_idx)
            inst_dropped_eqs, dropped_vars = get!(system_cache, dropped_key) do
                _instantiate_template_equations_at_point(dropped_sp_eqs, pep, interpolants, t_eval)
            end
            dropped_order = _system_max_order!(order_cache, (:sp_dropped_order, source, point_idx), dropped_vars)
        end

        coeff_order = max(kept_order, dropped_order)
        coeff_data = (isempty(varlist) && isempty(dropped_vars)) ? nothing :
            _consensus_coefficients!(coeff_cache, candidate_index, candidate, pep, [point_idx], coeff_order, opts)
        vals = isempty(varlist) ? Float64[] : _candidate_value_vector(varlist, coeff_data)
        push!(sp_kept, _equation_residual_norm(eqs, varlist, vals; system_cache = system_cache, cache_key = sp_key))
        push!(sp_cond, _equation_condition_number(eqs, varlist, vals; system_cache = system_cache, cache_key = sp_key))

        if !isempty(dropped_sp_eqs)
            dropped_vals = isempty(dropped_vars) ? Float64[] : _candidate_value_vector(dropped_vars, coeff_data)
            push!(sp_dropped, _equation_residual_norm(inst_dropped_eqs, dropped_vars, dropped_vals; system_cache = system_cache, cache_key = dropped_key))
        end
    end

    mp_kept = Float64[]
    mp_dropped = Float64[]
    if !isnothing(context.mpt) && !isempty(support_combos)
        for combo in support_combos
            try
                combo_tuple = Tuple(combo)
                evaluation = get!(system_cache, (:mp_eval, source, combo_tuple)) do
                    evaluate_multipoint_template(context.mpt, Int[combo...], interpolants, pep.data_sample)
                end
                kept_eqs, kept_vars = get!(system_cache, (:mp_kept, source, combo_tuple)) do
                    _instantiate_multipoint_equations(context.mpt, context.mpt.stripped_equations, evaluation)
                end
                kept_order = _system_max_order!(order_cache, (:mp_kept_order, source, combo_tuple), kept_vars)

                inst_dropped_eqs = nothing
                dropped_vars = Any[]
                dropped_order = 0
                if !isempty(context.mpt.dropped_equation_indices)
                    dropped_key = (:mp_dropped, source, combo_tuple)
                    inst_dropped_eqs, dropped_vars = get!(system_cache, dropped_key) do
                        dropped_eqs = context.mpt.all_equations[context.mpt.dropped_equation_indices]
                        _instantiate_multipoint_equations(context.mpt, dropped_eqs, evaluation)
                    end
                    dropped_order = _system_max_order!(order_cache, (:mp_dropped_order, source, combo_tuple), dropped_vars)
                end

                coeff_order = max(kept_order, dropped_order)
                coeff_data = (isempty(kept_vars) && isempty(dropped_vars)) ? nothing :
                    _consensus_coefficients!(coeff_cache, candidate_index, candidate, pep, combo, coeff_order, opts)
                vals = isempty(kept_vars) ? Float64[] : _candidate_value_vector(kept_vars, coeff_data)
                push!(mp_kept, _equation_residual_norm(kept_eqs, kept_vars, vals; system_cache = system_cache, cache_key = (:mp_kept, source, combo_tuple)))

                if !isempty(context.mpt.dropped_equation_indices)
                    dropped_vals = isempty(dropped_vars) ? Float64[] : _candidate_value_vector(dropped_vars, coeff_data)
                    push!(mp_dropped, _equation_residual_norm(inst_dropped_eqs, dropped_vars, dropped_vals; system_cache = system_cache, cache_key = dropped_key))
                end
            catch
            end
        end
    end

    diversity_tags = Symbol[candidate.provenance.source_type]
    !isnothing(candidate.provenance.interpolator_source) && push!(diversity_tags, candidate.provenance.interpolator_source)
    candidate.provenance.polish_applied && push!(diversity_tags, :polished)
    !isnothing(candidate.provenance.source_shooting_index) && push!(diversity_tags, Symbol("shoot_$(candidate.provenance.source_shooting_index)"))
    if !isnothing(candidate.provenance.multipoint_time_indices)
        for idx in candidate.provenance.multipoint_time_indices
            push!(diversity_tags, Symbol("mp_$(idx)"))
        end
    end

    polish_gain = 0.0
    if !isnothing(candidate.provenance.pre_polish_error) && !isnothing(candidate.provenance.post_polish_error)
        denom = max(abs(candidate.provenance.pre_polish_error), 1e-12)
        polish_gain = max(0.0, candidate.provenance.pre_polish_error - candidate.provenance.post_polish_error) / denom
    end

    support_strength = length(unique(diversity_tags))
    condition_proxy = _aggregate_metric(sp_cond)
    trust_strength = (isfinite(condition_proxy) ? 1 / (1 + log1p(condition_proxy)) : 0.0) + polish_gain

    equation_components = Float64[]
    for val in (_aggregate_metric(sp_kept), _aggregate_metric(mp_kept))
        isfinite(val) && push!(equation_components, val)
    end
    for val in (_aggregate_metric(sp_dropped), _aggregate_metric(mp_dropped))
        isfinite(val) && push!(equation_components, 0.5 * val)
    end
    equation_penalty = isempty(equation_components) ? Inf : mean(equation_components)

    return (
        base_fit_error = _result_err_key(candidate),
        sp_equation_residual_kept = _aggregate_metric(sp_kept),
        sp_equation_residual_dropped = _aggregate_metric(sp_dropped),
        mp_equation_residual_kept = _aggregate_metric(mp_kept),
        mp_equation_residual_dropped = _aggregate_metric(mp_dropped),
        conditioning_score = condition_proxy,
        uq_volume_proxy = NaN,
        source_diversity_tags = unique(diversity_tags),
        equation_penalty = equation_penalty,
        support_strength = support_strength,
        trust_strength = trust_strength,
    )
end

function _rank_penalties(values::AbstractVector{<:Real}; higher_is_better::Bool = false)
    penalties = fill(1.0, length(values))
    finite_idx = findall(isfinite, values)
    isempty(finite_idx) && return penalties
    order = sort(finite_idx; by = i -> values[i], rev = higher_is_better)
    denom = max(length(order) - 1, 1)
    for (rank, idx) in enumerate(order)
        penalties[idx] = (rank - 1) / denom
    end
    return penalties
end

function _build_candidate_evidence(
    candidates::Vector{ParameterEstimationResult},
    context,
    support_points::Vector{Int},
    support_combos::AbstractVector{<:AbstractVector},
    consensus_opts::ConsensusOptions,
    ;
    coeff_cache::Union{Nothing, Dict} = nothing,
    system_cache::Union{Nothing, Dict} = nothing,
    order_cache::Union{Nothing, Dict} = nothing,
)
    isempty(candidates) && return CandidateEvidence[]

    raw_metrics = Vector{NamedTuple}(undef, length(candidates))
    coeff_cache = isnothing(coeff_cache) ? Dict{Any, Any}() : coeff_cache
    system_cache = isnothing(system_cache) ? Dict{Any, Any}() : system_cache
    order_cache = isnothing(order_cache) ? Dict{Any, Any}() : order_cache
    if hasproperty(context, :reusable_system_cache)
        for (key, value) in context.reusable_system_cache
            haskey(system_cache, key) || (system_cache[key] = value)
        end
    end
    if hasproperty(context, :reusable_order_cache)
        for (key, value) in context.reusable_order_cache
            haskey(order_cache, key) || (order_cache[key] = value)
        end
    end
    for (i, candidate) in enumerate(candidates)
        raw_metrics[i] = try
            _score_candidate_raw(i, candidate, context, support_points, support_combos, coeff_cache, system_cache, order_cache)
        catch
            (
                base_fit_error = _result_err_key(candidate),
                sp_equation_residual_kept = NaN,
                sp_equation_residual_dropped = NaN,
                mp_equation_residual_kept = NaN,
                mp_equation_residual_dropped = NaN,
                conditioning_score = NaN,
                uq_volume_proxy = NaN,
                source_diversity_tags = Symbol[candidate.provenance.source_type],
                equation_penalty = Inf,
                support_strength = 1.0,
                trust_strength = 0.0,
            )
        end
    end

    fit_penalty = _rank_penalties([m.base_fit_error for m in raw_metrics])
    equation_penalty = _rank_penalties([m.equation_penalty for m in raw_metrics])
    support_penalty = _rank_penalties([m.support_strength for m in raw_metrics]; higher_is_better = true)
    trust_penalty = _rank_penalties([m.trust_strength for m in raw_metrics]; higher_is_better = true)

    evidence = CandidateEvidence[]
    for i in eachindex(candidates)
        breakdown = (
            fit = fit_penalty[i],
            equation = equation_penalty[i],
            support = support_penalty[i],
            trust = trust_penalty[i],
        )
        score = consensus_opts.score_weights.fit * breakdown.fit +
                consensus_opts.score_weights.equation * breakdown.equation +
                consensus_opts.score_weights.support * breakdown.support +
                consensus_opts.score_weights.trust * breakdown.trust
        push!(evidence, CandidateEvidence(
            i,
            raw_metrics[i].base_fit_error,
            raw_metrics[i].sp_equation_residual_kept,
            raw_metrics[i].sp_equation_residual_dropped,
            raw_metrics[i].mp_equation_residual_kept,
            raw_metrics[i].mp_equation_residual_dropped,
            raw_metrics[i].conditioning_score,
            raw_metrics[i].uq_volume_proxy,
            raw_metrics[i].source_diversity_tags,
            score,
            breakdown,
        ))
    end

    return evidence
end

function _argmin_by(indices, f::Function)
    best_idx = nothing
    best_val = Inf
    for idx in indices
        value = f(idx)
        if value < best_val
            best_val = value
            best_idx = idx
        end
    end
    return best_idx
end

function _family_medoid_index(candidates, members::Vector{Int})
    length(members) == 1 && return only(members)
    best_idx = first(members)
    best_cost = Inf
    for idx in members
        total = 0.0
        for jdx in members
            idx == jdx && continue
            total += solution_distance(candidates[idx], candidates[jdx])
        end
        if total < best_cost
            best_cost = total
            best_idx = idx
        end
    end
    return best_idx
end

function _build_candidate_families(
    candidates::Vector{ParameterEstimationResult},
    evidence::Vector{CandidateEvidence},
    consensus_opts::ConsensusOptions,
)
    isempty(candidates) && return CandidateFamily[]
    sorted_indices = sortperm(evidence; by = e -> e.composite_score)
    families = Vector{Vector{Int}}()

    for idx in sorted_indices
        placed = false
        for family in families
            if solution_distance(candidates[idx], candidates[first(family)]) <= consensus_opts.family_distance_threshold
                push!(family, idx)
                placed = true
                break
            end
        end
        !placed && push!(families, [idx])
    end

    reports = CandidateFamily[]
    for members in families
        medoid = _family_medoid_index(candidates, members)
        best_member = _argmin_by(members, i -> evidence[i].composite_score)
        family_scores = sort([evidence[i].composite_score for i in members])
        family_median = family_scores[cld(length(family_scores), 2)]

        interpolators = sort!(unique(Symbol[
            candidates[i].provenance.interpolator_source for i in members
            if !isnothing(candidates[i].provenance.interpolator_source)
        ]))
        source_types = sort!(collect(Set(Symbol[candidates[i].provenance.source_type for i in members])))
        shooting_support = Int[]
        for i in members
            prov = candidates[i].provenance
            !isnothing(prov.source_shooting_index) && push!(shooting_support, prov.source_shooting_index)
            if !isnothing(prov.multipoint_time_indices)
                append!(shooting_support, prov.multipoint_time_indices)
            end
        end
        sort!(shooting_support)
        unique!(shooting_support)

        diversity_bonus = 0.02 * (
            max(length(interpolators), 1) +
            max(length(source_types), 1) +
            min(length(shooting_support), 4)
        )
        family_score = max(0.0, 0.5 * evidence[best_member].composite_score + 0.5 * family_median - diversity_bonus)

        push!(reports, CandidateFamily(
            sort!(copy(members)),
            medoid,
            best_member,
            interpolators,
            source_types,
            shooting_support,
            family_score,
        ))
    end

    sort!(reports; by = f -> f.family_score)
    return reports
end

function _candidate_to_vector(candidate::ParameterEstimationResult, ctx::PolishContext)
    state_lookup = Dict(string(k) => Float64(v) for (k, v) in candidate.states)
    param_lookup = Dict(string(k) => Float64(v) for (k, v) in candidate.parameters)
    ic_vec = Float64[get(state_lookup, string(s), 0.0) for s in ctx.unknown_syms]
    param_vec = Float64[get(param_lookup, string(p), 0.0) for p in ctx.param_syms]
    return vcat(ic_vec, param_vec)
end

function _polish_research_seed(
    pep::ParameterEstimationProblem,
    seed::ParameterEstimationResult,
    ctx::PolishContext,
    opts::EstimationOptions,
)
    p0 = _candidate_to_vector(seed, ctx)
    # Residual-mode polishers (PolishLSOBoundedLog / PolishFastLMBoundedLog) get the
    # optimizer factory from `opts.polish_method` directly via `_polish_single_from_context`'s
    # dispatch; the legacy scalar path still wants a constructed optimizer instance.
    optimizer = if is_residual_polish_method(opts.polish_method)
        BFGS()  # placeholder; ignored when polish_method dispatches to the residual path
    else
        get_polish_optimizer(opts.polish_method)()
    end
    polished, _ = _polish_single_from_context(
        ctx,
        p0;
        optimizer = optimizer,
        polish_method = opts.polish_method,
        maxiters = opts.polish_maxiters,
        maxtime = opts.polish_maxtime,
        divergence_factor = opts.polish_divergence_factor,
        stagnation_window = opts.polish_stagnation_window,
        lso_delta = opts.polish_lso_delta,
        lso_x_tol = opts.polish_lso_x_tol,
        lso_f_tol = opts.polish_lso_f_tol,
        lso_g_tol = opts.polish_lso_g_tol,
    )
    polished.unident_dict = deepcopy(seed.unident_dict)
    polished.all_unidentifiable = copy(seed.all_unidentifiable)
    polished.provenance = copy_provenance(
        seed.provenance;
        primary_method = seed.provenance.primary_method,
        interpolator_source = seed.provenance.interpolator_source,
        rescue_path = seed.provenance.rescue_path,
        source_shooting_index = seed.provenance.source_shooting_index,
        source_candidate_index = seed.provenance.source_candidate_index,
        pre_polish_error = seed.err,
        post_polish_error = polished.err,
        polish_applied = true,
        source_type = seed.provenance.source_type,
        multipoint_time_indices = seed.provenance.multipoint_time_indices,
        multipoint_combo_index = seed.provenance.multipoint_combo_index,
        notes = seed.provenance.notes,
    )
    sync_result_contract!(polished)
    return polished
end

function _refine_consensus_candidates(
    candidates::Vector{ParameterEstimationResult},
    evidence::Vector{CandidateEvidence},
    families::Vector{CandidateFamily},
    context,
    consensus_opts::ConsensusOptions,
)
    consensus_opts.do_equation_refit || return ParameterEstimationResult[]
    isempty(families) && return ParameterEstimationResult[]

    ctx = _build_polish_context(context.pep; opts = context.opts)
    limit = min(consensus_opts.refine_top_families, length(families))
    seeds = Int[]
    for family in families[1:limit]
        push!(seeds, family.family_medoid_index)
        push!(seeds, family.best_member_index)
    end
    unique!(seeds)

    refined = ParameterEstimationResult[]
    for idx in seeds
        try
            push!(refined, _polish_research_seed(context.pep, candidates[idx], ctx, context.opts))
        catch
        end
    end
    return refined
end

function _winner_from_strategy(
    candidates::Vector{ParameterEstimationResult},
    evidence::Vector{CandidateEvidence},
    families::Vector{CandidateFamily},
    strategy::Symbol,
)
    isempty(candidates) && return (nothing, nothing)
    if strategy == :best_fit_baseline
        idx = _argmin_by(eachindex(candidates), i -> _result_err_key(candidates[i]))
        idx = isnothing(idx) ? 1 : idx
        return nothing, idx
    end
    if isempty(families)
        idx = _argmin_by(eachindex(evidence), i -> begin
            score = evidence[i].composite_score
            isfinite(score) ? score : Inf
        end)
        idx = isnothing(idx) ? 1 : idx
        return nothing, idx
    end
    return 1, first(families).family_medoid_index
end

function _empty_consensus_report(model_name::String, strategy::Symbol; note::String = "no raw candidates were produced")
    return ConsensusEstimationReport(
        model_name,
        strategy,
        ParameterEstimationResult[],
        CandidateEvidence[],
        CandidateFamily[],
        nothing,
        nothing,
        nothing,
        nothing,
        Int[],
        Vector{Vector{Int}}(),
        Dict{Symbol, Any}(
            :note => note,
            :strategy => strategy,
            :raw_winner_kind => :missing,
            :final_winner_kind => :missing,
            :raw_winner_evidence => nothing,
            :final_winner_evidence => nothing,
            :winner_score => NaN,
            :final_winner_score => NaN,
        ),
    )
end

function _prepare_consensus_inputs(
    pep::ParameterEstimationProblem,
    est_opts::EstimationOptions,
)
    validate_options(est_opts) || throw(ArgumentError("Invalid EstimationOptions; fix the reported configuration errors before running consensus estimation."))

    pep_with_data = isnothing(pep.data_sample) ? sample_problem_data(pep, est_opts) : pep
    if est_opts.auto_handle_transcendentals
        t_var = ModelingToolkit.get_iv(pep_with_data.model.system)
        pep_with_data, _ = transform_pep_for_estimation(pep_with_data, t_var)
    end

    run_opts = est_opts.flow == FlowStandard ? est_opts : merge_options(est_opts; flow = FlowStandard)
    raw_results, _, _, _ = optimized_multishot_parameter_estimation(pep_with_data, run_opts)
    raw_candidates = ParameterEstimationResult[result for result in raw_results]
    return pep_with_data, run_opts, raw_candidates
end

function _prepare_consensus_inputs_with_timing(
    pep::ParameterEstimationProblem,
    est_opts::EstimationOptions,
)
    validate_options(est_opts) || throw(ArgumentError("Invalid EstimationOptions; fix the reported configuration errors before running consensus estimation."))

    pep_with_data = isnothing(pep.data_sample) ? sample_problem_data(pep, est_opts) : pep
    if est_opts.auto_handle_transcendentals
        t_var = ModelingToolkit.get_iv(pep_with_data.model.system)
        pep_with_data, _ = transform_pep_for_estimation(pep_with_data, t_var)
    end

    run_opts = est_opts.flow == FlowStandard ? est_opts : merge_options(est_opts; flow = FlowStandard)
    timed = @timed _capture_estimation_timing() do
        optimized_multishot_parameter_estimation(pep_with_data, run_opts)
    end
    captured = isnothing(timed.value[2]) ? TimingBreakdown(
        label = :optimized_multishot,
        total_seconds = timed.time,
        phases = TimingPhaseEntry[
            TimingPhaseEntry("optimized_multishot", timed.time, Int64(timed.bytes), timed.gctime),
        ],
    ) : timed.value[2]
    raw_results, _, _, _ = timed.value[1]
    raw_candidates = ParameterEstimationResult[result for result in raw_results]
    return pep_with_data, run_opts, raw_candidates, captured
end

function _assemble_consensus_report(
    pep_with_data::ParameterEstimationProblem,
    run_opts::EstimationOptions,
    raw_candidates::Vector{ParameterEstimationResult},
    consensus_opts::ConsensusOptions;
    context = nothing,
)
    isempty(raw_candidates) && return _empty_consensus_report(pep_with_data.name, consensus_opts.strategy)

    context = isnothing(context) ? _build_consensus_context(pep_with_data, run_opts; reuse_bundle = _last_estimation_reuse()) : context
    support_points = _select_consensus_support_points(
        pep_with_data,
        raw_candidates,
        context.point_indices,
        context.support_labels,
        context.interpolant_cache,
        consensus_opts,
        context.t_vector,
    )
    support_combos = _select_consensus_support_combos(raw_candidates, support_points, run_opts.multipoint_n_points, consensus_opts)

    evidence = _build_candidate_evidence(raw_candidates, context, support_points, support_combos, consensus_opts)
    families = _build_candidate_families(raw_candidates, evidence, consensus_opts)
    winner_family_index, winner_candidate_index = _winner_from_strategy(raw_candidates, evidence, families, consensus_opts.strategy)
    winner_candidate = isnothing(winner_candidate_index) ? nothing : raw_candidates[winner_candidate_index]
    raw_winner_evidence = isnothing(winner_candidate_index) ? nothing : evidence[winner_candidate_index]
    raw_winner_score = isnothing(raw_winner_evidence) ? NaN : raw_winner_evidence.composite_score

    winner_refined = nothing
    final_winner_kind = isnothing(winner_candidate) ? :missing : :raw
    final_winner_evidence = raw_winner_evidence
    final_winner_score = raw_winner_score
    if consensus_opts.strategy == :family_consensus_refit
        refined_candidates = _refine_consensus_candidates(raw_candidates, evidence, families, context, consensus_opts)
        if !isempty(refined_candidates)
            combined = vcat(raw_candidates, refined_candidates)
            combined_evidence = _build_candidate_evidence(combined, context, support_points, support_combos, consensus_opts)
            combined_best = _argmin_by(eachindex(combined_evidence), i -> combined_evidence[i].composite_score)
            if combined_best > length(raw_candidates)
                winner_refined = combined[combined_best]
                final_winner_kind = :refined
                final_winner_evidence = combined_evidence[combined_best]
                final_winner_score = final_winner_evidence.composite_score
            end
        end
    end

    scoring_summary = Dict{Symbol, Any}(
        :strategy => consensus_opts.strategy,
        :version_label => :consensus_v0,
        :support_point_count => length(support_points),
        :support_combo_count => length(support_combos),
        :weights => consensus_opts.score_weights,
        :n_raw_candidates => length(raw_candidates),
        :n_families => length(families),
        :winner_score => raw_winner_score,
        :refit_mode => consensus_opts.strategy == :family_consensus_refit ? :existing_polish_rescore : :disabled,
        :raw_winner_kind => isnothing(winner_candidate) ? :missing : :raw,
        :final_winner_kind => final_winner_kind,
        :raw_winner_evidence => raw_winner_evidence,
        :final_winner_evidence => final_winner_evidence,
        :final_winner_score => final_winner_score,
        :final_winner_fit_error => isnothing(winner_refined) ? _result_err_key(winner_candidate) : _result_err_key(winner_refined),
    )

    return ConsensusEstimationReport(
        pep_with_data.name,
        consensus_opts.strategy,
        raw_candidates,
        evidence,
        families,
        winner_family_index,
        winner_candidate_index,
        winner_candidate,
        winner_refined,
        support_points,
        support_combos,
        scoring_summary,
    )
end

function research_consensus_estimation(
    pep::ParameterEstimationProblem;
    est_opts::EstimationOptions = EstimationOptions(),
    consensus_opts::ConsensusOptions = ConsensusOptions(),
)
    pep_with_data, run_opts, raw_candidates = _prepare_consensus_inputs(pep, est_opts)
    return _assemble_consensus_report(pep_with_data, run_opts, raw_candidates, consensus_opts)
end
