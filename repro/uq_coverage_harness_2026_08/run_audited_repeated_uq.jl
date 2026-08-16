# Repeated-noise estimator-aware UQ on hash-pinned PEB paper models.
#
# Unlike the historical package-constructor coverage runner, this driver reads
# the audited benchmark equations/truth/grid and the frozen clean trajectory.
# Each master seed generates one case-order-independent data set that is reused
# verbatim by every requested arm and lengthscale factor.

include(joinpath(@__DIR__, "run_estimator_aware_peb_canaries.jl"))

using SHA

const AUDITED_REPEATED_SCHEMA_VERSION = 2
const AUDITED_REPEATED_MANIFEST_ID = "odepe_uq_campaign_2026_08_v1"
const AUDITED_REPEATED_ROOT = normpath(joinpath(@__DIR__, "..", ".."))

struct AuditedCampaignContractError <: Exception
	message::String
end
Base.showerror(io::IO, err::AuditedCampaignContractError) = print(io, err.message)

function _aruq_bool_arg(name::String, default::Bool)
	fallback = default ? "true" : "false"
	return lowercase(_campaign_arg(name, fallback)) in ("true", "yes", "1")
end

function _aruq_master_seeds()
	explicit = _campaign_list("seeds", "")
	!isempty(explicit) && return parse.(Int, explicit)
	seed_start = parse(Int, _campaign_arg("seed-start", "8164101"))
	replicates = parse(Int, _campaign_arg("replicates", "3"))
	replicates > 0 || throw(ArgumentError("replicates must be positive"))
	return collect(seed_start:(seed_start + replicates - 1))
end

function _aruq_cell_seed(case_id::String, master_seed::Int)::UInt64
	payload = "$AUDITED_REPEATED_MANIFEST_ID|$case_id|$master_seed"
	digest = bytes2hex(sha256(payload))
	return parse(UInt64, digest[1:16]; base = 16)
end

function _aruq_data_sha256(data::AbstractDict)::String
	buffer = IOBuffer()
	for (key, values) in data
		write(buffer, string(key))
		write(buffer, UInt8(0))
		for value in Float64.(values)
			write(buffer, reinterpret(UInt8, [value]))
		end
	end
	return bytes2hex(sha256(take!(buffer)))
end

function _aruq_problem(
	case_id::String,
	case,
	paths,
	master_seed::Int,
	noise::Float64,
	data_source::String,
)
	if data_source == "frozen_noisy"
		noise == Float64(case.noise) || throw(ArgumentError(
			"frozen_noisy requires the catalog noise $(case.noise) for $case_id; got $noise",
		))
		problem, rows, original_rows = _peb_problem(case, paths.data, 0)
		original_rows == 750 || throw(ArgumentError(
			"$case_id frozen benchmark has $original_rows rows; expected 750",
		))
		return problem, rows, nothing, Dict{String, Float64}(), case.data_sha256
	elseif data_source != "synthetic"
		throw(ArgumentError(
			"unknown data-source '$data_source'; use frozen_noisy or synthetic",
		))
	end
	clean_problem, rows, original_rows = _peb_problem(case, paths.original_data, 0)
	original_rows == 750 || throw(ArgumentError(
		"$case_id clean benchmark has $original_rows rows; expected 750",
	))
	cell_seed = _aruq_cell_seed(case_id, master_seed)
	rng = MersenneTwister(cell_seed)
	noisy_data = deepcopy(clean_problem.data_sample)
	noise_scales = Dict{String, Float64}()
	for (key, clean_values) in clean_problem.data_sample
		key == "t" && continue
		# This deliberately mirrors PEB generate_data.py, including its signed
		# per-observable mean. A negative mean reverses the normal draw but leaves
		# its distribution unchanged; a zero mean produces the historical zero-noise
		# channel rather than silently substituting a different scale.
		scale = noise * mean(Float64.(clean_values))
		noisy_data[key] = Float64.(clean_values) .+ scale .* randn(rng, length(clean_values))
		noise_scales[string(key)] = Float64(scale)
	end
	problem = ParameterEstimationProblem(
		"$(case_id)_seed_$(master_seed)",
		clean_problem.model,
		clean_problem.measured_quantities,
		noisy_data,
		case.time_interval,
		clean_problem.solver,
		clean_problem.p_true,
		clean_problem.ic,
		clean_problem.unident_count,
	)
	return problem, rows, cell_seed, noise_scales, _aruq_data_sha256(noisy_data)
