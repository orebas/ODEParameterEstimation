# REFACTORING NOTE:
# Several functions have been moved out of this file to improve organization:
# - multipoint_parameter_estimation -> moved to multipoint_estimation.jl
# - multishot_parameter_estimation -> moved to multipoint_estimation.jl
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

		# ITERATIVE PARAMETER FIXING:
		# We fix ONE parameter at a time and re-run full SIAN analysis
		# until the system is determined (equations == variables)
		pre_fixed_params = OrderedDict{Num, Float64}()
		max_fix_iterations = 10
		iteration = 0
		converged = false

		while iteration < max_fix_iterations && !converged
			iteration += 1
			@info "[ITERATIVE-FIX] Iteration $iteration, fixed so far: $(keys(pre_fixed_params))"

			# Run SIAN analysis with current pre-fixed parameters
			template_equations, derivative_dict, unidentifiable, identifiable_funcs = get_si_equation_system(
				ordered_model,
				measured_quantities,
				data_sample;
				DD = good_DD,
				infolevel = diagnostics ? 1 : 0,
				pre_fixed_params = pre_fixed_params,
			)

			si_template = (
				equations = template_equations,
				deriv_dict = derivative_dict,
				unidentifiable = unidentifiable,
				identifiable_funcs = identifiable_funcs,
			)

			# Count equations and variables in the current system
			# Note: We need to count only UNKNOWN variables, not data values (y_i)
			# Data variables are of the form y1_0, y2_0, y3_1, etc.
			n_equations = length(template_equations)
			vars_in_system = OrderedSet{Any}()
			for eq in template_equations
				union!(vars_in_system, Symbolics.get_variables(eq))
			end

			# Filter out data variables - these are known values, not unknowns
			# Data variables can be in different formats:
			#   - Nemo format: y1_0, y2_1 (y followed by digit, underscore, digit)
			#   - Symbolics format: y1(t), y2(t) (y followed by digit and (t))
			#   - Symbolics derivatives: y1ˍt(t), y1ˍtt(t) (with derivative markers)
			unknown_vars = OrderedSet{Any}()
			data_vars = OrderedSet{Any}()
			for v in vars_in_system
				v_name = string(v)
				# Match y1_0, y2_1 (Nemo) OR y1(t), y2(t), y1ˍt(t), y1ˍtt(t) (Symbolics)
				if occursin(r"^y\d+_\d+$", v_name) || occursin(r"^y\d+", v_name) && occursin("(t)", v_name)
					push!(data_vars, v)
				else
					push!(unknown_vars, v)
				end
			end
			n_variables = length(unknown_vars)
			n_data_vars = length(data_vars)

			@info "[ITERATIVE-FIX] System status: $n_equations equations, $n_variables unknowns (+ $n_data_vars data variables)"

			if n_equations == n_variables
				@info "[ITERATIVE-FIX] CONVERGED: Determined system achieved after $iteration iteration(s)"
				converged = true
			elseif n_equations < n_variables
				# Underdetermined (more unknowns than equations) - fix ONE parameter to reduce unknowns
				# This is the typical case: SIAN produces fewer equations than variables
				already_fixed = Set(keys(pre_fixed_params))
				param_to_fix, fix_value = select_one_parameter_to_fix(
					si_template, already_fixed, diagnostics; states = states
				)

				if param_to_fix === nothing
					@warn "[ITERATIVE-FIX] No parameter available to fix, stopping iteration (still underdetermined)"
					break
				end

				@info "[ITERATIVE-FIX] Fixing parameter: $param_to_fix = $fix_value (to reduce unknowns)"
				pre_fixed_params[param_to_fix] = fix_value
				# Loop continues - will re-run SIAN with the new fixed param
			else
				# Overdetermined (more equations than unknowns) - unusual, cannot proceed
				@warn "[ITERATIVE-FIX] Overdetermined system ($n_equations eqs > $n_variables vars), cannot fix by adding parameters"
				break
			end
		end

		if !converged && iteration >= max_fix_iterations
			@warn "[ITERATIVE-FIX] Did not converge after $max_fix_iterations iterations"
		end

		@info "[DEBUG-EQ-COUNT] Final SI template: $(length(si_template.equations)) equations after iterative fixing"
		template_equations = si_template.equations

		# Note: We no longer call handle_unidentifiability here since iterative fixing handles it

		if diagnostics
			println("[DEBUG-SI] Created SI.jl template with $(length(template_equations)) equations")

			# Output the SI.jl polynomial system for debugging
			println("\n[DEBUG-SI] ========== SI.jl POLYNOMIAL SYSTEM ==========")
			println("[DEBUG-SI] Variables in deriv_dict: $(length(si_template.deriv_dict))")
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

