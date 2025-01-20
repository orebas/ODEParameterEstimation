using DelimitedFiles



########Below code is largely untested and hard to test.
"""
	add_random_linear_equation(F::System)

Returns a new system which is F plus a random linear equation in F's variables.
This tries to lower the dimension by 1, hopefully making the solution set finite.
"""
function add_random_linear_equation(F::HomotopyContinuation.System)

	#println("DEBUG: Adding random linear equation to system")
	#println("DEBUG: Original system:")
	#display(F)

	# Extract the variables we are solving for
	vars = HomotopyContinuation.variables(F)  # e.g. [x, y, ...]
	# Generate random coefficients and constant
	coeffs = randn(length(vars))
	c = randn()
	# Build the linear expression a₁*x₁ + ... + aₙ*xₙ + c
	eq = sum(coeffs[i] * vars[i] for i in 1:length(vars)) + c
	# Append to the original system. Keep the same parameters, if any.
	return HomotopyContinuation.System(
		vcat(expressions(F), eq),
		vars,
		parameters = HomotopyContinuation.parameters(F),
	)
end


function solveJSwithMonodromy(poly_system, varlist)


	#println("Input poly_system: ", poly_system)
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
	parsed = eval.(Meta.parse.(string_target))
	@var _mpm[1:len] _mpc[1:len]
	paramlist = Vector{HomotopyContinuation.ModelKit.Variable}()
	for i in 1:len
		push!(paramlist, _mpm[i])
	end
	for i in 1:len
		push!(paramlist, _mpc[i])
	end

	for i in eachindex(parsed)
		parsed[i] = _mpm[i] * parsed[i] - _mpc[i]
	end
	HomotopyContinuation.set_default_compile(:all)    #TODO test whether this helps or not
	F = HomotopyContinuation.System(parsed, variables = hcvarlist, parameters = paramlist)
	G = HomotopyContinuation.System(parsed, variables = hcvarlist, parameters = paramlist)

	param_final = vcat(repeat([1.0], outer = len), repeat([0.0], outer = len))
	pair_attempts = 0
	max_attempts = 500
	min_attempts = 10
	start_pairs = []

	while (pair_attempts < max_attempts && (pair_attempts < min_attempts || isempty(start_pairs)))
		testx, testp = HomotopyContinuation.find_start_pair(F)

		try
			newx = HomotopyContinuation.solve(G, testx, start_parameters = testp, target_parameters = param_final,
				tracker_options = TrackerOptions(automatic_differentiation = 3))

			if !isempty(solutions(newx))
				push!(start_pairs, solutions(newx))
			end
		catch e
			if e isa FiniteException
				@warn "Caught FiniteException. The solution set is positive-dimensional."
				@warn "Attempting to reduce dimension by adding a random linear equation."

				# ### ADDED / MODIFIED ###
				# Build a random linear equation and form a new system
				G = add_random_linear_equation(G)

				# Now attempt to solve the *augmented* system
			else
				# If it's some other kind of error, rethrow
				rethrow(e)
			end
		end

		pair_attempts += 1
	end

	if isempty(start_pairs)
		newx = nothing
	else
		# Use the first successful result for compatibility with rest of code
		newx = start_pairs[1]
	end
	function simpleprinter(x)
		println("BLAH")
		display(x)
		return false
	end
	#display(F)
	# Flatten the start_pairs array since each element is already a solution set
	flattened_start_pairs = length(start_pairs) > 0 ? vcat(start_pairs...) : Vector{eltype(start_pairs)}()
	tryagain = true
	result = nothing
	while (tryagain)
		try
			begin
				result = HomotopyContinuation.monodromy_solve(F, flattened_start_pairs, param_final,
					show_progress = false,
					target_solutions_count = 10000,
					timeout = 300.0,
					max_loops_no_progress = 100,
					unique_points_rtol = 1e-6,
					unique_points_atol = 1e-6,
					trace_test = true,
					trace_test_tol = 1e-10,
					min_solutions = 100000,
					tracker_options = TrackerOptions(automatic_differentiation = 3))#only_nonsingular = false  ,)
				tryagain = false
			end
		catch e
			println("Caught error: ", e)
			println("Attempting to reduce dimension by adding a random linear equation.")
			F = add_random_linear_equation(G)

		end
	end
	#display(HomotopyContinuation.solutions(result))
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

	return solns, hcvarlist


end






function solveJSwithHC(input_poly_system, input_varlist, use_monodromy = true, display_system = false)  #the input here is meant to be a polynomial, or eventually rational, system of julia symbolics
	if (display_system)
		println("starting solveJSWithHC.  Here is the polynomial system:")
		display(input_poly_system)
		println("varlist")
		display(input_varlist)
	end

	# println("\n=== Starting solveJSwithHC ===")
	# println("Original varlist ordering: ", input_varlist)

	# Store original ordering
	original_order = Dict(v => i for (i, v) in enumerate(input_varlist))

	(poly_system, varlist, trivial_vars, trivial_dict) = handle_simple_substitutions(input_poly_system, input_varlist)
	# println("After substitutions:")
	# println("Varlist: ", varlist)
	# println("Trivial dict: ", trivial_dict)

	poly_system, varlist, trash = squarify_by_trashing(poly_system, varlist)
	# println("After squarifying:")
	# println("Varlist: ", varlist)

	# Preserve original ordering after squarifying
	varlist = sort(varlist, by = v -> get(original_order, v, length(input_varlist) + 1))

	jsvarlist = deepcopy(varlist)
	solns = []
	hcvarlist = []


	# Calculate total degree of the system
	total_degree = 1
	for poly in poly_system
		total_degree *= Symbolics.degree(poly)
	end
	println("total degree: ", total_degree)

	if (total_degree > 50 && use_monodromy)
		println("using monodromy, line 917")
		solns, hcvarlist = solveJSwithMonodromy(poly_system, varlist)
		return solns, hcvarlist, trivial_dict, jsvarlist
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

		result = nothing
		try
			result = HomotopyContinuation.solve(F, show_progress = false) #only_nonsingular = false
		catch e
			if e isa FiniteException
				@warn "Caught FiniteException. The solution set is positive-dimensional."
				@warn "Attempting to reduce dimension by adding a random linear equation."

				# ### ADDED / MODIFIED ###
				# Build a random linear equation and form a new system
				F_with_rand = add_random_linear_equation(F)

				# Now attempt to solve the *augmented* system
				result = HomotopyContinuation.solve(F_with_rand, show_progress = false)

			else
				# If it's some other kind of error, rethrow
				rethrow(e)
			end
		end

		# Get unique real solutions with appropriate tolerance
		solns = solutions(result, only_real = true, real_tol = 1e-4)
		complex_flag = false

		# If no real solutions found, try complex ones
		if isempty(solns)
			solns = solutions(result, only_nonsingular = false, tol = 1e-4)
			complexflag = true
		end

		if (isempty(solns))
			display("No solutions, failed.")
			return ([], [], [], [])
		end
		display(solns)
		return solns, hcvarlist, trivial_dict, jsvarlist
	end
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
	result = HomotopyContinuation.solve(F, show_progress = false;) #only_nonsingular = false


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
