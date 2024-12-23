module ODEParameterEstimation

using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkit
using OrdinaryDiffEq
using LinearAlgebra
using OrderedCollections
using BaryRational
using HomotopyContinuation
using TaylorDiff
using PrecompileTools
using ForwardDiff
using Random



"""
	ParameterEstimationResult

Struct to store the results of parameter estimation.

# Fields
- `parameters::AbstractDict`: Estimated parameters
- `states::AbstractDict`: Estimated states
- `at_time::Float64`: Time at which estimation is done
- `err::Union{Nothing, Float64}`: Error of estimation
- `return_code::Any`: Return code of the estimation process
- `datasize::Int64`: Size of the data used
- `report_time::Any`: Time at which the result is reported
"""
mutable struct ParameterEstimationResult
	parameters::AbstractDict
	states::AbstractDict
	at_time::Float64
	err::Union{Nothing, Float64}
	return_code::Any
	datasize::Int64
	report_time::Any
end

"""
	DerivativeData

Struct to store derivative data of state variable equations and measured quantity equations.
No substitutions are made.
The "cleared" versions are produced from versions of the state equations and measured quantity equations
which have had their denominators cleared, i.e. they should be polynomial and never rational.

# Fields
- `states_lhs_cleared::Any`: Left-hand side of cleared state equations
- `states_rhs_cleared::Any`: Right-hand side of cleared state equations
- `obs_lhs_cleared::Any`: Left-hand side of cleared observation equations
- `obs_rhs_cleared::Any`: Right-hand side of cleared observation equations
- `states_lhs::Any`: Left-hand side of state equations
- `states_rhs::Any`: Right-hand side of state equations
- `obs_lhs::Any`: Left-hand side of observation equations
- `obs_rhs::Any`: Right-hand side of observation equations
"""
mutable struct DerivativeData
	states_lhs_cleared::Any
	states_rhs_cleared::Any
	obs_lhs_cleared::Any
	obs_rhs_cleared::Any
	states_lhs::Any
	states_rhs::Any
	obs_lhs::Any
	obs_rhs::Any
end

include("utils.jl")
include("SharedUtils.jl")
include("bary_derivs.jl")
include("sample_data.jl")
include("equation_solvers.jl")
#include("single-point.jl")
include("test_utils.jl")

"""
	handle_simple_substitutions(eqns, varlist)

Look for equations like a-5.5 and replace a with 5.5.

# Arguments
- `eqns`: Equations to process
- `varlist`: List of variables

# Returns
- Tuple containing filtered equations, reduced variable list, trivial variables, and trivial dictionary
"""
function handle_simple_substitutions(eqns, varlist)
	trivial_dict = Dict()
	filtered_eqns = typeof(eqns)()
	trivial_vars = []
	for i in eqns

		g = Symbolics.get_variables(i)
		if (length(g) == 1 && Symbolics.degree(i) == 1)
			thisvar = g[1]
			td = (polynomial_coeffs(i, (thisvar,)))[1]
			if (1 in Set(keys(td)))
				thisvarvalue = (-td[1] / td[thisvar])
				trivial_dict[thisvar] = thisvarvalue
				push!(trivial_vars, thisvar)
			else
				thisvarvalue = 0
				trivial_dict[thisvar] = thisvarvalue
				push!(trivial_vars, thisvar)
			end
		else
			push!(filtered_eqns, i)
		end
	end
	reduced_varlist = filter(x -> !(x in Set(trivial_vars)), varlist)
	filtered_eqns = Symbolics.substitute.(filtered_eqns, Ref(trivial_dict))
	return filtered_eqns, reduced_varlist, trivial_vars, trivial_dict
end