end

function _aruq_recipe()
	sp_raw = strip(_campaign_arg("fixed-sp-row", ""))
	mp_raw = strip(_campaign_arg("fixed-mp-rows", ""))
	!isempty(sp_raw) && !isempty(mp_raw) && throw(ArgumentError(
		"fixed-sp-row and fixed-mp-rows are mutually exclusive",
	))
	interp_raw = strip(_campaign_arg("fixed-interpolator", ""))
	interp = isempty(interp_raw) ? nothing : Symbol(interp_raw)
	if !isempty(sp_raw)
		return ODEParameterEstimation.FixedSinglePointRecipe(
			parse(Int, sp_raw); interpolator_source = interp,
		)
	elseif !isempty(mp_raw)
		rows = parse.(Int, filter(!isempty, strip.(split(mp_raw, ','))))
		return ODEParameterEstimation.FixedMultipointRecipe(
			rows; interpolator_source = interp,
		)
	elseif !isnothing(interp)
		throw(ArgumentError("fixed-interpolator requires a fixed point recipe"))
	end
	return nothing
end

function _aruq_recipe_dict(recipe)
	isnothing(recipe) && return Dict{String, Any}("kind" => "adaptive")
	if recipe isa ODEParameterEstimation.FixedSinglePointRecipe
		return Dict{String, Any}(
			"kind" => "fixed_single_point",
			"rows" => [recipe.row],
			"interpolator_source" => isnothing(recipe.interpolator_source) ? "" :
				string(recipe.interpolator_source),
		)
	end
	return Dict{String, Any}(
		"kind" => "fixed_multipoint",
		"rows" => copy(recipe.rows),
		"interpolator_source" => isnothing(recipe.interpolator_source) ? "" :
			string(recipe.interpolator_source),
	)
end

function _aruq_git_commit()
	return try
		readchomp(`git -C $AUDITED_REPEATED_ROOT rev-parse HEAD`)
	catch
		"unknown"
	end
end

function _aruq_repository_status()
	return try
		readchomp(`git -C $AUDITED_REPEATED_ROOT status --porcelain=v1 --untracked-files=all`)
	catch
		"repository-status-unavailable"
	end
end

function _aruq_repository_state_sha256()::String
	status = _aruq_repository_status()
	return isempty(status) ? "clean" : bytes2hex(sha256(status))
end

function _aruq_config(
	case_id::String,
	arm::String,
	pool::String,
	data_source::String,
	noise::Float64,
	master_seed::Int,
	shooting_points::Int,
	max_pairs::Int,
	pair_strategy::Symbol,
	lengthscale_factor::Float64,
	recipe,
)
	return Dict{String, Any}(
		"manifest_id" => AUDITED_REPEATED_MANIFEST_ID,
		"case_id" => case_id,
		"arm" => arm,
		"interpolator_pool" => pool,
		"data_source" => data_source,
		"noise" => noise,
		"master_seed" => master_seed,
		"shooting_points" => shooting_points,
		"multipoint_max_pairs" => max_pairs,
		"multipoint_pair_strategy" => string(pair_strategy),
		"gp_derivative_lengthscale_factor" => lengthscale_factor,
		"selection_recipe" => _aruq_recipe_dict(recipe),
		"observations" => 750,
		"odepe_commit" => _aruq_git_commit(),
		"odepe_repository_state_sha256" => _aruq_repository_state_sha256(),
		"peb_frozen_sha" => PEB_FROZEN_SHA,
	)
end

function _aruq_config_fingerprint(config::Dict{String, Any})::String
	buffer = IOBuffer()
	TOML.print(buffer, config; sorted = true)
	return bytes2hex(sha256(take!(buffer)))
end

function _aruq_output_path(out_dir::String, config::Dict{String, Any}, fingerprint::String)
	name = "$(config["case_id"])__seed_$(config["master_seed"])__$(config["arm"])" *
		"__$(config["interpolator_pool"])__$(fingerprint[1:12]).toml"
	return joinpath(out_dir, name)
end

_aruq_failed_outcome(outcome::AbstractString) = outcome in (
	"error", "no_estimate", "uq_unavailable", "uq_disabled_unexpectedly",
	"unknown_uq_outcome", "timeout", "rss_limit", "worker_error",
	"orphaned_process_tree", "process_tree_survived_kill",
)

