using ODEParameterEstimation, TOML, LinearAlgebra, SHA
const ODEPE = ODEParameterEstimation
const S = ODEPE.Symbolics
length(ARGS) == 3 || error("Expected capture TOML, method, output TOML")
capture = TOML.parsefile(ARGS[1])
mode = Symbol(ARGS[2])
mode in (:legacy_forwarddiff, :legacy_symbolic, :symbolic, :forwarddiff, :forwarddiff_auto, :finitediff) || error("Unknown mode")
for name in vcat(capture["solve_variables"],capture["data_variables"])
    Core.eval(Main, Expr(:(=),Symbol(name),QuoteNode(S.variable(Symbol(name)))))
end
vars = S.Num[getfield(Main,Symbol(n)) for n in capture["solve_variables"]]
dvars = S.Num[getfield(Main,Symbol(n)) for n in capture["data_variables"]]
equations = S.Num[Core.eval(Main,Meta.parse(s)) for s in capture["equations"]]
legacy = mode in (:legacy_forwarddiff,:legacy_symbolic)
if legacy
    root = normpath(joinpath(@__DIR__,"..",".."))
    source = read(Cmd(["git","-C",root,"show","cc0c973:src/core/solve_with_robust.jl"]),String)
    source = replace(source,"function solve_with_robust("=>"function legacy_solve_with_robust(")
    source = replace(source,"export solve_with_robust"=>"")
    Base.include_string(ODEPE,source,"legacy_solve_with_robust.jl")
end
method = mode in (:symbolic,:legacy_symbolic) ? :symbolic :
    mode==:finitediff ? :finitediff : :forwarddiff
record = Dict{String,Any}("method"=>string(mode),"julia_version"=>string(VERSION),
    "capture_sha256"=>bytes2hex(sha256(read(ARGS[1]))),"rows"=>Dict{String,Any}[])
safe(x::Union{AbstractString,Number,Bool}) = x
safe(x::AbstractDict) = Dict(string(k)=>safe(v) for (k,v) in x)
safe(x::AbstractArray) = safe.(x)
safe(x) = string(x)
checkpoint() = open(io->TOML.print(io,safe(record);sorted=true),ARGS[3],"w")
context = ODEPE.RunContext(;capture_timing=true)
Base.ScopedValues.with(ODEPE.RUN_CONTEXT=>context) do
    ODEPE._run_ctx_install_sinks!(NamedTuple[],NamedTuple[])
    preparation = @timed legacy ? nothing : ODEPE.prepare_robust_system(equations,vars;
        data_vars=dvars,jacobian=method,forwarddiff_chunk_size=mode==:forwarddiff_auto ? 0 : 1)
    kernel = preparation.value
    record["preparation_seconds"]=preparation.time
    checkpoint()
    for (i,(data,roots)) in enumerate(zip(capture["data_values"],capture["roots"]))
        legacy && i>2 && break # Bound the old per-point compilation comparison.
        values = Float64.(data)
        target = S.Num[S.substitute(eq,Dict(zip(dvars,values))) for eq in equations]
        for (j,root) in enumerate(roots)
            println("START $mode point $i root $j");flush(stdout)
            start = Float64.(root)
            result = @timed if legacy
                ODEPE.legacy_solve_with_robust(target,vars;start_point=start,polish_only=true,
                    options=Dict(:abstol=>1e-12,:reltol=>1e-12,:jacobian=>method,:debug=>false))
            else
                solve_with_robust(target,vars;start_point=start,polish_only=true,
                    prepared_system=kernel,data_values=values,
                    options=Dict(:abstol=>1e-12,:reltol=>1e-12,:debug=>false))
            end
            solutions = first(result.value)
            row = Dict{String,Any}("point"=>i,"root"=>j,"seconds"=>result.time,
                "compile_seconds"=>result.compile_time,"allocated_bytes"=>result.bytes,
                "solutions"=>solutions,"maxrss_bytes"=>Sys.maxrss())
            !isempty(context.detailed_timing_sink) &&
                (row["solver_timing"]=Dict(string(k)=>v for (k,v) in pairs(last(context.detailed_timing_sink)) if v!==nothing))
            push!(record["rows"],row)
            println("DONE $mode point $i root $j seconds=$(result.time) compile=$(result.compile_time) solutions=$(length(solutions))");flush(stdout)
            checkpoint()
        end
    end
end
record["status"]="complete"
checkpoint()
