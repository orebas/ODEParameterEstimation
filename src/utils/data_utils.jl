using OrderedCollections
using Random
using Statistics

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
	noisy_data = OrderedDict{Any, Vector{Float64}}()

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
	noisy_data = OrderedDict{Any, Vector{Float64}}()

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

"""
	calculate_error_stats(predicted, actual)

Calculate error statistics between predicted and actual values.

# Arguments
- `predicted`: Vector of predicted values
- `actual`: Vector of actual values

# Returns
- Named tuple containing absolute and relative error statistics
"""
function calculate_error_stats(predicted, actual)
	abs_error = abs.(predicted - actual)
	rel_error = abs_error ./ (abs.(actual) .+ 1e-10)  # Add small constant to avoid division by zero

	return (
		absolute = calculate_timeseries_stats(abs_error),
		relative = calculate_timeseries_stats(rel_error),
	)
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
function sample_problem_data(problem::ParameterEstimationProblem;
	datasize = 21,
	time_interval = [-0.5, 0.5],
	solver = package_wide_default_ode_solver,
	uneven_sampling = false,
	uneven_sampling_times = Vector{Float64}(),
	noise_level = 0.0)

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
		time_interval,
		problem.p_true,
		problem.ic,
		datasize,
		solver = solver,
		uneven_sampling = uneven_sampling,
		uneven_sampling_times = uneven_sampling_times)

	# Add noise if requested
	data = noise_level > 0 ? add_additive_noise(clean_data, noise_level) : clean_data

	return ParameterEstimationProblem(
		problem.name,
		ordered_system,
		problem.measured_quantities,
		data,
		problem.recommended_time_interval,
		solver,
		problem.p_true,
		problem.ic,
		problem.unident_count,
	)
end
