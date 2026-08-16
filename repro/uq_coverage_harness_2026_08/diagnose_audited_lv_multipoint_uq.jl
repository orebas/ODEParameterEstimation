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
	noisy = Matrix{Float64}(readdlm(paths.data, Char(44), Float64))
	true_internal = original[:, 2] ./ observable_scale
	noisy_internal = noisy[:, 2] ./ observable_scale
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
		gp_mean, W = ODEParameterEstimation.gp_derivative_influence_matrix(agp, t_eval, 3)
		fixed_noiseless = W * true_internal
		noise_effect = W * (noisy_internal - true_internal)
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

if abspath(PROGRAM_FILE) == @__FILE__
	if "--gp-only" in ARGS
		main_lv_gp_bias_decomposition()
	else
		main_lv_multipoint_diagnostic()
	end
end
