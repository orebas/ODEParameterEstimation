# Diagnostic fan-out only: reuse the captured family and roots without invoking
# the fresh polyhedral fallback. This does not replace the production workflow.
include("dense_common.jl")
length(ARGS) == 2 || error("Expected COMPLETED_OR_CHECKPOINTED_RUN FRESH_OUTPUT")
source_out, outarg = ARGS
out = abspath(outarg)
ispath(out) && error("Use a fresh output directory")
mkpath(out)
source_snapshot = joinpath(out, "source")
mkpath(source_snapshot)
for filename in ("replay_targets.jl", "dense_common.jl", "anchor_hooks.jl", "capture_and_solve.jl")
    cp(joinpath(@__DIR__, filename), joinpath(source_snapshot, filename))
end
spec = JSON.parsefile(joinpath(source_out, "spec.json"))
source_record = JSON.parsefile(joinpath(source_out, "result.json"))
family = JSON.parsefile(joinpath(source_out, "generic_system_1.json"))
cache = JSON.parsefile(joinpath(source_out, "generic_start_solutions.json"))
inputs = JSON.parsefile(joinpath(source_out, "parameter_homotopy_1.json"))
record = Dict{String,Any}("status"=>"preparing", "source_output"=>abspath(source_out),
    "julia_version"=>string(VERSION), "started_ns"=>time_ns(), "pid"=>getpid(),
    "scope"=>"Diagnostic gamma fan-out only, with no fresh-polyhedral fallback or fit; fixed scales and RNG across anchors",
    "manifest_sha256"=>bytes2hex(sha256(read(joinpath(dirname(Base.active_project()),"Manifest.toml")))))
record["source_sha256"] = Dict(filename=>bytes2hex(sha256(read(joinpath(source_snapshot, filename))))
    for filename in readdir(source_snapshot))
record["manifest_sha256"] == cache["manifest_sha256"] || error("Environment differs from cached roots")
record["julia_version"] == cache["julia_version"] || error("Julia version differs from cached roots")
checkpoint() = (record["elapsed_seconds"]=(time_ns()-record["started_ns"])/1e9;
    write_json(joinpath(out, "result.json"), record))
include("anchor_hooks.jl")
include("capture_and_solve.jl")
family_fingerprint(family) == cache["family_fingerprint"] || error("Cached family mismatch")

# Reconstruct the exact polynomial support and rational coefficients, retaining
# the recorded variable and data order. Capture equality is checked again below.
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
for (expression, row) in zip(HC.expressions(system), family["polynomials"])
    dictionary = HC.ModelKit.to_dict(HC.expand(expression), all_variables)
    @assert length(dictionary) == length(row)
    for term in row
        exponent = Int.(term["exponents"])
        expected = parse(BigInt, term["numerator"]) // parse(BigInt, term["denominator"])
        @assert Rational{BigInt}(HC.ModelKit.to_number(dictionary[exponent])) == expected
    end
end
roots = [ComplexF64.(r,i) for (r,i) in zip(cache["solutions_real"], cache["solutions_imag"])]
p0 = ComplexF64.(cache["parameters_real"], cache["parameters_imag"])
scales = Float64.(inputs["column_scales"])
@assert scales == ODEPE.compute_column_scales(family["original_unknowns"],
    family["original_data_variables"], inputs["parameters"])
scaled_system = ODEPE.scale_hc_system(system, variables, scales)
scaled_roots = [root ./ scales for root in roots]
requested_times = Float64.(source_record["anchor_selection"]["selected_times"])
targets = [Float64.(p) for p in inputs["parameters"]]

# Identify the actual interpolator by the evaluated data vector, rather than
# assuming it was the first diagnostic dictionary seen during construction.
control = nothing
times = Float64[]
for filename in readdir(source_out)
    startswith(filename, "interpolated_targets_") && endswith(filename, ".json") || continue
    packet = JSON.parsefile(joinpath(source_out, filename))
    lookup = packet["values_by_time"]
    matching_times = [[t for t in requested_times if get(lookup, string(t), nothing) == values]
        for values in targets]
    if all(ts -> length(ts) == 1, matching_times)
        # Production can drop nonfinite or rank-deficient points before HC.
        # Associate targets by their actual vectors, not their ordinal positions.
        global times = only.(matching_times)
        global control = Float64.(packet["t_zero_control"])
        record["interpolator_packet"] = filename
        break
    end
end
isnothing(control) && error("Could not match saved interpolation data for t=0 control")
record["requested_times"] = requested_times
record["times_passed_to_hc"] = times
selection = unique([1, argmin(abs.(times .- 0.2)), argmin(abs.(times .- 0.5)),
    argmin(abs.(times .- 0.8)), length(times)])
comparison = [(; time=0.0, values=control)]
append!(comparison, [(; time=times[i], values=targets[i]) for i in selection])
record["column_scales"] = scales
record["generic_start_count"] = length(roots)
record["targets"] = comparison
record["gamma_rng_seed"] = 20260915
record["gamma_max_seeds"] = 5
record["status"] = "tracking"
record["anchor_results"] = Any[]
checkpoint()
function target_residual(root, target)
    return setprecision(BigFloat, 256) do
        values = Complex{BigFloat}.(vcat(root, target))
        residuals = map(family["polynomials"]) do row
            terms = map(row) do term
                coefficient = parse(BigFloat, term["numerator"]) / parse(BigFloat, term["denominator"])
                coefficient * prod(values[j]^power for (j,power) in enumerate(term["exponents"]) if power != 0)
            end
            total = sum(terms)
            denominator = sum(abs, terms)
            (; absolute=abs(total), relative=iszero(denominator) ? zero(BigFloat) : abs(total)/denominator)
        end
        (; maximum_absolute=Float64(maximum(r.absolute for r in residuals)),
            maximum_relative_to_term_sum=Float64(maximum(r.relative for r in residuals)))
    end
end
for target in comparison
    started = time_ns()
    first_call = HC_CALL_INDEX[] + 1
    # Reset to the identical gamma stream for each target: only the data vector
    # changes within this panel. Production-derived RNG is recorded by the main run.
    result = ODEPE._track_gamma_straight(scaled_system, scaled_roots, p0, target.values;
        rng=ODEPE.MersenneTwister(20260915), max_seeds=5, show_progress=true)
    retained = HC.solutions(result; only_nonsingular=false)
    push!(record["anchor_results"], (; time=target.time, seconds=(time_ns()-started)/1e9,
        first_call, last_call=HC_CALL_INDEX[], finite_roots=length(retained),
        real_roots=length(HC.solutions(result; only_nonsingular=false, only_real=true)),
        target_residuals=[target_residual(scales .* root, target.values) for root in retained],
        unscaled_solutions_real=[real.(scales .* root) for root in retained],
        unscaled_solutions_imag=[imag.(scales .* root) for root in retained]))
    checkpoint()
    println("ANCHOR_RESULT t=$(target.time) finite=$(length(retained))"); flush(stdout)
end
record["status"] = "complete"
checkpoint()
