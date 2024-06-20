module ODEParameterEstimation

# Write your package code here.

using ModelingToolkit, OrdinaryDiffEq
using LinearAlgebra
using OrderedCollections
using BaryRational
using HomotopyContinuation
using TaylorDiff
using PrecompileTools
using ForwardDiff
using Random

using Optimization
using OptimizationOptimJL
using NonlinearSolve


Optimization, OptimizationOptimJL, NonlinearSolve

include("bary_derivs.jl")
include("sample_data.jl")

mutable struct ParameterEstimationResult
	parameters::AbstractDict
	states::AbstractDict
	at_time::Float64
	err::Union{Nothing, Float64}
	return_code::Any
	datasize::Int64
	report_time::Any
end


#the below struct contains derivatives of state variable equations and measured quantity equations.
#no substitutions are made.
#the "cleared" versions are produced from versions of the state equations and measured quantity equations
#which have had their denominators cleared, i.e. they should be polynomial and never rational.
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


function unpack_ODE(model::ODESystem)
	return ModelingToolkit.get_iv(model), deepcopy(ModelingToolkit.equations(model)), ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model)
end

#unident_dict is a dict of globally unidentifiable variables, and the substitution for them
#deriv_level is a dict of 
#(indices into measured_quantites =>   level of derivative to include)


function clear_denoms(eq)
	@variables _qz_discard1 _qz_discard2
	expr_fake = Symbolics.value(simplify_fractions(_qz_discard1 / _qz_discard2)) #this is a gross way to get the operator for division.
	op = Symbolics.operation(expr_fake)

	ret = eq
	if (!isequal(eq.rhs, 0))
		expr = eq.rhs
		lexpr = eq.lhs
		expr2 = Symbolics.value(simplify_fractions(expr))
		if (istree(expr2) && Symbolics.operation(expr2) == op)
			numer, denom = Symbolics.arguments(expr2)
			ret = lexpr * denom ~ numer
		end
	end
	return ret
end

function unident_subst!(model_eq, measured_quantities, unident_dict)
	for i in eachindex(model_eq)
		model_eq[i] = substitute(model_eq[i].lhs, unident_dict) ~ substitute(model_eq[i].rhs, unident_dict)
	end
	for i in eachindex(measured_quantities)
		measured_quantities[i] = substitute(measured_quantities[i].lhs, unident_dict) ~ substitute(measured_quantities[i].rhs, unident_dict)
	end
end

#this is meant to look for equations like a-5.5 and replace a with 5.5
function handle_simple_substitutions(eqns, varlist)
	println("these are trivial")
	trivial_dict = Dict()
	filtered_eqns = typeof(eqns)()
	trivial_vars = []
	for i in eqns

		g = Symbolics.get_variables(i)
		if (length(g) == 1 && Symbolics.degree(i) == 1)
			display(i)
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
	println("end trivial")
	reduced_varlist = filter(x -> !(x in Set(trivial_vars)), varlist)
	filtered_eqns = Symbolics.substitute.(filtered_eqns, Ref(trivial_dict))
	return filtered_eqns, reduced_varlist, trivial_vars, trivial_dict
end




#this populates a "DerivateData" object, by taking derivatives of state variable and measured quantity equations.
#diff2term is applied everywhere, so we will be left with variables like x_tttt etc.
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
		push!(DD.states_rhs, expand_derivatives.(D.(DD.states_rhs[end])))
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

