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
using GaussianProcesses
using LineSearches
using Plots
using BaryRational
using ForwardDiff
using Printf
using Loess

# Include our core converter and the examples file
include("convert_petab.jl")
include("../all_examples.jl")
include("../../src/bary_derivs.jl")


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
		#"petab_simple",
		#"petab_simple_linear_combination",
		"petab_sum_test",
		#"petab_onesp_cubed",
		#"petab_threesp_cubed",
		#"petab_substr_test",
		#"petab_global_unident_test",
		#"petab_trivial_unident",
		#"petab_vanderpol",
		#"petab_slowfast",
		#"petab_fitzhugh-nagumo",
		#"petab_Lotka_Volterra",
		#"petab_DAISY_ex3",
		#"petab_DAISY_mamil3",
		#"petab_treatment",
		#"petab_DAISY_mamil4",
		#"petab_BioHydrogenation",
		#"petab_SEIR",
		#"petab_hiv",
		#"petab_Crauste",
		#"petab_sirsforced",
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

"""
	analyze_interpolation_methods(petab_dir::String, output_prefix::String = "interp_analysis")

Analyze different interpolation methods on a PEtab problem.
"""
function analyze_interpolation_methods(petab_dir::String, output_prefix::String = "interp_analysis")
	# Load the PEtab problem with true values
	prob = process_petab_with_true_values(petab_dir)

	# Calculate derivatives of observables
	expanded_measured_quantities, ObservableDerivatives = calculate_observable_derivatives(
		equations(prob.model.system),
		prob.measured_quantities,
		5,
	)

	# Create new ODESystem with derivative observables
	@named new_sys = ODESystem(equations(prob.model.system), t; observed = expanded_measured_quantities)

	# Create new ODEProblem with derivatives
	new_prob = ODEProblem(structural_simplify(new_sys), prob.ic, (0.0, 10.0), prob.p_true)

	# Solve the system
	sol = solve(new_prob, Tsit5())

	# Get the sample data time points
	ts = prob.data_sample["t"]
	observables = collect(keys(filter(p -> p.first != "t", prob.data_sample)))

	# Storage for predictions and errors
	all_preds = Dict()
	all_errors = Dict()
	all_first_derivs = Dict()
	all_first_deriv_errors = Dict()
	all_second_derivs = Dict()
	all_second_deriv_errors = Dict()

	# Generate midpoints for testing interpolation
	midpoints = [(ts[i] + ts[i+1]) / 2 for i in 1:(length(ts)-1)]

	# Debug file for method parameters and predictions
	open(output_prefix * "_debug.txt", "w") do debug_io
		println(debug_io, "Interpolation Debug Information")
		println(debug_io, "============================")
		println(debug_io, "Generated at: ", Dates.now())
		println(debug_io)

		# For each observable
		for (obs_idx, obs_key) in enumerate(observables)
			println(debug_io, "\nObservable: $obs_key")
			println(debug_io, "="^(length("Observable: $obs_key")))

			ys = prob.data_sample[obs_key]

			# Get true values and derivatives at midpoints for this observable
			true_vals = [sol(t, idxs = prob.measured_quantities[obs_idx].lhs) for t in midpoints]
			true_first_derivs = [sol(t, idxs = ObservableDerivatives[obs_idx, 1]) for t in midpoints]
			true_second_derivs = [sol(t, idxs = ObservableDerivatives[obs_idx, 2]) for t in midpoints]

			# Standard GPR
			println(debug_io, "\nMethod: GPR")

			# Create and optimize GP with standard parameters
			kernel = SEIso(log(std(ts) / 8), 0.0)  # Standard SE kernel
			mZero = MeanZero()
			gp = GP(ts, ys, mZero, kernel, -2.0)  # Standard noise level

			try
				optimize!(gp, method = BFGS(linesearch = LineSearches.BackTracking()))

				# Get predictions
				preds, vars = predict_y(gp, midpoints)

				# Create function for derivatives
				gpr_func = let gp = gp
					x -> begin
						pred, _ = predict_y(gp, [x])
						return pred[1]
					end
				end

				# Calculate derivatives
				first_derivs = [ForwardDiff.derivative(gpr_func, x) for x in midpoints]
				second_derivs = [ForwardDiff.derivative(x -> ForwardDiff.derivative(gpr_func, x), x) for x in midpoints]

				# Store results
				method_key = "$(obs_key)_GPR"
				all_preds[method_key] = copy(preds)
				all_errors[method_key] = abs.(preds .- true_vals)
				all_first_derivs[method_key] = copy(first_derivs)
				all_first_deriv_errors[method_key] = abs.(first_derivs .- true_first_derivs)
				all_second_derivs[method_key] = copy(second_derivs)
				all_second_deriv_errors[method_key] = abs.(second_derivs .- true_second_derivs)
			catch e
				@warn "GPR failed for $obs_key" exception = e
				println(debug_io, "GPR failed: ", e)
			end

			# Loess
			println(debug_io, "\nMethod: Loess")
			try
				# Fit Loess model
				model = loess(collect(ts), ys; span = 0.75)  # Standard span

				# Get predictions
				preds = predict(model, midpoints)

				# Create interpolating function for derivatives
				loess_func = x -> predict(model, [x])[1]

				# Calculate derivatives
				first_derivs = [ForwardDiff.derivative(loess_func, x) for x in midpoints]
				second_derivs = [ForwardDiff.derivative(x -> ForwardDiff.derivative(loess_func, x), x) for x in midpoints]

				# Store results
				method_key = "$(obs_key)_Loess"
				all_preds[method_key] = copy(preds)
				all_errors[method_key] = abs.(preds .- true_vals)
				all_first_derivs[method_key] = copy(first_derivs)
				all_first_deriv_errors[method_key] = abs.(first_derivs .- true_first_derivs)
				all_second_derivs[method_key] = copy(second_derivs)
				all_second_deriv_errors[method_key] = abs.(second_derivs .- true_second_derivs)
			catch e
				@warn "Loess failed for $obs_key" exception = e
				println(debug_io, "Loess failed: ", e)
			end

			# AAA (keeping this as a baseline)
			println(debug_io, "\nMethod: AAA")
			aaa_approx = BaryRational.aaa(ts, ys, verbose = false)
			aaa_preds = [baryEval(x, aaa_approx.f, aaa_approx.x, aaa_approx.w) for x in midpoints]

			aaa_func = x -> baryEval(x, aaa_approx.f, aaa_approx.x, aaa_approx.w)
			aaa_first_derivs = [ForwardDiff.derivative(aaa_func, x) for x in midpoints]
			aaa_second_derivs = [ForwardDiff.derivative(x -> ForwardDiff.derivative(aaa_func, x), x) for x in midpoints]

			method_key = "$(obs_key)_AAA"
			all_preds[method_key] = aaa_preds
			all_errors[method_key] = abs.(aaa_preds .- true_vals)
			all_first_derivs[method_key] = aaa_first_derivs
			all_first_deriv_errors[method_key] = abs.(aaa_first_derivs .- true_first_derivs)
			all_second_derivs[method_key] = aaa_second_derivs
			all_second_deriv_errors[method_key] = abs.(aaa_second_derivs .- true_second_derivs)
		end
	end

	# Calculate and save detailed statistics
	open(output_prefix * "_detailed_stats.txt", "w") do io
		println(io, "Detailed Interpolation Error Statistics")
		println(io, "===================================")
		println(io, "Generated at: ", Dates.now())
		println(io)

		# For each observable
		for obs_key in observables
			println(io, "\nObservable: $obs_key")
			println(io, "="^(length("Observable: $obs_key")))

			# For each method
			methods = ["GPR", "Loess", "AAA"]

			for method in methods
				method_key = "$(obs_key)_$(method)"
				if !haskey(all_errors, method_key)
					continue
				end

				println(io, "\nMethod: $method")
				println(io, "-"^(length("Method: $method")))

				# Function to print statistics
				function print_stats(io, name, errors)
					println(io, "\n$name:")
					println(io, "  Mean Error: ", mean(errors))
					println(io, "  Median Error: ", median(errors))
					println(io, "  Max Error: ", maximum(errors))
					println(io, "  Min Error: ", minimum(errors))
					println(io, "  Std Error: ", std(errors))
					println(io, "  RMSE: ", sqrt(mean(errors .^ 2)))
				end

				print_stats(io, "Values", all_errors[method_key])
				print_stats(io, "First Derivatives", all_first_deriv_errors[method_key])
				print_stats(io, "Second Derivatives", all_second_deriv_errors[method_key])
			end
		end
	end

	# Create visualization plots
	for obs_key in observables
		p1 = plot(title = "Value Errors - $obs_key", xlabel = "Time", ylabel = "Absolute Error", yscale = :log10)
		p2 = plot(title = "First Derivative Errors - $obs_key", xlabel = "Time", ylabel = "Absolute Error", yscale = :log10)
		p3 = plot(title = "Second Derivative Errors - $obs_key", xlabel = "Time", ylabel = "Absolute Error", yscale = :log10)

		for method in ["GPR", "Loess", "AAA"]
			method_key = "$(obs_key)_$(method)"
			if !haskey(all_errors, method_key)
				continue
			end

			plot!(p1, midpoints, all_errors[method_key], label = method)
			plot!(p2, midpoints, all_first_deriv_errors[method_key], label = method)
			plot!(p3, midpoints, all_second_deriv_errors[method_key], label = method)
		end

		p = plot(p1, p2, p3, layout = (3, 1), size = (800, 1200))
		savefig(p, output_prefix * "_$(obs_key)_errors.png")
	end

	return all_errors, all_first_deriv_errors, all_second_deriv_errors
end

# Run the analysis
using Dates
#println("Starting PEtab analysis at ", Dates.now())
#results = process_all_petab_problems()
#println("\nAnalysis complete at ", Dates.now())
#println("See petab_results/summary.txt for a summary of all results")

analyze_interpolation_methods("petab_Lotka_Volterra")
