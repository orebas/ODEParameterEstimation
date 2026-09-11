# Construction-only check of the actual deferred PEtab path.
include(joinpath(@__DIR__, "..", "petab", "dense_single", "common.jl"))
length(ARGS) == 1 || error("Expected OUTPUT")
out = abspath(only(ARGS))
mkpath(out)
isfile(joinpath(out, "result.json")) && error("Use a fresh output directory")
Base.exit_on_sigint(false)
started = time()
record = Dict{String,Any}("model"=>"Sneyd_PNAS2002", "condition"=>"Ca_dose_response__1",
    "status"=>"importing", "pid"=>getpid(), "julia_version"=>string(VERSION), "events"=>Any[],
    "max_derivative_order"=>3, "harness_sha256"=>bytes2hex(sha256(read(@__FILE__))))
checkpoint() = (record["elapsed_seconds"] = time()-started; write_json(joinpath(out,"result.json"),record))
checkpoint()
Profile.init(; n=10^7, delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> Profile.print(joinpath(out, "profile_$(round(Int,time())).txt");
    format=:flat, C=true, sortedby=:count)
record["profile_ready"] = true
context = ODEPE.RunContext(; capture_timing=true)
try
    root = get(ENV,"ODEPE_PETAB_MODEL_ROOT","/tmp/odepe-petab-full-20260910/Benchmark-Models")
    adapter = load_petab_problem(joinpath(root,"Sneyd_PNAS2002","Sneyd_PNAS2002.yaml"))
    pep, _ = ODEPE.rescale_pep(adapter.algebraic)
    record["estimation_started_unix"] = time()
    record["status"] = "constructing"
    checkpoint()
    progress = event -> begin
        push!(record["events"], (; event..., seconds=time()-record["estimation_started_unix"]))
        checkpoint()
        println(event); flush(stdout)
    end
    built = Base.ScopedValues.with(ODEPE.RUN_CONTEXT=>context) do
        Ext._experiment_frontier(adapter, pep, [record["condition"]]; max_derivative_order=3, progress)
    end
    record["trace"] = built.trace
    record["polynomialization_calls"] = count(event -> event.stage == :experiment_polynomialization, record["events"])
    @assert record["polynomialization_calls"] == 0
    @assert last(built.trace).derivative_order == 3
    @assert isnothing(built.frontier.selected)
    record["status"] = "rank_deficient_at_limit"
catch err
    record["status"] = err isa InterruptException ? "interrupted" : "failed"
    record["error"] = sprint(showerror,err,catch_backtrace())
finally
    record["detailed_timing"] = context.detailed_timing_sink
    checkpoint()
end
println("FINISHED ", record["status"]); flush(stdout)
record["status"] == "rank_deficient_at_limit" || exit(1)
