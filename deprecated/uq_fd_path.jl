# Archived 2026-06-10 from src/core/uncertainty_quantification.jl — NOT part of the build.
# The finite-difference-Jacobian UQ path (compute_parameter_covariance /
# compute_constraint_jacobians[_simple] / estimate_parameter_uncertainty /
# validate_derivative_covariance + the legacy print_uncertainty_results).
# Replaced by the IFT-based diagnose_uncertainty path (review P0#5, Oren chose
# rewire): this code zeroed Jacobian rows at time boundaries and matched
# observables by substring — its covariance was not meaningful. Reference only.
# ============================================================================

"""
    compute_parameter_covariance(
        pep::ParameterEstimationProblem,
        solution,
        gp_results::Dict{String, <:AGPInterpolatorUQ},
        times::Vector{<:Real};
        max_deriv::Int=2
    )

Compute parameter uncertainty using the implicit function theorem.

Given the constraint equations F(θ, z) = 0 derived from the ODE system,
and the observation covariance Σ_z from the GPs, compute:

    Cov(θ) ≈ S Σ_z Sᵀ   where   S = -J_θ⁻¹ J_z

# Arguments
- `pep::ParameterEstimationProblem`: The parameter estimation problem
- `solution`: Estimated solution (containing states and parameters)
- `gp_results::Dict`: GP interpolators for each observable
- `times::Vector`: Time points used for constraint equations
- `max_deriv::Int`: Maximum derivative order in constraints (default 2)

# Returns
- `Σ_θ::Matrix{Float64}`: Covariance matrix for parameters
- `std_θ::Vector{Float64}`: Standard deviations (sqrt of diagonal)
- `param_names::Vector{Symbol}`: Names of parameters
- `cond_J::Float64`: Condition number of J_θ (indicates identifiability)

# Warnings
- High condition number suggests identifiability issues
- Linear approximation may underestimate uncertainty for nonlinear systems
"""
function compute_parameter_covariance(
	pep::ParameterEstimationProblem,
	solution,
	gp_results::Dict{String, <:AGPInterpolatorUQ},
	times::Vector{<:Real};
	max_deriv::Int = 2,
)
	# Get observation covariance
	μ_z, Σ_z, z_labels = build_observation_covariance(gp_results, times, max_deriv)

	# Build Jacobians using automatic differentiation
	J_θ, J_z, param_names = compute_constraint_jacobians(pep, solution, gp_results, times, max_deriv)

	# Check identifiability via condition number
	cond_J = cond(J_θ)
	if cond_J > 1e10
		@warn "J_θ is nearly singular (cond = $cond_J), parameters may be unidentifiable"
	end

	# Sensitivity matrix: ∂θ/∂z = -J_θ⁻¹ J_z
	# Use pseudo-inverse for robustness
	if cond_J > 1e6
		@warn "[UQ] Jacobian condition number $(round(cond_J; sigdigits=3)) > 1e6 — using pseudo-inverse. Some parameters may be unidentifiable."
		S = -pinv(J_θ) * J_z
	else
		S = -J_θ \ J_z
	end

	# Parameter covariance via delta method
	Σ_θ = S * Σ_z * S'

	# Ensure symmetry
	Σ_θ = Symmetric(Σ_θ)

	# Warn on negative variance before clipping
	neg_diag = findall(d -> d < -1e-10, diag(Σ_θ))
	if !isempty(neg_diag)
		@warn "[UQ] Negative variance at indices $neg_diag (values: $(diag(Σ_θ)[neg_diag])) — numerical breakdown, clipping to zero"
	end

	# Standard deviations
	std_θ = sqrt.(max.(diag(Σ_θ), 0.0))

	# Check if the result is valid (not NaN/Inf and reasonable condition number)
	if any(isnan, Σ_θ) || any(isinf, Σ_θ)
		return (
			param_covariance = nothing,
			param_std = nothing,
			param_names = param_names,
			condition_number = cond_J,
			success = false,
			message = "Covariance matrix contains NaN or Inf values",
		)
	end

	return (
		param_covariance = Matrix(Σ_θ),
		param_std = std_θ,
		param_names = param_names,
		condition_number = cond_J,
		success = true,
		message = "Parameter covariance computed successfully",
	)
