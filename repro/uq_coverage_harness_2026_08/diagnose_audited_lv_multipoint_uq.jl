# Detailed conditioning audit for the exact audited Lotka--Volterra
# multipoint estimator/UQ canary. This deliberately keeps the production
# reliability gate unchanged: it inspects the covariance that production
# already returns with status=:degenerate.

include(joinpath(@__DIR__, "run_estimator_aware_peb_canaries.jl"))

using DelimitedFiles
using ForwardDiff
using LinearAlgebra
using Printf
using Statistics

const LV_CASE_ID = "lotka_volterra_5_1em6"

condition_2(A) = begin
	s = svdvals(A)
	isempty(s) ? NaN : first(s) / max(last(s), 1e-300)
end

function row_equilibrate(A)
	scales = [max(norm(@view A[i, :]), 1e-300) for i in axes(A, 1)]
	return Diagonal(1.0 ./ scales) * A
end

function column_equilibrate(A)
	scales = [max(norm(@view A[:, j]), 1e-300) for j in axes(A, 2)]
	return A * Diagonal(1.0 ./ scales)
end

function relative_difference(A, B)
	return norm(A - B) / max(norm(B), 1e-300)
end

function print_direction(title, variables, roots, direction; limit = 10)
	println(title)
	order = sortperm(abs.(direction); rev = true)
	for j in first(order, min(limit, length(order)))
		@printf("  %-28s loading=% .6e  root=% .6e\n",
			string(variables[j]), direction[j], roots[j])
	end
end

const LV_LENGTHSCALE_LADDER = Float64[1.0, 0.9, 0.75, 0.6]

"""Refactor a retained AGPUQ fit at a fixed lengthscale multiplier.

The function-value ML hyperparameters are not reoptimized.  This is the
causal derivative-undersmoothing screen specified in the research program,
not a second GP fit with a different objective.
"""
function lv_refactor_lengthscale(
	interp::ODEParameterEstimation.AGPInterpolatorUQ,
	factor::Float64,
)
	isfinite(factor) && factor > 0 || throw(ArgumentError(
		"lengthscale factor must be finite and positive",
	))
	xs = interp.xs_train
	lengthscale = interp.fitted_lengthscale * factor
	n = length(xs)
	distance_squared = [abs2(xs[i] - xs[j]) for i in 1:n, j in 1:n]
	kernel = ODEParameterEstimation._se_covariance_matrix(
		distance_squared, lengthscale, interp.signal_var,
	)
	noisy_kernel = ODEParameterEstimation._add_diagonal_variance(
		kernel, interp.noise_var,
	)
	chol, jitter = ODEParameterEstimation._cholesky_adaptive(
		noisy_kernel; relative_jitter = true,
	)
	alpha = chol \ interp.ys_train
	jitter_ratio = jitter == 0 ? 0.0 :
		interp.noise_var > 0 ? jitter / interp.noise_var : Inf
	factorization_residual = ODEParameterEstimation._cholesky_relative_residual(
		chol, noisy_kernel, jitter,
	)

	inv_2l2 = 1.0 / (2.0 * lengthscale^2)
	function mean_prediction(x)
		kstar = [interp.signal_var * exp(-(x - xi)^2 * inv_2l2) for xi in xs]
		return interp.y_std * dot(kstar, alpha) + interp.y_mean
	end
	function std_prediction(x::Real)
		kstar = [interp.signal_var * exp(-(x - xi)^2 * inv_2l2) for xi in xs]
		v = chol \ kstar
		variance = interp.signal_var - dot(kstar, v)
		return interp.y_std * sqrt(max(variance, 0.0))
	end

	return ODEParameterEstimation.AGPInterpolatorUQ(
		mean_prediction, std_prediction,
		copy(xs), copy(interp.ys_train), alpha, chol,
		lengthscale, interp.fitted_lengthscale, factor,
		interp.signal_var, interp.noise_var, interp.y_mean, interp.y_std,
		jitter, jitter_ratio, factorization_residual,
		interp.hyperparams_optimized,
	)
end

function lv_oracle_jet(pep, time_value::Float64, max_order::Int)
	state_taylor = ODEParameterEstimation.compute_oracle_taylor_coefficients(
		pep, time_value, max_order + 2,
	)
	observable_taylor = ODEParameterEstimation.compute_observable_taylor_coefficients(
		pep, state_taylor, time_value, max_order + 2,
	)
	observable_key = ModelingToolkit.diff2term(first(pep.measured_quantities).rhs)
	return Float64[
		observable_taylor[observable_key][order + 1] * factorial(order)
		for order in 0:max_order
	]
end

function lv_production_jet(
	interp::ODEParameterEstimation.AGPInterpolatorUQ,
	time_value::Float64,
	max_order::Int,
)
	return Float64[
		ODEParameterEstimation._estimation_derivative(
			interp, order, time_value,
		)
		for order in 0:max_order
	]
end

"""Evaluate the same fixed kernel smoother on alternative raw observations.

This normalized-alpha form is algebraically equivalent to `W * raw_values`
but avoids the severe cancellation that direct raw-coordinate multiplication
can incur for high-order derivative weights.
"""
function lv_fixed_smoother_jet(
	interp::ODEParameterEstimation.AGPInterpolatorUQ,
	raw_values::Vector{Float64},
	time_value::Float64,
	max_order::Int,
)
	length(raw_values) == length(interp.xs_train) || throw(ArgumentError(
		"alternative raw observations do not match the retained GP grid",
	))
	raw_mean = mean(raw_values)
	raw_std = max(std(raw_values), 1e-8)
	normalized = (raw_values .- raw_mean) ./ raw_std
	alpha = interp.chol \ normalized
	kstar = ODEParameterEstimation._build_K_star_n(interp, time_value, max_order)
	jet = raw_std .* (kstar * alpha)
	jet[1] += raw_mean
	return jet
end

function lv_standardized(numerator::Real, denominator::Real)
	if denominator > 0 && isfinite(denominator)
		return Float64(numerator / denominator)
	end
	return iszero(numerator) ? 0.0 : copysign(Inf, numerator)
end

"""Newton solve of one fixed-data local polynomial branch.

The start is supplied explicitly.  Stage 1 uses the oracle root as the start,
so this is a mechanism diagnostic and never an admissible production ranking
quantity.
"""
function lv_local_newton(
	fn,
	start::AbstractVector{<:Real},
	data_values::AbstractVector{<:Real};
	max_iterations::Int = 60,
	tolerance::Float64 = 1e-11,
)
	x = Vector{Float64}(start)
	d = Vector{Float64}(data_values)
	last_residual = Inf
	for iteration in 0:max_iterations
		residual = Float64.(fn(vcat(x, d)))
		last_residual = norm(residual, Inf)
		last_residual <= tolerance && return x, true, iteration, last_residual
		iteration == max_iterations && break
		jacobian = Float64.(ForwardDiff.jacobian(xx -> fn(vcat(xx, d)), x))
		step = try
			jacobian \ residual
		catch
			return x, false, iteration, last_residual
		end
		all(isfinite, step) || return x, false, iteration, last_residual

		# Backtracking is important for the boundary pairs, whose GP jet error can
		# move the truth branch outside plain Newton's local convergence region.
		accepted = false
		step_scale = 1.0
		for _ in 1:18
			trial = x .- step_scale .* step
			trial_residual = norm(Float64.(fn(vcat(trial, d))), Inf)
			if isfinite(trial_residual) && trial_residual < last_residual
				x = trial
				accepted = true
				break
			end
			step_scale *= 0.5
		end
		accepted || return x, false, iteration, last_residual
	end
	return x, false, max_iterations, last_residual
end

function lv_ift_diagnostic(fn, root::Vector{Float64}, data_values::Vector{Float64})
	combined = vcat(root, data_values)
	jacobian = Float64.(ForwardDiff.jacobian(fn, combined))
	n_solve = length(root)
	Jx = Matrix(@view jacobian[:, 1:n_solve])
	Jd = Matrix(@view jacobian[:, (n_solve + 1):end])
	S = try
		-(Jx \ Jd)
	catch
		fill(NaN, n_solve, length(data_values))
	end
	S_big = try
		setprecision(256) do
			Float64.(-(BigFloat.(Jx) \ BigFloat.(Jd)))
		end
	catch
		fill(NaN, size(S))
	end
	residual = norm(Float64.(fn(combined)), Inf)
	Jx_row = row_equilibrate(Jx)
	Jx_column = column_equilibrate(Jx)
	Jx_row_column = column_equilibrate(Jx_row)
	return (;
		Jx,
		Jd,
		S,
		S_big,
		residual,
		condition_raw = condition_2(Jx),
		condition_row = condition_2(Jx_row),
		condition_column = condition_2(Jx_column),
		condition_row_column = condition_2(Jx_row_column),
		ift_precision_disagreement = relative_difference(S, S_big),
		ift_equation_residual = norm(Jx * S + Jd) / max(norm(Jd), 1e-300),
	)
end

