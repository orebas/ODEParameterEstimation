using ModelingToolkit, OrdinaryDiffEq, DataFrames, Optim
using ModelingToolkit: t_nounits as t, D_nounits as D
using PEtab
using OrderedCollections
using Statistics
using SymbolicUtils
using Symbolics
using SymbolicIndexingInterface
using ODEParameterEstimation
using JSON

# Include our core converter and the examples file
include("convert_petab.jl")
include("../all_examples.jl")

"""
	compare_problems(prob1, prob2)

Compare two ParameterEstimationProblem objects and print differences.
"""
function compare_problems(prob1, prob2)
	println("\nComparing problems:")

	# Compare parameters
	println("\nParameters:")
	p1_keys = collect(keys(prob1.p_true))
	p2_keys = collect(keys(prob2.p_true))
	println("Problem 1 params: ", p1_keys)
	println("Problem 2 params: ", p2_keys)


	println(prob1.p_true)
	println(prob2.p_true)

	# Compare initial conditions
	println("\nInitial Conditions:")
	ic1_keys = collect(keys(prob1.ic))
	ic2_keys = collect(keys(prob2.ic))
	println("Problem 1 ICs: ", ic1_keys)
	println("Problem 2 ICs: ", ic2_keys)


	println(prob1.ic)
	println(prob2.ic)

	# Compare parameter values
	println("\nParameter Values:")
	for (k, v) in prob1.p_true
		if haskey(prob2.p_true, k)
			if prob1.p_true[k] ≈ prob2.p_true[k]
				println("$k: $(prob1.p_true[k]) (same)")
			else
				println("$k: $(prob1.p_true[k]) vs $(prob2.p_true[k])")
			end
		else
			println("$k: $(prob1.p_true[k]) (only in prob1)")
		end
	end

	# Compare IC values
	println("\nIC Values:")
	for (k, v) in prob1.ic
		if haskey(prob2.ic, k)
			if prob1.ic[k] ≈ prob2.ic[k]
				println("$k: $(prob1.ic[k]) (same)")
			else
				println("$k: $(prob1.ic[k]) vs $(prob2.ic[k])")
			end
		else
			println("$k: $(prob1.ic[k]) (only in prob1)")
		end
	end

	# Compare measured quantities (observables)
	println("\nMeasured Quantities:")
	if hasfield(typeof(prob1), :measured_quantities) && hasfield(typeof(prob2), :measured_quantities)
		println("\nProblem 1 measured quantities:")
		if !isnothing(prob1.measured_quantities)
			for eq in prob1.measured_quantities
				println("  $eq")
			end
		end
		println("\nProblem 2 measured quantities:")
		if !isnothing(prob2.measured_quantities)
			for eq in prob2.measured_quantities
				println("  $eq")
			end
		end
	end

	println(prob1.measured_quantities)
	println(prob2.measured_quantities)

	println(prob1.measured_quantities[1].rhs)
	println(prob2.measured_quantities[1].rhs)


	println(typeof(prob1.measured_quantities[1].rhs))
	println(typeof(prob2.measured_quantities[1].rhs))


	# Compare sample data
	println("\nSample Data:")
	if hasfield(typeof(prob1), :data_sample) && hasfield(typeof(prob2), :data_sample)
		println("\nProblem 1 data sample:")
		if !isnothing(prob1.data_sample)
			for (key, value) in prob1.data_sample
				if key == "t"
					println("  Time points: ", value[1:min(5, length(value))], length(value) > 5 ? "..." : "")
				else
					println("  $key: ", value[1:min(5, length(value))], length(value) > 5 ? "..." : "")
				end
			end
		else
			println("No data sample")
		end

		println("\nProblem 2 data sample:")
		if !isnothing(prob2.data_sample)
			for (key, value) in prob2.data_sample
				if key == "t"
					println("  Time points: ", value[1:min(5, length(value))], length(value) > 5 ? "..." : "")
				else
					println("  $key: ", value[1:min(5, length(value))], length(value) > 5 ? "..." : "")
				end
			end
		else
			println("No data sample")
		end
	else
		println("Could not compare data samples - field not present in one or both problems")
	end
end

