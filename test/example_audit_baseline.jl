using Distributed
using Printf
using Statistics

const PROJECT_ROOT = normpath(joinpath(@__DIR__, ".."))
const EXAMPLES_ROOT = joinpath(PROJECT_ROOT, "src", "examples")
const AUDIT_TIMEOUT_SECS = tryparse(Float64, get(ENV, "ODEPE_AUDIT_TIMEOUT_SECS", "90")) |> x -> isnothing(x) ? 90.0 : x
const AUDIT_OUTPUT_PATH = get(ENV, "ODEPE_AUDIT_OUTPUT", "")

function ensure_local_example_includes!()
	if !isdefined(Main, :default_example_models)
		Base.include(Main, joinpath(EXAMPLES_ROOT, "run_examples.jl"))
	end
	return nothing
end

function all_model_case_ids_local()
	ensure_local_example_includes!()
	model_names = Base.invokelatest(() -> sort!(collect(keys(Main.ALL_MODELS)); by = x -> string(x)))
	return ["model:$(name)" for name in model_names]
end

function init_audit_worker!(pid::Int)
	remotecall_wait(pid) do
		project_root = PROJECT_ROOT
		Core.eval(Main, quote
		using ODEParameterEstimation
		using Logging
		using Statistics
		Logging.disable_logging(Logging.Error)

		const PROJECT_ROOT_WORKER = $project_root
		const EXAMPLES_ROOT_WORKER = joinpath(PROJECT_ROOT_WORKER, "src", "examples")

		function quiet_call(f)
			redirect_stdout(devnull) do
				redirect_stderr(devnull) do
					with_logger(NullLogger()) do
						return f()
					end
				end
			end
		end

		function include_example(parts...)
			return Base.include(Main, joinpath(EXAMPLES_ROOT_WORKER, parts...))
		end

		function ensure_example_includes!()
			isdefined(Main, :default_example_models) || include_example("run_examples.jl")
			isdefined(Main, :run_first_example) || include_example("first_example.jl")
			isdefined(Main, :run_hello_world) || include_example("control_investigations", "01_hello_world_constant_input.jl")
			isdefined(Main, :run_rc_circuit_examples) || include_example("control_investigations", "02_rc_circuit_voltage_step.jl")
			isdefined(Main, :run_tank_comparison) || include_example("control_investigations", "03_tank_constant_vs_driven.jl")
			isdefined(Main, :run_polynomialization_demo) || include_example("control_investigations", "04_oscillator_input_polynomialized.jl")
			isdefined(Main, :run_comprehensive_comparison) || include_example("control_investigations", "05_comparing_approaches.jl")
			isdefined(Main, :run_biohydrogenation_example) || include_example("biohydrogenation", "biohydrogenation_example.jl")
			isdefined(Main, :run_biohydrogenation_example_with_options) || include_example("biohydrogenation", "biohydrogenation_example_with_options.jl")
			return nothing
		end

		function default_time_interval(pep)
			return isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval
		end

		function summarize_leaf(case_id::AbstractString, result_tuple)
			raw_results, analysis, _ = result_tuple
			raw_count = raw_results isa Tuple && !isempty(raw_results) && raw_results[1] isa AbstractVector ? length(raw_results[1]) : -1
			best_count = analysis isa Tuple && !isempty(analysis) && analysis[1] isa AbstractVector ? length(analysis[1]) : -1
			best_err = analysis isa Tuple && length(analysis) >= 2 ? try
				Float64(analysis[2])
			catch
				Inf
			end : Inf
			status = best_count > 0 && isfinite(best_err) ? "ok" : raw_count > 0 ? "raw_only" : "no_result"
			return [(;
				case_id = String(case_id),
				status,
				raw_count,
				best_count,
				best_err,
				identifiable_param_count = -1,
				median_rel_param_err = NaN,
				max_rel_param_err = NaN,
				mean_rel_param_err = NaN,
				note = "",
			)]
		end

		function summarize_unsupported(case_id::AbstractString, err)
			note = "Unsupported model class $(err.category)"
			if !isempty(err.expressions)
				note *= ": " * join(err.expressions, ", ")
			end
			return [(;
				case_id = String(case_id),
				status = "unsupported_expected",
				raw_count = -1,
				best_count = 0,
				best_err = Inf,
				identifiable_param_count = -1,
				median_rel_param_err = NaN,
				max_rel_param_err = NaN,
				mean_rel_param_err = NaN,
				note,
			)]
		end

		function best_cluster_solution(analysis)
			analysis isa Tuple || return nothing
			length(analysis) >= 1 || return nothing
			results = analysis[1]
			results isa AbstractVector || return nothing
			isempty(results) && return nothing
			return first(sort(results; by = result -> isnothing(result.err) ? Inf : result.err))
		end

		function param_error_stats(pep, best)
			p_true = pep.p_true
			unident_names = Set(string.(collect(best.all_unidentifiable)))
			rel_errors = Float64[]
			missing_params = String[]

			for (param, true_value) in p_true
				string(param) in unident_names && continue
				if haskey(best.parameters, param)
					denom = max(abs(Float64(true_value)), 1e-12)
					push!(rel_errors, abs(Float64(best.parameters[param]) - Float64(true_value)) / denom)
				else
					push!(missing_params, string(param))
				end
			end

			note = isempty(missing_params) ? "" : "Missing identifiable params: $(join(missing_params, ","))"
			if isempty(rel_errors)
				return (0, NaN, NaN, NaN, note)
			end

			return (
				length(rel_errors),
				Statistics.median(rel_errors),
				maximum(rel_errors),
				Statistics.mean(rel_errors),
				note,
			)
		end

		function collect_leaf_summaries(case_id::AbstractString, value)
			if value isa Tuple && length(value) == 3 && value[2] isa Tuple
				return summarize_leaf(case_id, value)
			elseif value isa NamedTuple
				rows = NamedTuple[]
				for name in keys(value)
					append!(rows, collect_leaf_summaries("$(case_id).$(name)", getfield(value, name)))
				end
				return rows
			elseif value isa AbstractDict
				rows = NamedTuple[]
				for key in sort!(collect(keys(value)); by = x -> string(x))
					append!(rows, collect_leaf_summaries("$(case_id).$(key)", value[key]))
				end
				return rows
			elseif value isa Tuple
				rows = NamedTuple[]
				for (idx, item) in pairs(value)
					append!(rows, collect_leaf_summaries("$(case_id)[$(idx)]", item))
				end
				return rows
			else
				return [(;
					case_id = String(case_id),
					status = "unsupported_result",
					raw_count = -1,
					best_count = -1,
					best_err = Inf,
					note = "Unsupported result type $(typeof(value))",
				)]
			end
		end

		function model_case_ids()
			ensure_example_includes!()
			return ["model:$(name)" for name in Main.default_example_models()]
		end

		function script_case_ids()
			return [
				"script:first_example",
				"script:hello_world",
				"script:rc_circuit",
				"script:tank_comparison",
				"script:polynomialization_demo",
				"script:comprehensive_comparison",
				"script:biohydrogenation",
				"script:biohydrogenation_options",
			]
		end

		function all_case_ids()
			return vcat(model_case_ids(), script_case_ids())
		end

		function run_model_case(model_name::Symbol)
			ensure_example_includes!()
			model_fn = Base.invokelatest(getindex, Main.ALL_MODELS, model_name)
			pep = Base.invokelatest(model_fn)
			opts = Base.invokelatest(Main.default_example_options; smoke = true)
			opts = ODEParameterEstimation.merge_options(opts, time_interval = default_time_interval(pep))
			result = try
				quiet_call() do
					sampled = ODEParameterEstimation.sample_problem_data(pep, opts)
					ODEParameterEstimation.analyze_parameter_estimation_problem(sampled, opts)
				end
			catch err
				err isa ODEParameterEstimation.UnsupportedModelClassError && return summarize_unsupported("model:$(model_name)", err)
				rethrow(err)
			end
			rows = summarize_leaf("model:$(model_name)", result)
			best = best_cluster_solution(result[2])
			if !isnothing(best)
				ident_count, median_err, max_err, mean_err, note = param_error_stats(pep, best)
				row = only(rows)
				rows[1] = merge(row, (
					identifiable_param_count = ident_count,
					median_rel_param_err = median_err,
					max_rel_param_err = max_err,
					mean_rel_param_err = mean_err,
					note = isempty(row.note) ? note : isempty(note) ? row.note : row.note * "; " * note,
				))
			end
			return rows
		end

		function run_script_case(case_name::AbstractString)
			ensure_example_includes!()
			case_name == "first_example" && return collect_leaf_summaries("script:first_example", quiet_call(() -> Base.invokelatest(Main.run_first_example; smoke = true)))
			case_name == "hello_world" && return collect_leaf_summaries("script:hello_world", quiet_call(() -> Base.invokelatest(Main.run_hello_world; smoke = true)))
			case_name == "rc_circuit" && return collect_leaf_summaries("script:rc_circuit", quiet_call(() -> Base.invokelatest(Main.run_rc_circuit_examples; smoke = true)))
			case_name == "tank_comparison" && return collect_leaf_summaries("script:tank_comparison", quiet_call(() -> Base.invokelatest(Main.run_tank_comparison; smoke = true)))
			case_name == "polynomialization_demo" && return collect_leaf_summaries("script:polynomialization_demo", quiet_call(() -> Base.invokelatest(Main.run_polynomialization_demo; smoke = true)))
			case_name == "comprehensive_comparison" && return collect_leaf_summaries("script:comprehensive_comparison", quiet_call(() -> Base.invokelatest(Main.run_comprehensive_comparison; smoke = true)))
			case_name == "biohydrogenation" && return collect_leaf_summaries("script:biohydrogenation", quiet_call(() -> Base.invokelatest(Main.run_biohydrogenation_example; smoke = true)))
			case_name == "biohydrogenation_options" && return collect_leaf_summaries("script:biohydrogenation_options", quiet_call(() -> Base.invokelatest(Main.run_biohydrogenation_example_with_options; smoke = true)))
			error("Unknown script case $(case_name)")
		end

		function run_audit_case(case_id::AbstractString)
			if startswith(case_id, "model:")
				return run_model_case(Symbol(chop(case_id; head = 6, tail = 0)))
			elseif startswith(case_id, "script:")
				return run_script_case(chop(case_id; head = 7, tail = 0))
			else
				error("Unknown case id $(case_id)")
			end
		end
		end)
	end
	return nothing