"""
	populate_derivatives(model::ODESystem, measured_quantities_in, max_deriv_level, unident_dict)

Populate a DerivativeData object by taking derivatives of state variable and measured quantity equations.
diff2term is applied everywhere, so we will be left with variables like x_tttt etc.

# Arguments
- `model::ODESystem`: The ODE system
- `measured_quantities_in`: Input measured quantities
- `max_deriv_level`: Maximum derivative level
- `unident_dict`: Dictionary of unidentifiable variables

# Returns
- DerivativeData object
"""
function populate_derivatives(model::ODESystem, measured_quantities_in, max_deriv_level, unident_dict)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities = deepcopy(measured_quantities_in)


	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)

	DD = DerivativeData([], [], [], [], [], [], [], [])

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
		push!(DD.states_lhs, expand_derivatives.(D.(DD.states_lhs[end])))  #this constructs the derivatives of the state equations
		temp = DD.states_rhs[end]
		temp2 = D.(temp)
		temp3 = deepcopy(temp2)
		temp4 = []
		for j in 1:length(temp3)
			temptemp = expand_derivatives(temp3[j])
			push!(temp4, deepcopy(temptemp))
		end
		push!(DD.states_rhs, temp4)
		push!(DD.states_lhs_cleared, expand_derivatives.(D.(DD.states_lhs_cleared[end])))  #this constructs the derivatives of the state equations
		push!(DD.states_rhs_cleared, expand_derivatives.(D.(DD.states_rhs_cleared[end])))
	end
	for i in eachindex(DD.states_rhs), j in eachindex(DD.states_rhs[i])
		DD.states_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_rhs[i][j]))
		DD.states_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_lhs[i][j])) #applies differential operator everywhere.  
		DD.states_rhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_rhs_cleared[i][j]))
		DD.states_lhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_lhs_cleared[i][j])) #applies differential operator everywhere.  
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
	multipoint_numerical_jacobian(model, measured_quantities_in, max_deriv_level::Int, max_num_points, unident_dict,
								  varlist, param_dict, ic_dict_vector, values_dict, DD = :nothing)

Compute the numerical Jacobian at multiple points.
the multiple points have different values for states, but the same parameters.


# Arguments
- `model`: The ODE model
- `measured_quantities_in`: Input measured quantities
- `max_deriv_level::Int`: Maximum derivative level
- `max_num_points`: Maximum number of points
- `unident_dict`: Dictionary of unidentifiable variables
- `varlist`: List of variables
- `param_dict`: Dictionary of parameters
- `ic_dict_vector`: Vector of initial condition dictionaries
- `values_dict`: Dictionary of values; we just use this to copy its shape
- `DD`: DerivativeData object (optional)

