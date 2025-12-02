using ODEParameterEstimation
using ModelingToolkit
using Plots
using Statistics
using OrderedCollections
#using PrettyTables
using ModelingToolkit: t_nounits as t, D_nounits as D, value

# Function to print model summary
function print_model_summary(model, measured_quantities, p_true, ic_true)
	println("\nModel Summary:")
	println("States:")
	for (state, ic) in ic_true
		println("  $state (IC = $ic)")
	end
	println("\nParameters:")
	for (param, val) in p_true
		println("  $param = $val")
	end
	println("\nObservables:")
	for eq in measured_quantities
		println("  $(eq.lhs) = $(eq.rhs)")
	end
	println()
end

# Define the test case using DAISY_ex3 model
function create_test_case(; datasize = 21, time_interval = [0.0, 1.0], solver = Rodas5())
	# Define the model components
	parameters = @parameters p1 p3 p4 p6 p7
	states = @variables x1(t) x2(t) x3(t) u0(t)
	observables = @variables y1(t) y2(t)
	D = Differential(t)

	# Define true parameters and initial conditions
	ic_true = [0.2, 0.4, 0.6, 0.8]
	p_true = [0.167, 0.333, 0.5, 0.667, 0.833]

	equations = [
		D(x1) ~ -1.0 * p1 * x1 + x2 + u0,
		D(x2) ~ p3 * x1 - p4 * x2 + x3,
		D(x3) ~ p6 * x1 - p7 * x3,
		D(u0) ~ 1.0,
	]
	measured_quantities = [y1 ~ x1, y2 ~ u0]

	# Create the model using create_ordered_ode_system
	model, mq = create_ordered_ode_system("DAISY_ex3", states, parameters, equations, measured_quantities)

	# Create the parameter estimation problem
	pep = ParameterEstimationProblem(
		"DAISY_ex3",
		model,
		mq,
		nothing,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)

	# Generate synthetic data
	return sample_problem_data(pep, datasize = datasize, time_interval = time_interval)
end

# Function to calculate RMSE
function calculate_rmse(predicted, actual)
	return sqrt(mean((predicted .- actual) .^ 2))
end

# Function to analyze a single solution
function analyze_solution(model, solution, data_sample, p_true, ic_true, solver; plot_prefix = "solution_")
	# Extract parameters and initial conditions
	states = solution.states
	parameters = solution.parameters

	# Create ODE problem with these parameters
	tspan = (data_sample["t"][begin], data_sample["t"][end])

	# Create ODEProblem using the OrderedODESystem's inner system
	prob = ODEProblem(model.system, collect(values(states)), tspan, Dict(ModelingToolkit.parameters(model.system) .=> collect(values(parameters))))

	# Also create a solution with true parameters for comparison
	true_prob = ODEProblem(model.system, collect(values(ic_true)), tspan, Dict(ModelingToolkit.parameters(model.system) .=> collect(values(p_true))))
	true_sol = solve(true_prob, solver, saveat = data_sample["t"])

	# Solve ODE
	sol = solve(prob, solver, saveat = data_sample["t"])

	# Print tabular data
	println("\nTime series data:")
	header = ["t"]
	for state in keys(ic_true)
		push!(header, string(state) * "(true)")
	end
	for state in keys(ic_true)
		push!(header, string(state) * "(est)")
	end

	data = Matrix{Float64}(undef, length(data_sample["t"]), 1 + 2 * length(ic_true))
	for (i, t) in enumerate(data_sample["t"])
		data[i, 1] = t
		# True values from true solution
		for (j, state) in enumerate(keys(ic_true))
			state_sym = Symbol(replace(string(state), "(t)" => ""))
			data[i, j+1] = Array(true_sol[state_sym, :])[i]
		end
		# Estimated values
		for (j, state) in enumerate(keys(ic_true))
			state_sym = Symbol(replace(string(state), "(t)" => ""))
			data[i, j+1+length(ic_true)] = Array(sol[state_sym, :])[i]
		end
	end
	pretty_table(data, header = header, formatters = ft_round(4))

	# Calculate observation RMSEs
	obs_rmse = Dict()
	obs_keys = filter(k -> k != "t", keys(data_sample))
	for key in obs_keys
		# Find the corresponding state for this observation
		for eq in model.system.observed
			if string(eq.lhs) == key
				state_sym = Symbol(replace(string(eq.rhs), "(t)" => ""))
				predicted = Array(sol[state_sym, :])
				obs_rmse[key] = calculate_rmse(predicted, data_sample[key])
				break
			end
		end
	end

	println("\nParameters:")
	param_data = Matrix{Any}(undef, length(p_true), 4)
	for (i, (param, true_val)) in enumerate(p_true)
		est_val = parameters[param]
		rel_err = abs((est_val - true_val) / true_val) * 100
		param_data[i, :] = [string(param), float(true_val), float(est_val), float(rel_err)]
	end
	pretty_table(param_data, header = ["Parameter", "True", "Estimated", "Rel. Error (%)"], formatters = ft_round(4))

	println("\nInitial Conditions:")
	ic_data = Matrix{Any}(undef, length(ic_true), 4)
	for (i, (state, true_val)) in enumerate(ic_true)
		est_val = states[state]
		rel_err = abs((est_val - true_val) / true_val) * 100
		ic_data[i, :] = [string(state), float(true_val), float(est_val), float(rel_err)]
	end
	pretty_table(ic_data, header = ["State", "True", "Estimated", "Rel. Error (%)"], formatters = ft_round(4))

	# Calculate error metrics
	state_rmse = Dict()
	obs_rmse = Dict()
	param_rel_errors = Dict()

	# Get state names without (t)
	state_names = Dict(state => Symbol(replace(string(state), "(t)" => "")) for state in keys(ic_true))

	# Calculate state RMSEs comparing with true solution
	for state in keys(ic_true)
		state_sym = state_names[state]
		predicted = Array(sol[state_sym, :])
		true_values = Array(true_sol[state_sym, :])
		state_rmse[state] = calculate_rmse(predicted, true_values)
	end

	# Calculate parameter relative errors
	all_params = merge(OrderedDict(), ic_true, p_true)
	estimates = vcat(collect(values(states)), collect(values(parameters)))
	true_values = collect(values(all_params))

	for (param, true_val, est_val) in zip(keys(all_params), true_values, estimates)
		# Handle NaN/Inf estimated values
		if !isfinite(est_val)
			param_rel_errors[param] = NaN
		# Handle near-zero true values (use absolute error instead of relative)
		elseif abs(true_val) < 1e-6
			param_rel_errors[param] = abs(est_val - true_val)
		else
			param_rel_errors[param] = abs((est_val - true_val) / true_val)
		end
	end

	return Dict(
		"state_rmse" => state_rmse,
		"obs_rmse" => obs_rmse,
		"param_rel_errors" => param_rel_errors,
	)