# numerical_jacobian internally constructs a function f which takes in parameter and initial condition values
# and returns the values of all observed quantities, as well as whatever derivatives have been stored into DD.obs_rhs.
# then, we return the jacobian of this function vs all (locally identifiable) parameters and initial conditions 
function numerical_jacobian(model::ODESystem, measured_quantities_in, max_deriv_level,
	unident_dict, varlist, values_dict, DD = :nothing)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities = deepcopy(measured_quantities_in)

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)
	subst_dict = Dict()


	if (DD == :nothing)
		DD = populate_derivatives(model, measured_quantities, max_deriv_level, unident_dict)
	end
	#Below is a function which takes a vector of parameters and initial conditions 
	#and returns the measured variables, and their derivatives
	#need to exclude globally unidentifiable substitutions from here
	function f(values_vec)  #perhaps if we take this out of this function and make it module level, julia will precompile it.
		evaluated_subst_dict = OrderedDict{Any, Any}(deepcopy(values_dict))
		thekeys = collect(keys(evaluated_subst_dict))
		for i in eachindex(values_vec)
			evaluated_subst_dict[thekeys[i]] = values_vec[i]
		end

		for i in eachindex(DD.states_rhs)
			for j in eachindex(DD.states_rhs[i])
				evaluated_subst_dict[DD.states_lhs[i][j]] = substitute(DD.states_rhs[i][j], evaluated_subst_dict)
			end
		end

		obs_deriv_vals = []
		for i in eachindex(DD.obs_rhs), j in eachindex(DD.obs_rhs[i])
			push!(obs_deriv_vals, (substitute(DD.obs_rhs[i][j], evaluated_subst_dict)))
		end
		return obs_deriv_vals
	end

	init_values = collect(values(values_dict))

	matrix = ForwardDiff.jacobian(f, init_values)
	return Matrix{Float64}(matrix), DD
	#at some point, check if it makes sense to use sparse arrays here.
	#ForwardDiff is an AD package, and the only one that worked reliably even for this simple function.

end

#multipoint_numerical_jacobian does the same as the above, except at multiple points.
#the multiple points have different values for states, but the same parameters.
#the input to the below is as follows
#param_dict contains the value of the parameters
#ic_dict_vector is a vector of dicts, each dict says the value of each state variable
#values_dict is a single dict which we just copy the shape of.  it should contains
#the parameters and initial conditions just like numerical_jacobian likes
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
	#display(f(full_values))
	matrix = ForwardDiff.jacobian(f, full_values)
	return Matrix{Float64}(matrix), DD

end



#deriv_level is a dict which says that for observable i, we need precisely j derivatives and no more
#deriv_level_view takes a jacobian which includes "too many derivatives" and produces a view that 
#only sees precisely the relevant derivatives.
function deriv_level_view(evaluated_jac, deriv_level, num_obs)
	function linear_index(which_obs, this_deriv_level)
		return this_deriv_level * num_obs + which_obs
	end
	view_array = []
	for (which_observable, max_deriv_level) in deriv_level
		for j in 0:max_deriv_level
			push!(view_array, linear_index(which_observable, j))
		end
	end

	return view(evaluated_jac, view_array, :)

end

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




#local_identifiability_analysis proceeds as follows:
# pick a random test point.  At this point, produces a numerical jacobian of output data and N derivatives vs initial conditions and parameters
# by calculating the null space, we find parameters which are globally unidentifiable.  
# We iteratively plug in values for one unidentifiable parameter at a time, until everything is at least locally identifiable.

