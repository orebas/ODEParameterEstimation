# Archived 2026-06-10 from src/core/{parameter_estimation,parameter_estimation_helpers}.jl
# — NOT part of the build. The if(false) dead-diagnostics chain (postcampaign review P2):
# log_diagnostic_info's entire body was `if (false) ... end`, so its no-op call and the
# functions reachable ONLY through that dead branch (construct_multipoint_equation_system!,
# construct_equation_system, evaluate_poly_system) were all unreachable. Reference only.
# ============================================================================

# ---- log_diagnostic_info (parameter_estimation_helpers.jl 906-1011) ----
function log_diagnostic_info(
	PEP,
	time_index_set,
	good_deriv_level,
	good_udict,
	good_varlist,
	good_DD,
	interpolator,
	interpolants,
	diagnostic_data,
	states,
	params,
	final_target,
	forward_subst_dict,
	reverse_subst_dict,
)
	if (false)
		# Calculate maximum derivative level
		max_deriv = max(7, 1 + maximum(collect(values(good_deriv_level))))

		# Calculate observable derivatives
		expanded_mq, obs_derivs = calculate_observable_derivatives(
			equations(PEP.model.system), PEP.measured_quantities, max_deriv,
		)

		# Create a new system with the expanded measured quantities
		@named new_sys = ODESystem(equations(PEP.model.system), t; observed = expanded_mq)

		# Create and solve the problem with true parameters
		time_interval = extrema(PEP.data_sample["t"])
		local_prob = ODEProblem(
			structural_simplify(new_sys),
			merge(diagnostic_data.ic, diagnostic_data.p_true),
			time_interval,
		)

		ideal_sol = ModelingToolkit.solve(
			local_prob, AutoVern9(Rodas5P()), abstol = 1e-14, reltol = 1e-14,
			saveat = PEP.data_sample["t"],
		)

		# Construct equation system with ideal values
		ideal_full_target, ideal_full_varlist, ideal_forward_subst_dict, ideal_reverse_subst_dict =
			construct_multipoint_equation_system!(
				time_index_set,
				PEP.model.system,
				PEP.measured_quantities,
				PEP.data_sample,
				good_deriv_level,
				good_udict,
				good_varlist,
				good_DD,
				interpolator,
				interpolants,
				true,
				diagnostic_data,
				states,
				params,
				ideal = true,
				sol = ideal_sol,
			)

		ideal_final_target = reduce(vcat, ideal_full_target)

		# Log the targets
		log_equations(ideal_final_target, "Ideal final target")
		log_equations(final_target, "Actual target being solved")

		# Log parameter and state values
		@info "True parameter values: $(PEP.p_true)"
		@info "True states: $(PEP.ic)"

		# Get state and parameter values at the lowest time
		lowest_time = min(time_index_set...)
		exact_state_vals = OrderedDict{Num, Float64}()
		for s in states
			exact_state_vals[s] = ideal_sol(PEP.data_sample["t"][lowest_time], idxs = s)
		end

		# Evaluate the polynomial system with exact values
		exact_system = evaluate_poly_system(
			ideal_final_target,
			ideal_forward_subst_dict[1],
			ideal_reverse_subst_dict[1],
			exact_state_vals,
			PEP.p_true,
			equations(PEP.model.system),
		)

		inexact_system = evaluate_poly_system(
			final_target,
			forward_subst_dict[1],
			reverse_subst_dict[1],
			exact_state_vals,
			PEP.p_true,
			equations(PEP.model.system),
		)

		# Log the evaluated systems
		log_equations(exact_system, "Evaluated ideal polynomial system with exact values")
		log_equations(inexact_system, "Evaluated interpolated polynomial system with exact values")

		@info "Exact state values at time index $lowest_time: $(exact_state_vals)"
		@info "Exact parameter values: $(PEP.p_true)"
	end
end

