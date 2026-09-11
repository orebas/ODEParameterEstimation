# PEtab supplies the SBML equations, preparation function, tables and exact
# objective. Access to its imported representation is confined to this file.
struct PEtabAlgebraicProblem{P}
    path::String
    petab::P
    algebraic::ParameterEstimationProblem
    parameter_ids::Vector{String}
    parameter_symbols::Vector{Num}
    parameter_scales::Vector{Symbol}
    initial_maps::OrderedDict{Num, Num}
    condition_states::OrderedDict{String, Vector{Num}}
    row_observables::Vector{Num}
    condition_time_offsets::OrderedDict{String, Float64}
    notes::Vector{String}
end

_name(x) = replace(string(x), "(t)" => "")
_missing(x) = ismissing(x) || (x isa AbstractString && isempty(strip(x)))
_column(row, name::Symbol, default=missing) = hasproperty(row, name) ? getproperty(row, name) : default
_new_parameter(id::Int) = only(@parameters $(Symbol("petab_p", id)))
_named_parameter(id::String) = only(@parameters $(Symbol(id)))
_new_state(id::String) = only(@variables $(Symbol(id))(t))

function _load_petab_model(path::AbstractString; verbose::Bool=false)
    path = abspath(path)
    PEtab._get_version(path) == "1.0.0" || throw(ArgumentError("The ODEPE pilot supports PEtab v1"))
    source_tables = PEtab.read_tables_v1(path)
    source_paths = PEtab._get_petab_paths(path)
    normalized_paths, normalized = _normalize_condition_inputs(source_paths, source_tables)
    append!(normalized, _normalize_noise_observable_maps!(source_tables))
    model = isempty(normalized) ? PEtabModel(path; ifelse_to_callback=false, verbose=verbose) :
        PEtab._PEtabModel(normalized_paths, source_tables, true, verbose, false, false,
            PEtab.PEtabEvent[], PEtab.MLModels())
    tables = model.petab_tables
    estimated_ids = Set(string(row.parameterId) for row in eachrow(tables[:parameters]) if row.estimate == 1)
    derived = [Num(p) for (p, value) in model.parametermap
        if !isempty(Symbolics.get_variables(Num(value))) && !(_name(p) in estimated_ids)]
    isempty(derived) && return model, normalized
    # PEtab 5.4.3 evaluates parameter initial assignments at SBML defaults, before
    # condition overrides. Express their evaluated formulas as condition maps so
    # both likelihood and AD derivatives use the original SBML semantics. Rebuild
    # before PEtab allocates its parameter-index and derivative caches.
    names = Dict{String, Num}(id => _named_parameter(id) for id in estimated_ids)
    for row in eachrow(tables[:parameters])
        row.estimate == 0 && (names[string(row.parameterId)] = Num(row.nominalValue))
    end
    corrected = deepcopy(tables)
    ps = Num.(parameters(model.sys))
    repaired = String[]
    for p in derived
        id = _name(p)
        hasproperty(tables[:conditions], Symbol(id)) && continue
        index = findfirst(isequal(p), ps)
        isnothing(index) && continue
        formulas = String[_condition_formula_string(_condition_parameter_values(model, row, names)[index])
            for row in eachrow(tables[:conditions])]
        corrected[:conditions][!, Symbol(id)] = formulas
        push!(repaired, id)
    end
    isempty(repaired) && return model, normalized
    corrected_model = PEtab._PEtabModel(copy(model.paths), corrected, true, verbose,
        false, false, model.petab_events, model.ml_models)
    return corrected_model, vcat(normalized, repaired)
end

