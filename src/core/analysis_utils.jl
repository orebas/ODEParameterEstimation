"""
	get_solution_vector(solution)

Extract a vector of values from a solution object.

# Arguments
- `solution`: Solution object containing states and parameters

# Returns
- Vector containing concatenated state and parameter values
"""
function get_solution_vector(solution)
	return vcat(collect(values(solution.states)), collect(values(solution.parameters)))
end

"""
	solution_distance(sol1, sol2)

Calculate the relative distance between two solutions.

# Arguments
- `sol1`: First solution
- `sol2`: Second solution

# Returns
- Maximum relative difference between corresponding components
"""
function solution_distance(sol1, sol2)
	v1 = get_solution_vector(sol1)
	v2 = get_solution_vector(sol2)
	# Use relative distance for each component with better handling of near-zero values
	rel_diffs = map(zip(v1, v2)) do (x, y)
		denom = max(abs(x) + abs(y), 1.0)  # Avoid division by zero
		return abs(x - y) / denom
	end
	return maximum(rel_diffs)
end

"""
	cluster_solutions(sorted_results)

Group similar solutions into clusters based on relative distances.

# Arguments
- `sorted_results`: Vector of solutions sorted by error

# Returns
- Vector of solution clusters
"""
function cluster_solutions(sorted_results)
	clusters = Vector{Vector{Any}}()

	for sol in sorted_results
		# Try to find a cluster for this solution
		cluster_idx = findfirst(cluster ->
				solution_distance(sol, cluster[1]) < CLUSTERING_THRESHOLD,
			clusters)

		if isnothing(cluster_idx)
			# Start new cluster
			push!(clusters, [sol])
		else
			# Add to existing cluster
			push!(clusters[cluster_idx], sol)
		end
	end

	return clusters
end

"""
	print_stats_table(io, name, stats)

Print a formatted table of statistics.

# Arguments
- `io`: IO stream to print to
- `name`: Name of the statistics group
- `stats`: Dictionary of statistics to print
"""
function print_stats_table(io, name, stats)
	println(io, "\n$name Statistics:")
	println(io, "-"^50)
	println(io, "Variable      | Mean        | Std         | Min         | Max         | Range       | Turns")
	println(io, "-"^50)
	for (var, stat) in stats
		@printf(io, "%-12s | %10.6f | %10.6f | %10.6f | %10.6f | %10.6f | %10d\n",
			var, stat.mean, stat.std, stat.min, stat.max, stat.range, stat.turns)
	end
end

