# A standalone HC experiment; the input file does not contain a truth root.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using HomotopyContinuation, JSON, SHA, LinearAlgebra
const HC = HomotopyContinuation
!isempty(ARGS) && iseven(length(ARGS)) || error("Expected SYSTEM_JSON OUTPUT_JSON pairs")
function main(input_path, output_path)
input = JSON.parsefile(input_path)
record = Dict{String,Any}(
    "status" => "building", "julia_version" => string(VERSION),
    "hc_version" => string(pkgversion(HC)),
    "manifest_sha256" => bytes2hex(sha256(read(joinpath(dirname(Base.active_project()), "Manifest.toml")))),
    "system_sha256" => bytes2hex(sha256(read(input_path))),
    "worker_sha256" => bytes2hex(sha256(read(@__FILE__))),
    "truth_root_supplied" => false, "seed" => 20260916, "runs" => Any[])

function save_record()
    open(output_path * ".tmp", "w") do io
        JSON.print(io, record, 2)
    end
    mv(output_path * ".tmp", output_path; force=true)
end

function expressions(rows, variables)
    equations = HC.ModelKit.Expression[]
    for row in rows
        equation = zero(first(variables))
        for term in row
            coefficient = parse(BigInt, term["numerator"]) // parse(BigInt, term["denominator"])
            equation += coefficient * prod(v^Int(e) for (v,e) in zip(variables,term["exponents"]); init=1)
        end
        push!(equations,equation)
        actual=HC.ModelKit.to_dict(HC.expand(equation),variables)
        expected=Dict(Int.(t["exponents"]) => parse(BigInt,t["numerator"]) // parse(BigInt,t["denominator"]) for t in row)
        @assert keys(actual)==keys(expected)
        @assert all(Rational{BigInt}(HC.ModelKit.to_number(actual[e]))==c for (e,c) in expected)
    end
    equations
end

variables=[HC.ModelKit.Variable(Symbol(name)) for name in input["unknowns"]]
all_equations=expressions(input["polynomials"],variables)
full_system=HC.System(all_equations;variables)
variants=[("raw_selected", all_equations[Int.(input["selected_rows"]).+1]),
          ("raw_all",all_equations)]
if haskey(input,"row_reduced_polynomials")
    reduced=expressions(input["row_reduced_polynomials"],variables)
    push!(variants,("row_reduced_selected",reduced[Int.(input["row_reduced_selected_rows"]).+1]))
    push!(variants,("row_reduced_all",reduced))
end
save_record()
for (label,equations) in variants
    for mode in (:polyhedral,:total_degree)
        result_record=Dict{String,Any}("variant"=>label,"start_system"=>string(mode),
                                      "equations"=>length(equations),"unknowns"=>length(variables))
        push!(record["runs"],result_record)
        record["status"]=label*"_"*string(mode)*"_setup";save_record()
        println("STAGE ",record["status"]);flush(stdout)
        try
            system=HC.System(equations;variables)
            timed_setup=@timed HC.solver_startsolutions(system;
                start_system=mode,compile=:all,seed=UInt32(20260916),show_progress=false)
            solver,starts=timed_setup.value
            result_record["setup_seconds"]=timed_setup.time
            result_record["setup_compile_seconds"]=timed_setup.compile_time
            result_record["start_paths"]=length(starts)
            record["status"]=label*"_"*string(mode)*"_tracking";save_record()
            timed_solve=@timed HC.solve(solver,starts;threading=false,show_progress=false)
            result=timed_solve.value
            result_record["tracking_seconds"]=timed_solve.time
            result_record["tracking_compile_seconds"]=timed_solve.compile_time
            codes=Dict{String,Int}()
            for path in HC.path_results(result)
                code=string(path.return_code);codes[code]=get(codes,code,0)+1
            end
            roots=HC.solutions(result;only_nonsingular=false)
            result_record["path_codes"]=codes
            result_record["roots_real"]=real.(roots)
            result_record["roots_imag"]=imag.(roots)
            result_record["full_reduced_residuals_inf"]=[norm(HC.evaluate(full_system,r),Inf) for r in roots]
            result_record["selected_jacobian_conditions"]=[cond(HC.jacobian(system,r)) for r in roots]
            if !isempty(roots) && length(equations)==length(variables)
                certified=@timed HC.certify(system,roots;show_progress=false)
                result_record["certification_seconds"]=certified.time
                result_record["certified_distinct_roots"]=HC.ndistinct_certified(certified.value)
            end
            result_record["status"]="complete"
            println("RESULT ",label," ",mode," paths=",length(starts)," codes=",codes,
                    " roots=",length(roots)," setup_s=",timed_setup.time," solve_s=",timed_solve.time)
            flush(stdout)
        catch err
            result_record["status"]="failed"
            result_record["error"]=sprint(showerror,err,catch_backtrace())
            println("FAILED ",result_record["error"]);flush(stdout)
        end
        save_record()
    end
end
record["status"]="complete";save_record()
end

for i in 1:2:length(ARGS)
    main(ARGS[i],ARGS[i+1])
end