function _normalize_noise_observable_maps!(tables)
    # PEtab 5.4's noise callback receives noise and nondynamic parameters, but
    # not the per-row observable-parameter vector. A single shared mapping can
    # be inlined exactly in both formulas (Raia). Varying row mappings need a
    # different representation and are rejected instead of changing the noise.
    measurements, observables = tables[:measurements], tables[:observables]
    repaired = String[]
    for observable in eachrow(observables)
        occursin(r"\bobservableParameter\d+_", string(observable.noiseFormula)) || continue
        hasproperty(measurements, :observableParameters) || throw(ArgumentError("Noise formula requires missing observable-parameter mappings"))
        rows = findall(==(observable.observableId), measurements.observableId)
        isempty(rows) && continue
        overrides = unique(measurements[rows, :observableParameters])
        length(overrides) == 1 && !_missing(only(overrides)) || throw(ArgumentError(
            "Varying observable-parameter mappings inside noise formulas are outside this PEtab pilot"))
        for (i, value) in enumerate(split(string(only(overrides)), ';'))
            placeholder = "observableParameter$(i)_$(observable.observableId)"
            for column in (:observableFormula, :noiseFormula)
                observable[column] = PEtab.SBMLImporter._replace_variable(
                    string(observable[column]), placeholder, "(" * strip(value) * ")")
            end
        end
        occursin(r"\bobservableParameter\d+_", string(observable.noiseFormula)) &&
            throw(ArgumentError("Incomplete observable-parameter mapping in noise formula"))
        measurements[!, :observableParameters] = Union{Missing, String}[
            _missing(value) ? missing : string(value) for value in measurements.observableParameters]
        measurements[rows, :observableParameters] .= missing
        push!(repaired, "inlined shared observable mapping for $(observable.observableId)'s noise")
    end
    return repaired
end

function _condition_formula_string(expression)
    value = Symbolics.value(expression)
    Symbolics.iscall(value) || return string(value)
    op, args = Symbolics.operation(value), Symbolics.arguments(value)
    parts = _condition_formula_string.(args)
    if op in (+, -, *, /, ^)
        length(parts) == 1 && return "($(string(op))$(only(parts)))"
        return "(" * join(parts, " $(string(op)) ") * ")"
    end
    # Do not use Symbolics' display form here: it prints 2*k as `2k`, which
    # PEtab's identifier scanner fails to recognize as depending on k.
    op in (exp, log, log10, sqrt) || throw(ArgumentError("Unsupported condition formula: $expression"))
    return string(op) * "(" * join(parts, ", ") * ")"
end

function _normalize_condition_inputs(paths, tables)
    # A non-constant SBML parameter without rules or events is still constant
    # within each experiment. SBMLImporter 4.1 can eliminate it as a zero-rate
    # state before PEtab applies conditions (Raia's il13_level). Use SBML.jl's
    # reader/writer to retain those specific inputs as parameters. This is an
    # equivalent temporary representation; the published SBML remains untouched.
    sbml = PEtab.SBMLImporter.SBML
    model = sbml.readSBML(paths[:SBML])
    isempty(model.events) || return paths, String[]
    any(rule -> rule isa sbml.AlgebraicRule, model.rules) && return paths, String[]
    condition_columns = string.(propertynames(tables[:conditions]))
    changed = String[]
    for (id, parameter) in model.parameters
        parameter.constant === false || continue
        id in condition_columns || continue
        haskey(model.initial_assignments, id) && continue
        any(rule -> hasproperty(rule, :variable) && rule.variable == id, model.rules) && continue
        push!(changed, id)
    end
    isempty(changed) && return paths, changed
    directory = mktempdir(; prefix="odepe-petab-inputs-")
    normalized_path = joinpath(directory, basename(paths[:SBML]))
    # Use the documented native-document conversion hook. Reconstructing the
    # whole Julia SBML.Model loses annotation metadata needed by libSBML's
    # CVTerm writer for Raia; editing the native document preserves it.
    sbml.readSBML(paths[:SBML], document -> begin
        native_model = ccall(sbml.sbml(:SBMLDocument_getModel), Ptr{Cvoid}, (Ptr{Cvoid},), document)
        native_model == C_NULL && error("SBML input normalization found no model")
        for id in changed
            parameter = ccall(sbml.sbml(:Model_getParameterById), Ptr{Cvoid},
                (Ptr{Cvoid}, Cstring), native_model, id)
            parameter == C_NULL && error("SBML input normalization lost parameter $id")
            code = ccall(sbml.sbml(:Parameter_setConstant), Cint, (Ptr{Cvoid}, Cint), parameter, 1)
            iszero(code) || error("SBML input normalization failed for $id (code $code)")
        end
        code = ccall(sbml.sbml(:writeSBML), Cint, (Ptr{Cvoid}, Cstring), document, normalized_path)
        code == 1 || error("Writing normalized SBML input failed")
    end)
    normalized_paths = copy(paths)
    normalized_paths[:SBML] = normalized_path
    return normalized_paths, ["constant condition input $id" for id in changed]
end

