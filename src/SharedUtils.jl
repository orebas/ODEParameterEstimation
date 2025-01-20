#module SharedUtils

using ModelingToolkit
using Statistics
using Printf
using OrderedCollections
using Symbolics

struct OrderedODESystem
	system::ODESystem
	original_parameters::Vector
	original_states::Vector
end

struct ParameterEstimationProblem
	name::String
	model::OrderedODESystem
	measured_quantities::Vector{Equation}
	data_sample::Union{Nothing, OrderedDict}
	recommended_time_interval::Union{Nothing, Vector{Float64}}  # [start_time, end_time] or nothing for default
	solver::Any
	p_true::Any
	ic::Any
	unident_count::Int
end

const CLUSTERING_THRESHOLD = 0.01  # 1% relative difference threshold
const MAX_ERROR_THRESHOLD = 0.5    # Maximum acceptable error
const IMAG_THRESHOLD = 1e-8      # Threshold for ignoring imaginary components
const MAX_SOLUTIONS = 20          # Maximum number of solutions to consider if no good ones found

function create_ordered_ode_system(name, states, parameters, equations, measured_quantities)
	@named model = ODESystem(equations, t, states, parameters)
	model = complete(model)
	ordered_system = OrderedODESystem(model, parameters, states)
	return ordered_system, measured_quantities
end

function sample_problem_data(problem::ParameterEstimationProblem;
	datasize = 21,
	time_interval = [-0.5, 0.5],
	solver = package_wide_default_ode_solver,
	uneven_sampling = false,
	uneven_sampling_times = Vector{Float64}())

	# Create new OrderedODESystem with completed system
	ordered_system = OrderedODESystem(
		complete(problem.model.system),
		problem.model.original_parameters,
		problem.model.original_states,
	)

	return ParameterEstimationProblem(
		problem.name,
		ordered_system,
		problem.measured_quantities,
		ODEParameterEstimation.sample_data(
			ordered_system.system,
			problem.measured_quantities,
			time_interval,
			problem.p_true,
			problem.ic,
			datasize,
			solver = solver,
			uneven_sampling = uneven_sampling,
			uneven_sampling_times = uneven_sampling_times),
		problem.recommended_time_interval,
		solver,
		problem.p_true,
		problem.ic,
		problem.unident_count,
	)
end

# Helper function to get solution vector
function get_solution_vector(solution)
	return vcat(collect(values(solution.states)), collect(values(solution.parameters)))
end

# Improved solution distance calculation
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

# New function to handle clustering
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

# Helper function to calculate number of "turns" using sign changes in divided differences
function count_turns(values)
	if length(values) < 3
		return 0
	end
	diffs = diff(values)
	sign_changes = sum(abs.(sign.(diffs[2:end]) - sign.(diffs[1:end-1])) .> 1)
	return sign_changes
end

# Helper function to calculate statistics for a time series
function calculate_timeseries_stats(values)
	return (
		mean = mean(values),
		std = std(values),
		min = minimum(values),
		max = maximum(values),
		range = maximum(values) - minimum(values),
		turns = count_turns(values),
	)
end

# Helper function to print a statistics table
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

# Helper function to calculate error statistics
function calculate_error_stats(predicted, actual)
	abs_error = abs.(predicted - actual)
	rel_error = abs_error ./ (abs.(actual) .+ 1e-10)  # Add small constant to avoid division by zero

	return (
		absolute = calculate_timeseries_stats(abs_error),
		relative = calculate_timeseries_stats(rel_error),
	)
end

