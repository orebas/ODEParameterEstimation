# Transcendental Function Handling for ODEParameterEstimation
#
# This module provides automatic detection and handling of transcendental functions
# (sin, cos, exp) in ODE equations. These functions cannot be processed by SIAN/SI.jl
# which require polynomial systems. The approach is:
#
# 1. DETECT: Find sin(c*t), cos(c*t) etc. in equations where c is a known constant
# 2. REPLACE: Substitute with input variables (_trfn_1(t), _trfn_2(t), ...)
# 3. ANALYZE: SIAN sees a polynomial system with known inputs → correct identifiability
# 4. EVALUATE: At solve time, compute input values and derivatives numerically

"""
	TranscendentalEntry

Represents a single detected transcendental subexpression (e.g., sin(5.0*t)).

# Fields
- `original_expr::Num`: The original transcendental expression (e.g., sin(5.0*t))
- `input_variable::Num`: The replacement input variable (e.g., _trfn_1(t))
- `func_type::Symbol`: :sin, :cos, or :exp
- `frequency::Float64`: The constant coefficient of t (e.g., 5.0 for sin(5.0*t))
- `derivative_exprs::Vector{Num}`: Pre-computed symbolic derivatives d^n/dt^n of the original
"""
struct TranscendentalEntry
	original_expr::Num
	input_variable::Num
	func_type::Symbol
	frequency::Float64
	derivative_exprs::Vector{Num}
end

"""
	TranscendentalInfo

Stores all information about transcendental functions detected in an ODE system.

# Fields
- `entries::Vector{TranscendentalEntry}`: All detected transcendental subexpressions
- `substitution_dict::Dict{Num, Num}`: Maps original expr → input variable
- `reverse_dict::Dict{Num, Num}`: Maps input variable → original expr
- `input_variables::Vector{Num}`: All input variables created
- `max_derivative_order::Int`: Maximum derivative order pre-computed
"""
struct TranscendentalInfo
	entries::Vector{TranscendentalEntry}
	substitution_dict::Dict{Any, Any}
	reverse_dict::Dict{Any, Any}
	input_variables::Vector{Num}
	max_derivative_order::Int
end

"""
	_is_constant_times_t(expr, t_var)

Check if an expression is of the form `constant * t` where t is the independent variable.
Returns the constant if true, nothing otherwise.
"""
function _is_constant_times_t(expr, t_var)
	# Handle the case where expr IS t (constant = 1)
	if isequal(expr, t_var)
		return 1.0
	end

	# Try to extract constant * t pattern
	try
		val = Symbolics.value(expr)

		# Check if it's a multiplication
		if Symbolics.iscall(val)
			op = Symbolics.operation(val)
			args = Symbolics.arguments(val)

			if op === (*)
				# Look for constant * t pattern
				t_found = false
				constant_parts = Float64[]

				for arg in args
					if isequal(Num(arg), t_var) || isequal(arg, Symbolics.value(t_var))
						t_found = true
					else
						# Check if this is a numeric constant
						num_val = nothing
						try
							num_val = Float64(Symbolics.value(Num(arg)))
						catch
							try
								num_val = Float64(arg)
							catch
								return nothing  # Not a constant
							end
						end
						if !isnothing(num_val)
							push!(constant_parts, num_val)
						else
							return nothing  # Non-constant factor
						end
					end
				end

				if t_found && !isempty(constant_parts)
					return prod(constant_parts)
				elseif t_found
					return 1.0
				end
			end
		end
	catch
		# Expression is not decomposable
	end

	return nothing
end

"""
	_find_transcendentals_in_expr(expr, t_var, found_set)

Recursively walk an expression tree to find transcendental subexpressions
of the form sin(c*t), cos(c*t), exp(c*t) where c is a known constant.

Modifies `found_set` in place, adding tuples of (func_type, frequency, original_expr).
"""
function _find_transcendentals_in_expr(expr, t_var, found_set)
	val = Symbolics.value(expr isa Num ? expr : Num(expr))

	if !Symbolics.iscall(val)
		return
	end

	op = Symbolics.operation(val)
	args = Symbolics.arguments(val)

	# Check if this is sin, cos, or exp with a constant*t argument
	if op === sin || op === cos || op === exp
		if length(args) == 1
			arg_expr = Num(args[1])
			c = _is_constant_times_t(arg_expr, t_var)
			if !isnothing(c)
				func_type = op === sin ? :sin : (op === cos ? :cos : :exp)
				push!(found_set, (func_type, c, Num(val)))
				return  # Don't recurse into the argument
			end
		end
	end

	# Recurse into arguments
	for arg in args
		_find_transcendentals_in_expr(arg, t_var, found_set)
	end