# Parse adapter arithmetic without eval, accepting only whitelisted operators.
function _formula(value, names::AbstractDict)
    value isa Number && return Num(value)
    value isa Symbol && return get(names, String(value)) do
        throw(ArgumentError("Unknown PEtab formula identifier: $value"))
    end
    value isa AbstractString && return _formula(Meta.parse(value), names)
    value isa Expr && value.head == :call || throw(ArgumentError("Unsupported PEtab expression: $value"))
    op, args = first(value.args), value.args[2:end]
    operators = Dict(:+ => +, :- => -, :* => *, :/ => /, :// => /, :^ => ^, :exp => exp,
        :log => log, :log10 => log10, :sqrt => sqrt)
    haskey(operators, op) || throw(ArgumentError("Unsupported PEtab formula operator: $op"))
    return operators[op]((_formula(arg, names) for arg in args)...)
end

function _substitute_all(expr, replacements)
    result = Num(expr)
    for _ in 1:(length(replacements) + 1)
        next = Num(Symbolics.substitute(result, replacements))
        # Avoid expanding rational expressions into large floating-point
        # polynomials here. Substitution already folds numerical arithmetic.
        isequal(next, result) && return next
        result = next
    end
    throw(ArgumentError("Cyclic symbolic assignment in the imported PEtab model"))
end

function _constant_input_branch(expr, interval)
    value = Symbolics.value(expr)
    Symbolics.iscall(value) || return Num(value)
    op, args = Symbolics.operation(value), Symbolics.arguments(value)
    if string(op) == "ifelse"
        condition = Symbolics.value(args[1])
        if condition isa Bool
            return _constant_input_branch(args[condition ? 2 : 3], interval)
        end
        cop, cargs = Symbolics.operation(condition), Symbolics.arguments(condition)
        cop in (<, <=, >, >=) || throw(ArgumentError("Unsupported piecewise condition: $condition"))
        difference = Num(cargs[1]) - Num(cargs[2])
        slope = Symbolics.value(Symbolics.derivative(difference, t))
        intercept = Symbolics.value(Symbolics.substitute(difference, Dict(t => 0.0)))
        slope isa Real && intercept isa Real || throw(ArgumentError("Estimated switching time is outside the pilot"))
        root = iszero(slope) ? Inf : -intercept / slope
        interval[1] < root < interval[2] && throw(ArgumentError("An input changes inside the measured interval"))
        middle = sum(interval) / 2
        choice = cop(Float64(slope) * middle + Float64(intercept), 0.0)
        return _constant_input_branch(args[choice ? 2 : 3], interval)
    elseif op in (+, -, *, /, ^, exp)
        return Num(op((_constant_input_branch(arg, interval) for arg in args)...))
    end
    return Num(value)
end

function _lift_exponential(expr, lifts, extra_equations, initial_maps, parameter_symbols)
    value = Symbolics.value(expr)
    Symbolics.iscall(value) || return Num(value)
    op, args = Symbolics.operation(value), Symbolics.arguments(value)
    if op === exp
        argument = Num(only(args))
        rate = Symbolics.derivative(argument, t)
        zero_argument = Symbolics.substitute(argument, Dict(t => 0.0))
        isequal(Symbolics.simplify(zero_argument), Num(0)) ||
            throw(ArgumentError("Only exp(rate*t) inputs are supported by the pilot"))
        _assert_rational(rate, parameter_symbols)
        return get!(lifts, Num(value)) do
            state = _new_state("petab_input$(length(initial_maps) + 1)")
            push!(extra_equations, D(state) ~ rate * state)
            initial_maps[state] = Num(1)
            state
        end
    elseif op in (+, -, *, /, ^)
        return Num(op((_lift_exponential(arg, lifts, extra_equations, initial_maps, parameter_symbols) for arg in args)...))
    end
    return Num(value)
end

function _assert_rational(expr, allowed)
    value = Symbolics.value(expr)
    any(x -> isequal(value, Symbolics.value(x)), allowed) && return
    if !Symbolics.iscall(value)
        value isa Real && isfinite(value) && return
        throw(ArgumentError("Unmapped or unsupported symbol in algebraic model: $value"))
    end
    op, args = Symbolics.operation(value), Symbolics.arguments(value)
    if op === (^)
        power = Symbolics.value(args[2])
        power isa Real && isinteger(power) || throw(ArgumentError("Estimated or noninteger exponent is outside the PEtab pilot: $expr"))
        _assert_rational(args[1], allowed)
    elseif op in (+, -, *, /)
        foreach(arg -> _assert_rational(arg, allowed), args)
    else
        throw(ArgumentError("Nonrational expression is outside the PEtab pilot: $expr"))
    end
