# HC on the selected ORIGINAL equations in all 12 unknowns.
# Float64 is an explicit boundary; exact exported coefficients stay available.
using Pkg
Pkg.activate(get(ENV,"ODEPE_PETAB_ENV","/tmp/odepe-petab-pilot-env"))
using HomotopyContinuation, JSON, SHA, LinearAlgebra, Profile
const HC=HomotopyContinuation
length(ARGS)==5 || error("Expected SYSTEM_JSON OUTPUT_DIRECTORY SELECTION_JSON CASE SECONDS")
input_path,out,selection_path,label,seconds_arg=ARGS
input=JSON.parsefile(input_path);selection=JSON.parsefile(selection_path)
@assert selection["status"]=="complete"
@assert selection["input_sha256"]==bytes2hex(sha256(read(input_path)))
seconds=parse(Float64,seconds_arg)
Base.exit_on_sigint(false)
record=Dict{String,Any}("status"=>"building_system","profile_ready"=>true,
    "julia_version"=>string(VERSION),"hc_version"=>string(pkgversion(HC)),
    "input_sha256"=>bytes2hex(sha256(read(input_path))),
    "selection_sha256"=>bytes2hex(sha256(read(selection_path))),
    "worker_sha256"=>bytes2hex(sha256(read(@__FILE__))),
    "manifest_sha256"=>bytes2hex(sha256(read(joinpath(dirname(Base.active_project()),"Manifest.toml")))),
    "case"=>label,"seed"=>20260916,"truth_root_supplied"=>false,
    "parameter_elimination"=>false,"compile"=>"all","coefficient_arithmetic"=>"Float64",
    "row_normalization"=>"divide each exact polynomial by its largest absolute coefficient",
    "column_scaling"=>false,"only_non_zero"=>false,
    "selected_rows"=>selection["selected_rows"],"unknowns"=>input["unknowns"],
    "completeness"=>"not established", "paths_tracked"=>0,
    "path_return_codes"=>Dict{String,Int}(),"roots_real"=>Any[],"roots_imag"=>Any[])
function checkpoint()
    open(joinpath(out,"result.json.tmp"),"w") do io;JSON.print(io,record,2);end
    mv(joinpath(out,"result.json.tmp"),joinpath(out,"result.json");force=true)
end
function stage!(name)
    record["status"]=name;checkpoint();println("STAGE ",name);flush(stdout)
end
Profile.init(;n=10^7,delay=0.002)
Profile.set_peek_duration(5.0)
Profile.peek_report[] = () -> Profile.print(joinpath(out,"profile_$(time_ns()).txt");
    format=:flat,C=true,sortedby=:count)
checkpoint()
function rational(s)
    v=split(s,"/");parse(BigInt,v[1])//(length(v)==1 ? BigInt(1) : parse(BigInt,v[2]))
end
retained_roots=Vector{ComplexF64}[]
try
    variables=[HC.ModelKit.Variable(Symbol(v)) for v in input["unknowns"]]
    equations=HC.ModelKit.Expression[]
    exact_coefficients=[]
    for i in Int.(selection["selected_rows"])
        row=input["rows"][i];target=rational(input["cases"][label]["targets"][i])
        coefficients=Dict{Vector{Int},Rational{BigInt}}()
        for (key,factor) in (("numerator",big(1)//big(1)),("denominator",-target))
            for term in row[key]
                powers=Int.(term["exponents"])
                c=parse(BigInt,term["numerator"])//parse(BigInt,term["denominator"])
                coefficients[powers]=get(coefficients,powers,big(0)//big(1))+factor*c
            end
        end
        filter!(kv->!iszero(last(kv)),coefficients)
        scale=maximum(abs,values(coefficients));coefficients=Dict(e=>c/scale for (e,c) in coefficients)
        equation=zero(first(variables))
        for (powers,c) in sort!(collect(coefficients);by=first)
            equation+=Float64(c)*prod(v^e for (v,e) in zip(variables,powers);init=1)
        end
        actual=HC.ModelKit.to_dict(HC.expand(equation),variables)
        @assert keys(actual)==keys(coefficients)
        @assert all(Float64(HC.ModelKit.to_number(actual[e]))==Float64(c) for (e,c) in coefficients)
        push!(equations,equation);push!(exact_coefficients,coefficients)
    end
    system=HC.System(equations;variables)
    record["float_coefficient_roundtrip"]=true
    record["terms_per_equation"]=[length(c) for c in exact_coefficients]
    record["degrees"]=[maximum(sum,keys(c)) for c in exact_coefficients]
    record["total_degree_bound"]=string(prod(big.(record["degrees"])))
    record["operation_started_ns"]=time_ns();stage!("polyhedral_setup")
    setup=@timed HC.solver_startsolutions(system;start_system=:polyhedral,
        compile=:all,seed=UInt32(20260916),show_progress=true)
    solver,starts=setup.value
    record["setup_seconds"]=setup.time;record["setup_compile_seconds"]=setup.compile_time
    record["polyhedral_start_paths"]=length(starts)
    record["path_count_note"]="Default affine polyhedral support count, with origins added; not physical multiplicity M"
    stage!("polyhedral_tracking")
    started=time_ns();last_checkpoint=time_ns()
    for result in HC.solve(solver,starts;iterator_only=true)
        code=string(result.return_code);codes=record["path_return_codes"]
        codes[code]=get(codes,code,0)+1;record["paths_tracked"]+=1
        if HC.is_success(result)
            root=HC.solution(result);push!(retained_roots,root)
            push!(record["roots_real"],real.(root));push!(record["roots_imag"],imag.(root))
        end
        if record["paths_tracked"]%100==0 || (time_ns()-last_checkpoint)/1e9>15
            record["successful_endpoints"]=length(retained_roots)
            record["tracking_seconds"]=(time_ns()-started)/1e9
            checkpoint();last_checkpoint=time_ns()
        end
        (time_ns()-record["operation_started_ns"])/1e9>=seconds && break
    end
    record["tracking_seconds"]=(time_ns()-started)/1e9
    record["successful_endpoints"]=length(retained_roots)
    record["status"]=record["paths_tracked"]==length(starts) ? "complete" : "budget_exhausted"
catch err
    record["interrupted_stage"]=record["status"]
    record["status"]=err isa InterruptException ? "interrupted" : "failed"
    record["error"]=sprint(showerror,err,catch_backtrace())
finally
    haskey(record,"operation_started_ns") && (record["operation_seconds"]=(time_ns()-record["operation_started_ns"])/1e9)
    checkpoint()
end
println("FINISHED ",record["status"]);flush(stdout)
record["status"] in ("complete","budget_exhausted") || exit(1)