end

"""
	detect_transcendentals(equations, measured_quantities, t_var; max_derivative_order=10)

Detect all transcendental subexpressions in the ODE equations and measured quantities.

# Arguments
- `equations`: Vector of ODE equations (ModelingToolkit Equations)
- `measured_quantities`: Vector of measurement equations
- `t_var`: The independent variable (time)
- `max_derivative_order`: Maximum derivative order to pre-compute (default: 10)

# Returns
- `TranscendentalInfo` if transcendentals are found, `nothing` otherwise
"""
function detect_transcendentals(equations, measured_quantities, t_var; max_derivative_order = 10)
	found_set = Set{Tuple{Symbol, Float64, Num}}()

	# Search in equation RHS
	for eq in equations
		_find_transcendentals_in_expr(eq.rhs, t_var, found_set)
	end

	# Search in measured quantity RHS
	for mq in measured_quantities
		_find_transcendentals_in_expr(mq.rhs, t_var, found_set)
	end

	if isempty(found_set)
		return nothing
	end

	# Sort for deterministic ordering
	found_list = sort(collect(found_set), by = x -> (x[1], x[2]))

	# Create entries
	entries = TranscendentalEntry[]
	substitution_dict = Dict{Any, Any}()
	reverse_dict = Dict{Any, Any}()
	input_variables = Num[]

	for (idx, (func_type, freq, original_expr)) in enumerate(found_list)
		# Create input variable name
		# Use a name that encodes the function and frequency for readability
		freq_str = replace(string(freq), "." => "_", "-" => "m")
		var_name = Symbol("_trfn_$(func_type)_$(freq_str)")
		input_var = (@variables $var_name(t_var))[1]

		# Pre-compute derivatives symbolically
		# sin(c*t): d/dt = c*cos(c*t), d²/dt² = -c²*sin(c*t), etc.
		# cos(c*t): d/dt = -c*sin(c*t), d²/dt² = -c²*cos(c*t), etc.
		# exp(c*t): d/dt = c*exp(c*t), d²/dt² = c²*exp(c*t), etc.
		D_t = Differential(t_var)
		derivative_exprs = Num[original_expr]  # 0th derivative is the function itself

		current = original_expr
		for _ in 1:max_derivative_order
			d = expand_derivatives(D_t(current))
			push!(derivative_exprs, d)
			current = d
		end

		entry = TranscendentalEntry(original_expr, input_var, func_type, freq, derivative_exprs)
		push!(entries, entry)

		# Build substitution dictionaries
		substitution_dict[original_expr] = input_var
		reverse_dict[input_var] = original_expr

		push!(input_variables, input_var)
	end

	return TranscendentalInfo(entries, substitution_dict, reverse_dict, input_variables, max_derivative_order)
end

"""
	transform_equations_for_si(equations, measured_quantities, tr_info)

Replace transcendental subexpressions in equations and measured quantities
with input variables for SIAN/SI.jl analysis.

# Arguments
- `equations`: Vector of ODE equations
- `measured_quantities`: Vector of measurement equations
- `tr_info::TranscendentalInfo`: Transcendental detection info

# Returns
- `(new_equations, new_measured_quantities)`: Transformed equation vectors
"""
function transform_equations_for_si(equations, measured_quantities, tr_info::TranscendentalInfo)
	# Build substitution dict for Symbolics.substitute
	sub_dict = Dict{Any, Any}()
	for entry in tr_info.entries
		sub_dict[entry.original_expr] = entry.input_variable
	end

	# Transform equations
	new_equations = map(equations) do eq
		new_rhs = Symbolics.substitute(eq.rhs, sub_dict)
		eq.lhs ~ new_rhs
	end

	# Transform measured quantities
	new_measured = map(measured_quantities) do mq
		new_rhs = Symbolics.substitute(mq.rhs, sub_dict)
		mq.lhs ~ new_rhs
	end

	return new_equations, new_measured
