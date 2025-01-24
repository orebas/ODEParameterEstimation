"""
	unpack_ODE(model::ODESystem)

Extract the core components of an ODESystem.

# Arguments
- `model::ODESystem`: The ODE system to unpack

# Returns
- Tuple containing (independent variable, equations, state variables, parameters)
"""
function unpack_ODE(model::ODESystem)
	return ModelingToolkit.get_iv(model), deepcopy(ModelingToolkit.equations(model)), ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model)
end

"""
	clear_denoms(eq)

Clear denominators from both sides of an equation containing rational expressions.
For example, converts x/y = z to x = y*z.

# Arguments
- `eq`: Equation to process

# Returns
- Modified equation with cleared denominators
"""
function clear_denoms(eq)
	@variables _temp_num _temp_denom
	division_expr = Symbolics.value(simplify_fractions(_temp_num / _temp_denom))
	division_op = Symbolics.operation(division_expr)

	result = eq
	if (!isequal(eq.rhs, 0))
		rhs_expr = eq.rhs
		lhs_expr = eq.lhs
		simplified_rhs = Symbolics.value(simplify_fractions(rhs_expr))
		
		# Check if RHS is a fraction
		if (istree(simplified_rhs) && Symbolics.operation(simplified_rhs) == division_op)
			numerator, denominator = Symbolics.arguments(simplified_rhs)
			result = lhs_expr * denominator ~ numerator
		end
	end
	return result
end

"""
	unident_subst!(model_eq, measured_quantities, unident_dict)

Substitute values for unidentifiable parameters in model equations and measured quantities.
Modifies the input equations in place.

# Arguments
- `model_eq`: Model equations to modify
- `measured_quantities`: Measured quantities to modify
- `unident_dict`: Dictionary mapping unidentifiable parameters to their values
"""
function unident_subst!(model_eq, measured_quantities, unident_dict)
	for i in eachindex(model_eq)
		 model_eq[i] = substitute(model_eq[i].lhs, unident_dict) ~ substitute(model_eq[i].rhs, unident_dict)
	end
	for i in eachindex(measured_quantities)
		measured_quantities[i] = substitute(measured_quantities[i].lhs, unident_dict) ~ substitute(measured_quantities[i].rhs, unident_dict)
	end
end

"""
	hmcs(x)

Convert a string to a HomotopyContinuation ModelKit Variable.
Helper function used when converting symbolic expressions to HC format.

# Arguments
- `x`: String to convert

# Returns
- HomotopyContinuation ModelKit Variable
"""
function hmcs(x)
	return HomotopyContinuation.ModelKit.Variable(Symbol(x))
end

function print_element_types(v)
	for elem in v
		println(typeof(elem))
	end
end

"""
	tag_symbol(symbol, prefix, suffix)

Add prefix and suffix tags to a symbol, handling special cases like time-dependent variables.
For example: tag_symbol(x(t), "pre_", "_post") -> pre_x_t_post

# Arguments
- `symbol`: Symbol to modify
- `prefix`: String to add before the symbol
- `suffix`: String to add after the symbol

# Returns
- New tagged symbolic variable
"""
function tag_symbol(symbol, prefix, suffix)
	new_name = Symbol(prefix * replace(string(symbol), "(t)" => "_t") * suffix)
	return (@variables $new_name)[1]
end
