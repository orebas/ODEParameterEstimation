# Run from the global environment: julia --startup-file=no run_rational.jl MODEL OUTPUT
using ODEParameterEstimation, Pkg, Random, SHA, TOML, Profile
using ODEParameterEstimation.ModelingToolkit: @parameters, @variables, t_nounits as t, D_nounits as D
const ODEPE = ODEParameterEstimation
const Num = ODEPE.Symbolics.Num
const OrderedDict = ODEPE.OrderedDict

length(ARGS) == 2 || error("Expected MODEL OUTPUT")
model_name, output = ARGS
model_name in ("biohydrogenation", "repressilator", "fitzhugh_nagumo") || error("Unknown model")
out = abspath(output)
mkpath(out)
isfile(joinpath(out, "result.toml")) && error("Use a fresh output directory")
fixture = joinpath(@__DIR__, "fixtures", model_name)
include(joinpath(fixture, "model.jl"))
Base.exit_on_sigint(false)
Random.seed!(20260911)
started = time()
safe(x::Union{AbstractString, Number, Bool}) = x
safe(x::Nothing) = "nothing"
safe(x::AbstractDict) = Dict(string(k)=>safe(v) for (k,v) in x)
safe(x::NamedTuple) = Dict(string(k)=>safe(v) for (k,v) in pairs(x))
safe(x::Union{AbstractArray, Tuple, Set}) = [safe(v) for v in x]
safe(x) = string(x)
function write_record(path, value)
    open(path * ".tmp", "w") do io
        TOML.print(io, safe(value); sorted=true)
    end
    mv(path * ".tmp", path; force=true)
end
record = Dict{String,Any}("model"=>model_name, "status"=>"preparing", "pid"=>getpid(),
    "julia_version"=>string(VERSION), "seed"=>20260911,
    "data_sha256"=>bytes2hex(sha256(read(joinpath(fixture, "data.csv")))),
    "model_sha256"=>bytes2hex(sha256(read(joinpath(fixture, "model.jl")))),
    "harness_sha256"=>bytes2hex(sha256(read(@__FILE__))),
    "manifest_sha256"=>bytes2hex(sha256(read(joinpath(dirname(Base.active_project()), "Manifest.toml")))))
record["versions"] = Dict(d.name=>string(d.version) for d in values(Pkg.dependencies())
    if d.name in ("ODEParameterEstimation", "GaussianProcesses", "SIAN", "StructuralIdentifiability",
        "Symbolics", "ModelingToolkit", "HomotopyContinuation"))
