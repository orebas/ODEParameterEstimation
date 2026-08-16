# Linux process-tree supervisor for the audited repeated-noise UQ campaign.
#
# Each scientific cell runs in its own `setsid` process group. The supervisor
# samples aggregate group RSS, enforces a wall limit, and always performs a
# TERM -> bounded grace -> KILL -> verified-empty sequence when a limit is hit.
# The worker writes a schema-v2 `running` record before estimation; this file
# is converted into a typed failure record so timeouts and resource failures
# remain in unconditional availability denominators.

using Dates
using SHA
using TOML

isdefined(@__MODULE__, :_atomic_toml) ||
	include(joinpath(@__DIR__, "campaign_io.jl"))

const AUDITED_SUPERVISOR_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const AUDITED_SUPERVISOR_RUNNER = joinpath(@__DIR__, "run_audited_repeated_uq.jl")

function _asu_arg(name::String, default::String)
	prefix = "--$(name)="
	index = findfirst(arg -> startswith(arg, prefix), ARGS)
	return isnothing(index) ? default : ARGS[index][(length(prefix) + 1):end]
end

_asu_list(name::String, default::String) =
	String.(filter(!isempty, strip.(split(_asu_arg(name, default), ','))))

function _asu_seeds()
	explicit = _asu_list("seeds", "")
	!isempty(explicit) && return parse.(Int, explicit)
	first_seed = parse(Int, _asu_arg("seed-start", "8164101"))
	replicates = parse(Int, _asu_arg("replicates", "3"))
	replicates > 0 || throw(ArgumentError("replicates must be positive"))
	return collect(first_seed:(first_seed + replicates - 1))
end

_asu_bool(name::String, default::Bool = false) = lowercase(
	_asu_arg(name, default ? "true" : "false"),
) in ("true", "yes", "1")

function _asu_safe_token(value)::String
	return replace(string(value), r"[^A-Za-z0-9_.-]" => "_")
end

function _asu_git_state_token()::String
	commit = try
		readchomp(`git -C $AUDITED_SUPERVISOR_ROOT rev-parse HEAD`)
	catch
		"unknown"
	end
	status = try
		readchomp(`git -C $AUDITED_SUPERVISOR_ROOT status --porcelain=v1 --untracked-files=all`)
	catch
		"status-unavailable"
	end
	return bytes2hex(sha256("$commit\0$status"))
end

const _ASU_MATRIX_ARGUMENTS = Set([
	"cases", "arms", "interpolator-pools", "seeds", "seed-start",
	"replicates", "lengthscale-factors", "out", "cell-record-path",
])
const _ASU_ONLY_ARGUMENTS = Set([
	"cell-wall-limit-seconds", "cell-rss-limit-bytes", "machine-hour-budget",
	"term-grace-seconds", "kill-grace-seconds", "poll-seconds",
])

function _asu_argument_name(arg::String)
	starts_with_option = startswith(arg, "--")
	starts_with_option || return ""
	body = arg[3:end]
	equals = findfirst(==('='), body)
	return isnothing(equals) ? body : body[1:(equals - 1)]
end

function _asu_forwarded_args(args::Vector{String})
	return [arg for arg in args if begin
		name = _asu_argument_name(arg)
		!(name in _ASU_MATRIX_ARGUMENTS) && !(name in _ASU_ONLY_ARGUMENTS)
	end]
end

function _asu_cells()
	cases = _asu_list("cases", "daisy_mamil4_7_1em6,receptor_binding_5_1em6")
	arms = _asu_list("arms", "mp_solver_polish")
	pools = _asu_list("interpolator-pools", "uq_only")
	seeds = _asu_seeds()
	factors = parse.(Float64, _asu_list("lengthscale-factors", "1.0"))
	return [
		(case_id = case_id, arm = arm, pool = pool, seed = seed, factor = factor)
		for case_id in cases for seed in seeds for pool in pools for arm in arms
		for factor in factors
	]
end

function _asu_cell_digest(cell, forwarded::Vector{String})::String
	parts = sort(vcat(
		forwarded,
		[
			"case=$(cell.case_id)", "arm=$(cell.arm)", "pool=$(cell.pool)",
			"seed=$(cell.seed)", "factor=$(cell.factor)",
			"git-state=$(_asu_git_state_token())",
		],
	))
	return bytes2hex(sha256(join(parts, '\0')))
