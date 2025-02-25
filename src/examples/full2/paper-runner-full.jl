using ODEParameterEstimation
using GaussianProcesses
using LineSearches
using Optim
using Statistics
using OrderedCollections
using Dates  # for timestamping the output file name
using Printf
using Random
using DataFrames
using JSON   # <-- Added JSON for reading the JSON file

Random.seed!(42)


"""
	save_debug_script(pep, datasize, time_interval, noise_level)

Save a self‐contained Julia script that reproduces the parameter‐estimation problem (PEP)
with the exact same parameters, initial conditions, datasize, time interval, and noise level.
It assumes that the model's function is available and that its name (as a symbol) is the same as `pep.name`.
The generated script will include the necessary using/includes, recreate the PEP,
sample the data, and then run `analyze_parameter_estimation_problem`.
"""
function save_debug_script(pep::ParameterEstimationProblem,
	datasize::Int,
	time_interval::Vector{Float64},
	noise_level::Float64)
	# Create a unique file name using the model name and current timestamp.
	timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
	filename = "debug_$(pep.name)_$timestamp.jl"

	# Helper function: remove "(t)" from state variable names
	fixkey(x) = begin
		s = string(x)
		if endswith(s, "(t)")
			return replace(s, "(t)" => "")
		else
			return s
		end
	end

	# Get the original PEP to see its structure
	original_pep = eval(Symbol(pep.name))()

	# Generate code for the parameter OrderedDict using the original keys
	p_lines = String[]
	for (k, v) in zip(keys(original_pep.p_true), values(pep.p_true))
		push!(p_lines, "$(fixkey(k)) => $(v)")
	end
	params_code = "OrderedDict(" * join(p_lines, ", ") * ")"

	# Similarly for the initial conditions using original keys
	ic_lines = String[]
	for (s, v) in zip(keys(original_pep.ic), values(pep.ic))
		push!(ic_lines, "$(fixkey(s)) => $(v)")
	end
	ic_code = "OrderedDict(" * join(ic_lines, ", ") * ")"

	# Determine all the variable keys from both p_true and ic
	all_keys = union(keys(original_pep.p_true), keys(original_pep.ic))
	# Convert them to a string separated by space. Use fixkey to remove "(t)" if present.
	vars_string = join([(x) for x in collect(all_keys)], " ")

	# Create the script text with a header that predefines the required ModelingToolkit variables
	script = """
	#!/usr/bin/env julia
	#
	# This script reproduces a problematic parameter estimation case.
	# Model Name: $(pep.name)
	# Datasize: $datasize
	# Time Interval: [$time_interval[1], $time_interval[2]]
	# Noise Level: $noise_level
	# Generated on: $timestamp
	#
	# Predefine ModelingToolkit variables used in the PEP
	using ModelingToolkit
	using ModelingToolkit: t_nounits as t, D_nounits as D
	@variables $vars_string

	using ODEParameterEstimation
	using OrderedCollections


	# Get the original PEP
	original_pep = eval(Symbol("$(pep.name)"))()

	# Create new PEP with our specific parameters and initial conditions
	p_true = $params_code
	ic = $ic_code

	pep = ParameterEstimationProblem(
		original_pep.name,
		original_pep.model,
		original_pep.measured_quantities,
		original_pep.data_sample,
		original_pep.recommended_time_interval,
		original_pep.solver,
		p_true,
		ic,
		original_pep.unident_count
	)

	# Use the specified time interval and sample size.
	pep = sample_problem_data(pep, datasize = $datasize, time_interval = [$time_interval[1], $time_interval[2]], noise_level = $noise_level)

	# Run the estimation.
	res = analyze_parameter_estimation_problem(pep)

	println("Estimation Done!")
	"""

	# Write the script to file.
	open(filename, "w") do f
		write(f, script)
	end

	println("Debug script saved as: $filename")
end

fixed_time_interval = [-0.5, 0.5]
datasize = 1001

