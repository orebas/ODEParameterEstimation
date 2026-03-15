# REFACTORING NOTE:
# Several functions have been moved out of this file to improve organization:
# - Parameter estimation helper functions -> moved to parameter_estimation_helpers.jl

"""
	populate_derivatives(model::ModelingToolkit.System, measured_quantities_in, max_deriv_level, unident_dict)

Populate a DerivativeData object by taking derivatives of state variable and measured quantity equations.
diff2term is applied everywhere, so we will be left with variables like x_tttt etc.

# Arguments
- `model::ModelingToolkit.System`: The ODE system
- `measured_quantities_in`: Input measured quantities
- `max_deriv_level`: Maximum derivative level
- `unident_dict`: Dictionary of unidentifiable variables

# Returns
- DerivativeData object
"""
function populate_derivatives(model::ModelingToolkit.AbstractSystem, measured_quantities_in, max_deriv_level, unident_dict)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities = deepcopy(measured_quantities_in)

	DD = DerivativeData(
		Vector{Vector{Num}}(), Vector{Vector{Num}}(),
		Vector{Vector{Num}}(), Vector{Vector{Num}}(),
		Vector{Vector{Num}}(), Vector{Vector{Num}}(),
		Vector{Vector{Num}}(), Vector{Vector{Num}}(),
		Set{Num}(),
	)

	#First, we fully substitute values we have chosen for an unidentifiable variables.
	unident_subst!(model_eq, measured_quantities, unident_dict)

	model_eq_cleared = clear_denoms.(model_eq)
	measured_quantities_cleared = clear_denoms.(measured_quantities)

	DD.states_lhs = [[eq.lhs for eq in model_eq], expand_derivatives.(D.([eq.lhs for eq in model_eq]))]
	DD.states_rhs = [[eq.rhs for eq in model_eq], expand_derivatives.(D.([eq.rhs for eq in model_eq]))]
	DD.obs_lhs = [[eq.lhs for eq in measured_quantities], expand_derivatives.(D.([eq.lhs for eq in measured_quantities]))]
	DD.obs_rhs = [[eq.rhs for eq in measured_quantities], expand_derivatives.(D.([eq.rhs for eq in measured_quantities]))]

	DD.states_lhs_cleared = [[eq.lhs for eq in model_eq_cleared], expand_derivatives.(D.([eq.lhs for eq in model_eq_cleared]))]
	DD.states_rhs_cleared = [[eq.rhs for eq in model_eq_cleared], expand_derivatives.(D.([eq.rhs for eq in model_eq_cleared]))]
	DD.obs_lhs_cleared = [[eq.lhs for eq in measured_quantities_cleared], expand_derivatives.(D.([eq.lhs for eq in measured_quantities_cleared]))]
	DD.obs_rhs_cleared = [[eq.rhs for eq in measured_quantities_cleared], expand_derivatives.(D.([eq.rhs for eq in measured_quantities_cleared]))]

	extra_levels = 0
	for i in 1:(max_deriv_level-2)
		new_states_lhs = expand_derivatives.(D.(DD.states_lhs[end]))
		temp = DD.states_rhs[end]
		temp2 = D.(temp)
		temp4 = Num[]
		for j in 1:length(temp2)
			push!(temp4, expand_derivatives(temp2[j]))
		end

		# Stop if symbolic coefficients have overflowed Float64
		if any(expr -> (let s = string(expr); occursin("Inf", s) || occursin("NaN", s) end), temp4)
			@warn "populate_derivatives: coefficient overflow at derivative level $(length(DD.states_rhs) + 1), capping at $(length(DD.states_rhs))"
			break
		end

		push!(DD.states_lhs, new_states_lhs)
		push!(DD.states_rhs, temp4)
		push!(DD.states_lhs_cleared, expand_derivatives.(D.(DD.states_lhs_cleared[end])))
		push!(DD.states_rhs_cleared, expand_derivatives.(D.(DD.states_rhs_cleared[end])))
		extra_levels += 1
	end

	# Build observable derivatives (must match state derivative levels for substitution to work)
	# Note: obs derivatives must not exceed state derivatives, otherwise substitution
	# will fail with missing keys
	for i in 1:extra_levels
		push!(DD.obs_lhs, expand_derivatives.(D.(DD.obs_lhs[end])))
		push!(DD.obs_rhs, expand_derivatives.(D.(DD.obs_rhs[end])))
		push!(DD.obs_lhs_cleared, expand_derivatives.(D.(DD.obs_lhs_cleared[end])))
		push!(DD.obs_rhs_cleared, expand_derivatives.(D.(DD.obs_rhs_cleared[end])))
	end

	# NOTE: We intentionally do NOT apply diff2term here.
	# diff2term converts Differential(t)(x(t)) to xˍt(t), but it creates NEW symbol objects
	# each time, causing substitution failures (Symbolics.substitute uses object identity).
	# By keeping everything in Differential form, structural equality ensures matching.
	return DD
end


"""
	convert_to_real_or_complex_array(values) -> Union{Array{Float64,1}, Array{ComplexF64,1}}

Converts input values to either real or complex array based on the values' properties.

# Arguments
- `values`: Input values to convert

# Returns
- `Array{Float64,1}` if all values are real (within numerical precision)
- `Array{ComplexF64,1}` if any values have non-negligible imaginary components
"""
function convert_to_real_or_complex_array(values)::Union{Array{Float64, 1}, Array{ComplexF64, 1}}
	# First convert to complex to handle mixed inputs
	newvalues = Base.convert(Array{ComplexF64, 1}, values)

	# If all values are real (within tolerance), convert to real array
	if isreal(newvalues)
		return Base.convert(Array{Float64, 1}, newvalues)
	else
		return newvalues
	end
end





"""
	create_interpolants(
		measured_quantities::Vector{ModelingToolkit.Equation},
		data_sample::OrderedDict,
		t_vector::Vector{Float64},
		interp_func::Function
	) -> Dict{Any, AbstractInterpolator}

Creates interpolant functions for measured quantities using the provided interpolation function.

# Arguments
- `measured_quantities::Vector{ModelingToolkit.Equation}`: Equations for measured quantities
- `data_sample::OrderedDict`: Sample data for measured quantities
- `t_vector::Vector{Float64}`: Time points at which measurements were taken
- `interp_func::Function`: Function to use for interpolation (e.g., aaad, aaad_gpr_pivot)

# Returns
- Dictionary mapping each quantity to its corresponding interpolant function
"""
function create_interpolants(
	measured_quantities::Vector{ModelingToolkit.Equation},
	data_sample::OrderedDict,
	t_vector::Vector{Float64},
	interp_func::Function,
)::Dict{Num, AbstractInterpolator}
	interpolants = Dict{Num, AbstractInterpolator}()

	for j in measured_quantities
		r = j.rhs
		# Look up data in data_sample - use rhs if available, otherwise use lhs
		key = haskey(data_sample, r) ? r : Symbolics.wrap(j.lhs)
		y_vector = data_sample[key]

		# Create interpolant and store in dictionary
		interpolants[r] = interp_func(t_vector, y_vector)
	end

	return interpolants
end




function determine_optimal_points_count(model, measured_quantities, max_num_points, t_vector, nooutput)
	(t, eqns, states, params) = unpack_ODE(model)
	time_interval = extrema(t_vector)
	large_num_points = min(length(params), max_num_points, length(t_vector))
	good_num_points = large_num_points
	@debug "Large num points: $large_num_points"
	@debug "Good num points: $good_num_points"

	time_index_set, solns, good_udict, forward_subst_dict, trivial_dict, final_varlist, trimmed_varlist =
		[[] for _ in 1:7]
	good_DD = nothing

	@debug "Starting parameter estimation..."
	if good_num_points > 1
		(target_deriv_level, target_udict, target_varlist, target_DD) = multipoint_local_identifiability_analysis(model, measured_quantities, large_num_points)

		while (good_num_points > 1)
			good_num_points = good_num_points - 1
			(test_deriv_level, test_udict, test_varlist, test_DD) = multipoint_local_identifiability_analysis(model, measured_quantities, good_num_points)
			if !(test_deriv_level == target_deriv_level)
				good_num_points = good_num_points + 1
				break
			end
		end
	end

	(good_deriv_level, good_udict, good_varlist, good_DD) = multipoint_local_identifiability_analysis(model, measured_quantities, good_num_points)

	@debug "Final analysis with $(good_num_points) points"
	@debug "Final unidentifiable dict: $(good_udict)"
	@debug "Final varlist: $(good_varlist)"

	return good_num_points, good_deriv_level, good_udict, good_varlist, good_DD

end