"""
	analyze_estimation_result(problem::ParameterEstimationProblem, result)

Analyze the results of parameter estimation, including clustering solutions and printing statistics.

# Arguments
- `problem`: The parameter estimation problem
- `result`: Vector of solution results
"""
function analyze_estimation_result(problem::ParameterEstimationProblem, result; nooutput = false)
	# Merge dictionaries into a single OrderedDict
	all_params = merge(OrderedDict(), problem.ic, problem.p_true)

	# Print header
	if !nooutput
		println("\n=== Model: $(problem.name) ===")
	end

	# Filter out solutions with no error or error > threshold
	valid_results = filter(x -> !isnothing(x.err) && x.err < MAX_ERROR_THRESHOLD, result)

	# If no good solutions found, take top solutions
	if isempty(valid_results)
		valid_results = sort(result, by = x -> isnothing(x.err) ? Inf : x.err)[1:min(MAX_SOLUTIONS, length(result))]
	end

	# Sort results by error
	sorted_results = sort(valid_results, by = x -> x.err, rev = true)

	# Cluster solutions
	clusters = cluster_solutions(sorted_results)

	# Show unidentifiable parameters if any
	if !isempty(sorted_results)
		first_result = last(sorted_results)

		# First show all structurally unidentifiable parameters
		if hasfield(typeof(first_result), :all_unidentifiable) && !isempty(first_result.all_unidentifiable)
			if !nooutput
				println("\nAll structurally unidentifiable parameters:")
				println("-"^50)
				println("These parameters cannot be uniquely determined from the data:")
				for param in first_result.all_unidentifiable
					println("  • $param")
				end
				println()
			end
		end

		# Then show the minimal set of fixed values
		if !isnothing(first_result.unident_dict) && !isempty(first_result.unident_dict)
			if !nooutput
				println("\nMinimal set of fixed values to make remaining parameters identifiable:")
				println("-"^50)
				println("These parameters were fixed to make the system identifiable:")
				for (param, value) in first_result.unident_dict
					# Format the value - handle complex numbers
					val_str = if value isa Complex
						abs(imag(value)) < 1e-10 ?
						@sprintf("%.6f", real(value)) :
						@sprintf("%.3f%+.3fi", real(value), imag(value))
					else
						@sprintf("%.6f", value)
					end
					println("  • $param = $val_str")
				end
				println()
			end
		end
	end

	# Print best solution from each cluster
	if !nooutput
		println("\nFound $(length(clusters)) distinct solution clusters:")
	end
	for (i, cluster) in enumerate(clusters)
		best_solution = last(cluster)  # cluster is sorted by error
		if !nooutput
			println("\nCluster $i: $(length(cluster)) similar solutions")
			println("Best solution (Error: $(round(best_solution.err, digits=6))):")
			println("-"^50)
		end

		# Get parameters in original order from the model
		param_names = problem.model.original_parameters

		# Filter out init_ parameters from the parameter list since they're already in states
		non_init_params = filter(p -> !startswith(string(p), "init_"), param_names)

		# First get the state names in the order they appear in the model
		state_names = problem.model.original_states

		# Collect values in matching order
		estimates = vcat(
			[best_solution.states[s] for s in state_names],
			[best_solution.parameters[p] for p in non_init_params],
		)
		true_values = vcat(
			[problem.ic[s] for s in state_names],
			[problem.p_true[p] for p in non_init_params],
		)
		var_names = vcat(state_names, non_init_params)

		# Calculate relative errors with proper handling of near-zero values
		rel_errors = map(zip(estimates, true_values)) do (est, true_val)
			if abs(true_val) < 1e-6
				abs(est - true_val) # Use absolute error when true value is near zero
			else
				abs((est - true_val) / true_val) # Use relative error otherwise
			end
		end

		# Find maximum lengths for alignment
		max_var_len = maximum(length(string(var)) for var in var_names)
		max_var_len = max(max_var_len, 12) # minimum width for "Variable" header

		# Print table header with dynamic width
		header = @sprintf("%-*s | True Value  | Estimated   | Rel. Error", max_var_len, "Variable")
		if !nooutput
			println(header)
			println("-"^(length(header)))
		end

		# Print states and parameters
		for (var, true_val, est_val, rel_err) in zip(var_names, true_values, estimates, rel_errors)
			# Format the estimated value - handle complex numbers
			est_str = if est_val isa Complex
				abs(imag(est_val)) < 1e-10 ?
				@sprintf("%.6f", real(est_val)) :
				@sprintf("%.3f%+.3fi", real(est_val), imag(est_val))
			else
				@sprintf("%.6f", est_val)
			end

			# Print the row with dynamic width
			if !nooutput
				@printf("%-*s | %10.6f | %10s | %10.6f\n",
					max_var_len, var, true_val, est_str, rel_err)
			end
		end
		println()
	end

	# Print best approximation error summary line
	best_approximation_error = isempty(sorted_results) ? Inf : last(sorted_results).err
	if !nooutput
		println("\nBest approximation error for $(problem.name): $(round(best_approximation_error, digits=6))")
	end

	# Calculate and return best error (excluding unidentifiable parameters)
	besterror = Inf
	best_min_error = Inf
	best_mean_error = Inf
	best_median_error = Inf
	best_max_error = Inf
	best_rms_error = Inf

	for each in result
		# Get all parameter names
		param_names = collect(keys(each.parameters))

		# Filter out init_ parameters from the parameter list since they're already in states
		non_init_params = filter(p -> !startswith(string(p), "init_"), param_names)

		# Get ALL unidentifiable parameters from the analysis
		unident_params = if hasfield(typeof(each), :all_unidentifiable)
			Set(each.all_unidentifiable)
		else
			Set()
		end

		# Collect values, excluding init_ parameters and unidentifiable parameters
		estimates = Float64[]
		true_values = Float64[]

		# Add states that aren't unidentifiable
		for (state, value) in each.states
			if !(state in unident_params)
				push!(estimates, value)
				push!(true_values, problem.ic[state])
			end
		end

		# Add parameters that aren't unidentifiable
		for p in non_init_params
			if !(p in unident_params)
				push!(estimates, each.parameters[p])
				push!(true_values, problem.p_true[p])
			end
		end

		# Calculate relative errors only for identifiable parameters
		if !isempty(estimates)
			# Calculate errors, using absolute error when true value is near zero
			errorvec = map(zip(estimates, true_values)) do (est, true_val)
				if abs(true_val) < 1e-6
					abs(est - true_val)  # Use absolute error when true value is near zero
				else
					abs((est - true_val) / true_val)  # Use relative error otherwise
				end
			end
			besterror = min(besterror, maximum(errorvec))

			# Calculate additional statistics
			best_min_error = min(best_min_error, minimum(errorvec))
			best_mean_error = min(best_mean_error, mean(errorvec))
			best_median_error = min(best_median_error, median(errorvec))
			best_max_error = min(best_max_error, maximum(errorvec))
			best_rms_error = min(best_rms_error, sqrt(mean(errorvec .^ 2)))
		end
	end
	if !nooutput
		println("\nBest maximum relative error for $(problem.name) (excluding ALL unidentifiable parameters): $(round(besterror, digits=6))")
		println("Best minimum relative error: $(round(best_min_error, digits=6))")
		println("Best mean relative error: $(round(best_mean_error, digits=6))")
		println("Best median relative error: $(round(best_median_error, digits=6))")
		println("Best maximum relative error: $(round(best_max_error, digits=6))")
		println("Best RMS relative error: $(round(best_rms_error, digits=6))")
	end
	# Return a tuple containing:
	# - Vector of best solutions from each cluster
	# - Best maximum relative error across all results
	# - Best minimum relative error across all results
	# - Best mean relative error across all results
	# - Best median relative error across all results
	# - Best maximum relative error across all results
	# - Best approximation error across all results
	# - Best RMS relative error across all results
	return (
		[last(cluster) for cluster in clusters],
		besterror,
		best_min_error,
		best_mean_error,
		best_median_error,
		best_max_error,
		best_approximation_error,
		best_rms_error,
	)