# Returns
- Tuple containing the Jacobian matrix and DerivativeData object
"""


function multipoint_numerical_jacobian(model, measured_quantities_in, max_deriv_level::Int, max_num_points, unident_dict,
	varlist, param_dict, ic_dict_vector, values_dict, DD = :nothing)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities = deepcopy(measured_quantities_in)

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)
	subst_dict = Dict()

	num_real_params = length(keys(param_dict))
	num_real_states = length(keys(ic_dict_vector[1]))


	if (DD == :nothing)
		DD = populate_derivatives(model, measured_quantities, max_deriv_level, unident_dict)
	end

	function f(param_and_ic_values_vec)

		obs_deriv_vals = []
		for k in eachindex(ic_dict_vector)
			evaluated_subst_dict = OrderedDict{Any, Any}(deepcopy(values_dict))
			thekeys = collect(keys(evaluated_subst_dict))
			for i in 1:num_real_params
				evaluated_subst_dict[thekeys[i]] = param_and_ic_values_vec[i]  #this sets just the params
			end
			for i in 1:num_real_states  #this is wrong replace this
				evaluated_subst_dict[thekeys[i+num_real_params]] =  #check this?
					param_and_ic_values_vec[(k-1)*num_real_states+num_real_params+i]
			end

			for i in eachindex(DD.states_rhs)
				for j in eachindex(DD.states_rhs[i])
					evaluated_subst_dict[DD.states_lhs[i][j]] = substitute(DD.states_rhs[i][j], evaluated_subst_dict)
				end
			end
			for i in eachindex(DD.obs_rhs), j in eachindex(DD.obs_rhs[i])
				push!(obs_deriv_vals, (substitute(DD.obs_rhs[i][j], evaluated_subst_dict)))
			end
		end
		return obs_deriv_vals
	end

	full_values = collect(values(param_dict))
	for k in eachindex(ic_dict_vector)
		append!(full_values, collect(values(ic_dict_vector[k])))
	end
	matrix = ForwardDiff.jacobian(f, full_values)
	return Matrix{Float64}(matrix), DD

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
	multipoint_local_identifiability_analysis(model::ODESystem, measured_quantities, max_num_points, rtol = 1e-12, atol = 1e-12)

Perform local identifiability analysis at multiple points.

# Arguments
- `model::ODESystem`: The ODE system
- `measured_quantities`: Measured quantities
- `max_num_points`: Maximum number of points to use
- `rtol`: Relative tolerance (default: 1e-12)
- `atol`: Absolute tolerance (default: 1e-12)

# Returns
- Tuple containing derivative levels, unidentifiable dictionary, variable list, and DerivativeData object
"""
function multipoint_local_identifiability_analysis(model::ODESystem, measured_quantities, max_num_points, rtol = 1e-12, atol = 1e-12)

	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	varlist = Vector{Num}(vcat(model_ps, model_states))

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)

	#first, we construct a single (consistent) set of parameters, and n different sets of initial conditions
	parameter_values = Dict([p => rand(Float64) for p in ModelingToolkit.parameters(model)])
	points_ics = []
	test_points = []
	ordered_test_points = []

	for i in 1:max_num_points
		initial_conditions = Dict([p => rand(Float64) for p in ModelingToolkit.unknowns(model)])
		test_point = merge(parameter_values, initial_conditions)
		ordered_test_point = OrderedDict{SymbolicUtils.BasicSymbolic{Real}, Float64}()
		for i in model_ps
			ordered_test_point[i] = parameter_values[i]
		end
		for i in model_states
			ordered_test_point[i] = initial_conditions[i]
		end
		push!(points_ics, deepcopy(initial_conditions))
		push!(test_points, deepcopy(test_point))
		push!(ordered_test_points, deepcopy(ordered_test_point))
	end

	n = Int64(ceil((states_count + ps_count) / length(measured_quantities)) + 2)  #check this is sufficient, for the number of derivatives to take
	#see comment from non-multipoint version
	n = max(n, 3)
	deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
	unident_dict = Dict()


	jac = nothing
	evaluated_jac = nothing
	DD = nothing

	all_identified = false
	while (!all_identified)
		(evaluated_jac, DD) = (multipoint_numerical_jacobian(model, measured_quantities, n, max_num_points, unident_dict, varlist,
			parameter_values, points_ics, ordered_test_points[1]))
		ns = nullspace(evaluated_jac)

		if (!isempty(ns))
			candidate_plugins_for_unidentified = OrderedDict()
			for i in eachindex(varlist)
				if (!isapprox(norm(ns[i, :]), 0.0, atol = atol))
					candidate_plugins_for_unidentified[varlist[i]] = test_points[1][varlist[i]]
				end
			end

			println("After making the following substitutions:", unident_dict, " the following are globally unidentifiable:",
				keys(candidate_plugins_for_unidentified))
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
	println("Finally, the following substitutions will be made:", unident_dict)

	max_rank = rank(evaluated_jac, rtol = rtol)
	maxn = n
	while (n > 0)
		n = n - 1
		deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
		reduced_evaluated_jac = multipoint_deriv_level_view(evaluated_jac, deriv_level, length(measured_quantities), max_num_points, maxn, max_num_points)
		r = rank(reduced_evaluated_jac, rtol = rtol)
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

				r = rank(reduced_evaluated_jac, rtol = rtol)
				if (r < max_rank)
					deriv_level[i] = deriv_level[i] + 1
				else
					improvement_found = true
					break
				end
			else
				temp = pop!(deriv_level, i)
				reduced_evaluated_jac = multipoint_deriv_level_view(evaluated_jac, deriv_level, length(measured_quantities), max_num_points, maxn, max_num_points)

				r = rank(reduced_evaluated_jac, rtol = rtol)
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
	return (deriv_level, unident_dict, varlist, DD)
end


