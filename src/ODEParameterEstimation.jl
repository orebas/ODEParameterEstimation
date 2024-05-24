module ODEParameterEstimation

# Write your package code here.

using ModelingToolkit, DifferentialEquations
using LinearAlgebra
using OrderedCollections
using BaryRational
#using Suppressor  #not thread safe?
using HomotopyContinuation
using TaylorDiff
using PrecompileTools
#using ParameterEstimation



include("bary_derivs.jl")
#include("nemo2hc-rewrite.jl")


function sample_data(model::ModelingToolkit.ODESystem,
	measured_data::Vector{ModelingToolkit.Equation},
	time_interval::Vector{T},
	p_true::Vector{T},
	u0::Vector{T},
	num_points::Int;
	uneven_sampling = false,
	uneven_sampling_times = Vector{T}(),
	solver = Vern9(), inject_noise = false, mean_noise = 0,
	stddev_noise = 1, abstol = 1e-14, reltol = 1e-14) where {T <: Number}
	if uneven_sampling
		if length(uneven_sampling_times) == 0
			error("No uneven sampling times provided")
		end
		if length(uneven_sampling_times) != num_points
			error("Uneven sampling times must be of length num_points")
		end
		sampling_times = uneven_sampling_times
	else
		sampling_times = range(time_interval[1], time_interval[2], length = num_points)
	end
	problem = ODEProblem(ModelingToolkit.complete(model), u0, time_interval, Dict(ModelingToolkit.parameters(model) .=> p_true))
	solution_true = ModelingToolkit.solve(problem, solver,
		saveat = sampling_times;
		abstol, reltol)
	data_sample = OrderedDict{Any, Vector{T}}(Num(v.rhs) => solution_true[Num(v.rhs)]
											  for v in measured_data)
	if inject_noise
		for (key, sample) in data_sample
			data_sample[key] = sample + randn(num_points) .* stddev_noise .+ mean_noise
		end
	end
	data_sample["t"] = sampling_times
	return data_sample
end


function print_element_types(v)
	for elem in v
		println(typeof(elem))
	end
end

mutable struct ParameterEstimationResult
	parameters::AbstractDict
	states::AbstractDict
	at_time::Float64
	err::Union{Nothing, Float64}
	return_code::Any
	datasize::Int64
	report_time::Any
end



function unpack_ODE(model::ODESystem)
	return ModelingToolkit.get_iv(model), deepcopy(ModelingToolkit.equations(model)), ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model)
end

#below constructs fully substituted jacobian 
#unident_dict is a dict of globally unidentifiable variables, and the substitution for them
#deriv_level is a dict of 
#(indices into measured_quantites =>   level of derivative to include)

function calc_jacobian(model::ODESystem, measured_quantities_in, deriv_level, unident_dict, varlist)

	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities = deepcopy(measured_quantities_in)

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)

	#handle unident stuff

	for i in eachindex(model_eq)
		model_eq[i] = substitute(model_eq[i].lhs, unident_dict) ~ substitute(model_eq[i].rhs, unident_dict)
	end
	for i in eachindex(measured_quantities)
		measured_quantities[i] = substitute(measured_quantities[i].lhs, unident_dict) ~ substitute(measured_quantities[i].rhs, unident_dict)
	end


	max_deriv = max(4, 1 + maximum(collect(values(deriv_level))))




end