end

function _asu_cell_record_path(out_dir::String, cell, digest::String)
	stem = join((
		"cell", _asu_safe_token(cell.case_id), "seed_$(cell.seed)",
		_asu_safe_token(cell.arm), _asu_safe_token(cell.pool),
		"ls_$(_asu_safe_token(cell.factor))", digest[1:12],
	), "__")
	return joinpath(out_dir, "$stem.toml")
end

function _asu_proc_group_state(pid::Integer)
	path = "/proc/$pid/stat"
	isfile(path) || return nothing
	text = try
		read(path, String)
	catch
		return nothing
	end
	closing = findlast(==(')'), text)
	isnothing(closing) && return nothing
	fields = split(strip(text[nextind(text, closing):end]))
	length(fields) >= 3 || return nothing
	pgrp = tryparse(Int, fields[3])
	isnothing(pgrp) && return nothing
	return (; pgrp, state = only(fields[1]))
end

function _asu_proc_group(pid::Integer)::Union{Nothing, Int}
	info = _asu_proc_group_state(pid)
	return isnothing(info) ? nothing : info.pgrp
end

function _asu_proc_rss_bytes(pid::Integer)::Int
	path = "/proc/$pid/status"
	isfile(path) || return 0
	try
		for line in eachline(path)
			startswith(line, "VmRSS:") || continue
			fields = split(line)
			length(fields) >= 2 || return 0
			return something(tryparse(Int, fields[2]), 0) * 1024
		end
	catch
		return 0
	end
	return 0
end

function _asu_process_group_snapshot(pgid::Integer)
	members = Int[]
	rss_bytes = 0
	for entry in readdir("/proc")
		pid = tryparse(Int, entry)
		isnothing(pid) && continue
		info = _asu_proc_group_state(pid)
		isnothing(info) && continue
		info.pgrp == pgid || continue
		info.state == 'Z' && continue
		push!(members, pid)
		rss_bytes += _asu_proc_rss_bytes(pid)
	end
	sort!(members)
	return (; members, rss_bytes)
end

function _asu_signal_group(pgid::Integer, signal::Integer)::Bool
	# POSIX kill with a negative PID addresses the process group. ESRCH is an
	# acceptable race: it means the target group is already empty.
	result = ccall(:kill, Cint, (Cint, Cint), -Cint(pgid), Cint(signal))
	return result == 0 || Base.Libc.errno() == Base.Libc.ESRCH
end

function _asu_wait_group_empty(pgid::Integer, seconds::Float64, poll_seconds::Float64)
	deadline = time() + max(seconds, 0.0)
	while time() <= deadline
		snapshot = _asu_process_group_snapshot(pgid)
		isempty(snapshot.members) && return true
		sleep(poll_seconds)
	end
	return isempty(_asu_process_group_snapshot(pgid).members)
end

function _asu_terminate_group(
	pgid::Integer;
	term_grace_seconds::Float64,
	kill_grace_seconds::Float64,
	poll_seconds::Float64,
)
	_asu_signal_group(pgid, 15)
	_asu_wait_group_empty(pgid, term_grace_seconds, poll_seconds) && return true
	_asu_signal_group(pgid, 9)
	return _asu_wait_group_empty(pgid, kill_grace_seconds, poll_seconds)
end

function _asu_worker_command(cell, forwarded::Vector{String}, out_dir::String,
		record_path::String)
	julia_bin = joinpath(Sys.BINDIR, Base.julia_exename())
	args = vcat(
		forwarded,
		[
			"--cases=$(cell.case_id)", "--arms=$(cell.arm)",
			"--interpolator-pools=$(cell.pool)", "--seeds=$(cell.seed)",
			"--lengthscale-factors=$(cell.factor)", "--out=$out_dir",
			"--cell-record-path=$record_path",
		],
	)
	return Cmd(vcat(
		["setsid", julia_bin, "--startup-file=no", AUDITED_SUPERVISOR_RUNNER],
		args,
	))
end