#for the next step, we try to identify the minimal number of equations necessary to identify identifiable parameters.
# we do this by removing one equations at a time and check that the jacobian rank does not drop.
function local_identifiability_analysis(model::ODESystem, measured_quantities, rtol = 1e-12, atol = 1e-12)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	varlist = Vector{Num}(vcat(model_ps, model_states))

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)

	parameter_values = Dict([p => rand(Float64) for p in ModelingToolkit.parameters(model)])
	initial_conditions = Dict([p => rand(Float64) for p in ModelingToolkit.unknowns(model)])
	test_point = merge(parameter_values, initial_conditions)

	ordered_test_point = OrderedDict{SymbolicUtils.BasicSymbolic{Real}, Float64}()
	for i in model_ps
		ordered_test_point[i] = parameter_values[i]
	end
	for i in model_states
		ordered_test_point[i] = initial_conditions[i]
	end


	n = Int64(ceil((states_count + ps_count) / length(measured_quantities)) + 2)  #check this is sufficient, for the number of derivatives to take
	#6 didn't work, 7 worked for daisy_ex3 (v3 in particular) - so we changed +1 to +2.  check with A.O.
	n = max(n, 3)
	deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
	unident_dict = Dict()

	jac = nothing
	evaluated_jac = nothing
	DD = nothing

	all_identified = false
	while (!all_identified)
		(evaluated_jac, DD) = (numerical_jacobian(model, measured_quantities, n, unident_dict, varlist, ordered_test_point))
		ns = nullspace(evaluated_jac)

		if (!isempty(ns))
			candidate_plugins_for_unidentified = OrderedDict()
			for i in eachindex(varlist)
				if (!isapprox(norm(ns[i, :]), 0.0, atol = atol))
					candidate_plugins_for_unidentified[varlist[i]] = test_point[varlist[i]]
				end
			end

			println("After making the following substitutions:", unident_dict, " the following are globally unidentifiable:",
				keys(candidate_plugins_for_unidentified))
			if (!isempty(candidate_plugins_for_unidentified))
				p = first(candidate_plugins_for_unidentified)
				deleteat!(varlist, findall(x -> isequal(x, p.first), varlist))
				delete!(ordered_test_point, p.first)
				unident_dict[p.first] = p.second
			else
				all_identified = true
			end
		else
			all_identified = true
		end
	end

	max_rank = rank(evaluated_jac, rtol = rtol)
	while (n > 0)
		n = n - 1
		deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
		reduced_evaluated_jac = deriv_level_view(evaluated_jac, deriv_level, length(measured_quantities))
		r = rank(reduced_evaluated_jac, rtol = rtol)
		if (r < max_rank)
			n = n + 1
			deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
			break
		end
	end
	#at this point, we have a system that identifies what it can
	#now we try to strip it further


	keep_looking = true
	while (keep_looking)
		improvement_found = false
		sorting = collect(deriv_level)
		sorting = sort(sorting, by = (x -> x[2]), rev = true)
		for i in keys(deriv_level)
			if (deriv_level[i] > 0)
				deriv_level[i] = deriv_level[i] - 1
				reduced_evaluated_jac = deriv_level_view(evaluated_jac, deriv_level, length(measured_quantities))

				r = rank(reduced_evaluated_jac, rtol = rtol)
				if (r < max_rank)
					deriv_level[i] = deriv_level[i] + 1
				else
					improvement_found = true
					break
				end
			else
				temp = pop!(deriv_level, i)
				reduced_evaluated_jac = deriv_level_view(evaluated_jac, deriv_level, length(measured_quantities))

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

#handle unidentifiable variables, just substituting for them


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

function hmcs(x)
	return HomotopyContinuation.ModelKit.Variable(Symbol(x))
end


#take out this function
#function print_element_types(v)
#	for elem in v
#		println(typeof(elem))
#	end
#end

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

	println("we trash these: (line 708)")
	display(trash_system)

	return new_system, varlist, trash_system
end

function solveJSwithOptim(input_poly_system, input_varlist)
	resid_counter = 0
	loss = 0

	for i in input_poly_system
		loss = loss + (i)^2
		resid_counter += 1
	end

	lossvars = sort(get_variables(loss), by = string)
	#for i in lossvars
	#	loss += 0.0001 * i^2
	#	resid_counter += 1
	#end
	display(lossvars)
	f_expr = build_function(loss, input_varlist, expression = Val{false})
	f_expr2(u, p) = f_expr(u)
	function f_expr3!(du, u, p)
		du[1] = f_expr(u)
	end

	u0map = ones(Float64, (length(lossvars)))
	for ti in eachindex(u0map)
		u0map[ti] = rand() * 1
	end


	resid_vec = zeros(Float64, resid_counter)

	g = OptimizationFunction(f_expr2, AutoForwardDiff())  #or AutoZygote
	prob = OptimizationProblem(g, u0map)
	sol = Optimization.solve(prob, LBFGS())  #newton was slower
	println("Optimizer solution:")
	display(sol)
	display(sol.original)
	display(sol.retcode)
	#########################################3
	#println(f_expr2(u0map,zeros(Float64, 0)))
	#println("test1")
	#prob4 = NonlinearProblem(NonlinearFunction(f_expr3!),
	#	u0map, zeros(Float64, 0))

	#solnl = NonlinearSolve.solve(prob4,maxiters = 100000)
	#println(solnl.retcode)
	#println(solnl)
	return (sol.u)

end

