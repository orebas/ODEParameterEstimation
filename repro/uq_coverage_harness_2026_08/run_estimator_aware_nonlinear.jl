# Estimator-aware nonlinear UQ campaign (2026-08-14).
#
# This is the production-path successor to `run_nonlinear_validation.jl`.
# It compares the exact selected single-point and multipoint algebraic
# estimators on identical noisy data, records the selected estimator identity
# (including exact time points and lineage), and scores the UQ report around
# that selected estimate. Every completed cell is written atomically to TOML,
# so a long campaign can be resumed safely.
#
# Examples:
#
#   julia --startup-file=no repro/uq_coverage_harness_2026_08/run_estimator_aware_nonlinear.jl \
#       --n=1 --noises=1e-4 --arms=sp,mp --out=pilot_20260814
#
#   julia --startup-file=no repro/uq_coverage_harness_2026_08/run_estimator_aware_nonlinear.jl \
#       --n=60 --models=lotka_volterra --noises=1e-5 --arms=mp \
#       --out=lv_mp_n60_20260814

using ODEParameterEstimation
using Dates
using Printf
using Random
using Statistics
using TOML

include(joinpath(@__DIR__, "coverage_driver.jl"))

const NONLINEAR_CASES = Dict(
	"lotka_volterra" => (
		ctor = ODEParameterEstimation.lotka_volterra,
		time_interval = [0.0, 20.0],
		seed0 = 31_000,
	),
	"vanderpol" => (
		ctor = ODEParameterEstimation.vanderpol,
		time_interval = [0.0, 10.0],
		seed0 = 32_000,
	),
	"fitzhugh_nagumo" => (
		ctor = ODEParameterEstimation.fitzhugh_nagumo,
		time_interval = [0.0, 0.03],
		seed0 = 33_000,
	),
)

function _campaign_arg(name::String, default::String)
	prefix = "--$(name)="
	match = findfirst(arg -> startswith(arg, prefix), ARGS)
	isnothing(match) && return default
	return ARGS[match][(length(prefix) + 1):end]
end

_campaign_list(name::String, default::String) =
	String.(filter(!isempty, strip.(split(_campaign_arg(name, default), ','))))

function _campaign_float_list(name::String, default::String)
	return parse.(Float64, _campaign_list(name, default))
end

function _safe_token(x)
	return replace(string(x), "-" => "m", "+" => "p", "." => "p")
end

function _model_coordinates(pep::ParameterEstimationProblem)
	coords = NamedTuple[]
	for state in pep.model.original_states
		push!(coords, (label = _base_name(state), role = :state,
			truth = Float64(get(pep.ic, state, NaN))))
	end
	for param in pep.model.original_parameters
		startswith(string(param), "init_") && continue
		push!(coords, (label = _base_name(param), role = :parameter,
			truth = Float64(get(pep.p_true, param, NaN))))
	end
	return coords
end

function _selected_center(selected::ParameterEstimationResult, label::String)
	return Float64(_center_for_label(selected, label))
end

function _identity_dict(identity::EstimatorIdentity)
	return Dict{String, Any}(
		"candidate_id" => identity.candidate_id,
		"estimator_kind" => string(identity.estimator_kind),
		"data_scope" => string(identity.data_scope),
		"time_indices" => copy(identity.time_indices),
		"time_values" => copy(identity.time_values),
		"interpolator_source" => isnothing(identity.interpolator_source) ? "" : string(identity.interpolator_source),
		"parent_candidate_ids" => copy(identity.parent_candidate_ids),
	)
end

function _arm_options(
	arm::String,
	shooting_points::Int,
	max_pairs::Int;
	pair_strategy::Symbol = :spread,
	lengthscale_factor::Float64 = 1.0,
)
	common = (
		interpolator = InterpolatorAGPUQ,
		interpolators = InterpolatorMethod[],
		auto_filter_interpolators = false,
		compute_uncertainty = true,
		uq_failure_policy = :return_failed,
		polish_solutions = false,
		synthesize_aggregate_candidates = false,
		branch_completion = false,
		save_system = false,
		terminal_fallback = :none,
		multipoint_pair_strategy = pair_strategy,
		gp_derivative_lengthscale_factor = lengthscale_factor,
	)
	if arm == "sp"
		return (; common..., use_multipoint = false, shooting_points = 0,
			polish_solver_solutions = false)
	elseif arm == "mp"
		return (; common..., use_multipoint = true, shooting_points = shooting_points,
			multipoint_n_points = 2, multipoint_max_pairs = max_pairs,
			polish_solver_solutions = false)
	elseif arm == "mp_solver_polish"
		return (; common..., use_multipoint = true, shooting_points = shooting_points,
			multipoint_n_points = 2, multipoint_max_pairs = max_pairs,
			polish_solver_solutions = true)
	elseif arm == "sp_polish"
		return (; common..., use_multipoint = false, shooting_points = 0,
			polish_solutions = true, polish_solver_solutions = true, polish_maxtime = 120.0,
			polish_max_concurrency = max(1, min(Threads.nthreads(), 2)))
	elseif arm == "mp_polish"
		return (; common..., use_multipoint = true, shooting_points = shooting_points,
			multipoint_n_points = 2, multipoint_max_pairs = max_pairs,
			polish_solutions = true, polish_solver_solutions = true, polish_maxtime = 120.0,
			polish_max_concurrency = max(1, min(Threads.nthreads(), 2)))
	end
	throw(ArgumentError(
		"unknown arm '$arm'; use sp, mp, mp_solver_polish, sp_polish, or mp_polish"))