function _asu_annotate_record!(
	record_path::String,
	status::String,
	wall_seconds::Float64,
	peak_rss_bytes::Int,
	exit_code::Integer,
	death_verified::Bool,
	log_path::String,
)
	isfile(record_path) || return false
	record = TOML.parsefile(record_path)
	record["supervisor"] = Dict{String, Any}(
		"status" => status,
		"wall_seconds" => wall_seconds,
		"process_tree_peak_rss_bytes" => peak_rss_bytes,
		"worker_exit_code" => exit_code,
		"process_tree_death_verified" => death_verified,
		"log_path" => log_path,
		"completed_at" => string(now()),
	)
	if status != "completed" && get(record, "outcome", "running") == "running"
		record["outcome"] = status
		record["message"] = "process-tree supervisor ended the cell with status '$status'"
		record["elapsed_seconds"] = wall_seconds
	end
	if haskey(record, "max_rss_bytes")
		record["worker_max_rss_bytes"] = record["max_rss_bytes"]
	end
	record["max_rss_bytes"] = peak_rss_bytes
	_atomic_toml(record_path, record)
	return true
end

function _asu_supervise_cell(
	cell,
	forwarded::Vector{String},
	out_dir::String;
	wall_limit_seconds::Float64,
	rss_limit_bytes::Int,
	term_grace_seconds::Float64,
	kill_grace_seconds::Float64,
	poll_seconds::Float64,
)
	digest = _asu_cell_digest(cell, forwarded)
	record_path = _asu_cell_record_path(out_dir, cell, digest)
	force = any(arg -> arg == "--force=true", forwarded)
	retry_failures = any(arg -> arg == "--retry-failures=true", forwarded)
	if isfile(record_path) && !force
		existing = TOML.parsefile(record_path)
		outcome = String(get(existing, "outcome", ""))
		if !retry_failures || outcome == "report"
			println("SKIP supervised cell: ", basename(record_path), " outcome=", outcome)
			return (; status = "skipped", wall_seconds = 0.0, peak_rss_bytes = 0,
				record_path, contract_failure = get(existing, "contract_failure", false) === true)
		end
	end

	log_dir = joinpath(out_dir, "logs")
	mkpath(log_dir)
	log_path = joinpath(log_dir, replace(basename(record_path), ".toml" => ".log"))
	io = open(log_path, "w")
	cmd = _asu_worker_command(cell, forwarded, out_dir, record_path)
	started = time()
	process = try
		run(pipeline(ignorestatus(cmd), stdout = io, stderr = io); wait = false)
	catch
		close(io)
		rethrow()
	end
	pgid = getpid(process)
	peak_rss_bytes = 0
	status = "completed"
	death_verified = true
	while true
		snapshot = _asu_process_group_snapshot(pgid)
		peak_rss_bytes = max(peak_rss_bytes, snapshot.rss_bytes)
		elapsed = time() - started
		if elapsed > wall_limit_seconds
			status = "timeout"
			death_verified = _asu_terminate_group(pgid;
				term_grace_seconds, kill_grace_seconds, poll_seconds)
			break
		elseif snapshot.rss_bytes > rss_limit_bytes
			status = "rss_limit"
			death_verified = _asu_terminate_group(pgid;
				term_grace_seconds, kill_grace_seconds, poll_seconds)
			break
		elseif !process_running(process)
			if isempty(snapshot.members)
				break
			end
			# A normal worker must not leave descendants in its process group.
			status = "orphaned_process_tree"
			death_verified = _asu_terminate_group(pgid;
				term_grace_seconds, kill_grace_seconds, poll_seconds)
			break
		end
		sleep(poll_seconds)
	end
	if !death_verified
		status = "process_tree_survived_kill"
	end
	try
		!process_running(process) && wait(process)
	catch
	end
	exit_code = process.exitcode
	status == "completed" && exit_code != 0 && (status = "worker_error")
	close(io)
	wall_seconds = time() - started
	if status == "completed" && isfile(record_path)
		get(TOML.parsefile(record_path), "outcome", "running") == "running" &&
			(status = "worker_error")
	end
	has_record = _asu_annotate_record!(
		record_path, status, wall_seconds, peak_rss_bytes, exit_code,
		death_verified, log_path,
	)
	if !has_record
		# Failure before the worker's schema-v2 pre-estimation record is an
		# infrastructure/validation failure, not a missing scientific replicate.
		ledger_path = joinpath(out_dir, "supervisor_infrastructure_failures.toml")
		_atomic_toml(ledger_path, Dict{String, Any}(
			"schema_version" => 1,
			"status" => "infrastructure_failure",
			"case_id" => cell.case_id,
			"arm" => cell.arm,
			"interpolator_pool" => cell.pool,
			"master_seed" => cell.seed,
			"lengthscale_factor" => cell.factor,
			"worker_status" => status,
			"worker_exit_code" => exit_code,
			"log_path" => log_path,
		))
		throw(ErrorException(
			"worker failed before writing its audited cell record; see $log_path",
		))
	end
	record = TOML.parsefile(record_path)
	contract_failure = get(record, "contract_failure", false) === true
	println("SUPERVISED ", basename(record_path), " status=", status,
		" wall=", round(wall_seconds; digits = 1), "s peak_rss=", peak_rss_bytes)
	return (; status, wall_seconds, peak_rss_bytes, record_path, contract_failure)
