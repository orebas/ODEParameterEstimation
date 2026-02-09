

"""
	add_relative_noise(data::OrderedDict, noise_level::Float64)

Add relative Gaussian noise to data values while preserving time points.

# Arguments
- `data`: OrderedDict containing time series data
- `noise_level`: Standard deviation of the relative noise to add

# Returns
- New OrderedDict with noisy data
"""
function add_relative_noise(data::OrderedDict, noise_level::Float64)
	noisy_data = OrderedDict{Union{String, Num}, Vector{Float64}}()

	# Copy time points unchanged
	noisy_data["t"] = data["t"]

	# Add noise to each measurement
	for (key, values) in data
		if key != "t"  # Skip time points
			noise = 1.0 .+ noise_level .* randn(length(values))
			noisy_data[key] = values .* noise
		end
	end

	return noisy_data
end

function add_additive_noise(data::OrderedDict, noise_level::Float64)
	noisy_data = OrderedDict{Union{String, Num}, Vector{Float64}}()

	# Copy time points unchanged
	noisy_data["t"] = data["t"]

	# Add noise to each measurement
	for (key, values) in data
		if key != "t"  # Skip time points
			mean_val = mean(values)
			noise = mean_val .* noise_level .* randn(length(values))
			noisy_data[key] = values .+ noise
		end
	end

	return noisy_data
end


#This is a utility function which fills in observed data by solving an ODE.

function sample_data(model::ModelingToolkit.AbstractSystem,
	measured_data::Vector{ModelingToolkit.Equation},
	time_interval::Vector{T},
	p_true,
	u0,
	num_points::Int;
	uneven_sampling = false,
	uneven_sampling_times = Vector{T}(),
	solver = package_wide_default_ode_solver, inject_noise = false, mean_noise = 0,
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
	# Get parameters in the correct order from the model
	ordered_params = [p_true[p] for p in ModelingToolkit.parameters(model)]
	ordered_u0 = [u0[s] for s in ModelingToolkit.unknowns(model)]

	sys = ModelingToolkit.complete(model)

	problem = ODEProblem(sys, merge(if isempty(ordered_u0)
				Dict()
			else
				Dict(ModelingToolkit.unknowns(sys) .=> ordered_u0)
			end, if isempty(ordered_params)
				Dict()
			else
				Dict(ModelingToolkit.parameters(sys) .=> ordered_params)
			end), time_interval)
	solution_true = ModelingToolkit.solve(problem, solver,
		saveat = sampling_times;
		abstol, reltol)

	#if false # Plot state variables
	#	states = ModelingToolkit.unknowns(model)
	#	for state in states
	#		plot(solution_true.t, solution_true[state],
	#			label = string(state),
	#			xlabel = "Time",
	#			ylabel = "Value")
	#		savefig("state_$(state)_plot.png")
	#	end
	#end

	data_sample = OrderedDict{Union{String, Num}, Vector{T}}(Num(v.rhs) => solution_true[Num(v.rhs)]
											  for v in measured_data)
	if inject_noise
		for (key, sample) in data_sample
			data_sample[key] = sample + randn(num_points) .* stddev_noise .+ mean_noise
		end
	end
	data_sample["t"] = sampling_times
	return data_sample
end


"""
	sample_problem_data(problem::ParameterEstimationProblem;
					   datasize = 21,
					   time_interval = [-0.5, 0.5],
					   solver = package_wide_default_ode_solver,
					   uneven_sampling = false,
					   uneven_sampling_times = Vector{Float64}(),
					   noise_level = 0.0)

Generate sample data for a parameter estimation problem.

# Arguments
- `problem`: The parameter estimation problem
- `datasize`: Number of data points to generate
- `time_interval`: Time interval for sampling
- `solver`: ODE solver to use
- `uneven_sampling`: Whether to use uneven time sampling
- `uneven_sampling_times`: Custom sampling times (if uneven_sampling is true)
- `noise_level`: Level of noise to add to the data

# Returns
- New ParameterEstimationProblem with generated data
"""
function sample_problem_data(problem::ParameterEstimationProblem, opts::EstimationOptions = EstimationOptions())

	# Create new OrderedODESystem with completed system
	ordered_system = OrderedODESystem(
		complete(problem.model.system),
		problem.model.original_parameters,
		problem.model.original_states,
	)

	# Generate clean data
	clean_data = ODEParameterEstimation.sample_data(
		ordered_system.system,
		problem.measured_quantities,
		opts.time_interval,
		problem.p_true,
		problem.ic,
		opts.datasize,
		solver = opts.ode_solver,
		uneven_sampling = opts.uneven_sampling,
		uneven_sampling_times = opts.uneven_sampling_times)

	# Add noise if requested
	data = opts.noise_level > 0 ? add_relative_noise(clean_data, opts.noise_level) : clean_data

	return ParameterEstimationProblem(
		problem.name,
		ordered_system,
		problem.measured_quantities,
		data,
		problem.recommended_time_interval,
		opts.ode_solver,
		problem.p_true,
		problem.ic,
		problem.unident_count,
	)
end