function construct_multipoint_equation_system!(time_index_set,
	model, measured_quantities, data_sample, good_deriv_level, good_udict, good_varlist, good_DD,
	interpolator, precomputed_interpolants, diagnostics, diagnostic_data, states, params; ideal = false, sol = nothing, use_si_template = true)  # SI.jl is now the default
	full_target, full_varlist, forward_subst_dict, reverse_subst_dict = [[] for _ in 1:4]

	# Get SI.jl template using iterative parameter fixing (if using SI.jl)
	si_template = nothing
	if use_si_template
		# Create the template on first use
		ordered_model = if isa(model, OrderedODESystem)
			model
		else
			OrderedODESystem(model, states, params)
		end

		max_fix_iterations = 10

		si_template, _template_structure = prepare_si_template_with_fix_phases(
			ordered_model,
			measured_quantities,
			data_sample,
			good_DD,
			diagnostics;
			states = states,
			params = params,
			infolevel = diagnostics ? 1 : 0,
			placeholder_fail_categories = opts.si_placeholder_fail_categories,
			max_residual_fix_iterations = max_fix_iterations,
		)

		@info "[DEBUG-EQ-COUNT] Final SI template: $(length(si_template.equations)) equations after structural/residual fixing"
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

"""
	handle_unidentifiability(si_template, diagnostics)

Apply substitutions to the SI template to handle unidentifiable parameters.
The number of parameters to fix is determined by the difference between the
number of unidentifiable parameters and the number of independent identifiable functions.
"""

function _state_base_name_set(states)
	state_base_names = Set{String}()
	if !isnothing(states)
		for s in states
			name_str = string(s)
			if endswith(name_str, "(t)")
				name_str = name_str[1:(end-3)]
			end
			push!(state_base_names, name_str)
		end
	end
	return state_base_names
end

function _model_symbol_from_name(name::AbstractString, states = nothing, params = nothing)
	if !isnothing(params)
		for p in params
			if string(p) == name
				return p
			end
		end
	end
	if !isnothing(states)
		for s in states
			s_name = endswith(string(s), "(t)") ? string(s)[1:(end-3)] : string(s)
			if s_name == name
				return s
			end
		end
	end
	return Symbolics.variable(Symbol(name))
end

function _symbolic_identifiable_functions(identifiable_funcs)
	nemo_to_mtk_map = Dict()
	return [nemo_to_symbolics(f, nemo_to_mtk_map) for f in identifiable_funcs]
end

function _candidate_fix_variables(unidentifiable_params, already_fixed::Set, states)
	state_base_names = _state_base_name_set(states)
	param_like = Any[]
	state_like = Any[]
	already_fixed_names = Set(string.(collect(already_fixed)))
	for p in unidentifiable_params
		pstr = string(p)
		pstr in already_fixed_names && continue
		if pstr in state_base_names
			push!(state_like, p)
		else
			push!(param_like, p)
		end
	end
	return isempty(param_like) ? state_like : param_like
end

function _rank_based_fix_candidates(candidate_vars, symbolic_identifiable_funcs, diagnostics)
	isempty(candidate_vars) && return Any[]
	param_syms = [Symbolics.variable(Symbol(string(p))) for p in candidate_vars]
	candidate_names = Set(string.(candidate_vars))
	funcs_filtered = [
		f for f in symbolic_identifiable_funcs
		if any(string(v) in candidate_names for v in Symbolics.get_variables(f))
	]

	if isempty(funcs_filtered)
		diagnostics && println("[STRUCTURAL-FIX] No identifiable functions for candidates; selecting first candidate")
		return Any[candidate_vars[1]]
	end

	J_sym = Symbolics.jacobian(funcs_filtered, param_syms)
	all_vars = OrderedSet{Any}()
	for f in funcs_filtered
		union!(all_vars, Symbolics.get_variables(f))
	end
	val_dict = Dict{Num, Float64}()
	for v in all_vars
		val_dict[v] = 0.5 + rand()
	end
	J_num = Array{Float64}(undef, length(funcs_filtered), length(param_syms))
	for i in 1:size(J_sym, 1)
		for j in 1:size(J_sym, 2)
			entry = Symbolics.substitute(J_sym[i, j], val_dict)
			J_num[i, j] = Float64(Symbolics.value(entry))
		end
	end
	F = LinearAlgebra.qr(J_num, LinearAlgebra.ColumnNorm())
	R = Array(F.R)
	tol = 1e-10 * maximum(size(J_num)) * (isempty(R) ? 0.0 : maximum(abs, diag(R)))
	rnk = sum(abs.(diag(R)) .> tol)
	num_to_fix = max(length(candidate_vars) - rnk, 0)
	if num_to_fix == 0
		diagnostics && println("[STRUCTURAL-FIX] Jacobian rank indicates no remaining structural fix variables are required")
		return Any[]
	end

	cols_ordered = collect(F.p)
	pivot_cols = rnk > 0 ? Set(cols_ordered[1:rnk]) : Set{Int}()
	dof_cols = [j for j in 1:length(param_syms) if !(j in pivot_cols)]
	selected = Any[]
	for j in dof_cols
		push!(selected, candidate_vars[j])
		length(selected) >= num_to_fix && break
	end
	while length(selected) < num_to_fix && length(selected) < length(candidate_vars)
		for candidate in candidate_vars
			candidate in selected && continue
			push!(selected, candidate)
			length(selected) >= num_to_fix && break
		end
	end
	if diagnostics
		println("[STRUCTURAL-FIX] Jacobian rank: $rnk, DOF cols: $dof_cols")
		println("[STRUCTURAL-FIX] Selected structural fix candidates: $selected")
	end
	return selected
end

function derive_structural_fix_set(si_template, diagnostics; states = nothing, params = nothing)
	unidentifiable_params = si_template.unidentifiable
	isempty(unidentifiable_params) && return (
		pre_fixed = OrderedDict{Num, Float64}(),
		reported = OrderedDict{Num, Float64}(),
		structural_unidentifiable = Set{Num}(),
	)

	candidate_vars = _candidate_fix_variables(unidentifiable_params, Set(), states)
	symbolic_identifiable_funcs = _symbolic_identifiable_functions(si_template.identifiable_funcs)
	selected = _rank_based_fix_candidates(candidate_vars, symbolic_identifiable_funcs, diagnostics)

	pre_fixed = OrderedDict{Num, Float64}()
	reported = OrderedDict{Num, Float64}()
	for candidate in selected
		candidate_name = string(candidate)
		pre_fixed[Symbolics.variable(Symbol(candidate_name))] = 1.0
		reported[_model_symbol_from_name(candidate_name, states, params)] = 1.0
	end

	structural_unidentifiable = Set{Num}()
	for candidate in unidentifiable_params
		push!(structural_unidentifiable, _model_symbol_from_name(string(candidate), states, params))
	end

	if diagnostics
		println("[STRUCTURAL-FIX] Structural unidentifiable set from SI: $structural_unidentifiable")
		println("[STRUCTURAL-FIX] Representative structural fix set: $reported")
		println("[STRUCTURAL-FIX] Practical/numerical identifiability status: not_assessed")
	end

	return (
		pre_fixed = pre_fixed,
		reported = reported,
		structural_unidentifiable = structural_unidentifiable,
	)
end

function analyze_si_template_structure(si_template)
	template_equations = si_template.equations
	template_DD = hasproperty(si_template, :template_DD) ? si_template.template_DD : nothing
	data_vars = isnothing(template_DD) ? Any[] : extract_data_variables_from_DD(template_DD)
	data_vars_set = Set(data_vars)
	vars_in_system = OrderedSet{Any}()
	for eq in template_equations
		union!(vars_in_system, Symbolics.get_variables(eq))
	end
	unknown_vars = OrderedSet{Any}()
	for v in vars_in_system
		if !(v in data_vars_set)
			push!(unknown_vars, v)
		end
	end
	trfn_var_info, real_solve_vars, trfn_only_eq_indices = classify_trfn_in_template(
		collect(unknown_vars), data_vars_set, template_equations
	)
	n_equations = length(template_equations)
	n_variables = length(unknown_vars)
	n_data_vars = length(data_vars)
	n_trfn_vars = length(trfn_var_info)
	n_trfn_only_eqs = length(trfn_only_eq_indices)
	n_effective_eqs = n_equations - n_trfn_only_eqs
	n_effective_vars = n_variables - n_trfn_vars
	status = if n_effective_eqs == n_effective_vars
		:determined
	elseif n_effective_eqs > n_effective_vars && n_effective_eqs <= n_effective_vars + 2
		:slightly_overdetermined
	elseif n_effective_eqs < n_effective_vars
		:residual_underdetermined
	else
		:severely_overdetermined
	end
	rank_trim_meta = hasproperty(si_template, :rank_trimming_metadata) ? si_template.rank_trimming_metadata : (
		selected_equation_indices = Int[],
		dropped_equation_indices = Int[],
		original_equation_count = n_equations,
	)
	return (
		status = status,
		n_equations = n_equations,
		n_variables = n_variables,
		n_data_vars = n_data_vars,
		n_effective_eqs = n_effective_eqs,
		n_effective_vars = n_effective_vars,
		n_trfn_vars = n_trfn_vars,
		n_trfn_only_eqs = n_trfn_only_eqs,
		trfn_var_info = trfn_var_info,
		real_solve_vars = real_solve_vars,
		trfn_only_eq_indices = trfn_only_eq_indices,
		dropped_equation_indices = rank_trim_meta.dropped_equation_indices,
		selected_equation_indices = rank_trim_meta.selected_equation_indices,
		original_equation_count = rank_trim_meta.original_equation_count,
	)