end

"""
	create_transformed_model(model::OrderedODESystem, measured_quantities, tr_info, t_var)

Create a new OrderedODESystem with transcendental functions replaced by input variables.
The input variables are added as states with oscillator ODEs to make the system
compatible with the existing pipeline.

# Arguments
- `model::OrderedODESystem`: Original model
- `measured_quantities`: Original measured quantities
- `tr_info::TranscendentalInfo`: Transcendental detection info
- `t_var`: Independent variable

# Returns
- `(new_model, new_measured_quantities, new_states, new_params, new_ic)`: Transformed model and metadata
"""
function create_transformed_model(model::OrderedODESystem, measured_quantities, tr_info::TranscendentalInfo, t_var)
	t_equations = ModelingToolkit.equations(model.system)
	states = ModelingToolkit.unknowns(model.system)
	params = ModelingToolkit.parameters(model.system)
	D_t = Differential(t_var)

	# Build substitution dict
	sub_dict = Dict{Any, Any}()
	for entry in tr_info.entries
		sub_dict[entry.original_expr] = entry.input_variable
	end

	# Transform existing equation RHS
	new_equations = map(t_equations) do eq
		new_rhs = Symbolics.substitute(eq.rhs, sub_dict)
		eq.lhs ~ new_rhs
	end

	# Add oscillator ODEs for input variables
	# For each unique frequency, we need both sin and cos
	# Group entries by frequency to create coupled oscillator pairs
	freq_groups = Dict{Float64, Vector{TranscendentalEntry}}()
	for entry in tr_info.entries
		freq = entry.frequency
		if !haskey(freq_groups, freq)
			freq_groups[freq] = TranscendentalEntry[]
		end
		push!(freq_groups[freq], entry)
	end

	additional_equations = []
	additional_states = Num[]
	additional_observables = []
	additional_ic = Dict{Num, Float64}()

	for (freq, entries_at_freq) in freq_groups
		# Find sin and cos entries for this frequency
		sin_entry = nothing
		cos_entry = nothing
		for entry in entries_at_freq
			if entry.func_type == :sin
				sin_entry = entry
			elseif entry.func_type == :cos
				cos_entry = entry
			end
		end

		if !isnothing(sin_entry) && isnothing(cos_entry)
			# We have sin but not cos - need to create cos partner
			freq_str = replace(string(freq), "." => "_", "-" => "m")
			var_name = Symbol("_trfn_cos_$(freq_str)")
			cos_var = (@variables $var_name(t_var))[1]

			# Oscillator: d(sin)/dt = freq * cos, d(cos)/dt = -freq * sin
			push!(additional_equations, D_t(sin_entry.input_variable) ~ freq * cos_var)
			push!(additional_equations, D_t(cos_var) ~ -freq * sin_entry.input_variable)
			push!(additional_states, sin_entry.input_variable)
			push!(additional_states, cos_var)

			# Add observables for the oscillator states
			obs_sin_name = Symbol("_obs$(var_name)_sin")
			obs_cos_name = Symbol("_obs$(var_name)_cos")
			obs_sin = (@variables $obs_sin_name(t_var))[1]
			obs_cos = (@variables $obs_cos_name(t_var))[1]
			push!(additional_observables, obs_sin ~ sin_entry.input_variable)
			push!(additional_observables, obs_cos ~ cos_var)

			# Initial conditions: sin(0) = 0, cos(0) = 1
			additional_ic[sin_entry.input_variable] = 0.0
			additional_ic[cos_var] = 1.0

		elseif isnothing(sin_entry) && !isnothing(cos_entry)
			# We have cos but not sin - need to create sin partner
			freq_str = replace(string(freq), "." => "_", "-" => "m")
			var_name = Symbol("_trfn_sin_$(freq_str)")
			sin_var = (@variables $var_name(t_var))[1]

			push!(additional_equations, D_t(sin_var) ~ freq * cos_entry.input_variable)
			push!(additional_equations, D_t(cos_entry.input_variable) ~ -freq * sin_var)
			push!(additional_states, sin_var)
			push!(additional_states, cos_entry.input_variable)

			obs_sin_name = Symbol("_obs$(var_name)_sin")
			obs_cos_name = Symbol("_obs$(var_name)_cos")
			obs_sin = (@variables $obs_sin_name(t_var))[1]
			obs_cos = (@variables $obs_cos_name(t_var))[1]
			push!(additional_observables, obs_sin ~ sin_var)
			push!(additional_observables, obs_cos ~ cos_entry.input_variable)

			additional_ic[sin_var] = 0.0
			additional_ic[cos_entry.input_variable] = 1.0

		elseif !isnothing(sin_entry) && !isnothing(cos_entry)
			# We have both sin and cos for this frequency
			push!(additional_equations, D_t(sin_entry.input_variable) ~ freq * cos_entry.input_variable)
			push!(additional_equations, D_t(cos_entry.input_variable) ~ -freq * sin_entry.input_variable)
			push!(additional_states, sin_entry.input_variable)
			push!(additional_states, cos_entry.input_variable)

			obs_sin_name = Symbol("_obs_trfn_$(replace(string(freq), "." => "_"))_sin")
			obs_cos_name = Symbol("_obs_trfn_$(replace(string(freq), "." => "_"))_cos")
			obs_sin = (@variables $obs_sin_name(t_var))[1]
			obs_cos = (@variables $obs_cos_name(t_var))[1]
			push!(additional_observables, obs_sin ~ sin_entry.input_variable)
			push!(additional_observables, obs_cos ~ cos_entry.input_variable)

			additional_ic[sin_entry.input_variable] = 0.0
			additional_ic[cos_entry.input_variable] = 1.0
		end

		# Handle exp entries
		for entry in entries_at_freq
			if entry.func_type == :exp
				# exp(c*t): d(exp)/dt = c * exp
				push!(additional_equations, D_t(entry.input_variable) ~ freq * entry.input_variable)
				push!(additional_states, entry.input_variable)

				obs_name = Symbol("_obs_trfn_exp_$(replace(string(freq), "." => "_"))")
				obs_var = (@variables $obs_name(t_var))[1]
				push!(additional_observables, obs_var ~ entry.input_variable)

				additional_ic[entry.input_variable] = 1.0  # exp(0) = 1
			end
		end
	end

	# Combine everything - ensure proper Equation typing
	all_equations_raw = vcat(new_equations, additional_equations)
	all_equations = ModelingToolkit.Equation[eq for eq in all_equations_raw]
	all_states_vec = Num[s for s in vcat(collect(states), additional_states)]
	all_params_vec = Num[p for p in collect(params)]

	# Transform measured quantities
	new_measured = map(measured_quantities) do mq
		new_rhs = Symbolics.substitute(mq.rhs, sub_dict)
		mq.lhs ~ new_rhs
	end
	all_measured_raw = vcat(new_measured, additional_observables)
	all_measured = ModelingToolkit.Equation[eq for eq in all_measured_raw]

	# Create the new MTK system using create_ordered_ode_system for consistency
	new_system_name = string(ModelingToolkit.nameof(model.system)) * "_polynomialized"
	new_model, all_measured_eqs = create_ordered_ode_system(
		new_system_name, all_states_vec, all_params_vec, all_equations, all_measured,
	)

	return new_model, all_measured_eqs, all_states_vec, all_params_vec, additional_ic