function _aruq_existing_record(
	path::String,
	fingerprint::String;
	force::Bool,
	retry_failures::Bool,
)
	isfile(path) || return nothing
	force && return nothing
	record = TOML.parsefile(path)
	get(record, "config_fingerprint", "") == fingerprint || throw(ArgumentError(
		"resume fingerprint mismatch for $path",
	))
	if retry_failures && _aruq_failed_outcome(string(get(record, "outcome", "")))
		return nothing
	end
	println("SKIP exact completed record: ", basename(path))
	return record
end

function _aruq_record_result!(payload::Dict{String, Any}, pep, raw, analysis, uq;
		detailed::Bool, recipe)
	_record_peb_result!(payload, pep, raw, analysis, uq)
	detailed || pop!(payload, "candidate_diagnostics", nothing)
	if !isempty(analysis.returned_results)
		identity = first(analysis.returned_results).provenance.estimator_identity
		if recipe isa ODEParameterEstimation.FixedSinglePointRecipe
			identity.estimator_kind == :single_point_algebraic ||
				throw(AuditedCampaignContractError(
					"fixed-SP cell returned estimator kind $(identity.estimator_kind)",
				))
			identity.time_indices == [recipe.row] ||
				throw(AuditedCampaignContractError(
					"fixed-SP cell returned rows $(identity.time_indices), expected $([recipe.row])",
				))
		elseif recipe isa ODEParameterEstimation.FixedMultipointRecipe
			identity.estimator_kind == :multipoint_algebraic ||
				throw(AuditedCampaignContractError(
					"fixed-MP cell returned estimator kind $(identity.estimator_kind)",
				))
			identity.time_indices == recipe.rows ||
				throw(AuditedCampaignContractError(
					"fixed-MP cell returned rows $(identity.time_indices), expected $(recipe.rows)",
				))
		end
		if !isnothing(recipe) && !isnothing(recipe.interpolator_source)
			identity.interpolator_source == recipe.interpolator_source ||
				throw(AuditedCampaignContractError(
					"fixed cell returned interpolator $(identity.interpolator_source), expected $(recipe.interpolator_source)",
				))
		end
	end
	if uq isa UncertaintyReport
		isnothing(uq.target) && throw(AuditedCampaignContractError(
			"UQ report has no selected-estimator target",
		))
		selected_id = first(analysis.returned_results).provenance.estimator_identity.candidate_id
		uq.target.identity.candidate_id == selected_id ||
			throw(AuditedCampaignContractError(
				"UQ target candidate $(uq.target.identity.candidate_id) differs from returned rank-one candidate $selected_id",
			))
		uq.target.artifact_match == :exact || throw(AuditedCampaignContractError(
			"UQ artifact match is $(uq.target.artifact_match), expected :exact",
		))
	elseif uq isa UQUnavailable && uq.reason in (
		:missing_artifact, :artifact_mismatch, :identity_mismatch,
	)
		throw(AuditedCampaignContractError(
			"selected-estimator UQ contract failed [$(uq.reason)]: $(uq.message)",
		))
	end
	if haskey(payload, "coordinates")
		unidentifiable = Set(String.(get(payload, "unidentifiable_labels", String[])))
		for coordinate in payload["coordinates"]
			coordinate["identifiable"] = !(String(coordinate["label"]) in unidentifiable)
		end
	end
	return payload
end

