"""
SI.jl Integration Module for ODEParameterEstimation

This module provides functions to use StructuralIdentifiability.jl 
for equation system construction instead of iterative scanning.
"""

using StructuralIdentifiability
using ModelingToolkit
using Symbolics
using Nemo
using AbstractAlgebra
using OrderedCollections
using LinearAlgebra

# Import SI's ODE type
import StructuralIdentifiability: ODE

"""
    convert_to_si_ode(ode, measured_quantities::Vector{ModelingToolkit.Equation}, inputs::Vector{Num} = Vector{Num}())

Convert ModelingToolkit ODESystem to StructuralIdentifiability.jl ODE format.
Based on ParameterEstimation.jl's preprocess_ode function.

Returns:
- si_ode: StructuralIdentifiability.ODE object
- input_symbols: Original symbolic variables
- gens: Nemo polynomial ring generators
"""
function convert_to_si_ode(
    ode,  # Will be OrderedODESystem but can't reference type here
    measured_quantities::Vector{ModelingToolkit.Equation},
    inputs = []  # Vector{Num}
)
    @info "Converting ODESystem to SI.jl format"
    
    model = ode.system
    
    # Filter out output equations from the ODE system
    diff_eqs = filter(eq -> !(ModelingToolkit.isoutput(eq.lhs)), 
                     ModelingToolkit.equations(model))
    
    # Get symbolic components
    y_functions = [each.lhs for each in measured_quantities]
    state_vars = ModelingToolkit.unknowns(model)
    params = ModelingToolkit.parameters(model)
    
    # Get time variable
    t = ModelingToolkit.get_iv(model)
    
    # Collect all parameters including from measured quantities
    params_from_measured = ModelingToolkit.parameters(
        ModelingToolkit.ODESystem(measured_quantities, t, name=:DataSeries)
    )
    params = union(params, params_from_measured)
    
    # Create input symbols array
    input_symbols = vcat(state_vars, y_functions, inputs, params)
    
    # Create generator strings (remove (t) from variables)
    generators = string.(input_symbols)
    generators = map(g -> replace(g, "(t)" => ""), generators)
    
    # Create Nemo polynomial ring
    R, gens_ = Nemo.polynomial_ring(Nemo.QQ, generators)
    
    # Create dictionaries for state equations and output equations
    state_eqn_dict = Dict{Nemo.QQMPolyRingElem,
        Union{Nemo.QQMPolyRingElem, Nemo.Generic.FracFieldElem{Nemo.QQMPolyRingElem}}}()
    
    out_eqn_dict = Dict{Nemo.QQMPolyRingElem,
        Union{Nemo.QQMPolyRingElem, Nemo.Generic.FracFieldElem{Nemo.QQMPolyRingElem}}}()
    
    # Convert state equations
    for i in eachindex(diff_eqs)
        lhs_nemo = substitute(state_vars[i], input_symbols .=> gens_)
        if !(typeof(diff_eqs[i].rhs) <: Number)
            rhs_nemo = eval_at_nemo(diff_eqs[i].rhs, Dict(input_symbols .=> gens_))
        else
            rhs_nemo = R(diff_eqs[i].rhs)
        end
        state_eqn_dict[lhs_nemo] = rhs_nemo
    end
    
    # Convert output equations
    for i in 1:length(measured_quantities)
        lhs_nemo = substitute(y_functions[i], input_symbols .=> gens_)
        rhs_nemo = eval_at_nemo(measured_quantities[i].rhs, Dict(input_symbols .=> gens_))
        out_eqn_dict[lhs_nemo] = rhs_nemo
    end
    
    # Convert inputs
    inputs_ = [substitute(each, input_symbols .=> gens_) for each in inputs]
    if isempty(inputs_)
        inputs_ = Vector{Nemo.QQMPolyRingElem}()
    end
    
    # Create SI.jl ODE object
    si_ode = ODE{Nemo.QQMPolyRingElem}(state_eqn_dict, out_eqn_dict, inputs_)
    
    return si_ode, input_symbols, gens_