function numerical_jacobian(model::ODESystem, measured_quantities_in, max_deriv_level, unident_dict, varlist, values)

	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities = deepcopy(measured_quantities_in)

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)
	subst_dict = Dict()

	#handle unident stuff
	for i in eachindex(model_eq)
		model_eq[i] = substitute(model_eq[i].lhs, unident_dict) ~ substitute(model_eq[i].rhs, unident_dict)
	end
	for i in eachindex(measured_quantities)
		measured_quantities[i] = substitute(measured_quantities[i].lhs, unident_dict) ~ substitute(measured_quantities[i].rhs, unident_dict)
	end

	states_lhs = [[eq.lhs for eq in model_eq], expand_derivatives.(D.([eq.lhs for eq in model_eq]))]
	states_rhs = [[eq.rhs for eq in model_eq], expand_derivatives.(D.([eq.rhs for eq in model_eq]))]
	for i in 1:(max_deriv_level-3)
		push!(states_lhs, expand_derivatives.(D.(states_lhs[end])))  #this constructs the derivatives of the state equations
		push!(states_rhs, expand_derivatives.(D.(states_rhs[end])))
	end
	for i in eachindex(states_rhs), j in eachindex(states_rhs[i])
		states_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(states_rhs[i][j]))
		states_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(states_lhs[i][j])) #applies differential operator everywhere.  
		#subst_dict[states_lhs[i][j]] = states_rhs[i][j]   #this constructs a dict which substitutes the nth derivative of each state variable with the of each state equation
	end

	obs_lhs = [[eq.lhs for eq in measured_quantities], expand_derivatives.(D.([eq.lhs for eq in measured_quantities]))]
	obs_rhs = [[eq.rhs for eq in measured_quantities], expand_derivatives.(D.([eq.rhs for eq in measured_quantities]))]

	#obs_lhs = [Vector{Num}([eq.lhs for eq in measured_quantities]), Vector{Num}(expand_derivatives.(D.([eq.lhs for eq in measured_quantities])))]
	#obs_rhs = [Vector{Num}([eq.rhs for eq in measured_quantities]), Vector{Num}(expand_derivatives.(D.([eq.rhs for eq in measured_quantities])))]

	for i in 1:(max_deriv-2)
		push!(obs_lhs, expand_derivatives.(D.(obs_lhs[end])))
		push!(obs_rhs, expand_derivatives.(D.(obs_rhs[end])))
	end

	for i in eachindex(obs_rhs), j in eachindex(obs_rhs[i])
		obs_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(obs_rhs[i][j]))
		obs_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(obs_lhs[i][j]))
	end

	function f(values_dict)
		evaluated_subst_dict = deepcopy(values_dict)
		for i in eachindex(states_rhs)
			for j in eachindex(states_rhs[i])
				evaluated_subst_dict[states_lhs[i][j]] = substitute(states_rhs[i][j], evaluated_subst_dict)
			end
		end

		obs_deriv_vals = [substitute(obs_rhs[i][j], evaluated_subst_dict) for i in eachindex(obs_rhs), j in eachindex(obs_rhs[i])]
		return obs_deriv_vals
	end
	


end



