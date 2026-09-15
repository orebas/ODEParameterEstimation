# A separate native ODEPE problem, with independent effective reaction rates.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using JSON, Random, SHA, Profile
include("model.jl")

length(ARGS) == 3 || error("Expected SPEC_JSON OUTPUT_DIR original|moderate")
spec_path, outarg, scenario = ARGS
out = abspath(outarg)
spec = JSON.parsefile(spec_path)
isfile(joinpath(out, "result.json")) && error("Use a fresh output directory")
mkpath(out)
Base.exit_on_sigint(false)
Random.seed!(20260915)

json_safe(x::AbstractFloat) = isfinite(x) ? x : string(x)
json_safe(x::Union{AbstractString,Integer,Bool,Nothing}) = x
json_safe(x::Symbol) = string(x)
json_safe(x::AbstractDict) = Dict(string(k) => json_safe(v) for (k,v) in x)
json_safe(x::NamedTuple) = Dict(string(k) => json_safe(v) for (k,v) in pairs(x))
json_safe(x::Union{AbstractArray,Tuple,Set}) = [json_safe(v) for v in x]
json_safe(x) = string(x)
function write_json(path, value)
    open(path * ".tmp", "w") do io
        JSON.print(io, json_safe(value))
    end
    mv(path * ".tmp", path; force=true)
end

started_ns = time_ns()
record = Dict{String,Any}("status" => "preparing", "scenario" => scenario,
    "pid" => getpid(), "julia_version" => string(VERSION), "seed" => 20260915,
    "scope" => spec["scope"], "experiments" => 1, "multipoint" => false,
    "manifest_sha256" => bytes2hex(sha256(read(joinpath(dirname(Base.active_project()), "Manifest.toml")))),
    "spec_sha256" => bytes2hex(sha256(read(spec_path))),
    "source_sha256" => Dict(f => bytes2hex(sha256(read(joinpath(@__DIR__, f))))
        for f in ("run.jl", "model.jl", "capture_and_solve.jl")))
record["versions"] = Dict(d.name => string(d.version) for d in values(Pkg.dependencies())
    if d.name in ("ODEParameterEstimation", "Symbolics", "SymbolicUtils", "ModelingToolkit",
        "HomotopyContinuation", "SIAN", "StructuralIdentifiability", "GaussianProcesses"))
checkpoint() = (record["elapsed_seconds"] = (time_ns()-started_ns)/1e9;
    write_json(joinpath(out, "result.json"), record))
