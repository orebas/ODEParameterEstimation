"""
    calculate_higher_derivatives(equations, max_level; independent_variable=t)

Differentiate both sides of each equation through `max_level` additional orders.
Derivative expressions in the returned equations are converted to symbolic jet
terms with `Symbolics.diff2term`.

# Arguments
- `equations`: Initial symbolic equations.
- `max_level`: Nonnegative number of additional derivative levels.
- `independent_variable`: Variable with respect to which to differentiate.

# Returns
- Vector of equation vectors, beginning with the initial level in jet form.
"""
function calculate_higher_derivatives(
    equations::AbstractVector{<:Equation}, max_level::Integer;
    independent_variable=ODEParameterEstimation.t,
)
    lhs, rhs = calculate_higher_derivative_terms(
        getproperty.(equations, :lhs), getproperty.(equations, :rhs), max_level;
        independent_variable,
    )
    return [[left ~ right for (left, right) in zip(lhs[level], rhs[level])]
            for level in eachindex(lhs)]
end

"""
    calculate_higher_derivative_terms(lhs_terms, rhs_terms, max_level; independent_variable=t)

Calculate higher derivatives for equally sized arrays of left- and right-hand
terms. Input arrays are preserved. Differentiation precedes conversion to jet
terms, so higher orders retain the original derivative structure.

# Arguments
- `lhs_terms`: Initial left-hand terms.
- `rhs_terms`: Initial right-hand terms.
- `max_level`: Nonnegative number of additional derivative levels.
- `independent_variable`: Variable with respect to which to differentiate.

# Returns
- Tuple of derivative-level vectors for both sides, beginning at level zero.
"""
function calculate_higher_derivative_terms(
    lhs_terms::AbstractVector, rhs_terms::AbstractVector, max_level::Integer;
    independent_variable=ODEParameterEstimation.t,
)
    max_level >= 0 || throw(ArgumentError("max_level must be nonnegative"))
    length(lhs_terms) == length(rhs_terms) ||
        throw(DimensionMismatch("left- and right-hand term arrays must have equal length"))
    lhs_derivatives = [Num.(lhs_terms)]
    rhs_derivatives = [Num.(rhs_terms)]
    derivative = Differential(independent_variable)
    for _ in 1:max_level
        push!(lhs_derivatives, expand_derivatives.(derivative.(lhs_derivatives[end])))
        push!(rhs_derivatives, expand_derivatives.(derivative.(rhs_derivatives[end])))
    end
    # diff2term only converts a derivative at the root of an expression. Walk
    # sums/products too, visiting an entire derivative before its arguments so
    # nested or higher-order derivatives retain their complete order.
    to_jet_terms = SymbolicUtils.Prewalk(
        node -> Symbolics.is_derivative(node) ? Symbolics.diff2term(node) : node,
    )
    return (
        [Num.(to_jet_terms.(Symbolics.unwrap.(level))) for level in lhs_derivatives],
        [Num.(to_jet_terms.(Symbolics.unwrap.(level))) for level in rhs_derivatives],
    )
end