# Modified analyze_estimation_result function
function analyze_estimation_result(problem::ParameterEstimationProblem, result)
	# Merge dictionaries into a single OrderedDict
	all_params = merge(OrderedDict(), problem.ic, problem.p_true)

	# Print header
	println("\n=== Model: $(problem.name) ===")

	# Filter out solutions with no error or error > threshold
	valid_results = filter(x -> !isnothing(x.err) && x.err < MAX_ERROR_THRESHOLD, result)

	# If no good solutions found, take top solutions
	if isempty(valid_results)
		valid_results = sort(result, by = x -> isnothing(x.err) ? Inf : x.err)[1:min(MAX_SOLUTIONS, length(result))]
	end

	# Sort results by error
	sorted_results = sort(valid_results, by = x -> x.err, rev = true)

	# Cluster solutions using the new function
	clusters = cluster_solutions(sorted_results)

	# Show unidentifiable parameters if any
	if !isempty(sorted_results)
		first_result = last(sorted_results)

		# First show all structurally unidentifiable parameters
		if hasfield(typeof(first_result), :all_unidentifiable) && !isempty(first_result.all_unidentifiable)
			println("\nAll structurally unidentifiable parameters:")
			println("-"^50)
			println("These parameters cannot be uniquely determined from the data:")
			for param in first_result.all_unidentifiable
				println("  • $param")
			end
			println()
		end

		# Then show the minimal set of fixed values
		if !isnothing(first_result.unident_dict) && !isempty(first_result.unident_dict)
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

	# Print best solution from each cluster
	println("\nFound $(length(clusters)) distinct solution clusters:")
	for (i, cluster) in enumerate(clusters)
		best_solution = last(cluster)  # cluster is sorted by error
		println("\nCluster $i: $(length(cluster)) similar solutions")
		println("Best solution (Error: $(round(best_solution.err, digits=6))):")
		println("-"^50)

		# Get parameters in original order from the model
		param_names = problem.model.original_parameters
		#println("DEBUG [analyze_estimation_result]: Original parameters: ", param_names)
		#println("DEBUG [analyze_estimation_result]: problem.p_true: ", problem.p_true)
		#println("DEBUG [analyze_estimation_result]: best_solution.parameters: ", best_solution.parameters)

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

		#println("DEBUG [analyze_estimation_result]: Estimates order: ", var_names)
		#println("DEBUG [analyze_estimation_result]: Estimates values: ", estimates)

		# Calculate relative errors
		rel_errors = abs.((estimates .- true_values) ./ true_values)

		# Print table header
		println("Variable      | True Value  | Estimated   | Rel. Error")
		println("-"^50)

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

			# Print the row
			@printf("%-12s | %10.6f | %10s | %10.6f\n",
				var, true_val, est_str, rel_err)
		end
	end

	# Calculate and return best error (excluding unidentifiable parameters)
	besterror = Inf
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
			errorvec = abs.((estimates .- true_values) ./ true_values)
			besterror = min(besterror, maximum(errorvec))
		end
	end
	println("\nBest maximum relative error for $(problem.name) (excluding ALL unidentifiable parameters): $(round(besterror, digits=6))")

	# Debug printing
	#	println("\nDEBUG: Measured quantities:")
	#	for eq in problem.measured_quantities
	#		println("  Equation: ", eq)
	#		println("  LHS: ", eq.lhs, " (", typeof(eq.lhs), ")")
	#		println("  RHS: ", eq.rhs, " (", typeof(eq.rhs), ")")
	#	end

	#	println("\nDEBUG: Data sample keys:")
	#	for key in keys(problem.data_sample)
	#		println("  ", key, " (", typeof(key), ")")
	#	end

	# Calculate and print observable statistics
	observable_stats = OrderedDict()
	for eq in problem.measured_quantities
		obs_name = string(eq.lhs)
		rhs = eq.rhs
		rhs_str = string(rhs)
		#		println("\nDEBUG: Processing observable:")
		#		println("  obs_name: ", obs_name)
		#		println("  rhs: ", rhs)
		#		println("  rhs_str: ", rhs_str)
		if haskey(problem.data_sample, rhs)
			#			println("  Found by RHS")
			observable_stats[obs_name] = calculate_timeseries_stats(problem.data_sample[rhs])
		elseif haskey(problem.data_sample, rhs_str)
			#			println("  Found by RHS string")
			observable_stats[obs_name] = calculate_timeseries_stats(problem.data_sample[rhs_str])
		else
			#			println("  Not found in data sample")
		end
	end

	if !isempty(observable_stats)
		print_stats_table(stdout, "Observables", observable_stats)
	end

	# For the best solution, calculate error statistics
	if !isempty(sorted_results)
		best_solution = last(sorted_results)
		println("\nError Statistics for Best Solution:")
		println("-"^50)

		# Use stored solution
		sol = best_solution.solution

		# Calculate error statistics for each observable
		println("\nError Statistics by Observable:")
		println("-"^50)
		println("Observable   | Error Type | Mean        | Std         | Min         | Max         | Range")
		println("-"^50)

		for eq in problem.measured_quantities
			obs_name = string(eq.lhs)
			rhs = eq.rhs
			rhs_str = string(rhs)

			if haskey(problem.data_sample, rhs)
				# Get predicted values from solution
				predicted = Array(sol[rhs])  # Convert to Array for calculations
				actual = problem.data_sample[rhs]
				error_stats = calculate_error_stats(predicted, actual)

				# Print absolute error stats
				@printf("%-12s | Absolute   | %10.6f | %10.6f | %10.6f | %10.6f | %10.6f\n",
					obs_name,
					error_stats.absolute.mean,
					error_stats.absolute.std,
					error_stats.absolute.min,
					error_stats.absolute.max,
					error_stats.absolute.range)

				# Print relative error stats
				@printf("%-12s | Relative   | %10.6f | %10.6f | %10.6f | %10.6f | %10.6f\n",
					obs_name,
					error_stats.relative.mean,
					error_stats.relative.std,
					error_stats.relative.min,
					error_stats.relative.max,
					error_stats.relative.range)
			end
		end
	end

	# For the best solution, add detailed time series comparison
	if !isempty(sorted_results)
		best_solution = last(sorted_results)
		sol = best_solution.solution

		println("\nDetailed Time Series Comparison:")
		println("-"^120)

		# Print header
		header = "t"
		for eq in problem.measured_quantities
			obs_name = string(eq.lhs)
			header *= @sprintf(" | %-12s | %-12s | %-12s | %-12s",
				"$(obs_name)_act", "$(obs_name)_pred", "abs_err", "rel_err")
		end
		println(header)
		println("-"^120)

		# Print data for each time point
		t_points = problem.data_sample["t"]
		for (i, t) in enumerate(t_points)
			line = @sprintf("%8.4f", t)
			for eq in problem.measured_quantities
				rhs = eq.rhs
				if haskey(problem.data_sample, rhs)
					actual = problem.data_sample[rhs][i]
					predicted = sol[rhs][i]
					abs_err = abs(predicted - actual)
					rel_err = abs_err / (abs(actual) + 1e-10)

					line *= @sprintf(" | %12.6f | %12.6f | %12.6f | %12.6f",
						actual, predicted, abs_err, rel_err)
				end
			end
			println(line)
		end
		println("-"^120)
	end

	return besterror
