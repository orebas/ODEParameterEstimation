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


	# Also substitute _trfn_ transcendental input variables with their known analytical values.
	# These represent sin(c*t), cos(c*t), and their derivatives at the shooting point — they
	# are known functions of time, not unknowns.  After substitution, equations that only
	# contained data_vars + _trfn_ vars will become trivially satisfied (0 ≈ 0) and get
	# removed by the zero-variable filter below.
	n_trfn_substituted = 0
	for v in vars_in_template
		var_name = string(v)
		trfn_val = evaluate_trfn_template_variable(var_name, t_point)
		if !isnothing(trfn_val)
			interpolated_values_dict[v] = trfn_val
			n_trfn_substituted += 1
		end
	end
	if n_trfn_substituted > 0
		@info "[TEMPLATE] Substituted $n_trfn_substituted _trfn_ variable(s) at t=$t_point"
	end

	if diagnostics
		println("[DEBUG-SI] Created interpolated_values_dict with $(length(interpolated_values_dict)) entries (including $n_trfn_substituted _trfn_ vars)")
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

	# Extract variables from each equation *after* substitution,
	# and filter out trivially-satisfied equations (0 remaining variables).
	# These arise from oscillator coupling constraints when _trfn_ observable
	# derivatives are substituted — the equations become "0 ≈ 0".
	final_vars = OrderedSet()
	kept_equations = eltype(substituted_equations)[]
	n_trivial = 0
	for (eq_idx, eq) in enumerate(substituted_equations)
		vars_in_eq = Symbolics.get_variables(eq)
		if isempty(vars_in_eq)
			# Equation has no remaining variables — trivially satisfied after substitution
			n_trivial += 1
			if diagnostics
				@info "[DEBUG-SI-VARS] Eq$eq_idx TRIVIAL (0 variables, removing): $eq"
			end
		else
			push!(kept_equations, eq)
			union!(final_vars, vars_in_eq)
			if diagnostics
				@info "[DEBUG-SI-VARS] Eq$eq_idx has $(length(vars_in_eq)) variables: $(vars_in_eq)"
			end
		end
	end

	if n_trivial > 0
		@info "[TEMPLATE] Removed $n_trivial trivially-satisfied equations after data substitution"
	end

	if diagnostics
		println("[DEBUG-SI] Extracted $(length(final_vars)) variables from substituted system: $(collect(final_vars))")
	end

	# Log the final variables list
	@info "[DEBUG-SI-VARS] Final variables list ($(length(final_vars))): $(collect(final_vars))"

	# Always log this critical count info
	@info "[DEBUG-EQ-VAR-COUNT] After template instantiation: $(length(kept_equations)) equations, $(length(final_vars)) variables"

	# Handle overdetermined systems: when _trfn_ substitution + data substitution
	# leaves more equations than variables, remove redundant equations.
	# An equation is "removable" if every variable in it also appears in at least one
	# other kept equation — removing it won't lose any variable.
	# Among removable equations, prefer removing from the end (highest derivative order,
	# most numerically sensitive).
	while length(kept_equations) > length(final_vars)
		n_excess = length(kept_equations) - length(final_vars)
		# Build per-variable occurrence count across all kept equations
		var_eq_count = Dict{Any, Int}()
		for eq in kept_equations
			for v in Symbolics.get_variables(eq)
				var_eq_count[v] = get(var_eq_count, v, 0) + 1
			end
		end
		# Find removable equations (from the end, for numerical stability)
		removed = false
		for idx in length(kept_equations):-1:1
			eq_vars = Symbolics.get_variables(kept_equations[idx])
			# Safe to remove if every variable appears in at least 2 equations (this one + another)
			if all(v -> get(var_eq_count, v, 0) >= 2, eq_vars)
				@info "[TEMPLATE] Overdetermined ($n_excess excess): removing equation $idx (all $(length(eq_vars)) vars appear elsewhere)"
				deleteat!(kept_equations, idx)
				removed = true
				break
			end
		end
		if !removed
			@warn "[TEMPLATE] Cannot safely remove any equation without losing a variable. Keeping overdetermined system."
			break
		end
		# Recompute final_vars after removal
		final_vars = OrderedSet()
		for eq in kept_equations
			union!(final_vars, Symbolics.get_variables(eq))
		end
	end

	# Return the non-trivial equations and the correctly filtered variable list
	return kept_equations, collect(final_vars)
end

