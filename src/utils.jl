function unpack_ODE(model::ODESystem)
	return ModelingToolkit.get_iv(model), deepcopy(ModelingToolkit.equations(model)), ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model)
end

#unident_dict is a dict of globally unidentifiable variables, and the substitution for them
#deriv_level is a dict of 
#(indices into measured_quantites =>   level of derivative to include)


#clear denominators on both sides of an equation of rational expressions
function clear_denoms(eq)
	@variables _qz_discard1 _qz_discard2
	expr_fake = Symbolics.value(simplify_fractions(_qz_discard1 / _qz_discard2)) #this is a gross way to get the operator for division.
	op = Symbolics.operation(expr_fake)

	ret = eq
	if (!isequal(eq.rhs, 0))
		expr = eq.rhs
		lexpr = eq.lhs
		expr2 = Symbolics.value(simplify_fractions(expr))
		if (istree(expr2) && Symbolics.operation(expr2) == op)
			numer, denom = Symbolics.arguments(expr2)
			ret = lexpr * denom ~ numer
		end
	end
	return ret
end

#this substitutes parameters that have been tagged as unidentifiable, by their presence in unident_dict.
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

Convert a symbol to a HomotopyContinuation ModelKit Variable.

# Arguments
- `x`: Symbol to convert

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
	tag_symbol(thesymb, pre_tag, post_tag)

Add tags to a symbol.

# Arguments
- `thesymb`: Symbol to tag
- `pre_tag`: Tag to add before the symbol
- `post_tag`: Tag to add after the symbol

# Returns
- New tagged symbol
"""
function tag_symbol(thesymb, pre_tag, post_tag)
	newvarname = Symbol(pre_tag * replace(string(thesymb), "(t)" => "_t") * post_tag)
	return (@variables $newvarname)[1]
end