end

function clean_time_variables(name::String)
	# Remove (t) and fix time variable
	name = replace(name, r"\(t\)" => "")  # Remove (t)
	name = replace(name, "t_nounits" => "t")  # Replace t_nounits with t
	return name
end

function clean_rational_numbers(name::String)
	# Convert rational numbers (e.g., 1//3 -> 0.333333)
	while contains(name, "//")
		m = match(r"(\d+)//(\d+)", name)
		if !isnothing(m)
			num = parse(Int, m.captures[1])
			den = parse(Int, m.captures[2])
			name = replace(name, "$(num)//$(den)" => string(float(num / den)))
		else
			break
		end
	end
	return name
end

function clean_power_notation(name::String)
	# Handle power notation (e.g., x^2 -> x*x, x^3 -> x*x*x)
	while contains(name, "^")
		m = match(r"(\w+)\^(\d+)", name)
		if !isnothing(m)
			base = m.captures[1]
			power = parse(Int, m.captures[2])
			replacement = join(fill(base, power), "*")
			name = replace(name, "$(base)^$(power)" => replacement)
		else
			break
		end
	end
	return name
end

function fix_multiplication_syntax(name::String)
	# Fix multiplication syntax (add * between number and variable)
	name = replace(name, r"(\d+)([a-zA-Z])" => s"\1*\2")
	name = replace(name, r"(\d+\.\d+)([a-zA-Z])" => s"\1*\2")
	return name
end

function clean_name(name::String)
	name = clean_time_variables(name)
	name = clean_rational_numbers(name)
	name = clean_power_notation(name)
	name = fix_multiplication_syntax(name)
	return name
end

function save_to_toml(
	pep::ParameterEstimationProblem,
	output_file::String;
	parameter_bounds::Dict = Dict(),  # Optional bounds for parameters
	estimate_initial_conditions::Bool = true,  # Whether to estimate all ICs
	timespan::Tuple = (0.0, 5.0),
	n_timepoints::Int = 1001,
	noise_level::Float64 = 0.001,
	blind::Bool = true,
)
	# Open file for writing
	open(output_file, "w") do io
		# Write model section header
		println(io, "[model]")
		println(io, "name = \"$(pep.name)\"")

		# Write states section
		println(io, "states = [")
		for (state, value) in pep.ic
			state_name = clean_name(string(state))
			println(io, "    { name = \"$(state_name)\", initial_value = $(value), estimate = $(estimate_initial_conditions) },")
		end
		println(io, "]")

		# Write parameters section
		println(io, "parameters = [")
		for (param, value) in pep.p_true
			bounds = get(parameter_bounds, param, [-1e6, 1e6])
			println(io, "    { name = \"$(param)\", value = $(value), bounds = [$(bounds[1]), $(bounds[2])], scale = \"lin\" },")
		end
		println(io, "]")

		# Extract and write equations
		println(io, "equations = [")
		eqs = equations(pep.model.system)
		for eq in eqs
			state = clean_name(string(ModelingToolkit.arguments(eq.lhs)[1]))
			rhs = clean_name(string(eq.rhs))
			println(io, "    \"$(state)' = $(rhs)\",")
		end
		println(io, "]")

		# Write observables section
		println(io, "observables = [")
		for (i, mq) in enumerate(pep.measured_quantities)
			name = "obs_$(clean_name(string(mq.lhs)))"
			formula = clean_name(string(mq.rhs))
			println(io, "    { name = \"$(name)\", formula = \"$(formula)\", transformation = \"lin\", noise_distribution = \"normal\" },")
		end
		println(io, "]")

		# Write simulation section
		println(io, "[simulation]")
		println(io, "timespan = [$(timespan[1]), $(timespan[2])]")
		println(io, "n_timepoints = $(n_timepoints)")
		println(io, "noise_level = $(noise_level)")
		println(io, "output_dir = \"petab_$(pep.name)\"")
		println(io, "blind = $(blind)")
	end
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
