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

