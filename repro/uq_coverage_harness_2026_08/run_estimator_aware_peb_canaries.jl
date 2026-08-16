# Estimator-aware UQ canaries sourced from the audited PEB paper benchmark.
#
# This is intentionally not a benchmark sweep. The default three cells were
# selected from the frozen final-v2 PEB run because ODEPE historically produced
# accurate polished estimates and the saved metadata identifies the winning
# algebraic seed route: multipoint for LV/FHN and single-point for Van der Pol.
# The current run asks whether the selected trajectory estimator and its retained
# lineage/UQ artifact still tell that truth.
#
# The default uses all 750 frozen noisy observations. A reduced row count is an
# explicitly requested speed smoke, not a reproduction: FHN candidate ranking
# changed materially when the same cell was evenly reduced to 121 observations.

include(joinpath(@__DIR__, "run_estimator_aware_nonlinear.jl"))

using DelimitedFiles
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using SHA
using Symbolics: Num

const PEB_SNAPSHOT = "benchmark_final_v2_2026-06-12"
const PEB_RESULTS_SNAPSHOT = "results/final_v2_2026_06_12"
const PEB_FROZEN_SHA = "c94e0a3eb5bbd8ab95c73e30f203cbad73485d7b"

const PEB_AUDITED_CASES = Dict(
	"lotka_volterra_2_1em4" => (
		model = :lotka_volterra,
		instance = 2,
		noise = 1e-4,
		p_true = [0.467, 0.428, 0.825],
		ic = [0.606, 0.288],
		time_interval = [0.0, 20.0],
		data_sha256 = "2d32165c2153f481b948abb3fc5946792501f21c88461a2ddc5bfb54933cf24e",
		generator_sha256 = "12ecb6e437d7554809cc5ec59bcd02e995ddf0b4498fc49a2dd1a32d71864646",
		metadata_sha256 = "c739246934bcd95bae6bc12e73e61a3cb2e3bf34c30284db6974a31566098eb3",
		historical_run = "odepe_v2_polish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [16, 635],
		historical_interpolator = :s3_adapt_se,
		historical_max_error = 1.513708871692881e-5,
	),
	"vanderpol_2_1em4" => (
		model = :vanderpol,
		instance = 2,
		noise = 1e-4,
		p_true = [0.685, 0.851],
		ic = [0.178, 0.689],
		time_interval = [0.0, 10.0],
		data_sha256 = "65ed9a23b41e07298a911dfc2f697621b6a815c12752b5f997c8e276a473ecbb",
		generator_sha256 = "51edc95bfcaf31d1ff9bf13e1ebe3dca6491edc900b8c1d753c39a7bd090c48b",
		metadata_sha256 = "29a109daef065b46fe4118acbc02c4dac958fd9574dde17e1db4835a21c61286",
		historical_run = "odepe_v2_polish_run",
		historical_kind = :single_point_algebraic,
		historical_time_indices = [267],
		historical_interpolator = :aaad_gpr,
		historical_max_error = 1.5240685054897487e-6,
	),
	"fitzhugh_nagumo_1_1em4" => (
		model = :fitzhugh_nagumo,
		instance = 1,
		noise = 1e-4,
		p_true = [0.611, 0.855, 0.837],
		ic = [0.273, 0.772],
		time_interval = [0.0, 1.0],
		data_sha256 = "bddffad5e352f06057c55db44d1e5a67351fd729497030e159d70e58fb4bd111",
		generator_sha256 = "cdfcc9ad3b76856f027fafa142a765c9f72f515b39747c9415d83ce3121517bf",
		metadata_sha256 = "243d52ba8726ecbcd81104df997175cf48aca86797e421485e5967296703c487",
		historical_run = "odepe_v2_polish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [80, 750],
		historical_interpolator = :agp_robust_rq,
		historical_max_error = 0.0022960063372558215,
	),
	"lotka_volterra_5_1em6" => (
		model = :lotka_volterra,
		instance = 5,
		noise = 1e-6,
		p_true = [0.21, 0.778, 0.688],
		ic = [0.722, 0.879],
		time_interval = [0.0, 20.0],
		data_sha256 = "69bd0ba3d4cc4d188cf470591442542e1cf0ca7c5a074b75ff4d63a04ab469bb",
		generator_sha256 = "953d072fe9ce13f7ace2fa9ee6c211ff96c88edb33b0fd2e5e58616355e37a84",
		metadata_sha256 = "d9991ccd917b1cff9b4ca1a434a85c19eab682d670c74692eaa93556715193d3",
		historical_run = "odepe_v2_nopolish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [36, 635],
		historical_interpolator = :s3_adapt_se,
		historical_max_error = 2.533684888894984e-5,
	),
	"fitzhugh_nagumo_9_1em6" => (
		model = :fitzhugh_nagumo,
		instance = 9,
		noise = 1e-6,
		p_true = [0.433, 0.602, 0.729],
		ic = [0.888, 0.603],
		time_interval = [0.0, 1.0],
		data_sha256 = "18eeb2b90c94199f81f24b850ff0eaed3a5b8ac581b1433ac83e1afda027f51a",
		generator_sha256 = "f2f8156c9d8435d9a51dc4adffa6526d8ec8a5d22af31eeb9b164aa8347a6084",
		metadata_sha256 = "3c64c4135209c92b139305ae1a9d7d234bf8be69027b775c49a50de1d57d8f65",
		historical_run = "odepe_v2_nopolish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [80, 750],
		historical_interpolator = :s3_adapt_rq,
		historical_max_error = 0.0008993598587535475,
	),
)

