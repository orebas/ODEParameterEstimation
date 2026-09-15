# Experimental, explicitly requested extraction. The ordinary adapter/estimator
# still uses its explicit ODE. These definitions are not independent fit parameters.
import ODEParameterEstimation: Nemo
const CoefficientSBML = PEtab.SBMLImporter.SBML

struct PEtabCoefficientStructure{F}
    condition_id::String
    ring::Nemo.QQMPolyRing
    state_ids::Vector{String}
    parameter_ids::Vector{String}
    assignments::OrderedDict{String, F}
    coefficients::OrderedDict{String, F}
    expanded_coefficients::OrderedDict{String, F}
    dynamics::OrderedDict{String, F}
    expanded_dynamics::OrderedDict{String, F}
    denominator_guards::Vector{Nemo.QQMPolyRingElem}
end

_coefficient_rational(x::Integer) = Nemo.QQ(x)
_coefficient_rational(x::Rational) = Nemo.QQ(x)
function _coefficient_rational(x::AbstractFloat)
    isfinite(x) || throw(ArgumentError("Nonfinite coefficient literal: $x"))
    # Match the rational-model convention used by convert_to_si_ode. This is
    # rationalization of SBML's parsed Float64, not recovery of XML lexical digits.
    return Nemo.QQ(rationalize(BigInt, x))
end

function _coefficient_apply(op::String, args, guards)
    op == "+" && return sum(args)
    op == "*" && return prod(args)
    op == "-" && return length(args) == 1 ? -only(args) : foldl(-, args)
    if op == "/" && length(args) == 2
        iszero(args[2]) && throw(ArgumentError("Zero denominator in coefficient definition"))
        push!(guards, Nemo.numerator(args[2]))
        return args[1] / args[2]
    elseif op == "^" && length(args) == 2
        isempty(Nemo.vars(Nemo.numerator(args[2]))) &&
            Nemo.denominator(args[2]) == 1 || throw(ArgumentError("Coefficient exponent must be an integer"))
        coefficient = Nemo.constant_coefficient(Nemo.numerator(args[2]))
        isone(Nemo.denominator(coefficient)) || throw(ArgumentError("Coefficient exponent must be an integer"))
        exponent = Int(Nemo.numerator(coefficient))
        if exponent < 0
            iszero(args[1]) && throw(ArgumentError("Zero denominator in negative power"))
            push!(guards, Nemo.numerator(args[1]))
        end
        return args[1]^exponent
    end
    throw(ArgumentError("Unsupported coefficient operation: $op"))
end

function _coefficient_math(expr::CoefficientSBML.Math, names, field, guards)
    expr isa CoefficientSBML.MathVal && return field(_coefficient_rational(expr.val))
    expr isa CoefficientSBML.MathIdent && return get(names, expr.id) do
        throw(ArgumentError("Unknown coefficient identifier: $(expr.id)"))
    end
    if expr isa CoefficientSBML.MathApply
        return _coefficient_apply(expr.fn,
            [_coefficient_math(a, names, field, guards) for a in expr.args], guards)
    end
    throw(ArgumentError("Coefficient extraction requires time-independent rational expressions; got $(typeof(expr))"))
end

function _coefficient_formula(expr, names, field, guards)
    expr isa Number && return field(_coefficient_rational(expr))
    expr isa AbstractString && return _coefficient_formula(Meta.parse(expr), names, field, guards)
    expr isa Symbol && return get(names, string(expr)) do
        throw(ArgumentError("Unknown condition identifier: $expr"))
    end
    expr isa Expr && expr.head == :call && expr.args[1] isa Symbol ||
        throw(ArgumentError("Unsupported coefficient condition formula: $expr"))
    return _coefficient_apply(string(expr.args[1]),
        [_coefficient_formula(a, names, field, guards) for a in expr.args[2:end]], guards)
end

