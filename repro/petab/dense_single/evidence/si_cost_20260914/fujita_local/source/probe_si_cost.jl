# Read-only experiment: compare existing SI requests on the normal dense model.
include("common.jl")
using Logging
length(ARGS) == 5 || error("Expected MODEL MODE REPORT_JSON DATA_JSON OUTPUT_DIRECTORY")
model_name, mode, source_report, source_data, out = ARGS
mode in ("local", "global", "functions_absent", "functions_standard") || error("Unknown SI probe mode")
const SI = ODEPE.StructuralIdentifiability
Base.exit_on_sigint(false)
record = Dict{String,Any}("status"=>"preparing", "model"=>model_name, "mode"=>mode,
    "core_revision"=>strip(read(`git rev-parse HEAD`, String)), "julia_version"=>string(VERSION),
    "si_version"=>string(Base.pkgversion(SI)), "pid"=>getpid(), "profile_ready"=>true,
    "source_report_sha256"=>bytes2hex(sha256(read(source_report))),
    "source_data_sha256"=>bytes2hex(sha256(read(source_data))),
    "harness_sha256"=>bytes2hex(sha256(vcat(read(@__FILE__), read(joinpath(@__DIR__, "common.jl"))))))
checkpoint() = write_json(joinpath(out, "result.json"), record)
Profile.init(;n=10^7,delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> Profile.print(joinpath(out,"profile.txt");format=:flat,C=true,sortedby=:count)
checkpoint()
try
    original_record = JSON.parsefile(source_report)
    condition = original_record["condition"]
    extracted = single_condition(model_name, condition)
    # Guard against changes to the imported physical model since the dense run.
    for key in ("equations", "observations", "retained_states", "parameters")
        @assert json_safe(getproperty(extracted.record, Symbol(key))) == original_record["model_definition"][key]
    end
    record["physical_model_matches_retained_run"] = true
    raw = JSON.parsefile(source_data)
    data = OD{Union{String,Num},Vector{Float64}}("t"=>Float64.(raw["times"]))
    for (eq, signal) in zip(extracted.reduced.measured_quantities, raw["signals"])
        data[Num(eq.rhs)] = Float64.(signal["values"])
    end
    original = extracted.reduced
    pep = ParameterEstimationProblem(original.name, original.model, original.measured_quantities,
        data, original.recommended_time_interval, original.solver, original.p_true, original.ic, original.unident_count)
    pep, _ = ODEPE.rescale_pep(pep)
    si_ode, _, _ = ODEPE.convert_to_si_ode(pep.model, pep.measured_quantities)
    funcs = vcat(si_ode.parameters, si_ode.x_vars)
    record["parameters"] = string.(si_ode.parameters)
    record["states"] = string.(si_ode.x_vars)
    record["si_state_equations"] = Dict(string(x)=>string(f) for (x,f) in si_ode.x_equations)
    record["si_observation_equations"] = Dict(string(x)=>string(f) for (x,f) in si_ode.y_equations)
    record["status"] = "assessing"
    record["estimation_started_unix"] = time()
    checkpoint()
    if mode == "local"
        record["prob_threshold"] = 0.999 # Same local probability as assess_identifiability(p=0.99).
        record["experiment_type"] = "SE"
        record["trials"] = Any[]
        for seed in 20260914:20260916
            Random.seed!(seed)
            basis = ODEPE.Nemo.QQMPolyRingElem[]
            measurement = @timed SI.assess_local_identifiability(si_ode;
                funcs_to_check=funcs, prob_threshold=0.999, type=:SE,
                trbasis=basis, loglevel=Logging.Info)
            push!(record["trials"], Dict("seed"=>seed, "seconds"=>measurement.time,
                "compile_seconds"=>measurement.compile_time, "local_identifiability"=>measurement.value,
                "transcendence_basis"=>string.(basis)))
            checkpoint()
        end
    elseif mode == "global"
        Random.seed!(20260914)
        measurement = @timed SI.assess_identifiability(si_ode;
            funcs_to_check=funcs, prob_threshold=0.99, loglevel=Logging.Info)
        record["classification"] = measurement.value
        record["seconds"] = measurement.time
        record["compile_seconds"] = measurement.compile_time
    else
        simplify = mode == "functions_absent" ? :absent : :standard
        record["simplify"] = string(simplify)
        record["with_states"] = false
        checkpoint()
        measurement = @timed SI.find_identifiable_functions(si_ode;
            simplify, with_states=false, prob_threshold=0.99, seed=42, loglevel=Logging.Info)
        record["functions"] = string.(measurement.value)
        record["seconds"] = measurement.time
        record["compile_seconds"] = measurement.compile_time
    end
    record["status"] = "complete"
catch err
    record["status"] = err isa InterruptException ? "interrupted" : "failed"
    record["error"] = sprint(showerror, err, catch_backtrace())
finally
    haskey(record,"estimation_started_unix") && (record["operation_elapsed_seconds"] = time()-record["estimation_started_unix"])
    checkpoint()
end
println("FINISHED ", record["status"]); flush(stdout)
record["status"] == "complete" || exit(1)