function _default_peb_root()
	return normpath(joinpath(@__DIR__, "..", "..", "..", "..", "..",
		"ParameterEstimationBenchmark-local"))
end

_sha256_file(path::AbstractString) = bytes2hex(sha256(read(path)))

function _require_frozen_file(root::AbstractString, relative_path::AbstractString,
		expected_sha256::AbstractString)
	path = joinpath(root, relative_path)
	isfile(path) || throw(ArgumentError("missing frozen PEB artifact: $path"))
	actual = _sha256_file(path)
	actual == expected_sha256 || throw(ArgumentError(
		"PEB artifact hash mismatch for $path: expected $expected_sha256, got $actual"))
	return path
end

function _peb_paths(peb_root::AbstractString, case_id::String, case)
	model_instance = "$(case.model)_$(case.instance)"
	generator = _require_frozen_file(peb_root,
		joinpath(PEB_SNAPSHOT, "filetree", "data_generation", "$model_instance.jl"),
		case.generator_sha256)
	data = _require_frozen_file(peb_root,
		joinpath(PEB_RESULTS_SNAPSHOT, "results", "data_noisy", case_id, "data.csv"),
		case.data_sha256)
	metadata = _require_frozen_file(peb_root,
		joinpath(PEB_RESULTS_SNAPSHOT, "results", case.historical_run, case_id,
			"odepe_metadata.json"), case.metadata_sha256)
	return (; generator, data, metadata)
end

function _even_row_indices(n_rows::Int, max_observations::Int)
	(max_observations <= 0 || max_observations >= n_rows) && return collect(1:n_rows)
	max_observations >= 2 || throw(ArgumentError("max-observations must be 0 or at least 2"))
	indices = unique(round.(Int, range(1, n_rows; length = max_observations)))
	length(indices) == max_observations || throw(ArgumentError(
		"could not choose $max_observations unique rows from $n_rows observations"))
	return indices
end

function _peb_data_sample(path::AbstractString, mq, max_observations::Int)
	matrix = Matrix{Float64}(readdlm(path, ',', Float64))
	size(matrix, 2) == length(mq) + 1 || throw(ArgumentError(
		"$path has $(size(matrix, 2)) columns; expected $(length(mq) + 1)"))
	rows = _even_row_indices(size(matrix, 1), max_observations)
	data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
	data_sample["t"] = collect(matrix[rows, 1])
	for (column, equation) in enumerate(mq)
		data_sample[Num(equation.rhs)] = collect(matrix[rows, column + 1])
	end
	return data_sample, rows, size(matrix, 1)
end

