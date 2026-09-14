# Bounded externally: record the exact input before entering mixed volume or HC.
using Pkg
Pkg.activate(get(ENV,"ODEPE_PETAB_ENV","/tmp/odepe-petab-pilot-env"))
using HomotopyContinuation, JSON, SHA, Random, Profile
const HC = HomotopyContinuation
length(ARGS)==2 || error("Expected SYSTEM_JSON OUTPUT_JSON")
Base.exit_on_sigint(false)
Random.seed!(20260914)
input=JSON.parsefile(ARGS[1])
record=Dict{String,Any}("status"=>"converting","input"=>abspath(ARGS[1]),
    "input_sha256"=>bytes2hex(sha256(read(ARGS[1]))),"julia_version"=>string(VERSION),
    "pid"=>getpid(),"equations"=>length(input["equations"]),"unknowns"=>length(input["unknowns"]),
    "data_variables"=>length(input["data_variables"]),"profile_ready"=>true)
function checkpoint()
    open(ARGS[2]*".tmp","w") do io
        JSON.print(io,record)
    end
    mv(ARGS[2]*".tmp",ARGS[2];force=true)
end
Profile.init(;n=10^7,delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> Profile.print(ARGS[2]*".profile.txt";format=:flat,C=true,sortedby=:count)
checkpoint()
try
    for name in vcat(input["unknowns"],input["data_variables"])
        Core.eval(Main,Expr(:(=),Symbol(name),QuoteNode(HC.ModelKit.Variable(Symbol(name)))))
    end
    variables=[getfield(Main,Symbol(n)) for n in input["unknowns"]]
    data=[getfield(Main,Symbol(n)) for n in input["data_variables"]]
    equations=[Core.eval(Main,Meta.parse(replace(s,"**"=>"^"))) for s in input["equations"]]
    system=HC.System(equations;variables,parameters=data)
    record["status"]="mixed_volume"
    record["operation_started_unix"]=time()
    checkpoint()
    println("MIXED_VOLUME_START equations=$(length(equations)) unknowns=$(length(variables))");flush(stdout)
    measurement=@timed HC.mixed_volume(system)
    record["mixed_volume"]=measurement.value
    record["mixed_volume_seconds"]=measurement.time
    record["mixed_volume_compile_seconds"]=measurement.compile_time
    record["status"]="complete"
catch err
    record["status"]=err isa InterruptException ? "interrupted" : "failed"
    record["error"]=sprint(showerror,err,catch_backtrace())
finally
    haskey(record,"operation_started_unix") && (record["operation_elapsed_seconds"]=time()-record["operation_started_unix"])
    checkpoint()
end
println("FINISHED ",record["status"]);flush(stdout)
record["status"]=="complete" || exit(1)
