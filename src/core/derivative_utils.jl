using ModelingToolkit
using Symbolics

"""
    calculate_higher_derivatives(equations, max_level)

Calculate higher-order derivatives of equations up to the specified level.
This is a general utility function for handling the common pattern of
calculating derivatives throughout the codebase.

# Arguments
- `equations`: Initial equations
- `max_level`: Maximum derivative level to calculate

# Returns
- Vector of vectors containing derivatives at each level
"""
function calculate_higher_derivatives(equations, max_level)
    derivatives = [deepcopy(equations)]
    # Extract the time variable from the first differential equation
    # Use the global t variable from ODEParameterEstimation
    t = ODEParameterEstimation.t
    D = Differential(t)
    
    for i in 1:max_level
        # Calculate next level of derivatives
        next_level = []
        for eq in derivatives[end]
            # Use ModelingToolkit's D operator to differentiate
            diff_eq = expand_derivatives(D(eq))
            push!(next_level, diff_eq)
        end
        push!(derivatives, next_level)
    end
    
    # Convert all derivatives to terms using diff2term
    for i in eachindex(derivatives), j in eachindex(derivatives[i])
        derivatives[i][j] = ModelingToolkit.diff2term(expand_derivatives(derivatives[i][j]))
    end
    
    return derivatives
end

"""
    calculate_higher_derivative_terms(lhs_terms, rhs_terms, max_level)

Calculate higher-order derivatives for paired LHS and RHS term arrays.
This helper function is used when populating DerivativeData structures.

# Arguments
- `lhs_terms`: Left-hand side terms
- `rhs_terms`: Right-hand side terms
- `max_level`: Maximum derivative level to calculate

# Returns
- Tuple of (lhs_derivatives, rhs_derivatives)
"""
function calculate_higher_derivative_terms(lhs_terms, rhs_terms, max_level)
    lhs_derivatives = [lhs_terms]
    rhs_derivatives = [rhs_terms]
    D = Differential(ModelingToolkit.t_nounits)
    
    for i in 1:max_level
        push!(lhs_derivatives, expand_derivatives.(D.(lhs_derivatives[end])))
        
        temp = rhs_derivatives[end]
        temp2 = D.(temp)
        temp3 = deepcopy(temp2)
        temp4 = []
        
        for j in 1:length(temp3)
            temptemp = expand_derivatives(temp3[j])
            push!(temp4, deepcopy(temptemp))
        end
        
        push!(rhs_derivatives, temp4)
    end
    
    # Convert derivatives to terms
    for i in eachindex(lhs_derivatives), j in eachindex(lhs_derivatives[i])
        lhs_derivatives[i][j] = ModelingToolkit.diff2term(expand_derivatives(lhs_derivatives[i][j]))
    end
    
    for i in eachindex(rhs_derivatives), j in eachindex(rhs_derivatives[i])
        rhs_derivatives[i][j] = ModelingToolkit.diff2term(expand_derivatives(rhs_derivatives[i][j]))
    end
    
    return lhs_derivatives, rhs_derivatives
end