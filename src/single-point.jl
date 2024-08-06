

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