# ---- construct_multipoint_equation_system! (parameter_estimation.jl 204-334) ----
function construct_multipoint_equation_system!(time_index_set,
	model, measured_quantities, data_sample, good_deriv_level, good_udict, good_varlist, good_DD,
	interpolator, precomputed_interpolants, diagnostics, diagnostic_data, states, params; ideal = false, sol = nothing, use_si_template = true)  # SI.jl is now the default
	full_target, full_varlist, forward_subst_dict, reverse_subst_dict = [[] for _ in 1:4]

	# Get SI.jl template using structural representative fixing only.
	si_template = nothing
	if use_si_template
		# Create the template on first use
		ordered_model = if isa(model, OrderedODESystem)
			model
		else
			OrderedODESystem(model, states, params)
		end

		si_template, _template_structure = prepare_si_template_with_structural_fix(
			ordered_model,
			measured_quantities,
			data_sample,
			good_DD,
			diagnostics;
			states = states,
			params = params,
			infolevel = diagnostics ? 1 : 0,
			placeholder_fail_categories = opts.si_placeholder_fail_categories,
		)

		@info "[DEBUG-EQ-COUNT] Final SI template: $(length(si_template.equations)) equations after structural fixing"
		template_equations = si_template.equations

		if diagnostics
			println("[DEBUG-SI] Created SI.jl template with $(length(template_equations)) equations")

			# Output the SI.jl polynomial system for debugging
			println("\n[DEBUG-SI] ========== SI.jl POLYNOMIAL SYSTEM ==========")
			println("[DEBUG-SI] Variables in deriv_dict: $(length(si_template.deriv_dict))")
			if !isempty(si_template.si_variable_role_summary.counts)
				println("[DEBUG-SI] SI variable roles: $(si_template.si_variable_role_summary.counts)")
				if !isempty(si_template.si_variable_role_summary.auxiliary_variables)
					println("[DEBUG-SI] SI auxiliaries: $(si_template.si_variable_role_summary.auxiliary_variables)")
				end
				if !isempty(si_template.si_variable_role_summary.suspicious_categories)
					println("[DEBUG-SI] Suspicious SI roles: $(si_template.si_variable_role_summary.suspicious_categories)")
				end
			end
			println("[DEBUG-SI] Equations ($(length(template_equations))): ")
			for (i, eq) in enumerate(template_equations)
				println("[DEBUG-SI]   Eq $i: $eq")
				# Try to analyze coefficient ranges
				eq_str = string(eq)
				# Count terms as a rough complexity measure
				num_terms = length(split(eq_str, r"[+-]")) - 1
				println("[DEBUG-SI]     Complexity: ~$num_terms terms")
			end
			println("[DEBUG-SI] =========================================\n")

			# Save SI.jl template to file
			timestamp_str = Dates.format(now(), "yyyy-mm-dd'T'HH:MM:SS.sss")
			save_filepath = joinpath("saved_systems", "si_template_$(timestamp_str).jl")
			mkpath(dirname(save_filepath))
			open(save_filepath, "w") do io
				println(io, "# SI.jl Template Polynomial System")
				println(io, "# Generated: $(timestamp_str)")
				println(io, "# Number of equations: $(length(template_equations))")
				println(io, "# Variables: $(keys(si_template.deriv_dict))")
				println(io, "# SI variable roles: $(si_template.si_variable_role_summary.counts)")
				println(io, "# SI auxiliaries: $(si_template.si_variable_role_summary.auxiliary_variables)")
				println(io, "# Suspicious SI roles: $(si_template.si_variable_role_summary.suspicious_categories)")
				println(io, "# Structural fix set: $(si_template.structural_fix_set)")
				println(io, "# Residual fix set: $(si_template.residual_fix_set)")
				println(io, "# Template status before residual fix: $(si_template.template_status_before_residual_fix)")
				println(io, "# Template status after residual fix: $(si_template.template_status_after_residual_fix)")
				println(io, "# Dropped equations by rank trimming: $(si_template.rank_trimming_metadata.dropped_equation_indices)")
				println(io, "")
				for (i, eq) in enumerate(template_equations)
					println(io, "# Equation $i:")
					println(io, "$eq")
					println(io, "")
				end
			end
			@info "Saved SI.jl template to $save_filepath"
		end
	end

	for k in time_index_set
		if use_si_template
			# Use SI.jl template-based construction
			(target_k, varlist_k) = construct_equation_system_from_si_template(
				model,
				measured_quantities,
				data_sample,
				good_deriv_level,
				good_udict,
				good_varlist, # Pass the original good_varlist, it will be filtered inside
				good_DD;
				interpolator = interpolator,
				time_index_set = [k],
				precomputed_interpolants = precomputed_interpolants,
				diagnostics = diagnostics,
				si_template = si_template)
		else
			# Fall back to iterative construction (optional path)
			(target_k, varlist_k) = construct_equation_system(
				model,
				measured_quantities,
				data_sample,
				good_deriv_level,
				good_udict,
				good_varlist,
				good_DD;
				interpolator = interpolator,
				time_index_set = [k],
				precomputed_interpolants = precomputed_interpolants,
				diagnostics = diagnostics,
				diagnostic_data = diagnostic_data,
				ideal = ideal,
				sol = sol)
		end

		local_subst_dict = OrderedDict{Num, Any}()
		local_subst_dict_reverse = OrderedDict()
		# With the SI template providing a single system, the old per-point tagging is no longer needed.
		# We just push the results directly.
		push!(full_target, target_k)
		push!(full_varlist, varlist_k)
		# Substitution dictionaries are not used in this path but are kept for API compatibility.
		push!(forward_subst_dict, OrderedDict{Num, Any}())
		push!(reverse_subst_dict, OrderedDict{Num, Num}())
	end  #this is the end of the loop over the time points which just constructs the System
	return full_target, full_varlist, forward_subst_dict, reverse_subst_dict
