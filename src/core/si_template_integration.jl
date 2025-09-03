"""
SI.jl Template Integration for ODEParameterEstimation

This module provides the glue between SI.jl's polynomial template
and ODEPE's multipoint system construction.
"""

using StructuralIdentifiability
using ModelingToolkit
using Symbolics
using OrderedCollections

"""
    construct_equation_system_from_si_template(
        model, measured_quantities, data_sample,
        deriv_level, unident_dict, varlist, DD;
        interpolator, time_index_set, kwargs...
    )

Drop-in replacement for construct_equation_system that uses SI.jl's template
instead of iterative construction.

This function:
1. Gets the polynomial template from SI.jl (once)
2. Creates interpolated_values_dict for the specific time point
3. Substitutes values into the template
"""
function construct_equation_system_from_si_template(
    model::ModelingToolkit.AbstractSystem,
    measured_quantities_in,
    data_sample,
    deriv_level,
    unident_dict,
    varlist,
    DD;
    interpolator,
    time_index_set = nothing,
    precomputed_interpolants = nothing,
    diagnostics = false,
    si_template = nothing,  # Cache the template if provided
    kwargs...
)
    measured_quantities = deepcopy(measured_quantities_in)
    (t, model_eq, model_states, model_ps) = unpack_ODE(model)
    
    t_vector = data_sample["t"]
    if isnothing(time_index_set)
        time_index_set = [fld(length(t_vector), 2)]
    end
    time_index = time_index_set[1]
    
    # Get or create the SI.jl template
    if isnothing(si_template)
        # Create OrderedODESystem wrapper if needed
        ordered_model = if isa(model, ODEParameterEstimation.OrderedODESystem)
            model
        else
            ODEParameterEstimation.OrderedODESystem(model, model_states, model_ps)
        end
        
        # Get the template from SI.jl
        template_equations, derivative_dict, unidentifiable = get_si_equation_system(
            ordered_model,
            measured_quantities,
            data_sample;
            infolevel = diagnostics ? 1 : 0
        )
        
        si_template = (
            equations = template_equations,
            deriv_dict = derivative_dict,
            unidentifiable = unidentifiable
        )
        
        if diagnostics
            println("[DEBUG-SI] Got $(length(template_equations)) template equations from SI.jl")
            println("[DEBUG-SI] Derivative variables: ", keys(derivative_dict))
        end
    else
        template_equations = si_template.equations
        derivative_dict = si_template.deriv_dict
    end
    
    # Create interpolants if not provided
    if isnothing(precomputed_interpolants)
        interpolants = create_interpolants(measured_quantities, data_sample, t_vector, interpolator)
    else
        interpolants = precomputed_interpolants
    end
    
    # Apply unidentifiable substitutions
    unident_subst!(model_eq, measured_quantities, unident_dict)
    
    # Build interpolated_values_dict (same as iterative version!)
    interpolated_values_dict = Dict()
    
    # For each measured quantity and its derivatives
    for (key, value) in deriv_level
        # Base observable value
        obs_var = DD.obs_lhs[1][key]
        obs_interpolant = interpolants[ModelingToolkit.diff2term(measured_quantities[key].rhs)]
        interpolated_values_dict[obs_var] = nth_deriv_at(obs_interpolant, 0, t_vector[time_index])
        
        # Derivative values
        for i in 1:value
            deriv_var = DD.obs_lhs[i+1][key]
            interpolated_values_dict[deriv_var] = nth_deriv_at(obs_interpolant, i, t_vector[time_index])
        end
    end
    
    if diagnostics
        println("[DEBUG-SI] Created interpolated_values_dict with $(length(interpolated_values_dict)) entries")
    end
    
    # Substitute values into template equations
    target = []
    for eq in template_equations
        # Substitute interpolated values
        eq_subst = Symbolics.substitute(eq, interpolated_values_dict)
        push!(target, eq_subst)
    end
    
    # Determine variables needed (same as iterative)
    vars_needed = OrderedSet()
    vars_needed = union(vars_needed, model_ps)
    vars_needed = union(vars_needed, model_states)
    vars_needed = setdiff(vars_needed, keys(unident_dict))
    
    # Add any derivative variables that weren't substituted
    for eq in target
        vars_in_eq = Symbolics.get_variables(eq)
        for v in vars_in_eq
            # Check if it's a derivative variable that needs to be added
            if !(v in vars_needed) && !(v in keys(interpolated_values_dict))
                push!(vars_needed, v)
            end
        end
    end
    
    return (target, collect(vars_needed))
end

# Export the template-based constructor
export construct_equation_system_from_si_template