end

function select_one_parameter_to_fix(si_template, already_fixed::Set, diagnostics; states = nothing)
	candidate_vars = _candidate_fix_variables(si_template.unidentifiable, already_fixed, states)
	if isempty(candidate_vars)
		diagnostics && println("[TEMPLATE-RESIDUAL] No unfixed structural candidates remain for residual template repair")
		return nothing, nothing
	end

	symbolic_identifiable_funcs = _symbolic_identifiable_functions(si_template.identifiable_funcs)
	selected = _rank_based_fix_candidates(candidate_vars, symbolic_identifiable_funcs, diagnostics)
	param_to_fix = isempty(selected) ? candidate_vars[1] : selected[1]
	param_to_fix_sym = Symbolics.variable(Symbol(string(param_to_fix)))
	diagnostics && println("[TEMPLATE-RESIDUAL] Selected residual fix variable: $param_to_fix_sym")
	return param_to_fix_sym, 1.0
end

function prepare_si_template_with_fix_phases(
	ordered_model,
	measured_quantities,
	data_sample,
	base_DD,
	diagnostics;
	states = nothing,
	params = nothing,
	infolevel = diagnostics ? 1 : 0,
	placeholder_fail_categories = Symbol[],
	max_residual_fix_iterations = 10,
)
	initial_equations, initial_derivative_dict, initial_unidentifiable, initial_identifiable_funcs, initial_role_summary, initial_metadata = get_si_equation_system(
		ordered_model,
		measured_quantities,
		data_sample;
		DD = base_DD,
		infolevel = infolevel,
		pre_fixed_params = OrderedDict{Num, Float64}(),
		placeholder_fail_categories = placeholder_fail_categories,
	)
	initial_template_DD = ensure_si_template_dd_support(ordered_model, measured_quantities, base_DD, initial_derivative_dict)
	initial_template = (
		equations = initial_equations,
		deriv_dict = initial_derivative_dict,
		template_DD = initial_template_DD,
		unidentifiable = initial_unidentifiable,
		identifiable_funcs = initial_identifiable_funcs,
		si_variable_role_summary = initial_role_summary,
		rank_trimming_metadata = initial_metadata,
	)

	structural_fix_info = derive_structural_fix_set(initial_template, diagnostics; states = states, params = params)
	structural_fix_set = structural_fix_info.pre_fixed
	structural_fix_report = structural_fix_info.reported
	structural_unidentifiable = structural_fix_info.structural_unidentifiable
	current_fixed = OrderedDict{Num, Float64}(k => v for (k, v) in structural_fix_set)
	residual_fix_set = OrderedDict{Num, Float64}()
	residual_fix_report = OrderedDict{Num, Float64}()
	template_status_before_residual_fix = nothing
	template_status_after_residual_fix = nothing
	residual_iteration = 0
	final_template = initial_template
	final_structure = nothing

	while residual_iteration <= max_residual_fix_iterations
		template_equations, derivative_dict, unidentifiable, identifiable_funcs, si_variable_role_summary, si_template_metadata = get_si_equation_system(
			ordered_model,
			measured_quantities,
			data_sample;
			DD = base_DD,
			infolevel = infolevel,
			pre_fixed_params = current_fixed,
			placeholder_fail_categories = placeholder_fail_categories,
		)
		template_DD = ensure_si_template_dd_support(ordered_model, measured_quantities, base_DD, derivative_dict)
		si_template = (
			equations = template_equations,
			deriv_dict = derivative_dict,
			template_DD = template_DD,
			unidentifiable = unidentifiable,
			identifiable_funcs = identifiable_funcs,
			si_variable_role_summary = si_variable_role_summary,
			rank_trimming_metadata = si_template_metadata,
		)
		structure = analyze_si_template_structure(si_template)
		isnothing(template_status_before_residual_fix) && (template_status_before_residual_fix = structure.status)

		if diagnostics
			@info "[TEMPLATE-STRUCTURE] System status: $(structure.n_equations) equations, $(structure.n_variables) unknowns (+ $(structure.n_data_vars) data variables)"
			if structure.n_trfn_vars > 0
				@info "[TEMPLATE-STRUCTURE] _trfn_ vars: $(structure.n_trfn_vars) known inputs, $(structure.n_trfn_only_eqs) trivial equations"
				@info "[TEMPLATE-STRUCTURE] Effective system: $(structure.n_effective_eqs) equations, $(structure.n_effective_vars) real unknowns"
			end
		end

		final_template = (
			equations = template_equations,
			deriv_dict = derivative_dict,
			template_DD = template_DD,
			unidentifiable = unidentifiable,
			identifiable_funcs = identifiable_funcs,
			si_variable_role_summary = si_variable_role_summary,
			rank_trimming_metadata = si_template_metadata,
			structural_unidentifiable = structural_unidentifiable,
			structural_fix_set = structural_fix_report,
			residual_fix_set = copy(residual_fix_report),
			template_status_before_residual_fix = template_status_before_residual_fix,
			template_status_after_residual_fix = structure.status,
			practical_identifiability_status = :not_assessed,
		)
		final_structure = structure
		template_status_after_residual_fix = structure.status

		if structure.status in (:determined, :slightly_overdetermined)
			break
		elseif structure.status == :residual_underdetermined
			residual_iteration += 1
			if residual_iteration > max_residual_fix_iterations
				@warn "[TEMPLATE-RESIDUAL] Did not converge after $max_residual_fix_iterations residual iterations"
				break
			end
			@info "[TEMPLATE-RESIDUAL] Iteration $residual_iteration, fixed so far: $(keys(residual_fix_set))"
			param_to_fix, fix_value = select_one_parameter_to_fix(
				si_template, Set(keys(current_fixed)), diagnostics; states = states
			)
			if param_to_fix === nothing
				@warn "[TEMPLATE-RESIDUAL] No parameter available to fix, stopping residual template repair"
				break
			end
			@info "[TEMPLATE-RESIDUAL] Fixing residual template variable: $param_to_fix = $fix_value"
			current_fixed[param_to_fix] = fix_value
			residual_fix_set[param_to_fix] = fix_value
			residual_fix_report[_model_symbol_from_name(string(param_to_fix), states, params)] = fix_value
		else
			@warn "[TEMPLATE-RESIDUAL] Template is severely overdetermined ($(structure.n_effective_eqs) eqs > $(structure.n_effective_vars) vars)"
			break
		end
	end

	return final_template, final_structure
end

function handle_unidentifiability(si_template, diagnostics; states = nothing, params = nothing)
	structural_fix_info = derive_structural_fix_set(si_template, diagnostics; states = states, params = params)
	if isempty(structural_fix_info.pre_fixed)
		return si_template.equations, si_template
	end
	fix_dict = Dict{Any, Float64}()
	for (param, fix_value) in structural_fix_info.pre_fixed
		fix_dict[Symbolics.variable(Symbol(string(param) * "_0"))] = fix_value
	end
	template_equations = Symbolics.substitute.(si_template.equations, Ref(fix_dict))
	new_si_template = (
		equations = template_equations,
		deriv_dict = si_template.deriv_dict,
		template_DD = hasproperty(si_template, :template_DD) ? si_template.template_DD : nothing,
		unidentifiable = si_template.unidentifiable,
		identifiable_funcs = si_template.identifiable_funcs,
		si_variable_role_summary = si_template.si_variable_role_summary,
	)
	return template_equations, new_si_template
end

"""
	compute_default_bounds(PEP::ParameterEstimationProblem)

Compute default optimization bounds based on the scale of observed data.
Returns `(lb, ub)` vectors of length `n_states + n_params`, scaled by
`DEFAULT_BOUND_MULTIPLIER * max(1, max_data_value)`.
"""
function compute_default_bounds(PEP::ParameterEstimationProblem)
	data_vals = Float64[]
	for (k, v) in PEP.data_sample
		k == "t" && continue
		append!(data_vals, abs.(Float64.(v)))
	end
	data_scale = isempty(data_vals) ? 1.0 : max(1.0, maximum(data_vals))
	n_states = length(ModelingToolkit.unknowns(PEP.model.system))
	n_params = length(ModelingToolkit.parameters(PEP.model.system))
	p_size = n_states + n_params
	bound = DEFAULT_BOUND_MULTIPLIER * data_scale
	lb = fill(-bound, p_size)
	ub = fill(bound, p_size)
	return lb, ub
end