function solveJSwithMonodromy(poly_system, varlist)
	mangled_varlist = deepcopy(varlist)
	manglingDict = OrderedDict()
	len = length(poly_system)

	for i in eachindex(varlist)
		newvarname = Symbol("_z_" * replace(string(varlist[i]), "(t)" => "_t") * "_d")
		newvar = (@variables $newvarname)[1]
		mangled_varlist[i] = newvar
		manglingDict[Symbolics.unwrap(varlist[i])] = newvar
	end
	for i in eachindex(poly_system)
		poly_system[i] = Symbolics.substitute(Symbolics.unwrap(poly_system[i]), manglingDict)

	end
	string_target = string.(poly_system)
	varlist = mangled_varlist
	string_string_dict = Dict()
	var_string_dict = Dict()
	var_dict = Dict()
	hcvarlist = Vector{HomotopyContinuation.ModelKit.Variable}()

	#println("after mangling:")

	for v in varlist
		vhcs = string(v)
		vhcslong = "hmcs(\"" * vhcs * "\")"

		var_string_dict[v] = vhcs
		vhc = HomotopyContinuation.ModelKit.Variable(Symbol(vhcs))
		var_dict[v] = vhc
		string_string_dict[string(v)] = vhcslong
		push!(hcvarlist, vhc)
	end
	for i in eachindex(string_target)
		string_target[i] = replace(string_target[i], string_string_dict...)
	end
	#display(string_target)
	parsed = eval.(Meta.parse.(string_target))
	@var _mpm[1:len] _mpc[1:len]
	paramlist = Vector{HomotopyContinuation.ModelKit.Variable}()
	for i in 1:len
		#push!(paramlist, _mpm[i])
		push!(paramlist, _mpc[i])
	end
	for i in eachindex(parsed)
		parsed[i] = parsed[i] - _mpc[i]
	end
	HomotopyContinuation.set_default_compile(:all)    #TODO test whether this helps or not
	F = HomotopyContinuation.System(parsed, variables = hcvarlist, parameters = paramlist)
	#println("system we are solving (line 428)")

	#param_final = repeat([1, 0], outer = len)
	param_final = repeat([0.0], outer = len)
	#singlesoln = solveJSwithOptim(poly_system, varlist)
	found_start_pair = false
	pair_attempts = 0
	newx = nothing
	while (!found_start_pair && pair_attempts < 20)  #lots of magic numbers in this section:  20, 5000, 3
		println("is this a start pair? line 824")
		testx, testp = HomotopyContinuation.find_start_pair(F)
		display(testx)
		display(testp)

		println("hopefully, this is a good start pair:")
		newx = HomotopyContinuation.solve(F, testx, start_parameters = testp, target_parameters = param_final, tracker_options = TrackerOptions(automatic_differentiation = 3))
		display(newx)
		startpsoln = solutions(newx)
		display(startpsoln)
		display(param_final)
		pair_attempts += 1
		if (!isempty(startpsoln))
			found_start_pair = true
		end
	end
	result = HomotopyContinuation.monodromy_solve(F, solutions(newx), param_final, show_progress = true, target_solutions_count = 5000, timeout = 600.0, tracker_options = TrackerOptions(automatic_differentiation = 3))#only_nonsingular = false  ,)


	println("results")
	display(F)
	display(result)
	#display(HomotopyContinuation.real_solutions(result))
	solns = HomotopyContinuation.solutions(result)
	complex_flag = false
	#if isempty(solns)
	#	solns = solutions(result, only_nonsingular = false)
	#	complexflag = true
	#end
	if (isempty(solns))
		display("No solutions, failed.")
		return ([], [], [], [])
	end
	display(solns)
	return solns, hcvarlist


end





function solveJSwithNLLS(input_poly_system, input_varlist)

	nl_expr = build_function(input_poly_system, input_varlist, expression = Val{false})
	nl_expr_p(out, u, p) = nl_expr[2](out, u)
	resid_vec = zeros(Float64, length(input_poly_system))
	u0map = ones(Float64, (length(input_varlist)))
	prob5 = NonlinearLeastSquaresProblem(NonlinearFunction(nl_expr_p, resid_prototype = resid_vec), u0map)
	solnlls = NonlinearSolve.solve(prob5, maxiters = 64000)
	println("Here is the solution in NLLS line 732")
	display(solnlls.retcode)
	display(solnlls.stats)

	display(solnlls.original)
	display(solnlls.resid)
	display(solnlls)


end