end

function restart_worker!(pid_ref::Base.RefValue{Int})
	if pid_ref[] != 0
		try
			rmprocs(pid_ref[])
		catch
		end
	end
	newpid = only(addprocs(1))
	init_audit_worker!(newpid)
	pid_ref[] = newpid
	return newpid
end

function tsv_escape(value)
	text = string(value)
	text = replace(text, '\t' => ' ')
	return replace(text, '\n' => "\\n")
end

function print_row(row; secs = NaN)
	secs_str = isfinite(secs) ? @sprintf("%.3f", secs) : "NaN"
	best_err_str = isfinite(row.best_err) ? @sprintf("%.6g", row.best_err) : string(row.best_err)
	median_rel_str = isfinite(row.median_rel_param_err) ? @sprintf("%.6g", row.median_rel_param_err) : ""
	max_rel_str = isfinite(row.max_rel_param_err) ? @sprintf("%.6g", row.max_rel_param_err) : ""
	mean_rel_str = isfinite(row.mean_rel_param_err) ? @sprintf("%.6g", row.mean_rel_param_err) : ""
	println(join([
		row.case_id,
		row.status,
		secs_str,
		string(row.raw_count),
		string(row.best_count),
		best_err_str,
		string(row.identifiable_param_count),
		median_rel_str,
		max_rel_str,
		mean_rel_str,
		tsv_escape(row.note),
	], '\t'))
