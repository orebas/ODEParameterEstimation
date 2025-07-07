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
    interpolator = nothing
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
        all_unidentifiable = good_DD.all_unidentifiable
    )
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
    diagnostic_data = nothing
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
            params
        )
    
    # Combine all equations into a single target
    final_target = reduce(vcat, full_target)
    
    # Create the final list of variables to solve for
    final_varlist = collect(OrderedDict{eltype(first(full_varlist)), Nothing}(v => nothing for v in reduce(vcat, full_varlist)).keys)
    
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
            reverse_subst_dict
        )
    end
    
    # Solve the system
    @debug "Solving system..."
    solve_result, hcvarlist, trivial_dict, trimmed_varlist = system_solver(final_target, final_varlist)
    
    return (
        solns = solve_result,
        hcvarlist = hcvarlist,
        trivial_dict = trivial_dict,
        trimmed_varlist = trimmed_varlist,
        forward_subst_dict = forward_subst_dict,
        reverse_subst_dict = reverse_subst_dict,
        final_varlist = final_varlist,
        good_udict = good_udict
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
    nooutput = false,
    polish_solutions = false,
    polish_maxiters = 20,
    polish_method = NewtonTrustRegion
)
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
        solution_data.good_udict, setup_data.all_unidentifiable, nothing
    )
    
    # Process each solution
    results_vec = []
    for soln_index in eachindex(solns)
        # Extract initial conditions and parameter values
        initial_conditions = [1e10 for s in states]
        parameter_values = [1e10 for p in params]
        
        # Lookup parameters
        for i in eachindex(params)
            param_search = forward_subst_dict[1][(params[i])]
            parameter_values[i] = lookup_value(
                params[i], param_search,
                soln_index, solution_data.good_udict, trivial_dict, final_varlist, trimmed_varlist, solns
            )
        end
        
        # Lookup initial states
        for i in eachindex(states)
            model_state_search = forward_subst_dict[1][(states[i])]
            initial_conditions[i] = lookup_value(
                states[i], model_state_search,
                soln_index, solution_data.good_udict, trivial_dict, final_varlist, trimmed_varlist, solns
            )
        end
        
        # Convert to arrays of the appropriate type
        initial_conditions = convert_to_real_or_complex_array(initial_conditions)
        parameter_values = convert_to_real_or_complex_array(parameter_values)
        
        @debug "Processing solution $soln_index"
        @debug "Constructed initial conditions: $initial_conditions"
        @debug "Constructed parameter values: $parameter_values"
        
        # Solve the ODE with the estimated parameters
        tspan = (t_vector[lowest_time_index], t_vector[1])
        u0_map = Dict(states .=> initial_conditions)
        p_map = Dict(params .=> parameter_values)
        
        prob = ODEProblem(new_model, u0_map, tspan, p_map)
        ode_solution = ModelingToolkit.solve(prob, PEP.solver, abstol = 1e-14, reltol = 1e-14)
        
        # Extract state values at the end of the solution
        state_param_map = (Dict(x => replace(string(x), "(t)" => "")
                            for x in ModelingToolkit.unknowns(PEP.model.system)))
        
        newstates = OrderedDict()
        for s in states
            newstates[s] = ode_solution[Symbol(state_param_map[s])][end]
        end
        
        push!(results_vec, [collect(values(newstates)); parameter_values])
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
            raw_sol, PEP.model, PEP.data_sample, PEP.solver, abstol = 1e-14, reltol = 1e-14
        )
        
        # Update result with processed data
        solved_res[end].states = ordered_states
        solved_res[end].parameters = ordered_params
        solved_res[end].solution = ode_solution
        solved_res[end].err = err
    end
    
    # Polish solutions if requested
    if polish_solutions
        polished_solved_res = []
        for (i, candidate) in enumerate(solved_res)
            if !nooutput
                @debug "Polishing solution $i"
            end
            
            try
                polished_result, opt_result = polish_solution_using_optimization(
                    candidate,
                    PEP,
                    solver = PEP.solver,
                    opt_method = polish_method,
                    opt_maxiters = polish_maxiters,
                    abstol = 1e-14,
                    reltol = 1e-14,
                )
                
                # Keep both the original and polished result if polishing improved the error
                if polished_result.err < candidate.err
                    push!(polished_solved_res, candidate)
                    push!(polished_solved_res, polished_result)
                else
                    push!(polished_solved_res, candidate)
                end
            catch e
                @warn "Failed to polish solution $i: $e"
                push!(polished_solved_res, candidate)
            end
        end
        
        solved_res = polished_solved_res
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
    reverse_subst_dict
)
if(false)   
# Calculate maximum derivative level
    max_deriv = max(7, 1 + maximum(collect(values(good_deriv_level))))
    
    # Calculate observable derivatives
    expanded_mq, obs_derivs = calculate_observable_derivatives(
        equations(PEP.model.system), PEP.measured_quantities, max_deriv
    )
    
    # Create a new system with the expanded measured quantities
    @named new_sys = ODESystem(equations(PEP.model.system), t; observed = expanded_mq)
    
    # Create and solve the problem with true parameters
    time_interval = extrema(PEP.data_sample["t"])
    local_prob = ODEProblem(
        structural_simplify(new_sys), 
        diagnostic_data.ic, 
        time_interval, 
        diagnostic_data.p_true
    )
    
    ideal_sol = ModelingToolkit.solve(
        local_prob, AutoVern9(Rodas4P()), abstol = 1e-14, reltol = 1e-14, 
        saveat = PEP.data_sample["t"]
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
            sol = ideal_sol
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
    exact_state_vals = OrderedDict{Any, Any}()
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
        equations(PEP.model.system)
    )
    
    inexact_system = evaluate_poly_system(
        final_target, 
        forward_subst_dict[1], 
        reverse_subst_dict[1], 
        exact_state_vals, 
        PEP.p_true, 
        equations(PEP.model.system)
    )
    
    # Log the evaluated systems
    log_equations(exact_system, "Evaluated ideal polynomial system with exact values")
    log_equations(inexact_system, "Evaluated interpolated polynomial system with exact values")
    
    @info "Exact state values at time index $lowest_time: $(exact_state_vals)"
    @info "Exact parameter values: $(PEP.p_true)"
end
end