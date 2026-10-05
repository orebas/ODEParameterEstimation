# Adapted from SIAN-Julia 2f78ca8; see LICENSE and README.md in this directory.
"""
    compare_diff_var(dvl, dvr, non_jet_vars, shft, s)

# Arguments
Two jet variables and the original variable/ring layout.

# Returns
Whether the first jet precedes the second in SIAN ordering.
"""
function compare_diff_var(dvl, dvr, non_jet_vars, shft, s)
    vl, hl = get_order_var2(dvl, non_jet_vars, shft, s)
    vr, hr = get_order_var2(dvr, non_jet_vars, shft, s)
    if hl != hr
        return (hl > hr)
    end
    if length(string(vl)) != length(string(vr))
        return (length(string(vl)) > length(string(vr)))
    end
    return (vr >= vl)
end

"""
    jacobi_matrix(pol_arr, vrs, vals)

# Arguments
Polynomials, differentiation variables, and exact evaluation values.

# Returns
The evaluated Jacobian over the rational field.
"""
function jacobi_matrix(pol_arr, vrs, vals)
    m = Nemo.matrix_space(Nemo.QQ, length(pol_arr), length(vrs))()
    for i in 1:length(pol_arr)
        for j in 1:length(vrs)
            m[i, j] = evaluate(derivative(pol_arr[i], vrs[j]), vals)
        end
    end
    return (m)
end

"""
    get_order_var2(diff_var, non_jet_vars, shft, s)

# Arguments
A jet variable and its source ring layout.

# Returns
Its base variable and derivative order.
"""
function get_order_var2(diff_var, non_jet_vars, shft, s)
    idx = var_index(diff_var)
    if idx <= shft * (s + 3)
        return ([non_jet_vars[rem(idx - 1, shft)+1], div(idx - 1, shft)])
    else
        return ([non_jet_vars[idx-shft*(s+2)-1], 0])
    end
end

"""
    get_order_var(diff_var, non_jet_ring)

# Arguments
A derivative variable and the original polynomial ring.

# Returns
Its base variable and order, or empty labels when no suffix exists.
"""
function get_order_var(diff_var, non_jet_ring)
    rex = match(r"^(.*_)([0-9]+)$", string(diff_var))
    if rex === nothing
        return (["", ""])
    else
        return ([str_to_var(first(rex[1], length(rex[1]) - 1), non_jet_ring), parse(Int, rex[2])])
    end
end

"""
    get_vars(diff_poly, var_list, non_jet_vars, shft, s)

# Arguments
A jet polynomial, selected base variables, and ring layout.

# Returns
Jet variables whose base belongs to the selected list.
"""
function get_vars(diff_poly, var_list, non_jet_vars, shft, s)
    return [v for v in vars(diff_poly) if get_order_var2(v, non_jet_vars, shft, s)[1] in var_list]
end

"""
    make_derivative(var_name, der_order)

# Arguments
A base variable name and derivative order.

# Returns
The upstream-compatible derivative name.
"""
function make_derivative(var_name, der_order)
    return (string(var_name, "_", der_order))
end

"""
    add_to_var(vr, ring, r)

# Arguments
A base variable, target jet ring, and derivative order.

# Returns
The corresponding generator in the target ring.
"""
function add_to_var(vr, ring, r)
    return str_to_var(make_derivative(vr, r), ring)
end

"""
    create_jet_ring(var_list, param_list, max_ord)

# Arguments
Ordered state/output/input variables, parameters, and maximum order.

# Returns
A rational polynomial ring with the original jet and auxiliary ordering.
"""
function create_jet_ring(var_list, param_list, max_ord)
    varnames = vcat(vec(["$(s)_$i" for s in var_list, i in 0:max_ord]), "z_aux", ["$(s)_0" for s in param_list])
    return Nemo.polynomial_ring(Nemo.QQ, varnames)[1]
end

"""
    differentiate_all(diff_poly, var_list, shft, max_ord)

# Arguments
A polynomial, ordered jet variables, block size, and current order.

# Returns
The total time derivative using the next jet block.
"""
function differentiate_all(diff_poly, var_list, shft, max_ord)
    result = 0
    for i in 1:(shft*(max_ord+1))
        result = result + derivative(diff_poly, var_list[i]) * var_list[i+shft]
    end
    return (result)
