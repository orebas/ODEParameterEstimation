using ModelingToolkit
using OrderedCollections
using Logging
using LinearAlgebra
using NonlinearSolve
using OrdinaryDiffEq
using Statistics

# Use functions from the current module
using ..ODEParameterEstimation

"""
	setup_parameter_estimation(PEP::ParameterEstimationProblem; max_num_points, point_hint)

Setup phase for parameter estimation. This extracts the necessary data from the problem,
determines the optimal number of points to use, analyzes identifiability, and selects
time indices for sampling.

# Arguments
- `PEP`: Parameter estimation problem
- `max_num_points`: Maximum number of points to use
- `point_hint`: Hint for where to sample in the time series (0-1 range)

# Returns
- Named tuple with all settings needed for the solution phase
"""
function setup_parameter_estimation(
	PEP::ParameterEstimationProblem;
	max_num_points = 1,
	point_hint = 0.5,
	nooutput = false,
	interpolator = nothing,
)
	# Extract components from the problem
	t, eqns, states, params = unpack_ODE(PEP.model.system)
	t_vector = PEP.data_sample["t"]
	time_interval = extrema(t_vector)

	# Set up initial parameters
	num_points_cap = min(length(params), max_num_points, length(t_vector))

	# Create interpolants for measurement data
	interpolants = create_interpolants(PEP.measured_quantities, PEP.data_sample, t_vector, interpolator)

	# Determine optimal number of points and analyze identifiability
	good_num_points, good_deriv_level, good_udict, good_varlist, good_DD =
		determine_optimal_points_count(PEP.model.system, PEP.measured_quantities, num_points_cap, t_vector, nooutput)

	@debug "Parameter estimation using $(good_num_points) points"

	# Pick time points for estimation
	time_index_set = pick_points(t_vector, good_num_points, interpolants, point_hint)
	@debug "Using these points: $(time_index_set)"
	@debug "Using these observations and their derivatives: $(good_deriv_level)"

	return (
		states = states,
		params = params,
		t_vector = t_vector,
		interpolants = interpolants,
		good_num_points = good_num_points,
		good_deriv_level = good_deriv_level,
		good_udict = good_udict,
		good_varlist = good_varlist,
		good_DD = good_DD,
		time_index_set = time_index_set,
		all_unidentifiable = good_DD.all_unidentifiable,
	)
end

"""
	get_next_deriv_increment(current_deriv_level, attempted_increments; max_deriv_level=10)

Determine which observable's derivative level to increment next.

# Arguments
- `current_deriv_level`: Dict mapping observable indices to current derivative levels
- `attempted_increments`: Set of previously attempted (observable_index, new_level) pairs
- `max_deriv_level`: Maximum allowed derivative level (default: 10)

# Returns
- Tuple (observable_index, new_level) or nothing if no valid increment exists
"""
function get_next_deriv_increment(current_deriv_level, attempted_increments; max_deriv_level = 10)
	# TODO: max_deriv_level is a magic number - should be moved to config options

	# Generate all possible valid next increments
	candidates = []
	for (obs_idx, level) in current_deriv_level
		new_level = level + 1
		if new_level <= max_deriv_level && !((obs_idx, new_level) in attempted_increments)
			push!(candidates, (obs_idx, new_level))
		end
	end

	if isempty(candidates)
		return nothing
	end

	# Sort candidates to ensure deterministic selection.
	# Sort by new level first (prefer lowest), then by observable index.
	sort!(candidates, by = x -> (x[2], x[1]))

	return first(candidates)
end