checkpoint()
Profile.init(; n=10^7, delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> begin
    path = joinpath(out, "profile_$(time_ns()).txt")
    Profile.print(path; format=:flat, C=true, sortedby=:count)
    println("PROFILE_SAVED ", path); flush(stdout)
end
record["profile_ready"] = true
checkpoint()
include("capture_and_solve.jl")
context = ODEPE.RunContext(; capture_timing=true)
try
    empty_problem = coefficient_problem(spec, scenario)
    record["model_definition"] = (; states=string.(empty_problem.model.original_states),
        parameters=string.(empty_problem.model.original_parameters),
        equations=string.(ModelingToolkit.equations(empty_problem.model.system)),
        observations=string.(empty_problem.measured_quantities),
        generating_parameters=empty_problem.p_true, generating_initial_states=empty_problem.ic,
        time_interval=empty_problem.recommended_time_interval,
        truth_use="Simulation and post-fit diagnostics only. All six initial states and nine rates are unknown to the estimator.")
    record["status"] = "simulating"
    checkpoint()
    n = 201
    simulated = ODEPE.sample_data(empty_problem.model.system, empty_problem.measured_quantities,
        empty_problem.recommended_time_interval, empty_problem.p_true, empty_problem.ic, n;
        solver=empty_problem.solver, abstol=1e-12, reltol=1e-12)
    observable = S.Num(only(empty_problem.measured_quantities).rhs)
    if scenario == "original"
        retained = spec["original_data"]
        values = Float64.(only(retained["signals"])["values"])
        times = Float64.(retained["times"])
        @assert times == simulated["t"]
        relative_error = maximum(abs.(simulated[observable] .- values)) / max(maximum(abs.(values)), eps())
        record["native_vs_original_max_relative_signal_error"] = relative_error
        relative_error < 1e-7 || error("Native coefficient model does not reproduce the original data")
        # Preserve the old samples exactly; simulation above checks the rewrite.
        data = OD{Union{String,S.Num},Vector{Float64}}(observable => values, "t" => times)
    else
        data = simulated
    end
    pep = ParameterEstimationProblem(empty_problem.name, empty_problem.model,
        empty_problem.measured_quantities, data, empty_problem.recommended_time_interval,
        empty_problem.solver, empty_problem.p_true, empty_problem.ic, empty_problem.unident_count)
    write_json(joinpath(out, "data.json"), (; times=data["t"],
        signals=[(; expression=string(observable), values=data[observable])]))
    # The original PEtab bounds on kinetic parameters do not induce a rectangular
    # box on independent rates. Use broad nonnegative bounds for this new problem.
    lower = zeros(15)
    upper = fill(1e6, 15)
    opts = EstimationOptions(; datasize=n, time_interval=pep.recommended_time_interval,
        compute_algebraic_multiplicity=false, construction_compute_mixed_volume=false,
        noise_level=0.0, shooting_points=20, shooting_warp=true, shooting_warp_beta=3.0,
        use_multipoint=false, polish_solver_solutions=true, polish_solutions=true,
        polish_maxiters=5000, polish_method=PolishLSOBoundedLog, opt_maxiters=200000,
        opt_lb=lower, opt_ub=upper, abstol=1e-12, reltol=1e-12,
        polish_maxtime=120.0, polish_divergence_factor=10.0,
        polish_stagnation_window=50, polish_ode_maxiters=20000,
        terminal_fallback=:none, compute_uncertainty=false,
        dump_raw_candidates_path=joinpath(out, "raw_candidates.csv"),
        dump_polished_path=joinpath(out, "polished_candidates.csv"),
        profile_phases=true, heartbeat=true, diagnostics=true, nooutput=false,
        hc_show_progress=true, save_system=true)
    record["options"] = Dict(string(k) => getfield(opts,k) for k in fieldnames(EstimationOptions))
    effective = ODEPE.maybe_filter_interpolators_by_noise(ODEPE.resolve_interpolator_list(opts), pep, opts)
    record["effective_interpolators"] = [string(first(entry)) for entry in effective]
    record["diagnostic_caveats"] = ["Independent rates define a different inference problem from the original kinetic parameters",
        "Free initial states and a single scalar observation can leave rates nonidentifiable",
        "M is unknown: no Groebner count, no supplied 544, and no root-completeness claim",
        "Selection MV scoring disabled; ordinary polyhedral generic-start solve retained",
        "Stop after an empty generic-start result rather than retrying fresh solves at every anchor",
        "Trajectory fit and identifiable combinations matter; error in each nonidentifiable rate is not a recovery criterion"]
    record["preparation_seconds"] = (time_ns()-started_ns)/1e9
    record["estimation_started_ns"] = time_ns()
    record["status"] = "estimating"
    checkpoint()
    println("ESTIMATION_START ", record["estimation_started_ns"]); flush(stdout)
    answer = cd(out) do
        Base.ScopedValues.with(ODEPE.RUN_CONTEXT => context) do
            analyze_parameter_estimation_problem(pep, opts)
        end
    end
    raw, analysis, _ = answer
    ranked = first(analysis)
    function result_record(r)
        estimates = merge(r.states, r.parameters)
        truth = merge(pep.ic, pep.p_true)
        errors = Dict(string(k) => (; truth=v, estimate=get(estimates,k,NaN),
            absolute_error=abs(get(estimates,k,NaN)-v),
            relative_error=iszero(v) ? nothing : abs(get(estimates,k,NaN)-v)/abs(v)) for (k,v) in truth)
        return (; fit_error=r.err, parameters=r.parameters, states=r.states,
            source_anchor_time=r.at_time, report_time=r.report_time,
            all_unidentifiable=string.(collect(r.all_unidentifiable)),
            provenance=Dict(string(k)=>getfield(r.provenance,k) for k in fieldnames(typeof(r.provenance))),
            individual_errors_not_unique_recovery=errors)
    end
    record["ranked_results"] = result_record.(ranked)
    record["raw_count"] = length(first(raw))
    record["status"] = isempty(ranked) ? "no_candidates" : "complete"
catch err
    stopped = err isa InterruptException && get(record, "generic_start_empty", false)
    record["status"] = stopped ? "generic_start_failed" : err isa InterruptException ? "interrupted" : "failed"
    stopped || (record["error"] = sprint(showerror, err, catch_backtrace()))
finally
    haskey(record,"estimation_started_ns") &&
        (record["estimation_seconds"] = (time_ns()-record["estimation_started_ns"])/1e9)
    !isnothing(context.timing) && (record["timing"] = ODEPE.timing_breakdown_to_dict(context.timing))
    write_json(joinpath(out,"detailed_timing.json"), context.detailed_timing_sink)
    write_json(joinpath(out,"resolve_timing.json"), context.resolve_timing_sink)
    checkpoint()
end
println("FINISHED ", scenario, " ", record["status"]); flush(stdout)
record["status"] in ("failed", "interrupted", "generic_start_failed") && exit(1)