function diag_solveJSwithHC(input_poly_system, input_varlist, use_monodromy = true)  #the input here is meant to be a polynomial, or eventually rational, system of julia symbolics
	println("starting diag_SolveJSWithHC.  Here is the polynomial system:")
	display(input_poly_system)
	#print_element_types(poly_system)
	println("varlist")
	display(input_varlist)
	#print_element_types(varlist)


	(poly_system, varlist, trivial_vars, trivial_dict) = handle_simple_substitutions(input_poly_system, input_varlist)

	poly_system, varlist, trash = squarify_by_trashing(poly_system, varlist)

	jsvarlist = deepcopy(varlist)
	println("after trivial subst")
	display(poly_system)
	display(varlist)
	display(trivial_dict)




	#@variables _qz_discard1 _qz_discard2
	#expr_fake = Symbolics.value(simplify_fractions(_qz_discard1 / _qz_discard2))
	#op = Symbolics.operation(expr_fake)

	#for i in eachindex(poly_system)
	#	expr = poly_system[i]
	#	expr2 = Symbolics.value(simplify_fractions(poly_system[i]))
	#	if (istree(expr2) && Symbolics.operation(expr2) == op)
	#		poly_system[i], _ = Symbolics.arguments(expr2)
	#	end
	#end

	solns = []
	hcvarlist = []
	if (use_monodromy)
		println("using monodromy, line 917")
		solns, hcvarlist = solveJSwithMonodromy(poly_system, varlist)

	else

		mangled_varlist = deepcopy(varlist)
		manglingDict = OrderedDict()


		for i in eachindex(varlist)
			newvarname = Symbol("_z_" * replace(string(varlist[i]), "(t)" => "_t") * "_d")
			newvar = (@variables $newvarname)[1]
			mangled_varlist[i] = newvar
			manglingDict[Symbolics.unwrap(varlist[i])] = newvar
		end
		for i in eachindex(poly_system)
			poly_system[i] = Symbolics.substitute(Symbolics.unwrap(poly_system[i]), manglingDict)

		end
		string_target = string.(poly_system)
		varlist = mangled_varlist
		string_string_dict = Dict()
		var_string_dict = Dict()
		var_dict = Dict()
		hcvarlist = Vector{HomotopyContinuation.ModelKit.Variable}()

		#println("after mangling:")

		for v in varlist
			vhcs = string(v)
			vhcslong = "hmcs(\"" * vhcs * "\")"

			var_string_dict[v] = vhcs
			vhc = HomotopyContinuation.ModelKit.Variable(Symbol(vhcs))
			var_dict[v] = vhc
			string_string_dict[string(v)] = vhcslong
			push!(hcvarlist, vhc)
		end
		for i in eachindex(string_target)
			string_target[i] = replace(string_target[i], string_string_dict...)
		end
		#display(string_target)
		parsed = eval.(Meta.parse.(string_target))
		HomotopyContinuation.set_default_compile(:all)    #TODO test whether this helps or not
		F = HomotopyContinuation.System(parsed, variables = hcvarlist)
		#println("system we are solving (line 428)")
		result = HomotopyContinuation.solve(F, show_progress = true;) #only_nonsingular = false


		#println("results")
		#display(F)
		#display(result)
		#display(HomotopyContinuation.real_solutions(result))
		solns = HomotopyContinuation.real_solutions(result)
		complex_flag = false
		if isempty(solns)
			solns = solutions(result, only_nonsingular = false)
			complexflag = true
		end
	end

	if (isempty(solns))
		display("No solutions, failed.")
		return ([], [], [], [])
	end
	display(solns)
	return solns, hcvarlist, trivial_dict, jsvarlist
end