end

"""
	evaluate_input_at_time(tr_info::TranscendentalInfo, t_value::Float64, max_order::Int)

Evaluate all transcendental input variables and their derivatives at a given time point.

# Arguments
- `tr_info::TranscendentalInfo`: Transcendental detection info
- `t_value::Float64`: Time point to evaluate at
- `max_order::Int`: Maximum derivative order to compute

# Returns
- `Dict{Any, Float64}`: Maps input variables (and their derivatives) to numerical values
"""
function evaluate_input_at_time(tr_info::TranscendentalInfo, t_value::Float64, max_order::Int)
	values = Dict{Any, Float64}()

	for entry in tr_info.entries
		# Evaluate the original function and its derivatives at t_value
		c = entry.frequency
		for order in 0:min(max_order, length(entry.derivative_exprs) - 1)
			# Compute the value numerically
			if entry.func_type == :sin
				# d^n/dt^n sin(c*t) follows the pattern:
				# n=0: sin(ct), n=1: c*cos(ct), n=2: -c²*sin(ct), n=3: -c³*cos(ct), ...
				val = _eval_sin_derivative(c, t_value, order)
			elseif entry.func_type == :cos
				val = _eval_cos_derivative(c, t_value, order)
			elseif entry.func_type == :exp
				val = _eval_exp_derivative(c, t_value, order)
			else
				error("Unknown transcendental function type: $(entry.func_type)")
			end

			# Store with a key that matches what SIAN/SI will produce
			# The 0th derivative is keyed by the input variable itself
			if order == 0
				values[entry.input_variable] = val
			end
			# Higher derivatives will be handled by the DD structure
		end
	end

	return values
