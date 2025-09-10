
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

	is_equation = hasproperty(eq, :lhs)

	local lhs_expr, rhs_expr
	if is_equation
		lhs_expr = eq.lhs
		rhs_expr = eq.rhs
	else
		# It's an expression, treat as expr ~ 0
		lhs_expr = eq
		rhs_expr = 0
	end

	# Simplify both sides
	simplified_lhs = Symbolics.value(simplify_fractions(lhs_expr))
	simplified_rhs = Symbolics.value(simplify_fractions(rhs_expr))

	# Check if LHS is a fraction
	if (iscall(simplified_lhs) && Symbolics.operation(simplified_lhs) == division_op)
		lhs_num, lhs_denom = Symbolics.arguments(simplified_lhs)
		# Clear denominator by multiplying both sides
		new_lhs = lhs_num
		new_rhs = rhs_expr * lhs_denom
		return is_equation ? (new_lhs ~ new_rhs) : (new_lhs - new_rhs)
	end

	# Check if RHS is a fraction (original behavior)
	if (!isequal(rhs_expr, 0) && iscall(simplified_rhs) && Symbolics.operation(simplified_rhs) == division_op)
		rhs_num, rhs_denom = Symbolics.arguments(simplified_rhs)
		new_lhs = lhs_expr * rhs_denom
		new_rhs = rhs_num
		return is_equation ? (new_lhs ~ new_rhs) : (new_lhs - new_rhs)
	end

	return eq
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

"""
	count_turns(values)

Calculate the number of "turns" in a time series using sign changes in divided differences.

# Arguments
- `values`: Vector of numerical values

# Returns
- Number of turns (sign changes) in the series
"""
function count_turns(values)
	if length(values) < 3
		return 0
	end
	diffs = diff(values)
	# Count sign changes in consecutive differences
	signs = sign.(diffs)
	sign_changes = 0
	for i in 1:(length(signs)-1)
		if signs[i] != 0 && signs[i+1] != 0 && signs[i] != signs[i+1]
			sign_changes += 1
		end
	end
	return sign_changes
end

"""
	calculate_timeseries_stats(values)

Calculate basic statistics for a time series.

# Arguments
- `values`: Vector of numerical values

# Returns
- Named tuple containing mean, std, min, max, range, and number of turns
"""
function calculate_timeseries_stats(values)
	return (
		mean = mean(values),
		std = std(values),
		min = minimum(values),
		max = maximum(values),
		range = maximum(values) - minimum(values),
		turns = count_turns(values),
	)
end


"""
	calculate_error_stats(predicted, actual)

Calculate error statistics between predicted and actual values.

# Arguments
- `predicted`: Vector of predicted values
- `actual`: Vector of actual values

# Returns
- Named tuple containing absolute and relative error statistics
"""
function calculate_error_stats(predicted, actual)
	abs_error = abs.(predicted - actual)
	rel_error = abs_error ./ (abs.(actual) .+ 1e-10)  # Add small constant to avoid division by zero

	return (
		absolute = calculate_timeseries_stats(abs_error),
		relative = calculate_timeseries_stats(rel_error),
	)
end