end

function _coordinate_records(pep, selected, uq)
	report = uq isa UncertaintyReport ? uq : nothing
	sigma_by_label = Dict{String, Float64}()
	estimate_by_label = Dict{String, Float64}()
	if !isnothing(report)
		for (label, center, sigma) in zip(report.param_labels,
				report.estimate_values, report.param_std)
			sigma_by_label[_base_name(label)] = Float64(sigma)
			estimate_by_label[_base_name(label)] = Float64(center)
		end
	end

	rows = Dict{String, Any}[]
	for coord in _model_coordinates(pep)
		center = get(estimate_by_label, coord.label,
			_selected_center(selected, coord.label))
		sigma = get(sigma_by_label, coord.label, NaN)
		z = isfinite(center) && isfinite(coord.truth) && isfinite(sigma) && sigma > 0 ?
			(center - coord.truth) / sigma : NaN
		absolute_error = isfinite(center) && isfinite(coord.truth) ?
			abs(center - coord.truth) : Inf
		relerr = isfinite(center) && isfinite(coord.truth) ?
			ODEParameterEstimation.relative_error_value(center, coord.truth) : Inf
		push!(rows, Dict{String, Any}(
			"label" => coord.label,
			"role" => string(coord.role),
			"truth" => coord.truth,
			"estimate" => center,
			"sigma" => sigma,
			"z" => z,
			"covered_95" => isfinite(z) && abs(z) <= ODEParameterEstimation.UQ_CI_Z,
			"absolute_error" => absolute_error,
			"relative_error" => relerr,
		))
	end
	return rows
end

function _candidate_records(pep, candidates, selected_candidate_id::Int)
	rows = Dict{String, Any}[]
	for (raw_index, candidate) in enumerate(candidates)
		candidate isa ParameterEstimationResult || continue
		identity = candidate.provenance.estimator_identity
		stats = ODEParameterEstimation.oracle_error_stats(pep, candidate)
		push!(rows, Dict{String, Any}(
			"raw_index" => raw_index,
			"selected" => identity.candidate_id == selected_candidate_id,
			"fit_error" => isnothing(candidate.err) ? Inf : Float64(candidate.err),
			"minimum_error" => isnothing(stats) ? Inf : stats.minimum,
			"median_error" => isnothing(stats) ? Inf : stats.median,
			"maximum_error" => isnothing(stats) ? Inf : stats.maximum,
			"identity" => _identity_dict(identity),
		))
	end
	return rows
end

function _reliability_record(outcome)
	assessment = uq_reliability(outcome)
	return Dict{String, Any}(
		"availability" => string(assessment.availability),
		"numerical_linearization" => string(assessment.numerical_linearization),
		"interval_width" => string(assessment.interval_width),
		"selection_scope" => string(assessment.selection_scope),
		"empirical_calibration" => string(assessment.empirical_calibration),
	)
end

function _record_uq_outcome!(payload::Dict{String, Any}, uq)
	payload["uq_reliability"] = _reliability_record(uq)
	if uq isa UncertaintyReport
		payload["outcome"] = "report"
		payload["uq_status"] = string(uq.status)
		payload["max_cv"] = uq.max_cv
		payload["artifact_match"] = isnothing(uq.target) ? "" : string(uq.target.artifact_match)
		payload["lineage"] = isnothing(uq.target) ? Dict{String, Any}[] :
			[_identity_dict(item) for item in uq.target.lineage]
		payload["uq_param_labels"] = copy(uq.param_labels)
		payload["uq_estimate_values"] = copy(uq.estimate_values)
		payload["uq_param_std"] = copy(uq.param_std)
		payload["uq_param_covariance"] = [collect(row) for row in eachrow(uq.param_covariance)]
		payload["uq_correlation_matrix"] = [collect(row) for row in eachrow(uq.correlation_matrix)]
		payload["uq_warnings"] = copy(uq.warnings)
		diagnostics = uq.linearization_diagnostics
		payload["linearization"] = Dict{String, Any}(
			"reason" => string(diagnostics.reason),
			"root_residual_abs" => diagnostics.root_residual_abs,
			"root_residual_rel" => diagnostics.root_residual_rel,
			"jacobian_condition" => diagnostics.jacobian_condition,
			"gradient_norm" => diagnostics.gradient_norm,
			"active_bounds" => diagnostics.active_bounds,
			"degraded" => diagnostics.degraded,
			"gp_jitter_to_noise" => diagnostics.gp_jitter_to_noise,
			"gp_factorization_residual" => diagnostics.gp_factorization_residual,
		)
	elseif uq isa UQUnavailable
		payload["outcome"] = "uq_unavailable"
		payload["uq_reason"] = string(uq.reason)
		payload["message"] = uq.message
		payload["warnings"] = uq.warnings
		payload["lineage"] = isnothing(uq.target) ? Dict{String, Any}[] :
			[_identity_dict(item) for item in uq.target.lineage]
	else
		payload["outcome"] = isnothing(uq) ? "uq_disabled_unexpectedly" : "unknown_uq_outcome"
	end
	return payload