function process_raw_solution(raw_sol, model::OrderedODESystem, data_sample, ode_solver; abstol = 1e-12, reltol = 1e-12)
	# Create ordered collections for states and parameters
	ordered_states = OrderedDict()
	ordered_params = OrderedDict()

	# Get current ordering from ModelingToolkit
	current_states = ModelingToolkit.unknowns(model.system)
	current_params = ModelingToolkit.parameters(model.system)


	# Reorder states according to original ordering
	for (i, state) in enumerate(model.original_states)
		idx = findfirst(s -> isequal(s, state), current_states)
		if isnothing(idx)
			@warn "State $state not found in current states, using original index $i"
			idx = i
		end
		ordered_states[state] = raw_sol[idx]
	end

	# Reorder parameters according to original ordering
	param_offset = length(current_states)
	for (i, param) in enumerate(model.original_parameters)
		ordered_params[param] = raw_sol[param_offset+i]
	end

	ic = collect(values(ordered_states))
	ps = collect(values(ordered_params))


	# Solve ODE problem
	tspan = (data_sample["t"][begin], data_sample["t"][end])

	prob = ODEProblem(complete(model.system), merge(ordered_states, ordered_params), tspan)
	ode_solution = ModelingToolkit.solve(prob, ode_solver, saveat = data_sample["t"], abstol = abstol, reltol = reltol)

	# Calculate error
	err = 0
	if ode_solution.retcode == ReturnCode.Success
		err = 0
		for (key, sample) in data_sample
			if isequal(key, "t")
				continue
			end
			err += norm((ode_solution(data_sample["t"])[key]) .- sample) / length(data_sample["t"])
		end
		err /= length(data_sample)
	else
		err = 1e+15
	end


	# Reorder parameters according to original ordering
	param_offset = length(current_states)
	for (i, param) in enumerate(model.original_parameters)
		# Find the index of this parameter in the current parameters
		idx = findfirst(p -> isequal(p, param), current_params)
		if isnothing(idx)
			@warn "Parameter $param not found in current parameters, using original index $i"
			idx = i
		end
		ordered_params[param] = raw_sol[param_offset+idx]
	end


	return ordered_states, ordered_params, ode_solution, err
end

"""
	equilibrate_jacobian(jac::Matrix{Float64}) -> Matrix{Float64}

Apply full matrix equilibration (row and column scaling) to improve numerical stability.

When Jacobian matrices have values spanning many orders of magnitude (e.g., 10^0 to 10^36),
SVD-based nullspace computation can fail due to numerical precision issues. This function
normalizes the matrix so all rows and columns have similar magnitudes.

# Arguments
- `jac::Matrix{Float64}`: The input Jacobian matrix

# Returns
- Equilibrated copy of the Jacobian matrix with normalized rows and columns
"""
function equilibrate_jacobian(jac::Matrix{Float64})
	scaled_jac = copy(jac)

	# Step 1: Row scaling - normalize each row by its L2 norm
	row_norms = [norm(scaled_jac[i, :]) for i in 1:size(scaled_jac, 1)]
	for i in 1:size(scaled_jac, 1)
		if row_norms[i] > 1e-10
			scaled_jac[i, :] ./= row_norms[i]
		end
	end

	# Step 2: Column scaling - normalize each column by its L2 norm
	col_norms = [norm(scaled_jac[:, j]) for j in 1:size(scaled_jac, 2)]
	for j in 1:size(scaled_jac, 2)
		if col_norms[j] > 1e-10
			scaled_jac[:, j] ./= col_norms[j]
		end
	end

	return scaled_jac
end


"""
	multipoint_numerical_jacobian(
		model::ModelingToolkit.System,
		measured_quantities::Vector{ModelingToolkit.Equation},
		max_deriv_level::Int,
		max_num_points::Int,
		unident_dict::Dict,
		varlist::Vector{Num},
		param_dict,
		ic_dict_vector,
		values_dict,
		DD::Union{DerivativeData,Symbol} = :nothing
	) -> Tuple{Matrix{Float64}, DerivativeData}

Computes the numerical Jacobian at multiple points.
The multiple points have different values for states, but the same parameters.

# Arguments
- `model::ModelingToolkit.System`: The ODE system model
- `measured_quantities::Vector{ModelingToolkit.Equation}`: Input measured quantities
- `max_deriv_level::Int`: Maximum derivative level to compute
- `max_num_points::Int`: Maximum number of points to use
- `unident_dict::Dict`: Dictionary of unidentifiable variables
- `varlist::Vector{Num}`: List of variables
- `param_dict::OrderedDict{Num,Float64}`: Dictionary of parameters
- `ic_dict_vector::Vector{OrderedDict{Num,Float64}}`: Vector of initial condition dictionaries
- `values_dict::OrderedDict{Num,Float64}`: Dictionary of values; used for dictionary structure
- `DD::Union{DerivativeData,Symbol}`: DerivativeData object (optional, default: :nothing)

# Returns
- Tuple containing the Jacobian matrix and DerivativeData object
"""
function multipoint_numerical_jacobian(
	model::ModelingToolkit.AbstractSystem,
	measured_quantities::Vector{Equation},
	max_deriv_level::Int,
	max_num_points::Int,
	unident_dict::Dict,
	varlist::Vector{Num},
	param_dict,
	ic_dict_vector,
	values_dict,
	DD::Union{DerivativeData, Symbol} = :nothing,
)::Tuple{Matrix{Float64}, DerivativeData}
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities_local = deepcopy(measured_quantities)

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)
	subst_dict = Dict()

	num_real_params = length(keys(param_dict))
	num_real_states = length(keys(ic_dict_vector[1]))

	if (DD == :nothing)
		DD = populate_derivatives(model, measured_quantities_local, max_deriv_level, unident_dict)
	end

	function f(param_and_ic_values_vec)
		T = eltype(param_and_ic_values_vec)  # Float64 or ForwardDiff.Dual
		obs_deriv_vals = T[]
		for k in eachindex(ic_dict_vector)
			evaluated_subst_dict = OrderedDict{Num, Any}(values_dict)
			thekeys = collect(keys(evaluated_subst_dict))
			for i in 1:num_real_params
				evaluated_subst_dict[thekeys[i]] = param_and_ic_values_vec[i]
			end
			for i in 1:num_real_states
				evaluated_subst_dict[thekeys[i+num_real_params]] =
					param_and_ic_values_vec[(k-1)*num_real_states+num_real_params+i]
			end

		for i in eachindex(DD.states_rhs)
				for j in eachindex(DD.states_rhs[i])
					substituted_val = Symbolics.substitute(DD.states_rhs[i][j], evaluated_subst_dict)
					# If the substituted value is a constant, unwrap it from the symbolic type.
					if !Symbolics.iscall(substituted_val)
						evaluated_subst_dict[DD.states_lhs[i][j]] = Symbolics.value(substituted_val)
					else
						evaluated_subst_dict[DD.states_lhs[i][j]] = substituted_val
					end
				end
			end
			for i in eachindex(DD.obs_rhs), j in eachindex(DD.obs_rhs[i])
				substituted = Symbolics.substitute(DD.obs_rhs[i][j], evaluated_subst_dict)
				val = Symbolics.value(substituted)
				# Convert to the appropriate numeric type for ForwardDiff compatibility
				if val isa Number
					push!(obs_deriv_vals, T(val))
				else
					# If still symbolic, substitution was incomplete - this is a bug
					# Print debugging info to help diagnose
					dict_keys = collect(keys(evaluated_subst_dict))
					error("Incomplete symbolic substitution in multipoint_numerical_jacobian:\n" *
						  "  Expression: $(DD.obs_rhs[i][j])\n" *
						  "  After substitution: $(substituted)\n" *
						  "  Result type: $(typeof(val))\n" *
						  "  obs_rhs index: i=$i, j=$j\n" *
						  "  Number of derivative levels in states_lhs: $(length(DD.states_lhs))\n" *
						  "  Number of derivative levels in obs_rhs: $(length(DD.obs_rhs))\n" *
						  "  Dict keys (first 20): $(dict_keys[1:min(20, length(dict_keys))])")
				end
			end
		end
		return obs_deriv_vals
	end

	full_values = collect(values(param_dict))
	for k in eachindex(ic_dict_vector)
		append!(full_values, collect(values(ic_dict_vector[k])))
	end



	matrix = ForwardDiff.jacobian(f, full_values)
	matrix_float = map(x -> Float64(Symbolics.value(x)), matrix)
	return matrix_float, DD
end