"""
	select_one_parameter_to_fix(si_template, already_fixed, diagnostics; states=nothing)

Select ONE unidentifiable parameter to fix based on DOF analysis.
This is used in iterative parameter fixing - we fix one parameter at a time
and re-run the full SIAN analysis after each fix.

# Arguments
- `si_template`: The SI template containing equations, unidentifiable params, identifiable funcs
- `already_fixed`: Set of parameters already fixed in previous iterations
- `diagnostics`: Whether to print debug output
- `states`: Optional state variables (to prefer fixing params over initial conditions)

# Returns
- `(param_to_fix, fix_value)` or `(nothing, nothing)` if no parameter needs fixing
"""
function select_one_parameter_to_fix(si_template, already_fixed::Set, diagnostics; states = nothing)
	unidentifiable_params = si_template.unidentifiable
	identifiable_funcs = si_template.identifiable_funcs

	# Prepare state name hints if provided
	state_base_names = Set{String}()
	if states !== nothing
		for s in states
			name_str = string(s)
			if endswith(name_str, "(t)")
				name_str = name_str[1:(end-3)]
			end
			push!(state_base_names, name_str)
		end
	end

	if isempty(unidentifiable_params)
		if diagnostics
			println("[SELECT-PARAM] No unidentifiable parameters")
		end
		return nothing, nothing
	end

	# Convert identifiable funcs from Nemo to Symbolics
	nemo_to_mtk_map = Dict()
	symbolic_identifiable_funcs = []
	for f in identifiable_funcs
		push!(symbolic_identifiable_funcs, nemo_to_symbolics(f, nemo_to_mtk_map))
	end

	# Prefer fixing MODEL PARAMETERS over state initial conditions
	# Also filter out already-fixed parameters
	unident_params_only = Any[]
	for p in unidentifiable_params
		pstr = string(p)
		# Skip state initial conditions
		if (states !== nothing) && (pstr in state_base_names)
			continue
		end
		# Skip already-fixed parameters
		if pstr in [string(f) for f in already_fixed]
			continue
		end
		push!(unident_params_only, p)
	end

	if isempty(unident_params_only)
		if diagnostics
			println("[SELECT-PARAM] No unfixed unidentifiable parameters remaining")
		end
		return nothing, nothing
	end

	# Build Symbolics variables for parameters (base names, no _0) for Jacobian
	param_syms = [Symbolics.variable(Symbol(string(p))) for p in unident_params_only]

	# Keep only identifiable functions that depend on at least one candidate param
	funcs_filtered = [f for f in symbolic_identifiable_funcs if any(string(v) in Set(string.(unident_params_only)) for v in Symbolics.get_variables(f))]

	# Determine which parameter to fix using DOF analysis via Jacobian rank
	param_to_fix = nothing
	if isempty(funcs_filtered)
		# No identifiable functions involving these params - just fix the first one
		param_to_fix = unident_params_only[1]
		if diagnostics
			println("[SELECT-PARAM] No identifiable funcs for params, selecting first: $param_to_fix")
		end
	else
		J_sym = Symbolics.jacobian(funcs_filtered, param_syms)
		# Gather all variables in funcs to assign generic nonzero numeric values
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

		# The DOF cols are parameters NOT in the pivot set - these are "free" to fix
		cols_ordered = collect(F.p)
		pivot_cols = rnk > 0 ? Set(cols_ordered[1:rnk]) : Set{Int}()
		dof_cols = [j for j in 1:length(param_syms) if !(j in pivot_cols)]

		if !isempty(dof_cols)
			# Pick the first DOF column parameter to fix
			param_to_fix = unident_params_only[dof_cols[1]]
		elseif !isempty(unident_params_only)
			# Fallback: if all params are in pivot cols, still need to fix one
			param_to_fix = unident_params_only[1]
		end

		if diagnostics
			println("[SELECT-PARAM] Jacobian rank: $rnk, DOF cols: $dof_cols")
			println("[SELECT-PARAM] Selected parameter to fix: $param_to_fix")
		end
	end

	if param_to_fix === nothing
		return nothing, nothing
	end

	# Convert Nemo parameter to Symbolics Num for type consistency
	# The param_to_fix may be a Nemo.QQMPolyRingElem from SIAN
	param_to_fix_sym = Symbolics.variable(Symbol(string(param_to_fix)))

	# Return the parameter and the value to fix it to
	fix_value = 1.0
	return param_to_fix_sym, fix_value