function solveJSwithHC(input_poly_system, input_varlist)  #the input here is meant to be a polynomial, or eventually rational, system of julia symbolics
	println("starting SolveJSWithHC.  Here is the polynomial system:")
	display(input_poly_system)
	#print_element_types(poly_system)
	println("varlist")
	display(input_varlist)
	#print_element_types(varlist)


	(poly_system, varlist, trivial_vars, trivial_dict) = handle_simple_substitutions(input_poly_system, input_varlist)

	poly_system, varlist, trash = squarify_by_trashing(poly_system, varlist)

	jsvarlist = deepcopy(varlist)
	println("after trivial subst")
	display(poly_system)
	display(varlist)
	display(trivial_dict)


	#@variables _qz_discard1 _qz_discard2
	#expr_fake = Symbolics.value(simplify_fractions(_qz_discard1 / _qz_discard2))
	#op = Symbolics.operation(expr_fake)

	#for i in eachindex(poly_system)
	#	expr = poly_system[i]
	#	expr2 = Symbolics.value(simplify_fractions(poly_system[i]))
	#	if (istree(expr2) && Symbolics.operation(expr2) == op)
	#		poly_system[i], _ = Symbolics.arguments(expr2)
	#	end
	#end

	mangled_varlist = deepcopy(varlist)
	manglingDict = OrderedDict()


	for i in eachindex(varlist)
		newvarname = Symbol("_z_" * replace(string(varlist[i]), "(t)" => "_t") * "_d")
		newvar = (@variables $newvarname)[1]
		mangled_varlist[i] = newvar
		manglingDict[Symbolics.unwrap(varlist[i])] = newvar
	end
	for i in eachindex(poly_system)
		poly_system[i] = Symbolics.substitute(Symbolics.unwrap(poly_system[i]), manglingDict)

	end
	string_target = string.(poly_system)
	varlist = mangled_varlist
	string_string_dict = Dict()
	var_string_dict = Dict()
	var_dict = Dict()
	hcvarlist = Vector{HomotopyContinuation.ModelKit.Variable}()

	#println("after mangling:")

	for v in varlist
		vhcs = string(v)
		vhcslong = "hmcs(\"" * vhcs * "\")"

		var_string_dict[v] = vhcs
		vhc = HomotopyContinuation.ModelKit.Variable(Symbol(vhcs))
		var_dict[v] = vhc
		string_string_dict[string(v)] = vhcslong
		push!(hcvarlist, vhc)
	end
	for i in eachindex(string_target)
		string_target[i] = replace(string_target[i], string_string_dict...)
	end
	#display(string_target)
	parsed = eval.(Meta.parse.(string_target))
	HomotopyContinuation.set_default_compile(:all)    #TODO test whether this helps or not
	F = HomotopyContinuation.System(parsed, variables = hcvarlist)
	#println("system we are solving (line 428)")
	result = HomotopyContinuation.solve(F, show_progress = true;) #only_nonsingular = false


	#println("results")
	#display(F)
	#display(result)
	#display(HomotopyContinuation.real_solutions(result))
	solns = HomotopyContinuation.real_solutions(result)
	complex_flag = false
	if isempty(solns)
		solns = solutions(result, only_nonsingular = false)
		complexflag = true
	end
	if (isempty(solns))
		display("No solutions, failed.")
		return ([], [], [], [])
	end
	display(solns)
	return solns, hcvarlist, trivial_dict, jsvarlist
end

#this takes a vector of times and select points from it, sort of far apart from each other.
#TODO:  this can be improved, taking the measured_data into account
#TODO:  actually, for now, it's just random (and therefore nondeterministic)
#I haven't tested this (i.e. justified it), but by default, we avoid the endpoints.
# n is assumed to be less than length(vec)

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


function tag_symbol(thesymb, pre_tag, post_tag)
	newvarname = Symbol(pre_tag * replace(string(thesymb), "(t)" => "_t") * post_tag)
	return (@variables $newvarname)[1]
end