function lv_oracle_coordinates(pep, template, time_values::Vector{Float64})
	max_order = ODEParameterEstimation._multipoint_template_max_order(template)
	state_taylors = [
		ODEParameterEstimation.compute_oracle_taylor_coefficients(
			pep, time_value, max_order + 2,
		)
		for time_value in time_values
	]
	observable_taylors = [
		ODEParameterEstimation.compute_observable_taylor_coefficients(
			pep, state_taylors[point], time_values[point], max_order + 2,
		)
		for point in eachindex(time_values)
	]
	x_true = Float64[
		ODEParameterEstimation._lookup_multipoint_true_value(
			string(variable), pep, time_values, state_taylors, observable_taylors,
		)
		for variable in template.solve_vars
	]
	d_true = Float64[
		ODEParameterEstimation._lookup_multipoint_true_value(
			string(variable), pep, time_values, state_taylors, observable_taylors,
		)
		for variable in template.data_vars
	]
	return x_true, d_true
end

function lv_physical_backsolve_diagnostic(
	pep,
	template,
	root::Vector{Float64},
	coordinate_covariance::Matrix{Float64},
	t_shoot::Float64,
)
	params = pep.model.original_parameters
	states = [
		state for state in pep.model.original_states
		if !startswith(ODEParameterEstimation._uq_clean_name(state), "_trfn_")
	]
	local_symbols = vcat(params, states)
	local_indices = Int[]
	for symbol in local_symbols
		index = ODEParameterEstimation._uq_solve_coordinate_index(
			template.solve_vars, ODEParameterEstimation._uq_clean_name(symbol),
		)
		isnothing(index) && throw(ArgumentError(
			"LV physical backsolve cannot find local coordinate $symbol",
		))
		push!(local_indices, index)
	end
	local_values = root[local_indices]
	local_covariance = coordinate_covariance[local_indices, local_indices]
	n_params = length(params)
	n_states = length(states)
	t0 = Float64(first(pep.data_sample["t"]))
	transform = Matrix{Float64}(I, n_params + n_states, n_params + n_states)
	physical_values = copy(local_values)
	if abs(t_shoot - t0) > 1e-10
		completed_sys = ModelingToolkit.complete(pep.model.system)
		completed_states = ModelingToolkit.unknowns(completed_sys)
		completed_params = ModelingToolkit.parameters(completed_sys)
		local_by_name = Dict(
			ODEParameterEstimation._uq_clean_name(symbol) => value
			for (symbol, value) in zip(local_symbols, local_values)
		)
		x_shoot = Float64[
			local_by_name[ODEParameterEstimation._uq_clean_name(state)]
			for state in completed_states
		]
		param_values = Float64[
			local_by_name[ODEParameterEstimation._uq_clean_name(param)]
			for param in completed_params
		]
		problem = ODEParameterEstimation.ODEProblem(
			completed_sys,
			merge(
				Dict(completed_states .=> x_shoot),
				Dict(completed_params .=> param_values),
			),
			(t_shoot, t0),
		)
		solution = ODEParameterEstimation.OrdinaryDiffEq.solve(
			problem,
			ODEParameterEstimation.AutoVern9(ODEParameterEstimation.Rodas5P());
			abstol = 1e-12,
			reltol = 1e-12,
		)
		ODEParameterEstimation.SciMLBase.successful_retcode(solution) || error(
			"LV physical backsolve failed with $(solution.retcode)",
		)
		parameter_dict = OrderedDict(params .=> local_values[1:n_params])
		state_dict = OrderedDict(states .=> fill(NaN, n_states))
		result = ParameterEstimationResult(
			parameter_dict, state_dict, t_shoot, nothing, :Success,
			length(pep.data_sample["t"]), nothing, nothing, Set{Num}(), solution,
		)
		state_transform, x0 = ODEParameterEstimation._uq_variational_backsolve_jacobian(
			pep, result, t0, t_shoot,
		)
		transform[(n_params + 1):end, :] .= state_transform
		physical_values = vcat(local_values[1:n_params], x0)
	end
	physical_covariance = ODEParameterEstimation._psd_symmetric_matrix(
		transform * local_covariance * transform',
	)
	physical_sigma = sqrt.(max.(diag(physical_covariance), 0.0))
	truth = vcat(
		Float64[get(pep.p_true, param, NaN) for param in params],
		Float64[get(pep.ic, state, NaN) for state in states],
	)
	labels = vcat(
		[ODEParameterEstimation._uq_clean_name(param) for param in params],
		[ODEParameterEstimation._uq_clean_name(state) for state in states],
	)
	return (;
		labels,
		values = physical_values,
		truth,
		physical_sigma,
		physical_covariance,
		transform,
		amplification = maximum(svdvals(transform)),
	)
end

function main_lv_gp_bias_decomposition()
	case = PEB_AUDITED_CASES[LV_CASE_ID]
	peb_root = _default_peb_root()
	paths = _peb_paths(peb_root, LV_CASE_ID, case)
	pep, _, _ = _peb_problem(case, paths.data, 0)
	scaled_pep, scale_info = ODEParameterEstimation.rescale_pep(deepcopy(pep))
	isnothing(scale_info) && error("expected nontrivial LV power-of-two scaling")
	times = Float64.(scaled_pep.data_sample["t"])
	interpolants = _cov_quiet() do
		ODEParameterEstimation.create_interpolants(
			scaled_pep.measured_quantities, scaled_pep.data_sample,
			times, ODEParameterEstimation.agp_gpr_uq)
	end
	agp = only([value for value in values(interpolants)
		if value isa ODEParameterEstimation.AGPInterpolatorUQ])
	observable_scale = only(values(scale_info.observable_scales))
	original_path = joinpath(peb_root, PEB_SNAPSHOT, "filetree", "data_original",
		"lotka_volterra_5.csv")
	original = Matrix{Float64}(readdlm(original_path, Char(44), Float64))
	true_internal = original[:, 2] ./ observable_scale
	learned_sigma = sqrt(ODEParameterEstimation.learned_observation_noise_variance(agp))
	factorization = gp_factorization_diagnostics(agp)

	println("FIXED-HYPERPARAMETER GP-JET ERROR DECOMPOSITION")
	@printf("  learned raw-observation sigma (internal): %.8e\n", learned_sigma)
	@printf("  fitted/used lengthscale: %.8e / %.8e (factor %.3f)\n",
		factorization.fitted_lengthscale, factorization.lengthscale,
		factorization.lengthscale_factor)
	@printf("  Cholesky jitter/noise ratio: %.8e\n", factorization.jitter_to_noise)
	@printf("  factorization residual: %.8e\n", factorization.factorization_residual)
	println("  factorization status: ", factorization.status)
	for data_index in (25, 635)
		t_eval = times[data_index]
		state_taylor = ODEParameterEstimation.compute_oracle_taylor_coefficients(
			scaled_pep, t_eval, 5)
		obs_taylor = ODEParameterEstimation.compute_observable_taylor_coefficients(
			scaled_pep, state_taylor, t_eval, 5)
		obs_key = ModelingToolkit.diff2term(first(scaled_pep.measured_quantities).rhs)
		oracle = Float64[
			obs_taylor[obs_key][order + 1] * factorial(order)
			for order in 0:3
		]
		_, W = ODEParameterEstimation.gp_derivative_influence_matrix(agp, t_eval, 3)
		gp_mean = lv_production_jet(agp, t_eval, 3)
		fixed_noiseless = lv_fixed_smoother_jet(agp, true_internal, t_eval, 3)
		noise_effect = gp_mean - fixed_noiseless
		bias = fixed_noiseless - oracle
		total_error = gp_mean - oracle
		sampling_sigma = learned_sigma .* sqrt.(vec(sum(abs2, W; dims = 2)))
		println("\n  row=$data_index time=$t_eval")
		for order in 0:3
			i = order + 1
			@printf("    d%-2d total=% .6e  smooth_bias=% .6e  noise_effect=% .6e  sigma=% .6e  total_z=% .3f\n",
				order, total_error[i], bias[i], noise_effect[i], sampling_sigma[i],
				total_error[i] / max(sampling_sigma[i], 1e-300))
		end
		@printf("    decomposition residual norm: %.8e\n",
			norm(total_error - bias - noise_effect))
	end
	println("\nGP_BIAS_DIAGNOSTIC_COMPLETE")
	return nothing
end