# ------------------------------------------------------------------------------
# Helper function: get_instance selects an instance from the JSON instances by model
function get_instance(model_sym::Symbol, attempt::Int, instances_by_system::Dict{String, Vector{Any}})
	system_name = string(model_sym)
	if !haskey(instances_by_system, system_name)
		error("No instances found for model: $system_name")
	end
	instances = instances_by_system[system_name]
	# Use modulo to select an instance in a round-robin fashion if needed.
	idx = ((attempt - 1) % length(instances)) + 1
	return instances[idx]
end
# ------------------------------------------------------------------------------

function run_paper_runner()
	# Load JSON file and build a dictionary: system name (String) => Vector of instance dictionaries.
	instances_data = JSON.parsefile("instances.json")
	instances_list = instances_data["instances"]
	# Build a dictionary mapping system name to a vector of instances.
	instances_by_system = Dict{String, Vector{Any}}()
	for instance in instances_list
		system_name = instance["system-name"]
		if haskey(instances_by_system, system_name)
			push!(instances_by_system[system_name], instance)
		else
			instances_by_system[system_name] = [instance]
		end
	end

	model_dict = OrderedDict(
		#:vanderpol => vanderpol,
		#:harmonic => harmonic,
		#:lotka_volterra => lotka_volterra,
		#:fitzhugh_nagumo => fitzhugh_nagumo,
		#:seir => seir,
		#:daisy_mamil3 => daisy_mamil3,
		:daisy_mamil4 => daisy_mamil4,
		:hiv => hiv,
		#:crauste => crauste,
		#:biohydrogenation => biohydrogenation,
	)

	# Initialize the results structure
	# Structure: results[noise_level][model_symbol][run_number] = pep
	results = OrderedDict{Float64, OrderedDict{Symbol, OrderedDict{Int, ParameterEstimationProblem}}}()

	parameter_interval = [0.1, 0.9]
	noise_levels = [0.0, 1e-8, 1e-6, 1e-4, 1e-2]
	search_bounds = [-3.0, 3.0]  #not used, but could be used to set bounds on the search
	num_runs = 2
	for noise_level in noise_levels
		# Initialize dictionary for this noise level
		results[noise_level] = OrderedDict{Symbol, OrderedDict{Int, ParameterEstimationProblem}}()

		for model_symbol in collect(keys(model_dict))
			# Initialize dictionary for this model
			results[noise_level][model_symbol] = OrderedDict{Int, ParameterEstimationProblem}()

			model_fn = model_dict[model_symbol]
			original_pep = model_fn()

			# Initialize vector to store valid PEPs
			valid_peps = Vector{ParameterEstimationProblem}()

			# Keep generating data until we have num_runs valid samples
			run_num = 1
			while length(valid_peps) < num_runs
				println("Generating data for: $model_symbol, attempt: $run_num, noise: $noise_level")

				# Get parameter and initial condition values from JSON instance
				instance = get_instance(model_symbol, run_num, instances_by_system)
				p_from_instance = OrderedDict(
					k => instance["parameters"][replace(string(k), "(t)" => "")]
					for k in keys(original_pep.p_true)
				)
				ic_from_instance = OrderedDict(
					k => instance["initial"][replace(string(k), "(t)" => "")]
					for k in keys(original_pep.ic)
				)

				# Create new PEP with updated values from JSON
				newpep = ParameterEstimationProblem(
					original_pep.name,
					original_pep.model,
					original_pep.measured_quantities,
					original_pep.data_sample,
					fixed_time_interval,
					original_pep.solver,
					p_from_instance,      # Use parameters from JSON
					ic_from_instance,     # Use initial conditions from JSON
					original_pep.unident_count,
				)

				newpep = sample_problem_data(newpep, datasize = datasize, noise_level = noise_level)

				# Check if data generation was successful by verifying timepoints length
				# Check all vectors in data_sample have same length as datasize
				valid_lengths = all(length(v) == datasize for v in values(newpep.data_sample))
				# Check that all values are finite and less than 10K in absolute value
				valid_values = true
				for values_vec in values(newpep.data_sample)
					if !all(isfinite.(values_vec)) || !all(abs.(values_vec) .< 10000.0)
						valid_values = false
						break
					end
				end
				valid_lengths = valid_lengths && valid_values
				if valid_lengths
					push!(valid_peps, newpep)
					# Store the PEP in our results structure
					results[noise_level][model_symbol][length(valid_peps)] = newpep
					println("Successfully generated run $(length(valid_peps)) of $num_runs")
				else
					println("Data generation failed, retrying...")
				end

				run_num += 1
			end
		end
	end

	return results