end

function _atomic_toml(path::String, payload::Dict{String, Any})
	mkpath(dirname(path))
	tmp_path, io = mktemp(dirname(path))
	try
		TOML.print(io, payload; sorted = true)
		close(io)
		mv(tmp_path, path; force = true)
	catch
		isopen(io) && close(io)
		isfile(tmp_path) && rm(tmp_path; force = true)
		rethrow()
	end
	return path
end

function _run_path(
	out_dir::String, model::String, noise::Float64, rep::Int, arm::String,
	pair_strategy::Symbol, lengthscale_factor::Float64,
)
	variant = pair_strategy == :spread && lengthscale_factor == 1.0 ? "" :
		"__$(pair_strategy)__ls_$(_safe_token(lengthscale_factor))"
	filename = "$(model)__noise_$(_safe_token(noise))__rep_$(lpad(rep, 3, '0'))__$(arm)$(variant).toml"
	return joinpath(out_dir, filename)
end

function _run_one(model_name::String, case, noise::Float64, rep::Int, arm::String;
		datasize::Int, shooting_points::Int, max_pairs::Int, out_dir::String,
		pair_strategy::Symbol, lengthscale_factor::Float64, force::Bool)
	path = _run_path(out_dir, model_name, noise, rep, arm,
		pair_strategy, lengthscale_factor)
	if isfile(path) && !force
		println("SKIP completed: ", basename(path))
		return TOML.parsefile(path)
	end

	seed = case.seed0 + rep
	Random.seed!(seed)
	sample_opts = EstimationOptions(
		datasize = datasize,
		time_interval = case.time_interval,
		noise_level = noise,
		nooutput = true,
		diagnostics = false,
		save_system = false,
	)
	pep_data = ODEParameterEstimation.sample_problem_data(case.ctor(), sample_opts)
	extra = _arm_options(arm, shooting_points, max_pairs;
		pair_strategy, lengthscale_factor)
	opts = EstimationOptions(;
		datasize = datasize,
		time_interval = case.time_interval,
		noise_level = noise,
		nooutput = true,
		diagnostics = false,
		extra...,
	)

	println("RUN  model=$model_name noise=$noise rep=$rep arm=$arm seed=$seed")
	flush(stdout)
	started = time()
	payload = Dict{String, Any}(
		"schema_version" => 1,
		"model" => model_name,
		"noise" => noise,
		"replicate" => rep,
		"arm" => arm,
		"seed" => seed,
		"datasize" => datasize,
		"time_interval" => case.time_interval,
		"shooting_points" => arm in ("mp", "mp_solver_polish", "mp_polish") ? shooting_points : 1,
		"multipoint_max_pairs" => arm in ("mp", "mp_solver_polish", "mp_polish") ? max_pairs : 0,
		"multipoint_pair_strategy" => string(pair_strategy),
		"gp_derivative_lengthscale_factor" => lengthscale_factor,
		"started_at" => string(now()),
	)

	try
		result, timing = _cov_quiet() do
			with_estimation_timing() do
				ODEParameterEstimation.analyze_parameter_estimation_problem(deepcopy(pep_data), opts)
			end
		end
		raw, analysis, uq = result
		payload["elapsed_seconds"] = time() - started
		payload["max_rss_bytes"] = Sys.maxrss()
		payload["structured_timing"] = timing_breakdown_to_dict(timing)
		payload["raw_candidate_count"] = isempty(raw) ? 0 : length(raw[1])
		payload["returned_candidate_count"] = length(analysis.returned_results)
		if isempty(analysis.returned_results)
			payload["outcome"] = "no_estimate"
			payload["message"] = "analysis.returned_results was empty"
			_atomic_toml(path, payload)
			println("DONE ", basename(path), " outcome=no_estimate elapsed=",
				round(payload["elapsed_seconds"]; digits = 1), "s")
			flush(stdout)
			return payload
		end

		selected = first(analysis.returned_results)
		identity = selected.provenance.estimator_identity
		payload["selected_fit_error"] = isnothing(selected.err) ? Inf : Float64(selected.err)
		payload["selected_identity"] = _identity_dict(identity)
		payload["coordinates"] = _coordinate_records(pep_data, selected, uq)
		payload["candidate_diagnostics"] = _candidate_records(
			pep_data, isempty(raw) ? Any[] : raw[1], identity.candidate_id)

		_record_uq_outcome!(payload, uq)
	catch e
		e isa InterruptException && rethrow()
		payload["elapsed_seconds"] = time() - started
		payload["outcome"] = "error"
		payload["message"] = sprint(showerror, e, catch_backtrace())
	end

	_atomic_toml(path, payload)
	println("DONE ", basename(path), " outcome=", payload["outcome"],
		" elapsed=", round(payload["elapsed_seconds"]; digits = 1), "s")
	flush(stdout)
	return payload
