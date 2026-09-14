# Bounded externally: record the exact input before entering mixed volume or HC.
using Pkg
Pkg.activate(get(ENV,"ODEPE_PETAB_ENV","/tmp/odepe-petab-pilot-env"))
using HomotopyContinuation, JSON, SHA, Random, Profile
const HC = HomotopyContinuation
length(ARGS) in (2,3) || error("Expected SYSTEM_JSON OUTPUT_JSON [original|few_terms]")
ordering=length(ARGS)==3 ? Symbol(ARGS[3]) : :original
ordering in (:original,:few_terms) || error("Unsupported equation order")
Base.exit_on_sigint(false)
Random.seed!(20260914)
input=JSON.parsefile(ARGS[1])
record=Dict{String,Any}("status"=>"converting","input"=>abspath(ARGS[1]),
    "input_sha256"=>bytes2hex(sha256(read(ARGS[1]))),"julia_version"=>string(VERSION),
    "pid"=>getpid(),"equations"=>length(input["equations"]),"unknowns"=>length(input["unknowns"]),
    "data_variables"=>length(input["data_variables"]),"profile_ready"=>true,
    "ordering"=>string(ordering),"harness_sha256"=>bytes2hex(sha256(read(@__FILE__))))
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
traverser=nothing
try
    for name in vcat(input["unknowns"],input["data_variables"])
        Core.eval(Main,Expr(:(=),Symbol(name),QuoteNode(HC.ModelKit.Variable(Symbol(name)))))
    end
    variables=[getfield(Main,Symbol(n)) for n in input["unknowns"]]
    data=[getfield(Main,Symbol(n)) for n in input["data_variables"]]
    equations=[Core.eval(Main,Meta.parse(replace(s,"**"=>"^"))) for s in input["equations"]]
    system=HC.System(equations;variables,parameters=data)
    supports,_=HC.support_coefficients(system)
    permutation=ordering==:few_terms ? sortperm(eachindex(supports);by=i->(size(supports[i],2),maximum(sum(supports[i];dims=1)),i)) : collect(eachindex(supports))
    record["equation_permutation"]=permutation
    record["status"]="mixed_volume"
    record["operation_started_unix"]=time()
    checkpoint()
    println("MIXED_VOLUME_START equations=$(length(equations)) unknowns=$(length(variables))");flush(stdout)
    # This is the same torus mixed-volume traversal used by HC.mixed_volume.
    # Expose the traverser to retain its stage if the first cell is expensive.
    measurement=@timed begin
        global traverser=HC.MixedSubdivisions.traverser(supports[permutation])
        volume=big(0)
        cells=0
        while !HC.MixedSubdivisions.next_cell!(traverser)
            volume+=HC.MixedSubdivisions.mixed_cell(traverser).volume
            cells+=1
            record["completed_mixed_cells"]=cells
            record["partial_volume"]=string(volume)
            checkpoint()
        end
        volume
    end
    record["mixed_volume"]=string(measurement.value)
    record["mixed_volume_seconds"]=measurement.time
    record["mixed_volume_compile_seconds"]=measurement.compile_time
    record["status"]="complete"
catch err
    record["status"]=err isa InterruptException ? "interrupted" : "failed"
    record["error"]=sprint(showerror,err,catch_backtrace())
finally
    !isnothing(traverser) && (record["regeneration_stage_at_exit"]=traverser.stage)
    haskey(record,"operation_started_unix") && (record["operation_elapsed_seconds"]=time()-record["operation_started_unix"])
    checkpoint()
end
println("FINISHED ",record["status"]);flush(stdout)
record["status"]=="complete" || exit(1)