end

function main_supervise_audited_repeated_uq()
	Sys.islinux() || throw(ArgumentError(
		"audited process-tree supervision currently requires Linux /proc and setsid",
	))
	out_name = _asu_arg(
		"out", "audited_supervised_$(Dates.format(now(), "yyyymmdd_HHMMSS"))",
	)
	out_dir = isabspath(out_name) ? normpath(out_name) :
		joinpath(@__DIR__, "results", out_name)
	mkpath(out_dir)
	forwarded = _asu_forwarded_args(copy(ARGS))
	cells = _asu_cells()
	wall_limit_seconds = parse(Float64, _asu_arg("cell-wall-limit-seconds", "1800"))
	rss_limit_bytes = parse(Int, _asu_arg("cell-rss-limit-bytes", "17179869184"))
	machine_hour_budget = parse(Float64, _asu_arg("machine-hour-budget", "24"))
	term_grace_seconds = parse(Float64, _asu_arg("term-grace-seconds", "10"))
	kill_grace_seconds = parse(Float64, _asu_arg("kill-grace-seconds", "5"))
	poll_seconds = parse(Float64, _asu_arg("poll-seconds", "0.25"))
	wall_limit_seconds > 0 || throw(ArgumentError("cell wall limit must be positive"))
	rss_limit_bytes > 0 || throw(ArgumentError("cell RSS limit must be positive"))
	machine_hour_budget > 0 || throw(ArgumentError("machine-hour budget must be positive"))
	poll_seconds > 0 || throw(ArgumentError("poll interval must be positive"))

	used_machine_seconds = 0.0
	results = NamedTuple[]
	for cell in cells
		used_machine_seconds < 3600machine_hour_budget || begin
			println("STOP machine-hour budget reached before launching remaining cells")
			break
		end
		result = _asu_supervise_cell(
			cell, forwarded, out_dir;
			wall_limit_seconds, rss_limit_bytes, term_grace_seconds,
			kill_grace_seconds, poll_seconds,
		)
		push!(results, result)
		used_machine_seconds += result.wall_seconds
		result.contract_failure && throw(ErrorException(
			"campaign stopped after a selected-estimator identity/artifact contract failure in $(result.record_path)",
		))
		result.status == "process_tree_survived_kill" && throw(ErrorException(
			"campaign stopped because process-tree death could not be verified",
		))
	end
	_atomic_toml(joinpath(out_dir, "supervisor_summary.toml"), Dict{String, Any}(
		"schema_version" => 1,
		"generated_at" => string(now()),
		"requested_cells" => length(cells),
		"completed_or_skipped_cells" => length(results),
		"used_machine_hours" => used_machine_seconds / 3600,
		"cell_wall_limit_seconds" => wall_limit_seconds,
		"cell_rss_limit_bytes" => rss_limit_bytes,
		"machine_hour_budget" => machine_hour_budget,
		"records" => [result.record_path for result in results],
	))
	println("Supervisor summary written under ", out_dir)
	return results
end

if abspath(PROGRAM_FILE) == @__FILE__
	main_supervise_audited_repeated_uq()
end
