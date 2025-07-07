"""
	unpack_ODE(model::ModelingToolkit.System)

Extract the core components of an ODESystem.

# Arguments
- `model::ModelingToolkit.System`: The ODE system to unpack

# Returns
- Tuple containing (independent variable, equations, state variables, parameters)
"""
function unpack_ODE(model::ModelingToolkit.System)
	return ModelingToolkit.get_iv(model), deepcopy(ModelingToolkit.equations(model)), ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model)
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

"""
	create_ordered_ode_system(name, states, parameters, equations, measured_quantities)

Create an OrderedODESystem with completed equations and ordered variables.

# Arguments
- `name`: Name for the system
- `states`: State variables
- `parameters`: System parameters
- `equations`: System equations
- `measured_quantities`: Equations for measured quantities

# Returns
- Tuple of (OrderedODESystem, measured_quantities)
"""
function create_ordered_ode_system(name, states, parameters, equations, measured_quantities)
	@named model = ModelingToolkit.System(equations, t, states, parameters)
	model = complete(model)
	ordered_system = OrderedODESystem(model, parameters, states)
	return ordered_system, measured_quantities
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