end

function _condition_parameter_values(model, condition, names)
    ps = Num.(parameters(model.sys))
    defaults = Dict(Num(k) => Num(v) for (k, v) in model.parametermap)
    replacements = Dict{Num, Num}()
    for p in ps
        id = _name(p)
        cell = _column(condition, Symbol(id))
        if startswith(id, "__init__") && endswith(id, "__")
            species_id = id[9:(end - 2)]
            cell = _column(condition, Symbol(species_id), cell)
        end
        replacements[p] = !_missing(cell) ? _formula(cell, names) :
            haskey(names, id) ? names[id] : get(defaults, p) do
                throw(ArgumentError("No value or PEtab mapping for model parameter $id"))
            end
    end
    return Num[_substitute_all(replacements[p], replacements) for p in ps]
end

function _row_formula(row, observable, names)
    local_names = copy(names)
    overrides = _column(row, :observableParameters)
    if !_missing(overrides)
        for (index, value) in enumerate(split(string(overrides), ';'))
            local_names["observableParameter$(index)_$(observable.observableId)"] = _formula(value, names)
        end
    end
    return _formula(observable.observableFormula, local_names)
end

function load_petab_problem(path::AbstractString; initial_time::Real=0.0, verbose::Bool=false,
        ode_options::NamedTuple=(;))
    iszero(initial_time) || throw(ArgumentError("PEtab v1 preparation is defined at time zero; its initial epoch cannot be overridden"))
    model, repaired = _load_petab_model(path; verbose=verbose)
    tables = model.petab_tables
    tables[:yaml]["format_version"] in (1, "1.0.0") ||
        throw(ArgumentError("The ODEPE pilot currently supports PEtab v1"))
    measurements, conditions = tables[:measurements], tables[:conditions]
    for row in eachrow(measurements)
        _missing(_column(row, :preequilibrationConditionId)) ||
            throw(ArgumentError("Pre-equilibration is outside the ODEPE PEtab pilot"))
        isfinite(row.time) || throw(ArgumentError("Steady-state measurements are outside the ODEPE PEtab pilot"))
    end
    for callbacks in values(model.callbacks)
        isempty(callbacks.continuous_callbacks) && isempty(callbacks.discrete_callbacks) ||
            throw(ArgumentError("SBML events are outside the ODEPE PEtab pilot"))
    end
    prob = PEtabODEProblem(model; verbose=verbose, ode_options...)
    parameter_ids = String.(prob.xnames)
    parameter_rows = Dict(string(row.parameterId) => row for row in eachrow(tables[:parameters]))
    parameter_symbols = Num[_new_parameter(i) for i in eachindex(parameter_ids)]
    parameter_scales = Symbol[Symbol(parameter_rows[id].parameterScale) for id in parameter_ids]
    names = Dict{String, Num}(id => p for (id, p) in zip(parameter_ids, parameter_symbols))
    for row in eachrow(tables[:parameters])
        # Published estimates never enter the algebraic equations or truth fields.
        row.estimate == 0 && (names[string(row.parameterId)] = Num(row.nominalValue))
    end
    original_states, original_params = Num.(unknowns(model.sys)), Num.(parameters(model.sys))
    cids = unique(String.(measurements.simulationConditionId))
    state_maps = OrderedDict{String, Vector{Num}}()
    initial_maps = OrderedDict{Num, Num}()
    equations_joint, measured_joint = Equation[], Equation[]
    series = ObservationSeries[]
    row_observables = Vector{Num}(undef, size(measurements, 1))
    offsets = OrderedDict{String, Float64}()
    extra_equations = Equation[]
    auxiliary_states = Num[]
    observable_rows = Dict(string(row.observableId) => row for row in eachrow(tables[:observables]))
    for (ci, cid) in enumerate(cids)
        condition = only(row for row in eachrow(conditions) if string(row.conditionId) == cid)
        local_states = Num[_new_state("petab_c$(ci)_x$(i)") for i in eachindex(original_states)]
        state_maps[cid] = local_states
        local_rows = findall(==(cid), String.(measurements.simulationConditionId))
        # Autonomous experiments may use different absolute measurement windows.
        # Their algebraic anchors use local elapsed time; preparation inversion
        # below translates recovered states back to physical time zero.
        offsets[cid] = minimum(measurements[local_rows, :time])
        interval = (Float64(initial_time), maximum(measurements[local_rows, :time]))
        lifts = Dict{Num, Num}()
        ps = _condition_parameter_values(model, condition, names)
        substitutions = Dict{Num, Num}(zip(original_params, ps))
        substitutions[Num(ModelingToolkit.get_iv(model.sys))] = Num(t)
        merge!(substitutions, Dict(zip(original_states, local_states)))
        for eq in observed(model.sys)
            substitutions[Num(eq.lhs)] = Num(eq.rhs)
        end
        u0 = model.u0(ps)
        length(u0) == length(local_states) || error("PEtab initial-state order mismatch")
        for (s, value) in zip(local_states, u0)
            initial_maps[s] = _substitute_all(value, substitutions)
        end
        for eq in equations(model.sys)
            old_state = Num(only(Symbolics.arguments(Symbolics.value(eq.lhs))))
            haskey(substitutions, old_state) || error("Non-ODE equation in PEtab model: $eq")
            rhs = _constant_input_branch(_substitute_all(eq.rhs, substitutions), interval)
            rhs = _lift_exponential(rhs, lifts, extra_equations, initial_maps, parameter_symbols)
            push!(equations_joint, D(substitutions[old_state]) ~ rhs)
        end
        local_names = copy(names)
        for (old, new) in substitutions
            local_names[_name(old)] = _substitute_all(new, substitutions)
        end
        local_names["time"] = t
        local_names["t"] = t
        # Each override defines a separate signal, even for the same observable ID.
        groups = OrderedDict{Tuple{String, String}, Vector{Int}}()
        for (ri, row) in enumerate(eachrow(measurements))
            string(row.simulationConditionId) == cid || continue
            override = _column(row, :observableParameters)
            key = (string(row.observableId), _missing(override) ? "" : string(override))
            push!(get!(groups, key, Int[]), ri)
        end
        for ((oid, _), rows) in groups
            observable = observable_rows[oid]
            expr = _row_formula(measurements[first(rows), :], observable, local_names)
            expr = _substitute_all(expr, substitutions)
            row_observables[rows] .= Ref(expr)
            signal = _new_state("petab_y$(length(measured_joint) + 1)")
            push!(measured_joint, signal ~ expr)
            push!(series, ObservationSeries(oid, cid, expr,
                measurements[rows, :time] .- offsets[cid], measurements[rows, :measurement]))
        end
        !isempty(lifts) && offsets[cid] != 0 && throw(ArgumentError("Time-shifted exponential inputs require a preparation map not implemented in this pilot"))
        append!(auxiliary_states, values(lifts))
    end
    append!(equations_joint, extra_equations)
    states_joint = vcat(reduce(vcat, values(state_maps)), auxiliary_states)
    allowed = vcat(states_joint, parameter_symbols)
    for eq in vcat(equations_joint, measured_joint)
        _assert_rational(eq.rhs, allowed)
    end
    used = Set(Num(v) for eq in vcat(equations_joint, measured_joint) for v in Symbolics.get_variables(eq.rhs))
    algebraic_params = filter(p -> p in used, parameter_symbols)
    ordered, measured = create_ordered_ode_system(model.name, states_joint, algebraic_params,
        equations_joint, measured_joint)
    data = ObservationData(series; initial_time=initial_time)
    pep = ParameterEstimationProblem(model.name, ordered, measured, data,
        [Float64(initial_time), maximum(measurements.time)], package_wide_default_ode_solver,
        OrderedDict{Num, Float64}(), OrderedDict{Num, Float64}(), 0)
    notes = ["Joint finite experiment design is constructed before identifiability analysis.",
        "Algebraic initial states are relaxed; PEtab scoring enforces the original preparation.",
        "Noise and observable transformations remain in the PEtab objective; interpolation uses raw signal units."]
    !isempty(repaired) && push!(notes, "PEtab import compatibility repairs: $(join(repaired, ", "))")
    any(!iszero, values(offsets)) && push!(notes, "Algebraic state times use per-experiment offsets; original preparation is restored before IC parameter projection.")
    return PEtabAlgebraicProblem(abspath(path), prob, pep, parameter_ids, parameter_symbols,
        parameter_scales, initial_maps, state_maps, row_observables, offsets, notes)
end