end

# ---- construct_equation_system (parameter_estimation.jl 1305-1496) ----
function construct_equation_system(model::ModelingToolkit.AbstractSystem, measured_quantities_in, data_sample,
	deriv_level, unident_dict, varlist, DD; interpolator, time_index_set = nothing, return_parameterized_system = false,
	precomputed_interpolants = nothing, diagnostics = false, diagnostic_data = nothing, ideal = false, sol = nothing)

	measured_quantities = deepcopy(measured_quantities_in)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	D = Differential(t)

	t_vector = data_sample["t"]
	time_interval = (minimum(t_vector), maximum(t_vector))
	if (isnothing(time_index_set))
		time_index_set = [fld(length(t_vector), 2)]
	end
	time_index = time_index_set[1]

	if isnothing(precomputed_interpolants)
		interpolants = create_interpolants(measured_quantities, data_sample, t_vector, interpolator)
	else
		interpolants = precomputed_interpolants
	end

	unident_subst!(model_eq, measured_quantities, unident_dict)

	max_deriv = max(4, 1 + maximum(collect(values(deriv_level))))

	target = []
	for (key, value) in deriv_level
		push!(target, DD.obs_rhs_cleared[1][key] - DD.obs_lhs_cleared[1][key])
		for i in 1:value
			push!(target, DD.obs_rhs_cleared[i+1][key] - DD.obs_lhs_cleared[i+1][key])
		end
	end
	interpolated_values_dict = Dict()
	if (!ideal)
		for (key, value) in deriv_level
			# Use TaylorDiff-based nth_deriv instead of recursive ForwardDiff
			obs_interp = interpolants[ModelingToolkit.diff2term(measured_quantities[key].rhs)]
			interpolated_values_dict[DD.obs_lhs[1][key]] = nth_deriv(x -> obs_interp(x), 0, t_vector[time_index])
			for i in 1:value
				interpolated_values_dict[DD.obs_lhs[i+1][key]] = nth_deriv(x -> obs_interp(x), i, t_vector[time_index])
			end
		end
	else
		if sol === nothing
			expanded_mq, obs_derivs = calculate_observable_derivatives(equations(model), measured_quantities, max_deriv)
			@named new_sys = ModelingToolkit.System(equations(model), t; observed = expanded_mq)
			local_prob = ODEProblem(mtkcompile(new_sys), diagnostic_data.ic, (time_interval[1], time_interval[2]), diagnostic_data.p_true)
			sol = ModelingToolkit.solve(local_prob, AutoVern9(Rodas5P()), abstol = 1e-14, reltol = 1e-14, saveat = t_vector)
		else
			expanded_mq, obs_derivs = calculate_observable_derivatives(equations(model), measured_quantities, max_deriv)
		end
		for (key, value) in deriv_level

			temp1 = DD.obs_lhs[1][key]
			newidx = measured_quantities[key].lhs
			tempt = t_vector[time_index]
			#			println("DEBUG BEFORE ERROR")
			#			println(tempt)
			#			println(newidx)

			temp2 = sol(tempt, idxs = newidx)
			interpolated_values_dict[temp1] = temp2
			for i in 1:value
				interpolated_values_dict[DD.obs_lhs[i+1][key]] = sol(t_vector[time_index], idxs = obs_derivs[key, i])
			end
		end
	end

	for i in eachindex(target)
		target[i] = Symbolics.substitute(target[i], interpolated_values_dict)
	end


	vars_needed = OrderedSet()
	vars_added = OrderedSet()

	vars_needed = union(vars_needed, model_ps)
	vars_needed = union(vars_needed, model_states)
	vars_needed = setdiff(vars_needed, keys(unident_dict))

	# Simplified scanning loop with less verbose output
	keep_adding = true
	iteration_count = 0

	while (keep_adding)
		iteration_count += 1
		added = false

		for i in target
			for j in Symbolics.get_variables(i)
				push!(vars_needed, j)
			end
		end

		for i in setdiff(vars_needed, vars_added)
			for j in eachindex(DD.states_lhs), k in eachindex(DD.states_lhs[j])
				if (isequal(DD.states_lhs[j][k], i))
					push!(target, DD.states_lhs_cleared[j][k] - DD.states_rhs_cleared[j][k])
					added = true
					push!(vars_added, i)
					break
				end
			end
		end

		diff_set = setdiff(vars_needed, vars_added)
		keep_adding = !isempty(diff_set) && added
	end

	println("\n[DEBUG-ODEPE] Scanning complete after $iteration_count iterations")
	println("[DEBUG-ODEPE] Final target has $(length(target)) equations")
	println("[DEBUG-ODEPE] Final vars_needed has $(length(vars_needed)) variables")
	println("[DEBUG-ODEPE] Final vars_added has $(length(vars_added)) variables")

	# Output FULL polynomial system for debugging
	println("\n[DEBUG-ODEPE] ========== FULL POLYNOMIAL SYSTEM ==========")
	println("[DEBUG-ODEPE] Variables ($(length(vars_needed))): ")
	for (i, v) in enumerate(collect(vars_needed))
		println("[DEBUG-ODEPE]   Var $i: $v")
	end

	println("[DEBUG-ODEPE] Equations ($(length(target))): ")
	for (i, eq) in enumerate(target)
		println("[DEBUG-ODEPE]   Eq $i: $eq")
		# Try to analyze coefficient ranges
		eq_str = string(eq)
		# Count terms as a rough complexity measure
		num_terms = length(split(eq_str, r"[+-]")) - 1
		println("[DEBUG-ODEPE]     Complexity: ~$num_terms terms")
	end

	# Check for equation/variable imbalance
	if length(target) != length(vars_needed)
		println("[DEBUG-ODEPE] WARNING: Equation/variable count mismatch!")
		println("[DEBUG-ODEPE]   Variables without equations: ", setdiff(vars_needed, vars_added))

		# Count equations by type
		obs_eq_count = 0
		for (key, value) in deriv_level
			obs_eq_count += value + 1  # value is max derivative, so we have 0..value equations
		end
		println("[DEBUG-ODEPE]   Observable equations: $obs_eq_count")
		println("[DEBUG-ODEPE]   Additional ODE equations: $(length(target) - obs_eq_count)")
	end

	# Analyze linear vs nonlinear structure
	println("\n[DEBUG-ODEPE] Equation structure analysis:")
	linear_count = 0
	for (i, eq) in enumerate(target)
		eq_str = string(eq)
		# Check if equation is linear (no products of variables)
		if !occursin(r"[a-zA-Z_ˍ]\([^)]*\)\s*\*\s*[a-zA-Z_ˍ]\([^)]*\)", eq_str) &&
		   !occursin(r"k\d+\s*\*\s*k\d+", eq_str) &&
		   !occursin(r"\([^)]*\)\^2", eq_str)
			linear_count += 1
			if i <= 10  # Only show first few
				println("[DEBUG-ODEPE]   Eq $i is LINEAR")
			end
		elseif i <= 10
			println("[DEBUG-ODEPE]   Eq $i is NONLINEAR")
		end
	end
	println("[DEBUG-ODEPE] Total: $linear_count linear equations, $(length(target) - linear_count) nonlinear")

	# Check which parameters appear in which equations
	param_appearance = Dict()
	for p in [k for k in collect(vars_needed) if occursin("k", string(k))]
		param_appearance[p] = []
		for (i, eq) in enumerate(target)
			if occursin(string(p), string(eq))
				push!(param_appearance[p], i)
			end
		end
	end

	println("\n[DEBUG-ODEPE] Parameter coupling analysis:")
	for (param, eqs) in param_appearance
		if length(eqs) == 0
			println("[DEBUG-ODEPE]   $param appears in NO equations - FREE PARAMETER?")
		elseif length(eqs) <= 3
			println("[DEBUG-ODEPE]   $param appears in equations: $eqs")
		end
	end

	println("[DEBUG-ODEPE] =========================================")

	push!(data_sample, ("t" => t_vector))

	return_var = collect(vars_needed)

	return target, return_var