end

"""
	_eval_sin_derivative(c, t, n)

Evaluate the n-th derivative of sin(c*t) at time t.
Pattern: sin, c*cos, -c²*sin, -c³*cos, c⁴*sin, ...
"""
function _eval_sin_derivative(c::Float64, t::Float64, n::Int)
	phase = n % 4
	magnitude = c^n
	ct = c * t
	if phase == 0
		return magnitude * sin(ct)
	elseif phase == 1
		return magnitude * cos(ct)
	elseif phase == 2
		return -magnitude * sin(ct)
	else  # phase == 3
		return -magnitude * cos(ct)
	end
end

"""
	_eval_cos_derivative(c, t, n)

Evaluate the n-th derivative of cos(c*t) at time t.
Pattern: cos, -c*sin, -c²*cos, c³*sin, c⁴*cos, ...
"""
function _eval_cos_derivative(c::Float64, t::Float64, n::Int)
	phase = n % 4
	magnitude = c^n
	ct = c * t
	if phase == 0
		return magnitude * cos(ct)
	elseif phase == 1
		return -magnitude * sin(ct)
	elseif phase == 2
		return -magnitude * cos(ct)
	else  # phase == 3
		return magnitude * sin(ct)
	end
end

"""
	_eval_exp_derivative(c, t, n)

Evaluate the n-th derivative of exp(c*t) at time t.
All derivatives are c^n * exp(c*t).
"""
function _eval_exp_derivative(c::Float64, t::Float64, n::Int)
	return c^n * exp(c * t)
end

"""
	generate_input_data(tr_info::TranscendentalInfo, t_vector::Vector{Float64})

Generate synthetic data for the input variables (oscillator states) at all time points.
This data is used alongside the original ODE solution data.

# Arguments
- `tr_info::TranscendentalInfo`: Transcendental detection info
- `t_vector::Vector{Float64}`: Time points

# Returns
- `Dict{Num, Vector{Float64}}`: Maps each input variable to its time series values
"""
function generate_input_data(tr_info::TranscendentalInfo, t_vector::Vector{Float64})
	data = Dict{Num, Vector{Float64}}()

	for entry in tr_info.entries
		vals = Float64[]
		for t_val in t_vector
			if entry.func_type == :sin
				push!(vals, sin(entry.frequency * t_val))
			elseif entry.func_type == :cos
				push!(vals, cos(entry.frequency * t_val))
			elseif entry.func_type == :exp
				push!(vals, exp(entry.frequency * t_val))
			end
		end
		data[entry.input_variable] = vals
	end

	# Also generate data for partner variables (sin needs cos partner, etc.)
	# Group by frequency
	freq_groups = Dict{Float64, Vector{TranscendentalEntry}}()
	for entry in tr_info.entries
		if !haskey(freq_groups, entry.frequency)
			freq_groups[entry.frequency] = TranscendentalEntry[]
		end
		push!(freq_groups[entry.frequency], entry)
	end

	for (freq, entries_at_freq) in freq_groups
		has_sin = any(e -> e.func_type == :sin, entries_at_freq)
		has_cos = any(e -> e.func_type == :cos, entries_at_freq)

		if has_sin && !has_cos
			# Need cos partner data
			freq_str = replace(string(freq), "." => "_", "-" => "m")
			var_name = Symbol("_trfn_cos_$(freq_str)")
			cos_var = (@variables $var_name(ModelingToolkit.t_nounits))[1]
			data[cos_var] = [cos(freq * t_val) for t_val in t_vector]
		elseif has_cos && !has_sin
			# Need sin partner data
			freq_str = replace(string(freq), "." => "_", "-" => "m")
			var_name = Symbol("_trfn_sin_$(freq_str)")
			sin_var = (@variables $var_name(ModelingToolkit.t_nounits))[1]
			data[sin_var] = [sin(freq * t_val) for t_val in t_vector]
		end
	end

	return data
