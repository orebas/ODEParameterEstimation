# A bounded construction probe, not a Sneyd estimation run.
include("common.jl")
length(ARGS) == 1 || error("Expected OUTPUT_DIR")
out = abspath(only(ARGS))
mkpath(out)
isfile(joinpath(out,"result.json")) && error("Use a fresh output directory")
Base.exit_on_sigint(false)
started = time()
record = Dict{String,Any}("status"=>"importing", "pid"=>getpid(), "julia_version"=>string(VERSION),
    "model"=>"Sneyd_PNAS2002", "condition"=>"Ca_dose_response__1")
checkpoint() = (record["elapsed_seconds"] = time()-started; write_json(joinpath(out,"result.json"),record))
checkpoint()
Profile.init(; n=10^7, delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> begin
    Profile.print(joinpath(out,"sampled_profile.txt"); format=:flat, C=true, sortedby=:count)
    println("PROFILE_SAVED"); flush(stdout)
end
record["profile_ready"] = true
checkpoint()
try
    root = get(ENV,"ODEPE_PETAB_MODEL_ROOT","/tmp/odepe-petab-full-20260910/Benchmark-Models")
    adapter = load_petab_problem(joinpath(root,"Sneyd_PNAS2002","Sneyd_PNAS2002.yaml"))
    pep, _ = ODEPE.rescale_pep(adapter.algebraic)
    block = only(Ext._experiment_blocks(adapter, pep, [record["condition"]]))
    xs = collect(values(block.flat))
    jet = only(block.jets)
    record["steps"] = Any[]
    for order in 0:2
        if order > 0
            record["status"] = "differentiating_order_$order"
            checkpoint()
            stats = @timed sum((S.derivative(jet,x)*f for (x,f) in zip(xs,block.dynamics)); init=Num(0))
            jet = stats.value
            push!(record["steps"], (; operation="differentiate", order, seconds=stats.time, bytes=stats.bytes, gc_seconds=stats.gctime))
        end
        record["status"] = "flattening_order_$order"
        checkpoint()
        stats = @timed S.SymbolicUtils.flatten_fractions(S.value(jet))
        flat = Num(stats.value)
        push!(record["steps"], (; operation="flatten_without_polynomial_gcd", order,
            seconds=stats.time, bytes=stats.bytes, gc_seconds=stats.gctime,
            input_text_length=length(string(jet)), output_text_length=length(string(flat))))
        # Numerically check the proposed representation at ordinary positive
        # parameter/state probes. This is a diagnostic, not a production change.
        rng = MersenneTwister(20260911)
        variables = Num.(S.get_variables(jet))
        errors = Float64[]
        for _ in 1:5
            values = Dict(v=>0.5+rand(rng) for v in variables)
            a = Float64(S.value(S.substitute(jet, values)))
            b = Float64(S.value(S.substitute(flat, values)))
            push!(errors, abs(a-b)/max(1.0,abs(a),abs(b)))
        end
        record["steps"][end] = merge(record["steps"][end], (; max_relative_evaluation_difference=maximum(errors)))
        maximum(errors) < 1e-8 || error("Fraction flattening evaluation mismatch")
        checkpoint()
    end
    record["status"] = "original_clear_denoms_order_2"
    record["estimation_started_unix"] = time() # supervisor's isolated-operation clock
    checkpoint()
    println("CLEAR_DENOMS_START ", time()); flush(stdout)
    stats = @timed ODEPE.clear_denoms(jet ~ S.variable(:probe_y2))
    push!(record["steps"], (; operation="original_clear_denoms", order=2, seconds=stats.time,
        bytes=stats.bytes, gc_seconds=stats.gctime, output_text_length=length(string(stats.value))))
    record["status"] = "complete"
catch err
    record["status"] = err isa InterruptException ? "interrupted" : "failed"
    record["error"] = sprint(showerror,err,catch_backtrace())
finally
    Profile.stop_timer()
    !isempty(Profile.fetch()) && Profile.print(joinpath(out,"final_profile.txt"); format=:flat, C=true, sortedby=:count)
    checkpoint()
end
println("FINISHED ",record["status"]); flush(stdout)