"""
	process_petab_with_true_values(petab_dir::String)

Process a PEtab directory, including true values from JSON if available.
"""
function process_petab_with_true_values(petab_dir::String)
	# First use our core converter
	prob = convert_petab_to_odepe(petab_dir)

	# Load true values from JSON if it exists
	true_values_file = joinpath(petab_dir, "true_values.json")
	if isfile(true_values_file)
		true_values = JSON.parsefile(true_values_file)
		println("\nLoaded true values: ", true_values)

		# Update parameter dictionary with true values
		for (param_name, value) in true_values["parameters"]
			println("\nLooking for parameter: ", param_name)
			param_idx = findfirst(p -> string(p) == param_name, collect(keys(prob.p_true)))
			if isnothing(param_idx)
				@warn "Could not find parameter $param_name in parameters list"
				continue
			end
			param = collect(keys(prob.p_true))[param_idx]
			prob.p_true[param] = value
		end

		# Update initial conditions with true values
		for (state_name, value) in true_values["initial_conditions"]
			println("\nLooking for state: ", state_name)
			state_idx = findfirst(s -> string(s) == state_name * "(t)", collect(keys(prob.ic)))
			if isnothing(state_idx)
				@warn "Could not find state $state_name in states list"
				continue
			end
			state = collect(keys(prob.ic))[state_idx]
			prob.ic[state] = value
		end
	end

	# If this is the substr_test problem, compare with the reference implementation
	#if (false)
	#	println("Comparing with reference implementation...")
	#	println(petab_dir)
	#	println(basename(petab_dir))
	#	#if basename(petab_dir) == "petab_substr_test"
	#	println("\nDetected substr_test problem, comparing with reference implementation...")
	#	ref_prob =
	#		ODEParameterEstimation.sample_problem_data(onesp_cubed(), datasize = 21, time_interval = [-0.5, 0.5])
	#	compare_problems(prob, ref_prob)
	#end

	return prob


end

# Find and process all petab directories
function process_all_petab_problems()
	# Get the current directory
	current_dir = pwd()

	# Find all directories that start with "petab"
	petab_dirs = [
		"petab_simple",
		"petab_simple_linear_combination",
		"petab_sum_test",
		"petab_onesp_cubed",
		"petab_threesp_cubed",
		"petab_substr_test",
		"petab_global_unident_test",
		"petab_vanderpol",
		"petab_slowfast",
		"petab_fitzhugh-nagumo",
		"petab_Lotka_Volterra",
		"petab_DAISY_ex3",
		"petab_DAISY_mamil3",
		"petab_treatment",
		"petab_DAISY_mamil4",
		"petab_BioHydrogenation",
		"petab_SEIR",
		"petab_hiv",
		"petab_Crauste",
		"petab_sirsforced",
	]

	println("\nFound $(length(petab_dirs)) PEtab directories to process:")
	for dir in petab_dirs
		println("  - $dir")
	end
	println()

	# Create a results directory if it doesn't exist
	results_dir = "petab_results"
	mkpath(results_dir)

	# Process each directory
	results = Dict()
	for (i, dir) in enumerate(petab_dirs)
		println("\n[$i/$(length(petab_dirs))] Processing $dir...")
		log_file = joinpath(results_dir, "$(dir)_log.txt")

		open(log_file, "w") do io
			old_stdout = stdout
			redirect_stdout(io) do
				try
					prob = process_petab_with_true_values(dir)
					result = analyze_parameter_estimation_problem(prob)
					results[dir] = result
					println("Analysis complete for $dir")
				catch e
					@error "Error processing $dir" exception = (e, catch_backtrace())
					results[dir] = nothing
				end
			end
		end
	end

	# Write a summary
	open(joinpath(results_dir, "summary.txt"), "w") do io
		println(io, "PEtab Analysis Summary")
		println(io, "====================")
		println(io, "Processed at: ", Dates.now())
		println(io, "Number of problems: ", length(petab_dirs))
		println(io)

		# Sort by directory name and handle possible nothing results
		for dir in sort(collect(keys(results)))
			result = results[dir]
			if isnothing(result)
				println(io, "❌ $dir: Analysis failed")
			else
				println(io, "✓ $dir: Best error = $result")
			end
		end
	end

	return results
end

# Run the analysis
using Dates
println("Starting PEtab analysis at ", Dates.now())
results = process_all_petab_problems()
println("\nAnalysis complete at ", Dates.now())
println("See petab_results/summary.txt for a summary of all results")