end

"""
    compute_constraint_jacobians(
        pep::ParameterEstimationProblem,
        solution,
        gp_results::Dict,
        times::Vector,
        max_deriv::Int
    )

Compute Jacobians of the constraint equations F(θ, z) = 0.

The constraint is that the ODE-predicted observables must match the GP observations:
    F(θ, z) = h(x(t; θ), p) - z_obs = 0

where h is the observation function and x(t; θ) is the ODE solution.

# Returns
- `J_θ::Matrix{Float64}`: ∂F/∂θ - Jacobian with respect to parameters
- `J_z::Matrix{Float64}`: ∂F/∂z - Jacobian with respect to observations
- `param_names::Vector{Symbol}`: Names of all parameters (states + params)

# Theory
Since F = predicted(θ) - z, we have:
- J_θ = ∂(predicted)/∂θ  (requires sensitivity analysis)
- J_z = -I  (negative identity, since F is linear in z)

# Implementation Note
Uses finite differences for J_θ due to ODE solver AD compatibility issues.
This is computed by solving the ODE with perturbed parameters and measuring
how the predicted observables change.
"""
function compute_constraint_jacobians(
	pep::ParameterEstimationProblem,
	solution,
	gp_results::Dict{String, <:AGPInterpolatorUQ},
	times::Vector{<:Real},
	max_deriv::Int,
)
	# Extract parameter and state names from the model
	state_syms = pep.model.original_states
	param_syms = pep.model.original_parameters

	# Filter out any init_ parameters (these are handled as states)
	param_syms_only = filter(p -> !startswith(string(p), "init_"), param_syms)

	# Full parameter vector θ = [initial_conditions; parameters]
	θ_names = vcat(Symbol.(state_syms), Symbol.(param_syms_only))
	n_θ = length(θ_names)

	# Get current estimates from solution
	n_states = length(state_syms)
	n_params = length(param_syms_only)

	θ_current = Vector{Float64}(undef, n_θ)
	for (i, s) in enumerate(state_syms)
		θ_current[i] = get_solution_value(solution.states, s)
	end
	for (i, p) in enumerate(param_syms_only)
		θ_current[n_states + i] = get_solution_value(solution.parameters, p)
	end

	# Observation structure: for each GP, at each time, [f, f', f'', ...]
	obs_names = collect(keys(gp_results))
	n_obs = length(obs_names)
	n_times = length(times)
	n_derivs = max_deriv + 1
	n_z = n_obs * n_times * n_derivs

	# For each observable at each time and derivative order, we have one constraint
	n_constraints = n_z

	# Complete the system once outside the inner function
	completed_sys = ModelingToolkit.complete(pep.model.system)
	sys_unknowns = ModelingToolkit.unknowns(completed_sys)
	sys_params = ModelingToolkit.parameters(completed_sys)

	# Filter out init_ parameters from sys_params (these are handled as states)
	sys_params_only = filter(p -> !startswith(string(p), "init_"), sys_params)

	# Verify lengths match for debugging
	if length(sys_unknowns) != n_states
		@warn "Mismatch in state count: sys_unknowns=$(length(sys_unknowns)), state_syms=$(n_states)" sys_unknowns state_syms
	end
	if length(sys_params_only) != n_params
		@warn "Mismatch in param count: sys_params_only=$(length(sys_params_only)), param_syms_only=$(n_params)" sys_params_only param_syms_only
	end

	# Build mapping from state_syms order to sys_unknowns
	# This ensures values are assigned to the correct symbolic variables regardless of ordering
	state_name_to_sysunknown = Dict{String, Any}()
	for s in sys_unknowns
		state_name_to_sysunknown[string(s)] = s
	end
	param_name_to_sysparam = Dict{String, Any}()
	for p in sys_params_only
		param_name_to_sysparam[string(p)] = p
	end

	# Debug: Print system structure once
	@debug "UQ ODE System Structure" sys_unknowns sys_params_only n_states n_params

	# Build the prediction function: θ → predicted observations
	# This solves the ODE and evaluates the observation function
	_first_call = Ref(true)  # Track if this is the first call for debugging

	function predict_observables(θ_vec::Vector{T}) where {T}
		# Debug print on first call
		if _first_call[]
			@debug "predict_observables first call" θ_vec_length=length(θ_vec) n_states n_params expected_length=n_states+n_params
			_first_call[] = false
		end

		# Check that θ_vec has the right length
		expected_len = n_states + n_params
		if length(θ_vec) != expected_len
			@warn "θ_vec length mismatch" got=length(θ_vec) expected=expected_len
			return fill(T(Inf), n_constraints)
		end

		# Split θ into ICs and parameters
		ic_vals = θ_vec[1:n_states]
		param_vals = θ_vec[(n_states+1):end]

		# Build initial conditions dict using name-based mapping
		# state_syms[i] corresponds to ic_vals[i], we need to map to sys_unknowns symbols
		ic_dict = Dict{Num, T}()
		for (i, state_sym) in enumerate(state_syms)
			state_name = string(state_sym)
			if haskey(state_name_to_sysunknown, state_name)
				ic_dict[state_name_to_sysunknown[state_name]] = ic_vals[i]
			else
				# Fallback: try matching without (t) suffix
				base_name = replace(state_name, r"\(t\)$" => "")
				found = false
				for (k, v) in state_name_to_sysunknown
					if replace(k, r"\(t\)$" => "") == base_name
						ic_dict[v] = ic_vals[i]
						found = true
						break
					end
				end
				if !found
					@warn "Could not find sys_unknown for state" state_sym state_name keys(state_name_to_sysunknown)
				end
			end
		end

		# Build parameters dict using name-based mapping
		param_dict = Dict{Num, T}()
		for (i, param_sym) in enumerate(param_syms_only)
			param_name = string(param_sym)
			if haskey(param_name_to_sysparam, param_name)
				param_dict[param_name_to_sysparam[param_name]] = param_vals[i]
			else
				# Fallback: try exact name match
				found = false
				for (k, v) in param_name_to_sysparam
					if k == param_name
						param_dict[v] = param_vals[i]
						found = true
						break
					end
				end
				if !found
					@warn "Could not find sys_param for param" param_sym param_name keys(param_name_to_sysparam)
				end
			end
		end

		# Create and solve ODE problem using the new MTK API (merged dict)
		tspan = (minimum(times), maximum(times))
		try
			# Debug: print dict contents on first call
			if _first_call[]
				@debug "Creating ODEProblem with dicts" ic_dict_keys=collect(keys(ic_dict)) param_dict_keys=collect(keys(param_dict))
			end

			merged_dict = merge(ic_dict, param_dict)
			prob = ODEProblem(completed_sys, merged_dict, tspan)
			sol = OrdinaryDiffEq.solve(prob, AutoVern9(Rodas5P()), saveat = times, abstol = 1e-10, reltol = 1e-10)

			if sol.retcode != ReturnCode.Success
				@warn "ODE solve returned non-Success retcode in predict_observables" retcode=sol.retcode
				return fill(T(Inf), n_constraints)
			end

			# Extract predicted values for each observable
			# For now, assume observables are direct state observations (h(x) = x_i)
			# TODO: Handle general observation functions h(x, p)
			predictions = Vector{T}(undef, n_constraints)

			idx = 1
			for obs_name in obs_names
				# Find which state this observable corresponds to
				# This is a simplification - real implementation should use measured_quantities
				state_idx = 1  # Default to first state
				for (si, s) in enumerate(state_syms)
					if occursin(string(s), obs_name)
						state_idx = si
						break
					end
				end

				for (ti, t) in enumerate(times)
					# Get state value at this time
					state_val = sol.u[ti][state_idx]

					# For derivative order 0 (the value itself)
					predictions[idx] = state_val
					idx += 1

					# For higher derivatives, we'd need to compute them from the ODE RHS
					# For now, use numerical differentiation of the solution
					for d in 1:max_deriv
						# Use finite difference on the solution interpolation
						δt = 1e-6
						if ti > 1 && ti < n_times
							val_plus = sol(t + δt)[state_idx]
							val_minus = sol(t - δt)[state_idx]
							deriv = (val_plus - val_minus) / (2δt)
						else
							deriv = T(0)  # Boundary handling
						end
						# This is a simplification for first derivative
						# Higher derivatives need more sophisticated handling
						predictions[idx] = deriv
						idx += 1
					end
				end
			end

			return predictions
		catch e
			@warn "ODE solve failed in predict_observables" exception=e
			return fill(T(Inf), n_constraints)
		end
	end

	# Compute J_θ using finite differences
	ε = 1e-7
	pred_0 = predict_observables(θ_current)

	# Check if base prediction is valid
	if any(isinf, pred_0)
		@warn "Base prediction failed in compute_constraint_jacobians"
		J_θ = zeros(n_constraints, n_θ)
		J_z = -Matrix{Float64}(I, n_constraints, n_constraints)
		return J_θ, J_z, θ_names
	end

	J_θ = zeros(n_constraints, n_θ)

	for j in 1:n_θ
		θ_plus = copy(θ_current)
		θ_plus[j] += ε

		pred_plus = predict_observables(θ_plus)

		if !any(isinf, pred_plus)
			J_θ[:, j] = (pred_plus - pred_0) / ε
		end
	end

	# J_z = -I since F = predicted - observed
	# The constraint is F(θ, z) = predicted(θ) - z = 0
	# So ∂F/∂z = -I
	J_z = -Matrix{Float64}(I, n_constraints, n_constraints)

	return J_θ, J_z, θ_names