"""
	multipoint_deriv_level_view(evaluated_jac, deriv_level, num_obs, max_num_points, deriv_count, num_points_used)

Create a view of the Jacobian matrix for specific derivative levels and points.

# Arguments
- `evaluated_jac`: Evaluated Jacobian matrix
- `deriv_level`: Dictionary of derivative levels for each observable
- `num_obs`: Number of observables
- `max_num_points`: Maximum number of points
- `deriv_count`: Total number of derivatives
- `num_points_used`: Number of points actually used

# Returns
- View of the Jacobian matrix
"""
function multipoint_deriv_level_view(evaluated_jac, deriv_level, num_obs, max_num_points, deriv_count, num_points_used)
	function linear_index(which_obs, this_deriv_level, this_point)
		return this_deriv_level * num_obs + which_obs + (this_point - 1) * num_obs * (deriv_count + 1)
	end
	view_array = []
	for k in 1:num_points_used
		for (which_observable, max_deriv_level_this) in deriv_level
			for j in 0:max_deriv_level_this
				push!(view_array, linear_index(which_observable, j, k))
			end
		end
	end
	return view(evaluated_jac, view_array, :)
end

"""
	multipoint_local_identifiability_analysis(
		model::ModelingToolkit.System,
		measured_quantities::Vector{ModelingToolkit.Equation},
		max_num_points::Int,
		reltol::Float64 = 1e-12,
		abstol::Float64 = 1e-12
	) -> Tuple{Dict{Int,Int}, Dict, Vector{Num}, DerivativeData}

Performs local identifiability analysis at multiple points.

# Arguments
- `model::ModelingToolkit.System`: The ODE system
- `measured_quantities::Vector{ModelingToolkit.Equation}`: Measured quantities
- `max_num_points::Int`: Maximum number of points to use
- `reltol::Float64`: Relative tolerance (default: 1e-12)
- `abstol::Float64`: Absolute tolerance (default: 1e-12)

# Returns
- Tuple containing:
  1. Dictionary mapping observables to their required derivative levels
  2. Dictionary of unidentifiable parameters and their values
  3. List of identifiable variables
  4. DerivativeData object containing all computed derivatives
"""
function multipoint_local_identifiability_analysis(
	model::ModelingToolkit.AbstractSystem,
	measured_quantities,
	max_num_points::Int,
	reltol::Float64 = 1e-12,
	abstol::Float64 = 1e-12,
)::Tuple{Dict, Dict, Vector, DerivativeData}
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	varlist = Vector{Num}(vcat(model_ps, model_states))

	#println("DEBUG [multipoint_local_identifiability_analysis]: Starting analysis with ", max_num_points, " points")

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)

	# UNTESTED FIX: Use OrderedDict to ensure consistent ordering with varlist for Jacobian columns
	# This change was made to address potential Dict ordering issues in the Jacobian construction
	# but has NOT been verified to fix the k7=0 issue in biohydrogenation
	# TODO: Test if this actually improves parameter estimation accuracy
	parameter_values = OrderedDict{Num, Float64}()
	for p in ModelingToolkit.parameters(model)
		parameter_values[p] = rand(Float64)
	end

	points_ics = []
	test_points = []
	ordered_test_points = []

	for i in 1:max_num_points
		# UNTESTED FIX: Use OrderedDict for initial conditions too
		# See comment above - this is part of the same untested fix
		initial_conditions = OrderedDict{Num, Float64}()
		for s in ModelingToolkit.unknowns(model)
			initial_conditions[s] = rand(Float64)
		end

		ordered_test_point = OrderedDict{Num, Float64}()
		for i in model_ps
			ordered_test_point[i] = parameter_values[i]
		end
		for i in model_states
			ordered_test_point[i] = initial_conditions[i]
		end

		# test_point now uses the ordered version
		test_point = ordered_test_point

		push!(points_ics, deepcopy(initial_conditions))
		push!(test_points, deepcopy(test_point))
		push!(ordered_test_points, deepcopy(ordered_test_point))
	end

	# Determine derivative order 'n'
	# EXPERIMENTAL FIX: Match PE.jl's derivative order formula to handle biohydrogenation correctly
	# Original heuristic: n = Int64(ceil((states_count + ps_count) / length(measured_quantities)) + 2)
	# PE.jl formula: diff_order = num_parameters + 1 where num_parameters = params + states
	# Using PE's formula ensures sufficient equations for zero-dimensional polynomial system
	n_pe_formula = states_count + ps_count + 1
	n_heuristic = Int64(ceil((states_count + ps_count) / length(measured_quantities)) + 2)
	n = max(n_pe_formula, n_heuristic, 3)  # Use maximum of both approaches
	deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
	unident_dict = Dict()

	jac = nothing
	evaluated_jac = nothing
	DD = nothing
	unident_set = Set{Num}()

	all_identified = false
	while (!all_identified)

		temp = ordered_test_points[1]

		(evaluated_jac, DD) = (multipoint_numerical_jacobian(model, measured_quantities, n, max_num_points, unident_dict, varlist,
			parameter_values, points_ics, temp))

		# Cap n to actual derivative levels computed (may be less than requested if coefficients overflowed)
		n = length(DD.obs_rhs) - 1
		deriv_level = Dict([p => n for p in 1:length(measured_quantities)])

		# Apply matrix equilibration for numerical stability in nullspace computation
		evaluated_jac = equilibrate_jacobian(evaluated_jac)

		ns = nullspace(evaluated_jac)

		if (!isempty(ns))
			candidate_plugins_for_unidentified = OrderedDict()
			for i in eachindex(varlist)
				ns_norm = norm(ns[i, :])
				if (!isapprox(ns_norm, 0.0, atol = abstol))
					candidate_plugins_for_unidentified[varlist[i]] = test_points[1][varlist[i]]
					push!(unident_set, varlist[i])
				end
			end
			if (!isempty(candidate_plugins_for_unidentified))
				p = first(candidate_plugins_for_unidentified)
				deleteat!(varlist, findall(x -> isequal(x, p.first), varlist))
				for k in eachindex(points_ics)
					delete!(points_ics[k], p.first)
					delete!(ordered_test_points[k], p.first)
					delete!(parameter_values, p.first)
				end
				unident_dict[p.first] = p.second
			else
				all_identified = true
			end
		else
			all_identified = true
		end
	end

	max_rank = rank(evaluated_jac, rtol = reltol)
	maxn = n

	while (n > 0)
		n = n - 1
		deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
		reduced_evaluated_jac = multipoint_deriv_level_view(evaluated_jac, deriv_level, length(measured_quantities), max_num_points, maxn, max_num_points)
		r = rank(reduced_evaluated_jac, rtol = reltol)
		if (r < max_rank)
			n = n + 1
			deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
			break
		end
	end

	keep_looking = true
	while (keep_looking)
		improvement_found = false
		sorting = collect(deriv_level)
		sorting = sort(sorting, by = (x -> x[2]), rev = true)
		for i in keys(deriv_level)
			if (deriv_level[i] > 0)
				deriv_level[i] = deriv_level[i] - 1
				reduced_evaluated_jac = multipoint_deriv_level_view(evaluated_jac, deriv_level, length(measured_quantities), max_num_points, maxn, max_num_points)

				r = rank(reduced_evaluated_jac, rtol = reltol)
				if (r < max_rank)
					deriv_level[i] = deriv_level[i] + 1
				else
					improvement_found = true
					break
				end
			else
				temp = pop!(deriv_level, i)
				reduced_evaluated_jac = multipoint_deriv_level_view(evaluated_jac, deriv_level, length(measured_quantities), max_num_points, maxn, max_num_points)

				r = rank(reduced_evaluated_jac, rtol = reltol)
				if (r < max_rank)
					deriv_level[i] = temp
				else
					improvement_found = true
					break
				end
			end
		end
		keep_looking = improvement_found
	end

	DD.all_unidentifiable = unident_set
	return (deriv_level, unident_dict, varlist, DD)
end







"""
	calculate_observable_derivatives(equations, measured_quantities, nderivs=5)

Calculate symbolic derivatives of observables up to the specified order using ModelingToolkit.
Returns the expanded measured quantities with derivatives and the derivative variables.
"""
function calculate_observable_derivatives(equations, measured_quantities, nderivs = 5)
	# Create equation dictionary for substitution
	equation_dict = Dict(eq.lhs => eq.rhs for eq in equations)

	n_observables = length(measured_quantities)

	# Create symbolic variables for derivatives
	ObservableDerivatives = Symbolics.variables(:d_obs, 1:n_observables, 1:nderivs)

	# Initialize vector to store derivative equations
	SymbolicDerivs = Vector{Vector{Equation}}(undef, nderivs)

	# Calculate first derivatives
	SymbolicDerivs[1] = [ObservableDerivatives[i, 1] ~ Symbolics.substitute(expand_derivatives(D(measured_quantities[i].rhs)), equation_dict) for i in 1:n_observables]

	# Calculate higher order derivatives
	for j in 2:nderivs
		SymbolicDerivs[j] = [ObservableDerivatives[i, j] ~ Symbolics.substitute(expand_derivatives(D(SymbolicDerivs[j-1][i].rhs)), equation_dict) for i in 1:n_observables]
	end

	# Create new measured quantities with derivatives
	expanded_measured_quantities = copy(measured_quantities)
	append!(expanded_measured_quantities, vcat(SymbolicDerivs...))

	return expanded_measured_quantities, ObservableDerivatives
end



