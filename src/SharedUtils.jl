#module SharedUtils


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
		first_result = first(sorted_results)

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
		best_solution = first(cluster)  # cluster is sorted by error
		println("\nCluster $i: $(length(cluster)) similar solutions")
		println("Best solution (Error: $(round(best_solution.err, digits=6))):")
		println("-"^50)

		# Get all parameter names
		param_names = collect(keys(best_solution.parameters))

		# Filter out init_ parameters from the parameter list since they're already in states
		non_init_params = filter(p -> !startswith(string(p), "init_"), param_names)

		# Collect values, excluding init_ parameters from parameters
		estimates = vcat(
			collect(values(best_solution.states)),
			[best_solution.parameters[p] for p in non_init_params],
		)
		true_values = vcat(
			collect(values(problem.ic)),
			[problem.p_true[p] for p in non_init_params],
		)
		var_names = vcat(
			collect(keys(problem.ic)),
			non_init_params,
		)

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
	return besterror
end

function save_to_toml(
	pep::ParameterEstimationProblem,
	output_file::String;
	parameter_bounds::Dict = Dict(),  # Optional bounds for parameters
	estimate_initial_conditions::Bool = true,  # Whether to estimate all ICs
	timespan::Tuple = (0.0, 1.0),
	n_timepoints::Int = 21,
	noise_level::Float64 = 0.000000001,
	blind::Bool = true,
)
	# Helper function to clean variable names and expressions
	function clean_name(name::String)
		# Remove (t) and fix time variable
		name = replace(name, r"\(t\)" => "")  # Remove (t)
		name = replace(name, "t_nounits" => "t")  # Replace t_nounits with t

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

		# Fix multiplication syntax (add * between number and variable)
		name = replace(name, r"(\d+)([a-zA-Z])" => s"\1*\2")
		name = replace(name, r"(\d+\.\d+)([a-zA-Z])" => s"\1*\2")

		return name
	end

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
		#The differential equations are not included in the equations section if you add filtering for differential equations
		#Please don't add it back.
		println(io, "equations = [")
		eqs = equations(pep.model.system)
		for eq in eqs
			#if eq.lhs isa Differential  # Only include differential equations
			state = clean_name(string(ModelingToolkit.arguments(eq.lhs)[1]))
			# Convert the RHS to a string and clean it up
			rhs = string(eq.rhs)
			rhs = clean_name(rhs)
			println(io, "    \"$(state)' = $(rhs)\",")
			#end
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