end

"""
    compute_constraint_jacobians_simple(
        pep::ParameterEstimationProblem,
        solution,
        gp_results::Dict,
        times::Vector
    )

Simplified version that only considers function values (no derivatives).
Useful for quick uncertainty estimates or when derivative information is unreliable.

Returns smaller Jacobian matrices focusing only on f(t) matching.
"""
function compute_constraint_jacobians_simple(
	pep::ParameterEstimationProblem,
	solution,
	gp_results::Dict{String, <:AGPInterpolatorUQ},
	times::Vector{<:Real},
)
	return compute_constraint_jacobians(pep, solution, gp_results, times, 0)
end

#==========================================================================
 Factory Function for UQ-Enabled GP
==========================================================================#


"""
    validate_derivative_covariance(interp::AGPInterpolatorUQ, t::Real; n_samples=1000)

Validate derivative covariance by Monte Carlo sampling.

Draws samples from the GP posterior and computes empirical covariance.
Useful for testing that analytic covariance formulas are correct.

# Arguments
- `interp`: The GP interpolator
- `t`: Time point to test
- `n_samples`: Number of Monte Carlo samples

# Returns
- `empirical_cov`: Empirical covariance from samples
- `analytic_cov`: Analytic covariance from joint_derivative_covariance
"""
function validate_derivative_covariance(interp::AGPInterpolatorUQ, t::Real; n_samples::Int = 1000)
	# Get analytic covariance
	μ, Σ_analytic = joint_derivative_covariance(interp, t, 2)

	# For MC sampling, we'd need to draw from the GP posterior
	# This requires more infrastructure - placeholder for now
	@warn "validate_derivative_covariance MC sampling not fully implemented"

	return Σ_analytic, Σ_analytic
