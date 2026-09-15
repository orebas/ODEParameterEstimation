# Count a frozen, verified polynomial system. No estimator or PEtab is loaded.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using Nemo, Groebner, JSON, SHA
# Script-mode Julia otherwise exits immediately on SIGINT, bypassing finally.
# Let the external timeout interrupt the calculation and save its last phase.
Base.exit_on_sigint(false)
length(ARGS) == 2 || error("Usage: count.jl input.json output.json")
input, output = abspath.(ARGS)
isfile(output) && error("Use a fresh output path")
record = JSON.parsefile(input)
ring, vars = polynomial_ring(QQ, String.(record["variables"]); internal_ordering=:degrevlex)
polynomials = QQMPolyRingElem[]
for terms in record["polynomials"]
    polynomial = zero(ring)
    for (num, den, exponents) in terms
        term = ring(QQ(parse(BigInt, num), parse(BigInt, den)))
        for i in eachindex(exponents)
            iszero(exponents[i]) || (term *= vars[i]^Int(exponents[i]))
        end
        polynomial += term
    end
    push!(polynomials, polynomial)
end
result = Dict{String,Any}("input_sha256"=>bytes2hex(sha256(read(input))),
    "julia_version"=>string(VERSION), "equations"=>length(polynomials), "variables"=>length(vars),
    "terms"=>sum(length, polynomials), "max_degree"=>maximum(total_degree, polynomials),
    "status"=>"running", "settings"=>"Groebner.groebner production defaults")
function save_result()
    open(output * ".tmp", "w") do io
        JSON.print(io, result, 2)
    end
    mv(output * ".tmp", output; force=true)
end
save_result()
println("GROEBNER_READY ", result); flush(stdout)
started = time_ns()
try
    basis = Groebner.groebner(polynomials)
    result["groebner_seconds"] = (time_ns()-started)*1e-9
    result["dimension"] = Groebner.dimension(basis)
    result["basis_length"] = length(basis)
    if result["dimension"] == 0
        result["multiplicity"] = length(Groebner.quotient_basis(basis))
    end
    result["status"] = "complete"
catch err
    result["groebner_seconds"] = (time_ns()-started)*1e-9
    result["status"] = err isa InterruptException ? "interrupted" : "error"
    result["error"] = sprint(showerror, err, catch_backtrace())
    rethrow()
finally
    save_result()
end
println(result)