"""
	solve_parameter_estimation(PEP, setup_data; system_solver, diagnostics, diagnostic_data)

Solution phase for parameter estimation. Using the settings from the setup phase,
this constructs and solves the system of equations to estimate parameters.

# Arguments
- `PEP`: Parameter estimation problem
- `setup_data`: Data from the setup phase
- `system_solver`: Function to solve the system (default: solve_with_rs)
- `diagnostics`: Whether to output diagnostic information
- `diagnostic_data`: Additional diagnostic data

# Returns
- Results from the solver (system solutions and metadata)
"""
function solve_parameter_estimation(
	PEP::ParameterEstimationProblem,
	setup_data;
	system_solver = solve_with_rs,
	interpolator = nothing,
	diagnostics = false,
	diagnostic_data = nothing,
	save_system = true,
	max_reconstruction_attempts = 10,  # TODO: magic number - should be moved to config options
	max_deriv_level = 10,  # TODO: magic number - should be moved to config options
	debug_solver = false,
	debug_cas_diagnostics = false,
	debug_dimensional_analysis = false,
	polish_solver_solutions::Bool = false,
)
	# Extract settings from setup data
	states = setup_data.states
	params = setup_data.params
	t_vector = setup_data.t_vector
	interpolants = setup_data.interpolants
	good_deriv_level = setup_data.good_deriv_level
	good_udict = setup_data.good_udict
	good_varlist = setup_data.good_varlist
	good_DD = setup_data.good_DD
	time_index_set = setup_data.time_index_set

	# Construct the multipoint equation system
	full_target, full_varlist, forward_subst_dict, reverse_subst_dict =
		construct_multipoint_equation_system!(
			time_index_set,
			PEP.model.system,
			PEP.measured_quantities,
			PEP.data_sample,
			good_deriv_level,
			good_udict,
			good_varlist,
			good_DD,
			interpolator,
			interpolants,
			diagnostics,
			diagnostic_data,
			states,
			params,
		)

	# Combine all equations into a single target
	final_target = reduce(vcat, full_target)

	# Create the final list of variables to solve for
	# final_varlist = collect(OrderedDict{eltype(first(full_varlist)), Nothing}(v => nothing for v in reduce(vcat, full_varlist)).keys)
	# FINAL FIX: Correctly extract variables from the final symbolic system *after* all substitutions
	final_vars_set = OrderedSet()
	for eq in final_target
		union!(final_vars_set, Symbolics.get_variables(eq))
	end
	final_varlist = collect(final_vars_set)


	# Print diagnostic information if requested
	if diagnostics && !isnothing(diagnostic_data)
		log_diagnostic_info(
			PEP,
			time_index_set,
			good_deriv_level,
			good_udict,
			good_varlist,
			good_DD,
			interpolator,
			interpolants,
			diagnostic_data,
			states,
			params,
			final_target,
			forward_subst_dict,
			reverse_subst_dict,
		)
	end

	# Solve the system with reconstruction loop for non-zero-dimensional cases
	@debug "Solving system..."

	# Define a container for the results
	solve_result, hcvarlist, trivial_dict, trimmed_varlist = nothing, nothing, nothing, nothing

	# Initialize reconstruction tracking
	reconstruction_attempts = 0
	attempted_increments = Set{Tuple{Int, Int}}()
	current_deriv_level = deepcopy(good_deriv_level)

	# Main solving loop with reconstruction capability
	while reconstruction_attempts < max_reconstruction_attempts
		# Reconstruct the equation system if this is not the first attempt
		if reconstruction_attempts > 0
			@info "Reconstruction attempt $reconstruction_attempts: Re-constructing equation system with updated derivative levels"
			if diagnostics
				println("[DEBUG-ODEPE] Previous deriv_level: ", good_deriv_level)
				println("[DEBUG-ODEPE] Current deriv_level: ", current_deriv_level)
			end

			# Save the previous system for comparison
			prev_num_equations = length(final_target)
			prev_num_variables = length(final_varlist)

			# Need to recompute DerivativeData with the new deriv_level
			# The max derivative level needs to accommodate the highest derivative we're using
			max_deriv_needed = maximum(values(current_deriv_level)) + 2  # Add buffer for safety

			# Recompute the derivative data with the updated requirements
			updated_DD = ODEParameterEstimation.populate_derivatives(PEP.model.system, PEP.measured_quantities, max_deriv_needed, good_udict)

			# Reconstruct the multipoint equation system with new deriv_level and updated DD
			full_target, full_varlist, forward_subst_dict, reverse_subst_dict =
				construct_multipoint_equation_system!(
					time_index_set,
					PEP.model.system,
					PEP.measured_quantities,
					PEP.data_sample,
					current_deriv_level,  # Use updated deriv_level
					good_udict,
					good_varlist,
					updated_DD,  # Use recomputed derivative data
					interpolator,
					interpolants,
					diagnostics,
					diagnostic_data,
					states,
					params,
				)

			# Combine all equations into a single target
			final_target = reduce(vcat, full_target)

			# Create the final list of variables to solve for
			final_varlist = collect(OrderedDict{eltype(first(full_varlist)), Nothing}(v => nothing for v in reduce(vcat, full_varlist)).keys)

			# Report the changes
			if diagnostics
				println("[DEBUG-ODEPE] System size changed from $prev_num_equations equations, $prev_num_variables variables")
				println("[DEBUG-ODEPE]                     to $(length(final_target)) equations, $(length(final_varlist)) variables")
			end

			# Save both systems for debugging if requested
			if save_system
				# Save the reconstructed polynomial system
				save_filepath = "saved_systems/system_reconstruction_$(reconstruction_attempts)_$(now()).jl"
				mkpath(dirname(save_filepath)) # Ensure directory exists
				save_poly_system(save_filepath, final_target, final_varlist,
					metadata = Dict(
						"timestamp" => string(now()),
						"num_equations" => length(final_target),
						"num_variables" => length(final_varlist),
						"reconstruction_attempt" => reconstruction_attempts,
						"deriv_level" => current_deriv_level,
						"description" => "Reconstructed system after incrementing derivatives",
					),
				)
				@info "Saved reconstructed polynomial system to $save_filepath"
			end
		end

		if save_system
			# Save the polynomial system before attempting to solve it
			if reconstruction_attempts == 0
				save_filepath = "saved_systems/system_$(now()).jl"
			else
				save_filepath = "saved_systems/system_attempt_$(reconstruction_attempts)_$(now()).jl"
			end
			mkpath(dirname(save_filepath)) # Ensure directory exists
			save_poly_system(save_filepath, final_target, final_varlist,
				metadata = Dict(
					"timestamp" => string(now()),
					"num_equations" => length(final_target),
					"num_variables" => length(final_varlist),
					"reconstruction_attempt" => reconstruction_attempts,
					"deriv_level" => current_deriv_level,
				),
			)
			@info "Saved polynomial system to $save_filepath"

			# Also save in a simple text format for external analysis
			txt_filepath = replace(save_filepath, ".jl" => ".txt")
			open(txt_filepath, "w") do f
				println(f, "# Polynomial System")
				println(f, "# Equations: ", length(final_target))
				println(f, "# Variables: ", length(final_varlist))
				println(f, "# Variables list: ", final_varlist)
				println(f, "\n# Equations:")
				for (i, eq) in enumerate(final_target)
					println(f, "Eq$i: ", eq)
				end
			end
			@info "Also saved as text to $txt_filepath"
		end

		# Debug: Print polynomial system details
		if diagnostics
			println("\n[DEBUG-ODEPE] POLYNOMIAL SYSTEM DETAILS (attempt $reconstruction_attempts):")
			println("[DEBUG-ODEPE] Number of equations: ", length(final_target))
			println("[DEBUG-ODEPE] Number of variables: ", length(final_varlist))
			if reconstruction_attempts == 0
				println("[DEBUG-ODEPE] Variables: ", final_varlist)

				# Only print equations in deep debug mode
				if get(ENV, "ODEPE_DEEP_DEBUG", "false") == "true"
					println("[DEBUG-ODEPE] Equations:")
					for (i, eq) in enumerate(final_target)
						println("[DEBUG-ODEPE]   Eq $i: ", eq)
					end
				end
			end
		end

		# Attempt to solve the system
		local solver_result
		try
			# Prepare options for the solver
			solver_options = Dict(
				:debug_solver => debug_solver,
				:debug_cas_diagnostics => debug_cas_diagnostics,
				:debug_dimensional_analysis => debug_dimensional_analysis,
			)
			solver_result = system_solver(final_target, final_varlist; options = solver_options)


		catch e
			# Handle old-style exceptions for backward compatibility
			if isa(e, DomainError) && occursin("zerodimensional ideal", string(e))
				@warn "System is not zero-dimensional (via exception). Will attempt reconstruction."
				solver_result = (:needs_reconstruction, final_varlist, Dict(), final_varlist)
			else
				# Rethrow other errors
				rethrow(e)
			end
		end

		# Check if we got a special status indicating reconstruction is needed
		if isa(solver_result, Tuple) && length(solver_result) == 4 && solver_result[1] == :needs_reconstruction
			@info "System is not zero-dimensional. Attempting to add constraints via higher derivative levels."

			# Find next observable to increment
			next_increment = get_next_deriv_increment(current_deriv_level, attempted_increments; max_deriv_level = max_deriv_level)

			if isnothing(next_increment)
				@error "Cannot increment any more derivative levels. All observables at maximum or already attempted."
				error("Failed to achieve zero-dimensional system after exhausting all derivative increments.")
			end

			obs_idx, new_level = next_increment
			push!(attempted_increments, (obs_idx, new_level))

			@info "Incrementing derivative level for observable $obs_idx from $(current_deriv_level[obs_idx]) to $new_level"
			current_deriv_level[obs_idx] = new_level

			reconstruction_attempts += 1
			continue  # Try again with updated deriv_level
		else
			# Normal solution found
			solve_result, hcvarlist, trivial_dict, trimmed_varlist = solver_result
			@info "Successfully solved system" * (reconstruction_attempts > 0 ? " after $reconstruction_attempts reconstruction attempt(s)" : "")

			# Optional local polish pass using fast NL least-squares if enabled
			if polish_solver_solutions && !isempty(solve_result)
				polished = Vector{Vector{Float64}}()
				for sol in solve_result
					start_pt = real.(sol)
					p_solutions, _, _, _ = solve_with_fast_nlopt(final_target, final_varlist;
						start_point = start_pt,
						polish_only = true,
						options = Dict(:abstol => 1e-12, :reltol => 1e-12, :debug_solver => diagnostics, :log_every => 5),
					)
					if !isempty(p_solutions)
						push!(polished, p_solutions[1])
					else
						push!(polished, sol)
					end
				end
				solve_result = polished
			end

			break
		end
	end

	# Check if we exhausted attempts
	if reconstruction_attempts >= max_reconstruction_attempts
		@error "Exhausted maximum reconstruction attempts ($max_reconstruction_attempts)"
		error("Failed to solve system after $max_reconstruction_attempts reconstruction attempts")
	end

	# Check if a solution was found
	if isnothing(solve_result)
		error("Failed to solve the system, even after modifications.")
	end

	return (
		solns = solve_result,
		hcvarlist = hcvarlist,
		trivial_dict = trivial_dict,
		trimmed_varlist = trimmed_varlist,
		forward_subst_dict = forward_subst_dict,
		reverse_subst_dict = reverse_subst_dict,
		final_varlist = final_varlist,
		good_udict = good_udict,
	)
