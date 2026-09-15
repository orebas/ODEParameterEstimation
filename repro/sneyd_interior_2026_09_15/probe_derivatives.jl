# Inspect the ordinary first interpolator while the independent HC pool builds.
# These derivatives are diagnostic only and are not fed into the estimator.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
include("model.jl")
length(ARGS) == 2 || error("Expected MAIN_RUN FRESH_OUTPUT")
source_out, outarg = ARGS
out = abspath(outarg)
ispath(out) && error("Use a fresh output directory")
mkpath(out)
spec = JSON.parsefile(joinpath(source_out, "spec.json"))
source_record = JSON.parsefile(joinpath(source_out, "result.json"))
family = JSON.parsefile(joinpath(source_out, "generic_system_1.json"))
Random.seed!(20260915)
study = study_problem(spec, "free", "root")
pep, scale_info = ODEPE.rescale_pep(study.pep)
@assert json_safe(Dict(string(k)=>getfield(scale_info,k) for k in fieldnames(typeof(scale_info)))) == source_record["scale_info"]
method = ODEPE.InterpolatorAGPRobust
interpolants = ODEPE.create_interpolants(pep.measured_quantities, pep.data_sample,
    pep.data_sample["t"], ODEPE.get_interpolator_function(method))
times = vcat(0.0, source_record["anchor_selection"]["selected_times"])
data_vars = family["original_data_variables"]
jets = [ODEPE.evaluate_noise_frontier_data_vars_at_point(interpolants,
    data_vars, pep.measured_quantities, time) for time in times]
record = (; scope="Independent interpolation-only diagnostic; must be compared with full-run targets before claiming equality",
    interpolator=string(method), times, data_variables=data_vars, jets,
    observation_scale=only(values(scale_info.observable_scales)),
    column_scales_all=ODEPE.compute_column_scales(family["original_unknowns"],data_vars,jets),
    column_scales_excluding_zero=ODEPE.compute_column_scales(family["original_unknowns"],data_vars,jets[2:end]),
    manifest_sha256=source_record["manifest_sha256"], julia_version=string(VERSION))
write_json(joinpath(out, "derivatives.json"), record)
println("DERIVATIVE_PROBE_COMPLETE")