end
results = run_paper_runner()

# Print detailed summary of results structure
println("\nResults Summary:")
println("="^80)
for (noise_level, noise_dict) in results
	println("\nNoise Level: $noise_level")
	println("="^80)
	for (model_name, model_runs) in noise_dict
		println("\nModel: $model_name")
		println("-"^40)
		for (run_num, pep) in model_runs
			println("\nRun $run_num:")
			println("  Parameters:")
			for (param, value) in pep.p_true
				println("    $param = $value")
			end
			println("  Initial Conditions:")
			for (var, value) in pep.ic
				println("    $var = $value")
			end
		end
	end
end
println("\n")


# Create a data structure to store results
results_df = DataFrame(
	noise_level = Float64[],
	model = String[],
	run = Int[],
	min_error = Union{Float64, Missing}[],
	mean_error = Union{Float64, Missing}[],
	median_error = Union{Float64, Missing}[],
	max_error = Union{Float64, Missing}[],
	approximation_error = Union{Float64, Missing}[],
)

# Collect results
for (noise_level, noise_dict) in results
	for (model_name, model_runs) in noise_dict
		for (run_num, pep) in model_runs
			#try

			save_debug_script(pep, datasize, fixed_time_interval, noise_level)
			sol, besterror, best_min_error, best_mean_error, best_median_error, best_max_error, best_approximation_error = analyze_parameter_estimation_problem(pep, nooutput = false)

			# Add row to dataframe, replacing any Inf/NaN with missing
			push!(
				results_df,
				[
					noise_level,
					string(model_name),
					run_num,
					isfinite(best_min_error) ? best_min_error : missing,
					isfinite(best_mean_error) ? best_mean_error : missing,
					isfinite(best_median_error) ? best_median_error : missing,
					isfinite(best_max_error) ? best_max_error : missing,
					isfinite(best_approximation_error) ? best_approximation_error : missing,
				],
			)
			#catch e
			#println("Warning: Analysis failed for model $model_name run $run_num: $e")
			# Add row with missing values for failed runs
			push!(results_df, [noise_level, string(model_name), run_num, missing, missing, missing, missing, missing])
			#end
		end
	end
end

# Print summary tables for each noise level
println("\nSummary Statistics by Noise Level:")
println("="^80)

for noise_level in unique(results_df.noise_level)
	println("\nNoise Level: $noise_level")
	println("-"^80)

	# Group by model and compute means, handling missing values
	summary = combine(
		groupby(filter(:noise_level => ==(noise_level), results_df), :model),
		:min_error => (x -> mean(skipmissing(x))) => :min_error,
		:mean_error => (x -> mean(skipmissing(x))) => :mean_error,
		:median_error => (x -> mean(skipmissing(x))) => :median_error,
		:max_error => (x -> mean(skipmissing(x))) => :max_error,
		:approximation_error => (x -> mean(skipmissing(x))) => :approximation_error,
	)

	# Print formatted table
	println("Model                Min Error    Mean Error   Median Error  Max Error    Approx Error")
	println("-"^90)
	for row in eachrow(summary)
		@printf("%-20s %10.6f %12.6f %12.6f %12.6f %12.6f\n",
			row.model,
			something(row.min_error, NaN),
			something(row.mean_error, NaN),
			something(row.median_error, NaN),
			something(row.max_error, NaN),
			something(row.approximation_error, NaN)
		)
	end
end