"""
	resolve_states_with_fixed_params(
		model, measured_quantities, data_sample,
		deriv_level, unident_dict, varlist, DD,
		known_param_dict, interpolants;
		si_template, time_index, diagnostics
	)

Re-solve for unknown state initial conditions at a specific time point,
with parameter values fixed from a previous shooting-point solution.

This is the algebraic fallback for when backward ODE integration (backsolving)
fails due to stiff eigenvalues amplifying numerical errors.

**Approach**: Re-run SIAN with all parameters pre-fixed at the model level,
so SIAN generates a purpose-built polynomial system where the only unknowns
are state derivative variables. This produces a square system (N eqs = N vars),
unlike post-hoc parameter substitution which creates an overdetermined system
with numerically inconsistent redundant equations.

Returns `(state_solutions, state_vars)` where:
- `state_solutions::Vector{Vector{Float64}}` — each inner vector has values
  in the same order as `state_vars`
- `state_vars::Vector` — the Symbolics variables for states in the reduced system
"""
function resolve_states_with_fixed_params(
	model::ModelingToolkit.AbstractSystem,
	measured_quantities,
	data_sample,
	deriv_level,
	unident_dict,
	varlist,
	DD,
	known_param_dict::OrderedDict,
	interpolants;
	si_template = nothing,  # ignored — we generate a fresh template via SIAN re-run
	time_index::Int = 1,
	diagnostics::Bool = false,
)
	@info "[RESOLVE] Re-running SIAN with $(length(known_param_dict)) fixed parameters"

	# Step 1: Build OrderedODESystem for the original model
	model_states = ModelingToolkit.unknowns(model)
	model_params = ModelingToolkit.parameters(model)
	ordered_model = if isa(model, ODEParameterEstimation.OrderedODESystem)
		model
	else
		ODEParameterEstimation.OrderedODESystem(model, model_states, model_params)
	end

	# Step 2: Apply all parameters as pre-fixed → model with 0 parameters, values baked in
	fixed_model, fixed_mq = apply_prefixed_params_to_model(ordered_model, measured_quantities, known_param_dict)

	if diagnostics
		fixed_sys = isa(fixed_model, ODEParameterEstimation.OrderedODESystem) ? fixed_model.system : fixed_model
		n_remaining = length(ModelingToolkit.parameters(fixed_sys))
		@info "[RESOLVE] Fixed model: $(n_remaining) remaining parameters (should be 0)"
	end

	# Step 3: Re-run SIAN on the parameter-free model → template with only state unknowns
	new_template_eqs, new_deriv_dict, new_unident, new_id_funcs = get_si_equation_system(
		fixed_model, fixed_mq, data_sample;
		DD = DD,
		infolevel = diagnostics ? 1 : 0,
	)

	if isempty(new_template_eqs)
		@warn "[RESOLVE] SIAN re-run produced no template equations"
		return Vector{Float64}[], Any[]
	end

	new_si_template = (
		equations = new_template_eqs,
		deriv_dict = new_deriv_dict,
		unidentifiable = new_unident,
		identifiable_funcs = new_id_funcs,
	)

	@info "[RESOLVE] SIAN re-run produced $(length(new_template_eqs)) template eqs, $(length(new_deriv_dict)) deriv vars"

	# Step 4: Instantiate at t=0 using the new template
	# Use ORIGINAL model for unpack_ODE (DD is tied to original model's observables)
	# but the NEW si_template for equations (parameters already baked in)
	equations, template_vars = construct_equation_system_from_si_template(
		model,
		measured_quantities,
		data_sample,
		deriv_level,
		OrderedDict(),  # empty unident_dict — all params fixed, nothing unidentifiable
		varlist,
		DD;
		interpolator = :AAA,  # unused — precomputed_interpolants provided
		time_index_set = [time_index],
		precomputed_interpolants = interpolants,
		diagnostics = diagnostics,
		si_template = new_si_template,
	)

	if isempty(equations)
		@warn "[RESOLVE] No equations after template instantiation at time_index=$time_index"
		return Vector{Float64}[], Any[]
	end

	n_eqs = length(equations)
	n_vars = length(template_vars)
	@info "[RESOLVE] Instantiated system: $n_eqs eqs, $n_vars state vars" * (n_eqs == n_vars ? " (square)" : " (NOT square)")

	if diagnostics
		@info "[RESOLVE] Variables: $(template_vars)"
		for (i, eq) in enumerate(equations)
			eq_vars = Symbolics.get_variables(eq)
			@info "[RESOLVE] Eq$i ($(length(eq_vars)) vars): $eq"
		end
	end

	# Step 5: Try HC.jl first — square systems are HC.jl's sweet spot
	state_vars = template_vars
	solutions = Vector{Float64}[]

	if n_eqs == n_vars && n_vars > 0
		@info "[RESOLVE] Solving square system with HC.jl"
		solutions, _, _, _ = solve_with_hc(equations, state_vars)
		if isempty(solutions)
			@warn "[RESOLVE] HC.jl found no solutions for square system"
		else
			@info "[RESOLVE] HC.jl found $(length(solutions)) solution(s)"
		end
	elseif n_eqs != n_vars
		@warn "[RESOLVE] Non-square system ($n_eqs eqs, $n_vars vars) — skipping HC.jl"
	end

	# Fallback: cascading substitution if HC.jl fails or system isn't square
	if isempty(solutions)
		@info "[RESOLVE] Attempting cascading substitution fallback"

		cascade_subst = Dict{Any, Any}()
		cascade_pass = 0
		reduced_eqs = copy(equations)
		changed = true

		while changed
			changed = false
			cascade_pass += 1
			new_eqs = eltype(reduced_eqs)[]
			for eq in reduced_eqs
				eq_vars = Symbolics.get_variables(eq)
				if isempty(eq_vars)
					continue
				elseif length(eq_vars) == 1
					v = only(eq_vars)
					haskey(cascade_subst, v) && continue
					try
						solved = Symbolics.symbolic_linear_solve(eq, v)
						cascade_subst[v] = solved
						changed = true
						if diagnostics
							@info "[RESOLVE] Cascade (pass $cascade_pass): solved $v = $solved"
						end
					catch
						push!(new_eqs, eq)
					end
				else
					push!(new_eqs, eq)
				end
			end
			reduced_eqs = changed ? Symbolics.substitute.(new_eqs, Ref(cascade_subst)) : new_eqs
		end

		if diagnostics
			@info "[RESOLVE] Cascading completed in $cascade_pass passes, solved $(length(cascade_subst)) variables"
		end

		if !isempty(cascade_subst)
			# Resolve dependency chains (A→B→C→number)
			resolved = Dict{Any, Any}(k => v for (k, v) in cascade_subst)
			for _pass in 1:10
				all_numeric = true
				for (v, expr) in resolved
					new_expr = Symbolics.substitute(expr, resolved)
					resolved[v] = new_expr
					if !isempty(Symbolics.get_variables(new_expr))
						all_numeric = false
					end
				end
				all_numeric && break
			end

			final_vals = Dict{Any, Float64}()
			n_failed = 0
			for (v, expr) in resolved
				try
					final_vals[v] = Float64(Symbolics.value(expr))
				catch e
					n_failed += 1
					@warn "[RESOLVE] Failed to convert $v = $expr to Float64: $e"
					final_vals[v] = 0.0
				end
			end
			if n_failed > 0
				@warn "[RESOLVE] $n_failed variables failed Float64 conversion (set to 0.0)"
			end

			# Check if any equations remain unsolved
			remaining_vars = OrderedSet()
			remaining_eqs = eltype(reduced_eqs)[]
			for eq in reduced_eqs
				eq_vars = Symbolics.get_variables(eq)
				if !isempty(eq_vars)
					push!(remaining_eqs, eq)
					union!(remaining_vars, eq_vars)
				end
			end

			if isempty(remaining_eqs)
				@info "[RESOLVE] All variables solved by cascading (no HC.jl needed)"
				solutions = [collect(values(final_vals))]
				state_vars = collect(keys(final_vals))
			else
				remaining_state_vars = collect(remaining_vars)
				n_rem_eqs = length(remaining_eqs)
				n_rem_vars = length(remaining_state_vars)

				hc_solutions = Vector{Float64}[]
				if n_rem_eqs >= n_rem_vars && n_rem_vars > 0
					# Square or overdetermined — HC.jl can handle this
					@info "[RESOLVE] Trying HC.jl on remaining $n_rem_eqs eqs, $n_rem_vars vars"
					hc_solutions, _, _, _ = solve_with_hc(remaining_eqs, remaining_state_vars)
				elseif n_rem_vars > 0
					# Underdetermined — HC.jl would throw FiniteException
					@warn "[RESOLVE] Remaining system is underdetermined ($n_rem_eqs eqs, $n_rem_vars vars) — skipping HC.jl"
				end

				if !isempty(hc_solutions)
					# Merge cascaded + HC solutions
					all_vars = copy(remaining_state_vars)
					cascade_keys = collect(keys(cascade_subst))
					append!(all_vars, cascade_keys)

					for sol in hc_solutions
						sol_dict = Dict{Any, Any}(remaining_state_vars[j] => sol[j] for j in eachindex(remaining_state_vars))
						merged = copy(sol)
						for cvar in cascade_keys
							expr = cascade_subst[cvar]
							val = Symbolics.substitute(expr, merge(sol_dict, cascade_subst))
							try
								push!(merged, Float64(Symbolics.value(val)))
							catch
								push!(merged, 0.0)
							end
						end
						push!(solutions, merged)
					end
					state_vars = all_vars
				else
					# HC.jl failed or was skipped — return cascade-only partial solution.
					# The caller handles missing vars via data-derived fallback.
					@info "[RESOLVE] Returning partial solution from cascading ($(length(final_vals)) of $n_vars vars solved)"
					solutions = [collect(values(final_vals))]
					state_vars = collect(keys(final_vals))
				end
			end
		end
	end

	if isempty(solutions)
		@warn "[RESOLVE] No solutions found (neither HC.jl nor cascading)"
	else
		@info "[RESOLVE] Final: $(length(solutions)) solution(s) with $(length(state_vars)) variables"
	end

	return solutions, state_vars
end

# Export the template-based constructor
export construct_equation_system_from_si_template