end

"""
	transform_pep_for_estimation(pep::ParameterEstimationProblem, t_var)

Transform a ParameterEstimationProblem that contains transcendental functions
into an equivalent polynomial problem. This is the main entry point for
transcendental handling.

# Arguments
- `pep::ParameterEstimationProblem`: Original problem (may contain sin/cos/exp)
- `t_var`: Independent variable

# Returns
- `(new_pep, tr_info)`: Transformed problem and transcendental info, or `(pep, nothing)` if no transformation needed
"""
function transform_pep_for_estimation(pep::ParameterEstimationProblem, t_var)
	# Detect transcendentals in the equations
	t_equations = ModelingToolkit.equations(pep.model.system)
	tr_info = detect_transcendentals(t_equations, pep.measured_quantities, t_var)

	if isnothing(tr_info)
		return pep, nothing
	end

	@info "[TRANSCENDENTAL] Detected $(length(tr_info.entries)) transcendental expression(s):"
	for entry in tr_info.entries
		@info "  $(entry.func_type)($(entry.frequency) * t) → $(entry.input_variable)"
	end

	# Create transformed model
	new_model, new_measured, new_states, new_params, additional_ic = create_transformed_model(
		pep.model, pep.measured_quantities, tr_info, t_var,
	)

	# Build new initial conditions
	new_ic = OrderedDict{Num, Float64}()
	# Copy original ICs
	for (k, v) in pep.ic
		new_ic[k] = v
	end
	# Add oscillator ICs
	for (k, v) in additional_ic
		new_ic[k] = v
	end

	# Build new parameter dict (same as original)
	new_p_true = OrderedDict{Num, Float64}()
	for (k, v) in pep.p_true
		new_p_true[k] = v
	end

	# If data_sample exists, augment it with input variable data
	new_data_sample = pep.data_sample
	if !isnothing(pep.data_sample)
		new_data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
		for (k, v) in pep.data_sample
			new_data_sample[k] = v
		end

		# Generate input data
		t_vector = pep.data_sample["t"]
		input_data = generate_input_data(tr_info, t_vector)

		# Add to data sample keyed by the observable RHS (matching the new measured quantities)
		# Wrap keys as Num to match the OrderedDict type constraint
		for mq in new_measured
			rhs = Num(mq.rhs)
			for (input_var, data_vec) in input_data
				if isequal(rhs, Num(input_var))
					new_data_sample[rhs] = data_vec
				end
			end
		end
	end

	new_pep = ParameterEstimationProblem(
		pep.name * "_polynomialized",
		new_model,
		new_measured,
		new_data_sample,
		pep.recommended_time_interval,
		pep.solver,
		new_p_true,
		new_ic,
		pep.unident_count,
	)

	return new_pep, tr_info
end

# =============================================================================
# Template Variable Helpers
# Used at solve time to identify _trfn_ variables in SIAN template equations
# and compute their known values at shooting points.
# =============================================================================

