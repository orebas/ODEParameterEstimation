# Check physical-unit rescoring independently of any selected fitted branch.
using Pkg
Pkg.activate(get(ENV,"ODEPE_PETAB_ENV","/tmp/odepe-petab-pilot-env"))
include("model.jl")
length(ARGS) == 2 || error("Expected SPEC OUTPUT_JSON")
spec_path, output = ARGS
isfile(output) && error("Use a fresh output path")
spec = JSON.parsefile(spec_path)
record = Dict{String,Any}("status"=>"validating", "models"=>Dict{String,Any}(),
    "spec_sha256"=>bytes2hex(sha256(read(spec_path))),
    "scorer_source_sha256"=>bytes2hex(sha256(read(joinpath(@__DIR__,"model.jl")))))
write_json(output,record)
for model_kind in ("free","rational")
    study = study_problem(spec,model_kind,"root")
    candidate = (; parameters=study.pep.p_true,states=study.pep.ic,report_time=first(study.times))
    scores = score_candidate(study,candidate)
    @assert scores.original_y_sse < 1e-20
    @assert scores.root_z_sse < 1e-20
    @assert scores.predicted_linear_signal_min >= -1e-12
    rejected_wrong_time = try
        score_candidate(study,merge(candidate,(;report_time=0.1)))
        false
    catch err
        err isa AssertionError || rethrow()
        true
    end
    @assert rejected_wrong_time
    record["models"][model_kind] = (; scores..., rejected_wrong_report_time=rejected_wrong_time)
    write_json(output,record)
end
record["status"] = "complete"
write_json(output,record)
println("SCORE_VALIDATION_COMPLETE")