end

# Function to compare two solutions for similarity
function solutions_are_similar(sol1, sol2, tolerance = 1e-4)
	# Compare errors first (fast check)
	if isnothing(sol1.err) || isnothing(sol2.err)
		return false
	end

	# Debug print
	if abs(sol1.err - sol2.err) < 1e-10
		# If errors are exactly equal, print parameter values
		println("Found solutions with identical errors: $(sol1.err)")
		println("Parameters 1: ", collect(values(sol1.parameters)))
		println("Parameters 2: ", collect(values(sol2.parameters)))
	end

	# Use exact equality for identical solutions
	if sol1.err == sol2.err
		# If errors are exactly equal, check if all values are exactly equal
		all_equal_params = all(p1 == p2 for (p1, p2) in zip(values(sol1.parameters), values(sol2.parameters)))
		all_equal_states = all(s1 == s2 for (s1, s2) in zip(values(sol1.states), values(sol2.states)))
		if all_equal_params && all_equal_states
			return true
		end
	end

	# For non-identical solutions, use tolerance-based comparison
	if abs(sol1.err - sol2.err) > tolerance
		return false
	end

	# Compare parameter values
	for (p1, p2) in zip(values(sol1.parameters), values(sol2.parameters))
		if abs(p1 - p2) > tolerance * max(abs(p1), abs(p2), 1.0)  # Use relative tolerance
			return false
		end
	end

	# Compare state values
	for (s1, s2) in zip(values(sol1.states), values(sol2.states))
		if abs(s1 - s2) > tolerance * max(abs(s1), abs(s2), 1.0)  # Use relative tolerance
			return false
		end
	end

	return true
end

# Main analysis function
function analyze_solutions()
	# Create test case
	pep = create_test_case()

	# Print model summary
	print_model_summary(pep.model, pep.measured_quantities, pep.p_true, pep.ic)

	# Debug: Print data sample contents
	println("\nData sample contents:")
	for (key, value) in pep.data_sample
		println("$key: ", typeof(value))
	end

	# Run parameter estimation
	println("\nRunning parameter estimation...")
	results = ODEPEtestwrapper(pep.model, pep.measured_quantities, pep.data_sample, pep.solver)

	# Sort results by error
	sort!(results, by = x -> isnothing(x.err) ? Inf : x.err)

	# Deduplicate solutions
	unique_solutions = []
	for solution in results
		if isnothing(solution.err) || solution.err > 100
			continue
		end

		# Check if this solution is similar to any we've already kept
		is_duplicate = any(s -> solutions_are_similar(s, solution), unique_solutions)

		if !is_duplicate
			push!(unique_solutions, solution)
		end
	end

	# Analyze each unique solution
	println("\nAnalyzing solutions...")
	for (i, solution) in enumerate(unique_solutions)
		println("\n=== Solution $i (Error: $(round(solution.err, digits=6))) ===")

		# Analyze this solution
		analysis = analyze_solution(
			pep.model,
			solution,
			pep.data_sample,
			pep.p_true,
			pep.ic,
			pep.solver,
		)

		# Print summary metrics
		println("\nSummary of Error Metrics:")
		println("\nState Variable RMSE:")
		for (state, rmse) in analysis["state_rmse"]
			println("  $state: $(round(value(rmse), digits=6))")
		end

		println("\nObservation RMSE:")
		for (obs, rmse) in analysis["obs_rmse"]
			println("  $obs: $(round(value(rmse), digits=6))")
		end
	end
end

# Run the analysis if this is the main script
if abspath(PROGRAM_FILE) == @__FILE__
	analyze_solutions()
end
