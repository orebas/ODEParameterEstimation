# Trace inputs to the existing GCD algorithm in an isolated Julia process.
# The method replacement only adds recording; production source is unchanged.
include("common.jl")
length(ARGS) == 1 || error("Expected output JSON path")
Base.exit_on_sigint(false)
const SU = S.SymbolicUtils
const MP = SU.MP
record = Dict{String,Any}("status"=>"preparing", "calls"=>Any[])
checkpoint() = write_json(only(ARGS), record)
checkpoint()

function polynomial_shape(p)
    ms = MP.monomials(p)
    return Dict("terms"=>length(ms), "variables"=>length(MP.variables(p)),
        "degree"=>maximum((sum(MP.exponents(m)) for m in ms); init=0),
        "coefficient_type"=>string(eltype(MP.coefficients(p))))
end

function trace_gcd(q1, q2)
    call = Dict{String,Any}("numerator"=>polynomial_shape(q1), "denominator"=>polynomial_shape(q2),
        "status"=>"entered", "numerator_polynomial"=>string(q1), "denominator_polynomial"=>string(q2))
    push!(record["calls"], call)
    checkpoint()
    start = time_ns()
    result = gcd(q1,q2)
    call["seconds"] = (time_ns()-start)/1e9
    call["gcd"] = polynomial_shape(result)
    call["status"] = "complete"
    checkpoint()
    return result
end

try
    root = get(ENV,"ODEPE_PETAB_MODEL_ROOT","/tmp/odepe-petab-full-20260910/Benchmark-Models")
    adapter = load_petab_problem(joinpath(root,"Sneyd_PNAS2002","Sneyd_PNAS2002.yaml"))
    pep, _ = ODEPE.rescale_pep(adapter.algebraic)
    block = only(Ext._experiment_blocks(adapter, pep, ["Ca_dose_response__1"]))
    xs = collect(values(block.flat))
    jet = only(block.jets)
    for _ in 1:2
        jet = sum((S.derivative(jet,x)*f for (x,f) in zip(xs,block.dynamics)); init=Num(0))
    end
    record["second_derivative"] = string(jet)
    record["state_equations"] = string.(block.dynamics)
    # Copy safe_gcd's dispatch exactly, then call the same Base.gcd implementation.
    @eval SU function safe_gcd(p1::Union{PolyVarT, PolynomialT}, p2::Union{PolyVarT, PolynomialT})
        q1 = p1 isa PolynomialT ? poly_to_gcd_form(p1) : p1
        q2 = p2 isa PolynomialT ? poly_to_gcd_form(p2) : p2
        return Main.trace_gcd(q1,q2)
    end
    record["status"] = "clearing"
    checkpoint()
    result = Base.invokelatest(ODEPE.clear_denoms, jet ~ S.variable(:probe_y2))
    record["result"] = string(result)
    record["status"] = "complete"
catch err
    record["status"] = err isa InterruptException ? "interrupted" : "failed"
    record["error"] = sprint(showerror,err,catch_backtrace())
finally
    checkpoint()
end
println("FINISHED ", record["status"])
