using Symbolics
using SymbolicUtils
using AbstractAlgebra
using RationalUnivariateRepresentation
import RS
import PolynomialRoots

# The parent module functions will be available when this file is included

"""
    safe_variable_name(var_str::String)

Convert a variable name to a safe alphanumeric string for AbstractAlgebra.
"""
function safe_variable_name(var_str::String)
    # Replace problematic characters with descriptive substitutes
    safe = replace(var_str,
        "(" => "_lp_",
        ")" => "_rp_",
        "ˍ" => "_d_",
        "," => "_c_",
        " " => "_",
        "." => "_p_",
        "[" => "_lb_",
        "]" => "_rb_"
    )
    # Remove any trailing underscores
    safe = rstrip(safe, '_')
    # Ensure it starts with a letter
    if !isletter(safe[1])
        safe = "v_" * safe
    end
    return safe
end

"""
    extract_all_variables(exprs::Vector)

Extract all unique variables from a collection of symbolic expressions.
"""
function extract_all_variables(exprs::Vector)
    all_vars = Set{Any}()
    for expr in exprs
        # Unwrap if it's a Num
        unwrapped = expr isa Symbolics.Num ? Symbolics.value(expr) : expr
        union!(all_vars, Symbolics.get_variables(unwrapped))
    end
    return collect(all_vars)
end

"""
    walk_expression(expr, R, var_map::Dict)

Recursively walk a symbolic expression and convert it to an AbstractAlgebra polynomial.
"""
function walk_expression(expr, R, var_map::Dict)
    # Unwrap Symbolics.Num if needed
    if expr isa Symbolics.Num
        expr = Symbolics.value(expr)
    end
    
    # Handle numbers
    if expr isa Number
        if expr isa Float64
            # Convert Float64 to exact rational
            return R(rationalize(expr))
        else
            return R(expr)
        end
    end
    
    # Handle variables and function-like variables
    # Check if this expression matches any of our known variables
    for (key, val) in var_map
        key_val = key isa Symbolics.Num ? Symbolics.value(key) : key
        if isequal(key_val, expr)
            return val
        end
    end
    
    # Special handling for function-like variables (e.g., x1(t))
    # These appear as operations but should be treated as variables
    if SymbolicUtils.istree(expr)
        # First check if this entire expression is a known variable
        # This handles cases like x1(t) which look like function calls but are actually variables
        for (key, val) in var_map
            key_val = key isa Symbolics.Num ? Symbolics.value(key) : key
            if isequal(key_val, expr)
                return val
            end
        end
        
        # If not found as a variable, check if it's a function with 't' argument
        op = SymbolicUtils.operation(expr)
        args = SymbolicUtils.arguments(expr)
        
        if length(args) == 1 && string(args[1]) == "t"
            # This looks like a state variable x1(t) but wasn't found in mapping
            error("State variable $expr not found in mapping")
        end
        
        # If it's not a state variable, continue to handle it as an operation below
    end
    
    # If not found and it's a symbol, it might be an untracked variable
    if SymbolicUtils.issym(expr)
        # Check if it's actually 't' or another special variable we should ignore
        if string(expr) == "t"
            # This is the time variable, we don't convert it
            error("Time variable 't' should not appear in polynomial expressions")
        end
        error("Variable $expr not found in mapping")
    end
    
    # Handle operations
    if SymbolicUtils.istree(expr)
        op = SymbolicUtils.operation(expr)
        args = SymbolicUtils.arguments(expr)
        
        # Recursively convert arguments
        converted_args = [walk_expression(arg, R, var_map) for arg in args]
        
        # Apply operation
        if op === (+)
            return sum(converted_args)
        elseif op === (-)
            if length(converted_args) == 1
                return -converted_args[1]
            else
                result = converted_args[1]
                for i in 2:length(converted_args)
                    result = result - converted_args[i]
                end
                return result
            end
        elseif op === (*)
            return prod(converted_args)
        elseif op === (/)
            if length(converted_args) != 2
                error("Division must have exactly 2 arguments")
            end
            numerator = converted_args[1]
            denominator = converted_args[2]
            # Check if denominator is a constant
            if isa(denominator, typeof(R(1))) && iszero(AbstractAlgebra.degree(denominator))
                # Get the constant value
                const_val = AbstractAlgebra.coeff(denominator, 0)
                if !iszero(const_val)
                    return numerator * inv(const_val)
                else
                    error("Division by zero")
                end
            else
                error("Non-constant division not supported for polynomials")
            end
        elseif op === (^)
            if length(args) != 2
                error("Power must have exactly 2 arguments")
            end
            base = converted_args[1]
            exponent = args[2]  # Use original argument for exponent
            if exponent isa Integer && exponent >= 0
                return base^exponent
            else
                error("Only non-negative integer exponents supported, got $exponent")
            end
        else
            error("Unsupported operation: $op")
        end
    end
    
    error("Cannot convert expression: $expr (type: $(typeof(expr)))")