"""
	construct_equation_system(model::ODESystem, measured_quantities_in, data_sample,
							  deriv_level, unident_dict, varlist, DD, time_index_set = nothing, return_parameterized_system = false)

Construct an equation system for parameter estimation.

# Arguments
- `model::ODESystem`: The ODE system
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
function construct_equation_system(model::ODESystem, measured_quantities_in, data_sample,
	deriv_level, unident_dict, varlist, DD, time_index_set = nothing, return_parameterized_system = false)  #return_parameterized_system not supported yet

	measured_quantities = deepcopy(measured_quantities_in)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	D = Differential(t)

	t_vector = pop!(data_sample, "t")
	time_interval = (minimum(t_vector), maximum(t_vector))
	if (isnothing(time_index_set))
		time_index_set = [fld(length(t_vector), 2)]  #TODO add vector handling 
	end
	time_index = time_index_set[1]

	interpolants = Dict()
	for j in measured_quantities
		r = j.rhs
		y_vector = data_sample[r]
		interpolants[r] = aaad(t_vector, y_vector)
	end

	#handle unidentifiable variables, just substituting for them
	unident_subst!(model_eq, measured_quantities, unident_dict)

	max_deriv = max(4, 1 + maximum(collect(values(deriv_level))))

	#We begin building a system of equations which will be solved, e.g. by homotopoy continuation.
	#the first set of equations, built below, constrains the observables values and their derivatives 
	#to values determined by interpolation.
	target = []  # TODO give this a type later
	for (key, value) in deriv_level  # 0 means include the observation itself, 1 means first derivative
		push!(target, DD.obs_rhs_cleared[1][key] - DD.obs_lhs_cleared[1][key])
		for i in 1:value
			push!(target, DD.obs_rhs_cleared[i+1][key] - DD.obs_lhs_cleared[i+1][key])
		end
	end
	interpolated_values_dict = Dict()
	for (key, value) in deriv_level
		interpolated_values_dict[DD.obs_lhs[1][key]] =
			nth_deriv_at(interpolants[ModelingToolkit.diff2term(measured_quantities[key].rhs)], 0, t_vector[time_index])
		for i in 1:value
			interpolated_values_dict[DD.obs_lhs[i+1][key]] =
				nth_deriv_at(interpolants[ModelingToolkit.diff2term(measured_quantities[key].rhs)], i, t_vector[time_index])
		end
	end

	#if (!return_parameterized_system)
	for i in eachindex(target)
		target[i] = substitute(target[i], interpolated_values_dict)
	end
	#end

	#Now, we scan for state variables and their derivatives we need values for.
	#We add precisely the state variables we need and no more.
	#This forces the system to be square.
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

	push!(data_sample, ("t" => t_vector)) #TODO(orebas) maybe don't pop this in the first place


	return_var = collect(vars_needed)

	return target, return_var

end



"""
	squarify_by_trashing(poly_system, varlist, rtol = 1e-12)

Make a polynomial system square by removing equations.

# Arguments
- `poly_system`: Polynomial system to squarify
- `varlist`: List of variables
- `rtol`: Relative tolerance (default: 1e-12)

# Returns
- Tuple containing the new system, variable list, and trashed equations
"""
function squarify_by_trashing(poly_system, varlist, rtol = 1e-12)
	mat = ModelingToolkit.jacobian(poly_system, varlist)
	vsubst = Dict([p => rand(Float64) for p in varlist])
	numerical_mat = Matrix{Float64}(Symbolics.value.((substitute.(mat, Ref(vsubst)))))
	target_rank = rank(numerical_mat, rtol = rtol)
	currentlist = 1:length(poly_system)
	trashlist = []
	keep_looking = true
	while (keep_looking)
		improvement_found = false
		for j in currentlist
			newlist = filter(x -> x != j, currentlist)
			jac_view = view(numerical_mat, newlist, :)
			rank2 = rank(jac_view, rtol = rtol)
			if (rank2 == target_rank)
				improvement_found = true
				currentlist = newlist
				push!(trashlist, j)
				break
			end
		end
		keep_looking = improvement_found
	end
	new_system = [poly_system[i] for i in currentlist]
	trash_system = [poly_system[i] for i in trashlist]

	#println("we trash these: (line 708)")
	#display(trash_system)

	return new_system, varlist, trash_system
end


"""
	pick_points(vec, n)

Select n points from a vector, trying to spread them out.
TODO:  this can be improved, taking the measured_data into account
TODO:  actually, for now, it's just random (and therefore nondeterministic)
I haven't tested this (i.e. justified it), but by default, we avoid the endpoints.
n is assumed to be less than length(vec)

# Arguments
- `vec`: Vector to pick points from
- `n`: Number of points to pick