end

"""
    eval_at_nemo(expr, subs_dict)

Evaluate a Symbolics expression in the Nemo polynomial ring.
Delegates to StructuralIdentifiability's eval_at_nemo function.
"""
function eval_at_nemo(expr, subs_dict)
    # Use StructuralIdentifiability's implementation
    return StructuralIdentifiability.eval_at_nemo(expr, subs_dict)
end

"""
    get_si_equation_system(ode, measured_quantities::Vector{ModelingToolkit.Equation}, data_sample::OrderedDict; kwargs...)

Get polynomial equation system from StructuralIdentifiability.jl.
This replaces the iterative equation construction in ODEPE.

Returns:
- equations: Polynomial equations in Symbolics format (template)
- derivative_vars: Dictionary mapping derivative variables to their orders
- unidentifiable: Set of unidentifiable parameters
"""
function get_si_equation_system(
    ode,  # Will be OrderedODESystem
    measured_quantities::Vector{ModelingToolkit.Equation},
    data_sample::OrderedDict;
    p = 0.99,
    p_mod = 0,
    infolevel = 0,
    kwargs...
)
    @info "Getting equation system from StructuralIdentifiability.jl"
    
    # Convert to SI.jl format
    si_ode, symbol_map, gens = convert_to_si_ode(ode, measured_quantities)
    
    # Get parameters for identifiability analysis
    params_to_assess = StructuralIdentifiability.get_parameters(si_ode)
    
    # Create mapping from Nemo to MTK types
    nemo2mtk = Dict(gens .=> symbol_map)
    
    # Run the full identifiability analysis to get polynomial system
    @info "Running SI.jl identifiability analysis"
    result = identifiability_ode(
        si_ode, 
        params_to_assess;
        p = p,
        p_mod = p_mod,
        infolevel = infolevel,
        weighted_ordering = false,
        local_only = false
    )
    
    # Extract the polynomial system (this is our template!)
    poly_system = result["polynomial_system"]
    y_derivative_dict = result["Y_eq"]  # Maps derivative variables to their orders
    
    # Extract identifiability results
    unidentifiable = result["identifiability"]["nonidentifiable"]
    
    @info "SI.jl found $(length(poly_system)) template equations"
    @info "Derivative variables: $(keys(y_derivative_dict))"
    @info "Non-identifiable parameters: $unidentifiable"
    
    # Convert polynomial system to Symbolics format
    # These equations are the template with derivative variables
    template_equations = []
    for poly in poly_system
        # Convert Nemo polynomial to Symbolics
        sym_eq = nemo_to_symbolics(poly, nemo2mtk)
        push!(template_equations, sym_eq)
    end
    
    return template_equations, y_derivative_dict, unidentifiable
end

"""
    identifiability_ode(ode, params_to_assess; kwargs...)

Wrapper for StructuralIdentifiability's identifiability analysis.
This is based on ParameterEstimation.jl's implementation.
"""
function identifiability_ode(ode, params_to_assess; p = 0.99, p_mod = 0, infolevel = 0,
                             weighted_ordering = false, local_only = false)
    # Try to use StructuralIdentifiability's function if available
    if isdefined(StructuralIdentifiability, :identifiability_ode)
        return StructuralIdentifiability.identifiability_ode(
            ode, params_to_assess;
            p = p, p_mod = p_mod, infolevel = infolevel,
            weighted_ordering = weighted_ordering, local_only = local_only
        )
    else
        # Fallback: use assess_identifiability if available
        result = StructuralIdentifiability.assess_identifiability(
            ode;
            funcs_to_check = params_to_assess,
            prob_threshold = p,
            loglevel = infolevel > 0 ? Logging.Info : Logging.Warn
        )
        
        # Convert to expected format
        return Dict(
            "polynomial_system" => [],  # Not available in this API
            "Y_eq" => Dict(),
            "identifiability" => Dict(
                "globally" => Set(k for (k,v) in result if v == :globally),
                "locally" => Set(k for (k,v) in result if v == :locally),
                "nonidentifiable" => Set(k for (k,v) in result if v == :nonidentifiable)
            )
        )
    end