checkpoint() = (record["elapsed_seconds"] = time()-started; write_record(joinpath(out, "result.toml"), record))
checkpoint()
Profile.init(; n=10^7, delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> Profile.print(joinpath(out, "profile_$(round(Int,time())).txt");
    format=:flat, C=true, sortedby=:count)
record["profile_ready"] = true
context = ODEPE.RunContext(; capture_timing=true)
try
    base = benchmark_problem()
    rows = [parse.(Float64, strip.(split(line, ','))) for line in readlines(joinpath(fixture, "data.csv"))]
    @assert all(row -> length(row) == length(base.measured_quantities)+1, rows)
    data = OrderedDict{Union{Num,String},Vector{Float64}}("t"=>[row[1] for row in rows])
    for (i, eq) in enumerate(base.measured_quantities)
        data[Num(eq.rhs)] = [row[i+1] for row in rows]
    end
    pep = ParameterEstimationProblem(base.name, base.model, base.measured_quantities, data,
        base.recommended_time_interval, package_wide_default_ode_solver, base.p_true, base.ic, base.unident_count)
    # Verify the extracted equations and original coordinate scales against the
    # retained data before estimation. This does not replace or resample the data.
    clean = ODEPE.sample_data(pep.model.system, pep.measured_quantities,
        pep.recommended_time_interval, pep.p_true, pep.ic, length(rows);
        uneven_sampling=true, uneven_sampling_times=data["t"], abstol=1e-12, reltol=1e-12)
    nominal_noise = Dict("biohydrogenation"=>1e-6, "repressilator"=>1e-4, "fitzhugh_nagumo"=>0.0)[model_name]
    record["nominal_data_noise"] = nominal_noise
    record["data_vs_generating_trajectory_relative_rms"] = [
        sqrt(sum(abs2, data[Num(eq.rhs)] - clean[Num(eq.rhs)])/length(rows)) /
        max(sum(abs, clean[Num(eq.rhs)])/length(rows), 1e-12) for eq in pep.measured_quantities]
    maximum(record["data_vs_generating_trajectory_relative_rms"]) < 10max(nominal_noise,1e-8) ||
        error("Retained data disagree with the extracted generating model")
    nvar = length(pep.p_true) + length(pep.ic)
    opts = EstimationOptions(; datasize=length(rows), noise_level=0.0,
        si_fix_strategy=Symbol(get(ENV, "ODEPE_SI_FIX_STRATEGY", string(EstimationOptions().si_fix_strategy))),
        shooting_points=20, shooting_warp=true, shooting_warp_beta=3.0,
        use_multipoint=true, multipoint_n_points=2, multipoint_max_pairs=15,
        polish_solver_solutions=true, polish_solutions=true, polish_maxiters=5000,
        polish_method=PolishLSOBoundedLog, opt_maxiters=200000,
        opt_lb=fill(1e-5,nvar), opt_ub=fill(10.0,nvar), abstol=1e-12, reltol=1e-12,
        polish_maxtime=120.0, polish_divergence_factor=10.0,
        polish_stagnation_window=50, polish_ode_maxiters=20000,
        terminal_fallback=:none, compute_uncertainty=false,
        profile_phases=true, heartbeat=true, diagnostics=true, nooutput=false,
        hc_show_progress=true, save_system=true)
    record["options"] = Dict(string(k)=>getfield(opts,k) for k in fieldnames(EstimationOptions))
    record["effective_interpolators"] = [string(first(entry)) for entry in
        ODEPE.maybe_filter_interpolators_by_noise(ODEPE.resolve_interpolator_list(opts), pep, opts)]
    record["samples_per_observable"] = length(rows)
    record["time_interval"] = [first(data["t"]), last(data["t"])]
    record["equations"] = string.(ODEPE.ModelingToolkit.equations(pep.model.system))
    record["observations"] = string.(pep.measured_quantities)
    record["generating_parameters"] = Dict(string(k)=>v for (k,v) in pep.p_true)
    record["generating_initial_states"] = Dict(string(k)=>v for (k,v) in pep.ic)
    record["benchmark_differences"] = ["Current default nine-method interpolator pool and ordinary noise filtering",
        "120 seconds per trajectory polish", "Terminal direct optimization disabled", "UQ disabled", "Phase timing enabled"]
    record["status"] = "estimating"
    record["estimation_started_unix"] = time()
    checkpoint()
    answer = cd(out) do
        Base.ScopedValues.with(ODEPE.RUN_CONTEXT=>context) do
            analyze_parameter_estimation_problem(pep, opts)
        end
    end
    record["estimation_seconds"] = time()-record["estimation_started_unix"]
    raw, analysis, _ = answer
    ranked = first(analysis)
    function summarize(r)
        estimates = merge(r.states, r.parameters)
        truth = merge(pep.ic, pep.p_true)
        recovery = Dict(string(k)=>(; truth=v, estimate=get(estimates,k,NaN),
            absolute_error=abs(get(estimates,k,NaN)-v),
            relative_error=abs(get(estimates,k,NaN)-v)/max(abs(v),1e-12),
            structurally_unidentifiable=k in r.all_unidentifiable) for (k,v) in truth)
        parameter_error = maximum(abs(get(r.parameters,p,NaN)-v)/max(abs(v),1e-12) for (p,v) in pep.p_true)
        return (; fit_error=r.err, max_relative_parameter_error=parameter_error,
            source_anchor_time=r.at_time, report_time=r.report_time, recovery,
            all_unidentifiable=string.(collect(r.all_unidentifiable)),
            provenance=Dict(string(k)=>getfield(r.provenance,k) for k in fieldnames(typeof(r.provenance))))
    end
    record["ranked_results"] = summarize.(ranked)
    record["raw_count"] = length(first(raw))
    record["ranked_count"] = length(ranked)
    record["status"] = isempty(ranked) ? "no_candidates" : "complete"
    if !isempty(ranked)
        record["selected_parameter_error"] = first(record["ranked_results"]).max_relative_parameter_error
        record["best_of_branch_parameter_error"] = minimum(r.max_relative_parameter_error for r in record["ranked_results"])
        record["selected_fit_error"] = first(ranked).err
    end
catch err
    record["status"] = err isa InterruptException ? "interrupted" : "failed"
    record["error"] = sprint(showerror, err, catch_backtrace())
finally
    haskey(record,"estimation_started_unix") && !haskey(record,"estimation_seconds") &&
        (record["estimation_seconds"] = time()-record["estimation_started_unix"])
    !isnothing(context.timing) && (record["timing"] = ODEPE.timing_breakdown_to_dict(context.timing))
    write_record(joinpath(out, "detailed_timing.toml"), Dict("rows"=>context.detailed_timing_sink))
    write_record(joinpath(out, "resolve_timing.toml"), Dict("rows"=>context.resolve_timing_sink))
    checkpoint()
end
println("FINISHED ", model_name, " ", record["status"]); flush(stdout)
record["status"] == "complete" || exit(1)
