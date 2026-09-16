# Explicit Float64 coefficient boundary for HC's polyhedral entry point.
# The original rational system is retained for validation and certification.
using Pkg
Pkg.activate(get(ENV,"ODEPE_PETAB_ENV","/tmp/odepe-petab-pilot-env"))
using HomotopyContinuation, JSON, SHA, LinearAlgebra
const HC=HomotopyContinuation
length(ARGS)==2 || error("Expected SYSTEM_JSON OUTPUT_JSON")
input_path,output_path=ARGS
input=JSON.parsefile(input_path)
variables=[HC.ModelKit.Variable(Symbol(v)) for v in input["unknowns"]]
record=Dict{String,Any}("status"=>"running","coefficient_arithmetic"=>"Float64 cast of saved exact rational coefficients",
    "system_sha256"=>bytes2hex(sha256(read(input_path))),"worker_sha256"=>bytes2hex(sha256(read(@__FILE__))),
    "julia_version"=>string(VERSION),"hc_version"=>string(pkgversion(HC)),
    "truth_root_supplied"=>false,"seed"=>20260916,"runs"=>Any[])
function checkpoint()
    open(output_path*".tmp","w") do io; JSON.print(io,record,2); end
    mv(output_path*".tmp",output_path;force=true)
end
checkpoint()
for (label,key,indices) in [("raw_selected","polynomials",input["selected_rows"]),
                            ("row_reduced_selected","row_reduced_polynomials",input["row_reduced_selected_rows"])]
    exact_equations=HC.ModelKit.Expression[];float_equations=HC.ModelKit.Expression[]
    for row in input[key][Int.(indices).+1]
        exact=zero(variables[1]);floating=zero(variables[1])
        for term in row
            coefficient=parse(BigInt,term["numerator"])//parse(BigInt,term["denominator"])
            monomial=prod(v^Int(e) for (v,e) in zip(variables,term["exponents"]);init=1)
            exact+=coefficient*monomial;floating+=Float64(coefficient)*monomial
        end
        push!(exact_equations,exact);push!(float_equations,floating)
    end
    system=HC.System(float_equations;variables)
    exact_system=HC.System(exact_equations;variables)
    run=Dict{String,Any}("variant"=>label,"start_system"=>"polyhedral","status"=>"setup")
    push!(record["runs"],run);checkpoint()
    println("STAGE ",label);flush(stdout)
    try
        setup=@timed HC.solver_startsolutions(system;start_system=:polyhedral,compile=:all,
                                              seed=UInt32(20260916),show_progress=false)
        solver,starts=setup.value
        run["setup_seconds"]=setup.time;run["setup_compile_seconds"]=setup.compile_time
        run["start_paths"]=length(starts);checkpoint()
        tracking=@timed HC.solve(solver,starts;threading=false,show_progress=false)
        result=tracking.value;roots=HC.solutions(result;only_nonsingular=false)
        run["tracking_seconds"]=tracking.time;run["tracking_compile_seconds"]=tracking.compile_time
        codes=Dict{String,Int}()
        for path in HC.path_results(result)
            code=string(path.return_code);codes[code]=get(codes,code,0)+1
        end
        run["path_codes"]=codes;run["roots_real"]=real.(roots);run["roots_imag"]=imag.(roots)
        run["certified_distinct_roots_for_exact_system"]=isempty(roots) ? 0 :
            HC.ndistinct_certified(HC.certify(exact_system,roots;show_progress=false))
        run["status"]="complete"
        println("RESULT ",label," paths=",length(starts)," codes=",codes," roots=",length(roots));flush(stdout)
    catch err
        run["status"]="failed";run["error"]=sprint(showerror,err,catch_backtrace())
        println("FAILED ",run["error"]);flush(stdout)
    end
    checkpoint()
end
record["status"]="complete";checkpoint()