end

"""
    robust_exprs_to_AA_polys(exprs::Vector, vars::Vector)

Convert Symbolics expressions to AbstractAlgebra polynomials using robust tree walking.
Returns the polynomial ring and the converted polynomials.
"""
function robust_exprs_to_AA_polys(exprs::Vector, vars::Vector)
    # Extract all variables if not provided
    if isempty(vars)
        vars = extract_all_variables(exprs)
    end
    
    # Create safe variable names
    var_name_map = Dict{Any, String}()
    safe_names = String[]
    used_names = Set{String}()
    
    for var in vars
        var_str = string(var)
        safe_name = safe_variable_name(var_str)
        
        # Handle name collisions
        original_safe = safe_name
        counter = 1
        while safe_name in used_names
            safe_name = original_safe * "_" * string(counter)
            counter += 1
        end
        
        var_name_map[var] = safe_name
        push!(safe_names, safe_name)
        push!(used_names, safe_name)
    end
    
    # Create polynomial ring
    R, ring_vars = AbstractAlgebra.polynomial_ring(AbstractAlgebra.QQ, safe_names)
    
    # Create mapping from symbolic variables to ring variables
    var_to_ring = Dict{Any, Any}()
    for (i, var) in enumerate(vars)
        var_to_ring[var] = ring_vars[i]
    end
    
    # Convert each expression
    aa_polys = []
    for expr in exprs
        try
            poly = walk_expression(expr, R, var_to_ring)
            push!(aa_polys, poly)
        catch e
            @warn "Failed to convert expression: $expr" exception=e
            # Try to provide a zero polynomial as fallback
            push!(aa_polys, R(0))
        end
    end
    
    return R, aa_polys, var_to_ring
end

