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

	DD = DerivativeData([], [], [], [], [], [], [], [], Set{Any}())

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

	for i in 1:(max_deriv_level-2)
		push!(DD.states_lhs, expand_derivatives.(D.(DD.states_lhs[end])))
		temp = DD.states_rhs[end]
		temp2 = D.(temp)
		temp3 = deepcopy(temp2)
		temp4 = []
		for j in 1:length(temp3)
			temptemp = expand_derivatives(temp3[j])
			push!(temp4, deepcopy(temptemp))
		end
		push!(DD.states_rhs, temp4)
		push!(DD.states_lhs_cleared, expand_derivatives.(D.(DD.states_lhs_cleared[end])))
		push!(DD.states_rhs_cleared, expand_derivatives.(D.(DD.states_rhs_cleared[end])))
	end

	for i in eachindex(DD.states_rhs), j in eachindex(DD.states_rhs[i])
		DD.states_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_rhs[i][j]))
		DD.states_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_lhs[i][j]))
		DD.states_rhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_rhs_cleared[i][j]))
		DD.states_lhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_lhs_cleared[i][j]))
	end

	for i in 1:(max_deriv_level-1)
		push!(DD.obs_lhs, expand_derivatives.(D.(DD.obs_lhs[end])))
		push!(DD.obs_rhs, expand_derivatives.(D.(DD.obs_rhs[end])))
		push!(DD.obs_lhs_cleared, expand_derivatives.(D.(DD.obs_lhs_cleared[end])))
		push!(DD.obs_rhs_cleared, expand_derivatives.(D.(DD.obs_rhs_cleared[end])))
	end

	for i in eachindex(DD.obs_rhs), j in eachindex(DD.obs_rhs[i])
		DD.obs_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.obs_rhs[i][j]))
		DD.obs_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.obs_lhs[i][j]))
		DD.obs_rhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.obs_rhs_cleared[i][j]))
		DD.obs_lhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.obs_lhs_cleared[i][j]))
	end
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
)::Dict{Any, AbstractInterpolator}
	interpolants = Dict{Any, AbstractInterpolator}()

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
	interpolator, precomputed_interpolants, diagnostics, diagnostic_data, states, params; ideal = false, sol = nothing)
	full_target, full_varlist, forward_subst_dict, reverse_subst_dict = [[] for _ in 1:4]

	for k in time_index_set
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

		local_subst_dict = OrderedDict{Num, Any}()
		local_subst_dict_reverse = OrderedDict()
		subst_var_list = []

		append!(subst_var_list, vcat(good_DD.states_lhs...))
		append!(subst_var_list, states)
		append!(subst_var_list, vcat(good_DD.obs_lhs...))

		for i in subst_var_list
			newname = tag_symbol(i, "_t" * string(k) * "_", "_")
			j = Symbolics.wrap(i)
			local_subst_dict[j] = newname
			local_subst_dict_reverse[newname] = j
		end

		for i in params
			newname = tag_symbol(i, "_t" * string("p"), "_")
			j = Symbolics.wrap(i)
			local_subst_dict[j] = newname
			local_subst_dict_reverse[newname] = j
		end

		target_k_subst = substitute.(target_k, Ref(local_subst_dict))
		varlist_k_subst = substitute.(varlist_k, Ref(local_subst_dict))
		push!(full_target, target_k_subst)
		push!(full_varlist, varlist_k_subst)
		push!(forward_subst_dict, local_subst_dict)
		push!(reverse_subst_dict, local_subst_dict_reverse)
	end  #this is the end of the loop over the time points which just constructs the System
	return full_target, full_varlist, forward_subst_dict, reverse_subst_dict
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
    DD::Union{DerivativeData,Symbol} = :nothing
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
		obs_deriv_vals = []
		for k in eachindex(ic_dict_vector)
			evaluated_subst_dict = OrderedDict{Any, Any}(deepcopy(values_dict))
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
					substituted_val = substitute(DD.states_rhs[i][j], evaluated_subst_dict)
					# If the substituted value is a constant, unwrap it from the symbolic type.
					if !Symbolics.iscall(substituted_val)
						evaluated_subst_dict[DD.states_lhs[i][j]] = Symbolics.value(substituted_val)
					else
						evaluated_subst_dict[DD.states_lhs[i][j]] = substituted_val
					end
				end
			end
			for i in eachindex(DD.obs_rhs), j in eachindex(DD.obs_rhs[i])
				push!(obs_deriv_vals, Symbolics.value(substitute(DD.obs_rhs[i][j], evaluated_subst_dict)))
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
	
	#println("DEBUG [multipoint_numerical_jacobian]: Matrix type before conversion: $(typeof(matrix))")
	#println("DEBUG [multipoint_numerical_jacobian]: Matrix size: $(size(matrix))")
	#println("DEBUG [multipoint_numerical_jacobian]: Matrix elements: $(matrix[1:5, 1:5])")
	#println("DEBUG [multipoint_numerical_jacobian]: Matrix type after conversion: $(typeof(matrix_float))")
	#println("DEBUG [multipoint_numerical_jacobian]: Matrix size after conversion: $(size(matrix_float))")
	#println("DEBUG [multipoint_numerical_jacobian]: Matrix elements after conversion: $(matrix_float[1:5, 1:5])")
	# Ensure every element is a Float64 by applying Symbolics.value before conversion
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
    abstol::Float64 = 1e-12
)::Tuple{Dict, Dict, Vector, DerivativeData}
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	varlist = Vector{Num}(vcat(model_ps, model_states))

	#println("DEBUG [multipoint_local_identifiability_analysis]: Starting analysis with ", max_num_points, " points")

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)

	# FIX: Use OrderedDict to ensure consistent ordering with varlist for Jacobian columns
	parameter_values = OrderedDict{SymbolicUtils.BasicSymbolic{Real}, Float64}()
	for p in ModelingToolkit.parameters(model)
		parameter_values[p] = rand(Float64)
	end
	
	points_ics = []
	test_points = []
	ordered_test_points = []

	for i in 1:max_num_points
		# FIX: Use OrderedDict for initial conditions too
		initial_conditions = OrderedDict{SymbolicUtils.BasicSymbolic{Real}, Float64}()
		for s in ModelingToolkit.unknowns(model)
			initial_conditions[s] = rand(Float64)
		end
		
		ordered_test_point = OrderedDict{SymbolicUtils.BasicSymbolic{Real}, Float64}()
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
	n = Int64(ceil((states_count + ps_count) / length(measured_quantities)) + 2)
	n = max(n, 3)
	deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
	unident_dict = Dict()

	jac = nothing
	evaluated_jac = nothing
	DD = nothing
	unident_set = Set{Any}()

	all_identified = false
	while (!all_identified)

		temp = ordered_test_points[1]
		(evaluated_jac, DD) = (multipoint_numerical_jacobian(model, measured_quantities, n, max_num_points, unident_dict, varlist,
			parameter_values, points_ics, temp))
		ns = nullspace(evaluated_jac)

		if (!isempty(ns))
			candidate_plugins_for_unidentified = OrderedDict()
			for i in eachindex(varlist)
				if (!isapprox(norm(ns[i, :]), 0.0, atol = abstol))
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
	SymbolicDerivs[1] = [ObservableDerivatives[i, 1] ~ substitute(expand_derivatives(D(measured_quantities[i].rhs)), equation_dict) for i in 1:n_observables]

	# Calculate higher order derivatives
	for j in 2:nderivs
		SymbolicDerivs[j] = [ObservableDerivatives[i, j] ~ substitute(expand_derivatives(D(SymbolicDerivs[j-1][i].rhs)), equation_dict) for i in 1:n_observables]
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
			interpolated_values_dict[DD.obs_lhs[1][key]] = nth_deriv_at(interpolants[ModelingToolkit.diff2term(measured_quantities[key].rhs)], 0, t_vector[time_index])
			for i in 1:value
				interpolated_values_dict[DD.obs_lhs[i+1][key]] = nth_deriv_at(interpolants[ModelingToolkit.diff2term(measured_quantities[key].rhs)], i, t_vector[time_index])
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
		target[i] = substitute(target[i], interpolated_values_dict)
	end


	vars_needed = OrderedSet()
	vars_added = OrderedSet()

	vars_needed = union(vars_needed, model_ps)
	vars_needed = union(vars_needed, model_states)
	vars_needed = setdiff(vars_needed, keys(unident_dict))

	keep_adding = true
	while (keep_adding)
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
				end
			end
		end
		diff_set = setdiff(vars_needed, vars_added)
		keep_adding = !isempty(diff_set) && added
	end

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

	# Return the real part of the solution as a Float64
	return Float64(real(solns[soln_index][index]))