function main_lv_multipoint_diagnostic()
	case = PEB_AUDITED_CASES[LV_CASE_ID]
	peb_root = _default_peb_root()
	paths = _peb_paths(peb_root, LV_CASE_ID, case)
	pep, rows, original_rows = _peb_problem(case, paths.data, 0)
	extra = _peb_arm_options(case, "mp_solver_polish", 20, 15, "uq_only")
	opts = EstimationOptions(;
		datasize = length(rows),
		time_interval = case.time_interval,
		noise_level = case.noise,
		nooutput = true,
		diagnostics = false,
		shooting_warp = true,
		shooting_warp_beta = 3.0,
		use_parameter_homotopy = true,
		opt_lb = fill(1e-5, length(case.p_true) + length(case.ic)),
		opt_ub = fill(10.0, length(case.p_true) + length(case.ic)),
		extra...,
	)

	println("Running exact audited LV cell ($original_rows observations)...")
	(value, context) = ODEParameterEstimation._with_run_context() do
		_cov_quiet() do
			ODEParameterEstimation._analyze_parameter_estimation_problem_impl(
				deepcopy(pep), opts)
		end
	end
	raw, analysis, uq = value
	uq isa UncertaintyReport || error("expected an UncertaintyReport, got $(typeof(uq))")
	selected = only(analysis.returned_results)
	identity = selected.provenance.estimator_identity
	artifact = get(context.estimator_artifacts, identity.candidate_id, nothing)
	artifact isa ODEParameterEstimation.MultipointUQArtifact ||
		error("selected candidate did not retain a multipoint UQ artifact")

	evaluation = artifact.evaluation
	template = evaluation.template
	combined_vars = vcat(template.solve_vars, template.data_vars)
	combined_values = vcat(Float64.(artifact.root), evaluation.data_values)
	fn = ODEParameterEstimation._compile_system_function(
		template.stripped_equations, combined_vars)
	J = Float64.(ForwardDiff.jacobian(fn, combined_values))
	nx = length(template.solve_vars)
	Jx = Matrix(@view J[:, 1:nx])
	Jd = Matrix(@view J[:, (nx + 1):end])
	root = Float64.(artifact.root)

	S_lu = -(Jx \ Jd)
	S_svd = -(svd(Jx) \ Jd)
	S_big = setprecision(256) do
		Float64.(-(BigFloat.(Jx) \ BigFloat.(Jd)))
	end

	Jx_row = row_equilibrate(Jx)
	Jx_col = column_equilibrate(Jx)
	Jx_row_col = column_equilibrate(Jx_row)
	relative_scales = max.(abs.(root), 1e-12)
	Jx_relative = Jx * Diagonal(relative_scales)
	Jx_relative_row = row_equilibrate(Jx_relative)

	println("\nSELECTED ESTIMATOR")
	println("  candidate_id: ", identity.candidate_id)
	println("  kind: ", identity.estimator_kind)
	println("  rows: ", identity.time_indices)
	println("  times: ", identity.time_values)
	println("  root residual relative: ", uq.linearization_diagnostics.root_residual_rel)

	println("\nJACOBIAN CONDITIONING")
	@printf("  raw cond2(Jx):                    %.8e\n", condition_2(Jx))
	@printf("  row-equilibrated:                 %.8e\n", condition_2(Jx_row))
	@printf("  column-equilibrated:              %.8e\n", condition_2(Jx_col))
	@printf("  row + column equilibrated:        %.8e\n", condition_2(Jx_row_col))
	@printf("  relative-coordinate:              %.8e\n", condition_2(Jx_relative))
	@printf("  relative-coordinate + row equil.: %.8e\n", condition_2(Jx_relative_row))
	@printf("  cond(Jx)*eps(Float64):            %.8e\n", condition_2(Jx) * eps(Float64))

	println("\nIFT SOLVE STABILITY")
	@printf("  LU vs 256-bit solve:  %.8e relative\n", relative_difference(S_lu, S_big))
	@printf("  SVD vs 256-bit solve: %.8e relative\n", relative_difference(S_svd, S_big))
	@printf("  LU equation residual: %.8e relative\n",
		norm(Jx * S_lu + Jd) / max(norm(Jd), 1e-300))

	raw_svd = svd(Jx)
	rel_svd = svd(Jx_relative_row)
	println("\nRAW SINGULAR VALUES")
	println("  ", raw_svd.S)
	print_direction("\nWeakest raw-coordinate right-singular direction:",
		template.solve_vars, root, raw_svd.V[:, end])
	print_direction("\nWeakest row-scaled relative-coordinate direction:",
		template.solve_vars, root, rel_svd.V[:, end])

	# The retained artifact lives in the automatically rescaled problem. Rebuild
	# that deterministic transform so oracle jets and roots use the same
	# coordinates; the public UQ report itself has already been unscaled.
	scaled_pep, scale_info = ODEParameterEstimation.rescale_pep(deepcopy(pep))
	isnothing(scale_info) && error("expected nontrivial LV power-of-two scaling")
	max_order = ODEParameterEstimation._multipoint_template_max_order(template)
	state_taylors = [
		ODEParameterEstimation.compute_oracle_taylor_coefficients(
			scaled_pep, time_value, max_order + 2)
		for time_value in evaluation.t_values
	]
	observable_taylors = [
		ODEParameterEstimation.compute_observable_taylor_coefficients(
			scaled_pep, state_taylors[point], evaluation.t_values[point], max_order + 2)
		for point in eachindex(evaluation.t_values)
	]
	d_true = Float64[
		ODEParameterEstimation._lookup_multipoint_true_value(
			string(variable), scaled_pep, evaluation.t_values,
			state_taylors, observable_taylors)
		for variable in template.data_vars
	]
	x_true = Float64[
		ODEParameterEstimation._lookup_multipoint_true_value(
			string(variable), scaled_pep, evaluation.t_values,
			state_taylors, observable_taylors)
		for variable in template.solve_vars
	]
	delta_d = evaluation.data_values - d_true
	delta_x = root - x_true
	delta_x_linear = S_lu * delta_d
	data_sigma = sqrt.(max.(diag(uq.data_covariance)[1:length(d_true)], 0.0))

	println("\nRETAINED ROOT VS ORACLE COORDINATES")
	for i in eachindex(template.solve_vars)
		@printf("  %-28s root=% .8e oracle=% .8e error=% .4e linear=% .4e\n",
			string(template.solve_vars[i]), root[i], x_true[i], delta_x[i],
			delta_x_linear[i])
	end
	println("\nGP-JET ERROR VS PROPAGATED SAMPLING SIGMA")
	jet_order = sortperm(abs.(delta_d) ./ max.(data_sigma, 1e-300); rev = true)
	for i in jet_order
		@printf("  %-28s gp=% .8e oracle=% .8e error=% .4e sigma=% .4e bias_z=% .3g\n",
			string(template.data_vars[i]), evaluation.data_values[i], d_true[i],
			delta_d[i], data_sigma[i], delta_d[i] / max(data_sigma[i], 1e-300))
	end
	@printf("  linearized root-error agreement: %.8e relative\n",
		norm(delta_x - delta_x_linear) / max(norm(delta_x), 1e-300))

	local_uq = something(uq.local_coordinate_report)
	backsolve = something(uq.backsolve_transform)
	println("\nLOCAL VS PHYSICAL UQ")
	@printf("  backsolve spectral amplification: %.8e\n", backsolve.amplification)
	@printf("  backsolve cond2:                  %.8e\n", condition_2(backsolve.transform_matrix))
	for label in uq.param_labels
		li = findfirst(==(label), local_uq.param_labels)
		pi = findfirst(==(label), uq.param_labels)
		@printf("  %-8s local_sigma=% .6e  physical_sigma=% .6e  ratio=% .4g\n",
			label, local_uq.param_std[li], uq.param_std[pi],
			uq.param_std[pi] / max(local_uq.param_std[li], 1e-300))
	end

	println("\nFORCED-THROUGH INTERVALS (production covariance, status remains degenerate)")
	for (label, estimate, truth, sigma) in zip(
			uq.param_labels, uq.estimate_values, uq.param_true_values, uq.param_std)
		z = (estimate - truth) / sigma
		@printf("  %-8s estimate=% .9f truth=% .9f sigma=% .6e z=% .4f covered95=%s\n",
			label, estimate, truth, sigma, z, abs(z) <= 1.959963984540054)
	end

	interpolants = [value for value in values(artifact.interpolants)
		if value isa ODEParameterEstimation.AGPInterpolatorUQ]
	isempty(interpolants) && error("no retained AGPInterpolatorUQ")
	interp = first(interpolants)
	learned_sigma = sqrt(ODEParameterEstimation.learned_observation_noise_variance(interp))
	residual_covariance = ODEParameterEstimation._uq_observation_covariance_from_source(
		interp, :smoother_residual_edf)
	residual_sigma = sqrt(residual_covariance[1, 1])
	original_path = joinpath(peb_root, PEB_SNAPSHOT, "filetree", "data_original",
		"lotka_volterra_5.csv")
	original = Matrix{Float64}(readdlm(original_path, Char(44), Float64))
	noisy = Matrix{Float64}(readdlm(paths.data, Char(44), Float64))
	noise_draw = noisy[:, 2] - original[:, 2]
	design_sigma = mean(original[:, 2]) * case.noise
	sample_sigma = std(noise_draw)
	observable_scale = only(values(scale_info.observable_scales))
	scaled_design_sigma = design_sigma / observable_scale
	scaled_sample_sigma = sample_sigma / observable_scale

	println("\nOBSERVATION NOISE")
	@printf("  observable scale (original=scale*internal): %.8e\n", observable_scale)
	@printf("  benchmark design sigma, original units:     %.8e\n", design_sigma)
	@printf("  realized sample sigma, original units:      %.8e\n", sample_sigma)
	@printf("  benchmark design sigma, internal units:     %.8e\n", scaled_design_sigma)
	@printf("  realized sample sigma, internal units:      %.8e\n", scaled_sample_sigma)
	@printf("  GP learned sigma, internal units:            %.8e\n", learned_sigma)
	@printf("  smoother residual/EDF sigma, internal units: %.8e\n", residual_sigma)
	@printf("  learned/design ratio, matched units:         %.6f\n", learned_sigma / scaled_design_sigma)
	@printf("  residual/design ratio, matched units:        %.6f\n", residual_sigma / scaled_design_sigma)
	@printf("  GP lengthscale:              %.8e\n", interp.lengthscale)
	@printf("  GP normalized noise var:     %.8e\n", interp.noise_var)
	println("  GP hyperparameters optimized: ", interp.hyperparams_optimized)

	println("\nKNOWN-NOISE RESCALING (same fixed influence map)")
	noise_ratio = scaled_design_sigma / learned_sigma
	for (label, estimate, truth, sigma) in zip(
			uq.param_labels, uq.estimate_values, uq.param_true_values, uq.param_std)
		known_sigma = sigma * noise_ratio
		z = (estimate - truth) / known_sigma
		@printf("  %-8s sigma=% .6e z=% .4f covered95=%s\n",
			label, known_sigma, z, abs(z) <= 1.959963984540054)
	end

	println("\nRESIDUAL/EDF INTERVALS")
	residual_ratio = residual_sigma / learned_sigma
	for (label, estimate, truth, learned_param_sigma) in zip(
			uq.param_labels, uq.estimate_values, uq.param_true_values, uq.param_std)
		sigma = learned_param_sigma * residual_ratio
		z = (estimate - truth) / sigma
		@printf("  %-8s sigma=% .6e z=% .4f covered95=%s\n",
			label, sigma, z, abs(z) <= 1.959963984540054)
	end

	println("\nDIAGNOSTIC_COMPLETE")
	return (; raw, analysis, uq, artifact, Jx, Jd, S_lu, S_big,
		d_true, x_true, delta_d, delta_x, delta_x_linear)