end

function case_ids_from_args(pid::Int, args::Vector{String})
	if isempty(args) || (length(args) == 1 && only(args) == "--all")
		models = ["model:$(name)" for name in Base.invokelatest(Main.default_example_models)]
		return vcat(models, script_case_ids())
	elseif length(args) == 1 && only(args) == "--all-models"
		return all_model_case_ids_local()
	elseif length(args) == 1 && only(args) == "--models"
		return ["model:$(name)" for name in Base.invokelatest(Main.default_example_models)]
	elseif length(args) == 1 && only(args) == "--scripts"
		return script_case_ids()
	else
		return args
	end
end

function script_case_ids()
	return [
		"script:first_example",
		"script:hello_world",
		"script:rc_circuit",
		"script:tank_comparison",
		"script:polynomialization_demo",
		"script:comprehensive_comparison",
		"script:biohydrogenation",
		"script:biohydrogenation_options",
	]
end

worker_ref = Ref(0)
restart_worker!(worker_ref)
cases = case_ids_from_args(worker_ref[], ARGS)

if !isempty(AUDIT_OUTPUT_PATH)
	open(AUDIT_OUTPUT_PATH, "w") do io
		write(io, "case_id\tstatus\tsecs\traw_count\tbest_count\tbest_err\tidentifiable_param_count\tmedian_rel_param_err\tmax_rel_param_err\tmean_rel_param_err\tnote\n")
	end