function _coefficient_symbolic(expr, names, field)
    value = Symbolics.value(expr)
    haskey(names, string(value)) && return names[string(value)]
    value isa Real && return field(_coefficient_rational(value))
    Symbolics.iscall(value) || throw(ArgumentError("Unmapped imported coefficient symbol: $value"))
    op = Symbolics.operation(value)
    op in (+, -, *, /, ^) || throw(ArgumentError("Unsupported imported coefficient operation: $op"))
    return _coefficient_apply(string(op),
        [_coefficient_symbolic(a, names, field) for a in Symbolics.arguments(value)], Nemo.QQMPolyRingElem[])
end

function _verify_coefficient_import(problem, condition_id, state_ids, dynamics, names, field)
    model = problem.petab.model_info.model
    original_ids = _name.(unknowns(model.sys))
    Set(original_ids) == Set(state_ids) || throw(ArgumentError("Coefficient extraction requires the same states as the imported ODE"))
    local_states = problem.condition_states[condition_id]
    imported_names = Dict(string(s) => names[id] for (s, id) in zip(local_states, original_ids))
    merge!(imported_names, Dict(string(p) => names[id]
        for (p, id) in zip(problem.parameter_symbols, problem.parameter_ids)))
    state_names = Dict(zip(local_states, original_ids))
    checked = Set{String}()
    for eq in equations(problem.algebraic.model.system)
        state = Num(only(Symbolics.arguments(Symbolics.value(eq.lhs))))
        haskey(state_names, state) || continue
        id = state_names[state]
        _coefficient_symbolic(eq.rhs, imported_names, field) == dynamics[id] ||
            throw(ArgumentError("Coefficient extraction disagrees with the loaded adapter for $id; source files or import semantics differ"))
        push!(checked, id)
    end
    checked == Set(state_ids) || error("Coefficient extraction did not verify every imported ODE equation")
    return nothing
end

# Polynomial evaluation in a rational-function field. Avoid converting to
# Float64, expression strings, or eval while substituting nested definitions.
function _coefficient_polyeval(poly::Nemo.QQMPolyRingElem, values::Vector{F}) where {F}
    result = zero(first(values))
    for (coefficient, exponents) in zip(Nemo.coefficients(poly), Nemo.exponent_vectors(poly))
        term = one(result) * coefficient
        for i in eachindex(exponents)
            iszero(exponents[i]) || (term *= values[i]^exponents[i])
        end
        result += term
    end
    return result
end

function _coefficient_substitute(expr, replacements)
    field = parent(expr)
    ring = parent(Nemo.numerator(expr))
    values = [get(replacements, string(v), field(v)) for v in Nemo.gens(ring)]
    denominator = _coefficient_polyeval(Nemo.denominator(expr), values)
    iszero(denominator) && throw(ArgumentError("Coefficient substitution reaches an excluded denominator"))
    return _coefficient_polyeval(Nemo.numerator(expr), values) / denominator
end

function _resolve_coefficient_definitions(definitions::OrderedDict{String, F}) where {F}
    resolved = OrderedDict{String, F}()
    pending = Set{String}()
    function visit(id)
        haskey(resolved, id) && return resolved[id]
        id in pending && throw(ArgumentError("Cyclic coefficient definitions at $id"))
        push!(pending, id)
        expression = definitions[id]
        dependencies = union(Nemo.vars(Nemo.numerator(expression)), Nemo.vars(Nemo.denominator(expression)))
        replacements = Dict{String, F}()
        for variable in dependencies
            name = string(variable)
            haskey(definitions, name) && (replacements[name] = visit(name))
        end
        resolved[id] = _coefficient_substitute(expression, replacements)
        delete!(pending, id)
        return resolved[id]
    end
    foreach(visit, keys(definitions))
    return resolved
end

