# The target equals the generic starting data in both arms. Only the variable
# coordinates change, isolating initialization from the choice of shooting time.
include("dense_common.jl")
length(ARGS) == 2 || error("Expected MAIN_RUN FRESH_OUTPUT")
source_out, outarg = ARGS
out = abspath(outarg)
ispath(out) && error("Use a fresh output directory")
mkpath(out)
mkpath(joinpath(out, "source"))
for filename in ("check_generic_scaling.jl", "dense_common.jl", "anchor_hooks.jl", "capture_and_solve.jl")
    cp(joinpath(@__DIR__, filename), joinpath(out, "source", filename))
end
spec = JSON.parsefile(joinpath(source_out, "spec.json"))
family = JSON.parsefile(joinpath(source_out, "generic_system_1.json"))
cache = JSON.parsefile(joinpath(source_out, "generic_start_solutions.json"))
inputs = JSON.parsefile(joinpath(source_out, "parameter_homotopy_1.json"))
record = Dict{String,Any}("status"=>"preparing", "source_output"=>abspath(source_out),
    "started_ns"=>time_ns(), "pid"=>getpid(), "julia_version"=>string(VERSION),
    "scope"=>"Generic p0 to the identical p0, unscaled versus scaled variable coordinates; no real-data target or fresh solve",
    "manifest_sha256"=>bytes2hex(sha256(read(joinpath(dirname(Base.active_project()),"Manifest.toml")))))
@assert record["manifest_sha256"] == cache["manifest_sha256"]
@assert record["julia_version"] == cache["julia_version"]
checkpoint() = (record["elapsed_seconds"]=(time_ns()-record["started_ns"])/1e9;
    write_json(joinpath(out, "result.json"), record))
include("anchor_hooks.jl")
include("capture_and_solve.jl")
@assert family_fingerprint(family) == cache["family_fingerprint"]
variables = HC.ModelKit.Variable.(Symbol.(family["unknowns"]))
parameters = HC.ModelKit.Variable.(Symbol.(family["data_variables"]))
all_variables = vcat(variables, parameters)
expressions = map(family["polynomials"]) do row
    sum(row) do term
        coefficient = parse(BigInt, term["numerator"]) // parse(BigInt, term["denominator"])
        coefficient * prod(all_variables[j]^power for (j,power) in enumerate(term["exponents"]) if power != 0)
    end
end
system = HC.System(expressions; variables, parameters)
roots = [ComplexF64.(r,i) for (r,i) in zip(cache["solutions_real"], cache["solutions_imag"])]
p0 = ComplexF64.(cache["parameters_real"], cache["parameters_imag"])
@assert real.(p0) == family["generic_parameters_real"] && imag.(p0) == family["generic_parameters_imag"]
scales = Float64.(inputs["column_scales"])
record["column_scales"] = scales
record["gamma_rng_seed"] = 20260915
record["results"] = Any[]
record["status"] = "tracking"
checkpoint()
for scaled in (false, true)
    active_system = scaled ? ODEPE.scale_hc_system(system, variables, scales) : system
    starts = scaled ? [root ./ scales for root in roots] : roots
    result = ODEPE._track_gamma_straight(active_system, starts, p0, p0;
        rng=ODEPE.MersenneTwister(20260915), max_seeds=1, show_progress=true)
    paths = HC.path_results(result)
    summary = (; scaled, finite_roots=length(HC.solutions(result; only_nonsingular=false)),
        return_codes=string.([path.return_code for path in paths]),
        accepted_steps=[path.accepted_steps for path in paths],
        homotopy_t=[path.t for path in paths], hc_call=HC_CALL_INDEX[])
    push!(record["results"], summary)
    checkpoint()
    println("IDENTITY_CONTROL scaled=$(scaled) finite=$(summary.finite_roots)"); flush(stdout)
end
record["status"] = "complete"
checkpoint()
