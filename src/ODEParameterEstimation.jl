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
	expr_fake = Symbolics.value(simplify_fractions(_qz_discard1 / _qz_discard2))
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



function populate_derivatives(model::ODESystem, measured_quantities_in, max_deriv_level, unident_dict)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities = deepcopy(measured_quantities_in)


	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)

	DD = DerivativeData([], [], [], [], [], [], [], [])

	#First, we fully substitute values we have chosen for an unidentifiable variables.
	for i in eachindex(model_eq)
		model_eq[i] = substitute(model_eq[i].lhs, unident_dict) ~ substitute(model_eq[i].rhs, unident_dict)
	end
	for i in eachindex(measured_quantities)
		measured_quantities[i] = substitute(measured_quantities[i].lhs, unident_dict) ~ substitute(measured_quantities[i].rhs, unident_dict)
	end


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

function numerical_jacobian(model::ODESystem, measured_quantities_in, max_deriv_level, unident_dict, varlist, values_dict, DD = :nothing)
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
	function f(values_vec)
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
	return Matrix{Float64}(matrix), DD #at some point, check if it makes sense to use sparse arrays here.

end




function deriv_level_view(evaluated_jac, deriv_level, num_obs)
	function linear_index(which_obs, deriv_level)
		return deriv_level * num_obs + which_obs
	end
	view_array = []
	for (which_observable, max_deriv_level) in deriv_level
		for j in 0:max_deriv_level
			push!(view_array, linear_index(which_observable, j))
		end
	end

	return view(evaluated_jac, view_array, :)

end

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
	println("we decided to take this many derivatives: ", n)
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

function construct_equation_system(model::ODESystem, measured_quantities_in, data_sample,
	deriv_level, unident_dict, varlist, DD, time_index_set = nothing)

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
	for i in eachindex(model_eq)
		model_eq[i] = substitute(model_eq[i].lhs, unident_dict) ~ substitute(model_eq[i].rhs, unident_dict)
	end
	for i in eachindex(measured_quantities)
		measured_quantities[i] = substitute(measured_quantities[i].lhs, unident_dict) ~ substitute(measured_quantities[i].rhs, unident_dict)
	end

	max_deriv = max(4, 1 + maximum(collect(values(deriv_level))))

	#We begin building a systme of equations which will be solved, e.g. by homotopoy continuation.
	#the first set of equations, built below, constraints the observables values and their derivatives 
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

	for i in eachindex(target)
		target[i] = substitute(target[i], interpolated_values_dict)
	end

	#Now, we scan for state variables and their derivatives we need values for.
	#We add precisely the state variables we need and no more.
	#This forces the system to by square.
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

	return target, collect(vars_needed)

end

function hmcs(x)
	return HomotopyContinuation.ModelKit.Variable(Symbol(x))
end


function solveJSwithHC(poly_system, varlist)  #the input here is meant to be a polynomial, or eventually rational, system of julia symbolics
	println("starting SolveJSWithHC.  Here is the polynomial system:")
	display(poly_system)
	#print_element_types(poly_system)
	println("varlist")
	display(varlist)
	#print_element_types(varlist)

	@variables _qz_discard1 _qz_discard2
	expr_fake = Symbolics.value(simplify_fractions(_qz_discard1 / _qz_discard2))
	op = Symbolics.operation(expr_fake)


	for i in eachindex(poly_system)
		expr = poly_system[i]
		expr2 = Symbolics.value(simplify_fractions(poly_system[i]))
		if (Symbolics.operation(expr2) == op)
			poly_system[i], _ = Symbolics.arguments(expr2)
		end
	end

	mangled_varlist = deepcopy(varlist)
	manglingDict = OrderedDict()


	for i in eachindex(mangled_varlist)
		newvarname = Symbol("_qz_xy_" * replace(string(mangled_varlist[i]), "(t)" => "_t"))
		newvar = (@variables $newvarname)[1]
		mangled_varlist[i] = newvar
		manglingDict[varlist[i]] = newvar
	end
	for i in eachindex(poly_system)
		poly_system[i] = substitute(poly_system[i], manglingDict)
	end
	string_target = string.(poly_system)
	varlist = mangled_varlist
	string_string_dict = Dict()
	var_string_dict = Dict()
	var_dict = Dict()
	hcvarlist = Vector{HomotopyContinuation.ModelKit.Variable}()
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
	parsed = eval.(Meta.parse.(string_target))
	HomotopyContinuation.set_default_compile(:all)
	F = HomotopyContinuation.System(parsed, variables = hcvarlist)
	println("system we are solving (line 428)")
	result = HomotopyContinuation.solve(F, show_progress = true) #only_nonsingular = false


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
		return
	end
	display(solns)
	return solns, hcvarlist
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




function ODEPEtestwrapper(model::ODESystem, measured_quantities, data_sample, solver, abstol = 1e-12, reltol = 1e-12)

	model_states = ModelingToolkit.unknowns(model)
	model_ps = ModelingToolkit.parameters(model)
	tspan = (data_sample["t"][begin], data_sample["t"][end])

	param_dict = Dict(model_ps .=> ones(length(model_ps)))

	states_dict = Dict(model_states .=> ones(length(model_states)))

	solved_res = []
	newres = ParameterEstimationResult(param_dict,
		states_dict, tspan[1], nothing, nothing, length(data_sample["t"]), tspan[1])
	results_vec = HCPE(model, measured_quantities, data_sample, solver, [])




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

		ode_solution = ModelingToolkit.solve(prob, solver, saveat = data_sample["t"], abstol = abstol, reltol = reltol)
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



export HCPE, ODEPEtestwrapper, ParameterEstimationResult, sample_data

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