function MCHCPE(model::ODESystem, measured_quantities, data_sample, ode_solver; system_solver = solveJSwithHC)
	t = ModelingToolkit.get_iv(model)
	model_eq = ModelingToolkit.equations(model)
	model_states = ModelingToolkit.unknowns(model)
	model_ps = ModelingToolkit.parameters(model)

	t_vector = data_sample["t"]
	time_interval = (minimum(t_vector), maximum(t_vector))
	found_any_solutions = false
	large_num_points = min(length(model_ps), 4, length(t_vector)) + 1
	good_num_points = large_num_points
	time_index_set = []
	solns = []
	good_udict = []
	forward_subst_dict = []
	trivial_dict = []
	final_varlist = []
	trimmed_varlist = []
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
		println("optimal number of points is ", good_num_points)
		display(good_deriv_level)

		time_index_set = pick_points(t_vector, good_num_points)
		println("We picked these points:", time_index_set)
		display(time_index_set)
		full_target = []
		full_varlist = []
		forward_subst_dict = []
		reverse_subst_dict = []
		@variables testing
		for k in time_index_set
			(target_k, varlist_k) = construct_equation_system(model, measured_quantities, data_sample, good_deriv_level, good_udict, good_varlist, good_DD, [k])
			local_subst_dict = OrderedDict{Num, Any}()
			local_subst_dict_reverse = OrderedDict()
			subst_var_list = []

			for i in eachindex(good_DD.states_lhs), j in eachindex(good_DD.states_lhs[i])
				push!(subst_var_list, good_DD.states_lhs[i][j])
			end
			for i in eachindex(model_states)
				push!(subst_var_list, model_states[i])
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
			for i in model_ps
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
		final_varlist = collect(reduce(union!, OrderedSet.(full_varlist))) #does this even work





		solve_result, hcvarlist, trivial_dict, trimmed_varlist = system_solver(final_target, final_varlist)

		solns = solve_result
		if (!isempty(solns))
			found_any_solutions = true
		end
	end

	@named new_model = ODESystem(model_eq, t, model_states, model_ps)
	new_model = complete(new_model)
	lowest_time_index = min(time_index_set...)

	results_vec = []
	local_states_dict_all = []
	for soln_index in eachindex(solns)
		initial_conditions = [1e10 for s in model_states]
		parameter_values = [1e10 for p in model_ps]
		for i in eachindex(model_ps)
			if model_ps[i] in keys(good_udict)
				parameter_values[i] = good_udict[model_ps[i]]
			else

				param_search = forward_subst_dict[1][(model_ps[i])]
				if (param_search in keys(trivial_dict))
					parameter_values[i] = trivial_dict[param_search]
				else
					index = findfirst(isequal(param_search), final_varlist)
					parameter_values[i] = real(solns[soln_index][index]) #TODOdo we ignore the imaginary part?
				end
			end                                                   #what about other vars
		end

		for i in eachindex(model_states)
			if model_states[i] in keys(good_udict)
				initial_conditions[i] = good_udict[model_states[i]]

			else
				#println("line 596")
				#display(Symbolics.wrap(model_states[i]))
				#display(fullvarlist)
				#display(typeof(Symbolics.wrap(model_states[i])))
				#display(varlist[3])
				#display(typeof(varlist[3]))
				#println("line 856")
				#display(lowest_time_index)
				#display(forward_subst_dict[lowest_time_index])
				#display(Symbolics.wrap(model_states[i]))

				#display(reverse_subst_dict[1])
				model_state_search = forward_subst_dict[1][(model_states[i])]
				#				println("line 929")
				#				display(model_states[i])
				#				display(model_state_search)

				if (model_state_search in keys(trivial_dict))
					initial_conditions[i] = trivial_dict[model_state_search]
					#					display(trivial_dict[model_state_search])

				else
					index = findfirst(
						isequal(model_state_search),
						trimmed_varlist)
					#						display(solns[soln_index][index])

					#display(real(solns[soln_index][index]))
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
		for s in model_states
			newstates[s] = ode_solution[Symbol(state_param_map[s])][end]
		end
		push!(results_vec, [collect(values(newstates)); parameter_values])
	end

	return results_vec


end


