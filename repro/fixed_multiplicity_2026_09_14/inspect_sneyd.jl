# Inspect multiplicity inputs without running Groebner or changing production methods.
using ODEParameterEstimation, Random, TOML, SHA
const ODEPE = ODEParameterEstimation
const N = ODEPE.Nemo
const SI = ODEPE.StructuralIdentifiability
length(ARGS) == 1 || error("Expected fresh output directory")
out = abspath(only(ARGS))
isdir(out) && error("Use a fresh output directory")
mkpath(out)
model_file = joinpath(@__DIR__, "sneyd_si_model.toml")
record = TOML.parsefile(model_file)
names = vcat(record["states"], record["outputs"], record["parameters"])
ring, variables = N.polynomial_ring(N.QQ, names)
for (name, variable) in zip(names, variables)
    @eval $(Symbol(name)) = $variable
end
by_name = Dict(zip(names, variables))
FF = N.fraction_field(ring)
F = typeof(FF(0))
states = [by_name[name] for name in record["states"]]
outputs = [by_name[name] for name in record["outputs"]]
state_eqs = Dict{N.QQMPolyRingElem,F}(by_name[name] => FF(eval(Meta.parse(eq))) for (name, eq) in record["state_equations"])
output_eqs = Dict{N.QQMPolyRingElem,F}(by_name[name] => FF(eval(Meta.parse(eq))) for (name, eq) in record["output_equations"])
ode = SI.ODE{N.QQMPolyRingElem}(states, outputs, state_eqs, output_eqs, N.QQMPolyRingElem[])

# Copy only the existing construction prefix into a separately named diagnostic
# function. Stop before M's gating/solving code, then call the production input
# preparation helper. This lets us inspect the unfixed positive-dimensional case.
source_path = joinpath(dirname(dirname(pathof(ODEPE))), "src/core/si_equation_builder.jl")
source = read(source_path, String)
start = first(findfirst("function get_polynomial_system_from_sian(", source))
stop = first(findnext("\t# Count solutions of the representative-fixed ideal", source, start))-1
body = replace(source[start:stop], "function get_polynomial_system_from_sian(" =>
    "function inspect_sneyd_multiplicity_input(", count=1)
body *= "\treturn _prepare_sian_multiplicity_system(si_ode, Et, Q, X_eq, Y_eq, all_params, sample, D1; pre_fixed_params)\nend\n"
Base.include_string(ODEPE, body, "inspect_sneyd_multiplicity_input.jl")
write(joinpath(out, "construction_prefix.jl"),body)

function shape(poly)
    cs = collect(N.coefficients(poly))
    return Dict("terms"=>length(poly), "total_degree"=>Int(N.total_degree(poly)),
        "max_numerator_digits"=>maximum(length(string(abs(N.numerator(c)))) for c in cs; init=0),
        "max_denominator_digits"=>maximum(length(string(N.denominator(c))) for c in cs; init=0))
end
fixed_names = ["l2","k_4","k_3","k_2","k_1","k4","k3","k2","k1"]
for mode in ("unfixed","fixed")
    fixes = ODEPE.OrderedDict(name=>1.0 for name in (mode == "fixed" ? fixed_names : String[]))
    Random.seed!(20260914)
    seconds = @elapsed input = Base.invokelatest(ODEPE.inspect_sneyd_multiplicity_input,
        ode,vcat(ode.parameters,ode.x_vars);pre_fixed_params=fixes)
    verified = all(p -> iszero(N.evaluate(p,input.point)),input.polynomials)
    @assert verified
    stats = [merge(Dict("index"=>i),shape(poly)) for (i,poly) in enumerate(input.polynomials)]
    summary = Dict("mode"=>mode,"source_sha256"=>bytes2hex(sha256(source)),
        "model_sha256"=>bytes2hex(sha256(read(model_file))),"julia_version"=>string(VERSION),
        "seed"=>20260914,"seconds"=>seconds,"sample_verified"=>verified,
        "polynomials"=>length(stats),"variables"=>string.(N.gens(input.ring)),
        "total_terms"=>sum(s["terms"] for s in stats),
        "max_degree"=>maximum(s["total_degree"] for s in stats),
        "jacobian_rank_without_auxiliary"=>input.jacobian_rank,
        "linearized_dimension"=>N.ngens(input.ring)-1-input.jacobian_rank,
        "locally_identifiable"=>string.(input.locally_identifiable),
        "fixed_coordinates"=>Dict(string(k)=>string(v) for (k,v) in input.fixed_coordinates),
        "polynomial_stats"=>stats)
    open(joinpath(out,mode*".toml"),"w") do io
        TOML.print(io,summary)
    end
    open(joinpath(out,mode*"_polynomials.txt"),"w") do io
        for (i,p) in enumerate(input.polynomials)
            println(io,"# Polynomial ",i," ",stats[i])
            println(io,p," = 0\n")
        end
    end
    println(mode,": ",length(stats)," polynomials, ",N.ngens(input.ring)," variables, ",summary["total_terms"]," terms; dimension ",summary["linearized_dimension"])
    flush(stdout)
end