"""
	construct_equation_system(model::ModelingToolkit.System, measured_quantities_in, data_sample,
							deriv_level, unident_dict, varlist, DD; interpolator, time_index_set = nothing, return_parameterized_system = false)

Construct an equation system for parameter estimation.

# Arguments
- `model::ModelingToolkit.System`: The ODE system
- `measured_quantities_in`: Input measured quantities
- `data_sample`: Sample data
- `deriv_level`: Dictionary of derivative levels
- `unident_dict`: Dictionary of unidentifiable variables
- `varlist`: List of variables
- `DD`: DerivativeData object
- `time_index_set`: Set of time indices (optional)
- `return_parameterized_system`: Whether to return a parameterized system (optional, default: false)

# Returns
- Tuple containing the target equations and variable list
"""
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
			sol = ModelingToolkit.solve(local_prob, AutoVern9(Rodas4P()), abstol = 1e-14, reltol = 1e-14, saveat = t_vector)
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

"""
	lookup_value(var, var_search, soln_index::Int, 
				good_udict::Dict, trivial_dict::Dict, 
				final_varlist::Vector, trimmed_varlist::Vector, 
				solns::Vector) -> Float64

Look up a variable's value from various dictionaries and solution vectors.
This is a helper function for parameter estimation.

# Arguments
- `var`: Original variable to look up (Num or SymbolicUtils.BasicSymbolic{Real})
- `var_search`: Symbolic variable to search for
- `soln_index::Int`: Index in the solutions array
- `good_udict::Dict`: Dictionary of unidentifiable parameters
- `trivial_dict::Dict`: Dictionary of trivially determined values
- `final_varlist::Vector`: Full list of variables
- `trimmed_varlist::Vector`: Reduced list of variables
- `solns::Vector`: Solutions array

# Returns
- `Float64`: Value of the variable
"""
function lookup_value(var, var_search, soln_index::Int,
	good_udict::Dict, trivial_dict::Dict,
	final_varlist::Vector, trimmed_varlist::Vector,
	solns::Vector)::Float64
	# First check if it's in the unidentifiable dictionary
	if var in keys(good_udict)
		return Float64(good_udict[var])
	end

	# Then check if it's in the trivial dictionary
	if var_search in keys(trivial_dict)
		return Float64(trivial_dict[var_search])
	end

	# Finally, look it up in the solution vectors
	index = findfirst(isequal(var_search), final_varlist)
	if isnothing(index)
		index = findfirst(isequal(var_search), trimmed_varlist)
	end

	# Heuristic fallback: map model-style names to SI template names
	if isnothing(index)
		# Convert x(t) -> x_0, k5 -> k5_0, xˍt -> x_1, xˍtt -> x_2, etc.
		try
			# Unwrap Num or other wrappers to get the core symbol/expression
			core = try
				Symbolics.value(var_search)
			catch e
				@debug "Symbolics.value unwrap failed, using raw variable" exception = e
				var_search
			end
			name_str = string(core)

			# Strip special tags if present:
			# - parameter tag: _tp<name>_
			# - timepoint tag: _t<idx>_<name>_
			while true
				m = match(r"^_tp(.+)_$", name_str)
				if !isnothing(m)
					name_str = m.captures[1]
					continue
				end
				m2 = match(r"^_t\d+_(.+)_$", name_str)
				if !isnothing(m2)
					name_str = m2.captures[1]
					continue
				end
				break
			end

			# Remove trailing _t token introduced by tagging x(t) -> x_t
			if endswith(name_str, "_t")
				name_str = name_str[1:(end-2)]
			end

			# Strip (t)
			if endswith(name_str, "(t)")
				name_str = name_str[1:(end-3)]
			end
			# Count occurrences of the derivative marker "ˍt"
			deriv_count = 0
			while occursin("ˍt", name_str)
				name_str = replace(name_str, "ˍt" => "")
				deriv_count += 1
			end
			# If already has a _n suffix, keep it; otherwise append _n (parameters get _0)
			has_suffix = occursin(r"_[0-9]+$", name_str)
			suffix = has_suffix ? "" : string("_", deriv_count)
			fallback_sym = Symbolics.variable(Symbol(name_str * suffix))
			fallback_str = string(fallback_sym)

			index = findfirst(isequal(fallback_sym), final_varlist)
			if isnothing(index)
				index = findfirst(isequal(fallback_sym), trimmed_varlist)
			end

			# Final string-based search as last resort
			if isnothing(index)
				idx_str = findfirst(i -> string(final_varlist[i]) == fallback_str, eachindex(final_varlist))
				if !isnothing(idx_str)
					index = idx_str
				else
					idx_str = findfirst(i -> string(trimmed_varlist[i]) == fallback_str, eachindex(trimmed_varlist))
					if !isnothing(idx_str)
						index = idx_str
					end
				end
			end

			# Extra base-name fallback: prefer `_0`, then any `_n`
			if isnothing(index)
				base_name = has_suffix ? replace(name_str, r"_[0-9]+$" => "") : name_str
				preferred = base_name * "_0"
				idx0 = findfirst(i -> string(final_varlist[i]) == preferred, eachindex(final_varlist))
				if isnothing(idx0)
					idx0 = findfirst(i -> string(trimmed_varlist[i]) == preferred, eachindex(trimmed_varlist))
				end
				if !isnothing(idx0)
					index = idx0
				else
					idx_any = findfirst(i -> startswith(string(final_varlist[i]), base_name * "_"), eachindex(final_varlist))
					if isnothing(idx_any)
						idx_any = findfirst(i -> startswith(string(trimmed_varlist[i]), base_name * "_"), eachindex(trimmed_varlist))
					end
					if !isnothing(idx_any)
						index = idx_any
					end
				end
			end
		catch e
			@debug "Variable index fallback lookup failed" exception = e
		end
	end

	# quiet: remove verbose debug prints

	# Return the real part of the solution as a Float64
	return Float64(real(solns[soln_index][index]))
end

# New helper function to evaluate a polynomial system by substituting exact state and parameter values
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

"""
	PolishContext

Holds all invariant data needed for polishing solutions. Built once per problem,
reused across all polish/optimization runs. This avoids redundant calls to
`complete()`, `build_function()`, and `ODEProblem()` construction.

# Fields
- `unknown_syms`: System state variable symbols (MTK ordering)
- `param_syms`: System parameter symbols (MTK ordering)
- `n_ic`: Number of initial conditions (states)
- `n_param`: Number of parameters
- `new_model`: Completed MTK system (from `complete()`)
- `obs_funcs`: Compiled observable functions (one per measured quantity)
- `data_targets`: Vector of data vectors for each observable
- `t_vector`: Time points from data sample
- `tspan`: ODE integration time span
- `solver`: ODE solver instance
- `abstol`: Absolute tolerance for ODE solver
- `reltol`: Relative tolerance for ODE solver
- `adtype`: AD backend for Optimization.jl
- `optf`: Pre-built OptimizationFunction (loss closure + AD)
- `base_ode_prob`: Template ODEProblem for `remake` inside loss
- `state_syms_out`: User-facing state symbol ordering (from PEP.ic)
- `param_syms_out`: User-facing parameter symbol ordering (from PEP.p_true)
- `state_index`: Map from state symbol → index in unknown_syms
- `param_index`: Map from param symbol → index in param_syms
- `lb`: Optional lower bounds
- `ub`: Optional upper bounds
- `polish_ode_maxiters`: ODE solver iteration cap inside loss function (fails fast on hopeless regions)
"""
struct PolishContext
	unknown_syms::Vector
	param_syms::Vector
	n_ic::Int
	n_param::Int
	new_model::Any
	obs_funcs::Vector{Function}
	data_targets::Vector{Vector{Float64}}
	t_vector::Vector{Float64}
	tspan::Tuple{Float64, Float64}
	solver::Any
	abstol::Float64
	reltol::Float64
	adtype::Any
	optf::Optimization.OptimizationFunction
	base_ode_prob::Any
	state_syms_out::Vector
	param_syms_out::Vector
	state_index::Dict
	param_index::Dict
	lb::Union{Nothing, Vector{Float64}}
	ub::Union{Nothing, Vector{Float64}}
	polish_ode_maxiters::Int
end