"""
    solve_with_rs_new(poly_system, varlist; kwargs...)

New version of solve_with_rs that reuses the proven OLD conversion method.
This is a pragmatic solution that works with the existing infrastructure.
"""
function solve_with_rs_new(poly_system, varlist;
    start_point = nothing,
    options = Dict(),
    _recursion_depth = 0, 
    digits = 10,
    polish_solutions = true,  # Enable polynomial polishing by default
    debug = false)
    
    if _recursion_depth > 5
        @warn "solve_with_rs_new: Maximum recursion depth exceeded"
        return [], varlist, Dict(), varlist
    end
    
    try
        # Clear all denominators before converting to AA polynomials
        cleared_system = clear_all_denominators(poly_system, varlist)
        
        # Use the robust conversion method that handles special characters
        R, aa_system, var_map = robust_exprs_to_AA_polys(cleared_system, varlist)
        
        # Compute RUR and get separating element
        rur, sep = RationalUnivariateRepresentation.zdim_parameterization(
            aa_system, 
            get_separating_element = true
        )
        
        # Find solutions - try PolynomialRoots first to handle complex solutions
        solutions = []
        try
            
            # Extract the univariate polynomial from RUR
            univariate_poly = rur[1]
            
            # Convert coefficients to Complex{Float64} for PolynomialRoots
            coeffs = Complex{Float64}[]
            for coeff in univariate_poly
                push!(coeffs, Complex(Float64(coeff), 0.0))
            end
            
            # Find ALL roots (complex and real)
            all_roots = PolynomialRoots.roots(coeffs)
            
            # Reconstruct full solutions from univariate roots
            for root in all_roots
                # Skip roots with very large imaginary parts (likely spurious)
                if abs(imag(root)) > 1e6
                    continue
                end
                
                # Compute derivative of f1 at root for reconstruction
                f1 = univariate_poly
                f1_deriv = sum((i-1) * f1[i] * root^(i-2) for i in 2:length(f1))
                
                # Skip if derivative is too small (multiple root or numerical issue)
                if abs(f1_deriv) < 1e-14
                    continue
                end
                
                # Reconstruct solution for all variables
                solution = Float64[]
                
                # For each variable, use the corresponding polynomial in the RUR
                for (idx, var) in enumerate(varlist)
                    if idx + 1 <= length(rur)
                        poly = rur[idx + 1]
                        value = sum(poly[i] * root^(i-1) for i in 1:length(poly))
                        reconstructed = value / f1_deriv
                        
                        # Use real part if imaginary part is negligible
                        if abs(imag(reconstructed)) < 1e-10
                            push!(solution, real(reconstructed))
                        else
                            # For complex solutions, use the real part
                            push!(solution, real(reconstructed))
                        end
                    else
                        # If we don't have enough polynomials, use a default value
                        push!(solution, 0.0)
                    end
                end
                
                push!(solutions, solution)
            end
            
        catch poly_error
            @debug "PolynomialRoots failed, falling back to RS: $poly_error"
            
            # Fallback to RS.rs_isolate for real solutions only
            output_precision = get(options, :output_precision, Int32(20))
            sol = RS.rs_isolate(rur, sep, output_precision = output_precision)
            
            # Convert solutions back to our format
            for s in sol
                # Extract real solutions
                real_sol = [convert(Float64, real(v[1])) for v in s]
                push!(solutions, real_sol)
            end
        end
        
        # Polish solutions if requested (using polynomial system residual minimization)
        if polish_solutions && !isempty(solutions)
            polished_solutions = []
            for sol in solutions
                # Use the solution as starting point for polishing
                start_pt = Float64.(sol)  # Ensure Float64
                
                if debug
                    println("DEBUG [solve_with_rs_new]: Polishing solution: ", start_pt)
                end
                
                # Polish the solution using local optimization on polynomial system
                # This minimizes the polynomial residual, not ODE residual
                polished_sol, _, _, _ = solve_with_nlopt(poly_system, varlist,
                                                        start_point = start_pt,
                                                        polish_only = true,
                                                        options = Dict(:abstol => 1e-12, :reltol => 1e-12))
                
                # If polishing succeeded, use polished solution
                if !isempty(polished_sol)
                    push!(polished_solutions, polished_sol[1])
                    
                    if debug
                        println("DEBUG [solve_with_rs_new]: Polished solution: ", polished_sol[1])
                    end
                else
                    # Polishing failed, keep original solution
                    push!(polished_solutions, sol)
                    
                    if debug
                        println("DEBUG [solve_with_rs_new]: Polishing failed, keeping original solution")
                    end
                end
            end
            solutions = polished_solutions
        end
        
        return solutions, varlist, Dict(), varlist
        
    catch e
        if isa(e, DomainError) && occursin("zerodimensional ideal", string(e))
            @warn "System is not zero-dimensional, adding a random linear equation"
            # Add a random linear equation
            n = length(varlist)
            coeffs = rand(Float64, n)
            linear_eq = sum(coeffs[i] * varlist[i] for i in 1:n) - rand(Float64)
            modified_system = [poly_system; linear_eq]
            
            return solve_with_rs_new(
                modified_system, varlist,
                start_point = start_point,
                options = options,
                _recursion_depth = _recursion_depth + 1,
                digits = digits,
                polish_solutions = polish_solutions,
                debug = debug
            )
        else
            @warn "solve_with_rs_new failed: $e"
            return [], varlist, Dict(), varlist
        end
    end
end

# Export the new functions
export robust_exprs_to_AA_polys, solve_with_rs_new