"""
    petab_coefficient_structure(problem, condition_id)

Extract named SBML assignments and constant reaction coefficients without
changing the estimation model. This experimental adapter entry point currently
accepts rational, time-independent assignments and reaction fluxes consisting
of a parameter-only coefficient times one state, in unit compartments.

# Arguments
- `problem`: A loaded PEtab adapter, retaining the source path and condition table.
- `condition_id`: One experimental condition. Shared estimated parameters stay
  symbolic; their nominal values are never substituted.

# Returns
A `PEtabCoefficientStructure` with compact dynamics, defining rational maps,
fully expanded maps, and the original expression's denominator exclusions.
The expanded vector field is checked against the already-loaded adapter.
The coefficients are constrained auxiliaries, not a replacement parameter set.
No structural-identifiability or multiplicity claim is made by extraction.
"""
function petab_coefficient_structure(problem::PEtabAlgebraicProblem, condition_id::AbstractString)
    model = problem.petab.model_info.model
    tables = model.petab_tables
    condition = only(r for r in eachrow(tables[:conditions]) if string(r.conditionId) == condition_id)
    source = CoefficientSBML.readSBML(model.paths[:SBML])
    isempty(source.events) || throw(ArgumentError("Coefficient extraction does not support SBML events"))
    isempty(source.initial_assignments) || throw(ArgumentError("Coefficient extraction does not yet support SBML initial assignments"))
    all(r -> r isa CoefficientSBML.AssignmentRule, source.rules) ||
        throw(ArgumentError("Coefficient extraction requires explicit assignment rules"))
    all(c -> c.size == 1 && c.constant !== false, values(source.compartments)) ||
        throw(ArgumentError("Coefficient extraction currently requires constant unit compartments"))
    all(s -> s.boundary_condition !== true && s.constant !== true, values(source.species)) ||
        throw(ArgumentError("Coefficient extraction currently requires dynamic species"))

    states = sort!(collect(keys(source.species)))
    estimated = copy(problem.parameter_ids)
    assignment_ids = [r.variable for r in source.rules]
    all(id -> haskey(source.parameters, id), assignment_ids) ||
        throw(ArgumentError("Only parameter assignment rules are supported by coefficient extraction"))
    reactions = sort!(collect(keys(source.reactions)))
    coefficient_ids = ["__odepe_coefficient_$i" for i in eachindex(reactions)]
    original_names = unique(vcat(states, sort!(collect(keys(source.parameters))), estimated,
        sort!(collect(keys(source.compartments)))))
    isempty(intersect(original_names, coefficient_ids)) || throw(ArgumentError("Coefficient identifier collision"))
    ring, variables = Nemo.polynomial_ring(Nemo.QQ, vcat(original_names, coefficient_ids); internal_ordering=:degrevlex)
    field = Nemo.fraction_field(ring)
    F = typeof(field(0))
    names = Dict(string(v) => field(v) for v in variables)
    guards = Nemo.QQMPolyRingElem[]
    known = OrderedDict{String, F}()
    for (id, c) in source.compartments
        known[id] = field(_coefficient_rational(c.size))
    end
    fixed_rows = Dict(string(r.parameterId) => r.nominalValue for r in eachrow(tables[:parameters]) if r.estimate == 0)
    for (id, p) in source.parameters
        id in assignment_ids && continue
        value = _column(condition, Symbol(id))
        if !_missing(value)
            known[id] = _coefficient_formula(value, names, field, guards)
        elseif !(id in estimated)
            value = get(fixed_rows, id, p.value)
            isnothing(value) && throw(ArgumentError("Missing fixed parameter value: $id"))
            known[id] = field(_coefficient_rational(value))
        end
    end
    # Mapping a model parameter to the same estimated parameter is an identity,
    # not an algebraic loop (a common PEtab condition-table convention).
    filter!(pair -> pair.second != names[pair.first], known)
    known = _resolve_coefficient_definitions(known)
    assignments = OrderedDict{String, F}()
    for rule in source.rules
        value = _coefficient_math(rule.math, names, field, guards)
        assignments[rule.variable] = _coefficient_substitute(value, known)
    end
    expanded_assignments = _resolve_coefficient_definitions(assignments)
    for (id, value) in expanded_assignments
        deps = union(Nemo.vars(Nemo.numerator(value)), Nemo.vars(Nemo.denominator(value)))
        all(v -> string(v) in estimated, deps) ||
            throw(ArgumentError("Assignment $id is not a parameter-only coefficient"))
    end

    coefficients = OrderedDict{String, F}()
    expanded_coefficients = OrderedDict{String, F}()
    dynamics = OrderedDict(s => field(0) for s in states)
    original_dynamics = OrderedDict(s => field(0) for s in states)
    for (index, rid) in enumerate(reactions)
        reaction = source.reactions[rid]
        isempty(reaction.kinetic_parameters) || throw(ArgumentError("Local reaction parameters are outside coefficient extraction"))
        isnothing(reaction.kinetic_math) && throw(ArgumentError("Missing kinetic law for $rid"))
        flux = _coefficient_substitute(_coefficient_math(reaction.kinetic_math, names, field, guards), known)
        iszero(flux) && continue
        dependencies = union(Nemo.vars(Nemo.numerator(flux)), Nemo.vars(Nemo.denominator(flux)))
        involved = filter(s -> Nemo.numerator(names[s]) in dependencies, states)
        length(involved) == 1 || throw(ArgumentError("Reaction $rid is not coefficient times one state"))
        coefficient = flux / names[only(involved)]
        deps = union(Nemo.vars(Nemo.numerator(coefficient)), Nemo.vars(Nemo.denominator(coefficient)))
        isempty(intersect(string.(deps), states)) || throw(ArgumentError("Reaction $rid is nonlinear in states"))
        expanded = _coefficient_substitute(coefficient, expanded_assignments)
        all(v -> string(v) in estimated,
            union(Nemo.vars(Nemo.numerator(expanded)), Nemo.vars(Nemo.denominator(expanded)))) ||
            throw(ArgumentError("Reaction $rid contains unresolved coefficient inputs"))
        # Deduplicate only identical rational maps. Keep all original guards even
        # when cancellation or deduplication removes a factor from the map.
        id = findfirst(==(expanded), expanded_coefficients)
        if isnothing(id)
            id = coefficient_ids[index]
            coefficients[id] = coefficient
            expanded_coefficients[id] = expanded
        end
        lifted_flux = names[id] * names[only(involved)]
        for (sign, refs) in ((-1, reaction.reactants), (1, reaction.products))
            for ref in refs
                stoichiometry = isnothing(ref.stoichiometry) ? Nemo.QQ(1) : _coefficient_rational(ref.stoichiometry)
                dynamics[ref.species] += sign * stoichiometry * lifted_flux
                original_dynamics[ref.species] += sign * stoichiometry * flux
            end
        end
    end
    expanded_dynamics = OrderedDict(s => _coefficient_substitute(dynamics[s], expanded_coefficients) for s in states)
    for s in states
        expanded_dynamics[s] == _coefficient_substitute(original_dynamics[s], expanded_assignments) ||
            error("Coefficient extraction changed the vector field for $s")
    end
    _verify_coefficient_import(problem, string(condition_id), states, expanded_dynamics, names, field)
    retained_guards = Nemo.QQMPolyRingElem[]
    for g in guards
        value = _coefficient_substitute(field(g), known)
        iszero(value) && throw(ArgumentError("Condition lies on an excluded source denominator"))
        polynomial = Nemo.numerator(value)
        isempty(Nemo.vars(polynomial)) && continue
        polynomial *= inv(first(Nemo.coefficients(polynomial)))
        polynomial in retained_guards || push!(retained_guards, polynomial)
    end
    return PEtabCoefficientStructure(string(condition_id), ring, states, estimated, assignments,
        coefficients, expanded_coefficients, dynamics, expanded_dynamics, retained_guards)
end