end

println("case_id\tstatus\tsecs\traw_count\tbest_count\tbest_err\tidentifiable_param_count\tmedian_rel_param_err\tmax_rel_param_err\tmean_rel_param_err\tnote")

for case_id in cases
	t0 = time()
	fut = remotecall(case_id -> Main.run_audit_case(case_id), worker_ref[], case_id)
	while !isready(fut) && (time() - t0) < AUDIT_TIMEOUT_SECS
		sleep(0.25)
	end

	if isready(fut)
		elapsed = time() - t0
		try
			rows = fetch(fut)
			for row in rows
				print_row(row; secs = elapsed)
				if !isempty(AUDIT_OUTPUT_PATH)
					open(AUDIT_OUTPUT_PATH, "a") do io
						secs_str = isfinite(elapsed) ? @sprintf("%.3f", elapsed) : "NaN"
						best_err_str = isfinite(row.best_err) ? @sprintf("%.6g", row.best_err) : string(row.best_err)
						median_rel_str = isfinite(row.median_rel_param_err) ? @sprintf("%.6g", row.median_rel_param_err) : ""
						max_rel_str = isfinite(row.max_rel_param_err) ? @sprintf("%.6g", row.max_rel_param_err) : ""
						mean_rel_str = isfinite(row.mean_rel_param_err) ? @sprintf("%.6g", row.mean_rel_param_err) : ""
						write(io, join([
							row.case_id,
							row.status,
							secs_str,
							string(row.raw_count),
							string(row.best_count),
							best_err_str,
							string(row.identifiable_param_count),
							median_rel_str,
							max_rel_str,
							mean_rel_str,
							tsv_escape(row.note),
						], '\t') * "\n")
					end
				end
			end
		catch err
			row = (;
				case_id = String(case_id),
				status = "error",
				raw_count = -1,
				best_count = -1,
				best_err = Inf,
				identifiable_param_count = -1,
				median_rel_param_err = NaN,
				max_rel_param_err = NaN,
				mean_rel_param_err = NaN,
				note = sprint(showerror, err),
			)
			print_row(row; secs = elapsed)
			if !isempty(AUDIT_OUTPUT_PATH)
				open(AUDIT_OUTPUT_PATH, "a") do io
					write(io, join([
						row.case_id,
						row.status,
						@sprintf("%.3f", elapsed),
						string(row.raw_count),
						string(row.best_count),
						string(row.best_err),
						string(row.identifiable_param_count),
						"",
						"",
						"",
						tsv_escape(row.note),
					], '\t') * "\n")
				end
			end
			restart_worker!(worker_ref)
		end
	else
		row = (;
			case_id = String(case_id),
			status = "timeout",
			raw_count = -1,
			best_count = -1,
			best_err = Inf,
			identifiable_param_count = -1,
			median_rel_param_err = NaN,
			max_rel_param_err = NaN,
			mean_rel_param_err = NaN,
			note = "Timed out after $(AUDIT_TIMEOUT_SECS)s",
		)
		print_row(row; secs = NaN)
		if !isempty(AUDIT_OUTPUT_PATH)
			open(AUDIT_OUTPUT_PATH, "a") do io
				write(io, join([
					row.case_id,
					row.status,
					"NaN",
					string(row.raw_count),
					string(row.best_count),
					string(row.best_err),
					string(row.identifiable_param_count),
					"",
					"",
					"",
					tsv_escape(row.note),
				], '\t') * "\n")
			end
		end
		restart_worker!(worker_ref)
	end
end

rmprocs(worker_ref[])