end

#==========================================================================
 High-Level Integration Functions
==========================================================================#

"""
    estimate_parameter_uncertainty(
        PEP::ParameterEstimationProblem,
        solution,
        data_sample::OrderedDict;
        max_deriv_order::Int = 2,
        n_timepoints::Int = 10,
        fd_step::Float64 = 1e-6
    )

Estimate parameter uncertainty using GP derivative covariances and the Implicit Function Theorem.

This is experimental sidecar functionality rather than part of the stable core
estimation contract.

This is the main entry point for uncertainty quantification. It:
1. Fits UQ-enabled GP interpolators to each observable
2. Selects time points for constraint evaluation
3. Builds the observation covariance matrix Σ_z (block-diagonal for independent GPs)
4. Computes constraint Jacobians J_θ and J_z
5. Applies the delta method: Cov(θ) ≈ S Σ_z Sᵀ where S = -J_θ⁻¹ J_z

# Arguments
- `PEP`: The parameter estimation problem with model and true parameters
- `solution`: A solution result containing estimated parameters and states
- `data_sample`: OrderedDict with "t" and observable data
- `max_deriv_order`: Maximum derivative order for covariance (default: 2)
- `n_timepoints`: Number of time points for constraint evaluation (default: 10)
- `fd_step`: Step size for finite difference Jacobian computation (default: 1e-6)

# Returns
Named tuple with:
- `param_covariance`: Covariance matrix of parameters
- `param_std`: Standard deviations for each parameter
- `param_names`: Names of the parameters (in order)
- `obs_covariance`: The observation covariance matrix Σ_z
- `interpolators`: Dictionary of fitted UQ interpolators
- `success`: Whether the computation succeeded
- `message`: Status message
"""
function estimate_parameter_uncertainty(
	PEP::ParameterEstimationProblem,
	solution,
	data_sample::OrderedDict;
	max_deriv_order::Int = 2,
	n_timepoints::Int = 10,
	fd_step::Float64 = 1e-6,
)
	try
		# Extract time points from data
		ts = collect(data_sample["t"])
		t_min, t_max = extrema(ts)

		# Get observable keys (excluding "t")
		obs_keys = filter(k -> k != "t", collect(keys(data_sample)))
		n_obs = length(obs_keys)

		if n_obs == 0
			return (
				param_covariance = nothing,
				param_std = nothing,
				param_names = nothing,
				obs_covariance = nothing,
				interpolators = nothing,
				success = false,
				message = "No observables found in data_sample",
			)
		end

		# Step 1: Fit UQ-enabled GP interpolators to each observable
		# Skip failed observables instead of aborting the whole pipeline
		interpolators = OrderedDict{Num, AGPInterpolatorUQ}()
		failed_obs = String[]
		for obs_key in obs_keys
			ys = collect(data_sample[obs_key])
			try
				interpolators[obs_key] = agp_gpr_uq(ts, ys)
			catch e
				@warn "[UQ] GP fitting failed for observable $obs_key — skipping (not aborting)" exception = e
				push!(failed_obs, string(obs_key))
			end
		end

		if isempty(interpolators)
			return (
				param_covariance = nothing,
				param_std = nothing,
				param_names = nothing,
				obs_covariance = nothing,
				interpolators = nothing,
				success = false,
				message = "GP fitting failed for ALL observables: $(join(failed_obs, ", "))",
			)
		elseif !isempty(failed_obs)
			@warn "[UQ] GP fitting succeeded for $(length(interpolators))/$(n_obs) observables; failed: $(join(failed_obs, ", "))"
		end

		# Step 2: Select time points for constraint evaluation
		# Avoid boundaries where GP uncertainty is higher
		margin = 0.1 * (t_max - t_min)
		t_eval_min = t_min + margin
		t_eval_max = t_max - margin
		eval_times = range(t_eval_min, t_eval_max, length = n_timepoints)

		# Step 3: Build observation covariance matrix Σ_z (block-diagonal)
		# Convert interpolators to Dict{String, AGPInterpolatorUQ} as required by build_observation_covariance
		interp_dict = Dict{String, AGPInterpolatorUQ}(string(k) => v for (k, v) in interpolators)
		μ_z, Σ_z, labels = build_observation_covariance(interp_dict, collect(eval_times), max_deriv_order)

		# Step 4: Extract parameter vector from solution
		# Combine states (initial conditions) and parameters
		param_names = Symbol[]
		param_values = Float64[]

		# Add states (initial conditions)
		for (state_sym, state_val) in solution.states
			# Convert symbolic expression to Symbol (e.g., x1(t) -> :x1)
			state_name = Symbol(replace(string(state_sym), r"\(.*\)" => ""))
			push!(param_names, state_name)
			push!(param_values, real(state_val))
		end

		# Add parameters (excluding init_ prefixed ones)
		for (param_sym, param_val) in solution.parameters
			if !startswith(string(param_sym), "init_")
				# Convert to Symbol if needed
				param_name = param_sym isa Symbol ? param_sym : Symbol(replace(string(param_sym), r"\(.*\)" => ""))
				push!(param_names, param_name)
				push!(param_values, real(param_val))
			end
		end

		θ_est = param_values

		# Step 5: Compute parameter covariance using IFT
		# Note: compute_parameter_covariance expects Dict{String, AGPInterpolatorUQ}
		# and the solution object (not just the parameter values)
		result = compute_parameter_covariance(
			PEP,
			solution,
			interp_dict,
			collect(eval_times);
			max_deriv = max_deriv_order,
		)

		if result.success
			# Warn on negative variance before clipping
			neg_diag = findall(d -> d < -1e-10, diag(result.param_covariance))
			if !isempty(neg_diag)
				@warn "[UQ] Negative variance at indices $neg_diag (values: $(diag(result.param_covariance)[neg_diag])) — numerical breakdown, clipping to zero"
			end
			# Extract standard deviations from diagonal
			param_std = sqrt.(max.(diag(result.param_covariance), 0.0))

			return (
				param_covariance = result.param_covariance,
				param_std = param_std,
				param_names = param_names,
				obs_covariance = Σ_z,
				interpolators = interpolators,
				success = true,
				message = "Uncertainty estimation completed successfully",
			)
		else
			return (
				param_covariance = nothing,
				param_std = nothing,
				param_names = param_names,
				obs_covariance = Σ_z,
				interpolators = interpolators,
				success = false,
				message = result.message,
			)
		end

	catch e
		@warn "Uncertainty estimation failed: $e"
		return (
			param_covariance = nothing,
			param_std = nothing,
			param_names = nothing,
			obs_covariance = nothing,
			interpolators = nothing,
			success = false,
			message = "Uncertainty estimation failed: $e",
		)
	end
end

"""
    print_uncertainty_results(uq_result; io=stdout)

Pretty-print the uncertainty quantification results.

# Arguments
- `uq_result`: Result from estimate_parameter_uncertainty
- `io`: IO stream to print to (default: stdout)
"""
function print_uncertainty_results(uq_result; io = stdout)
	if !uq_result.success
		println(io, "\n=== Uncertainty Quantification ===")
		println(io, "Status: FAILED")
		println(io, "Message: $(uq_result.message)")
		return
	end

	println(io, "\n=== Uncertainty Quantification Results ===")
	println(io, "-"^50)
	println(io, "Parameter       | Std. Dev.   | 95% CI Half-Width")
	println(io, "-"^50)

	for (i, name) in enumerate(uq_result.param_names)
		std_val = uq_result.param_std[i]
		ci_half = UQ_CI_Z * std_val  # 95% confidence interval (shared constant, core_types.jl)
		@printf(io, "%-14s | %10.6f | %10.6f\n", string(name), std_val, ci_half)
	end

	println(io, "-"^50)
	println(io, "\nNote: Uncertainties assume Gaussian errors and linearized constraints.")
	println(io, "      Results are conservative (Phase 1: independent GP assumption).")
end