end

# New helper function to evaluate a polynomial system by substituting exact state and parameter values
function evaluate_poly_system(poly_system, forward_subst::OrderedDict, reverse_subst::OrderedDict, true_states::OrderedDict, true_params::OrderedDict, eqns)
	sub_dict = Dict()

	#println("starting evaluate_poly_system")
	#println(poly_system)
	poly_system = substitute(poly_system, reverse_subst)
	#println("poly_system after substitution:")
	#println(poly_system)

	#println("break")


	# Create DD structure to compute derivatives
	DD = DerivativeData([], [], [], [], [], [], [], [], Set{Any}())
	DD.states_lhs = [[eq.lhs for eq in eqns], expand_derivatives.(D.([eq.lhs for eq in eqns]))]
	DD.states_rhs = [[eq.rhs for eq in eqns], expand_derivatives.(D.([eq.rhs for eq in eqns]))]

	# Compute higher derivatives
	for i in 1:7
		push!(DD.states_lhs, expand_derivatives.(D.(DD.states_lhs[end])))
		temp = DD.states_rhs[end]
		temp2 = D.(temp)
		temp3 = deepcopy(temp2)
		temp4 = []
		for j in 1:length(temp3)
			temptemp = expand_derivatives(temp3[j])
			push!(temp4, deepcopy(temptemp))
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
		sub_dict[DD.states_lhs[i][j]] = simplify(substitute(DD.states_rhs[i][j], sub_dict))
	end


	#println("deriv_values:")
	#println(deriv_values)
	#println("sub_dict after computing derivatives:")
	#println(sub_dict)

	# Apply all substitutions to the polynomial system
	for i in 1:7
		evaluated = [simplify(substitute(expr, sub_dict)) for expr in poly_system]
		#println(evaluated)
	end

	# Final pass: convert any remaining derivatives to terms
	evaluated = [ModelingToolkit.diff2term(expand_derivatives(expr)) for expr in evaluated]



	return evaluated