end

"""
	process_estimation_results(PEP, solution_data, lowest_time_index; polish_solutions, polish_maxiters, polish_method)

Process the raw results from the solver into a format suitable for analysis.
Backsolves for the original model parameters and creates ParameterEstimationResult objects.

# Arguments
- `PEP`: Parameter estimation problem
- `solution_data`: Data from the solution phase
- `lowest_time_index`: The lowest time index used in the estimation
- `polish_solutions`: Whether to polish solutions using optimization
- `polish_maxiters`: Maximum iterations for polishing
- `polish_method`: Optimization method for polishing

# Returns
- Vector of ParameterEstimationResult objects
"""
function process_estimation_results(
	PEP::ParameterEstimationProblem,
	solution_data,
	setup_data;
	opts::Union{Nothing, EstimationOptions} = nothing,
	nooutput = false,
	polish_solutions = false,
	polish_maxiters = 20,
	polish_method = NewtonTrustRegion,
)
	# If opts not provided, construct from legacy kwargs for backward compatibility
	if isnothing(opts)
		# Map legacy function types to PolishMethod enums
		pm = if polish_method isa PolishMethod
			polish_method
		elseif polish_method === NewtonTrustRegion
			PolishNewtonTrust
		elseif polish_method === LevenbergMarquardt
			PolishLevenberg
		elseif polish_method === GaussNewton
			PolishGaussNewton
		elseif polish_method === BFGS
			PolishBFGS
		elseif polish_method === LBFGS
			PolishLBFGS
		else
			PolishNewtonTrust  # default
		end
		opts = EstimationOptions(
			nooutput = nooutput,
			polish_solutions = polish_solutions,
			polish_maxiters = polish_maxiters,
			polish_method = pm,
		)
	end
	# Use opts as the single source of truth from here on
	nooutput = opts.nooutput
	polish_solutions = opts.polish_solutions
	# Extract components from the solution data
	solns = solution_data.solns
	forward_subst_dict = solution_data.forward_subst_dict
	trivial_dict = solution_data.trivial_dict
	final_varlist = solution_data.final_varlist
	trimmed_varlist = solution_data.trimmed_varlist

	# Extract components from the problem
	t, eqns, states, params = unpack_ODE(PEP.model.system)
	t_vector = PEP.data_sample["t"]

	# Find the lowest time index
	lowest_time_index = min(setup_data.time_index_set...)

	# Create a new model for solving ODEs
	@named new_model = ODESystem(eqns, t, states, params)
	new_model = complete(new_model)

	# Get current ordering from ModelingToolkit
	current_states = ModelingToolkit.unknowns(PEP.model.system)
	current_params = ModelingToolkit.parameters(PEP.model.system)

	# Create ordered dictionaries to preserve parameter order
	param_dict = OrderedDict(current_params .=> ones(length(current_params)))
	states_dict = OrderedDict(current_states .=> ones(length(current_states)))

	# Create a template for results
	# Create a template for the result
	result_template = ParameterEstimationResult(
		param_dict, states_dict, t_vector[lowest_time_index], nothing, nothing,
		length(PEP.data_sample["t"]), t_vector[lowest_time_index],
		OrderedDict{Num, Float64}(k => Float64(v) for (k, v) in solution_data.good_udict),
		Set{Num}(setup_data.all_unidentifiable), nothing,
	)

	# Process each solution
	results_vec = []
	for soln_index in eachindex(solns)
		# Determine shooting time index early — needed for _trfn_ state IC computation below.
		shoot_idx = hasfield(typeof(solution_data), :solution_time_indices) && soln_index <= length(solution_data.solution_time_indices) ? solution_data.solution_time_indices[soln_index] : lowest_time_index
		t_shoot = t_vector[shoot_idx]

		# Extract initial conditions and parameter values
		initial_conditions = [1e10 for s in states]
		parameter_values = [1e10 for p in params]

		# Lookup parameters
		for i in eachindex(params)
			param_search = if !isempty(forward_subst_dict[1])
				forward_subst_dict[1][(params[i])]
			else
				params[i]
			end
			# In SI-template workflow forward_subst_dict is empty; avoid using random good_udict values.
			use_si_workflow = isempty(forward_subst_dict[1])
			local_good_udict = use_si_workflow ? Dict{Any, Any}() : solution_data.good_udict
			# Prefer solver-provided values; if the parameter was eliminated by SI substitutions,
			# fall back to a consistent default (1.0) instead of a random value from good_udict.
			try
				parameter_values[i] = lookup_value(
					params[i], param_search,
					soln_index, local_good_udict, trivial_dict, final_varlist, trimmed_varlist, solns,
				)
			catch e
				if use_si_workflow
					@debug "Parameter $(params[i]) not found in solver vars under SI; defaulting to 1.0 for backsolve"
					parameter_values[i] = 1.0
				else
					rethrow(e)
				end
			end
		end

		# Lookup initial states
		for i in eachindex(states)
			# Check if this is a _trfn_ transcendental input state (e.g. _trfn_sin_5_0(t)).
			# These were substituted out during solving — their values are known analytically.
			state_name = string(states[i])
			base_name = replace(state_name, "(t)" => "")
			trfn_info = _parse_trfn_base_name(base_name)
			if !isnothing(trfn_info)
				func_type, frequency = trfn_info
				# Compute analytical value at shooting time (0th derivative = the function itself)
				if func_type == :sin
					initial_conditions[i] = sin(frequency * t_shoot)
				elseif func_type == :cos
					initial_conditions[i] = cos(frequency * t_shoot)
				elseif func_type == :exp
					initial_conditions[i] = exp(frequency * t_shoot)
				end
				@debug "Set _trfn_ state $(states[i]) = $(initial_conditions[i]) at t=$t_shoot"
				continue
			end

			model_state_search = if !isempty(forward_subst_dict[1])
				forward_subst_dict[1][(states[i])]
			else
				states[i]
			end
			# Convert trivial_dict to Dict{Symbol, Any} to ensure type stability
			safe_trivial_dict = Dict{Symbol, Any}(solution_data.trivial_dict)
			use_si_workflow = isempty(forward_subst_dict[1])
			try
				initial_conditions[i] = lookup_value(
					states[i], model_state_search,
					soln_index, solution_data.good_udict, safe_trivial_dict, final_varlist, trimmed_varlist, solns,
				)
			catch e
				if use_si_workflow
					# State not found in solver vars — it may have been eliminated because it
					# equals a measured quantity (e.g. y2 ~ y means y was treated as data).
					# Try to get its value from the data sample via measured quantities.
					found_from_mq = false
					for mq in PEP.measured_quantities
						mq_rhs = ModelingToolkit.diff2term(mq.rhs)
						if isequal(mq_rhs, states[i])
							# This state is directly observed via this measured quantity
							mq_lhs_str = string(mq.lhs)
							mq_key = replace(mq_lhs_str, "(t)" => "")
							if haskey(PEP.data_sample, mq_key)
								initial_conditions[i] = Float64(PEP.data_sample[mq_key][shoot_idx])
								@debug "State $(states[i]) resolved from measured quantity $mq_key at t=$t_shoot"
								found_from_mq = true
								break
							end
						end
					end
					if !found_from_mq
						@debug "State $(states[i]) not found in solver vars or measured quantities; defaulting to 0.0"
						initial_conditions[i] = 0.0
					end
				else
					rethrow(e)
				end
			end
		end

		# Convert to arrays of the appropriate type
		initial_conditions = convert_to_real_or_complex_array(initial_conditions)
		parameter_values = convert_to_real_or_complex_array(parameter_values)

		@debug "Processing solution $soln_index"
		@debug "Constructed initial conditions: $initial_conditions"
		@debug "Constructed parameter values: $parameter_values"

		# Solve the ODE with the estimated parameters
		tspan = (t_vector[shoot_idx], t_vector[1])
		u0_map = Dict(states .=> initial_conditions)
		p_map = Dict(params .=> parameter_values)

		prob = ODEProblem(new_model, merge(u0_map, p_map), tspan)
		ode_solution = try
			ModelingToolkit.solve(prob, PEP.solver, abstol = opts.abstol, reltol = opts.reltol)
		catch e
			@warn "ODE solve failed during final trajectory reconstruction: $e"
			nothing
		end

		# Extract state values at the initial dataset time (backsolved to t0)
		backsolved_initial_conditions = copy(initial_conditions)
		try
			if !(ode_solution === nothing)
				for (i, s) in enumerate(states)
					val0 = ode_solution(t_vector[1], idxs = s)
					backsolved_initial_conditions[i] = Float64(real(val0))
				end
			end
		catch e
			@warn "Failed to extract backsolved initial conditions at t0: $e"
		end

		@debug "Constructed initial conditions (at shooting time): $initial_conditions"
		@debug "Backsolved initial conditions (at t0): $backsolved_initial_conditions"
		@debug "Constructed parameter values: $parameter_values"

		# We report the initial conditions at t0 (backsolved), not the state at the shooting time
		push!(results_vec, [backsolved_initial_conditions; parameter_values])
	end

	# Convert raw results to ParameterEstimationResult objects
	solved_res = []
	for (i, raw_sol) in enumerate(results_vec)
		if !nooutput
			@debug "Processing solution $i for final result"
		end

		# Create a copy of the template
		push!(solved_res, deepcopy(result_template))

		# Process the raw solution
		ordered_states, ordered_params, ode_solution, err = process_raw_solution(
			raw_sol, PEP.model, PEP.data_sample, PEP.solver, abstol = opts.abstol, reltol = opts.reltol,
		)

		# Update result with processed data
		solved_res[end].states = ordered_states
		solved_res[end].parameters = ordered_params
		solved_res[end].solution = ode_solution
		solved_res[end].err = err
	end

	# Polish solutions if requested (shared context built once, reused for all solutions)
	if polish_solutions
		ctx = _build_polish_context(PEP; opts = opts)
		solved_res = _polish_batch_from_context(ctx, solved_res; opts = opts)
	end

	# Print solutions to match ParameterEstimation.jl output
	println("\n[ODEPE SOLUTIONS]:")
	for (i, result) in enumerate(solved_res)
		sol_dict = merge(result.states, result.parameters)
		println("Solution $i: $sol_dict")
	end

	return solved_res
