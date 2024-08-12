using DelimitedFiles


### from claude
#=function create_debug_callback(filename="monodromy_debug.csv")
	# Initialize the debug file with headers
	open(filename, "w") do io
		writedlm(io, ["Iteration" "NumSolutions" "NewSolutions" "UniquenessTolerance"], ',')
	end

	last_num_solutions = 0
	iteration = 0

	function debug_callback(results)
		global last_num_solutions, iteration
		iteration += 1
		current_num_solutions = length(results)
		new_solutions = current_num_solutions - last_num_solutions

		# Estimate the uniqueness tolerance used
		if !isempty(results)
			last_result = results[end]
			tol_estimate = uniqueness_rtol(last_result)
		else
			tol_estimate = NaN
		end

		# Append debug information to the file
		open(filename, "a") do io
			writedlm(io, [iteration current_num_solutions new_solutions tol_estimate], ',')
		end

		last_num_solutions = current_num_solutions

		# Return false to continue the monodromy process
		return false
	end

	return debug_callback
end
=#
###end claude

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

	#param_final = repeat([1, 0], outer = len)
	param_final = repeat([0.0], outer = len)
	found_start_pair = false
	pair_attempts = 0
	newx = nothing
	while (!found_start_pair && pair_attempts < 50)  #lots of magic numbers in this section:  20, 5000, 3
		#println("is this a start pair? line 824")
		testx, testp = HomotopyContinuation.find_start_pair(F)
		#display(testx)
		#display(testp)

		#println("hopefully, this is a good start pair:")
		newx = HomotopyContinuation.solve(F, testx, start_parameters = testp, target_parameters = param_final, tracker_options = TrackerOptions(automatic_differentiation = 3))
		#display(newx)
		startpsoln = solutions(newx)
		#display(startpsoln)
		#display(param_final)
		pair_attempts += 1
		if (!isempty(startpsoln))
			found_start_pair = true
		end
	end
	println("starting monodromy solve (line 74)")
	#debug_cb = create_debug_callback("my_debug_output.csv")
	function simpleprinter(x)
		println("BLAH")
		display(x)
		return false
	end
	result = HomotopyContinuation.monodromy_solve(F, solutions(newx), param_final,
		show_progress = true,
		#target_solutions_count = 5000,
		timeout = 120.0,
		max_loops_no_progress = 20,
		#loop_finished_callback = debug_cb,
		#loop_finished_callback = simpleprinter,
		unique_points_rtol = 1e-6,
		unique_points_atol = 1e-6,
		tracker_options = TrackerOptions(automatic_differentiation = 3))#only_nonsingular = false  ,)


	#println("results")
	#display(F)
	#display(result)
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

	#display(solns)
	return solns, hcvarlist


end






function solveJSwithHC(input_poly_system, input_varlist, use_monodromy = true, display_system = false)  #the input here is meant to be a polynomial, or eventually rational, system of julia symbolics
	if (display_system)
		println("starting solveJSWithHC.  Here is the polynomial system:")
		display(input_poly_system)
		#print_element_types(poly_system)
		println("varlist")
		display(input_varlist)
		#print_element_types(varlist)
	end

	(poly_system, varlist, trivial_vars, trivial_dict) = handle_simple_substitutions(input_poly_system, input_varlist)

	poly_system, varlist, trash = squarify_by_trashing(poly_system, varlist)

	jsvarlist = deepcopy(varlist)
	if (display_system)
		println("after trivial subst")
		display(poly_system)
		display(varlist)
		display(trivial_dict)
	end
	solns = []
	hcvarlist = []
	if (use_monodromy)
		#println("using monodromy, line 917")
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



function discarded_solveJSwithHC(input_poly_system, input_varlist)  #the input here is meant to be a polynomial, or eventually rational, system of julia symbolics
	#println("starting SolveJSWithHC.  Here is the polynomial system:")
	#display(input_poly_system)
	#print_element_types(poly_system)
	#println("varlist")
	#display(input_varlist)
	#print_element_types(varlist)


	(poly_system, varlist, trivial_vars, trivial_dict) = handle_simple_substitutions(input_poly_system, input_varlist)

	poly_system, varlist, trash = squarify_by_trashing(poly_system, varlist)

	jsvarlist = deepcopy(varlist)
	#println("after trivial subst")
	#display(poly_system)
	#display(varlist)
	#display(trivial_dict)

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
