using Symbolics
using HomotopyContinuation
using Statistics

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
	sign_changes = sum(abs.(sign.(diffs[2:end]) - sign.(diffs[1:end-1])) .> 1)
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