"""
	_build_polish_context(PEP; opts) -> PolishContext

Perform all expensive one-time setup for polishing: model completion, observable
compilation, base ODEProblem construction, and OptimizationFunction assembly.
Call this once, then pass the result to `_polish_single_from_context` or
`_polish_batch_from_context` for each solution.
"""
function _build_polish_context(
	PEP::ParameterEstimationProblem;
	opts::EstimationOptions = EstimationOptions(),
)
	# Stable variable ordering from the system
	unknown_syms = ModelingToolkit.unknowns(PEP.model.system)
	param_syms = ModelingToolkit.parameters(PEP.model.system)
	n_ic = length(unknown_syms)
	n_param = length(param_syms)
	p_size = n_ic + n_param

	# Complete model once (not 28× per polish run)
	new_model = complete(PEP.model.system)
	t_vector = Float64.(PEP.data_sample["t"])
	tspan = (t_vector[1], t_vector[end])

	# Compile observable functions once (not 28× per polish run)
	obs_funcs = Function[
		let f_raw = ModelingToolkit.build_function(eq.rhs, unknown_syms, param_syms; expression = Val(false))
			f_fun = isa(f_raw, Tuple) ? f_raw[1] : f_raw
			(u::AbstractVector{<:Real}, p::AbstractVector{<:Real}) -> f_fun(u, p)
		end for eq in PEP.measured_quantities
	]
	data_targets = Vector{Float64}[Float64.(PEP.data_sample[eq.rhs]) for eq in PEP.measured_quantities]

	# Solver and tolerances
	solver = PEP.solver
	abstol = opts.abstol
	reltol = opts.reltol
	adtype = get_ad_backend(opts.opt_ad_backend)

	# Build base ODEProblem once — remake inside loss will swap u0/p values
	u0_default = Dict(unknown_syms .=> zeros(n_ic))
	p_default = Dict(param_syms .=> ones(n_param))
	base_ode_prob = ODEProblem(new_model, merge(u0_default, p_default), tspan)

	# Bounds: use user-specified if valid, otherwise auto-compute from data scale.
	# Note: only BFGS/LBFGS support Fminbox bounds wrapping; Newton-family optimizers
	# silently ignore bounds in _polish_single_from_context.
	lb = nothing
	ub = nothing
	if !isnothing(opts.opt_lb) && !isnothing(opts.opt_ub) &&
	   length(opts.opt_lb) == p_size && length(opts.opt_ub) == p_size
		lb = Float64.(opts.opt_lb)
		ub = Float64.(opts.opt_ub)
	else
		lb_auto, ub_auto = compute_default_bounds(PEP)
		lb = lb_auto
		ub = ub_auto
	end

	# ODE solver iteration cap — fail fast on hopeless parameter regions
	ode_maxiters = opts.polish_ode_maxiters

	# Loss closure capturing all invariants — uses remake for efficiency
	function loss(p_all)
		ic_guess = @view p_all[1:n_ic]
		param_guess = @view p_all[(n_ic+1):end]

		prob_opt = remake(base_ode_prob; u0 = Dict(unknown_syms .=> ic_guess), p = Dict(param_syms .=> param_guess), build_initializeprob = false)
		sol_opt = try
			ModelingToolkit.solve(prob_opt, solver; saveat = t_vector, abstol = abstol, reltol = reltol, maxiters = ode_maxiters)
		catch e
			@warn "ODE solver failed during polish" exception = (e, catch_backtrace())
			return Inf
		end
		(sol_opt.retcode != ReturnCode.Success) && (return Inf)

		total_error = zero(eltype(p_all))
		for (j, f) in enumerate(obs_funcs)
			data_true = data_targets[j]
			local_err = zero(eltype(p_all))
			@inbounds for i in eachindex(t_vector)
				val = f(sol_opt.u[i], param_guess)
				diff = val - data_true[i]
				local_err += diff * diff
			end
			total_error += local_err
		end
		return total_error
	end

	optf = Optimization.OptimizationFunction((x, _) -> loss(x), adtype)

	# User-facing symbol ordering for result construction
	state_syms_out = collect(keys(PEP.ic))
	param_syms_out = collect(keys(PEP.p_true))
	state_index = Dict(s => i for (i, s) in enumerate(unknown_syms))
	param_index = Dict(p => i for (i, p) in enumerate(param_syms))

	return PolishContext(
		unknown_syms, param_syms, n_ic, n_param,
		new_model, obs_funcs, data_targets,
		t_vector, tspan, solver, abstol, reltol, adtype, optf,
		base_ode_prob,
		state_syms_out, param_syms_out, state_index, param_index,
		lb, ub,
		ode_maxiters,
	)
end

"""
	_polish_single_from_context(ctx, p0; optimizer, maxiters, maxtime, divergence_factor, stagnation_window) -> (ParameterEstimationResult, opt_result)

Polish a single solution using a pre-built PolishContext. Only constructs
the lightweight OptimizationProblem (wrapping p0) and solves.

Safeguard callbacks automatically stop optimization when:
- Wall-clock time exceeds `maxtime` seconds
- Loss diverges beyond `initial_loss * divergence_factor`
- No improvement seen in `stagnation_window` consecutive iterations
- Loss becomes non-finite (NaN/Inf)

The best solution seen during optimization is tracked; if the optimizer
wanders past a good minimum, the best iterate is recovered.
"""
function _polish_single_from_context(
	ctx::PolishContext,
	p0::AbstractVector{<:Real};
	optimizer = BFGS(),
	maxiters::Int = 200000,
	maxtime::Float64 = 300.0,
	divergence_factor::Float64 = 10.0,
	stagnation_window::Int = 50,
)
	# Only BFGS/LBFGS support Fminbox bounds wrapping; Newton-family optimizers
	# (NewtonTrustRegion, LevenbergMarquardt, GaussNewton) don't.
	use_bounds = !isnothing(ctx.lb) && !isnothing(ctx.ub) &&
		optimizer isa Union{Optim.BFGS, Optim.LBFGS}

	p0_clamped = use_bounds ? clamp.(p0, ctx.lb, ctx.ub) : Float64.(p0)

	optprob = if use_bounds
		Optimization.OptimizationProblem(ctx.optf, p0_clamped; lb = ctx.lb, ub = ctx.ub)
	else
		Optimization.OptimizationProblem(ctx.optf, p0_clamped)
	end

	# Evaluate initial loss for divergence baseline
	initial_loss = try
		ctx.optf.f(p0_clamped, nothing)
	catch
		Inf
	end

	# Safeguard state — each Threads.@spawn gets its own closure, so Refs are thread-safe
	opt_verbose = get(ENV, "ODEPE_OPT_VERBOSE", "false") == "true"
	iter_count = Ref(0)
	best_loss = Ref(isfinite(initial_loss) ? initial_loss : Inf)
	best_p = Ref(copy(p0_clamped))
	iters_since_improvement = Ref(0)
	start_time = time()
	last_log_time = Ref(start_time)
	stop_reason = Ref("")

	callback = (x, l) -> begin
		iter_count[] += 1

		# Track best solution
		if isfinite(l) && l < best_loss[]
			best_loss[] = l
			best_p[] = copy(x.u)
			iters_since_improvement[] = 0
		else
			iters_since_improvement[] += 1
		end

		# Safeguard checks
		if !isfinite(l)
			stop_reason[] = "non-finite loss"
			return true
		end

		elapsed = time() - start_time
		if elapsed > maxtime
			stop_reason[] = "wall-clock timeout ($(round(elapsed; digits=1))s > $(maxtime)s)"
			return true
		end

		if isfinite(initial_loss) && initial_loss > 0 && l > initial_loss * divergence_factor
			stop_reason[] = "divergence (loss $(round(l; sigdigits=3)) > $(round(initial_loss * divergence_factor; sigdigits=3)))"
			return true
		end

		if iters_since_improvement[] >= stagnation_window
			stop_reason[] = "stagnation (no improvement in $(stagnation_window) iters)"
			return true
		end

		# Verbose logging (gated on env var)
		if opt_verbose
			now = time()
			dt = now - last_log_time[]
			last_log_time[] = now
			if (iter_count[] == 1) || (l <= best_loss[]) || (iter_count[] % 50 == 0)
				println("[polish]  iter=$(iter_count[]) loss=$(l) best=$(round(best_loss[]; sigdigits=6)) dt=$(round(dt; digits=3))s elapsed=$(round(elapsed; digits=1))s")
			end
		end

		false
	end

	if opt_verbose
		println("[polish] Starting optimization with $(typeof(optimizer))")
		println("[polish]  n_states=$(ctx.n_ic), n_params=$(ctx.n_param), data_points=$(length(ctx.t_vector))")
		println("[polish]  solver=$(typeof(ctx.solver)), abstol=$(ctx.abstol), reltol=$(ctx.reltol), maxiters=$(maxiters)")
		println("[polish]  safeguards: maxtime=$(maxtime)s, divergence=$(divergence_factor)x, stagnation=$(stagnation_window) iters")
		println("[polish]  initial_loss=$(initial_loss)")
	end

	result = Optimization.solve(optprob, optimizer; maxiters = maxiters, callback = callback)

	if opt_verbose && !isempty(stop_reason[])
		println("[polish]  early stop: $(stop_reason[]) after $(iter_count[]) iters")
	end

	# Recover best solution if optimizer wandered past the minimum
	p_opt = if isfinite(best_loss[]) && best_loss[] < result.objective
		if opt_verbose
			println("[polish]  recovering best iterate: loss $(round(best_loss[]; sigdigits=6)) < final $(round(result.objective; sigdigits=6))")
		end
		best_p[]
	else
		result.u
	end
	ic_opt = p_opt[1:ctx.n_ic]
	param_opt = p_opt[(ctx.n_ic+1):end]
	prob_final = remake(ctx.base_ode_prob;
		u0 = Dict(ctx.unknown_syms .=> ic_opt),
		p = Dict(ctx.param_syms .=> param_opt),
		build_initializeprob = false,
	)
	sol_final = ModelingToolkit.solve(prob_final, ctx.solver; saveat = ctx.t_vector, abstol = ctx.abstol, reltol = ctx.reltol)

	# Map back to user-facing ordering
	states_out = OrderedDict(s => ic_opt[ctx.state_index[s]] for s in ctx.state_syms_out if haskey(ctx.state_index, s))
	params_out = OrderedDict(p => param_opt[ctx.param_index[p]] for p in ctx.param_syms_out if haskey(ctx.param_index, p))

	# Use best_loss if we recovered the best iterate, otherwise use optimizer's final value
	final_obj = (isfinite(best_loss[]) && best_loss[] < result.objective) ? best_loss[] : result.objective

	final_result = ParameterEstimationResult(
		params_out,
		states_out,
		ctx.t_vector[1],
		final_obj,
		nothing,
		length(ctx.t_vector),
		ctx.t_vector[1],
		OrderedDict{Num, Float64}(),
		Set{Num}(),
		sol_final,
	)
	final_result.provenance = ResultProvenance(
		primary_method = :direct_opt,
		post_polish_error = final_obj,
	)
	sync_result_contract!(final_result)
	return final_result, result