function HCPE(model::ODESystem, measured_quantities, data_sample, solver, time_index_set = [])

	t = ModelingToolkit.get_iv(model)
	model_eq = ModelingToolkit.equations(model)
	model_states = ModelingToolkit.unknowns(model)
	model_ps = ModelingToolkit.parameters(model)

	t_vector = data_sample["t"]
	time_interval = (minimum(t_vector), maximum(t_vector))

	if (isempty(time_index_set))
		time_index_set = [fld(length(t_vector), 2)]  #TODO add vector handling 

	end
	#testing code

	(deriv_level, unident_dict, varlist, DD) = local_identifiability_analysis(model, measured_quantities)
	#(deriv_level_mp, unident_dict_mp, varlist_mp, DD_mp) = multipoint_local_identifiability_analysis(model, measured_quantities, 1)
	#(deriv_level_mp3, unident_dict_mp3, varlist_mp3, DD_mp3) = multipoint_local_identifiability_analysis(model, measured_quantities, 3)
	#(deriv_level_mp5, unident_dict_mp5, varlist_mp5, DD_mp5) = multipoint_local_identifiability_analysis(model, measured_quantities, 5)
	#(deriv_level_mp10, unident_dict_mp10, varlist_mp10, DD_mp10) = multipoint_local_identifiability_analysis(model, measured_quantities, 10)

	#display("testing MP vs single point (SP, 1, 3, 5, 10)")
	#display(deriv_level)
	#display(deriv_level_mp)
	#display(deriv_level_mp3)
	#display(deriv_level_mp5)
	#display(deriv_level_mp10)

	large_num_points = min(length(model_ps), 20, length(t_vector))
	good_num_points = large_num_points
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
	#println("Optimal number of points is ", good_num_points)
	#display(good_deriv_level)


	#end testing code

	(target, fullvarlist) = construct_equation_system(model, measured_quantities, data_sample, deriv_level, unident_dict, varlist, DD)

	solve_result, hcvarlist = solveJSwithHC(target, fullvarlist)
	solns = solve_result


	@named new_model = ODESystem(model_eq, t, model_states, model_ps)
	new_model = complete(new_model)
	lowest_time_index = min(time_index_set...)

	results_vec = []
	local_states_dict_all = []
	for soln_index in eachindex(solns)
		initial_conditions = [1e10 for s in model_states]
		parameter_values = [1e10 for p in model_ps]
		for i in eachindex(model_ps)
			if model_ps[i] in keys(unident_dict)
				parameter_values[i] = unident_dict[model_ps[i]]
			else

				index = findfirst(isequal(Symbolics.wrap(model_ps[i])), fullvarlist)
				parameter_values[i] = real(solns[soln_index][index]) #TODOdo we ignore the imaginary part?
			end                                                   #what about other vars
		end

		for i in eachindex(model_states)
			if model_states[i] in keys(unident_dict)
				initial_conditions[i] = unident_dict[model_states[i]]
			else
				#println("line 596")
				#display(model_states[i])
				#display(Symbolics.wrap(model_states[i]))
				#display(fullvarlist)
				#display(typeof(Symbolics.wrap(model_states[i])))
				#display(varlist[3])
				#display(typeof(varlist[3]))
				index = findfirst(
					isequal(Symbolics.wrap(model_states[i])),
					fullvarlist)

				#display(index)
				#display(real(solns[soln_index][index]))
				initial_conditions[i] = real(solns[soln_index][index]) #see above
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

		ode_solution = ModelingToolkit.solve(prob, solver, abstol = 1e-14, reltol = 1e-14)

		state_param_map = (Dict(x => replace(string(x), "(t)" => "")
								for x in ModelingToolkit.unknowns(model)))
		newstates = OrderedDict()
		for s in model_states
			newstates[s] = ode_solution[Symbol(state_param_map[s])][end]
		end
		push!(results_vec, [collect(values(newstates)); parameter_values])
	end

	return results_vec


end




function ODEPEtestwrapper(model::ODESystem, measured_quantities, data_sample, ode_solver; system_solver = solveJSwithHC, abstol = 1e-12, reltol = 1e-12)

	model_states = ModelingToolkit.unknowns(model)
	model_ps = ModelingToolkit.parameters(model)
	tspan = (data_sample["t"][begin], data_sample["t"][end])

	param_dict = Dict(model_ps .=> ones(length(model_ps)))

	states_dict = Dict(model_states .=> ones(length(model_states)))

	solved_res = []
	newres = ParameterEstimationResult(param_dict,
		states_dict, tspan[1], nothing, nothing, length(data_sample["t"]), tspan[1])
	results_vec = MCHCPE(model, measured_quantities, data_sample, ode_solver, system_solver = system_solver)




	for each in results_vec
		push!(solved_res, deepcopy(newres))


		for (key, value) in solved_res[end].parameters
			solved_res[end].parameters[key] = 1e30
		end
		for (key, value) in solved_res[end].states
			solved_res[end].states[key] = 1e30
		end
		#println(newres)
		i = 1
		for (key, value) in solved_res[end].states
			solved_res[end].states[key] = each[i]
			i += 1
		end


		for (key, value) in solved_res[end].parameters
			solved_res[end].parameters[key] = each[i]
			i += 1
		end
		ic = deepcopy(solved_res[end].states)
		ps = deepcopy(solved_res[end].parameters)
		prob = ODEProblem(complete(model), ic, tspan, ps)

		ode_solution = ModelingToolkit.solve(prob, ode_solver, saveat = data_sample["t"], abstol = abstol, reltol = reltol)
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
		solved_res[end].err = err


	end
	return solved_res
end



export MCHCPE, HCPE, ODEPEtestwrapper, ParameterEstimationResult, sample_data, diag_solveJSwithHC

#later, disable output of the compile_workload

@recompile_invalidations begin
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
		data_sample = sample_data(model, measured_quantities, [-1.0, 1.0], p_true, ic, 19, solver = Vern9())

		ret = ODEPEtestwrapper(model, measured_quantities, data_sample, Vern9())

		display(ret)
	end
end


end