end

function handle_unidentifiability(si_template, diagnostics; states = nothing, params = nothing)
	template_equations = si_template.equations
	unidentifiable_params = si_template.unidentifiable
	identifiable_funcs = si_template.identifiable_funcs

	# Use the identifiable functions directly
	# The QR decomposition below (line ~407) will handle any redundancy correctly
	id_funcs_indep_nemo = identifiable_funcs

	# Convert identifiable funcs (independent set) from Nemo to Symbolics for easier processing
	nemo_to_mtk_map = Dict() # We don't have the full map here, so we'll build it as needed
	symbolic_identifiable_funcs = []
	for f in id_funcs_indep_nemo
		push!(symbolic_identifiable_funcs, nemo_to_symbolics(f, nemo_to_mtk_map))
	end

	# Prepare state name hints if provided
	state_base_names = Set{String}()
	if states !== nothing
		for s in states
			name_str = string(s)
			if endswith(name_str, "(t)")
				name_str = name_str[1:(end-3)]
			end
			push!(state_base_names, name_str)
		end
	end

	num_unidentifiable = length(unidentifiable_params)
	if !isempty(unidentifiable_params)
		if diagnostics
			println("[DEBUG-SI] SI.jl found $num_unidentifiable unidentifiable params: $unidentifiable_params")
			println("[DEBUG-SI] Using $(length(symbolic_identifiable_funcs)) independent identifiable functions for DOF analysis")
		end
		# Ensure we enter selection; we will refine the actual number to fix below
		num_to_fix = length(unidentifiable_params)

		if true
			# Prefer fixing MODEL PARAMETERS over state initial conditions.
			# Partition unidentifiable into parameter-like vs state-like using state name hints if available.
			unident_params_only = Any[]
			for p in unidentifiable_params
				pstr = string(p)
				if (states !== nothing) && (pstr in state_base_names)
					continue
				end
				push!(unident_params_only, p)
			end

			# If no parameter remains to fix, return unchanged template
			if isempty(unident_params_only)
				return template_equations, (
					equations = template_equations,
					deriv_dict = si_template.deriv_dict,
					unidentifiable = si_template.unidentifiable,
					identifiable_funcs = si_template.identifiable_funcs,
				)
			end

			# Build Symbolics variables for parameters (base names, no _0) for Jacobian
			param_syms = [Symbolics.variable(Symbol(string(p))) for p in unident_params_only]

			# Keep only identifiable functions that depend on at least one candidate param
			funcs_filtered = [f for f in symbolic_identifiable_funcs if any(string(v) in Set(string.(unident_params_only)) for v in Symbolics.get_variables(f))]

			# Determine number of DOFs to fix via Jacobian rank; fallback to one scaling DOF
			params_to_fix = Any[]
			if isempty(funcs_filtered)
				num_to_fix = min(1, length(unident_params_only))
				params_to_fix = unident_params_only[1:num_to_fix]
			else
				J_sym = Symbolics.jacobian(funcs_filtered, param_syms)
				# Gather all variables in funcs to assign generic nonzero numeric values
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
				num_to_fix = max(length(unident_params_only) - rnk, 0)
				if num_to_fix > 0
					cols_ordered = collect(F.p)
					pivot_cols = Set(cols_ordered[1:rnk])
					dof_cols = [j for j in 1:length(param_syms) if !(j in pivot_cols)]
					for j in dof_cols
						push!(params_to_fix, unident_params_only[j])
						if length(params_to_fix) >= num_to_fix
							break
						end
					end
				end
			end

			if diagnostics
				println("[DEBUG-SI] Independent identifiable funcs used: ", id_funcs_indep_nemo)
				println("[DEBUG-SI] Choosing to fix $(length(params_to_fix)) parameter(s): ", params_to_fix)
			end

			# Apply substitutions for selected parameters (SI format uses _0 suffix)
			if !isempty(params_to_fix)
				fix_dict = Dict()
				for param in params_to_fix
					si_name = string(param) * "_0"
					si_param = Symbolics.variable(Symbol(si_name))
					fix_value = 1.0
					fix_dict[si_param] = fix_value
				end

				if diagnostics
					println("[DEBUG-SI] Applying substitutions to fix parameters: $fix_dict")
				end

				# Create a new template with the substituted equations
				template_equations = Symbolics.substitute.(si_template.equations, Ref(fix_dict))
			end
		end
	end

	# Return the (potentially modified) template_equations and the original si_template
	# We update the equations in the template for consistency
	new_si_template = (
		equations = template_equations,
		deriv_dict = si_template.deriv_dict, # old
		unidentifiable = si_template.unidentifiable, # old
		identifiable_funcs = si_template.identifiable_funcs, # old
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




# multishot_parameter_estimation has been moved to multipoint_estimation.jl



# The implementation has been moved to multipoint_estimation.jl


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

	# Loss closure capturing all invariants — uses remake for efficiency
	function loss(p_all)
		ic_guess = @view p_all[1:n_ic]
		param_guess = @view p_all[(n_ic+1):end]

		prob_opt = remake(base_ode_prob; u0 = Dict(unknown_syms .=> ic_guess), p = Dict(param_syms .=> param_guess))
		sol_opt = try
			ModelingToolkit.solve(prob_opt, solver; saveat = t_vector, abstol = abstol, reltol = reltol)
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
	)
