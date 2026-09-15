# Bounded numerical root discovery for the separate Sneyd coefficient fibre.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using HomotopyContinuation, JSON, SHA, LinearAlgebra
const HC = HomotopyContinuation
Base.exit_on_sigint(false)
length(ARGS) == 3 || error("Expected counter.json output_directory seconds")
input, out, seconds_arg = ARGS
isdir(out) && error("Use a fresh output directory")
mkpath(out)
seconds = parse(Float64, seconds_arg)
data = JSON.parsefile(input)
rational(s) = begin
    parts = split(s, '/'); parse(BigInt, parts[1]) // (length(parts) == 1 ? big(1) : parse(BigInt, parts[2]))
end
nx, np = length(data["variables"]), length(data["parameters"])
x = [HC.ModelKit.Variable(Symbol("v$i")) for i in 1:nx]
p = [HC.ModelKit.Variable(Symbol("p$i")) for i in 1:np]
scales = rational.(vcat(data["start_root"], data["start_parameters"]))
symbols = vcat(x,p)
equations = HC.ModelKit.Expression[]
for terms in data["polynomials"]
    scaled = [rational(num*"/"*den)*prod(scales[i]^Int(exponents[i]) for i in eachindex(scales))
              for (num,den,exponents) in terms]
    normalization = maximum(abs, scaled)
    expression = zero(first(x))
    for ((_,_,exponents), coefficient) in zip(terms,scaled)
        expression += (coefficient/normalization)*prod(symbols[i]^Int(exponents[i]) for i in eachindex(symbols))
    end
    push!(equations,expression)
end
system = HC.System(equations; variables=x, parameters=p)
root, parameters = ones(ComplexF64,nx), ones(ComplexF64,np)
record = Dict{String,Any}("status"=>"ready", "input_sha256"=>bytes2hex(sha256(read(input))),
    "worker_sha256"=>bytes2hex(sha256(read(@__FILE__))),"julia_version"=>string(VERSION),
    "timeout_seconds"=>seconds,"start_residual"=>norm(HC.evaluate(system,root,parameters),Inf),
    "start_jacobian_condition"=>cond(HC.jacobian(system,root,parameters)),
    "method"=>"monodromy with known exact generic start, no group-action quotient", "seed"=>20260915,
    "completeness"=>"not established", "loop_root_counts"=>Int[])
checkpoint() = begin
    open(joinpath(out,"result.json.tmp"),"w") do io
        JSON.print(io,record,2)
    end
    mv(joinpath(out,"result.json.tmp"),joinpath(out,"result.json");force=true)
end
checkpoint()
println("SIDE_COUNT_READY ", record); flush(stdout)
started = time_ns()
try
    record["status"] = "monodromy"
    result = HC.monodromy_solve(system,[root],parameters;
        seed=UInt32(20260915),timeout=seconds,max_loops_no_progress=10,
        trace_test=false,show_progress=false,catch_interrupt=true,
        loop_finished_callback=results -> begin
            push!(record["loop_root_counts"],length(results)); checkpoint()
            println("SIDE_COUNT_LOOP roots=",length(results));flush(stdout)
            false
        end)
    roots = HC.solutions(result)
    record["return_code"] = string(result.returncode)
    record["monodromy_seconds"] = (time_ns()-started)/1e9
    record["roots_found"] = length(roots)
    record["scaled_roots_real"] = real.(roots)
    record["scaled_roots_imag"] = imag.(roots)
    record["status"] = "validating"
    checkpoint()
    certification = HC.certify(system,roots,parameters;show_progress=false)
    record["certified_distinct_roots"] = HC.ndistinct_certified(certification)
    c = reshape(ComplexF64.(data["observable_linear_weights"]),1,:)
    moments = ComplexF64.(rational.(data["sample_moments"]))
    function evaluate_terms(terms, values)
        sum(ComplexF64(rational(num*"/"*den))*prod(values[i]^Int(exponents[i]) for i in eachindex(values))
            for (num,den,exponents) in terms;init=0.0+0.0im)
    end
    checks = Any[]
    for candidate in roots
        theta = candidate[1:5].*Float64.(scales[1:5])
        matrix = [evaluate_terms(data["matrix"][i][j],theta)/
                  evaluate_terms(data["matrix_denominators"][i][j],theta) for i in 1:6,j in 1:6]
        obs = reduce(vcat,[c*matrix^i for i in 0:5])
        row_scales = vec(maximum(abs.(obs);dims=2))
        obs_scaled = obs./row_scales
        singular_values = svdvals(obs_scaled)
        initial = obs_scaled\(moments[1:6]./row_scales)
        reconstructed = [(c*matrix^i*initial)[1] for i in 0:11]
        relative_jet_error = maximum(abs.(reconstructed.-moments)./max.(1.0,abs.(moments)))
        push!(checks,Dict("observability_singular_value_ratio"=>last(singular_values)/first(singular_values),
            "relative_linear_jet_error"=>relative_jet_error,
            "scaled_polynomial_residual"=>norm(HC.evaluate(system,candidate,parameters),Inf),
            "kinetics_real"=>real.(theta),"kinetics_imag"=>imag.(theta),
            "initial_state_real"=>real.(initial),"initial_state_imag"=>imag.(initial)))
    end
    record["root_checks"] = checks
    regular = count(d -> d["observability_singular_value_ratio"]>1e-10 &&
        d["relative_linear_jet_error"]<1e-5 && d["scaled_polynomial_residual"]<1e-8,checks)
    record["regular_reconstructed_kinetic_roots"] = regular
    record["provisional_M"] = 4regular
    record["M_note"] = "Four fourth-root observable branches per regular kinetic root. Provisional: monodromy completeness and numerical reconstruction checks are not an exact multiplicity proof."
    record["status"] = "complete"
catch err
    record["status"] = err isa InterruptException ? "interrupted" : "failed"
    record["error"] = sprint(showerror,err,catch_backtrace())
finally
    record["elapsed_seconds"] = (time_ns()-started)/1e9
    checkpoint()
end
println("SIDE_COUNT_END ",record["status"]," roots=",get(record,"roots_found",0),
    " provisional_M=",get(record,"provisional_M",nothing));flush(stdout)
record["status"] == "complete" || exit(1)