# Returns
- Vector of selected indices
"""
function pick_points(vec, n)
	if (n == length(vec))
		return 1:n
	elseif (n == length(vec) - 1)
		return 1:(n-1)
	elseif (n == length(vec) - 2)
		return 2:(n-1)
	else
		l = length(vec)
		perm = randperm(l - 2) .+ 1
		reduced = perm[1:n]
		#res = [ [1] ; reduced ; [l]]
		sort!(reduced)
		return reduced
	end
end


"""
	MPHCPE(model::ODESystem, measured_quantities, data_sample, ode_solver; system_solver = solveJSwithHC, display_points = true, max_num_points = 4)

Perform Multi-point Homotopy Continuation Parameter Estimation.

# Arguments
- `model::ODESystem`: The ODE system
- `measured_quantities`: Measured quantities
- `data_sample`: Sample data
- `ode_solver`: ODE solver to use
- `system_solver`: System solver function (optional, default: solveJSwithHC)
- `display_points`: Whether to display points (optional, default: true)
- `max_num_points`: Maximum number of points to use (optional, default: 4)

# Returns
- Vector of result vectors
"""
function MPHCPE(model::ODESystem, measured_quantities, data_sample, ode_solver; system_solver = solveJSwithHC, display_points = true, max_num_points = 2)
	t = ModelingToolkit.get_iv(model)
	eqns = ModelingToolkit.equations(model)
	states = ModelingToolkit.unknowns(model)
	params = ModelingToolkit.parameters(model)

	t_vector = data_sample["t"]
	time_interval = extrema(t_vector)
	found_any_solutions = false
	large_num_points = min(length(params), max_num_points, length(t_vector)) + 1
	good_num_points = large_num_points

	time_index_set, solns, good_udict, forward_subst_dict, trivial_dict, final_varlist, trimmed_varlist =
		[[] for _ in 1:7]

	while (!found_any_solutions)
		good_num_points = good_num_points - 1
		(target_deriv_level, target_udict, target_varlist, target_DD) = multipoint_local_identifiability_analysis(model, measured_quantities, large_num_points)
		while (good_num_points > 1)
			good_num_points = good_num_points - 1
			(test_deriv_level, test_udict, test_varlist, test_DD) = multipoint_local_identifiability_analysis(model, measured_quantities, good_num_points)
			if !(test_deriv_level == target_deriv_level)
				good_num_points = good_num_points + 1
				break
			end
		end
		(good_deriv_level, good_udict, good_varlist, good_DD) = multipoint_local_identifiability_analysis(model, measured_quantities, good_num_points)

		time_index_set = pick_points(t_vector, good_num_points)
		if (display_points)
			println("We are trying these points:", time_index_set)
			println("Using these observations and their derivatives:")
			display(good_deriv_level)
		end
		full_target, full_varlist, forward_subst_dict, reverse_subst_dict = [[] for _ in 1:4]

		@variables testing
		for k in time_index_set
			(target_k, varlist_k) = construct_equation_system(model, measured_quantities, data_sample, good_deriv_level, good_udict, good_varlist, good_DD, [k])
			local_subst_dict = OrderedDict{Num, Any}()
			local_subst_dict_reverse = OrderedDict()
			subst_var_list = []

			for i in eachindex(good_DD.states_lhs), j in eachindex(good_DD.states_lhs[i])
				push!(subst_var_list, good_DD.states_lhs[i][j])
			end
			for i in eachindex(states)
				push!(subst_var_list, states[i])
			end
			for i in eachindex(good_DD.obs_lhs), j in eachindex(good_DD.obs_lhs[i])
				push!(subst_var_list, good_DD.obs_lhs[i][j])
			end
			for i in subst_var_list
				newname = tag_symbol(i, "_t" * string(k) * "_", "_")
				j = Symbolics.wrap(i)

				#newname = testing
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
			varlist_k_subst = substitute.(varlist_k, Ref(local_subst_dict)) #TODO maybe ask why this didn't work but didn't fail without broadcasting
			push!(full_target, target_k_subst)
			push!(full_varlist, varlist_k_subst)
			push!(forward_subst_dict, local_subst_dict)
			push!(reverse_subst_dict, local_subst_dict_reverse)
		end
		# println("full target")
		#display(full_target)

		final_target = reduce(vcat, full_target)
		# Maintain order by keeping first occurrence of each variable
		final_varlist = collect(OrderedDict{eltype(first(full_varlist)),Nothing}(v => nothing for v in reduce(vcat, full_varlist)).keys)

		solve_result, hcvarlist, trivial_dict, trimmed_varlist = system_solver(final_target, final_varlist)

		solns = solve_result
		if (!isempty(solns))
			found_any_solutions = true
		end
	end

	@named new_model = ODESystem(eqns, t, states, params)
	new_model = complete(new_model)
	lowest_time_index = min(time_index_set...)

	results_vec = []
	local_states_dict_all = []
	for soln_index in eachindex(solns)
		initial_conditions = [1e10 for s in states]
		parameter_values = [1e10 for p in params]
		for i in eachindex(params)
			if params[i] in keys(good_udict)
				parameter_values[i] = good_udict[params[i]]
			else

				param_search = forward_subst_dict[1][(params[i])]
				if (param_search in keys(trivial_dict))
					parameter_values[i] = trivial_dict[param_search]
				else
					index = findfirst(isequal(param_search), final_varlist)
					parameter_values[i] = real(solns[soln_index][index]) #TODOdo we ignore the imaginary part?
				end
			end                                                   #what about other vars
		end

		for i in eachindex(states)
			if states[i] in keys(good_udict)
				initial_conditions[i] = good_udict[states[i]]

			else
				model_state_search = forward_subst_dict[1][(states[i])]
				
				if (model_state_search in keys(trivial_dict))
					initial_conditions[i] = trivial_dict[model_state_search]
					#					display(trivial_dict[model_state_search])

				else
					index = findfirst(
						isequal(model_state_search),
						trimmed_varlist)
					initial_conditions[i] = real(solns[soln_index][index]) #see above
				end
			end
		end

		initial_conditions = Base.convert(Array{ComplexF64, 1}, initial_conditions)
		if (isreal(initial_conditions))
			initial_conditions = Base.convert(Array{Float64, 1}, initial_conditions)
		end


		parameter_values = Base.convert(Array{ComplexF64, 1}, parameter_values)
		if (isreal(parameter_values))
			parameter_values = Base.convert(Array{Float64, 1}, parameter_values)
		end
		tspan = (t_vector[lowest_time_index], t_vector[1])  #this is backwards

		new_model = complete(new_model)
		prob = ODEProblem(new_model, initial_conditions, tspan, Dict(ModelingToolkit.parameters(new_model) .=> parameter_values))

		ode_solution = ModelingToolkit.solve(prob, ode_solver, abstol = 1e-14, reltol = 1e-14)

		state_param_map = (Dict(x => replace(string(x), "(t)" => "")
								for x in ModelingToolkit.unknowns(model)))
		newstates = OrderedDict()
		for s in states
			newstates[s] = ode_solution[Symbol(state_param_map[s])][end]
		end
		push!(results_vec, [collect(values(newstates)); parameter_values])
	end

	return results_vec


end





export MPHCPE, HCPE, ODEPEtestwrapper, ParameterEstimationResult, sample_data, diag_solveJSwithHC
export ParameterEstimationProblem, analyze_parameter_estimation_problem, fillPEP
export create_ode_system, sample_problem_data, analyze_estimation_result

#later, disable output of the compile_workload

#=@recompile_invalidations begin
	@compile_workload begin
		@parameters a b
		@variables t x1(t) x2(t) y1(t) y2(t)
		D = Differential(t)
		states = [x1, x2]
		parameters = [a, b]

		@named model = ODESystem([
				D(x1) ~ -a * x2,
				D(x2) ~ b * x1,  #edited from 1/b
			], t, states, parameters)
		measured_quantities = [
			y1 ~ x1,
			y2 ~ x2]

		ic = [0.333, 0.667]
		p_true = [0.4, 0.8]

		model = complete(model)
		
		# Create OrderedODESystem wrapper
		ordered_model = OrderedODESystem(model, states, parameters)
		
		data_sample = sample_data(model, measured_quantities, [-1.0, 1.0], p_true, ic, 19, solver = Vern9())

		ret = ODEPEtestwrapper(ordered_model, measured_quantities, data_sample, Vern9())

		display(ret)
	end
end =#


end
