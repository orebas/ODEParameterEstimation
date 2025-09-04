"""
SI.jl Integration Module for ODEParameterEstimation

This module provides functions to use StructuralIdentifiability.jl 
for equation system construction instead of iterative scanning.
"""

using StructuralIdentifiability
using SIAN
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
        lhs_nemo = Symbolics.substitute(state_vars[i], input_symbols .=> gens_)
        if !(typeof(diff_eqs[i].rhs) <: Number)
            rhs_nemo = eval_at_nemo(diff_eqs[i].rhs, Dict(input_symbols .=> gens_))
        else
            rhs_nemo = R(diff_eqs[i].rhs)
        end
        state_eqn_dict[lhs_nemo] = rhs_nemo
    end
    
    # Convert output equations
    for i in 1:length(measured_quantities)
        lhs_nemo = Symbolics.substitute(y_functions[i], input_symbols .=> gens_)
        rhs_nemo = eval_at_nemo(measured_quantities[i].rhs, Dict(input_symbols .=> gens_))
        out_eqn_dict[lhs_nemo] = rhs_nemo
    end
    
    # Convert inputs
    inputs_ = [Symbolics.substitute(each, input_symbols .=> gens_) for each in inputs]
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
    
    # Get parameters for identifiability analysis using SIAN
    params_to_assess = SIAN.get_parameters(si_ode)
    
    # Create mapping from Nemo to MTK types
    nemo2mtk = Dict(gens .=> symbol_map)
    
    # Get polynomial system using SIAN
    @info "Getting polynomial system from SIAN"
    result = get_polynomial_system_from_sian(
        si_ode, 
        params_to_assess;
        p = p,
        infolevel = infolevel
    )
    
    # Extract the polynomial system and derivative info
    poly_system = result["polynomial_system"]
    y_derivative_dict = result["Y_eq"]
    
    # Also run identifiability check
    @info "Checking identifiability"
    id_result = StructuralIdentifiability.assess_identifiability(
        si_ode;
        funcs_to_check = params_to_assess,
        prob_threshold = p,
        loglevel = infolevel > 0 ? Logging.Info : Logging.Warn
    )
    
    # Extract non-identifiable parameters
    unidentifiable = Set()
    for (param, status) in id_result
        if status == :nonidentifiable
            # Need to map Nemo param back to MTK
            push!(unidentifiable, param)
        end
    end
    
    @info "SI.jl found $(length(poly_system)) template equations"
    @info "Derivative variables: $(keys(y_derivative_dict))"
    @info "Non-identifiable parameters: $unidentifiable"
    
    # Convert polynomial system to Symbolics format
    # These equations are pairs [variable, polynomial]
    template_equations = []
    for (var, poly) in poly_system
        # Convert both the variable and polynomial to Symbolics
        var_sym = nemo_to_symbolics(var, nemo2mtk)
        poly_sym = nemo_to_symbolics(poly, nemo2mtk)
        # Create equation: poly_sym = 0 (or var_sym - poly_sym = 0)
        push!(template_equations, var_sym - poly_sym)
    end
    
    return template_equations, y_derivative_dict, unidentifiable
end

"""
    get_polynomial_system_from_sian(si_ode, params_to_assess; p = 0.99, infolevel = 0)

Get polynomial system using SIAN functions, adapted from PE.jl's implementation.
Returns a simplified version focused on what we need.
"""
function get_polynomial_system_from_sian(si_ode, params_to_assess; p = 0.99, infolevel = 0)
    # Get equations using SIAN
    eqs, Q, x_eqs, y_eqs, x_vars, y_vars, u_vars, mu, all_indets, gens_Rjet = SIAN.get_equations(si_ode)
    
    non_jet_ring = si_ode.poly_ring
    n = length(x_vars)
    m = length(y_vars)
    u = length(u_vars)
    s = length(mu) + n
    
    # Get X and Y equations
    X, X_eq = SIAN.get_x_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)
    Y, Y_eq = SIAN.get_y_eq(x_eqs, y_eqs, n, m, s, u, gens_Rjet)
    
    # For now, return the Y equations as our polynomial system
    # These contain the derivatives we need
    y_derivative_dict = Dict()
    for each in Y_eq
        name, order = SIAN.get_order_var(each[1], non_jet_ring)
        y_derivative_dict[each[1]] = order
    end
    
    # Return simplified result
    return Dict(
        "polynomial_system" => Y_eq,  # The polynomial equations with derivatives
        "Y_eq" => y_derivative_dict,  # Maps derivative variables to orders
        "X_eq" => X_eq,
        "non_jet_ring" => non_jet_ring
    )
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
            poly = Symbolics.substitute(poly, transcendence_subs)
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
        # Convert Nemo.ZZRingElem to Julia integers
        num = BigInt(Nemo.numerator(nemo_expr))
        den = BigInt(Nemo.denominator(nemo_expr))
        return Rational(num, den)
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
                # Convert coefficient - handle different Nemo types
                coeff_val = if c isa Nemo.QQFieldElem
                    # Need to convert Nemo.ZZRingElem to Julia integers
                    num = BigInt(Nemo.numerator(c))
                    den = BigInt(Nemo.denominator(c))
                    Rational(num, den)
                elseif c isa Nemo.ZZRingElem
                    # Integer coefficient
                    BigInt(c)
                elseif c isa Integer
                    c
                else
                    # Try to convert to a number
                    try
                        BigInt(c)
                    catch
                        @error "Unknown coefficient type in nemo_to_symbolics" typeof(c) c
                        c
                    end
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