"""
SI.jl Template Integration for ODEParameterEstimation

This module provides the glue between SI.jl's polynomial template
and ODEPE's multipoint system construction.
"""

"""
	construct_equation_system_from_si_template(
		model, measured_quantities, data_sample,
		deriv_level, unident_dict, varlist, DD;
		interpolator, time_index_set, kwargs...
	)

Drop-in replacement for construct_equation_system that uses SI.jl's template
instead of iterative construction.

This function:
1. Gets the polynomial template from SI.jl (once)
2. Creates interpolated_values_dict for the specific time point
3. Substitutes values into the template
"""
function construct_equation_system_from_si_template(
	model::ModelingToolkit.AbstractSystem,
	measured_quantities_in,
	data_sample,
	deriv_level,
	unident_dict,
	varlist,
	DD;
	interpolator,
	time_index_set = nothing,
	precomputed_interpolants = nothing,
	diagnostics = false,
	si_template = nothing,  # Cache the template if provided
	kwargs...,
)
	measured_quantities = deepcopy(measured_quantities_in)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)

	t_vector = data_sample["t"]
	if isnothing(time_index_set)
		time_index_set = [fld(length(t_vector), 2)]
	end
	time_index = time_index_set[1]

	# Get or create the SI.jl template
	if isnothing(si_template)
		# Create OrderedODESystem wrapper if needed
		ordered_model = if isa(model, ODEParameterEstimation.OrderedODESystem)
			model
		else
			ODEParameterEstimation.OrderedODESystem(model, model_states, model_ps)
		end

		# Get the template from SI.jl
		template_equations, derivative_dict, unidentifiable = get_si_equation_system(
			ordered_model,
			measured_quantities,
			data_sample;
			DD = DD,
			infolevel = diagnostics ? 1 : 0,
		)

		si_template = (
			equations = template_equations,
			deriv_dict = derivative_dict,
			unidentifiable = unidentifiable,
		)

		if diagnostics
			println("[DEBUG-SI] Got $(length(template_equations)) template equations from SI.jl")
			println("[DEBUG-SI] Derivative variables: ", keys(derivative_dict))
		end
	else
		template_equations = si_template.equations
		derivative_dict = si_template.deriv_dict
	end

	# Create interpolants if not provided
	if isnothing(precomputed_interpolants)
		if diagnostics
			println("[DEBUG-SI] Creating interpolants for $(length(measured_quantities)) quantities...")
		end
		interpolants = create_interpolants(measured_quantities, data_sample, t_vector, interpolator)
		if diagnostics
			println("[DEBUG-SI] Interpolants created successfully")
		end
	else
		interpolants = precomputed_interpolants
	end

	# Apply unidentifiable substitutions
	unident_subst!(model_eq, measured_quantities, unident_dict)

	# Create a set of all variables present in the template equations
	vars_in_template = OrderedSet()
	for eq in template_equations
		union!(vars_in_template, Symbolics.get_variables(eq))
	end

	# Filter the provided varlist to include only variables present in the template
	# This ensures the variable list matches the reduced equation system
	varlist_in_template = filter(v -> v in vars_in_template, varlist)

	# Interpolate data for the required derivatives at the specified time point
	interpolated_values_dict = Dict()
	t_point = data_sample["t"][time_index_set[1]]

	# The derivatives needed are determined by the SI.jl template
	max_required_deriv = isempty(derivative_dict) ? 0 : maximum(values(derivative_dict))

	if diagnostics
		println("[DEBUG-SI] Max derivative order required by template: $max_required_deriv")
	end

	# For each measured quantity, populate all derivatives up to the max required order.
	for (obs_idx, obs_eqn) in enumerate(measured_quantities_in)
		obs_rhs = ModelingToolkit.diff2term(obs_eqn.rhs)
		obs_interp = precomputed_interpolants[obs_rhs]

		for i in 0:max_required_deriv
			# Find the corresponding lhs variable in the DD structure
			if i + 1 <= length(DD.obs_lhs) && obs_idx <= length(DD.obs_lhs[i+1])
				lhs_var = DD.obs_lhs[i+1][obs_idx]
				val = nth_deriv(x -> obs_interp(x), i, t_point)
				if isnan(val)
					@warn "[DEBUG-ODEPE-NaN] NaN detected from interpolator call." observable = obs_rhs deriv_order = i time_point = t_point
					@warn "[DEBUG-ODEPE-NaN] The failing interpolator object is:" interpolator_object = obs_interp
					t_near = t_point + 1e-9
					val_near = try
						nth_deriv(x -> obs_interp(x), i, t_near)
					catch e
						"Failed with error: $e"
					end
					@warn "[DEBUG-ODEPE-NaN] For comparison, value at nearby point t=$t_near is: $val_near"
				end
				interpolated_values_dict[lhs_var] = val
			else
				# This may not be an error if a high derivative of one observable is needed,
				# but not for this specific one.
			end
		end
	end


	if diagnostics
		println("[DEBUG-SI] Created interpolated_values_dict with $(length(interpolated_values_dict)) entries")
	end

	# Substitute interpolated values into the template equations (broadcast over the vector)
	if diagnostics
		# Print a small sample of keys and an example equation before substitution
		key_sample = collect(keys(interpolated_values_dict))
		println("[DEBUG-SI] Substitution key sample (up to 5): ", key_sample[1:min(length(key_sample), 5)])
		println("[DEBUG-SI] Before substitution (Eq1): ", template_equations[1])
	end

	substituted_equations = Symbolics.substitute.(template_equations, Ref(interpolated_values_dict))

	if diagnostics
		println("[DEBUG-SI] After substitution (Eq1): ", substituted_equations[1])
	end

	# FINAL FIX: Extract variables from the system *after* substitution
	final_vars = OrderedSet()
	for (eq_idx, eq) in enumerate(substituted_equations)
		vars_in_eq = Symbolics.get_variables(eq)
		union!(final_vars, vars_in_eq)
		@info "[DEBUG-SI-VARS] Eq$eq_idx has $(length(vars_in_eq)) variables: $(vars_in_eq)"
	end

	if diagnostics
		println("[DEBUG-SI] Extracted $(length(final_vars)) variables from substituted system: $(collect(final_vars))")
	end

	# Log the final variables list
	@info "[DEBUG-SI-VARS] Final variables list ($(length(final_vars))): $(collect(final_vars))"

	# Always log this critical count info
	@info "[DEBUG-EQ-VAR-COUNT] After template instantiation: $(length(substituted_equations)) equations, $(length(final_vars)) variables"
	if length(substituted_equations) != length(final_vars)
		@warn "[DEBUG-EQ-VAR-COUNT] MISMATCH! equations=$(length(substituted_equations)) != variables=$(length(final_vars))"
	end

	# Return the substituted equations and the correctly filtered variable list
	return substituted_equations, collect(final_vars)
end

# Export the template-based constructor
export construct_equation_system_from_si_template