end

"""
	log_diagnostic_info(PEP, time_index_set, good_deriv_level, good_udict, good_varlist, good_DD, interpolator, interpolants, diagnostic_data, states, params, final_target, forward_subst_dict, reverse_subst_dict)

Log diagnostic information about the system being solved.
This is a helper function for debugging and understanding the system.

# Arguments
- Various parameters from the parameter estimation problem and setup
"""
function log_diagnostic_info(
	PEP,
	time_index_set,
	good_deriv_level,
	good_udict,
	good_varlist,
	good_DD,
	interpolator,
	interpolants,
	diagnostic_data,
	states,
	params,
	final_target,
	forward_subst_dict,
	reverse_subst_dict,
)
	if (false)
		# Calculate maximum derivative level
		max_deriv = max(7, 1 + maximum(collect(values(good_deriv_level))))

		# Calculate observable derivatives
		expanded_mq, obs_derivs = calculate_observable_derivatives(
			equations(PEP.model.system), PEP.measured_quantities, max_deriv,
		)

		# Create a new system with the expanded measured quantities
		@named new_sys = ODESystem(equations(PEP.model.system), t; observed = expanded_mq)

		# Create and solve the problem with true parameters
		time_interval = extrema(PEP.data_sample["t"])
		local_prob = ODEProblem(
			structural_simplify(new_sys),
			merge(diagnostic_data.ic, diagnostic_data.p_true),
			time_interval,
		)

		ideal_sol = ModelingToolkit.solve(
			local_prob, AutoVern9(Rodas4P()), abstol = 1e-14, reltol = 1e-14,
			saveat = PEP.data_sample["t"],
		)

		# Construct equation system with ideal values
		ideal_full_target, ideal_full_varlist, ideal_forward_subst_dict, ideal_reverse_subst_dict =
			construct_multipoint_equation_system!(
				time_index_set,
				PEP.model.system,
				PEP.measured_quantities,
				PEP.data_sample,
				good_deriv_level,
				good_udict,
				good_varlist,
				good_DD,
				interpolator,
				interpolants,
				true,
				diagnostic_data,
				states,
				params,
				ideal = true,
				sol = ideal_sol,
			)

		ideal_final_target = reduce(vcat, ideal_full_target)

		# Log the targets
		log_equations(ideal_final_target, "Ideal final target")
		log_equations(final_target, "Actual target being solved")

		# Log parameter and state values
		@info "True parameter values: $(PEP.p_true)"
		@info "True states: $(PEP.ic)"

		# Get state and parameter values at the lowest time
		lowest_time = min(time_index_set...)
		exact_state_vals = OrderedDict{Num, Float64}()
		for s in states
			exact_state_vals[s] = ideal_sol(PEP.data_sample["t"][lowest_time], idxs = s)
		end

		# Evaluate the polynomial system with exact values
		exact_system = evaluate_poly_system(
			ideal_final_target,
			ideal_forward_subst_dict[1],
			ideal_reverse_subst_dict[1],
			exact_state_vals,
			PEP.p_true,
			equations(PEP.model.system),
		)

		inexact_system = evaluate_poly_system(
			final_target,
			forward_subst_dict[1],
			reverse_subst_dict[1],
			exact_state_vals,
			PEP.p_true,
			equations(PEP.model.system),
		)

		# Log the evaluated systems
		log_equations(exact_system, "Evaluated ideal polynomial system with exact values")
		log_equations(inexact_system, "Evaluated interpolated polynomial system with exact values")

		@info "Exact state values at time index $lowest_time: $(exact_state_vals)"
		@info "Exact parameter values: $(PEP.p_true)"
	end
end