end

function lv_anchor_diagnostics(
	scaled_pep,
	template,
	base_interp::ODEParameterEstimation.AGPInterpolatorUQ,
	true_internal::Vector{Float64},
	anchor_indices::Vector{Int},
	;
	lengthscale_ladder::Vector{Float64} = LV_LENGTHSCALE_LADDER,
)
	!isempty(lengthscale_ladder) && 1.0 in lengthscale_ladder ||
		throw(ArgumentError("lengthscale ladder must contain 1.0"))
	times = Float64.(scaled_pep.data_sample["t"])
	max_order = maximum((meta.order for meta in template.data_var_meta
		if meta.kind == :observable_jet); init = 0)
	variants = Dict(
		factor => factor == 1.0 ? base_interp :
			lv_refactor_lengthscale(base_interp, factor)
		for factor in lengthscale_ladder
	)
	learned_sigma = sqrt(ODEParameterEstimation.learned_observation_noise_variance(
		base_interp,
	))
	noisy_internal = ODEParameterEstimation._raw_training_values(base_interp)
	length(noisy_internal) == length(true_internal) || error(
		"true/noisy training-grid length mismatch",
	)

	records = Dict{String, Any}[]
	internal = Dict{Int, NamedTuple}()
	for index in anchor_indices
		time_value = times[index]
		oracle = lv_oracle_jet(scaled_pep, time_value, max_order)
		influence_mean, base_W = ODEParameterEstimation.gp_derivative_influence_matrix(
			base_interp, time_value, max_order,
		)
		base_mean = lv_production_jet(base_interp, time_value, max_order)
		fixed_noiseless = lv_fixed_smoother_jet(
			base_interp, true_internal, time_value, max_order,
		)
		noise_effect = base_mean - fixed_noiseless
		sampling_sigma = learned_sigma .* sqrt.(vec(sum(abs2, base_W; dims = 2)))
		smoother_bias = fixed_noiseless - oracle
		total_error = base_mean - oracle

		variant_records = Dict{String, Any}[]
		max_stability_by_order = zeros(max_order + 1)
		variant_means = Dict{Float64, Vector{Float64}}()
		variant_weights = Dict{Float64, Matrix{Float64}}()
		for factor in lengthscale_ladder
			variant = variants[factor]
			_, variant_W = ODEParameterEstimation.gp_derivative_influence_matrix(
					variant, time_value, max_order,
				)
			variant_mean = lv_production_jet(variant, time_value, max_order)
			variant_means[factor] = variant_mean
			variant_weights[factor] = variant_W
			difference = variant_mean - base_mean
			difference_W = variant_W - base_W
			difference_sigma = learned_sigma .* sqrt.(vec(sum(abs2, difference_W; dims = 2)))
			stability_z = Float64[
				lv_standardized(difference[i], difference_sigma[i])
				for i in eachindex(difference)
			]
			max_stability_by_order = max.(max_stability_by_order, abs.(stability_z))
			factorization = gp_factorization_diagnostics(variant)
			push!(variant_records, Dict{String, Any}(
				"factor" => factor,
				"lengthscale" => factorization.lengthscale,
				"jitter_to_noise" => factorization.jitter_to_noise,
				"factorization_residual" => factorization.factorization_residual,
				"jet_difference_from_base" => difference,
				"jet_difference_sigma" => difference_sigma,
				"stability_z" => stability_z,
			))
		end

		boundary_distance = min(time_value - first(times), last(times) - time_value)
		record = Dict{String, Any}(
			"index" => index,
			"time" => time_value,
			"boundary_distance" => boundary_distance,
			"boundary_distance_lengthscales" =>
				boundary_distance / base_interp.lengthscale,
			"max_observed_derivative_order" => max_order,
			"oracle_jet" => oracle,
			"gp_jet" => base_mean,
			"raw_influence_reconstruction_error" => influence_mean - base_mean,
			"fixed_noiseless_jet" => fixed_noiseless,
			"smoother_bias" => smoother_bias,
			"noise_effect" => noise_effect,
			"sampling_sigma" => sampling_sigma,
			"smoother_bias_z" => Float64[
				lv_standardized(smoother_bias[i], sampling_sigma[i])
				for i in eachindex(smoother_bias)
			],
			"total_error_z" => Float64[
				lv_standardized(total_error[i], sampling_sigma[i])
				for i in eachindex(total_error)
			],
			"max_abs_stability_z_by_order" => max_stability_by_order,
			"max_abs_stability_z" => maximum(max_stability_by_order),
			"lengthscale_ladder" => variant_records,
		)
		push!(records, record)
		internal[index] = (;
			oracle,
			base_mean,
			base_W,
			fixed_noiseless,
			sampling_sigma,
			variant_means,
			variant_weights,
			max_stability_by_order,
		)
	end
	return records, internal, variants
end