end

"""
	polish_solution_using_optimization(candidate_solution::ParameterEstimationResult, PEP::ParameterEstimationProblem;
										 solver = Vern9(),
										 opt_method = BFGS,
										 opt_maxiters = 200000,
										 abstol = 1e-13,
										 reltol = 1e-13,
										 lb = nothing,
										 ub = nothing)

Using a local-optimization approach, polish a candidate solution obtained from multi-point analysis.
This function assumes that `PEP` contains the original model, measured quantities, and data_sample,
and that the candidate_solution (of type ParameterEstimationResult) includes guessed values for states
and parameters in OrderedDicts. We form an ODEProblem from these values, define a loss function that sums
squared errors between simulated trajectories with the data stored in `PEP.data_sample.
On success, the returned `polished_result` is a new ParameterEstimationResult whose fields (states, parameters,
solution, err) have been updated with the optimized values.

An example call is provided below.
"""
function polish_solution_using_optimization(candidate_solution::ParameterEstimationResult, PEP::ParameterEstimationProblem;
	solver = Vern9(),
	opt_method = LBFGS,
	opt_maxiters = 20,
	abstol = 1e-13,
	reltol = 1e-13,
	lb = nothing,
	ub = nothing)
	# Extract the time vector from the data sample
	t_vector = PEP.data_sample["t"]

	# Candidate solution contains states and parameters as OrderedDicts.
	# For the optimization we form a single vector: [state_values; parameter_values]
	state_keys = collect(keys(candidate_solution.states))
	param_keys = collect(keys(candidate_solution.parameters))
	n_ic = length(state_keys)
	n_param = length(param_keys)

	# Convert to Float64 explicitly
	initial_states = Float64[v for v in values(candidate_solution.states)]
	initial_params = Float64[v for v in values(candidate_solution.parameters)]
	p0 = vcat(initial_states, initial_params)

	# Set default bounds if not provided
	if lb === nothing
		lb = -3.0 * ones(Float64, length(p0))
	end
	if ub === nothing
		ub = 3.0 * ones(Float64, length(p0))
	end

	# Build the ODE problem using the model stored in PEP.
	# (We call complete() to ensure the system is fully defined.)
	new_model = complete(PEP.model.system)
	tspan = (Float64(t_vector[1]), Float64(t_vector[end]))

	prob = ODEProblem(new_model, merge(initial_states, initial_params), tspan)

	# Create a mapping from state variables to their index in the solution vector.
	state_index = Dict{Any, Int}()
	for (i, s) in enumerate(state_keys)
		state_index[s] = i
	end

	# The loss function:
	# Given a vector p_vec (with the candidate's state and parameter guesses),
	# re-simulate the ODE and compute the sum of squared differences between
	# simulated measurements and the data stored in PEP.data_sample.
	# Here we assume that each measured quantity equation is of the form `LHS ~ rhs`,
	# where the source of the measurement is the state corresponding to `rhs`.
	function loss(p_vec)
		# Validate input vector for complex numbers
		if any(abs.(imag.(p_vec)) .> complex_threshold)
			return Inf
		end

		ic_guess = real.(p_vec[1:n_ic])
		param_guess = real.(p_vec[(n_ic+1):end])

		prob_opt = remake(prob, u0 = ic_guess, p = param_guess)
		sol_opt = try
			ModelingToolkit.solve(prob_opt, solver, saveat = t_vector, abstol = abstol, reltol = reltol)
		catch e
			println("WARNING: ODE solver failed with error: $e")
			return Inf
		end

		if sol_opt.retcode != ReturnCode.Success
			return Inf
		end

		total_error = 0.0
		# Loop over each measured quantity
		for eq in PEP.measured_quantities
			sim_vals = []
			for i in 1:length(sol_opt.u)
				# Create substitution dictionary for current timepoint
				time_subst = Dict(s => sol_opt.u[i][state_index[s]] for s in state_keys)
				# Evaluate the formula with current state values and extract value from possible Dual type
				val = substitute(eq.rhs, time_subst)
				push!(sim_vals, val)
			end
			# Determine which key to use from the data sample
			key = eq.rhs
			data_true = PEP.data_sample[key]
			total_error += sum((sim_vals .- data_true) .^ 2)
		end
		return total_error
	end

	# Print initial loss value for debugging
	initial_loss = loss(p0)
	println("Initial parameter vector: ", p0)
	println("Initial loss value: ", initial_loss)


	# Set up the Optimization problem using auto-differentiation via ForwardDiff
	adtype = Optimization.AutoForwardDiff()
	optf = Optimization.OptimizationFunction((x, p) -> loss(x), adtype)
	optprob = Optimization.OptimizationProblem(optf, p0)  #lb = lb, ub = ub

	# Solve the optimization problem with a timeout
	result = Optimization.solve(optprob, opt_method(), callback = (p, l) -> false, maxiters = opt_maxiters)

	# Extract the optimized initial conditions and parameters.
	p_opt = result.u
	ic_opt = real.(p_opt[1:n_ic])
	param_opt = real.(p_opt[(n_ic+1):end])

	# Re-simulate the ODE using the optimized values.
	prob_polished = remake(prob, u0 = ic_opt, p = param_opt)
	sol_polished = ModelingToolkit.solve(prob_polished, solver, saveat = t_vector, abstol = abstol, reltol = reltol)

	# Update a copy of the candidate solution with the polished values.
	polished_result = deepcopy(candidate_solution)
	polished_result.states = OrderedDict(zip(state_keys, ic_opt))
	polished_result.parameters = OrderedDict(zip(param_keys, param_opt))
	polished_result.solution = sol_polished
	polished_result.err = loss(p_opt)

	return polished_result, result
end