function _aruq_run_cell(
	case_id::String,
	case,
	arm::String,
	pool::String,
	master_seed::Int;
	peb_root::String,
	out_dir::String,
	data_source::String,
	noise::Float64,
	shooting_points::Int,
	max_pairs::Int,
	pair_strategy::Symbol,
	lengthscale_factor::Float64,
	recipe,
	force::Bool,
	retry_failures::Bool,
	detailed::Bool,
	path_override::Union{Nothing, String} = nothing,
)
	config = _aruq_config(
		case_id, arm, pool, data_source, noise, master_seed, shooting_points, max_pairs,
		pair_strategy, lengthscale_factor, recipe,
	)
	fingerprint = _aruq_config_fingerprint(config)
	path = isnothing(path_override) ? _aruq_output_path(out_dir, config, fingerprint) :
		normpath(path_override)
	existing = _aruq_existing_record(
		path, fingerprint; force, retry_failures,
	)
	!isnothing(existing) && return existing
	payload = Dict{String, Any}(
		"schema_version" => AUDITED_REPEATED_SCHEMA_VERSION,
		"source" => data_source == "synthetic" ?
			"PEB audited clean trajectory + paired synthetic noise" :
			"PEB audited frozen noisy paper cell",
		"config" => config,
		"config_fingerprint" => fingerprint,
		"case_id" => case_id,
		"model" => string(case.model),
		"noise" => noise,
		"arm" => arm,
		"interpolator_pool" => pool,
		"data_source" => data_source,
		"master_seed" => master_seed,
		"cell_seed_uint64" => "",
		"generated_data_sha256" => "",
		"noise_scales" => Dict{String, Float64}(),
		"selection_recipe" => _aruq_recipe_dict(recipe),
		"unidentifiable_labels" => hasproperty(case, :unidentifiable_labels) ?
			copy(case.unidentifiable_labels) : String[],
		"original_data_sha256" => case.original_data_sha256,
		"generator_sha256" => case.generator_sha256,
		"peb_frozen_sha" => PEB_FROZEN_SHA,
		"historical_kind" => string(case.historical_kind),
		"historical_run" => case.historical_run,
		"historical_time_indices" => copy(case.historical_time_indices),
		"historical_interpolator" => string(case.historical_interpolator),
		"historical_fit_error" => case.historical_max_error,
		"historical_coordinate_max_rel_error" =>
			hasproperty(case, :historical_coordinate_max_rel_error) ?
				case.historical_coordinate_max_rel_error : case.historical_max_error,
		"odepe_commit" => config["odepe_commit"],
		"odepe_repository_state_sha256" => config["odepe_repository_state_sha256"],
		"julia_version" => string(VERSION),
		"julia_threads" => Threads.nthreads(),
		"started_at" => string(now()),
		"outcome" => "running",
	)

	# This pre-estimation record is deliberate: the process-tree supervisor can
	# turn it into a timeout/resource-limit outcome if the worker is killed, so
	# failed cells remain in the unconditional availability denominator.
	_atomic_toml(path, payload)

	paths = _peb_paths(peb_root, case_id, case)
	pep, rows, cell_seed, noise_scales, generated_hash = _aruq_problem(
		case_id, case, paths, master_seed, noise, data_source,
	)
	extra = _peb_arm_options(
		case, arm, shooting_points, max_pairs, pool;
		pair_strategy, lengthscale_factor,
	)
	n_unknowns = length(case.p_true) + length(case.ic)
	opts = EstimationOptions(;
		datasize = length(rows),
		time_interval = case.time_interval,
		noise_level = noise,
		nooutput = true,
		diagnostics = false,
		shooting_warp = true,
		shooting_warp_beta = 3.0,
		use_parameter_homotopy = true,
		opt_lb = fill(1e-5, n_unknowns),
		opt_ub = fill(10.0, n_unknowns),
		extra...,
	)
	payload["cell_seed_uint64"] = isnothing(cell_seed) ? "" : string(cell_seed)
	payload["generated_data_sha256"] = generated_hash
	payload["noise_scales"] = noise_scales
	payload["hc_threading"] = opts.hc_threading
	payload["hc_compile_mode"] = string(opts.hc_compile_mode)
	_atomic_toml(path, payload)
	println("RUN  case=$case_id seed=$master_seed arm=$arm pool=$pool noise=$noise")
	flush(stdout)
	started = time()
	try
		(value, context) = _cov_quiet() do
			ODEParameterEstimation._with_run_context(
				capture_timing = true,
				selection_recipe = recipe,
			) do
				ODEParameterEstimation.analyze_parameter_estimation_problem(
					deepcopy(pep), opts,
				)
			end
		end
		raw, analysis, uq = value
		payload["elapsed_seconds"] = time() - started
		payload["max_rss_bytes"] = Sys.maxrss()
		payload["structured_timing"] = timing_breakdown_to_dict(context.timing)
		_aruq_record_result!(payload, pep, raw, analysis, uq; detailed, recipe)
	catch err
		err isa InterruptException && rethrow()
		payload["elapsed_seconds"] = time() - started
		payload["outcome"] = "error"
		payload["message"] = sprint(showerror, err, catch_backtrace())
		payload["contract_failure"] = err isa AuditedCampaignContractError
	end
	payload["completed_at"] = string(now())
	_atomic_toml(path, payload)
	println("DONE ", basename(path), " outcome=", payload["outcome"],
		" elapsed=", round(payload["elapsed_seconds"]; digits = 1), "s")
	flush(stdout)
	get(payload, "contract_failure", false) === true &&
		throw(AuditedCampaignContractError(String(payload["message"])))
	return payload
