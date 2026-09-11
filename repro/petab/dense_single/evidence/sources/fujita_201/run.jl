# julia --startup-file=no --compiled-modules=existing run.jl MODEL CONDITION OUTPUT_DIR [POINTS]
include("common.jl")
length(ARGS) in (3,4) || error("Expected MODEL CONDITION OUTPUT_DIR [POINTS]")
name, cid, outarg = ARGS[1:3]
out = abspath(outarg)
mkpath(out)
isfile(joinpath(out, "result.json")) && error("Use a fresh output directory; retained attempts are immutable")
n = length(ARGS) == 4 ? parse(Int, ARGS[4]) : 201
Base.exit_on_sigint(false)
Random.seed!(20260911)
started = time()
record = Dict{String,Any}("model" => name, "condition" => cid, "status" => "importing",
    "pid" => getpid(), "julia_version" => string(VERSION), "seed" => 20260911,
    "datasize_per_observable" => n, "noise_level" => 0.0,
    "manifest_sha256" => bytes2hex(sha256(read(joinpath(dirname(Base.active_project()), "Manifest.toml")))),
    "harness_sha256" => bytes2hex(sha256(vcat(read(@__FILE__), read(joinpath(@__DIR__, "common.jl"))))))
checkpoint() = (record["elapsed_seconds"] = time()-started; write_json(joinpath(out,"result.json"), record))
checkpoint()
Profile.init(; n=10^7, delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> begin
    path = joinpath(out, "profile_$(round(Int,time())).txt")
    Profile.print(path; format=:flat, C=true, sortedby=:count)
    println("PROFILE_SAVED ", path); flush(stdout)
end
context = ODEPE.RunContext(; capture_timing=true)
try
    extracted = single_condition(name, cid)
    record["model_definition"] = extracted.record
    record["status"] = "simulating"
    checkpoint()
    pep = sample_dense(extracted.reduced, n)
    full = sample_dense(extracted.full, n)
    errors = [maximum(abs.(pep.data_sample[a.rhs] .- full.data_sample[b.rhs])) /
        max(maximum(abs.(full.data_sample[b.rhs])), eps())
        for (a,b) in zip(pep.measured_quantities, full.measured_quantities)]
    record["full_vs_reduced_max_relative_signal_errors"] = errors
    maximum(errors) < 1e-7 || error("Reduced simulation disagrees with full imported condition")
    write_json(joinpath(out,"data.json"), (; times=pep.data_sample["t"],
        signals=[(; expression=string(eq.rhs), values=pep.data_sample[eq.rhs]) for eq in pep.measured_quantities]))
    opts = EstimationOptions(; datasize=n, time_interval=pep.recommended_time_interval,
        noise_level=0.0, shooting_points=20, shooting_warp=true, shooting_warp_beta=3.0,
        use_multipoint=true, multipoint_n_points=2, multipoint_max_pairs=15,
        polish_solver_solutions=true, polish_solutions=true, polish_maxiters=5000,
        polish_method=PolishLSOBoundedLog, opt_maxiters=200000,
        opt_lb=extracted.lower, opt_ub=extracted.upper, abstol=1e-12, reltol=1e-12,
        polish_maxtime=120.0, polish_divergence_factor=10.0,
        polish_stagnation_window=50, polish_ode_maxiters=20000,
        terminal_fallback=:none, compute_uncertainty=false,
        profile_phases=true, heartbeat=true, diagnostics=true, nooutput=false,
        hc_show_progress=true, save_system=true)
    record["options"] = Dict(string(k) => getfield(opts,k) for k in fieldnames(EstimationOptions))
    effective = ODEPE.maybe_filter_interpolators_by_noise(ODEPE.resolve_interpolator_list(opts), pep, opts)
    record["effective_interpolators"] = [string(first(entry)) for entry in effective]
    record["benchmark_differences"] = ["201 clean synthetic samples per observable on original physical interval",
        "Original PEtab parameter bounds; nonnegative free IC bounds", "120 seconds per trajectory polish",
        "Terminal direct optimization disabled so algebraic failure stays visible", "Timing and HC progress enabled"]
    record["preparation_seconds"] = time()-started
    record["estimation_started_unix"] = time()
    record["status"] = "estimating"
    checkpoint()
    println("ESTIMATION_START ", record["estimation_started_unix"]); flush(stdout)
    answer = cd(out) do
        Base.ScopedValues.with(ODEPE.RUN_CONTEXT => context) do
            analyze_parameter_estimation_problem(pep, opts)
        end
    end
    record["estimation_seconds"] = time()-record["estimation_started_unix"]
    raw, analysis, _ = answer
    ranked = first(analysis)
    function result_record(r)
        estimates = merge(r.states, r.parameters)
        truth = merge(pep.ic, pep.p_true)
        errors = Dict(string(k) => (; truth=v, estimate=get(estimates,k,NaN),
            absolute_error=abs(get(estimates,k,NaN)-v),
            relative_error=iszero(v) ? nothing : abs(get(estimates,k,NaN)-v)/abs(v)) for (k,v) in truth)
        return (; fit_error=r.err, parameters=r.parameters, states=r.states,
            at_time=r.at_time, all_unidentifiable=string.(collect(r.all_unidentifiable)),
            provenance=Dict(string(k)=>getfield(r.provenance,k) for k in fieldnames(typeof(r.provenance))), recovery=errors)
    end
    record["ranked_results"] = result_record.(ranked)
    # Preserve the returned ordering. No truth-based choice of winning branch.
    record["raw_count"] = length(first(raw))
    record["status"] = isempty(ranked) ? "no_candidates" : "complete"
catch err
    record["status"] = err isa InterruptException ? "interrupted" : "failed"
    record["error"] = sprint(showerror, err, catch_backtrace())
finally
    !isnothing(context.timing) && (record["timing"] = ODEPE.timing_breakdown_to_dict(context.timing))
    write_json(joinpath(out,"detailed_timing.json"), context.detailed_timing_sink)
    write_json(joinpath(out,"resolve_timing.json"), context.resolve_timing_sink)
    checkpoint()
end
println("FINISHED ", name, " ", record["status"]); flush(stdout)