end

"""
	_polish_batch_from_context(ctx, candidates; opts) -> Vector{ParameterEstimationResult}

Polish all candidate solutions using a shared PolishContext. For each candidate,
extracts the p0 vector, calls `_polish_single_from_context`, and returns the
combined list of original + polished results.
"""
function _polish_batch_from_context(
	ctx::PolishContext,
	candidates::AbstractVector;
	opts::EstimationOptions = EstimationOptions(),
)
	optimizer_type = get_polish_optimizer(opts.polish_method)
	optimizer = optimizer_type()
	maxiters = opts.polish_maxiters
	n_candidates = length(candidates)

	# --- Pre-polish clustering: deduplicate candidates that clamp to the same point ---
	# Build clamped p0 vectors for all candidates
	use_bounds = !isnothing(ctx.lb) && !isnothing(ctx.ub) &&
		optimizer isa Union{Optim.BFGS, Optim.LBFGS}

	clamped_p0s = Vector{Vector{Float64}}(undef, n_candidates)
	for (i, candidate) in enumerate(candidates)
		ic_vec = [candidate.states[s] for s in ctx.unknown_syms]
		param_vec = [candidate.parameters[p] for p in ctx.param_syms]
		p0 = vcat(ic_vec, param_vec)
		clamped_p0s[i] = use_bounds ? clamp.(p0, ctx.lb, ctx.ub) : Float64.(p0)
	end

	# Cluster by max relative component-wise distance (same metric as solution_distance)
	cluster_threshold = 0.001  # 0.1% relative difference
	# cluster_rep[k] = index of representative candidate for cluster k
	cluster_reps = Int[]
	# candidate_cluster[i] = which cluster candidate i belongs to
	candidate_cluster = zeros(Int, n_candidates)

	for i in 1:n_candidates
		merged = false
		for (k, rep) in enumerate(cluster_reps)
			# Max relative component-wise distance
			dist = zero(Float64)
			for j in eachindex(clamped_p0s[i])
				a = clamped_p0s[i][j]
				b = clamped_p0s[rep][j]
				scale = max(abs(a), abs(b), 1.0)
				dist = max(dist, abs(a - b) / scale)
			end
			if dist <= cluster_threshold
				candidate_cluster[i] = k
				# Pick the candidate with better (lower) error as representative
				err_i = isnothing(candidates[i].err) ? Inf : candidates[i].err
				err_rep = isnothing(candidates[rep].err) ? Inf : candidates[rep].err
				if err_i < err_rep
					cluster_reps[k] = i
				end
				merged = true
				break
			end
		end
		if !merged
			push!(cluster_reps, i)
			candidate_cluster[i] = length(cluster_reps)
		end
	end

	n_unique = length(cluster_reps)
	if !opts.nooutput && n_unique < n_candidates
		println("Deduplicated $n_candidates candidates → $n_unique unique starting points for polish")
	end

	if !opts.nooutput
		n_threads = Threads.nthreads()
		println("Polishing $n_unique solutions (maxiters=$maxiters, threads=$n_threads)...")
	end

	polish_start = time()
	print_lock = ReentrantLock()

	# Only polish the cluster representatives
	tasks = map(enumerate(cluster_reps)) do (task_idx, rep_idx)
		Threads.@spawn begin
			t0 = time()
			candidate = candidates[rep_idx]
			local_results = ParameterEstimationResult[]
			try
				p0 = clamped_p0s[rep_idx]

				polished_result, opt_result = _polish_single_from_context(
					ctx, p0;
					optimizer = optimizer,
					maxiters = maxiters,
					maxtime = opts.polish_maxtime,
					divergence_factor = opts.polish_divergence_factor,
					stagnation_window = opts.polish_stagnation_window,
				)
				dt = time() - t0
				n_iters = try; opt_result.original.iterations; catch; -1; end
				polished_result.unident_dict = deepcopy(candidate.unident_dict)
				polished_result.all_unidentifiable = copy(candidate.all_unidentifiable)
				polished_result.provenance = copy_provenance(
					candidate.provenance;
					pre_polish_error = candidate.err,
					post_polish_error = polished_result.err,
					polish_applied = true,
				)
				set_result_lineage!(
					polished_result;
					primary_method = candidate.provenance.primary_method,
					interpolator_source = candidate.provenance.interpolator_source,
					rescue_path = candidate.provenance.rescue_path,
					source_shooting_index = candidate.provenance.source_shooting_index,
					source_candidate_index = candidate.provenance.source_candidate_index,
					pre_polish_error = candidate.err,
					post_polish_error = polished_result.err,
					polish_applied = true,
					notes = candidate.provenance.notes,
				)
				if !opts.nooutput
					err_before = isnothing(candidate.err) ? Inf : candidate.err
					err_after = isnothing(polished_result.err) ? Inf : polished_result.err
					lock(print_lock) do
						println("  Polish $task_idx/$n_unique (candidate $rep_idx): $(round(dt; digits=1))s, $(n_iters) iters, err $(round(err_before; sigdigits=3)) → $(round(err_after; sigdigits=3))")
					end
				end

				push!(local_results, polished_result)
			catch e
				dt = time() - t0
				@warn "Failed to polish solution $rep_idx ($(round(dt; digits=1))s): $e"
			end
			local_results
		end
	end

	# Collect results: all original candidates (unpolished baselines) + polished results
	polished_results = ParameterEstimationResult[]

	# First, include all original candidates as unpolished baselines
	for candidate in candidates
		push!(polished_results, candidate)
	end

	# Then append polished results from cluster representatives
	for task in tasks
		append!(polished_results, fetch(task))
	end

	if !opts.nooutput
		println("  Polish total: $(round(time() - polish_start; digits=1))s for $n_unique unique solutions (from $n_candidates candidates)")
	end
	return polished_results
end

"""
	direct_optimization_parameter_estimation(PEP; opts) -> Vector{ParameterEstimationResult}

Perform parameter estimation via direct BFGS optimization from a random initial guess.
Uses the shared PolishContext infrastructure for consistency with the polish path.
"""
function direct_optimization_parameter_estimation(PEP::ParameterEstimationProblem;
	opts::EstimationOptions = EstimationOptions())
	ctx = _build_polish_context(PEP; opts = opts)
	p_size = ctx.n_ic + ctx.n_param

	# Generate random initial guess, respecting bounds if set
	p0 = if !isnothing(ctx.lb) && !isnothing(ctx.ub)
		ctx.lb .+ rand(p_size) .* (ctx.ub .- ctx.lb)
	else
		rand(p_size)
	end

	if !opts.nooutput
		println("Starting direct optimization with initial guess: ", p0)
	end

	final_result, opt_result = _polish_single_from_context(
		ctx, p0;
		optimizer = LBFGS(),
		maxiters = opts.opt_maxiters,
		maxtime = opts.polish_maxtime,
		divergence_factor = opts.polish_divergence_factor,
		stagnation_window = opts.polish_stagnation_window,
	)

	if !opts.nooutput
		println("Direct optimization finished with final loss: ", opt_result.objective)
		println("Found solution: ", merge(final_result.states, final_result.parameters))
	end
	final_result.provenance = ResultProvenance(
		primary_method = :direct_opt,
		rescue_path = :none,
		source_candidate_index = 1,
		pre_polish_error = nothing,
		post_polish_error = final_result.err,
		polish_applied = true,
	)
	sync_result_contract!(final_result)

	return [final_result]
end