function construct_substituted_jacobian(
	model::ODESystem, measured_quantities_in, deriv_level, unident_dict, varlist)

	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities = deepcopy(measured_quantities_in)

	states_count = length(model_states)
	ps_count = length(model_ps)
	D = Differential(t)
	subst_dict = Dict()

	#handle unident stuff
	for i in eachindex(model_eq)
		model_eq[i] = substitute(model_eq[i].lhs, unident_dict) ~ substitute(model_eq[i].rhs, unident_dict)
	end
	for i in eachindex(measured_quantities)
		measured_quantities[i] = substitute(measured_quantities[i].lhs, unident_dict) ~ substitute(measured_quantities[i].rhs, unident_dict)
	end

	max_deriv = max(7, 1 + maximum(collect(values(deriv_level))))

	states_lhs = [[eq.lhs for eq in model_eq], expand_derivatives.(D.([eq.lhs for eq in model_eq]))]
	states_rhs = [[eq.rhs for eq in model_eq], expand_derivatives.(D.([eq.rhs for eq in model_eq]))]
	for i in 1:(max_deriv-3)
		push!(states_lhs, expand_derivatives.(D.(states_lhs[end])))  #this constructs the derivatives of the state equations
		push!(states_rhs, expand_derivatives.(D.(states_rhs[end])))
	end
	for i in eachindex(states_rhs), j in eachindex(states_rhs[i])
		states_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(states_rhs[i][j]))
		states_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(states_lhs[i][j])) #applies differential operator everywhere.  
		subst_dict[states_lhs[i][j]] = states_rhs[i][j]   #this constructs a dict which substitutes the nth derivative of each state variable with the of each state equation
	end


	obs_lhs = [[eq.lhs for eq in measured_quantities], expand_derivatives.(D.([eq.lhs for eq in measured_quantities]))]
	obs_rhs = [[eq.rhs for eq in measured_quantities], expand_derivatives.(D.([eq.rhs for eq in measured_quantities]))]

	#obs_lhs = [Vector{Num}([eq.lhs for eq in measured_quantities]), Vector{Num}(expand_derivatives.(D.([eq.lhs for eq in measured_quantities])))]
	#obs_rhs = [Vector{Num}([eq.rhs for eq in measured_quantities]), Vector{Num}(expand_derivatives.(D.([eq.rhs for eq in measured_quantities])))]

	for i in 1:(max_deriv-2)
		push!(obs_lhs, expand_derivatives.(D.(obs_lhs[end])))
		push!(obs_rhs, expand_derivatives.(D.(obs_rhs[end])))
	end

	for i in eachindex(obs_rhs), j in eachindex(obs_rhs[i])
		obs_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(obs_rhs[i][j]))
		obs_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(obs_lhs[i][j]))
	end

	for s in 1:max_deriv
		for i in eachindex(obs_rhs), j in eachindex(obs_rhs[i])
			#println("line 140")
			#display(obs_rhs[i][j])
			result = substitute(obs_rhs[i][j], subst_dict)
			#display(result)
			#display(typeof(result))
			#display(typeof(result) <: Number)


			if typeof(result) <: Number
				#display(typeof(result))
				#display(result)
				templ = Symbolics.Term(Symbolics.sqrt, [0])
				if (isequal(result, 0))  #TODO: every other case will fail.
					templ = Symbolics.Term(Symbolics.sqrt, [0])
				else
					if typeof(result) <: Int64
						#println("FAIL")
						#						@variables dummy1
						#						@variables dummy2
						#						dumeq = [ dummy1 ~ dummy2 /dummy2]
						#						dumeq[1].lhs = dumeq[2].rhs
						#display(dumeq[1])
						#display(typeof(dumeq[1]))
						#symone = dumeq[1].rhs
						symone = SymbolicUtils.Term{Real}(identity, [1.0])

						templ = symone * result

						#display(typeof(symone))
						#display(typeof(templ))
						#display(symone)
						#display(templ)
						obs_rhs[i][j] = templ
					else
						#println("line 180")
						templ = SymbolicUtils.Term{Real}(identity, [result])
						#display(templ)
						#display(typeof(templ))
						#templ = (Symbolics.wrap(Symbolics.BasicSymbolic{Real}(result)))
						#display(templ)
						#display(typeof(templ))
					end
				end
				#println("line 184")
				#display(templ)

				#display(typeof(templ))
				#display(typeof(obs_rhs[i][j]))
				#display(obs_rhs[i][j])
				templ = Symbolics.unwrap(templ)
				obs_rhs[i][j] = templ  #type = SymbolicUtils.BasicSymbolic{Real}
			else
				obs_rhs[i][j] = result
			end
		end
	end
	target = []  # TODO give this a type later
	for (key, value) in deriv_level  # 0 means include the obs, 1 means first derivative
		push!(target, obs_rhs[1][key])
		for i in 1:value
			push!(target, obs_rhs[i+1][key])
		end
	end

	return ModelingToolkit.jacobian(target, varlist)


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

	n = Int64(ceil((states_count + ps_count) / length(measured_quantities)) + 2)  #check this is sufficient, for the number of derivatives to take
	#6 didn't work, 7 worked for daisy_ex3 (v3 in particular)
	n = max(n, 3)
	println("we decided to take this many derivatives: ", n)
	deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
	unident_dict = Dict()

	jac = nothing
	evaluated_jac = nothing
	#jac = construct_substituted_jacobian(model, measured_quantities, deriv_level, unident_dict, varlist)
	#evaluated_jac = Symbolics.value.(substitute.(jac, Ref(test_point)))

	#ns = nullspace(evaluated_jac)
	all_identified = false
	while (!all_identified)
		jac = construct_substituted_jacobian(model, measured_quantities, deriv_level, unident_dict, varlist)
		evaluated_jac = Symbolics.value.(substitute.(jac, Ref(test_point)))

		ns = nullspace(evaluated_jac)


		if (!isempty(ns))
			candidate_plugins_for_unidentified = OrderedDict()
			for i in eachindex(varlist)
				if (!isapprox(ns[i], 0.0, atol = atol))
					candidate_plugins_for_unidentified[varlist[i]] = test_point[varlist[i]]
				end
			end
			if (!isempty(candidate_plugins_for_unidentified))
				p = first(candidate_plugins_for_unidentified)
				deleteat!(varlist, findall(x -> isequal(x, p.first), varlist))
				unident_dict[p.first] = p.second
			else
				all_identified = true
			end
		else
			all_identified = true
		end
	end

	#jac = construct_substituted_jacobian(model, measured_quantities, deriv_level, unident_dict, varlist)
	#evaluated_jac = Symbolics.value.(substitute.(jac, Ref(test_point)))
	max_rank = rank(evaluated_jac, rtol = rtol)

	while (n > 0)
		n = n - 1
		deriv_level = Dict([p => n for p in 1:length(measured_quantities)])
		jac = construct_substituted_jacobian(model, measured_quantities, deriv_level, unident_dict, varlist)
		evaluated_jac = Symbolics.value.(substitute.(jac, Ref(test_point)))
		r = rank(evaluated_jac, rtol = rtol)
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
		for i in keys(deriv_level)
			if (deriv_level[i] > 0)
				deriv_level[i] = deriv_level[i] - 1
				jac = construct_substituted_jacobian(model, measured_quantities, deriv_level, unident_dict, varlist)
				evaluated_jac = Symbolics.value.(substitute.(jac, Ref(test_point)))
				r = rank(evaluated_jac, rtol = rtol)
				if (r < max_rank)
					deriv_level[i] = deriv_level[i] + 1
				else
					improvement_found = true
				end
			else
				temp = pop!(deriv_level, i)
				jac = construct_substituted_jacobian(model, measured_quantities, deriv_level, unident_dict, varlist)
				evaluated_jac = Symbolics.value.(substitute.(jac, Ref(test_point)))
				r = rank(evaluated_jac, rtol = rtol)
				if (r < max_rank)
					deriv_level[i] = temp
				else
					improvement_found = true
				end
			end
		end
		keep_looking = improvement_found
	end
	return (deriv_level, unident_dict, varlist)