function _peb_lotka_volterra(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters k1 k2 k3
	states = @variables r(t) w(t)
	observables = @variables y1(t)
	equations = [
		D(r) ~ 2.0 * k1 * r - 2.0 * k2 * w * r,
		D(w) ~ -0.6 * k3 * w + 4.0 * k2 * w * r,
	]
	measured_quantities = [y1 ~ 4.0 * r]
	model, mq = create_ordered_ode_system(
		"lotka_volterra", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"lotka_volterra", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_vanderpol(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters a b
	states = @variables x1(t) x2(t)
	observables = @variables y1(t) y2(t)
	equations = [
		D(x1) ~ 0.5 * a * x2,
		D(x2) ~ -4.0 * x1 + 2.0 * b * x2 - 32.0 * b * x2 * x1^2,
	]
	measured_quantities = [y1 ~ 4.0 * x1, y2 ~ x2]
	model, mq = create_ordered_ode_system(
		"vanderpol", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"vanderpol", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_fitzhugh_nagumo(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters g a b
	states = @variables Vm(t) R(t)
	observables = @variables y1(t)
	equations = [
		D(Vm) ~ (-3.0) * g * (0.5 * R - 2.0 * Vm + (8.0 / 3.0) * Vm^3),
		D(R) ~ (-0.4 * a - 2.0 * Vm + 0.2 * b * R) / (3.0 * g),
	]
	measured_quantities = [y1 ~ -2.0 * Vm]
	model, mq = create_ordered_ode_system(
		"fitzhugh_nagumo", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"fitzhugh_nagumo", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_problem(case, data_path::AbstractString, max_observations::Int)
	case.model == :lotka_volterra && return _peb_lotka_volterra(case, data_path, max_observations)
	case.model == :vanderpol && return _peb_vanderpol(case, data_path, max_observations)
	case.model == :fitzhugh_nagumo && return _peb_fitzhugh_nagumo(case, data_path, max_observations)
	throw(ArgumentError("unsupported audited model $(case.model)"))
end

function _peb_output_path(out_dir::String, case_id::String, arm::String,
		max_observations::Int, interpolator_pool::String)
	row_token = max_observations <= 0 ? "full" : "n$(max_observations)"
	return joinpath(out_dir,
		"$(case_id)__$(row_token)__$(interpolator_pool)__$(arm).toml")
end

function _historical_interpolator(method::Symbol)
	method == :s3_adapt_se && return InterpolatorS3AdaptSE
	method == :s3_adapt_rq && return InterpolatorS3AdaptRQ
	method == :aaad_gpr && return InterpolatorAAADGPR
	method == :agp_robust_rq && return InterpolatorAGPRobustRQ
	throw(ArgumentError("no InterpolatorMethod mapping for historical source $method"))
end

function _peb_arm_options(case, arm::String, shooting_points::Int, max_pairs::Int,
		interpolator_pool::String)
	extra = _arm_options(arm, shooting_points, max_pairs)
	if interpolator_pool == "uq_only"
		return extra
	elseif interpolator_pool == "historical_plus_uq"
		historical = _historical_interpolator(case.historical_interpolator)
		methods = historical == InterpolatorAGPUQ ?
			InterpolatorMethod[InterpolatorAGPUQ] :
			InterpolatorMethod[historical, InterpolatorAGPUQ]
		return (; extra..., interpolator = first(methods), interpolators = methods,
			auto_filter_interpolators = false)
	end
	throw(ArgumentError(
		"unknown interpolator-pool '$interpolator_pool'; use historical_plus_uq or uq_only"))
end

function _record_peb_result!(payload::Dict{String, Any}, pep, raw, analysis, uq)
	payload["raw_candidate_count"] = isempty(raw) ? 0 : length(raw[1])
	payload["returned_candidate_count"] = length(analysis.returned_results)
	if isempty(analysis.returned_results)
		payload["outcome"] = "no_estimate"
		payload["message"] = "analysis.returned_results was empty"
		return payload
	end

	selected = first(analysis.returned_results)
	identity = selected.provenance.estimator_identity
	payload["selected_fit_error"] = isnothing(selected.err) ? Inf : Float64(selected.err)
	payload["selected_identity"] = _identity_dict(identity)
	payload["coordinates"] = _coordinate_records(pep, selected, uq)
	payload["candidate_diagnostics"] = _candidate_records(
		pep, isempty(raw) ? Any[] : raw[1], identity.candidate_id)

	if uq isa UncertaintyReport
		payload["outcome"] = "report"
		payload["uq_status"] = string(uq.status)
		payload["max_cv"] = uq.max_cv
		payload["artifact_match"] = isnothing(uq.target) ? "" : string(uq.target.artifact_match)
		payload["lineage"] = isnothing(uq.target) ? Dict{String, Any}[] :
			[_identity_dict(item) for item in uq.target.lineage]
		diagnostics = uq.linearization_diagnostics
		payload["linearization"] = Dict{String, Any}(
			"reason" => string(diagnostics.reason),
			"root_residual_abs" => diagnostics.root_residual_abs,
			"root_residual_rel" => diagnostics.root_residual_rel,
			"jacobian_condition" => diagnostics.jacobian_condition,
			"gradient_norm" => diagnostics.gradient_norm,
			"active_bounds" => diagnostics.active_bounds,
			"degraded" => diagnostics.degraded,
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

function _run_peb_canary(case_id::String, case, arm::String;
		peb_root::String, out_dir::String, max_observations::Int,
		shooting_points::Int, max_pairs::Int, interpolator_pool::String, force::Bool)
	path = _peb_output_path(out_dir, case_id, arm, max_observations, interpolator_pool)
	if isfile(path) && !force
		println("SKIP completed: ", basename(path))
		return TOML.parsefile(path)
	end

	paths = _peb_paths(peb_root, case_id, case)
	pep, rows, original_rows = _peb_problem(case, paths.data, max_observations)
	extra = _peb_arm_options(case, arm, shooting_points, max_pairs, interpolator_pool)
	n_unknowns = length(case.p_true) + length(case.ic)
	opts = EstimationOptions(;
		datasize = length(rows),
		time_interval = case.time_interval,
		noise_level = case.noise,
		nooutput = true,
		diagnostics = false,
		shooting_warp = true,
		shooting_warp_beta = 3.0,
		use_parameter_homotopy = true,
		opt_lb = fill(1e-5, n_unknowns),
		opt_ub = fill(10.0, n_unknowns),
		extra...,
	)

	payload = Dict{String, Any}(
		"schema_version" => 1,
		"source" => "PEB audited paper snapshot",
		"peb_frozen_sha" => PEB_FROZEN_SHA,
		"peb_snapshot" => PEB_SNAPSHOT,
		"case_id" => case_id,
		"model" => string(case.model),
		"noise" => case.noise,
		"arm" => arm,
		"shooting_points" => shooting_points,
		"multipoint_max_pairs" => max_pairs,
		"interpolator_pool" => interpolator_pool,
		"replicate" => case.instance,
		"time_interval" => case.time_interval,
		"original_observations" => original_rows,
		"used_observations" => length(rows),
		"selected_source_rows" => rows,
		"data_sha256" => case.data_sha256,
		"generator_sha256" => case.generator_sha256,
		"metadata_sha256" => case.metadata_sha256,
		"historical_kind" => string(case.historical_kind),
		"historical_run" => case.historical_run,
		"historical_time_indices" => case.historical_time_indices,
		"historical_interpolator" => string(case.historical_interpolator),
		"historical_max_error" => case.historical_max_error,
		"started_at" => string(now()),
	)

	println("RUN  case=$case_id historical=$(case.historical_kind) arm=$arm " *
		"pool=$interpolator_pool rows=$(length(rows))/$original_rows")
	flush(stdout)
	started = time()
	try
		raw, analysis, uq = _cov_quiet() do
			ODEParameterEstimation.analyze_parameter_estimation_problem(deepcopy(pep), opts)
		end
		payload["elapsed_seconds"] = time() - started
		_record_peb_result!(payload, pep, raw, analysis, uq)
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

function _print_peb_summary(payloads)
	println("\n", "="^126)
	println("AUDITED PEB ESTIMATOR/UQ CANARIES")
	println("="^126)
	@printf("%-29s %-18s %-22s %-22s %-15s %-11s %-9s\n",
		"case", "arm", "historical seed", "selected estimator", "UQ outcome",
		"worst err", "seconds")
	for payload in payloads
		identity = get(payload, "selected_identity", Dict{String, Any}())
		coordinates = get(payload, "coordinates", Dict{String, Any}[])
		worst_error = _finite_max(Float64[
			Float64(get(row, "relative_error", Inf)) for row in coordinates])
		@printf("%-29s %-18s %-22s %-22s %-15s %-11.3g %-9.1f\n",
			payload["case_id"], payload["arm"], payload["historical_kind"],
			get(identity, "estimator_kind", "—"), get(payload, "outcome", "—"),
			worst_error, get(payload, "elapsed_seconds", NaN))
	end
	println("="^126)
	return nothing
end

function main_peb_canaries()
	case_ids = _campaign_list("cases",
		"lotka_volterra_2_1em4,vanderpol_2_1em4,fitzhugh_nagumo_1_1em4")
	unknown = setdiff(case_ids, collect(keys(PEB_AUDITED_CASES)))
	isempty(unknown) || throw(ArgumentError("unknown audited cases: $(join(unknown, ", "))"))
	arms = _campaign_list("arms", "mp_polish")
	max_observations = parse(Int, _campaign_arg("max-observations", "0"))
	shooting_points = parse(Int, _campaign_arg("shooting-points", "20"))
	max_pairs = parse(Int, _campaign_arg("max-pairs", "15"))
	interpolator_pool = _campaign_arg("interpolator-pool", "historical_plus_uq")
	force = lowercase(_campaign_arg("force", "false")) in ("true", "yes", "1")
	peb_root = normpath(_campaign_arg("peb-root", _default_peb_root()))
	out_name = _campaign_arg("out", "peb_audited_canaries_$(Dates.format(now(), "yyyymmdd_HHMMSS"))")
	out_dir = isabspath(out_name) ? out_name : joinpath(@__DIR__, "results", out_name)
	mkpath(out_dir)

	println("PEB root: ", peb_root)
	println("Output: ", out_dir)
	println("Cases: ", join(case_ids, ", "), " | arms: ", join(arms, ", "),
		" | pool: ", interpolator_pool, " | max observations: ", max_observations)
	payloads = Dict{String, Any}[]
	for case_id in case_ids, arm in arms
		push!(payloads, _run_peb_canary(case_id, PEB_AUDITED_CASES[case_id], arm;
			peb_root, out_dir, max_observations, shooting_points, max_pairs,
			interpolator_pool, force))
	end
	_print_peb_summary(payloads)
	println("Results saved under ", out_dir)
	return payloads
end

if abspath(PROGRAM_FILE) == @__FILE__
	main_peb_canaries()
end