end

"""
    convert_si_polys_to_symbolics(polys::Vector, symbol_map::Vector, gens::Vector, transcendence_subs::Dict)

Convert Nemo polynomial system back to Symbolics expressions that ODEPE expects.
"""
function convert_si_polys_to_symbolics(
    polys::Vector,
    symbol_map::Vector,
    gens::Vector,
    transcendence_subs::Dict
)
    @info "Converting SI.jl polynomials to Symbolics format"
    
    # Create mapping from Nemo generators to Symbolics variables
    nemo_to_sym = Dict(gens .=> symbol_map)
    
    symbolic_equations = []
    
    for poly in polys
        # Apply transcendence substitutions if provided
        if !isempty(transcendence_subs)
            poly = substitute(poly, transcendence_subs)
        end
        
        # Convert Nemo polynomial to Symbolics
        sym_eq = nemo_to_symbolics(poly, nemo_to_sym)
        push!(symbolic_equations, sym_eq)
    end
    
    @info "Converted $(length(symbolic_equations)) equations to Symbolics format"
    return symbolic_equations
end

"""
    nemo_to_symbolics(nemo_expr, var_map::Dict)

Convert a Nemo expression to a Symbolics expression.
"""
function nemo_to_symbolics(nemo_expr, var_map::Dict)
    # Handle constants
    if nemo_expr isa Number
        return nemo_expr
    end
    
    # Handle Nemo QQ field elements
    if nemo_expr isa Nemo.QQFieldElem
        return Rational(Nemo.numerator(nemo_expr), Nemo.denominator(nemo_expr))
    end
    
    # Handle fraction field elements
    if nemo_expr isa Nemo.Generic.FracFieldElem
        numer = nemo_to_symbolics(Nemo.numerator(nemo_expr), var_map)
        denom = nemo_to_symbolics(Nemo.denominator(nemo_expr), var_map)
        return numer / denom
    end
    
    # Handle polynomial variables directly
    if haskey(var_map, nemo_expr)
        return var_map[nemo_expr]
    end
    
    # For multivariate polynomials
    if nemo_expr isa Nemo.QQMPolyRingElem
        # Get the parent ring
        R = parent(nemo_expr)
        vars = Nemo.gens(R)
        
        # Build Symbolics expression by iterating over terms
        result = 0
        
        # Use the proper API: coefficients and exponent_vectors
        for (i, c) in enumerate(Nemo.coefficients(nemo_expr))
            if !iszero(c)
                # Convert coefficient
                coeff_val = if c isa Nemo.QQFieldElem
                    Rational(Nemo.numerator(c), Nemo.denominator(c))
                else
                    c
                end
                
                # Get exponent vector for this term
                exp_vec = Nemo.exponent_vector(nemo_expr, i)
                
                # Build monomial
                term_expr = coeff_val
                for (j, exp) in enumerate(exp_vec)
                    if exp > 0
                        var_sym = get(var_map, vars[j], vars[j])
                        term_expr *= var_sym^exp
                    end
                end
                
                result += term_expr
            end
        end
        
        return result
    end
    
    # For cases we can't handle directly, try converting to string and parsing
    # This is a fallback - not ideal but works
    @warn "Using string conversion fallback for type $(typeof(nemo_expr))"
    expr_str = string(nemo_expr)
    
    # Replace Nemo variable names with Symbolics variables
    for (nemo_var, sym_var) in var_map
        var_str = string(nemo_var)
        expr_str = replace(expr_str, var_str => string(sym_var))
    end
    
    # Parse and evaluate (this is risky but a last resort)
    try
        return eval(Meta.parse(expr_str))
    catch e
        @error "Failed to convert Nemo expression" nemo_expr e
        return nemo_expr
    end
end

# Export main functions
export get_si_equation_system, convert_to_si_ode