end

function construct_equation_system(model::ODESystem, measured_quantities_in, data_sample,
	deriv_level, unident_dict, varlist,
	time_index_set = nothing)

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
	println("line 238")
	display(model_eq)
	display(unident_dict)

	for i in eachindex(model_eq)
		model_eq[i] = substitute(model_eq[i].lhs, unident_dict) ~ substitute(model_eq[i].rhs, unident_dict)
	end
	for i in eachindex(measured_quantities)
		measured_quantities[i] = substitute(measured_quantities[i].lhs, unident_dict) ~ substitute(measured_quantities[i].rhs, unident_dict)
	end
	display(model_eq)

	max_deriv = max(4, 1 + maximum(collect(values(deriv_level))))

	states_lhs = [[eq.lhs for eq in model_eq], expand_derivatives.(D.([eq.lhs for eq in model_eq]))]
	states_rhs = [[eq.rhs for eq in model_eq], expand_derivatives.(D.([eq.rhs for eq in model_eq]))]
	for i in 1:(max_deriv-3)
		push!(states_lhs, expand_derivatives.(D.(states_lhs[end])))  #this constructs the derivatives of the state equations
		push!(states_rhs, expand_derivatives.(D.(states_rhs[end])))
	end
	for i in eachindex(states_rhs), j in eachindex(states_rhs[i])
		states_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(states_rhs[i][j]))
		states_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(states_lhs[i][j])) #applies differential operator everywhere. 
	end


	obs_lhs = [[eq.lhs for eq in measured_quantities], expand_derivatives.(D.([eq.lhs for eq in measured_quantities]))]
	obs_rhs = [[eq.rhs for eq in measured_quantities], expand_derivatives.(D.([eq.rhs for eq in measured_quantities]))]

	for i in 1:(max_deriv-2)
		push!(obs_lhs, expand_derivatives.(D.(obs_lhs[end])))
		push!(obs_rhs, expand_derivatives.(D.(obs_rhs[end])))
	end

	for i in eachindex(obs_rhs), j in eachindex(obs_rhs[i])
		obs_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(obs_rhs[i][j]))
		obs_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(obs_lhs[i][j]))
	end  #this obs is completely unsubstituted

	target = []  # TODO give this a type later
	for (key, value) in deriv_level  # 0 means include the obs, 1 means first derivative
		push!(target, obs_rhs[1][key] -
					  nth_deriv_at(interpolants[measured_quantities[key].rhs], 0, t_vector[time_index]))
		for i in 1:value
			push!(target, obs_rhs[i+1][key] -
						  nth_deriv_at(interpolants[measured_quantities[key].rhs], i, t_vector[time_index]))
		end
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
			for j in eachindex(states_lhs), k in eachindex(states_lhs[j])
				if (isequal(states_lhs[j][k], i))
					push!(target, states_lhs[j][k] - states_rhs[j][k])
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


	println("starting SolveJSWithHC")
	display(poly_system)
	#print_element_types(poly_system)
	println("varlist")
	display(varlist)
	#print_element_types(varlist)

	@variables _qz_discard1 _qz_discard2
	expr_fake = Symbolics.value(simplify_fractions(_qz_discard1 / _qz_discard2))
	op = Symbolics.operation(expr_fake)


	for i in eachindex(poly_system)
		#println("attempting to simplify")
		#display(poly_system[i])
		expr = poly_system[i]
		expr2 = Symbolics.value(simplify_fractions(poly_system[i]))
		if (Symbolics.operation(expr2) == op)
			poly_system[i], _ = Symbolics.arguments(expr2)
		end
		#display(poly_system[i])

	end
	mangled_varlist = deepcopy(varlist)
	manglingDict = OrderedDict()


	for i in eachindex(mangled_varlist)
		newvarname = Symbol("_qz_xy_" * replace(string(mangled_varlist[i]), "(t)" => "_t"))
		newvar = (@variables $newvarname)[1]
		#display(newvar)
		mangled_varlist[i] = newvar
		manglingDict[varlist[i]] = newvar
	end
	for i in eachindex(poly_system)
		poly_system[i] = substitute(poly_system[i], manglingDict)
	end
	#println("line 390")
	#display(manglingDict)
	#display(poly_system)
	string_target = string.(poly_system)
	varlist = mangled_varlist
	string_string_dict = Dict()
	var_string_dict = Dict()
	var_dict = Dict()
	hcvarlist = Vector{HomotopyContinuation.ModelKit.Variable}()
	for v in varlist
		#display(v)
		#		vhcs = replace(string(v), "(t)" => "_t" * string(time_index)) * "_hc"
		#vhcslong = "HomotopyContinuation.ModelKit.Variable(Symbol(\"" * vhcs * "\"))"
		vhcs = string(v)
		vhcslong = "hmcs(\"" * vhcs * "\")"

		var_string_dict[v] = vhcs
		vhc = HomotopyContinuation.ModelKit.Variable(Symbol(vhcs))
		var_dict[v] = vhc
		#string_string_dict[string(v)] = vhcslong
		#if (contains(string(v), "t"))
		string_string_dict[string(v)] = vhcslong
		#else
		#	string_string_dict[Regex("\\b(?:\\d+)?" * string(v) * "\\b")] = vhcslong
		#end
		push!(hcvarlist, vhc)
	end
	#display(string_string_dict)
	for i in eachindex(string_target)
		string_target[i] = replace(string_target[i], string_string_dict...)
	end
	#display(string_target)
	parsed = eval.(Meta.parse.(string_target))
	HomotopyContinuation.set_default_compile(:all)
	#display(hcvarlist)
	F = HomotopyContinuation.System(parsed, variables = hcvarlist)
	println("system we are solving (line 428)")
	result = HomotopyContinuation.solve(F, show_progress = true) #only_nonsingular = false


	println("results")
	display(F)
	display(result)
	display(HomotopyContinuation.real_solutions(result))
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
	#display(t_vector)
	time_interval = (minimum(t_vector), maximum(t_vector))

	if (isempty(time_index_set))
		time_index_set = [fld(length(t_vector), 2)]  #TODO add vector handling 
		#println("line 548")
		#display(time_index_set)
	end

	(deriv_level, unident_dict, varlist) = local_identifiability_analysis(model, measured_quantities)
	println("line 561")
	display(varlist)
	display(deriv_level)
	display(unident_dict)
	(target, fullvarlist) = construct_equation_system(model, measured_quantities, data_sample, deriv_level, unident_dict, varlist)

	#println("line 554")
	#display(target)
	#display(fullvarlist)

	solve_result, hcvarlist = solveJSwithHC(target, fullvarlist)
	solns = solve_result

	#println("hcvarlist")
	#display(hcvarlist)

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
				#display("line 578")
				#display(model_ps[i])
				#display(varlist)

				index = findfirst(isequal(Symbolics.wrap(model_ps[i])), fullvarlist)
				#display(index)
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
				err += norm((ode_solution(data_sample["t"])[key]) .- sample)
			end
			err /= length(data_sample)
		else
			err = 1e+10
		end
		solved_res[end].err = err


	end
	return solved_res
end

#the below function exists for compatibility with testing against ParameterEstimation.jl
function LIANPEWrapper(model::ODESystem, measured_quantities, data_sample, solver, oldres)

	newres = Vector{ParameterEstimation.EstimationResult}()
	lianres_vec = HCPE(model, measured_quantities, data_sample, solver, [])
	(deriv_level, unident_dict, varlist) = local_identifiability_analysis(model, measured_quantities)

	#display(lianres_vec)
	for each in lianres_vec
		push!(newres, Base.deepcopy(oldres))

		for (key, value) in newres[end].parameters
			newres[end].parameters[key] = 1e30
		end
		for (key, value) in newres[end].states
			newres[end].states[key] = 1e30
		end
		#println(newres)
		i = 1
		for (key, value) in newres[end].states
			newres[end].states[key] = each[i]
			i += 1
		end


		for (key, value) in newres[end].parameters
			newres[end].parameters[key] = each[i]
			i += 1
		end
	end
	fake_inputs = Vector{Equation}()

	ParameterEstimation.solve_ode!(model, newres, fake_inputs, data_sample, solver = solver, abstol = 1e-12, reltol = 1e-12)

	println(newres)
	return newres
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