function lv_pair_diagnostic(
	combo::Vector{Int},
	spread_rank::Int,
	boundary_rank::Int,
	scaled_pep,
	template,
	interpolants::AbstractDict,
	base_interp::ODEParameterEstimation.AGPInterpolatorUQ,
	true_internal::Vector{Float64},
	anchor_internal::Dict{Int, NamedTuple},
	fn,
)
	times = Float64.(scaled_pep.data_sample["t"])
	time_values = Float64[times[index] for index in combo]
	evaluation = ODEParameterEstimation.evaluate_multipoint_template(
		template, combo, interpolants, scaled_pep.data_sample,
	)
	x_true, d_true = lv_oracle_coordinates(scaled_pep, template, time_values)
	all(isfinite, x_true) && all(isfinite, d_true) || error(
		"oracle coordinate lookup failed for pair $combo",
	)

	n_data = length(template.data_vars)
	n_raw = length(true_internal)
	data_to_raw = zeros(n_data, n_raw)
	d_fixed = copy(d_true)
	for (row, meta) in enumerate(template.data_var_meta)
		if meta.kind == :observable_jet
			meta.obs_idx == 1 || error("LV map expected one observable")
			anchor = anchor_internal[combo[meta.point]]
			data_to_raw[row, :] .= @view anchor.base_W[meta.order + 1, :]
			d_fixed[row] = anchor.fixed_noiseless[meta.order + 1]
		elseif meta.kind == :transcendental
			d_fixed[row] = d_true[row]
		else
			error("unsupported LV template data kind $(meta.kind)")
		end
	end
	d_noisy_from_production_jet = copy(d_true)
	for (row, meta) in enumerate(template.data_var_meta)
		meta.kind == :observable_jet || continue
		d_noisy_from_production_jet[row] =
			anchor_internal[combo[meta.point]].base_mean[meta.order + 1]
	end
	production_jet_reconstruction_error = norm(
		evaluation.data_values - d_noisy_from_production_jet, Inf,
	)
	observation_variance = ODEParameterEstimation.learned_observation_noise_variance(
		base_interp,
	)
	data_covariance = ODEParameterEstimation._psd_symmetric_matrix(
		observation_variance .* (data_to_raw * data_to_raw'),
	)

	oracle_ift = lv_ift_diagnostic(fn, x_true, d_true)
	x_bias, bias_root_ok, bias_iterations, bias_residual = lv_local_newton(
		fn, x_true, d_fixed,
	)
	noisy_start = bias_root_ok ? x_bias : x_true
	x_noisy, noisy_root_ok, noisy_iterations, noisy_residual = lv_local_newton(
		fn, noisy_start, evaluation.data_values,
	)
	linearization_root = noisy_root_ok ? x_noisy : x_true
	linearization_data = noisy_root_ok ? evaluation.data_values : d_true
	root_ift = lv_ift_diagnostic(fn, linearization_root, linearization_data)

	bias_data = d_fixed - d_true
	total_data_error = evaluation.data_values - d_true
	predicted_bias = oracle_ift.S * bias_data
	predicted_total = oracle_ift.S * total_data_error
	coordinate_covariance = ODEParameterEstimation._psd_symmetric_matrix(
		oracle_ift.S * data_covariance * oracle_ift.S',
	)
	coordinate_sigma = sqrt.(max.(diag(coordinate_covariance), 0.0))
	coordinate_names = string.(template.solve_vars)
	predicted_coordinate_bias_z = Float64[
		lv_standardized(predicted_bias[i], coordinate_sigma[i])
		for i in eachindex(coordinate_sigma)
	]
	parameter_indices = template.param_var_indices
	parameter_names = string.(template.solve_vars[parameter_indices])
	parameter_sigma = coordinate_sigma[parameter_indices]
	predicted_parameter_bias = predicted_bias[parameter_indices]
	predicted_parameter_bias_z = Float64[
		lv_standardized(predicted_parameter_bias[i], parameter_sigma[i])
		for i in eachindex(parameter_indices)
	]
	actual_bias = bias_root_ok ? x_bias - x_true : fill(NaN, length(x_true))
	actual_total = noisy_root_ok ? x_noisy - x_true : fill(NaN, length(x_true))
	actual_parameter_bias = actual_bias[parameter_indices]
	actual_parameter_total = actual_total[parameter_indices]
	actual_parameter_bias_z = Float64[
		lv_standardized(actual_parameter_bias[i], parameter_sigma[i])
		for i in eachindex(parameter_indices)
	]
	actual_parameter_total_z = Float64[
		lv_standardized(actual_parameter_total[i], parameter_sigma[i])
		for i in eachindex(parameter_indices)
	]
	actual_coordinate_bias_z = Float64[
		lv_standardized(actual_bias[i], coordinate_sigma[i])
		for i in eachindex(coordinate_sigma)
	]
	actual_coordinate_total_z = Float64[
		lv_standardized(actual_total[i], coordinate_sigma[i])
		for i in eachindex(coordinate_sigma)
	]
	physical_bias = if bias_root_ok
		try
			lv_physical_backsolve_diagnostic(
				scaled_pep, template, x_bias, coordinate_covariance,
				first(time_values),
			)
		catch err
			@warn "LV bias-root physical backsolve failed" combo exception = err
			nothing
		end
	else
		nothing
	end
	physical_total = if noisy_root_ok
		try
			lv_physical_backsolve_diagnostic(
				scaled_pep, template, x_noisy, coordinate_covariance,
				first(time_values),
			)
		catch err
			@warn "LV noisy-root physical backsolve failed" combo exception = err
			nothing
		end
	else
		nothing
	end
	physical_reference = isnothing(physical_total) ? physical_bias : physical_total
	physical_labels = isnothing(physical_reference) ? String[] : physical_reference.labels
	physical_sigma = isnothing(physical_reference) ? Float64[] : physical_reference.physical_sigma
	physical_truth = isnothing(physical_reference) ? Float64[] : physical_reference.truth
	physical_bias_error = isnothing(physical_bias) ? fill(NaN, length(physical_labels)) :
		physical_bias.values - physical_bias.truth
	physical_total_error = isnothing(physical_total) ? fill(NaN, length(physical_labels)) :
		physical_total.values - physical_total.truth
	physical_bias_z = Float64[
		lv_standardized(physical_bias_error[i], physical_sigma[i])
		for i in eachindex(physical_sigma)
	]
	physical_total_z = Float64[
		lv_standardized(physical_total_error[i], physical_sigma[i])
		for i in eachindex(physical_sigma)
	]

	max_anchor_stability = maximum(
		maximum(anchor_internal[index].max_stability_by_order) for index in combo
	)
	boundary_priority = ODEParameterEstimation._multipoint_combo_priority(
		combo, times, interpolants, template, :boundary_order,
	)
	spread_priority = ODEParameterEstimation._multipoint_combo_priority(
		combo, times, interpolants, template, :spread,
	)
	minimum_boundary_lengthscales = minimum(
		min(times[index] - first(times), last(times) - times[index]) /
			base_interp.lengthscale
		for index in combo
	)

	parameter_prediction_error = noisy_root_ok ?
		norm(actual_parameter_total - predicted_total[parameter_indices]) /
			max(norm(actual_parameter_total), 1e-300) : Inf
	parameter_bias_prediction_error = bias_root_ok ?
		norm(actual_parameter_bias - predicted_parameter_bias) /
			max(norm(actual_parameter_bias), 1e-300) : Inf
	max_relative_parameter_error = noisy_root_ok ? maximum(
		abs.(actual_parameter_total) ./ max.(abs.(x_true[parameter_indices]), 1e-12)
	) : Inf

	return Dict{String, Any}(
		"indices" => combo,
		"times" => time_values,
		"spread_rank" => spread_rank,
		"boundary_order_rank" => boundary_rank,
		"spread_priority" => spread_priority,
		"boundary_order_priority" => boundary_priority,
		"minimum_boundary_lengthscales" => minimum_boundary_lengthscales,
		"maximum_anchor_stability_z" => max_anchor_stability,
		"production_jet_reconstruction_error" =>
			production_jet_reconstruction_error,
		"bias_root_ok" => bias_root_ok,
		"bias_root_iterations" => bias_iterations,
		"bias_root_residual" => bias_residual,
		"noisy_root_ok" => noisy_root_ok,
		"noisy_root_iterations" => noisy_iterations,
		"noisy_root_residual" => noisy_residual,
		"condition_raw" => root_ift.condition_raw,
		"condition_row" => root_ift.condition_row,
		"condition_column" => root_ift.condition_column,
		"condition_row_column" => root_ift.condition_row_column,
		"ift_precision_disagreement" => root_ift.ift_precision_disagreement,
		"ift_equation_residual" => root_ift.ift_equation_residual,
		"oracle_root_residual" => oracle_ift.residual,
		"coordinate_names" => coordinate_names,
		"coordinate_sigma" => coordinate_sigma,
		"predicted_coordinate_bias" => predicted_bias,
		"predicted_coordinate_bias_z" => predicted_coordinate_bias_z,
		"actual_coordinate_bias" => actual_bias,
		"actual_coordinate_bias_z" => actual_coordinate_bias_z,
		"actual_coordinate_total_error" => actual_total,
		"actual_coordinate_total_z" => actual_coordinate_total_z,
		"max_abs_predicted_coordinate_bias_z" =>
			maximum(abs, predicted_coordinate_bias_z),
		"max_abs_actual_coordinate_bias_z" =>
			maximum(abs, actual_coordinate_bias_z),
		"max_abs_actual_coordinate_total_z" =>
			maximum(abs, actual_coordinate_total_z),
		"physical_labels" => physical_labels,
		"physical_truth" => physical_truth,
		"physical_sigma" => physical_sigma,
		"physical_bias_error" => physical_bias_error,
		"physical_bias_z" => physical_bias_z,
		"physical_total_error" => physical_total_error,
		"physical_total_z" => physical_total_z,
		"max_abs_physical_bias_z" => isempty(physical_bias_z) ? NaN :
			maximum(abs, physical_bias_z),
		"max_abs_physical_total_z" => isempty(physical_total_z) ? NaN :
			maximum(abs, physical_total_z),
		"physical_backsolve_amplification" => isnothing(physical_reference) ? NaN :
			physical_reference.amplification,
		"parameter_names" => parameter_names,
		"parameter_sigma" => parameter_sigma,
		"predicted_parameter_bias" => predicted_parameter_bias,
		"predicted_parameter_bias_z" => predicted_parameter_bias_z,
		"actual_parameter_bias" => actual_parameter_bias,
		"actual_parameter_bias_z" => actual_parameter_bias_z,
		"actual_parameter_total_error" => actual_parameter_total,
		"actual_parameter_total_z" => actual_parameter_total_z,
		"max_abs_predicted_parameter_bias_z" =>
			maximum(abs, predicted_parameter_bias_z),
		"max_abs_actual_parameter_bias_z" =>
			maximum(abs, actual_parameter_bias_z),
		"max_abs_actual_parameter_total_z" =>
			maximum(abs, actual_parameter_total_z),
		"max_relative_parameter_error" => max_relative_parameter_error,
		"parameter_bias_prediction_relative_error" =>
			parameter_bias_prediction_error,
		"parameter_total_prediction_relative_error" => parameter_prediction_error,
		"data_bias" => bias_data,
		"data_sampling_sigma" => sqrt.(max.(diag(data_covariance), 0.0)),
	)
end

"""Run Stage 1 on one bounded set of 15 production-ranked LV pairs.

The default inspects historical `:spread` ordering. `scope=:boundary15`
inspects the opt-in boundary/order arm without broadening to all 190 pairs.
The result is written atomically. Expanding to all 190 remains a separate
decision, as required by the staged protocol.
"""
function main_lv_mechanism_map(;
	scope::Symbol = :spread15,
	output_path::String = joinpath(
		@__DIR__, "results", "lv_stage1_$(scope)_20260815.toml",
	),
)
	scope in (:spread15, :boundary15) || throw(ArgumentError(
		"scope must be :spread15 or :boundary15",
	))
	production = main_lv_multipoint_diagnostic()
	artifact = production.artifact
	template = artifact.evaluation.template
	case = PEB_AUDITED_CASES[LV_CASE_ID]
	peb_root = _default_peb_root()
	paths = _peb_paths(peb_root, LV_CASE_ID, case)
	pep, rows, original_rows = _peb_problem(case, paths.data, 0)
	scaled_pep, scale_info = ODEParameterEstimation.rescale_pep(deepcopy(pep))
	isnothing(scale_info) && error("expected nontrivial LV power-of-two scaling")
	times = Float64.(scaled_pep.data_sample["t"])
	anchor_indices = ODEParameterEstimation.compute_shooting_indices(
		20, length(times); warp = true, beta = 3.0,
	)
	interpolants = artifact.interpolants
	base_interp = only([
		value for value in values(interpolants)
		if value isa ODEParameterEstimation.AGPInterpolatorUQ
	])
	original_path = joinpath(
		peb_root, PEB_SNAPSHOT, "filetree", "data_original",
		"lotka_volterra_5.csv",
	)
	original = Matrix{Float64}(readdlm(original_path, Char(44), Float64))
	observable_scale = only(values(scale_info.observable_scales))
	true_internal = original[:, 2] ./ observable_scale

	println("\nBuilding deterministic diagnostics for $(length(anchor_indices)) production anchors...")
	anchor_records, anchor_internal, variants = lv_anchor_diagnostics(
		scaled_pep, template, base_interp, true_internal, anchor_indices,
	)
	all_combos = Vector{Vector{Int}}()
	ODEParameterEstimation._generate_combinations!(all_combos, anchor_indices, 2)
	spread_combos = sort(copy(all_combos); by = combo ->
		-ODEParameterEstimation._multipoint_combo_priority(
			combo, times, interpolants, template, :spread,
		))
	boundary_combos = sort(copy(all_combos); by = combo ->
		-ODEParameterEstimation._multipoint_combo_priority(
			combo, times, interpolants, template, :boundary_order,
		))
	spread_rank = Dict(Tuple(combo) => rank for (rank, combo) in enumerate(spread_combos))
	boundary_rank = Dict(Tuple(combo) => rank for (rank, combo) in enumerate(boundary_combos))
	ordered_combos = scope == :spread15 ? spread_combos : boundary_combos
	selected_combos = first(ordered_combos, min(15, length(ordered_combos)))
	combined_vars = vcat(template.solve_vars, template.data_vars)
	fn = ODEParameterEstimation._compile_system_function(
		template.stripped_equations, combined_vars,
	)

	pair_records = Dict{String, Any}[]
	for (rank, combo) in enumerate(selected_combos)
		println("  pair $rank/$(length(selected_combos)): $combo")
		push!(pair_records, lv_pair_diagnostic(
			combo, spread_rank[Tuple(combo)], boundary_rank[Tuple(combo)],
			scaled_pep, template, interpolants, base_interp, true_internal,
			anchor_internal, fn,
		))
	end

	selected_identity = only(production.analysis.returned_results).provenance.estimator_identity
	factorization_records = Dict{String, Any}[]
	for factor in LV_LENGTHSCALE_LADDER
		diagnostics = gp_factorization_diagnostics(variants[factor])
		push!(factorization_records, Dict{String, Any}(
			"factor" => factor,
			"lengthscale" => diagnostics.lengthscale,
			"fitted_lengthscale" => diagnostics.fitted_lengthscale,
			"noise_variance" => diagnostics.noise_variance,
			"jitter_to_noise" => diagnostics.jitter_to_noise,
			"factorization_residual" => diagnostics.factorization_residual,
			"status" => string(diagnostics.status),
		))
	end
	payload = Dict{String, Any}(
		"schema_version" => 1,
		"generated_at" => string(now()),
		"case_id" => LV_CASE_ID,
		"scope" => string(scope),
		"diagnostic_branch_policy" => "oracle_seeded_local_newton",
		"selection_truth_policy" => "oracle quantities forbidden",
		"frozen_peb_commit" => PEB_FROZEN_SHA,
		"data_sha256" => case.data_sha256,
		"generator_sha256" => case.generator_sha256,
		"metadata_sha256" => case.metadata_sha256,
		"row_count" => length(rows),
		"original_row_count" => original_rows,
		"anchor_indices" => anchor_indices,
		"candidate_pair_count" => length(all_combos),
		"evaluated_pair_count" => length(pair_records),
		"template" => Dict{String, Any}(
			"n_points" => template.n_points,
			"equation_count" => length(template.stripped_equations),
			"solve_variable_count" => length(template.solve_vars),
			"data_variable_count" => length(template.data_vars),
			"max_observed_derivative_order" => maximum(
				(meta.order for meta in template.data_var_meta
				 if meta.kind == :observable_jet); init = 0,
			),
		),
		"selected_production_estimator" => _identity_dict(selected_identity),
		"selected_production_uq" => Dict{String, Any}(
			"labels" => copy(production.uq.param_labels),
			"estimates" => copy(production.uq.estimate_values),
			"truth" => copy(production.uq.param_true_values),
			"sigma" => copy(production.uq.param_std),
			"z" => Float64[
				(production.uq.estimate_values[i] - production.uq.param_true_values[i]) /
					production.uq.param_std[i]
				for i in eachindex(production.uq.param_std)
			],
		),
		"factorizations" => factorization_records,
		"anchors" => anchor_records,
		"pairs" => pair_records,
	)
	_atomic_toml(output_path, payload)

	println("\nSTAGE 1 $(uppercase(string(scope))) SUMMARY")
	for record in sort(pair_records; by = record ->
		(record["noisy_root_ok"] ? 0 : 1,
		 record["max_abs_actual_parameter_total_z"]))
		@printf("  rows=%-12s roots=%s/%s boundary_l=%.3f stability=%.3g max|bias z|=%.3g max|total z|=%.3g maxrel=%.3g\n",
			string(record["indices"]), record["bias_root_ok"],
			record["noisy_root_ok"],
			record["minimum_boundary_lengthscales"],
			record["maximum_anchor_stability_z"],
			record["max_abs_actual_parameter_bias_z"],
			record["max_abs_actual_parameter_total_z"],
			record["max_relative_parameter_error"])
	end
	println("Atomic result: $output_path")
	println("LV_STAGE1_MAP_COMPLETE")
	return payload
end

"""Build the LV k=1:4 noise-frontier structures without solving them.

Mixed-volume calculation is separately opt-in because it can dominate the
structure screen. The first pass asks only whether more points actually lower
the required observed-jet order at a tractable system dimension.
"""
function main_lv_structural_frontier(;
	point_counts::Vector{Int} = collect(1:4),
	compute_mixed_volume::Bool = false,
	output_path::String = joinpath(
		@__DIR__, "results",
		"lv_stage2_frontier_$(compute_mixed_volume ? "mv" : "nomv")_20260816.toml",
	),
)
	!isempty(point_counts) && all(point -> 1 <= point <= 4, point_counts) ||
		throw(ArgumentError("point_counts must be a nonempty subset of 1:4"))
	point_counts = sort(unique(point_counts))
	production = main_lv_multipoint_diagnostic()
	artifact = production.artifact
	retained_template = artifact.evaluation.template
	case = PEB_AUDITED_CASES[LV_CASE_ID]
	peb_root = _default_peb_root()
	paths = _peb_paths(peb_root, LV_CASE_ID, case)
	pep, rows, original_rows = _peb_problem(case, paths.data, 0)
	scaled_pep, scale_info = ODEParameterEstimation.rescale_pep(deepcopy(pep))
	isnothing(scale_info) && error("expected nontrivial LV power-of-two scaling")
	setup = (good_DD = retained_template.template_DD,)
	si_template = retained_template.base_si_template

	records = Dict{String, Any}[]
	for n_points in point_counts
		println("Building noise-frontier structure for k=$n_points...")
		measurement = @timed ODEParameterEstimation.build_noise_frontier_system(
			scaled_pep,
			setup,
			si_template;
			n_points,
			compute_mixed_volume,
			candidate_limit = 64,
			beam_width = 16,
			diagnostics = false,
			selection_mode = :generic,
		)
		result = measurement.value
		selected = result.selected
		frontier = Dict{String, Any}[
			Dict{String, Any}(
				"max_observed_order" => row.max_observed_order,
				"allowed_count" => row.allowed_count,
				"allowed_rank" => row.allowed_rank,
				"target_rank" => row.target_rank,
				"feasible" => row.feasible,
			)
			for row in result.frontier
		]
		record = Dict{String, Any}(
			"n_points" => n_points,
			"elapsed_seconds" => measurement.time,
			"allocated_bytes" => measurement.bytes,
			"gc_seconds" => measurement.gctime,
			"minimal_max_observed_order" => isnothing(
				result.minimal_max_observed_order,
			) ? -1 : result.minimal_max_observed_order,
			"candidate_count" => length(result.candidates),
			"full_equation_count" => result.full_equation_count,
			"combined_equation_count" => result.combined_equation_count,
			"target_rank" => result.target_rank,
			"selected" => !isnothing(selected),
			"frontier" => frontier,
		)
		if !isnothing(selected)
			merge!(record, Dict{String, Any}(
				"selected_max_observed_order" => selected.max_observed_order,
				"selected_equation_count" => length(selected.equations),
				"selected_solve_variable_count" => length(selected.solve_vars),
				"selected_data_variable_count" => length(selected.data_vars),
				"selected_mixed_volume" => isnothing(selected.mixed_volume) ?
					-1 : selected.mixed_volume,
				"selected_support_score" => selected.support_score,
				"selected_condition_proxy" => selected.condition_proxy,
				"selected_unfloored_svd_ratio" => selected.unfloored_svd_ratio,
				"selected_equation_indices" => selected.selected_equation_indices,
				"selected_source_indices" => selected.selected_source_indices,
			))
		end
		push!(records, record)
	end

	payload = Dict{String, Any}(
		"schema_version" => 1,
		"generated_at" => string(now()),
		"case_id" => LV_CASE_ID,
		"scope" => "noise_frontier_structure_only",
		"point_counts" => point_counts,
		"compute_mixed_volume" => compute_mixed_volume,
		"frozen_peb_commit" => PEB_FROZEN_SHA,
		"data_sha256" => case.data_sha256,
		"generator_sha256" => case.generator_sha256,
		"metadata_sha256" => case.metadata_sha256,
		"row_count" => length(rows),
		"original_row_count" => original_rows,
		"frontiers" => records,
	)
	_atomic_toml(output_path, payload)
	println("\nSTAGE 2 STRUCTURAL FRONTIER")
	for record in records
		if !record["selected"]
			@printf("  k=%d no square full-rank candidate; candidates=%d time=%.3fs alloc=%.3f GiB\n",
				record["n_points"], record["candidate_count"],
				record["elapsed_seconds"], record["allocated_bytes"] / 2.0^30)
			continue
		end
		@printf("  k=%d order=%d eq/solve/data=%d/%d/%d candidates=%d time=%.3fs alloc=%.3f GiB MV=%d\n",
			record["n_points"], record["selected_max_observed_order"],
			record["selected_equation_count"],
			record["selected_solve_variable_count"],
			record["selected_data_variable_count"], record["candidate_count"],
			record["elapsed_seconds"], record["allocated_bytes"] / 2.0^30,
			record["selected_mixed_volume"])
	end
	println("Atomic result: $output_path")
	println("LV_STAGE2_FRONTIER_COMPLETE")
	return payload
end

"""Screen three predeclared k=3 LV combinations on the oracle branch.

This is still a deterministic mechanism test: it establishes branch
feasibility, projected bias, and local solve cost before any production HC or
repeated-noise campaign is authorized.
"""
function main_lv_k3_fixed_combo_screen(;
	combos::Vector{Vector{Int}} = Vector{Vector{Int}}([
		[25, 223, 635],
		[48, 223, 635],
		[80, 267, 635],
	]),
	screen_id::String = "predeclared_diverse",
	output_path::String = joinpath(
		@__DIR__, "results", "lv_stage2_k3_fixed_combos_20260816.toml",
	),
)
	!isempty(combos) && all(length(combo) == 3 for combo in combos) ||
		throw(ArgumentError("k=3 screen requires nonempty three-index combos"))
	production = main_lv_multipoint_diagnostic()
	artifact = production.artifact
	retained_template = artifact.evaluation.template
	case = PEB_AUDITED_CASES[LV_CASE_ID]
	peb_root = _default_peb_root()
	paths = _peb_paths(peb_root, LV_CASE_ID, case)
	pep, rows, original_rows = _peb_problem(case, paths.data, 0)
	scaled_pep, scale_info = ODEParameterEstimation.rescale_pep(deepcopy(pep))
	isnothing(scale_info) && error("expected nontrivial LV power-of-two scaling")
	setup = (
		good_DD = retained_template.template_DD,
		interpolants = artifact.interpolants,
	)
	template_measurement = @timed ODEParameterEstimation.build_noise_frontier_multipoint_template(
		scaled_pep,
		setup,
		retained_template.base_si_template;
		n_points = 3,
		compute_mixed_volume = true,
		candidate_limit = 64,
		beam_width = 16,
		diagnostics = false,
		selection_mode = :generic,
	)
	template = template_measurement.value
	times = Float64.(scaled_pep.data_sample["t"])
	anchor_indices = ODEParameterEstimation.compute_shooting_indices(
		20, length(times); warp = true, beta = 3.0,
	)
	all(index -> index in anchor_indices, vcat(combos...)) || error(
		"predeclared k=3 screen contains a non-production anchor",
	)
	base_interp = only([
		value for value in values(artifact.interpolants)
		if value isa ODEParameterEstimation.AGPInterpolatorUQ
	])
	original_path = joinpath(
		peb_root, PEB_SNAPSHOT, "filetree", "data_original",
		"lotka_volterra_5.csv",
	)
	original = Matrix{Float64}(readdlm(original_path, Char(44), Float64))
	observable_scale = only(values(scale_info.observable_scales))
	true_internal = original[:, 2] ./ observable_scale
	anchor_records, anchor_internal, variants = lv_anchor_diagnostics(
		scaled_pep, template, base_interp, true_internal, anchor_indices,
	)
	fn = ODEParameterEstimation._compile_system_function(
		template.stripped_equations, vcat(template.solve_vars, template.data_vars),
	)

	combo_records = Dict{String, Any}[]
	for combo in combos
		println("Screening k=3 combo $combo...")
		measurement = @timed lv_pair_diagnostic(
			combo, 0, 0, scaled_pep, template, artifact.interpolants,
			base_interp, true_internal, anchor_internal, fn,
		)
		record = measurement.value
		record["diagnostic_elapsed_seconds"] = measurement.time
		record["diagnostic_allocated_bytes"] = measurement.bytes
		push!(combo_records, record)
	end
	factorization = gp_factorization_diagnostics(variants[1.0])
	payload = Dict{String, Any}(
		"schema_version" => 1,
		"generated_at" => string(now()),
		"case_id" => LV_CASE_ID,
		"scope" => "k3_fixed_combo_oracle_branch_screen",
		"screen_id" => screen_id,
		"diagnostic_branch_policy" => "oracle_seeded_local_newton",
		"selection_truth_policy" => "predeclared_combos_only",
		"frozen_peb_commit" => PEB_FROZEN_SHA,
		"data_sha256" => case.data_sha256,
		"generator_sha256" => case.generator_sha256,
		"metadata_sha256" => case.metadata_sha256,
		"row_count" => length(rows),
		"original_row_count" => original_rows,
		"template" => Dict{String, Any}(
			"n_points" => template.n_points,
			"equation_count" => length(template.stripped_equations),
			"solve_variable_count" => length(template.solve_vars),
			"data_variable_count" => length(template.data_vars),
			"max_observed_derivative_order" => maximum(
				(meta.order for meta in template.data_var_meta
				 if meta.kind == :observable_jet); init = 0,
			),
			"construction_seconds" => template_measurement.time,
			"construction_allocated_bytes" => template_measurement.bytes,
		),
		"factorization" => Dict{String, Any}(
			"lengthscale" => factorization.lengthscale,
			"noise_variance" => factorization.noise_variance,
			"jitter_to_noise" => factorization.jitter_to_noise,
			"factorization_residual" => factorization.factorization_residual,
		),
		"anchors" => anchor_records,
		"combos" => combo_records,
	)
	_atomic_toml(output_path, payload)
	println("\nSTAGE 2 k=3 FIXED-COMBO SUMMARY")
	for record in combo_records
		@printf("  rows=%-16s roots=%s/%s max|param bias/total z|=%.3g/%.3g max|physical bias/total z|=%.3g/%.3g maxrel=%.3g cond(eq)=%.3g time=%.3fs\n",
			string(record["indices"]), record["bias_root_ok"],
			record["noisy_root_ok"],
			record["max_abs_actual_parameter_bias_z"],
			record["max_abs_actual_parameter_total_z"],
			record["max_abs_physical_bias_z"],
			record["max_abs_physical_total_z"],
			record["max_relative_parameter_error"],
			record["condition_row_column"],
			record["diagnostic_elapsed_seconds"])
	end
	println("Atomic result: $output_path")
	println("LV_STAGE2_K3_SCREEN_COMPLETE")
	return payload
end

"""Screen fixed lengthscale multipliers on the selected k=2 LV recipe.

The shooting rows, polynomial template, fitted signal/noise variances, and
oracle-seeded branch are held fixed.  Only the retained SE lengthscale is
multiplied, so this is a deterministic derivative-undersmoothing mechanism
screen rather than a production model-selection rule.
"""
function main_lv_k2_lengthscale_screen(;
	factors::Vector{Float64} = copy(LV_LENGTHSCALE_LADDER),
	combo::Vector{Int} = [25, 635],
	output_path::String = joinpath(
		@__DIR__, "results", "lv_stage3_k2_lengthscale_screen_20260816.toml",
	),
)
	!isempty(factors) && all(factor -> isfinite(factor) && factor > 0, factors) ||
		throw(ArgumentError("lengthscale factors must be finite and positive"))
	length(combo) == 2 || throw(ArgumentError(
		"k=2 lengthscale screen requires exactly two shooting rows",
	))
	factors = unique(factors)
	production = main_lv_multipoint_diagnostic()
	artifact = production.artifact
	template = artifact.evaluation.template
	case = PEB_AUDITED_CASES[LV_CASE_ID]
	peb_root = _default_peb_root()
	paths = _peb_paths(peb_root, LV_CASE_ID, case)
	pep, rows, original_rows = _peb_problem(case, paths.data, 0)
	scaled_pep, scale_info = ODEParameterEstimation.rescale_pep(deepcopy(pep))
	isnothing(scale_info) && error("expected nontrivial LV power-of-two scaling")
	times = Float64.(scaled_pep.data_sample["t"])
	anchor_indices = ODEParameterEstimation.compute_shooting_indices(
		20, length(times); warp = true, beta = 3.0,
	)
	all(index -> index in anchor_indices, combo) || error(
		"lengthscale screen contains a non-production shooting row",
	)
	base_interp = only([
		value for value in values(artifact.interpolants)
		if value isa ODEParameterEstimation.AGPInterpolatorUQ
	])
	original_path = joinpath(
		peb_root, PEB_SNAPSHOT, "filetree", "data_original",
		"lotka_volterra_5.csv",
	)
	original = Matrix{Float64}(readdlm(original_path, Char(44), Float64))
	observable_scale = only(values(scale_info.observable_scales))
	true_internal = original[:, 2] ./ observable_scale
	fn = ODEParameterEstimation._compile_system_function(
		template.stripped_equations, vcat(template.solve_vars, template.data_vars),
	)

	records = Dict{String, Any}[]
	for factor in factors
		println("Screening selected k=2 rows $combo at lengthscale factor $factor...")
		variant = factor == 1.0 ? base_interp :
			lv_refactor_lengthscale(base_interp, factor)
		variant_interpolants = Dict{Any, Any}(
			key => value isa ODEParameterEstimation.AGPInterpolatorUQ ?
				variant : value
			for (key, value) in artifact.interpolants
		)
		anchor_records, anchor_internal, _ = lv_anchor_diagnostics(
			scaled_pep, template, variant, true_internal, combo;
			lengthscale_ladder = Float64[1.0],
		)
		measurement = @timed lv_pair_diagnostic(
			combo, 0, 0, scaled_pep, template, variant_interpolants,
			variant, true_internal, anchor_internal, fn,
		)
		record = measurement.value
		factorization = gp_factorization_diagnostics(variant)
		record["lengthscale_factor"] = factor
		record["lengthscale"] = factorization.lengthscale
		record["fitted_lengthscale"] = factorization.fitted_lengthscale
		record["jitter_to_noise"] = factorization.jitter_to_noise
		record["factorization_residual"] = factorization.factorization_residual
		record["diagnostic_elapsed_seconds"] = measurement.time
		record["diagnostic_allocated_bytes"] = measurement.bytes
		record["anchors"] = anchor_records
		push!(records, record)
	end

	selected_identity = only(
		production.analysis.returned_results,
	).provenance.estimator_identity
	payload = Dict{String, Any}(
		"schema_version" => 1,
		"generated_at" => string(now()),
		"case_id" => LV_CASE_ID,
		"scope" => "k2_fixed_recipe_lengthscale_mechanism_screen",
		"diagnostic_branch_policy" => "oracle_seeded_local_newton",
		"selection_truth_policy" => "fixed_production_selected_rows",
		"fitted_hyperparameter_policy" =>
			"signal_and_noise_frozen; lengthscale_multiplier_only",
		"production_promotion_policy" =>
			"none; an oracle-free selection rule requires a separate design round",
		"frozen_peb_commit" => PEB_FROZEN_SHA,
		"data_sha256" => case.data_sha256,
		"generator_sha256" => case.generator_sha256,
		"metadata_sha256" => case.metadata_sha256,
		"row_count" => length(rows),
		"original_row_count" => original_rows,
		"selected_production_estimator" => _identity_dict(selected_identity),
		"indices" => combo,
		"times" => Float64[times[index] for index in combo],
		"factors" => factors,
		"template" => Dict{String, Any}(
			"n_points" => template.n_points,
			"equation_count" => length(template.stripped_equations),
			"solve_variable_count" => length(template.solve_vars),
			"data_variable_count" => length(template.data_vars),
			"max_observed_derivative_order" => maximum(
				(meta.order for meta in template.data_var_meta
				 if meta.kind == :observable_jet); init = 0,
			),
		),
		"screens" => records,
	)
	_atomic_toml(output_path, payload)

	println("\nSTAGE 3 k=2 FIXED-LENGTHSCALE SUMMARY")
	for record in records
		@printf("  l/l_ML=%.2f roots=%s/%s max|param bias/total z|=%.3g/%.3g max|physical bias/total z|=%.3g/%.3g maxrel=%.3g cond(eq)=%.3g time=%.3fs\n",
			record["lengthscale_factor"], record["bias_root_ok"],
			record["noisy_root_ok"],
			record["max_abs_actual_parameter_bias_z"],
			record["max_abs_actual_parameter_total_z"],
			record["max_abs_physical_bias_z"],
			record["max_abs_physical_total_z"],
			record["max_relative_parameter_error"],
			record["condition_row_column"],
			record["diagnostic_elapsed_seconds"])
	end
	println("Atomic result: $output_path")
	println("LV_STAGE3_LENGTHSCALE_SCREEN_COMPLETE")
	return payload
end

if abspath(PROGRAM_FILE) == @__FILE__
	if "--lengthscale-screen" in ARGS
		factors = parse.(Float64, split(
			_campaign_arg("factors", join(LV_LENGTHSCALE_LADDER, ',')), ',',
		))
		combo = parse.(Int, split(_campaign_arg("indices", "25,635"), ','))
		main_lv_k2_lengthscale_screen(; factors, combo, output_path = _campaign_arg(
			"out", joinpath(
				@__DIR__, "results",
				"lv_stage3_k2_lengthscale_screen_20260816.toml",
			),
		))
	elseif "--k3-screen" in ARGS
		main_lv_k3_fixed_combo_screen(; output_path = _campaign_arg(
			"out", joinpath(
				@__DIR__, "results", "lv_stage2_k3_fixed_combos_20260816.toml",
			),
		))
	elseif "--k3-augment" in ARGS
		main_lv_k3_fixed_combo_screen(;
			combos = Vector{Vector{Int}}([
				[25, 267, 635],
				[25, 320, 635],
				[25, 381, 635],
			]),
			screen_id = "selected_pair_plus_low_instability_interior",
			output_path = _campaign_arg(
				"out", joinpath(
					@__DIR__, "results",
					"lv_stage2_k3_selected_pair_augmentation_20260816.toml",
				),
			),
		)
	elseif "--frontier" in ARGS
		compute_mixed_volume = lowercase(_campaign_arg("mixed-volume", "false")) == "true"
		point_counts = parse.(Int, split(_campaign_arg("points", "1,2,3,4"), ','))
		point_token = join(sort(unique(point_counts)), "_")
		main_lv_structural_frontier(; point_counts, compute_mixed_volume,
			output_path = _campaign_arg(
			"out", joinpath(
				@__DIR__, "results",
				"lv_stage2_frontier_k$(point_token)_$(compute_mixed_volume ? "mv" : "nomv")_20260816.toml",
			),
		))
	elseif "--pair-map" in ARGS
		scope = Symbol(_campaign_arg("scope", "spread15"))
		main_lv_mechanism_map(; scope, output_path = _campaign_arg(
			"out", joinpath(
				@__DIR__, "results", "lv_stage1_$(scope)_20260815.toml",
			),
		))
	elseif "--gp-only" in ARGS
		main_lv_gp_bias_decomposition()
	else
		main_lv_multipoint_diagnostic()
	end
end