end

function analyze_parameter_estimation_problem(PEP::ParameterEstimationProblem; interpolator = aaad_gpr_pivot,
	max_num_points = 1, nooutput = false, system_solver = solve_with_rs, abstol = 1e-14, reltol = 1e-14,
	trap_debug = false, diagnostics = true, polish_method = NewtonTrustRegion, polish_maxiters = 10, try_more_methods = true, shooting_points = 8, use_new_flow = false)  #try_more_methods = true
	#if trap_debug
	#	timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
	#	filename = "PEP_debug_$(timestamp).log"
	#	open(filename, "w") do log_file
	#		redirect_stdout(log_file) do
	#	println("Trap debug enabled. Saving diagnostic output to: ", filename)
	# Prepare diagnostic_data: merge true parameter values and initial conditions


	if !nooutput
		println("Starting model: ", PEP.name)
	end

	if system_solver == nothing
		system_solver = solve_with_rs
	end
	if interpolator == nothing
		interpolator = aaad_gpr_pivot
	end

	# Initialize variables outside try blocks
	solved_res = []
	unident_dict = Dict()
	trivial_dict = Dict()
	all_unidentifiable = []
	results_tuple_aaad = ([], Dict(), Dict(), [])
	results_tuple_multi = ([], Dict(), Dict(), [])

	# Choose between old and new flow
	if use_new_flow
		if !nooutput
			println("Using NEW optimized parameter estimation flow")
		end
		# Use the new optimized flow
		results_tuple = optimized_multishot_parameter_estimation(PEP,
			system_solver = system_solver,
			max_num_points = max_num_points,
			interpolator = interpolator,
			nooutput = nooutput, diagnostics = diagnostics, diagnostic_data = PEP,
			polish_method = polish_method, polish_maxiters = polish_maxiters, shooting_points = shooting_points,
		)
	else
		# Use the original flow
		if !nooutput
			println("Using standard parameter estimation flow")
		end
		results_tuple = multishot_parameter_estimation(PEP,
			system_solver = system_solver,
			max_num_points = max_num_points,
			interpolator = interpolator,
			nooutput = nooutput, diagnostics = diagnostics, diagnostic_data = PEP,
			polish_method = polish_method, polish_maxiters = polish_maxiters, shooting_points = shooting_points,
		)
	end
	solved_res, unident_dict, trivial_dict, all_unidentifiable = results_tuple

	#catch e
	#@warn "First estimation failed: $e"
	#results_tuple = ([], Dict(), Dict(), [])
	#solved_res, unident_dict, trivial_dict, all_unidentifiable = results_tuple
	#end
	if try_more_methods
		# Try second estimation with aaad interpolator
		try
			if use_new_flow
				results_tuple_aaad = optimized_multishot_parameter_estimation(PEP,
					system_solver = system_solver,
					max_num_points = max_num_points,
					interpolator = aaad,
					nooutput = nooutput, diagnostics = diagnostics, diagnostic_data = PEP,
					polish_method = polish_method, polish_maxiters = polish_maxiters, shooting_points = shooting_points,
				)
			else
				results_tuple_aaad = multishot_parameter_estimation(PEP,
					system_solver = system_solver,
					max_num_points = max_num_points,
					interpolator = aaad,
					nooutput = nooutput, diagnostics = diagnostics, diagnostic_data = PEP,
					polish_method = polish_method, polish_maxiters = polish_maxiters, shooting_points = shooting_points,
				)
			end
		catch e
			@warn "Second estimation failed: $e"
			results_tuple_aaad = ([], Dict(), Dict(), [])
		end

		# Try third estimation with multiple points
		#try
		#	results_tuple_multi = multishot_parameter_estimation(PEP,
		#		system_solver = system_solver,
		#		max_num_points = 2,
		#		interpolator = interpolator,
		#		nooutput = nooutput, diagnostics = diagnostics, diagnostic_data = PEP,
		#		polish_method = polish_method, polish_maxiters = polish_maxiters, shooting_points = shooting_points,
		#	)
		#catch e
		#	@warn "Third estimation failed: $e"
			results_tuple_multi = ([], Dict(), Dict(), [])
		#end
	end

	# Merge solutions from all attempts
	solved_res = vcat(solved_res, first(results_tuple_aaad), first(results_tuple_multi))
	unident_dict = merge(unident_dict, results_tuple_aaad[2], results_tuple_multi[2])
	trivial_dict = merge(trivial_dict, results_tuple_aaad[3], results_tuple_multi[3])
	all_unidentifiable = union(all_unidentifiable, results_tuple_aaad[4], results_tuple_multi[4])


	if !nooutput
		println("\nUnidentifiability Analysis from multipoint_parameter_estimation:")
		println("All unidentifiable variables: ", all_unidentifiable)
		println("Unidentifiable variables substitution dictionary: ", unident_dict)
		println("Trivially solvable variables: ", trivial_dict)
	end



	results_tuple_to_return = analyze_estimation_result(PEP, solved_res, nooutput = nooutput)
	return results_tuple, results_tuple_to_return

end