end

"""
	_polish_single_from_context(ctx, p0; optimizer, maxiters) -> (ParameterEstimationResult, opt_result)

Polish a single solution using a pre-built PolishContext. Only constructs
the lightweight OptimizationProblem (wrapping p0) and solves.
"""
function _polish_single_from_context(
	ctx::PolishContext,
	p0::AbstractVector{<:Real};
	optimizer = BFGS(),
	maxiters::Int = 200000,
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

	opt_verbose = get(ENV, "ODEPE_OPT_VERBOSE", "false") == "true"
	result = if opt_verbose
		println("[polish] Starting optimization with $(typeof(optimizer))")
		println("[polish]  n_states=$(ctx.n_ic), n_params=$(ctx.n_param), data_points=$(length(ctx.t_vector))")
		println("[polish]  solver=$(typeof(ctx.solver)), abstol=$(ctx.abstol), reltol=$(ctx.reltol), maxiters=$(maxiters)")
		iter_count = Ref(0)
		best_obj = Ref(Inf)
		last_t = Ref(time())
		callback = (x, l) -> begin
			iter_count[] += 1
			now = time()
			dt = now - last_t[]
			last_t[] = now
			if (iter_count[] == 1) || (l < best_obj[]) || (iter_count[] % 5 == 0)
				best_obj[] = min(best_obj[], l)
				println("[polish]  iter=$(iter_count[]) loss=$(l) dt=$(round(dt; digits=3))s")
			end
			false
		end
		Optimization.solve(optprob, optimizer; maxiters = maxiters, callback = callback)
	else
		Optimization.solve(optprob, optimizer; maxiters = maxiters)
	end

	# Final simulate via remake
	p_opt = result.u
	ic_opt = p_opt[1:ctx.n_ic]
	param_opt = p_opt[(ctx.n_ic+1):end]
	prob_final = remake(ctx.base_ode_prob;
		u0 = Dict(ctx.unknown_syms .=> ic_opt),
		p = Dict(ctx.param_syms .=> param_opt),
	)
	sol_final = ModelingToolkit.solve(prob_final, ctx.solver; saveat = ctx.t_vector, abstol = ctx.abstol, reltol = ctx.reltol)

	# Map back to user-facing ordering
	states_out = OrderedDict(s => ic_opt[ctx.state_index[s]] for s in ctx.state_syms_out if haskey(ctx.state_index, s))
	params_out = OrderedDict(p => param_opt[ctx.param_index[p]] for p in ctx.param_syms_out if haskey(ctx.param_index, p))

	final_result = ParameterEstimationResult(
		params_out,
		states_out,
		ctx.t_vector[1],
		result.objective,
		nothing,
		length(ctx.t_vector),
		ctx.t_vector[1],
		OrderedDict{Num, Float64}(),
		Set{Num}(),
		sol_final,
	)
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

	if !opts.nooutput
		n_threads = Threads.nthreads()
		println("Polishing $n_candidates solutions (maxiters=$maxiters, threads=$n_threads)...")
	end

	polish_start = time()
	print_lock = ReentrantLock()

	# Spawn one task per candidate — each builds a local result vector
	tasks = map(enumerate(candidates)) do (i, candidate)
		Threads.@spawn begin
			t0 = time()
			local_results = ParameterEstimationResult[]
			try
				# Build p0 vector in system order from candidate
				ic_vec = [candidate.states[s] for s in ctx.unknown_syms]
				param_vec = [candidate.parameters[p] for p in ctx.param_syms]
				p0 = vcat(ic_vec, param_vec)

				polished_result, opt_result = _polish_single_from_context(
					ctx, p0; optimizer = optimizer, maxiters = maxiters,
				)
				dt = time() - t0
				n_iters = try; opt_result.original.iterations; catch; -1; end
				if !opts.nooutput
					err_before = isnothing(candidate.err) ? Inf : candidate.err
					err_after = isnothing(polished_result.err) ? Inf : polished_result.err
					lock(print_lock) do
						println("  Polish $i/$n_candidates: $(round(dt; digits=1))s, $(n_iters) iters, err $(round(err_before; sigdigits=3)) → $(round(err_after; sigdigits=3))")
					end
				end

				# Always retain the original candidate and append the polished result
				push!(local_results, candidate)
				push!(local_results, polished_result)
			catch e
				dt = time() - t0
				@warn "Failed to polish solution $i ($(round(dt; digits=1))s): $e"
				push!(local_results, candidate)
			end
			local_results
		end
	end

	# Collect results in original order (preserves deterministic ordering)
	polished_results = ParameterEstimationResult[]
	for task in tasks
		append!(polished_results, fetch(task))
	end

	if !opts.nooutput
		println("  Polish total: $(round(time() - polish_start; digits=1))s for $n_candidates solutions")
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
		ctx, p0; optimizer = LBFGS(), maxiters = opts.opt_maxiters,
	)

	if !opts.nooutput
		println("Direct optimization finished with final loss: ", opt_result.objective)
		println("Found solution: ", merge(final_result.states, final_result.parameters))
	end

	return [final_result]
end