end

function _finite_max(values)
	finite = filter(isfinite, values)
	return isempty(finite) ? Inf : maximum(finite)
end

function _point_summary(points)
	length(points) <= 8 && return string(points)
	return "[$(length(points)) points: $(first(points))…$(last(points))]"
end

function _print_summary(payloads)
	println("\n", "="^132)
	println("ESTIMATOR-AWARE NONLINEAR PILOT SUMMARY")
	println("="^132)
	@printf("%-19s %-9s %-3s %-11s %-23s %-15s %-11s %-11s %-9s %s\n",
		"model", "noise", "rep", "arm", "selected estimator", "UQ outcome", "worst err", "fit error", "seconds", "selected points")
	for payload in payloads
		identity = get(payload, "selected_identity", Dict{String, Any}())
		coords = get(payload, "coordinates", Dict{String, Any}[])
		worst_rel = _finite_max(Float64[
			ODEParameterEstimation.relative_error_value(
				Float64(get(row, "estimate", NaN)), Float64(get(row, "truth", NaN)))
			for row in coords
		])
		points = get(identity, "time_values", Any[])
		@printf("%-19s %-9.1e %-3d %-11s %-23s %-15s %-11.3g %-11.3g %-9.1f %s\n",
			payload["model"], payload["noise"], payload["replicate"], payload["arm"],
			get(identity, "estimator_kind", "—"), get(payload, "outcome", "—"),
			worst_rel, get(payload, "selected_fit_error", Inf),
			get(payload, "elapsed_seconds", NaN), _point_summary(points))
	end
	println("="^132)
	return nothing
end

function main()
	model_names = _campaign_list("models", "lotka_volterra,vanderpol,fitzhugh_nagumo")
	unknown = setdiff(model_names, collect(keys(NONLINEAR_CASES)))
	isempty(unknown) || throw(ArgumentError("unknown models: $(join(unknown, ", "))"))
	noises = _campaign_float_list("noises", "1e-4")
	arms = _campaign_list("arms", "sp,mp")
	n_reps = parse(Int, _campaign_arg("n", "1"))
	datasize = parse(Int, _campaign_arg("datasize", "121"))
	shooting_points = parse(Int, _campaign_arg("shooting-points", "6"))
	max_pairs = parse(Int, _campaign_arg("max-pairs", "6"))
	pair_strategy = Symbol(_campaign_arg("pair-strategy", "spread"))
	lengthscale_factor = parse(Float64, _campaign_arg("lengthscale-factor", "1.0"))
	time_end_arg = _campaign_arg("time-end", "")
	time_end = isempty(time_end_arg) ? nothing : parse(Float64, time_end_arg)
	force = lowercase(_campaign_arg("force", "false")) in ("true", "yes", "1")
	out_name = _campaign_arg("out", "estimator_aware_nonlinear_$(Dates.format(now(), "yyyymmdd_HHMMSS"))")
	out_dir = isabspath(out_name) ? out_name : joinpath(@__DIR__, "results", out_name)
	mkpath(out_dir)

	println("Output: ", out_dir)
	println("Models: ", join(model_names, ", "), " | noises: ", noises,
		" | arms: ", arms, " | N=", n_reps)
	payloads = Dict{String, Any}[]
	for model_name in model_names, noise in noises, rep in 1:n_reps, arm in arms
		base_case = NONLINEAR_CASES[model_name]
		case = isnothing(time_end) ? base_case : (;
			base_case..., time_interval = [first(base_case.time_interval), time_end])
		push!(payloads, _run_one(model_name, case, noise, rep, arm;
			datasize, shooting_points, max_pairs, out_dir,
			pair_strategy, lengthscale_factor, force))
	end
	_print_summary(payloads)
	println("Results saved under ", out_dir)
	return payloads
end

if abspath(PROGRAM_FILE) == @__FILE__
	main()
end