"""
	_parse_trfn_base_name(base_name::String)

Parse a _trfn_ base variable name (without derivative order suffix) to extract
the function type and frequency.

# Examples
- "_trfn_sin_5_0" → (:sin, 5.0)
- "_trfn_cos_2_0" → (:cos, 2.0)
- "_trfn_exp_m1_5" → (:exp, -1.5)

# Returns
- `(func_type::Symbol, frequency::Float64)` or `nothing` if parsing fails
"""
function _parse_trfn_base_name(base_name::AbstractString)
	m = match(r"^_trfn_(sin|cos|exp)_(.+)$", base_name)
	if isnothing(m)
		return nothing
	end
	func_type = Symbol(m.captures[1])
	freq_str = m.captures[2]
	# Convert freq string back to Float64: "5_0" → "5.0", "m2_5" → "-2.5"
	freq_str_dot = replace(replace(freq_str, "_" => "."), "m" => "-")
	frequency = tryparse(Float64, freq_str_dot)
	if isnothing(frequency)
		return nothing
	end
	return (func_type, frequency)
end

"""
	is_trfn_template_variable(var_name::String)

Check if a variable name from a SIAN template represents a _trfn_ transcendental
input variable (or its derivative). These have the form `_trfn_{type}_{freq}_{order}`.

# Returns
- `true` if the variable is a _trfn_ template variable
"""
function is_trfn_template_variable(var_name::AbstractString)
	parsed = parse_derivative_variable_name(var_name)
	if isnothing(parsed)
		return false
	end
	base_name, _ = parsed
	return !isnothing(_parse_trfn_base_name(base_name))
end

"""
	evaluate_trfn_template_variable(var_name::String, t_value::Float64)

Compute the numerical value of a _trfn_ template variable at a given time point.
Uses the known analytical derivatives of sin/cos/exp.

# Arguments
- `var_name`: Variable name like "_trfn_sin_5_0_0" (sin(5t), 0th derivative)
- `t_value`: Time point

# Returns
- `Float64` value, or `nothing` if the variable is not a _trfn_ variable
"""
function evaluate_trfn_template_variable(var_name::AbstractString, t_value::Float64)
	parsed = parse_derivative_variable_name(var_name)
	if isnothing(parsed)
		return nothing
	end
	base_name, deriv_order = parsed
	trfn_parsed = _parse_trfn_base_name(base_name)
	if isnothing(trfn_parsed)
		return nothing
	end
	func_type, frequency = trfn_parsed

	if func_type == :sin
		return _eval_sin_derivative(frequency, t_value, deriv_order)
	elseif func_type == :cos
		return _eval_cos_derivative(frequency, t_value, deriv_order)
	elseif func_type == :exp
		return _eval_exp_derivative(frequency, t_value, deriv_order)
	end
	return nothing
end

"""
	classify_trfn_in_template(solve_vars, data_vars_set, template_equations)

Identify _trfn_ transcendental input variables among the template solve_vars.
These represent sin(c*t), cos(c*t) at shooting points — their values are known
analytically, so they should be treated as data rather than unknowns.

# Returns
- `trfn_var_info`: Dict mapping _trfn_ variable → (func_type, frequency, deriv_order)
- `real_solve_vars`: Variables that are real unknowns (not _trfn_)
- `trfn_only_eq_indices`: Indices of equations containing only data_vars + _trfn_ vars
"""
function classify_trfn_in_template(solve_vars, data_vars_set, template_equations)
	trfn_var_info = Dict{Any, Tuple{Symbol, Float64, Int}}()
	real_solve_vars = Any[]

	for v in solve_vars
		var_name = string(v)
		parsed = parse_derivative_variable_name(var_name)
		if !isnothing(parsed)
			base_name, deriv_order = parsed
			trfn_parsed = _parse_trfn_base_name(base_name)
			if !isnothing(trfn_parsed)
				func_type, frequency = trfn_parsed
				trfn_var_info[v] = (func_type, frequency, deriv_order)
				continue
			end
		end
		push!(real_solve_vars, v)
	end

	# Find equations that only involve data_vars and _trfn_ vars (no real unknowns)
	real_solve_set = Set(real_solve_vars)
	trfn_only_eq_indices = Int[]
	for (idx, eq) in enumerate(template_equations)
		eq_vars = Symbolics.get_variables(eq)
		has_real_unknown = any(v -> v in real_solve_set, eq_vars)
		if !has_real_unknown
			push!(trfn_only_eq_indices, idx)
		end
	end

	return trfn_var_info, real_solve_vars, trfn_only_eq_indices
end