end

function main_audited_repeated_uq()
	case_ids = _campaign_list("cases", "daisy_mamil4_7_1em6,receptor_binding_5_1em6")
	unknown = setdiff(case_ids, collect(keys(PEB_AUDITED_CASES)))
	isempty(unknown) || throw(ArgumentError("unknown audited cases: $(join(unknown, ", "))"))
	arms = _campaign_list("arms", "mp_solver_polish")
	pools = _campaign_list("interpolator-pools", "uq_only")
	seeds = _aruq_master_seeds()
	data_source = _campaign_arg("data-source", "synthetic")
	noise_arg = strip(_campaign_arg("noise", "case"))
	shooting_points = parse(Int, _campaign_arg("shooting-points", "20"))
	max_pairs = parse(Int, _campaign_arg("max-pairs", "15"))
	pair_strategy = Symbol(_campaign_arg("pair-strategy", "spread"))
	lengthscales = _campaign_float_list("lengthscale-factors", "1.0")
	recipe = _aruq_recipe()
	force = _aruq_bool_arg("force", false)
	retry_failures = _aruq_bool_arg("retry-failures", false)
	detailed = _aruq_bool_arg("detailed", false)
	allow_dirty = _aruq_bool_arg("allow-dirty", false)
	validate_only = _aruq_bool_arg("validate-only", false)
	peb_root = normpath(_campaign_arg("peb-root", _default_peb_root()))
	_validate_peb_catalog(peb_root, case_ids)
	if validate_only
		for case_id in case_ids
			case = PEB_AUDITED_CASES[case_id]
			noise = noise_arg == "case" ? Float64(case.noise) : parse(Float64, noise_arg)
			paths = _peb_paths(peb_root, case_id, case)
			for seed in seeds
				_, rows, _, _, data_hash = _aruq_problem(
					case_id, case, paths, seed, noise, data_source,
				)
				length(rows) == 750 || throw(ArgumentError(
					"$case_id generated row count is $(length(rows)), expected 750",
				))
				println("VALID REPEATED $case_id source=$data_source seed=$seed data_sha256=$data_hash")
			end
		end
		return nothing
	end
	out_name = _campaign_arg(
		"out", "audited_repeated_uq_$(Dates.format(now(), "yyyymmdd_HHMMSS"))",
	)
	out_dir = isabspath(out_name) ? out_name : joinpath(@__DIR__, "results", out_name)
	mkpath(out_dir)
	status = _aruq_repository_status()
	allow_dirty || isempty(status) || throw(ArgumentError(
		"audited repeated-UQ runs require a clean ODEPE worktree; commit/stash changes or pass --allow-dirty=true for a non-scientific smoke",
	))
	path_override_raw = strip(_campaign_arg("cell-record-path", ""))
	path_override = isempty(path_override_raw) ? nothing : abspath(path_override_raw)
	n_cells = length(case_ids) * length(seeds) * length(pools) * length(arms) *
		length(lengthscales)
	!isnothing(path_override) && n_cells != 1 && throw(ArgumentError(
		"cell-record-path requires exactly one case/seed/pool/arm/lengthscale cell",
	))

	payloads = Dict{String, Any}[]
	for case_id in case_ids
		case = PEB_AUDITED_CASES[case_id]
		noise = noise_arg == "case" ? Float64(case.noise) : parse(Float64, noise_arg)
		for seed in seeds, pool in pools, arm in arms, factor in lengthscales
			push!(payloads, _aruq_run_cell(
				case_id, case, arm, pool, seed;
				peb_root, out_dir, data_source, noise, shooting_points, max_pairs,
				pair_strategy, lengthscale_factor = factor, recipe,
				force, retry_failures, detailed, path_override,
			))
		end
	end
	_print_peb_summary(payloads)
	println("Results saved under ", out_dir)
	return payloads
end

if abspath(PROGRAM_FILE) == @__FILE__
	main_audited_repeated_uq()
end