end

"""
    str_to_var(s, ring)

# Arguments
A variable name and a polynomial ring.

# Returns
The matching generator; missing names raise KeyError.
"""
function str_to_var(s, ring::MPolyRing)
    ind = findfirst(v -> (string(v) == s), symbols(ring))
    if ind == nothing
        throw(Base.KeyError("Variable $s is not found in ring $ring"))
    end
    return gens(ring)[ind]
end

"""
    unpack_fraction(f)

# Arguments
A polynomial or rational function.

# Returns
Its numerator and denominator; polynomial denominators are one.
"""
function unpack_fraction(f::MPolyRingElem)
    return (f, one(parent(f)))
end

"""
    unpack_fraction(f)

# Arguments
A polynomial or rational function.

# Returns
Its numerator and denominator; polynomial denominators are one.
"""
function unpack_fraction(f::Generic.FracFieldElem{<:MPolyRingElem})
    return (numerator(f), denominator(f))
end

"""
    parent_ring_change(poly, new_ring)

# Arguments
A polynomial and target ring containing all variables used by it.

# Returns
The same polynomial with coefficients and generators in the target ring.
"""
function parent_ring_change(poly::MPolyRingElem, new_ring::MPolyRing)
    old_ring = parent(poly)
    # construct a mapping for the variable indices
    var_mapping = Union{Nothing,Int}[]

    for u in symbols(old_ring)
        push!(
            var_mapping,
            findfirst(v -> (string(u) == string(v)), symbols(new_ring))
        )
    end
    builder = MPolyBuildCtx(new_ring)
    for term in zip(exponent_vectors(poly), coefficients(poly))
        exp, coef = term
        new_exp = [0 for _ in gens(new_ring)]
        for i in 1:length(exp)
            if exp[i] != 0
                if var_mapping[i] == nothing
                    throw(Base.ArgumentError("The polynomial contains a variable not present in the new ring $poly"))
                else
                    new_exp[var_mapping[i]] = exp[i]
                end
            end
        end
        if typeof(coef) <: Nemo.QQFieldElem
            push_term!(builder, base_ring(new_ring)(coef), new_exp)
        else
            push_term!(builder, base_ring(new_ring)(Nemo.data(coef)), new_exp)
        end
    end
    return finish(builder)
end

"""
    insert_zeros_to_vals(var_arr, val_arr)

# Arguments
Aligned lists of ring variables and exact values.

# Returns
A dense value vector in ring order, with zero for unspecified variables.
"""
function insert_zeros_to_vals(var_arr, val_arr)
    all_val_arr = zeros(QQFieldElem, length(gens(parent(var_arr[1]))))
    for i in 1:length(var_arr)
        all_val_arr[var_index(var_arr[i])] = val_arr[i]
    end
    return all_val_arr
end

"""
    add_zero_to_vars(poly, new_ring)

# Arguments
A polynomial and a jet ring containing its order-zero variables.

# Returns
The polynomial mapped to order-zero jet generators.
"""
function add_zero_to_vars(poly::MPolyRingElem, new_ring::MPolyRing)
    old_ring = parent(poly)
    # construct a mapping for the variable indices
    var_mapping = Union{Nothing,Int}[]
    for u in symbols(old_ring)
        push!(
            var_mapping,
            findfirst(v -> (string(u, "_0") == string(v)), symbols(new_ring))
        )
    end
    builder = MPolyBuildCtx(new_ring)
    for term in zip(exponent_vectors(poly), coefficients(poly))
        exp, coef = term
        new_exp = [0 for _ in gens(new_ring)]
        for i in 1:length(exp)
            if exp[i] != 0
                if var_mapping[i] == nothing
                    throw(Base.ArgumentError("The polynomial contains a variable not present in the new ring $poly"))
                else
                    new_exp[var_mapping[i]] = exp[i]
                end
            end
        end
        push_term!(builder, base_ring(new_ring)(coef), new_exp)
    end
    return finish(builder)
end
