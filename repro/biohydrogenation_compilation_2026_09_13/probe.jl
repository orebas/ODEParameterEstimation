# Isolated diagnostic on the retained SI template, not an estimation run.
# Data-jet values and the evaluation point are deterministic synthetic values.
# The saved template's Jacobian is independent of those data-jet values.
using ODEParameterEstimation, TOML, LinearAlgebra
const S = ODEParameterEstimation.Symbolics
const FD = ODEParameterEstimation.ForwardDiff
const Num = S.Num

const SOURCE = normpath(joinpath(@__DIR__, "..", "deferred_denominators_2026_09_11", "evidence", "biohydrogenation_si_template.jl"))
length(ARGS) == 1 || error("Expected output TOML path")
text = read(SOURCE, String)
names = split(strip(split(split(text, "varlist_str = \"\"\"")[2], "\"\"\"")[1]), '\n')
renamed = Dict(name => occursin('(', name) ? "data_$(i)" : name for (i, name) in enumerate(names))
body = split(split(text, "poly_system = [")[2], "\n]")[1]
for name in sort(collect(keys(renamed)); by=length, rev=true)
    global body = replace(body, name => renamed[name])
end
# Evaluate only expressions from the repository's retained trusted snapshot.
for name in names
    clean = renamed[name]
    Core.eval(@__MODULE__, Meta.parse("S.@variables " * clean))
end
template = Num.(Core.eval(@__MODULE__, Meta.parse("[" * body * "\n]")))
vars = Num[getfield(@__MODULE__, Symbol(renamed[name])) for name in names if !occursin('(', name)]
data_vars = Num[getfield(@__MODULE__, Symbol(renamed[name])) for name in names if occursin('(', name)]
u = [0.25 + 0.013i for i in eachindex(vars)]
data1 = [0.41 + 0.017i for i in eachindex(data_vars)]
data2 = data1 .+ 0.001
rows = Dict{String, Any}[]
record = Dict{String, Any}("julia_version"=>string(VERSION), "source"=>SOURCE,
    "equations"=>length(template), "variables"=>length(vars), "data_variables"=>length(data_vars),
    "automatic_chunk_size"=>FD.chunksize(FD.Chunk(u)),
    "synthetic_evaluation_point"=>u, "synthetic_data1"=>data1, "rows"=>rows)
function checkpoint()
    open(only(ARGS), "w") do io
        TOML.print(io, record; sorted=true)
    end
end
function mark(label)
    println(label); flush(stdout)
    checkpoint()
end
instantiate(values) = Num[S.substitute(eq, Dict(zip(data_vars, values))) for eq in template]
function make_f_ip(polys, vars)
    ip = S.build_function(polys, vars; expression=Val(false))[2]
    m = length(polys)
    return u_ -> (r = similar(u_, m); ip(r, u_); r)
end
function time_jacobian(label, f, u, chunk)
    cfg = FD.JacobianConfig(f, u, chunk)
    J = zeros(length(template), length(u))
    mark("$label: first Jacobian")
    cold = @timed FD.jacobian!(J, f, u, cfg)
    reference = copy(J)
    warm = @timed FD.jacobian!(J, f, u, cfg)
    @assert J == reference
    row = Dict{String, Any}("label"=>label, "first_seconds"=>cold.time,
        "first_compile_seconds"=>cold.compile_time, "second_seconds"=>warm.time,
        "chunk_size"=>FD.chunksize(chunk), "jacobian_norm"=>norm(J))
    push!(rows, row)
    println(row); flush(stdout); checkpoint()
    return J
end
mark("loaded; dimensions $(length(template)) × $(length(vars)); automatic chunk $(FD.chunksize(FD.Chunk(u)))")
polys1, polys2 = instantiate(data1), instantiate(data2)
f1 = make_f_ip(polys1, vars)
J1 = time_jacobian("numeric_chunk1", f1, u, FD.Chunk{1}())
J9 = time_jacobian("numeric_automatic", f1, u, FD.Chunk(u))
@assert J1 ≈ J9 rtol=1e-13 atol=1e-13
f2 = make_f_ip(polys2, vars)
J2 = time_jacobian("numeric_automatic_changed_data", f2, u, FD.Chunk(u))
@assert J2 == J9
mark("symbolic Jacobian: build")
jbuild = @timed S.build_function(S.jacobian(polys1, vars), vars; expression=Val(false))[2]
jip = jbuild.value
Js = similar(J1)
mark("symbolic Jacobian: first evaluation")
jfirst = @timed jip(Js, u)
jsecond = @timed jip(Js, u)
@assert Js ≈ J1 rtol=1e-13 atol=1e-13
push!(rows, Dict("label"=>"symbolic", "build_seconds"=>jbuild.time,
    "first_seconds"=>jfirst.time, "first_compile_seconds"=>jfirst.compile_time,
    "second_seconds"=>jsecond.time, "max_difference_from_chunk1"=>maximum(abs,Js-J1)))
mark("parameterized residual: build")
parameterized_ip = S.build_function(template, vars, data_vars; expression=Val(false))[2]
function parameterized_residual(ip, values, m)
    return u_ -> (r = similar(u_, m); ip(r, u_, values); r)
end
fp1 = parameterized_residual(parameterized_ip, data1, length(template))
fp2 = parameterized_residual(parameterized_ip, data2, length(template))
Jp1 = time_jacobian("parameterized_automatic", fp1, u, FD.Chunk(u))
Jp2 = time_jacobian("parameterized_automatic_changed_data", fp2, u, FD.Chunk(u))
@assert Jp1 ≈ J1 rtol=1e-13 atol=1e-13
@assert Jp2 == Jp1
record["status"] = "passed"
record["max_jacobian_difference"] = maximum([maximum(abs, J-J1) for J in (J9,J2,Js,Jp1,Jp2)])
mark("all Jacobian comparisons passed")