end

# ---- evaluate_poly_system (parameter_estimation.jl 1649-1737) ----
function evaluate_poly_system(poly_system, forward_subst::OrderedDict, reverse_subst::OrderedDict, true_states::OrderedDict, true_params::OrderedDict, eqns)
	sub_dict = Dict()

	#println("starting evaluate_poly_system")
	#println(poly_system)
	poly_system = Symbolics.substitute(poly_system, reverse_subst)
	#println("poly_system after substitution:")
	#println(poly_system)

	#println("break")


	# Create DD structure to compute derivatives
	DD = DerivativeData(
		Vector{Vector{Num}}(), Vector{Vector{Num}}(),
		Vector{Vector{Num}}(), Vector{Vector{Num}}(),
		Vector{Vector{Num}}(), Vector{Vector{Num}}(),
		Vector{Vector{Num}}(), Vector{Vector{Num}}(),
		Set{Num}(),
	)
	DD.states_lhs = [[eq.lhs for eq in eqns], expand_derivatives.(D.([eq.lhs for eq in eqns]))]
	DD.states_rhs = [[eq.rhs for eq in eqns], expand_derivatives.(D.([eq.rhs for eq in eqns]))]

	# Compute higher derivatives
	for i in 1:7
		push!(DD.states_lhs, expand_derivatives.(D.(DD.states_lhs[end])))
		temp = DD.states_rhs[end]
		temp2 = D.(temp)
		temp4 = Num[]
		for j in 1:length(temp2)
			push!(temp4, expand_derivatives(temp2[j]))
		end
		push!(DD.states_rhs, temp4)
	end

	# Convert all derivatives to terms
	for i in eachindex(DD.states_rhs), j in eachindex(DD.states_rhs[i])
		DD.states_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_rhs[i][j]))
		DD.states_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_lhs[i][j]))
	end


	# First pass: substitute known parameters and states (0th derivatives)
	for (temp_var, base_var) in forward_subst
		if haskey(true_params, temp_var)
			sub_dict[temp_var] = true_params[temp_var]
		elseif haskey(true_states, temp_var)
			sub_dict[temp_var] = true_states[temp_var]
		end
	end
	#println("after first pass")
	#println(sub_dict)

	# Create a dictionary of derivative values
	deriv_values = Dict()

	# For each state (V and R)

	# Second pass: map derivative values to temporary variables
	#for (temp_var, base_var) in reverse_subst
	#	if !haskey(sub_dict, temp_var)
	#		if haskey(deriv_values, base_var)
	#			sub_dict[temp_var] = deriv_values[base_var]
	#		end
	#	end
	#end
	#println("DD.states_rhs:")
	#println(DD.states_rhs)
	#println("DD.states_lhs:")
	#println(DD.states_lhs)


	for i in eachindex(DD.states_rhs), j in eachindex(DD.states_rhs[i])
		sub_dict[DD.states_lhs[i][j]] = simplify(Symbolics.substitute(DD.states_rhs[i][j], sub_dict))
	end


	#println("deriv_values:")
	#println(deriv_values)
	#println("sub_dict after computing derivatives:")
	#println(sub_dict)

	# Apply substitutions and convert remaining derivatives to terms
	evaluated = [ModelingToolkit.diff2term(expand_derivatives(simplify(Symbolics.substitute(expr, sub_dict)))) for expr in poly_system]



	return evaluated
end
