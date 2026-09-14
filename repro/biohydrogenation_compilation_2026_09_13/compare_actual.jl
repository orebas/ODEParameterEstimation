using ODEParameterEstimation, TOML, LinearAlgebra
const ODEPE = ODEParameterEstimation
const S = ODEPE.Symbolics
const FD = ODEPE.ForwardDiff
const HC = ODEPE.HomotopyContinuation
length(ARGS) == 2 || error("Expected captured TOML and output TOML")
capture = TOML.parsefile(ARGS[1])
for name in vcat(capture["solve_variables"], capture["data_variables"])
    Core.eval(Main, Expr(:(=), Symbol(name), QuoteNode(S.variable(Symbol(name)))))
end
vars = S.Num[getfield(Main, Symbol(n)) for n in capture["solve_variables"]]
dvars = S.Num[getfield(Main, Symbol(n)) for n in capture["data_variables"]]
equations = S.Num[Core.eval(Main, Meta.parse(s)) for s in capture["equations"]]
points = [(Float64.(values), Float64.(root)) for (values, roots) in
    zip(capture["data_values"], capture["roots"]) for root in roots]
data, x = first(points)
m, n = length(equations), length(vars)
record = Dict{String,Any}("julia_version"=>string(VERSION), "capture"=>abspath(ARGS[1]),
    "equations"=>m, "variables"=>n, "data_variables"=>length(dvars), "root_count"=>length(points),
    "rows"=>Dict{String,Any}[])
function checkpoint()
    open(ARGS[2], "w") do io
        TOML.print(io,record;sorted=true)
    end
end
function mark(label)
    println(label); flush(stdout); checkpoint()
end
mark("Construct reference symbolic Jacobian")
jacobian_construction = @timed S.jacobian(equations,vars)
Jexpr = jacobian_construction.value
record["symbolic_differentiation_seconds"] = jacobian_construction.time
record["symbolic_differentiation_compile_seconds"] = jacobian_construction.compile_time
ref_ip = S.build_function(Jexpr,vars,dvars;expression=Val(false))[2]
reference(u,p) = setprecision(256) do
    J = zeros(BigFloat,m,n)
    ref_ip(J,BigFloat.(u),BigFloat.(p))
    Float64.(J)
end
refs = [reference(u,p) for (p,u) in points]
residual_construction = @timed S.build_function(equations,vars,dvars;expression=Val(false))[2]
residual_ip = residual_construction.value
record["shared_residual_build_seconds"] = residual_construction.time
hc_system = nothing
for mode in (:symbolic, :forwarddiff1, :forwarddiff_auto, :finite_central, :complex_step,
    :hc_interpreted, :hc_compiled)
    mark("Preparing $mode")
    build = @timed if mode == :symbolic
        S.build_function(Jexpr,vars,dvars;expression=Val(false))[2]
    elseif mode in (:forwarddiff1,:forwarddiff_auto)
        p_ref = Ref(data)
        r = zeros(m)
        f! = (r,u) -> residual_ip(r,u,p_ref[])
        cfg = FD.JacobianConfig(f!,r,x,mode==:forwarddiff1 ? FD.Chunk{1}() : FD.Chunk(x))
        (J,u,p) -> (p_ref[]=p; FD.jacobian!(J,f!,r,u,cfg))
    elseif mode == :finite_central
        (J,u,p) -> begin
            up,um = copy(u),copy(u)
            rp,rm = zeros(m),zeros(m)
            for j in eachindex(u)
                h = cbrt(eps(Float64))*max(abs(u[j]),1.0)
                up[j]=u[j]+h; um[j]=u[j]-h
                residual_ip(rp,up,p); residual_ip(rm,um,p)
                J[:,j] .= (rp.-rm)./(2h)
                up[j]=um[j]=u[j]
            end
        end
    elseif mode == :complex_step
        (J,u,p) -> begin
            uc,rc = ComplexF64.(u),zeros(ComplexF64,m)
            for j in eachindex(u)
                uc[j]=u[j]+1e-30im
                residual_ip(rc,uc,p)
                J[:,j] .= imag.(rc)./1e-30
                uc[j]=u[j]
            end
        end
    else
        F = first(ODEPE.convert_to_hc_format_with_params(equations,vars,dvars))
        sys = mode==:hc_interpreted ? HC.InterpretedSystem(F) : HC.CompiledSystem(F)
        (J,u,p) -> HC.jacobian!(J,sys,u,p)
    end
    jac! = build.value
    J = zeros(m,n)
    mark("First evaluation $mode")
    cold = @timed jac!(J,x,data)
    first_error = norm(J-refs[1])/max(norm(refs[1]),eps())
    sweep = @timed begin
        errors = Float64[]
        for ((p,u),ref) in zip(points,refs)
            jac!(J,u,p)
            push!(errors,norm(J-ref)/max(norm(ref),eps()))
        end
        errors
    end
    warm = @timed for _ in 1:1000
        jac!(J,x,data)
    end
    row = Dict("method"=>string(mode),"build_seconds"=>build.time,
        "first_seconds"=>cold.time,"first_compile_seconds"=>cold.compile_time,
        "warm_seconds_per_call"=>warm.time/1000,"warm_bytes_per_call"=>warm.bytes/1000,
        "root_sweep_seconds"=>sweep.time,"root_sweep_compile_seconds"=>sweep.compile_time,
        "max_relative_jacobian_error"=>maximum(sweep.value),"first_relative_jacobian_error"=>first_error)
    push!(record["rows"],row)
    println(row);flush(stdout);checkpoint()
end
record["status"]="complete"
checkpoint()
